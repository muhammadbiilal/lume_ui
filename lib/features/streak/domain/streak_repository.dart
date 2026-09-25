/// Daily Streak's records, read and written through the record layer's
/// transactions.
///
/// One flat collection, one check-in per date, no aggregate parent. Marking
/// an already-checked-in date and clearing an already-empty one are both
/// no-ops, matching every other family's idempotent toggle. Nothing is
/// seeded: a reader's Daily Streak starts empty (Option B, session-only).
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import 'streak_book.dart';
import 'streak_failure.dart';
import 'streak_model.dart';

@immutable
class StreakWrite {
  const StreakWrite(this.receipt, {this.checkIn});
  final LumeTxReceipt receipt;
  final StreakCheckIn? checkIn;
}

@immutable
class StreakSnapshot {
  const StreakSnapshot({
    required this.status,
    this.checkIns = const <StreakCheckIn>[],
    this.defects = const <StreakDefect>[],
  });

  final LumeCollectionStatus status;
  final List<StreakCheckIn> checkIns;
  final List<StreakDefect> defects;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;

  StreakStats stats(LumeDate today) => StreakStats.compute(
    checkIns: <LumeDate>{for (final StreakCheckIn c in checkIns) c.date},
    today: today,
  );
}

class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(StreakCollections.checkIns)) {
      try {
        checkIns.add(StreakCheckIn.decode(r));
      } on StreakDefectException catch (e) {
        defects.add(e.defect);
      }
    }
  }

  final LumeRecordTx tx;
  final List<StreakCheckIn> checkIns = <StreakCheckIn>[];
  final List<StreakDefect> defects = <StreakDefect>[];

  StreakCheckIn? at(LumeDate date) {
    for (final StreakCheckIn c in checkIns) {
      if (c.date == date) return c;
    }
    return null;
  }
}

class StreakRepository {
  StreakRepository(this._store, {Random? random, DateTime Function()? now})
    : _random = random ?? Random.secure(),
      _now = now ?? DateTime.now;

  final LumeRecordRepository _store;
  final Random _random;
  final DateTime Function() _now;

  Listenable get changes => _store;

  /// Option B: always `false` today.
  bool get durable => _store.durable;

  LumeRecordId _newId() => LumeRecordId.generate(_random);

  void open() {
    for (final String c in StreakCollections.all) {
      _store.open(c);
    }
  }

  void retry() {
    for (final String c in StreakCollections.all) {
      if (_store.view(c).status == LumeCollectionStatus.error) {
        _store.retry(c);
      }
    }
  }

  StreakSnapshot view() {
    final LumeCollectionView v = _store.view(StreakCollections.checkIns);
    if (v.status == LumeCollectionStatus.error) {
      return const StreakSnapshot(status: LumeCollectionStatus.error);
    }
    if (v.status == LumeCollectionStatus.loading) {
      return const StreakSnapshot(status: LumeCollectionStatus.loading);
    }
    final List<StreakDefect> defects = <StreakDefect>[];
    final List<StreakCheckIn> out = <StreakCheckIn>[];
    for (final LumeRecord r in v.items) {
      try {
        out.add(StreakCheckIn.decode(r));
      } on StreakDefectException catch (e) {
        defects.add(e.defect);
      }
    }
    return StreakSnapshot(status: v.status, checkIns: out, defects: defects);
  }

  /// Mark [date] as done. A no-op (receipt revision `0`) when it already was.
  StreakResult<StreakWrite> checkIn(LumeDate date) {
    if (view().checkIns.any((StreakCheckIn c) => c.date == date)) {
      return const StreakResult<StreakWrite>.ok(
        StreakWrite(LumeTxReceipt(0, <LumeTxChange>[])),
      );
    }
    return _write<StreakCheckIn>((_Data d) {
      if (d.at(date) != null) return d.at(date)!;
      final StreakCheckIn c = StreakCheckIn(
        id: _newId(),
        date: date,
        createdAt: _now(),
      );
      final StreakCheckIn stored = StreakCheckIn.decode(
        d.tx.create(StreakCollections.checkIns, c.id.value, c.toFields()),
      );
      d.checkIns.add(stored);
      return stored;
    });
  }

  /// Clear [date]'s check-in, with Undo. A no-op when it was already clear.
  StreakResult<StreakWrite> uncheck(LumeDate date) {
    final StreakCheckIn? existing = view().checkIns
        .cast<StreakCheckIn?>()
        .firstWhere((StreakCheckIn? c) => c!.date == date, orElse: () => null);
    if (existing == null) {
      return const StreakResult<StreakWrite>.ok(
        StreakWrite(LumeTxReceipt(0, <LumeTxChange>[])),
      );
    }
    return _write<StreakCheckIn>((_Data d) {
      final StreakCheckIn? c = d.at(date);
      if (c == null) {
        throw StreakFailure(
          StreakFailureKind.notFound,
          ids: <LumeRecordId>[existing.id],
        );
      }
      d.tx.delete(
        StreakCollections.checkIns,
        c.id.value,
        expectVersion: c.version,
      );
      d.checkIns.removeWhere((StreakCheckIn x) => x.id == c.id);
      return c;
    });
  }

  StreakResult<void> undo(StreakWrite write) {
    if (write.receipt.revision == 0) return const StreakResult<void>.ok(null);
    final LumeTxResult<void> r = _store.revert(write.receipt);
    return r.ok
        ? const StreakResult<void>.ok(null)
        : StreakResult<void>.failed(_map(r.failure!));
  }

  StreakResult<StreakWrite> _write<T>(T Function(_Data d) body) {
    final LumeTxResult<T> r = _store.run<T>((LumeRecordTx tx) {
      try {
        final _Data d = _Data(tx);
        return body(d);
      } on StreakFailure catch (f) {
        tx.reject(f);
      }
    });
    if (!r.ok) return StreakResult<StreakWrite>.failed(_map(r.failure!));
    final T v = r.value as T;
    return StreakResult<StreakWrite>.ok(
      StreakWrite(r.receipt!, checkIn: v is StreakCheckIn ? v : null),
    );
  }

  static StreakFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected =>
      f.detail is StreakFailure
          ? f.detail! as StreakFailure
          : StreakFailure(StreakFailureKind.storage, cause: f.kind),
    LumeTxFailureKind.conflict ||
    LumeTxFailureKind.duplicateId => StreakFailure(
      StreakFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => StreakFailure(
      StreakFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => StreakFailure(
      StreakFailureKind.storage,
      cause: f.kind,
    ),
  };
}

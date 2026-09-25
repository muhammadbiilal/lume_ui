/// Taraweeh's records, read and written through the record layer's
/// transactions.
///
/// One flat collection, one entry per date, no aggregate parent — the same
/// shape Daily Streak's check-ins use. Marking an already-logged date is a
/// no-op ([logTonight]); clearing an already-empty one is a no-op too
/// ([clear]). Nothing is seeded: a reader's Taraweeh starts empty (Option B,
/// session-only).
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import 'taraweeh_book.dart';
import 'taraweeh_failure.dart';
import 'taraweeh_model.dart';

@immutable
class TaraweehWrite {
  const TaraweehWrite(this.receipt, {this.night});
  final LumeTxReceipt receipt;
  final TaraweehNight? night;
}

@immutable
class TaraweehSnapshot {
  const TaraweehSnapshot({
    required this.status,
    this.nights = const <TaraweehNight>[],
    this.defects = const <TaraweehDefect>[],
  });

  final LumeCollectionStatus status;
  final List<TaraweehNight> nights;
  final List<TaraweehDefect> defects;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;

  TaraweehStats stats(LumeDate today) =>
      TaraweehStats.compute(nights: nights, today: today);
}

class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(TaraweehCollections.nights)) {
      try {
        nights.add(TaraweehNight.decode(r));
      } on TaraweehDefectException catch (e) {
        defects.add(e.defect);
      }
    }
  }

  final LumeRecordTx tx;
  final List<TaraweehNight> nights = <TaraweehNight>[];
  final List<TaraweehDefect> defects = <TaraweehDefect>[];

  TaraweehNight? at(LumeDate date) {
    for (final TaraweehNight n in nights) {
      if (n.date == date) return n;
    }
    return null;
  }
}

class TaraweehRepository {
  TaraweehRepository(this._store, {Random? random, DateTime Function()? now})
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
    for (final String c in TaraweehCollections.all) {
      _store.open(c);
    }
  }

  void retry() {
    for (final String c in TaraweehCollections.all) {
      if (_store.view(c).status == LumeCollectionStatus.error) {
        _store.retry(c);
      }
    }
  }

  TaraweehSnapshot view() {
    final LumeCollectionView v = _store.view(TaraweehCollections.nights);
    if (v.status == LumeCollectionStatus.error) {
      return const TaraweehSnapshot(status: LumeCollectionStatus.error);
    }
    if (v.status == LumeCollectionStatus.loading) {
      return const TaraweehSnapshot(status: LumeCollectionStatus.loading);
    }
    final List<TaraweehDefect> defects = <TaraweehDefect>[];
    final List<TaraweehNight> out = <TaraweehNight>[];
    for (final LumeRecord r in v.items) {
      try {
        out.add(TaraweehNight.decode(r));
      } on TaraweehDefectException catch (e) {
        defects.add(e.defect);
      }
    }
    return TaraweehSnapshot(status: v.status, nights: out, defects: defects);
  }

  /// Log [date] as prayed, at [rakaat] (8 or 20). A no-op (receipt revision
  /// `0`) when [date] already has an entry — use [setRakaat] or [setJuz] to
  /// change one already logged.
  TaraweehResult<TaraweehWrite> logTonight(
    LumeDate date, {
    required int rakaat,
  }) {
    if (view().nights.any((TaraweehNight n) => n.date == date)) {
      return const TaraweehResult<TaraweehWrite>.ok(
        TaraweehWrite(LumeTxReceipt(0, <LumeTxChange>[])),
      );
    }
    return _write<TaraweehNight>((_Data d) {
      _validateRakaat(rakaat);
      if (d.at(date) != null) return d.at(date)!;
      final TaraweehNight n = TaraweehNight(
        id: _newId(),
        date: date,
        rakaat: rakaat,
        createdAt: _now(),
      );
      final TaraweehNight stored = TaraweehNight.decode(
        d.tx.create(TaraweehCollections.nights, n.id.value, n.toFields()),
      );
      d.nights.add(stored);
      return stored;
    });
  }

  /// Change [date]'s rakaat count. Fails with
  /// [TaraweehFailureKind.notFound] when [date] has no entry yet.
  TaraweehResult<TaraweehWrite> setRakaat(LumeDate date, int rakaat) {
    return _write<TaraweehNight>((_Data d) {
      _validateRakaat(rakaat);
      final TaraweehNight? existing = d.at(date);
      if (existing == null) {
        throw const TaraweehFailure(TaraweehFailureKind.notFound);
      }
      final TaraweehNight updated = existing.copyWith(rakaat: rakaat);
      final TaraweehNight stored = TaraweehNight.decode(
        d.tx.update(
          TaraweehCollections.nights,
          existing.id.value,
          updated.toFields(),
          expectVersion: existing.version,
        ),
      );
      d.nights[d.nights.indexWhere((TaraweehNight n) => n.id == existing.id)] =
          stored;
      return stored;
    });
  }

  /// Set (or clear, with `juz: null`) the Juz reached [date]'s night. Fails
  /// with [TaraweehFailureKind.notFound] when [date] has no entry yet.
  TaraweehResult<TaraweehWrite> setJuz(LumeDate date, int? juz) {
    return _write<TaraweehNight>((_Data d) {
      if (juz != null && (juz < kTaraweehJuzMin || juz > kTaraweehJuzMax)) {
        throw const TaraweehFailure.validation('juz');
      }
      final TaraweehNight? existing = d.at(date);
      if (existing == null) {
        throw const TaraweehFailure(TaraweehFailureKind.notFound);
      }
      final TaraweehNight updated = existing.copyWith(
        juz: juz,
        clearJuz: juz == null,
      );
      final TaraweehNight stored = TaraweehNight.decode(
        d.tx.update(
          TaraweehCollections.nights,
          existing.id.value,
          updated.toFields(),
          expectVersion: existing.version,
        ),
      );
      d.nights[d.nights.indexWhere((TaraweehNight n) => n.id == existing.id)] =
          stored;
      return stored;
    });
  }

  /// Clear [date]'s entry entirely, with Undo. A no-op when it was already
  /// clear.
  TaraweehResult<TaraweehWrite> clear(LumeDate date) {
    final TaraweehNight? existing = view().nights
        .cast<TaraweehNight?>()
        .firstWhere((TaraweehNight? n) => n!.date == date, orElse: () => null);
    if (existing == null) {
      return const TaraweehResult<TaraweehWrite>.ok(
        TaraweehWrite(LumeTxReceipt(0, <LumeTxChange>[])),
      );
    }
    return _write<TaraweehNight>((_Data d) {
      final TaraweehNight? n = d.at(date);
      if (n == null) {
        throw TaraweehFailure(
          TaraweehFailureKind.notFound,
          ids: <LumeRecordId>[existing.id],
        );
      }
      d.tx.delete(
        TaraweehCollections.nights,
        n.id.value,
        expectVersion: n.version,
      );
      d.nights.removeWhere((TaraweehNight x) => x.id == n.id);
      return n;
    });
  }

  TaraweehResult<void> undo(TaraweehWrite write) {
    if (write.receipt.revision == 0) return const TaraweehResult<void>.ok(null);
    final LumeTxResult<void> r = _store.revert(write.receipt);
    return r.ok
        ? const TaraweehResult<void>.ok(null)
        : TaraweehResult<void>.failed(_map(r.failure!));
  }

  static void _validateRakaat(int rakaat) {
    if (!kTaraweehRakaatOptions.contains(rakaat)) {
      throw const TaraweehFailure.validation('rakaat');
    }
  }

  TaraweehResult<TaraweehWrite> _write<T>(T Function(_Data d) body) {
    final LumeTxResult<T> r = _store.run<T>((LumeRecordTx tx) {
      try {
        final _Data d = _Data(tx);
        return body(d);
      } on TaraweehFailure catch (f) {
        tx.reject(f);
      }
    });
    if (!r.ok) return TaraweehResult<TaraweehWrite>.failed(_map(r.failure!));
    final T v = r.value as T;
    return TaraweehResult<TaraweehWrite>.ok(
      TaraweehWrite(r.receipt!, night: v is TaraweehNight ? v : null),
    );
  }

  static TaraweehFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected =>
      f.detail is TaraweehFailure
          ? f.detail! as TaraweehFailure
          : TaraweehFailure(TaraweehFailureKind.storage, cause: f.kind),
    LumeTxFailureKind.conflict ||
    LumeTxFailureKind.duplicateId => TaraweehFailure(
      TaraweehFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => TaraweehFailure(
      TaraweehFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => TaraweehFailure(
      TaraweehFailureKind.storage,
      cause: f.kind,
    ),
  };
}

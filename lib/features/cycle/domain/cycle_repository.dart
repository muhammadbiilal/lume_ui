/// Cycle Tracker's records, read and written through the record layer's
/// transactions.
///
/// One flat collection, no aggregate parent. Session-only (Option B, like
/// every other converted record family): a reader's history starts empty and
/// lives for as long as the app runs, which is what
/// [LumeRecordRepository.durable] already says without this repository
/// repeating it.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import 'cycle_book.dart';
import 'cycle_failure.dart';
import 'cycle_model.dart';

@immutable
class CycleWrite {
  const CycleWrite(this.receipt, {this.period});
  final LumeTxReceipt receipt;
  final CyclePeriod? period;
}

@immutable
class CycleSnapshot {
  const CycleSnapshot({
    required this.status,
    this.periods = const <CyclePeriod>[],
    this.defects = const <CycleDefect>[],
  });

  final LumeCollectionStatus status;
  final List<CyclePeriod> periods;
  final List<CycleDefect> defects;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;

  /// The derived calculation over [periods] — never stored, always worked
  /// out fresh for [today] (`cycle_book.dart`).
  CycleInsights insights(LumeDate today) =>
      CycleInsights.compute(periods: periods, today: today);
}

class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(CycleCollections.periods)) {
      try {
        periods.add(CyclePeriod.decode(r));
      } on CycleDefectException catch (e) {
        defects.add(e.defect);
      }
    }
  }

  final LumeRecordTx tx;
  final List<CyclePeriod> periods = <CyclePeriod>[];
  final List<CycleDefect> defects = <CycleDefect>[];

  CyclePeriod? at(LumeRecordId id) {
    for (final CyclePeriod p in periods) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Whether another logged period already starts on [start] — a reader
  /// cannot log the same start date twice. [excluding] lets an update check
  /// against every period but the one it is editing.
  bool startTaken(LumeDate start, {LumeRecordId? excluding}) {
    for (final CyclePeriod p in periods) {
      if (p.id == excluding) continue;
      if (p.startDate == start) return true;
    }
    return false;
  }
}

class CycleRepository {
  CycleRepository(this._store, {Random? random, DateTime Function()? now})
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
    for (final String c in CycleCollections.all) {
      _store.open(c);
    }
  }

  void retry() {
    for (final String c in CycleCollections.all) {
      if (_store.view(c).status == LumeCollectionStatus.error) {
        _store.retry(c);
      }
    }
  }

  CycleSnapshot view() {
    final LumeCollectionView v = _store.view(CycleCollections.periods);
    if (v.status == LumeCollectionStatus.error) {
      return const CycleSnapshot(status: LumeCollectionStatus.error);
    }
    if (v.status == LumeCollectionStatus.loading) {
      return const CycleSnapshot(status: LumeCollectionStatus.loading);
    }
    final List<CycleDefect> defects = <CycleDefect>[];
    final List<CyclePeriod> out = <CyclePeriod>[];
    for (final LumeRecord r in v.items) {
      try {
        out.add(CyclePeriod.decode(r));
      } on CycleDefectException catch (e) {
        defects.add(e.defect);
      }
    }
    return CycleSnapshot(status: v.status, periods: out, defects: defects);
  }

  /// Log a new period. [end], if the reader already knows it, must not be
  /// before [start].
  CycleResult<CycleWrite> logPeriod(LumeDate start, {LumeDate? end}) =>
      _write<CyclePeriod>((_Data d) {
        _validate(d, start: start, end: end);
        final CyclePeriod p = CyclePeriod(
          id: _newId(),
          startDate: start,
          endDate: end,
          createdAt: _now(),
        );
        final CyclePeriod stored = CyclePeriod.decode(
          d.tx.create(CycleCollections.periods, p.id.value, p.toFields()),
        );
        d.periods.add(stored);
        return stored;
      });

  /// Correct an already-logged period — its start, its end, or both. The
  /// same operation closes an ongoing period: pass its [endDate] for the
  /// first time.
  CycleResult<CycleWrite> updatePeriod(
    LumeRecordId id, {
    required LumeDate start,
    LumeDate? endDate,
    required int expectVersion,
  }) => _write<CyclePeriod>((_Data d) {
    final CyclePeriod? existing = d.at(id);
    if (existing == null) {
      throw CycleFailure(CycleFailureKind.notFound, ids: <LumeRecordId>[id]);
    }
    _validate(d, start: start, end: endDate, excluding: id);
    final LumeRecord r = d.tx.update(
      CycleCollections.periods,
      id.value,
      existing.copyWith(startDate: start, endDate: endDate, clearEnd: endDate == null).toFields(),
      expectVersion: expectVersion,
    );
    final CyclePeriod stored = CyclePeriod.decode(r);
    d.periods[d.periods.indexWhere((CyclePeriod p) => p.id == id)] = stored;
    return stored;
  });

  /// Delete a logged period — for one added by mistake. Recoverable: the
  /// receipt reverts it with [undo], exactly like every other family's
  /// delete.
  CycleResult<CycleWrite> deletePeriod(
    LumeRecordId id, {
    required int expectVersion,
  }) => _write<CyclePeriod>((_Data d) {
    final CyclePeriod? existing = d.at(id);
    if (existing == null) {
      throw CycleFailure(CycleFailureKind.notFound, ids: <LumeRecordId>[id]);
    }
    d.tx.delete(CycleCollections.periods, id.value, expectVersion: expectVersion);
    d.periods.removeWhere((CyclePeriod p) => p.id == id);
    return existing;
  });

  CycleResult<void> undo(CycleWrite write) {
    if (write.receipt.revision == 0) return const CycleResult<void>.ok(null);
    final LumeTxResult<void> r = _store.revert(write.receipt);
    return r.ok
        ? const CycleResult<void>.ok(null)
        : CycleResult<void>.failed(_map(r.failure!));
  }

  void _validate(
    _Data d, {
    required LumeDate start,
    LumeDate? end,
    LumeRecordId? excluding,
  }) {
    if (end != null && end.isBefore(start)) {
      throw const CycleFailure.validation('end', 'before-start');
    }
    if (d.startTaken(start, excluding: excluding)) {
      throw const CycleFailure.validation('start', 'duplicate');
    }
  }

  CycleResult<CycleWrite> _write<T>(T Function(_Data d) body) {
    final LumeTxResult<T> r = _store.run<T>((LumeRecordTx tx) {
      try {
        final _Data d = _Data(tx);
        return body(d);
      } on CycleFailure catch (f) {
        tx.reject(f);
      }
    });
    if (!r.ok) return CycleResult<CycleWrite>.failed(_map(r.failure!));
    final T v = r.value as T;
    return CycleResult<CycleWrite>.ok(
      CycleWrite(r.receipt!, period: v is CyclePeriod ? v : null),
    );
  }

  static CycleFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected => f.detail! as CycleFailure,
    LumeTxFailureKind.conflict ||
    LumeTxFailureKind.duplicateId => CycleFailure(
      CycleFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => CycleFailure(
      CycleFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => CycleFailure(
      CycleFailureKind.storage,
      cause: f.kind,
    ),
  };
}

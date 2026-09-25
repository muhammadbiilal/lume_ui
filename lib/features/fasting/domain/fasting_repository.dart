/// Fasting Tracker's records, read and written through the record layer's
/// transactions.
///
/// One flat collection, no aggregate parent. Session-only (Option B, like
/// every other converted record family): a reader's fasting log starts empty
/// and lives for as long as the app runs, which is what
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
import 'fasting_book.dart';
import 'fasting_failure.dart';
import 'fasting_model.dart';

@immutable
class FastingWrite {
  const FastingWrite(this.receipt, {this.entry});
  final LumeTxReceipt receipt;
  final FastEntry? entry;
}

@immutable
class FastingSnapshot {
  const FastingSnapshot({
    required this.status,
    this.entries = const <FastEntry>[],
    this.defects = const <FastingDefect>[],
  });

  final LumeCollectionStatus status;
  final List<FastEntry> entries;
  final List<FastingDefect> defects;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;

  /// The derived calculation over [entries] — never stored, always worked
  /// out fresh for [today] (`fasting_book.dart`).
  FastingInsights insights(LumeDate today) =>
      FastingInsights.compute(entries: entries, today: today);
}

class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(FastingCollections.entries)) {
      try {
        entries.add(FastEntry.decode(r));
      } on FastingDefectException catch (e) {
        defects.add(e.defect);
      }
    }
  }

  final LumeRecordTx tx;
  final List<FastEntry> entries = <FastEntry>[];
  final List<FastingDefect> defects = <FastingDefect>[];

  FastEntry? at(LumeRecordId id) {
    for (final FastEntry e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Whether another logged fast already falls on [date] — a reader corrects
  /// that day's entry instead of creating a duplicate. [excluding] lets an
  /// update check against every entry but the one it is editing.
  bool dateTaken(LumeDate date, {LumeRecordId? excluding}) {
    for (final FastEntry e in entries) {
      if (e.id == excluding) continue;
      if (e.date == date) return true;
    }
    return false;
  }
}

class FastingRepository {
  FastingRepository(this._store, {Random? random, DateTime Function()? now})
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
    for (final String c in FastingCollections.all) {
      _store.open(c);
    }
  }

  void retry() {
    for (final String c in FastingCollections.all) {
      if (_store.view(c).status == LumeCollectionStatus.error) {
        _store.retry(c);
      }
    }
  }

  FastingSnapshot view() {
    final LumeCollectionView v = _store.view(FastingCollections.entries);
    if (v.status == LumeCollectionStatus.error) {
      return const FastingSnapshot(status: LumeCollectionStatus.error);
    }
    if (v.status == LumeCollectionStatus.loading) {
      return const FastingSnapshot(status: LumeCollectionStatus.loading);
    }
    final List<FastingDefect> defects = <FastingDefect>[];
    final List<FastEntry> out = <FastEntry>[];
    for (final LumeRecord r in v.items) {
      try {
        out.add(FastEntry.decode(r));
      } on FastingDefectException catch (e) {
        defects.add(e.defect);
      }
    }
    return FastingSnapshot(status: v.status, entries: out, defects: defects);
  }

  /// Log a fast for [date]. [date] must not already have an entry.
  FastingResult<FastingWrite> logFast(
    LumeDate date, {
    required FastingKind kind,
    required bool kept,
  }) => _write<FastEntry>((_Data d) {
    _validate(d, date: date);
    final FastEntry e = FastEntry(
      id: _newId(),
      date: date,
      kind: kind,
      kept: kept,
      createdAt: _now(),
    );
    final FastEntry stored = FastEntry.decode(
      d.tx.create(FastingCollections.entries, e.id.value, e.toFields()),
    );
    d.entries.add(stored);
    return stored;
  });

  /// Correct an already-logged fast — its date, kind, or whether it was kept.
  FastingResult<FastingWrite> updateFast(
    LumeRecordId id, {
    required LumeDate date,
    required FastingKind kind,
    required bool kept,
    required int expectVersion,
  }) => _write<FastEntry>((_Data d) {
    final FastEntry? existing = d.at(id);
    if (existing == null) {
      throw FastingFailure(FastingFailureKind.notFound, ids: <LumeRecordId>[id]);
    }
    _validate(d, date: date, excluding: id);
    final LumeRecord r = d.tx.update(
      FastingCollections.entries,
      id.value,
      existing.copyWith(date: date, kind: kind, kept: kept).toFields(),
      expectVersion: expectVersion,
    );
    final FastEntry stored = FastEntry.decode(r);
    d.entries[d.entries.indexWhere((FastEntry e) => e.id == id)] = stored;
    return stored;
  });

  /// Delete a logged fast — for one added by mistake. Recoverable: the
  /// receipt reverts it with [undo], exactly like every other family's
  /// delete.
  FastingResult<FastingWrite> deleteFast(
    LumeRecordId id, {
    required int expectVersion,
  }) => _write<FastEntry>((_Data d) {
    final FastEntry? existing = d.at(id);
    if (existing == null) {
      throw FastingFailure(FastingFailureKind.notFound, ids: <LumeRecordId>[id]);
    }
    d.tx.delete(FastingCollections.entries, id.value, expectVersion: expectVersion);
    d.entries.removeWhere((FastEntry e) => e.id == id);
    return existing;
  });

  FastingResult<void> undo(FastingWrite write) {
    if (write.receipt.revision == 0) return const FastingResult<void>.ok(null);
    final LumeTxResult<void> r = _store.revert(write.receipt);
    return r.ok
        ? const FastingResult<void>.ok(null)
        : FastingResult<void>.failed(_map(r.failure!));
  }

  void _validate(_Data d, {required LumeDate date, LumeRecordId? excluding}) {
    if (d.dateTaken(date, excluding: excluding)) {
      throw const FastingFailure.validation('date', 'duplicate');
    }
  }

  FastingResult<FastingWrite> _write<T>(T Function(_Data d) body) {
    final LumeTxResult<T> r = _store.run<T>((LumeRecordTx tx) {
      try {
        final _Data d = _Data(tx);
        return body(d);
      } on FastingFailure catch (f) {
        tx.reject(f);
      }
    });
    if (!r.ok) return FastingResult<FastingWrite>.failed(_map(r.failure!));
    final T v = r.value as T;
    return FastingResult<FastingWrite>.ok(
      FastingWrite(r.receipt!, entry: v is FastEntry ? v : null),
    );
  }

  static FastingFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected => f.detail! as FastingFailure,
    LumeTxFailureKind.conflict ||
    LumeTxFailureKind.duplicateId => FastingFailure(
      FastingFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => FastingFailure(
      FastingFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => FastingFailure(
      FastingFailureKind.storage,
      cause: f.kind,
    ),
  };
}

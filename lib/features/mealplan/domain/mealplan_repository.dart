/// Meal Plan's records, read and written through the record layer's
/// transactions (`MEALPLAN_PROPOSAL.md`).
///
/// One flat collection, no aggregate parent, no money — simpler than
/// every wave-5 family. At most one entry per (date, slot): setting an
/// already-filled slot replaces its text in place rather than creating a
/// second entry for the same slot. Nothing is seeded: a reader's Meal
/// Plan starts empty (Option B).
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import 'mealplan_book.dart';
import 'mealplan_failure.dart';
import 'mealplan_model.dart';

@immutable
class MealPlanWrite {
  const MealPlanWrite(this.receipt, {this.entry});
  final LumeTxReceipt receipt;
  final MealPlanEntry? entry;
}

@immutable
class MealPlanSnapshot {
  const MealPlanSnapshot({
    required this.status,
    this.entries = const <MealPlanEntry>[],
    this.defects = const <MealPlanDefect>[],
  });

  final LumeCollectionStatus status;
  final List<MealPlanEntry> entries;
  final List<MealPlanDefect> defects;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;

  MealPlanWeek week(LumeDate today) => MealPlanWeek.from(entries: entries, today: today);
}

class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(MealPlanCollections.entries)) {
      try {
        entries.add(MealPlanEntry.decode(r));
      } on MealPlanDefectException catch (e) {
        defects.add(e.defect);
      }
    }
  }

  final LumeRecordTx tx;
  final List<MealPlanEntry> entries = <MealPlanEntry>[];
  final List<MealPlanDefect> defects = <MealPlanDefect>[];

  MealPlanEntry? at(LumeDate date, MealSlot slot) {
    for (final MealPlanEntry e in entries) {
      if (e.date == date && e.slot == slot) return e;
    }
    return null;
  }
}

class MealPlanRepository {
  MealPlanRepository(this._store, {Random? random, DateTime Function()? now})
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
    for (final String c in MealPlanCollections.all) {
      _store.open(c);
    }
  }

  void retry() {
    for (final String c in MealPlanCollections.all) {
      if (_store.view(c).status == LumeCollectionStatus.error) {
        _store.retry(c);
      }
    }
  }

  MealPlanSnapshot view() {
    final LumeCollectionView v = _store.view(MealPlanCollections.entries);
    if (v.status == LumeCollectionStatus.error) {
      return const MealPlanSnapshot(status: LumeCollectionStatus.error);
    }
    if (v.status == LumeCollectionStatus.loading) {
      return const MealPlanSnapshot(status: LumeCollectionStatus.loading);
    }
    final List<MealPlanDefect> defects = <MealPlanDefect>[];
    final List<MealPlanEntry> out = <MealPlanEntry>[];
    for (final LumeRecord r in v.items) {
      try {
        out.add(MealPlanEntry.decode(r));
      } on MealPlanDefectException catch (e) {
        defects.add(e.defect);
      }
    }
    return MealPlanSnapshot(status: v.status, entries: out, defects: defects);
  }

  /// Set (or replace) what the reader plans for [date]'s [slot]. Blank
  /// [text] is refused here — clearing a slot is [clearSlot], a delete,
  /// not an empty-string write.
  MealPlanResult<MealPlanWrite> setSlot(
    LumeDate date,
    MealSlot slot,
    String text,
  ) => _write<MealPlanEntry>((_Data d) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const MealPlanFailure.validation('text', 'required');
    }
    if (trimmed.length > kMealPlanTextMax) {
      throw const MealPlanFailure.validation('text', 'long');
    }
    final MealPlanEntry? existing = d.at(date, slot);
    if (existing != null) {
      final LumeRecord r = d.tx.update(
        MealPlanCollections.entries,
        existing.id.value,
        existing.copyWith(text: trimmed).toFields(),
        expectVersion: existing.version,
      );
      final MealPlanEntry stored = MealPlanEntry.decode(r);
      d.entries[d.entries.indexWhere((MealPlanEntry x) => x.id == existing.id)] = stored;
      return stored;
    }
    final MealPlanEntry e = MealPlanEntry(
      id: _newId(),
      date: date,
      slot: slot,
      text: trimmed,
      createdAt: _now(),
    );
    final MealPlanEntry stored = MealPlanEntry.decode(
      d.tx.create(MealPlanCollections.entries, e.id.value, e.toFields()),
    );
    d.entries.add(stored);
    return stored;
  });

  /// Clear a slot — a delete, with Undo, matching every other family's
  /// delete pattern. A no-op result (not a failure) when the slot was
  /// already empty.
  MealPlanResult<MealPlanWrite> clearSlot(LumeDate date, MealSlot slot) {
    final MealPlanSnapshot s = view();
    MealPlanEntry? existing;
    for (final MealPlanEntry e in s.entries) {
      if (e.date == date && e.slot == slot) existing = e;
    }
    if (existing == null) {
      return const MealPlanResult<MealPlanWrite>.ok(
        MealPlanWrite(LumeTxReceipt(0, <LumeTxChange>[])),
      );
    }
    return _write<MealPlanEntry>((_Data d) {
      final MealPlanEntry? e = d.at(date, slot);
      if (e == null) {
        throw MealPlanFailure(MealPlanFailureKind.notFound, ids: <LumeRecordId>[existing!.id]);
      }
      d.tx.delete(MealPlanCollections.entries, e.id.value, expectVersion: e.version);
      d.entries.removeWhere((MealPlanEntry x) => x.id == e.id);
      return e;
    });
  }

  MealPlanResult<void> undo(MealPlanWrite write) {
    if (write.receipt.revision == 0) return const MealPlanResult<void>.ok(null);
    final LumeTxResult<void> r = _store.revert(write.receipt);
    return r.ok
        ? const MealPlanResult<void>.ok(null)
        : MealPlanResult<void>.failed(_map(r.failure!));
  }

  MealPlanResult<MealPlanWrite> _write<T>(T Function(_Data d) body) {
    final LumeTxResult<T> r = _store.run<T>((LumeRecordTx tx) {
      try {
        final _Data d = _Data(tx);
        return body(d);
      } on MealPlanFailure catch (f) {
        tx.reject(f);
      }
    });
    if (!r.ok) return MealPlanResult<MealPlanWrite>.failed(_map(r.failure!));
    final T v = r.value as T;
    return MealPlanResult<MealPlanWrite>.ok(
      MealPlanWrite(r.receipt!, entry: v is MealPlanEntry ? v : null),
    );
  }

  static MealPlanFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected => f.detail! as MealPlanFailure,
    LumeTxFailureKind.conflict ||
    LumeTxFailureKind.duplicateId => MealPlanFailure(
      MealPlanFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => MealPlanFailure(
      MealPlanFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => MealPlanFailure(
      MealPlanFailureKind.storage,
      cause: f.kind,
    ),
  };
}

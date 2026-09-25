/// Habits' records, read and written through the record layer's
/// transactions.
///
/// Two collections: a habit, and its check-ins. Deleting a habit removes
/// every check-in that names it, in the same transaction — the same rule
/// Goals' contributions and Ledger's entries already keep. A check-in is
/// never edited, only toggled: [toggleCheckin] creates one where there was
/// none, or removes the one that was there — no confirmation, no form.
/// `record-schemas.js`'s own note on this family: "tapping a habit must
/// feel instant or nobody taps it." Nothing is seeded: a reader's Habits
/// starts empty (Option B — session-only, `durable` says so).
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import 'habits_book.dart';
import 'habits_failure.dart';
import 'habits_model.dart';

/// What the reader filled in for a habit.
@immutable
class HabitDraft {
  const HabitDraft({
    required this.name,
    required this.frequency,
    this.notes,
  });

  final String name;
  final HabitFrequency frequency;
  final String? notes;

  String get fingerprint => jsonEncode(<String, Object?>{
    'n': name,
    'f': frequency.name,
    'note': notes,
  });
}

/// A committed write — enough to show it and to undo it.
@immutable
class HabitsWrite {
  const HabitsWrite(this.receipt, {this.habit, this.checkin});

  final LumeTxReceipt receipt;
  final Habit? habit;

  /// Set on a toggle that added a check-in; `null` when the toggle removed
  /// one, or when this write is not a toggle at all.
  final HabitCheckin? checkin;
}

/// Habits' records as they stand, or why they cannot be shown.
@immutable
class HabitsSnapshot {
  const HabitsSnapshot({
    required this.status,
    this.habits = const <Habit>[],
    this.checkins = const <HabitCheckin>[],
    this.defects = const <HabitsDefect>[],
  });

  final LumeCollectionStatus status;
  final List<Habit> habits;
  final List<HabitCheckin> checkins;
  final List<HabitsDefect> defects;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;

  HabitsBook book(LumeDate? today) => HabitsBook.from(
    habits: habits,
    checkins: checkins,
    defects: defects,
    today: today,
  );
}

/// Records decoded inside one transaction.
class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(HabitsCollections.habits)) {
      _read(r, Habit.decode, habits);
    }
    for (final LumeRecord r in tx.all(HabitsCollections.checkins)) {
      _read(r, HabitCheckin.decode, checkins);
    }
  }

  final LumeRecordTx tx;
  final List<Habit> habits = <Habit>[];
  final List<HabitCheckin> checkins = <HabitCheckin>[];
  final List<HabitsDefect> defects = <HabitsDefect>[];

  void _read<T>(LumeRecord r, T Function(LumeRecord) decode, List<T> into) {
    try {
      into.add(decode(r));
    } on HabitsDefectException catch (e) {
      defects.add(e.defect);
    }
  }

  Habit sound(LumeRecordId id) {
    for (final Habit h in habits) {
      if (h.id == id) return h;
    }
    throw HabitsFailure(HabitsFailureKind.notFound, ids: <LumeRecordId>[id]);
  }

  HabitCheckin? checkinAt(LumeRecordId habitId, LumeDate date) {
    for (final HabitCheckin c in checkins) {
      if (c.habitId == habitId && c.date == date) return c;
    }
    return null;
  }
}

class HabitsRepository {
  HabitsRepository(this._store, {Random? random, DateTime Function()? now})
    : _random = random ?? Random.secure(),
      _now = now ?? DateTime.now;

  final LumeRecordRepository _store;
  final Random _random;
  final DateTime Function() _now;

  /// Told once per committed write.
  Listenable get changes => _store;

  /// Whether a write survives the app closing — the store's answer.
  /// Option B: always `false` today.
  bool get durable => _store.durable;

  LumeRecordId _newId() => LumeRecordId.generate(_random);

  void open() {
    for (final String c in HabitsCollections.all) {
      _store.open(c);
    }
  }

  void retry() {
    for (final String c in HabitsCollections.all) {
      if (_store.view(c).status == LumeCollectionStatus.error) {
        _store.retry(c);
      }
    }
  }

  /// The records now, decoded; one that cannot be read is a defect, listed,
  /// never dropped.
  HabitsSnapshot view() {
    final List<LumeCollectionView> views = <LumeCollectionView>[
      for (final String c in HabitsCollections.all) _store.view(c),
    ];
    if (views.any((LumeCollectionView v) => v.status == LumeCollectionStatus.error)) {
      return const HabitsSnapshot(status: LumeCollectionStatus.error);
    }
    if (views.any((LumeCollectionView v) => v.status == LumeCollectionStatus.loading)) {
      return const HabitsSnapshot(status: LumeCollectionStatus.loading);
    }
    final List<HabitsDefect> defects = <HabitsDefect>[];
    List<T> read<T>(LumeCollectionView v, T Function(LumeRecord) decode) => <T>[
      for (final LumeRecord r in v.items)
        ...() {
          try {
            return <T>[decode(r)];
          } on HabitsDefectException catch (e) {
            defects.add(e.defect);
            return <T>[];
          }
        }(),
    ];
    return HabitsSnapshot(
      status: views.first.status,
      habits: read(views[0], Habit.decode),
      checkins: read(views[1], HabitCheckin.decode),
      defects: defects,
    );
  }

  // ---- habits ---------------------------------------------------------------

  HabitsResult<HabitsWrite> addHabit(HabitDraft draft, {String? idempotencyKey}) =>
      _write<Habit?>(
        (_Data d) {
          _validate(draft);
          final Habit h = Habit(
            id: _newId(),
            name: draft.name.trim(),
            frequency: draft.frequency,
            notes: _optional(draft.notes),
            createdAt: _now(),
          );
          final Habit stored = Habit.decode(
            d.tx.create(HabitsCollections.habits, h.id.value, h.toFields()),
          );
          d.habits.add(stored);
          return stored;
        },
        idempotencyKey: idempotencyKey,
        fingerprint: idempotencyKey == null ? null : draft.fingerprint,
      );

  /// Edit a habit — every field, at any time. Its check-in history is
  /// untouched.
  HabitsResult<HabitsWrite> editHabit(
    LumeRecordId id,
    HabitDraft draft, {
    required int version,
  }) => _write<Habit?>((_Data d) {
    final Habit was = d.sound(id);
    _validate(draft);
    final Habit now = was.copyWith(
      name: draft.name.trim(),
      frequency: draft.frequency,
      notes: _optional(draft.notes),
      clearNotes: draft.notes == null || draft.notes!.trim().isEmpty,
    );
    final Habit stored = Habit.decode(
      d.tx.update(
        HabitsCollections.habits,
        id.value,
        now.toFields(),
        expectVersion: version,
      ),
    );
    d.habits[d.habits.indexWhere((Habit x) => x.id == id)] = stored;
    return stored;
  });

  /// Delete a habit made by mistake: the habit and every check-in that
  /// names it, in one transaction. [undo] brings back the same ids and
  /// versions.
  HabitsResult<HabitsWrite> deleteHabit(
    LumeRecordId id, {
    required int version,
  }) => _write<Habit?>((_Data d) {
    final Habit was = d.sound(id);
    for (final LumeRecord r in d.tx.all(HabitsCollections.checkins)) {
      if (r['habit'] == id.value) {
        d.tx.delete(HabitsCollections.checkins, r.id, expectVersion: r.version);
      }
    }
    d.tx.delete(HabitsCollections.habits, id.value, expectVersion: version);
    d.habits.removeWhere((Habit x) => x.id == id);
    d.checkins.removeWhere((HabitCheckin x) => x.habitId == id);
    d.defects.removeWhere((HabitsDefect x) => x.habitId == id.value);
    return was;
  });

  // ---- check-ins --------------------------------------------------------

  /// Toggle whether [habitId] was kept on [date]: creates a check-in where
  /// there was none, or removes the one that was there. Fast and
  /// optimistic — no confirmation sheet, matching the reference's own
  /// composition note on this family.
  HabitsResult<HabitsWrite> toggleCheckin(LumeRecordId habitId, LumeDate date) =>
      _write<HabitCheckin?>((_Data d) {
        d.sound(habitId);
        final HabitCheckin? existing = d.checkinAt(habitId, date);
        if (existing != null) {
          d.tx.delete(
            HabitsCollections.checkins,
            existing.id.value,
            expectVersion: existing.version,
          );
          d.checkins.removeWhere((HabitCheckin x) => x.id == existing.id);
          return null;
        }
        final HabitCheckin c = HabitCheckin(
          id: _newId(),
          habitId: habitId,
          date: date,
          createdAt: _now(),
        );
        final HabitCheckin stored = HabitCheckin.decode(
          d.tx.create(HabitsCollections.checkins, c.id.value, c.toFields()),
        );
        d.checkins.add(stored);
        return stored;
      });

  /// Reverse a committed write — a delete's or a toggle's — restoring the
  /// same ids and versions.
  HabitsResult<void> undo(HabitsWrite write) {
    final LumeTxResult<void> r = _store.revert(write.receipt);
    return r.ok
        ? const HabitsResult<void>.ok(null)
        : HabitsResult<void>.failed(_map(r.failure!));
  }

  // ---- internals ----------------------------------------------------------

  static void _validate(HabitDraft draft) {
    final String name = draft.name.trim();
    if (name.isEmpty) throw const HabitsFailure.validation('name', 'required');
    if (name.length > kHabitsNameMax) {
      throw const HabitsFailure.validation('name', 'long');
    }
    if ((draft.notes?.trim().length ?? 0) > kHabitsNoteMax) {
      throw const HabitsFailure.validation('notes', 'long');
    }
  }

  static String? _optional(String? s) =>
      s == null || s.trim().isEmpty ? null : s.trim();

  HabitsResult<HabitsWrite> _write<T>(
    T Function(_Data d) body, {
    String? idempotencyKey,
    String? fingerprint,
  }) {
    final LumeTxResult<T> r = _store.run<T>((LumeRecordTx tx) {
      try {
        final _Data d = _Data(tx);
        return body(d);
      } on HabitsFailure catch (f) {
        tx.reject(f);
      }
    }, idempotencyKey: idempotencyKey, fingerprint: fingerprint);
    if (!r.ok) return HabitsResult<HabitsWrite>.failed(_map(r.failure!));
    final T v = r.value as T;
    return HabitsResult<HabitsWrite>.ok(
      HabitsWrite(
        r.receipt!,
        habit: v is Habit ? v : null,
        checkin: v is HabitCheckin ? v : null,
      ),
    );
  }

  static HabitsFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected => f.detail! as HabitsFailure,
    LumeTxFailureKind.conflict ||
    LumeTxFailureKind.duplicateId => HabitsFailure(
      HabitsFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => HabitsFailure(
      HabitsFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => HabitsFailure(
      HabitsFailureKind.storage,
      cause: f.kind,
    ),
  };
}

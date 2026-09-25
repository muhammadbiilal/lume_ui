/// Habits over an in-memory store, a controllable clock and seeded ids —
/// deterministic, and never the wall clock.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/habits/domain/habits_book.dart';
import 'package:lume/features/habits/domain/habits_failure.dart';
import 'package:lume/features/habits/domain/habits_model.dart';
import 'package:lume/features/habits/domain/habits_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_transaction.dart';

LumeDate d(int month, int day) => LumeDate(2026, month, day);

/// The fixture day: 7 September 2026 (a Monday).
final LumeDate kToday = d(9, 7);

class HabitsHarness {
  HabitsHarness({int seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = HabitsRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  late final LumeMemoryRecordRepository store;
  late final HabitsRepository repo;
  DateTime clock = DateTime.utc(2026, 9, 7, 10);

  void tick([Duration by = const Duration(minutes: 1)]) =>
      clock = clock.add(by);

  HabitsBook book([LumeDate? today]) => repo.view().book(today ?? kToday);

  HabitsResult<HabitsWrite> tryAdd({
    String name = 'Read',
    HabitFrequency frequency = HabitFrequency.daily,
    String? notes,
    String? idempotencyKey,
  }) {
    tick();
    return repo.addHabit(
      HabitDraft(name: name, frequency: frequency, notes: notes),
      idempotencyKey: idempotencyKey,
    );
  }

  Habit add({
    String name = 'Read',
    HabitFrequency frequency = HabitFrequency.daily,
    String? notes,
  }) {
    final HabitsResult<HabitsWrite> r = tryAdd(
      name: name,
      frequency: frequency,
      notes: notes,
    );
    expect(r.failure, isNull, reason: 'add $name');
    return r.value!.habit!;
  }

  /// Toggles [habitId] checked on each of [dates], at the fixture clock's
  /// own pace (one write per tick, like a reader tapping across days).
  void checkIn(LumeRecordId habitId, Iterable<LumeDate> dates) {
    for (final LumeDate date in dates) {
      tick();
      final HabitsResult<HabitsWrite> r = repo.toggleCheckin(habitId, date);
      expect(r.failure, isNull, reason: 'check in $habitId $date');
    }
  }

  HabitView view(LumeRecordId id, [LumeDate? today]) => book(today).habit(id)!;

  void raw(String collection, String id, Map<String, Object?> fields) {
    final LumeTxResult<void> r = store.run<void>(
      (LumeRecordTx tx) => tx.create(collection, id, fields),
    );
    expect(r.ok, isTrue);
  }

  void dispose() => store.dispose();
}

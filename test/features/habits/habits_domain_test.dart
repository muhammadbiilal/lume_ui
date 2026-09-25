import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/habits/domain/habits_book.dart';
import 'package:lume/features/habits/domain/habits_failure.dart';
import 'package:lume/features/habits/domain/habits_model.dart';
import 'package:lume/features/habits/domain/habits_repository.dart';

import 'habits_harness.dart';

void main() {
  group('model and codec', () {
    test('a habit round-trips through its fields', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      final Habit habit = h.add(
        name: 'Read',
        frequency: HabitFrequency.weekly,
        notes: 'Before bed',
      );
      expect(habit.name, 'Read');
      expect(habit.frequency, HabitFrequency.weekly);
      expect(habit.notes, 'Before bed');
      expect(habit.version, 1);
    });

    test('an empty name is refused', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      final HabitsResult<HabitsWrite> r = h.tryAdd(name: '   ');
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'name');
    });

    test('a name over the limit is refused', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      final HabitsResult<HabitsWrite> r = h.tryAdd(
        name: 'x' * (kHabitsNameMax + 1),
      );
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'name');
    });

    test('a habit record of the wrong schema is a defect, not a crash', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      h.raw(
        HabitsCollections.habits,
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        <String, Object?>{'schema': 'lume.other/1'},
      );
      expect(h.repo.view().defects, hasLength(1));
      expect(h.repo.view().defects.first.reason, 'schema');
      expect(h.book().habits, isEmpty);
    });

    test(
      'a check-in with a malformed date is a defect naming its own habit',
      () {
        final HabitsHarness h = HabitsHarness();
        addTearDown(h.dispose);
        final Habit habit = h.add();
        h.raw(
          HabitsCollections.checkins,
          'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
          <String, Object?>{
            'schema': kHabitsSchema,
            'habit': habit.id.value,
            'date': 'not-a-date',
          },
        );
        final HabitsSnapshot snap = h.repo.view();
        expect(snap.defects, hasLength(1));
        expect(snap.defects.first.habitId, habit.id.value);
        final HabitsBook book = h.book();
        final HabitView v = book.habit(habit.id)!;
        expect(v.damaged, isTrue);
        expect(v.currentStreak, isNull);
        expect(v.bestStreak, 0);
      },
    );

    test(
      'an orphan check-in names a habit that is not there, and does not crash',
      () {
        final HabitsHarness h = HabitsHarness();
        addTearDown(h.dispose);
        h.raw(
          HabitsCollections.checkins,
          'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
          <String, Object?>{
            'schema': kHabitsSchema,
            'habit': 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
            'date': kToday.toIso(),
          },
        );
        final HabitsBook book = h.book();
        expect(book.habits, isEmpty);
        expect(book.damage, hasLength(1));
        expect(book.damage.first.reason, 'orphanCheckin');
      },
    );
  });

  group('streaks — daily', () {
    test('counts consecutive days ending today when today is checked', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      h.clock = DateTime.utc(2026, 9, 1);
      final Habit habit = h.add();
      h.checkIn(habit.id, <LumeDate>[d(9, 5), d(9, 6), d(9, 7)]);
      final HabitView v = h.view(habit.id);
      expect(v.doneToday, isTrue);
      expect(v.currentStreak, 3);
    });

    test(
      'stays alive, counting from yesterday, when today is not yet checked',
      () {
        final HabitsHarness h = HabitsHarness();
        addTearDown(h.dispose);
        h.clock = DateTime.utc(2026, 9, 1);
        final Habit habit = h.add();
        h.checkIn(habit.id, <LumeDate>[d(9, 5), d(9, 6)]);
        final HabitView v = h.view(habit.id); // today is 7 Sep, unchecked
        expect(v.doneToday, isFalse);
        expect(v.currentStreak, 2);
      },
    );

    test('breaks on a missed day', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      h.clock = DateTime.utc(2026, 9, 1);
      final Habit habit = h.add();
      h.checkIn(habit.id, <LumeDate>[
        d(9, 5),
      ]); // 6th missed, 7th (today) missed
      final HabitView v = h.view(habit.id);
      expect(v.currentStreak, 0);
    });

    test('bestStreak is the longest run in history, not just the live one', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      h.clock = DateTime.utc(2026, 9, 1);
      final Habit habit = h.add();
      h.checkIn(habit.id, <LumeDate>[
        d(9, 1),
        d(9, 2),
        d(9, 3), // a 3-day run
        // 4th missed
        d(9, 6),
        d(9, 7), // a live 2-day run
      ]);
      final HabitView v = h.view(habit.id);
      expect(v.currentStreak, 2);
      expect(v.bestStreak, 3);
    });
  });

  group('streaks — weekdays', () {
    test('weekends never break the streak, checked or not', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      h.clock = DateTime.utc(2026, 9, 1);
      final Habit habit = h.add(frequency: HabitFrequency.weekdays);
      // Fri 4 Sep, weekend untouched, Mon 7 Sep (today).
      h.checkIn(habit.id, <LumeDate>[d(9, 4), d(9, 7)]);
      final HabitView v = h.view(habit.id);
      expect(v.currentStreak, 2);
    });

    test('a missed weekday still breaks it', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      h.clock = DateTime.utc(2026, 9, 1);
      final Habit habit = h.add(frequency: HabitFrequency.weekdays);
      // Wed 2 Sep checked, Thu/Fri missed, today (Mon) checked.
      h.checkIn(habit.id, <LumeDate>[d(9, 2), d(9, 7)]);
      final HabitView v = h.view(habit.id);
      expect(v.currentStreak, 1);
    });
  });

  group('streaks — weekly', () {
    test(
      'any day in the week counts for that week, and weeks must be consecutive',
      () {
        final HabitsHarness h = HabitsHarness();
        addTearDown(h.dispose);
        h.clock = DateTime.utc(2026, 8, 1);
        final Habit habit = h.add(frequency: HabitFrequency.weekly);
        // Three consecutive Mondays (17, 24, 31 Aug) — this week (7 Sep,
        // today) is not yet done, but is not over yet either, so it does not
        // break the streak.
        h.checkIn(habit.id, <LumeDate>[d(8, 17), d(8, 24), d(8, 31)]);
        final HabitView v = h.view(habit.id);
        expect(v.currentStreak, 3);
      },
    );

    test('a week with no check-in breaks the streak', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      h.clock = DateTime.utc(2026, 8, 1);
      final Habit habit = h.add(frequency: HabitFrequency.weekly);
      // Week of 17 Aug done, week of 24 Aug skipped, this week done.
      h.checkIn(habit.id, <LumeDate>[d(8, 17), d(9, 7)]);
      final HabitView v = h.view(habit.id);
      expect(v.currentStreak, 1);
    });

    test(
      'stays alive counting from last week when this week is not done yet',
      () {
        final HabitsHarness h = HabitsHarness();
        addTearDown(h.dispose);
        h.clock = DateTime.utc(2026, 8, 1);
        final Habit habit = h.add(frequency: HabitFrequency.weekly);
        h.checkIn(habit.id, <LumeDate>[d(8, 31), d(9, 3)]); // last week only
        final HabitView v = h.view(habit.id);
        expect(v.currentStreak, 1);
      },
    );
  });

  group('completion rate', () {
    test('daily: checked days over days since creation, through today', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      h.clock = DateTime.utc(2026, 9, 1); // habit made 1 Sep
      final Habit habit = h.add();
      // 7 days from 1 Sep to 7 Sep inclusive; 5 checked.
      h.checkIn(habit.id, <LumeDate>[
        d(9, 1),
        d(9, 2),
        d(9, 3),
        d(9, 5),
        d(9, 6),
      ]);
      final HabitView v = h.view(habit.id);
      expect(v.completionRate, closeTo(5 / 7, 1e-9));
    });

    test('weekly: checked weeks over weeks since creation', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      h.clock = DateTime.utc(2026, 8, 1); // week of 17 Aug is the first
      final Habit habit = h.add(frequency: HabitFrequency.weekly);
      // Habit made 1 Aug (week of 27 Jul) through 7 Sep (week of 7 Sep) —
      // 7 weeks; 2 have a check-in.
      h.checkIn(habit.id, <LumeDate>[d(8, 17), d(9, 7)]);
      final HabitView v = h.view(habit.id);
      expect(v.completionRate, closeTo(2 / 7, 1e-9));
    });

    test('without the reader\'s day, nothing is dated', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      final Habit habit = h.add();
      final HabitView v = h.repo.view().book(null).habit(habit.id)!;
      expect(v.doneToday, isNull);
      expect(v.currentStreak, isNull);
      expect(v.completionRate, isNull);
      // bestStreak is still known — it never needs "today".
      expect(v.bestStreak, 0);
    });
  });

  group('aggregate book stats — real, never a fixture literal', () {
    test(
      'doneTodayCount and activeStreakCount count only undamaged habits',
      () {
        final HabitsHarness h = HabitsHarness();
        addTearDown(h.dispose);
        h.clock = DateTime.utc(2026, 9, 1);
        final Habit a = h.add(name: 'A');
        final Habit b = h.add(name: 'B');
        h.checkIn(a.id, <LumeDate>[d(9, 6), d(9, 7)]); // streak, done today
        h.checkIn(b.id, <LumeDate>[d(9, 5)]); // no streak, not done today
        final HabitsBook book = h.book();
        expect(book.doneTodayCount, 1);
        expect(book.activeStreakCount, 1);
      },
    );

    test('an empty book counts zero, not a fabricated figure', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      final HabitsBook book = h.book();
      expect(book.isEmpty, isTrue);
      expect(book.doneTodayCount, 0);
      expect(book.activeStreakCount, 0);
    });
  });

  group('toggle — instant, no confirmation', () {
    test('toggling an unchecked day creates a check-in', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      final Habit habit = h.add();
      final HabitsResult<HabitsWrite> r = h.repo.toggleCheckin(
        habit.id,
        kToday,
      );
      expect(r.ok, isTrue);
      expect(r.value!.checkin, isNotNull);
      expect(h.view(habit.id).doneToday, isTrue);
    });

    test('toggling it again removes it', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      final Habit habit = h.add();
      h.repo.toggleCheckin(habit.id, kToday);
      final HabitsResult<HabitsWrite> r = h.repo.toggleCheckin(
        habit.id,
        kToday,
      );
      expect(r.ok, isTrue);
      expect(r.value!.checkin, isNull);
      expect(h.view(habit.id).doneToday, isFalse);
    });

    test('toggling a habit that does not exist fails', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      final HabitsResult<HabitsWrite> r = h.repo.toggleCheckin(
        LumeRecordId.generate(),
        kToday,
      );
      expect(r.ok, isFalse);
      expect(r.failure!.kind, HabitsFailureKind.notFound);
    });

    test('undo of a toggle restores the previous state', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      final Habit habit = h.add();
      final HabitsResult<HabitsWrite> r = h.repo.toggleCheckin(
        habit.id,
        kToday,
      );
      expect(h.view(habit.id).doneToday, isTrue);
      final HabitsResult<void> u = h.repo.undo(r.value!);
      expect(u.ok, isTrue);
      expect(h.view(habit.id).doneToday, isFalse);
    });
  });

  group('delete cascades', () {
    test('deleting a habit removes its check-ins too', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      final Habit habit = h.add();
      h.checkIn(habit.id, <LumeDate>[kToday]);
      final HabitsResult<HabitsWrite> r = h.repo.deleteHabit(
        habit.id,
        version: habit.version,
      );
      expect(r.ok, isTrue);
      expect(h.repo.view().habits, isEmpty);
      expect(h.repo.view().checkins, isEmpty);
    });

    test('undo restores the habit and its check-ins', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      final Habit habit = h.add();
      h.checkIn(habit.id, <LumeDate>[kToday]);
      final HabitsResult<HabitsWrite> del = h.repo.deleteHabit(
        habit.id,
        version: habit.version,
      );
      final HabitsResult<void> u = h.repo.undo(del.value!);
      expect(u.ok, isTrue);
      expect(h.repo.view().habits, hasLength(1));
      expect(h.repo.view().checkins, hasLength(1));
      expect(h.view(habit.id).doneToday, isTrue);
    });
  });

  group('conflict', () {
    test('editing with a stale version fails as a conflict', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      final Habit habit = h.add();
      h.repo.editHabit(
        habit.id,
        const HabitDraft(name: 'Renamed', frequency: HabitFrequency.daily),
        version: habit.version,
      );
      final HabitsResult<HabitsWrite> r = h.repo.editHabit(
        habit.id,
        const HabitDraft(name: 'Again', frequency: HabitFrequency.daily),
        version: habit.version, // stale
      );
      expect(r.ok, isFalse);
      expect(r.failure!.kind, HabitsFailureKind.conflict);
    });
  });

  group('Option B — non-durability', () {
    test('the repository reports itself as not durable', () {
      final HabitsHarness h = HabitsHarness();
      addTearDown(h.dispose);
      expect(h.repo.durable, isFalse);
    });
  });
}

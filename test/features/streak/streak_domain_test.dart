import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/features/streak/domain/streak_book.dart';
import 'package:lume/features/streak/domain/streak_failure.dart';
import 'package:lume/features/streak/domain/streak_model.dart';
import 'package:lume/features/streak/domain/streak_repository.dart';

import 'streak_harness.dart';

void main() {
  group('model and codec', () {
    test('a check-in round-trips through its fields', () {
      final StreakHarness h = StreakHarness();
      addTearDown(h.dispose);
      final StreakCheckIn c = h.checkIn(kToday);
      expect(c.date, kToday);
      expect(c.version, 1);
    });

    test('a record of the wrong schema is a defect, not a crash', () {
      final StreakHarness h = StreakHarness();
      addTearDown(h.dispose);
      h.raw(StreakCollections.checkIns, 'not-a-uuid', <String, Object?>{
        'schema': 'lume.other/1',
      });
      expect(h.stats().current, 0);
      expect(h.repo.view().defects, hasLength(1));
    });
  });

  group('idempotent check-in — one per date', () {
    test('marking an already-checked-in day is a no-op, never a duplicate', () {
      final StreakHarness h = StreakHarness();
      addTearDown(h.dispose);
      h.checkIn(kToday);
      final StreakResult<StreakWrite> second = h.repo.checkIn(kToday);
      expect(second.ok, isTrue);
      expect(second.value!.receipt.revision, 0);
      expect(h.repo.view().checkIns, hasLength(1));
    });
  });

  group('current streak — a real calculation, never a literal', () {
    test('is 0 with nothing checked in', () {
      final StreakHarness h = StreakHarness();
      addTearDown(h.dispose);
      expect(h.stats().current, 0);
      expect(h.stats().checkedInToday, isFalse);
    });

    test('counts the consecutive days ending today', () {
      final StreakHarness h = StreakHarness();
      addTearDown(h.dispose);
      h.checkIn(kToday.addDays(-2));
      h.checkIn(kToday.addDays(-1));
      h.checkIn(kToday);
      expect(h.stats().current, 3);
      expect(h.stats().checkedInToday, isTrue);
    });

    test('still counts yesterday\'s run today, before a missed day resets it', () {
      final StreakHarness h = StreakHarness();
      addTearDown(h.dispose);
      h.checkIn(kToday.addDays(-2));
      h.checkIn(kToday.addDays(-1));
      // Nothing logged yet today.
      expect(h.stats().current, 2);
      expect(h.stats().checkedInToday, isFalse);
    });

    test('a gap resets the streak — only the run since the gap counts', () {
      final StreakHarness h = StreakHarness();
      addTearDown(h.dispose);
      h.checkIn(kToday.addDays(-3));
      h.checkIn(kToday.addDays(-2));
      // kToday.addDays(-1) is missing — the gap.
      h.checkIn(kToday);
      expect(h.stats().current, 1);
    });
  });

  group('best streak — the longest run ever, even when not current', () {
    test('outlives a broken run', () {
      final StreakHarness h = StreakHarness();
      addTearDown(h.dispose);
      h.checkIn(kToday.addDays(-10));
      h.checkIn(kToday.addDays(-9));
      h.checkIn(kToday.addDays(-8));
      // Gap, then a fresh single-day run today.
      h.checkIn(kToday);
      final StreakStats s = h.stats();
      expect(s.current, 1);
      expect(s.best, 3);
    });

    test('is never smaller than the current run', () {
      final StreakHarness h = StreakHarness();
      addTearDown(h.dispose);
      h.checkIn(kToday.addDays(-1));
      h.checkIn(kToday);
      final StreakStats s = h.stats();
      expect(s.current, 2);
      expect(s.best, 2);
    });
  });

  group('this month and rate', () {
    test('thisMonth counts only dates in today\'s calendar month', () {
      final StreakHarness h = StreakHarness();
      addTearDown(h.dispose);
      h.checkIn(LumeDate(2026, 8, 31)); // last day of August — excluded
      h.checkIn(LumeDate(2026, 9, 1));
      h.checkIn(LumeDate(2026, 9, 3));
      h.checkIn(kToday); // 7 September
      final StreakStats s = h.stats();
      expect(s.thisMonth, 3);
      // kToday.day == 7 days elapsed so far this month.
      expect(s.rate, closeTo(3 / 7, 1e-9));
    });
  });

  group('milestones — the reference\'s own thresholds', () {
    test('7/14/30/100, done and days-to-go, computed from current', () {
      final StreakStats s = StreakStats.compute(
        checkIns: <LumeDate>{for (int i = 0; i < 7; i++) kToday.addDays(-i)},
        today: kToday,
      );
      expect(s.current, 7);
      expect(s.milestones, hasLength(4));
      expect(s.milestones[0].threshold, 7);
      expect(s.milestones[0].done, isTrue);
      expect(s.milestones[0].inDays, 0);
      expect(s.milestones[1].threshold, 14);
      expect(s.milestones[1].done, isFalse);
      expect(s.milestones[1].inDays, 7);
      expect(s.nextMilestone, 14);
    });

    test('nextMilestone is null once every threshold is passed', () {
      final StreakStats s = StreakStats.compute(
        checkIns: <LumeDate>{for (int i = 0; i < 120; i++) kToday.addDays(-i)},
        today: kToday,
      );
      expect(s.current, 120);
      expect(s.milestones.every((StreakMilestone m) => m.done), isTrue);
      expect(s.nextMilestone, isNull);
    });
  });

  group('heat — the reader\'s own last 35 days, never a random fixture', () {
    test('is 35 days, oldest first, ending today', () {
      final StreakStats s = StreakStats.compute(checkIns: <LumeDate>{}, today: kToday);
      expect(s.heat, hasLength(35));
      expect(s.heat.first.date, kToday.addDays(-34));
      expect(s.heat.last.date, kToday);
    });

    test('marks exactly the reader\'s own checked-in days', () {
      final StreakStats s = StreakStats.compute(
        checkIns: <LumeDate>{kToday, kToday.addDays(-5)},
        today: kToday,
      );
      final int checked = s.heat.where((StreakHeatDay h) => h.checkedIn).length;
      expect(checked, 2);
      expect(s.heat.last.checkedIn, isTrue);
    });
  });

  group('clear', () {
    test('unchecking a checked day removes it', () {
      final StreakHarness h = StreakHarness();
      addTearDown(h.dispose);
      h.checkIn(kToday);
      final StreakResult<StreakWrite> r = h.repo.uncheck(kToday);
      expect(r.ok, isTrue);
      expect(h.stats().checkedInToday, isFalse);
    });

    test('unchecking an already-clear day is a no-op, not a failure', () {
      final StreakHarness h = StreakHarness();
      addTearDown(h.dispose);
      final StreakResult<StreakWrite> r = h.repo.uncheck(kToday);
      expect(r.ok, isTrue);
      expect(r.value!.receipt.revision, 0);
    });

    test('undo restores a cleared day', () {
      final StreakHarness h = StreakHarness();
      addTearDown(h.dispose);
      h.checkIn(kToday);
      final StreakResult<StreakWrite> cleared = h.repo.uncheck(kToday);
      final StreakResult<void> u = h.repo.undo(cleared.value!);
      expect(u.ok, isTrue);
      expect(h.stats().checkedInToday, isTrue);
    });

    test('undo of a no-op clear does nothing and does not fail', () {
      final StreakHarness h = StreakHarness();
      addTearDown(h.dispose);
      final StreakResult<StreakWrite> r = h.repo.uncheck(kToday);
      final StreakResult<void> u = h.repo.undo(r.value!);
      expect(u.ok, isTrue);
    });
  });

  group('Option B — non-durability', () {
    test('the repository reports itself as not durable', () {
      final StreakHarness h = StreakHarness();
      addTearDown(h.dispose);
      expect(h.repo.durable, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/features/fasting/domain/fasting_book.dart';
import 'package:lume/features/fasting/domain/fasting_failure.dart';
import 'package:lume/features/fasting/domain/fasting_model.dart';
import 'package:lume/features/fasting/domain/fasting_repository.dart';

import 'fasting_harness.dart';

void main() {
  group('model and codec', () {
    test('a fast round-trips through its fields', () {
      final FastingHarness h = FastingHarness();
      addTearDown(h.dispose);
      final FastEntry e = h.log(
        kToday,
        kind: FastingKind.voluntary,
        kept: true,
      );
      expect(e.date, kToday);
      expect(e.kind, FastingKind.voluntary);
      expect(e.kept, isTrue);
      expect(e.version, 1);
    });

    test('a missed fast round-trips kept as false, not dropped', () {
      final FastingHarness h = FastingHarness();
      addTearDown(h.dispose);
      final FastEntry e = h.log(kToday, kind: FastingKind.makeup, kept: false);
      expect(e.kind, FastingKind.makeup);
      expect(e.kept, isFalse);
    });

    test('a record of the wrong schema is a defect, not a crash', () {
      final FastingHarness h = FastingHarness();
      addTearDown(h.dispose);
      h.raw('fasting.entry', 'not-a-uuid', <String, Object?>{
        'schema': 'lume.other/1',
      });
      expect(h.repo.view().entries, isEmpty);
      expect(h.repo.view().defects, hasLength(1));
    });
  });

  group('validation', () {
    test('logging two fasts on the same date is refused', () {
      final FastingHarness h = FastingHarness();
      addTearDown(h.dispose);
      h.log(kToday);
      final FastingResult<FastingWrite> r = h.repo.logFast(
        kToday,
        kind: FastingKind.voluntary,
        kept: true,
      );
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'date');
    });

    test("editing a fast to another fast's date is refused", () {
      final FastingHarness h = FastingHarness();
      addTearDown(h.dispose);
      final FastEntry a = h.log(kToday.addDays(-1));
      final FastEntry b = h.log(kToday);
      final FastingResult<FastingWrite> r = h.repo.updateFast(
        b.id,
        date: a.date,
        kind: b.kind,
        kept: b.kept,
        expectVersion: b.version,
      );
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'date');
    });
  });

  group('update', () {
    test(
      'correcting kept from true to false moves it out of the kept count',
      () {
        final FastingHarness h = FastingHarness();
        addTearDown(h.dispose);
        final FastEntry e = h.log(kToday, kept: true);
        final FastingResult<FastingWrite> r = h.repo.updateFast(
          e.id,
          date: e.date,
          kind: e.kind,
          kept: false,
          expectVersion: e.version,
        );
        expect(r.ok, isTrue);
        expect(r.value!.entry!.kept, isFalse);
        expect(h.insights().keptCount, 0);
        expect(h.insights().missedCount, 1);
      },
    );

    test('a stale version is a conflict, not a silent overwrite', () {
      final FastingHarness h = FastingHarness();
      addTearDown(h.dispose);
      final FastEntry e = h.log(kToday);
      h.repo.updateFast(
        e.id,
        date: e.date,
        kind: e.kind,
        kept: false,
        expectVersion: e.version,
      );
      final FastingResult<FastingWrite> r = h.repo.updateFast(
        e.id,
        date: e.date,
        kind: FastingKind.makeup,
        kept: true,
        expectVersion: e.version,
      );
      expect(r.ok, isFalse);
      expect(r.failure!.kind, FastingFailureKind.conflict);
    });
  });

  group('delete and undo', () {
    test('deleting removes the fast', () {
      final FastingHarness h = FastingHarness();
      addTearDown(h.dispose);
      final FastEntry e = h.log(kToday);
      final FastingResult<FastingWrite> r = h.repo.deleteFast(
        e.id,
        expectVersion: e.version,
      );
      expect(r.ok, isTrue);
      expect(h.repo.view().entries, isEmpty);
    });

    test('undo restores a deleted fast', () {
      final FastingHarness h = FastingHarness();
      addTearDown(h.dispose);
      final FastEntry e = h.log(kToday);
      final FastingResult<FastingWrite> deleted = h.repo.deleteFast(
        e.id,
        expectVersion: e.version,
      );
      final FastingResult<void> u = h.repo.undo(deleted.value!);
      expect(u.ok, isTrue);
      expect(h.repo.view().entries.single.date, kToday);
    });

    test('deleting a fast that is not there is not-found, not a crash', () {
      final FastingHarness h = FastingHarness();
      addTearDown(h.dispose);
      final FastEntry e = h.log(kToday);
      h.repo.deleteFast(e.id, expectVersion: e.version);
      final FastingResult<FastingWrite> r = h.repo.deleteFast(
        e.id,
        expectVersion: e.version,
      );
      expect(r.ok, isFalse);
      expect(r.failure!.kind, FastingFailureKind.notFound);
    });
  });

  group('Option B — non-durability', () {
    test('the repository reports itself as not durable', () {
      final FastingHarness h = FastingHarness();
      addTearDown(h.dispose);
      expect(h.repo.durable, isFalse);
    });
  });

  // -------------------------------------------------------------------
  // The derived figures — pure, and tested against concrete logs rather
  // than the reference's fixture. The reference's own `fasting()`
  // (`context.js:335-346`) returns `kept: 8, target: 12, streak: 3,
  // voluntary: 5, obligatory: 3, missed: 1` as six bare literals with a
  // random-seeded heatmap behind them: none of that is reproduced, because
  // none of it is real.
  // -------------------------------------------------------------------
  group('FastingInsights.compute — the reference has no equivalent to match', () {
    test('no fasts logged: nothing to show, nothing invented', () {
      final FastingInsights i = FastingInsights.compute(
        entries: const <FastEntry>[],
        today: kToday,
      );
      expect(i.loggedCount, 0);
      expect(i.keptCount, 0);
      expect(i.missedCount, 0);
      expect(i.currentStreak, 0);
      expect(i.completionRate, isNull);
      expect(i.recent, isEmpty);
      expect(i.heat, hasLength(FastingInsights.heatWindowDays));
      expect(
        i.heat.every((FastingHeatDay d) => d.state == FastingDayState.none),
        isTrue,
      );
    });

    test('one kept voluntary fast this month', () {
      final FastingHarness h = FastingHarness();
      addTearDown(h.dispose);
      h.log(kToday, kind: FastingKind.voluntary, kept: true);
      final FastingInsights i = h.insights(kToday);
      expect(i.loggedCount, 1);
      expect(i.keptCount, 1);
      expect(i.keptThisMonth, 1);
      expect(i.voluntaryKept, 1);
      expect(i.makeupKept, 0);
      expect(i.missedCount, 0);
      expect(i.currentStreak, 1);
      expect(i.completionRate, 1.0);
    });

    test(
      'a fast logged in a different month does not count toward this month',
      () {
        final FastingHarness h = FastingHarness();
        addTearDown(h.dispose);
        h.log(LumeDate(2026, 8, 15), kind: FastingKind.voluntary, kept: true);
        final FastingInsights i = h.insights(kToday); // kToday is in September
        expect(i.keptCount, 1);
        expect(i.keptThisMonth, 0);
      },
    );

    test('voluntary and makeup kept fasts are counted separately', () {
      final FastingHarness h = FastingHarness();
      addTearDown(h.dispose);
      h.log(d(9, 1), kind: FastingKind.voluntary, kept: true);
      h.log(d(9, 2), kind: FastingKind.makeup, kept: true);
      h.log(d(9, 3), kind: FastingKind.makeup, kept: true);
      final FastingInsights i = h.insights(kToday);
      expect(i.voluntaryKept, 1);
      expect(i.makeupKept, 2);
      expect(i.keptCount, 3);
    });

    test(
      'a missed fast counts toward missed, never invented as the complement of kept',
      () {
        final FastingHarness h = FastingHarness();
        addTearDown(h.dispose);
        h.log(d(9, 1), kept: true);
        h.log(d(9, 2), kept: false);
        h.log(d(9, 3), kept: false);
        final FastingInsights i = h.insights(kToday);
        expect(i.keptCount, 1);
        expect(i.missedCount, 2);
        expect(i.completionRate, closeTo(1 / 3, 1e-9));
      },
    );

    test(
      'the streak is the run of consecutive kept entries ending at the most recent log',
      () {
        final FastingHarness h = FastingHarness();
        addTearDown(h.dispose);
        h.log(d(9, 1), kept: true);
        h.log(
          d(9, 4),
          kept: true,
        ); // not calendar-adjacent — a voluntary fast is not daily
        h.log(d(9, 6), kept: true);
        final FastingInsights i = h.insights(kToday);
        expect(i.currentStreak, 3);
      },
    );

    test(
      'a missed entry breaks the streak even when kept entries follow it earlier',
      () {
        final FastingHarness h = FastingHarness();
        addTearDown(h.dispose);
        h.log(d(9, 1), kept: true);
        h.log(d(9, 2), kept: true);
        h.log(d(9, 3), kept: false);
        h.log(d(9, 4), kept: true);
        final FastingInsights i = h.insights(kToday);
        // Most recent is kept, but the day before it was missed.
        expect(i.currentStreak, 1);
      },
    );

    test(
      'the streak is zero when the most recently logged fast was missed',
      () {
        final FastingHarness h = FastingHarness();
        addTearDown(h.dispose);
        h.log(d(9, 1), kept: true);
        h.log(d(9, 2), kept: false);
        final FastingInsights i = h.insights(kToday);
        expect(i.currentStreak, 0);
      },
    );

    test('recent lists every logged entry, most recent date first', () {
      final FastingHarness h = FastingHarness();
      addTearDown(h.dispose);
      h.log(d(9, 1), kept: true);
      h.log(d(9, 5), kept: false);
      h.log(d(9, 3), kept: true);
      final FastingInsights i = h.insights(kToday);
      expect(i.recent.map((FastEntry e) => e.date), <LumeDate>[
        d(9, 5),
        d(9, 3),
        d(9, 1),
      ]);
    });

    test(
      'the heat window covers the trailing 30 days ending today, over real entries only',
      () {
        final FastingHarness h = FastingHarness();
        addTearDown(h.dispose);
        h.log(kToday, kept: true);
        h.log(kToday.addDays(-2), kept: false);
        final FastingInsights i = h.insights(kToday);
        expect(i.heat.length, FastingInsights.heatWindowDays);
        expect(i.heat.last.date, kToday);
        expect(i.heat.last.state, FastingDayState.kept);
        final FastingHeatDay missedDay = i.heat.firstWhere(
          (FastingHeatDay d) => d.date == kToday.addDays(-2),
        );
        expect(missedDay.state, FastingDayState.missed);
        final FastingHeatDay untouched = i.heat.firstWhere(
          (FastingHeatDay d) => d.date == kToday.addDays(-1),
        );
        expect(untouched.state, FastingDayState.none);
      },
    );
  });
}

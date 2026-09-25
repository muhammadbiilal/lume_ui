import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/cycle/domain/cycle_book.dart';
import 'package:lume/features/cycle/domain/cycle_failure.dart';
import 'package:lume/features/cycle/domain/cycle_model.dart';
import 'package:lume/features/cycle/domain/cycle_repository.dart';

import 'cycle_harness.dart';

void main() {
  group('model and codec', () {
    test('a period round-trips through its fields', () {
      final CycleHarness h = CycleHarness();
      addTearDown(h.dispose);
      final CyclePeriod p = h.log(kToday);
      expect(p.startDate, kToday);
      expect(p.endDate, isNull);
      expect(p.ongoing, isTrue);
      expect(p.version, 1);
    });

    test('an end date round-trips and the period is no longer ongoing', () {
      final CycleHarness h = CycleHarness();
      addTearDown(h.dispose);
      final CyclePeriod p = h.log(kToday, end: kToday.addDays(5));
      expect(p.endDate, kToday.addDays(5));
      expect(p.ongoing, isFalse);
    });

    test('a record of the wrong schema is a defect, not a crash', () {
      final CycleHarness h = CycleHarness();
      addTearDown(h.dispose);
      h.raw('cycle.period', 'not-a-uuid', <String, Object?>{
        'schema': 'lume.other/1',
      });
      expect(h.repo.view().periods, isEmpty);
      expect(h.repo.view().defects, hasLength(1));
    });
  });

  group('validation', () {
    test('an end before the start is refused', () {
      final CycleHarness h = CycleHarness();
      addTearDown(h.dispose);
      final CycleResult<CycleWrite> r = h.repo.logPeriod(
        kToday,
        end: kToday.addDays(-1),
      );
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'end');
    });

    test('logging two periods on the same start date is refused', () {
      final CycleHarness h = CycleHarness();
      addTearDown(h.dispose);
      h.log(kToday);
      final CycleResult<CycleWrite> r = h.repo.logPeriod(kToday);
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'start');
    });

    test('editing a period to another period\'s start date is refused', () {
      final CycleHarness h = CycleHarness();
      addTearDown(h.dispose);
      final CyclePeriod a = h.log(kToday.addDays(-28));
      final CyclePeriod b = h.log(kToday);
      final CycleResult<CycleWrite> r = h.repo.updatePeriod(
        b.id,
        start: a.startDate,
        expectVersion: b.version,
      );
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'start');
    });
  });

  group('update', () {
    test('closing an ongoing period sets its end date', () {
      final CycleHarness h = CycleHarness();
      addTearDown(h.dispose);
      final CyclePeriod p = h.log(kToday);
      final CycleResult<CycleWrite> r = h.repo.updatePeriod(
        p.id,
        start: p.startDate,
        endDate: kToday.addDays(5),
        expectVersion: p.version,
      );
      expect(r.ok, isTrue);
      expect(r.value!.period!.endDate, kToday.addDays(5));
      expect(r.value!.period!.ongoing, isFalse);
    });

    test('correcting a start date moves it', () {
      final CycleHarness h = CycleHarness();
      addTearDown(h.dispose);
      final CyclePeriod p = h.log(kToday);
      final CycleResult<CycleWrite> r = h.repo.updatePeriod(
        p.id,
        start: kToday.addDays(-1),
        expectVersion: p.version,
      );
      expect(r.ok, isTrue);
      expect(r.value!.period!.startDate, kToday.addDays(-1));
    });

    test('a stale version is a conflict, not a silent overwrite', () {
      final CycleHarness h = CycleHarness();
      addTearDown(h.dispose);
      final CyclePeriod p = h.log(kToday);
      // Someone/something else updates it first.
      h.repo.updatePeriod(
        p.id,
        start: p.startDate,
        endDate: kToday.addDays(3),
        expectVersion: p.version,
      );
      // This caller still holds the pre-update version.
      final CycleResult<CycleWrite> r = h.repo.updatePeriod(
        p.id,
        start: kToday.addDays(1),
        expectVersion: p.version,
      );
      expect(r.ok, isFalse);
      expect(r.failure!.kind, CycleFailureKind.conflict);
    });
  });

  group('delete and undo', () {
    test('deleting removes the period', () {
      final CycleHarness h = CycleHarness();
      addTearDown(h.dispose);
      final CyclePeriod p = h.log(kToday);
      final CycleResult<CycleWrite> r = h.repo.deletePeriod(
        p.id,
        expectVersion: p.version,
      );
      expect(r.ok, isTrue);
      expect(h.repo.view().periods, isEmpty);
    });

    test('undo restores a deleted period', () {
      final CycleHarness h = CycleHarness();
      addTearDown(h.dispose);
      final CyclePeriod p = h.log(kToday);
      final CycleResult<CycleWrite> deleted = h.repo.deletePeriod(
        p.id,
        expectVersion: p.version,
      );
      final CycleResult<void> u = h.repo.undo(deleted.value!);
      expect(u.ok, isTrue);
      expect(h.repo.view().periods.single.startDate, kToday);
    });

    test('deleting a period that is not there is not-found, not a crash', () {
      final CycleHarness h = CycleHarness();
      addTearDown(h.dispose);
      final CyclePeriod p = h.log(kToday);
      h.repo.deletePeriod(p.id, expectVersion: p.version);
      final CycleResult<CycleWrite> r = h.repo.deletePeriod(
        p.id,
        expectVersion: p.version,
      );
      expect(r.ok, isFalse);
      expect(r.failure!.kind, CycleFailureKind.notFound);
    });
  });

  group('Option B — non-durability', () {
    test('the repository reports itself as not durable', () {
      final CycleHarness h = CycleHarness();
      addTearDown(h.dispose);
      expect(h.repo.durable, isFalse);
    });
  });

  // -------------------------------------------------------------------
  // The prediction math — pure, and tested against concrete date
  // sequences rather than the reference's fixture. The reference's own
  // `cycle()` computes `(new Date().getDate() % 28) + 1` against a fixed
  // 28: none of that is a real cycle day, so none of it is reproduced.
  // -------------------------------------------------------------------
  group('CycleInsights.compute — the reference has no equivalent to match', () {
    test('no periods logged: nothing to show, nothing invented', () {
      final CycleInsights i = CycleInsights.compute(
        periods: const <CyclePeriod>[],
        today: kToday,
      );
      expect(i.loggedCount, 0);
      expect(i.currentPeriod, isNull);
      expect(i.currentDay, isNull);
      expect(i.averageLength, isNull);
      expect(i.predictedNextStart, isNull);
      expect(i.phase, isNull);
      expect(i.history, isEmpty);
    });

    test(
      'one period logged: a current day, but no average and no prediction',
      () {
        final CycleHarness h = CycleHarness();
        addTearDown(h.dispose);
        h.log(kToday.addDays(-4));
        final CycleInsights i = h.insights(kToday);
        expect(i.loggedCount, 1);
        expect(i.currentDay, 5); // day 1 is the start date itself
        expect(i.averageLength, isNull);
        expect(i.predictedNextStart, isNull);
        expect(i.phase, isNull);
        expect(i.history, isEmpty);
      },
    );

    test(
      'a start dated after "today" leaves currentDay unknown, not negative',
      () {
        final CyclePeriod future = CyclePeriod(
          id: LumeRecordId.generate(),
          startDate: kToday.addDays(3),
          createdAt: DateTime.utc(2026),
        );
        final CycleInsights i = CycleInsights.compute(
          periods: <CyclePeriod>[future],
          today: kToday,
        );
        expect(i.currentDay, isNull);
      },
    );

    test(
      'two periods 28 days apart: the average, the estimate and the history are all real',
      () {
        final CycleHarness h = CycleHarness();
        addTearDown(h.dispose);
        final LumeDate first = LumeDate(2026, 6, 1);
        final LumeDate second = LumeDate(2026, 6, 29); // +28
        h.log(first);
        h.log(second);
        final LumeDate today = second.addDays(2);
        final CycleInsights i = h.insights(today);

        expect(i.loggedCount, 2);
        expect(i.averageLength, 28.0);
        expect(i.averageLengthRounded, 28);
        expect(i.predictedNextStart, second.addDays(28));
        expect(i.daysUntilNext, today.daysUntil(second.addDays(28)));
        expect(i.isOverdue, isFalse);
        expect(i.history, hasLength(1));
        expect(i.history.single.start, first);
        expect(i.history.single.length, 28);
      },
    );

    test(
      'three cycles of uneven length: the mean of the real intervals, not a round number',
      () {
        final CycleHarness h = CycleHarness();
        addTearDown(h.dispose);
        final LumeDate p1 = LumeDate(2026, 6, 1);
        final LumeDate p2 = LumeDate(2026, 6, 29); // +28
        final LumeDate p3 = LumeDate(2026, 7, 28); // +29
        h.log(p1);
        h.log(p2);
        h.log(p3);
        final LumeDate today = LumeDate(2026, 8, 1);
        final CycleInsights i = h.insights(today);

        expect(i.averageLength, 28.5);
        // 28.5 rounds to 29 (ties round toward +infinity).
        expect(i.predictedNextStart, p3.addDays(29));
        expect(i.predictedNextStart, LumeDate(2026, 8, 26));
        expect(i.currentDay, p3.daysUntil(today) + 1);
        expect(i.history, hasLength(2));
        // Most recent completed cycle first.
        expect(i.history.first.start, p2);
        expect(i.history.first.length, 29);
        expect(i.history.last.start, p1);
        expect(i.history.last.length, 28);
      },
    );

    test(
      'overdue: a predicted date already passed is a negative countdown, not silence',
      () {
        final CycleHarness h = CycleHarness();
        addTearDown(h.dispose);
        final LumeDate p1 = LumeDate(2026, 6, 1);
        final LumeDate p2 = LumeDate(2026, 6, 29); // +28
        h.log(p1);
        h.log(p2);
        final LumeDate predicted = p2.addDays(28);
        final LumeDate today = predicted.addDays(3);
        final CycleInsights i = h.insights(today);

        expect(i.isOverdue, isTrue);
        expect(i.overdueByDays, 3);
        expect(i.daysUntilNext, -3);
      },
    );

    test(
      'duplicate or out-of-order spans never poison the average (defensive, not reachable via the repository)',
      () {
        final CyclePeriod a = CyclePeriod(
          id: LumeRecordId.generate(),
          startDate: LumeDate(2026, 6, 1),
          createdAt: DateTime.utc(2026),
        );
        final CyclePeriod b = CyclePeriod(
          id: LumeRecordId.generate(),
          startDate: LumeDate(2026, 6, 1), // same day as `a`
          createdAt: DateTime.utc(2026),
        );
        final CycleInsights i = CycleInsights.compute(
          periods: <CyclePeriod>[a, b],
          today: LumeDate(2026, 6, 10),
        );
        expect(i.averageLength, isNull);
        expect(i.history, isEmpty);
      },
    );
  });

  group(
    'CycleInsights.phaseFor — the reference\'s own day <= 5/13/16 thresholds, scaled',
    () {
      test(
        'at the reference\'s own length (28), the thresholds are exactly its own',
        () {
          expect(CycleInsights.phaseFor(5, 28), CyclePhase.menstrual);
          expect(CycleInsights.phaseFor(6, 28), CyclePhase.follicular);
          expect(CycleInsights.phaseFor(13, 28), CyclePhase.follicular);
          expect(CycleInsights.phaseFor(14, 28), CyclePhase.ovulation);
          expect(CycleInsights.phaseFor(16, 28), CyclePhase.ovulation);
          expect(CycleInsights.phaseFor(17, 28), CyclePhase.luteal);
          expect(CycleInsights.phaseFor(28, 28), CyclePhase.luteal);
        },
      );

      test('a shorter real average scales the thresholds proportionally', () {
        // 5*14/28 = 2.5 -> 3; 13*14/28 = 6.5 -> 7; 16*14/28 = 8 -> 8.
        expect(CycleInsights.phaseFor(3, 14), CyclePhase.menstrual);
        expect(CycleInsights.phaseFor(4, 14), CyclePhase.follicular);
        expect(CycleInsights.phaseFor(7, 14), CyclePhase.follicular);
        expect(CycleInsights.phaseFor(8, 14), CyclePhase.ovulation);
        expect(CycleInsights.phaseFor(9, 14), CyclePhase.luteal);
      });

      test(
        'a day past the average length still resolves — overdue, not out of range',
        () {
          expect(CycleInsights.phaseFor(40, 28), CyclePhase.luteal);
        },
      );
    },
  );
}

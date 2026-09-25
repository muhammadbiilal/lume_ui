import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/features/pregnancy/domain/pregnancy_failure.dart';
import 'package:lume/features/pregnancy/domain/pregnancy_maths.dart';
import 'package:lume/features/pregnancy/domain/pregnancy_model.dart';
import 'package:lume/features/pregnancy/domain/pregnancy_repository.dart';

import 'pregnancy_harness.dart';

void main() {
  final LumeDate lmp = LumeDate(2026, 1, 5);

  group('LumePregnancy.of — gestational age in completed weeks', () {
    test('the LMP date itself is week 0, day 0, trimester 1', () {
      final LumePregnancy p = LumePregnancy.of(lmp, lmp);
      expect(p.daysPregnant, 0);
      expect(p.week, 0);
      expect(p.trimester, 1);
      expect(p.dueDate, lmp.addDays(280));
      expect(p.daysUntilDue, 280);
      expect(p.overdue, isFalse);
      expect(p.progress, 0.0);
    });

    test('day 6 is still week 0 — the day before the boundary', () {
      final LumePregnancy p = LumePregnancy.of(lmp, lmp.addDays(6));
      expect(p.daysPregnant, 6);
      expect(p.week, 0);
    });

    test('day 7 turns over to week 1', () {
      final LumePregnancy p = LumePregnancy.of(lmp, lmp.addDays(7));
      expect(p.daysPregnant, 7);
      expect(p.week, 1);
    });

    test('very early: day 1 of the cycle', () {
      final LumePregnancy p = LumePregnancy.of(lmp, lmp.addDays(1));
      expect(p.week, 0);
      expect(p.trimester, 1);
    });

    test('week 13 (day 91–97) is the last week of the first trimester', () {
      final LumePregnancy p = LumePregnancy.of(lmp, lmp.addDays(91));
      expect(p.week, 13);
      expect(p.trimester, 1);
    });

    test('week 14 (day 98) opens the second trimester', () {
      final LumePregnancy p = LumePregnancy.of(lmp, lmp.addDays(98));
      expect(p.week, 14);
      expect(p.trimester, 2);
    });

    test('week 27 (day 189–195) is the last week of the second trimester', () {
      final LumePregnancy p = LumePregnancy.of(lmp, lmp.addDays(189));
      expect(p.week, 27);
      expect(p.trimester, 2);
    });

    test('week 28 (day 196) opens the third trimester', () {
      final LumePregnancy p = LumePregnancy.of(lmp, lmp.addDays(196));
      expect(p.week, 28);
      expect(p.trimester, 3);
    });

    test('day 279 — one day before the due date', () {
      final LumePregnancy p = LumePregnancy.of(lmp, lmp.addDays(279));
      expect(p.week, 39);
      expect(p.daysUntilDue, 1);
      expect(p.overdue, isFalse);
    });

    test('day 280 — the due date itself is exactly week 40, 100% progress', () {
      final LumePregnancy p = LumePregnancy.of(lmp, lmp.addDays(280));
      expect(p.week, 40);
      expect(p.trimester, 3);
      expect(p.daysUntilDue, 0);
      expect(p.overdue, isFalse);
      expect(p.progress, 1.0);
    });

    test('very late: 7 days overdue, progress stays capped at 100%', () {
      final LumePregnancy p = LumePregnancy.of(lmp, lmp.addDays(287));
      expect(p.week, 41);
      expect(p.daysUntilDue, -7);
      expect(p.overdue, isTrue);
      expect(p.progress, 1.0);
    });

    test(
      'milestones carry real dates for this LMP and flip to done in order',
      () {
        final LumePregnancy early = LumePregnancy.of(lmp, lmp.addDays(90));
        expect(
          early.milestones.map((LumePregnancyMilestone m) => m.week),
          <int>[12, 20, 28, 37],
        );
        expect(early.milestones[0].date, lmp.addDays(12 * 7));
        // Day 90 is week 12 (90 ~/ 7 == 12), so the first milestone is done.
        expect(early.milestones[0].done, isTrue);
        final LumePregnancy late = LumePregnancy.of(lmp, lmp.addDays(280));
        expect(
          late.milestones.every((LumePregnancyMilestone m) => m.done),
          isTrue,
        );
        final LumePregnancy fresh = LumePregnancy.of(lmp, lmp);
        expect(
          fresh.milestones.every((LumePregnancyMilestone m) => m.done),
          isFalse,
        );
      },
    );
  });

  group('LumePregnancyValidity.check', () {
    test('a future last period is refused', () {
      final LumeDate today = LumeDate(2026, 9, 7);
      expect(
        LumePregnancyValidity.check(today.addDays(1), today),
        LumePregnancyInvalid.future,
      );
    });

    test('today itself is a valid last-period date', () {
      final LumeDate today = LumeDate(2026, 9, 7);
      expect(LumePregnancyValidity.check(today, today), isNull);
    });

    test('exactly the plausible-range boundary is accepted', () {
      final LumeDate today = LumeDate(2026, 9, 7);
      expect(
        LumePregnancyValidity.check(
          today.addDays(-LumePregnancy.maxPlausibleDays),
          today,
        ),
        isNull,
      );
    });

    test('one day past the plausible range is refused as too old', () {
      final LumeDate today = LumeDate(2026, 9, 7);
      expect(
        LumePregnancyValidity.check(
          today.addDays(-LumePregnancy.maxPlausibleDays - 1),
          today,
        ),
        LumePregnancyInvalid.tooOld,
      );
    });
  });

  group('model and codec', () {
    test('a profile round-trips through its fields', () {
      final PregnancyHarness h = PregnancyHarness();
      addTearDown(h.dispose);
      final PregnancyResult<PregnancyWrite> r = h.set(LumeDate(2026, 6, 1));
      expect(r.ok, isTrue);
      final PregnancyProfile p = r.value!.profile!;
      expect(p.lmp, LumeDate(2026, 6, 1));
      expect(p.version, 1);
    });

    test('a record of the wrong schema is a defect, not a crash', () {
      final PregnancyHarness h = PregnancyHarness();
      addTearDown(h.dispose);
      h.raw(PregnancyCollections.profile, 'not-a-uuid', <String, Object?>{
        'schema': 'lume.other/1',
      });
      final PregnancySnapshot s = h.repo.view();
      expect(s.profile, isNull);
      expect(s.defect, isNotNull);
    });
  });

  group('setLmp — at most one record', () {
    test('the first set creates a record', () {
      final PregnancyHarness h = PregnancyHarness();
      addTearDown(h.dispose);
      h.set(LumeDate(2026, 6, 1));
      expect(h.repo.view().profile!.lmp, LumeDate(2026, 6, 1));
    });

    test('setting again replaces the same record, never a second one', () {
      final PregnancyHarness h = PregnancyHarness();
      addTearDown(h.dispose);
      final PregnancyProfile first = h
          .set(LumeDate(2026, 6, 1))
          .value!
          .profile!;
      final PregnancyProfile second = h
          .set(LumeDate(2026, 6, 8))
          .value!
          .profile!;

      expect(second.id, first.id);
      expect(second.version, first.version + 1);
      expect(h.repo.view().profile!.lmp, LumeDate(2026, 6, 8));
    });

    test('a future last-period date is refused, nothing stored', () {
      final PregnancyHarness h = PregnancyHarness();
      addTearDown(h.dispose);
      final PregnancyResult<PregnancyWrite> r = h.set(kToday.addDays(1));
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'lmp');
      expect(r.failure!.reason, 'future');
      expect(h.repo.view().profile, isNull);
    });

    test('an implausibly old last-period date is refused', () {
      final PregnancyHarness h = PregnancyHarness();
      addTearDown(h.dispose);
      final PregnancyResult<PregnancyWrite> r = h.set(
        kToday.addDays(-LumePregnancy.maxPlausibleDays - 1),
      );
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'lmp');
      expect(r.failure!.reason, 'tooOld');
    });
  });

  group('clear', () {
    test('clearing a set date removes it', () {
      final PregnancyHarness h = PregnancyHarness();
      addTearDown(h.dispose);
      h.set(LumeDate(2026, 6, 1));
      final PregnancyResult<PregnancyWrite> r = h.repo.clear();
      expect(r.ok, isTrue);
      expect(h.repo.view().profile, isNull);
    });

    test('clearing when nothing is set is a no-op, not a failure', () {
      final PregnancyHarness h = PregnancyHarness();
      addTearDown(h.dispose);
      final PregnancyResult<PregnancyWrite> r = h.repo.clear();
      expect(r.ok, isTrue);
      expect(r.value!.receipt.revision, 0);
    });

    test('undo restores a cleared date', () {
      final PregnancyHarness h = PregnancyHarness();
      addTearDown(h.dispose);
      h.set(LumeDate(2026, 6, 1));
      final PregnancyResult<PregnancyWrite> cleared = h.repo.clear();
      final PregnancyResult<void> u = h.repo.undo(cleared.value!);
      expect(u.ok, isTrue);
      expect(h.repo.view().profile!.lmp, LumeDate(2026, 6, 1));
    });

    test('undo of a no-op clear does nothing and does not fail', () {
      final PregnancyHarness h = PregnancyHarness();
      addTearDown(h.dispose);
      final PregnancyResult<PregnancyWrite> r = h.repo.clear();
      final PregnancyResult<void> u = h.repo.undo(r.value!);
      expect(u.ok, isTrue);
    });
  });

  group('Option B — non-durability', () {
    test('the repository reports itself as not durable', () {
      final PregnancyHarness h = PregnancyHarness();
      addTearDown(h.dispose);
      expect(h.repo.durable, isFalse);
    });
  });
}

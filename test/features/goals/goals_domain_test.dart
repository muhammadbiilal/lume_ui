import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/features/goals/domain/goals_book.dart';
import 'package:lume/features/goals/domain/goals_failure.dart';
import 'package:lume/features/goals/domain/goals_model.dart';
import 'package:lume/features/goals/domain/goals_repository.dart';

import 'goals_harness.dart';

void main() {
  group('model and codec', () {
    test('a goal round-trips through its fields', () {
      final GoalsHarness h = GoalsHarness();
      addTearDown(h.dispose);
      final Goal g = h.add(name: 'Umrah trip', note: 'By Ramadan', target: rs(240000));
      expect(g.name, 'Umrah trip');
      expect(g.note, 'By Ramadan');
      expect(g.target, rs(240000));
      expect(g.state, GoalState.active);
      expect(g.version, 1);
      h.expectSound();
    });

    test('a zero target is refused', () {
      final GoalsHarness h = GoalsHarness();
      addTearDown(h.dispose);
      final GoalsResult<GoalsWrite> r = h.tryAdd(target: rs(0));
      expect(r.ok, isFalse);
      expect(r.failure!.kind, GoalsFailureKind.validation);
      expect(r.failure!.field, 'target');
    });

    test('an empty name is refused', () {
      final GoalsHarness h = GoalsHarness();
      addTearDown(h.dispose);
      final GoalsResult<GoalsWrite> r = h.tryAdd(name: '   ');
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'name');
    });

    test('a record of the wrong schema is a defect, not a crash', () {
      final GoalsHarness h = GoalsHarness();
      addTearDown(h.dispose);
      h.raw(GoalsCollections.goals, 'not-a-uuid', <String, Object?>{
        'schema': 'lume.other/1',
      });
      final GoalsBook b = h.book();
      expect(b.defects, hasLength(1));
      expect(b.defects.first.reason, 'schema');
    });
  });

  group('derived figures', () {
    test('saved is the sum of active contributions only', () {
      final GoalsHarness h = GoalsHarness();
      addTearDown(h.dispose);
      final Goal g = h.add(target: rs(1000));
      final GoalContribution c1 = h.contribute(g.id, rs(300));
      h.contribute(g.id, rs(200));
      h.repo.setContributionVoided(c1.id, true, version: c1.version);

      final GoalView v = h.view(g.id);
      expect(v.saved, rs(200));
      expect(v.remaining, rs(800));
      expect(v.pct, closeTo(0.2, 1e-9));
      expect(v.reached, isFalse);
      h.expectSound();
    });

    test('remaining never goes negative when over-saved', () {
      final GoalsHarness h = GoalsHarness();
      addTearDown(h.dispose);
      final Goal g = h.add(target: rs(1000));
      h.contribute(g.id, rs(1500));
      final GoalView v = h.view(g.id);
      expect(v.remaining, LumeMoney.zero(pkr));
      expect(v.reached, isTrue);
      expect(v.pct, closeTo(1.5, 1e-9));
    });

    test('a contribution to a closed goal is refused', () {
      final GoalsHarness h = GoalsHarness();
      addTearDown(h.dispose);
      final Goal g = h.add(target: rs(1000));
      h.repo.setState(g.id, GoalState.abandoned, version: g.version);
      final GoalsResult<GoalsWrite> r = h.repo.addContribution(g.id, rs(100), kToday);
      expect(r.ok, isFalse);
      expect(r.failure!.kind, GoalsFailureKind.closed);
    });

    test('a mismatched contribution currency is refused, not converted', () {
      final GoalsHarness h = GoalsHarness();
      addTearDown(h.dispose);
      final Goal g = h.add(target: rs(1000));
      final GoalsResult<GoalsWrite> r = h.repo.addContribution(
        g.id,
        dollars(10),
        kToday,
      );
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'amount');
      expect(r.failure!.reason, 'currency');
    });

    test('the aggregate summary counts only active goals', () {
      final GoalsHarness h = GoalsHarness();
      addTearDown(h.dispose);
      final Goal a = h.add(name: 'A', target: rs(1000));
      final Goal b = h.add(name: 'B', target: rs(2000));
      h.contribute(a.id, rs(500));
      h.contribute(b.id, rs(1000));
      h.repo.setState(b.id, GoalState.completed, version: b.version);

      final GoalsBook book = h.book();
      final GoalsCurrencySummary s = book.summary(pkr);
      expect(s.activeGoals, 1);
      expect(s.saved, rs(500));
      expect(s.target, rs(1000));
      expect(s.ratio, closeTo(0.5, 1e-9));
    });

    test('nextComplete is the active goal closest to its target', () {
      final GoalsHarness h = GoalsHarness();
      addTearDown(h.dispose);
      final Goal a = h.add(name: 'A', target: rs(1000));
      final Goal b = h.add(name: 'B', target: rs(1000));
      h.contribute(a.id, rs(900));
      h.contribute(b.id, rs(100));

      final GoalsCurrencySummary s = h.book().summary(pkr);
      expect(s.nextComplete?.goal.id, a.id);
    });

    test('this month sums only contributions in the reader\'s calendar month', () {
      final GoalsHarness h = GoalsHarness();
      addTearDown(h.dispose);
      final Goal g = h.add(target: rs(10000));
      h.contribute(g.id, rs(300), kToday);
      h.contribute(g.id, rs(700), d(8, 1)); // last month

      final GoalsCurrencySummary s = h.book(kToday).summary(pkr);
      expect(s.thisMonth, rs(300));
    });

    test('projected months is null before a month of history exists', () {
      final GoalsHarness h = GoalsHarness();
      addTearDown(h.dispose);
      final Goal g = h.add(target: rs(1000), targetDate: d(12, 1));
      h.contribute(g.id, rs(100));
      final GoalView v = h.view(g.id, kToday);
      expect(v.projectedMonths, isNull);
    });

    test('projected months is real once a month of pace exists', () {
      final GoalsHarness h = GoalsHarness();
      addTearDown(h.dispose);
      // Created in July, 300 saved by September: two full months of pace.
      h.clock = DateTime.utc(2026, 7, 7, 10);
      final Goal g = h.add(target: rs(1000), targetDate: d(12, 1));
      h.contribute(g.id, rs(300), d(9, 1));
      final GoalView v = h.view(g.id, kToday);
      // pace = 300 / 2 months = 150/month; remaining 700 -> ceil(700/150) = 5
      expect(v.projectedMonths, 5);
    });

    test('monthlyHistory is real and zero-filled, never the reference\'s literal array', () {
      final GoalsHarness h = GoalsHarness();
      addTearDown(h.dispose);
      final Goal g = h.add(target: rs(10000));
      h.contribute(g.id, rs(300), kToday);

      final List<GoalsMonth>? months = h.book(kToday).months(pkr, count: 6);
      expect(months, isNotNull);
      expect(months!.length, 6);
      expect(months.last.total, rs(300));
      expect(months.first.total, LumeMoney.zero(pkr));
    });
  });

  group('delete and undo', () {
    test('deleting a goal removes its contributions too', () {
      final GoalsHarness h = GoalsHarness();
      addTearDown(h.dispose);
      final Goal g = h.add(target: rs(1000));
      h.contribute(g.id, rs(100));
      final GoalsResult<GoalsWrite> r = h.repo.deleteGoal(g.id, version: g.version);
      expect(r.ok, isTrue);
      expect(h.book().goals, isEmpty);
    });

    test('undo restores a deleted goal and its contribution', () {
      final GoalsHarness h = GoalsHarness();
      addTearDown(h.dispose);
      final Goal g = h.add(target: rs(1000));
      h.contribute(g.id, rs(100));
      final GoalsResult<GoalsWrite> del = h.repo.deleteGoal(g.id, version: g.version);
      final GoalsResult<void> u = h.repo.undo(del.value!);
      expect(u.ok, isTrue);
      expect(h.view(g.id).saved, rs(100));
    });
  });

  group('Option B — non-durability', () {
    test('the repository reports itself as not durable', () {
      final GoalsHarness h = GoalsHarness();
      addTearDown(h.dispose);
      expect(h.repo.durable, isFalse);
    });
  });
}

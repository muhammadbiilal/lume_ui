/// Baby Budget's rules, against the records themselves
/// (`BABY_BUDGET_PROPOSAL.md` §5–§9). Every worked example of §6 is here,
/// in minor units, and so is every one of the six corrections the
/// proposal was approved with.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/babybudget/domain/babybudget_book.dart';
import 'package:lume/features/babybudget/domain/babybudget_failure.dart';
import 'package:lume/features/babybudget/domain/babybudget_model.dart';
import 'package:lume/features/babybudget/domain/babybudget_repository.dart';

import 'babybudget_harness.dart';

void main() {
  late BabyBudgetHarness h;

  setUp(() => h = BabyBudgetHarness());
  tearDown(() => h.dispose());

  group('Example A — the reference month, entered', () {
    test('the parts add to the whole, and the ratio is 82%', () {
      final BabyBudget b = h.referenceMonth();
      final BabyBudgetView v = h.view(b.id);
      expect(v.plan!.minor, 3900000);
      expect(v.thisMonth!.minor, 3200000);
      expect(v.ratio, 82);
      expect(v.overBy, isNull);
      // The slices add to the month exactly.
      final int parts = v.slices.fold<int>(
        0,
        (int a, BabyCategoryView s) => a + s.spent.minor,
      );
      expect(parts, 3200000);
      h.expectSound();
    });

    test('spent to date is every month, not just this one', () {
      final BabyBudget b = h.referenceMonth();
      expect(
        h.spend(b.id, 4000, category: 'Health', on: d(8, 10)).failure,
        isNull,
      );
      final BabyBudgetView v = h.view(b.id);
      expect(v.thisMonth!.minor, 3200000, reason: 'September alone');
      expect(v.spentToDate.minor, 3600000, reason: 'August too');
      expect(v.spentIn(d(8, 1)).minor, 400000);
      h.expectSound();
    });
  });

  group('Example B — the donut adds to 100 (correction 5)', () {
    test('largest remainder in integers: 37, 25, 22, 16', () {
      final BabyBudget b = h.referenceMonth();
      final List<BabyCategoryView> slices = h.view(b.id).slices;
      expect(
        <String>[for (final BabyCategoryView s in slices) s.name],
        <String>['Nappies & wipes', 'Formula & food', 'Clothing', 'Health'],
      );
      expect(
        <int>[for (final BabyCategoryView s in slices) s.share],
        <int>[37, 25, 22, 16],
        reason: 'not 38/25/22/16, which would make 101',
      );
      expect(
        slices.fold<int>(0, (int a, BabyCategoryView s) => a + s.share),
        100,
      );
    });

    test('a three-way tie is broken by the reader\'s order, and still '
        'totals 100', () {
      final BabyBudget b = h.add(
        plan: rs(9000),
        categories: <BabyCategoryDraft>[
          const BabyCategoryDraft(name: 'One'),
          const BabyCategoryDraft(name: 'Two'),
          const BabyCategoryDraft(name: 'Three'),
        ],
      );
      for (final String name in <String>['One', 'Two', 'Three']) {
        expect(h.spend(b.id, 1000, category: name).failure, isNull);
      }
      final List<BabyCategoryView> slices = h.view(b.id).slices;
      // 33.33% each: the point left over goes to the first in the
      // reader's own order.
      expect(
        <int>[for (final BabyCategoryView s in slices) s.share],
        <int>[34, 33, 33],
      );
      expect(slices.first.name, 'One');
      expect(
        slices.fold<int>(0, (int a, BabyCategoryView s) => a + s.share),
        100,
      );
    });

    test('uncategorised is a real slice, and sorts last in a tie', () {
      final BabyBudget b = h.add(
        plan: rs(9000),
        categories: <BabyCategoryDraft>[const BabyCategoryDraft(name: 'Named')],
      );
      expect(h.spend(b.id, 1000, category: 'Named').failure, isNull);
      expect(h.spend(b.id, 1000).failure, isNull, reason: 'no category');
      final List<BabyCategoryView> slices = h.view(b.id).slices;
      expect(slices, hasLength(2));
      expect(slices.any((BabyCategoryView s) => s.uncategorised), isTrue);
      expect(
        slices.fold<int>(0, (int a, BabyCategoryView s) => a + s.share),
        100,
      );
      // An exact half each: the named category takes the odd point.
      final BabyCategoryView named = slices.firstWhere(
        (BabyCategoryView s) => !s.uncategorised,
      );
      final BabyCategoryView other = slices.firstWhere(
        (BabyCategoryView s) => s.uncategorised,
      );
      expect(named.share, 50);
      expect(other.share, 50);
      h.expectSound();
    });

    test('a month with nothing has no slices and no percentages', () {
      final BabyBudget b = h.add();
      expect(h.view(b.id).slices, isEmpty);
      expect(h.view(b.id).thisMonth!.minor, 0);
      expect(h.view(b.id).ratio, 0);
    });
  });

  group('Example C and D — over the plan, and no plan at all', () {
    test('115% and over by Rs 5,850; never clamped', () {
      final BabyBudget b = h.add();
      expect(h.spend(b.id, 44850, category: 'Health').failure, isNull);
      final BabyBudgetView v = h.view(b.id);
      expect(v.thisMonth!.minor, 4485000);
      expect(v.ratio, 115);
      expect(v.overBy!.minor, 585000);
    });

    test('no plan: no ratio, no ring, and nothing invented', () {
      final BabyBudget b = h.add(noPlan: true);
      expect(h.spend(b.id, 44850, category: 'Health').failure, isNull);
      final BabyBudgetView v = h.view(b.id);
      expect(v.plan, isNull);
      expect(v.ratio, isNull);
      expect(v.overBy, isNull);
      expect(v.unallocated, isNull);
      expect(v.thisMonth!.minor, 4485000, reason: 'the spend is still known');
      h.expectSound();
    });
  });

  group('correction 1 — spent or planned, never between', () {
    test('a planned purchase has no spent day, and is in no month', () {
      final BabyBudget b = h.add();
      final BabyBudgetResult<BabyBudgetWrite> r = h.plan(
        b.id,
        73600,
        label: 'Pram',
        expectedOn: d(10, 10),
      );
      expect(r.failure, isNull);
      final BabySpend s = r.value!.spend!;
      expect(s.planned, isTrue);
      expect(s.spentOn, isNull, reason: 'nothing was spent');
      expect(s.expectedOn, d(10, 10));
      final BabyBudgetView v = h.view(b.id);
      expect(v.thisMonth!.minor, 0);
      expect(v.plannedTotal.minor, 7360000);
      expect(v.slices, isEmpty);
      h.expectSound();
    });

    test('marking it bought moves every field in one write', () {
      final BabyBudget b = h.add();
      final BabySpend planned = h
          .plan(b.id, 73600, label: 'Pram', expectedOn: d(10, 10))
          .value!
          .spend!;
      final String before = h.records();
      final BabyBudgetResult<BabyBudgetWrite> r = h.repo.markBought(
        planned.id,
        on: d(10, 3),
        actually: rs(71000),
        today: d(10, 5),
        version: planned.version,
      );
      expect(r.failure, isNull);
      final BabySpend s = r.value!.spend!;
      expect(s.planned, isFalse);
      expect(s.spentOn, d(10, 3));
      expect(s.expectedOn, isNull, reason: 'it is no longer expected');
      expect(s.amount.minor, 7100000, reason: 'what was actually paid');
      expect(s.id, planned.id, reason: 'one record, not two');
      // One write, and the store holds one spend, not two.
      expect(h.view(b.id).spends, hasLength(1));
      expect(h.view(b.id, d(10, 5)).thisMonth!.minor, 7100000);
      expect(h.view(b.id, d(10, 5)).plannedTotal.minor, 0);
      expect(h.records(), isNot(before));
      h.expectSound();
    });

    test('an edit can never turn a plan into a spend', () {
      final BabyBudget b = h.add();
      final BabySpend planned = h
          .plan(b.id, 5000, expectedOn: d(10, 10))
          .value!
          .spend!;
      // Editing the day of a planned record moves what it expects, and
      // leaves it planned.
      final BabyBudgetResult<BabyBudgetWrite> r = h.repo.editSpend(
        planned.id,
        day: d(11, 1),
        amount: rs(6000),
        version: planned.version,
      );
      expect(r.failure, isNull);
      final BabySpend s = r.value!.spend!;
      expect(s.planned, isTrue);
      expect(s.spentOn, isNull);
      expect(s.expectedOn, d(11, 1));
      expect(s.amount.minor, 600000);
    });

    test('going back is its own action, and refuses to repeat itself', () {
      final BabyBudget b = h.add();
      final BabySpend spent = h
          .spend(b.id, 5000, category: 'Health')
          .value!
          .spend!;
      final BabyBudgetResult<BabyBudgetWrite> back = h.repo.markPlanned(
        spent.id,
        expectedOn: d(10, 1),
        version: spent.version,
      );
      expect(back.failure, isNull);
      expect(back.value!.spend!.planned, isTrue);
      expect(back.value!.spend!.spentOn, isNull);
      expect(h.view(b.id).thisMonth!.minor, 0);

      // Doing it again is refused: it is already a plan.
      final BabySpend now = h.view(b.id).spends.single;
      expect(
        h.repo.markPlanned(now.id, version: now.version).failure!.reason,
        'alreadyPlanned',
      );
      // And marking a spend bought is refused for the same reason.
      final BabySpend other = h
          .spend(b.id, 100, category: 'Health')
          .value!
          .spend!;
      expect(
        h.repo
            .markBought(other.id, on: kToday, version: other.version)
            .failure!
            .reason,
        'alreadySpent',
      );
    });

    test('a stored record that is both is damage, not a state', () {
      final BabyBudget b = h.add();
      h.raw(
        BabyBudgetCollections.spends,
        LumeRecordId.generate().value,
        <String, Object?>{
          'schema': kBabyBudgetSchema,
          'budget': b.id.value,
          'amountMinor': 100000,
          'currency': 'PKR',
          'planned': true,
          'spentOn': '2026-09-10',
          'state': 'active',
        },
      );
      final BabyBudgetBook book = h.book();
      expect(book.defects.single.field, 'spentOn');
      expect(book.defects.single.reason, 'planned');
    });
  });

  group('correction 2 — what a plan may be', () {
    test('a plan of nothing is refused', () {
      expect(h.tryAdd(plan: rs(0)).failure!.reason, 'zero');
      expect(h.recordLines(), isEmpty);
    });

    test('a category plan without a budget plan is refused', () {
      final BabyBudgetResult<BabyBudgetWrite> r = h.tryAdd(
        noPlan: true,
        categories: <BabyCategoryDraft>[
          BabyCategoryDraft(name: 'Nappies', monthlyPlan: rs(5000)),
        ],
      );
      expect(r.failure!.kind, BabyBudgetFailureKind.planShape);
      expect(r.failure!.reason, 'noBudgetPlan');
      expect(h.recordLines(), isEmpty);
    });

    test('category plans may total less, and what is left is named', () {
      final BabyBudget b = h.add(
        plan: rs(39000),
        categories: <BabyCategoryDraft>[
          BabyCategoryDraft(name: 'Nappies', monthlyPlan: rs(12000)),
          BabyCategoryDraft(name: 'Formula', monthlyPlan: rs(8000)),
        ],
      );
      expect(h.view(b.id).unallocated!.minor, 1900000, reason: 'Rs 19,000');
      h.expectSound();
    });

    test('category plans may never total more', () {
      final BabyBudgetResult<BabyBudgetWrite> r = h.tryAdd(
        plan: rs(10000),
        categories: <BabyCategoryDraft>[
          BabyCategoryDraft(name: 'Nappies', monthlyPlan: rs(6000)),
          BabyCategoryDraft(name: 'Formula', monthlyPlan: rs(5000)),
        ],
      );
      expect(r.failure!.kind, BabyBudgetFailureKind.planShape);
      expect(r.failure!.reason, 'overPlan');
      expect(h.recordLines(), isEmpty);
    });

    test('removing the budget plan clears every category plan in the same '
        'write', () {
      final BabyBudget b = h.add(
        plan: rs(39000),
        categories: <BabyCategoryDraft>[
          BabyCategoryDraft(name: 'Nappies', monthlyPlan: rs(12000)),
          BabyCategoryDraft(name: 'Formula', monthlyPlan: rs(8000)),
        ],
      );
      final BabyBudgetResult<BabyBudgetWrite> r = h.repo.setPlan(
        b.id,
        null,
        version: h.view(b.id).budget.version,
      );
      expect(r.failure, isNull);
      final BabyBudgetView v = h.view(b.id);
      expect(v.plan, isNull);
      expect(
        v.categories.every((BabyCategory c) => c.monthlyPlan == null),
        isTrue,
        reason: 'no share of nothing is left behind',
      );
      h.expectSound();
    });

    test('lowering the plan below what the categories hold is refused', () {
      final BabyBudget b = h.add(
        plan: rs(39000),
        categories: <BabyCategoryDraft>[
          BabyCategoryDraft(name: 'Nappies', monthlyPlan: rs(30000)),
        ],
      );
      final BabyBudgetResult<BabyBudgetWrite> r = h.repo.setPlan(
        b.id,
        rs(20000),
        version: h.view(b.id).budget.version,
      );
      expect(r.failure!.kind, BabyBudgetFailureKind.planShape);
      expect(r.failure!.reason, 'belowCategories');
      expect(h.view(b.id).plan!.minor, 3900000, reason: 'unchanged');
    });
  });

  group('correction 3 — the start means something', () {
    test('a spend before the start is refused', () {
      final BabyBudget b = h.add(startedOn: d(9, 1));
      final BabyBudgetResult<BabyBudgetWrite> r = h.spend(
        b.id,
        1000,
        category: 'Health',
        on: d(8, 31),
      );
      expect(r.failure!.kind, BabyBudgetFailureKind.beforeStart);
      expect(r.failure!.day, d(9, 1));
      expect(h.view(b.id).spentToDate.minor, 0);
    });

    test('moving the start past a record is refused, and the record is '
        'named', () {
      final BabyBudget b = h.add(startedOn: d(1, 1));
      final BabySpend s = h
          .spend(b.id, 1000, category: 'Health', on: d(3, 4), label: 'Wipes')
          .value!
          .spend!;
      final BabyBudgetResult<BabyBudgetWrite> r = h.repo.setStartedOn(
        b.id,
        d(6, 1),
        version: h.view(b.id).budget.version,
      );
      expect(r.failure!.kind, BabyBudgetFailureKind.beforeStart);
      expect(r.failure!.day, d(3, 4), reason: 'the earliest record\'s day');
      expect(r.failure!.label, 'Wipes');
      expect(r.failure!.ids, <LumeRecordId>[s.id]);
      expect(h.view(b.id).budget.startedOn, d(1, 1), reason: 'unchanged');
      // Moving it to exactly that day is allowed.
      expect(
        h.repo
            .setStartedOn(b.id, d(3, 4), version: h.view(b.id).budget.version)
            .failure,
        isNull,
      );
    });

    test('a budget that has not started says so instead of a zero month', () {
      final BabyBudget b = h.add(startedOn: d(11, 1));
      final BabyBudgetView v = h.view(b.id);
      expect(v.status, BabyBudgetStatus.notStarted);
      expect(v.running, isFalse);
      expect(v.thisMonth, isNull, reason: 'not a month of nothing');
      expect(v.ratio, isNull);
      expect(v.trend, isNull);
      expect(v.slices, isEmpty);
      // Once it starts, the figures appear.
      final BabyBudgetView later = h.view(b.id, d(11, 2));
      expect(later.status, BabyBudgetStatus.inUse);
      expect(later.thisMonth!.minor, 0);
    });

    test('the trend leaves out months before the budget began', () {
      final BabyBudget b = h.add(startedOn: d(8, 1));
      expect(
        h.spend(b.id, 1000, category: 'Health', on: d(8, 5)).failure,
        isNull,
      );
      final List<BabyMonth> trend = h.view(b.id).trend!;
      // Six months would be April..September; only August and September
      // are the budget's.
      expect(trend, hasLength(2));
      expect(trend.first.month, d(8, 1));
      expect(trend.first.spent.minor, 100000);
      expect(trend.last.month, d(9, 1));
      expect(trend.last.spent.minor, 0, reason: 'a true zero inside range');
    });
  });

  group('correction 4 — archiving is truthful', () {
    test('it cannot be archived tomorrow', () {
      final BabyBudget b = h.add();
      final BabyBudgetResult<BabyBudgetWrite> r = h.repo.setArchived(
        b.id,
        true,
        on: d(9, 22),
        today: kToday,
        version: h.view(b.id).budget.version,
      );
      expect(r.failure!.field, 'archivedOn');
      expect(r.failure!.reason, 'future');
      expect(h.view(b.id).budget.archived, isFalse);
    });

    test('archived takes no ordinary write, and un-archive restores '
        'everything', () {
      final BabyBudget b = h.referenceMonth();
      final String before = h.records();
      expect(
        h.repo
            .setArchived(
              b.id,
              true,
              on: kToday,
              today: kToday,
              version: h.view(b.id).budget.version,
            )
            .failure,
        isNull,
      );
      expect(h.view(b.id).status, BabyBudgetStatus.archived);
      // No new spend, no edit.
      expect(
        h.spend(b.id, 100, category: 'Health').failure!.kind,
        BabyBudgetFailureKind.archived,
      );
      final BabySpend s = h.view(b.id).spends.first;
      expect(
        h.repo.setVoided(s.id, true, version: s.version).failure!.kind,
        BabyBudgetFailureKind.archived,
      );
      // Every figure is still there.
      expect(h.view(b.id).spentToDate.minor, 3200000);

      expect(
        h.repo
            .setArchived(b.id, false, version: h.view(b.id).budget.version)
            .failure,
        isNull,
      );
      // Every record but the budget's own is byte-identical.
      List<String> others(String dump) => dump
          .split('\n')
          .where((String l) => !l.startsWith(b.id.value))
          .toList();
      expect(others(h.records()), others(before));
      expect(h.view(b.id).thisMonth!.minor, 3200000);
      h.expectSound();
    });

    test('without the reader\'s day an entered date is taken as entered', () {
      final BabyBudget b = h.add();
      final BabyBudgetResult<BabyBudgetWrite> r = h.repo.setArchived(
        b.id,
        true,
        on: d(12, 25),
        version: h.view(b.id).budget.version,
      );
      expect(r.failure, isNull);
      expect(h.view(b.id).budget.archivedOn, d(12, 25));
    });
  });

  group('correction 6 — Coming up is ordered by what needs doing', () {
    test('overdue first, oldest first; then soonest first', () {
      final BabyBudget b = h.add();
      // Entered newest-first on purpose, so insertion order cannot be
      // what the list shows.
      expect(
        h.plan(b.id, 100, label: 'soon', expectedOn: d(9, 25)).failure,
        isNull,
      );
      expect(
        h.plan(b.id, 100, label: 'later', expectedOn: d(11, 1)).failure,
        isNull,
      );
      expect(
        h.plan(b.id, 100, label: 'late', expectedOn: d(9, 2)).failure,
        isNull,
      );
      expect(
        h.plan(b.id, 100, label: 'latest', expectedOn: d(8, 1)).failure,
        isNull,
      );
      expect(h.plan(b.id, 100, label: 'undated').failure, isNull);

      expect(
        <String>[for (final BabySpend s in h.view(b.id).comingUp) s.label!],
        <String>['latest', 'late', 'soon', 'later'],
        reason: 'overdue oldest first, then soonest to come',
      );
      expect(
        <String>[for (final BabySpend s in h.view(b.id).oneOff) s.label!],
        <String>['undated'],
        reason: 'undated keeps its own section',
      );
      final BabyBudgetView v = h.view(b.id);
      expect(v.statusOf(v.comingUp.first), BabyPlannedStatus.overdue);
      expect(v.statusOf(v.comingUp.last), BabyPlannedStatus.expected);
    });

    test('without the reader\'s day nothing is overdue, and the order is '
        'still by date', () {
      final BabyBudget b = h.add();
      expect(
        h.plan(b.id, 100, label: 'a', expectedOn: d(11, 1)).failure,
        isNull,
      );
      expect(
        h.plan(b.id, 100, label: 'b', expectedOn: d(9, 2)).failure,
        isNull,
      );
      final BabyBudgetView v = h.viewWithoutDay(b.id);
      expect(
        <String>[for (final BabySpend s in v.comingUp) s.label!],
        <String>['b', 'a'],
      );
      expect(v.statusOf(v.comingUp.first), BabyPlannedStatus.unknown);
      expect(v.thisMonth, isNull);
      expect(v.ratio, isNull);
      expect(v.trend, isNull);
    });
  });

  group('categories', () {
    test('deleting one keeps its spends, uncategorised', () {
      final BabyBudget b = h.referenceMonth();
      final BabyCategory health = h.category(b.id, 'Health');
      final BabyBudgetResult<BabyBudgetWrite> r = h.repo.deleteCategory(
        health.id,
        version: health.version,
      );
      expect(r.failure, isNull);
      final BabyBudgetView v = h.view(b.id);
      expect(v.categories, hasLength(3));
      expect(v.spends, hasLength(4), reason: 'no spend was deleted');
      expect(v.thisMonth!.minor, 3200000, reason: 'the month is unchanged');
      expect(v.slices.any((BabyCategoryView s) => s.uncategorised), isTrue);
      h.expectSound();
    });

    test('deleting one can move its spends to another', () {
      final BabyBudget b = h.referenceMonth();
      final BabyCategory health = h.category(b.id, 'Health');
      final BabyCategory clothing = h.category(b.id, 'Clothing');
      expect(
        h.repo
            .deleteCategory(
              health.id,
              moveTo: clothing.id,
              version: health.version,
            )
            .failure,
        isNull,
      );
      final BabyBudgetView v = h.view(b.id);
      expect(v.categories, hasLength(3));
      final BabyCategoryView moved = v.slices.firstWhere(
        (BabyCategoryView s) => s.name == 'Clothing',
      );
      expect(moved.spent.minor, 1200000, reason: '7,000 + 5,000');
      expect(v.slices.any((BabyCategoryView s) => s.uncategorised), isFalse);
      h.expectSound();
    });
  });

  group('deletion, Undo and transactions', () {
    test('delete removes the budget and everything it owns; Undo brings '
        'back the same ids and versions', () {
      final BabyBudget b = h.referenceMonth();
      expect(h.plan(b.id, 73600, label: 'Pram').failure, isNull);
      final BabyBudgetCounts counts = h.repo.counts(b.id);
      expect(counts.categories, 4);
      expect(counts.spends, 4);
      expect(counts.planned, 1);
      expect(counts.total, 10);

      final String before = h.records();
      final BabyBudgetResult<BabyBudgetWrite> r = h.repo.deleteBudget(
        b.id,
        version: h.view(b.id).budget.version,
      );
      expect(r.failure, isNull);
      expect(h.book().isEmpty, isTrue);
      expect(h.recordLines(), isEmpty, reason: 'no orphans left behind');

      expect(h.repo.undo(r.value!).failure, isNull);
      expect(h.records(), before);
      h.expectSound();
    });

    test('a failure part-way through creation publishes nothing', () {
      h.store.publishFault = (_, int i) {
        if (i == 3) throw StateError('disk');
      };
      final BabyBudgetResult<BabyBudgetWrite> r = h.tryAdd();
      expect(r.failure!.kind, BabyBudgetFailureKind.storage);
      h.store.publishFault = null;
      expect(h.recordLines(), isEmpty);
    });

    test('a retried create with the same key writes one budget', () {
      expect(h.tryAdd(idempotencyKey: 'once').failure, isNull);
      final BabyBudgetResult<BabyBudgetWrite> again = h.tryAdd(
        idempotencyKey: 'once',
      );
      expect(again.failure, isNull);
      expect(again.value!.receipt.replayed, isTrue);
      expect(h.book().budgets, hasLength(1));
    });

    test('a stale version is a conflict, and nothing is written', () {
      final BabyBudget b = h.add();
      final String before = h.records();
      expect(
        h.repo.editBudget(b.id, name: 'Other', version: 99).failure!.kind,
        BabyBudgetFailureKind.conflict,
      );
      expect(h.records(), before);
    });
  });

  group('void, restore and the day', () {
    test('voiding takes a spend out of every figure; restoring puts it '
        'back exactly', () {
      final BabyBudget b = h.referenceMonth();
      final BabySpend formula = h
          .view(b.id)
          .spends
          .firstWhere((BabySpend s) => s.amount.minor == 800000);
      expect(
        h.repo.setVoided(formula.id, true, version: formula.version).failure,
        isNull,
      );
      final BabyBudgetView v = h.view(b.id);
      expect(v.thisMonth!.minor, 2400000);
      expect(v.ratio, 62, reason: '0.6154 to a whole percent');
      expect(v.slices, hasLength(3), reason: 'the category has nothing left');

      final BabySpend voided = h
          .view(b.id)
          .spends
          .firstWhere((BabySpend s) => s.id == formula.id);
      expect(
        h.repo.setVoided(voided.id, false, version: voided.version).failure,
        isNull,
      );
      expect(h.view(b.id).thisMonth!.minor, 3200000);
      expect(h.view(b.id).ratio, 82);
      h.expectSound();
    });

    test('a spend dated after the reader\'s day is refused', () {
      final BabyBudget b = h.add();
      final BabyBudgetResult<BabyBudgetWrite> r = h.spend(
        b.id,
        1000,
        category: 'Health',
        on: d(9, 22),
        today: kToday,
      );
      expect(r.failure!.field, 'spentOn');
      expect(r.failure!.reason, 'future');
      expect(h.view(b.id).spentToDate.minor, 0);
    });

    test('a planned purchase may be expected in the future', () {
      final BabyBudget b = h.add();
      expect(h.plan(b.id, 1000, expectedOn: d(12, 25)).failure, isNull);
      expect(h.view(b.id).plannedTotal.minor, 100000);
    });
  });

  group('currencies and stored damage', () {
    test('summaries are per currency, and never added across them', () {
      h.add();
      h.add(name: 'Dollars', currency: usd, plan: dollars(400));
      final BabyBudgetBook b = h.book();
      expect(b.currencies.map((LumeCurrency c) => c.code), <String>[
        'PKR',
        'USD',
      ]);
      expect(b.summary(pkr).budgets, 1);
      expect(b.summary(usd).spentToDate.currency, usd);
    });

    test('a record that cannot be read is a defect; its budget leaves the '
        'totals and is not written over', () {
      final BabyBudget b = h.referenceMonth();
      final BabySpend s = h.view(b.id).spends.first;
      h.store.run<void>(
        (tx) => tx.update(
          BabyBudgetCollections.spends,
          s.id.value,
          <String, Object?>{...s.toFields(), 'spentOn': 'whenever'},
          expectVersion: s.version,
        ),
      );
      final BabyBudgetBook book = h.book();
      expect(book.defects.single.field, 'spentOn');
      expect(book.defects.single.reason, 'date');
      expect(
        h.spend(b.id, 100, category: 'Health').failure!.kind,
        BabyBudgetFailureKind.damaged,
      );
      // Deleting it is still allowed.
      expect(
        h.repo
            .deleteBudget(b.id, version: h.book().budgets.first.budget.version)
            .failure,
        isNull,
      );
    });

    test('a spend naming a category of another budget is damage', () {
      final BabyBudget a = h.add();
      final BabyBudget b = h.add(name: 'Second');
      final BabyCategory other = h.category(a.id, 'Health');
      h.raw(
        BabyBudgetCollections.spends,
        LumeRecordId.generate().value,
        <String, Object?>{
          'schema': kBabyBudgetSchema,
          'budget': b.id.value,
          'category': other.id.value,
          'amountMinor': 100000,
          'currency': 'PKR',
          'planned': false,
          'spentOn': '2026-09-10',
          'state': 'active',
        },
      );
      expect(
        h.book().damage.map((BabyBudgetDamage x) => x.reason),
        contains('spendCategory'),
      );
    });

    test('an overlarge plan is refused', () {
      final BabyBudgetResult<BabyBudgetWrite> r = h.tryAdd(
        plan: LumeMoney.entry(LumeMoney.maxEntryMinor, pkr),
      );
      expect(r.failure!.reason, 'overflow');
      expect(h.recordLines(), isEmpty);
    });
  });
}

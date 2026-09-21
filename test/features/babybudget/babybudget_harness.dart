/// Baby Budget over an in-memory store, a controllable clock and seeded
/// ids — deterministic, and never the wall clock.
///
/// The reference's month, as a reader would enter it: a plan of
/// Rs 39,000 and four categories (`BABY_BUDGET_PROPOSAL.md` §6 A).
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/babybudget/domain/babybudget_book.dart';
import 'package:lume/features/babybudget/domain/babybudget_failure.dart';
import 'package:lume/features/babybudget/domain/babybudget_model.dart';
import 'package:lume/features/babybudget/domain/babybudget_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_transaction.dart';

final LumeCurrency pkr = LumeCurrency.of('PKR');
final LumeCurrency usd = LumeCurrency.of('USD');

/// Rupees, in paisa.
LumeMoney rs(num rupees) => LumeMoney.entry((rupees * 100).round(), pkr);

/// Dollars, in cents.
LumeMoney dollars(num d) => LumeMoney.entry((d * 100).round(), usd);

/// 2026 dates.
LumeDate d(int month, int day) => LumeDate(2026, month, day);

/// The fixture day: 21 September 2026.
final LumeDate kToday = d(9, 21);

/// The reference's four categories, and the plan they sit under.
const List<String> kCategoryNames = <String>[
  'Nappies & wipes',
  'Formula & food',
  'Clothing',
  'Health',
];

class BabyBudgetHarness {
  BabyBudgetHarness({int seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = BabyBudgetRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  late final LumeMemoryRecordRepository store;
  late final BabyBudgetRepository repo;
  DateTime clock = DateTime.utc(2026, 9, 21, 10);

  void tick([Duration by = const Duration(minutes: 1)]) =>
      clock = clock.add(by);

  BabyBudgetBook book([LumeDate? today]) => repo.view().book(today ?? kToday);

  /// The same records read with no day at all.
  BabyBudgetBook bookWithoutDay() => repo.view().book(null);

  BabyBudgetView view(LumeRecordId id, [LumeDate? today]) =>
      book(today).budget(id)!;

  BabyBudgetView viewWithoutDay(LumeRecordId id) =>
      bookWithoutDay().budget(id)!;

  BabyBudgetResult<BabyBudgetWrite> tryAdd({
    String name = 'The baby',
    String? note,
    LumeCurrency? currency,
    LumeMoney? plan,
    bool noPlan = false,
    LumeDate? startedOn,
    List<BabyCategoryDraft>? categories,
    String? idempotencyKey,
  }) {
    tick();
    return repo.addBudget(
      BabyBudgetDraft(
        name: name,
        note: note,
        currency: currency ?? pkr,
        monthlyPlan: noPlan ? null : plan ?? rs(39000),
        startedOn: startedOn ?? d(1, 1),
        categories: categories ?? reference(),
      ),
      idempotencyKey: idempotencyKey,
    );
  }

  /// The reference's four categories, without plans of their own.
  static List<BabyCategoryDraft> reference() => <BabyCategoryDraft>[
    for (final (int i, String name) in kCategoryNames.indexed)
      BabyCategoryDraft(name: name, colour: i),
  ];

  BabyBudget add({
    String name = 'The baby',
    LumeCurrency? currency,
    LumeMoney? plan,
    bool noPlan = false,
    LumeDate? startedOn,
    List<BabyCategoryDraft>? categories,
  }) {
    final BabyBudgetResult<BabyBudgetWrite> r = tryAdd(
      name: name,
      currency: currency,
      plan: plan,
      noPlan: noPlan,
      startedOn: startedOn,
      categories: categories,
    );
    expect(r.failure, isNull, reason: 'add $name');
    return r.value!.budget!;
  }

  BabyCategory category(LumeRecordId budget, String name) =>
      view(budget).categories.firstWhere((BabyCategory c) => c.name == name);

  /// Record money that went, in a named category.
  BabyBudgetResult<BabyBudgetWrite> spend(
    LumeRecordId budget,
    num amount, {
    String? category,
    LumeDate? on,
    String? label,
    LumeDate? today,
  }) {
    tick();
    return repo.recordSpend(
      budget,
      amount: rs(amount),
      spentOn: on ?? kToday,
      categoryId: category == null ? null : this.category(budget, category).id,
      label: label,
      today: today,
    );
  }

  /// Record something the reader means to buy.
  BabyBudgetResult<BabyBudgetWrite> plan(
    LumeRecordId budget,
    num amount, {
    String? category,
    LumeDate? expectedOn,
    String? label,
  }) {
    tick();
    return repo.recordPlanned(
      budget,
      amount: rs(amount),
      expectedOn: expectedOn,
      categoryId: category == null ? null : this.category(budget, category).id,
      label: label,
    );
  }

  /// The reference's month: 12,000 / 8,000 / 7,000 / 5,000 = Rs 32,000.
  BabyBudget referenceMonth() {
    final BabyBudget b = add();
    const List<num> amounts = <num>[12000, 8000, 7000, 5000];
    for (final (int i, String name) in kCategoryNames.indexed) {
      final BabyBudgetResult<BabyBudgetWrite> r = spend(
        b.id,
        amounts[i],
        category: name,
        on: d(9, 3 + i),
      );
      expect(r.failure, isNull, reason: name);
    }
    return b;
  }

  /// A raw record, written as it is — for damaged-state tests.
  void raw(String collection, String id, Map<String, Object?> fields) {
    final LumeTxResult<void> r = store.run<void>(
      (LumeRecordTx tx) => tx.create(collection, id, fields),
    );
    expect(r.ok, isTrue);
  }

  void expectSound() {
    final BabyBudgetBook b = book();
    expect(b.invariants(), isEmpty, reason: 'invariants');
    expect(b.damage, isEmpty, reason: 'damage');
    expect(b.defects, isEmpty, reason: 'defects');
  }

  /// Just the stored records, without the dump's collection headings.
  List<String> recordLines() => records()
      .split('\n')
      .where((String l) => RegExp('^[0-9a-f-]{36} ').hasMatch(l))
      .toList();

  /// Every record, byte for byte, in id order and without the store's
  /// revision counters — which an Undo advances, as it should.
  String records() =>
      (store.debugDump().replaceAll(RegExp(r'\] r[0-9]+'), ']').split('\n')
            ..sort())
          .join('\n');

  void dispose() => store.dispose();
}

/// Baby Budget on the real router, over an in-memory store with seeded
/// ids and a controllable clock.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/app/providers/records_provider.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/platform/lume_export.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/babybudget/application/babybudget_providers.dart';
import 'package:lume/features/babybudget/domain/babybudget_book.dart';
import 'package:lume/features/babybudget/domain/babybudget_failure.dart';
import 'package:lume/features/babybudget/domain/babybudget_model.dart';
import 'package:lume/features/babybudget/domain/babybudget_repository.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

final LumeCurrency babyPkr = LumeCurrency.of('PKR');

LumeMoney babyRs(num rupees) =>
    LumeMoney.entry((rupees * 100).round(), babyPkr);

LumeDate babyDay(int month, int d) => LumeDate(2026, month, d);

/// The reference's month, as a reader would enter it
/// (`BABY_BUDGET_PROPOSAL.md` §6, Example A): a plan of Rs 39,000, four
/// categories, and Rs 32,000 spent across them.
class BabyBudgetWorld {
  BabyBudgetWorld({this.seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = BabyBudgetRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  final int seed;
  late final LumeMemoryRecordRepository store;
  late final BabyBudgetRepository repo;

  /// Seeding writes land in the past, so nothing depends on a wall clock.
  DateTime clock = kFixtureInstant.subtract(const Duration(days: 200));
  final LumeRecordingExporter exporter = LumeRecordingExporter();
  final Map<String, LumeRecordId> budgets = <String, LumeRecordId>{};

  void _tick() => clock = clock.add(const Duration(minutes: 1));

  /// The reader's own day in the fixture: 7 September 2026, which is
  /// what the zone service resolves [kFixtureInstant] to in Pakistan.
  static final LumeDate today = babyDay(9, 7);

  static const List<String> categoryNames = <String>[
    'Nappies & wipes',
    'Formula & food',
    'Clothing',
    'Health',
  ];

  BabyBudget add({
    String name = 'The baby',
    LumeCurrency? currency,
    LumeMoney? plan,
    bool noPlan = false,
    LumeDate? startedOn,
    List<BabyCategoryDraft>? categories,
  }) {
    _tick();
    final BabyBudgetResult<BabyBudgetWrite> r = repo.addBudget(
      BabyBudgetDraft(
        name: name,
        currency: currency ?? babyPkr,
        monthlyPlan: noPlan ? null : plan ?? babyRs(39000),
        startedOn: startedOn ?? babyDay(1, 1),
        categories: categories ?? reference(),
      ),
    );
    if (r.failure != null) throw StateError('add $name: ${r.failure}');
    budgets[name] = r.value!.budget!.id;
    return r.value!.budget!;
  }

  static List<BabyCategoryDraft> reference() => <BabyCategoryDraft>[
    for (final (int i, String name) in categoryNames.indexed)
      BabyCategoryDraft(name: name, colour: i),
  ];

  BabyBudgetBook book([LumeDate? day]) => repo.view().book(day ?? today);

  BabyBudgetView view(LumeRecordId id, [LumeDate? day]) =>
      book(day).budget(id)!;

  BabyCategory category(LumeRecordId budget, String name) =>
      view(budget).categories.firstWhere((BabyCategory c) => c.name == name);

  BabySpend spend(
    LumeRecordId budget,
    num amount, {
    String? category,
    LumeDate? on,
    String? label,
  }) {
    _tick();
    final BabyBudgetResult<BabyBudgetWrite> r = repo.recordSpend(
      budget,
      amount: babyRs(amount),
      spentOn: on ?? today,
      categoryId: category == null ? null : this.category(budget, category).id,
      label: label,
    );
    if (r.failure != null) throw StateError('spend: ${r.failure}');
    return r.value!.spend!;
  }

  BabySpend plan(
    LumeRecordId budget,
    num amount, {
    String? label,
    LumeDate? expectedOn,
    String? category,
  }) {
    _tick();
    final BabyBudgetResult<BabyBudgetWrite> r = repo.recordPlanned(
      budget,
      amount: babyRs(amount),
      expectedOn: expectedOn,
      categoryId: category == null ? null : this.category(budget, category).id,
      label: label,
    );
    if (r.failure != null) throw StateError('plan: ${r.failure}');
    return r.value!.spend!;
  }

  /// The reference dashboard, in rupees: Rs 32,000 across four
  /// categories this month, five earlier months for the bars, two
  /// planned purchases with days and two without.
  BabyBudgetWorld reference_() {
    final BabyBudget b = add();
    const List<num> month = <num>[12000, 8000, 7000, 5000];
    for (final (int i, String name) in categoryNames.indexed) {
      spend(b.id, month[i], category: name, on: babyDay(9, 1 + i));
    }
    // April through August, so "Six months" has six real months.
    const List<num> earlier = <num>[28000, 30500, 29000, 34000, 31000];
    for (final (int i, num amount) in earlier.indexed) {
      spend(b.id, amount, category: 'Nappies & wipes', on: babyDay(4 + i, 12));
    }
    plan(b.id, 18400, label: 'Nappy restock', expectedOn: babyDay(9, 13));
    plan(b.id, 39600, label: 'Cot mattress', expectedOn: babyDay(9, 21));
    plan(b.id, 119000, label: 'Cot and mattress');
    plan(b.id, 73600, label: 'Pram');
    clock = kFixtureInstant;
    return this;
  }

  /// The reference's own PK figures, as a reader would have entered
  /// them (`BABY_BUDGET_PROPOSAL.md` §2.2): Rs 90,600 this month, split
  /// 120 : 80 : 70 : 50 as the fixture splits it, five earlier months at
  /// the reference's trend, and its four planned purchases to the rupee.
  ///
  /// The plan is Rs 110,500, because the reference has none at all — its
  /// "82% of plan" is the literal constant `ratio: 0.82` (defect 1). A
  /// plan of Rs 110,500 against Rs 90,600 is 82%, so the ring can be
  /// compared with the one the reference drew.
  BabyBudgetWorld parity_() {
    final BabyBudget b = add(plan: LumeMoney.entry(11050000, babyPkr));
    // In paisa, so the four add to Rs 90,600 exactly.
    const List<int> month = <int>[3397500, 2265000, 1981875, 1415625];
    for (final (int i, String name) in categoryNames.indexed) {
      _tick();
      final BabyBudgetResult<BabyBudgetWrite> r = repo.recordSpend(
        b.id,
        amount: LumeMoney.entry(month[i], babyPkr),
        spentOn: babyDay(9, 1 + i),
        categoryId: category(b.id, name).id,
      );
      if (r.failure != null) throw StateError('parity spend: ${r.failure}');
    }
    // April to August, the reference's trend at its own PK rate.
    const List<int> earlier = <int>[
      7927500,
      8635313,
      8210625,
      9626250,
      8776875,
    ];
    for (final (int i, int paisa) in earlier.indexed) {
      _tick();
      final BabyBudgetResult<BabyBudgetWrite> r = repo.recordSpend(
        b.id,
        amount: LumeMoney.entry(paisa, babyPkr),
        spentOn: babyDay(4 + i, 12),
        categoryId: category(b.id, 'Nappies & wipes').id,
      );
      if (r.failure != null) throw StateError('parity month: ${r.failure}');
    }
    plan(b.id, 18400, label: 'Nappy restock', expectedOn: babyDay(9, 13));
    plan(b.id, 39600, label: 'Cot mattress', expectedOn: babyDay(9, 21));
    plan(b.id, 119000, label: 'Cot and mattress');
    plan(b.id, 73600, label: 'Pram');
    clock = kFixtureInstant;
    return this;
  }

  List<Override> get overrides => <Override>[
    recordRepositoryProvider.overrideWithValue(store),
    babyBudgetRepositoryProvider.overrideWithValue(repo),
    exporterProvider.overrideWithValue(exporter),
  ];

  void dispose() => store.dispose();
}

Future<GoRouter> pumpBabyBudget(
  WidgetTester tester,
  BabyBudgetWorld world, {
  String state = 'default_pk',
  LumeProfileRepository? profile,
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  String query = '',
  List<Override> overrides = const <Override>[],
}) async {
  final GoRouter router = await pumpLumeRouter(
    tester,
    initialLocation:
        '${LumeRoutes.tool(LumeRoutes.tools, 'babybudget')}'
        '${query.isEmpty ? '' : '?$query'}',
    profile: profile ?? taxProfile(state),
    surface: surface,
    locale: locale,
    textScale: textScale,
    theme: theme,
    overrides: <Override>[...world.overrides, ...overrides],
  );
  await tester.pumpAndSettle();
  return router;
}

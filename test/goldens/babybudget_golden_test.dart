/// Baby Budget, pinned and captured: the reference's composition in its
/// eight cells, and every state the reader reaches — first use, the list
/// and each filter, no match, a budget with no plan, one over its plan,
/// one that has not started, an archived one, a category, a month's
/// spending, the budget form and its validation, locked currency, the
/// spend and planned-purchase forms, the mark-bought and archive sheets,
/// the delete confirmation, the day-unavailable and damaged states,
/// loading and a storage failure.
///
/// The composition cells also write a `.flutter.png` beside the
/// browser's `.web.png` in
/// `docs/conversion_archive/shots/tools/tool_babybudget_default_pk/` for
/// `compare.mjs`. The reference draws one month from a USD fixture; here
/// the same figures are entered through the repository as a reader
/// would, with the plan the reference never had — a test fixture, and a
/// reader's Baby Budget starts empty.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/features/babybudget/domain/babybudget_model.dart';
import 'package:lume/features/babybudget/domain/babybudget_repository.dart';
import 'package:lume/features/babybudget/presentation/babybudget_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/domain/record_transaction.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../features/babybudget/babybudget_screen_harness.dart';
import '../features/tax/tax_harness.dart';
import '../helpers/capture.dart';
import '../helpers/load_fonts.dart';

const String kOut = '$kShotsDir/tools';

typedef Cell = (
  String name,
  Size size,
  ThemeMode theme,
  Locale locale,
  double scale,
);

const List<Cell> kCells = <Cell>[
  ('390x844_light_en', Size(390, 844), ThemeMode.light, Locale('en'), 1.0),
  ('390x844_dark_en', Size(390, 844), ThemeMode.dark, Locale('en'), 1.0),
  ('700x900_light_en', Size(700, 900), ThemeMode.light, Locale('en'), 1.0),
  ('1100x900_light_en', Size(1100, 900), ThemeMode.light, Locale('en'), 1.0),
  ('852x393_light_en', Size(852, 393), ThemeMode.light, Locale('en'), 1.0),
  ('390x844_light_ur', Size(390, 844), ThemeMode.light, Locale('ur'), 1.0),
  ('390x844_light_ar', Size(390, 844), ThemeMode.light, Locale('ar'), 1.0),
  ('390x844_light_en_x2', Size(390, 844), ThemeMode.light, Locale('en'), 2.0),
];

const Cell kPhone = (
  '390x844_light_en',
  Size(390, 844),
  ThemeMode.light,
  Locale('en'),
  1.0,
);

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadLumeFonts);

  Future<void> shoot(
    WidgetTester tester, {
    required String golden,
    required Cell cell,
    required BabyBudgetWorld world,
    LumeProfileRepository? profile,
    String query = '',
    List<Override> overrides = const <Override>[],
    Future<void> Function(WidgetTester tester)? after,
    bool compared = false,
  }) async {
    await captureLumeRoute(
      tester,
      location:
          '${LumeRoutes.tool(LumeRoutes.tools, 'babybudget')}'
          '${query.isEmpty ? '' : '?$query'}',
      name: golden,
      outDir: compared ? kOut : 'build/babybudget_shots',
      surface: cell.$2,
      theme: cell.$3,
      locale: cell.$4,
      textScale: cell.$5,
      suffix: cell.$5 == 1.0 ? '' : '_x${cell.$5.toStringAsFixed(0)}',
      profile: profile ?? taxProfile('default_pk'),
      overrides: <Override>[...world.overrides, ...overrides],
      after: after,
    );
    expect(find.byType(LumeToolFrame), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/${golden}_${cell.$1}.png'),
    );
    world.dispose();
  }

  group('Baby Budget — the reference composition', () {
    for (final Cell cell in kCells) {
      testWidgets('the dashboard, ${cell.$1}', (WidgetTester t) async {
        final BabyBudgetWorld w = BabyBudgetWorld().parity_();
        await shoot(
          t,
          golden: 'tool_babybudget_default_pk',
          cell: cell,
          world: w,
          query: 'budget=${w.budgets['The baby']!.value}',
          compared: true,
        );
      });
    }
  });

  group('Baby Budget — the states a reader reaches', () {
    Future<void> state(
      WidgetTester t,
      String name,
      BabyBudgetWorld world, {
      Future<void> Function(WidgetTester tester)? after,
      LumeProfileRepository? profile,
      String query = '',
      Cell cell = kPhone,
      List<Override> overrides = const <Override>[],
    }) => shoot(
      t,
      golden: 'tool_babybudget_$name',
      cell: cell,
      world: world,
      profile: profile,
      query: query,
      overrides: overrides,
      after: after,
    );

    testWidgets('first use: nothing seeded', (WidgetTester t) async {
      await state(t, 'empty', BabyBudgetWorld());
    });

    testWidgets('the list, with one budget', (WidgetTester t) async {
      await state(t, 'list', BabyBudgetWorld()..parity_());
    });

    testWidgets('the list, filtered to archived', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld()..parity_();
      w.repo.setArchived(
        w.budgets['The baby']!,
        true,
        on: BabyBudgetWorld.today,
        today: BabyBudgetWorld.today,
        version: w.view(w.budgets['The baby']!).budget.version,
      );
      await state(
        t,
        'archived_list',
        w,
        after: (WidgetTester t) => tapShown(
          t,
          find.byKey(LumeBabyBudgetTool.filterChip(BabyFilter.archived)),
        ),
      );
    });

    testWidgets('no match', (WidgetTester t) async {
      await state(
        t,
        'no_match',
        BabyBudgetWorld()..parity_(),
        after: (WidgetTester t) async {
          await t.enterText(
            find.byKey(LumeBabyBudgetTool.searchKey),
            'nothing like this',
          );
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('a budget with no plan: no ratio and no ring', (
      WidgetTester t,
    ) async {
      final BabyBudgetWorld w = BabyBudgetWorld();
      w.add(name: 'No plan', noPlan: true);
      w.spend(w.budgets['No plan']!, 4200, category: 'Health');
      await state(
        t,
        'no_plan',
        w,
        query: 'budget=${w.budgets['No plan']!.value}',
      );
    });

    testWidgets('a month over its plan, said as over by', (
      WidgetTester t,
    ) async {
      final BabyBudgetWorld w = BabyBudgetWorld();
      w.add(name: 'Over', plan: babyRs(20000));
      w.spend(w.budgets['Over']!, 23000, category: 'Nappies & wipes');
      await state(t, 'over', w, query: 'budget=${w.budgets['Over']!.value}');
    });

    testWidgets('a budget that has not started yet', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld();
      w.add(name: 'Later', startedOn: babyDay(12, 1));
      await state(
        t,
        'not_started',
        w,
        query: 'budget=${w.budgets['Later']!.value}',
      );
    });

    testWidgets('an archived budget keeps its figures', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld()..parity_();
      w.repo.setArchived(
        w.budgets['The baby']!,
        true,
        on: BabyBudgetWorld.today,
        today: BabyBudgetWorld.today,
        version: w.view(w.budgets['The baby']!).budget.version,
      );
      await state(
        t,
        'archived',
        w,
        query: 'budget=${w.budgets['The baby']!.value}',
      );
    });

    testWidgets('one category and its own spends', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld()..parity_();
      await state(
        t,
        'category',
        w,
        query: 'budget=${w.budgets['The baby']!.value}',
        after: (WidgetTester t) => tapShown(
          t,
          find.byKey(
            LumeBabyBudgetTool.categoryRow(
              w.category(w.budgets['The baby']!, 'Nappies & wipes').id.value,
            ),
          ),
        ),
      );
    });

    testWidgets('a month\'s spending, with its month picker', (
      WidgetTester t,
    ) async {
      final BabyBudgetWorld w = BabyBudgetWorld()..parity_();
      await state(
        t,
        'spending',
        w,
        query: 'budget=${w.budgets['The baby']!.value}',
        after: (WidgetTester t) async {
          final AppLocalizations l = AppLocalizations.of(
            t.element(find.byKey(LumeBabyBudgetTool.budgetKey)),
          );
          await tapShown(t, find.text(l.commonAll));
        },
      );
    });

    testWidgets('the budget form, empty', (WidgetTester t) async {
      await state(
        t,
        'form',
        BabyBudgetWorld(),
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeBabyBudgetTool.addKey)),
      );
    });

    testWidgets('the budget form, refusing a plan of zero', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'form_invalid',
        BabyBudgetWorld(),
        after: (WidgetTester t) async {
          await tapShown(t, find.byKey(LumeBabyBudgetTool.addKey));
          await t.enterText(find.byKey(LumeBabyBudgetTool.planField), '0');
          await t.pumpAndSettle();
          await tapShown(t, find.byKey(LumeBabyBudgetTool.saveKey));
        },
      );
    });

    testWidgets('the budget form, its currency fixed by a spend', (
      WidgetTester t,
    ) async {
      final BabyBudgetWorld w = BabyBudgetWorld()..parity_();
      await state(
        t,
        'form_locked',
        w,
        query: 'budget=${w.budgets['The baby']!.value}',
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeBabyBudgetTool.editKey)),
      );
    });

    testWidgets('the spend form', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld()..parity_();
      await state(
        t,
        'spend_form',
        w,
        query: 'budget=${w.budgets['The baby']!.value}',
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeBabyBudgetTool.spendKey)),
      );
    });

    testWidgets('the planned purchase form, whose day may be empty', (
      WidgetTester t,
    ) async {
      final BabyBudgetWorld w = BabyBudgetWorld()..parity_();
      await state(
        t,
        'plan_form',
        w,
        query: 'budget=${w.budgets['The baby']!.value}',
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeBabyBudgetTool.planKey)),
      );
    });

    testWidgets('the sheet that turns a plan into a spend', (
      WidgetTester t,
    ) async {
      final BabyBudgetWorld w = BabyBudgetWorld()..parity_();
      final BabySpend restock = w.view(w.budgets['The baby']!).comingUp.first;
      await state(
        t,
        'bought_sheet',
        w,
        query: 'budget=${w.budgets['The baby']!.value}',
        after: (WidgetTester t) async {
          await tapShown(
            t,
            find.byKey(LumeBabyBudgetTool.entry(restock.id.value)),
          );
          final AppLocalizations l = AppLocalizations.of(
            t.element(find.byKey(LumeBabyBudgetTool.budgetKey)),
          );
          await tapShown(t, find.text(l.babyMarkBought));
        },
      );
    });

    testWidgets('the archive confirmation', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld()..parity_();
      await state(
        t,
        'archive_sheet',
        w,
        query: 'budget=${w.budgets['The baby']!.value}',
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeBabyBudgetTool.archiveKey)),
      );
    });

    testWidgets('the delete confirmation, saying what would go', (
      WidgetTester t,
    ) async {
      final BabyBudgetWorld w = BabyBudgetWorld()..parity_();
      await state(
        t,
        'delete_sheet',
        w,
        query: 'budget=${w.budgets['The baby']!.value}',
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeBabyBudgetTool.deleteKey)),
      );
    });

    testWidgets('the day cannot be worked out', (WidgetTester t) async {
      await state(
        t,
        'day_unknown',
        BabyBudgetWorld()..parity_(),
        profile: LumeMemoryProfileRepository(
          initial: taxReader(country: 'US', region: 'New York', city: ''),
        ),
      );
    });

    testWidgets('a record that cannot be read', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld()..parity_();
      final BabySpend s = w.view(w.budgets['The baby']!).spends.first;
      w.store.run<void>(
        (LumeRecordTx tx) => tx.update(
          BabyBudgetCollections.spends,
          s.id.value,
          <String, Object?>{...s.toFields(), 'spentOn': 'whenever'},
          expectVersion: s.version,
        ),
      );
      await state(
        t,
        'damaged',
        w,
        query: 'budget=${w.budgets['The baby']!.value}',
      );
    });

    testWidgets('the records are still being read', (WidgetTester t) async {
      await state(
        t,
        'loading',
        BabyBudgetWorld(readDelay: const Duration(seconds: 30)),
      );
    });

    testWidgets('the store would not answer', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld();
      // The collections are already read, so mark one unreadable and
      // make the tool ask for it again.
      w.store.retry(BabyBudgetCollections.spends);
      w.store.unreadable.add(BabyBudgetCollections.spends);
      w.store.retry(BabyBudgetCollections.spends);
      await state(t, 'storage_failure', w);
    });
  });

  group('Baby Budget — a second currency', () {
    testWidgets('each currency keeps its own totals, and every amount '
        'carries its code', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld()..parity_();
      final LumeCurrency gbp = LumeCurrency.of('GBP');
      final BabyBudget other = w.add(
        name: 'In London',
        currency: gbp,
        plan: LumeMoney.entry(30000, gbp),
        categories: const <BabyCategoryDraft>[
          BabyCategoryDraft(name: 'Nappies'),
        ],
      );
      expect(other.currency.code, 'GBP');
      await shoot(
        t,
        golden: 'tool_babybudget_two_currencies',
        cell: kPhone,
        world: w,
      );
    });
  });
}

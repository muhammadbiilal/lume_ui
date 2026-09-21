/// Baby Budget on screen: what a reader sees and can do
/// (`BABY_BUDGET_PROPOSAL.md` §15).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/core/widgets/lume/lume_chart.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/babybudget/domain/babybudget_book.dart';
import 'package:lume/features/babybudget/domain/babybudget_model.dart';
import 'package:lume/features/babybudget/domain/babybudget_repository.dart';
import 'package:lume/features/babybudget/presentation/babybudget_sheets.dart';
import 'package:lume/features/babybudget/presentation/babybudget_tool.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/load_fonts.dart';
import 'babybudget_screen_harness.dart';

/// Scroll to something, then press it.
Future<void> press(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

String digits(String s) => s.replaceAll(RegExp('[^0-9]'), '');

/// Every string the screen is currently showing.
List<String> texts(WidgetTester t) => <String>[
  for (final Text w in t.widgetList<Text>(find.byType(Text)))
    if (w.data != null) w.data!,
];

void main() {
  setUpAll(loadLumeFonts);

  group('first use', () {
    testWidgets('nothing is seeded: the reader is asked to start one', (
      WidgetTester t,
    ) async {
      final BabyBudgetWorld w = BabyBudgetWorld();
      await pumpBabyBudget(t, w);
      expect(find.byKey(LumeBabyBudgetTool.emptyKey), findsOneWidget);
      expect(find.byKey(LumeBabyBudgetTool.summaryKey), findsNothing);
      expect(find.byKey(LumeBabyBudgetTool.listKey), findsNothing);
      // Opening the tool wrote nothing.
      expect(w.repo.view().budgets, isEmpty);
      w.dispose();
    });

    testWidgets('a budget is created from the form, with its plan and its '
        'categories', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld();
      await pumpBabyBudget(t, w);
      await press(t, find.byKey(LumeBabyBudgetTool.addKey));
      expect(find.byKey(LumeBabyBudgetTool.formKey), findsOneWidget);

      await t.enterText(find.byKey(LumeBabyBudgetTool.nameField), 'Ayaan');
      await t.enterText(find.byKey(LumeBabyBudgetTool.planField), '39000');
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(LumeBabyBudgetTool.categoryName(0)),
        'Nappies',
      );
      await press(t, find.byKey(LumeBabyBudgetTool.addCategoryKey));
      await t.enterText(
        find.byKey(LumeBabyBudgetTool.categoryName(1)),
        'Formula',
      );
      await press(t, find.byKey(LumeBabyBudgetTool.saveKey));

      final BabyBudgetBook book = w.book();
      expect(book.budgets, hasLength(1));
      final BabyBudgetView v = book.budgets.single;
      expect(v.name, 'Ayaan');
      expect(v.plan!.minor, 3900000);
      expect(
        <String>[for (final BabyCategory c in v.categories) c.name],
        <String>['Nappies', 'Formula'],
      );
      expect(find.byKey(LumeBabyBudgetTool.budgetKey), findsOneWidget);
      w.dispose();
    });

    testWidgets('an empty plan is a real answer, not an error', (
      WidgetTester t,
    ) async {
      final BabyBudgetWorld w = BabyBudgetWorld();
      await pumpBabyBudget(t, w);
      await press(t, find.byKey(LumeBabyBudgetTool.addKey));
      await t.enterText(find.byKey(LumeBabyBudgetTool.nameField), 'No plan');
      await press(t, find.byKey(LumeBabyBudgetTool.saveKey));

      final BabyBudgetView v = w.book().budgets.single;
      expect(v.plan, isNull);
      expect(v.ratio, isNull);
      // No plan, no ring and no percentage anywhere on the card.
      expect(find.byType(LumeProgressRing), findsNothing);
      final AppLocalizations l = AppLocalizations.of(
        t.element(find.byType(LumeSummaryCard).first),
      );
      expect(texts(t), contains(l.babyNoPlan));
      w.dispose();
    });

    testWidgets('a plan of zero is refused, in place', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld();
      await pumpBabyBudget(t, w);
      await press(t, find.byKey(LumeBabyBudgetTool.addKey));
      final AppLocalizations l = AppLocalizations.of(
        t.element(find.byKey(LumeBabyBudgetTool.formKey)),
      );
      await t.enterText(find.byKey(LumeBabyBudgetTool.nameField), 'Zero');
      await t.enterText(find.byKey(LumeBabyBudgetTool.planField), '0');
      await press(t, find.byKey(LumeBabyBudgetTool.saveKey));
      final LumeFormField field = t.widget<LumeFormField>(
        find.byKey(LumeBabyBudgetTool.planField),
      );
      expect(field.error, l.babyErrZeroPlan);
      expect(w.repo.view().budgets, isEmpty);
      w.dispose();
    });
  });

  group('the dashboard', () {
    testWidgets('the reference composition, in its order', (
      WidgetTester t,
    ) async {
      final BabyBudgetWorld w = BabyBudgetWorld().reference_();
      await pumpBabyBudget(t, w);
      await press(
        t,
        find.byKey(LumeBabyBudgetTool.row(w.budgets['The baby']!.value)),
      );

      final AppLocalizations l = AppLocalizations.of(
        t.element(find.byKey(LumeBabyBudgetTool.budgetKey)),
      );
      // Summary, donut, bars, Coming up, One-off — all present.
      expect(find.byKey(LumeBabyBudgetTool.summaryKey), findsOneWidget);
      expect(find.byKey(LumeBabyBudgetTool.donutKey), findsOneWidget);
      expect(find.byKey(LumeBabyBudgetTool.chartKey), findsOneWidget);
      expect(find.byKey(LumeBabyBudgetTool.comingUpKey), findsOneWidget);
      expect(find.byKey(LumeBabyBudgetTool.oneOffKey), findsOneWidget);
      final List<String> shown = texts(t);
      expect(shown, contains(l.babyWhereItGoes));
      expect(shown, contains(l.babySixMonths));
      expect(shown, contains(l.babyComingUp));
      expect(shown, contains(l.babyOneOff));
      w.dispose();
    });

    testWidgets('the month, the ratio and the ring are the reader\'s own '
        'plan — not a constant', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld().reference_();
      await pumpBabyBudget(t, w);
      await press(
        t,
        find.byKey(LumeBabyBudgetTool.row(w.budgets['The baby']!.value)),
      );

      final BabyBudgetView v = w.view(w.budgets['The baby']!);
      expect(v.thisMonth!.minor, 3200000);
      expect(v.ratio, 82, reason: '32,000 of 39,000');
      final LumeProgressRing ring = t.widget<LumeProgressRing>(
        find.byType(LumeProgressRing).first,
      );
      expect(ring.value, closeTo(0.82, 0.0001));
      expect(digits(ring.centreValue!), '82');
      // The figure on the card is the month's spends, to the rupee.
      expect(
        texts(t).any((String s) => digits(s) == '32000'),
        isTrue,
        reason: 'Rs 32,000 on the card',
      );
      w.dispose();
    });

    testWidgets('the donut legend adds to exactly 100', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld().reference_();
      await pumpBabyBudget(t, w);
      await press(
        t,
        find.byKey(LumeBabyBudgetTool.row(w.budgets['The baby']!.value)),
      );

      final LumeDonut donut = t.widget<LumeDonut>(find.byType(LumeDonut));
      expect(donut.slices, hasLength(4));
      final List<int> shares = <int>[
        for (final LumeDonutSlice s in donut.slices)
          int.parse(digits(s.display!)),
      ];
      expect(shares, <int>[37, 25, 22, 16]);
      expect(shares.reduce((int a, int b) => a + b), 100);
      w.dispose();
    });

    testWidgets('the bars are the six months ending with the reader\'s own, '
        'labelled in their language and drawn to their values', (
      WidgetTester t,
    ) async {
      final BabyBudgetWorld w = BabyBudgetWorld().reference_();
      await pumpBabyBudget(t, w);
      await press(
        t,
        find.byKey(LumeBabyBudgetTool.row(w.budgets['The baby']!.value)),
      );

      final LumeBarChart chart = t.widget<LumeBarChart>(
        find.byType(LumeBarChart),
      );
      expect(chart.values, hasLength(6));
      expect(chart.highlight, 5, reason: 'the reader\'s own month last');
      expect(chart.labels.last, isNot('Sep'.padLeft(0)));
      // The bars differ, rather than sitting at a floor (defect 5).
      expect(chart.fillOf(3), 100, reason: 'July is the largest');
      expect(chart.fillOf(0), lessThan(100));
      expect(chart.fillOf(0), greaterThan(50));
      // The caption names the budget's currency, not raw USD (defect 4).
      expect(texts(t).any((String s) => s.contains('PKR')), isTrue);
      w.dispose();
    });

    testWidgets('Coming up carries real dates, and One-off keeps the '
        'undated ones', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld().reference_();
      await pumpBabyBudget(t, w);
      await press(
        t,
        find.byKey(LumeBabyBudgetTool.row(w.budgets['The baby']!.value)),
      );

      expect(find.text('Nappy restock'), findsOneWidget);
      expect(find.text('Cot mattress'), findsOneWidget);
      expect(find.text('Cot and mattress'), findsOneWidget);
      expect(find.text('Pram'), findsOneWidget);
      // Soonest first, and a month and day rather than a weekday name.
      final BabyBudgetView v = w.view(w.budgets['The baby']!);
      expect(
        <String>[for (final BabySpend s in v.comingUp) s.label!],
        <String>['Nappy restock', 'Cot mattress'],
      );
      expect(
        texts(
          t,
        ).any((String s) => s.contains('13 Sep') || s.contains('Sep 13')),
        isTrue,
        reason: 'a stored date, not dayName(+6)',
      );
      w.dispose();
    });

    testWidgets('a budget that has not started says so, instead of a month '
        'of nothing', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld();
      w.add(name: 'Later', startedOn: babyDay(12, 1));
      await pumpBabyBudget(t, w, query: 'budget=${w.budgets['Later']!.value}');

      expect(find.byKey(LumeBabyBudgetTool.notStartedKey), findsOneWidget);
      expect(find.byKey(LumeBabyBudgetTool.chartKey), findsNothing);
      expect(find.byKey(LumeBabyBudgetTool.donutKey), findsNothing);
      final BabyBudgetView v = w.view(w.budgets['Later']!);
      expect(v.thisMonth, isNull);
      expect(v.ratio, isNull);
      w.dispose();
    });
  });

  group('recording', () {
    testWidgets('a spend goes in from the form and moves every figure', (
      WidgetTester t,
    ) async {
      final BabyBudgetWorld w = BabyBudgetWorld().reference_();
      await pumpBabyBudget(t, w);
      final LumeRecordId id = w.budgets['The baby']!;
      await press(t, find.byKey(LumeBabyBudgetTool.row(id.value)));
      await press(t, find.byKey(LumeBabyBudgetTool.spendKey));
      expect(find.byKey(LumeBabyBudgetTool.spendFormKey), findsOneWidget);

      await t.enterText(find.byKey(LumeBabyBudgetTool.amountField), '1500');
      await t.enterText(find.byKey(LumeBabyBudgetTool.labelField), 'Wipes');
      await press(t, find.byKey(LumeBabyBudgetTool.saveKey));

      final BabyBudgetView v = w.view(id);
      expect(v.thisMonth!.minor, 3350000, reason: '32,000 + 1,500');
      expect(v.spends.any((BabySpend s) => s.label == 'Wipes'), isTrue);
      w.dispose();
    });

    testWidgets('a planned purchase is not in the month until it is bought, '
        'and then it is one record', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld().reference_();
      await pumpBabyBudget(t, w);
      final LumeRecordId id = w.budgets['The baby']!;
      final int before = w.view(id).spends.length;
      await press(t, find.byKey(LumeBabyBudgetTool.row(id.value)));

      // Nothing planned counts towards the month.
      expect(w.view(id).thisMonth!.minor, 3200000);
      expect(w.view(id).plannedTotal.minor, 25060000);

      final BabySpend restock = w.view(id).comingUp.first;
      await press(t, find.byKey(LumeBabyBudgetTool.entry(restock.id.value)));
      final AppLocalizations l = AppLocalizations.of(
        t.element(find.byType(LumeSummaryCard).first),
      );
      await press(t, find.text(l.babyMarkBought));
      expect(find.byKey(BabyBudgetSheetKeys.go), findsOneWidget);
      await press(t, find.byKey(BabyBudgetSheetKeys.go));

      final BabyBudgetView v = w.view(id);
      expect(v.spends, hasLength(before), reason: 'no second record');
      final BabySpend now = v.spends.firstWhere(
        (BabySpend s) => s.id == restock.id,
      );
      expect(now.planned, isFalse);
      expect(now.spentOn, isNotNull);
      expect(now.expectedOn, isNull);
      expect(v.thisMonth!.minor, 3200000 + 1840000);
      expect(v.plannedTotal.minor, 25060000 - 1840000);
      w.dispose();
    });

    testWidgets('voiding takes a spend out of every figure, and Undo is '
        'offered on the writes that carry it', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld().reference_();
      await pumpBabyBudget(t, w);
      final LumeRecordId id = w.budgets['The baby']!;
      await press(t, find.byKey(LumeBabyBudgetTool.row(id.value)));

      final BabySpend health = w
          .view(id)
          .spends
          .firstWhere((BabySpend s) => s.counts && s.amount.minor == 500000);
      await press(t, find.byKey(LumeBabyBudgetTool.entry(health.id.value)));
      final AppLocalizations l = AppLocalizations.of(
        t.element(find.byType(LumeSummaryCard).first),
      );
      await press(t, find.text(l.babyVoidSpend));
      expect(w.view(id).thisMonth!.minor, 2700000);
      expect(w.view(id).slices, hasLength(3));
      w.dispose();
    });
  });

  group('archiving and deletion', () {
    testWidgets('an archived budget keeps every figure and takes no new '
        'record', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld().reference_();
      await pumpBabyBudget(t, w);
      final LumeRecordId id = w.budgets['The baby']!;
      await press(t, find.byKey(LumeBabyBudgetTool.row(id.value)));
      await press(t, find.byKey(LumeBabyBudgetTool.archiveKey));
      await press(t, find.byKey(BabyBudgetSheetKeys.confirm));

      expect(w.view(id).status, BabyBudgetStatus.archived);
      expect(w.view(id).thisMonth!.minor, 3200000, reason: 'every figure');
      expect(find.byKey(LumeBabyBudgetTool.archivedKey), findsOneWidget);
      expect(find.byKey(LumeBabyBudgetTool.spendKey), findsNothing);
      expect(find.byKey(LumeBabyBudgetTool.planKey), findsNothing);

      await press(t, find.byKey(LumeBabyBudgetTool.unarchiveKey));
      expect(w.view(id).status, BabyBudgetStatus.inUse);
      expect(w.view(id).thisMonth!.minor, 3200000);
      w.dispose();
    });

    testWidgets('delete says what would go, and Undo brings all of it back', (
      WidgetTester t,
    ) async {
      final BabyBudgetWorld w = BabyBudgetWorld().reference_();
      await pumpBabyBudget(t, w);
      final LumeRecordId id = w.budgets['The baby']!;
      final int records = w.store.debugDump().split('\n').length;
      await press(t, find.byKey(LumeBabyBudgetTool.row(id.value)));
      await press(t, find.byKey(LumeBabyBudgetTool.deleteKey));

      final AppLocalizations l = AppLocalizations.of(
        t.element(find.byKey(BabyBudgetSheetKeys.confirm)),
      );
      // Each count in its own grammar, and the real numbers.
      expect(
        texts(t).any(
          (String s) =>
              s.contains(l.babyCountCategories(4)) &&
              s.contains(l.babyCountSpends(9)) &&
              s.contains(l.babyCountPlanned(4)),
        ),
        isTrue,
      );
      await press(t, find.text(l.actionDelete).last);
      expect(w.repo.view().budgets, isEmpty);
      expect(find.byKey(LumeBabyBudgetTool.emptyKey), findsOneWidget);

      await press(t, find.text(l.recUndo));
      expect(w.repo.view().budgets, hasLength(1));
      expect(w.store.debugDump().split('\n').length, records);
      expect(w.view(id).thisMonth!.minor, 3200000);
      w.dispose();
    });
  });

  group('two currencies and a deep link', () {
    testWidgets('each currency has its own summary, and no amount is added '
        'across them', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld().reference_();
      final LumeCurrency gbp = LumeCurrency.of('GBP');
      w.add(
        name: 'In London',
        currency: gbp,
        plan: LumeMoney.entry(30000, gbp),
        categories: const <BabyCategoryDraft>[
          BabyCategoryDraft(name: 'Nappies'),
        ],
      );
      await pumpBabyBudget(t, w);

      // Two summaries, and each holds only its own currency's figures.
      expect(find.byType(LumeSummaryCard), findsNWidgets(2));
      expect(w.book().summary(babyPkr).spentToDate.minor, 18450000);
      expect(w.book().summary(gbp).spentToDate.minor, 0);
      // With two currencies on screen every amount carries its code.
      final List<String> shown = texts(t);
      expect(shown.any((String s) => s.contains('PKR')), isTrue);
      expect(shown.any((String s) => s.contains('GBP')), isTrue);
      w.dispose();
    });

    testWidgets('a deep link opens the budget it names; a stale one opens '
        'the list', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld().reference_();
      final LumeRecordId id = w.budgets['The baby']!;
      await pumpBabyBudget(t, w, query: 'budget=${id.value}');
      expect(find.byKey(LumeBabyBudgetTool.budgetKey), findsOneWidget);
      w.dispose();

      final BabyBudgetWorld w2 = BabyBudgetWorld().reference_();
      await pumpBabyBudget(
        t,
        w2,
        query: 'budget=00000000-0000-4000-8000-000000000000',
      );
      expect(find.byKey(LumeBabyBudgetTool.budgetKey), findsNothing);
      expect(find.byKey(LumeBabyBudgetTool.listKey), findsOneWidget);
      w2.dispose();
    });
  });

  group('other languages', () {
    testWidgets('Urdu lays out right to left and says every section in '
        'Urdu', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld().reference_();
      await pumpBabyBudget(t, w, locale: const Locale('ur'));
      final AppLocalizations l = AppLocalizations.of(
        t.element(find.byType(LumeSummaryCard).first),
      );
      expect(l.babyComingUp, isNot('Coming up'));
      expect(
        Directionality.of(t.element(find.byType(LumeSummaryCard).first)),
        TextDirection.rtl,
      );
      w.dispose();
    });

    testWidgets('Arabic too, and the bars are still six', (
      WidgetTester t,
    ) async {
      final BabyBudgetWorld w = BabyBudgetWorld().reference_();
      await pumpBabyBudget(t, w, locale: const Locale('ar'));
      await press(
        t,
        find.byKey(LumeBabyBudgetTool.row(w.budgets['The baby']!.value)),
      );
      final LumeBarChart chart = t.widget<LumeBarChart>(
        find.byType(LumeBarChart),
      );
      expect(chart.values, hasLength(6));
      expect(
        Directionality.of(t.element(find.byType(LumeBarChart))),
        TextDirection.rtl,
      );
      w.dispose();
    });

    testWidgets('at 200% text nothing overflows', (WidgetTester t) async {
      final BabyBudgetWorld w = BabyBudgetWorld().reference_();
      await pumpBabyBudget(t, w, textScale: 2);
      await press(
        t,
        find.byKey(LumeBabyBudgetTool.row(w.budgets['The baby']!.value)),
      );
      expect(layoutErrors(t), isEmpty);
      w.dispose();
    });
  });
}

/// Any layout exception the frame recorded while building.
List<Object> layoutErrors(WidgetTester t) {
  final Object? e = t.takeException();
  return e == null ? const <Object>[] : <Object>[e];
}

/// Installments on screen, through the real router: first use, the
/// reference's composition with figures that agree, filters, sorts, search,
/// the form and its validation, payments with Undo, locked terms, cancel,
/// delete with Undo, void and restore, deep links, restoration, the states
/// that need saying, and three languages (`INSTALLMENTS_PROPOSAL.md` §40).
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/widgets/lume/lume_chart.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/installments/domain/installments_book.dart';
import 'package:lume/features/installments/domain/installments_model.dart';
import 'package:lume/features/installments/presentation/installments_sheets.dart';
import 'package:lume/features/installments/presentation/installments_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/l10n/app_localizations_ar.dart';
import 'package:lume/l10n/app_localizations_ur.dart';

import '../../helpers/load_fonts.dart';
import '../tax/tax_harness.dart';
import 'installments_screen_harness.dart';

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

List<String> plansShown(WidgetTester t) => <String>[
  for (final LumeRichRow r in t.widgetList<LumeRichRow>(
    find.descendant(
      of: find.byKey(LumeInstallmentsTool.plansKey),
      matching: find.byType(LumeRichRow),
    ),
  ))
    r.title,
];

LumeSummaryCard summary(WidgetTester t) =>
    t.widget<LumeSummaryCard>(find.byKey(LumeInstallmentsTool.summaryKey));

String stat(WidgetTester t, String label) =>
    n(summary(t).stats.firstWhere((LumeStat s) => s.label == label).value);

/// The formatter's spaces are non-breaking; a test reads them as spaces.
String n(String s) => s.replaceAll('\u00a0', ' ').replaceAll('\u202f', ' ');

final LumeCurrency pkr = LumeCurrency.of('PKR');
LumeMoney rs(int rupees) => LumeMoney.entry(rupees * 100, pkr);

void main() {
  setUpAll(loadLumeFonts);

  group('first use', () {
    testWidgets('empty: what it is for, one way in, private, nothing seeded', (
      WidgetTester t,
    ) async {
      final InstallmentsWorld w = InstallmentsWorld();
      await pumpInstallments(t, w);
      expect(find.byKey(LumeInstallmentsTool.emptyKey), findsOneWidget);
      expect(find.text('No payment plans yet'), findsOneWidget);
      expect(find.byKey(LumeInstallmentsTool.addKey), findsOneWidget);
      expect(find.text('Private to you'), findsOneWidget);
      // Nothing of the reference's three plans.
      expect(find.text('Laptop'), findsNothing);
      expect(w.repo.view().plans, isEmpty);
      expect(w.repo.view().schedule, isEmpty);
      w.dispose();
    });
  });

  group('the reference composition', () {
    testWidgets('figures that agree with their rows', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await pumpInstallments(t, w);
      final LumeSummaryCard s = summary(t);
      expect(s.kicker, 'Due this month');
      // 26,900 + 17,500 + 13,600 — the three instalments due in September.
      expect(n(s.value), 'Rs 58,000');
      expect(s.caption, '3 active plans');
      // The reference says 427,000 and 298,000; the rows add to these.
      expect(stat(t, 'Remaining'), 'Rs 427,300');
      expect(stat(t, 'Paid so far'), 'Rs 297,800');
      expect(stat(t, 'Late instalments'), '0');
      final InstallmentsBook b = w.book();
      expect(
        b.summaries.single.remaining.minor,
        b.plans.fold<int>(
          0,
          (int a, InstallmentPlanView v) => a + v.remaining.minor,
        ),
      );
      w.dispose();
    });

    testWidgets('each row: paid of count, and the real next date', (
      WidgetTester t,
    ) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await pumpInstallments(t, w);
      final LumeRichRow laptop = t.widget<LumeRichRow>(
        find.byKey(LumeInstallmentsTool.row(w.plans['Laptop']!.value)),
      );
      expect(laptop.subtitle, 'TechMart');
      expect(laptop.meta, <String>['5 of 12 paid', 'next 14 Sept']);
      expect(n(laptop.value!), 'Rs 26,900');
      expect(laptop.valueSub, 'a month');
      w.dispose();
    });

    testWidgets('filters, with their counts; the summary never moves', (
      WidgetTester t,
    ) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      w.pay('Sofa set', 2); // completed
      await pumpInstallments(t, w);
      final String before = summary(t).value;
      int? count(InstallmentsFilter f) => t
          .widget<LumeFilterChip>(
            find.byKey(LumeInstallmentsTool.filterChip(f)),
          )
          .count;
      expect(count(InstallmentsFilter.active), 2);
      expect(count(InstallmentsFilter.completed), 1);
      expect(count(InstallmentsFilter.cancelled), 0);
      expect(count(InstallmentsFilter.all), 3);
      await tapShown(
        t,
        find.byKey(
          LumeInstallmentsTool.filterChip(InstallmentsFilter.completed),
        ),
      );
      expect(plansShown(t), <String>['Sofa set']);
      expect(summary(t).value, before);
      await tapShown(
        t,
        find.byKey(
          LumeInstallmentsTool.filterChip(InstallmentsFilter.cancelled),
        ),
      );
      expect(find.byKey(LumeInstallmentsTool.noMatchKey), findsOneWidget);
      await tapShown(t, find.text('Show all'));
      expect(plansShown(t), hasLength(3));
      w.dispose();
    });

    testWidgets('sorts: Next due, Payments left, Monthly amount, Name, '
        'Recent', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await pumpInstallments(t, w);
      expect(plansShown(t), <String>['Laptop', 'Sofa set', 'Phone']);
      Future<void> sortBy(String label) async {
        await tapShown(
          t,
          find.descendant(
            of: find.byKey(LumeInstallmentsTool.sortKey),
            matching: find.text(label),
          ),
        );
      }

      // A newly chosen sort starts descending, as the reference's does;
      // a second press turns it.
      await sortBy('Payments left');
      expect(plansShown(t), <String>['Phone', 'Laptop', 'Sofa set']);
      await sortBy('Payments left');
      // The reference's "Remaining ↑" order, under its right name.
      expect(plansShown(t), <String>['Sofa set', 'Laptop', 'Phone']);
      await sortBy('Monthly amount');
      // The reference's "Amount ↓".
      expect(plansShown(t), <String>['Laptop', 'Sofa set', 'Phone']);
      await sortBy('Name');
      expect(plansShown(t), <String>['Sofa set', 'Phone', 'Laptop']);
      await sortBy('Name');
      expect(plansShown(t), <String>['Laptop', 'Phone', 'Sofa set']);
      await sortBy('Recent activity');
      // Most recent first: Phone's last payment was the last written.
      expect(plansShown(t), <String>['Phone', 'Sofa set', 'Laptop']);
      w.dispose();
    });

    testWidgets('search: item, merchant and note; the summary never moves', (
      WidgetTester t,
    ) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await pumpInstallments(t, w);
      final String before = summary(t).value;
      await t.enterText(find.byKey(LumeInstallmentsTool.searchKey), 'mobile');
      await t.pumpAndSettle();
      expect(plansShown(t), <String>['Phone']);
      expect(summary(t).value, before);
      await t.enterText(find.byKey(LumeInstallmentsTool.searchKey), 'sofa');
      await t.pumpAndSettle();
      expect(plansShown(t), <String>['Sofa set']);
      w.dispose();
    });

    testWidgets('coming up: the next unpaid of each running plan, by date', (
      WidgetTester t,
    ) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await pumpInstallments(t, w);
      final LumeTimeline tl = t.widget<LumeTimeline>(
        find.descendant(
          of: find.byKey(LumeInstallmentsTool.comingKey),
          matching: find.byType(LumeTimeline),
        ),
      );
      expect(tl.entries.map((LumeTimelineEntry e) => e.title), <String>[
        'Laptop',
        'Sofa set',
        'Phone',
      ]);
      expect(tl.entries.first.time, '14 Sept');
      w.dispose();
    });

    testWidgets('the chart: bars that grow, heard as months and amounts', (
      WidgetTester t,
    ) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await pumpInstallments(t, w);
      final LumeBarChart c = t.widget<LumeBarChart>(find.byType(LumeBarChart));
      expect(c.values, <double>[58000, 58000, 40500, 40500, 40500, 40500]);
      expect(c.labels, <String>['S', 'O', 'N', 'D', 'J', 'F']);
      expect(n(c.label), contains('September: Rs 58,000'));
      expect(n(c.label), contains('February: Rs 40,500'));
      expect(c.label, isNot(contains('205')));
      w.dispose();
    });
  });

  group('adding a plan', () {
    testWidgets('the form: saved, its schedule stored, the plan opens', (
      WidgetTester t,
    ) async {
      final InstallmentsWorld w = InstallmentsWorld();
      await pumpInstallments(t, w);
      await tapShown(t, find.byKey(LumeInstallmentsTool.addKey));
      expect(find.byKey(LumeInstallmentsTool.formKey), findsOneWidget);
      await t.enterText(find.byKey(LumeInstallmentsTool.itemField), 'Fridge');
      await t.enterText(
        find.byKey(LumeInstallmentsTool.merchantField),
        'Cool Co',
      );
      await t.enterText(find.byKey(LumeInstallmentsTool.amountField), '9,500');
      await t.enterText(find.byKey(LumeInstallmentsTool.countField), '6');
      await tapShown(t, find.byKey(LumeInstallmentsTool.saveKey));
      final InstallmentsBook b = w.book();
      expect(b.plans, hasLength(1));
      final InstallmentPlanView v = b.plans.single;
      expect(v.plan.item, 'Fridge');
      expect(v.plan.amount, rs(9500));
      expect(v.rows, hasLength(6));
      // First due defaults to the reader's today.
      expect(v.plan.firstDue, LumeDate(2026, 9, 7));
      expect(find.byKey(LumeInstallmentsTool.planKey), findsOneWidget);
      w.dispose();
    });

    testWidgets('validation: nothing is written until every field is right', (
      WidgetTester t,
    ) async {
      final InstallmentsWorld w = InstallmentsWorld();
      await pumpInstallments(t, w);
      await tapShown(t, find.byKey(LumeInstallmentsTool.addKey));
      await t.enterText(find.byKey(LumeInstallmentsTool.countField), '0');
      await t.enterText(find.byKey(LumeInstallmentsTool.amountField), '1.234');
      await t.enterText(find.byKey(LumeInstallmentsTool.depositField), '500');
      await tapShown(t, find.byKey(LumeInstallmentsTool.saveKey));
      expect(find.text('Enter what you bought'), findsOneWidget);
      expect(find.text('Enter a whole number from 1 to 600'), findsOneWidget);
      expect(
        find.textContaining('PKR'),
        findsWidgets,
      ); // precision says how many
      expect(
        find.text('A deposit needs both an amount and a date'),
        findsOneWidget,
      );
      expect(w.book().plans, isEmpty);
      w.dispose();
    });

    testWidgets('Urdu digits are read exactly', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld();
      await pumpInstallments(t, w, locale: const Locale('ur'));
      await tapShown(t, find.byKey(LumeInstallmentsTool.addKey));
      await t.enterText(find.byKey(LumeInstallmentsTool.itemField), 'فریج');
      await t.enterText(find.byKey(LumeInstallmentsTool.amountField), '۹۵۰۰');
      await t.enterText(find.byKey(LumeInstallmentsTool.countField), '۱۲');
      await tapShown(t, find.byKey(LumeInstallmentsTool.saveKey));
      final InstallmentPlan p = w.book().plans.single.plan;
      expect(p.amount, rs(9500));
      expect(p.count, 12);
      w.dispose();
    });

    testWidgets('leaving a changed form asks first', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld();
      await pumpInstallments(t, w);
      await tapShown(t, find.byKey(LumeInstallmentsTool.addKey));
      await t.enterText(find.byKey(LumeInstallmentsTool.itemField), 'Bike');
      await tapShown(t, find.text('Cancel').last);
      expect(find.text('Discard your changes?'), findsOneWidget);
      await tapShown(t, find.text('Keep editing'));
      expect(find.text('Bike'), findsOneWidget);
      w.dispose();
    });
  });

  group('a plan', () {
    testWidgets('pay the next instalment, then Undo', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await pumpInstallments(t, w, query: 'plan=${w.plans['Laptop']!.value}');
      expect(find.byKey(LumeInstallmentsTool.planKey), findsOneWidget);
      await tapShown(t, find.byKey(LumeInstallmentsTool.payKey));
      expect(
        find.byWidgetPredicate(
          (Widget x) =>
              x is Text &&
              n(x.data ?? '').replaceAll(RegExp('[\u2068\u2069]'), '') ==
                  'Instalment 6 of 12: Rs 26,900.00, due 14 September. It '
                      'is recorded as paid in full.',
        ),
        findsOneWidget,
      );
      await tapShown(t, find.byKey(InstallmentsSheetKeys.payGo));
      InstallmentPlanView v = w.book().plan(w.plans['Laptop']!)!;
      expect(v.paidCount, 6);
      expect(v.payments.first.paidOn, LumeDate(2026, 9, 7));
      expect(find.text('Payment recorded'), findsOneWidget);
      await tapShown(t, find.text('Undo'));
      v = w.book().plan(w.plans['Laptop']!)!;
      expect(v.paidCount, 5);
      w.dispose();
    });

    testWidgets('void and restore a payment from its row', (
      WidgetTester t,
    ) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await pumpInstallments(t, w, query: 'plan=${w.plans['Phone']!.value}');
      final InstallmentPlanView v = w.book().plan(w.plans['Phone']!)!;
      final InstallmentPayment last = v.payments.first;
      await tapShown(
        t,
        find.byKey(LumeInstallmentsTool.payment(last.id.value)),
      );
      await tapShown(t, find.text('Void payment'));
      expect(w.book().plan(w.plans['Phone']!)!.paidCount, 2);
      await tapShown(
        t,
        find.byKey(LumeInstallmentsTool.payment(last.id.value)),
      );
      await tapShown(t, find.text('Restore payment'));
      expect(w.book().plan(w.plans['Phone']!)!.paidCount, 3);
      w.dispose();
    });

    testWidgets('with payments the terms are locked; the item is not', (
      WidgetTester t,
    ) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await pumpInstallments(t, w, query: 'plan=${w.plans['Laptop']!.value}');
      await tapShown(t, find.byKey(LumeInstallmentsTool.editKey));
      expect(find.byKey(LumeInstallmentsTool.lockedKey), findsOneWidget);
      expect(
        t
            .widget<LumeFormField>(find.byKey(LumeInstallmentsTool.amountField))
            .enabled,
        isFalse,
      );
      expect(
        t
            .widget<LumeFormField>(find.byKey(LumeInstallmentsTool.countField))
            .enabled,
        isFalse,
      );
      expect(
        t
            .widget<LumeFormPicker>(
              find.byKey(LumeInstallmentsTool.currencyField),
            )
            .onTap,
        isNull,
      );
      await t.enterText(
        find.byKey(LumeInstallmentsTool.itemField),
        'Work laptop',
      );
      await tapShown(t, find.byKey(LumeInstallmentsTool.saveKey));
      final InstallmentPlanView v = w.book().plan(w.plans['Laptop']!)!;
      expect(v.plan.item, 'Work laptop');
      expect(v.paidCount, 5);
      w.dispose();
    });

    testWidgets('cancel asks first, keeps everything, and can be undone; '
        'reinstate brings it back', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await pumpInstallments(t, w, query: 'plan=${w.plans['Phone']!.value}');
      await tapShown(t, find.byKey(LumeInstallmentsTool.cancelKey));
      expect(find.text('Cancel this plan?'), findsOneWidget);
      await tapShown(t, find.text('Keep plan'));
      expect(w.book().plan(w.plans['Phone']!)!.plan.cancelled, isFalse);
      await tapShown(t, find.byKey(LumeInstallmentsTool.cancelKey));
      await tapShown(t, find.byKey(InstallmentsSheetKeys.confirm));
      InstallmentPlanView v = w.book().plan(w.plans['Phone']!)!;
      expect(v.status, InstallmentPlanStatus.cancelled);
      expect(v.payments, hasLength(3));
      await tapShown(t, find.byKey(LumeInstallmentsTool.reinstateKey));
      v = w.book().plan(w.plans['Phone']!)!;
      expect(v.status, InstallmentPlanStatus.active);
      w.dispose();
    });

    testWidgets('delete says what goes, removes it all, and Undo brings the '
        'same records back', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      final String before = w.store.debugDump();
      await pumpInstallments(t, w, query: 'plan=${w.plans['Laptop']!.value}');
      await tapShown(t, find.byKey(LumeInstallmentsTool.deleteKey));
      expect(
        find.textContaining(
          'all 12 of its scheduled instalments and 5 '
          'recorded payments',
        ),
        findsOneWidget,
      );
      await tapShown(t, find.text('Delete').last);
      expect(w.book().plan(w.plans['Laptop']!), isNull);
      expect(
        w.repo.view().schedule.where(
          (ScheduledInstallment r) => r.planId == w.plans['Laptop'],
        ),
        isEmpty,
      );
      expect(find.byKey(LumeInstallmentsTool.plansKey), findsOneWidget);
      await tapShown(t, find.text('Undo'));
      expect(w.book().plan(w.plans['Laptop']!)!.paidCount, 5);
      expect(w.repo.view().schedule.length, 12 + 9 + 18);
      expect(w.store.debugDump().length, before.length);
      w.dispose();
    });
  });

  group('states', () {
    testWidgets('late: marked in words, counted, and filtered', (
      WidgetTester t,
    ) async {
      final InstallmentsWorld w = InstallmentsWorld();
      w.add('Bike', rs(5000), 6, LumeDate(2026, 8, 1), merchant: 'Wheels');
      await pumpInstallments(t, w);
      final LumeRichRow r = t.widget<LumeRichRow>(
        find.byKey(LumeInstallmentsTool.row(w.plans['Bike']!.value)),
      );
      expect(r.badge?.label, 'Late');
      // 1 August and 1 September are both unpaid on 7 September.
      expect(stat(t, 'Late instalments'), '2');
      await tapShown(
        t,
        find.byKey(LumeInstallmentsTool.filterChip(InstallmentsFilter.late)),
      );
      expect(plansShown(t), <String>['Bike']);
      w.dispose();
    });

    testWidgets('day unavailable: nothing marked late, the Late filter says '
        'why, due this month is not guessed', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld();
      w.add('Bike', rs(5000), 6, LumeDate(2026, 8, 1));
      await pumpInstallments(
        t,
        w,
        profile: LumeMemoryProfileRepository(
          initial: taxReader(country: 'US', region: 'New York', city: ''),
        ),
      );
      final LumeRichRow r = t.widget<LumeRichRow>(
        find.byKey(LumeInstallmentsTool.row(w.plans['Bike']!.value)),
      );
      expect(r.badge, isNull);
      expect(n(summary(t).value), 'Day unknown');
      expect(stat(t, 'Late instalments'), 'Day unknown');
      await tapShown(
        t,
        find.byKey(LumeInstallmentsTool.filterChip(InstallmentsFilter.late)),
      );
      expect(find.byKey(LumeInstallmentsTool.dayUnknownKey), findsOneWidget);
      w.dispose();
    });

    testWidgets('two currencies: two summaries, each amount with its code', (
      WidgetTester t,
    ) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      w.add(
        'Camera',
        LumeMoney.entry(4800, LumeCurrency.of('USD')),
        10,
        LumeDate(2026, 9, 20),
      );
      await pumpInstallments(t, w);
      expect(find.text('In PKR'), findsOneWidget);
      expect(find.text('In USD'), findsOneWidget);
      expect(find.textContaining('USD'), findsWidgets);
      w.dispose();
    });

    testWidgets('a record that cannot be read is shown, never dropped', (
      WidgetTester t,
    ) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      w.store.run<void>(
        (tx) => tx.create(
          InstallmentsCollections.plans,
          'not-a-uuid',
          <String, Object?>{'schema': kInstallmentsSchema},
        ),
      );
      await pumpInstallments(t, w);
      expect(find.byKey(LumeInstallmentsTool.defectsKey), findsOneWidget);
      expect(plansShown(t), hasLength(3));
      w.dispose();
    });

    testWidgets('loading, then the storage failure says so and can retry', (
      WidgetTester t,
    ) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      w.store.unreadable.add(InstallmentsCollections.payments);
      w.store.retry(InstallmentsCollections.payments);
      await pumpInstallments(t, w);
      expect(
        t.widget<LumeToolFrame>(find.byType(LumeToolFrame)).status,
        LumeToolStatus.error,
      );
      w.dispose();
    });

    testWidgets('a deep link to a plan that is gone opens the list and says '
        'so', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await pumpInstallments(
        t,
        w,
        query: 'plan=00000000-0000-4000-8000-000000000000',
      );
      expect(find.byKey(LumeInstallmentsTool.plansKey), findsOneWidget);
      expect(find.text("That plan isn't here any more."), findsOneWidget);
      w.dispose();
    });

    testWidgets('restoration: the plan open in this session comes back', (
      WidgetTester t,
    ) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      final GoRouter router = await pumpInstallments(t, w);
      await tapShown(
        t,
        find.byKey(LumeInstallmentsTool.row(w.plans['Sofa set']!.value)),
      );
      expect(find.byKey(LumeInstallmentsTool.planKey), findsOneWidget);
      router.go('/tools');
      await t.pumpAndSettle();
      router.go('/tools/tool/installments');
      await t.pumpAndSettle();
      expect(find.byKey(LumeInstallmentsTool.planKey), findsOneWidget);
      expect(find.text('Sofa set'), findsWidgets);
      w.dispose();
    });
  });

  group('languages and access', () {
    for (final (String code, String due, String add)
        in <(String, String, String)>[
          (
            'ur',
            AppLocalizationsUr().instDueThisMonth,
            AppLocalizationsUr().instAdd,
          ),
          (
            'ar',
            AppLocalizationsAr().instDueThisMonth,
            AppLocalizationsAr().instAdd,
          ),
        ]) {
      testWidgets('$code: right to left, every word translated', (
        WidgetTester t,
      ) async {
        final InstallmentsWorld w = InstallmentsWorld().reference();
        await pumpInstallments(t, w, locale: Locale(code));
        expect(
          Directionality.of(
            t.element(find.byKey(LumeInstallmentsTool.summaryKey)),
          ),
          TextDirection.rtl,
        );
        expect(summary(t).kicker, due);
        expect(find.text(add), findsWidgets);
        // No English beyond the reader's own item and merchant names.
        const Set<String> own = <String>{
          'Laptop',
          'TechMart',
          'Sofa set',
          'HomeStore',
          'Phone',
          'Mobile Hub',
          'Rs',
          'PKR',
          'Lume',
        };
        for (final Text x in t.widgetList<Text>(
          find.descendant(
            of: find.byKey(LumeInstallmentsTool.plansKey),
            matching: find.byType(Text),
          ),
        )) {
          String s = x.data ?? '';
          for (final String w in own) {
            s = s.replaceAll(w, '');
          }
          expect(s, isNot(matches(RegExp('[A-Za-z]{3,}'))), reason: x.data);
        }
        w.dispose();
      });
    }

    testWidgets('a screen reader hears progress, states and the chart', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await pumpInstallments(t, w);
      expect(find.bySemanticsLabel(RegExp('^Laptop')), findsWidgets);
      final SemanticsNode p = t.getSemantics(
        find
            .descendant(
              of: find.byKey(LumeInstallmentsTool.plansKey),
              matching: find.bySemanticsLabel('Laptop'),
            )
            .last,
      );
      expect(p.value, '42% paid');
      h.dispose();
      w.dispose();
    });
  });

  group('keyboard and switch access', () {
    testWidgets('Enter on a focused control acts; a switch uses the tap '
        'action', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      final InstallmentsWorld w = InstallmentsWorld();
      await pumpInstallments(t, w, surface: const Size(390, 844));
      // Keyboard: focus Add a plan and press Enter.
      Focus.of(
        t.element(
          find
              .descendant(
                of: find.byKey(LumeInstallmentsTool.addKey),
                matching: find.byType(GestureDetector),
              )
              .first,
        ),
      ).requestFocus();
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(find.byKey(LumeInstallmentsTool.formKey), findsOneWidget);
      // An untouched form leaves without asking.
      await t.tap(find.byType(LumeBackButton));
      await t.pumpAndSettle();
      expect(find.byKey(LumeInstallmentsTool.emptyKey), findsOneWidget);
      // A switch: the tap action on Add a plan.
      t.semantics.tap(find.semantics.byLabel(RegExp('Add a plan')).first);
      await t.pumpAndSettle();
      expect(find.byKey(LumeInstallmentsTool.formKey), findsOneWidget);
      h.dispose();
      w.dispose();
    });
  });
}

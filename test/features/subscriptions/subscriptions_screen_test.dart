/// Subscriptions on screen, through the real router: first use, figures
/// that agree, the form and its validation, search, cancel/reactivate,
/// delete with Undo, and Urdu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/subscriptions/domain/subscriptions_book.dart';
import 'package:lume/features/subscriptions/domain/subscriptions_model.dart';
import 'package:lume/features/subscriptions/presentation/subscriptions_tool.dart';

import '../../helpers/load_fonts.dart';
import 'subscriptions_screen_harness.dart';

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

LumeSummaryCard summary(WidgetTester t) =>
    t.widget<LumeSummaryCard>(find.byKey(LumeSubscriptionsTool.summaryKey));

String stat(WidgetTester t, String label) =>
    n(summary(t).stats.firstWhere((LumeStat s) => s.label == label).value);

String n(String s) => s.replaceAll(' ', ' ').replaceAll(' ', ' ');

final LumeCurrency pkr = LumeCurrency.of('PKR');
LumeMoney rs(int rupees) => LumeMoney.entry(rupees * 100, pkr);

void main() {
  setUpAll(loadLumeFonts);

  group('first use', () {
    testWidgets('empty: what it is for, one way in, nothing seeded', (
      WidgetTester t,
    ) async {
      final SubscriptionsWorld w = SubscriptionsWorld();
      await pumpSubscriptions(t, w);
      expect(find.byKey(LumeSubscriptionsTool.emptyKey), findsOneWidget);
      expect(find.text('No subscriptions yet'), findsOneWidget);
      expect(find.byKey(LumeSubscriptionsTool.addKey), findsOneWidget);
      expect(find.text('Netflix'), findsNothing);
      expect(w.repo.view().subscriptions, isEmpty);
      w.dispose();
    });
  });

  group('the reference composition', () {
    testWidgets('figures agree with the record', (WidgetTester t) async {
      final SubscriptionsWorld w = SubscriptionsWorld().reference();
      await pumpSubscriptions(t, w);
      final LumeSummaryCard s = summary(t);
      expect(s.kicker, 'Every month');
      expect(n(s.value), 'Rs 9.00');
      expect(n(s.caption!), 'Rs 108.00 a year');
      expect(stat(t, 'Active'), '1');
      expect(find.text('Netflix'), findsWidgets);
      w.dispose();
    });
  });

  group('adding a subscription', () {
    testWidgets('a new subscription appears', (WidgetTester t) async {
      final SubscriptionsWorld w = SubscriptionsWorld();
      await pumpSubscriptions(t, w);
      await tapShown(t, find.byKey(LumeSubscriptionsTool.addKey));
      expect(find.byKey(LumeSubscriptionsTool.formKey), findsOneWidget);

      await t.enterText(find.byKey(LumeSubscriptionsTool.nameField), 'Spotify');
      await t.enterText(find.byKey(LumeSubscriptionsTool.amountField), '5');
      await t.pumpAndSettle();
      await tapShown(t, find.byKey(LumeSubscriptionsTool.saveKey));

      expect(find.byKey(LumeSubscriptionsTool.subscriptionKey), findsOneWidget);
      expect(w.repo.view().subscriptions, hasLength(1));
      expect(w.repo.view().subscriptions.single.name, 'Spotify');
      w.dispose();
    });

    testWidgets('an empty name is refused, on screen', (WidgetTester t) async {
      final SubscriptionsWorld w = SubscriptionsWorld();
      await pumpSubscriptions(t, w);
      await tapShown(t, find.byKey(LumeSubscriptionsTool.addKey));
      await t.enterText(find.byKey(LumeSubscriptionsTool.amountField), '5');
      await t.pumpAndSettle();
      await tapShown(t, find.byKey(LumeSubscriptionsTool.saveKey));

      expect(find.byKey(LumeSubscriptionsTool.formKey), findsOneWidget);
      final LumeFormField nameField = t.widget<LumeFormField>(
        find.byKey(LumeSubscriptionsTool.nameField),
      );
      expect(nameField.error, isNotNull);
      expect(w.repo.view().subscriptions, isEmpty);
      w.dispose();
    });

    testWidgets('a custom cycle requires a day count', (WidgetTester t) async {
      final SubscriptionsWorld w = SubscriptionsWorld();
      await pumpSubscriptions(t, w);
      await tapShown(t, find.byKey(LumeSubscriptionsTool.addKey));
      await t.enterText(find.byKey(LumeSubscriptionsTool.nameField), 'Trial');
      await t.enterText(find.byKey(LumeSubscriptionsTool.amountField), '3');
      await tapShown(t, find.text('Custom'));
      await tapShown(t, find.byKey(LumeSubscriptionsTool.saveKey));

      expect(find.byKey(LumeSubscriptionsTool.formKey), findsOneWidget);
      expect(w.repo.view().subscriptions, isEmpty);
      w.dispose();
    });
  });

  group('search', () {
    testWidgets('filters the list by name', (WidgetTester t) async {
      final SubscriptionsWorld w = SubscriptionsWorld();
      w.add('Netflix', rs(9));
      w.add('Spotify', rs(5));
      await pumpSubscriptions(t, w);
      expect(find.text('Netflix'), findsWidgets);
      expect(find.text('Spotify'), findsWidgets);

      await t.enterText(find.byKey(LumeSubscriptionsTool.searchKey), 'spot');
      await t.pumpAndSettle();
      // Search narrows the row list; the timeline/donut below it still
      // summarise every active subscription, matching the reference's own
      // scope for search (subs.tool.js:17-19,36 only filters `s.list`).
      final Finder rows = find.descendant(
        of: find.byKey(LumeSubscriptionsTool.listKey),
        matching: find.text('Netflix'),
      );
      expect(rows, findsNothing);
      expect(
        find.descendant(
          of: find.byKey(LumeSubscriptionsTool.listKey),
          matching: find.text('Spotify'),
        ),
        findsWidgets,
      );
      w.dispose();
    });
  });

  group('cancel and reactivate', () {
    testWidgets(
      'cancelling asks first, keeps the record, excludes it from the total',
      (WidgetTester t) async {
        final SubscriptionsWorld w = SubscriptionsWorld().reference();
        await pumpSubscriptions(t, w);
        await tapShown(
          t,
          find.byKey(LumeSubscriptionsTool.row(w.subs['Netflix']!.value)),
        );
        await tapShown(t, find.byKey(LumeSubscriptionsTool.cancelKey));
        expect(find.text('Cancel this subscription?'), findsOneWidget);
        await tapShown(t, find.text('Confirm'));

        final SubscriptionView v = w.book().subscriptions.single;
        expect(v.subscription.state, SubscriptionState.cancelled);
        expect(w.book().summary(pkr).activeCount, 0);
        expect(find.byKey(LumeSubscriptionsTool.reactivateKey), findsOneWidget);
        w.dispose();
      },
    );
  });

  group('delete', () {
    testWidgets('removes it, and Undo brings it back', (WidgetTester t) async {
      final SubscriptionsWorld w = SubscriptionsWorld().reference();
      await pumpSubscriptions(t, w);
      await tapShown(
        t,
        find.byKey(LumeSubscriptionsTool.row(w.subs['Netflix']!.value)),
      );
      await tapShown(t, find.text('Delete'));
      expect(find.byType(LumeDeleteConfirmation), findsOneWidget);
      await tapShown(t, find.text('Delete').last);

      expect(w.repo.view().subscriptions, isEmpty);
      expect(find.text('Subscription deleted'), findsOneWidget);

      await tapShown(t, find.text('Undo'));
      expect(w.repo.view().subscriptions, hasLength(1));
      w.dispose();
    });
  });

  group('language', () {
    testWidgets('Urdu: the empty state is translated', (WidgetTester t) async {
      final SubscriptionsWorld w = SubscriptionsWorld();
      await pumpSubscriptions(t, w, locale: const Locale('ur'));
      expect(find.text('ابھی تک کوئی سبسکرپشن نہیں'), findsOneWidget);
      w.dispose();
    });
  });
}

/// Currency on screen: what it opens on, what it does when it is used, and
/// the one addition a reader can see from the outside (a real currency
/// picker, where the reference only ever swaps two fixed sides).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_share_card.dart';
import 'package:lume/core/widgets/lume/lume_spark.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/currency/domain/currency_maths.dart';
import 'package:lume/features/currency/presentation/currency_tool.dart';
import 'package:lume/features/tools/application/tool_session.dart';

import '../../helpers/capture.dart';
import 'currency_harness.dart';

void main() {
  group('what it opens on', () {
    testWidgets('the reader\'s own currency to the reference\'s own default', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester);

      expect(currencyCode(tester, LumeCurrencyTool.fromKey), 'PKR');
      expect(currencyCode(tester, LumeCurrencyTool.toKey), 'USD');
      expect(
        tester
            .widget<TextField>(find.byKey(LumeCurrencyTool.amountKey))
            .controller!
            .text,
        LumeCurrencyTool.defaultAmount,
      );
    });

    testWidgets('a dollar reader opens converting to the euro', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester, user: const LumeUserContext(country: 'US'));
      expect(currencyCode(tester, LumeCurrencyTool.fromKey), 'USD');
      expect(currencyCode(tester, LumeCurrencyTool.toKey), 'EUR');
    });

    testWidgets('the answer is the reference\'s own arithmetic', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester);
      final LumeCurrencyBoard b = LumeCurrencyBoard.forPair('PKR', 'USD');
      final double expected = 100 * b.rate;
      expect(
        double.parse(currencyResult(tester).replaceAll(',', '')),
        closeTo(expected, 0.01),
      );
    });

    testWidgets('the Popular board is the majors, minus PKR', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester);
      expect(
        tester
            .widgetList<LumeRichRow>(
              inKey(LumeCurrencyTool.popularKey, find.byType(LumeRichRow)),
            )
            .map((LumeRichRow r) => r.title)
            .toList(),
        <String>['USD', 'EUR', 'GBP', 'SAR', 'AED', 'INR'],
      );
    });

    testWidgets('the chart is 30 points of the active pair', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester);
      final LumeLineChart chart = tester.widget<LumeLineChart>(
        find.byKey(LumeCurrencyTool.chartKey),
      );
      expect(chart.values, hasLength(30));
    });
  });

  group('using it', () {
    testWidgets('typing an amount moves the answer', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester);
      final LumeCurrencyBoard b = LumeCurrencyBoard.forPair('PKR', 'USD');
      await typeAmount(tester, '5000');
      expect(
        double.parse(currencyResult(tester).replaceAll(',', '')),
        closeTo(5000 * b.rate, 0.01),
      );
    });

    testWidgets('an empty amount reads a dash and throws nothing', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester);
      await typeAmount(tester, '');
      expect(currencyResult(tester), '—');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a minus sign cannot even be typed — the field only ever '
        'holds a non-negative amount', (WidgetTester tester) async {
      await pumpCurrency(tester);
      await typeAmount(tester, '-5');
      // The amount field's own input formatter has no `-` in its allowed
      // set, so it is silently dropped rather than reaching a state
      // `LumeCurrencyBoard.convert` would have to guard against (that guard
      // is still real and is exercised directly in
      // `currency_maths_test.dart`, for a negative value however it might
      // arrive).
      expect(
        tester
            .widget<TextField>(find.byKey(LumeCurrencyTool.amountKey))
            .controller!
            .text,
        '5',
      );
    });

    testWidgets('swapping exchanges both sides and the answer', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester);
      await tester.tap(find.byKey(LumeCurrencyTool.swapKey));
      await tester.pumpAndSettle();

      expect(currencyCode(tester, LumeCurrencyTool.fromKey), 'USD');
      expect(currencyCode(tester, LumeCurrencyTool.toKey), 'PKR');
      final LumeCurrencyBoard b = LumeCurrencyBoard.forPair('USD', 'PKR');
      expect(
        double.parse(currencyResult(tester).replaceAll(',', '')),
        closeTo(100 * b.rate, 1),
      );
    });

    testWidgets('picking a currency from the sheet changes that side', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester);
      await pickCurrency(tester, LumeCurrencyTool.toKey, 'JPY');
      expect(currencyCode(tester, LumeCurrencyTool.toKey), 'JPY');
      final LumeCurrencyBoard b = LumeCurrencyBoard.forPair('PKR', 'JPY');
      expect(
        double.parse(currencyResult(tester).replaceAll(',', '')),
        closeTo(100 * b.rate, 1),
      );
    });

    testWidgets('picking the currency already on the other side swaps '
        'instead of converting a currency into itself', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester);
      // `to` is already USD; asking `from` for it must not leave both sides
      // reading USD.
      await pickCurrency(tester, LumeCurrencyTool.fromKey, 'USD');
      expect(currencyCode(tester, LumeCurrencyTool.fromKey), 'USD');
      expect(currencyCode(tester, LumeCurrencyTool.toKey), 'PKR');
    });

    testWidgets('the sheet offers every currency the shared table covers', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester);
      await tester.tap(find.byKey(LumeCurrencyTool.fromKey));
      await tester.pumpAndSettle();
      for (final String code in <String>['USD', 'JPY', 'NGN', 'BRL', 'TRY']) {
        expect(find.byKey(LumeCurrencyTool.optionKey(code)), findsOneWidget);
      }
    });

    testWidgets('searching the sheet by code narrows the list', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester);
      await tester.tap(find.byKey(LumeCurrencyTool.fromKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(LumeCurrencyTool.sheetSearchKey),
        'jpy',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(LumeCurrencyTool.optionKey('JPY')), findsOneWidget);
      expect(find.byKey(LumeCurrencyTool.optionKey('USD')), findsNothing);
    });

    testWidgets('searching the sheet by name narrows the list, for a '
        'currency the reference names', (WidgetTester tester) async {
      await pumpCurrency(tester);
      await tester.tap(find.byKey(LumeCurrencyTool.fromKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(LumeCurrencyTool.sheetSearchKey),
        'euro',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(LumeCurrencyTool.optionKey('EUR')), findsOneWidget);
      expect(find.byKey(LumeCurrencyTool.optionKey('USD')), findsNothing);
    });

    testWidgets('a search matching nothing shows the empty state', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester);
      await tester.tap(find.byKey(LumeCurrencyTool.fromKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(LumeCurrencyTool.sheetSearchKey),
        'zzz-nope',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(LumeCurrencyTool.sheetEmptyKey), findsOneWidget);
    });

    testWidgets('the Popular search narrows the board, by code or name', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester);
      await tester.enterText(find.byKey(LumeCurrencyTool.searchKey), 'euro');
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<LumeRichRow>(
              inKey(LumeCurrencyTool.popularKey, find.byType(LumeRichRow)),
            )
            .map((LumeRichRow r) => r.title)
            .toList(),
        <String>['EUR'],
      );
    });

    testWidgets('a Popular search matching nothing shows the empty state', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester);
      await tester.enterText(
        find.byKey(LumeCurrencyTool.searchKey),
        'zzz-nope',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(LumeCurrencyTool.emptyKey), findsOneWidget);
      expect(find.byType(LumeToolState), findsOneWidget);
    });

    testWidgets('tapping a Popular row toasts its rate, and touches '
        'neither side', (WidgetTester tester) async {
      await pumpCurrency(tester);
      await tester.tap(
        inKey(LumeCurrencyTool.popularKey, find.text('EUR')).first,
      );
      await tester.pump();
      expect(find.byType(LumeToast), findsOneWidget);
      expect(currencyCode(tester, LumeCurrencyTool.fromKey), 'PKR');
      expect(currencyCode(tester, LumeCurrencyTool.toKey), 'USD');
      // `showLumeToast` (unlike the tool host's own `say`) schedules its own
      // dismiss Timer with nothing tied to this widget's dispose — let it
      // run out rather than leaving it pending when the test ends.
      await tester.pump(const Duration(milliseconds: 3300));
    });

    testWidgets('the session carries the screen between openings', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = LumeToolSession();
      await pumpCurrency(tester, session: session);
      await pickCurrency(tester, LumeCurrencyTool.toKey, 'GBP');
      await typeAmount(tester, '250');

      await pumpCurrency(tester, session: session);
      expect(currencyCode(tester, LumeCurrencyTool.toKey), 'GBP');
      expect(
        tester
            .widget<TextField>(find.byKey(LumeCurrencyTool.amountKey))
            .controller!
            .text,
        '250',
      );
    });
  });

  group('what it claims', () {
    testWidgets('the share card is the rate the screen leads with', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester, surface: const Size(390, 900));
      await tester.tap(
        find.descendant(
          of: find.byType(LumeToolbar),
          matching: find.byWidgetPredicate(
            (Widget w) => w is LumeIconButton && w.label == 'Share',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final LumeShareCard card = tester
          .widget<LumeShareCardArt>(find.byType(LumeShareCardArt))
          .card;
      expect(card.kind, LumeShareKind.quote);
      expect(card.text, contains('PKR'));
      expect(card.text, contains('USD'));
      expect(card.text, isNot(contains('null')));
    });
  });

  group('other languages, and other shapes', () {
    testWidgets('a currency is found by its name, in Urdu or English', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester, locale: const Locale('ur'));
      await tester.enterText(find.byKey(LumeCurrencyTool.searchKey), 'pound');
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<LumeRichRow>(
              inKey(LumeCurrencyTool.popularKey, find.byType(LumeRichRow)),
            )
            .map((LumeRichRow r) => r.title)
            .toList(),
        <String>['GBP'],
      );
    });

    testWidgets('in Arabic, right to left, without overflow', (
      WidgetTester tester,
    ) async {
      await pumpCurrency(tester, locale: const Locale('ar'));
      expectNoOverflow(tester);
      expect(
        Directionality.of(tester.element(find.byKey(LumeCurrencyTool.cardKey))),
        TextDirection.rtl,
      );
      // The figures keep their own left-to-right order inside the RTL page.
      expect(
        Directionality.of(
          tester.element(find.byKey(LumeCurrencyTool.amountKey)),
        ),
        TextDirection.ltr,
      );
      expect(
        Directionality.of(
          tester.element(find.byKey(LumeCurrencyTool.resultKey)),
        ),
        TextDirection.ltr,
      );
    });

    testWidgets('at 200%, without overflow', (WidgetTester tester) async {
      await pumpCurrency(tester, textScale: 2);
      expectNoOverflow(tester);
    });

    testWidgets('dark mode draws', (WidgetTester tester) async {
      await pumpCurrency(tester, theme: ThemeMode.dark);
      expect(tester.takeException(), isNull);
    });
  });
}

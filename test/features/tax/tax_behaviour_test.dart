/// Tax, used: typing, switching the period, leaving and coming back, the
/// gates, and the controls that go somewhere.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_chart.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/features/shell/presentation/fixture_tool_screen.dart';
import 'package:lume/features/expenses/presentation/expenses_tool.dart';
import 'package:lume/features/tax/presentation/tax_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import 'tax_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  Finder input(Key key) =>
      find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

  String summary(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(LumeTaxTool.resultKey),
          matching: find.byType(Text),
        ),
      )
      .map((Text t) => t.data ?? t.textSpan!.toPlainText())
      .join(' | ')
      // A lettered currency symbol is followed by a no-break space, as CLDR
      // and the reference write it; read here as the space it looks like.
      .replaceAll(' ', ' ');

  group('it works it out as the reader types', () {
    testWidgets('a lower income moves every figure', (
      WidgetTester tester,
    ) async {
      await pumpTax(tester, surface: const Size(390, 5000));
      await tester.enterText(input(LumeTaxTool.incomeKey), '100000');
      await tester.pump();
      // 1,200,000 a year: 6,000 in the 1 % band, 500 a month.
      expect(
        summary(tester),
        'TAX A MONTH | Rs 500 | Effective rate 0.5% | Rs 99,500 | Take-home | '
        'Rs 1,200,000 | Taxable income | 1% | Marginal rate',
      );
      expect(find.text('Above Rs 4,100,000'), findsNothing);
    });

    testWidgets('deductions come off the year, not the month', (
      WidgetTester tester,
    ) async {
      await pumpTax(tester, surface: const Size(390, 5000));
      await tester.enterText(input(LumeTaxTool.incomeKey), '100000');
      await tester.enterText(input(LumeTaxTool.deductionsKey), '600000');
      await tester.pump();
      expect(summary(tester), contains('Rs 0 | Effective rate 0%'));
      expect(summary(tester), contains('Rs 600,000 | Taxable income'));
      expect(summary(tester), contains('0% | Marginal rate'));
    });

    testWidgets('an empty field is nothing, not an error', (
      WidgetTester tester,
    ) async {
      await pumpTax(tester, surface: const Size(390, 5000));
      await tester.enterText(input(LumeTaxTool.incomeKey), '');
      await tester.pump();
      expect(
        summary(tester),
        startsWith('TAX A MONTH | Rs 0 | Effective rate 0%'),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the period changes what the figure means, not the figure', (
      WidgetTester tester,
    ) async {
      await pumpTax(tester, surface: const Size(390, 5000));
      await tester.tap(find.text('Annual'));
      await tester.pumpAndSettle();
      expect(find.text('ANNUAL INCOME'), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(input(LumeTaxTool.incomeKey))
            .controller
            .text,
        '849000',
      );
      expect(summary(tester), startsWith('TAX A YEAR | Rs 2,490'));
      final LumeSegmented seg = tester.widget(
        find.byKey(LumeTaxTool.periodKey),
      );
      expect(seg.value, 'year');
    });
  });

  group('it remembers, for the session', () {
    testWidgets('leaving and opening it again keeps what was typed', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpTax(tester);
      await tester.enterText(input(LumeTaxTool.incomeKey), '250000');
      await tester.tap(find.text('Annual'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();
      expect(locationOf(router), LumeRoutes.tools);
      expect(find.byType(LumeTaxTool), findsNothing);

      router.go(kTaxLocation);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<EditableText>(input(LumeTaxTool.incomeKey))
            .controller
            .text,
        '250000',
      );
      expect(find.text('ANNUAL INCOME'), findsOneWidget);
    });
  });

  group('the gates', () {
    testWidgets('a market Tax has not launched in is refused at the route', (
      WidgetTester tester,
    ) async {
      await pumpTax(tester, state: 'default_jp');
      expect(find.byType(LumeTaxTool), findsNothing);
      expect(find.byType(FixtureToolScreen), findsOneWidget);
      // And the refusal does not name the tool it refused.
      expect(find.text('Tax Calculator'), findsNothing);
    });

    testWidgets(
      'an id the registry has never heard of still takes the fixture path',
      (WidgetTester tester) async {
        await pumpTax(
          tester,
          // As of wave 10 every one of the catalogue's 85 ids is a
          // registered, converted tool (`tool_registry.dart`'s own header
          // comment) — there is no longer a real, still-unconverted id to
          // point this at. What the route actually promises (`app_router.
          // dart`'s own comment on `_tool`) is that a missing registry
          // entry and an unknown catalogue id take the identical fixture
          // path, so a made-up id exercises the same fallback.
          location: LumeRoutes.tool(LumeRoutes.tools, 'not-a-real-tool'),
        );
        expect(find.byType(FixtureToolScreen), findsOneWidget);
        expect(find.byType(LumeTaxTool), findsNothing);
      },
    );

    testWidgets('a related tool the reader cannot open is not offered', (
      WidgetTester tester,
    ) async {
      // National Savings is Pakistan-only.
      await pumpTax(
        tester,
        state: 'default_us',
        surface: const Size(390, 5000),
      );
      expect(find.text('National Savings'), findsNothing);
      expect(find.text('Savings Goals'), findsOneWidget);
    });
  });

  group('the controls that go somewhere', () {
    testWidgets('a related tool replaces this one on the same branch', (
      WidgetTester tester,
    ) async {
      await pumpTax(tester, surface: const Size(390, 5000));
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();
      // go_router reports the shell's location after a `replace`, so what is
      // drawn is the evidence: Expenses, and no Tax beneath it to go back to.
      expect(find.byType(LumeTaxTool), findsNothing);
      expect(find.byType(LumeExpensesTool), findsOneWidget);
    });

    testWidgets('the country opens Personalise', (WidgetTester tester) async {
      await pumpTax(tester);
      await tester.tap(find.text('Pakistan'));
      // The sheet keeps something moving while it reads its table, so it is
      // given its entrance rather than asked to settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(LumeSheet), findsOneWidget);
    });

    // D7 decided: both work, through the host. What each hands over, and
    // every outcome's sentence, is `share_export_host_test.dart`.
    testWidgets('share and export are named, enabled, and stay on Tax (D7)', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpTax(
        tester,
        surface: const Size(390, 5000),
      );
      final SemanticsHandle semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Share'), findsWidgets);
      expect(find.bySemanticsLabel('Export'), findsWidgets);
      for (final Finder f in <Finder>[
        find.byType(LumeIconButton).at(0),
        find.byType(LumeIconButton).at(1),
      ]) {
        expect(tester.widget<LumeIconButton>(f).onPressed, isNotNull);
      }
      await tester.tap(find.widgetWithText(LumeButton, 'Export'));
      await tester.pump();
      expect(find.text('Saved lume-tax-2026-09-07.csv'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(locationOf(router), kTaxLocation);
      semantics.dispose();
    });
  });

  group('it holds up', () {
    testWidgets('at 200 % text', (WidgetTester tester) async {
      await pumpTax(tester, textScale: 2);
      expectNoOverflow(tester);
      expect(find.byType(LumeTaxTool), findsOneWidget);
    });

    testWidgets(
      'with the keyboard up, the field being typed in stays on screen',
      (WidgetTester tester) async {
        await pumpTax(tester);
        tester.view.viewInsets = FakeViewPadding(
          bottom: 336 * tester.view.devicePixelRatio,
        );
        addTearDown(tester.view.resetViewInsets);
        await tester.showKeyboard(input(LumeTaxTool.deductionsKey));
        await tester.pumpAndSettle();
        expectNoOverflow(tester);
        final Rect field = tester.getRect(
          find.byKey(LumeTaxTool.deductionsKey),
        );
        expect(field.bottom, lessThanOrEqualTo(844 - 336));
      },
    );

    testWidgets('the donut and the table announce what they are', (
      WidgetTester tester,
    ) async {
      await pumpTax(tester, surface: const Size(390, 5000));
      final SemanticsHandle semantics = tester.ensureSemantics();
      // The figure's name, with its legend read after it.
      expect(find.bySemanticsLabel(RegExp('^Where it goes')), findsOneWidget);
      expect(find.bySemanticsLabel('How it is worked out'), findsWidgets);
      expect(find.bySemanticsLabel('Period'), findsOneWidget);
      semantics.dispose();
      expect(find.byType(LumeDonut), findsOneWidget);
    });
  });
}

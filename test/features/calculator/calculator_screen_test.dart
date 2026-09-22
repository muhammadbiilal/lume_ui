/// Calculator, used — with fingers, with a keyboard, in three languages and
/// in both directions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_pressable.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/features/calculator/domain/calculator_engine.dart';
import 'package:lume/features/calculator/presentation/calculator_text.dart';
import 'package:lume/features/calculator/presentation/calculator_tool.dart';
import 'package:lume/l10n/app_localizations.dart';
import 'package:lume/l10n/app_localizations_ar.dart';
import 'package:lume/l10n/app_localizations_en.dart';
import 'package:lume/l10n/app_localizations_ur.dart';

import '../../helpers/load_fonts.dart';
import 'calculator_harness.dart';

final AppLocalizations en = AppLocalizationsEn();
final AppLocalizations ur = AppLocalizationsUr();
final AppLocalizations ar = AppLocalizationsAr();

/// Tap a sequence: an `int` is a digit, a [LumeCalcOp] is an operator, and
/// `'='`, `'.'`, `'%'`, `'C'`, `'<'` are the five named keys.
Future<void> tapKeys(WidgetTester tester, List<Object> presses) async {
  for (final Object p in presses) {
    await calcTap(tester, switch (p) {
      final int n => LumeCalculatorTool.digitKey(n),
      final LumeCalcOp op => LumeCalculatorTool.opKey(op),
      '=' => LumeCalculatorTool.equalsKey,
      '.' => LumeCalculatorTool.pointKey,
      '%' => LumeCalculatorTool.perCentKey,
      'C' => LumeCalculatorTool.clearKey,
      '<' => LumeCalculatorTool.backspaceKey,
      _ => throw ArgumentError('unknown press $p'),
    });
  }
}

Future<void> type(WidgetTester tester, String text) async {
  for (final String c in text.split('')) {
    final LogicalKeyboardKey key = switch (c) {
      '0' => LogicalKeyboardKey.digit0,
      '1' => LogicalKeyboardKey.digit1,
      '2' => LogicalKeyboardKey.digit2,
      '3' => LogicalKeyboardKey.digit3,
      '4' => LogicalKeyboardKey.digit4,
      '5' => LogicalKeyboardKey.digit5,
      '6' => LogicalKeyboardKey.digit6,
      '7' => LogicalKeyboardKey.digit7,
      '8' => LogicalKeyboardKey.digit8,
      '9' => LogicalKeyboardKey.digit9,
      // The numeric pad's keys: they have physical keys the simulator
      // knows, and they are what a reader with a keyboard actually presses.
      '+' => LogicalKeyboardKey.numpadAdd,
      '-' => LogicalKeyboardKey.numpadSubtract,
      '*' => LogicalKeyboardKey.numpadMultiply,
      '/' => LogicalKeyboardKey.numpadDivide,
      '%' => LogicalKeyboardKey.digit5,
      '.' => LogicalKeyboardKey.period,
      _ => LogicalKeyboardKey.space,
    };
    await simulateKeyDownEvent(key, character: c);
    await simulateKeyUpEvent(key);
    await tester.pumpAndSettle();
  }
}

String? clearLabel(WidgetTester tester) => tester
    .widget<LumePressable>(find.byKey(LumeCalculatorTool.clearKey))
    .semanticLabel;

Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
  await simulateKeyDownEvent(key);
  await simulateKeyUpEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadLumeFonts);

  group('the pad works out what was pressed', () {
    testWidgets('digits reach the readout, and the sum reaches History', (
      WidgetTester tester,
    ) async {
      await pumpCalculator(tester);
      expect(find.byKey(LumeCalculatorTool.emptyKey), findsOneWidget);
      expect(find.text(en.calcNoHistory), findsOneWidget);

      await tapKeys(tester, <Object>[1, 2, LumeCalcOp.add, 3, '=']);
      expect(calcReadout(tester), '15');
      expect(calcExpression(tester), '12 + 3 =');

      expect(find.byKey(LumeCalculatorTool.emptyKey), findsNothing);
      expect(find.byKey(LumeCalculatorTool.historyKey), findsOneWidget);
      expect(
        calcTextsIn(tester, find.byKey(LumeCalculatorTool.historyKey)),
        containsAllInOrder(<String>['12 + 3', '15']),
      );
    });

    testWidgets('precedence: 2 + 3 × 4 = is 14, not the reference\'s 20', (
      WidgetTester tester,
    ) async {
      await pumpCalculator(tester);
      await tapKeys(tester, <Object>[
        2,
        LumeCalcOp.add,
        3,
        LumeCalcOp.multiply,
        4,
        '=',
      ]);
      expect(calcReadout(tester), '14');
      expect(calcExpression(tester), '2 + 3 × 4 =');
    });

    testWidgets('0.1 + 0.2 is 0.3 on the screen too', (
      WidgetTester tester,
    ) async {
      await pumpCalculator(tester);
      await tapKeys(tester, <Object>[
        0,
        '.',
        1,
        LumeCalcOp.add,
        0,
        '.',
        2,
        '=',
      ]);
      expect(calcReadout(tester), '0.3');
    });

    testWidgets('1.1 % is 0.011', (WidgetTester tester) async {
      await pumpCalculator(tester);
      await tapKeys(tester, <Object>[1, '.', 1, '%']);
      expect(calcReadout(tester), '0.011');
    });

    testWidgets('repeated equals keeps going', (WidgetTester tester) async {
      await pumpCalculator(tester);
      await tapKeys(tester, <Object>[2, LumeCalcOp.add, 3, '=']);
      expect(calcReadout(tester), '5');
      await tapKeys(tester, <Object>['=']);
      expect(calcReadout(tester), '8');
      expect(
        calcTextsIn(tester, find.byKey(LumeCalculatorTool.historyKey)),
        containsAllInOrder(<String>['5 + 3', '8', '2 + 3', '5']),
      );
    });

    testWidgets('history is newest first and stops at six', (
      WidgetTester tester,
    ) async {
      await pumpCalculator(tester);
      for (int i = 1; i <= 8; i++) {
        await tapKeys(tester, <Object>['C', 'C', i, LumeCalcOp.add, 1, '=']);
      }
      expect(
        find.descendant(
          of: find.byKey(LumeCalculatorTool.historyKey),
          matching: find.byType(LumeCompactRow),
        ),
        findsNWidgets(LumeCalcEngine.historyLimit),
      );
      expect(
        calcTextsIn(tester, find.byKey(LumeCalculatorTool.historyKey)).first,
        '8 + 1',
      );
    });

    testWidgets('clear clears the entry, then the sum, and says which', (
      WidgetTester tester,
    ) async {
      await pumpCalculator(tester);
      expect(clearLabel(tester), en.calcClear);
      await tapKeys(tester, <Object>[2, LumeCalcOp.add, 3]);
      expect(clearLabel(tester), en.calcClearEntry);
      await tapKeys(tester, <Object>['C']);
      expect(calcReadout(tester), '0');
      expect(
        calcExpression(tester),
        '2 + 0',
        reason: 'the sum is still open, on a cleared right-hand side',
      );
      await tapKeys(tester, <Object>[5, '=']);
      expect(calcReadout(tester), '7');
    });

    testWidgets('clearing everything is announced, not just drawn', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpCalculator(tester);
      await tapKeys(tester, <Object>[2, LumeCalcOp.add, 3]);
      // Clearing the entry is visible on the readout; nothing is said.
      await tapKeys(tester, <Object>['C']);
      expect(tester.takeAnnouncements(), isEmpty);
      // Clearing the pending sum takes away something the reader cannot see.
      await tapKeys(tester, <Object>['C']);
      expect(
        tester.takeAnnouncements().map((CapturedAccessibilityAnnouncement a) {
          return a.message;
        }),
        contains(en.calcCleared),
      );
      handle.dispose();
    });

    testWidgets('backspace drops the last digit', (WidgetTester tester) async {
      await pumpCalculator(tester);
      await tapKeys(tester, <Object>[1, 2, 3, '<']);
      expect(calcReadout(tester), '12');
      await tapKeys(tester, <Object>['<', '<']);
      expect(calcReadout(tester), '0');
    });
  });

  group('a key that cannot do what it was asked says so', () {
    testWidgets('5 ÷ 0 = shows the reason, and never a number', (
      WidgetTester tester,
    ) async {
      await pumpCalculator(tester);
      await tapKeys(tester, <Object>[5, LumeCalcOp.divide, 0, '=']);
      expect(calcReadout(tester), en.calcErrDivZero);
      expect(calcReadout(tester), isNot(contains('0.')));
      expect(find.byKey(LumeCalculatorTool.historyKey), findsNothing);
      expect(find.byKey(LumeCalculatorTool.emptyKey), findsOneWidget);
      // Clear is the way out, and it works.
      await tapKeys(tester, <Object>['C']);
      expect(calcReadout(tester), '0');
    });

    testWidgets('a division that does not end is named', (
      WidgetTester tester,
    ) async {
      await pumpCalculator(tester);
      await tapKeys(tester, <Object>[
        1,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        LumeCalcOp.divide,
        3,
        '=',
      ]);
      expect(calcReadout(tester), en.calcErrPrecision);
    });

    testWidgets('an overflow is named', (WidgetTester tester) async {
      await pumpCalculator(tester);
      await tapKeys(tester, <Object>[
        9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, //
        LumeCalcOp.multiply,
        9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, //
        '=',
      ]);
      expect(calcReadout(tester), en.calcErrOverflow);
    });

    testWidgets('a thirteenth digit is refused, with the number kept', (
      WidgetTester tester,
    ) async {
      await pumpCalculator(tester);
      await tapKeys(tester, <Object>[1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3]);
      expect(calcReadout(tester), '123,456,789,123');
      await tapKeys(tester, <Object>[4]);
      expect(find.byKey(LumeCalculatorTool.noteKey), findsOneWidget);
      expect(find.text(en.calcErrTooLong), findsOneWidget);
      expect(calcReadout(tester), '123,456,789,123');
    });
  });

  group('the keyboard', () {
    testWidgets('digits, operators, Enter, Backspace and Escape', (
      WidgetTester tester,
    ) async {
      await pumpCalculator(tester);
      await type(tester, '12+3');
      expect(calcExpression(tester), '12 + 3');
      await press(tester, LogicalKeyboardKey.enter);
      expect(calcReadout(tester), '15');

      await type(tester, '48');
      expect(calcReadout(tester), '48');
      await press(tester, LogicalKeyboardKey.backspace);
      expect(calcReadout(tester), '4');

      await press(tester, LogicalKeyboardKey.escape);
      expect(calcReadout(tester), '0');
      await press(tester, LogicalKeyboardKey.escape);
      expect(calcExpression(tester), isEmpty);

      await type(tester, '9/4');
      await press(tester, LogicalKeyboardKey.enter);
      expect(calcReadout(tester), '2.25');
    });
  });

  group('localisation', () {
    testWidgets(
      'the readout goes through the formatter, not String(n) (defect 4)',
      (WidgetTester tester) async {
        await pumpCalculator(tester);
        await tapKeys(tester, <Object>[1, 2, 3, 4, 5, 6, 7]);
        // `out.textContent = toolCalc.b` would read `1234567`.
        expect(calcReadout(tester), '1,234,567');
        await tapKeys(tester, <Object>['.', 5, 0]);
        expect(
          calcReadout(tester),
          '1,234,567.50',
          reason: 'the zeros a reader typed are still there',
        );
      },
    );

    testWidgets("every string on the screen is the reader's own", (
      WidgetTester tester,
    ) async {
      for (final (Locale locale, AppLocalizations l)
          in <(Locale, AppLocalizations)>[
            (const Locale('en'), en),
            (const Locale('ur'), ur),
            (const Locale('ar'), ar),
          ]) {
        await pumpCalculator(tester, locale: locale);
        expect(find.text(l.calcHistory), findsOneWidget);
        expect(find.text(l.calcNoHistory), findsOneWidget);
        expect(
          find.text(l.calcPrecisionNote('12')),
          findsOneWidget,
          reason: 'the precision policy is stated, in $locale',
        );
        expect(clearLabel(tester), l.calcClear);
        expect(
          tester
              .widget<LumePressable>(
                find.byKey(LumeCalculatorTool.backspaceKey),
              )
              .semanticLabel,
          l.calcBackspace,
        );
        await tapKeys(tester, <Object>[5, LumeCalcOp.divide, 0, '=']);
        expect(calcReadout(tester), l.calcErrDivZero);
      }
    });

    testWidgets("the reader's own digits are read back", (
      WidgetTester tester,
    ) async {
      await pumpCalculator(tester, locale: const Locale('ar'));
      // U+0665 — Arabic-Indic five, as an Arabic keyboard sends it.
      await simulateKeyDownEvent(
        LogicalKeyboardKey.digit5,
        character: String.fromCharCode(0x0665),
      );
      await simulateKeyUpEvent(LogicalKeyboardKey.digit5);
      await tester.pumpAndSettle();
      final String typed = calcReadout(tester);
      expect(typed, isNot('0'), reason: 'the keypress was understood');

      await pumpCalculator(tester, locale: const Locale('ar'));
      await tapKeys(tester, <Object>[5]);
      expect(
        typed,
        calcReadout(tester),
        reason: 'typing it and pressing it are the same key',
      );
    });

    testWidgets('a history row is the calculation, not a kept string', (
      WidgetTester tester,
    ) async {
      await pumpCalculator(tester, locale: const Locale('ur'));
      await tapKeys(tester, <Object>[
        1,
        0,
        0,
        0,
        0,
        0,
        0,
        LumeCalcOp.add,
        1,
        '=',
      ]);
      expect(
        calcTextsIn(tester, find.byKey(LumeCalculatorTool.historyKey)),
        containsAllInOrder(<String>['1,000,000 + 1', '1,000,001']),
        reason:
            "the row is formatted when it is drawn, in the reader's "
            'locale, from the decimals it holds',
      );
      // The isolates travel with the label, so the arithmetic keeps its
      // order inside a right-to-left row.
      final LumeCompactRow row = tester.widget<LumeCompactRow>(
        find
            .descendant(
              of: find.byKey(LumeCalculatorTool.historyKey),
              matching: find.byType(LumeCompactRow),
            )
            .first,
      );
      expect(row.label.codeUnitAt(0), 0x2066);
      expect(row.label.codeUnits.last, 0x2069);
      expect(row.value!.codeUnitAt(0), 0x2066);
    });

    testWidgets('right to left does not reverse the arithmetic', (
      WidgetTester tester,
    ) async {
      await pumpCalculator(tester, locale: const Locale('ur'));
      expect(
        Directionality.of(
          tester.element(find.byKey(LumeCalculatorTool.keypadKey)),
        ),
        TextDirection.rtl,
        reason: 'the page is right to left',
      );
      await tapKeys(tester, <Object>[8, LumeCalcOp.divide, 2, '=']);
      // Each run is isolated left to right, so "8 ÷ 2 =" is not laid out
      // as "= 2 ÷ 8".
      for (final Key k in <Key>[
        LumeCalculatorTool.readoutKey,
        LumeCalculatorTool.expressionKey,
      ]) {
        expect(
          Directionality.of(
            tester.element(
              find.descendant(of: find.byKey(k), matching: find.byType(Text)),
            ),
          ),
          TextDirection.ltr,
        );
      }
      final String line = calcExpression(tester);
      expect(line, endsWith('='));
      expect(line.indexOf(calcDivideSign), greaterThan(0));
      expect(line.indexOf(calcDivideSign), lessThan(line.indexOf('=')));
      expect(calcReadout(tester), '4');
    });
  });

  group('the screen reader', () {
    testWidgets('hears the expression, then the result, as it changes', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpCalculator(tester);
      await tapKeys(tester, <Object>[9, LumeCalcOp.subtract, 4, '=']);

      final SemanticsNode expression = tester.getSemantics(
        find.byKey(LumeCalculatorTool.expressionKey),
      );
      final SemanticsNode result = tester.getSemantics(
        find.byKey(LumeCalculatorTool.readoutKey),
      );
      expect(expression.label, en.calcExpression);
      expect(expression.value, '9 − 4 =');
      expect(result.label, en.calcDisplay);
      expect(result.value, '5');
      expect(
        result.flagsCollection.isLiveRegion,
        isTrue,
        reason: 'the readout announces itself when it changes',
      );
      // Reading order: the expression comes before the result.
      expect(
        tester.getRect(find.byKey(LumeCalculatorTool.expressionKey)).top,
        lessThan(tester.getRect(find.byKey(LumeCalculatorTool.readoutKey)).top),
      );
      handle.dispose();
    });

    testWidgets('every key says what it is', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpCalculator(tester);
      expect(
        tester.getSemantics(find.byKey(LumeCalculatorTool.digitKey(7))).label,
        en.calcDigit('7'),
      );
      expect(
        tester
            .getSemantics(find.byKey(LumeCalculatorTool.opKey(LumeCalcOp.add)))
            .label,
        en.calcPlus,
      );
      expect(
        tester
            .getSemantics(
              find.byKey(LumeCalculatorTool.opKey(LumeCalcOp.divide)),
            )
            .label,
        en.calcDivide,
      );
      expect(
        tester.getSemantics(find.byKey(LumeCalculatorTool.backspaceKey)).label,
        en.calcBackspace,
      );
      expect(
        tester.getSemantics(find.byKey(LumeCalculatorTool.equalsKey)).label,
        en.calcEquals,
      );
      expect(
        tester.getSemantics(find.byKey(LumeCalculatorTool.perCentKey)).label,
        en.calcPercent,
      );
      handle.dispose();
    });

    testWidgets('a history row is heard as one calculation', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpCalculator(tester);
      await tapKeys(tester, <Object>[6, LumeCalcOp.multiply, 7, '=']);
      expect(
        find.bySemanticsLabel(en.calcHistoryRow('6 × 7', '42')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('every layout holds', () {
    for (final (String name, Size surface, double scale)
        in <(String, Size, double)>[
          ('compact', const Size(390, 844), 1),
          ('compact at 200%', const Size(390, 844), 2),
          ('landscape', const Size(718, 393), 1),
          ('landscape at 200%', const Size(718, 393), 2),
          ('wide', const Size(806, 900), 1),
          ('wide at 200%', const Size(806, 900), 2),
        ]) {
      testWidgets(name, (WidgetTester tester) async {
        await pumpCalculator(tester, surface: surface, textScale: scale);
        expect(tester.takeException(), isNull);
        await tapKeys(tester, <Object>[7, LumeCalcOp.divide, 8, '=']);
        expect(tester.takeException(), isNull);
        expect(calcReadout(tester), '0.875');
        // The pad stays inside the page at every width and scale.
        final Rect pad = tester.getRect(
          find.byKey(LumeCalculatorTool.keypadKey),
        );
        expect(pad.left, greaterThanOrEqualTo(0));
        expect(pad.right, lessThanOrEqualTo(surface.width));
        expect(find.byType(LumeToolState), findsNothing);
      });
    }
  });
}

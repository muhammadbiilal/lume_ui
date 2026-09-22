/// Calculator, held against the running reference.
///
/// Seven cells were captured, and each is reproduced on its own surface: the
/// reference's viewport less the 25-point stage margin either side, which is
/// a frame Lume never draws. What the reference *does* share is the
/// navigation beside the screen above compact width, and the tool route is
/// inside the shell that draws it, so the screen inside each surface is the
/// reference's own — 390, 566, 718 and 806. The `.calc` block's height is a
/// pure function of that width, and it is checked at all four widths the
/// reference recorded it at: 350, 518, 670 and 742.
///
/// Two recorded differences, both written into the report rather than
/// absorbed by a tolerance:
///
/// * **the empty state** (defect 6). The reference draws "History" over two
///   points of border and nothing else; Lume draws `l.calcNoHistory`. So the
///   History section is taller by the state's height less those two points,
///   and everything after it sits that much lower. The amount is measured in
///   the test and passed as `grown`/`shifted`.
/// * **the section's gap**. CSS puts `.sect`'s 24 points outside the
///   element's own box; [LumeToolSection] draws them inside it. `sect1` is
///   therefore 24 higher and 24 taller by construction, on every screen in
///   the product.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/calculator/presentation/calculator_tool.dart';
import 'package:lume/features/tools/application/tool_registry.dart';

import '../../helpers/load_fonts.dart';
import '../tools/tool_parity.dart';
import 'calculator_harness.dart';

/// `.sect`'s own gap, drawn inside the widget rather than outside the box.
const double kSectionGap = -24;

/// The `.calc` block's recorded height, from the cell's composition.
double webCalcHeight(String cell) {
  final Map<String, dynamic> web =
      jsonDecode(
            File(
              'docs/conversion_archive/measurements/$cell.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final List<dynamic> sections =
      (web['composition'] as Map<String, dynamic>)['sections'] as List<dynamic>;
  final Map<String, dynamic> calc = sections.first as Map<String, dynamic>;
  expect(calc['cls'], 'calc', reason: '$cell does not lead with `.calc`');
  return (calc['height'] as num).toDouble();
}

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('calculator');
  tearDownAll(parity.write);

  Finder historySection() => find
      .ancestor(
        of: find.byKey(LumeCalculatorTool.emptyKey),
        matching: find.byType(LumeToolSection),
      )
      .first;

  /// What the empty state adds where the reference drew two points of border.
  double emptyGrowth(WidgetTester tester) =>
      tester.getRect(find.byKey(LumeCalculatorTool.emptyKey)).height - 2;

  group('where everything is', () {
    for (final String cell in <String>[
      'tool_calculator_default_pk_390x844_light_en',
      'tool_calculator_default_pk_390x844_dark_en',
      'tool_calculator_default_pk_852x393_light_en',
    ]) {
      testWidgets(cell, (WidgetTester tester) async {
        await pumpCalculator(
          tester,
          surface: kCalculatorCells[cell]!,
          theme: cell.contains('dark') ? ThemeMode.dark : ThemeMode.light,
        );
        final double shift = emptyGrowth(tester);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          <String, Finder>{
            'toolbar': find.byType(LumeToolbar),
            'sect1': historySection(),
            'rows': find.byKey(LumeCalculatorTool.emptyKey),
            'srcbar': find.byType(LumeSourceBar),
            'related': find.byType(LumeRelatedTools),
          },
          // The section carries its own gap and the state inside it, so its
          // height is not the reference's 33 and is not compared.
          noHeight: const <String>{'sect1'},
          shifted: <String, double>{
            'sect1': kSectionGap,
            'srcbar': shift,
            'related': shift,
          },
          grown: <String, double>{'rows': shift},
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }
  });

  group(
    'the `.calc` block is the reference\'s, at every width it recorded',
    () {
      // 350, 670, 518 and 742 wide — the four the reference recorded, each
      // reached on the cell's own surface, because the shell now puts the
      // same navigation beside the screen that the reference did.
      for (final String cell in <String>[
        'tool_calculator_default_pk_390x844_light_en',
        'tool_calculator_default_pk_390x844_light_ur',
        'tool_calculator_default_pk_390x844_light_ar',
        'tool_calculator_default_pk_852x393_light_en',
        'tool_calculator_default_pk_700x900_light_en',
        'tool_calculator_default_pk_1100x900_light_en',
      ]) {
        testWidgets(cell, (WidgetTester tester) async {
          final String language = cell.split('_').last;
          await pumpCalculator(
            tester,
            surface: kCalculatorCells[cell]!,
            locale: Locale(language),
          );
          final Rect block = tester.getRect(
            find.byKey(LumeCalculatorTool.blockKey),
          );
          expect(
            block.height,
            closeTo(webCalcHeight(cell), kToolTolerance),
            reason: '$cell: the readout and the nineteen keys',
          );
          // The pad is the reference's grid: four columns, nine between, each
          // key 1.15 as wide as it is tall.
          final Rect pad = tester.getRect(
            find.byKey(LumeCalculatorTool.keypadKey),
          );
          final double key = (pad.width - LumeCalculatorTool.keyGap * 3) / 4;
          expect(
            pad.height,
            closeTo(
              5 * key / LumeCalculatorTool.keyAspect +
                  4 * LumeCalculatorTool.keyGap,
              0.01,
            ),
          );
        });
      }
    },
  );

  group('what it says', () {
    testWidgets('the reference\'s own strings, in the reference\'s order', (
      WidgetTester tester,
    ) async {
      await pumpCalculator(tester);
      // `screen.text`: the readout's 0, the nineteen keys, then History.
      expect(calcReadout(tester), '0');
      expect(calcExpression(tester), isEmpty);
      for (int n = 0; n <= 9; n++) {
        expect(find.byKey(LumeCalculatorTool.digitKey(n)), findsOneWidget);
      }
      for (final Key k in <Key>[
        LumeCalculatorTool.clearKey,
        LumeCalculatorTool.backspaceKey,
        LumeCalculatorTool.perCentKey,
        LumeCalculatorTool.pointKey,
        LumeCalculatorTool.equalsKey,
      ]) {
        expect(find.byKey(k), findsOneWidget);
      }
      expect(find.text('History'), findsOneWidget);
      // The reference's source line, unchanged.
      expect(referenceSourceLine(tester), <String>['On device']);
      expect(
        textsUnder(tester, find.byType(LumeRelatedTools)),
        containsAll(<String>['Unit Converter', 'Currency', 'Tip & Split']),
      );
    });

    testWidgets('the header carries no actions, as the cell records', (
      WidgetTester tester,
    ) async {
      await pumpCalculator(tester);
      final Map<String, dynamic>? web = webToolCell(
        'tool_calculator_default_pk_390x844_light_en',
      );
      final Map<String, dynamic> actions =
          (web!['bounds'] as Map<String, dynamic>)['toolbar.actions']
              as Map<String, dynamic>;
      expect(actions['width'], 0);
    });
  });

  testWidgets('the route reaches the tool', (WidgetTester tester) async {
    expect(kLumeToolRegistry[LumeCalculatorTool.id], isNotNull);
    await pumpCalculator(tester);
    expect(find.byType(LumeCalculatorTool), findsOneWidget);
  });
}

/// Rollout wave 1, pinned and captured in every cell the brief names.
///
/// Each case writes a committed golden in `images/` and a `.flutter.png`
/// beside the browser's `.web.png` in `docs/conversion_archive/shots/tools/`,
/// so `compare.mjs` can put the two side by side. The states after the ten
/// default cells — a mode chosen, a tip and a head count changed, a keyboard
/// raised, laps recorded — are Flutter's alone: the reference was captured
/// only as it opens.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_pressable.dart';
import 'package:lume/features/datecalc/presentation/datecalc_tool.dart';
import 'package:lume/features/loan/presentation/loan_tool.dart';
import 'package:lume/features/tipsplit/presentation/tipsplit_tool.dart';
import 'package:lume/features/tools/application/tool_session.dart';

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
  ('360x800_light_en', Size(360, 800), ThemeMode.light, Locale('en'), 1.0),
  ('359x844_light_en', Size(359, 844), ThemeMode.light, Locale('en'), 1.0),
  ('700x900_light_en', Size(700, 900), ThemeMode.light, Locale('en'), 1.0),
  ('1100x900_light_en', Size(1100, 900), ThemeMode.light, Locale('en'), 1.0),
  ('852x393_light_en', Size(852, 393), ThemeMode.light, Locale('en'), 1.0),
  ('390x844_light_ur', Size(390, 844), ThemeMode.light, Locale('ur'), 1.0),
  ('390x844_light_ar', Size(390, 844), ThemeMode.light, Locale('ar'), 1.0),
  ('390x844_light_en_x2', Size(390, 844), ThemeMode.light, Locale('en'), 2.0),
];

void main() {
  setUpAll(loadLumeFonts);

  Future<void> shoot(
    WidgetTester tester, {
    required String tool,
    required String golden,
    required Cell cell,
    String state = 'default_pk',
    String? folder,
    List<Override> overrides = const <Override>[],
    Future<void> Function(WidgetTester tester)? after,
  }) async {
    await captureLumeRoute(
      tester,
      location: LumeRoutes.tool(LumeRoutes.tools, tool),
      name: golden,
      folder: folder,
      outDir: kOut,
      surface: cell.$2,
      theme: cell.$3,
      locale: cell.$4,
      textScale: cell.$5,
      suffix: cell.$5 == 1.0 ? '' : '_x${cell.$5.toStringAsFixed(0)}',
      profile: taxProfile(state),
      overrides: overrides,
      after: after,
    );
    expect(find.byType(LumeToolFrame), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/${golden}_${cell.$1}.png'),
    );
  }

  for (final (String tool, String name) in <(String, String)>[
    ('age', 'Age'),
    ('datecalc', 'Date Calculator'),
    ('tipsplit', 'Tip & Split'),
    ('loan', 'Loan / EMI'),
    ('compound', 'Compound Interest'),
    ('stopwatch', 'Stopwatch'),
  ]) {
    group(name, () {
      for (final Cell cell in kCells) {
        testWidgets(cell.$1, (WidgetTester tester) async {
          await shoot(
            tester,
            tool: tool,
            golden: 'tool_${tool}_default_pk',
            cell: cell,
          );
        });
      }
    });
  }

  group('Wave 1 states', () {
    testWidgets('Date Calculator adding days · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        tool: 'datecalc',
        golden: 'tool_datecalc_default_pk_add',
        cell: kCells.first,
        after: (WidgetTester t) async {
          await t.tap(
            find.descendant(
              of: find.byKey(LumeDatecalcTool.modeKey),
              matching: find.text('Add days'),
            ),
          );
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('Tip & Split at 15 % for three · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        tool: 'tipsplit',
        golden: 'tool_tipsplit_default_pk_tip15-people3',
        cell: kCells.first,
        after: (WidgetTester t) async {
          await t.tap(find.text('15%'));
          await t.pumpAndSettle();
          await t.tap(
            find
                .descendant(
                  of: find.byKey(LumeTipsplitTool.peopleKey),
                  matching: find.byType(LumePressable),
                )
                .last,
          );
          await t.pumpAndSettle();
        },
      );
    });

    // A phone keyboard, 336 points tall, with Tenure focused. The web
    // reference cannot raise one, so this cell is Flutter's alone.
    testWidgets('Loan / EMI with the keyboard up · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        tool: 'loan',
        golden: 'tool_loan_keyboard',
        cell: kCells.first,
        after: (WidgetTester t) async {
          t.view.viewInsets = FakeViewPadding(
            bottom: 336 * t.view.devicePixelRatio,
          );
          addTearDown(t.view.resetViewInsets);
          await t.showKeyboard(
            find.descendant(
              of: find.byKey(LumeLoanTool.yearsKey),
              matching: find.byType(EditableText),
            ),
          );
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('Stopwatch with three laps · the reference cell', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = LumeToolSession()
        ..write('stopwatch', 'ms', '83450')
        ..write('stopwatch', 'laps', '31200,62950,83450');
      await shoot(
        tester,
        tool: 'stopwatch',
        golden: 'tool_stopwatch_default_pk_laps',
        cell: kCells.first,
        overrides: <Override>[toolSessionProvider.overrideWithValue(session)],
      );
    });
  });
}

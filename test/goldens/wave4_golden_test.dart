/// Rollout wave 4, pinned and captured: each tool as it opens in seven
/// cells, and the states a reader reaches that the reference cannot.
///
/// Three of the states here exist *because* the conversion corrected
/// something, and each has a cell so the correction can be looked at rather
/// than read about:
///
/// * **Unit Converter's Data category**, where the reference's binary
///   factors sit under decimal names and Lume separates them and says so;
/// * **Birthdays and Water opened in a development build**, where the seeds
///   are not there (`kLumeParityOnlySeeds`) and the tools draw their empty
///   states. The reference always has four people and 1250 ml, so it has no
///   empty day and no empty list, and these two cells are the only picture
///   of what a reader actually opens;
/// * **Water's goal editor**, which the reference does not have at all.
///
/// Each case writes a committed golden in `images/` and a `.flutter.png`
/// beside the browser's `.web.png` in `docs/conversion_archive/shots/tools/`,
/// so `compare.mjs` can put the two side by side.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/features/records/presentation/record_tool.dart';
import 'package:lume/features/birthdays/presentation/birthdays_tool.dart';
import 'package:lume/features/converter/domain/unit_table.dart';
import 'package:lume/features/converter/presentation/converter_tool.dart';
import 'package:lume/features/water/presentation/water_tool.dart';

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

/// Scroll [f] into view, then press it.
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
    required String tool,
    required String golden,
    required Cell cell,
    String state = 'default_pk',
    LumeBuildProfile build = LumeBuildProfile.parity,
    Future<void> Function(WidgetTester tester)? after,
  }) async {
    await captureLumeRoute(
      tester,
      location: LumeRoutes.tool(LumeRoutes.tools, tool),
      name: golden,
      outDir: kOut,
      surface: cell.$2,
      theme: cell.$3,
      locale: cell.$4,
      textScale: cell.$5,
      suffix: cell.$5 == 1.0 ? '' : '_x${cell.$5.toStringAsFixed(0)}',
      profile: taxProfile(state),
      // The store reads this to decide whether the two parity-only families
      // are seeded, so a development cell is genuinely an empty collection
      // and not a seeded one with its figures hidden.
      overrides: <Override>[buildProfileProvider.overrideWithValue(build)],
      after: after,
    );
    expect(find.byType(LumeToolFrame), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/${golden}_${cell.$1}.png'),
    );
  }

  group('wave 4, as each tool opens', () {
    for (final Cell cell in kCells) {
      testWidgets('Unit Converter ${cell.$1}', (WidgetTester tester) async {
        await shoot(
          tester,
          tool: LumeConverterTool.id,
          golden: 'tool_converter_default_pk',
          cell: cell,
        );
      });

      testWidgets('Birthdays ${cell.$1}', (WidgetTester tester) async {
        await shoot(
          tester,
          tool: LumeBirthdaysTool.id,
          golden: 'tool_birthdays_default_pk',
          cell: cell,
        );
      });

      testWidgets('Water ${cell.$1}', (WidgetTester tester) async {
        await shoot(
          tester,
          tool: LumeWaterTool.id,
          golden: 'tool_water_default_pk',
          cell: cell,
        );
      });
    }
  });

  group('Unit Converter, in the states the corrections are visible in', () {
    testWidgets('the Data category, where the names are separated', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        tool: LumeConverterTool.id,
        golden: 'tool_converter_default_pk_data',
        cell: kPhone,
        after: (WidgetTester t) => tapShown(
          t,
          find.byKey(LumeConverterTool.categoryKey(LumeUnitKind.data)),
        ),
      );
    });

    testWidgets('Volume, where both gallons are named', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        tool: LumeConverterTool.id,
        golden: 'tool_converter_default_pk_volume',
        cell: kPhone,
        after: (WidgetTester t) => tapShown(
          t,
          find.byKey(LumeConverterTool.categoryKey(LumeUnitKind.volume)),
        ),
      );
    });

    testWidgets('the unit picker the reference does not have', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        tool: LumeConverterTool.id,
        golden: 'tool_converter_default_pk_units',
        cell: kPhone,
        after: (WidgetTester t) async {
          await tapShown(
            t,
            find.byKey(LumeConverterTool.categoryKey(LumeUnitKind.volume)),
          );
          await tapShown(t, find.byKey(LumeConverterTool.toKey));
        },
      );
    });
  });

  group('Birthdays and Water, as a reader opens them', () {
    // A development build: no seeds, so these are the real first screens.
    // The reference has no such state — it always holds four people and
    // 1250 ml — so nothing on either cell can be compared to it, and that
    // is the point of having them.
    testWidgets('Birthdays with nothing saved', (WidgetTester tester) async {
      await shoot(
        tester,
        tool: LumeBirthdaysTool.id,
        golden: 'tool_birthdays_empty',
        cell: kPhone,
        build: LumeBuildProfile.development,
      );
      expect(find.byKey(LumeBirthdaysTool.nothingKey), findsOneWidget);
    });

    testWidgets('Water with nothing logged', (WidgetTester tester) async {
      await shoot(
        tester,
        tool: LumeWaterTool.id,
        golden: 'tool_water_empty',
        cell: kPhone,
        build: LumeBuildProfile.development,
      );
      expect(find.byKey(LumeWaterTool.nothingKey), findsOneWidget);
    });

    testWidgets('Water, the goal a reader can change', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        tool: LumeWaterTool.id,
        golden: 'tool_water_default_pk_goal',
        cell: kPhone,
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeWaterTool.goalEditKey)),
      );
    });
  });

  group('and the records under them', () {
    for (final String tool in <String>[
      LumeBirthdaysTool.id,
      LumeWaterTool.id,
    ]) {
      final LumeRecordKeys k = LumeRecordKeys(tool);

      testWidgets('$tool · a record opened', (WidgetTester tester) async {
        await shoot(
          tester,
          tool: tool,
          golden: 'tool_${tool}_default_pk_detail',
          cell: kPhone,
          after: (WidgetTester t) => tapShown(t, find.byType(LumeRecordRow)),
        );
      });

      testWidgets('$tool · a record opened beside the list', (
        WidgetTester tester,
      ) async {
        await shoot(
          tester,
          tool: tool,
          golden: 'tool_${tool}_default_pk_detail',
          cell: kCells[3],
          after: (WidgetTester t) => tapShown(t, find.byType(LumeRecordRow)),
        );
      });

      testWidgets('$tool · a new record', (WidgetTester tester) async {
        await shoot(
          tester,
          tool: tool,
          golden: 'tool_${tool}_default_pk_new',
          cell: kPhone,
          after: (WidgetTester t) => tapShown(t, find.byKey(k.add)),
        );
      });
    }
  });
}

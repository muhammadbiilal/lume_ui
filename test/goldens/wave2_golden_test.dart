/// Rollout wave 2, pinned and captured: each tool as it opens in seven
/// cells, and the states a reader reaches — a record's detail, its form, the
/// delete confirmation, To-dos filtered, Shopping's bulk clear, and Sun &
/// Moon for other cities and for a zone this build cannot read.
///
/// Each case writes a committed golden in `images/` and a `.flutter.png`
/// beside the browser's `.web.png` in `docs/conversion_archive/shots/tools/`,
/// so `compare.mjs` can put the two side by side.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/features/records/presentation/record_tool.dart';
import 'package:lume/features/shopping/presentation/shopping_tool.dart';
import 'package:lume/features/todos/presentation/todos_tool.dart';

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
  ('390x844_light_ur', Size(390, 844), ThemeMode.light, Locale('ur'), 1.0),
  ('390x844_light_ar', Size(390, 844), ThemeMode.light, Locale('ar'), 1.0),
  ('390x844_light_en_x2', Size(390, 844), ThemeMode.light, Locale('en'), 2.0),
];

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
      after: after,
    );
    expect(find.byType(LumeToolFrame), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/${golden}_${cell.$1}.png'),
    );
  }

  for (final (String tool, String name) in <(String, String)>[
    ('notes', 'Notes'),
    ('todos', 'To-dos'),
    ('events', 'Events'),
    ('shopping', 'Shopping List'),
    ('sunmoon', 'Sun & Moon'),
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

  group('Wave 2 states', () {
    for (final String tool in <String>[
      'notes',
      'todos',
      'events',
      'shopping',
    ]) {
      final LumeRecordKeys k = LumeRecordKeys(tool);

      testWidgets('$tool · a record opened', (WidgetTester tester) async {
        await shoot(
          tester,
          tool: tool,
          golden: 'tool_${tool}_default_pk_detail',
          cell: kCells.first,
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
          cell: kCells.first,
          after: (WidgetTester t) => tapShown(t, find.byKey(k.add)),
        );
      });

      testWidgets('$tool · a delete asked', (WidgetTester tester) async {
        await shoot(
          tester,
          tool: tool,
          golden: 'tool_${tool}_default_pk_delete',
          cell: kCells.first,
          after: (WidgetTester t) async {
            await tapShown(t, find.byType(LumeRecordRow));
            await tapShown(
              t,
              find
                  .descendant(
                    of: find.byKey(k.detailActions),
                    matching: find.byType(LumeDetailAction),
                  )
                  .last,
            );
          },
        );
      });
    }

    testWidgets('To-dos · this week, high priority', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        tool: 'todos',
        golden: 'tool_todos_default_pk_when-week-priority-high',
        cell: kCells.first,
        after: (WidgetTester t) async {
          await tapShown(
            t,
            find.byKey(LumeTodosTool.whenChip(LumeTodoWhen.week)),
          );
          await tapShown(t, find.byKey(LumeTodosTool.priorityChip('high')));
        },
      );
    });

    testWidgets('Shopping · clearing the basket asked', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        tool: 'shopping',
        golden: 'tool_shopping_default_pk_bulk',
        cell: kCells.first,
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeShoppingTool.keys.bulk)),
      );
    });

    for (final String state in <String>[
      'muslim_gb',
      'default_us',
      'default_ae',
      'default_jp',
    ]) {
      testWidgets('Sun & Moon · $state', (WidgetTester tester) async {
        await shoot(
          tester,
          tool: 'sunmoon',
          golden: 'tool_sunmoon_$state',
          state: state,
          cell: kCells.first,
        );
      });
    }
  });
}

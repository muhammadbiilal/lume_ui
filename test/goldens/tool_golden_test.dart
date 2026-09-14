/// Tax, pinned and captured in every cell the brief names.
///
/// The first reference tool, so the first entry in this file. Each case writes
/// a committed golden in `images/` and a `.flutter.png` beside the browser's
/// `.web.png` in `docs/conversion_archive/shots/tools/`, under the folder
/// `measure_destinations.mjs --tool tax` writes to, so `compare.mjs` can put
/// the two side by side.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/features/tax/presentation/tax_tool.dart';

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
    required String state,
    required String golden,
    required Cell cell,
    String? folder,
    String suffix = '',
    Future<void> Function(WidgetTester tester)? after,
  }) async {
    await captureLumeRoute(
      tester,
      location: kTaxLocation,
      name: golden,
      folder: folder,
      outDir: kOut,
      surface: cell.$2,
      theme: cell.$3,
      locale: cell.$4,
      textScale: cell.$5,
      suffix: cell.$5 == 1.0 ? suffix : '_x${cell.$5.toStringAsFixed(0)}',
      profile: taxProfile(state),
      after: after,
    );
    expect(find.byType(LumeTaxTool), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/${golden}_${cell.$1}.png'),
    );
  }

  /// The tool's own scroll position, moved exactly — a drag would add touch
  /// slop and a fling to a number the web capture sets directly.
  Future<void> Function(WidgetTester) scrolledTo(double offset) =>
      (WidgetTester t) async {
        final ScrollableState s = t.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(LumeToolFrame),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        s.position.jumpTo(offset);
        await t.pumpAndSettle();
      };

  group('Tax, Pakistan', () {
    for (final Cell cell in kCells) {
      testWidgets(cell.$1, (WidgetTester tester) async {
        await shoot(
          tester,
          state: 'default_pk',
          golden: 'tool_tax_default_pk',
          cell: cell,
        );
      });
    }

    testWidgets('a year · the reference cell', (WidgetTester tester) async {
      await shoot(
        tester,
        state: 'default_pk',
        golden: 'tool_tax_default_pk_period-year',
        cell: kCells.first,
        after: (WidgetTester t) async {
          await t.tap(find.text('Annual'));
          await t.pumpAndSettle();
        },
      );
    });

    for (final double offset in <double>[560, 1000]) {
      testWidgets('scrolled ${offset.round()} · the reference cell', (
        WidgetTester tester,
      ) async {
        await shoot(
          tester,
          state: 'default_pk',
          golden: 'tool_tax_default_pk_s${offset.round()}',
          folder: 'tool_tax_default_pk',
          cell: kCells.first,
          after: scrolledTo(offset),
        );
      });
    }

    // A phone keyboard, 336 points tall, with Deductions focused. The web
    // reference cannot raise one, so this cell is Flutter's alone.
    testWidgets('with the keyboard up · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        state: 'default_pk',
        golden: 'tool_tax_keyboard',
        cell: kCells.first,
        after: (WidgetTester t) async {
          t.view.viewInsets = FakeViewPadding(
            bottom: 336 * t.view.devicePixelRatio,
          );
          addTearDown(t.view.resetViewInsets);
          await t.showKeyboard(
            find.descendant(
              of: find.byKey(LumeTaxTool.deductionsKey),
              matching: find.byType(EditableText),
            ),
          );
          await t.pumpAndSettle();
        },
      );
    });
  });

  for (final String state in <String>[
    'default_us',
    'muslim_gb',
    'default_ae',
  ]) {
    testWidgets('Tax, $state · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        state: state,
        golden: 'tool_tax_$state',
        cell: kCells.first,
      );
    });
  }
}

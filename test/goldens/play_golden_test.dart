/// Play, pinned and captured: the grid of four in its eight cells, and the
/// notice under it.
///
/// There is nothing else to capture, and that is the point of the screen.
/// The reference ships no game — each tile's whole behaviour is a toast of
/// its own title — so the tiles here are not controls, nothing opens, no
/// score and no play count is drawn, and a notice beneath the grid says in
/// the reader's own language that these cannot be played yet. The tool holds
/// no state, reads no clock and writes nothing, so every cell is a function
/// of the surface, the theme and the language alone.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/notification_feed.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/features/play/presentation/play_tool.dart';

import '../features/play/play_harness.dart';
import '../features/tax/tax_harness.dart';
import '../helpers/capture.dart';
import '../helpers/load_fonts.dart';

/// The sidecars land beside the images, out of the way of the archive.
const String kOut = 'build/play_shots';

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

/// The phone at twice the text size, where the screen no longer fits.
const Cell kCellX2 = (
  '390x844_light_en_x2',
  Size(390, 844),
  ThemeMode.light,
  Locale('en'),
  2.0,
);

void main() {
  setUpAll(loadLumeFonts);

  Future<void> shoot(
    WidgetTester tester, {
    required String golden,
    required Cell cell,
    Future<void> Function(WidgetTester tester)? after,
  }) async {
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));

    await captureLumeRoute(
      tester,
      location: kPlayLocation,
      name: golden,
      outDir: kOut,
      surface: cell.$2,
      theme: cell.$3,
      locale: cell.$4,
      textScale: cell.$5,
      suffix: cell.$5 == 1.0 ? '' : '_x${cell.$5.toStringAsFixed(0)}',
      profile: taxProfile('default_pk'),
      overrides: <Override>[
        // A capture of a tool, not of the shell's notification banner.
        notificationScheduleProvider.overrideWithValue(
          const LumeNotificationSchedule.off(),
        ),
      ],
      after: after,
    );
    expect(find.byType(LumeToolFrame), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/${golden}_${cell.$1}.png'),
    );
  }

  group('Play — the reference composition', () {
    for (final Cell cell in kCells) {
      testWidgets('the four tiles, ${cell.$1}', (WidgetTester t) async {
        await shoot(t, golden: 'tool_play_grid', cell: cell);
      });
    }
  });

  group('Play — the states a reader reaches', () {
    // At ordinary text size the notice is already on the phone cell, so a
    // second capture of it there would be the same image byte for byte. At
    // twice the text size it is below the fold, and scrolling to it is the
    // one thing on this screen a reader can still do.
    testWidgets('the notice: none of the four can be played yet', (
      WidgetTester t,
    ) async {
      await shoot(
        t,
        golden: 'tool_play_not_playable',
        cell: kCellX2,
        after: (WidgetTester t) async {
          await t.ensureVisible(find.byKey(LumePlayTool.noticeKey));
          await t.pumpAndSettle();
        },
      );
    });
  });
}

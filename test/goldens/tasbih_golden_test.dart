/// Tasbih, pinned and captured: the counter as it opens in its eight cells,
/// and every state a reader reaches — part-way through a round, a round just
/// finished, the question asked before a reset, another phrase chosen, the
/// question asked before a part-finished round is thrown away, and the
/// ceiling the count will not go past.
///
/// **The reader is a Muslim reader.** `tasbih` is faith-gated in the
/// catalogue, so the route refuses a default profile outright; every cell
/// here is taken with `muslim_pk`, exactly as the tool's own harness takes
/// them, and the refusal is a test of its own elsewhere.
///
/// The counter is driven by tapping the face and the chips, or seeded through
/// [LumeTasbihStore] — the one place this tool keeps anything, and an
/// in-memory one at that. There is no clock in it, so no cell depends on
/// the instant.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/notification_feed.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/features/tasbih/application/tasbih_store.dart';
import 'package:lume/features/tasbih/domain/tasbih_count.dart';
import 'package:lume/features/tasbih/domain/tasbih_phrase.dart';
import 'package:lume/features/tasbih/presentation/tasbih_tool.dart';
import 'package:lume/features/tools/application/tool_session.dart';

import '../features/tasbih/tasbih_harness.dart';
import '../features/tax/tax_harness.dart';
import '../helpers/capture.dart';
import '../helpers/load_fonts.dart';

/// The sidecars land beside the images, out of the way of the archive.
const String kOut = 'build/tasbih_shots';

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

/// A session already holding [count].
LumeToolSession seeded(LumeTasbihCount count) {
  final LumeToolSession session = LumeToolSession();
  LumeTasbihStore(session).write(count);
  return session;
}

/// Scroll [f] into view, then press it.
Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

/// [n] taps on the face, as fast as the framework delivers them.
Future<void> burst(WidgetTester t, int n) async {
  await t.ensureVisible(find.byKey(LumeTasbihTool.counterKey));
  await t.pumpAndSettle();
  for (int i = 0; i < n; i++) {
    await t.tap(find.byKey(LumeTasbihTool.counterKey));
    await t.pump(const Duration(milliseconds: 8));
  }
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadLumeFonts);

  Future<void> shoot(
    WidgetTester tester, {
    required String golden,
    required Cell cell,
    LumeToolSession? session,
    Future<void> Function(WidgetTester tester)? after,
  }) async {
    // The count's announcement is throttled by a timer; the tree comes down
    // first so nothing is left pending.
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));

    await captureLumeRoute(
      tester,
      location: kTasbih,
      name: golden,
      outDir: kOut,
      surface: cell.$2,
      theme: cell.$3,
      locale: cell.$4,
      textScale: cell.$5,
      suffix: cell.$5 == 1.0 ? '' : '_x${cell.$5.toStringAsFixed(0)}',
      // Faith-gated: a default profile is refused at the route.
      profile: taxProfile('muslim_pk'),
      overrides: <Override>[
        toolSessionProvider.overrideWithValue(session ?? LumeToolSession()),
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

  group('Tasbih — the reference composition', () {
    for (final Cell cell in kCells) {
      testWidgets('the counter at nothing, ${cell.$1}', (WidgetTester t) async {
        await shoot(t, golden: 'tool_tasbih_zero', cell: cell);
      });
    }
  });

  group('Tasbih — the states a reader reaches', () {
    Future<void> state(
      WidgetTester t,
      String name, {
      LumeToolSession? session,
      Future<void> Function(WidgetTester tester)? after,
      Cell cell = kPhone,
    }) => shoot(
      t,
      golden: 'tool_tasbih_$name',
      cell: cell,
      session: session,
      after: after,
    );

    testWidgets('part-way through a round, counted by hand', (
      WidgetTester t,
    ) async {
      await state(t, 'part_round', after: (WidgetTester t) => burst(t, 12));
    });

    testWidgets('the round finishes, says so, and starts again', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'round_complete',
        session: seeded(const LumeTasbihCount(count: 32)),
        after: (WidgetTester t) => burst(t, 1),
      );
    });

    testWidgets('Reset asks first, and says what would go', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'reset_confirm',
        session: seeded(const LumeTasbihCount(count: 12, rounds: 2)),
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeTasbihTool.resetKey)),
      );
    });

    testWidgets('another phrase chosen, with its own round', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'phrase_picker',
        after: (WidgetTester t) =>
            tapShown(t, find.text(LumeTasbihPhrases.all[4].transliteration)),
      );
    });

    testWidgets('switching phrase asks before a round is thrown away', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'switch_confirm',
        session: seeded(const LumeTasbihCount(count: 12, rounds: 2)),
        after: (WidgetTester t) =>
            tapShown(t, find.text(LumeTasbihPhrases.all[1].transliteration)),
      );
    });

    testWidgets('the ceiling: a tap that counts nothing, and why', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'ceiling',
        session: seeded(
          const LumeTasbihCount(count: 12, rounds: LumeTasbihCount.maxRounds),
        ),
        after: (WidgetTester t) => burst(t, 1),
      );
    });
  });
}

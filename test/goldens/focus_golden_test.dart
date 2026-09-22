/// Focus Timer, pinned and captured: the sample composition in its eight
/// cells, and every state a reader reaches on the honest path — ready,
/// running, paused, a focus stretch that ran out and the break it offers,
/// that break running, and "This session" both before anything has been
/// counted and after a stretch has.
///
/// **Two compositions, and the cells are of the first one.** A parity build
/// draws the reference's own figures — 75 minutes, a streak of 5, 3 sessions
/// and a seven-bar week — under a source bar that says they are sample data.
/// That is what the capture matrix compares against, so the eight cells are
/// taken at [LumeBuildProfile.parity]. Everything a reader actually runs is
/// the development build, where those figures do not exist at all, and every
/// state below is taken there.
///
/// **Time is [FocusWorld]**, the elapsed-time source the tool's own harness
/// provides: the test moves it by hand and pumps, so a stretch that takes
/// twenty-five minutes takes none here and takes exactly twenty-five as far
/// as the tool is concerned. Nothing reads the wall clock, and the face is
/// computed fresh from the reading rather than counted in ticks, so the
/// figure on a cell is a function of [FocusWorld.now] alone.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/notification_feed.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/features/focus/presentation/focus_tool.dart';

import '../features/focus/focus_harness.dart';
import '../features/tax/tax_harness.dart';
import '../helpers/capture.dart';
import '../helpers/load_fonts.dart';

/// The sidecars land beside the images, out of the way of the archive.
const String kOut = 'build/focus_shots';

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

/// Bring [key] under the eye and leave the screen settled there.
Future<void> show(WidgetTester t, Key key) async {
  await t.ensureVisible(find.byKey(key));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadLumeFonts);

  Future<void> shoot(
    WidgetTester tester, {
    required String golden,
    required Cell cell,
    required FocusWorld world,
    LumeBuildProfile build = LumeBuildProfile.parity,
    Future<void> Function(WidgetTester tester)? after,
  }) async {
    // The repaint ticker of a running stretch would outlive the test, so the
    // tree comes down first and the controller's `dispose` cancels it.
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));

    await captureLumeRoute(
      tester,
      location: kFocus,
      name: golden,
      outDir: kOut,
      surface: cell.$2,
      theme: cell.$3,
      locale: cell.$4,
      textScale: cell.$5,
      suffix: cell.$5 == 1.0 ? '' : '_x${cell.$5.toStringAsFixed(0)}',
      profile: taxProfile('default_pk'),
      overrides: <Override>[
        buildProfileProvider.overrideWithValue(build),
        ...world.overrides,
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

  group('Focus Timer — the reference composition', () {
    for (final Cell cell in kCells) {
      testWidgets('the sample figures and the week, ${cell.$1}', (
        WidgetTester t,
      ) async {
        await shoot(
          t,
          golden: 'tool_focus_sample',
          cell: cell,
          world: FocusWorld(),
        );
      });
    }
  });

  group('Focus Timer — the states a reader reaches', () {
    Future<void> state(
      WidgetTester t,
      String name,
      FocusWorld world, {
      Future<void> Function(WidgetTester tester)? after,
      Cell cell = kPhone,
    }) => shoot(
      t,
      golden: 'tool_focus_$name',
      cell: cell,
      world: world,
      build: LumeBuildProfile.development,
      after: after,
    );

    testWidgets('ready: a full stretch, and nothing running', (
      WidgetTester t,
    ) async {
      await state(t, 'ready', FocusWorld());
    });

    testWidgets('running, two and a half minutes in', (WidgetTester t) async {
      final FocusWorld w = FocusWorld();
      await state(
        t,
        'running',
        w,
        after: (WidgetTester t) async {
          await tapShown(t, find.byKey(LumeFocusTool.startKey));
          w.advance(const Duration(minutes: 2, seconds: 30));
          await t.pump(const Duration(seconds: 1));
        },
      );
    });

    testWidgets('paused, with the time it had reached kept', (
      WidgetTester t,
    ) async {
      final FocusWorld w = FocusWorld();
      await state(
        t,
        'paused',
        w,
        after: (WidgetTester t) async {
          await tapShown(t, find.byKey(LumeFocusTool.startKey));
          w.advance(const Duration(minutes: 2, seconds: 30));
          await t.pump(const Duration(seconds: 1));
          await tapShown(t, find.byKey(LumeFocusTool.startKey));
        },
      );
    });

    testWidgets('the stretch ran out, and the break is offered', (
      WidgetTester t,
    ) async {
      final FocusWorld w = FocusWorld();
      await state(
        t,
        'break_offered',
        w,
        after: (WidgetTester t) async {
          await tapShown(t, find.byKey(LumeFocusTool.startKey));
          w.advance(const Duration(minutes: 25));
          await t.pump(const Duration(seconds: 1));
        },
      );
    });

    testWidgets('the break, running', (WidgetTester t) async {
      final FocusWorld w = FocusWorld();
      await state(
        t,
        'break_running',
        w,
        after: (WidgetTester t) async {
          await tapShown(t, find.byKey(LumeFocusTool.skipKey));
          await tapShown(t, find.byKey(LumeFocusTool.startKey));
          w.advance(const Duration(minutes: 1, seconds: 20));
          await t.pump(const Duration(seconds: 1));
        },
      );
    });

    testWidgets('this session, with nothing counted yet', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'nothing_counted',
        FocusWorld(),
        after: (WidgetTester t) => show(t, LumeFocusTool.emptyKey),
      );
    });

    testWidgets('this session, with one stretch counted', (
      WidgetTester t,
    ) async {
      final FocusWorld w = FocusWorld();
      await state(
        t,
        'counted',
        w,
        after: (WidgetTester t) async {
          await tapShown(t, find.byKey(LumeFocusTool.startKey));
          w.advance(const Duration(minutes: 25));
          await t.pump(const Duration(seconds: 1));
          await show(t, LumeFocusTool.countedKey);
        },
      );
    });
  });
}

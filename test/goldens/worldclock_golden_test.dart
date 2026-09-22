/// World Clock, pinned and captured: the composition in its eight cells,
/// and every state a reader reaches — the converter with an answer in it, a
/// place added by search and a place taken off, a stored alias reading under
/// both its names, an identifier the database does not know, a database that
/// is not there at all, a device that has not said where it is, a country
/// with more than one civil time, a search that matches nothing, and a list
/// with nothing on it but the reader's own clock.
///
/// Every state is driven the way a reader drives it — typing in the search
/// field, tapping a row and choosing from its sheet, picking a place and an
/// hour in the converter — or is seeded into the one thing this tool stores,
/// which is the list of identifiers ([LumeWorldClockTool.placesKey]) and
/// nothing else.
///
/// Time is pinned to 2026-09-07T11:41:32Z — a UTC instant rather than
/// [kFixtureInstant], which is a local `DateTime` and would make every
/// row a function of the machine's own zone. Nothing here reads the wall
/// clock, and no capture moves it: the
/// minute tick is a one-shot timer scheduled at the next minute boundary,
/// which a settled pump never reaches, so the figures on every cell are the
/// fixture's and only the fixture's.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/app/providers/notification_feed.dart';
import 'package:lume/app/providers/time_zone_provider.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/tools/application/tool_session.dart';
import 'package:lume/features/worldclock/presentation/worldclock_tool.dart';

import '../features/worldclock/worldclock_screen_harness.dart';
import '../helpers/capture.dart';
import '../helpers/load_fonts.dart';

/// The sidecars land beside the images, out of the way of the archive.
const String kOut = 'build/worldclock_shots';

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

/// A session already holding [ids] as the reader's list.
LumeToolSession listed(List<String> ids) => LumeToolSession()
  ..write(LumeWorldClockTool.id, LumeWorldClockTool.placesKey, ids.join(','));

void main() {
  setUpAll(loadLumeFonts);

  Future<void> shoot(
    WidgetTester tester, {
    required String golden,
    required Cell cell,
    LumeProfileRecord? reader,
    LumeToolSession? session,
    LumeTimeZoneService? service,
    Future<void> Function(WidgetTester tester)? after,
    LumeBuildProfile build = LumeBuildProfile.parity,
  }) async {
    // A minute tick outliving the test would be reported as a pending timer,
    // so the tree comes down first and `dispose` cancels it.
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));

    await captureLumeRoute(
      tester,
      location: kWorldClockLocation,
      name: golden,
      outDir: kOut,
      surface: cell.$2,
      theme: cell.$3,
      locale: cell.$4,
      textScale: cell.$5,
      suffix: cell.$5 == 1.0 ? '' : '_x${cell.$5.toStringAsFixed(0)}',
      profile: LumeMemoryProfileRepository(
        initial: reader ?? worldClockReader(),
      ),
      // A UTC instant, not [kFixtureInstant]. That one is a local
      // `DateTime`, and every row here is it converted into another
      // zone — so on a machine in a different zone the whole list would
      // draw different times and every golden would differ. Pinned, the
      // picture is the same everywhere. 11:41:32Z is the same moment the
      // screen tests use, so the goldens and those assertions agree.
      clock: LumeClock.fixed(DateTime.utc(2026, 9, 7, 11, 41, 32)),
      overrides: <Override>[
        toolSessionProvider.overrideWithValue(session ?? LumeToolSession()),
        if (service != null) timeZoneServiceProvider.overrideWithValue(service),
        deviceZoneProvider.overrideWithValue(const LumeDeviceZone.unknown()),
        // A capture of a tool, not of the shell's notification banner: the
        // tick is the documented knob for a walk that wants screens, and a
        // state driven through several pumps would otherwise be captured
        // under a banner it has nothing to do with.
        notificationScheduleProvider.overrideWithValue(
          const LumeNotificationSchedule.off(),
        ),
        buildProfileProvider.overrideWithValue(build),
      ],
      after: after,
    );
    expect(find.byType(LumeToolFrame), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/${golden}_${cell.$1}.png'),
    );
  }

  group('World Clock — the reference composition', () {
    for (final Cell cell in kCells) {
      testWidgets('the list, ${cell.$1}', (WidgetTester t) async {
        await shoot(t, golden: 'tool_worldclock_list', cell: cell);
      });
    }
  });

  // The source bar a reader actually gets. A parity capture reproduces the
  // reference's own word, "Live", which beside a named source reads as a
  // feed; a shipping build says what is true of this tool — the clock runs
  // here, and the zone rules are compiled in and named by their version.
  // The correction is invisible in every cell above, so it gets one of its
  // own rather than only a test that reads the string.
  testWidgets('World Clock — the source bar a reader gets', (
    WidgetTester t,
  ) async {
    await shoot(
      t,
      golden: 'tool_worldclock_calculated_live',
      cell: kPhone,
      build: LumeBuildProfile.development,
    );
  });

  group('World Clock — the states a reader reaches', () {
    Future<void> state(
      WidgetTester t,
      String name, {
      LumeProfileRecord? reader,
      LumeToolSession? session,
      LumeTimeZoneService? service,
      Future<void> Function(WidgetTester tester)? after,
      Cell cell = kPhone,
    }) => shoot(
      t,
      golden: 'tool_worldclock_$name',
      cell: cell,
      reader: reader,
      session: session,
      service: service,
      after: after,
    );

    testWidgets('the converter, with an hour chosen and an answer', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'convert',
        after: (WidgetTester t) async {
          await tapShown(t, find.byKey(LumeWorldClockTool.convertToKey));
          await tapShown(
            t,
            find.byKey(LumeWorldClockTool.optionKey('Europe/London')),
          );
          await tapShown(t, find.byKey(LumeWorldClockTool.convertAtKey));
          await tapShown(t, find.byKey(LumeWorldClockTool.optionKey('540')));
          await t.ensureVisible(
            find.byKey(LumeWorldClockTool.convertResultKey),
          );
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('a place searched for and added', (WidgetTester t) async {
      await state(
        t,
        'added',
        after: (WidgetTester t) async {
          await t.enterText(
            find.byKey(LumeWorldClockTool.searchKey),
            'Kathmandu',
          );
          await t.pumpAndSettle();
          await tapShown(
            t,
            find.byKey(LumeWorldClockTool.choiceKey('Asia/Kathmandu')),
          );
          await t.ensureVisible(
            find.byKey(LumeWorldClockTool.rowKey('Asia/Kathmandu')),
          );
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('a place removed, with the way back offered', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'removed',
        session: listed(<String>['Asia/Dubai', 'Europe/London']),
        after: (WidgetTester t) async {
          await tapShown(
            t,
            find.byKey(LumeWorldClockTool.rowKey('Asia/Dubai')),
          );
          await tapShown(t, find.byKey(LumeWorldClockTool.removeKey));
        },
      );
    });

    testWidgets('a stored alias, reading under both names', (
      WidgetTester t,
    ) async {
      await state(t, 'alias', session: listed(<String>['Asia/Calcutta']));
    });

    testWidgets('a zone the database does not know', (WidgetTester t) async {
      await state(
        t,
        'zone_unknown',
        reader: worldClockReader(timeZone: 'Asia/Atlantis'),
      );
    });

    testWidgets('the database is not available', (WidgetTester t) async {
      await state(
        t,
        'database_unavailable',
        service: LumeTimeZoneService.detached(),
      );
    });

    testWidgets('the device has not said where it is', (WidgetTester t) async {
      await state(
        t,
        'device_unknown',
        reader: worldClockReader(follow: LumeZoneFollow.device),
      );
    });

    testWidgets('the country has more than one civil time', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'choose_zone',
        reader: worldClockReader(country: 'US', region: '', city: ''),
      );
    });

    testWidgets('the search matches nothing', (WidgetTester t) async {
      await state(
        t,
        'no_match',
        after: (WidgetTester t) async {
          await t.enterText(find.byKey(LumeWorldClockTool.searchKey), 'zzzzzz');
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('nothing on the list but the reader\'s own clock', (
      WidgetTester t,
    ) async {
      await state(t, 'empty', session: listed(const <String>[]));
    });
  });
}

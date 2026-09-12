/// Home and the Tools hub, pinned as images and captured for the comparison.
///
/// Two jobs in one file, as the onboarding and authentication suites do:
///
/// * **goldens** — committed images that fail when a pixel moves, so a
///   refactor cannot quietly redraw a screen;
/// * **captures** — the `.flutter.png` that sits beside the browser's
///   `.web.png` in `docs/conversion_archive/shots/destinations`, so the two
///   can be looked at side by side.
///
/// The cells are the ones the brief names: the reference phone in light and
/// dark, the narrowest and the next phone, a tablet, a wide tablet, a phone on
/// its side, Urdu, Arabic and 200 % text — plus the state variants that only
/// exist in one of them.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/home/application/home_controller.dart';
import 'package:lume/features/home/data/home_fixtures.dart';
import 'package:lume/features/home/domain/home_repository.dart';
import 'package:lume/features/tools/domain/tools_filter.dart';
import 'package:lume/features/tools/presentation/tools_screen.dart';

import '../features/destinations/destination_harness.dart';
import '../helpers/capture.dart';
import '../helpers/load_fonts.dart';

const String kOut = '$kShotsDir/destinations';

/// Home and the hub are long pages. The reference cell is the *width*; the
/// height is the one the brief names, and the capture is the top of the page —
/// which is what the browser capture shows too.
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
    WidgetTester tester,
    Widget child,
    String name,
    Cell cell,
  ) async {
    await captureLume(
      tester,
      child,
      name: name,
      outDir: kOut,
      surface: cell.$2,
      theme: cell.$3,
      locale: cell.$4,
      textScale: cell.$5,
      // The capture's filename is `<name>_<w>x<h>_<theme>_<lang>`, which two
      // cells at the same geometry would share — so the text scale goes in the
      // suffix rather than silently overwriting the other one.
      suffix: cell.$5 == 1.0 ? '' : '_x${cell.$5.toStringAsFixed(0)}',
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/${name}_${cell.$1}.png'),
    );
  }

  group('Home', () {
    for (final Cell cell in kCells) {
      testWidgets('Muslim, Pakistan · ${cell.$1}', (WidgetTester tester) async {
        final LumeHomeController c = await composeHome(LumeUsers.muslimPk);
        addTearDown(c.dispose);
        await shoot(
          tester,
          homeScreenFor(c, LumeUsers.muslimPk),
          'home_muslim_pk',
          cell,
        );
      });
    }

    for (final String state in <String>[
      'default_pk',
      'muslim_gb',
      'default_us',
      'named_pk',
      'prefs_off_pk',
    ]) {
      testWidgets('$state · the reference cell', (WidgetTester tester) async {
        final LumeHomeController c = await composeHome(LumeUsers.all[state]!);
        addTearDown(c.dispose);
        await shoot(
          tester,
          homeScreenFor(c, LumeUsers.all[state]!),
          'home_$state',
          kCells.first,
        );
      });
    }
  });

  group('Home, in the states the data can be in', () {
    Future<void> state(
      WidgetTester tester,
      String name,
      LumeHomeRepository repository,
    ) async {
      final LumeHomeController c = controllerOn(repository);
      addTearDown(c.dispose);
      // The loading state is a load that has not returned, so it is started
      // and not awaited.
      unawaited(c.load(LumeUsers.defaultPk));
      if (repository is! LumeFakeHomeRepository || !repository.pending) {
        await c.load(LumeUsers.defaultPk);
      }
      await shoot(
        tester,
        homeScreenFor(c, LumeUsers.defaultPk),
        'home_$name',
        kCells.first,
      );
    }

    testWidgets('still loading', (WidgetTester tester) async {
      await state(tester, 'loading', LumeFakeHomeRepository.slow());
    });

    testWidgets('one section failed, the rest did not', (
      WidgetTester tester,
    ) async {
      await state(
        tester,
        'partial',
        LumeFakeHomeRepository(
          failing: const <LumeHomeSection>{LumeHomeSection.live},
        ),
      );
    });

    testWidgets('offline, with what was cached', (WidgetTester tester) async {
      await state(
        tester,
        'offline',
        LumeFakeHomeRepository(
          sources: const <LumeHomeSection, LumeSourceState>{
            LumeHomeSection.live: LumeSourceState.offline,
          },
        ),
      );
    });

    testWidgets('nothing loaded at all', (WidgetTester tester) async {
      await state(tester, 'failed', const LumeBrokenHomeRepository());
    });

    testWidgets('a user with nothing recorded', (WidgetTester tester) async {
      await state(tester, 'empty', LumeFakeHomeRepository(empty: true));
    });

    testWidgets('the market open rather than shut', (
      WidgetTester tester,
    ) async {
      // 11:00 in Karachi, which is inside the session — the live card then
      // says the market is open and the delta is against a live figure.
      final LumeHomeController c = controllerOn(
        LumeFakeHomeRepository(),
        now: DateTime(2026, 9, 7, 11),
      );
      addTearDown(c.dispose);
      await c.load(LumeUsers.defaultPk);
      await shoot(
        tester,
        homeScreenFor(c, LumeUsers.defaultPk),
        'home_market_open',
        kCells.first,
      );
    });
  });

  group('the Tools hub', () {
    for (final Cell cell in kCells) {
      testWidgets('a user with a history · ${cell.$1}', (
        WidgetTester tester,
      ) async {
        await shoot(
          tester,
          toolsScreenFor(LumeUsers.namedPk),
          'tools_named_pk',
          cell,
        );
      });
    }

    testWidgets('Muslim, Pakistan · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        toolsScreenFor(LumeUsers.muslimPk),
        'tools_muslim_pk',
        kCells.first,
      );
    });

    testWidgets('the United Kingdom · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        toolsScreenFor(LumeUsers.muslimGb),
        'tools_muslim_gb',
        kCells.first,
      );
    });

    testWidgets('everything · the reference cell', (WidgetTester tester) async {
      await shoot(
        tester,
        LumeToolsScreen(
          eligibility: kEligibility,
          user: LumeUsers.defaultPk,
          initialFilter: LumeToolsFilter.all,
          actions: LumeRecordedActions().toolsActions,
        ),
        'tools_all',
        kCells.first,
      );
    });

    testWidgets('a search with results · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        LumeToolsScreen(
          eligibility: kEligibility,
          user: LumeUsers.defaultPk,
          initialQuery: 'petrol',
          actions: LumeRecordedActions().toolsActions,
        ),
        'tools_search',
        kCells.first,
      );
    });

    testWidgets('a search with none · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        LumeToolsScreen(
          eligibility: kEligibility,
          user: LumeUsers.defaultPk,
          initialQuery: 'zzzzz',
          actions: LumeRecordedActions().toolsActions,
        ),
        'tools_noresults',
        kCells.first,
      );
    });

    testWidgets('a shortlist with nothing in it · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        toolsScreenFor(LumeUsers.noInterestsPk),
        'tools_nothing_yet',
        kCells.first,
      );
    });
  });
}

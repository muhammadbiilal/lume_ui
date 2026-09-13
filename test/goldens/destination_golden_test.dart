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
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/home/domain/home_repository.dart';
import 'package:lume/features/tools/domain/tools_filter.dart';
import 'package:lume/core/navigation/lume_destination.dart';
import 'package:lume/features/explore/data/explore_fixtures.dart';
import 'package:lume/features/explore/domain/explore_repository.dart';
import 'package:lume/features/explore/presentation/explore_screen.dart';
import 'package:lume/features/today/presentation/today_screen.dart';
import 'package:lume/features/trains/data/trains_fixtures.dart';
import 'package:lume/features/trains/domain/trains_model.dart';
import 'package:lume/features/trains/domain/trains_repository.dart';
import 'package:lume/features/trains/presentation/trains_screen.dart';
import 'package:lume/features/tools/presentation/tools_screen.dart';

import '../features/destinations/destination_harness.dart';
import '../features/destinations/today_explore_harness.dart';
import 'package:lume/features/account/domain/account_model.dart';
import '../features/destinations/profile_harness.dart';
import '../features/destinations/trains_harness.dart';
import '../helpers/capture.dart';
import '../helpers/load_fonts.dart';
import '../helpers/lume_harness.dart';

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

  group('Home, scrolled to the strips no viewport golden reaches', () {
    // Discover sits about 1,700 points down a 844-point screen, so every cell
    // above stops short of it — and Discover is where D23's localized outage
    // time and D33's reproduced weather literal both live. Two cells that
    // scroll to it, so those are pinned as pixels and not only as `find.text`.
    for (final (String name, String state, double offset) shot
        in <(String, String, double)>[
          ('home_muslim_pk_discover', 'muslim_pk', 1450),
          ('home_muslim_gb_discover', 'muslim_gb', 1450),
        ]) {
      testWidgets('${shot.$1} · the reference cell', (
        WidgetTester tester,
      ) async {
        final LumeUserContext user = LumeUsers.all[shot.$2]!;
        final LumeHomeController c = await composeHome(user);
        addTearDown(c.dispose);

        await pumpLume(
          tester,
          homeScreenFor(c, user),
          surface: kCells.first.$2,
        );
        // Jumped rather than dragged: a fling settles wherever physics puts
        // it, and a golden needs the same offset every run. The page's own
        // scrollable is the first in the tree; the strips' come after it.
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(shot.$3);
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('images/${shot.$1}_390x844_light_en.png'),
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
  group('Today', () {
    Future<Widget> screen(LumeUserContext user) async => LumeTodayScreen(
      user: user,
      data: await composeToday(user),
      actions: LumeRecordedDay().today,
    );

    for (final Cell cell in kCells) {
      testWidgets('Muslim, Pakistan, ${cell.$1}', (WidgetTester tester) async {
        await shoot(
          tester,
          await screen(LumeUsers.muslimPk),
          'today_muslim_pk',
          cell,
        );
      });
    }

    // The three other primary states, at the reference cell. Each changes what
    // the day *contains* rather than how it is drawn: no prayers and a thought
    // instead of an ayah, a different city's timetable, a market with no
    // outage.
    for (final String state in <String>[
      'default_pk',
      'muslim_gb',
      'default_us',
      'prefs_off_pk',
    ]) {
      testWidgets('$state, the reference cell', (WidgetTester tester) async {
        await shoot(
          tester,
          await screen(LumeUsers.all[state]!),
          'today_$state',
          kCells.first,
        );
      });
    }

    testWidgets('still arriving, the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        LumeTodayScreen(
          user: LumeUsers.muslimPk,
          actions: LumeRecordedDay().today,
        ),
        'today_loading',
        kCells.first,
      );
    });

    testWidgets('and when it could not be composed at all', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        LumeTodayScreen(
          user: LumeUsers.muslimPk,
          actions: LumeRecordedDay().today,
          failed: true,
          onRetry: () async {},
        ),
        'today_failed',
        kCells.first,
      );
    });
  });

  group('Today, scrolled past what a viewport golden reaches', () {
    // Tasks, habits and the private card sit below 844 points on the reference
    // cell, so every cell above stops short of them.
    for (final (String name, String state, double offset) shot
        in <(String, String, double)>[
          ('today_muslim_pk_lower', 'muslim_pk', 1200),
          ('today_default_pk_lower', 'default_pk', 900),
        ]) {
      testWidgets('${shot.$1}, the reference cell', (
        WidgetTester tester,
      ) async {
        final LumeUserContext user = LumeUsers.all[shot.$2]!;
        await pumpLume(
          tester,
          LumeTodayScreen(
            user: user,
            data: await composeToday(user),
            actions: LumeRecordedDay().today,
          ),
          surface: kCells.first.$2,
        );
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(shot.$3);
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('images/${shot.$1}_390x844_light_en.png'),
        );
      });
    }
  });

  group('Explore', () {
    Future<Widget> screen(LumeUserContext user) async => LumeExploreScreen(
      user: user,
      eligibility: kEligibility,
      snapshot: await composeExplore(user),
      actions: LumeRecordedDay().explore,
      // Pakistan has no Explore tab, so the capture carries the way back the
      // reference draws there. Every other market's does not.
      onBack:
          LumeDestinations.orderFor(
            user.country,
          ).contains(LumeDestinationId.explore)
          ? null
          : () {},
    );

    for (final Cell cell in kCells) {
      testWidgets('Muslim, Pakistan, ${cell.$1}', (WidgetTester tester) async {
        await shoot(
          tester,
          await screen(LumeUsers.muslimPk),
          'explore_muslim_pk',
          cell,
        );
      });
    }

    for (final String state in <String>[
      'default_pk',
      'muslim_gb',
      'default_us',
      'prefs_off_pk',
    ]) {
      testWidgets('$state, the reference cell', (WidgetTester tester) async {
        await shoot(
          tester,
          await screen(LumeUsers.all[state]!),
          'explore_$state',
          kCells.first,
        );
      });
    }

    testWidgets('still arriving, the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        LumeExploreScreen(
          user: LumeUsers.muslimPk,
          eligibility: kEligibility,
          actions: LumeRecordedDay().explore,
        ),
        'explore_loading',
        kCells.first,
      );
    });

    testWidgets('two sources that could not answer', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        LumeExploreScreen(
          user: LumeUsers.muslimPk,
          eligibility: kEligibility,
          snapshot: await composeExplore(
            LumeUsers.muslimPk,
            repository: LumeFakeExploreRepository(
              eligibility: kEligibility,
              failing: const <LumeExploreSource>{
                LumeExploreSource.around,
                LumeExploreSource.news,
              },
            ),
          ),
          actions: LumeRecordedDay().explore,
        ),
        'explore_partial',
        kCells.first,
      );
    });

    testWidgets('and when none of it could', (WidgetTester tester) async {
      await shoot(
        tester,
        LumeExploreScreen(
          user: LumeUsers.muslimPk,
          eligibility: kEligibility,
          actions: LumeRecordedDay().explore,
          failed: true,
          onRetry: () async {},
        ),
        'explore_failed',
        kCells.first,
      );
    });
  });

  group('Explore, scrolled past what a viewport golden reaches', () {
    for (final (String name, String state, double offset) shot
        in <(String, String, double)>[
          ('explore_muslim_pk_lower', 'muslim_pk', 1250),
          ('explore_muslim_gb_lower', 'muslim_gb', 1050),
        ]) {
      testWidgets('${shot.$1}, the reference cell', (
        WidgetTester tester,
      ) async {
        final LumeUserContext user = LumeUsers.all[shot.$2]!;
        await pumpLume(
          tester,
          LumeExploreScreen(
            user: user,
            eligibility: kEligibility,
            snapshot: await composeExplore(user),
            actions: LumeRecordedDay().explore,
          ),
          surface: kCells.first.$2,
        );
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(shot.$3);
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('images/${shot.$1}_390x844_light_en.png'),
        );
      });
    }
  });
  group('Profile', () {
    // The account state is part of the cell's identity: `profile_default_pk`
    // is a guest, and the same profile signed in is a different screen. The
    // names match `measure_destinations.mjs --account`, so a capture and its
    // comparison line up without a lookup table.
    const Map<String, LumeAccountState> states = <String, LumeAccountState>{
      'profile_default_pk': LumeAccountState.guest,
      'profile_default_pk_authed': LumeAccountState.authed,
      'profile_default_pk_expired': LumeAccountState.expired,
    };

    for (final MapEntry<String, LumeAccountState> e in states.entries) {
      for (final Cell cell in kCells) {
        testWidgets('${e.key} · ${cell.$1}', (WidgetTester tester) async {
          await shoot(
            tester,
            profileScreenFor(
              profileView(state: e.value),
              LumeRecordedProfile(),
            ),
            e.key,
            cell,
          );
        });
      }
    }

    // The account with no name at all — the one state that carries the
    // invitation to complete itself.
    testWidgets('profile_default_pk_noname · the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        profileScreenFor(
          profileView(
            state: LumeAccountState.authed,
            identity: kNamelessIdentity,
          ),
          LumeRecordedProfile(),
        ),
        'profile_default_pk_noname',
        kCells.first,
      );
    });
  });

  group('Trains', () {
    Future<Widget> screen(LumeUserContext user) async => LumeTrainsScreen(
      user: user,
      snapshot: await composeTrains(user),
      actions: LumeRecordedRail().actions,
    );

    for (final Cell cell in kCells) {
      testWidgets('Pakistan, ${cell.$1}', (WidgetTester tester) async {
        await shoot(
          tester,
          await screen(LumeUsers.muslimPk),
          'trains_muslim_pk',
          cell,
        );
      });
    }

    testWidgets('not Muslim, Pakistan, the reference cell', (
      WidgetTester tester,
    ) async {
      // The destination is country-gated, not faith-gated: the same screen.
      await shoot(
        tester,
        await screen(LumeUsers.defaultPk),
        'trains_default_pk',
        kCells.first,
      );
    });

    testWidgets('still arriving, the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        LumeTrainsScreen(
          user: LumeUsers.muslimPk,
          actions: LumeRecordedRail().actions,
        ),
        'trains_loading',
        kCells.first,
      );
    });

    testWidgets('a market without rail, the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        LumeTrainsScreen(
          user: LumeUsers.muslimGb,
          actions: LumeRecordedRail().actions,
          failure: LumeTrainsFailure.unsupported,
        ),
        'trains_unsupported',
        kCells.first,
      );
    });

    testWidgets('and a feed that could not answer', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        LumeTrainsScreen(
          user: LumeUsers.muslimPk,
          actions: LumeRecordedRail().actions,
          failure: LumeTrainsFailure.unreachable,
          onRetry: () async {},
        ),
        'trains_failed',
        kCells.first,
      );
    });

    testWidgets('the journey turned around, the reference cell', (
      WidgetTester tester,
    ) async {
      // R2: an interactive state, pinned as pixels. The card is the same
      // card; the two stations have exchanged.
      final LumeFakeTrainsRepository repo = LumeFakeTrainsRepository(
        eligibility: kEligibility,
      );
      final LumeTrainsSnapshot first = await repo.load(
        LumeUsers.muslimPk,
        now: kPinned,
      );
      await shoot(
        tester,
        LumeTrainsScreen(
          user: LumeUsers.muslimPk,
          snapshot: await repo.search(
            LumeUsers.muslimPk,
            now: kPinned,
            query: first.data.query.swapped(),
          ),
          actions: LumeRecordedRail().actions,
        ),
        'trains_swapped',
        kCells.first,
      );
    });

    testWidgets('tomorrow’s departures, the reference cell', (
      WidgetTester tester,
    ) async {
      // R3: the other selectable day. One timetable answers both, and the
      // selected chip is what moved.
      final LumeFakeTrainsRepository repo = LumeFakeTrainsRepository(
        eligibility: kEligibility,
      );
      final LumeTrainsSnapshot first = await repo.load(
        LumeUsers.muslimPk,
        now: kPinned,
      );
      await shoot(
        tester,
        LumeTrainsScreen(
          user: LumeUsers.muslimPk,
          snapshot: await repo.search(
            LumeUsers.muslimPk,
            now: kPinned,
            query: first.data.query.withDay(
              LumeJourneyDay.tomorrow,
              on: kPinned.add(const Duration(days: 1)),
            ),
          ),
          actions: LumeRecordedRail().actions,
        ),
        'trains_tomorrow',
        kCells.first,
      );
    });

    testWidgets('a route that is not a journey, the reference cell', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        LumeTrainsScreen(
          user: LumeUsers.muslimPk,
          snapshot: await composeTrains(LumeUsers.muslimPk),
          status: LumeQueryStatus.invalid,
          actions: LumeRecordedRail().actions,
        ),
        'trains_invalid',
        kCells.first,
      );
    });

    testWidgets('and one source of three unavailable', (
      WidgetTester tester,
    ) async {
      await shoot(
        tester,
        LumeTrainsScreen(
          user: LumeUsers.muslimPk,
          snapshot: await composeTrains(
            LumeUsers.muslimPk,
            repository: LumeFakeTrainsRepository(
              eligibility: kEligibility,
              failing: const <LumeTrainsSource>{LumeTrainsSource.tracked},
            ),
          ),
          actions: LumeRecordedRail().actions,
        ),
        'trains_partial',
        kCells.first,
      );
    });
  });
}

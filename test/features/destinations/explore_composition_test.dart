/// What Explore puts on the screen, and whether it is entitled to.
///
/// The reference sets its own standard in its header comment: *"this screen
/// must never show a market, a unit or a venue from somewhere the user is
/// not."* Half of it meets that standard and half does not, and the halves are
/// tested differently — the honest sections are asserted to *be* honest, and
/// the two that are not are asserted to reproduce the reference exactly, so
/// the defect stays visible instead of drifting into something invented.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';
import 'package:lume/core/widgets/lume/lume_explore.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/explore/data/explore_fixtures.dart';
import 'package:lume/features/explore/domain/explore_model.dart';
import 'package:lume/features/explore/domain/explore_repository.dart';
import 'package:lume/features/explore/presentation/explore_screen.dart';
import 'package:lume/features/home/domain/home_model.dart';

import '../../helpers/load_fonts.dart';
import 'destination_harness.dart';
import 'today_explore_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  group('the sections, in the order the source emits them', () {
    testWidgets('head, featured, weather, around, cricket, reads, '
        'collections, nearby', (WidgetTester tester) async {
      await pumpExplore(
        tester,
        LumeUsers.muslimPk.copyWith(
          interests: <String>{...LumeUsers.muslimPk.interests, 'cricket'},
        ),
        surface: const Size(390, 4000),
      );

      const List<String> order = <String>[
        LumeExploreScreen.headKey,
        LumeExploreScreen.featuredKey,
        LumeExploreScreen.weatherKey,
        LumeExploreScreen.aroundKey,
        LumeExploreScreen.cricketKey,
        LumeExploreScreen.newsKey,
        LumeExploreScreen.collectionsKey,
        LumeExploreScreen.nearbyKey,
      ];
      final List<double> tops = <double>[
        for (final String key in order)
          tester.getTopLeft(find.byKey(ValueKey<String>(key))).dy,
      ];
      for (int i = 1; i < tops.length; i++) {
        expect(
          tops[i],
          greaterThan(tops[i - 1]),
          reason: '${order[i]} is above ${order[i - 1]}',
        );
      }
    });
  });

  group('the weather, which is honest', () {
    test('reads the market\'s own entry', () async {
      final LumeExploreWeather pk = (await composeExplore(
        LumeUsers.muslimPk,
      )).data.weather;
      final LumeExploreWeather gb = (await composeExplore(
        LumeUsers.muslimGb,
      )).data.weather;
      final LumeExploreWeather us = (await composeExplore(
        LumeUsers.defaultUs,
      )).data.weather;

      // Measured: Islamabad 34/38, London 21/19, New York 24/24.
      expect((pk.temperatureC, pk.feelsLikeC, pk.city), (34, 38, 'Islamabad'));
      expect((gb.temperatureC, gb.feelsLikeC, gb.city), (21, 19, 'London'));
      expect((us.temperatureC, us.feelsLikeC, us.city), (24, 24, 'New York'));
    });

    testWidgets('and shows it in the reader\'s own units', (
      WidgetTester tester,
    ) async {
      await pumpExplore(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      // The figure and its degree sign are two spans in one run, so the card
      // is asked rather than the text — which is also what keeps the two from
      // being drawn as separate widgets that could drift apart.
      String degreesOn(WidgetTester t) =>
          t.widget<LumeWeatherCard>(find.byType(LumeWeatherCard)).temperature;

      expect(degreesOn(tester), '34');
      expect(find.text('Hazy sun · humid · 38°'), findsOneWidget);
      expect(find.text('14 km/h'), findsOneWidget);

      // The United States measures in Fahrenheit and miles, and the reference
      // converts both. 24 °C is 75 °F; 10 km/h is 6 mph.
      await pumpExplore(
        tester,
        LumeUsers.defaultUs,
        surface: const Size(390, 4000),
      );
      expect(degreesOn(tester), '75');
      expect(find.text('6 mph'), findsOneWidget);
    });

    testWidgets('and its sunset is the same calculation the prayers use', (
      WidgetTester tester,
    ) async {
      await pumpExplore(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      // Maghrib is 18:27 in Islamabad, and the card cannot disagree with it.
      expect(find.text('6:27 pm'), findsOneWidget);
    });

    testWidgets('and its three figures are read out as words', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpExplore(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(find.bySemanticsLabel('Rain 8%'), findsOneWidget);
      expect(find.bySemanticsLabel('Wind 14 km/h'), findsOneWidget);
      expect(find.bySemanticsLabel('Sunset 6:27 pm'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('but its freshness is the prototype\'s literal (E1)', (
      WidgetTester tester,
    ) async {
      // Reproduced by decision, and asserted so it cannot quietly become
      // something truer or something else. Dayroz replaces it with a real
      // fetch timestamp.
      for (final LumeUserContext user in <LumeUserContext>[
        LumeUsers.muslimPk,
        LumeUsers.muslimGb,
        LumeUsers.defaultUs,
      ]) {
        final LumeExploreSnapshot s = await composeExplore(user);
        // A timestamp, not a number: the fixture pins the reading four
        // minutes before the clock, and the screen subtracts.
        expect(
          s.data.weather.observedAt,
          kPinned.subtract(
            const Duration(minutes: kReferenceWeatherAgeMinutes),
          ),
        );
        expect(
          s.data.weather.minutesAgoAt(kPinned),
          kReferenceWeatherAgeMinutes,
        );
      }
      await pumpExplore(
        tester,
        LumeUsers.muslimGb,
        surface: const Size(390, 4000),
      );
      expect(find.text('London · updated 4 min ago'), findsOneWidget);
    });
  });

  group('around you, which is honest', () {
    test(
      'lists the services this market actually has, in source order',
      () async {
        final List<String> pk = (await composeExplore(
          LumeUsers.muslimPk,
        )).data.around.map((LumeAroundService s) => s.featureId).toList();
        expect(pk, <String>[
          'fuel',
          'loadshed',
          'goldrates',
          'trains',
          'emergency',
          'holidays',
        ]);

        // Measured: the United Kingdom has four — no loadshedding, no trains.
        final List<String> gb = (await composeExplore(
          LumeUsers.muslimGb,
        )).data.around.map((LumeAroundService s) => s.featureId).toList();
        expect(gb, <String>['fuel', 'goldrates', 'emergency', 'holidays']);
      },
    );

    test('and the content switches take one away', () async {
      // Measured: with the switches off Pakistan drops to five — Currency &
      // Gold is the one the preference gate reaches.
      final List<String> off = (await composeExplore(
        LumeUsers.prefsOffPk,
      )).data.around.map((LumeAroundService s) => s.featureId).toList();
      expect(off, isNot(contains('goldrates')));
      expect(off, hasLength(5));
    });

    test('and each row carries the market\'s own values', () async {
      final List<LumeAroundService> pk = (await composeExplore(
        LumeUsers.muslimPk,
      )).data.around;
      final LumeAroundService fuel = pk.first;
      expect(fuel.value, 'Rs 264.61');
      expect(fuel.subtitle, 'Petrol · Hi-Octane · Diesel');

      final List<LumeAroundService> us = (await composeExplore(
        LumeUsers.defaultUs,
      )).data.around;
      expect(us.first.value, r'$3.12');
      expect(us.first.subtitle, 'Regular · Mid-grade · Premium');
    });

    test(
      'and a service with no figure shows none rather than a blank',
      () async {
        final LumeAroundService trains =
            (await composeExplore(LumeUsers.muslimPk)).data.around.firstWhere(
              (LumeAroundService s) => s.featureId == 'trains',
            );
        expect(trains.value, isNull);
        expect(trains.subtitle, 'Green Line Express · On time');
      },
    );

    testWidgets('and one service is not a section', (
      WidgetTester tester,
    ) async {
      // `wrap.hidden = rows.length < 2` — the reference's own rule.
      final LumeExploreData one = LumeExploreData(
        countryCode: 'ZZ',
        countryName: 'ZZ',
        localised: false,
        featured: const LumeFeaturedCollection(
          id: LumeFeatureId.calmWeek,
          target: LumeHomeTargetStub.none,
        ),
        weather: LumeExploreWeather(
          city: 'Nowhere',
          temperatureC: 0,
          feelsLikeC: 0,
          conditionKey: 'clear',
          rainPercent: 0,
          windKph: 0,
          icon: '',
          sunsetMinute: 0,
          // A timestamp keeps this out of const, which is fine: the
          // shape is what the assertion is about.
          observedAt: DateTime(2026),
        ),
        around: const <LumeAroundService>[
          LumeAroundService(featureId: 'fuel', icon: '', subtitle: 'x'),
        ],
        score: null,
        news: <LumeNewsArticle>[],
        collections: <LumeCollectionCard>[],
        nearby: <LumeNearbyPlace>[],
      );
      expect(one.showAround, isFalse);
    });

    testWidgets('and the market names itself in the head', (
      WidgetTester tester,
    ) async {
      await pumpExplore(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>(LumeExploreScreen.aroundKey)),
          matching: find.widgetWithText(LumeTag, 'Pakistan'),
        ),
        findsOneWidget,
      );
    });
  });

  group('the news, which follows the country', () {
    test('Pakistan gets its own edition', () async {
      final List<String> pk = (await composeExplore(
        LumeUsers.muslimPk,
      )).data.news.map((LumeNewsArticle a) => a.id).toList();
      expect(pk, <String>['rupee', 'loadshed', 'squad']);
    });

    test('and everywhere else gets the global one', () async {
      for (final LumeUserContext user in <LumeUserContext>[
        LumeUsers.muslimGb,
        LumeUsers.defaultUs,
      ]) {
        final List<String> ids = (await composeExplore(
          user,
        )).data.news.map((LumeNewsArticle a) => a.id).toList();
        expect(ids, <String>['reset', 'shortList', 'savings'], reason: '$user');
      }
    });

    testWidgets('and a story names its category and its reading time', (
      WidgetTester tester,
    ) async {
      await pumpExplore(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(find.text('BUSINESS'), findsOneWidget);
      expect(
        find.text('Rupee holds steady as remittances climb for a third month'),
        findsOneWidget,
      );
      expect(find.text('4 min read'), findsOneWidget);
    });
  });

  group('the cricket, which follows the interests', () {
    test('is there for a reader who asked for it', () async {
      final LumeUserContext fan = LumeUsers.muslimPk.copyWith(
        interests: <String>{...LumeUsers.muslimPk.interests, 'cricket'},
      );
      expect((await composeExplore(fan)).data.score, isNotNull);
    });

    test('and gone for one who did not', () async {
      // The seven default interests do not include cricket, which is why the
      // section is hidden in every captured state.
      expect((await composeExplore(LumeUsers.muslimPk)).data.score, isNull);
    });

    test('and there for a reader who chose nothing at all', () async {
      // `if (!profile.interests.length) { gate(el, true); return; }`
      final LumeUserContext blank = LumeUsers.muslimPk.copyWith(
        interests: const <String>{},
      );
      expect((await composeExplore(blank)).data.score, isNotNull);
    });

    testWidgets('and the section is absent rather than empty', (
      WidgetTester tester,
    ) async {
      await pumpExplore(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(
        find.byKey(const ValueKey<String>(LumeExploreScreen.cricketKey)),
        findsNothing,
      );
      expect(find.byType(LumeScoreCard), findsNothing);
    });
  });

  group('the faith gates', () {
    test('swap the featured collection', () async {
      expect(
        (await composeExplore(LumeUsers.muslimPk)).data.featured.id,
        LumeFeatureId.duas,
      );
      expect(
        (await composeExplore(LumeUsers.defaultPk)).data.featured.id,
        LumeFeatureId.calmWeek,
      );
    });

    test('and drop the first collection and the first nearby row', () async {
      final LumeExploreData muslim = (await composeExplore(
        LumeUsers.muslimPk,
      )).data;
      final LumeExploreData other = (await composeExplore(
        LumeUsers.defaultPk,
      )).data;
      expect(muslim.collections, hasLength(4));
      expect(other.collections, hasLength(3));
      expect(muslim.nearby, hasLength(3));
      expect(other.nearby, hasLength(2));
      expect(
        other.collections.map((LumeCollectionCard c) => c.id),
        isNot(contains('nightSurahs')),
      );
    });
  });

  group('nearby, which is not honest and is reproduced anyway (E2)', () {
    testWidgets('shows the same three Karachi venues in every market', (
      WidgetTester tester,
    ) async {
      // The reference hard-codes them with no city gate and no source, so a
      // reader in London is told a Karachi mosque is 650 m away. Decided:
      // reproduce Lume exactly, record the defect, and make Dayroz responsible
      // for a real places source. Asserted here so the decision is visible and
      // cannot drift into something invented.
      for (final LumeUserContext user in <LumeUserContext>[
        LumeUsers.muslimPk,
        LumeUsers.muslimGb,
      ]) {
        await pumpExplore(tester, user, surface: const Size(390, 4000));
        expect(find.text('Masjid-e-Tooba'), findsOneWidget, reason: '$user');
        expect(find.text('650 m'), findsOneWidget, reason: '$user');
        expect(find.text('Chai Shai'), findsOneWidget);
        expect(find.text('1.1 km'), findsOneWidget);
        expect(find.text('Hill Park'), findsOneWidget);
      }
    });

    test('and its distances are written down, not measured', () async {
      final List<LumeNearbyPlace> places = (await composeExplore(
        LumeUsers.muslimPk,
      )).data.nearby;
      expect(
        places.map((LumeNearbyPlace p) => p.distanceMetres).toList(),
        <int>[650, 1100, 1400],
      );
    });
  });

  group('nothing here is labelled live', () {
    test('every source reports itself as a fixture', () async {
      final LumeExploreSnapshot s = await composeExplore(LumeUsers.muslimPk);
      for (final LumeExploreSource source in LumeExploreSource.values) {
        expect(s.of(source), LumeSourceFreshness.fixture, reason: source.name);
      }
    });

    test(
      'and a source that cannot answer says so rather than vanishing',
      () async {
        final LumeExploreSnapshot s = await composeExplore(
          LumeUsers.muslimPk,
          repository: LumeFakeExploreRepository(
            eligibility: kEligibility,
            failing: <LumeExploreSource>{LumeExploreSource.around},
          ),
        );
        expect(s.of(LumeExploreSource.around), LumeSourceFreshness.unavailable);
        expect(s.data.around, isEmpty);
        expect(s.of(LumeExploreSource.news), LumeSourceFreshness.fixture);
        expect(
          s.data.news,
          isNotEmpty,
          reason: 'one failure is not all of them',
        );
      },
    );

    testWidgets('and the section says so on the screen', (
      WidgetTester tester,
    ) async {
      await pumpExplore(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
        repository: LumeFakeExploreRepository(
          eligibility: kEligibility,
          failing: <LumeExploreSource>{LumeExploreSource.around},
        ),
      );
      // The head is still there, so the reader knows their market has local
      // services and that this is a failure rather than an absence.
      expect(find.text('Around you'), findsOneWidget);
      expect(find.byType(LumeListRow), findsWidgets, reason: 'Nearby remains');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>(LumeExploreScreen.aroundKey)),
          matching: find.byType(LumeListRow),
        ),
        findsNothing,
      );
    });
  });

  group('the page head', () {
    testWidgets('says which kind of market this is', (
      WidgetTester tester,
    ) async {
      await pumpExplore(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(find.text('Local services, scores and reading'), findsOneWidget);
    });

    test('and a market with nothing localised gets the other line', () async {
      final LumeUserContext nowhere = LumeUsers.muslimPk.copyWith(
        country: 'ZZ',
        city: 'Nowhere',
      );
      expect((await composeExplore(nowhere)).data.localised, isFalse);
    });
  });

  group('the way back out', () {
    testWidgets('is there in a market where Explore is not a tab', (
      WidgetTester tester,
    ) async {
      // `explore.screen.js`: "Explore is reachable in Pakistan even though it
      // is not a tab there, so it carries its own way back."
      final LumeRecordedDay day = await pumpExplore(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 2000),
      );
      expect(find.bySemanticsLabel('Back to home'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back to home'));
      await tester.pump();
      expect(day.backs, 1);
    });

    testWidgets('and gone where it is one', (WidgetTester tester) async {
      await pumpExplore(
        tester,
        LumeUsers.muslimGb,
        surface: const Size(390, 2000),
      );
      expect(find.bySemanticsLabel('Back to home'), findsNothing);
      // The head is otherwise unchanged: the title, the subtitle and search.
      expect(find.text('Explore'), findsWidgets);
      expect(find.bySemanticsLabel('Search everything'), findsOneWidget);
    });
  });
}

/// A `LumeHomeTarget` for a card that goes nowhere, so the one structural
/// assertion above does not need a real destination.
abstract final class LumeHomeTargetStub {
  static const LumeHomeTarget none = LumeHomeTarget.tool('');
}

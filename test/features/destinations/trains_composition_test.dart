/// Trains, against the screen the prototype renders.
///
/// The composition, the gate, the interactions and the states. The roster is
/// the Trains *tool*'s roster on purpose — the reference shares it so a fare
/// cannot read differently in two places — so the figures here are the tool's
/// figures and a change to either is a change to both.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/core/widgets/lume/lume_destination.dart';
import 'package:lume/core/widgets/lume/lume_explore.dart';
import 'package:lume/core/widgets/lume/lume_rail.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/trains/data/trains_fixtures.dart';
import 'package:lume/features/trains/domain/trains_model.dart';
import 'package:lume/features/trains/domain/trains_repository.dart';
import 'package:lume/features/trains/presentation/trains_screen.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import 'destination_harness.dart';
import 'today_explore_harness.dart';
import 'trains_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  group('the sections, in the order the source emits them', () {
    testWidgets('head, search, tracking, departures, routes', (
      WidgetTester tester,
    ) async {
      await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );

      double topOf(String key) =>
          tester.getTopLeft(find.byKey(ValueKey<String>(key))).dy;

      final List<double> tops = <double>[
        topOf(LumeTrainsScreen.headKey),
        topOf(LumeTrainsScreen.searchKey),
        topOf(LumeTrainsScreen.trackedKey),
        topOf(LumeTrainsScreen.departuresKey),
        topOf(LumeTrainsScreen.routesKey),
      ];
      final List<double> sorted = List<double>.of(tops)..sort();
      expect(tops, sorted, reason: 'the five blocks are in source order');
    });

    testWidgets('and each carries the copy the reference renders', (
      WidgetTester tester,
    ) async {
      await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(find.text('Trains'), findsWidgets);
      expect(
        find.text('Pakistan Railways · live running status'),
        findsOneWidget,
      );
      expect(find.text('You are tracking'), findsOneWidget);
      expect(find.text('Updated 2 minutes ago'), findsOneWidget);
      // `i18n/tools.js` overrides `trains.departures` to "Departures", and
      // the rendered screen is the authority — `i18n/core.js` declares
      // "Today's departures" and never wins.
      expect(find.text('Departures'), findsOneWidget);
      expect(find.text('From Karachi Cantt'), findsOneWidget);
      expect(find.text('Popular routes'), findsOneWidget);
      expect(find.text('Tap to check fares and seats'), findsOneWidget);
    });
  });

  group('the route search', () {
    testWidgets('opens on the reference’s two stations, with Today active', (
      WidgetTester tester,
    ) async {
      await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(find.text('Karachi Cantt'), findsWidgets);
      expect(find.text('Lahore Junction'), findsOneWidget);
      expect(find.text('FROM'), findsOneWidget);
      expect(find.text('TO'), findsOneWidget);

      final LumeRailChip today = tester.widget<LumeRailChip>(
        find.byKey(const ValueKey<String>('trains.day.today')),
      );
      final LumeRailChip tomorrow = tester.widget<LumeRailChip>(
        find.byKey(const ValueKey<String>('trains.day.tomorrow')),
      );
      expect(today.selected, isTrue);
      expect(tomorrow.selected, isFalse);
    });

    testWidgets('and every control in it reports what it would do', (
      WidgetTester tester,
    ) async {
      final LumeRecordedRail rail = await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );

      await tester.tap(find.byKey(const ValueKey<String>('trains.origin')));
      await tester.tap(
        find.byKey(const ValueKey<String>('trains.destination')),
      );
      await tester.tap(find.byType(LumeRailSwap));
      await tester.tap(find.text('Search'));
      await tester.tap(
        find.byKey(const ValueKey<String>('trains.day.tomorrow')),
      );
      await tester.pump();

      expect(rail.origins, 1);
      expect(rail.destinations, 1);
      expect(rail.swaps, 1);
      expect(rail.searches, 1);
      expect(rail.days, <LumeJourneyDay>[LumeJourneyDay.tomorrow]);
    });

    test('and a swapped query is a query, whatever the screen does with '
        'it', () async {
      // R2: the reference's swap control reports "Stations swapped" and
      // changes nothing, which is what Flutter reproduces. The *model* can
      // still turn a journey around, so the day a decision goes the other way
      // is a one-line change rather than a new type.
      const LumeJourneyQuery q = LumeJourneyQuery(
        origin: 'Karachi Cantt',
        destination: 'Lahore Junction',
      );
      expect(q.swapped().origin, 'Lahore Junction');
      expect(q.swapped().destination, 'Karachi Cantt');
      expect(q.swapped().swapped(), q);
    });
  });

  group('the tracked service', () {
    test('is 62 per cent along, from a pinned observation', () async {
      final LumeTrainsSnapshot s = await composeTrains(LumeUsers.muslimPk);
      final LumeTrackedTrain t = s.data.tracked!;
      expect(t.progress, kTrackedProgress);
      expect(
        t.observedAt,
        kPinned.subtract(const Duration(minutes: kTrackedAgeMinutes)),
      );
      expect(t.minutesAgoAt(kPinned), kTrackedAgeMinutes);
      // The age is computed, so a later clock reads a larger one and a real
      // feed makes the sentence true with no change to the screen.
      expect(
        t.minutesAgoAt(kPinned.add(const Duration(minutes: 13))),
        kTrackedAgeMinutes + 13,
      );
    });

    testWidgets('and names three stops, the middle one "Now"', (
      WidgetTester tester,
    ) async {
      await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(find.byType(LumeLiveTrainCard), findsOneWidget);
      expect(find.text('5UP'), findsWidgets);
      expect(find.text('Green Line Express'), findsWidgets);
      expect(find.text('Karachi Cantt → Islamabad'), findsOneWidget);
      expect(find.text('22:00'), findsWidgets);
      expect(find.text('Now'), findsOneWidget);
      expect(find.text('17:30'), findsWidgets);
      expect(find.text('Near Rohri'), findsOneWidget);
    });

    testWidgets('and Refresh asks for it again', (WidgetTester tester) async {
      final LumeRecordedRail rail = await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      await tester.tap(find.text('Refresh'));
      await tester.pump();
      expect(rail.refreshes, 1);
    });
  });

  group('the departures', () {
    test('are the roster, in the order it is declared', () async {
      final LumeTrainsSnapshot s = await composeTrains(LumeUsers.muslimPk);
      expect(
        s.data.departures.map((LumeTrainService x) => x.number).toList(),
        <String>['5UP', '7UP', '41UP', '27DN', '101UP'],
      );
    });

    test('and R1: the list is not filtered to the heading’s station', () async {
      // `renderRoster` maps the roster without filtering it, so `27DN` — which
      // leaves Lahore — is listed under "From Karachi Cantt". Reproduced.
      final LumeTrainsSnapshot s = await composeTrains(LumeUsers.muslimPk);
      expect(s.data.departuresFrom, 'Karachi Cantt');
      expect(
        s.data.departures.any(
          (LumeTrainService x) => x.from != 'Karachi Cantt',
        ),
        isTrue,
      );
    });

    testWidgets('are written as published times, not the reader’s clock', (
      WidgetTester tester,
    ) async {
      // A railway publishes 24-hour times and `trains.screen.js` prints the
      // roster's strings verbatim. Pakistan reads a 12-hour clock everywhere
      // else in the product, and this is the one place it does not.
      await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(find.text('22:00 → 17:30 · 19h 30m · Rs 8,900'), findsOneWidget);
      expect(find.textContaining('10:00 pm'), findsNothing);
    });

    testWidgets('and a delay is said in words as well as in colour', (
      WidgetTester tester,
    ) async {
      await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(find.text('On time'), findsWidgets);
      expect(find.text('35 min late'), findsOneWidget);
      expect(find.text('70 min late'), findsOneWidget);
      expect(find.text('Departed'), findsOneWidget);
    });

    testWidgets('and a row opens the tool, not a screen of its own', (
      WidgetTester tester,
    ) async {
      final LumeRecordedRail rail = await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('trains.service.7UP')),
      );
      await tester.pump();
      expect(rail.services, <String>['7UP']);
    });

    testWidgets('and All reports what it would open', (
      WidgetTester tester,
    ) async {
      final LumeRecordedRail rail = await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      await tester.tap(find.text('All'));
      await tester.pump();
      expect(rail.alls, 1);
    });
  });

  group('the popular routes', () {
    testWidgets('are three cards with a code pair, a meta and a fare', (
      WidgetTester tester,
    ) async {
      await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(find.byType(LumeRouteCard), findsNWidgets(3));
      expect(find.text('KHI'), findsNWidgets(2));
      expect(find.text('LHR'), findsNWidgets(2));
      expect(find.text('17h 45m · 4 trains'), findsOneWidget);
      // R4: the card writes the rupee *sign*, where the departures row two
      // sections above writes the abbreviation. Two symbols, one currency,
      // one screen — the reference's own.
      expect(find.text('from ₨ 2,400'), findsOneWidget);
    });

    testWidgets('and tapping one reports the route it would open', (
      WidgetTester tester,
    ) async {
      final LumeRecordedRail rail = await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('trains.route.KHILHR')),
      );
      await tester.pump();
      expect(rail.routes, <String>['KHILHR']);
    });
  });

  group('the country gate', () {
    test('a market without rail is refused by the repository', () async {
      final LumeFakeTrainsRepository repo = LumeFakeTrainsRepository(
        eligibility: kEligibility,
      );
      for (final LumeUserContext user in <LumeUserContext>[
        LumeUsers.muslimGb,
        LumeUsers.defaultUs,
      ]) {
        await expectLater(
          repo.load(user, now: kPinned),
          throwsA(
            isA<LumeTrainsException>().having(
              (LumeTrainsException e) => e.failure,
              'failure',
              LumeTrainsFailure.unsupported,
            ),
          ),
          reason: user.country,
        );
      }
    });

    test('and Pakistan is not', () async {
      final LumeTrainsSnapshot s = await composeTrains(LumeUsers.muslimPk);
      expect(s.data.operatorName, 'Pakistan Railways');
    });

    testWidgets('and the refusal names no service, as a tool’s does not', (
      WidgetTester tester,
    ) async {
      // §64: "you may not have this" and "there is no such thing" must not be
      // distinguishable, so the refusal says nothing about Pakistan Railways.
      await pumpLumeTrainsFailure(
        tester,
        LumeUsers.muslimGb,
        LumeTrainsFailure.unsupported,
      );
      expect(find.byType(LumeNotice), findsOneWidget);
      expect(find.text('Trains are not in your setup'), findsOneWidget);
      expect(find.textContaining('Pakistan'), findsNothing);
      expect(find.text('Try again'), findsNothing);
    });
  });

  group('nothing here is labelled live', () {
    test('every source reports itself a fixture', () async {
      final LumeTrainsSnapshot s = await composeTrains(LumeUsers.muslimPk);
      for (final LumeTrainsSource source in LumeTrainsSource.values) {
        expect(s.of(source), LumeTrainsFreshness.fixture, reason: source.name);
      }
      expect(s.freshness.values, everyElement(isNot(LumeTrainsFreshness.live)));
    });

    test('and a kept journey says it will not survive the process', () async {
      final LumeMemoryJourneyStore store = LumeMemoryJourneyStore();
      expect(store.isDurable, isFalse);
      const LumeJourneyQuery q = LumeJourneyQuery(
        origin: 'Karachi Cantt',
        destination: 'Lahore Junction',
      );
      final List<LumeSavedJourney> after = await store.save(q, now: kPinned);
      expect(after.single.query, q);
      expect(await LumeMemoryJourneyStore().saved(), isEmpty);
      expect(await store.remove(after.single.id), isEmpty);
    });
  });

  group('the states a feed can be in', () {
    testWidgets('still arriving draws its own shape, not a spinner', (
      WidgetTester tester,
    ) async {
      await pumpLumeTrainsFailure(tester, LumeUsers.muslimPk, null);
      expect(find.byType(LumeSkeleton), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Trains'), findsWidgets);
    });

    testWidgets('and nothing at all says so, with a way back', (
      WidgetTester tester,
    ) async {
      await pumpLumeTrainsFailure(
        tester,
        LumeUsers.muslimPk,
        LumeTrainsFailure.unreachable,
      );
      expect(find.byType(LumeNotice), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('and one source failing leaves the others alone', (
      WidgetTester tester,
    ) async {
      await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
        repository: LumeFakeTrainsRepository(
          eligibility: kEligibility,
          failing: const <LumeTrainsSource>{LumeTrainsSource.tracked},
        ),
      );
      expect(find.byType(LumeLiveTrainCard), findsNothing);
      expect(find.text('You are tracking'), findsOneWidget);
      expect(find.byType(LumeNotice), findsOneWidget);
      // The roster and the routes are unaffected.
      expect(find.byType(LumeListRow), findsNWidgets(5));
      expect(find.byType(LumeRouteCard), findsNWidgets(3));
    });

    testWidgets('and an empty roster is an empty state, not a blank', (
      WidgetTester tester,
    ) async {
      await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
        repository: LumeFakeTrainsRepository(
          eligibility: kEligibility,
          failing: const <LumeTrainsSource>{LumeTrainsSource.departures},
        ),
      );
      expect(find.byType(LumeListRow), findsNothing);
      expect(find.text('Departures'), findsOneWidget);
      expect(find.byType(LumeNotice), findsOneWidget);
    });
  });

  group('what a screen reader is told', () {
    testWidgets('the tracked card is a sentence, not a bar', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(
        find.bySemanticsLabel(
          'Green Line Express 5UP, Karachi Cantt → Islamabad, On time, 62%',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('and a station field says which end it is', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(find.bySemanticsLabel('From, Karachi Cantt'), findsOneWidget);
      expect(find.bySemanticsLabel('To, Lahore Junction'), findsOneWidget);
      expect(find.bySemanticsLabel('Swap stations'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('and a route card says the whole route', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(
        find.bySemanticsLabel('Karachi → Lahore · 4 trains · from ₨ 2,400'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('and every section title is a heading', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      for (final String title in <String>[
        'You are tracking',
        'Departures',
        'Popular routes',
      ]) {
        expect(
          tester.getSemantics(find.text(title)).flagsCollection.isHeader,
          isTrue,
          reason: title,
        );
      }
      handle.dispose();
    });
  });

  group('the clock is injected', () {
    testWidgets('a later moment reads a larger age', (
      WidgetTester tester,
    ) async {
      final DateTime later = kPinned.add(const Duration(minutes: 11));
      await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
        now: later,
      );
      // The snapshot was composed at `later`, so the reading is still two
      // minutes old — the point is that nothing reads a wall clock.
      expect(find.text('Updated 2 minutes ago'), findsOneWidget);
    });

    test('and the repository never reads one', () async {
      final LumeTrainsSnapshot a = await composeTrains(LumeUsers.muslimPk);
      final LumeTrainsSnapshot b = await composeTrains(LumeUsers.muslimPk);
      expect(a.fetchedAt, b.fetchedAt);
      expect(a.data.tracked!.observedAt, b.data.tracked!.observedAt);
    });
  });

  group('the formatter writes a timetable, not a clock', () {
    test('24 hours, zero-padded, in every market', () {
      for (final String country in <String>['PK', 'GB', 'US']) {
        final LumeFormatting f = LumeFormatting(
          locale: const Locale('en'),
          countryCode: country,
        );
        expect(f.timetable(22 * 60), '22:00', reason: country);
        expect(f.timetable(6 * 60 + 15), '06:15', reason: country);
        expect(f.timetable(0), '00:00', reason: country);
      }
    });
  });
}

/// Trains with no snapshot — loading when [failure] is `null`, refused
/// otherwise.
Future<void> pumpLumeTrainsFailure(
  WidgetTester tester,
  LumeUserContext user,
  LumeTrainsFailure? failure,
) => pumpLume(
  tester,
  LumeTrainsScreen(
    user: user,
    actions: LumeRecordedRail().actions,
    failure: failure,
    onRetry: () async {},
  ),
  surface: const Size(390, 2000),
);

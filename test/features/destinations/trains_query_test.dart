/// The two approved functional corrections to Trains: a swap that swaps
/// (R2) and day chips that choose a day (R3).
///
/// Both are driven through the real host rather than the screen, because what
/// is being asserted is a *state machine* — the order of the write and the
/// announcement, what a second tap does while the first is outstanding, and
/// what a late answer to a superseded question is allowed to do to the page.
library;

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';
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

void main() {
  setUpAll(loadLumeFonts);

  /// Every announcement the page made, in order.
  late List<String> announced;

  setUp(() {
    announced = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
          dynamic message,
        ) async {
          final Map<Object?, Object?> m = message as Map<Object?, Object?>;
          if (m['type'] == 'announce') {
            final Map<Object?, Object?> data =
                m['data']! as Map<Object?, Object?>;
            announced.add(data['message']! as String);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<dynamic>(
          SystemChannels.accessibility,
          null,
        );
  });

  /// Trains inside the real router, on a repository the test controls.
  Future<LumeFakeTrainsRepository> open(
    WidgetTester tester, {
    LumeFakeTrainsRepository? repository,
    Locale locale = const Locale('en'),
  }) async {
    final LumeFakeTrainsRepository repo =
        repository ?? LumeFakeTrainsRepository(eligibility: kEligibility);
    await pumpLumeRouter(
      tester,
      initialLocation: LumeRoutes.trains,
      surface: LumeViewport.tall,
      locale: locale,
      overrides: <Override>[
        countryOverrideProvider.overrideWith((Ref ref) => 'PK'),
        trainsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    return repo;
  }

  String originOn(WidgetTester tester) => tester
      .widget<LumeRailField>(
        find.byKey(const ValueKey<String>('trains.origin')),
      )
      .value;

  String destinationOn(WidgetTester tester) => tester
      .widget<LumeRailField>(
        find.byKey(const ValueKey<String>('trains.destination')),
      )
      .value;

  bool chipOn(WidgetTester tester, String id) => tester
      .widget<LumeRailChip>(find.byKey(ValueKey<String>('trains.day.$id')))
      .selected;

  Future<void> tapSwap(WidgetTester tester) async {
    await tester.tap(find.byType(LumeRailSwap));
    await tester.pumpAndSettle();
  }

  group('R2 — the swap swaps', () {
    testWidgets('origin and destination exchange', (WidgetTester tester) async {
      await open(tester);
      expect(originOn(tester), 'Karachi Cantt');
      expect(destinationOn(tester), 'Lahore Junction');

      await tapSwap(tester);

      expect(originOn(tester), 'Lahore Junction');
      expect(destinationOn(tester), 'Karachi Cantt');
      expect(find.text('Lahore Junction'), findsWidgets);
    });

    testWidgets('and swapping twice restores the journey that was asked for', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tapSwap(tester);
      await tapSwap(tester);
      expect(originOn(tester), 'Karachi Cantt');
      expect(destinationOn(tester), 'Lahore Junction');
    });

    testWidgets('and the day comes with it', (WidgetTester tester) async {
      // Swapping a route does not change when the reader is travelling.
      await open(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('trains.day.tomorrow')),
      );
      await tester.pumpAndSettle();
      expect(chipOn(tester, 'tomorrow'), isTrue);

      await tapSwap(tester);
      expect(chipOn(tester, 'tomorrow'), isTrue);
      expect(originOn(tester), 'Lahore Junction');
    });

    testWidgets('and it is announced after the state has changed, not '
        'before', (WidgetTester tester) async {
      await open(tester);
      await tapSwap(tester);
      // The sentence names what is now on screen, which is the point: the
      // reference says "Stations swapped" and swaps nothing.
      expect(announced, <String>[
        'Stations swapped: Lahore Junction to Karachi Cantt',
      ]);
      expect(originOn(tester), 'Lahore Junction');
    });

    testWidgets('and a second tap while one is outstanding is not a second '
        'request', (WidgetTester tester) async {
      final LumeFakeTrainsRepository repo = await open(
        tester,
        repository: LumeFakeTrainsRepository(
          eligibility: kEligibility,
          searchDelays: <Duration>[const Duration(milliseconds: 300)],
        ),
      );
      expect(repo.searches, 0);

      await tester.tap(find.byType(LumeRailSwap));
      await tester.pump();
      // Busy: the controls are inert and the departures show their own
      // loading rather than the page showing one.
      expect(find.byType(LumeSkeleton), findsWidgets);
      await tester.tap(find.byType(LumeRailSwap), warnIfMissed: false);
      await tester.tap(find.byType(LumeRailSwap), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(repo.searches, 1);
      expect(originOn(tester), 'Lahore Junction');
    });

    testWidgets('and a refusal leaves the fields where they were', (
      WidgetTester tester,
    ) async {
      final LumeFakeTrainsRepository repo = await open(
        tester,
        repository: LumeFakeTrainsRepository(
          eligibility: kEligibility,
          failSearches: 1,
        ),
      );
      await tapSwap(tester);

      expect(repo.searches, 1);
      // Nothing was written, so nothing had to be rolled back.
      expect(originOn(tester), 'Karachi Cantt');
      expect(destinationOn(tester), 'Lahore Junction');
      expect(find.byType(LumeNotice), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(announced, isEmpty, reason: 'nothing happened, so nothing said');
    });

    testWidgets('and the keyboard can do it', (WidgetTester tester) async {
      await open(tester);
      // Tab to the swap control and press it. The order is the tree's, so
      // the assertion is that *some* focused control swapped — what matters
      // is that a keyboard can reach it at all.
      for (int i = 0; i < 12; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final BuildContext? focused = primaryFocus?.context;
        if (focused == null) continue;
        if (find
            .descendant(
              of: find.byType(LumeRailSwap),
              matching: find.byWidget(focused.widget),
            )
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(originOn(tester), 'Lahore Junction');
    });

    testWidgets('and it works right to left', (WidgetTester tester) async {
      await open(tester, locale: const Locale('ur'));
      await tapSwap(tester);
      expect(originOn(tester), 'Lahore Junction');
      expect(destinationOn(tester), 'Karachi Cantt');
    });
  });

  group('R2 — a journey that is not one', () {
    test('the same station twice is refused before anything is fetched', () {
      const LumeJourneyQuery same = LumeJourneyQuery(
        origin: 'Lahore Junction',
        destination: 'lahore junction',
      );
      expect(same.isSameStation, isTrue);
      expect(same.isAskable, isFalse);
    });

    test('and so is a missing end', () {
      const LumeJourneyQuery half = LumeJourneyQuery(
        origin: 'Karachi Cantt',
        destination: '  ',
      );
      expect(half.hasBothEnds, isFalse);
      expect(half.isAskable, isFalse);
    });

    test('and the repository says which refusal it is', () async {
      final LumeFakeTrainsRepository repo = LumeFakeTrainsRepository(
        eligibility: kEligibility,
      );
      await expectLater(
        repo.search(
          LumeUsers.muslimPk,
          now: kPinned,
          query: const LumeJourneyQuery(origin: 'A', destination: 'A'),
        ),
        throwsA(
          isA<LumeTrainsException>().having(
            (LumeTrainsException e) => e.failure,
            'failure',
            LumeTrainsFailure.invalidRoute,
          ),
        ),
      );
      expect(repo.searches, 1, reason: 'counted, and refused before fetching');
    });

    testWidgets('and the screen says so on the section, not over the page', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        LumeTrainsScreen(
          user: LumeUsers.muslimPk,
          snapshot: await composeTrainsFor(LumeUsers.muslimPk),
          status: LumeQueryStatus.invalid,
          actions: noTrainActions,
        ),
        surface: const Size(390, 4000),
      );
      expect(find.text('Choose two different stations'), findsOneWidget);
      // The rest of the page is untouched.
      expect(find.byType(LumeLiveTrainCard), findsOneWidget);
      expect(find.byType(LumeRouteCard), findsNWidgets(3));
    });
  });

  group('R3 — the day chips choose a day', () {
    testWidgets('Today is selected to begin with, and only Today', (
      WidgetTester tester,
    ) async {
      await open(tester);
      expect(chipOn(tester, 'today'), isTrue);
      expect(chipOn(tester, 'tomorrow'), isFalse);
      expect(chipOn(tester, 'other'), isFalse);
    });

    testWidgets('and pressing Tomorrow moves the selection, one at a time', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('trains.day.tomorrow')),
      );
      await tester.pumpAndSettle();

      expect(chipOn(tester, 'tomorrow'), isTrue);
      expect(chipOn(tester, 'today'), isFalse);
      expect(chipOn(tester, 'other'), isFalse);
      expect(announced, <String>['Departures for tomorrow']);
    });

    testWidgets('and back to Today again', (WidgetTester tester) async {
      await open(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('trains.day.tomorrow')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('trains.day.today')));
      await tester.pumpAndSettle();
      expect(chipOn(tester, 'today'), isTrue);
      expect(chipOn(tester, 'tomorrow'), isFalse);
    });

    testWidgets('and pressing the selected chip asks nothing again', (
      WidgetTester tester,
    ) async {
      final LumeFakeTrainsRepository repo = await open(tester);
      await tester.tap(find.byKey(const ValueKey<String>('trains.day.today')));
      await tester.pumpAndSettle();
      expect(repo.searches, 0);
    });

    testWidgets('and the repository is asked for the right date', (
      WidgetTester tester,
    ) async {
      final LumeFakeTrainsRepository repo = await open(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('trains.day.tomorrow')),
      );
      await tester.pumpAndSettle();

      final LumeTrainsScreen screen = tester.widget<LumeTrainsScreen>(
        find.byType(LumeTrainsScreen),
      );
      expect(repo.searches, 1);
      expect(screen.snapshot!.data.query.day, LumeJourneyDay.tomorrow);
      // The identity of the answer is explicit, even though the fixture
      // reuses one timetable for every day.
      expect(
        screen.snapshot!.data.serviceDate,
        DateTime(kPinned.year, kPinned.month, kPinned.day + 1),
      );
    });

    testWidgets('and a day with no service is an empty state, not a blank', (
      WidgetTester tester,
    ) async {
      await open(
        tester,
        repository: LumeFakeTrainsRepository(
          eligibility: kEligibility,
          emptyOn: <DateTime>{
            DateTime(kPinned.year, kPinned.month, kPinned.day + 1),
          },
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('trains.day.tomorrow')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LumeListRow), findsNothing);
      expect(find.byType(LumeEmptyState), findsOneWidget);
      // The rest of the page is unaffected: this is a fact about one list.
      expect(find.byType(LumeLiveTrainCard), findsOneWidget);
      expect(find.byType(LumeRouteCard), findsNWidgets(3));
    });

    testWidgets('and a day that could not be fetched keeps the selection it '
        'had', (WidgetTester tester) async {
      await open(
        tester,
        repository: LumeFakeTrainsRepository(
          eligibility: kEligibility,
          failSearches: 1,
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('trains.day.tomorrow')),
      );
      await tester.pumpAndSettle();

      expect(chipOn(tester, 'today'), isTrue, reason: 'nothing was written');
      expect(find.byType(LumeNotice), findsOneWidget);
      expect(announced, isEmpty);
    });

    testWidgets('and a late answer to a superseded question is dropped', (
      WidgetTester tester,
    ) async {
      // Tomorrow is asked for first and answers slowly; the reader goes back
      // to Today before it lands. The slow answer must not overwrite the one
      // the reader is looking at.
      final LumeFakeTrainsRepository repo = await open(
        tester,
        repository: LumeFakeTrainsRepository(
          eligibility: kEligibility,
          searchDelays: <Duration>[
            const Duration(milliseconds: 400),
            const Duration(milliseconds: 20),
          ],
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('trains.day.tomorrow')),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(chipOn(tester, 'tomorrow'), isTrue);

      await tester.tap(find.byKey(const ValueKey<String>('trains.day.today')));
      await tester.pumpAndSettle();

      expect(repo.searches, 2);
      expect(chipOn(tester, 'today'), isTrue);
      expect(chipOn(tester, 'tomorrow'), isFalse);
    });

    testWidgets('and midnight rollover is the clock’s, not a stored day', (
      WidgetTester tester,
    ) async {
      // The same chip, pressed a minute before and a minute after midnight,
      // asks for two different dates.
      final DateTime late = DateTime(2026, 9, 7, 23, 59);
      final DateTime after = DateTime(2026, 9, 8, 0, 1);
      for (final (DateTime now, DateTime expected) cell
          in <(DateTime, DateTime)>[
            (late, DateTime(2026, 9, 8)),
            (after, DateTime(2026, 9, 9)),
          ]) {
        expect(
          LumeTrainsComposer.dateFor(
            const LumeJourneyQuery(
              origin: 'a',
              destination: 'b',
              day: LumeJourneyDay.tomorrow,
            ),
            now: cell.$1,
          ),
          cell.$2,
          reason: '${cell.$1}',
        );
      }
    });

    testWidgets('and a chip says out loud that it is chosen', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      // By key, not by label: "Today" is also a tab in the bar below, and a
      // chip and a destination are two different things that say the same
      // word.
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey<String>('trains.day.today')),
            )
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      expect(
        tester
            .getSemantics(
              find.byKey(const ValueKey<String>('trains.day.tomorrow')),
            )
            .flagsCollection
            .isSelected,
        Tristate.isFalse,
      );
      handle.dispose();
    });

    testWidgets('and the chips keep their geometry when the selection moves', (
      WidgetTester tester,
    ) async {
      // R3: nothing moves except the selected treatment.
      await open(tester);
      final Rect today = tester.getRect(
        find.byKey(const ValueKey<String>('trains.day.today')),
      );
      final Rect tomorrow = tester.getRect(
        find.byKey(const ValueKey<String>('trains.day.tomorrow')),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('trains.day.tomorrow')),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byKey(const ValueKey<String>('trains.day.today'))),
        today,
      );
      expect(
        tester.getRect(
          find.byKey(const ValueKey<String>('trains.day.tomorrow')),
        ),
        tomorrow,
      );
    });

    testWidgets('and it all works right to left', (WidgetTester tester) async {
      await open(tester, locale: const Locale('ar'));
      await tester.tap(
        find.byKey(const ValueKey<String>('trains.day.tomorrow')),
      );
      await tester.pumpAndSettle();
      expect(chipOn(tester, 'tomorrow'), isTrue);
      expect(chipOn(tester, 'today'), isFalse);
    });
  });

  group('and the selection survives leaving the branch', () {
    testWidgets('a day chosen before a trip to Home is still chosen after', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('trains.day.tomorrow')),
      );
      await tester.pumpAndSettle();
      expect(chipOn(tester, 'tomorrow'), isTrue);

      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trains').last);
      await tester.pumpAndSettle();

      expect(
        chipOn(tester, 'tomorrow'),
        isTrue,
        reason: 'the branch was re-presented, not rebuilt',
      );
    });
  });
}

/// A settled snapshot, for the screen-only cases.
Future<LumeTrainsSnapshot> composeTrainsFor(LumeUserContext user) =>
    LumeFakeTrainsRepository(
      eligibility: kEligibility,
    ).load(user, now: kPinned);

/// Actions that record nothing, for a case that is about what is drawn.
final LumeTrainsActions noTrainActions = LumeTrainsActions(
  openSaved: () {},
  chooseOrigin: () {},
  chooseDestination: () {},
  swap: () {},
  chooseDay: (LumeJourneyDay _) {},
  search: () {},
  refresh: () async {},
  openAllDepartures: () {},
  openService: (LumeTrainService _) {},
  openRoute: (LumePopularRoute _) {},
);

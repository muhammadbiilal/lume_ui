/// Saved journeys: the control, and the contract behind it.
///
/// The reference's header bookmark reports the intention and does nothing
/// else — there is no saved-journeys screen in the prototype, and F5C builds
/// none. So there are two separate things to hold: the control must say what
/// would happen **without** quietly doing half of it, and the store it will
/// eventually write to must already behave, because a contract nothing calls
/// yet is exactly the kind that turns out wrong the day something does.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/features/trains/data/trains_fixtures.dart';
import 'package:lume/features/trains/domain/trains_model.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import 'destination_harness.dart';
import 'today_explore_harness.dart';

const LumeJourneyQuery kKhiLhe = LumeJourneyQuery(
  origin: 'Karachi Cantt',
  destination: 'Lahore Junction',
);

const LumeJourneyQuery kLheKhi = LumeJourneyQuery(
  origin: 'Lahore Junction',
  destination: 'Karachi Cantt',
);

void main() {
  setUpAll(loadLumeFonts);

  group('the control', () {
    Future<LumeMemoryJourneyStore> open(WidgetTester tester) async {
      final LumeMemoryJourneyStore store = LumeMemoryJourneyStore();
      await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.trains,
        surface: LumeViewport.tall,
        overrides: <Override>[
          countryOverrideProvider.overrideWith((Ref ref) => 'PK'),
          trainsRepositoryProvider.overrideWithValue(
            LumeFakeTrainsRepository(eligibility: kEligibility),
          ),
          journeyStoreProvider.overrideWithValue(store),
        ],
      );
      return store;
    }

    testWidgets('says what it is, to a screen reader as well as a glance', (
      WidgetTester tester,
    ) async {
      await open(tester);
      // A bookmark glyph on its own is not a label.
      expect(find.bySemanticsLabel('Saved journeys'), findsOneWidget);
    });

    testWidgets('reports the intention, and does not act on it', (
      WidgetTester tester,
    ) async {
      final LumeMemoryJourneyStore store = await open(tester);
      expect(find.byType(LumeToast), findsNothing);

      await tester.tap(find.bySemanticsLabel('Saved journeys'));
      await tester.pump();

      // Saying what would happen is the reference's behaviour. Saving the
      // journey quietly, or opening a screen that does not exist, would not
      // be — and either would be a claim this build cannot keep.
      expect(find.byType(LumeToast), findsOneWidget);
      expect(await store.saved(), isEmpty);
    });

    testWidgets('and does not leave the destination', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.tap(find.bySemanticsLabel('Saved journeys'));
      await tester.pumpAndSettle();
      expect(find.text('Trains'), findsWidgets);
    });
  });

  group('the store it will write to', () {
    test('keeps a journey, newest first', () async {
      final LumeMemoryJourneyStore store = LumeMemoryJourneyStore();
      expect(await store.saved(), isEmpty);

      await store.save(kKhiLhe, now: kPinned);
      final List<LumeSavedJourney> two = await store.save(
        kLheKhi,
        now: kPinned.add(const Duration(minutes: 1)),
      );

      expect(two, hasLength(2));
      expect(two.first.query, kLheKhi);
      expect(two.last.query, kKhiLhe);
    });

    test('and keeping the same one twice keeps it once', () async {
      final LumeMemoryJourneyStore store = LumeMemoryJourneyStore();
      await store.save(kKhiLhe, now: kPinned);
      await store.save(kLheKhi, now: kPinned.add(const Duration(minutes: 1)));
      final List<LumeSavedJourney> again = await store.save(
        kKhiLhe,
        now: kPinned.add(const Duration(minutes: 2)),
      );

      // Saving a journey already kept moves it to the front rather than
      // making a second copy of it: a list with the same trip twice is a
      // list nobody asked for.
      expect(again, hasLength(2));
      expect(again.first.query, kKhiLhe);
      expect(again.first.savedAt, kPinned.add(const Duration(minutes: 2)));
    });

    test('a journey the other way round is a different journey', () async {
      final LumeMemoryJourneyStore store = LumeMemoryJourneyStore();
      await store.save(kKhiLhe, now: kPinned);
      final List<LumeSavedJourney> both = await store.save(
        kLheKhi,
        now: kPinned,
      );
      expect(both, hasLength(2));
    });

    test('and so is the same pair on another day', () async {
      final LumeMemoryJourneyStore store = LumeMemoryJourneyStore();
      await store.save(kKhiLhe, now: kPinned);
      final List<LumeSavedJourney> both = await store.save(
        const LumeJourneyQuery(
          origin: 'Karachi Cantt',
          destination: 'Lahore Junction',
          day: LumeJourneyDay.tomorrow,
        ),
        now: kPinned,
      );
      expect(both, hasLength(2));
    });

    test('removing takes one, by its own id', () async {
      final LumeMemoryJourneyStore store = LumeMemoryJourneyStore();
      await store.save(kKhiLhe, now: kPinned);
      final List<LumeSavedJourney> two = await store.save(
        kLheKhi,
        now: kPinned,
      );

      final List<LumeSavedJourney> left = await store.remove(two.first.id);
      expect(left, hasLength(1));
      expect(left.single.query, kKhiLhe);

      // An id that is not there removes nothing rather than the first thing.
      expect(await store.remove('journey-not-here'), hasLength(1));
    });

    test('the list handed out cannot be edited from outside', () async {
      final LumeMemoryJourneyStore store = LumeMemoryJourneyStore();
      await store.save(kKhiLhe, now: kPinned);
      final List<LumeSavedJourney> kept = await store.saved();
      expect(() => kept.clear(), throwsUnsupportedError);
    });

    test('and it says out loud that it will not survive the process', () async {
      final LumeMemoryJourneyStore store = LumeMemoryJourneyStore();
      expect(store.isDurable, isFalse);
      await store.save(kKhiLhe, now: kPinned);
      // A second store is a second process: nothing carried over, and the
      // contract never pretended it would.
      expect(await LumeMemoryJourneyStore().saved(), isEmpty);
    });
  });
}

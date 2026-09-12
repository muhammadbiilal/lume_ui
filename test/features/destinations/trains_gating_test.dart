/// Trains is country-gated at every door, not only at the tab bar.
///
/// §64: hiding the entry point is not enough. Trains is the one *destination*
/// that a market can be without, so every surface that could reach it is
/// asked, and each one asks the same `LumeEligibility` — the bar, a deep link,
/// search, recents, Home, Explore, and a route restored from the last session.
///
/// The reference's own comment says why this lives outside the screen:
/// *"Nothing here asks which country it is in: whether this destination is in
/// the tab set at all is the router's question, answered from the profile."*
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/core/navigation/lume_destination.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/trains/domain/trains_model.dart';
import 'package:lume/features/trains/data/trains_fixtures.dart';
import 'package:lume/features/trains/domain/trains_repository.dart';
import 'package:lume/features/trains/presentation/trains_screen.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import 'destination_harness.dart';
import 'today_explore_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  /// The markets the captures cover, and whether each has rail.
  const Map<String, bool> markets = <String, bool>{
    'PK': true,
    'GB': false,
    'US': false,
  };

  group('one gate, asked everywhere', () {
    test('the selector is the only thing that decides', () {
      markets.forEach((String country, bool hasRail) {
        final LumeUserContext user = LumeUsers.muslimPk.copyWith(
          country: country,
        );
        expect(
          kEligibility.visibleById('trains', user) != null,
          hasRail,
          reason: country,
        );
      });
    });

    test('and the tab bar presents the destination on the same answer', () {
      expect(
        LumeDestinations.orderFor('PK').contains(LumeDestinationId.trains),
        isTrue,
      );
      for (final String country in <String>['GB', 'US']) {
        expect(
          LumeDestinations.orderFor(country).contains(LumeDestinationId.trains),
          isFalse,
          reason: country,
        );
      }
    });
  });

  group('the bar', () {
    testWidgets('carries Trains in Pakistan and not in the United Kingdom', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(
        tester,
        surface: LumeViewport.tall,
        overrides: <Override>[
          countryOverrideProvider.overrideWith((Ref ref) => 'PK'),
        ],
      );
      expect(find.text('Trains'), findsWidgets);

      await pumpLumeRouter(
        tester,
        surface: LumeViewport.tall,
        overrides: <Override>[
          countryOverrideProvider.overrideWith((Ref ref) => 'GB'),
        ],
      );
      expect(find.text('Trains'), findsNothing);
    });
  });

  group('a deep link', () {
    testWidgets('opens Trains where the market has rail', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.trains,
        surface: LumeViewport.tall,
        overrides: <Override>[
          countryOverrideProvider.overrideWith((Ref ref) => 'PK'),
        ],
      );
      expect(locationOf(router), LumeRoutes.trains);
      expect(find.byType(LumeTrainsScreen), findsOneWidget);
      expect(find.text('You are tracking'), findsOneWidget);
    });

    testWidgets('and refuses it where the market does not', (
      WidgetTester tester,
    ) async {
      // The branch still exists — six branches for five tabs is the shell's
      // own arrangement — so the refusal is the screen's, from the same
      // selector, rather than a missing route.
      await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.trains,
        surface: LumeViewport.tall,
        overrides: <Override>[
          countryOverrideProvider.overrideWith((Ref ref) => 'GB'),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.byType(LumeNotice), findsOneWidget);
      expect(find.text('Trains are not in your setup'), findsOneWidget);
      // Nothing about the service leaks through the refusal.
      expect(find.text('You are tracking'), findsNothing);
      expect(find.text('Green Line Express'), findsNothing);
      expect(find.text('Karachi Cantt'), findsNothing);
    });

    testWidgets('and the tool behind it is refused too', (
      WidgetTester tester,
    ) async {
      // A destination and a tool share one id and one gate. Letting the tool
      // through would be the same feature reachable by a second door.
      await pumpLumeRouter(
        tester,
        initialLocation: '/home/tool/trains',
        surface: LumeViewport.tall,
        overrides: <Override>[
          countryOverrideProvider.overrideWith((Ref ref) => 'GB'),
        ],
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<LumeToolFrame>(find.byType(LumeToolFrame)).eligible,
        isFalse,
      );
      expect(find.text('Not part of your setup'), findsWidgets);
      expect(find.text('Green Line Express'), findsNothing);
    });
  });

  group('the repository', () {
    test('refuses a market without rail rather than returning an empty '
        'roster', () async {
      // An empty list would draw an empty state, which says "there is nothing
      // today". There is no service at all, which is a different sentence.
      final LumeFakeTrainsRepository repo = LumeFakeTrainsRepository(
        eligibility: kEligibility,
      );
      await expectLater(
        repo.load(LumeUsers.muslimGb, now: kPinned),
        throwsA(
          isA<LumeTrainsException>().having(
            (LumeTrainsException e) => e.failure,
            'failure',
            LumeTrainsFailure.unsupported,
          ),
        ),
      );
    });

    test('and a search is refused on the same terms', () async {
      final LumeFakeTrainsRepository repo = LumeFakeTrainsRepository(
        eligibility: kEligibility,
      );
      await expectLater(
        repo.search(
          LumeUsers.defaultUs,
          now: kPinned,
          query: const LumeJourneyQuery(
            origin: 'Nowhere',
            destination: 'Nowhere else',
          ),
        ),
        throwsA(isA<LumeTrainsException>()),
      );
    });
  });

  group('every other surface', () {
    testWidgets('search does not turn up rail outside its market', (
      WidgetTester tester,
    ) async {
      // The hub's search reads the same visible catalogue the tiles do.
      await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.tools,
        surface: LumeViewport.tall,
        overrides: <Override>[
          countryOverrideProvider.overrideWith((Ref ref) => 'GB'),
        ],
      );
      await tester.enterText(find.byType(TextField), 'train');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('tools.tile.trains')),
        findsNothing,
      );
    });

    testWidgets('and the hub does not list it', (WidgetTester tester) async {
      await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.tools,
        surface: LumeViewport.tall,
        overrides: <Override>[
          countryOverrideProvider.overrideWith((Ref ref) => 'US'),
        ],
      );
      expect(
        find.byKey(const ValueKey<String>('tools.tile.trains')),
        findsNothing,
      );
    });

    test('and recents cannot carry it out of its market', () {
      // `recentFeatures` filters on the way *out*, so a journey taken in
      // Pakistan cannot resurface after a move to London.
      final LumeUserContext gb = LumeUsers.muslimPk.copyWith(
        country: 'GB',
        recents: <String>['trains', 'calculator'],
      );
      expect(
        kEligibility.recentFeatures(gb).map((LumeFeature f) => f.id),
        <String>['calculator'],
      );
    });
  });
}

/// Every account route, through the real router.
///
/// The manifest test proves the twenty-one exist. This proves each one is a
/// place: it resolves, it renders, it names itself, Back returns where it came
/// from, and the seven that need an account cannot be walked into without one.
///
/// Driven through `buildLumeRouter` rather than by pumping the host directly,
/// because the things most likely to be wrong are the ones only the router
/// has: the path parameter, the redirect, the gate and the back stack.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/features/account/data/fake_account_repository.dart';
import 'package:lume/features/account/domain/account_model.dart';
import 'package:lume/features/account/presentation/account_host.dart';
import 'package:lume/features/account/presentation/profile_screen.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/capture.dart';
import '../../helpers/lume_harness.dart';
import 'account_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  /// Tall, so a route's whole body is laid out and "it rendered" means all of
  /// it rather than the part above the fold.
  const Size tall = Size(390, 3000);

  group('every route is a place', () {
    for (final LumeAccountRoute route in LumeAccountRoute.values) {
      testWidgets('${route.segment} resolves and renders', (
        WidgetTester tester,
      ) async {
        final GoRouter router = await pumpAccountRouter(
          tester,
          route: route,
          surface: tall,
        );

        expect(
          locationOf(router),
          LumeRoutes.accountRoute(LumeRoutes.profile, route.segment),
        );
        // It is the host, and the host has a header with a real title on it.
        expect(find.byType(LumeAccountHost), findsOneWidget);
        expect(find.byKey(LumeAccountHost.headerKey), findsOneWidget);
        expect(find.byKey(LumeAccountHost.bodyKey), findsOneWidget);

        final LumeToolbar bar = tester.widget<LumeToolbar>(
          find.byType(LumeToolbar),
        );
        expect(bar.title.trim(), isNotEmpty, reason: route.segment);
        // A title that is a key, a placeholder or the enum's own name is a
        // route that was never written.
        expect(bar.title, isNot(route.segment), reason: route.segment);
        expect(bar.title, isNot(contains('acct.')), reason: route.segment);

        expect(find.text('We can’t find that'), findsNothing);
        expect(tester.takeException(), isNull);
        expectNoOverflow(tester);
      });
    }

    testWidgets('and a segment nobody defined is refused', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(
        tester,
        initialLocation: '/profile/account/administrator',
        signedIn: true,
        surface: tall,
      );
      // The same refusal an unknown tool gets: "there is no such thing" and
      // "you may not have this" must not be distinguishable.
      expect(find.byType(LumeAccountHost), findsNothing);
      expect(find.text('We can’t find that'), findsNothing);
    });
  });

  group('the way in and the way back', () {
    testWidgets('the bare path lands on preferences', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.account(LumeRoutes.profile),
        signedIn: true,
        surface: tall,
      );
      expect(
        locationOf(router),
        LumeRoutes.accountRoute(LumeRoutes.profile, 'prefs'),
      );
    });

    testWidgets('a row on Profile opens its route, and Back returns', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.profile,
        signedIn: true,
        surface: tall,
      );
      expect(find.byType(LumeProfileScreen), findsOneWidget);

      await tester.tap(find.text('Help'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(
        locationOf(router),
        LumeRoutes.accountRoute(LumeRoutes.profile, 'help'),
      );

      // Back, through the host's own control.
      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();
      expect(locationOf(router), LumeRoutes.profile);
      expect(find.byType(LumeProfileScreen), findsOneWidget);
    });

    testWidgets('a route opened from a route returns to that route', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpAccountRouter(
        tester,
        route: LumeAccountRoute.prefs,
        surface: tall,
      );

      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();
      expect(
        locationOf(router),
        LumeRoutes.accountRoute(LumeRoutes.profile, 'appearance'),
      );

      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();
      // Back to Preferences, not out of the section: a route inside the
      // account stacks on the one it was opened from.
      expect(
        locationOf(router),
        LumeRoutes.accountRoute(LumeRoutes.profile, 'prefs'),
      );
    });

    testWidgets('a deep link into a leaf still has a way out', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpAccountRouter(
        tester,
        route: LumeAccountRoute.about,
        surface: tall,
      );
      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();
      // Nothing to pop, so Back goes to the branch the route rides — not to a
      // blank screen and not out of the app.
      expect(locationOf(router), LumeRoutes.profile);
    });

    testWidgets('the account rides whichever branch it was opened from', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.accountRoute(LumeRoutes.home, 'help'),
        signedIn: true,
        surface: tall,
      );
      expect(find.byType(LumeAccountHost), findsOneWidget);
      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();
      expect(locationOf(router), LumeRoutes.home);
    });
  });

  group('the seven that need an account', () {
    for (final LumeAccountRoute route in LumeAccountRoute.values.where(
      (LumeAccountRoute r) =>
          LumeFakeAccountRepository.guest().requiresAccount(r),
    )) {
      testWidgets('${route.segment} sends a guest to sign in', (
        WidgetTester tester,
      ) async {
        final GoRouter router = await pumpLumeRouter(
          tester,
          initialLocation: LumeRoutes.accountRoute(
            LumeRoutes.profile,
            route.segment,
          ),
          surface: tall,
        );
        // The gate, not the screen: a guest never reaches the host at all.
        expect(locationOf(router), '/auth/signin');
        expect(find.byType(LumeAccountHost), findsNothing);
      });
    }

    testWidgets('and a session that runs out while one is open is told', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.accountRoute(
          LumeRoutes.profile,
          'security',
        ),
        auth: expiredAuth(),
        surface: tall,
      );
      // An expiry is a thing to be told about, not a quiet downgrade to
      // guest — and not a sign-in form with no explanation.
      expect(locationOf(router), '/auth/expired');
    });

    testWidgets('a guest reaching one anyway sees one refusal, with a way on', (
      WidgetTester tester,
    ) async {
      // The host's own gate, in front of the router's: this is what a session
      // that expires *while the screen is open* runs into.
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sessions,
        account: LumeFakeAccountRepository.guest(),
        surface: tall,
      );
      expect(find.textContaining('You’re signed out'), findsOneWidget);
      expect(find.text('Sign in'), findsWidgets);
      // And nothing of the protected screen leaks through it.
      expect(find.text('This device'), findsNothing);
    });
  });

  group('the fourteen that do not', () {
    for (final LumeAccountRoute route in LumeAccountRoute.values.where(
      (LumeAccountRoute r) =>
          !LumeFakeAccountRepository.guest().requiresAccount(r),
    )) {
      testWidgets('${route.segment} opens for a guest', (
        WidgetTester tester,
      ) async {
        final GoRouter router = await pumpLumeRouter(
          tester,
          initialLocation: LumeRoutes.accountRoute(
            LumeRoutes.profile,
            route.segment,
          ),
          surface: tall,
        );
        expect(
          locationOf(router),
          LumeRoutes.accountRoute(LumeRoutes.profile, route.segment),
          reason: route.segment,
        );
        expect(find.byType(LumeAccountHost), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('right to left', () {
    testWidgets('changes the direction and nothing about the route', (
      WidgetTester tester,
    ) async {
      for (final LumeAccountRoute route in <LumeAccountRoute>[
        LumeAccountRoute.prefs,
        LumeAccountRoute.language,
        LumeAccountRoute.privacy,
        LumeAccountRoute.about,
      ]) {
        final GoRouter router = await pumpAccountRouter(
          tester,
          route: route,
          locale: const Locale('ur'),
          surface: tall,
        );
        expect(
          locationOf(router),
          LumeRoutes.accountRoute(LumeRoutes.profile, route.segment),
          reason: route.segment,
        );
        expect(find.byType(LumeAccountHost), findsOneWidget);
        expect(tester.takeException(), isNull, reason: route.segment);
        expectNoOverflow(tester);
      }
    });
  });
}

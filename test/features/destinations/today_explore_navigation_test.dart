/// Today and Explore inside the real router.
///
/// The screens are tested against fixtures elsewhere; this is for what only a
/// navigator can answer — that a direct link lands on the right branch, that a
/// tool opened from Today comes back to Today, that Week and Add keep Today as
/// their origin, that changing market re-presents the bar without rebuilding a
/// branch, and that a branch keeps its scroll.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/core/navigation/lume_destination.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_agenda.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/features/explore/presentation/explore_screen.dart';
import 'package:lume/features/auth/domain/auth_model.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/startup/domain/startup_state.dart';
import 'package:lume/features/today/presentation/today_screen.dart';

import '../../helpers/lume_harness.dart';

void main() {
  group('the two destinations are reachable', () {
    testWidgets('/today is the product, not a fixture', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.today,
        surface: LumeViewport.tall,
      );
      expect(find.byType(LumeTodayScreen), findsOneWidget);
      expect(find.text('Your day'), findsOneWidget);
      expect(
        LumeRoutes.destinationAt(locationOf(router)),
        LumeDestinationId.today,
      );
    });

    testWidgets('/explore is too', (WidgetTester tester) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.explore,
        surface: LumeViewport.tall,
      );
      expect(find.byType(LumeExploreScreen), findsOneWidget);
      expect(find.text('Around you'), findsOneWidget);
      expect(
        LumeRoutes.destinationAt(locationOf(router)),
        LumeDestinationId.explore,
      );
    });

    testWidgets('and Explore opens in Pakistan, where it is not a tab', (
      WidgetTester tester,
    ) async {
      // §46: "Explore can still be reached through contextual links when it is
      // not a primary tab." Not being in the bar must not mean not existing.
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.explore,
        surface: LumeViewport.tall,
        overrides: <Override>[
          countryOverrideProvider.overrideWith((Ref ref) => 'PK'),
        ],
      );
      expect(find.byType(LumeExploreScreen), findsOneWidget);
      expect(find.text('Trains'), findsWidgets);

      // And it carries its own way back, because no tab is selected to
      // return to.
      await tester.tap(find.bySemanticsLabel('Back to home'));
      await tester.pumpAndSettle();
      expect(locationOf(router), LumeRoutes.home);
    });

    testWidgets('and carries no way back where it is a tab', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.explore,
        surface: LumeViewport.tall,
        overrides: <Override>[
          countryOverrideProvider.overrideWith((Ref ref) => 'GB'),
        ],
      );
      expect(find.bySemanticsLabel('Back to home'), findsNothing);
    });

    testWidgets('and the bar puts them where the market says', (
      WidgetTester tester,
    ) async {
      // Pakistan: Home · Tools · Trains · Today · Profile. Everywhere else:
      // Home · Tools · Today · Explore · Profile. The branch order never
      // changes; only what is presented does.
      expect(LumeDestinations.orderFor('PK'), <LumeDestinationId>[
        LumeDestinationId.home,
        LumeDestinationId.tools,
        LumeDestinationId.trains,
        LumeDestinationId.today,
        LumeDestinationId.profile,
      ]);
      expect(LumeDestinations.orderFor('GB'), <LumeDestinationId>[
        LumeDestinationId.home,
        LumeDestinationId.tools,
        LumeDestinationId.today,
        LumeDestinationId.explore,
        LumeDestinationId.profile,
      ]);
    });
  });

  group('a tool opened from Today', () {
    testWidgets('opens on the Today branch, so Back is Today', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.today,
        surface: LumeViewport.tall,
      );

      // An agenda row that goes somewhere. The two meetings have no target —
      // a calendar entry is not a tool — and the launch profile has not asked
      // for the Islamic experience, so there are no prayer rows to tap either.
      // The errand is the row every reader has.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('today.agenda.groceries')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('today.agenda.groceries')),
      );
      await tester.pumpAndSettle();

      expect(locationOf(router), '/today/tool/shopping');
      expect(LumeRoutes.branchOf(locationOf(router)), LumeRoutes.today);
      // A tool selects no destination, so the pill hides rather than
      // pretending the reader is still on Today.
      expect(LumeRoutes.destinationAt(locationOf(router)), isNull);
    });

    testWidgets('and from Explore, Back is Explore', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.explore,
        surface: LumeViewport.tall,
      );

      await tester.tap(find.text('Fuel Prices'));
      await tester.pumpAndSettle();

      expect(LumeRoutes.branchOf(locationOf(router)), LumeRoutes.explore);
    });

    testWidgets('and the search on Explore rides the same branch', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.explore,
        surface: LumeViewport.tall,
      );
      await tester.tap(find.bySemanticsLabel('Search everything').first);
      await tester.pumpAndSettle();
      expect(locationOf(router), LumeRoutes.search(LumeRoutes.explore));
    });
  });

  group('Week and Add keep Today as their origin', () {
    testWidgets('neither navigates anywhere, and both say so', (
      WidgetTester tester,
    ) async {
      // There is no Week screen and no Add-task screen — in the reference or
      // in F5B. Sending the reader to a route that does not exist would be
      // worse than saying nothing happened, so both toast and the location
      // does not move.
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.today,
        surface: LumeViewport.tall,
      );

      await tester.tap(find.text('Week'));
      await tester.pump();
      expect(find.byType(LumeToast), findsOneWidget);
      expect(locationOf(router), LumeRoutes.today);

      await tester.tap(find.bySemanticsLabel('Add').first);
      await tester.pump();
      expect(locationOf(router), LumeRoutes.today);
      expect(
        LumeRoutes.destinationAt(locationOf(router)),
        LumeDestinationId.today,
      );
    });

    testWidgets('and the private door does not open onto a record', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.today,
        surface: LumeViewport.tall,
      );
      await tester.scrollUntilVisible(
        find.byType(LumePrivateCard),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(LumePrivateCard));
      await tester.pump();
      expect(locationOf(router), LumeRoutes.today);
      expect(find.byType(LumeToast), findsOneWidget);
    });
  });

  group('ticking a task', () {
    testWidgets('reports the change and stays on the page', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.today,
        surface: LumeViewport.tall,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('today.task.email')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey<String>('today.task.email')));
      await tester.pumpAndSettle();
      expect(locationOf(router), LumeRoutes.today);
      expect(find.byType(LumeToast), findsOneWidget);
    });
  });

  group('changing market', () {
    testWidgets('reloads Today rather than keeping the old city', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.today,
        surface: LumeViewport.tall,
        overrides: <Override>[
          countryOverrideProvider.overrideWith((Ref ref) => 'GB'),
        ],
      );
      // London's timetable, not Islamabad's, and the outage is Pakistan's
      // alone so it is not on the page at all.
      expect(find.byType(LumeAgendaRow), findsWidgets);
      expect(find.text('Loadshedding'), findsNothing);
    });

    testWidgets('and Explore loses the services the market does not have', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.explore,
        surface: LumeViewport.tall,
        overrides: <Override>[
          countryOverrideProvider.overrideWith((Ref ref) => 'GB'),
        ],
      );
      // Loadshedding and Trains are Pakistan's alone and are gone. Fuel is a
      // global service with a local reading, so it stays — and reads in
      // pounds, not rupees. §20: visibility and localisation are different
      // questions.
      expect(find.text('Loadshedding'), findsNothing);
      expect(find.text('Trains'), findsNothing);
      expect(find.text('£1.34'), findsOneWidget);
      expect(find.textContaining('Rs '), findsNothing);
    });
  });

  group('a branch keeps where it was', () {
    testWidgets('Today is where it was left when the reader comes back', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.today,
        surface: LumeViewport.phone,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      final double left = _offset(tester);
      expect(left, greaterThan(0));

      router.go(LumeRoutes.home);
      await tester.pumpAndSettle();
      router.go(LumeRoutes.today);
      await tester.pumpAndSettle();

      expect(_offset(tester), moreOrLessEquals(left, epsilon: 0.5));
    });

    testWidgets('and so is Explore after a tool', (WidgetTester tester) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.explore,
        surface: LumeViewport.phone,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      final double left = _offset(tester);
      expect(left, greaterThan(0));

      router.go(LumeRoutes.tool(LumeRoutes.explore, 'weather'));
      await tester.pumpAndSettle();
      router.go(LumeRoutes.explore);
      await tester.pumpAndSettle();

      expect(_offset(tester), moreOrLessEquals(left, epsilon: 0.5));
    });
  });

  group('the guards apply to these two as well', () {
    // The rules themselves are a table in `startup_gate_test.dart`. What is
    // asserted here is only that the two new locations are inside it — §64:
    // hiding the entry point is not enough, a link straight to a destination
    // has to meet the same gate the bar does.
    for (final String where in <String>[LumeRoutes.today, LumeRoutes.explore]) {
      test('$where waits for the launch to decide', () {
        expect(
          LumeRouteGate.redirect(
            state: const LumeStartupState(),
            location: where,
          ),
          LumeRouteGate.splash,
        );
      });

      test('$where waits for onboarding', () {
        expect(
          LumeRouteGate.redirect(
            state: const LumeStartupState(
              phase: LumeStartupPhase.ready,
              auth: LumeAuthStatus.guest(),
              profile: LumeProfileRecord(onboarded: false),
              profileIsDurable: true,
            ),
            location: where,
          ),
          LumeRoutes.onboarding,
        );
      });
    }
  });
}

/// How far down the destination currently is.
///
/// Read off the position rather than a controller: the page hands its
/// `CustomScrollView` a `PageStorageKey` and lets the framework own the
/// controller, which is exactly what makes the offset survive the branch being
/// re-presented.
double _offset(WidgetTester tester) => tester
    .state<ScrollableState>(find.byType(Scrollable).first)
    .position
    .pixels;

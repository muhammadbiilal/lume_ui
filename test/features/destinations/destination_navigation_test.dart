/// Home and the Tools hub inside the real router.
///
/// The screens themselves are tested against fixtures; this is about the
/// things only a navigator can answer — that a tool opened from Home comes
/// back to Home, that the same tool opened from the hub comes back to the hub,
/// that a tool selects no destination, and that changing country re-presents
/// the bar without disturbing a branch.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/core/navigation/lume_destination.dart';
import 'package:lume/core/navigation/lume_navigation_surfaces.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/home/presentation/home_screen.dart';
import 'package:lume/features/tools/presentation/tools_screen.dart';

import '../../helpers/lume_harness.dart';

void main() {
  group('Home is the Home branch', () {
    testWidgets('/home is the product, not a fixture', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(tester, surface: LumeViewport.tall);
      expect(find.byType(LumeHomeScreen), findsOneWidget);
      expect(find.text('Quick tools'), findsOneWidget);
    });

    testWidgets('/tools is the hub', (WidgetTester tester) async {
      await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.tools,
        surface: LumeViewport.tall,
      );
      expect(find.byType(LumeToolsScreen), findsOneWidget);
      expect(find.text('68 utilities, neatly sorted'), findsOneWidget);
    });

    testWidgets('a direct link opens the right branch', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.tools,
        surface: LumeViewport.tall,
      );
      expect(locationOf(router), LumeRoutes.tools);
      expect(
        LumeRoutes.destinationAt(locationOf(router)),
        LumeDestinationId.tools,
      );
    });
  });

  group('a tool remembers where it was opened from', () {
    testWidgets('from Home, Back is Home', (WidgetTester tester) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        surface: LumeViewport.tall,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('home.tool.calculator')),
      );
      await tester.pumpAndSettle();
      expect(locationOf(router), '/home/tool/calculator');

      // The path itself carries the branch, so nothing has to be remembered.
      expect(LumeRoutes.branchOf(locationOf(router)), LumeRoutes.home);
    });

    testWidgets('from the hub, Back is the hub', (WidgetTester tester) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.tools,
        surface: LumeViewport.tall,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('tools.tile.calculator')),
      );
      await tester.pumpAndSettle();
      expect(locationOf(router), '/tools/tool/calculator');
      expect(LumeRoutes.branchOf(locationOf(router)), LumeRoutes.tools);
    });

    testWidgets('and a tool selects no destination at all', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        surface: LumeViewport.tall,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('home.tool.calculator')),
      );
      await tester.pumpAndSettle();

      // `router.js` syncs the selection against `data-tab`, and a tool has
      // none — so the pill hides even though the tool is on Home's branch.
      expect(LumeRoutes.destinationAt(locationOf(router)), isNull);
      final LumeBottomBar bar = tester.widget<LumeBottomBar>(
        find.byType(LumeBottomBar),
      );
      expect(bar.selectedIndex, -1);
    });
  });

  group('the header goes where it says', () {
    testWidgets('search opens search on this branch', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        surface: LumeViewport.tall,
      );
      await tester.tap(find.bySemanticsLabel('Search everything'));
      await tester.pumpAndSettle();
      expect(locationOf(router), '/home/search');
    });

    testWidgets('the bell opens the notification centre on this branch', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        surface: LumeViewport.tall,
      );
      await tester.tap(find.bySemanticsLabel(RegExp('^Notifications')));
      await tester.pumpAndSettle();
      expect(locationOf(router), '/home/notifications');
    });

    testWidgets('the avatar goes to Profile, which is a destination', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        surface: LumeViewport.tall,
      );
      await tester.tap(find.bySemanticsLabel('Your profile'));
      await tester.pumpAndSettle();
      expect(locationOf(router), LumeRoutes.profile);
      expect(
        LumeRoutes.destinationAt(locationOf(router)),
        LumeDestinationId.profile,
      );
    });

    testWidgets('"All" on Quick tools goes to the hub', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        surface: LumeViewport.tall,
      );
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(locationOf(router), LumeRoutes.tools);
    });
  });

  group('opening a tool writes it to recents', () {
    testWidgets('and the hub shows it on the next arrival', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        surface: LumeViewport.tall,
      );

      // Two, because one pill is not a history.
      for (final String id in <String>['calculator', 'notes']) {
        await tester.tap(find.byKey(ValueKey<String>('home.tool.$id')));
        await tester.pumpAndSettle();
        router.go(LumeRoutes.home);
        await tester.pumpAndSettle();
      }

      router.go(LumeRoutes.tools);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>(LumeToolsScreen.recentsKey)),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('tools.recent.notes')),
        findsOneWidget,
      );
    });
  });

  group('changing market', () {
    testWidgets('re-presents the bar without rebuilding a branch', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(
        tester,
        surface: LumeViewport.tall,
        overrides: <Override>[
          countryOverrideProvider.overrideWith((Ref ref) => 'GB'),
        ],
      );
      // Trains is not a tab outside Pakistan; Explore takes the slot.
      expect(find.text('Trains'), findsNothing);
      expect(find.text('Explore'), findsWidgets);
    });

    testWidgets('and the hub loses the services that had not launched', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.tools,
        surface: LumeViewport.tall,
        overrides: <Override>[
          countryOverrideProvider.overrideWith((Ref ref) => 'GB'),
        ],
      );
      expect(
        find.byKey(const ValueKey<String>('tools.tile.loadshed')),
        findsNothing,
      );
    });
  });

  group('the three navigations agree', () {
    for (final (String name, Size size) cell in <(String, Size)>[
      ('a phone', const Size(390, 3000)),
      ('a rail', const Size(700, 3000)),
      ('a sidebar', const Size(1100, 3000)),
    ]) {
      testWidgets('Home is selected on ${cell.$1}', (
        WidgetTester tester,
      ) async {
        final GoRouter router = await pumpLumeRouter(tester, surface: cell.$2);
        expect(locationOf(router), LumeRoutes.home);
        expect(find.byType(LumeHomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}

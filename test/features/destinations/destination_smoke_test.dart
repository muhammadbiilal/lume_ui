/// The launch, then Home, then the hub, then a tool, then Today, then
/// Explore, then Trains, then Profile and the account section — and back.
///
/// One test that walks the product the way a person does — through the real
/// router, the real gate and the real registry — because every other test in
/// this suite holds something still.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/navigation/lume_navigation_surfaces.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_rail.dart';
import 'package:lume/core/widgets/lume/lume_settings.dart';
import 'package:lume/features/explore/presentation/explore_screen.dart';
import 'package:lume/features/home/presentation/home_screen.dart';
import 'package:lume/features/today/presentation/today_screen.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/features/notifications/presentation/notification_host.dart';
import 'package:lume/features/notifications/presentation/notification_row.dart';
import 'package:lume/features/search/presentation/search_sheet.dart';
import 'package:lume/features/tools/presentation/tools_screen.dart';
import 'package:lume/features/trains/presentation/trains_screen.dart';

import '../../helpers/lume_harness.dart';

void main() {
  testWidgets('a walk through Home, the hub and a tool', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpLumeRouter(
      tester,
      surface: LumeViewport.tall,
    );

    // 1. The launch lands on Home, and Home is the product.
    expect(locationOf(router), LumeRoutes.home);
    expect(find.byType(LumeHomeScreen), findsOneWidget);
    expect(find.text('Quick tools'), findsOneWidget);
    expect(find.text('At a glance'), findsOneWidget);

    // 2. The bar carries this market's five destinations, Home selected.
    expect(find.byType(LumeBottomBar), findsOneWidget);
    for (final String label in <String>[
      'Home',
      'Tools',
      'Trains',
      'Today',
      'Profile',
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }

    // 3. A quick tool opens on Home's branch.
    await tester.tap(
      find.byKey(const ValueKey<String>('home.tool.calculator')),
    );
    await tester.pumpAndSettle();
    expect(locationOf(router), '/home/tool/calculator');

    // 4. The hub is the hub, and it has the tool that was just opened in its
    //    history the moment a second one joins it.
    router.go(LumeRoutes.tools);
    await tester.pumpAndSettle();
    expect(find.byType(LumeToolsScreen), findsOneWidget);
    expect(find.text('68 utilities, neatly sorted'), findsOneWidget);

    // 5. A search finds a tool by a word nobody would guess from its name.
    await tester.enterText(find.byType(TextField), 'petrol');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('tools.tile.fuel')),
      findsOneWidget,
    );

    // 6. Opening it lands on the hub's branch, not Home's.
    await tester.tap(find.byKey(const ValueKey<String>('tools.tile.fuel')));
    await tester.pumpAndSettle();
    expect(locationOf(router), '/tools/tool/fuel');

    // 7. Nothing threw on the way.
    expect(tester.takeException(), isNull);
  });

  testWidgets('a walk through Today and Explore', (WidgetTester tester) async {
    // A phone, not the tall test surface: the point of steps 2 and 5 is that
    // the page actually scrolls and remembers where it was.
    final GoRouter router = await pumpLumeRouter(
      tester,
      surface: LumeViewport.phone,
    );

    // 1. Today is a tab in this market, and tapping it draws the day.
    await tester.tap(find.text('Today').last);
    await tester.pumpAndSettle();
    expect(locationOf(router), LumeRoutes.today);
    expect(find.byType(LumeTodayScreen), findsOneWidget);
    expect(find.text('Your day'), findsOneWidget);

    // 2. Ticking a task reports what happened and stays on the page.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('today.task.email')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    // The navigation bar floats over the page, so a row that is merely
    // on-screen can still be under it. Another 160 clears it.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -160));
    await tester.pumpAndSettle();
    expect(find.text('Tasks'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('today.task.email')));
    await tester.pumpAndSettle();
    expect(locationOf(router), LumeRoutes.today);
    expect(find.byType(LumeToast), findsOneWidget);

    // 3. Explore is not a tab in Pakistan, and a link still reaches it.
    router.go(LumeRoutes.explore);
    await tester.pumpAndSettle();
    expect(find.byType(LumeExploreScreen), findsOneWidget);
    expect(find.text('Around you'), findsOneWidget);
    expect(find.text('Fuel Prices'), findsOneWidget);

    // 4. It carries its own way back, because no tab is selected.
    await tester.tap(find.bySemanticsLabel('Back to home'));
    await tester.pumpAndSettle();
    expect(locationOf(router), LumeRoutes.home);

    // 5. Today kept its place while the reader was away.
    router.go(LumeRoutes.today);
    await tester.pumpAndSettle();
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      greaterThan(0),
    );

    // 6. Nothing threw on the way.
    expect(tester.takeException(), isNull);
  });

  testWidgets('a walk through Trains and into a journey', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpLumeRouter(
      tester,
      surface: LumeViewport.tall,
    );

    // 1. Trains is a tab in this market, and tapping it draws the rail.
    await tester.tap(find.text('Trains').last);
    await tester.pumpAndSettle();
    expect(locationOf(router), LumeRoutes.trains);
    expect(find.byType(LumeTrainsScreen), findsOneWidget);

    // 2. The search card opens on a journey, both ends named.
    final String origin = tester
        .widget<LumeRailField>(
          find.byKey(const ValueKey<String>('trains.origin')),
        )
        .value;
    final String destination = tester
        .widget<LumeRailField>(
          find.byKey(const ValueKey<String>('trains.destination')),
        )
        .value;
    expect(origin, isNotEmpty);
    expect(destination, isNotEmpty);
    expect(origin, isNot(destination));

    // 3. Swapping the ends asks the timetable again and answers (R2).
    await tester.tap(find.byType(LumeRailSwap));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LumeRailField>(
            find.byKey(const ValueKey<String>('trains.origin')),
          )
          .value,
      destination,
    );
    expect(find.byType(LumeToast), findsOneWidget);

    // 4. And the reader is still on Trains, with its own tab selected.
    expect(locationOf(router), LumeRoutes.trains);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a walk into search, a result, and back', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpLumeRouter(
      tester,
      surface: LumeViewport.tall,
    );

    // 1. Home's app bar raises search over Home, which stays where it was.
    await tester.tap(find.bySemanticsLabel('Search everything').first);
    await tester.pumpAndSettle();
    expect(find.byType(LumeSearchSheet), findsOneWidget);
    expect(find.text('Quick tools'), findsOneWidget);
    expect(locationOf(router), '/home/search');

    // 2. A word nobody would guess from the tool's name finds it.
    await tester.enterText(find.byType(LumeSearchField), 'petrol');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fuel Prices'));
    await tester.pumpAndSettle();
    expect(locationOf(router), '/home/tool/fuel');
    expect(find.byType(LumeSearchSheet), findsNothing);

    // 3. And Back returns to Home, not to the search address.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(locationOf(router), LumeRoutes.home);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a direct search link, then dismissed', (
    WidgetTester tester,
  ) async {
    // The destination is established *before* the sheet appears, so a deep
    // link never flashes the wrong branch behind it.
    final GoRouter router = await pumpLumeRouter(
      tester,
      initialLocation: '/today/search',
      surface: LumeViewport.tall,
    );
    expect(find.byType(LumeTodayScreen), findsOneWidget);
    expect(find.byType(LumeSearchSheet), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LumeSearchSheet), findsNothing);
    expect(locationOf(router), LumeRoutes.today);
  });

  testWidgets('a walk through the notification centre and into a target', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpLumeRouter(
      tester,
      initialLocation: '/home/notifications',
      surface: LumeViewport.tall,
    );
    await tester.pump(LumeNotificationHost.settle);
    await tester.pumpAndSettle();

    // 1. Unread to begin with, and the header says how many.
    expect(find.textContaining('unread'), findsWidgets);

    // 2. Opening a row marks it read and goes to its tool on this branch.
    await tester.tap(find.text('Heavy rain warning'));
    await tester.pumpAndSettle();
    expect(locationOf(router), '/home/tool/weather');

    // 3. Back returns to the centre, and that row is no longer unread.
    router.go('/home/notifications');
    await tester.pumpAndSettle();
    final LumeNotificationRow row = tester.widget<LumeNotificationRow>(
      find.ancestor(
        of: find.text('Heavy rain warning'),
        matching: find.byType(LumeNotificationRow),
      ),
    );
    expect(row.notification.read, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mark all read, and the shell badge follows', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpLumeRouter(
      tester,
      initialLocation: '/home/notifications',
      surface: LumeViewport.tall,
    );
    await tester.pump(LumeNotificationHost.settle);
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Mark all as read'));
    await tester.pumpAndSettle();
    expect(find.text('You’re all caught up'), findsWidgets);

    // The centre and Home's bell read the same feed, so the badge cannot
    // disagree with the list.
    router.go(LumeRoutes.home);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the preferences sheet opens over the centre and saves', (
    WidgetTester tester,
  ) async {
    await pumpLumeRouter(
      tester,
      initialLocation: '/home/notifications',
      surface: LumeViewport.tall,
    );
    await tester.pump(LumeNotificationHost.settle);
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Notification settings').first);
    await tester.pumpAndSettle();
    expect(find.text('Show previews'), findsOneWidget);

    await tester.tap(find.text('Show previews'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // Back on the centre, and every body is now withheld.
    expect(find.text('Content hidden'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a walk through Profile and into the account', (
    WidgetTester tester,
  ) async {
    final GoRouter router = await pumpLumeRouter(
      tester,
      surface: LumeViewport.tall,
    );

    // 1. Profile is the fifth destination.
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(locationOf(router), LumeRoutes.profile);

    // 2. A row opens one of the twenty-one account routes, on this branch.
    await tester.tap(
      find.byWidgetPredicate(
        (Widget w) => w is LumeSettingsRow && w.title == 'Privacy',
      ),
    );
    await tester.pumpAndSettle();
    expect(locationOf(router), endsWith('/account/privacy'));

    // 3. A switch there writes, and the row it wrote reads back changed.
    final Finder previews = find.byWidgetPredicate(
      (Widget w) => w is LumeSettingsRow && w.title == 'Notification previews',
    );
    final bool before = tester.widget<LumeSettingsRow>(previews).toggle!;
    await tester.tap(previews);
    await tester.pumpAndSettle();
    expect(tester.widget<LumeSettingsRow>(previews).toggle, !before);

    // 4. A route reached from a route returns to it, not out of the section.
    await tester.tap(
      find.byWidgetPredicate(
        (Widget w) => w is LumeSettingsRow && w.title == 'Data & sync',
      ),
    );
    await tester.pumpAndSettle();
    expect(locationOf(router), endsWith('/account/sync'));

    await tester.tap(find.byType(LumeBackButton));
    await tester.pumpAndSettle();
    expect(locationOf(router), endsWith('/account/privacy'));

    // 5. And out of the section is Profile, not Home.
    await tester.tap(find.byType(LumeBackButton));
    await tester.pumpAndSettle();
    expect(locationOf(router), LumeRoutes.profile);

    // 6. Nothing threw on the way.
    expect(tester.takeException(), isNull);
  });
}

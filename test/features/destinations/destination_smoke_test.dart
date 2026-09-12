/// The launch, then Home, then the hub, then a tool, then Today, then
/// Explore, then back.
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
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/features/explore/presentation/explore_screen.dart';
import 'package:lume/features/home/presentation/home_screen.dart';
import 'package:lume/features/today/presentation/today_screen.dart';
import 'package:lume/features/tools/presentation/tools_screen.dart';

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
}

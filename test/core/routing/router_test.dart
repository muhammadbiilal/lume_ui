/// The route map, and the four promises it makes.
///
/// Every route resolves. A branch keeps its stack. Back lands where the user
/// came from. Nothing that is not a tab claims to be one.
///
/// These are behaviour tests, not geometry: they drive the real router through
/// the real shell, because the interesting failures — a tab that loses its
/// scroll, a Back that goes to the wrong place, a country change that strands
/// the user — only appear *between* screens.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/core/navigation/lume_destination.dart';
import 'package:lume/core/navigation/lume_navigation_surfaces.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/shell/presentation/fixture_tool_screen.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  /// The index the bar reports as selected.
  int selectedIndex(WidgetTester tester) =>
      tester.widget<LumeBottomBar>(find.byType(LumeBottomBar)).selectedIndex;

  /// The destinations the bar is currently showing.
  List<LumeDestination> barDestinations(WidgetTester tester) =>
      tester.widget<LumeBottomBar>(find.byType(LumeBottomBar)).destinations;

  group('every route resolves', () {
    const List<String> locations = <String>[
      '/home',
      '/tools',
      '/trains',
      '/today',
      '/explore',
      '/profile',
      '/onboarding',
      '/home/notifications',
      '/today/notifications',
      '/home/search',
      '/home/unavailable',
      '/home/tool/ready',
      '/tools/tool/loading',
      '/tools/tool/failed',
      '/tools/tool/elsewhere',
      '/tools/tool/gated',
      '/home/tool/records/records',
      '/home/tool/records/records/7',
      '/home/tool/records/records/new',
      '/home/tool/records/records/7/edit',
      '/profile/gallery',
      '/profile/navigation-gallery',
    ];

    for (final String location in locations) {
      testWidgets(location, (WidgetTester tester) async {
        final GoRouter router = await pumpLumeRouter(
          tester,
          initialLocation: location,
        );
        expect(locationOf(router), location);
        expect(tester.takeException(), isNull);
        expectNoOverflow(tester);
      });
    }

    testWidgets('/auth resolves to the first screen of the flow', (
      WidgetTester tester,
    ) async {
      // `/auth` names the flow, not a screen. It resolves rather than 404s,
      // because a link to "sign in" is a thing people send each other.
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.auth,
      );
      expect(locationOf(router), '/auth/signin');
    });

    testWidgets('the account surfaces resolve for somebody signed in', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: '/profile/account',
        signedIn: true,
      );
      expect(locationOf(router), '/profile/account');
      expect(tester.takeException(), isNull);
      expectNoOverflow(tester);
    });

    testWidgets('a location nobody defined shows the not-found screen', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(tester, initialLocation: '/nowhere/at/all');
      expect(find.text('We can’t find that'), findsOneWidget);
    });

    testWidgets('a bare nested destination lands on the home branch', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: '/notifications',
      );
      expect(locationOf(router), LumeRoutes.notifications(LumeRoutes.home));
    });

    testWidgets('a bare account link lands on the profile branch', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: '/account',
        signedIn: true,
      );
      expect(locationOf(router), LumeRoutes.account(LumeRoutes.profile));
    });
  });

  group('the route vocabulary resolves', () {
    // Every builder on LumeRoutes, driven through the real router. A path
    // helper that nothing has navigated to yet is a path helper that is wrong
    // the first time somebody uses it.
    const String branch = '/today';
    const String tool = 'ready';
    const String record = '4';

    final Map<String, String> vocabulary = <String, String>{
      'notifications': LumeRoutes.notifications(branch),
      'search': LumeRoutes.search(branch),
      'account': LumeRoutes.account(branch),
      'unavailable': LumeRoutes.unavailable(branch),
      'tool': LumeRoutes.tool(branch, tool),
      'records': LumeRoutes.records(branch, tool),
      'record': LumeRoutes.record(branch, tool, record),
      'newRecord': LumeRoutes.newRecord(branch, tool),
      'editRecord': LumeRoutes.editRecord(branch, tool, record),
    };

    vocabulary.forEach((String name, String location) {
      testWidgets(name, (WidgetTester tester) async {
        final GoRouter router = await pumpLumeRouter(
          tester,
          initialLocation: location,
          // The account's own surfaces need an account; everything else in
          // Lume is open to a guest, and the gate only guards these.
          signedIn: true,
        );
        expect(locationOf(router), location);
        expect(find.text('We can’t find that'), findsNothing);
      });
    });

    test('branchOf finds the branch a nested location rides on', () {
      expect(LumeRoutes.branchOf(LumeRoutes.tool(branch, tool)), branch);
      expect(LumeRoutes.branchOf(branch), branch);
      expect(
        LumeRoutes.branchOf('/nowhere'),
        LumeRoutes.start,
        reason: 'a location on no branch falls back to the start',
      );
      expect(
        LumeRoutes.branchOf('/todayish/thing'),
        LumeRoutes.start,
        reason: 'a prefix is not a branch — /todayish is not /today',
      );
    });

    test('destinationAt answers only for a branch root', () {
      expect(LumeRoutes.destinationAt('/today'), LumeDestinationId.today);
      expect(LumeRoutes.destinationAt('/today/search'), isNull);
      expect(LumeRoutes.destinationAt('/nowhere'), isNull);
    });
  });

  group('selection follows the location', () {
    testWidgets('a branch root selects its destination', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(tester, initialLocation: '/today');
      final List<LumeDestination> ds = barDestinations(tester);
      expect(ds[selectedIndex(tester)].id, LumeDestinationId.today);
    });

    testWidgets('a tool on the Tools branch selects nothing', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(tester, initialLocation: '/tools/tool/ready');
      expect(
        selectedIndex(tester),
        -1,
        reason: 'a destination with no data-tab selects no tab (router.js)',
      );
    });

    testWidgets('the notification centre selects nothing', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(tester, initialLocation: '/home/notifications');
      expect(selectedIndex(tester), -1);
    });

    testWidgets('Explore is not a tab in Pakistan, so it selects nothing', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(tester, initialLocation: '/explore');
      expect(
        selectedIndex(tester),
        -1,
        reason: 'Explore stays reachable in Pakistan without being a tab',
      );
    });
  });

  group('the tab set follows the country', () {
    testWidgets('Pakistan shows Trains, and not Explore', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(tester);
      final List<LumeDestinationId> ids = barDestinations(
        tester,
      ).map((LumeDestination d) => d.id).toList();
      expect(ids, contains(LumeDestinationId.trains));
      expect(ids, isNot(contains(LumeDestinationId.explore)));
    });

    testWidgets('another country shows Explore, and not Trains', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(
        tester,
        overrides: <Override>[
          countryOverrideProvider.overrideWith((Ref ref) => 'GB'),
        ],
      );
      final List<LumeDestinationId> ids = barDestinations(
        tester,
      ).map((LumeDestination d) => d.id).toList();
      expect(ids, contains(LumeDestinationId.explore));
      expect(ids, isNot(contains(LumeDestinationId.trains)));
    });
  });

  group('branches keep their stacks', () {
    testWidgets('a tab switch does not reset the other tab\'s screen', (
      WidgetTester tester,
    ) async {
      // The instrument used to be the fixture screen's tap counter, on
      // whichever branch was still a fixture. Every branch but Profile is the
      // product now, so the instrument is a real branch's own state instead:
      // how far down Today is scrolled. It survives only if the branch is
      // re-presented rather than rebuilt, and it will still be there when
      // Profile stops being a fixture too.
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.today,
        surface: LumeViewport.phone,
      );

      double offset() => tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels;

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      final double left = offset();
      expect(left, greaterThan(0));

      router.go(LumeRoutes.home);
      await tester.pumpAndSettle();
      expect(offset(), 0, reason: 'Home has its own offset, not Today\'s');

      router.go(LumeRoutes.today);
      await tester.pumpAndSettle();
      expect(
        offset(),
        moreOrLessEquals(left, epsilon: 0.5),
        reason: 'Today came back to where it was left',
      );
    });

    testWidgets('a nested screen stays on its branch while you visit another', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: '/home/notifications',
      );

      await tester.tap(find.text('Today').last);
      await tester.pumpAndSettle();
      expect(locationOf(router), '/today');

      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      expect(
        locationOf(router),
        '/home/notifications',
        reason: 'Home remembered it was showing the notification centre',
      );
    });

    testWidgets('tapping the tab you are already inside returns to its root', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: '/today/notifications',
      );
      await tester.tap(find.text('Today').last);
      await tester.pumpAndSettle();
      expect(locationOf(router), '/today');
    });

    testWidgets('the same screen on two branches keeps two positions', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: '/home/notifications',
      );

      await tester.tap(find.text('Today').last);
      await tester.pumpAndSettle();
      router.go('/today/search');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      expect(locationOf(router), '/home/notifications');

      await tester.tap(find.text('Today').last);
      await tester.pumpAndSettle();
      expect(locationOf(router), '/today/search');
    });
  });

  group('back lands where the user came from', () {
    testWidgets('a tool opened from Home returns to Home', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: '/home/tool/ready',
      );
      await tester.tap(find.bySemanticsLabel('Back').first);
      await tester.pumpAndSettle();
      expect(locationOf(router), '/home');
    });

    testWidgets('the same tool opened from Today returns to Today', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: '/today/tool/ready',
      );
      await tester.tap(find.bySemanticsLabel('Back').first);
      await tester.pumpAndSettle();
      expect(
        locationOf(router),
        '/today',
        reason:
            'the centre remembers where the user was — and a stack remembers '
            'it without a variable to keep in step',
      );
    });

    testWidgets('a record shown over its list gives the list back first', (
      WidgetTester tester,
    ) async {
      // Compact: the record is over the list, so the first Back returns to the
      // list rather than leaving the collection. Only the second one leaves.
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: '/home/tool/records/records/7',
      );
      expect(find.byType(LumeRecordHero), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LumeRecordHero), findsNothing);
      expect(
        locationOf(router),
        '/home/tool/records/records/7',
        reason: 'clearing the selection is not a navigation',
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        locationOf(router),
        '/home/tool/records',
        reason:
            'one page for the collection, whether or not it opened on a '
            'record — so the second Back leaves the collection entirely',
      );
    });

    testWidgets('the create form is matched before the record pattern', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(
        tester,
        initialLocation: '/home/tool/records/records/new',
      );
      expect(find.text('Add'), findsWidgets);
      expect(
        find.byType(LumeRecordHero),
        findsNothing,
        reason: '"new" must not be read as a record id',
      );
    });

    testWidgets('a record collection returns to its tool', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: '/home/tool/records/records',
      );
      await tester.tap(find.bySemanticsLabel('Back').first);
      await tester.pumpAndSettle();
      expect(locationOf(router), '/home/tool/records');
    });
  });

  group('the eligibility gate', () {
    testWidgets('a gated tool renders the unavailable state, not its body', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(tester, initialLocation: '/home/tool/gated');
      final LumeToolFrame frame = tester.widget<LumeToolFrame>(
        find.byType(LumeToolFrame),
      );
      expect(frame.eligible, isFalse);
      expect(find.text('Not part of your setup'), findsOneWidget);
    });

    testWidgets('a tool id nobody knows is refused the same way', (
      WidgetTester tester,
    ) async {
      // §64: a deep link is not a second entry point with weaker rules.
      await pumpLumeRouter(tester, initialLocation: '/home/tool/not-a-tool');
      // The title and the state say the same thing, which is the point: the
      // screen has no other content to show.
      expect(find.text('Not part of your setup'), findsWidgets);
      expect(LumeFixtureTool.parse('not-a-tool'), isNull);
    });
  });

  group('the tablet presentations route the same way', () {
    testWidgets('a rail selects a destination at medium', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        surface: LumeViewport.medium,
      );
      expect(find.byType(LumeNavigationRail), findsOneWidget);
      await tester.tap(find.text('Today').last);
      await tester.pumpAndSettle();
      expect(locationOf(router), '/today');
    });

    testWidgets('a sidebar selects a destination at expanded', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        surface: LumeViewport.expanded,
      );
      await tester.tap(find.text('Trains').last);
      await tester.pumpAndSettle();
      expect(locationOf(router), '/trains');
    });
  });
}

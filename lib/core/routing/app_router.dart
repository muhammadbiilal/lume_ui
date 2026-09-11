/// The route table, and the one place the shell is wrapped around a screen.
///
/// `router.js` has a single activation path — *"everything that shows a screen
/// comes through here, so the leave/enter pairing cannot be skipped by one
/// caller and honoured by another"* — and this keeps that property for the same
/// reason: one [StatefulShellRoute] builds the shell, so there is no second
/// code path that could draw navigation differently.
///
/// **Six branches for five tabs.** [LumeDestinations.all] is the branch order
/// and never changes; [LumeDestinations.orderFor] is the *visible* order and
/// changes with country. A Pakistani user who moves to the UK loses Trains from
/// the bar and gains Explore, and every other branch keeps its stack, its
/// scroll and its form — because nothing was rebuilt, only re-presented. That
/// is what [LumeDestinations.branchIndexOf] is for, and it is why the branch
/// list is not built from `orderFor`.
///
/// **Nested destinations ride on a branch.** The notification centre, search,
/// account, a tool and a tool's records are all sub-routes of whichever branch
/// they were opened from, so Back returns to where the user actually was. The
/// reference does this with a remembered `notifReturnTab`; a stack does it
/// without remembering anything, and survives being opened twice from two
/// different tabs.
///
/// **Selection follows the location, not the branch.** `router.js` syncs the
/// selection against `data-tab`, and a nested destination has none — so a tool
/// selects nothing and the pill hides, even though the tool is sitting on the
/// Tools branch. [LumeRoutes.destinationAt] is that rule, and the shell asks it
/// rather than reading `navigationShell.currentIndex`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/shell_provider.dart';
import '../../features/shell/presentation/fixture_records_screen.dart';
import '../../features/shell/presentation/fixture_screens.dart';
import '../../features/gallery/presentation/gallery_screen.dart';
import '../../features/gallery/presentation/navigation_gallery.dart';
import '../../features/onboarding/presentation/onboarding_flow.dart';
import '../../features/shell/presentation/fixture_tool_screen.dart';
import '../../l10n/app_localizations.dart';
import '../icons/lume_icons.dart';
import '../navigation/lume_destination.dart';
import '../navigation/lume_shell.dart';
import 'lume_routes.dart';

/// The application's router.
///
/// A provider rather than a global so a test can build one per case — a
/// different starting location, a different country — without the previous
/// test's navigation state leaking into it.
final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  return buildLumeRouter();
});

/// Builds the route table.
///
/// [initialLocation] exists for tests and for a deep link arriving before the
/// app is up; nothing in the product passes it.
GoRouter buildLumeRouter({
  String? initialLocation,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouter(
    initialLocation: initialLocation ?? LumeRoutes.start,
    navigatorKey: navigatorKey,
    debugLogDiagnostics: false,
    errorBuilder: (BuildContext context, GoRouterState state) {
      final AppLocalizations l = AppLocalizations.of(context);
      return LumeMessageScreen(
        title: l.routeMissingTitle,
        text: l.routeMissingText,
        actionLabel: l.navHome,
        onAction: () => context.go(LumeRoutes.start),
      );
    },
    routes: <RouteBase>[
      // The two flows that cover the shell rather than sitting inside it.
      // §124: authentication is a flow, not a tool — it never enters the tool
      // router, the catalogue or search, and it has no navigation of its own.
      GoRoute(
        path: LumeRoutes.auth,
        builder: (BuildContext context, GoRouterState state) => _flow(
          context,
          storageId: 'auth',
          label: AppLocalizations.of(context).navAccount,
        ),
      ),
      // The two converted steps, reachable. The other seven are F4B; the flow
      // host is where they will be added.
      GoRoute(
        path: LumeRoutes.onboarding,
        builder: (BuildContext context, GoRouterState state) =>
            LumeOnboardingFlowLoader(
              onLeave: () => context.go(LumeRoutes.start),
              onFinished: (LumeOnboardingDraft draft) =>
                  context.go(LumeRoutes.start),
            ),
      ),

      // A bare nested destination, arriving from a push notification or a
      // link, has no branch of its own. It lands on Home's, which is the same
      // fallback `notifReturnTab` starts at.
      GoRoute(
        path: '/${LumeRoutes.notificationsSegment}',
        redirect: (BuildContext context, GoRouterState state) =>
            LumeRoutes.notifications(LumeRoutes.home),
      ),
      GoRoute(
        path: '/${LumeRoutes.searchSegment}',
        redirect: (BuildContext context, GoRouterState state) =>
            LumeRoutes.search(LumeRoutes.home),
      ),
      GoRoute(
        path: '/${LumeRoutes.accountSegment}',
        redirect: (BuildContext context, GoRouterState state) =>
            LumeRoutes.account(LumeRoutes.profile),
      ),

      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) => _ShellHost(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          for (final LumeDestinationId id in LumeDestinations.all)
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  path: id.path,
                  builder: (BuildContext context, GoRouterState state) =>
                      _destination(context, id),
                  routes: _nestedRoutes(id),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

/// The destinations that are not tabs, defined once and mounted on every
/// branch.
///
/// One list, six mountings — so the notification centre opened from Today is
/// the same screen with the same behaviour as the one opened from Home, and
/// only its stack differs.
List<RouteBase> _nestedRoutes(LumeDestinationId branch) {
  final String root = branch.path;

  return <RouteBase>[
    // The development gallery hangs off Profile and nowhere else. It is not a
    // product surface: `gallery_scope_test.dart` keeps it out of every other
    // import graph, and this is the one route that reaches it.
    if (branch == LumeDestinationId.profile) ...<RouteBase>[
      GoRoute(
        path: _gallerySegment,
        builder: (BuildContext context, GoRouterState state) =>
            const GalleryScreen(),
      ),
      GoRoute(
        path: _navigationGallerySegment,
        builder: (BuildContext context, GoRouterState state) =>
            NavigationGallery(onBack: () => context.go(root)),
      ),
    ],
    GoRoute(
      path: LumeRoutes.notificationsSegment,
      builder: (BuildContext context, GoRouterState state) => LumeFixtureScreen(
        title: AppLocalizations.of(context).navNotifications,
        storageId: '${branch.name}/notifications',
        onBack: () => context.go(root),
        backLabel: AppLocalizations.of(context).actionBack,
      ),
    ),
    GoRoute(
      path: LumeRoutes.searchSegment,
      builder: (BuildContext context, GoRouterState state) => LumeFixtureScreen(
        title: AppLocalizations.of(context).actionSearch,
        storageId: '${branch.name}/search',
        onBack: () => context.go(root),
        backLabel: AppLocalizations.of(context).actionBack,
      ),
    ),
    GoRoute(
      path: LumeRoutes.accountSegment,
      builder: (BuildContext context, GoRouterState state) => LumeFixtureScreen(
        title: AppLocalizations.of(context).navAccount,
        storageId: '${branch.name}/account',
        onBack: () => context.go(root),
        backLabel: AppLocalizations.of(context).actionBack,
      ),
    ),
    GoRoute(
      path: LumeRoutes.unavailableSegment,
      builder: (BuildContext context, GoRouterState state) {
        final AppLocalizations l = AppLocalizations.of(context);
        return LumeMessageScreen(
          title: l.toolUnavailableTitle,
          text: l.toolUnavailableText,
          actionLabel: l.actionBack,
          onAction: () => context.go(root),
        );
      },
    ),
    GoRoute(
      path: '${LumeRoutes.toolSegment}/:${LumeRoutes.toolIdParam}',
      builder: (BuildContext context, GoRouterState state) {
        final String toolId = state.pathParameters[LumeRoutes.toolIdParam]!;
        return FixtureToolScreen(
          toolId: toolId,
          onBack: () => context.go(root),
          // A related tool *replaces* rather than stacks, so a chain of them
          // cannot grow a back stack the user has to press through.
          onOpenRelated: (String id) =>
              context.replace(LumeRoutes.tool(root, id)),
          onOpenRecords: () => context.go(LumeRoutes.records(root, toolId)),
        );
      },
      routes: <RouteBase>[
        // Four siblings rather than a nest. `records/:recordId` is not a page
        // *on top of* the collection: it is the collection, opened on a
        // record — see LumeMasterDetailShell. Stacking them would put two
        // near-identical lists in the back stack, and Back would walk through
        // both. The fixed segments come first, so `new` is never read as a
        // record id.
        GoRoute(
          path: LumeRoutes.recordsSegment,
          builder: (BuildContext context, GoRouterState state) =>
              _records(context, state, root),
        ),
        GoRoute(
          path: '${LumeRoutes.recordsSegment}/${LumeRoutes.newSegment}',
          builder: (BuildContext context, GoRouterState state) =>
              _recordForm(context, state, root, recordId: null),
        ),
        GoRoute(
          path:
              '${LumeRoutes.recordsSegment}/:${LumeRoutes.recordIdParam}/'
              '${LumeRoutes.editSegment}',
          builder: (BuildContext context, GoRouterState state) => _recordForm(
            context,
            state,
            root,
            recordId: state.pathParameters[LumeRoutes.recordIdParam],
          ),
        ),
        GoRoute(
          path: '${LumeRoutes.recordsSegment}/:${LumeRoutes.recordIdParam}',
          builder: (BuildContext context, GoRouterState state) =>
              _records(context, state, root),
        ),
      ],
    ),
  ];
}

/// A tool's record collection, opened on a record when the location names one.
Widget _records(BuildContext context, GoRouterState state, String root) {
  final String toolId = state.pathParameters[LumeRoutes.toolIdParam]!;
  return FixtureRecordsScreen(
    toolId: toolId,
    initialRecordId: state.pathParameters[LumeRoutes.recordIdParam],
    onBack: () => context.go(LumeRoutes.tool(root, toolId)),
  );
}

/// The create and edit forms. One screen, because the difference between them
/// is what it opens with, not what it is.
Widget _recordForm(
  BuildContext context,
  GoRouterState state,
  String root, {
  required String? recordId,
}) {
  final AppLocalizations l = AppLocalizations.of(context);
  final String toolId = state.pathParameters[LumeRoutes.toolIdParam]!;
  return LumeFixtureScreen(
    title: recordId == null ? l.actionAdd : l.actionEdit,
    subtitle: recordId,
    storageId: 'form/$toolId/${recordId ?? LumeRoutes.newSegment}',
    rows: 8,
    onBack: () => context.go(LumeRoutes.records(root, toolId)),
    backLabel: l.actionCancel,
  );
}

/// The two development surfaces, kept off [LumeRoutes] because they are not
/// part of the product's route map.
const String _gallerySegment = 'gallery';
const String _navigationGallerySegment = 'navigation-gallery';

/// A branch root.
Widget _destination(BuildContext context, LumeDestinationId id) {
  final AppLocalizations l = AppLocalizations.of(context);
  final String root = id.path;

  return LumeFixtureScreen(
    title: destinationLabel(l, id),
    storageId: id.name,
    links: <LumeFixtureLink>[
      LumeFixtureLink(
        label: l.actionSearch,
        icon: LumeIcons.search,
        onTap: () => context.go(LumeRoutes.search(root)),
      ),
      LumeFixtureLink(
        label: l.navNotifications,
        icon: LumeIcons.bell,
        onTap: () => context.go(LumeRoutes.notifications(root)),
      ),
      LumeFixtureLink(
        label: l.navTools,
        icon: LumeIcons.grid,
        onTap: () =>
            context.go(LumeRoutes.tool(root, LumeFixtureTool.ready.name)),
      ),
      LumeFixtureLink(
        label: l.commonHistory,
        icon: LumeIcons.list,
        onTap: () =>
            context.go(LumeRoutes.records(root, LumeFixtureTool.records.name)),
      ),
      LumeFixtureLink(
        label: l.navAccount,
        icon: LumeIcons.user,
        onTap: () => context.go(LumeRoutes.account(root)),
      ),
      if (id == LumeDestinationId.profile) ...<LumeFixtureLink>[
        LumeFixtureLink(
          label: l.appTagline,
          icon: LumeIcons.sparkles,
          onTap: () => context.go('$root/$_gallerySegment'),
        ),
        LumeFixtureLink(
          label: l.a11yMainNavigation,
          icon: LumeIcons.compass,
          onTap: () => context.go('$root/$_navigationGallerySegment'),
        ),
      ],
    ],
  );
}

/// A flow that covers the shell: no navigation, one way out.
Widget _flow(
  BuildContext context, {
  required String storageId,
  required String label,
}) {
  return LumeFixtureScreen(
    title: label,
    storageId: storageId,
    rows: 6,
    onBack: () => context.go(LumeRoutes.start),
    backLabel: AppLocalizations.of(context).actionBack,
  );
}

/// A destination's label.
///
/// The one mapping from id to string, so a label is translated once and the
/// bar, the rail, the sidebar and any screen that names a destination all agree.
String destinationLabel(AppLocalizations l, LumeDestinationId id) =>
    switch (id) {
      LumeDestinationId.home => l.navHome,
      LumeDestinationId.tools => l.navTools,
      LumeDestinationId.trains => l.navTrains,
      LumeDestinationId.today => l.navToday,
      LumeDestinationId.explore => l.navExplore,
      LumeDestinationId.profile => l.navProfile,
    };

/// Wraps whichever branch is showing in the shell.
class _ShellHost extends ConsumerWidget {
  const _ShellHost({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String country = ref.watch(countryCodeProvider);

    final List<LumeDestination> destinations = LumeDestinations.build(
      countryCode: country,
      label: (LumeDestinationId id) => destinationLabel(l, id),
      badges: ref.watch(destinationBadgesProvider),
      dots: ref.watch(destinationDotsProvider),
    );

    // The *location*, not the branch: a tool sitting on the Tools branch
    // selects nothing, exactly as `syncTabs` finds no matching `.tab`.
    final String location = GoRouterState.of(context).uri.path;
    final LumeDestinationId? current = LumeRoutes.destinationAt(location);
    final int selectedIndex = current == null
        ? -1
        : destinations.indexWhere((LumeDestination d) => d.id == current);

    return LumeShell(
      destinations: destinations,
      selectedIndex: selectedIndex,
      navigationLabel: l.a11yMainNavigation,
      onSelected: (int index) => _select(destinations[index].id),
      child: navigationShell,
    );
  }

  void _select(LumeDestinationId id) {
    final int branch = LumeDestinations.branchIndexOf(id);
    // Tapping the destination you are already inside returns to its root,
    // which is the one thing a deep stack needs and a flat one never did.
    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }
}

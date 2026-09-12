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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers/personalisation.dart';
import '../../app/providers/shell_provider.dart';
import '../../features/auth/application/auth_flow_controller.dart';
import '../../features/auth/data/fake_auth_repository.dart';
import '../../features/auth/domain/auth_model.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/presentation/auth_flow.dart';
import '../../features/catalogue/domain/eligibility.dart';
import '../../features/catalogue/domain/lume_feature.dart';
import '../../features/catalogue/presentation/feature_strings.dart';
import '../../features/shell/presentation/fixture_records_screen.dart';
import '../../features/shell/presentation/fixture_screens.dart';
import '../../features/gallery/presentation/gallery_screen.dart';
import '../../features/explore/presentation/explore_host.dart';
import '../../features/home/presentation/home_host.dart';
import '../../features/today/presentation/today_host.dart';
import '../../features/trains/presentation/trains_host.dart';
import '../../features/tools/presentation/tools_host.dart';
import '../../features/gallery/presentation/navigation_gallery.dart';
import '../../features/onboarding/domain/onboarding_state.dart';
import '../../features/onboarding/domain/profile_repository.dart';
import '../../features/onboarding/presentation/onboarding_flow.dart';
import '../../features/shell/presentation/fixture_tool_screen.dart';
import '../../features/startup/application/startup_controller.dart';
import '../../features/startup/domain/startup_state.dart';
import '../../features/startup/presentation/splash_screen.dart';
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
  final GoRouter router = buildLumeRouter(
    startup: ref.watch(startupControllerProvider),
    auth: ref.watch(authRepositoryProvider),
    onboardingStore: ref.watch(onboardingStoreProvider),
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Builds the route table.
///
/// [initialLocation] exists for tests and for a deep link arriving before the
/// app is up; nothing in the product passes it.
GoRouter buildLumeRouter({
  String? initialLocation,
  GlobalKey<NavigatorState>? navigatorKey,
  LumeStartupController? startup,
  LumeAuthRepository? auth,
  LumeOnboardingStore? onboardingStore,
}) {
  final LumeAuthRepository repository = auth ?? LumeFakeAuthRepository();
  final LumeStartupController gate =
      startup ??
      LumeStartupController(
        authRepository: repository,
        profileRepository: LumeMemoryProfileRepository(),
      );
  final LumeOnboardingStore store =
      onboardingStore ?? LumeMemoryOnboardingStore();

  // The launch starts here and nowhere else. `boot()` is idempotent, so a
  // second router in a test cannot cause a second session restoration.
  unawaited(gate.boot());

  return GoRouter(
    initialLocation: initialLocation ?? LumeRoutes.start,
    navigatorKey: navigatorKey,
    debugLogDiagnostics: false,
    // The gate re-runs whenever something it reads has actually moved.
    refreshListenable: gate,
    redirect: (BuildContext context, GoRouterState state) {
      final String here = state.uri.path;
      final String? there = LumeRouteGate.redirect(
        state: gate.state,
        location: here,
      );
      // Somebody asked for a place they cannot have yet. Hold it rather than
      // dropping it: losing a deep link to a sign-in is the defect this whole
      // arrangement exists to prevent.
      if (there != null && there != here) gate.hold(here);
      return there;
    },
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
      //
      // It covers the shell rather than sitting inside it, which is D18: the
      // reference leaves the floating navigation bar drawn over the flow,
      // where it covers the footer and walks straight out of two screens that
      // declare nothing dismisses them.
      GoRoute(
        path: LumeRoutes.splash,
        builder: (BuildContext context, GoRouterState state) =>
            const LumeSplashScreen(),
      ),
      GoRoute(
        path: LumeRoutes.auth,
        redirect: (BuildContext context, GoRouterState state) =>
            state.uri.path == LumeRoutes.auth
            ? LumeRoutes.authRoute(LumeAuthRoute.signIn.segment)
            : null,
        routes: <RouteBase>[
          GoRoute(
            path: ':$_authScreenParam',
            // One page for the whole flow, keyed by name rather than by
            // location: the controller holds the recovery token, the step and
            // the held destination, and a new page per screen would throw all
            // three away on the way from sign-in to sign-up.
            pageBuilder: (BuildContext context, GoRouterState state) =>
                NoTransitionPage<void>(
                  key: const ValueKey<String>('auth-flow'),
                  child: _auth(context, state),
                ),
          ),
        ],
      ),
      // The whole first-run flow. "Sign in" hands over to authentication,
      // which is its own phase; everything else lands on the start route.
      GoRoute(
        path: LumeRoutes.onboarding,
        builder: (BuildContext context, GoRouterState state) =>
            LumeOnboardingFlowLoader(
              store: store,
              onDone:
                  (LumeOnboardingOutcome outcome, LumeProfileRecord record) {
                    // Onboarding is the one thing that may say onboarding is
                    // finished. Authentication never does.
                    gate.profileChanged(record);
                    context.go(
                      outcome == LumeOnboardingOutcome.signIn
                          ? LumeRoutes.auth
                          : (gate.takeHeld() ?? LumeRoutes.start),
                    );
                  },
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
      builder: (BuildContext context, GoRouterState state) =>
          _tool(context, state, root),
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
///
/// Home, the Tools hub, Today, Explore and Trains are the product; Profile is
/// still the F3 fixture that proved the shell, and it is replaced by its own
/// screen in turn.
Widget _destination(BuildContext context, LumeDestinationId id) {
  final AppLocalizations l = AppLocalizations.of(context);
  final String root = id.path;

  switch (id) {
    case LumeDestinationId.home:
      return LumeHomeHost(branch: root);
    case LumeDestinationId.tools:
      return LumeToolsHost(branch: root);
    case LumeDestinationId.today:
      return LumeTodayHost(branch: root);
    case LumeDestinationId.explore:
      return LumeExploreHost(branch: root);
    case LumeDestinationId.trains:
      return LumeTrainsHost(branch: root);
    case LumeDestinationId.profile:
      break;
  }

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

/// A tool screen, behind the catalogue's own gate.
///
/// §64 lists deep links among the surfaces a hidden feature must not be
/// reachable through, and a route is the one surface with no tile to hide.
/// So the route puts the catalogue the same question the hub puts before it
/// draws a tile — the *same* [LumeEligibility], reading the *same* profile —
/// and a faith-gated, country-gated or switched-off tool is refused by the
/// frame rather than rendered because somebody typed its id.
///
/// An id the catalogue does not know falls through to the fixture rule, which
/// refuses it too. Both refusals look identical from outside, on purpose:
/// "you may not have this" and "there is no such thing" must not be
/// distinguishable, or the refusal itself becomes the leak.
Widget _tool(BuildContext context, GoRouterState state, String root) {
  final String toolId = state.pathParameters[LumeRoutes.toolIdParam]!;

  return Consumer(
    builder: (BuildContext context, WidgetRef ref, Widget? _) {
      final LumeEligibility eligibility = ref.watch(eligibilityProvider);
      return LumeProfileScope(
        builder: (BuildContext context, LumeUserContext user) {
          final LumeFeature? feature = eligibility.byId(toolId);
          return FixtureToolScreen(
            toolId: toolId,
            catalogueEligible: feature == null
                ? null
                : eligibility.isVisible(feature, user),
            catalogueName: feature == null
                ? null
                : LumeFeatureStrings.name(
                    AppLocalizations.of(context),
                    feature.id,
                  ),
            onBack: () => context.go(root),
            // A related tool *replaces* rather than stacks, so a chain of them
            // cannot grow a back stack the user has to press through.
            onOpenRelated: (String id) =>
                context.replace(LumeRoutes.tool(root, id)),
            onOpenRecords: () => context.go(LumeRoutes.records(root, toolId)),
          );
        },
      );
    },
  );
}

/// The path parameter naming which authentication screen is showing.
const String _authScreenParam = 'screen';

/// The authentication flow, wired to the gate.
Widget _auth(BuildContext context, GoRouterState state) {
  final String segment = state.pathParameters[_authScreenParam] ?? '';
  final LumeAuthRoute route =
      LumeAuthRoute.fromSegment(segment) ?? LumeAuthRoute.signIn;

  return Consumer(
    builder: (BuildContext context, WidgetRef ref, Widget? _) {
      final LumeStartupController gate = ref.watch(startupControllerProvider);
      final LumeAuthStatus status = gate.state.auth;

      return LumeAuthFlow(
        repository: ref.watch(authRepositoryProvider),
        initialRoute: route,
        status: status,
        // A flow reached because something was held is a flow that
        // interrupted something, and it says so: a cross, and a way to
        // carry on as a guest.
        modal: gate.state.held != null,
        pendingDestination: gate.state.held,
        onRouteChanged: (LumeAuthRoute next) {
          if (!context.mounted) return;
          context.replace(LumeRoutes.authRoute(next.segment));
        },
        onOutcome:
            (
              LumeAuthOutcome outcome,
              LumeAuthStatus? status,
              String? pending,
            ) async {
              switch (outcome) {
                case LumeAuthOutcome.signedOutGuest:
                  await gate.continueAsGuest();
                case LumeAuthOutcome.authenticated:
                case LumeAuthOutcome.verified:
                  // The flow hands over the status it produced. Asking the
                  // repository again would be a second restoration.
                  if (status != null) gate.signedIn(status);
                case LumeAuthOutcome.dismissed:
                  break;
              }
              if (!context.mounted) return;

              final bool succeeded =
                  outcome == LumeAuthOutcome.authenticated ||
                  outcome == LumeAuthOutcome.verified;
              // A held destination is resumed by *succeeding*, never by
              // walking away: somebody who chose to stay a guest is not asking
              // to be sent to the screen that sent them here.
              final String? held = gate.takeHeld() ?? pending;
              context.go(
                succeeded ? (held ?? LumeRoutes.start) : LumeRoutes.start,
              );
            },
      );
    },
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
    // The tab set is personalised by country, and the country lives on the
    // profile — one store, read through the same scope every destination
    // reads, so switching market re-presents the bar in the same frame the
    // setting changed without rebuilding a branch.
    final LumeStartupController gate = ref.watch(startupControllerProvider);
    final String country =
        ref.watch(countryOverrideProvider) ?? gate.state.profile.country;

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

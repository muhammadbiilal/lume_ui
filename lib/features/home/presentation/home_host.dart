/// Home, wired to the launch.
///
/// The screen takes data and actions; this is what supplies them. It owns the
/// controller for the life of the branch, reloads when the personalisation
/// moves, and turns a tap into a route — so [LumeHomeScreen] itself stays a
/// function of its inputs and can be pumped with a fixture and no router.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/personalisation.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/routing/lume_routes.dart';
import '../../catalogue/domain/eligibility.dart';
import '../application/home_controller.dart';
import '../domain/home_model.dart';
import 'home_screen.dart';

/// Home on a branch.
class LumeHomeHost extends ConsumerStatefulWidget {
  const LumeHomeHost({super.key, required this.branch});

  /// The branch root Home sits on, so a tool opened from here returns here.
  final String branch;

  @override
  ConsumerState<LumeHomeHost> createState() => _LumeHomeHostState();
}

class _LumeHomeHostState extends ConsumerState<LumeHomeHost> {
  LumeHomeController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LumeProfileScope(
    builder: (BuildContext context, LumeUserContext user) {
      final LumeHomeController controller = _controller ??= LumeHomeController(
        repository: ref.read(homeDataRepositoryProvider),
        eligibility: ref.read(eligibilityProvider),
        clock: LumeClockScope.of(context),
        routes: LumeHomeRoutes(
          today: LumeRoutes.today,
          tools: LumeRoutes.tools,
          trains: LumeRoutes.trains,
          explore: LumeRoutes.explore,
        ),
      );

      // A change of country, city or faith is a change of what Home shows, so
      // the load is keyed on the personalisation rather than on the frame.
      // `load` is idempotent for an unchanged user, so a rebuild is not a
      // second fetch.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.load(user),
      );

      return ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? _) => LumeHomeScreen(
          data: controller.state.data,
          user: user,
          loading: controller.state.loading,
          failed: controller.state.failed,
          onRefresh: controller.refresh,
          actions: LumeHomeActions(
            openTarget: (LumeHomeTarget target) => _open(context, user, target),
            openSearch: () => context.go(LumeRoutes.search(widget.branch)),
            openNotifications: () =>
                context.go(LumeRoutes.notifications(widget.branch)),
            openProfile: () => context.go(LumeRoutes.profile),
            openTools: () => context.go(LumeRoutes.tools),
            openToday: () => context.go(LumeRoutes.today),
            openExplore: () => context.go(LumeRoutes.explore),
          ),
        ),
      );
    },
  );

  /// A tool opens **on this branch**, so Back returns to Home rather than to
  /// whatever the Tools hub was last showing. A destination goes to its own
  /// root, which is what the bottom bar would have done.
  void _open(BuildContext context, LumeUserContext user, LumeHomeTarget t) {
    switch (t) {
      case LumeToolTarget(:final String featureId):
        ref.read(recentToolsProvider).note(featureId);
        context.go(LumeRoutes.tool(widget.branch, featureId));
      case LumeDestinationTarget(:final String path):
        context.go(path);
    }
  }
}

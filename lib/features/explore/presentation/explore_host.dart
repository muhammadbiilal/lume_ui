/// Explore, wired to the launch.
///
/// The same shape as Today's host: the screen takes a snapshot and a set of
/// actions, and this supplies them. The reload is keyed on the
/// personalisation, because a change of country changes which local services
/// exist, which weather is read and which news edition arrives.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/personalisation.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/navigation/lume_destination.dart';
import '../../../core/routing/lume_routes.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../home/domain/home_model.dart';
import '../domain/explore_repository.dart';
import 'explore_screen.dart';

/// Explore on a branch.
class LumeExploreHost extends ConsumerStatefulWidget {
  const LumeExploreHost({super.key, required this.branch});

  /// The branch root Explore sits on, so a tool opened from here returns here.
  final String branch;

  @override
  ConsumerState<LumeExploreHost> createState() => _LumeExploreHostState();
}

class _LumeExploreHostState extends ConsumerState<LumeExploreHost> {
  LumeExploreSnapshot? _snapshot;
  bool _failed = false;
  LumeUserContext? _loadedFor;
  LumeToastData? _toast;

  Future<void> _load(LumeUserContext user, {bool force = false}) async {
    if (!force && _loadedFor == user) return;
    _loadedFor = user;
    final LumeExploreRepository repo = ref.read(exploreRepositoryProvider);
    try {
      final LumeExploreSnapshot s = await repo.load(
        user,
        now: LumeClockScope.of(context).now(),
      );
      if (!mounted) return;
      setState(() {
        _snapshot = s;
        _failed = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) => LumeProfileScope(
    builder: (BuildContext context, LumeUserContext user) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(user));
      final AppLocalizations l = AppLocalizations.of(context);

      final Widget screen = LumeExploreScreen(
        user: user,
        eligibility: ref.watch(eligibilityProvider),
        snapshot: _snapshot,
        failed: _failed,
        onRetry: () => _load(user, force: true),
        // Shown only where Explore is not one of the market's tabs, which is
        // the same condition the reference's router uses.
        onBack:
            LumeDestinations.orderFor(
              user.country,
            ).contains(LumeDestinationId.explore)
            ? null
            : () => context.go(LumeRoutes.home),
        actions: LumeExploreActions(
          openTarget: (LumeHomeTarget target) => _open(context, target),
          openSearch: () => context.go(LumeRoutes.search(widget.branch)),
          refreshWeather: () async {
            await _load(user, force: true);
            if (!mounted) return;
            setState(
              () => _toast = LumeToastData(message: l.exploreWeatherToast),
            );
          },
        ),
      );

      if (_toast == null) return screen;
      return Stack(
        children: <Widget>[
          screen,
          Positioned(
            left: 0,
            right: 0,
            bottom: 92 + MediaQuery.paddingOf(context).bottom,
            child: Align(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LumeToast(data: _toast!),
              ),
            ),
          ),
        ],
      );
    },
  );

  void _open(BuildContext context, LumeHomeTarget t) {
    switch (t) {
      case LumeToolTarget(:final String featureId):
        ref.read(recentToolsProvider).note(featureId);
        context.go(LumeRoutes.tool(widget.branch, featureId));
      case LumeDestinationTarget(:final String path):
        context.go(path);
    }
  }
}

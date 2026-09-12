/// Today, wired to the launch.
///
/// The screen takes a day and a set of actions; this supplies them. It holds
/// the day for the life of the branch, reloads when the personalisation moves,
/// and turns a tap into a route — so [LumeTodayScreen] stays a function of its
/// inputs and can be pumped with a fixture and no router.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/personalisation.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/routing/lume_routes.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../home/domain/home_model.dart';
import '../domain/today_model.dart';
import '../domain/today_repository.dart';
import 'today_screen.dart';

/// Today on a branch.
class LumeTodayHost extends ConsumerStatefulWidget {
  const LumeTodayHost({super.key, required this.branch});

  /// The branch root Today sits on, so a tool opened from here returns here.
  final String branch;

  @override
  ConsumerState<LumeTodayHost> createState() => _LumeTodayHostState();
}

class _LumeTodayHostState extends ConsumerState<LumeTodayHost> {
  LumeTodayData? _data;
  bool _failed = false;
  LumeUserContext? _loadedFor;

  /// Shown over the page. There is no global presenter, so a screen that
  /// toasts holds its own — the same shape onboarding uses.
  LumeToastData? _toast;

  void _say(String message) {
    setState(() => _toast = LumeToastData(message: message));
  }

  Future<void> _load(LumeUserContext user, {bool force = false}) async {
    if (!force && _loadedFor == user) return;
    _loadedFor = user;
    final LumeTodayRepository repo = ref.read(todayRepositoryProvider);
    try {
      final LumeTodayDay day = await repo.load(
        user,
        now: LumeClockScope.of(context).now(),
      );
      if (!mounted) return;
      setState(() {
        _data = day.data;
        _failed = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  Future<void> _toggle(LumeUserContext user, String id, bool done) async {
    final LumeTodayRepository repo = ref.read(todayRepositoryProvider);
    final LumeTodayDay day = await repo.setTaskDone(
      user,
      now: LumeClockScope.of(context).now(),
      taskId: id,
      done: done,
    );
    if (!mounted) return;
    setState(() => _data = day.data);
    final AppLocalizations l = AppLocalizations.of(context);
    _say(done ? l.todayTaskDone : l.todayTaskUndone);
  }

  @override
  Widget build(BuildContext context) => LumeProfileScope(
    builder: (BuildContext context, LumeUserContext user) {
      // A change of country, city or faith changes what the day contains, so
      // the load is keyed on the personalisation rather than on the frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(user));

      final AppLocalizations l = AppLocalizations.of(context);

      final Widget screen = LumeTodayScreen(
        user: user,
        data: _data,
        failed: _failed,
        onRetry: () => _load(user, force: true),
        actions: LumeTodayActions(
          openTarget: (LumeHomeTarget target) => _open(context, target),
          toggleTask: (String id, bool done) => _toggle(user, id, done),
          // There is no Week screen and no Add-task screen in the reference,
          // and F5B does not implement one. Both toast, as the reference
          // does, rather than navigating somewhere that does not exist.
          openWeek: () => _say(l.todayWeekToast),
          addTask: () => _say(l.todayAddToast),
          openPrivate: () => _say(l.todayPrivateToast),
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

  /// A tool opens **on this branch**, so Back returns to Today.
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

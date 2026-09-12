/// Trains, wired to the launch.
///
/// The same shape as Today's and Explore's hosts: the screen takes a snapshot
/// and a set of actions, and this supplies them. The reload is keyed on the
/// personalisation, because a change of country changes whether this
/// destination exists at all.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/personalisation.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/routing/lume_routes.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/eligibility.dart';
import '../domain/trains_model.dart';
import '../domain/trains_repository.dart';
import 'trains_screen.dart';

/// Trains on a branch.
class LumeTrainsHost extends ConsumerStatefulWidget {
  const LumeTrainsHost({super.key, required this.branch});

  /// The branch root Trains sits on, so a tool opened from here returns here.
  final String branch;

  @override
  ConsumerState<LumeTrainsHost> createState() => _LumeTrainsHostState();
}

class _LumeTrainsHostState extends ConsumerState<LumeTrainsHost> {
  LumeTrainsSnapshot? _snapshot;
  LumeTrainsFailure? _failure;
  LumeUserContext? _loadedFor;

  /// Shown over the page. There is no global presenter, so a screen that
  /// toasts holds its own.
  LumeToastData? _toast;

  void _say(String message) {
    if (!mounted) return;
    setState(() => _toast = LumeToastData(message: message));
  }

  Future<void> _load(LumeUserContext user, {bool force = false}) async {
    if (!force && _loadedFor == user) return;
    _loadedFor = user;
    final LumeTrainsRepository repo = ref.read(trainsRepositoryProvider);
    try {
      final LumeTrainsSnapshot s = await repo.load(
        user,
        now: LumeClockScope.of(context).now(),
      );
      if (!mounted) return;
      setState(() {
        _snapshot = s;
        _failure = null;
      });
    } on LumeTrainsException catch (e) {
      if (!mounted) return;
      // A domain failure, not an exception: the screen is told which of the
      // two refusals to draw and never sees the error itself.
      setState(() => _failure = e.failure);
    } on Object {
      if (!mounted) return;
      setState(() => _failure = LumeTrainsFailure.unreachable);
    }
  }

  @override
  Widget build(BuildContext context) => LumeProfileScope(
    builder: (BuildContext context, LumeUserContext user) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(user));
      final AppLocalizations l = AppLocalizations.of(context);
      final LumeFormatting f = LumeFormatting.of(
        context,
        countryCode: user.country,
      );
      final LumeTrainsData? d = _snapshot?.data;

      final Widget screen = LumeTrainsScreen(
        user: user,
        snapshot: _snapshot,
        failure: _failure,
        onRetry: () => _load(user, force: true),
        actions: LumeTrainsActions(
          // Every one of these reports what the reference's own control
          // reports. There is no saved-journeys screen, no station picker and
          // no date picker in the reference, and F5C implements none: saying
          // what would happen is the reference's behaviour, and opening a
          // route that does not exist would not be.
          openSaved: () => _say(l.trainsSaved),
          chooseOrigin: () => _say(l.trainsChooseOrigin),
          chooseDestination: () => _say(l.trainsChooseDestination),
          // R2: the reference's swap reports "Stations swapped" and leaves
          // both fields where they were. Reproduced, and raised rather than
          // repaired — see TRAINS_PROFILE_CONTRACT.md §1.7.
          swap: () => _say(l.trainsSwapped),
          // R3: the day chips are `<button>`s with no handler. Reachable and
          // focusable, as the reference's are, and inert, as the reference's
          // are.
          chooseDay: (LumeJourneyDay _) {},
          search: () => _say(l.trainsSearchResult(d?.departures.length ?? 0)),
          refresh: () async {
            await _load(user, force: true);
            _say(l.trainsRefreshed);
          },
          openAllDepartures: () => _say(l.trainsAllDepartures),
          // `data-act="tool:trains"` — a departure row opens the Trains tool
          // on this branch, so Back returns here.
          openService: (LumeTrainService _) {
            ref.read(recentToolsProvider).note('trains');
            context.go(LumeRoutes.tool(widget.branch, 'trains'));
          },
          // The same sentence the card says out loud, so the toast and the
          // accessible name cannot drift apart.
          openRoute: (LumePopularRoute r) =>
              _say(LumeTrainsScreen.routeSummary(l, f, r)),
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
}

/// Trains, wired to the launch.
///
/// The same shape as Today's and Explore's hosts — the screen takes a snapshot
/// and a set of actions, and this supplies them — with one thing they do not
/// have: a **query**, which two of its controls change.
///
/// ### R2 and R3, the two approved functional corrections
///
/// The reference's swap reports "Stations swapped" and leaves both fields
/// where they were; its day chips are `<button>`s with no handler. Both are
/// corrected here, by decision, and both go through the same path:
///
/// 1. the next query is built from the current one, atomically;
/// 2. a query that is not a journey — one end missing, or one station twice —
///    is refused before anything is fetched, and the refusal is drawn on the
///    departures section rather than over the page;
/// 3. the repository is asked, with a request number;
/// 4. a late answer to a superseded question is dropped, so rapid switching
///    cannot leave yesterday's list under today's chip;
/// 5. the visible fields move only when an answer arrives, which makes
///    rollback the *absence* of a change rather than a second write;
/// 6. success is announced **after** the state has changed, to a screen
///    reader as well as to the toast.
///
/// While a query is in flight every control that would start another one is
/// inert, so a second tap cannot become a second request.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/personalisation.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/routing/lume_routes.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/eligibility.dart';
import '../data/trains_fixtures.dart';
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
  LumeQueryStatus _status = LumeQueryStatus.settled;

  /// Which request the screen is showing the answer to. A response carrying
  /// an older number is a stale one and is dropped.
  int _request = 0;

  /// Shown over the page. There is no global presenter, so a screen that
  /// toasts holds its own.
  LumeToastData? _toast;

  void _say(String message) {
    if (!mounted) return;
    setState(() => _toast = LumeToastData(message: message));
    // A toast is a picture. A screen reader is told separately, and only once
    // the state it describes has actually changed.
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      ),
    );
  }

  Future<void> _load(LumeUserContext user, {bool force = false}) async {
    if (!force && _loadedFor == user) return;
    _loadedFor = user;
    final LumeTrainsRepository repo = ref.read(trainsRepositoryProvider);
    final int request = ++_request;
    try {
      final LumeTrainsSnapshot s = await repo.load(
        user,
        now: LumeClockScope.of(context).now(),
      );
      if (!mounted || request != _request) return;
      setState(() {
        _snapshot = s;
        _failure = null;
        _status = LumeQueryStatus.settled;
      });
    } on LumeTrainsException catch (e) {
      if (!mounted || request != _request) return;
      // A domain failure, not an exception: the screen is told which refusal
      // to draw and never sees the error itself.
      setState(() => _failure = e.failure);
    } on Object {
      if (!mounted || request != _request) return;
      setState(() => _failure = LumeTrainsFailure.unreachable);
    }
  }

  /// Ask the timetable a new question, and show the answer or nothing.
  ///
  /// [announce] is handed the snapshot that came back, so the sentence a
  /// reader hears is built from what is now on screen rather than from what
  /// was asked for.
  Future<void> _ask(
    LumeUserContext user,
    LumeJourneyQuery next, {
    required String Function(LumeTrainsSnapshot) announce,
  }) async {
    // R2/R3: a second tap while one is in flight is not a second request.
    if (_status == LumeQueryStatus.busy) return;

    if (!next.isAskable) {
      setState(() => _status = LumeQueryStatus.invalid);
      return;
    }

    final int request = ++_request;
    setState(() => _status = LumeQueryStatus.busy);

    final LumeTrainsRepository repo = ref.read(trainsRepositoryProvider);
    try {
      final LumeTrainsSnapshot s = await repo.search(
        user,
        now: LumeClockScope.of(context).now(),
        query: next,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _snapshot = s;
        _failure = null;
        _status = LumeQueryStatus.settled;
      });
      _say(announce(s));
    } on LumeTrainsException catch (e) {
      if (!mounted || request != _request) return;
      // Nothing was written, so nothing has to be rolled back: the visible
      // fields still read the snapshot that is still on screen.
      setState(
        () => _status = e.failure == LumeTrainsFailure.invalidRoute
            ? LumeQueryStatus.invalid
            : LumeQueryStatus.failed,
      );
    } on Object {
      if (!mounted || request != _request) return;
      setState(() => _status = LumeQueryStatus.failed);
    }
  }

  /// The date a chip means, against the injected clock.
  ///
  /// Midnight rollover falls out of this: "today" is whatever day `now` is on
  /// when the chip is pressed, so a screen left open past midnight answers
  /// with the new day rather than the one it was opened on.
  DateTime _dateFor(LumeJourneyDay day, {DateTime? picked}) =>
      LumeTrainsComposer.dateFor(
        LumeJourneyQuery(origin: '', destination: '', day: day, date: picked),
        now: LumeClockScope.of(context).now(),
      );

  Future<void> _pickDate(
    LumeUserContext user,
    AppLocalizations l,
    LumeJourneyQuery current,
  ) async {
    final DateTime now = LumeClockScope.of(context).now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    // The picker is platform furniture, like the keyboard: the reference's
    // chip is labelled "Pick a date" and has nothing behind it, and a date
    // has to come from somewhere real (R3).
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current.date ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 90)),
      helpText: l.trainsPickedDate,
    );
    if (picked == null || !mounted) return;
    await _ask(
      user,
      current.withDay(LumeJourneyDay.other, on: picked),
      announce: (LumeTrainsSnapshot s) => l.trainsDayOn(
        LumeFormatting.of(
          context,
          countryCode: user.country,
        ).dateMedium(s.data.serviceDate),
      ),
    );
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
      final LumeJourneyQuery query =
          d?.query ??
          const LumeJourneyQuery(
            origin: kDefaultOrigin,
            destination: kDefaultDestination,
          );

      final Widget screen = LumeTrainsScreen(
        user: user,
        snapshot: _snapshot,
        failure: _failure,
        status: _status,
        onRetry: () => _load(user, force: true),
        actions: LumeTrainsActions(
          // There is no saved-journeys screen and no station picker in the
          // reference, and F5C implements none: saying what would happen is
          // the reference's behaviour, and opening a route that does not
          // exist would not be.
          openSaved: () => _say(l.trainsSaved),
          chooseOrigin: () => _say(l.trainsChooseOrigin),
          chooseDestination: () => _say(l.trainsChooseDestination),
          // R2 — a real swap. Atomic, answered before it is announced, and
          // inert while the answer is outstanding.
          swap: () => unawaited(
            _ask(
              user,
              query.swapped(),
              announce: (LumeTrainsSnapshot s) => l.trainsSwappedTo(
                s.data.query.origin,
                s.data.query.destination,
              ),
            ),
          ),
          // R3 — a real single selection. One day at a time, the date computed
          // from the injected clock, the results asked for again.
          chooseDay: (LumeJourneyDay day) {
            if (day == LumeJourneyDay.other) {
              unawaited(_pickDate(user, l, query));
              return;
            }
            if (day == query.day) return;
            unawaited(
              _ask(
                user,
                query.withDay(day, on: _dateFor(day)),
                announce: (LumeTrainsSnapshot _) => day == LumeJourneyDay.today
                    ? l.trainsDayToday
                    : l.trainsDayTomorrow,
              ),
            );
          },
          search: () => unawaited(
            _ask(
              user,
              query,
              announce: (LumeTrainsSnapshot s) =>
                  l.trainsSearchResult(s.data.departures.length),
            ),
          ),
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

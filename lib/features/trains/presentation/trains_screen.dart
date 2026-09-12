/// Trains — a destination Pakistan has and most markets do not.
///
/// Five blocks, in the order `trains.screen.js` emits them:
///
/// 1. the page head — the operator, and a Saved journeys control
/// 2. the route search — two stations, a swap, three day chips and Search
/// 3. **You are tracking** — one service, how far along it is, with Refresh
/// 4. **Today's departures** — the roster, with an All link
/// 5. **Popular routes** — three cards in a strip
///
/// *"Nothing here asks which country it is in: whether this destination is in
/// the tab set at all is the router's question, answered from the profile."*
/// The screen keeps that property — it takes a snapshot and draws it — and the
/// country gate lives in `LumeEligibility`, which the repository asks and the
/// router asks and search asks, so there is one answer rather than four.
library;

import 'package:flutter/material.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/widgets/lume/lume_destination.dart';
import '../../../core/widgets/lume/lume_explore.dart';
import '../../../core/widgets/lume/lume_rail.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_destination_cards.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../tools/presentation/tools_art.dart';
import '../domain/trains_model.dart';
import '../domain/trains_repository.dart';
import 'trains_art.dart';

/// What Trains can ask the shell to do.
@immutable
class LumeTrainsActions {
  const LumeTrainsActions({
    required this.openSaved,
    required this.chooseOrigin,
    required this.chooseDestination,
    required this.swap,
    required this.chooseDay,
    required this.search,
    required this.refresh,
    required this.openAllDepartures,
    required this.openService,
    required this.openRoute,
  });

  final VoidCallback openSaved;
  final VoidCallback chooseOrigin;
  final VoidCallback chooseDestination;
  final VoidCallback swap;
  final void Function(LumeJourneyDay day) chooseDay;
  final VoidCallback search;
  final Future<void> Function() refresh;
  final VoidCallback openAllDepartures;
  final void Function(LumeTrainService service) openService;
  final void Function(LumePopularRoute route) openRoute;
}

/// How the last query went.
///
/// Section-local on purpose (R3): a day that could not be fetched is a fact
/// about the departures list, not about the page, and the tracked service and
/// the route cards have nothing to do with it.
enum LumeQueryStatus {
  /// Showing what came back.
  settled,

  /// A search, a swap or a day change is in flight.
  busy,

  /// The journey asked for is not one — a missing end, or one station twice.
  invalid,

  /// It was a fair question and the answer did not arrive.
  failed,
}

/// The screen.
class LumeTrainsScreen extends StatelessWidget {
  const LumeTrainsScreen({
    super.key,
    required this.user,
    required this.actions,
    this.snapshot,
    this.failure,
    this.onRetry,
    this.status = LumeQueryStatus.settled,
  });

  final LumeUserContext user;
  final LumeTrainsActions actions;

  /// `null` until the first load returns.
  final LumeTrainsSnapshot? snapshot;

  /// Why nothing could be read. The reference has no such state; a feed does.
  final LumeTrainsFailure? failure;

  final Future<void> Function()? onRetry;

  /// What the route search is doing. See [LumeQueryStatus].
  final LumeQueryStatus status;

  /// Whether a query is in flight, and every control that would start another
  /// one is therefore inert. R2 and R3: *"prevent duplicate taps while a
  /// repository refresh is pending."*
  bool get isBusy => status == LumeQueryStatus.busy;

  /// Keys the tests and the bounds comparison address elements by.
  static const String headKey = 'trains.head';
  static const String searchKey = 'trains.search';
  static const String trackedKey = 'trains.tracked';
  static const String departuresKey = 'trains.departures';
  static const String routesKey = 'trains.routes';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: user.country,
    );
    final LumeTrainsSnapshot? s = snapshot;

    if (s == null) {
      return LumeDestinationPage(
        storageId: 'trains',
        semanticLabel: l.navTrains,
        slivers: <Widget>[
          SliverToBoxAdapter(child: _head(context, l, null)),
          SliverToBoxAdapter(
            child: failure == null
                ? const _TrainsSkeleton()
                : LumeMeasure(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: LumeNotice(
                        kind: failure == LumeTrainsFailure.unsupported
                            ? LumeNoticeKind.info
                            : LumeNoticeKind.error,
                        title: failure == LumeTrainsFailure.unsupported
                            ? l.trainsUnavailableTitle
                            : l.toolErrorTitle,
                        text: failure == LumeTrainsFailure.unsupported
                            ? l.toolUnavailableText
                            : l.toolErrorText,
                        actions: <Widget>[
                          if (onRetry != null &&
                              failure != LumeTrainsFailure.unsupported)
                            LumeNoticeAction(
                              label: l.actionTryAgain,
                              onPressed: () => onRetry!(),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      );
    }

    final LumeTrainsData d = s.data;

    return LumeDestinationPage(
      storageId: 'trains',
      semanticLabel: l.navTrains,
      onRefresh: onRetry,
      slivers: <Widget>[
        SliverToBoxAdapter(child: _head(context, l, d)),
        SliverToBoxAdapter(child: _search(context, l, d)),
        if (d.tracked != null)
          SliverToBoxAdapter(child: _tracked(context, l, f, d.tracked!))
        else if (s.of(LumeTrainsSource.tracked) ==
            LumeTrainsFreshness.unavailable)
          SliverToBoxAdapter(child: _trackedUnavailable(context, l)),
        if (status != LumeQueryStatus.settled)
          SliverToBoxAdapter(child: _departuresQuery(context, l, d))
        else if (d.departures.isNotEmpty)
          SliverToBoxAdapter(child: _departures(context, l, f, d))
        else
          SliverToBoxAdapter(child: _departuresEmpty(context, l, s, d)),
        if (d.routes.isNotEmpty)
          SliverToBoxAdapter(child: _routes(context, l, f, d)),
      ],
    );
  }

  // -- 1. the page head ----------------------------------------------------

  Widget _head(BuildContext context, AppLocalizations l, LumeTrainsData? d) =>
      KeyedSubtree(
        key: const ValueKey<String>(headKey),
        child: LumePageHead(
          title: l.navTrains,
          subtitle: l.trainsHeadSub(d?.operatorName ?? ''),
          action: LumeHeaderButton(
            icon: LumeIcons.bookmark,
            semanticLabel: l.trainsSaved,
            onTap: actions.openSaved,
          ),
        ),
      );

  // -- 2. the route search -------------------------------------------------

  Widget _search(BuildContext context, AppLocalizations l, LumeTrainsData d) =>
      KeyedSubtree(
        key: const ValueKey<String>(searchKey),
        child: LumePageSection(
          // `style="margin-top:18px"`, inline on this one section.
          topGap: 18,
          child: LumeMeasure(
            child: LumeRailSearchCard(
              art: const LumeRailSearchArt(),
              origin: LumeRailField(
                key: const ValueKey<String>('trains.origin'),
                label: l.trainsFrom,
                value: d.query.origin,
                semanticLabel: '${l.trainsFrom}, ${d.query.origin}',
                onTap: isBusy ? null : actions.chooseOrigin,
              ),
              destination: LumeRailField(
                key: const ValueKey<String>('trains.destination'),
                label: l.trainsTo,
                value: d.query.destination,
                semanticLabel: '${l.trainsTo}, ${d.query.destination}',
                onTap: isBusy ? null : actions.chooseDestination,
              ),
              swapLabel: l.trainsSwap,
              onSwap: isBusy ? null : actions.swap,
              chips: <LumeRailChip>[
                LumeRailChip(
                  key: const ValueKey<String>('trains.day.today'),
                  label: l.trainsToday,
                  semanticLabel: l.trainsToday,
                  selected: d.query.day == LumeJourneyDay.today,
                  onTap: isBusy
                      ? null
                      : () => actions.chooseDay(LumeJourneyDay.today),
                ),
                LumeRailChip(
                  key: const ValueKey<String>('trains.day.tomorrow'),
                  label: l.trainsTomorrow,
                  semanticLabel: l.trainsTomorrow,
                  selected: d.query.day == LumeJourneyDay.tomorrow,
                  onTap: isBusy
                      ? null
                      : () => actions.chooseDay(LumeJourneyDay.tomorrow),
                ),
                LumeRailChip(
                  key: const ValueKey<String>('trains.day.other'),
                  icon: LumeIcons.calendar,
                  semanticLabel: l.trainsPickDate,
                  selected: d.query.day == LumeJourneyDay.other,
                  onTap: isBusy
                      ? null
                      : () => actions.chooseDay(LumeJourneyDay.other),
                ),
              ],
              searchLabel: l.actionSearch,
              onSearch: isBusy ? null : actions.search,
            ),
          ),
        ),
      );

  // -- 3. the tracked service ----------------------------------------------

  Widget _tracked(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeTrackedTrain t,
  ) {
    final int age = t.minutesAgoAt(LumeClockScope.of(context).now());
    final String route = l.trainsRoute(t.from, t.to);
    final String status = _statusLabel(l, t.status, 0);
    final String percent = f.percent((t.progress * 100).round(), decimals: 0);

    return KeyedSubtree(
      key: const ValueKey<String>(trackedKey),
      child: LumePageSection(
        title: l.trainsTracking,
        // A literal in the reference; an age against the injected clock here,
        // so a real feed makes it true without changing the screen.
        subtitle: l.trainsUpdated(age),
        link: l.actionRefresh,
        linkIcon: LumeIcons.refresh,
        onLinkTap: () => actions.refresh(),
        child: LumeMeasure(
          child: LumeCard(
            child: LumeLiveTrainCard(
              number: t.number,
              name: t.name,
              route: route,
              progress: t.progress,
              status: LumeStatusPill(
                label: status,
                tone: _statusTone(t.status),
                // `.status .live` — only the tracked card has it, because only
                // this figure is being watched.
                live: true,
              ),
              stops: <LumeLiveTrainStop>[
                for (final LumeTrainStop stop in t.stops)
                  LumeLiveTrainStop(
                    lead: stop.minuteOfDay == null
                        ? l.trainsNow
                        : f.timetable(stop.minuteOfDay!),
                    station: stop.station,
                    isNow: stop.isNow,
                  ),
              ],
              semanticLabel: l.trainsTrackedSummary(
                t.name,
                t.number,
                route,
                status,
                percent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _trackedUnavailable(BuildContext context, AppLocalizations l) =>
      KeyedSubtree(
        key: const ValueKey<String>(trackedKey),
        child: LumePageSection(
          title: l.trainsTracking,
          child: LumeMeasure(
            child: LumeNotice(
              kind: LumeNoticeKind.offline,
              title: l.toolUnavailableTitle,
              text: l.toolErrorText,
              actions: <Widget>[
                if (onRetry != null)
                  LumeNoticeAction(
                    label: l.actionTryAgain,
                    onPressed: () => onRetry!(),
                  ),
              ],
            ),
          ),
        ),
      );

  // -- 4. today's departures -----------------------------------------------

  Widget _departures(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeTrainsData d,
  ) => KeyedSubtree(
    key: const ValueKey<String>(departuresKey),
    child: LumePageSection(
      title: l.trainsDepartures,
      subtitle: l.trainsDeparturesSub(d.departuresFrom),
      link: l.actionAll,
      onLinkTap: actions.openAllDepartures,
      child: LumeMeasure(
        child: LumeCard(
          padded: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < d.departures.length; i++)
                _serviceRow(context, l, f, d.departures[i], i, d),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _serviceRow(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeTrainService s,
    int index,
    LumeTrainsData d,
  ) {
    final String status = _statusLabel(l, s.status, s.delayMinutes);
    return LumeListRow(
      key: ValueKey<String>('trains.service.${s.number}'),
      icon: LumeIcons.train,
      title: s.name,
      titleTrailing: LumeTrainNumber(s.number),
      subtitle: l.trainsServiceLine(
        // Published timetable times, not the reader's clock: see
        // `LumeFormatting.timetable`.
        f.timetable(s.departMinute),
        f.timetable(s.arriveMinute),
        _duration(l, f, s.durationMinutes),
        f.money(s.fare),
      ),
      end: LumeStatusPill(label: status, tone: _statusTone(s.status)),
      isLast: index == d.departures.length - 1,
      onTap: () => actions.openService(s),
    );
  }

  /// The departures while a query is in flight, or after one that failed.
  ///
  /// Section-local: the tracked service above and the route cards below are
  /// unaffected by a day that could not be fetched.
  Widget _departuresQuery(
    BuildContext context,
    AppLocalizations l,
    LumeTrainsData d,
  ) => KeyedSubtree(
    key: const ValueKey<String>(departuresKey),
    child: LumePageSection(
      title: l.trainsDepartures,
      subtitle: l.trainsDeparturesSub(d.departuresFrom),
      child: LumeMeasure(
        child: switch (status) {
          LumeQueryStatus.busy => const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LumeSkeleton(kind: LumeSkeletonKind.row),
              SizedBox(height: LumeSpace.gapCard),
              LumeSkeleton(kind: LumeSkeletonKind.row),
              SizedBox(height: LumeSpace.gapCard),
              LumeSkeleton(kind: LumeSkeletonKind.row),
            ],
          ),
          LumeQueryStatus.invalid => LumeNotice(
            kind: LumeNoticeKind.warning,
            title: l.trainsRouteInvalidTitle,
            text: l.trainsRouteInvalidText,
          ),
          _ => LumeNotice(
            kind: LumeNoticeKind.error,
            title: l.toolErrorTitle,
            text: l.toolErrorText,
            actions: <Widget>[
              if (onRetry != null)
                LumeNoticeAction(
                  label: l.actionTryAgain,
                  onPressed: () => onRetry!(),
                ),
            ],
          ),
        },
      ),
    ),
  );

  Widget _departuresEmpty(
    BuildContext context,
    AppLocalizations l,
    LumeTrainsSnapshot s,
    LumeTrainsData d,
  ) => KeyedSubtree(
    key: const ValueKey<String>(departuresKey),
    child: LumePageSection(
      title: l.trainsDepartures,
      subtitle: l.trainsDeparturesSub(d.departuresFrom),
      child: LumeMeasure(
        child:
            s.of(LumeTrainsSource.departures) == LumeTrainsFreshness.unavailable
            ? LumeNotice(
                kind: LumeNoticeKind.offline,
                title: l.toolUnavailableTitle,
                text: l.toolErrorText,
                actions: <Widget>[
                  if (onRetry != null)
                    LumeNoticeAction(
                      label: l.actionTryAgain,
                      onPressed: () => onRetry!(),
                    ),
                ],
              )
            : LumeEmptyState(
                art: const LumeToolsEmptyArt(),
                title: l.trainsDepartures,
                text: l.trainsDeparturesSub(d.departuresFrom),
              ),
      ),
    ),
  );

  // -- 5. popular routes ---------------------------------------------------

  Widget _routes(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeTrainsData d,
  ) => KeyedSubtree(
    key: const ValueKey<String>(routesKey),
    child: LumePageSection(
      title: l.trainsPopular,
      subtitle: l.trainsPopularSub,
      child: LumeHorizontalStrip(
        children: <Widget>[
          for (final LumePopularRoute r in d.routes)
            LumeRouteCard(
              key: ValueKey<String>('trains.route.${r.fromCode}${r.toCode}'),
              fromCode: r.fromCode,
              toCode: r.toCode,
              meta:
                  '${_duration(l, f, r.durationMinutes)} · '
                  '${l.trainsCount(r.trainCount)}',
              // R4: `.routecard__fare` is the literal "from ₨ 2,400" — the
              // rupee *sign*, where the departures row two sections above
              // uses the abbreviation `L.moneyRaw` produces. Two symbols for
              // one currency on one screen, reproduced.
              fare: l.trainsFareFrom(f.rupeeSign(r.fromFare, decimals: 0)),
              semanticLabel: routeSummary(l, f, r),
              onTap: () => actions.openRoute(r),
            ),
        ],
      ),
    ),
  );

  // -- shared --------------------------------------------------------------

  /// What a route card says out loud, and what its toast repeats.
  ///
  /// One function rather than two, so the card a reader hears and the message
  /// they get after tapping it cannot drift apart.
  static String routeSummary(
    AppLocalizations l,
    LumeFormatting f,
    LumePopularRoute r,
  ) => l.trainsRouteToast(
    r.fromName,
    r.toName,
    l.trainsCount(r.trainCount),
    l.trainsFareFrom(f.rupeeSign(r.fromFare, decimals: 0)),
  );

  static String _duration(AppLocalizations l, LumeFormatting f, int minutes) =>
      l.trainsDuration(f.integer(minutes ~/ 60), f.integer(minutes % 60));

  static String _statusLabel(
    AppLocalizations l,
    LumeTrainStatus status,
    int delay,
  ) => switch (status) {
    LumeTrainStatus.onTime => l.trainsStatusOnTime,
    LumeTrainStatus.late_ => l.trainsStatusLate(delay),
    LumeTrainStatus.departed => l.trainsStatusDeparted,
  };

  static LumeStatusTone _statusTone(LumeTrainStatus status) => switch (status) {
    LumeTrainStatus.onTime || LumeTrainStatus.departed => LumeStatusTone.ok,
    LumeTrainStatus.late_ => LumeStatusTone.late_,
  };
}

/// Trains while it is still arriving.
class _TrainsSkeleton extends StatelessWidget {
  const _TrainsSkeleton();

  @override
  Widget build(BuildContext context) => LumeMeasure(
    child: Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const LumeSkeleton(kind: LumeSkeletonKind.metric),
          const SizedBox(height: LumeSpace.gapSection),
          const LumeSkeleton(kind: LumeSkeletonKind.metric),
          const SizedBox(height: LumeSpace.gapSection),
          for (int i = 0; i < 3; i++) ...<Widget>[
            const LumeSkeleton(kind: LumeSkeletonKind.row),
            const SizedBox(height: LumeSpace.gapCard),
          ],
        ],
      ),
    ),
  );
}

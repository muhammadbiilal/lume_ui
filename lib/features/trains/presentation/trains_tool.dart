/// Trains — the tool `trains.tool.js` draws, over the same roster the Trains
/// destination shows.
///
/// §33 gives Pakistan a first-class Trains destination (`trains_host.dart`,
/// `trains_screen.dart`), already built. That screen's "Today's departures"
/// row and a departure row's own header comment (`data-act="tool:trains"`)
/// both point here: a service opened from the destination — and Trains
/// wherever it sits in Tools, for a reader whose bottom navigation has no
/// Trains tab — lands on this richer board. Wiring `'trains'` into the tool
/// registry that resolves that route is a shared-file change outside this
/// directory, for whoever owns it centrally; what lives here is the screen
/// that opens once it is.
///
/// `tools/daily/trains.tool.js` over `tool-data.js` `TRAINS`/`TRAIN_STOPS`
/// (reached in Flutter through `LumeTrainsComposer`, so a fare or a status
/// cannot read differently here than on the destination): a from/to search
/// that mirrors the tracked service's own endpoints, how many services are
/// running and how many are on time or delayed, a status filter, a
/// departures list, the tracked service's journey and speed/next-stop/delay
/// figures, its route on the map, the fixed station timeline the reference
/// draws under every service, its fares, and reminding on it or sharing it.
/// The status filter and the tracked service live in the tool session.
///
/// Kept as the reference has it (C73): the from/to fields never do anything
/// but mirror the tracked service's endpoints, and "Find trains" always shows
/// the same toast regardless of what they read — so this port draws them
/// read-only rather than as search fields with nothing behind them. The
/// station timeline is the reference's one fixed list, shown under whichever
/// service is selected. For a reader whose country has no rail network in
/// `LumeTrainsComposer.operatorFor`, the screen says so rather than showing
/// Pakistan's — the same `trainsUnavailableTitle` the destination uses for the
/// same reason.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_journey.dart';
import '../../../core/widgets/lume/lume_map.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/trains_fixtures.dart';
import '../domain/trains_model.dart';
import 'trains_strings.dart';

class LumeTrainsTool extends ConsumerStatefulWidget {
  const LumeTrainsTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeTrainsTool(request: request);

  static const String id = 'trains';

  static const Key contextKey = ValueKey<String>('trains.context');
  static const Key searchKey = ValueKey<String>('trains.search');
  static const Key metricsKey = ValueKey<String>('trains.metrics');
  static const Key filterKey = ValueKey<String>('trains.filter');
  static const Key boardKey = ValueKey<String>('trains.board');
  static const Key emptyKey = ValueKey<String>('trains.empty');
  static const Key unavailableKey = ValueKey<String>('trains.unavailable');
  static const Key journeyKey = ValueKey<String>('trains.journey');
  static const Key detailMetricsKey = ValueKey<String>('trains.detailMetrics');
  static const Key mapKey = ValueKey<String>('trains.map');
  static const Key stopsKey = ValueKey<String>('trains.stops');
  static const Key faresKey = ValueKey<String>('trains.fares');
  static const Key actionsKey = ValueKey<String>('trains.actions');

  /// `M8 84 C 30 70, 40 44, 62 30 S 88 14, 94 8`, reshaped as one cubic run.
  static const LumeMapRoute route = LumeMapRoute(
    Offset(8, 84),
    Offset(30, 70),
    Offset(62, 20),
    Offset(94, 8),
  );

  /// `L.speed(kmh)`.
  static String speed(AppLocalizations l, LumeFormatting f, int kmh) =>
      '${f.speed(kmh)} ${f.units == LumeUnits.imperial ? l.unitMph : l.unitKmh}';

  /// `L.distance(km)` — rounded, a tenth under ten, metres under one, and
  /// written without grouping, as the reference writes it (C73).
  static String distance(AppLocalizations l, LumeFormatting f, num km) {
    if (f.units == LumeUnits.imperial) {
      final double mi = km * 0.621;
      return '${mi < 10 ? mi.toStringAsFixed(1) : mi.round()} ${l.unitMi}';
    }
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km < 10 ? km.toStringAsFixed(1) : km.round()} ${l.unitKm}';
  }

  /// `l.trainsDuration(h, m)`.
  static String duration(AppLocalizations l, LumeFormatting f, int minutes) =>
      l.trainsDuration(f.integer(minutes ~/ 60), f.integer(minutes % 60));

  @override
  ConsumerState<LumeTrainsTool> createState() => _LumeTrainsToolState();
}

class _LumeTrainsToolState extends ConsumerState<LumeTrainsTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);

  String get _status => _session.read(LumeTrainsTool.id, 'status') ?? 'all';

  void _write(String key, String value) =>
      setState(() => _session.write(LumeTrainsTool.id, key, value));

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final DateTime now = LumeClockScope.of(context).now();

    // The same market gate the repository asks for the destination (§64):
    // hidden where there is no operator, rather than showing Pakistan's.
    final String operatorName = LumeTrainsComposer.operatorFor(r.user.country);

    if (operatorName.isEmpty) {
      return LumeToolScreen(
        key: _host,
        feature: r.feature,
        user: r.user,
        onBack: r.onBack,
        onOpenRelated: r.onOpenRelated,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            LumeToolSection(
              flush: true,
              child: LumeContextBar(
                key: LumeTrainsTool.contextKey,
                items: <LumeContextItem>[
                  LumeContextItem(
                    label: r.user.city,
                    icon: LumeIcons.pin,
                    onTap: () => showLumePersonalise(context),
                  ),
                ],
              ),
            ),
            LumeToolSection(
              child: LumeToolState(
                key: LumeTrainsTool.unavailableKey,
                icon: LumeIcons.train,
                title: l.trainsUnavailableTitle,
                text: l.toolUnavailableText,
              ),
            ),
          ],
        ),
      );
    }

    final List<LumeTrainService> all = LumeTrainsComposer.departures(
      '',
      on: now,
    );
    final String selected =
        _session.read(LumeTrainsTool.id, 'train') ?? all.first.number;
    final LumeTrainService train = all.firstWhere(
      (LumeTrainService x) => x.number == selected,
      orElse: () => all.first,
    );
    final String status = _status;
    final List<LumeTrainService> shown = LumeTrainsComposer.filterByStatus(
      all,
      status: status,
    );
    final int onTime = all.where((LumeTrainService x) => !x.isLate).length;

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      // The reference shares an unrelated quote (C68); this is the tracked
      // service, its route and when it arrives.
      shareCard: () => LumeShareCard.forFeature(
        sensitive: r.feature.sensitive,
        kind: LumeShareKind.quote,
        text: l.trainsShareText(
          train.name,
          train.from,
          train.to,
          f.timetable(train.arriveMinute),
        ),
        source: '${train.number} · ${f.dateLong(now)}',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            flush: true,
            child: LumeContextBar(
              key: LumeTrainsTool.contextKey,
              items: <LumeContextItem>[
                LumeContextItem(
                  label: r.user.city,
                  icon: LumeIcons.pin,
                  onTap: () => showLumePersonalise(context),
                ),
                LumeContextItem(label: operatorName),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        key: LumeTrainsTool.searchKey,
                        child: LumeToolField(
                          label: l.trainsFrom,
                          value: train.from,
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LumeToolField(
                          label: l.trainsTo,
                          value: train.to,
                          enabled: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LumeButtonRow(
                    children: <Widget>[
                      LumeButton.accent(
                        label: l.trainsFind,
                        icon: LumeIcons.search,
                        block: true,
                        onPressed: () =>
                            _host.currentState?.say(l.trainsSearching),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            child: LumeMetrics(
              key: LumeTrainsTool.metricsKey,
              columns: 3,
              children: <Widget>[
                LumeMetric(
                  value: f.integer(all.length),
                  label: l.trainsRunning,
                ),
                LumeMetric(
                  value: f.integer(onTime),
                  label: l.trainsStatusOnTime,
                ),
                LumeMetric(
                  value: f.integer(all.length - onTime),
                  label: l.trainsDelayed,
                ),
              ],
            ),
          ),
          LumeToolSection(
            spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
            child: LumeFilterBar(
              key: LumeTrainsTool.filterKey,
              children: <Widget>[
                LumeFilterChip(
                  label: l.commonAll,
                  selected: status == 'all',
                  onTap: () => _write('status', 'all'),
                ),
                LumeFilterChip(
                  label: l.trainsStatusOnTime,
                  selected: status == 'ontime',
                  onTap: () => _write('status', 'ontime'),
                ),
                LumeFilterChip(
                  label: l.trainsDelayed,
                  selected: status == 'late',
                  onTap: () => _write('status', 'late'),
                ),
              ],
            ),
          ),
          LumeToolSection(
            spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
            title: l.trainsDepartures,
            child: shown.isEmpty
                ? LumeToolState(
                    key: LumeTrainsTool.emptyKey,
                    icon: LumeIcons.train,
                    title: l.trainsNoMatch,
                    text: l.trainsNoMatchText,
                    action: LumeButton(
                      label: l.commonAll,
                      icon: LumeIcons.refresh,
                      onPressed: () => _write('status', 'all'),
                    ),
                  )
                : LumeRows(
                    key: LumeTrainsTool.boardKey,
                    children: <Widget>[
                      for (final LumeTrainService x in shown)
                        LumeRichRow(
                          logo: x.code,
                          iconTone: x.isLate
                              ? context.lume.toneAmber
                              : context.lume.tintAccent,
                          title: x.name,
                          subtitle: '${x.from} → ${x.to}',
                          meta: <String>[
                            '${f.timetable(x.departMinute)} – '
                                '${f.timetable(x.arriveMinute)}',
                            LumeTrainsTool.duration(l, f, x.durationMinutes),
                            '${l.trainsPlatform} ${x.platform}',
                          ],
                          badge: LumeBadge(
                            label: LumeTrainsStrings.status(l, x),
                            tone: LumeTrainsStrings.tone(x),
                          ),
                          value: f.money(x.fare),
                          valueSub: l.trainsFareCaption,
                          selected: x.number == train.number,
                          onTap: () => _write('train', x.number),
                        ),
                    ],
                  ),
          ),
          LumeToolSection(
            title: l.trainsSelected(train.name),
            child: LumeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  LumeJourney(
                    key: LumeTrainsTool.journeyKey,
                    fromCode: train.fromCode,
                    from: train.from,
                    fromTime: f.timetable(train.departMinute),
                    toCode: train.toCode,
                    to: train.to,
                    toTime: f.timetable(train.arriveMinute),
                    remaining: LumeTrainsTool.duration(
                      l,
                      f,
                      train.durationMinutes,
                    ),
                    progress: train.progress,
                    icon: LumeIcons.train,
                  ),
                  const SizedBox(height: 16),
                  LumeMetrics(
                    key: LumeTrainsTool.detailMetricsKey,
                    columns: 3,
                    children: <Widget>[
                      LumeMetric(
                        value: LumeTrainsTool.speed(l, f, train.speedKmh),
                        label: l.trainsSpeed,
                      ),
                      LumeMetric(value: train.next, label: l.trainsNextStop),
                      LumeMetric(
                        value: train.isLate
                            ? l.trainsStatusLate(train.delayMinutes)
                            : l.trainsStatusOnTime,
                        label: l.trainsDelay,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            child: LumeMap(
              key: LumeTrainsTool.mapKey,
              label: l.trainsMap,
              caption: '${train.from} → ${train.to}',
              route: LumeTrainsTool.route,
              pins: <LumeMapPin>[
                LumeMapPin(x: 8, y: 84, icon: LumeIcons.pin, label: train.from),
                LumeMapPin(
                  x: 8 + (94 - 8) * train.progress,
                  y: 84 - (84 - 8) * train.progress,
                  icon: LumeIcons.train,
                  label: train.name,
                  active: true,
                ),
                LumeMapPin(x: 94, y: 8, icon: LumeIcons.pin, label: train.to),
              ],
            ),
          ),
          LumeToolSection(
            title: l.trainsStops,
            child: LumeTimeline(
              key: LumeTrainsTool.stopsKey,
              entries: <LumeTimelineEntry>[
                for (final LumeTrainTimelineStop s
                    in LumeTrainsComposer.timelineStops())
                  LumeTimelineEntry(
                    time: f.timetable(s.scheduledMinute),
                    title: s.name,
                    subtitle: s.actualMinute != null
                        ? l.trainsActual(f.timetable(s.actualMinute!))
                        : l.trainsScheduled,
                    meta: LumeTrainsTool.distance(l, f, s.km),
                    state: switch (s.state) {
                      LumeTrainTimelineState.done => LumeTimelineState.done,
                      LumeTrainTimelineState.now => LumeTimelineState.now,
                      LumeTrainTimelineState.next => LumeTimelineState.upcoming,
                    },
                  ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.trainsFares,
            child: LumeTable(
              key: LumeTrainsTool.faresKey,
              label: l.trainsFares,
              columns: <LumeColumn>[
                LumeColumn(label: l.trainsClass),
                LumeColumn(label: l.trainsFare, numeric: true),
                LumeColumn(label: l.trainsSeats, numeric: true),
              ],
              rows: <List<String>>[
                for (int i = 0; i < train.classes.length; i++)
                  <String>[
                    train.classes[i],
                    f.money(LumeTrainsComposer.fareForTier(train, i)),
                    f.integer(LumeTrainsComposer.seatsForTier(i)),
                  ],
              ],
            ),
          ),
          LumeToolSection(
            child: LumeButtonRow(
              key: LumeTrainsTool.actionsKey,
              children: <Widget>[
                LumeButton.accent(
                  label: l.trainsRemind,
                  icon: LumeIcons.bell,
                  onPressed: () =>
                      _host.currentState?.say(l.trainsReminded(train.name)),
                ),
                LumeButton(
                  label: l.commonShare,
                  icon: LumeIcons.share,
                  onPressed: () => _host.currentState?.share(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

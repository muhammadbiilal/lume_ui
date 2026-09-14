/// Flights — the reference tool for the tracking archetype.
///
/// `tools/daily/flights.tool.js` over `tool-data.js` `FLIGHTS`: a search, the
/// board's view, how many flights there are and how many are moving or late,
/// where the chosen flight is, the board, the chosen flight's journey, its
/// aircraft, its timeline, and tracking and sharing it. The view, the query
/// and the chosen flight live in the tool session.
///
/// Kept as the reference has it (C73): Arrivals lists every flight, Departures
/// every flight still to land, Tracked the flights en route; distances are
/// written without grouping; "Track this flight" says so and keeps nothing.
/// Corrected: the empty board's Arrivals action clears the search it is
/// offering an alternative to, and the map's pins are not controls.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_field.dart';
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
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/flights_fixtures.dart';
import 'flights_strings.dart';

class LumeFlightsTool extends ConsumerStatefulWidget {
  const LumeFlightsTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeFlightsTool(request: request);

  static const String id = 'flights';

  static const Key searchKey = ValueKey<String>('flights.search');
  static const Key viewKey = ValueKey<String>('flights.view');
  static const Key metricsKey = ValueKey<String>('flights.metrics');
  static const Key mapKey = ValueKey<String>('flights.map');
  static const Key boardKey = ValueKey<String>('flights.board');
  static const Key emptyKey = ValueKey<String>('flights.empty');
  static const Key journeyKey = ValueKey<String>('flights.journey');
  static const Key aircraftKey = ValueKey<String>('flights.aircraft');
  static const Key timelineKey = ValueKey<String>('flights.timeline');
  static const Key actionsKey = ValueKey<String>('flights.actions');

  /// `M10 78 C 34 50, 58 30, 90 16`.
  static const LumeMapRoute route = LumeMapRoute(
    Offset(10, 78),
    Offset(34, 50),
    Offset(58, 30),
    Offset(90, 16),
  );

  /// What a view and a query leave, in board order.
  static List<LumeFlight> board(
    List<LumeFlight> flights, {
    required String view,
    required String query,
  }) {
    final String q = query.trim().toLowerCase();
    return <LumeFlight>[
      for (final LumeFlight f in flights)
        if (switch (view) {
          'departures' => f.fromCode != f.toCode && f.progress < 1,
          // `favourites.indexOf('flights') !== -1 || f.tone2 === 'live'` —
          // no reader here has favourited the tool, so it is the live ones.
          'tracked' => f.live,
          _ => true,
        })
          if (q.isEmpty ||
              <String>[
                f.no,
                f.airline,
                f.from,
                f.to,
                f.fromCode,
                f.toCode,
              ].join(' ').toLowerCase().contains(q))
            f,
    ];
  }

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

  /// `L.speed(kmh)`.
  static String speed(AppLocalizations l, LumeFormatting f, int kmh) =>
      '${f.speed(kmh)} ${f.units == LumeUnits.imperial ? l.unitMph : l.unitKmh}';

  static Color toneOf(LumeColors lume, LumeAirlineTone t) => switch (t) {
    LumeAirlineTone.rose => lume.tone(lume.rose),
    LumeAirlineTone.green => lume.toneGreen,
    LumeAirlineTone.violet => lume.tone(lume.violet),
    LumeAirlineTone.amber => lume.toneAmber,
    LumeAirlineTone.indigo => lume.tone(lume.indigo),
  };

  @override
  ConsumerState<LumeFlightsTool> createState() => _LumeFlightsToolState();
}

class _LumeFlightsToolState extends ConsumerState<LumeFlightsTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(
    text: _session.read(LumeFlightsTool.id, 'q') ?? '',
  );
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _query.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  String get _view => _session.read(LumeFlightsTool.id, 'view') ?? 'arrivals';

  void _write(String key, String value) =>
      setState(() => _session.write(LumeFlightsTool.id, key, value));

  /// The empty board's action: back to Arrivals, and the search that emptied
  /// it cleared — the reference changes only the view, which was already
  /// Arrivals, so the action did nothing (C73).
  void _showArrivals() {
    _query.clear();
    setState(() {
      _session.write(LumeFlightsTool.id, 'q', '');
      _session.write(LumeFlightsTool.id, 'view', 'arrivals');
    });
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final DateTime now = LumeClockScope.of(context).now();
    final double gutter = LumeLayout.pageGutter(context.measureClass);
    const List<LumeFlight> all = LumeFlightBoard.flights;

    final String selected =
        _session.read(LumeFlightsTool.id, 'flight') ?? all.first.no;
    final LumeFlight fl = all.firstWhere(
      (LumeFlight x) => x.no == selected,
      orElse: () => all.first,
    );
    final String view = _view;
    final List<LumeFlight> board = LumeFlightsTool.board(
      all,
      view: view,
      query: _query.text,
    );
    final String altitude = l.flightsAltitudeFeet(f.number(fl.alt));
    final String groundSpeed = LumeFlightsTool.speed(l, f, fl.speed);

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      actions: LumeToolActions(onSearch: _searchFocus.requestFocus),
      // The reference shares an unrelated quote (C68); this is the chosen
      // flight, where it is going and when.
      shareCard: () => LumeShareCard.forFeature(
        sensitive: r.feature.sensitive,
        kind: LumeShareKind.quote,
        text: l.flightsShareText(fl.no, fl.fromCode, fl.toCode, fl.eta),
        source: '${fl.airline} · ${f.dateLong(now)}',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // The same second gutter as the other tools' search fields (C69).
          LumeToolSection(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: LumeSearchField(
                key: LumeFlightsTool.searchKey,
                controller: _query,
                focusNode: _searchFocus,
                placeholder: l.flightsSearch,
                onChanged: (String q) => _write('q', q),
              ),
            ),
          ),
          LumeToolSection(
            child: LumeSegmented(
              key: LumeFlightsTool.viewKey,
              semanticLabel: l.flightsBoard,
              value: view,
              onChanged: (String v) => _write('view', v),
              items: <LumeChoice>[
                LumeChoice(value: 'arrivals', label: l.flightsArrivals),
                LumeChoice(value: 'departures', label: l.flightsDepartures),
                LumeChoice(value: 'tracked', label: l.flightsTracked),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeMetrics(
              key: LumeFlightsTool.metricsKey,
              columns: 3,
              children: <Widget>[
                LumeMetric(value: f.integer(all.length), label: l.flightsTotal),
                LumeMetric(
                  value: f.integer(
                    all
                        .where(
                          (LumeFlight x) =>
                              x.status == LumeFlightStatus.enroute,
                        )
                        .length,
                  ),
                  label: l.flightsEnRoute,
                ),
                LumeMetric(
                  value: f.integer(
                    all.where((LumeFlight x) => x.delay > 0).length,
                  ),
                  label: l.flightsDelayed,
                ),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeMap(
              key: LumeFlightsTool.mapKey,
              tall: true,
              label: l.flightsMap,
              caption: '${fl.fromCode} → ${fl.toCode}',
              route: LumeFlightsTool.route,
              pins: <LumeMapPin>[
                LumeMapPin(x: 10, y: 78, icon: LumeIcons.pin, label: fl.from),
                LumeMapPin(
                  x: 10 + 80 * fl.progress,
                  y: 78 - 62 * fl.progress,
                  icon: LumeIcons.plane,
                  label: fl.no,
                  active: true,
                ),
                LumeMapPin(x: 90, y: 16, icon: LumeIcons.pin, label: fl.to),
              ],
            ),
          ),
          LumeToolSection(
            title: l.flightsLive,
            child: board.isEmpty
                ? LumeToolState(
                    key: LumeFlightsTool.emptyKey,
                    icon: LumeIcons.plane,
                    title: l.flightsNoMatch,
                    text: l.flightsNoMatchText,
                    action: LumeButton(
                      label: l.flightsArrivals,
                      icon: LumeIcons.refresh,
                      onPressed: _showArrivals,
                    ),
                  )
                : LumeRows(
                    key: LumeFlightsTool.boardKey,
                    children: <Widget>[
                      for (final LumeFlight x in board)
                        LumeRichRow(
                          logo: x.logo,
                          iconTone: LumeFlightsTool.toneOf(
                            context.lume,
                            x.tone,
                          ),
                          title: x.no,
                          badge: LumeBadge(
                            label: LumeFlightsStrings.status(l, x.status),
                            tone: x.status.badge,
                          ),
                          subtitle: '${x.airline} · ${x.craft}',
                          // "→" comes from a fallback face whose line is 14 (C73).
                          metaLineHeight: 14 / 10,
                          meta: <String>[
                            '${x.fromCode} → ${x.toCode}',
                            l.flightsGate(x.gate),
                            if (x.delay > 0)
                              l.flightsLateShort(x.delay)
                            else
                              l.flightsOnTime,
                          ],
                          value: x.arr,
                          valueSub: x.delay > 0
                              ? l.flightsEta(x.eta)
                              : l.flightsScheduled,
                          selected: x.no == fl.no,
                          onTap: () => _write('flight', x.no),
                        ),
                    ],
                  ),
          ),
          LumeToolSection(
            title: '${fl.no} · ${fl.airline}',
            child: LumeCard(
              child: LumeJourney(
                key: LumeFlightsTool.journeyKey,
                fromCode: fl.fromCode,
                from: fl.from,
                fromTime: fl.actual,
                toCode: fl.toCode,
                to: fl.to,
                toTime: fl.eta,
                remaining: l.flightsRemaining(
                  LumeFlightsTool.distance(
                    l,
                    f,
                    (fl.dist * (1 - fl.progress)).round(),
                  ),
                ),
                progress: fl.progress,
              ),
            ),
          ),
          LumeToolSection(
            title: l.flightsAircraft,
            child: LumeTable(
              key: LumeFlightsTool.aircraftKey,
              label: l.flightsAircraft,
              columns: <LumeColumn>[
                LumeColumn(label: l.commonField),
                LumeColumn(label: l.commonValue, numeric: true),
              ],
              rows: <List<String>>[
                <String>[l.flightsType, fl.craft],
                <String>[l.flightsRegistration, fl.reg],
                <String>[l.flightsAltitude, altitude],
                <String>[l.flightsSpeed, groundSpeed],
                <String>[
                  l.flightsDistance,
                  LumeFlightsTool.distance(l, f, fl.dist),
                ],
                <String>[
                  l.flightsTerminal,
                  l.flightsTerminalGate(fl.term, fl.gate),
                ],
              ],
            ),
          ),
          LumeToolSection(
            title: l.flightsTimeline,
            child: LumeTimeline(
              key: LumeFlightsTool.timelineKey,
              entries: <LumeTimelineEntry>[
                LumeTimelineEntry(
                  time: fl.dep,
                  title: l.flightsScheduledDep,
                  subtitle: fl.from,
                  state: LumeTimelineState.done,
                ),
                LumeTimelineEntry(
                  time: fl.actual,
                  title: l.flightsActualDep,
                  subtitle: fl.delay > 0
                      ? l.flightsLateBy(fl.delay)
                      : l.flightsOnTime,
                  state: LumeTimelineState.done,
                ),
                LumeTimelineEntry(
                  time: '—',
                  title: l.flightsCruise,
                  subtitle: l.flightsCruiseSub(altitude, groundSpeed),
                  state: fl.progress < 1
                      ? LumeTimelineState.now
                      : LumeTimelineState.done,
                ),
                LumeTimelineEntry(
                  time: fl.eta,
                  title: l.flightsEstArrival,
                  subtitle: fl.to,
                  state: fl.progress >= 1
                      ? LumeTimelineState.done
                      : LumeTimelineState.upcoming,
                ),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeButtonRow(
              key: LumeFlightsTool.actionsKey,
              children: <Widget>[
                LumeButton.accent(
                  label: l.flightsTrack,
                  icon: LumeIcons.bell,
                  onPressed: () =>
                      _host.currentState?.say(l.flightsTracking(fl.no)),
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

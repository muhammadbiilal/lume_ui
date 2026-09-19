/// Sun & Moon — `tools/daily/sunmoon.tool.js`, a context dashboard on the
/// Weather reference's composition: the city bar, a summary card, and a
/// timeline of the day.
///
/// Worked out for the reader's city ([LumeSky]), at its coordinates in
/// Lume's city table, on the reader's clock — never read from a fixture,
/// never inferred from language, religion or time zone, and never from the
/// device's position (there is no location service here). A city the table
/// does not carry, or a zone this build cannot read, is said, not guessed.
///
/// What differs from the reference (C86): dawn and dusk are civil twilight,
/// not an hour either side of sunrise and sunset; a day with no sunrise or no
/// sunset says so rather than showing 06:00 and 18:00; dawn is not "done"
/// before it happens, and the next event on the timeline is the one marked
/// now.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../app/providers/time_zone_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/time/lume_sky.dart';
import '../../../core/time/lume_solar.dart';
import '../../../core/time/lume_zone.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';

/// The day at the reader's city, or why there is none.
@immutable
class LumeSkyBoard {
  const LumeSkyBoard({
    required this.sun,
    required this.moon,
    required this.minute,
  });

  final LumeSunDay sun;
  final LumeMoon moon;

  /// Now, in hours of the reader's day.
  final double minute;

  /// `null` with [missing] set when it cannot be worked out.
  /// The place ([country], [city]) and the zone are separate inputs: the
  /// sun is worked out at the city's coordinates, and read on the reader's
  /// resolved zone — never a zone guessed from the place.
  static (LumeSkyBoard?, LumeSkyMissing?) at({
    required DateTime now,
    required String country,
    required String city,
    required LumeZoneResolution zone,
  }) {
    final (double, double)? at = LumeSolar.coordsFor(country, city);
    if (at == null) return (null, LumeSkyMissing.city);
    final LumeZone? z = zone.zone;
    if (z == null) return (null, LumeSkyMissing.zone);
    return _on(now, at, z);
  }

  static (LumeSkyBoard?, LumeSkyMissing?) _on(
    DateTime now,
    (double, double) at,
    LumeZone zone,
  ) {
    final DateTime local = zone.wallClockAt(now);
    return (
      LumeSkyBoard(
        sun: LumeSky.sun(
          date: local,
          lat: at.$1,
          lon: at.$2,
          offsetHours: zone.offsetAt(now).inMinutes / 60,
        ),
        moon: LumeSky.moon(now),
        minute: local.hour + local.minute / 60,
      ),
      null,
    );
  }
}

enum LumeSkyMissing { city, zone }

/// One stop on the day's timeline.
@immutable
class LumeSkyEvent {
  const LumeSkyEvent(this.kind, this.at);

  final LumeSkyEventKind kind;

  /// Hours of the day, or `null` where it does not happen.
  final double? at;
}

enum LumeSkyEventKind { dawn, sunrise, noon, sunset, dusk }

class LumeSunmoonTool extends ConsumerStatefulWidget {
  const LumeSunmoonTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeSunmoonTool(request: request);

  static const String id = 'sunmoon';

  static const Key contextKey = ValueKey<String>('sunmoon.context');
  static const Key summaryKey = ValueKey<String>('sunmoon.summary');
  static const Key timelineKey = ValueKey<String>('sunmoon.timeline');
  static const Key missingKey = ValueKey<String>('sunmoon.missing');

  /// The five stops, in order; a stop that does not happen is kept, with no
  /// time, so the reader sees what is missing and why.
  static List<LumeSkyEvent> events(LumeSunDay sun) => <LumeSkyEvent>[
    LumeSkyEvent(LumeSkyEventKind.dawn, sun.dawn),
    LumeSkyEvent(LumeSkyEventKind.sunrise, sun.sunrise),
    LumeSkyEvent(LumeSkyEventKind.noon, sun.noon),
    LumeSkyEvent(LumeSkyEventKind.sunset, sun.sunset),
    LumeSkyEvent(LumeSkyEventKind.dusk, sun.dusk),
  ];

  /// Past is done; the first stop still to come is now; the rest wait.
  static List<LumeTimelineState> states(
    List<LumeSkyEvent> events,
    double minute,
  ) {
    final List<LumeTimelineState> out = <LumeTimelineState>[];
    bool marked = false;
    for (final LumeSkyEvent e in events) {
      if (e.at != null && e.at! <= minute) {
        out.add(LumeTimelineState.done);
      } else if (e.at != null && !marked) {
        marked = true;
        out.add(LumeTimelineState.now);
      } else {
        out.add(LumeTimelineState.upcoming);
      }
    }
    return out;
  }

  /// Minutes of daylight as the caption reads them: set minus rise, each
  /// rounded to the minute first, so the two figures always agree.
  static int daylightMinutes(LumeSunDay sun) {
    int at(double hours) {
      final (int h, int m) = LumeSky.clock(hours);
      return h * 60 + m;
    }

    return switch (sun.kind) {
      LumeSunKind.polarDay => 24 * 60,
      LumeSunKind.polarNight => 0,
      LumeSunKind.normal => at(sun.sunset!) - at(sun.sunrise!),
    };
  }

  static String moonPhase(AppLocalizations l, LumeMoonPhase p) => switch (p) {
    LumeMoonPhase.newMoon => l.moonNew,
    LumeMoonPhase.waxingCrescent => l.moonWaxCrescent,
    LumeMoonPhase.firstQuarter => l.moonFirstQuarter,
    LumeMoonPhase.waxingGibbous => l.moonWaxGibbous,
    LumeMoonPhase.full => l.moonFull,
    LumeMoonPhase.waningGibbous => l.moonWanGibbous,
    LumeMoonPhase.lastQuarter => l.moonLastQuarter,
    LumeMoonPhase.waningCrescent => l.moonWanCrescent,
  };

  /// `duration.hm` — "12h 05m".
  static String span(AppLocalizations l, int minutes) => l.durationHm(
    '${minutes ~/ 60}',
    (minutes % 60).toString().padLeft(2, '0'),
  );

  @override
  ConsumerState<LumeSunmoonTool> createState() => _LumeSunmoonToolState();
}

class _LumeSunmoonToolState extends ConsumerState<LumeSunmoonTool> {
  String _clock(LumeFormatting f, double hours) {
    final (int h, int m) = LumeSky.clock(hours);
    return f.time(DateTime(2000, 1, 1, h, m));
  }

  String _label(AppLocalizations l, LumeSkyEventKind k) => switch (k) {
    LumeSkyEventKind.dawn => l.sunDawn,
    LumeSkyEventKind.sunrise => l.sunSunrise,
    LumeSkyEventKind.noon => l.sunNoon,
    LumeSkyEventKind.sunset => l.sunSunset,
    LumeSkyEventKind.dusk => l.sunDusk,
  };

  String? _note(AppLocalizations l, LumeSunDay sun, LumeSkyEvent e) {
    final bool twilight =
        e.kind == LumeSkyEventKind.dawn || e.kind == LumeSkyEventKind.dusk;
    if (e.at == null) {
      if (twilight) return l.sunNoTwilight;
      return sun.kind == LumeSunKind.polarDay ? l.sunPolarDay : l.sunPolarNight;
    }
    if (e.kind == LumeSkyEventKind.dawn) return l.sunDawnNote;
    if (e.kind == LumeSkyEventKind.dusk) return l.sunDuskNote;
    return null;
  }

  String _caption(AppLocalizations l, LumeFormatting f, LumeSunDay sun) =>
      switch (sun.kind) {
        LumeSunKind.polarDay => l.sunPolarDay,
        LumeSunKind.polarNight => l.sunPolarNight,
        LumeSunKind.normal => l.sunRange(
          _clock(f, sun.sunrise!),
          _clock(f, sun.sunset!),
        ),
      };

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final DateTime now = LumeClockScope.of(context).now();
    final LumeStartupState startup = ref.watch(startupControllerProvider).state;
    final LumeZoneResolution zone = ref
        .watch(timeZoneServiceProvider)
        .readerZone(startup, r.user.country, ref.watch(deviceZoneProvider));
    final (LumeSkyBoard? board, LumeSkyMissing? missing) = LumeSkyBoard.at(
      now: now,
      country: r.user.country,
      city: r.user.city,
      zone: zone,
    );
    final String zoneLabel = zone.canonicalId ?? zone.requested ?? '';

    return LumeToolScreen(
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      shareCard: board == null
          ? null
          : () => LumeShareCard.forFeature(
              sensitive: r.feature.sensitive,
              kind: LumeShareKind.reminder,
              text:
                  '${l.sunDaylength} ${LumeSunmoonTool.span(l, LumeSunmoonTool.daylightMinutes(board.sun))} · '
                  '${_caption(l, f, board.sun)}',
              source: l.sunShareSource(r.user.city, f.dateShort(now)),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            flush: true,
            child: LumeContextBar(
              key: LumeSunmoonTool.contextKey,
              items: <LumeContextItem>[
                LumeContextItem(label: r.user.city, icon: LumeIcons.pin),
              ],
            ),
          ),
          if (board == null)
            LumeToolSection(
              child: LumeToolState(
                key: LumeSunmoonTool.missingKey,
                icon: LumeIcons.sun,
                title: switch (missing) {
                  LumeSkyMissing.city => l.sunNoCityTitle(r.user.city),
                  _ when zoneLabel.isEmpty => l.recZoneUnknownTitle,
                  _ => l.sunNoZoneTitle('\u2068$zoneLabel\u2069'),
                },
                text: switch (missing) {
                  LumeSkyMissing.city => l.sunNoCityText,
                  _ when zoneLabel.isEmpty => l.recZoneMissingText,
                  _ => l.sunNoZoneText,
                },
              ),
            )
          else
            ..._board(l, f, board),
        ],
      ),
    );
  }

  List<Widget> _board(
    AppLocalizations l,
    LumeFormatting f,
    LumeSkyBoard board,
  ) {
    final LumeSunDay sun = board.sun;
    final List<LumeSkyEvent> events = LumeSunmoonTool.events(sun);
    final List<LumeTimelineState> states = LumeSunmoonTool.states(
      events,
      board.minute,
    );
    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeSunmoonTool.summaryKey,
          kicker: l.sunDaylength,
          value: LumeSunmoonTool.span(l, LumeSunmoonTool.daylightMinutes(sun)),
          caption: _caption(l, f, sun),
          stats: <LumeStat>[
            LumeStat(
              value: LumeSunmoonTool.moonPhase(l, board.moon.phase),
              label: l.sunMoon,
            ),
            LumeStat(
              value: '${f.integer(board.moon.lit)}%',
              label: l.sunIllumination,
            ),
            LumeStat(value: _clock(f, sun.noon), label: l.sunNoon),
          ],
        ),
      ),
      LumeToolSection(
        title: l.sunToday,
        child: LumeTimeline(
          key: LumeSunmoonTool.timelineKey,
          entries: <LumeTimelineEntry>[
            for (final (int i, LumeSkyEvent e) in events.indexed)
              LumeTimelineEntry(
                time: e.at == null ? '—' : _clock(f, e.at!),
                title: _label(l, e.kind),
                subtitle: _note(l, sun, e),
                icon: switch (e.kind) {
                  LumeSkyEventKind.sunrise ||
                  LumeSkyEventKind.noon => LumeIcons.sun,
                  _ => LumeIcons.moon,
                },
                state: states[i],
              ),
          ],
        ),
      ),
    ];
  }
}

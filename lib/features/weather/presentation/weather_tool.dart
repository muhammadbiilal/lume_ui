/// Weather — the reference tool for context dashboards (F6A-D2).
///
/// `tools/daily/weather.tool.js`: where and when, the conditions now, a heat
/// advisory when there is one, the next twelve hours, five days, air quality,
/// the sun and moon, and the rest of the conditions. Every figure is the
/// reference's port (C61 and `weather_fixtures.dart`) — none is an
/// observation, and the host's source line says so: "Delayed", never "Live".
/// A market the reference cannot describe draws nothing in place of weather.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/fixtures/lume_reference_weather.dart';
import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_gradients.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/time/lume_solar.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/time/lume_zone.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../core/widgets/lume/lume_weather.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../catalogue/presentation/feature_strings.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/weather_fixtures.dart';

class LumeWeatherTool extends ConsumerStatefulWidget {
  const LumeWeatherTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeWeatherTool(request: request);

  static const String id = 'weather';

  static const Key contextKey = ValueKey<String>('weather.context');
  static const Key summaryKey = ValueKey<String>('weather.summary');
  static const Key alertKey = ValueKey<String>('weather.alert');
  static const Key hourlyKey = ValueKey<String>('weather.hourly');
  static const Key daysKey = ValueKey<String>('weather.days');
  static const Key aqiKey = ValueKey<String>('weather.aqi');
  static const Key sunKey = ValueKey<String>('weather.sun');
  static const Key metricsKey = ValueKey<String>('weather.metrics');
  static const Key conditionsKey = ValueKey<String>('weather.conditions');

  /// `sunTimes()` falls back to 06:00 and 18:30 when no schedule is known.
  static const LumeSunDay fallbackSun = LumeSunDay(
    riseMinute: 6 * 60,
    setMinute: 18 * 60 + 30,
  );

  /// `sunTimes()` — sunrise and Maghrib from the prayer schedule at the
  /// reader's city, in the reader's zone.
  static LumeSunDay sunDay({
    required DateTime now,
    required String country,
    required String city,
    required String zoneId,
    LumeZoneDatabase? zones,
  }) {
    final (double, double)? at = LumeSolar.coordsFor(country, city);
    final LumeZone? zone = (zones ?? LumeTimeZoneService.shared).zoneFor(
      zoneId,
    );
    if (at == null || zone == null) return fallbackSun;
    final List<LumeSolarTime> day = LumeSolar.prayerTimes(
      // The zone's own date, not the device's.
      date: zone.wallClockAt(now),
      lat: at.$1,
      lon: at.$2,
      offsetHours: zone.offsetAt(now).inMinutes / 60,
    );
    int? minuteOf(String key) {
      for (final LumeSolarTime t in day) {
        if (t.key == key) return t.hour * 60 + t.minute;
      }
      return null;
    }

    return LumeSunDay(
      riseMinute: minuteOf('sunrise') ?? fallbackSun.riseMinute,
      setMinute: minuteOf('maghrib') ?? fallbackSun.setMinute,
    );
  }

  @override
  ConsumerState<LumeWeatherTool> createState() => _LumeWeatherToolState();
}

class _LumeWeatherToolState extends ConsumerState<LumeWeatherTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();

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
    // `L.timezone()` — the reader's own choice, or the country's.
    final String zoneId =
        startup.profile.timeZone ??
        startup.countries?.zoneOf(r.user.country) ??
        'UTC';
    final LumeWeatherBoard? board = LumeWeatherBoard.forMarket(
      country: r.user.country,
      city: r.user.city,
      timeZone: zoneId,
      nowHour: now.hour,
    );
    final String country = LumeToolScreen.countryName(
      context,
      ref,
      r.user.country,
    );

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      shareCard: board == null
          ? null
          : () => LumeShareCard.forFeature(
              sensitive: r.feature.sensitive,
              kind: LumeShareKind.quote,
              // `shareForTool('weather')`: the place, the temperature and the
              // conditions, then the day's high and low; stamped with when.
              text:
                  '${r.user.city} · ${f.temperature(board.climate.temperatureC)} '
                  '${LumeFeatureStrings.weatherCondition(l, board.climate.conditionKey)}. '
                  '${l.weatherHilo(f.temperature(board.today.highC), f.temperature(board.today.lowC))}',
              source: '${f.dateShort(now)} · ${f.time(now)}',
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            flush: true,
            child: LumeContextBar(
              key: LumeWeatherTool.contextKey,
              items: <LumeContextItem>[
                LumeContextItem(
                  label: '${r.user.city}, $country',
                  icon: LumeIcons.pin,
                  onTap: () => showLumePersonalise(context),
                ),
                LumeContextItem(label: f.dateFull(now)),
              ],
            ),
          ),
          if (board != null) ..._dashboard(l, f, now, zoneId, board),
        ],
      ),
    );
  }

  String _speed(AppLocalizations l, LumeFormatting f, int kph) =>
      '${f.speed(kph)} ${f.units == LumeUnits.imperial ? l.unitMph : l.unitKmh}';

  String _distance(AppLocalizations l, LumeFormatting f, int km) =>
      f.units == LumeUnits.imperial
      ? '${f.number(km * 0.621, decimals: 1)} ${l.unitMi}'
      : '${f.integer(km)} ${l.unitKm}';

  List<Widget> _dashboard(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    String zoneId,
    LumeWeatherBoard board,
  ) {
    final LumeToolRequest r = widget.request;
    final LumeReferenceClimate w = board.climate;
    final LumeGradient sky = context.lumeGradients.sky;
    final LumeSunDay sun = LumeWeatherTool.sunDay(
      now: now,
      country: r.user.country,
      city: r.user.city,
      zoneId: zoneId,
    );
    DateTime clock(int minute) =>
        DateTime(now.year, now.month, now.day, minute ~/ 60, minute % 60);
    String percent(int v) => '${f.integer(v)}%';

    final LumeAqiBand band = board.aqi.band;
    final (
      String bandLabel,
      String bandAdvice,
      LumeBadgeTone bandTone,
    ) = switch (band) {
      LumeAqiBand.good => (l.aqiGoodLabel, l.aqiGoodAdvice, LumeBadgeTone.ok),
      LumeAqiBand.moderate => (
        l.aqiModerateLabel,
        l.aqiModerateAdvice,
        LumeBadgeTone.info,
      ),
      LumeAqiBand.sensitive => (
        l.aqiSensitiveLabel,
        l.aqiSensitiveAdvice,
        LumeBadgeTone.warn,
      ),
      LumeAqiBand.unhealthy => (
        l.aqiUnhealthyLabel,
        l.aqiUnhealthyAdvice,
        LumeBadgeTone.warn,
      ),
      LumeAqiBand.veryUnhealthy => (
        l.aqiVeryUnhealthyLabel,
        l.aqiVeryUnhealthyAdvice,
        LumeBadgeTone.late_,
      ),
      LumeAqiBand.hazardous => (
        l.aqiHazardousLabel,
        l.aqiHazardousAdvice,
        LumeBadgeTone.late_,
      ),
    };

    final String moon = switch (lumeMoonPhase(now)) {
      LumeMoonPhase.newMoon => l.moonNew,
      LumeMoonPhase.waxingCrescent => l.moonWaxCrescent,
      LumeMoonPhase.firstQuarter => l.moonFirstQuarter,
      LumeMoonPhase.waxingGibbous => l.moonWaxGibbous,
      LumeMoonPhase.full => l.moonFull,
      LumeMoonPhase.waningGibbous => l.moonWanGibbous,
      LumeMoonPhase.lastQuarter => l.moonLastQuarter,
      LumeMoonPhase.waningCrescent => l.moonWanCrescent,
    };
    final int length = sun.lengthMinutes;

    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeWeatherTool.summaryKey,
          gradient: sky,
          kicker: LumeFeatureStrings.weatherCondition(l, w.conditionKey),
          value: f.temperature(w.temperatureC),
          caption:
              '${l.weatherFeels(f.temperature(w.feelsLikeC))} · '
              '${l.weatherHilo(f.temperature(board.today.highC), f.temperature(board.today.lowC))}',
          // `.wicon svg { width: 52px }` at .9.
          aside: ExcludeSemantics(
            child: Opacity(
              opacity: 0.9,
              child: LumeIcon(w.icon, size: 52, color: sky.on),
            ),
          ),
          stats: <LumeStat>[
            LumeStat(value: percent(w.rainPercent), label: l.weatherStatRain),
            LumeStat(value: _speed(l, f, w.windKph), label: l.weatherWind),
            LumeStat(value: percent(board.humidity), label: l.weatherHumidity),
          ],
        ),
      ),
      if (board.heatAlert)
        LumeToolSection(
          child: LumeNoteCard(
            key: LumeWeatherTool.alertKey,
            tone: LumeNoteTone.warn,
            icon: LumeIcons.alert,
            title: l.weatherAlertHeat,
            text: l.weatherAlertHeatText,
          ),
        ),
      LumeToolSection(
        title: l.weatherHourly,
        flush: true,
        child: LumeHourlyStrip(
          key: LumeWeatherTool.hourlyKey,
          label: l.weatherHourly,
          items: <LumeHourlyItem>[
            for (final (int i, LumeWeatherHour h)
                in board.hourly.take(12).indexed)
              LumeHourlyItem(
                time: i == 0 ? l.commonNow : f.time(clock(h.hour * 60)),
                icon: h.icon,
                temperature: f.temperature(h.temperatureC),
                rain: percent(h.rainPercent),
                now: i == 0,
              ),
          ],
        ),
      ),
      LumeToolSection(
        title: l.weatherForecast,
        child: LumeRows(
          key: LumeWeatherTool.daysKey,
          children: <Widget>[
            for (final (int i, LumeReferenceDay d) in w.days.indexed)
              LumeRichRow(
                icon: d.icon,
                title: switch (i) {
                  0 => l.commonToday,
                  1 => l.commonTomorrow,
                  _ => f.weekdayLong(
                    DateTime(now.year, now.month, now.day + i),
                  ),
                },
                subtitle: LumeFeatureStrings.weatherCondition(
                  l,
                  d.conditionKey,
                ),
                meta: <String>[l.weatherRainChance(f.integer(d.rainPercent))],
                // `.rrow__spark` is 54 × 22 and its bar 60 wide: the bar runs
                // past the box's end, as it does there.
                trailing: SizedBox(
                  width: 54,
                  height: 22,
                  child: OverflowBox(
                    alignment: AlignmentDirectional.topStart,
                    maxWidth: LumeTempBar.width,
                    maxHeight: 22,
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      child: () {
                        final (int lo, int hi) = board.barFor(d);
                        return LumeTempBar(start: lo, end: hi);
                      }(),
                    ),
                  ),
                ),
                value: f.temperature(d.highC),
                valueSub: f.temperature(d.lowC),
              ),
          ],
        ),
      ),
      LumeToolSection(
        title: l.weatherAir,
        child: LumeCard(
          child: LumeAqiCard(
            key: LumeWeatherTool.aqiKey,
            value: '${board.aqi.value}',
            unit: l.aqiUnit,
            badge: LumeBadge(label: bandLabel, tone: bandTone),
            advice: bandAdvice,
            parts: <LumeAqiPartItem>[
              for (final LumeAqiPart p in board.aqi.parts)
                LumeAqiPartItem(value: '${p.value}', name: p.name),
            ],
          ),
        ),
      ),
      LumeToolSection(
        title: l.sunTitle,
        child: LumeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LumeSunArc(
                key: LumeWeatherTool.sunKey,
                progress: sun.progressAt(now.hour * 60 + now.minute),
                rise: f.time(clock(sun.riseMinute)),
                riseLabel: l.sunSunrise,
                set: f.time(clock(sun.setMinute)),
                setLabel: l.sunSunset,
              ),
              const SizedBox(height: 16),
              LumeMetrics(
                key: LumeWeatherTool.metricsKey,
                columns: 3,
                children: <Widget>[
                  LumeMetric(
                    value: l.durationHm(
                      '${length ~/ 60}',
                      (length % 60).toString().padLeft(2, '0'),
                    ),
                    label: l.sunDaylength,
                  ),
                  LumeMetric(value: moon, label: l.sunMoon),
                  LumeMetric(
                    value: f.temperature(board.dewC),
                    label: l.weatherDew,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      LumeToolSection(
        title: l.weatherDetails,
        child: LumeRows(
          key: LumeWeatherTool.conditionsKey,
          children: <Widget>[
            LumeCompactRow(
              icon: LumeIcons.eye,
              label: l.weatherVisibility,
              value: _distance(l, f, LumeWeatherBoard.visibilityKm),
            ),
            LumeCompactRow(
              icon: LumeIcons.gauge,
              label: l.weatherPressure,
              value: '${f.integer(LumeWeatherBoard.pressureHpa)} ${l.unitHpa}',
            ),
            LumeCompactRow(
              icon: LumeIcons.wind,
              label: l.weatherGusts,
              value: _speed(l, f, board.gustsKph),
            ),
            LumeCompactRow(
              icon: LumeIcons.sun,
              label: l.weatherUv,
              value: l.weatherUvValue(
                f.integer(board.uv),
                board.uvHigh ? l.weatherUvHigh : l.weatherUvModerate,
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

/// Air Quality — `tools/daily/aqi.tool.js` over `tool-data.js` `aqiFor`.
///
/// A context bar naming the reader's city, a summary card leading with the
/// index and its band, an advice note, the four pollutant rows and the
/// 24-hour trend — the reference's own composition, moved here rather than
/// rewritten. See `data/aqi_fixtures.dart` for what the number actually is
/// and the Dayroz obligation it carries.
///
/// The reference's own comment on `aqiFor` asks the screen to label the
/// pollutant rows "estimated" rather than "measured" — wired through on every
/// row (`aqi.estimated`). This port keeps that, and adds the same word to the
/// summary card's own caption and to the share card's source line, so the
/// honesty travels with the figure everywhere it is read, not only in the
/// small print under the pollutants.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_spark.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/aqi_fixtures.dart';
import 'aqi_text.dart';

class LumeAqiTool extends ConsumerWidget {
  const LumeAqiTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) => LumeAqiTool(request: request);

  static const String id = 'aqi';

  static const Key contextKey = ValueKey<String>('aqi.context');
  static const Key summaryKey = ValueKey<String>('aqi.summary');
  static const Key adviceKey = ValueKey<String>('aqi.advice');
  static const Key pollutantsKey = ValueKey<String>('aqi.pollutants');
  static const Key trendKey = ValueKey<String>('aqi.trend');

  /// `dirOf`-style tone-to-colour, so the ring reads the same severity as
  /// the badge beside it without a second, disagreeing colour system.
  static Color _toneColor(LumeColors lume, LumeBadgeTone tone) => switch (tone) {
    LumeBadgeTone.ok => lume.up,
    LumeBadgeTone.info => lume.sky,
    LumeBadgeTone.warn => lume.amberInk,
    LumeBadgeTone.late_ => lume.roseInk,
    _ => lume.accent,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LumeToolRequest r = request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final LumeColors lume = context.lume;
    final DateTime now = LumeClockScope.of(context).now();
    final String countryName = LumeToolScreen.countryName(
      context,
      ref,
      r.user.country,
    );
    final LumeAirQualityReading reading = lumeAirQualityFor(
      r.user.country,
      r.user.city,
    );
    final LumeAirQualityBandText band = LumeAqiText.bandText(l, reading.band);

    return LumeToolScreen(
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      // The reference shares no card of its own for this tool; the pattern
      // is Currency & Gold's (C68): the figure the screen leads with, kept
      // honest with the same "estimated" word the pollutant rows carry.
      shareCard: () => LumeShareCard.forFeature(
        sensitive: r.feature.sensitive,
        kind: LumeShareKind.quote,
        text: l.aqiShareText(r.user.city, f.integer(reading.value), band.label),
        source: '${l.aqiEstimatedSource} · ${f.dateLong(now)}',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            flush: true,
            child: LumeContextBar(
              key: LumeAqiTool.contextKey,
              items: <LumeContextItem>[
                LumeContextItem(
                  label: '${r.user.city}, $countryName',
                  icon: LumeIcons.pin,
                  onTap: () => showLumePersonalise(context),
                ),
                LumeContextItem(label: f.dateFull(now)),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumeAqiTool.summaryKey,
              kicker: l.aqiIndex,
              value: f.integer(reading.value),
              unit: l.aqiUnit,
              // The honesty the reference's own `aqiFor` comment asks for,
              // surfaced beside the headline number rather than only under
              // the pollutant rows below.
              caption: l.aqiEstimatedNote(r.user.city),
              // The number is already the card's own headline; the ring
              // repeats it only as a filled arc (`Math.min(1, aq.value /
              // 300)`), not as a second, smaller copy of the same digits —
              // a badge or a ring big enough to hold a third "185" would
              // squeeze this row at a larger text size, exactly what
              // [LumeProgressRing] with a bare number in it risks at 200 %.
              aside: LumeProgressRing(
                value: (reading.value / 300).clamp(0.0, 1.0),
                valueText: f.integer(reading.value),
                label: l.aqiIndex,
                tone: _toneColor(lume, band.tone),
              ),
              // The band's own word — full width, so it is never squeezed
              // by the value above it, however long a translation runs
              // ("Unhealthy for sensitive groups").
              footer: Align(
                alignment: AlignmentDirectional.centerStart,
                child: LumeBadge(label: band.label, tone: band.tone),
              ),
            ),
          ),
          LumeToolSection(
            child: LumeNotice(
              key: LumeAqiTool.adviceKey,
              kind: LumeAqiText.adviceKind(band.tone),
              title: l.aqiAdvice,
              text: band.advice,
            ),
          ),
          LumeToolSection(
            title: l.aqiPollutants,
            child: LumeRows(
              key: LumeAqiTool.pollutantsKey,
              children: <Widget>[
                for (final LumeAirQualityPart p in reading.parts)
                  LumeRichRow(
                    icon: LumeIcons.wind,
                    title: p.name,
                    // `sub: c.t('aqi.estimated')` on every row — never
                    // "measured", because nothing here is.
                    subtitle: l.aqiEstimated,
                    value: f.integer(p.value),
                    valueSub: p.unit,
                  ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.aqiTrend,
            child: LumeCard(
              child: LumeLineChart(
                key: LumeAqiTool.trendKey,
                values: reading.trend,
                label: l.aqiTrend,
                labels: <String>[
                  l.aqiHoursAgo(24),
                  l.aqiHoursAgo(12),
                  l.commonNow,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Prayer Times — `tools/islamic/prayer.tool.js`, on Sun & Moon's own
/// composition (a context bar, a summary card, a timeline, a source card).
///
/// The next prayer, the countdown to it, the day's five and the sunrise/
/// sunset pair are all worked out for the reader's city and clock at
/// [LumePrayerDay.at] — never a fixture, never a live network feed. This tool
/// is faith-gated at the catalogue (`faith: true`); nothing here re-decides
/// that, and [LumeToolFrame] blocks the body for a non-Muslim reader before
/// this widget's own `build` ever draws its content (defence in depth, §64 —
/// the same guarantee Qibla's own test proves).
///
/// **What differs from the reference**, beyond [LumePrayerDay]'s own note:
/// the reference reads a chosen calculation method and madhab from
/// `c.profile.method`; this build has no central preference for either yet,
/// so it fixes both to [LumeSolar.prayerTimes]'s own defaults (Muslim World
/// League, standard Asr) and says so plainly in the method rows and the
/// in-tool note, rather than presenting a reader's own choice that was never
/// asked for.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../app/providers/time_zone_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_export.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/time/lume_solar.dart';
import '../../../core/time/lume_zone.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/presentation/feature_strings.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../domain/prayer_schedule.dart';

class LumePrayerTool extends ConsumerStatefulWidget {
  const LumePrayerTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumePrayerTool(request: request);

  static const String id = 'prayer';

  static const Key contextKey = ValueKey<String>('prayer.context');
  static const Key summaryKey = ValueKey<String>('prayer.summary');
  static const Key timelineKey = ValueKey<String>('prayer.timeline');
  static const Key sunKey = ValueKey<String>('prayer.sun');
  static const Key upcomingKey = ValueKey<String>('prayer.upcoming');
  static const Key methodKey = ValueKey<String>('prayer.method');
  static const Key missingKey = ValueKey<String>('prayer.missing');

  @override
  ConsumerState<LumePrayerTool> createState() => _LumePrayerToolState();
}

class _LumePrayerToolState extends ConsumerState<LumePrayerTool> {
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
        .readerZone(
          startup.profile,
          ref.watch(deviceZoneProvider),
          country: r.user.country,
          city: r.user.city,
        );
    final (LumePrayerDay? day, LumePrayerMissing? missing) = LumePrayerDay.at(
      now: now,
      country: r.user.country,
      city: r.user.city,
      zone: zone,
    );
    final String countryName = LumeToolScreen.countryName(
      context,
      ref,
      r.user.country,
    );
    final String zoneLabel =
        zone.label(Localizations.localeOf(context).languageCode)?.display ??
        zone.requested ??
        '';

    return LumeToolScreen(
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      shareCard: day == null
          ? null
          : () {
              final (LumePrayerSlot next, _, _) = day.state(now);
              return LumeShareCard.forFeature(
                sensitive: r.feature.sensitive,
                kind: LumeShareKind.reminder,
                text:
                    '${LumeFeatureStrings.prayerName(l, next.key)} '
                    '${f.time(next.at)}',
                source: l.prayerShareSource(r.user.city, f.dateShort(now)),
              );
            },
      exportFile: day == null
          ? null
          : () => LumeExportFile.csv(
              tool: LumePrayerTool.id,
              day: now,
              rows: <List<Object?>>[
                <Object?>[l.commonName, l.recFieldTime],
                for (final LumePrayerSlot slot in day.slots)
                  <Object?>[
                    LumeFeatureStrings.prayerName(l, slot.key),
                    f.time(slot.at),
                  ],
              ],
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            flush: true,
            child: LumeContextBar(
              key: LumePrayerTool.contextKey,
              items: <LumeContextItem>[
                LumeContextItem(
                  label: '${r.user.city}, $countryName',
                  icon: LumeIcons.pin,
                ),
                LumeContextItem(label: f.dateFull(now)),
              ],
            ),
          ),
          if (day == null)
            LumeToolSection(
              child: LumeToolState(
                key: LumePrayerTool.missingKey,
                icon: LumeIcons.prayer,
                title: switch (missing) {
                  LumePrayerMissing.city => l.prayerNoCityTitle(r.user.city),
                  _ when zoneLabel.isEmpty => l.recZoneUnknownTitle,
                  _ => l.prayerNoZoneTitle(_isolate(zoneLabel)),
                },
                text: switch (missing) {
                  LumePrayerMissing.city => l.prayerNoCityText,
                  _ when zoneLabel.isEmpty => l.prayerZoneChooseText,
                  _ => l.prayerNoZoneText,
                },
              ),
            )
          else
            ..._board(l, f, now, day, zone, zoneLabel, countryName),
        ],
      ),
    );
  }

  List<Widget> _board(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    LumePrayerDay day,
    LumeZoneResolution zone,
    String zoneLabel,
    String countryName,
  ) {
    final (LumePrayerSlot next, Duration remaining, double progress) = day
        .state(now);
    final String pctLabel = '${(progress * 100).round()}%';

    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumePrayerTool.summaryKey,
          kicker: l.prayerNext,
          value: LumeFeatureStrings.prayerName(l, next.key),
          unit: f.time(next.at),
          caption: l.prayerCountdown(LumeFormatting.countdown(remaining)),
          aside: LumeProgressRing(
            value: progress,
            centreValue: pctLabel,
            label: l.prayerProgress,
            valueText: pctLabel,
          ),
          footer: LumeProgressBar(
            value: progress,
            label: l.prayerProgress,
            valueText: pctLabel,
          ),
        ),
      ),
      LumeToolSection(
        title: l.prayerToday,
        child: LumeTimeline(
          key: LumePrayerTool.timelineKey,
          entries: <LumeTimelineEntry>[
            for (final LumePrayerSlot slot in day.slots)
              LumeTimelineEntry(
                time: f.time(slot.at),
                title: LumeFeatureStrings.prayerName(l, slot.key),
                subtitle: slot.key == next.key
                    ? l.prayerUpNext
                    : (slot.at.isBefore(now) ? l.prayerPassed : null),
                value: slot.key == next.key
                    ? LumeFormatting.shortCountdown(remaining)
                    : null,
                icon: slot.at.isBefore(now) && slot.key != next.key
                    ? LumeIcons.check
                    : null,
                state: slot.key == next.key
                    ? LumeTimelineState.now
                    : (slot.at.isBefore(now)
                          ? LumeTimelineState.done
                          : LumeTimelineState.upcoming),
              ),
          ],
        ),
      ),
      LumeToolSection(
        title: l.prayerSunTitle,
        child: LumeMetrics(
          key: LumePrayerTool.sunKey,
          children: <Widget>[
            LumeMetric(
              icon: LumeIcons.sun,
              value: f.time(day.sunrise),
              label: l.sunSunrise,
            ),
            LumeMetric(
              icon: LumeIcons.moon,
              value: f.time(day.sunset),
              label: l.sunSunset,
            ),
          ],
        ),
      ),
      LumeToolSection(
        title: l.prayerUpcoming,
        child: _upcoming(l, f, now, zone),
      ),
      LumeToolSection(
        title: l.prayerSettings,
        child: LumeRows(
          key: LumePrayerTool.methodKey,
          children: <Widget>[
            // The method/Asr/location strings are a plain disclosure, not a
            // short paired figure — long enough (`prayerAsrStandard`'s own
            // "Standard (Shafi'i, Maliki, Hanbali)", or a long city name
            // beside its country) to overflow the row's fixed end column at
            // 200% text scale. `subtitle` sits under the label at the row's
            // own full width instead, the same fix loadshed's own bill hint
            // took (wave 9).
            LumeCompactRow(
              icon: LumeIcons.sliders,
              label: l.prayerMethod,
              subtitle: l.prayerMethodMwl,
            ),
            LumeCompactRow(
              icon: LumeIcons.scales,
              label: l.prayerAsrMethodLabel,
              subtitle: l.prayerAsrStandard,
            ),
            LumeCompactRow(
              icon: LumeIcons.pin,
              label: l.prayerLocation,
              subtitle: '${widget.request.user.city}, $countryName',
            ),
            LumeCompactRow(
              icon: LumeIcons.globe,
              label: l.prayerTimezone,
              subtitle: zoneLabel.isEmpty ? null : zoneLabel,
            ),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeNotice(
          kind: LumeNoticeKind.info,
          title: l.prayerNoteTitle,
          text: l.prayerNoteText,
        ),
      ),
    ];
  }

  /// The drift table, or nothing where the day's own coordinates or zone —
  /// already resolved once for [day] — cannot say. `[LumePrayerDay.at]`
  /// having returned a non-`null` day means both are in fact available; the
  /// re-checks here are for the type system, not a second real chance of
  /// failure.
  Widget _upcoming(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    LumeZoneResolution zone,
  ) {
    final (double, double)? coords = LumeSolar.coordsFor(
      widget.request.user.country,
      widget.request.user.city,
    );
    final LumeZone? z = zone.zone;
    if (coords == null || z == null) return const SizedBox.shrink();
    final List<LumePrayerOutlookDay> rows = LumePrayerDay.outlook(
      local: z.wallClockAt(now),
      coords: coords,
      offsetHours: z.offsetAt(now).inMinutes / 60,
    );

    return LumeTable(
      key: LumePrayerTool.upcomingKey,
      label: l.prayerUpcoming,
      columns: <LumeColumn>[
        LumeColumn(label: l.commonDate),
        LumeColumn(label: l.prayerFajr, numeric: true),
        LumeColumn(label: l.prayerDhuhr, numeric: true),
        LumeColumn(label: l.prayerMaghrib, numeric: true),
      ],
      rows: <List<String>>[
        for (final LumePrayerOutlookDay d in rows)
          <String>[
            f.dateShort(d.day),
            f.time(d.fajr),
            f.time(d.dhuhr),
            f.time(d.maghrib),
          ],
      ],
    );
  }

  /// First-strong isolate marks (U+2068/U+2069) around [s] — a zone label may
  /// read right-to-left inside an otherwise left-to-right sentence, or the
  /// reverse. `String.fromCharCode` rather than an inline escape: typed
  /// literally, the mark itself is invisible in an editor and easy to mistake
  /// for the character it is not (Qibla and Sun & Moon's own equivalent notes
  /// apply the same guard the other way, spelling the escape out because
  /// their surrounding source never risked losing it silently).
  static String _isolate(String s) =>
      '${String.fromCharCode(0x2068)}$s${String.fromCharCode(0x2069)}';
}

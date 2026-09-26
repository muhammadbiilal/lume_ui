/// Ramadan — a seasonal dashboard: the countdown before the month, and the
/// day's own rhythm during it.
///
/// `tools/islamic/ramadan.tool.js` over `context.js` `ramadan()`
/// (`:314-333`), `sunTimes()` and `prayerTimes()`. What is real in the
/// reference is kept and worked out for real here — never read from a
/// fixture: whether the reader is in Ramadan at all comes from the same
/// tabular Hijri calendar Calendar already reads ([LumeHijriDate]), and
/// Suhoor and Iftar are the real Fajr and Maghrib for the reader's city
/// ([LumeSolar.prayerTimes]), the same calculation Calendar and Weather
/// already share — not the reference's own `sun.sunrise.h - 1, 42` shortcut,
/// which is not Fajr at all (a fixed 42 minutes before a hard-coded hour
/// offset from sunrise, wrong by however far Fajr's own twilight angle falls
/// from that guess).
///
/// **What is corrected.** The reference's `daysUntil` treats every Hijri
/// month as 29 days flat (`monthsAway * 29 + (30 - day)`); the true tabular
/// calendar alternates 29- and 30-day months, and on the day this was
/// written the two disagree by 26 days. Here the count is the real number of
/// calendar days until the Hijri month turns 9, walked one day at a time over
/// the same conversion — still an approximation (the tabular calendar can sit
/// a day or two from the sighted month, see the "Dayroz obligation" in
/// `lume_hijri.dart`), but never off by weeks. `hijriYear` has an outright
/// bug: `h.year + (monthsAway ? 1 : 0)` adds a year whenever the reader is
/// not currently *in* Ramadan, including the months of the same Hijri year
/// that still lead up to it — so for most of the year it names next year's
/// Ramadan as the one about to start. Fixed to the year Ramadan actually
/// falls in this cycle.
///
/// **What is dropped, and why.** The reference's own "Key dates" list
/// (`D.ISLAMIC_EVENTS`) is a fixture of fixed Gregorian dates with a fixed
/// "days away" figure baked in — accurate for whatever one day the fixture
/// was written against, wrong on every other day the app is opened, and
/// disconnected from the real Hijri math above it. Not reproduced, and
/// nothing here invents the other-direction (Hijri-to-Gregorian) conversion
/// needed to build an honest replacement — that would be real added scope,
/// not a port. The "Your Ramadan" progress meters (fasts kept, juz read,
/// charity given) are bare literals with no record behind any of them
/// (`kept: h.day - 1` assumes a perfect month; `charity: 180, charityGoal:
/// 400` are not the reader's own numbers) — dropped, the same call already
/// made for Fasting Tracker's own reference composition
/// (`fasting_model.dart`). The month heatmap is a seeded-random calendar
/// with no meaning behind its colours, and this build has no heatmap widget
/// to draw one in regardless — dropped. The timeline's fixed
/// "Taraweeh · 20:45" row is a hard-coded clock time with nothing behind
/// it — the reference's only Taraweeh times are Taraweeh's own sample
/// mosques (`mosques_fixtures.dart`) — dropped rather than guessed at
/// ("shortly after Isha" would still be a number nobody measured).
///
/// **What is added.** A "Prepare" section (the reference's own composition,
/// kept) links out to Fasting Tracker, Qur'an and Zakat Calculator — real
/// tools, each gated the same way the frame's own related rail is gated, so
/// a link this reader cannot open is never drawn either.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/personalisation.dart';
import '../../../app/providers/shell_provider.dart';
import '../../../app/providers/time_zone_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/time/lume_hijri.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/time/lume_solar.dart';
import '../../../core/time/lume_solar_day.dart';
import '../../../core/time/lume_zone.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';

/// Why [LumeRamadanReading.at] found nothing to show.
enum LumeRamadanMissing { city, zone }

/// The reader's Ramadan, worked out for their place and clock — the
/// countdown before the month, or the day's own rhythm inside it. Never
/// both; [active] says which.
@immutable
class LumeRamadanReading {
  const LumeRamadanReading._({
    required this.active,
    required this.hijri,
    required this.day,
    required this.fajr,
    required this.maghrib,
    this.dayOfRamadan,
    this.daysRemaining,
    this.iftarInMinutes,
    this.daysUntil,
    this.ramadanHijriYear,
  });

  final bool active;
  final LumeHijriDate hijri;

  /// The reader's local day's schedule — Fajr through Isha, sunrise
  /// excluded, exactly as the reference's own `prayerTimes()` filters it.
  final List<LumeSolarTime> day;

  /// Fajr and Maghrib, named for what they mean during Ramadan: Suhoor's end
  /// and Iftar.
  final LumeSolarTime fajr;
  final LumeSolarTime maghrib;

  /// Set only when [active].
  final int? dayOfRamadan;

  /// Calendar days left in this Ramadan, today included. Set only when
  /// [active].
  final int? daysRemaining;

  /// Minutes from now to Maghrib. Set only when [active].
  final int? iftarInMinutes;

  /// Calendar days until the Hijri month turns 9. Set only when not
  /// [active].
  final int? daysUntil;

  /// The Hijri year Ramadan falls in this cycle. Set only when not [active].
  final int? ramadanHijriYear;

  /// Ramadan is the ninth Hijri month — [LumeHijriDate.month] is 1 for
  /// Muharram, so 9 is Ramadan.
  static const int ramadanMonth = 9;

  /// The reading at [now] for a reader in [country] and [city], on their
  /// [zone] — or `null` with [LumeRamadanMissing] set, where the city has no
  /// coordinates or the zone cannot be read. Never a guessed place or a
  /// guessed clock: the "no fabricated data" rule extends to which day it
  /// is.
  static (LumeRamadanReading?, LumeRamadanMissing?) at({
    required DateTime now,
    required String country,
    required String city,
    required LumeZoneResolution zone,
  }) {
    final (double, double)? at = LumeSolar.coordsFor(country, city);
    if (at == null) return (null, LumeRamadanMissing.city);
    final LumeZone? z = zone.zone;
    if (z == null) return (null, LumeRamadanMissing.zone);

    // The same local-instant-plus-raw-solar-times resolution Prayer Times'
    // own `LumePrayerDay.at` uses — extracted to `LumeSolarDay` once both
    // tools had independently derived it identically.
    final LumeSolarDay solarDay = LumeSolarDay.at(
      now: now,
      coords: at,
      zone: z,
    );
    final DateTime local = solarDay.local;
    final LumeHijriDate hijri = LumeHijriDate.of(local);
    final List<LumeSolarTime> day = solarDay.raw
        .where((LumeSolarTime t) => !t.minor)
        .toList();
    final LumeSolarTime fajr = day.firstWhere(
      (LumeSolarTime t) => t.key == 'fajr',
    );
    final LumeSolarTime maghrib = day.firstWhere(
      (LumeSolarTime t) => t.key == 'maghrib',
    );

    final bool active = hijri.month == ramadanMonth;
    if (active) {
      final double nowMinutes =
          local.hour * 60 + local.minute + local.second / 60;
      final double toMaghrib = maghrib.minutes - nowMinutes;
      final int iftarIn = (toMaghrib < 0 ? toMaghrib + 1440 : toMaghrib)
          .round();
      return (
        LumeRamadanReading._(
          active: true,
          hijri: hijri,
          day: day,
          fajr: fajr,
          maghrib: maghrib,
          dayOfRamadan: hijri.day,
          daysRemaining: _daysRemaining(local),
          iftarInMinutes: iftarIn < 0 ? 0 : iftarIn,
        ),
        null,
      );
    }
    return (
      LumeRamadanReading._(
        active: false,
        hijri: hijri,
        day: day,
        fajr: fajr,
        maghrib: maghrib,
        daysUntil: _daysUntil(local),
        // The reference's own `h.year + (monthsAway ? 1 : 0)` names next
        // year's Ramadan for most of the months that lead up to *this*
        // year's — corrected: a month at or before Ramadan is still counting
        // down to this Hijri year's own Ramadan.
        ramadanHijriYear: hijri.month <= ramadanMonth
            ? hijri.year
            : hijri.year + 1,
      ),
      null,
    );
  }

  /// Calendar days from [localToday] until the Hijri month first reads 9 —
  /// walked over [LumeHijriDate.walkForward], the same day-by-day scan
  /// `hijri_events.dart`'s own `LumeHijriEvents.upcoming` walks to find its
  /// six transitions, so an alternating 29-/30-day month is never
  /// approximated away.
  static int _daysUntil(DateTime localToday) {
    // A Hijri year is never more than 355 days; two of them is headroom, not
    // a magic number tuned to one date.
    final (_, _, int daysAway) = LumeHijriDate.walkForward(
      start: localToday,
      matches: (LumeHijriDate h) => h.month == ramadanMonth,
      horizonDays: 710,
      reason:
          'No Hijri month 9 found within 710 days of '
          '${localToday.toIso8601String()} — a Hijri year is at most 355 '
          'days, so this should be unreachable.',
    );
    return daysAway;
  }

  /// Calendar days left in Ramadan from [localToday], today included —
  /// walked forward the same way, so a 29-day Ramadan is never told it has a
  /// 30th.
  static int _daysRemaining(DateTime localToday) {
    DateTime d = DateTime(localToday.year, localToday.month, localToday.day);
    int count = 0;
    while (LumeHijriDate.of(d).month == ramadanMonth && count <= 40) {
      count++;
      d = d.add(const Duration(days: 1));
    }
    return count;
  }
}

class LumeRamadanTool extends ConsumerStatefulWidget {
  const LumeRamadanTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeRamadanTool(request: request);

  static const String id = 'ramadan';

  static const Key contextKey = ValueKey<String>('ramadan.context');
  static const Key summaryKey = ValueKey<String>('ramadan.summary');
  static const Key timelineKey = ValueKey<String>('ramadan.timeline');
  static const Key prepareKey = ValueKey<String>('ramadan.prepare');
  static const Key noteKey = ValueKey<String>('ramadan.note');
  static const Key missingKey = ValueKey<String>('ramadan.missing');

  /// `t('prayer.' + key)` — the same names Calendar's own agenda draws.
  static String prayerName(AppLocalizations l, String key) => switch (key) {
    'fajr' => l.prayerFajr,
    'dhuhr' => l.prayerDhuhr,
    'asr' => l.prayerAsr,
    'maghrib' => l.prayerMaghrib,
    _ => l.prayerIsha,
  };

  /// `duration.hm` — "2h 05m".
  static String hm(AppLocalizations l, int minutes) => l.durationHm(
    '${minutes ~/ 60}',
    (minutes % 60).toString().padLeft(2, '0'),
  );

  /// Past is done, the first stop still to come is now, the rest wait — the
  /// same rule Sun & Moon's own `states()` draws its timeline with.
  static List<LumeTimelineState> states(List<double> minutes, double now) {
    final List<LumeTimelineState> out = <LumeTimelineState>[];
    bool marked = false;
    for (final double m in minutes) {
      if (m <= now) {
        out.add(LumeTimelineState.done);
      } else if (!marked) {
        marked = true;
        out.add(LumeTimelineState.now);
      } else {
        out.add(LumeTimelineState.upcoming);
      }
    }
    return out;
  }

  @override
  ConsumerState<LumeRamadanTool> createState() => _LumeRamadanToolState();
}

class _LumeRamadanToolState extends ConsumerState<LumeRamadanTool> {
  String _clock(LumeFormatting f, LumeSolarTime t) =>
      f.time(DateTime(2000, 1, 1, t.hour, t.minute));

  LumeShareCard? _shareCard(
    AppLocalizations l,
    LumeFormatting f,
    LumeRamadanReading reading,
    DateTime local,
  ) {
    final LumeToolRequest r = widget.request;
    final String text = reading.active
        ? '${l.ramadanDay('${reading.dayOfRamadan}')} · '
              '${l.ramadanIftarIn(LumeRamadanTool.hm(l, reading.iftarInMinutes!))}'
        : '${l.ramadanCountdown} · ${reading.daysUntil} ${l.commonDays}';
    return LumeShareCard.forFeature(
      sensitive: r.feature.sensitive,
      kind: LumeShareKind.reminder,
      text: text,
      source: l.ramadanShareSource(r.user.city, f.dateShort(local)),
    );
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
    final LumeStartupState startup = ref.watch(startupControllerProvider).state;
    final LumeZoneResolution zone = ref
        .watch(timeZoneServiceProvider)
        .readerZone(
          startup.profile,
          ref.watch(deviceZoneProvider),
          country: r.user.country,
          city: r.user.city,
        );
    final (
      LumeRamadanReading? reading,
      LumeRamadanMissing? missing,
    ) = LumeRamadanReading.at(
      now: now,
      country: r.user.country,
      city: r.user.city,
      zone: zone,
    );
    final String zoneLabel =
        zone.label(Localizations.localeOf(context).languageCode)?.display ??
        zone.requested ??
        '';
    final DateTime? local = zone.zone?.wallClockAt(now);

    return LumeToolScreen(
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      shareCard: reading == null
          ? null
          : () => _shareCard(l, f, reading, local!),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            flush: true,
            child: LumeContextBar(
              key: LumeRamadanTool.contextKey,
              items: <LumeContextItem>[
                LumeContextItem(label: r.user.city, icon: LumeIcons.pin),
              ],
            ),
          ),
          if (reading == null)
            LumeToolSection(
              child: LumeToolState(
                key: LumeRamadanTool.missingKey,
                icon: LumeIcons.moonStar,
                title: switch (missing) {
                  LumeRamadanMissing.city => l.ramadanNoCityTitle(r.user.city),
                  _ when zoneLabel.isEmpty => l.recZoneUnknownTitle,
                  _ => l.ramadanNoZoneTitle(
                    '${String.fromCharCode(0x2068)}$zoneLabel${String.fromCharCode(0x2069)}',
                  ),
                },
                text: switch (missing) {
                  LumeRamadanMissing.city => l.ramadanNoCityText,
                  _ when zoneLabel.isEmpty => l.ramadanZoneChooseText,
                  _ => l.ramadanNoZoneText,
                },
              ),
            )
          else
            ...reading.active
                ? _active(l, f, local!, reading)
                : _countdown(l, f, local!, reading),
        ],
      ),
    );
  }

  List<Widget> _countdown(
    AppLocalizations l,
    LumeFormatting f,
    DateTime local,
    LumeRamadanReading reading,
  ) {
    final LumeEligibility eligibility = ref.watch(eligibilityProvider);
    final LumeToolRequest r = widget.request;

    Widget? prep(String id, String title, String sub, String icon) {
      if (eligibility.visibleById(id, r.user) == null) return null;
      return LumeRichRow(
        icon: icon,
        title: title,
        subtitle: sub,
        chevron: true,
        onTap: () => r.onOpenRelated?.call(id),
      );
    }

    final List<Widget> prepRows = <Widget>[
      ?prep(
        'fasting',
        l.ramadanPrepQada,
        l.ramadanPrepQadaSub,
        LumeIcons.checkCircle,
      ),
      ?prep('quran', l.ramadanPrepQuran, l.ramadanPrepQuranSub, LumeIcons.book),
      ?prep(
        'zakat',
        l.ramadanPrepZakat,
        l.ramadanPrepZakatSub,
        LumeIcons.wallet,
      ),
    ];

    final DateTime approxStart = DateTime(
      local.year,
      local.month,
      local.day,
    ).add(Duration(days: reading.daysUntil!));

    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeRamadanTool.summaryKey,
          kicker: l.ramadanCountdown,
          value: '${reading.daysUntil}',
          valueSmall: l.commonDays,
          caption: l.ramadanStarts(f.dateShort(approxStart)),
          stats: <LumeStat>[
            LumeStat(
              value: '${reading.ramadanHijriYear}',
              label: l.ramadanYear,
            ),
            LumeStat(
              value: _clock(f, reading.maghrib),
              label: l.ramadanSunsetToday,
            ),
          ],
        ),
      ),
      if (prepRows.isNotEmpty)
        LumeToolSection(
          title: l.ramadanPrepare,
          child: LumeRows(key: LumeRamadanTool.prepareKey, children: prepRows),
        ),
      LumeToolSection(
        child: LumeNotice(
          key: LumeRamadanTool.noteKey,
          kind: LumeNoticeKind.info,
          title: l.ramadanNoteTitle,
          text: l.ramadanNoteText,
        ),
      ),
    ];
  }

  List<Widget> _active(
    AppLocalizations l,
    LumeFormatting f,
    DateTime local,
    LumeRamadanReading reading,
  ) {
    final double nowMinutes =
        local.hour * 60 + local.minute + local.second / 60;

    final List<(LumeSolarTime, String, String?, String)>
    rows = <(LumeSolarTime, String, String?, String)>[
      (reading.fajr, l.ramadanSuhoorEnds, l.ramadanSuhoorSub, LumeIcons.moon),
      for (final LumeSolarTime p in reading.day)
        (p, LumeRamadanTool.prayerName(l, p.key), null, LumeIcons.prayer),
      (reading.maghrib, l.ramadanIftar, l.ramadanIftarSub, LumeIcons.utensils),
    ];
    final List<LumeTimelineState> states = LumeRamadanTool.states(<double>[
      for (final (LumeSolarTime, String, String?, String) row in rows)
        row.$1.minutes.toDouble(),
    ], nowMinutes);

    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeRamadanTool.summaryKey,
          kicker: l.ramadanDay('${reading.dayOfRamadan}'),
          value: _clock(f, reading.maghrib),
          caption: l.ramadanIftarIn(
            LumeRamadanTool.hm(l, reading.iftarInMinutes!),
          ),
          stats: <LumeStat>[
            LumeStat(value: _clock(f, reading.fajr), label: l.ramadanSuhoor),
            LumeStat(value: _clock(f, reading.maghrib), label: l.ramadanIftar),
            LumeStat(
              value: '${reading.daysRemaining}',
              label: l.ramadanRemaining,
            ),
          ],
        ),
      ),
      LumeToolSection(
        title: l.ramadanDayTimeline,
        child: LumeTimeline(
          key: LumeRamadanTool.timelineKey,
          entries: <LumeTimelineEntry>[
            for (final (int i, (LumeSolarTime, String, String?, String) row)
                in rows.indexed)
              LumeTimelineEntry(
                time: _clock(f, row.$1),
                title: row.$2,
                subtitle: row.$3,
                icon: row.$4,
                state: states[i],
              ),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeNotice(
          key: LumeRamadanTool.noteKey,
          kind: LumeNoticeKind.info,
          title: l.ramadanNoteTitle,
          text: l.ramadanNoteText,
        ),
      ),
    ];
  }
}

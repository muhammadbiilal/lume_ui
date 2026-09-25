/// Prayer Tracker — `tools/islamic/praytrack.tool.js`, as a real
/// record-backed tool.
///
/// The reference draws a summary card (today's count, a streak, this
/// month's rate and a qada backlog), a "mark today" list of the five daily
/// prayers, a 35-day heatmap, a per-prayer bar chart and a qada meter with a
/// "Log Qada" button. Every figure behind the summary, the heatmap and the
/// bar chart is a bare literal with a fixed seed
/// (`context.js` `prayerTracker()` — the full quote is in
/// `praytrack_model.dart`'s own doc); nothing in `record-schemas.js` backs
/// any of it. This build keeps the reference's five-block composition and
/// its five-prayer, five-figure shape, and replaces every one of those
/// figures with a real calculation over a check-in the reader makes
/// themselves, toggled straight from its row (`praytrack_book.dart`).
///
/// **What is dropped.** The reference's "Log Qada" button
/// (`act: 'toast:' + t('track.qadaLogged')`) does not write anything even in
/// the reference — a fixed toast regardless of what is typed, the same class
/// of dead control Prize Bonds' own save-a-number button turned out to be.
/// There is no "qada paid down" concept in this schema for it to write to,
/// so it is left out rather than reproduced as a fake control; the qada
/// meter itself stays, computed for real from unmarked past days.
///
/// **What is added.** Each prayer's row shows its real computed time for
/// today (`LumeSolar.prayerTimes`, the same astronomical calculation Qibla
/// and Weather already use), from the reader's own city — never a fixture,
/// never shown at all where the city has no coordinates.
///
/// A single screen, like Daily Streak's: one summary, the five-prayer mark
/// list, the reader's own last 35 days, a real per-prayer bar chart and a
/// real qada meter.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../app/providers/time_zone_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/navigation/lume_tool_frame.dart';
import '../../../core/platform/lume_export.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/time/lume_solar.dart';
import '../../../core/time/lume_zone.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/widgets/lume/lume_chart.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/praytrack_providers.dart';
import '../domain/praytrack_book.dart';
import '../domain/praytrack_failure.dart';
import '../domain/praytrack_model.dart';
import '../domain/praytrack_repository.dart';
import 'praytrack_text.dart';

abstract final class LumePrayTrackTool {
  static const String id = 'praytrack';

  static const Key summaryKey = ValueKey<String>('praytrack.summary');
  static const Key markKey = ValueKey<String>('praytrack.mark');
  static const Key heatKey = ValueKey<String>('praytrack.heat');
  static const Key byPrayerKey = ValueKey<String>('praytrack.byPrayer');
  static const Key qadaKey = ValueKey<String>('praytrack.qada');

  static Key row(PrayerKey k) => ValueKey<String>('praytrack.row.${k.name}');

  static Widget open(LumeToolRequest request) =>
      PrayTrackTool(request: request);

  /// The reader's five daily prayer times for [now], in [zone] — or `null`
  /// where the city has no coordinates or the zone is not known, which
  /// shows no times rather than guessed ones. Mirrors
  /// `LumeCalendarTool.nextPrayer`'s own shape.
  static List<LumeSolarTime>? dayTimes({
    required DateTime now,
    required String country,
    required String city,
    required LumeZone? zone,
  }) {
    final (double, double)? at = LumeSolar.coordsFor(country, city);
    if (at == null || zone == null) return null;
    final DateTime local = zone.wallClockAt(now);
    return LumeSolar.prayerTimes(
      date: local,
      lat: at.$1,
      lon: at.$2,
      offsetHours: zone.offsetAt(now).inMinutes / 60,
    );
  }
}

class PrayTrackTool extends ConsumerStatefulWidget {
  const PrayTrackTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<PrayTrackTool> createState() => _PrayTrackToolState();
}

class _PrayTrackToolState extends ConsumerState<PrayTrackTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final PrayTrackRepository _repo = ref.read(prayTrackRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _repo.open();
    _repo.changes.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repo.changes.removeListener(_changed);
    super.dispose();
  }

  void _say(String message, {LumeToastTone tone = LumeToastTone.success}) =>
      _host.currentState?.say(message, tone: tone);

  void _failed(AppLocalizations l, PrayTrackFailure f) {
    _say(switch (f.kind) {
      PrayTrackFailureKind.conflict ||
      PrayTrackFailureKind.notFound => l.praytrackErrConflict,
      PrayTrackFailureKind.storage => l.praytrackErrFailed,
    }, tone: LumeToastTone.error);
  }

  Future<void> _toggle(AppLocalizations l, PrayerKey k, LumeDate today) async {
    final PrayTrackResult<PrayTrackWrite> r = _repo.toggle(k, today);
    if (r.failure != null) _failed(l, r.failure!);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: widget.request.user.country,
    );
    final DateTime now = LumeClockScope.of(context).now();

    // `L.timezone()` — the reader's zone as Account › Time resolves it, the
    // same source Habits'/Daily Streak's own "today" and Calendar's own
    // prayer time use.
    final LumeStartupState startup = ref.watch(startupControllerProvider).state;
    final LumeZoneResolution resolution = ref
        .watch(timeZoneServiceProvider)
        .readerZone(
          startup.profile,
          ref.watch(deviceZoneProvider),
          country: widget.request.user.country,
          city: widget.request.user.city,
        );
    final LumeZoneClock clock = ref
        .watch(timeZoneServiceProvider)
        .clock(now, resolution);
    final LumeDate? today = clock.ok
        ? LumeDate.ofWallClock(clock.local!)
        : null;

    final PrayTrackSnapshot snapshot = _repo.view();

    LumeToolStatus status = LumeToolStatus.ready;
    PrayTrackStats? stats;
    if (snapshot.loading) {
      status = LumeToolStatus.loading;
    } else if (snapshot.failed || today == null) {
      status = LumeToolStatus.error;
    } else {
      stats = snapshot.stats(today);
    }

    final List<LumeSolarTime>? times = LumePrayTrackTool.dayTimes(
      now: now,
      country: widget.request.user.country,
      city: widget.request.user.city,
      zone: resolution.zone,
    );

    return LumeToolScreen(
      key: _host,
      feature: widget.request.feature,
      user: widget.request.user,
      onBack: widget.request.onBack,
      onOpenRelated: widget.request.onOpenRelated,
      status: status,
      onRetry: () => setState(_repo.retry),
      exportFile: stats == null ? null : () => _export(l, stats!, today!),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: (stats == null || today == null)
            ? const <Widget>[]
            : _body(context, l, f, stats, times, today),
      ),
    );
  }

  /// Prayer and its current streak, real for every row — never the
  /// reference's unconditional literals.
  LumeExportFile _export(
    AppLocalizations l,
    PrayTrackStats stats,
    LumeDate today,
  ) {
    final List<List<Object?>> rows = <List<Object?>>[
      <Object?>[l.praytrackMarkTitle, l.commonToday],
      for (final PrayerKey k in PrayerKey.values)
        <Object?>[
          PrayTrackText.name(l, k),
          stats.isDoneToday(k) ? l.commonDone : l.praytrackPending,
        ],
    ];
    return LumeExportFile.csv(
      tool: LumePrayTrackTool.id,
      day: today.toCalendarDateTime(),
      rows: rows,
    );
  }

  String? _timeFor(
    LumeFormatting f,
    List<LumeSolarTime>? times,
    LumeDate today,
    PrayerKey k,
  ) {
    if (times == null) return null;
    for (final LumeSolarTime t in times) {
      if (t.key == k.name) {
        return f.time(
          DateTime(today.year, today.month, today.day, t.hour, t.minute),
        );
      }
    }
    return null;
  }

  List<Widget> _body(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    PrayTrackStats stats,
    List<LumeSolarTime>? times,
    LumeDate today,
  ) {
    final int total = PrayerKey.values.length;
    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumePrayTrackTool.summaryKey,
          kicker: l.commonToday,
          value: f.integer(stats.doneToday.length),
          valueSmall: '/ ${f.integer(total)}',
          caption: l.praytrackStreakCaption(stats.currentStreak),
          stats: <LumeStat>[
            LumeStat(
              value: f.integer(stats.currentStreak),
              label: l.praytrackStreakLabel,
            ),
            LumeStat(
              value: f.percent(stats.monthRate * 100, decimals: 0),
              label: l.commonThisMonth,
            ),
            LumeStat(
              value: f.integer(stats.qada),
              label: l.praytrackQadaStatLabel,
            ),
          ],
        ),
      ),
      LumeToolSection(
        title: l.praytrackMarkTitle,
        child: LumeRecordList(
          key: LumePrayTrackTool.markKey,
          children: <Widget>[
            for (final PrayerKey k in PrayerKey.values)
              LumeRecordRow(
                key: LumePrayTrackTool.row(k),
                title: PrayTrackText.name(l, k),
                subtitle: _timeFor(f, times, today, k),
                done: stats.isDoneToday(k),
                checkLabel: l.praytrackCheckLabel,
                onToggle: (bool _) => unawaited(_toggle(l, k, today)),
              ),
          ],
        ),
      ),
      LumeToolSection(
        title: l.praytrackHeatTitle,
        child: LumeCard(
          child: LumeHeatmap(
            key: LumePrayTrackTool.heatKey,
            label: l.praytrackHeatTitle,
            summary:
                '${f.integer(stats.heat.where((PrayTrackHeatDay h) => h.level == 3).length)} '
                '/ ${f.integer(stats.heat.length)}',
            levels: <int>[for (final PrayTrackHeatDay h in stats.heat) h.level],
            less: l.commonLess,
            more: l.commonMore,
            levelLabels: <String>[
              l.heatLevelNone,
              l.heatLevelSome,
              l.heatLevelMost,
              l.heatLevelAll,
            ],
          ),
        ),
      ),
      LumeToolSection(
        title: l.praytrackByPrayerTitle,
        child: LumeCard(
          child: LumeBarChart(
            key: LumePrayTrackTool.byPrayerKey,
            label: l.praytrackByPrayerTitle,
            values: <double>[
              for (final PrayerKey k in PrayerKey.values)
                (stats.byPrayer[k] ?? 0).toDouble(),
            ],
            labels: <String>[
              for (final PrayerKey k in PrayerKey.values)
                PrayTrackText.name(l, k),
            ],
            max: stats.heat.length.toDouble(),
            caption: Text(
              l.praytrackByPrayerCaption,
              style: context.lumeType.metaSmall.copyWith(
                color: context.lume.text3,
              ),
            ),
          ),
        ),
      ),
      LumeToolSection(
        title: l.praytrackQadaTitle,
        child: LumeCard(
          key: LumePrayTrackTool.qadaKey,
          child: LumeMeterRow(
            label: l.praytrackQadaTitle,
            value: l.praytrackQadaValue(stats.qada),
            progress: _qadaProgress(stats),
            footnote: l.praytrackQadaFootnote,
          ),
        ),
      ),
    ];
  }

  /// `1` once nothing is outstanding; otherwise the share of every prayer the
  /// reader has been asked for, since their first check-in through
  /// yesterday, that was actually marked prayed — never the reference's
  /// arbitrary `1 - qada/40` cap (`praytrack.tool.js:49`, a ceiling nothing
  /// in the schema justifies).
  static double _qadaProgress(PrayTrackStats stats) {
    final int total = stats.historyDone + stats.qada;
    return total == 0 ? 1 : (stats.historyDone / total).clamp(0, 1);
  }
}

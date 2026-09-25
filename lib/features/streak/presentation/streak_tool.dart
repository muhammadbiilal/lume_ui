/// Daily Streak — `tools/personal/streak.tool.js`, as a real record-backed
/// tool.
///
/// The reference draws a summary card, a 35-day heat grid and a milestone
/// list, but every figure behind them is a bare literal
/// (`context.js:1609-1618`) and there is no schema for `streak` anywhere in
/// `record-schemas.js` — nothing a reader can ever tap. This keeps the
/// reference's three-block composition and its milestone thresholds
/// (7 / 14 / 30 / 100 days), but replaces the fixture with a real check-in
/// the reader makes each day and a real calculation over their own dates:
/// [StreakStats.compute] in `streak_book.dart`, never a literal.
///
/// A single screen: one toggle for today, the summary it feeds, the
/// reader's own last 35 days, and where their current streak stands against
/// each milestone.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../app/providers/time_zone_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/navigation/lume_tool_frame.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/streak_providers.dart';
import '../domain/streak_book.dart';
import '../domain/streak_failure.dart';
import '../domain/streak_repository.dart';

abstract final class LumeStreakTool {
  static const String id = 'streak';

  static const Key summaryKey = ValueKey<String>('streak.summary');
  static const Key checkInKey = ValueKey<String>('streak.checkin');
  static const Key calendarKey = ValueKey<String>('streak.calendar');
  static const Key milestonesKey = ValueKey<String>('streak.milestones');

  static Key milestoneKey(int threshold) =>
      ValueKey<String>('streak.milestone.$threshold');

  static Widget open(LumeToolRequest request) => StreakTool(request: request);
}

class StreakTool extends ConsumerStatefulWidget {
  const StreakTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<StreakTool> createState() => _StreakToolState();
}

class _StreakToolState extends ConsumerState<StreakTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final StreakRepository _repo = ref.read(streakRepositoryProvider);

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

  void _say(
    String message, {
    LumeToastTone tone = LumeToastTone.success,
    String? actionLabel,
    VoidCallback? onAction,
  }) => _host.currentState?.say(
    message,
    tone: tone,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  LumeDate? _today(BuildContext context) {
    final LumeStartupState startup = ref.watch(startupControllerProvider).state;
    final LumeZoneResolution zone = ref
        .watch(timeZoneServiceProvider)
        .readerZone(
          startup.profile,
          ref.watch(deviceZoneProvider),
          country: widget.request.user.country,
          city: widget.request.user.city,
        );
    final LumeZoneClock clock = ref
        .watch(timeZoneServiceProvider)
        .clock(LumeClockScope.of(context).now(), zone);
    return clock.ok ? LumeDate.ofWallClock(clock.local!) : null;
  }

  void _failed(AppLocalizations l, StreakFailure f) {
    _say(switch (f.kind) {
      StreakFailureKind.conflict ||
      StreakFailureKind.notFound => l.streakErrConflict,
      StreakFailureKind.storage => l.streakErrFailed,
    }, tone: LumeToastTone.error);
  }

  Future<void> _setChecked(
    AppLocalizations l,
    LumeDate date,
    bool value,
  ) async {
    final StreakResult<StreakWrite> r = value
        ? _repo.checkIn(date)
        : _repo.uncheck(date);
    if (r.failure != null) return _failed(l, r.failure!);
    if (r.value!.receipt.revision == 0) return;
    _say(
      value ? l.streakCheckedInToast : l.streakUncheckedToast,
      actionLabel: l.recUndo,
      onAction: () {
        final StreakResult<void> u = _repo.undo(r.value!);
        if (u.failure != null) _failed(l, u.failure!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: widget.request.user.country,
    );
    final LumeDate? today = _today(context);
    final StreakSnapshot snapshot = _repo.view();

    LumeToolStatus status = LumeToolStatus.ready;
    StreakStats? stats;
    if (snapshot.loading) {
      status = LumeToolStatus.loading;
    } else if (snapshot.failed || today == null) {
      status = LumeToolStatus.error;
    } else {
      stats = snapshot.stats(today);
    }

    return LumeToolScreen(
      key: _host,
      feature: widget.request.feature,
      user: widget.request.user,
      onBack: widget.request.onBack,
      onOpenRelated: widget.request.onOpenRelated,
      status: status,
      onRetry: () => setState(_repo.retry),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: (stats == null || today == null)
            ? const <Widget>[]
            : _body(context, l, f, today, stats),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeDate today,
    StreakStats stats,
  ) => <Widget>[
    LumeToolSection(
      child: LumeSummaryCard(
        key: LumeStreakTool.summaryKey,
        kicker: l.streakSummaryKicker,
        value: f.integer(stats.current),
        valueSmall: l.commonDays,
        caption: l.streakBestCaption(stats.best),
        stats: <LumeStat>[
          LumeStat(value: f.integer(stats.thisMonth), label: l.commonThisMonth),
          LumeStat(
            value: f.percent(stats.rate * 100, decimals: 0),
            label: l.streakRateLabel,
          ),
          LumeStat(
            value: stats.nextMilestone == null
                ? '—'
                : f.integer(stats.nextMilestone!),
            label: l.streakNextLabel,
          ),
        ],
      ),
    ),
    LumeToolSection(
      child: LumeRecordRow(
        key: LumeStreakTool.checkInKey,
        title: l.commonToday,
        subtitle: f.dateMediumYear(today.toCalendarDateTime()),
        done: stats.checkedInToday,
        checkLabel: l.streakCheckInLabel,
        onToggle: (bool v) => unawaited(_setChecked(l, today, v)),
      ),
    ),
    LumeToolSection(
      title: l.streakCalendarTitle,
      child: _StreakHeatGrid(
        key: LumeStreakTool.calendarKey,
        days: stats.heat,
        l: l,
      ),
    ),
    LumeToolSection(
      title: l.streakMilestonesTitle,
      child: LumeRows(
        key: LumeStreakTool.milestonesKey,
        children: <Widget>[
          for (final StreakMilestone m in stats.milestones)
            LumeCompactRow(
              key: LumeStreakTool.milestoneKey(m.threshold),
              icon: m.done ? LumeIcons.checkCircle : LumeIcons.star,
              label: l.streakMilestoneDays(m.threshold),
              value: m.done ? l.commonDone : l.commonInDays(m.inDays),
              chevron: false,
            ),
        ],
      ),
    ),
  ];
}

/// The reader's own last 35 days — a plain checked/not-checked grid, never a
/// graduated heat scale: a single daily check-in carries no intensity to
/// show one.
class _StreakHeatGrid extends StatelessWidget {
  const _StreakHeatGrid({super.key, required this.days, required this.l});

  final List<StreakHeatDay> days;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final int checked = days.where((StreakHeatDay d) => d.checkedIn).length;
    return Semantics(
      label: l.streakCalendarA11y(checked, days.length),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: <Widget>[
            for (final StreakHeatDay d in days)
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: d.checkedIn ? lume.accent : lume.tintNeutral,
                  borderRadius: BorderRadius.circular(LumeRadius.xs / 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

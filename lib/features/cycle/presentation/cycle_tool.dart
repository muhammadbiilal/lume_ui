/// Cycle Tracker — `tools/personal/cycle.tool.js`, as a real record-backed
/// tool.
///
/// The reference's own composition, kept: a summary card leading with a
/// cycle day over a length, a month view, a short history, and a privacy
/// note. What it only drew, this does for real — every one of those numbers
/// comes from the reader's own logged periods (`cycle_book.dart`), and a
/// period can be logged, corrected and deleted, which the reference has no
/// way to do at all: its `cycle()` returns today's day-of-month wrapped at a
/// hard-coded 28, and three months of fixture history whose lengths and
/// "Regular" captions are bare literals. Those are dropped entirely, not
/// approximated — a wrapped day-of-month is not a cycle day, and a fixture
/// is not history.
///
/// A single screen, like Meal Plan: logging a period is one small sheet, not
/// a separate list/detail/form host. The one thing this tool does that Meal
/// Plan does not is delete — a period logged by mistake has to be
/// correctable — so its sheet is also where an entry is edited or removed.
///
/// This is one of the app's most sensitive record families (`sensitive:
/// true`, default `LumeOutbound.none` in the catalogue), so nothing here is
/// promoted on Home, nothing here is shareable, and the shared tool frame's
/// privacy note already says the data never leaves this device — this file
/// adds no note of its own.
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
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/cycle_providers.dart';
import '../domain/cycle_book.dart';
import '../domain/cycle_failure.dart';
import '../domain/cycle_model.dart';
import '../domain/cycle_repository.dart';
import 'cycle_sheets.dart';

abstract final class LumeCycleTool {
  static const String id = 'cycle';

  static const Key summaryKey = ValueKey<String>('cycle.summary');
  static const Key currentRowKey = ValueKey<String>('cycle.current');
  static const Key nextKey = ValueKey<String>('cycle.next');
  static const Key historyKey = ValueKey<String>('cycle.history');
  static const Key actionsKey = ValueKey<String>('cycle.actions');
  static const Key addKey = ValueKey<String>('cycle.add');
  static const Key emptyKey = ValueKey<String>('cycle.empty');
  static const Key emptyAddKey = ValueKey<String>('cycle.empty.add');

  static Key historyRowKey(LumeRecordId id) =>
      ValueKey<String>('cycle.history.${id.value}');

  static Widget open(LumeToolRequest request) => CycleTool(request: request);
}

class CycleTool extends ConsumerStatefulWidget {
  const CycleTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<CycleTool> createState() => _CycleToolState();
}

class _CycleToolState extends ConsumerState<CycleTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final CycleRepository _repo = ref.read(cycleRepositoryProvider);

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

  void _failed(AppLocalizations l, CycleFailure f) {
    _say(switch (f.kind) {
      CycleFailureKind.conflict || CycleFailureKind.notFound => l.cycleErrConflict,
      _ => l.cycleErrFailed,
    }, tone: LumeToastTone.error);
  }

  Future<void> _addNew(
    AppLocalizations l,
    LumeDate today,
    List<CyclePeriod> periods,
  ) async {
    final CycleEntryResult? result = await CycleEntrySheet.show(
      context,
      isNew: true,
      initialStart: today,
      today: today,
      startTaken: (LumeDate d) => periods.any((CyclePeriod p) => p.startDate == d),
    );
    if (result == null || !mounted) return;
    final CycleResult<CycleWrite> r = _repo.logPeriod(result.start!, end: result.end);
    if (r.failure != null) return _failed(l, r.failure!);
    _say(l.cycleSavedToast);
  }

  Future<void> _editEntry(
    AppLocalizations l,
    LumeDate today,
    CyclePeriod period,
    List<CyclePeriod> periods,
  ) async {
    final CycleEntryResult? result = await CycleEntrySheet.show(
      context,
      isNew: false,
      initialStart: period.startDate,
      initialEnd: period.endDate,
      today: today,
      canDelete: true,
      startTaken: (LumeDate d) =>
          periods.any((CyclePeriod p) => p.id != period.id && p.startDate == d),
    );
    if (result == null || !mounted) return;
    if (result.delete) {
      final CycleResult<CycleWrite> r = _repo.deletePeriod(
        period.id,
        expectVersion: period.version,
      );
      if (r.failure != null) return _failed(l, r.failure!);
      _say(
        l.cycleDeletedToast,
        actionLabel: l.recUndo,
        onAction: () {
          final CycleResult<void> u = _repo.undo(r.value!);
          if (u.failure != null) _failed(l, u.failure!);
        },
      );
      return;
    }
    final CycleResult<CycleWrite> r = _repo.updatePeriod(
      period.id,
      start: result.start!,
      endDate: result.end,
      expectVersion: period.version,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _say(l.cycleSavedToast);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(context, countryCode: widget.request.user.country);
    final LumeDate? today = _today(context);
    final CycleSnapshot snapshot = _repo.view();

    LumeToolStatus status = LumeToolStatus.ready;
    CycleInsights? insights;
    if (snapshot.loading) {
      status = LumeToolStatus.loading;
    } else if (snapshot.failed || today == null) {
      status = LumeToolStatus.error;
    } else {
      insights = snapshot.insights(today);
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
        children: insights == null
            ? const <Widget>[]
            : _body(context, l, f, today!, snapshot.periods, insights),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeDate today,
    List<CyclePeriod> periods,
    CycleInsights insights,
  ) {
    if (insights.loggedCount == 0) {
      return <Widget>[
        LumeToolSection(
          child: LumeCollectionState(
            key: LumeCycleTool.emptyKey,
            kind: LumeCollectionStateKind.empty,
            title: l.cycleEmptyTitle,
            text: l.cycleEmptyText,
            icon: LumeIcons.droplet,
            primaryAction: LumeButton.accent(
              key: LumeCycleTool.emptyAddKey,
              label: l.cycleLogFirst,
              icon: LumeIcons.plus,
              onPressed: () => unawaited(_addNew(l, today, periods)),
            ),
          ),
        ),
      ];
    }

    final CyclePeriod? current = insights.currentPeriod;
    final Map<LumeDate, int> lengthByStart = <LumeDate, int>{
      for (final CycleHistoryEntry h in insights.history) h.start: h.length,
    };
    final List<CyclePeriod> past =
        periods.where((CyclePeriod p) => p.id != current?.id && lengthByStart.containsKey(p.startDate)).toList()
          ..sort((CyclePeriod a, CyclePeriod b) => b.startDate.compareTo(a.startDate));

    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeCycleTool.summaryKey,
          kicker: l.cycleDayKicker,
          value: insights.currentDay == null ? '—' : f.integer(insights.currentDay!),
          valueSmall: insights.currentDay != null && insights.averageLengthRounded != null
              ? '/ ${f.integer(insights.averageLengthRounded!)}'
              : null,
          caption: insights.phase == null
              ? l.cycleTrackingCaption
              : _phaseLabel(l, insights.phase!),
          aside: LumeProgressRing(
            value: insights.currentDay != null && insights.averageLengthRounded != null && insights.averageLengthRounded! > 0
                ? insights.currentDay! / insights.averageLengthRounded!
                : 0,
            centreValue: insights.currentDay == null ? '—' : f.integer(insights.currentDay!),
            label: l.cycleDayKicker,
          ),
          stats: <LumeStat>[
            if (insights.averageLengthRounded != null)
              LumeStat(
                value: l.ageDaysCount(insights.averageLengthRounded!),
                label: l.cycleAverageLabel,
              ),
            LumeStat(value: f.integer(insights.loggedCount), label: l.cycleLoggedCountLabel),
          ],
        ),
      ),
      if (current != null)
        LumeToolSection(
          child: LumeCompactRow(
            key: LumeCycleTool.currentRowKey,
            icon: LumeIcons.droplet,
            label: l.cycleStartedOn(f.dateMediumYear(current.startDate.toCalendarDateTime())),
            value: current.ongoing
                ? l.cycleOngoingBadge
                : f.dateMediumYear(current.endDate!.toCalendarDateTime()),
            onTap: () => unawaited(_editEntry(l, today, current, periods)),
          ),
        ),
      if (insights.hasPrediction)
        LumeToolSection(
          title: l.cycleNextEstimateKicker,
          child: Column(
            key: LumeCycleTool.nextKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              LumeCompactRow(
                icon: LumeIcons.calendar,
                label: f.dateMediumYear(insights.predictedNextStart!.toCalendarDateTime()),
                value: insights.isOverdue
                    ? l.billsOverdueBy(insights.overdueByDays!)
                    : l.subsRenewsIn(insights.daysUntilNext!),
                chevron: false,
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l.cycleNextEstimateCaption,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      if (past.isNotEmpty)
        LumeToolSection(
          title: l.cycleHistoryTitle,
          child: Column(
            key: LumeCycleTool.historyKey,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final CyclePeriod p in past)
                LumeCompactRow(
                  key: LumeCycleTool.historyRowKey(p.id),
                  icon: LumeIcons.droplet,
                  label: p.endDate == null
                      ? f.dateMedium(p.startDate.toCalendarDateTime())
                      : l.cycleDateRange(
                          f.dateMedium(p.startDate.toCalendarDateTime()),
                          f.dateMedium(p.endDate!.toCalendarDateTime()),
                        ),
                  value: l.ageDaysCount(lengthByStart[p.startDate]!),
                  onTap: () => unawaited(_editEntry(l, today, p, periods)),
                ),
            ],
          ),
        ),
      LumeToolSection(
        child: LumeButtonRow(
          key: LumeCycleTool.actionsKey,
          children: <Widget>[
            LumeButton.accent(
              key: LumeCycleTool.addKey,
              label: l.cycleLogPeriod,
              icon: LumeIcons.plus,
              onPressed: () => unawaited(_addNew(l, today, periods)),
            ),
          ],
        ),
      ),
    ];
  }

  String _phaseLabel(AppLocalizations l, CyclePhase phase) => switch (phase) {
    CyclePhase.menstrual => l.cyclePhaseMenstrual,
    CyclePhase.follicular => l.cyclePhaseFollicular,
    CyclePhase.ovulation => l.cyclePhaseOvulation,
    CyclePhase.luteal => l.cyclePhaseLuteal,
  };
}

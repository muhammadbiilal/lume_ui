/// Fasting Tracker — `tools/islamic/fasting.tool.js`, as a real record-backed
/// tool.
///
/// The reference's own composition, kept: a summary card leading with a
/// month figure and a streak caption, a voluntary/obligatory/missed
/// breakdown, a kind filter, a 30-day calendar and a recent-days list. What
/// it only drew, this does for real — every one of those numbers comes from
/// the reader's own logged fasts (`fasting_book.dart`), and a fast can be
/// logged, corrected and deleted, which the reference has no way to do at
/// all: its `fasting()` is six bare literals and a random-seeded heatmap
/// (`context.js:335-346`). Those are dropped entirely except for the one the
/// reference itself never computed either — the fixed `target: 12` behind
/// its progress ring — which is replaced by a real completion rate over the
/// reader's own logged attempts rather than approximated with another
/// invented number.
///
/// A single screen, like Cycle Tracker: logging a fast is one small sheet,
/// which is also where an entry already logged is edited or removed.
///
/// Faith-gated, like Qibla and every other Prayer & Islam feature — the
/// catalogue's `fasting` entry carries `faith: true`, so a non-Muslim reader
/// never reaches this screen at all; nothing in this file re-checks that.
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
import '../../../core/values/lume_record_id.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chip.dart';
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
import '../application/fasting_providers.dart';
import '../domain/fasting_book.dart';
import '../domain/fasting_failure.dart';
import '../domain/fasting_model.dart';
import '../domain/fasting_repository.dart';
import 'fasting_sheets.dart';

/// Which entries the "recent" list shows — the reference's own filter bar
/// values (`fasting.tool.js:29-33`).
enum _FastingFilter { all, voluntary, makeup }

abstract final class LumeFastingTool {
  static const String id = 'fasting';

  static const Key summaryKey = ValueKey<String>('fasting.summary');
  static const Key filterKey = ValueKey<String>('fasting.filter');
  static const Key calendarKey = ValueKey<String>('fasting.calendar');
  static const Key recentKey = ValueKey<String>('fasting.recent');
  static const Key actionsKey = ValueKey<String>('fasting.actions');
  static const Key addKey = ValueKey<String>('fasting.add');
  static const Key emptyKey = ValueKey<String>('fasting.empty');
  static const Key emptyAddKey = ValueKey<String>('fasting.empty.add');

  static Key recentRowKey(LumeRecordId id) =>
      ValueKey<String>('fasting.recent.${id.value}');

  static Widget open(LumeToolRequest request) => FastingTool(request: request);
}

class FastingTool extends ConsumerStatefulWidget {
  const FastingTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<FastingTool> createState() => _FastingToolState();
}

class _FastingToolState extends ConsumerState<FastingTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final FastingRepository _repo = ref.read(fastingRepositoryProvider);
  _FastingFilter _filter = _FastingFilter.all;

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

  void _failed(AppLocalizations l, FastingFailure f) {
    _say(switch (f.kind) {
      FastingFailureKind.conflict || FastingFailureKind.notFound => l.fastingErrConflict,
      _ => l.fastingErrFailed,
    }, tone: LumeToastTone.error);
  }

  Future<void> _addNew(
    AppLocalizations l,
    LumeDate today,
    List<FastEntry> entries,
  ) async {
    final FastEntryResult? result = await FastEntrySheet.show(
      context,
      isNew: true,
      initialDate: today,
      today: today,
      dateTaken: (LumeDate d) => entries.any((FastEntry e) => e.date == d),
    );
    if (result == null || !mounted) return;
    final FastingResult<FastingWrite> r = _repo.logFast(
      result.date!,
      kind: result.kind!,
      kept: result.kept,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _say(l.fastingSavedToast);
  }

  Future<void> _editEntry(
    AppLocalizations l,
    LumeDate today,
    FastEntry entry,
    List<FastEntry> entries,
  ) async {
    final FastEntryResult? result = await FastEntrySheet.show(
      context,
      isNew: false,
      initialDate: entry.date,
      today: today,
      initialKind: entry.kind,
      initialKept: entry.kept,
      canDelete: true,
      dateTaken: (LumeDate d) =>
          entries.any((FastEntry e) => e.id != entry.id && e.date == d),
    );
    if (result == null || !mounted) return;
    if (result.delete) {
      final FastingResult<FastingWrite> r = _repo.deleteFast(
        entry.id,
        expectVersion: entry.version,
      );
      if (r.failure != null) return _failed(l, r.failure!);
      _say(
        l.fastingDeletedToast,
        actionLabel: l.recUndo,
        onAction: () {
          final FastingResult<void> u = _repo.undo(r.value!);
          if (u.failure != null) _failed(l, u.failure!);
        },
      );
      return;
    }
    final FastingResult<FastingWrite> r = _repo.updateFast(
      entry.id,
      date: result.date!,
      kind: result.kind!,
      kept: result.kept,
      expectVersion: entry.version,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _say(l.fastingSavedToast);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(context, countryCode: widget.request.user.country);
    final LumeDate? today = _today(context);
    final FastingSnapshot snapshot = _repo.view();

    LumeToolStatus status = LumeToolStatus.ready;
    FastingInsights? insights;
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
            : _body(context, l, f, today!, snapshot.entries, insights),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeDate today,
    List<FastEntry> entries,
    FastingInsights insights,
  ) {
    if (insights.isEmpty) {
      return <Widget>[
        LumeToolSection(
          child: LumeCollectionState(
            key: LumeFastingTool.emptyKey,
            kind: LumeCollectionStateKind.empty,
            title: l.fastingEmptyTitle,
            text: l.fastingEmptyText,
            icon: LumeIcons.moon,
            primaryAction: LumeButton.accent(
              key: LumeFastingTool.emptyAddKey,
              label: l.fastingLogFirst,
              icon: LumeIcons.plus,
              onPressed: () => unawaited(_addNew(l, today, entries)),
            ),
          ),
        ),
      ];
    }

    final List<FastEntry> filtered = insights.recent.where((FastEntry e) {
      switch (_filter) {
        case _FastingFilter.all:
          return true;
        case _FastingFilter.voluntary:
          return e.kind == FastingKind.voluntary;
        case _FastingFilter.makeup:
          return e.kind == FastingKind.makeup;
      }
    }).toList();

    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeFastingTool.summaryKey,
          kicker: l.commonThisMonth,
          value: f.integer(insights.keptThisMonth),
          valueSmall: l.commonDays,
          caption: l.fastingStreakCaption(insights.currentStreak),
          aside: LumeProgressRing(
            value: insights.completionRate ?? 0,
            centreValue: f.integer(insights.keptCount),
            label: l.fastingProgressLabel,
          ),
          stats: <LumeStat>[
            LumeStat(value: f.integer(insights.voluntaryKept), label: l.fastingVoluntaryLabel),
            LumeStat(value: f.integer(insights.makeupKept), label: l.fastingObligatoryLabel),
            LumeStat(value: f.integer(insights.missedCount), label: l.fastingMissedLabel),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeFilterBar(
          key: LumeFastingTool.filterKey,
          children: <Widget>[
            LumeFilterChip(
              label: l.commonAll,
              selected: _filter == _FastingFilter.all,
              onTap: () => setState(() => _filter = _FastingFilter.all),
            ),
            LumeFilterChip(
              label: l.fastingKindSunnah,
              selected: _filter == _FastingFilter.voluntary,
              onTap: () => setState(() => _filter = _FastingFilter.voluntary),
            ),
            LumeFilterChip(
              label: l.fastingKindQada,
              selected: _filter == _FastingFilter.makeup,
              onTap: () => setState(() => _filter = _FastingFilter.makeup),
            ),
          ],
        ),
      ),
      LumeToolSection(
        title: l.fastingCalendarTitle,
        child: _FastingHeatGrid(key: LumeFastingTool.calendarKey, days: insights.heat, l: l),
      ),
      LumeToolSection(
        title: l.fastingRecentTitle,
        child: filtered.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  l.fastingEmptyText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            : LumeRows(
                key: LumeFastingTool.recentKey,
                children: <Widget>[
                  for (final FastEntry e in filtered)
                    LumeRichRow(
                      key: LumeFastingTool.recentRowKey(e.id),
                      icon: e.kept ? LumeIcons.checkCircle : LumeIcons.x,
                      iconTone: e.kept ? context.lume.tintAccent : null,
                      iconInk: e.kept ? context.lume.accent : null,
                      title: f.dateMediumYear(e.date.toCalendarDateTime()),
                      subtitle: e.kind == FastingKind.voluntary
                          ? l.fastingKindSunnah
                          : l.fastingKindQada,
                      badge: LumeBadge(
                        label: e.kept ? l.fastingKeptBadge : l.fastingNotKeptBadge,
                        tone: e.kept ? LumeBadgeTone.ok : LumeBadgeTone.neutral,
                      ),
                      onTap: () => unawaited(_editEntry(l, today, e, entries)),
                    ),
                ],
              ),
      ),
      LumeToolSection(
        child: LumeButtonRow(
          key: LumeFastingTool.actionsKey,
          children: <Widget>[
            LumeButton.accent(
              key: LumeFastingTool.addKey,
              label: l.fastingLogFast,
              icon: LumeIcons.plus,
              onPressed: () => unawaited(_addNew(l, today, entries)),
            ),
          ],
        ),
      ),
    ];
  }
}

/// The reader's own last 30 days — kept, missed, or not logged. Never a
/// randomised fixture like the reference's `heatDays(30, 9182, 0.45)`.
class _FastingHeatGrid extends StatelessWidget {
  const _FastingHeatGrid({super.key, required this.days, required this.l});

  final List<FastingHeatDay> days;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final int kept = days.where((FastingHeatDay d) => d.state == FastingDayState.kept).length;
    return Semantics(
      label: l.fastingCalendarA11y(kept, days.length),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: <Widget>[
            for (final FastingHeatDay d in days)
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: switch (d.state) {
                    FastingDayState.kept => lume.accent,
                    FastingDayState.missed => lume.down,
                    FastingDayState.none => lume.tintNeutral,
                  },
                  borderRadius: BorderRadius.circular(LumeRadius.xs / 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pregnancy — `tools/personal/pregnancy.tool.js`, rebuilt as a real
/// estimate rather than a fixture.
///
/// The reference draws a fixed `week: 22` forever, a due date 126 days from
/// whatever "now" happens to be, an invented weekly note, a size
/// comparison, a weight, two appointments and a six-point weight series —
/// none of it computed from anything the reader entered (`pregnancy.tool.js`,
/// `context.js` `pregnancy()`). This build asks for the one date a due-date
/// estimate actually needs — the first day of the reader's last period —
/// and works every figure out from it on Naegele's rule
/// ([LumePregnancy.of]): the week, the trimester, the due date, the days
/// either side of it, and the four standard gestational-age milestones.
/// The invented note, size, weight and weight series are dropped entirely,
/// the same call Meal Plan made on its own bare literals
/// (`MEALPLAN_PROPOSAL.md` §2, D-M2).
///
/// A single screen: one stored date, so there is no separate list/detail
/// navigation, only the field that sets it and the dashboard it drives.
///
/// **Sensitive** (catalogue `sensitive: true`): the frame's own privacy note
/// covers this tool without anything drawn here, and — like Cycle Tracker —
/// there is no share button (`supports` carries no `sharing`), so nothing
/// here is ever handed to the system share sheet.
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
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/pregnancy_providers.dart';
import '../domain/pregnancy_failure.dart';
import '../domain/pregnancy_maths.dart';
import '../domain/pregnancy_repository.dart';

abstract final class LumePregnancyTool {
  static const String id = 'pregnancy';

  static const Key lmpKey = ValueKey<String>('pregnancy.lmp');
  static const Key emptyKey = ValueKey<String>('pregnancy.empty');
  static const Key summaryKey = ValueKey<String>('pregnancy.summary');
  static const Key milestonesKey = ValueKey<String>('pregnancy.milestones');
  static const Key clearKey = ValueKey<String>('pregnancy.clear');

  static Widget open(LumeToolRequest request) =>
      PregnancyTool(request: request);
}

class PregnancyTool extends ConsumerStatefulWidget {
  const PregnancyTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<PregnancyTool> createState() => _PregnancyToolState();
}

class _PregnancyToolState extends ConsumerState<PregnancyTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final PregnancyRepository _repo = ref.read(pregnancyRepositoryProvider);

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

  void _failed(AppLocalizations l, PregnancyFailure f) {
    _say(switch (f.kind) {
      PregnancyFailureKind.conflict ||
      PregnancyFailureKind.notFound => l.pregnancyErrConflict,
      _ => l.pregnancyErrFailed,
    }, tone: LumeToastTone.error);
  }

  Future<void> _pick(LumeDate today) async {
    final PregnancySnapshot before = _repo.view();
    final LumeDate initial = before.profile?.lmp ?? today;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial.toCalendarDateTime(),
      firstDate: today
          .addDays(-LumePregnancy.maxPlausibleDays)
          .toCalendarDateTime(),
      lastDate: today.toCalendarDateTime(),
      helpText: AppLocalizations.of(context).pregnancyLmpLabel,
    );
    if (picked == null || !mounted) return;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeDate lmp = LumeDate(picked.year, picked.month, picked.day);
    final PregnancyResult<PregnancyWrite> r = _repo.setLmp(lmp, today);
    if (r.failure != null) return _failed(l, r.failure!);
    _say(l.commonSaved);
  }

  Future<void> _clear() async {
    final AppLocalizations l = AppLocalizations.of(context);
    final PregnancyResult<PregnancyWrite> r = _repo.clear();
    if (r.failure != null) return _failed(l, r.failure!);
    if (r.value!.receipt.revision != 0) {
      _say(
        l.pregnancyClearedToast,
        actionLabel: l.recUndo,
        onAction: () {
          final PregnancyResult<void> u = _repo.undo(r.value!);
          if (u.failure != null) _failed(l, u.failure!);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: widget.request.user.country,
    );
    final LumeDate? today = _today(context);
    final PregnancySnapshot snapshot = _repo.view();

    LumeToolStatus status = LumeToolStatus.ready;
    if (snapshot.loading) {
      status = LumeToolStatus.loading;
    } else if (snapshot.failed || today == null) {
      status = LumeToolStatus.error;
    }

    final LumePregnancy? estimate =
        (status == LumeToolStatus.ready &&
            snapshot.profile != null &&
            today != null)
        ? LumePregnancy.of(snapshot.profile!.lmp, today)
        : null;

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
        children: today == null
            ? const <Widget>[]
            : _body(l, f, today, snapshot, estimate),
      ),
    );
  }

  List<Widget> _body(
    AppLocalizations l,
    LumeFormatting f,
    LumeDate today,
    PregnancySnapshot snapshot,
    LumePregnancy? estimate,
  ) => <Widget>[
    LumeToolSection(
      child: LumeCard(
        child: LumeToolField(
          key: LumePregnancyTool.lmpKey,
          label: l.pregnancyLmpLabel,
          value: snapshot.profile == null
              ? l.pregnancyNotSet
              : f.dateNumeric(snapshot.profile!.lmp.toCalendarDateTime()),
          kind: LumeFieldKind.date,
          wide: true,
          hint: l.pregnancyLmpHint,
          onTap: () => unawaited(_pick(today)),
        ),
      ),
    ),
    if (estimate == null)
      LumeToolSection(
        child: LumeToolState(
          key: LumePregnancyTool.emptyKey,
          icon: LumeIcons.baby,
          title: l.pregnancyEmptyTitle,
          text: l.pregnancyEmptyText,
        ),
      )
    else ...<Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumePregnancyTool.summaryKey,
          kicker: l.commonWeek,
          value: f.integer(estimate.week),
          unit: l.pregnancyOfWeeks(f.integer(LumePregnancy.gestationWeeks)),
          caption:
              '${l.pregnancyTrimester(f.integer(estimate.trimester))} · '
              '${l.commonDue} ${f.dateMediumYear(estimate.dueDate.toCalendarDateTime())}',
          stats: <LumeStat>[
            LumeStat(
              value: f.integer(estimate.daysPregnant),
              label: l.pregnancyDaysPregnant,
            ),
            LumeStat(
              value: f.integer(estimate.daysUntilDue.abs()),
              label: estimate.overdue
                  ? l.pregnancyDaysOverdue
                  : l.pregnancyDaysToGo,
            ),
            LumeStat(
              value: f.dateShort(estimate.dueDate.toCalendarDateTime()),
              label: l.pregnancyDueDateLabel,
            ),
          ],
          aside: LumeProgressRing(
            value: estimate.progress,
            centreValue: '${(estimate.progress * 100).round()}%',
            label: l.pregnancyProgressLabel,
          ),
        ),
      ),
      LumeToolSection(
        title: l.pregnancyMilestonesTitle,
        child: LumeRows(
          key: LumePregnancyTool.milestonesKey,
          children: <Widget>[
            for (final LumePregnancyMilestone m in estimate.milestones)
              LumeCompactRow(
                icon: m.done ? LumeIcons.checkCircle : LumeIcons.calendar,
                label: _milestoneLabel(l, m.week),
                value: f.dateMediumYear(m.date.toCalendarDateTime()),
                chevron: false,
              ),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeButton.dangerGhost(
          key: LumePregnancyTool.clearKey,
          label: l.actionClear,
          block: true,
          onPressed: () => unawaited(_clear()),
        ),
      ),
    ],
  ];

  String _milestoneLabel(AppLocalizations l, int week) => switch (week) {
    12 => l.pregnancyMilestone12,
    20 => l.pregnancyMilestone20,
    28 => l.pregnancyMilestone28,
    _ => l.pregnancyMilestone37,
  };
}

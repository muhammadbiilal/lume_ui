/// Meal Plan — `tools/personal/mealplan.tool.js`, as a real record-backed
/// tool (`MEALPLAN_PROPOSAL.md`).
///
/// The reference's composition, in its order: the summary card, the week
/// as seven expandable days each holding three slots, then Build a
/// shopping list / Browse recipes. What it only drew, this does: every
/// slot's content is the reader's own text (nothing rotated in from a
/// fixture), the summary's number is a real count of filled slots, and a
/// slot can be filled in, edited and cleared — the reference has no CRUD
/// at all, not even a stub. The reference's calorie chart and its three
/// summary stats (kcal/shopItems/cost) are dropped entirely (D-M2): all
/// five of its headline figures are bare literals with no computation
/// behind them, and `kcal: 1980` doesn't even agree with the real
/// per-day sums the reference computes beside it from the same fixture.
///
/// A single screen, unlike Goals/Subscriptions/Installments' multi-view
/// hosts — the week's 21 slots are fixed structure, not an open-ended
/// list, so there is no separate list/detail/form navigation, only the
/// one screen and a small sheet to edit a slot.
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
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/mealplan_providers.dart';
import '../domain/mealplan_book.dart';
import '../domain/mealplan_failure.dart';
import '../domain/mealplan_model.dart';
import '../domain/mealplan_repository.dart';
import 'mealplan_sheets.dart';
import 'mealplan_text.dart';

abstract final class LumeMealPlanTool {
  static const String id = 'mealplan';

  static const Key summaryKey = ValueKey<String>('mealplan.summary');
  static const Key weekKey = ValueKey<String>('mealplan.week');
  static const Key actionsKey = ValueKey<String>('mealplan.actions');
  static const Key shoppingKey = ValueKey<String>('mealplan.shopping');
  static const Key recipesKey = ValueKey<String>('mealplan.recipes');

  static Key dayKey(LumeDate d) => ValueKey<String>('mealplan.day.${d.toIso()}');
  static Key slotKey(LumeDate d, MealSlot s) =>
      ValueKey<String>('mealplan.slot.${d.toIso()}.${s.name}');

  static Widget open(LumeToolRequest request) => MealPlanTool(request: request);
}

class MealPlanTool extends ConsumerStatefulWidget {
  const MealPlanTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<MealPlanTool> createState() => _MealPlanToolState();
}

class _MealPlanToolState extends ConsumerState<MealPlanTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final MealPlanRepository _repo = ref.read(mealPlanRepositoryProvider);

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

  void _failed(AppLocalizations l, MealPlanFailure f) {
    _say(switch (f.kind) {
      MealPlanFailureKind.conflict || MealPlanFailureKind.notFound => l.mealErrConflict,
      _ => l.mealErrFailed,
    }, tone: LumeToastTone.error);
  }

  Future<void> _editSlot(AppLocalizations l, LumeDate date, MealSlot slot, String current) async {
    final String? result = await mealPlanEditSlot(
      context,
      title: MealPlanText.slot(l, slot),
      subtitle: LumeFormatting.of(context).dateMediumYear(date.toCalendarDateTime()),
      initial: current,
    );
    if (result == null || !mounted) return;
    if (result.isEmpty) {
      final MealPlanResult<MealPlanWrite> r = _repo.clearSlot(date, slot);
      if (r.failure != null) return _failed(l, r.failure!);
      if (r.value!.receipt.revision != 0) {
        _say(
          l.mealSlotClearedToast,
          actionLabel: l.recUndo,
          onAction: () {
            final MealPlanResult<void> u = _repo.undo(r.value!);
            if (u.failure != null) _failed(l, u.failure!);
          },
        );
      }
      return;
    }
    final MealPlanResult<MealPlanWrite> r = _repo.setSlot(date, slot, result);
    if (r.failure != null) return _failed(l, r.failure!);
    _say(l.mealSlotSavedToast);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(context, countryCode: widget.request.user.country);
    final LumeDate? today = _today(context);
    final MealPlanSnapshot snapshot = _repo.view();

    LumeToolStatus status = LumeToolStatus.ready;
    MealPlanWeek? week;
    if (snapshot.loading) {
      status = LumeToolStatus.loading;
    } else if (snapshot.failed || today == null) {
      status = LumeToolStatus.error;
    } else {
      week = snapshot.week(today);
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
        children: week == null ? const <Widget>[] : _body(context, l, f, week),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    MealPlanWeek week,
  ) => <Widget>[
    LumeToolSection(
      child: LumeSummaryCard(
        key: LumeMealPlanTool.summaryKey,
        kicker: l.mealSummaryKicker,
        value: f.integer(week.filled),
        valueSmall: '/ ${f.integer(MealPlanWeek.totalSlots)}',
        caption: l.mealPlannedCaption,
      ),
    ),
    LumeToolSection(
      title: l.mealWeekTitle,
      child: Column(
        key: LumeMealPlanTool.weekKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final MealPlanDay day in week.days) _dayRow(context, l, f, day),
        ],
      ),
    ),
    LumeToolSection(
      child: LumeButtonRow(
        key: LumeMealPlanTool.actionsKey,
        children: <Widget>[
          LumeButton.accent(
            key: LumeMealPlanTool.shoppingKey,
            label: l.mealToShopping,
            icon: LumeIcons.cart,
            onPressed: () => widget.request.onOpenRelated?.call('shopping'),
          ),
          LumeButton(
            key: LumeMealPlanTool.recipesKey,
            label: l.mealBrowseRecipes,
            icon: LumeIcons.utensils,
            onPressed: () => widget.request.onOpenRelated?.call('recipes'),
          ),
        ],
      ),
    ),
  ];

  Widget _dayRow(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    MealPlanDay day,
  ) {
    final String label = day.today
        ? l.commonToday
        : f.weekdayLong(day.date.toCalendarDateTime());
    final String summary = day.filledCount == 0
        ? l.mealEmptySlot
        : '${day.filledCount}/${MealSlot.values.length}';
    return LumeExpandRow(
      key: LumeMealPlanTool.dayKey(day.date),
      initiallyExpanded: day.today,
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          Text(summary, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final MealSlot slot in MealSlot.values)
            LumeCompactRow(
              key: LumeMealPlanTool.slotKey(day.date, slot),
              icon: MealPlanText.icon(slot),
              label: MealPlanText.slot(l, slot),
              value: day.slot(slot)?.text ?? l.mealEmptySlot,
              onTap: () => unawaited(
                _editSlot(l, day.date, slot, day.slot(slot)?.text ?? ''),
              ),
            ),
        ],
      ),
    );
  }
}

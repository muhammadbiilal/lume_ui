/// Goals — `tools/personal/goals.tool.js`, as a real record-backed tool
/// (`GOALS_PROPOSAL.md`).
///
/// The reference's composition, in its order: the summary card, the goals
/// with their progress bars, the contributions chart, then Add/Share. What
/// it only drew, this does: goals and their contributions are the reader's
/// own records (nothing seeded), every figure is derived from them, a goal
/// can be added, edited, contributed to, completed, abandoned and deleted.
/// It is sensitive: the frame shows its privacy note and nothing here
/// reaches Home (D-G1). It sends no notification (D-G9).
///
/// A dedicated host, as Installments': the list, a goal and the form take
/// the screen in turn; each write is one transaction through
/// [GoalsRepository], and each typed failure has its own answer.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../app/providers/shell_provider.dart';
import '../../../app/providers/time_zone_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/navigation/lume_tool_frame.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chart.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../ledger/presentation/ledger_text.dart';
import '../../onboarding/domain/onboarding_state.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/goals_providers.dart';
import '../domain/goals_book.dart';
import '../domain/goals_failure.dart';
import '../domain/goals_model.dart';
import '../domain/goals_repository.dart';
import 'goals_sheets.dart';
import 'goals_text.dart';

enum _View { list, goal, form }

abstract final class LumeGoalsTool {
  static const String id = 'goals';

  static const Key summaryKey = ValueKey<String>('goals.summary');
  static const Key listKey = ValueKey<String>('goals.list');
  static const Key chartKey = ValueKey<String>('goals.chart');
  static const Key emptyKey = ValueKey<String>('goals.empty');
  static const Key addKey = ValueKey<String>('goals.add');
  static const Key goalKey = ValueKey<String>('goals.goal');
  static const Key contributeKey = ValueKey<String>('goals.contribute');
  static const Key historyKey = ValueKey<String>('goals.history');
  static const Key editKey = ValueKey<String>('goals.edit');
  static const Key completeKey = ValueKey<String>('goals.complete');
  static const Key abandonKey = ValueKey<String>('goals.abandon');
  static const Key reactivateKey = ValueKey<String>('goals.reactivate');
  static const Key deleteKey = ValueKey<String>('goals.delete');
  static const Key formKey = ValueKey<String>('goals.form');
  static const Key saveKey = ValueKey<String>('goals.save');
  static const Key nameField = ValueKey<String>('goals.field.name');
  static const Key noteField = ValueKey<String>('goals.field.note');
  static const Key targetField = ValueKey<String>('goals.field.target');
  static const Key targetDateField = ValueKey<String>('goals.field.targetDate');
  static Key row(String goal) => ValueKey<String>('goals.row.$goal');
  static Key contribution(String id) => ValueKey<String>('goals.contribution.$id');

  static Widget open(LumeToolRequest request) => GoalsTool(request: request);
}

class GoalsTool extends ConsumerStatefulWidget {
  const GoalsTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<GoalsTool> createState() => _GoalsToolState();
}

/// A goal form's state.
class _GoalDraft {
  _GoalDraft({
    this.id,
    this.version,
    required this.currency,
    this.targetDate,
    this.icon = GoalIcon.target,
    String name = '',
    String note = '',
    String target = '',
  }) : name = TextEditingController(text: name),
       note = TextEditingController(text: note),
       target = TextEditingController(text: target) {
    _initial = _state;
  }

  final LumeRecordId? id;
  final int? version;
  LumeCurrency? currency;
  LumeDate? targetDate;
  GoalIcon icon;
  final TextEditingController name;
  final TextEditingController note;
  final TextEditingController target;
  final Map<String, String> errors = <String, String>{};
  late final String _initial;

  String get _state => <Object?>[
    name.text,
    note.text,
    target.text,
    currency?.code,
    targetDate?.toIso(),
    icon.name,
  ].join('\u0000');

  bool get dirty => _state != _initial;

  void dispose() {
    name.dispose();
    note.dispose();
    target.dispose();
  }
}

class _GoalsToolState extends ConsumerState<GoalsTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final GoalsRepository _repo = ref.read(goalsRepositoryProvider);
  late final LumeToolSession _session = ref.read(toolSessionProvider);

  /// The body, to find the frame's scroll from: a new view opens at its top.
  final GlobalKey _body = GlobalKey();

  _View _view = _View.list;
  LumeRecordId? _goal;
  _GoalDraft? _draft;
  bool _linked = false;

  String get _id => widget.request.feature.id;
  String? _read(String key) => _session.read(_id, key);
  void _write(String key, String value) => _session.write(_id, key, value);

  @override
  void initState() {
    super.initState();
    _repo.open();
    _repo.changes.addListener(_changed);
    final LumeRecordId? kept = LumeRecordId.tryParse(_read('goal') ?? '');
    if (kept != null) {
      _goal = kept;
      _view = _View.goal;
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repo.changes.removeListener(_changed);
    _draft?.dispose();
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

  // ---------------------------------------------------------------- context

  /// The reader's calendar date in their resolved zone, or `null` when it
  /// cannot be worked out: nothing is then dated against "this month".
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

  LumeCurrency? _currency() {
    final LumeProfileRecord p = ref.read(startupControllerProvider).state.profile;
    final String code = p.currency != LumePreference.auto
        ? p.currency
        : (ref
                  .read(startupControllerProvider)
                  .state
                  .countries
                  ?.currencyOf(widget.request.user.country) ??
              '');
    return GoalsRepository.defaultCurrency(code);
  }

  // ------------------------------------------------------------ navigation

  void _go(_View v, {LumeRecordId? goal}) {
    final bool moved = v != _view || (goal != null && goal != _goal);
    setState(() {
      _view = v;
      if (goal != null) _goal = goal;
      _write('goal', v == _View.list ? '' : (_goal?.value ?? ''));
    });
    if (!moved) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? c = _body.currentContext;
      final ScrollPosition? p = c == null ? null : Scrollable.maybeOf(c)?.position;
      if (p != null && p.pixels != 0) p.jumpTo(0);
    });
  }

  Future<void> _back() async {
    switch (_view) {
      case _View.list:
        widget.request.onBack?.call();
      case _View.goal:
        _go(_View.list);
      case _View.form:
        final _GoalDraft? d = _draft;
        if (d != null && d.dirty && !await _confirmDiscard()) return;
        if (!mounted) return;
        _draft = null;
        d?.dispose();
        _go(d?.id != null ? _View.goal : _View.list);
    }
  }

  Future<bool> _confirmDiscard() async {
    final AppLocalizations l = AppLocalizations.of(context);
    return await goalsDecide(
          context,
          title: l.recDiscardAsk,
          text: l.recDiscardText,
          confirm: l.recDiscard,
          cancel: l.recKeepEditing,
          destructive: true,
        ) ??
        false;
  }

  void _addGoal() {
    _draft?.dispose();
    _draft = _GoalDraft(currency: _currency());
    _go(_View.form);
  }

  void _editGoal(Goal g) {
    _draft?.dispose();
    _draft = _GoalDraft(
      id: g.id,
      version: g.version,
      currency: g.currency,
      targetDate: g.targetDate,
      icon: g.icon,
      name: g.name,
      note: g.note ?? '',
      target: g.target.toDecimalString(),
    );
    _go(_View.form);
  }

  // ---------------------------------------------------------------- writes

  void _failed(AppLocalizations l, GoalsFailure f) {
    _say(switch (f.kind) {
      GoalsFailureKind.conflict || GoalsFailureKind.notFound => l.goalsErrConflict,
      GoalsFailureKind.damaged => l.goalsErrDamaged,
      GoalsFailureKind.closed => l.goalsErrClosed,
      GoalsFailureKind.overflow => l.goalsErrTooLarge,
      _ => l.goalsErrFailed,
    }, tone: LumeToastTone.error);
  }

  void _undoable(AppLocalizations l, String message, GoalsWrite w) => _say(
    message,
    actionLabel: l.recUndo,
    onAction: () {
      final GoalsResult<void> r = _repo.undo(w);
      if (r.failure != null) _failed(l, r.failure!);
    },
  );

  Future<void> _saveGoal(AppLocalizations l) async {
    final _GoalDraft d = _draft!;
    final Map<String, String> errors = <String, String>{};
    final intl.NumberFormat nf = intl.NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag().replaceAll('-', '_'),
    );

    final String name = d.name.text.trim();
    if (name.isEmpty) errors['name'] = l.goalsErrName;
    if (name.length > kGoalsNameMax) errors['name'] = l.goalsErrLong;
    if (d.note.text.length > kGoalsNoteMax) errors['note'] = l.goalsErrLong;
    if (d.currency == null) errors['currency'] = l.goalsErrTarget;
    LumeMoney? target;
    if (d.currency != null) {
      final LedgerParsedAmount p = ledgerParseAmount(
        l,
        d.target.text,
        d.currency!,
        decimalSeparator: nf.symbols.DECIMAL_SEP,
        groupSeparator: nf.symbols.GROUP_SEP,
      );
      if (p.error != null) {
        errors['target'] = p.error!;
      } else {
        target = p.money;
      }
    }
    setState(() {
      d.errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) return;

    final GoalDraft draft = GoalDraft(
      name: name,
      note: d.note.text,
      target: target!,
      targetDate: d.targetDate,
      icon: d.icon,
    );
    final GoalsResult<GoalsWrite> r = d.id == null
        ? _repo.addGoal(draft)
        : _repo.editGoal(d.id!, draft, version: d.version!);
    if (!mounted) return;
    final GoalsFailure? failure = r.failure;
    if (failure != null) {
      if (failure.field == 'currency' && failure.reason == 'withdrawn') {
        setState(() => d.errors['currency'] = l.goalsErrWithdrawn(d.currency!.code));
        return;
      }
      if (failure.field == 'currency' && failure.reason == 'hasContributions') {
        setState(
          () => d.errors['currency'] = l.goalsErrCurrencyLocked(d.currency!.code),
        );
        return;
      }
      _failed(l, failure);
      return;
    }
    final GoalsWrite w = r.value!;
    _draft = null;
    d.dispose();
    _go(_View.goal, goal: w.goal!.id);
    _say(l.commonSaved);
  }

  Future<void> _contribute(AppLocalizations l, GoalView v, LumeDate? today) async {
    final (LumeMoney, LumeDate)? entered = await GoalsContributeSheet.show(
      context,
      currency: v.currency,
      initial: today,
      dateText: (LumeDate d) =>
          LumeFormatting.of(context).dateMediumYear(d.toCalendarDateTime()),
    );
    if (entered == null || !mounted) return;
    final GoalsResult<GoalsWrite> r = _repo.addContribution(
      v.goal.id,
      entered.$1,
      entered.$2,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _undoable(l, l.goalsContributionAdded, r.value!);
  }

  Future<void> _setState(AppLocalizations l, GoalView v, GoalState state) async {
    final (String title, String text, String toast)? copy = switch (state) {
      GoalState.completed => (l.goalsMarkCompleteAsk, l.goalsMarkCompleteText, l.goalsMarkCompleteToast),
      GoalState.abandoned => (l.goalsAbandonAsk, l.goalsAbandonText, l.goalsAbandonToast),
      GoalState.active => null,
    };
    if (copy != null) {
      final bool? ok = await goalsDecide(
        context,
        title: copy.$1,
        text: copy.$2,
        confirm: l.actionConfirm,
      );
      if (ok != true || !mounted) return;
    }
    final GoalsResult<GoalsWrite> r = _repo.setState(
      v.goal.id,
      state,
      version: v.goal.version,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _say(copy?.$3 ?? l.goalsReactivatedToast);
  }

  Future<void> _delete(AppLocalizations l, GoalView v) async {
    final bool ok = await goalsConfirmDelete(
      context,
      title: l.goalsDeleteAsk,
      text: l.goalsDeleteText,
    );
    if (!ok || !mounted) return;
    final GoalsResult<GoalsWrite> r = _repo.deleteGoal(v.goal.id, version: v.goal.version);
    if (r.failure != null) return _failed(l, r.failure!);
    _go(_View.list);
    _undoable(l, l.goalsDeletedToast, r.value!);
  }

  Future<void> _voidContribution(AppLocalizations l, GoalContribution c) async {
    final GoalsResult<GoalsWrite> r = _repo.setContributionVoided(
      c.id,
      true,
      version: c.version,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _undoable(l, l.goalsContributionVoidedToast, r.value!);
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: widget.request.user.country,
    );
    final LumeDate? today = _today(context);
    final GoalsSnapshot snapshot = _repo.view();

    GoalsBook? book;
    LumeToolStatus status = LumeToolStatus.ready;
    if (snapshot.loading) {
      status = LumeToolStatus.loading;
    } else if (snapshot.failed) {
      status = LumeToolStatus.error;
    } else {
      try {
        book = snapshot.book(today);
        for (final LumeCurrency c in book.currencies) {
          book.summary(c);
        }
      } on LumeMoneyException {
        book = null;
        status = LumeToolStatus.error;
      }
    }
    if (book != null && !_linked) {
      _linked = true;
      _deepLink(l, book);
    }

    final (String? title, List<Widget> body, bool bare) = switch (_view) {
      _ when book == null => (null, const <Widget>[], false),
      _View.list => (null, _list(context, l, f, book, today), false),
      _View.goal => _goalScreen(context, l, f, book, today),
      _View.form => (
        _draft?.id == null ? l.goalsNewGoal : l.goalsEditGoal,
        _form(context, l),
        true,
      ),
    };

    return PopScope(
      canPop: _view == _View.list,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) unawaited(_back());
      },
      child: LumeToolScreen(
        key: _host,
        feature: widget.request.feature,
        user: widget.request.user,
        onBack: () => unawaited(_back()),
        onOpenRelated: widget.request.onOpenRelated,
        status: status,
        onRetry: () => setState(_repo.retry),
        title: title,
        bare: bare,
        shareCard: book == null || book.isEmpty
            ? null
            : () {
                final GoalsCurrencySummary s = book!.summary(book.currencies.first);
                return LumeShareCard.forFeature(
                  sensitive: widget.request.feature.sensitive,
                  kind: LumeShareKind.reminder,
                  text: l.goalsShareText(
                    f.amount(s.saved),
                    f.amount(s.target),
                    f.integer((s.ratio * 100).round()),
                  ),
                  source: f.dateLongYear(LumeClockScope.of(context).now()),
                );
              },
        headerActions: _view == _View.form
            ? <Widget>[
                LumeTextButton(
                  key: LumeGoalsTool.saveKey,
                  label: l.actionSave,
                  onPressed: () => unawaited(_saveGoal(l)),
                ),
              ]
            : null,
        body: Column(
          key: _body,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: body,
        ),
      ),
    );
  }

  void _deepLink(AppLocalizations l, GoalsBook book) {
    final String? asked = widget.request.query['goal'];
    if (asked == null) {
      if (_goal != null && book.goal(_goal!) == null) {
        _view = _View.list;
        _goal = null;
      }
      return;
    }
    final LumeRecordId? id = LumeRecordId.tryParse(asked);
    if (id != null && book.goal(id) != null) {
      _goal = id;
      _view = _View.goal;
      return;
    }
    _view = _View.list;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _say(l.goalsNotFound, tone: LumeToastTone.info),
    );
  }

  // ------------------------------------------------------------------ list

  List<Widget> _list(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    GoalsBook book,
    LumeDate? today,
  ) {
    if (book.goals.isEmpty) {
      return <Widget>[
        LumeToolSection(
          child: LumeToolState(
            key: LumeGoalsTool.emptyKey,
            icon: LumeIcons.target,
            title: l.goalsEmptyTitle,
            text: l.goalsEmptyText,
          ),
        ),
        LumeToolSection(
          child: LumeButton.accent(
            key: LumeGoalsTool.addKey,
            label: l.goalsAddGoal,
            block: true,
            onPressed: _addGoal,
          ),
        ),
      ];
    }

    final bool withCode = book.currencies.length > 1;
    final LumeCurrency primary = book.currencies.first;
    final GoalsCurrencySummary summary = book.summary(primary);
    final List<GoalsMonth>? months = book.months(primary);

    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeGoalsTool.summaryKey,
          kicker: l.goalsSummaryKicker,
          value: f.amount(summary.saved, withCode: withCode),
          caption: l.goalsSummaryCaption(f.amount(summary.target, withCode: withCode)),
          aside: LumeProgressRing(
            value: summary.ratio,
            centreValue: f.integer((summary.ratio * 100).round().clamp(0, 999)),
            valueText: f.percent(summary.ratio * 100),
          ),
          stats: <LumeStat>[
            LumeStat(value: f.integer(summary.activeGoals), label: l.goalsStatActive),
            LumeStat(
              value: summary.thisMonth == null
                  ? '—'
                  : f.amount(summary.thisMonth!, compact: true),
              label: l.goalsStatThisMonth,
            ),
            LumeStat(
              value: summary.nextComplete?.goal.name ?? '—',
              label: l.goalsStatNext,
            ),
          ],
        ),
      ),
      LumeToolSection(
        title: l.goalsYourGoals,
        child: Column(
          key: LumeGoalsTool.listKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final GoalView v in book.goals)
              if (v.goal.state == GoalState.active && !v.damaged)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _goalCard(context, l, f, v),
                ),
          ],
        ),
      ),
      if (book.goals.any(
        (GoalView v) => v.goal.state != GoalState.active && !v.damaged,
      ))
        LumeToolSection(
          title: l.goalsOtherGoals,
          child: LumeRows(
            children: <Widget>[
              for (final GoalView v in book.goals)
                if (v.goal.state != GoalState.active && !v.damaged)
                  LumeCompactRow(
                    key: LumeGoalsTool.row(v.goal.id.value),
                    label: v.goal.name,
                    subtitle: GoalsText.state(l, v.goal.state),
                    value: f.amount(v.saved),
                    onTap: () => _go(_View.goal, goal: v.goal.id),
                  ),
            ],
          ),
        ),
      if (months != null && months.any((GoalsMonth m) => !m.total.isZero))
        LumeToolSection(
          title: l.goalsChartTitle,
          child: LumeCard(
            child: LumeBarChart(
              key: LumeGoalsTool.chartKey,
              values: <double>[for (final GoalsMonth m in months) m.total.minor.toDouble()],
              labels: <String>[for (final GoalsMonth m in months) f.monthShort(m.month.toCalendarDateTime())],
              label: l.goalsChartTitle,
              highlight: months.length - 1,
            ),
          ),
        ),
      LumeToolSection(
        child: LumeButton.accent(
          key: LumeGoalsTool.addKey,
          label: l.goalsAddGoal,
          block: true,
          onPressed: _addGoal,
        ),
      ),
    ];
  }

  Widget _goalCard(BuildContext context, AppLocalizations l, LumeFormatting f, GoalView v) {
    final String meta = v.goal.targetDate == null
        ? l.goalsOfTarget(f.amount(v.saved), f.amount(v.target))
        : '${l.goalsOfTarget(f.amount(v.saved), f.amount(v.target))} · '
              '${l.goalsByDate(f.dateMediumYear(v.goal.targetDate!.toCalendarDateTime()))}';
    final String footer = v.reached
        ? l.goalsReached
        : v.projectedMonths == null
        ? l.goalsToGo(f.amount(v.remaining))
        : '${l.goalsToGo(f.amount(v.remaining))} · ${l.goalsProjectedDate(v.projectedMonths!)}';
    return LumeCard(
      key: LumeGoalsTool.row(v.goal.id.value),
      onTap: () => _go(_View.goal, goal: v.goal.id),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            LumeRichRow(
              icon: GoalsText.icon(v.goal.icon),
              title: v.goal.name,
              value: f.percent(v.pct.clamp(0, 9.99) * 100),
            ),
            const SizedBox(height: 10),
            LumeProgressBar(value: v.pct, label: v.goal.name),
            const SizedBox(height: 8),
            Text(meta, style: Theme.of(context).textTheme.bodySmall),
            Text(footer, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ goal

  (String?, List<Widget>, bool) _goalScreen(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    GoalsBook book,
    LumeDate? today,
  ) {
    final GoalView? v = _goal == null ? null : book.goal(_goal!);
    if (v == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _go(_View.list));
      return (null, const <Widget>[], false);
    }
    return (
      v.goal.name,
      <Widget>[
        LumeToolSection(
          child: LumeSummaryCard(
            key: LumeGoalsTool.goalKey,
            kicker: GoalsText.state(l, v.goal.state),
            value: f.amount(v.saved),
            caption: l.goalsSummaryCaption(f.amount(v.target)),
            aside: LumeProgressRing(
              value: v.pct,
              centreValue: f.integer((v.pct * 100).round().clamp(0, 999)),
            ),
          ),
        ),
        LumeToolSection(
          child: LumeButton.accent(
            key: LumeGoalsTool.contributeKey,
            label: l.goalsAddContribution,
            block: true,
            onPressed: v.goal.state == GoalState.active
                ? () => unawaited(_contribute(l, v, today))
                : null,
          ),
        ),
        LumeToolSection(
          title: l.goalsHistoryTitle,
          child: v.contributions.isEmpty
              ? LumeToolState(
                  key: LumeGoalsTool.historyKey,
                  icon: LumeIcons.target,
                  title: l.goalsHistoryEmpty,
                  text: '',
                )
              : LumeRows(
                  key: LumeGoalsTool.historyKey,
                  children: <Widget>[
                    for (final GoalContribution c in v.contributions)
                      LumeRichRow(
                        key: LumeGoalsTool.contribution(c.id.value),
                        title: f.amount(c.amount),
                        subtitle: f.dateMediumYear(c.on.toCalendarDateTime()),
                        trailing: LumeTextButton(
                          label: l.goalsVoidContribution,
                          onPressed: () => unawaited(_voidContribution(l, c)),
                        ),
                      ),
                  ],
                ),
        ),
        LumeToolSection(
          child: LumeDetailActions(
            editLabel: l.actionEdit,
            onEdit: () => _editGoal(v.goal),
            deleteLabel: l.actionDelete,
            onDelete: () => unawaited(_delete(l, v)),
            extra: <Widget>[
              if (v.goal.state == GoalState.active) ...<Widget>[
                LumeDetailAction(
                  key: LumeGoalsTool.completeKey,
                  label: l.goalsMarkComplete,
                  icon: LumeIcons.checkCircle,
                  onPressed: () => unawaited(_setState(l, v, GoalState.completed)),
                ),
                LumeDetailAction(
                  key: LumeGoalsTool.abandonKey,
                  label: l.goalsAbandon,
                  destructive: true,
                  onPressed: () => unawaited(_setState(l, v, GoalState.abandoned)),
                ),
              ] else
                LumeDetailAction(
                  key: LumeGoalsTool.reactivateKey,
                  label: l.goalsReactivate,
                  icon: LumeIcons.refresh,
                  onPressed: () => unawaited(_setState(l, v, GoalState.active)),
                ),
            ],
          ),
        ),
      ],
      true,
    );
  }

  // ------------------------------------------------------------------ form

  List<Widget> _form(BuildContext context, AppLocalizations l) {
    final _GoalDraft d = _draft!;
    return <Widget>[
      LumeToolSection(
        child: LumeFormCard(
          key: LumeGoalsTool.formKey,
          children: <Widget>[
            LumeFormField(
              key: LumeGoalsTool.nameField,
              label: l.goalsFieldName,
              controller: d.name,
              required: true,
              autofocus: d.id == null,
              error: d.errors['name'],
            ),
            LumeFormField(
              key: LumeGoalsTool.targetField,
              label: l.goalsFieldTarget,
              controller: d.target,
              kind: LumeFieldKind.money,
              required: true,
              error: d.errors['target'] ?? d.errors['currency'],
            ),
            LumeFormPicker(
              key: LumeGoalsTool.targetDateField,
              label: l.goalsFieldTargetDate,
              optionalLabel: l.actionNotSet,
              value: d.targetDate == null
                  ? l.actionNotSet
                  : LumeFormatting.of(context).dateMediumYear(
                      d.targetDate!.toCalendarDateTime(),
                    ),
              onTap: () async {
                final DateTime base =
                    d.targetDate?.toCalendarDateTime() ?? LumeClockScope.of(context).now();
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: base,
                  firstDate: DateTime(base.year - 1),
                  lastDate: DateTime(base.year + 50),
                );
                if (picked != null && mounted) {
                  setState(() => d.targetDate = LumeDate.ofWallClock(picked));
                }
              },
            ),
            LumeFormField(
              key: LumeGoalsTool.noteField,
              label: l.goalsFieldNote,
              controller: d.note,
              kind: LumeFieldKind.multiline,
              optionalLabel: l.actionNotSet,
              error: d.errors['note'],
            ),
          ],
        ),
      ),
    ];
  }
}

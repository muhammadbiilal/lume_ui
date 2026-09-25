/// Habits — `tools/personal/habits.tool.js`, as a real record-backed tool.
///
/// The reference draws a progress ring, a heatmap and two "insights" beside
/// four fixture habits — `streak: 12, best: 28, rate: 0.82` and a
/// `heatDays(35, 7731, 0.3)` heatmap are bare literals with a fixed seed,
/// none of it worked out from the habits drawn beside them
/// (`context.js:1591-1607`). None of that is reproduced here (dropped, not
/// approximated): the persisted schema itself
/// (`record-schemas.js` `habits:`) only ever asks for a name, a cadence and
/// a note, with no daily log at all. This build keeps that name and
/// cadence, and adds the one real thing the reference never stored: a
/// check-in per day a habit was kept, toggled straight from its row — fast
/// and unconfirmed, matching the schema's own `optimistic: true`. Every
/// streak, best streak and completion figure on screen is computed from
/// those check-ins.
///
/// List, one habit's detail, and its form — the same three-view shape as
/// Goals and Subscriptions.
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
import '../../../core/platform/lume_export.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/habits_providers.dart';
import '../domain/habits_book.dart';
import '../domain/habits_failure.dart';
import '../domain/habits_model.dart';
import '../domain/habits_repository.dart';
import 'habits_sheets.dart';
import 'habits_text.dart';

enum _View { list, habit, form }

abstract final class LumeHabitsTool {
  static const String id = 'habits';

  static const Key summaryKey = ValueKey<String>('habits.summary');
  static const Key listKey = ValueKey<String>('habits.list');
  static const Key emptyKey = ValueKey<String>('habits.empty');
  static const Key addKey = ValueKey<String>('habits.add');
  static const Key habitKey = ValueKey<String>('habits.habit');
  static const Key markKey = ValueKey<String>('habits.mark');
  static const Key formKey = ValueKey<String>('habits.form');
  static const Key saveKey = ValueKey<String>('habits.save');
  static const Key nameField = ValueKey<String>('habits.field.name');
  static const Key frequencyField = ValueKey<String>('habits.field.frequency');
  static const Key notesField = ValueKey<String>('habits.field.notes');
  static Key row(String id) => ValueKey<String>('habits.row.$id');
  static Key toggle(String id) => ValueKey<String>('habits.toggle.$id');

  static Widget open(LumeToolRequest request) => HabitsTool(request: request);
}

class HabitsTool extends ConsumerStatefulWidget {
  const HabitsTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<HabitsTool> createState() => _HabitsToolState();
}

class _HabitDraft {
  _HabitDraft({
    this.id,
    this.version,
    this.frequency = HabitFrequency.daily,
    String name = '',
    String notes = '',
  }) : name = TextEditingController(text: name),
       notes = TextEditingController(text: notes) {
    _initial = _state;
  }

  final LumeRecordId? id;
  final int? version;
  HabitFrequency frequency;
  final TextEditingController name;
  final TextEditingController notes;
  final Map<String, String> errors = <String, String>{};
  late final String _initial;

  String get _state => <Object?>[name.text, notes.text, frequency.name].join('\u0000');

  bool get dirty => _state != _initial;

  void dispose() {
    name.dispose();
    notes.dispose();
  }
}

class _HabitsToolState extends ConsumerState<HabitsTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final HabitsRepository _repo = ref.read(habitsRepositoryProvider);
  final GlobalKey _body = GlobalKey();

  _View _view = _View.list;
  LumeRecordId? _habit;
  _HabitDraft? _draft;

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

  // ------------------------------------------------------------ navigation

  void _go(_View v, {LumeRecordId? habit}) {
    setState(() {
      _view = v;
      if (habit != null) {
        _habit = habit;
      } else if (v == _View.list) {
        _habit = null;
      }
    });
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
      case _View.habit:
        _go(_View.list);
      case _View.form:
        final _HabitDraft? d = _draft;
        if (d != null && d.dirty && !await _confirmDiscard()) return;
        if (!mounted) return;
        _draft = null;
        d?.dispose();
        _go(d?.id != null ? _View.habit : _View.list);
    }
  }

  Future<bool> _confirmDiscard() async {
    final AppLocalizations l = AppLocalizations.of(context);
    return await habitsDecide(
          context,
          title: l.recDiscardAsk,
          text: l.recDiscardText,
          confirm: l.recDiscard,
          cancel: l.recKeepEditing,
          destructive: true,
        ) ??
        false;
  }

  void _add() {
    _draft?.dispose();
    _draft = _HabitDraft();
    _go(_View.form);
  }

  void _edit(Habit h) {
    _draft?.dispose();
    _draft = _HabitDraft(
      id: h.id,
      version: h.version,
      frequency: h.frequency,
      name: h.name,
      notes: h.notes ?? '',
    );
    _go(_View.form);
  }

  // ---------------------------------------------------------------- writes

  void _failed(AppLocalizations l, HabitsFailure f) {
    _say(switch (f.kind) {
      HabitsFailureKind.conflict || HabitsFailureKind.notFound => l.habitsErrConflict,
      _ => l.habitsErrFailed,
    }, tone: LumeToastTone.error);
  }

  void _undoable(AppLocalizations l, String message, HabitsWrite w) => _say(
    message,
    actionLabel: l.recUndo,
    onAction: () {
      final HabitsResult<void> r = _repo.undo(w);
      if (r.failure != null) _failed(l, r.failure!);
    },
  );

  Future<void> _save(AppLocalizations l) async {
    final _HabitDraft d = _draft!;
    final Map<String, String> errors = <String, String>{};
    final String name = d.name.text.trim();
    if (name.isEmpty) errors['name'] = l.habitsErrName;
    if (name.length > kHabitsNameMax) errors['name'] = l.habitsErrLong;
    if (d.notes.text.trim().length > kHabitsNoteMax) errors['notes'] = l.habitsErrLong;
    setState(() {
      d.errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) return;

    final HabitDraft draft = HabitDraft(
      name: name,
      frequency: d.frequency,
      notes: d.notes.text,
    );
    final HabitsResult<HabitsWrite> r = d.id == null
        ? _repo.addHabit(draft)
        : _repo.editHabit(d.id!, draft, version: d.version!);
    if (!mounted) return;
    if (r.failure != null) return _failed(l, r.failure!);
    final HabitsWrite w = r.value!;
    _draft = null;
    d.dispose();
    _go(_View.habit, habit: w.habit!.id);
    _say(l.commonSaved);
  }

  Future<void> _toggleToday(AppLocalizations l, Habit h, LumeDate today) async {
    final HabitsResult<HabitsWrite> r = _repo.toggleCheckin(h.id, today);
    if (r.failure != null) _failed(l, r.failure!);
  }

  Future<void> _delete(AppLocalizations l, Habit h) async {
    final bool ok = await habitsConfirmDelete(
      context,
      title: l.habitsDeleteAsk,
      text: l.habitsDeleteText(h.name),
    );
    if (!ok || !mounted) return;
    final HabitsResult<HabitsWrite> r = _repo.deleteHabit(h.id, version: h.version);
    if (r.failure != null) return _failed(l, r.failure!);
    _go(_View.list);
    _undoable(l, l.habitsDeletedToast, r.value!);
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(context, countryCode: widget.request.user.country);
    final LumeDate? today = _today(context);
    final HabitsSnapshot snapshot = _repo.view();

    LumeToolStatus status = LumeToolStatus.ready;
    HabitsBook? book;
    if (snapshot.loading) {
      status = LumeToolStatus.loading;
    } else if (snapshot.failed) {
      status = LumeToolStatus.error;
    } else {
      book = snapshot.book(today);
    }
    if (book != null && _habit != null && book.habit(_habit!) == null && _view != _View.form) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _go(_View.list);
      });
    }

    final (String? title, List<Widget> body, bool bare) = switch (_view) {
      _ when book == null => (null, const <Widget>[], false),
      _View.list => (null, _list(context, l, f, book, today), false),
      _View.habit => _habitScreen(context, l, f, book, today),
      _View.form => (
        _draft?.id == null ? l.habitsNewHabit : l.habitsEditHabit,
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
        exportFile: book == null || book.isEmpty
            ? null
            : () => _export(l, book!, today),
        headerActions: _view == _View.form
            ? <Widget>[
                LumeTextButton(
                  key: LumeHabitsTool.saveKey,
                  label: l.actionSave,
                  onPressed: () => unawaited(_save(l)),
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

  /// Name and current streak, real for every habit — never the reference's
  /// unconditional `h.streak` fixture (`context.js:1972-1974`).
  LumeExportFile? _export(AppLocalizations l, HabitsBook book, LumeDate? today) {
    if (book.isEmpty) return null;
    final List<List<Object?>> rows = <List<Object?>>[
      <Object?>[l.commonName, l.habitsFieldFrequency],
      for (final HabitView v in book.habits)
        <Object?>[
          v.habit.name,
          v.damaged || v.currentStreak == null
              ? '—'
              : HabitsText.streakSentence(l, v.frequency, v.currentStreak!),
        ],
    ];
    return LumeExportFile.csv(
      tool: LumeHabitsTool.id,
      day: today?.toCalendarDateTime() ?? LumeClockScope.of(context).now(),
      rows: rows,
    );
  }

  // ------------------------------------------------------------------ list

  List<Widget> _list(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    HabitsBook book,
    LumeDate? today,
  ) {
    if (book.isEmpty) {
      return <Widget>[
        LumeToolSection(
          child: LumeToolState(
            key: LumeHabitsTool.emptyKey,
            icon: LumeIcons.flame,
            title: l.habitsEmptyTitle,
            text: l.habitsEmptyText,
          ),
        ),
        LumeToolSection(
          child: LumeButton.accent(
            key: LumeHabitsTool.addKey,
            label: l.habitsAddHabit,
            block: true,
            onPressed: _add,
          ),
        ),
      ];
    }

    final int? doneToday = book.doneTodayCount;
    final int? active = book.activeStreakCount;

    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeHabitsTool.summaryKey,
          kicker: l.habitsSummaryKicker,
          value: doneToday == null ? '—' : f.integer(doneToday),
          valueSmall: '/ ${f.integer(book.habits.length)}',
          stats: <LumeStat>[
            LumeStat(value: f.integer(book.habits.length), label: l.habitsStatTotal),
            LumeStat(
              value: active == null ? '—' : f.integer(active),
              label: l.habitsStatActiveStreaks,
            ),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeRecordList(
          key: LumeHabitsTool.listKey,
          children: <Widget>[for (final HabitView v in book.habits) _row(l, f, v, today)],
        ),
      ),
      LumeToolSection(
        child: LumeButton.accent(
          key: LumeHabitsTool.addKey,
          label: l.habitsAddHabit,
          block: true,
          onPressed: _add,
        ),
      ),
    ];
  }

  Widget _row(AppLocalizations l, LumeFormatting f, HabitView v, LumeDate? today) {
    final Habit h = v.habit;
    return LumeRecordRow(
      key: LumeHabitsTool.row(h.id.value),
      title: h.name,
      subtitle: HabitsText.frequency(l, h.frequency),
      meta: v.damaged
          ? <String>[l.habitsDamagedBadge]
          : v.currentStreak == null
          ? null
          : <String>[HabitsText.streakSentence(l, h.frequency, v.currentStreak!)],
      done: v.doneToday ?? false,
      onToggle: v.damaged || today == null
          ? null
          : (bool _) => unawaited(_toggleToday(l, h, today)),
      checkLabel: l.habitsCheckLabel,
      onTap: () => _go(_View.habit, habit: h.id),
    );
  }

  // ------------------------------------------------------------ habit detail

  (String?, List<Widget>, bool) _habitScreen(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    HabitsBook book,
    LumeDate? today,
  ) {
    final HabitView? v = _habit == null ? null : book.habit(_habit!);
    if (v == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _go(_View.list);
      });
      return (null, const <Widget>[], false);
    }
    final Habit h = v.habit;
    final int? streak = v.currentStreak;
    final bool doneToday = v.doneToday ?? false;

    return (
      h.name,
      <Widget>[
        LumeToolSection(
          child: LumeSummaryCard(
            key: LumeHabitsTool.habitKey,
            kicker: HabitsText.frequency(l, h.frequency),
            value: v.damaged || streak == null ? '—' : f.integer(streak),
            valueSmall: v.damaged || streak == null ? null : HabitsText.unit(l, h.frequency, streak),
            caption: v.damaged ? l.habitsDamagedBadge : l.habitsCurrentStreakCaption,
            stats: v.damaged
                ? const <LumeStat>[]
                : <LumeStat>[
                    LumeStat(
                      value: '${f.integer(v.bestStreak)} ${HabitsText.unit(l, h.frequency, v.bestStreak)}',
                      label: l.habitsStatBest,
                    ),
                    LumeStat(
                      value: v.completionRate == null
                          ? '—'
                          : f.percent(v.completionRate! * 100, decimals: 0),
                      label: l.habitsStatCompletion,
                    ),
                  ],
          ),
        ),
        if (h.notes != null)
          LumeToolSection(
            child: LumeFactCard(
              facts: <LumeFact>[LumeFact(label: l.recFieldNotes, value: h.notes!, block: true)],
            ),
          ),
        LumeToolSection(
          child: LumeDetailActions(
            editLabel: l.actionEdit,
            onEdit: () => _edit(h),
            deleteLabel: l.actionDelete,
            onDelete: () => unawaited(_delete(l, h)),
            extra: <Widget>[
              if (!v.damaged && today != null)
                LumeDetailAction(
                  key: LumeHabitsTool.markKey,
                  label: doneToday ? l.habitsUnmarkDone : l.habitsMarkDone,
                  icon: LumeIcons.checkCircle,
                  onPressed: () => unawaited(_toggleToday(l, h, today)),
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
    final _HabitDraft d = _draft!;
    return <Widget>[
      LumeToolSection(
        child: LumeFormCard(
          key: LumeHabitsTool.formKey,
          children: <Widget>[
            LumeFormField(
              key: LumeHabitsTool.nameField,
              label: l.commonName,
              controller: d.name,
              required: true,
              autofocus: d.id == null,
              error: d.errors['name'],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LumeFieldLabel(label: l.habitsFieldFrequency),
                const SizedBox(height: 7),
                LumeSegmented(
                  key: LumeHabitsTool.frequencyField,
                  value: d.frequency.name,
                  semanticLabel: l.habitsFieldFrequency,
                  items: <LumeChoice>[
                    LumeChoice(value: HabitFrequency.daily.name, label: l.habitsFreqDaily),
                    LumeChoice(value: HabitFrequency.weekdays.name, label: l.habitsFreqWeekdays),
                    LumeChoice(value: HabitFrequency.weekly.name, label: l.habitsFreqWeekly),
                  ],
                  onChanged: (String v) => setState(
                    () => d.frequency =
                        HabitFrequency.values.firstWhere((HabitFrequency x) => x.name == v),
                  ),
                ),
              ],
            ),
            LumeFormField(
              key: LumeHabitsTool.notesField,
              label: l.recFieldNotes,
              controller: d.notes,
              kind: LumeFieldKind.multiline,
              optionalLabel: l.recOptional,
              error: d.errors['notes'],
            ),
          ],
        ),
      ),
    ];
  }
}

/// Medication — `tools/personal/meds.tool.js`, as a real record-backed tool.
///
/// The reference draws a summary card (next dose + an adherence ring), a
/// "Today" timeline of doses due or taken, the active list, and a refill
/// section — all five figures bare literals rotated from a three-item
/// fixture (`tool-data.js:735-738`): `adherence: 0.94`, `next: 'Sun 09:00'`
/// and the rest agree with nothing a reader ever entered. There is no dose
/// log in `record-schemas.js`'s own `meds` schema — only a name, a dose, a
/// schedule, an optional first-dose time of day, an optional count left and
/// a note — so there is nothing to honestly compute an adherence percentage
/// or a "taken today" timeline from (D-Md1). Both are dropped. What this
/// does instead, which the reference has none of at all: a medication can be
/// added, edited and deleted, with Undo; the running-low flag is the
/// reference's own real rule (`left > 0 && <= 3`) over the reader's own
/// count, not a fixture; and the safety note the schema asks for
/// (`rec.meds.safety`) is shown on every medication's detail, without the
/// generic "Kept on this device" title the reference pairs it with — this
/// store is session-only (Option B), and claiming otherwise would be exactly
/// the kind of promise `RELEASE_HONESTY.md` forbids.
///
/// It sends no notification: a stored time of day is read back as typed,
/// never turned into a scheduled alert. That pipeline is Reminders' alone.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/navigation/lume_tool_frame.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/values/lume_record_id.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../records/presentation/record_family.dart' show LumeFamilyText;
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/meds_providers.dart';
import '../domain/meds_book.dart';
import '../domain/meds_failure.dart';
import '../domain/meds_model.dart';
import '../domain/meds_repository.dart';
import 'meds_sheets.dart';
import 'meds_text.dart';

enum _View { list, medication, form }

abstract final class LumeMedsTool {
  static const String id = 'meds';

  static const Key summaryKey = ValueKey<String>('meds.summary');
  static const Key listKey = ValueKey<String>('meds.list');
  static const Key emptyKey = ValueKey<String>('meds.empty');
  static const Key addKey = ValueKey<String>('meds.add');
  static const Key medicationKey = ValueKey<String>('meds.medication');
  static const Key factsKey = ValueKey<String>('meds.facts');
  static const Key safetyKey = ValueKey<String>('meds.safety');
  static const Key formKey = ValueKey<String>('meds.form');
  static const Key saveKey = ValueKey<String>('meds.save');
  static const Key nameField = ValueKey<String>('meds.field.name');
  static const Key doseField = ValueKey<String>('meds.field.dose');
  static const Key scheduleField = ValueKey<String>('meds.field.schedule');
  static const Key firstDoseField = ValueKey<String>('meds.field.firstDose');
  static const Key clearFirstDose = ValueKey<String>(
    'meds.field.firstDose.clear',
  );
  static const Key dosesLeftField = ValueKey<String>('meds.field.dosesLeft');
  static const Key notesField = ValueKey<String>('meds.field.notes');
  static Key row(String id) => ValueKey<String>('meds.row.$id');

  static Widget open(LumeToolRequest request) => MedsTool(request: request);
}

class MedsTool extends ConsumerStatefulWidget {
  const MedsTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<MedsTool> createState() => _MedsToolState();
}

class _MedsDraft {
  _MedsDraft({
    this.id,
    this.version,
    this.schedule = MedsSchedule.daily,
    this.firstDoseAt,
    String name = '',
    String dose = '',
    String dosesLeft = '',
    String notes = '',
  }) : name = TextEditingController(text: name),
       dose = TextEditingController(text: dose),
       dosesLeft = TextEditingController(text: dosesLeft),
       notes = TextEditingController(text: notes) {
    _initial = _state;
  }

  final LumeRecordId? id;
  final int? version;
  MedsSchedule schedule;
  String? firstDoseAt;
  final TextEditingController name;
  final TextEditingController dose;
  final TextEditingController dosesLeft;
  final TextEditingController notes;
  final Map<String, String> errors = <String, String>{};
  late final String _initial;

  String get _state => <Object?>[
    name.text,
    dose.text,
    dosesLeft.text,
    notes.text,
    schedule.name,
    firstDoseAt,
  ].join('\u0000');

  bool get dirty => _state != _initial;

  void dispose() {
    name.dispose();
    dose.dispose();
    dosesLeft.dispose();
    notes.dispose();
  }
}

class _MedsToolState extends ConsumerState<MedsTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final MedsRepository _repo = ref.read(medsRepositoryProvider);
  final GlobalKey _body = GlobalKey();

  _View _view = _View.list;
  LumeRecordId? _medication;
  _MedsDraft? _draft;

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

  // ------------------------------------------------------------ navigation

  void _go(_View v, {LumeRecordId? medication}) {
    setState(() {
      _view = v;
      if (medication != null) _medication = medication;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? c = _body.currentContext;
      final ScrollPosition? p = c == null
          ? null
          : Scrollable.maybeOf(c)?.position;
      if (p != null && p.pixels != 0) p.jumpTo(0);
    });
  }

  Future<void> _back() async {
    switch (_view) {
      case _View.list:
        widget.request.onBack?.call();
      case _View.medication:
        _go(_View.list);
      case _View.form:
        final _MedsDraft? d = _draft;
        if (d != null && d.dirty && !await _confirmDiscard()) return;
        if (!mounted) return;
        final bool wasEditing = d?.id != null;
        _draft = null;
        d?.dispose();
        _go(wasEditing ? _View.medication : _View.list);
    }
  }

  Future<bool> _confirmDiscard() async {
    final AppLocalizations l = AppLocalizations.of(context);
    return await medsDecide(
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
    _draft = _MedsDraft();
    _go(_View.form);
  }

  void _edit(MedsEntry m) {
    _draft?.dispose();
    _draft = _MedsDraft(
      id: m.id,
      version: m.version,
      schedule: m.schedule,
      firstDoseAt: m.firstDoseAt,
      name: m.name,
      dose: m.dose,
      dosesLeft: m.dosesLeft?.toString() ?? '',
      notes: m.notes ?? '',
    );
    _go(_View.form);
  }

  // ---------------------------------------------------------------- writes

  void _failed(AppLocalizations l, MedsFailure f) {
    _say(switch (f.kind) {
      MedsFailureKind.conflict || MedsFailureKind.notFound => l.medsErrConflict,
      MedsFailureKind.damaged => l.medsErrDamaged,
      _ => l.medsErrFailed,
    }, tone: LumeToastTone.error);
  }

  void _undoable(AppLocalizations l, String message, MedsWrite w) => _say(
    message,
    actionLabel: l.recUndo,
    onAction: () {
      final MedsResult<void> r = _repo.undo(w);
      if (r.failure != null) _failed(l, r.failure!);
    },
  );

  Future<void> _save(AppLocalizations l) async {
    final _MedsDraft d = _draft!;
    final Map<String, String> errors = <String, String>{};

    final String name = d.name.text.trim();
    if (name.isEmpty) {
      errors['name'] = l.medsErrName;
    } else if (name.length > kMedsNameMax) {
      errors['name'] = l.medsErrLong;
    }
    final String dose = d.dose.text.trim();
    if (dose.isEmpty) {
      errors['dose'] = l.medsErrDose;
    } else if (dose.length > kMedsDoseMax) {
      errors['dose'] = l.medsErrLong;
    }
    if (d.notes.text.trim().length > kMedsNoteMax) {
      errors['notes'] = l.medsErrLong;
    }
    int? dosesLeft;
    final String leftText = d.dosesLeft.text.trim();
    if (leftText.isNotEmpty) {
      dosesLeft = int.tryParse(leftText);
      if (dosesLeft == null || dosesLeft < 0 || dosesLeft > kMedsDosesLeftMax) {
        errors['dosesLeft'] = l.medsErrDosesLeft;
      }
    }
    setState(() {
      d.errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) return;

    final MedsDraft draft = MedsDraft(
      name: name,
      dose: dose,
      schedule: d.schedule,
      firstDoseAt: d.firstDoseAt,
      dosesLeft: dosesLeft,
      notes: d.notes.text,
    );
    final MedsResult<MedsWrite> r = d.id == null
        ? _repo.add(draft)
        : _repo.edit(d.id!, draft, version: d.version!);
    if (!mounted) return;
    if (r.failure != null) {
      _failed(l, r.failure!);
      return;
    }
    final MedsWrite w = r.value!;
    _draft = null;
    d.dispose();
    _go(_View.medication, medication: w.medication!.id);
    _say(l.commonSaved);
  }

  Future<void> _delete(AppLocalizations l, MedsEntry m) async {
    final bool ok = await medsConfirmDelete(
      context,
      title: l.medsDeleteAsk,
      text: l.medsDeleteText(m.name),
    );
    if (!ok || !mounted) return;
    final MedsResult<MedsWrite> r = _repo.delete(m.id, version: m.version);
    if (r.failure != null) return _failed(l, r.failure!);
    _go(_View.list);
    _undoable(l, l.medsDeletedToast, r.value!);
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: widget.request.user.country,
    );
    final MedsSnapshot snapshot = _repo.view();

    MedsBook? book;
    LumeToolStatus status = LumeToolStatus.ready;
    if (snapshot.loading) {
      status = LumeToolStatus.loading;
    } else if (snapshot.failed) {
      status = LumeToolStatus.error;
    } else {
      book = snapshot.book();
    }

    if (book != null &&
        _medication != null &&
        book.medication(_medication!) == null) {
      _view = _View.list;
      _medication = null;
    }

    final (String? title, List<Widget> body, bool bare) = switch (_view) {
      _ when book == null => (null, const <Widget>[], false),
      _View.list => (null, _list(context, l, f, book), false),
      _View.medication => _medicationScreen(context, l, f, book),
      _View.form => (
        _draft?.id == null ? l.medsNewMedication : l.medsEditMedication,
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
        headerActions: _view == _View.form
            ? <Widget>[
                LumeTextButton(
                  key: LumeMedsTool.saveKey,
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

  // ------------------------------------------------------------------ list

  List<Widget> _list(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    MedsBook book,
  ) {
    if (book.isEmpty) {
      return <Widget>[
        LumeToolSection(
          child: LumeToolState(
            key: LumeMedsTool.emptyKey,
            icon: LumeIcons.pill,
            title: l.medsEmptyTitle,
            text: l.medsEmptyText,
          ),
        ),
        LumeToolSection(
          child: LumeButton.accent(
            key: LumeMedsTool.addKey,
            label: l.medsAddMedication,
            block: true,
            onPressed: _add,
          ),
        ),
      ];
    }

    final int lowCount = book.runningLow.length;
    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeMedsTool.summaryKey,
          kicker: l.medsSummaryKicker,
          value: f.integer(book.medications.length),
          caption: lowCount > 0 ? l.medsSummaryCaption(lowCount) : null,
        ),
      ),
      LumeToolSection(
        child: LumeRows(
          key: LumeMedsTool.listKey,
          children: <Widget>[
            for (final MedsEntry m in book.medications) _row(context, l, f, m),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeButton.accent(
          key: LumeMedsTool.addKey,
          label: l.medsAddMedication,
          block: true,
          onPressed: _add,
        ),
      ),
    ];
  }

  Widget _row(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    MedsEntry m,
  ) => LumeRichRow(
    key: LumeMedsTool.row(m.id.value),
    icon: LumeIcons.pill,
    title: m.name,
    subtitle: m.dose,
    meta: <String>[MedsText.schedule(l, m.schedule)],
    value: m.firstDoseAt == null ? '—' : _time(f, m.firstDoseAt!),
    badge: m.runningLow
        ? LumeBadge(label: l.medsLowBadge, tone: LumeBadgeTone.warn)
        : null,
    chevron: true,
    onTap: () => _go(_View.medication, medication: m.id),
  );

  // -------------------------------------------------------------- medication

  (String?, List<Widget>, bool) _medicationScreen(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    MedsBook book,
  ) {
    final MedsEntry? m = _medication == null
        ? null
        : book.medication(_medication!);
    if (m == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _go(_View.list));
      return (null, const <Widget>[], false);
    }
    final String schedule = MedsText.schedule(l, m.schedule);
    return (
      m.name,
      <Widget>[
        LumeToolSection(
          child: LumeSummaryCard(
            key: LumeMedsTool.medicationKey,
            kicker: schedule,
            value: m.dosesLeft == null ? '—' : f.integer(m.dosesLeft!),
            unit: m.dosesLeft == null ? null : l.medsDosesLeftUnit,
            caption: m.firstDoseAt == null
                ? null
                : l.medsFirstDoseAt(_time(f, m.firstDoseAt!)),
            aside: m.runningLow
                ? LumeBadge(label: l.medsLowBadge, tone: LumeBadgeTone.warn)
                : null,
          ),
        ),
        LumeToolSection(
          child: Container(
            key: LumeMedsTool.factsKey,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            decoration: BoxDecoration(
              color: context.lume.card,
              borderRadius: LumeRadius.brMd,
              border: Border.all(
                color: context.lume.border,
                width: LumeSpace.border,
              ),
              boxShadow: context.lumeShadows.xs,
            ),
            child: LumeFactCard(
              facts: <LumeFact>[
                LumeFact(label: l.medsFieldDose, value: m.dose),
                LumeFact(label: l.medsFieldSchedule, value: schedule),
                LumeFact(
                  label: l.medsFieldFirstDose,
                  value: m.firstDoseAt == null ? '—' : _time(f, m.firstDoseAt!),
                ),
                LumeFact(
                  label: l.medsFieldDosesLeft,
                  value: m.dosesLeft == null ? '—' : f.integer(m.dosesLeft!),
                ),
                LumeFact(
                  label: l.medsFieldNotes,
                  value: m.notes ?? l.recNone,
                  block: true,
                ),
              ],
            ),
          ),
        ),
        LumeToolSection(
          child: LumeNotice(
            key: LumeMedsTool.safetyKey,
            kind: LumeNoticeKind.info,
            title: l.medsSafetyTitle,
            text: l.medsSafetyText,
          ),
        ),
        LumeToolSection(
          child: LumeDetailActions(
            editLabel: l.actionEdit,
            onEdit: () => _edit(m),
            deleteLabel: l.actionDelete,
            onDelete: () => unawaited(_delete(l, m)),
          ),
        ),
      ],
      true,
    );
  }

  // ------------------------------------------------------------------ form

  List<Widget> _form(BuildContext context, AppLocalizations l) {
    final _MedsDraft d = _draft!;
    return <Widget>[
      LumeToolSection(
        child: LumeFormCard(
          key: LumeMedsTool.formKey,
          children: <Widget>[
            LumeFormField(
              key: LumeMedsTool.nameField,
              label: l.medsFieldName,
              controller: d.name,
              required: true,
              autofocus: d.id == null,
              placeholder: l.medsFieldNamePh,
              error: d.errors['name'],
            ),
            LumeFormField(
              key: LumeMedsTool.doseField,
              label: l.medsFieldDose,
              controller: d.dose,
              required: true,
              placeholder: l.medsFieldDosePh,
              error: d.errors['dose'],
            ),
            LumeFormPicker(
              key: LumeMedsTool.scheduleField,
              label: l.medsFieldSchedule,
              value: MedsText.schedule(l, d.schedule),
              onTap: () async {
                final MedsSchedule? chosen = await medsChooseSchedule(
                  context,
                  current: d.schedule,
                );
                if (chosen != null && mounted) {
                  setState(() => d.schedule = chosen);
                }
              },
            ),
            _timeField(context, l, d),
            LumeFormField(
              key: LumeMedsTool.dosesLeftField,
              label: l.medsFieldDosesLeft,
              controller: d.dosesLeft,
              kind: LumeFieldKind.number,
              optionalLabel: l.commonOptional,
              error: d.errors['dosesLeft'],
            ),
            LumeFormField(
              key: LumeMedsTool.notesField,
              label: l.medsFieldNotes,
              controller: d.notes,
              kind: LumeFieldKind.multiline,
              optionalLabel: l.commonOptional,
              error: d.errors['notes'],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _timeField(BuildContext context, AppLocalizations l, _MedsDraft d) {
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: widget.request.user.country,
    );
    final String shown = d.firstDoseAt == null
        ? l.actionNotSet
        : _time(f, d.firstDoseAt!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LumeFormPicker(
          key: LumeMedsTool.firstDoseField,
          label: l.medsFieldFirstDose,
          optionalLabel: l.commonOptional,
          value: shown,
          icon: LumeIcons.clock,
          onTap: () async {
            final (int, int)? current = LumeFamilyText.clock(d.firstDoseAt);
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: current == null
                  ? const TimeOfDay(hour: 8, minute: 0)
                  : TimeOfDay(hour: current.$1, minute: current.$2),
            );
            if (picked != null && mounted) {
              setState(
                () => d.firstDoseAt = LumeFamilyText.isoClock(
                  picked.hour,
                  picked.minute,
                ),
              );
            }
          },
        ),
        if (d.firstDoseAt != null)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: LumeTextButton(
              key: LumeMedsTool.clearFirstDose,
              label: l.actionClear,
              semanticLabel: '${l.actionClear} ${l.medsFieldFirstDose}',
              onPressed: () => setState(() => d.firstDoseAt = null),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------------ time

  String _time(LumeFormatting f, String hhmm) {
    final (int, int)? t = LumeFamilyText.clock(hhmm);
    if (t == null) return hhmm;
    return f.time(DateTime(2000, 1, 1, t.$1, t.$2));
  }
}

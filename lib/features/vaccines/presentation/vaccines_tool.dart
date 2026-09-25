/// Vaccinations — `tools/personal/vaccines.tool.js`, as a real record-backed
/// tool.
///
/// The reference draws a person switcher over three named fixture people
/// ("You", "Sana", "Musa" — `HEALTH_PEOPLE`) and a fixed vaccine list keyed
/// to those invented names (`VACCINES`, `tool-data.js`); neither is real, and
/// there is no CRUD at all behind either, not even a stub. This build drops
/// the invented household: a vaccination's `forWhom` is the reader's own
/// free text (`vaccines_model.dart`), and every record — the vaccine, the
/// dose, the date, who gave it, whether it has been given or is still due,
/// and a note — is the reader's own, added, edited and deleted here. It is
/// sensitive: the frame shows its privacy note and nothing here reaches Home.
/// A delete is irreversible and says so, matching Documents' own health-record
/// precedent (D-V2); no notification is scheduled for a due date — it is
/// shown as the reader's own note, never a promise Lume will alert them
/// (D-V3).
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
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/vaccines_providers.dart';
import '../domain/vaccines_book.dart';
import '../domain/vaccines_failure.dart';
import '../domain/vaccines_model.dart';
import '../domain/vaccines_repository.dart';
import 'vaccines_sheets.dart';
import 'vaccines_text.dart';

enum VaccinesFilter { all, given, due }

enum _View { list, record, form }

abstract final class LumeVaccinesTool {
  static const String id = 'vaccines';

  static const Key summaryKey = ValueKey<String>('vaccines.summary');
  static const Key filterKey = ValueKey<String>('vaccines.filter');
  static const Key listKey = ValueKey<String>('vaccines.list');
  static const Key emptyKey = ValueKey<String>('vaccines.empty');
  static const Key noMatchKey = ValueKey<String>('vaccines.noMatch');
  static const Key addKey = ValueKey<String>('vaccines.add');
  static const Key recordKey = ValueKey<String>('vaccines.record');
  static const Key editKey = ValueKey<String>('vaccines.edit');
  static const Key deleteKey = ValueKey<String>('vaccines.delete');
  static const Key formKey = ValueKey<String>('vaccines.form');
  static const Key saveKey = ValueKey<String>('vaccines.save');
  static const Key nameField = ValueKey<String>('vaccines.field.name');
  static const Key forWhomField = ValueKey<String>('vaccines.field.forWhom');
  static const Key doseField = ValueKey<String>('vaccines.field.dose');
  static const Key statusField = ValueKey<String>('vaccines.field.status');
  static const Key dateField = ValueKey<String>('vaccines.field.date');
  static const Key providerField = ValueKey<String>('vaccines.field.provider');
  static const Key notesField = ValueKey<String>('vaccines.field.notes');
  static Key filterChip(VaccinesFilter f) => ValueKey<String>('vaccines.filter.${f.name}');
  static Key row(String id) => ValueKey<String>('vaccines.row.$id');

  static Widget open(LumeToolRequest request) => VaccinesTool(request: request);
}

class VaccinesTool extends ConsumerStatefulWidget {
  const VaccinesTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<VaccinesTool> createState() => _VaccinesToolState();
}

class _VaccineDraft {
  _VaccineDraft({
    this.id,
    this.version,
    this.date,
    this.status = VaccineStatus.given,
    String name = '',
    String forWhom = '',
    String dose = '',
    String provider = '',
    String notes = '',
  }) : name = TextEditingController(text: name),
       forWhom = TextEditingController(text: forWhom),
       dose = TextEditingController(text: dose),
       provider = TextEditingController(text: provider),
       notes = TextEditingController(text: notes) {
    _initial = _state;
  }

  final LumeRecordId? id;
  final int? version;
  LumeDate? date;
  VaccineStatus status;
  final TextEditingController name;
  final TextEditingController forWhom;
  final TextEditingController dose;
  final TextEditingController provider;
  final TextEditingController notes;
  final Map<String, String> errors = <String, String>{};
  late final String _initial;

  String get _state => <Object?>[
    name.text,
    forWhom.text,
    dose.text,
    provider.text,
    notes.text,
    status.name,
    date?.toIso(),
  ].join('\u0000');

  bool get dirty => _state != _initial;

  void dispose() {
    name.dispose();
    forWhom.dispose();
    dose.dispose();
    provider.dispose();
    notes.dispose();
  }
}

class _VaccinesToolState extends ConsumerState<VaccinesTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final VaccinesRepository _repo = ref.read(vaccinesRepositoryProvider);
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  final GlobalKey _body = GlobalKey();

  _View _view = _View.list;
  LumeRecordId? _record;
  _VaccineDraft? _draft;

  String get _id => widget.request.feature.id;
  String? _read(String key) => _session.read(_id, key);
  void _write(String key, String value) => _session.write(_id, key, value);

  VaccinesFilter get _filter => VaccinesFilter.values.firstWhere(
    (VaccinesFilter f) => f.name == _read('filter'),
    orElse: () => VaccinesFilter.all,
  );

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

  void _go(_View v, {LumeRecordId? record}) {
    final bool moved = v != _view || (record != null && record != _record);
    setState(() {
      _view = v;
      if (record != null) _record = record;
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
      case _View.record:
        _go(_View.list);
      case _View.form:
        final _VaccineDraft? d = _draft;
        if (d != null && d.dirty && !await vaccinesConfirmDiscard(context)) return;
        if (!mounted) return;
        _draft = null;
        d?.dispose();
        _go(d?.id != null ? _View.record : _View.list);
    }
  }

  void _add(LumeDate? today) {
    _draft?.dispose();
    _draft = _VaccineDraft(date: today);
    _go(_View.form);
  }

  void _edit(VaccineRecord r) {
    _draft?.dispose();
    _draft = _VaccineDraft(
      id: r.id,
      version: r.version,
      date: r.date,
      status: r.status,
      name: r.name,
      forWhom: r.forWhom ?? '',
      dose: r.dose ?? '',
      provider: r.provider ?? '',
      notes: r.notes ?? '',
    );
    _go(_View.form);
  }

  // ---------------------------------------------------------------- writes

  void _failed(AppLocalizations l, VaccinesFailure f) {
    _say(switch (f.kind) {
      VaccinesFailureKind.conflict || VaccinesFailureKind.notFound => l.vaccinesErrConflict,
      _ => l.vaccinesErrFailed,
    }, tone: LumeToastTone.error);
  }

  Future<void> _save(AppLocalizations l) async {
    final _VaccineDraft d = _draft!;
    final Map<String, String> errors = <String, String>{};

    final String name = d.name.text.trim();
    if (name.isEmpty) {
      errors['name'] = l.recErrRequired(l.vaccinesFieldName);
    } else if (name.length > kVaccinesNameMax) {
      errors['name'] = l.vaccinesErrLong;
    }
    if (d.forWhom.text.trim().length > kVaccinesForWhomMax) {
      errors['forWhom'] = l.vaccinesErrLong;
    }
    if (d.dose.text.trim().length > kVaccinesDoseMax) {
      errors['dose'] = l.vaccinesErrLong;
    }
    if (d.provider.text.trim().length > kVaccinesProviderMax) {
      errors['provider'] = l.vaccinesErrLong;
    }
    if (d.notes.text.trim().length > kVaccinesNotesMax) {
      errors['notes'] = l.vaccinesErrLong;
    }
    if (d.date == null) {
      errors['date'] = l.recErrRequired(l.recFieldDate);
    }
    setState(() {
      d.errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) return;

    final VaccineDraft draft = VaccineDraft(
      name: name,
      forWhom: d.forWhom.text,
      dose: d.dose.text,
      date: d.date!,
      status: d.status,
      provider: d.provider.text,
      notes: d.notes.text,
    );
    final VaccinesResult<VaccinesWrite> r = d.id == null
        ? _repo.add(draft)
        : _repo.edit(d.id!, draft, version: d.version!);
    if (!mounted) return;
    if (r.failure != null) return _failed(l, r.failure!);
    final VaccinesWrite w = r.value!;
    _draft = null;
    d.dispose();
    _go(_View.record, record: w.record!.id);
    _say(l.commonSaved);
  }

  Future<void> _delete(AppLocalizations l, VaccineRecord r) async {
    final bool ok = await vaccinesConfirmDelete(
      context,
      title: l.recDeleteAsk(l.vaccinesNoun),
      text: l.recDeleteTextFinal(r.name),
    );
    if (!ok || !mounted) return;
    final VaccinesResult<VaccinesWrite> result = _repo.delete(r.id, version: r.version);
    if (result.failure != null) return _failed(l, result.failure!);
    _go(_View.list);
    // Irreversible, by design (D-V2): no Undo is offered here.
    _say(l.recDeletedFinal(l.vaccinesNoun));
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(context, countryCode: widget.request.user.country);
    final LumeDate? today = _today(context);
    final VaccinesSnapshot snapshot = _repo.view();

    VaccinesBook? book;
    LumeToolStatus status = LumeToolStatus.ready;
    if (snapshot.loading) {
      status = LumeToolStatus.loading;
    } else if (snapshot.failed) {
      status = LumeToolStatus.error;
    } else {
      book = snapshot.book(today);
    }

    final (String? title, List<Widget> body, bool bare) = switch (_view) {
      _ when book == null => (null, const <Widget>[], false),
      _View.list => (null, _list(context, l, f, book, today), false),
      _View.record => _recordScreen(context, l, f, book),
      _View.form => (
        _draft?.id == null ? l.vaccinesNewVaccination : l.vaccinesEditVaccination,
        _form(context, l, f),
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
                  key: LumeVaccinesTool.saveKey,
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

  bool _matchesFilter(VaccineView v, VaccinesFilter f) => switch (f) {
    VaccinesFilter.all => true,
    VaccinesFilter.given => v.given,
    VaccinesFilter.due => !v.given,
  };

  List<Widget> _list(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    VaccinesBook book,
    LumeDate? today,
  ) {
    if (book.isEmpty) {
      return <Widget>[
        LumeToolSection(
          child: LumeToolState(
            key: LumeVaccinesTool.emptyKey,
            icon: LumeIcons.syringe,
            title: l.vaccinesEmptyTitle,
            text: l.vaccinesEmptyText,
          ),
        ),
        LumeToolSection(
          child: LumeButton.accent(
            key: LumeVaccinesTool.addKey,
            label: l.vaccinesAddVaccination,
            block: true,
            onPressed: () => _add(today),
          ),
        ),
      ];
    }

    final List<VaccineView> shown = <VaccineView>[
      for (final VaccineView v in book.records)
        if (_matchesFilter(v, _filter)) v,
    ]..sort((VaccineView a, VaccineView b) => b.record.date.compareTo(a.record.date));

    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeVaccinesTool.summaryKey,
          kicker: l.featureVaccines,
          value: f.integer(book.givenCount),
          valueSmall: '/ ${f.integer(book.total)}',
          caption: l.vaccinesDueCaption(book.dueCount),
          aside: LumeProgressRing(
            value: book.progress,
            label: l.featureVaccines,
            centreValue: '${(book.progress * 100).round()}%',
          ),
        ),
      ),
      LumeToolSection(
        flush: true,
        child: LumeFilterBar(
          key: LumeVaccinesTool.filterKey,
          children: <Widget>[
            for (final VaccinesFilter filt in VaccinesFilter.values)
              LumeFilterChip(
                key: LumeVaccinesTool.filterChip(filt),
                label: switch (filt) {
                  VaccinesFilter.all => l.commonAll,
                  VaccinesFilter.given => l.commonDone,
                  VaccinesFilter.due => l.commonDue,
                },
                selected: _filter == filt,
                onTap: () => setState(() => _write('filter', filt.name)),
              ),
          ],
        ),
      ),
      if (shown.isEmpty)
        LumeToolSection(
          child: LumeToolState(
            key: LumeVaccinesTool.noMatchKey,
            icon: LumeIcons.search,
            title: l.recNoMatch,
            text: '',
          ),
        )
      else
        LumeToolSection(
          child: LumeRows(
            key: LumeVaccinesTool.listKey,
            children: <Widget>[
              for (final VaccineView v in shown) _row(context, l, f, v),
            ],
          ),
        ),
      LumeToolSection(
        child: LumeButton.accent(
          key: LumeVaccinesTool.addKey,
          label: l.vaccinesAddVaccination,
          block: true,
          onPressed: () => _add(today),
        ),
      ),
    ];
  }

  Widget _row(BuildContext context, AppLocalizations l, LumeFormatting f, VaccineView v) {
    final LumeColors lume = context.lume;
    final VaccineRecord r = v.record;
    final (Color tone, Color ink, LumeBadge badge) = switch ((v.given, v.overdue)) {
      (true, _) => (
        lume.tintAccent,
        lume.accent,
        LumeBadge(label: l.commonDone, tone: LumeBadgeTone.ok),
      ),
      (false, true) => (
        lume.amber.withValues(alpha: 0.18),
        lume.amber,
        LumeBadge(label: l.commonOverdue, tone: LumeBadgeTone.late_),
      ),
      (false, false) => (
        lume.amber.withValues(alpha: 0.18),
        lume.amber,
        LumeBadge(label: l.commonDue, tone: LumeBadgeTone.warn),
      ),
    };
    return LumeRichRow(
      key: LumeVaccinesTool.row(r.id.value),
      icon: LumeIcons.syringe,
      iconTone: tone,
      iconInk: ink,
      title: r.name,
      subtitle: r.forWhom,
      meta: <String>[if (r.dose != null) r.dose!, if (r.provider != null) r.provider!],
      badge: badge,
      value: f.dateMediumYear(r.date.toCalendarDateTime()),
      valueSub: !v.given && v.daysUntil != null && v.daysUntil! >= 0
          ? l.commonInDays(v.daysUntil!)
          : null,
      chevron: true,
      onTap: () => _go(_View.record, record: r.id),
    );
  }

  // ------------------------------------------------------------- record

  (String?, List<Widget>, bool) _recordScreen(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    VaccinesBook book,
  ) {
    final VaccineView? v = _record == null ? null : book.view(_record!);
    if (v == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _go(_View.list));
      return (null, const <Widget>[], false);
    }
    final VaccineRecord r = v.record;
    return (
      r.name,
      <Widget>[
        LumeToolSection(
          child: LumeSummaryCard(
            key: LumeVaccinesTool.recordKey,
            kicker: VaccinesText.status(l, r.status),
            value: f.dateMediumYear(r.date.toCalendarDateTime()),
            caption: r.dose ?? l.actionNotSet,
          ),
        ),
        LumeToolSection(
          child: LumeFactCard(
            facts: <LumeFact>[
              LumeFact(label: l.vaccinesFieldFor, value: r.forWhom ?? l.actionNotSet),
              LumeFact(label: l.vaccinesFieldGivenBy, value: r.provider ?? l.actionNotSet),
              if (r.notes != null) LumeFact(label: l.recFieldNotes, value: r.notes!, block: true),
            ],
          ),
        ),
        LumeToolSection(
          child: LumeDetailActions(
            editLabel: l.actionEdit,
            onEdit: () => _edit(r),
            deleteLabel: l.actionDelete,
            onDelete: () => unawaited(_delete(l, r)),
          ),
        ),
      ],
      true,
    );
  }

  // ------------------------------------------------------------------ form

  List<Widget> _form(BuildContext context, AppLocalizations l, LumeFormatting f) {
    final _VaccineDraft d = _draft!;
    return <Widget>[
      LumeToolSection(
        child: LumeFormCard(
          key: LumeVaccinesTool.formKey,
          children: <Widget>[
            LumeFormField(
              key: LumeVaccinesTool.nameField,
              label: l.vaccinesFieldName,
              controller: d.name,
              required: true,
              autofocus: d.id == null,
              error: d.errors['name'],
            ),
            LumeFormField(
              key: LumeVaccinesTool.forWhomField,
              label: l.vaccinesFieldFor,
              controller: d.forWhom,
              optionalLabel: l.actionNotSet,
              error: d.errors['forWhom'],
            ),
            LumeFormField(
              key: LumeVaccinesTool.doseField,
              label: l.vaccinesFieldDose,
              controller: d.dose,
              optionalLabel: l.actionNotSet,
              error: d.errors['dose'],
            ),
            LumeSegmented(
              key: LumeVaccinesTool.statusField,
              value: d.status.name,
              items: <LumeChoice>[
                LumeChoice(value: VaccineStatus.given.name, label: l.commonDone),
                LumeChoice(value: VaccineStatus.due.name, label: l.commonDue),
              ],
              onChanged: (String v) => setState(
                () => d.status = VaccineStatus.values.firstWhere((VaccineStatus s) => s.name == v),
              ),
            ),
            LumeFormPicker(
              key: LumeVaccinesTool.dateField,
              label: l.recFieldDate,
              value: d.date == null
                  ? l.actionNotSet
                  : f.dateMediumYear(d.date!.toCalendarDateTime()),
              onTap: () async {
                final DateTime base = d.date?.toCalendarDateTime() ?? LumeClockScope.of(context).now();
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: base,
                  firstDate: DateTime(base.year - 20),
                  lastDate: DateTime(base.year + 5),
                );
                if (picked != null && mounted) {
                  setState(() => d.date = LumeDate.ofWallClock(picked));
                }
              },
            ),
            LumeFormField(
              key: LumeVaccinesTool.providerField,
              label: l.vaccinesFieldGivenBy,
              controller: d.provider,
              optionalLabel: l.actionNotSet,
              error: d.errors['provider'],
            ),
            LumeFormField(
              key: LumeVaccinesTool.notesField,
              label: l.recFieldNotes,
              controller: d.notes,
              kind: LumeFieldKind.multiline,
              optionalLabel: l.actionNotSet,
              error: d.errors['notes'],
            ),
          ],
        ),
      ),
    ];
  }
}

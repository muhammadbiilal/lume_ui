/// Health Records — `tools/personal/health.tool.js`, as a real record-backed
/// tool.
///
/// The reference draws a family-member switcher, a blood-type/age hero, a
/// six-month weight chart and a yearly spend figure. None of that survives
/// here: there is no family-member model in this build, and a chart or a
/// running total needs a series of real entries this schema does not keep.
/// What this tool keeps is the reference's own record shape
/// (`record-schemas.js`'s `health` entry) as a real record family: a
/// searchable, filterable, sortable list of the reader's own visits,
/// results, prescriptions, vaccinations and measurements, each of which can
/// be added, edited and deleted — the reference has no CRUD at all, not
/// even a stub.
///
/// It is sensitive (`recoverable: false`, `sensitive: true`): the frame
/// shows its privacy note, nothing here reaches Home, deleting a record is
/// final and its confirmation says so, and no record carries a share action
/// of its own (`lume_crud.dart`'s [LumeDeleteKind.irreversible]).
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
import '../../../core/theme/lume/lume_space.dart';
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
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/health_providers.dart';
import '../domain/health_book.dart';
import '../domain/health_failure.dart';
import '../domain/health_model.dart';
import '../domain/health_repository.dart';
import 'health_sheets.dart';
import 'health_text.dart';

enum HealthSort { date, title }

enum _View { list, record, form }

abstract final class LumeHealthTool {
  static const String id = 'health';

  static const Key summaryKey = ValueKey<String>('health.summary');
  static const Key searchKey = ValueKey<String>('health.search');
  static const Key filterKey = ValueKey<String>('health.filter');
  static const Key sortKey = ValueKey<String>('health.sort');
  static const Key listKey = ValueKey<String>('health.list');
  static const Key emptyKey = ValueKey<String>('health.empty');
  static const Key noMatchKey = ValueKey<String>('health.noMatch');
  static const Key addKey = ValueKey<String>('health.add');
  static const Key recordKey = ValueKey<String>('health.record');
  static const Key factsKey = ValueKey<String>('health.facts');
  static const Key detailActionsKey = ValueKey<String>('health.detailActions');
  static const Key formKey = ValueKey<String>('health.form');
  static const Key saveKey = ValueKey<String>('health.save');
  static const Key titleField = ValueKey<String>('health.field.title');
  static const Key typeField = ValueKey<String>('health.field.type');
  static const Key dateField = ValueKey<String>('health.field.date');
  static const Key sourceField = ValueKey<String>('health.field.source');
  static const Key valueField = ValueKey<String>('health.field.value');
  static const Key notesField = ValueKey<String>('health.field.notes');
  static Key filterChip(HealthRecordKind? k) =>
      ValueKey<String>('health.filter.${k?.name ?? 'all'}');
  static Key row(String id) => ValueKey<String>('health.row.$id');

  static Widget open(LumeToolRequest request) => HealthTool(request: request);
}

class HealthTool extends ConsumerStatefulWidget {
  const HealthTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<HealthTool> createState() => _HealthToolState();
}

class _HealthDraft {
  _HealthDraft({
    this.id,
    this.version,
    this.kind = HealthRecordKind.appointment,
    this.date,
    String title = '',
    String source = '',
    String value = '',
    String notes = '',
  }) : title = TextEditingController(text: title),
       source = TextEditingController(text: source),
       value = TextEditingController(text: value),
       notes = TextEditingController(text: notes) {
    _initial = _state;
  }

  final LumeRecordId? id;
  final int? version;
  HealthRecordKind kind;
  LumeDate? date;
  final TextEditingController title;
  final TextEditingController source;
  final TextEditingController value;
  final TextEditingController notes;
  final Map<String, String> errors = <String, String>{};
  late final String _initial;

  String get _state => <Object?>[
    title.text,
    source.text,
    value.text,
    notes.text,
    kind.name,
    date?.toIso(),
  ].join('\u0000');

  bool get dirty => _state != _initial;

  void dispose() {
    title.dispose();
    source.dispose();
    value.dispose();
    notes.dispose();
  }
}

class _HealthToolState extends ConsumerState<HealthTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final HealthRepository _repo = ref.read(healthRepositoryProvider);
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(text: _read('q') ?? '');
  final FocusNode _searchFocus = FocusNode();
  final GlobalKey _body = GlobalKey();

  _View _view = _View.list;
  LumeRecordId? _record;
  _HealthDraft? _draft;

  String get _id => widget.request.feature.id;
  String? _read(String key) => _session.read(_id, key);
  void _write(String key, String value) => _session.write(_id, key, value);

  HealthRecordKind? get _filter {
    final String? saved = _read('filter');
    if (saved == null || saved.isEmpty) return null;
    for (final HealthRecordKind k in HealthRecordKind.values) {
      if (k.name == saved) return k;
    }
    return null;
  }

  HealthSort get _sort => HealthSort.values.firstWhere(
    (HealthSort s) => s.name == _read('sort'),
    orElse: () => HealthSort.date,
  );
  bool get _descending => (_read('dir') ?? 'desc') == 'desc';

  @override
  void initState() {
    super.initState();
    _repo.open();
    _repo.changes.addListener(_changed);
    final LumeRecordId? kept = LumeRecordId.tryParse(_read('rec') ?? '');
    if (kept != null) {
      _record = kept;
      _view = _View.record;
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repo.changes.removeListener(_changed);
    _query.dispose();
    _searchFocus.dispose();
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
      _write('rec', v == _View.list ? '' : (_record?.value ?? ''));
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
        final _HealthDraft? d = _draft;
        if (d != null && d.dirty && !await _confirmDiscard()) return;
        if (!mounted) return;
        _draft = null;
        d?.dispose();
        _go(d?.id != null ? _View.record : _View.list);
    }
  }

  Future<bool> _confirmDiscard() async {
    final AppLocalizations l = AppLocalizations.of(context);
    return await healthDecide(
          context,
          title: l.recDiscardAsk,
          text: l.recDiscardText,
          confirm: l.recDiscard,
          cancel: l.recKeepEditing,
          destructive: true,
        ) ??
        false;
  }

  void _add(LumeDate? today) {
    _draft?.dispose();
    _draft = _HealthDraft(date: today);
    _go(_View.form);
  }

  void _edit(HealthRecord r) {
    _draft?.dispose();
    _draft = _HealthDraft(
      id: r.id,
      version: r.version,
      kind: r.kind,
      date: r.date,
      title: r.title,
      source: r.source ?? '',
      value: r.value ?? '',
      notes: r.notes ?? '',
    );
    _go(_View.form);
  }

  // ---------------------------------------------------------------- writes

  void _failed(AppLocalizations l, HealthFailure f) {
    _say(switch (f.kind) {
      HealthFailureKind.conflict || HealthFailureKind.notFound => l.recConflict,
      HealthFailureKind.damaged => l.healthErrDamaged,
      _ => l.recSaveFailed,
    }, tone: LumeToastTone.error);
  }

  Future<void> _save(AppLocalizations l) async {
    final _HealthDraft d = _draft!;
    final Map<String, String> errors = <String, String>{};

    final String title = d.title.text.trim();
    if (title.isEmpty) errors['title'] = l.recErrRequired(l.recFieldTitle);
    if (title.length > kHealthTitleMax) errors['title'] = l.healthErrTooLong;
    if (d.source.text.trim().length > kHealthSourceMax) {
      errors['source'] = l.healthErrTooLong;
    }
    if (d.value.text.trim().length > kHealthValueMax) {
      errors['value'] = l.healthErrTooLong;
    }
    if (d.notes.text.trim().length > kHealthNotesMax) {
      errors['notes'] = l.healthErrTooLong;
    }
    if (d.date == null) errors['date'] = l.recErrRequired(l.commonDate);
    setState(() {
      d.errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) return;

    final HealthDraft draft = HealthDraft(
      title: title,
      kind: d.kind,
      date: d.date!,
      source: d.source.text,
      value: d.value.text,
      notes: d.notes.text,
    );
    final HealthResult<HealthWrite> r = d.id == null
        ? _repo.add(draft)
        : _repo.edit(d.id!, draft, version: d.version!);
    if (!mounted) return;
    final HealthFailure? failure = r.failure;
    if (failure != null) {
      _failed(l, failure);
      return;
    }
    final HealthWrite w = r.value!;
    _draft = null;
    d.dispose();
    _go(_View.record, record: w.record!.id);
    _say(l.commonSaved);
  }

  /// A record is deleted for good: the sheet says so, and nothing offered
  /// afterwards pretends otherwise.
  Future<void> _delete(AppLocalizations l, HealthRecord r) async {
    final bool ok = await healthConfirmDelete(
      context,
      title: l.healthDeleteAsk,
      text: l.healthDeleteText,
    );
    if (!ok || !mounted) return;
    final HealthResult<HealthWrite> result = _repo.delete(r.id, version: r.version);
    if (result.failure != null) return _failed(l, result.failure!);
    _go(_View.list);
    _say(l.healthDeletedToast);
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(context, countryCode: widget.request.user.country);
    final LumeDate? today = _today(context);
    final HealthSnapshot snapshot = _repo.view();

    HealthBook? book;
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
        _draft?.id == null ? l.healthNewRecord : l.healthEditRecord,
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
        actions: LumeToolActions(
          onSearch: () {
            if (_view != _View.list) _go(_View.list);
            _searchFocus.requestFocus();
          },
        ),
        headerActions: _view == _View.form
            ? <Widget>[
                LumeTextButton(
                  key: LumeHealthTool.saveKey,
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

  bool _matchesFilter(HealthRecordView v, HealthRecordKind? f) =>
      f == null || v.record.kind == f;

  bool _matchesSearch(HealthRecordView v, String q) {
    if (q.isEmpty) return true;
    final HealthRecord r = v.record;
    final String hay = <String>[
      r.title,
      r.source ?? '',
      r.value ?? '',
      r.notes ?? '',
    ].join(' ').toLowerCase();
    return hay.contains(q.toLowerCase());
  }

  List<Widget> _list(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    HealthBook book,
    LumeDate? today,
  ) {
    if (book.isEmpty) {
      return <Widget>[
        LumeToolSection(
          child: LumeToolState(
            key: LumeHealthTool.emptyKey,
            icon: LumeIcons.pulse,
            title: l.healthEmptyTitle,
            text: l.healthEmptyText,
          ),
        ),
        LumeToolSection(
          child: LumeButton.accent(
            key: LumeHealthTool.addKey,
            label: l.healthAddRecord,
            block: true,
            onPressed: () => _add(today),
          ),
        ),
      ];
    }

    List<HealthRecordView> shown = <HealthRecordView>[
      for (final HealthRecordView v in book.records)
        if (_matchesFilter(v, _filter) && _matchesSearch(v, _query.text)) v,
    ];
    int cmp(HealthRecordView a, HealthRecordView b) => switch (_sort) {
      HealthSort.date => a.record.date.compareTo(b.record.date),
      HealthSort.title => a.record.title.compareTo(b.record.title),
    };
    shown.sort(cmp);
    if (_descending) shown = shown.reversed.toList();

    final Map<HealthRecordKind, int> counts = book.countsByKind;
    final int? upcoming = book.upcomingCount;

    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeHealthTool.summaryKey,
          gradient: context.lumeGradients.lock,
          kicker: l.healthSummaryKicker,
          value: f.integer(book.totalCount),
          caption: upcoming == null
              ? null
              : (upcoming > 0 ? l.healthSummaryUpcoming(upcoming) : l.healthSummaryNoneUpcoming),
          stats: <LumeStat>[
            LumeStat(value: f.integer(book.totalCount), label: l.healthStatTotal),
            LumeStat(
              value: upcoming == null ? '—' : f.integer(upcoming),
              label: l.healthStatUpcoming,
            ),
            LumeStat(value: f.integer(book.kindsUsed), label: l.healthStatTypes),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeSearchField(
          key: LumeHealthTool.searchKey,
          controller: _query,
          focusNode: _searchFocus,
          placeholder: l.healthSearch,
          onChanged: (String q) => setState(() => _write('q', q)),
        ),
      ),
      LumeToolSection(
        flush: true,
        child: LumeFilterBar(
          key: LumeHealthTool.filterKey,
          children: <Widget>[
            LumeFilterChip(
              key: LumeHealthTool.filterChip(null),
              label: l.commonAll,
              count: book.totalCount,
              selected: _filter == null,
              onTap: () => setState(() => _write('filter', '')),
            ),
            for (final HealthRecordKind k in HealthRecordKind.values)
              LumeFilterChip(
                key: LumeHealthTool.filterChip(k),
                label: HealthText.kind(l, k),
                count: counts[k] ?? 0,
                selected: _filter == k,
                onTap: () => setState(() => _write('filter', k.name)),
              ),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeSortBar(
          key: LumeHealthTool.sortKey,
          label: l.commonSort,
          value: _sort.name,
          direction: _descending ? LumeSortDirection.descending : LumeSortDirection.ascending,
          items: <LumeChoice>[
            LumeChoice(value: HealthSort.date.name, label: l.commonDate),
            LumeChoice(value: HealthSort.title.name, label: l.recFieldTitle),
          ],
          onChanged: (String v, LumeSortDirection dir) => setState(() {
            _write('sort', v);
            _write('dir', dir == LumeSortDirection.descending ? 'desc' : 'asc');
          }),
        ),
      ),
      if (shown.isEmpty)
        LumeToolSection(
          child: LumeToolState(
            key: LumeHealthTool.noMatchKey,
            icon: LumeIcons.search,
            title: l.recNoMatch,
            text: l.recNoMatchText,
          ),
        )
      else
        LumeToolSection(
          title: l.healthAll,
          child: LumeRows(
            key: LumeHealthTool.listKey,
            children: <Widget>[
              for (final HealthRecordView v in shown) _row(context, l, f, v),
            ],
          ),
        ),
      LumeToolSection(
        child: LumeButton.accent(
          key: LumeHealthTool.addKey,
          label: l.healthAddRecord,
          block: true,
          onPressed: () => _add(today),
        ),
      ),
    ];
  }

  Widget _row(BuildContext context, AppLocalizations l, LumeFormatting f, HealthRecordView v) {
    final HealthRecord r = v.record;
    return LumeRichRow(
      key: LumeHealthTool.row(r.id.value),
      icon: HealthText.icon(r.kind),
      title: r.title,
      subtitle: r.source,
      meta: <String>[HealthText.kind(l, r.kind), f.dateMediumYear(r.date.toCalendarDateTime())],
      badge: v.isUpcoming
          ? LumeBadge(
              label: v.daysUntil == 0 ? l.commonToday : l.commonInDays(v.daysUntil!),
              tone: LumeBadgeTone.info,
            )
          : null,
      value: r.value,
      chevron: true,
      onTap: () => _go(_View.record, record: r.id),
    );
  }

  // ---------------------------------------------------------------- record

  (String?, List<Widget>, bool) _recordScreen(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    HealthBook book,
  ) {
    final HealthRecordView? v = _record == null ? null : book.record(_record!);
    if (v == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _go(_View.list));
      return (null, const <Widget>[], false);
    }
    final HealthRecord r = v.record;
    return (
      r.title,
      <Widget>[
        LumeRecordHero(
          key: LumeHealthTool.recordKey,
          gradient: context.lumeGradients.lock,
          kicker: HealthText.kind(l, r.kind),
          value: r.title,
          caption: r.source == null
              ? f.dateMediumYear(r.date.toCalendarDateTime())
              : '${f.dateMediumYear(r.date.toCalendarDateTime())} · ${r.source}',
        ),
        const SizedBox(height: 20),
        Container(
          key: LumeHealthTool.factsKey,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          decoration: BoxDecoration(
            color: context.lume.card,
            borderRadius: LumeRadius.brMd,
            border: Border.all(color: context.lume.border, width: LumeSpace.border),
            boxShadow: context.lumeShadows.xs,
          ),
          child: LumeFactCard(
            facts: <LumeFact>[
              LumeFact(label: l.healthFieldType, value: HealthText.kind(l, r.kind)),
              LumeFact(label: l.commonDate, value: f.dateMediumYear(r.date.toCalendarDateTime())),
              LumeFact(label: l.healthFieldSource, value: r.source ?? '—'),
              LumeFact(label: l.commonValue, value: r.value ?? '—'),
              LumeFact(label: l.recFieldNotes, value: r.notes ?? l.recNone, block: true),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LumeDetailActions(
          key: LumeHealthTool.detailActionsKey,
          editLabel: l.actionEdit,
          onEdit: () => _edit(r),
          deleteLabel: l.actionDelete,
          onDelete: () => unawaited(_delete(l, r)),
        ),
      ],
      true,
    );
  }

  // ------------------------------------------------------------------ form

  Future<void> _chooseKind(AppLocalizations l) async {
    final _HealthDraft d = _draft!;
    final HealthRecordKind? chosen = await showLumeSheet<HealthRecordKind>(
      context: context,
      barrierLabel: l.healthFieldType,
      child: Builder(
        builder: (BuildContext sheet) => LumeSheet(
          title: l.healthFieldType,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final HealthRecordKind k in HealthRecordKind.values)
                LumeRadioRow(
                  label: HealthText.kind(l, k),
                  selected: k == d.kind,
                  onTap: () => Navigator.of(sheet).pop(k),
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) setState(() => d.kind = chosen);
  }

  Future<void> _chooseDate(BuildContext context) async {
    final _HealthDraft d = _draft!;
    final DateTime base = d.date?.toCalendarDateTime() ?? LumeClockScope.of(context).now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(base.year - 100),
      lastDate: DateTime(base.year + 20),
    );
    if (picked != null && mounted) {
      setState(() => d.date = LumeDate.ofWallClock(picked));
    }
  }

  List<Widget> _form(BuildContext context, AppLocalizations l, LumeFormatting f) {
    final _HealthDraft d = _draft!;
    return <Widget>[
      LumeToolSection(
        child: LumeFormCard(
          key: LumeHealthTool.formKey,
          children: <Widget>[
            LumeFormField(
              key: LumeHealthTool.titleField,
              label: l.recFieldTitle,
              controller: d.title,
              placeholder: l.healthTitlePlaceholder,
              required: true,
              autofocus: d.id == null,
              error: d.errors['title'],
            ),
            LumeFormPicker(
              key: LumeHealthTool.typeField,
              label: l.healthFieldType,
              value: HealthText.kind(l, d.kind),
              onTap: () => unawaited(_chooseKind(l)),
            ),
            LumeFormPicker(
              key: LumeHealthTool.dateField,
              label: l.commonDate,
              value: d.date == null
                  ? l.actionNotSet
                  : f.dateMediumYear(d.date!.toCalendarDateTime()),
              icon: LumeIcons.calendar,
              onTap: () => unawaited(_chooseDate(context)),
            ),
            LumeFormField(
              key: LumeHealthTool.sourceField,
              label: l.healthFieldSource,
              controller: d.source,
              placeholder: l.healthSourcePlaceholder,
              optionalLabel: l.recOptional,
              error: d.errors['source'],
            ),
            LumeFormField(
              key: LumeHealthTool.valueField,
              label: l.commonValue,
              controller: d.value,
              optionalLabel: l.recOptional,
              error: d.errors['value'],
            ),
            LumeFormField(
              key: LumeHealthTool.notesField,
              label: l.recFieldNotes,
              controller: d.notes,
              optionalLabel: l.recOptional,
              kind: LumeFieldKind.multiline,
              error: d.errors['notes'],
            ),
          ],
        ),
      ),
    ];
  }
}

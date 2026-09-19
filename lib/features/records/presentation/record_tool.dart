/// One host for a record tool — `crud-engine.js` with `engine.js`
/// `withRecords`, for the families of rollout wave 2.
///
/// Documents and Expenses each carry this lifecycle inline. What they share
/// is proven twice over — the list and its states, search, chips, the
/// two-pane width, the detail, the form and its validation, the dirty guard,
/// save, undo and delete — and is drawn here once, from a
/// [LumeRecordFamily]. What differs by family (its fields, how a row reads,
/// a tick on the row, a bulk clear) is the family's.
///
/// The record list leads ("lists are the home of record-based tools", CRUD
/// guide §1); the tool's own composition follows, and reads the same records
/// the list does ([LumeRecordScope.items]), so the two never disagree (C86).
/// A record's detail and form take the whole screen, or sit beside the list
/// at expanded width. Records are kept in memory and declared not durable
/// (C74).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../../../app/providers/shell_provider.dart';
import '../../../app/providers/time_zone_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/navigation/lume_back_intercept.dart';
import '../../../core/platform/lume_share.dart' show LumeShareCard;
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
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
import '../application/record_form.dart';
import '../data/record_seeds.dart';
import '../domain/record_model.dart';
import '../domain/record_repository.dart';
import '../domain/record_schema.dart';
import 'record_family.dart';

/// Every key a record tool's test reaches for, scoped by tool id.
@immutable
class LumeRecordKeys {
  const LumeRecordKeys(this.tool);

  final String tool;

  Key _k(String name) => ValueKey<String>('$tool.$name');

  Key get add => _k('add');
  Key get search => _k('search');
  Key get chips => _k('chips');
  Key get records => _k('records');
  Key get recordState => _k('recordState');
  Key get bulk => _k('bulk');
  Key get hero => _k('hero');
  Key get facts => _k('facts');
  Key get detailActions => _k('detailActions');
  Key get recordId => _k('recordId');
  Key get form => _k('form');
  Key get submit => _k('submit');
  Key field(String name) => _k('field.$name');
  Key clearField(String name) => _k('clear.$name');
  Key chip(String value) => _k('chip.$value');
  Key row(String id) => _k('row.$id');
}

/// What a tool's composition is given: the same records the list shows, and
/// the list's own actions, so a composition never writes around the host.
class LumeRecordScope<T extends LumeFamilyRecord> {
  LumeRecordScope._(this._host, this.c, this.items, this.status);

  final _LumeRecordToolState<T> _host;
  final LumeRecordContext c;

  /// Every record, newest first; empty while loading or unreadable.
  final List<T> items;

  final LumeCollectionStatus status;

  /// The one query the list and the composition share (`c.state('q')`).
  String get query => _host._query.text;

  String? read(String key) => _host._read(key);
  void write(String key, String value) =>
      _host._set(() => _host._write(key, value));

  void open(String id) => _host._open(id);
  void create() => _host._startCreate();
  void toggle(T x) => _host._toggle(x);
  Future<void> bulk() => _host._askBulk();
  void say(String message, {LumeToastTone tone = LumeToastTone.success}) =>
      _host._say?.say(message, tone: tone);
  Future<void> share() async => _host._host.currentState?.share();
}

/// What a tool that groups by the reader's day shows instead, when that day
/// cannot be worked out ([LumeRecordContext.dayKnown] is false): which zone
/// could not be read, and where to set one. The records are still listed
/// above it; nothing is grouped on another zone's day.
class LumeRecordDayUnknown extends StatelessWidget {
  const LumeRecordDayUnknown({super.key, required this.c});

  final LumeRecordContext c;

  @override
  Widget build(BuildContext context) {
    final String? asked = c.zone.requested;
    return LumeToolState(
      icon: LumeIcons.clock,
      title: c.l.recZoneUnknownTitle,
      text: switch (c.zone.outcome) {
        LumeZoneOutcome.selectionRequired => c.l.recZoneChooseText,
        _ when asked == null || asked.isEmpty => c.l.recZoneMissingText,
        _ => c.l.recZoneUnknownText(LumeFamilyText.isolate(asked)),
      },
    );
  }
}

typedef LumeRecordComposition<T extends LumeFamilyRecord> =
    List<Widget> Function(BuildContext context, LumeRecordScope<T> scope);

class LumeRecordTool<T extends LumeFamilyRecord>
    extends ConsumerStatefulWidget {
  const LumeRecordTool({
    super.key,
    required this.request,
    required this.family,
    required this.compose,
    this.floating,
    this.shareCard,
  });

  final LumeToolRequest request;
  final LumeRecordFamily<T> family;

  /// The tool's own sections, after the records.
  final LumeRecordComposition<T> compose;

  /// A floating action over the list screen.
  final Widget Function(BuildContext context, LumeRecordScope<T> scope)?
  floating;

  /// The host's share card, where the family has one.
  final LumeShareCard? Function(LumeRecordScope<T> scope)? shareCard;

  @override
  ConsumerState<LumeRecordTool<T>> createState() => _LumeRecordToolState<T>();
}

class _LumeRecordToolState<T extends LumeFamilyRecord>
    extends ConsumerState<LumeRecordTool<T>> {
  static const double _chipOverhang =
      (LumeSpace.tap - LumeRecordChip.height) / 2;

  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final LumeRecordRepository _repo = ref.read(recordRepositoryProvider);
  late final TextEditingController _query = TextEditingController(
    text: _session.read(_id, 'q') ?? '',
  );
  final FocusNode _searchFocus = FocusNode();

  LumeRecordForm? _form;
  final Map<String, TextEditingController> _text =
      <String, TextEditingController>{};
  final Map<String, FocusNode> _focus = <String, FocusNode>{};

  LumeRecordFamily<T> get _family => widget.family;
  LumeRecordSchema get _schema => _family.schema;
  String get _coll => _family.collection;
  String get _id => widget.request.feature.id;
  LumeRecordKeys get _keys => LumeRecordKeys(_id);

  bool _isText(LumeRecordField f) => switch (f.kind) {
    LumeRecordFieldKind.text ||
    LumeRecordFieldKind.textarea ||
    LumeRecordFieldKind.number ||
    LumeRecordFieldKind.money => true,
    _ => false,
  };

  @override
  void initState() {
    super.initState();
    for (final LumeRecordField f in _schema.fields) {
      _focus[f.name] = FocusNode();
      if (_isText(f)) _text[f.name] = TextEditingController();
    }
    _repo.addListener(_changed);
    _repo.open(_coll);
    // A draft does not outlive the screen that held it; the view it was in
    // does not come back without it.
    if (_view == 'new' || _view == 'edit') _write('view', '');
  }

  @override
  void dispose() {
    _repo.removeListener(_changed);
    _form?.dispose();
    _query.dispose();
    _searchFocus.dispose();
    for (final TextEditingController c in _text.values) {
      c.dispose();
    }
    for (final FocusNode n in _focus.values) {
      n.dispose();
    }
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _set(VoidCallback fn) => setState(fn);

  String? _read(String k) => _session.read(_id, k);
  void _write(String k, String v) => _session.write(_id, k, v);

  String get _view => _read('view') ?? '';
  String get _selected => _read('rec') ?? '';

  LumeToolScreenState? get _say => _host.currentState;

  LumeRecordContext _context() {
    final LumeToolRequest r = widget.request;
    final LumeStartupState startup = ref.read(startupControllerProvider).state;
    return LumeRecordContext(
      l: AppLocalizations.of(context),
      f: LumeFormatting.of(context, countryCode: r.user.country),
      now: LumeClockScope.of(context).now(),
      zone: ref
          .read(timeZoneServiceProvider)
          .readerZone(
            startup.profile,
            ref.read(deviceZoneProvider),
            country: r.user.country,
            city: r.user.city,
          ),
      currency: startup.countries?.currencyOf(r.user.country) ?? '',
    );
  }

  // ------------------------------------------------------------ transitions

  void _open(String id) => setState(() {
    _write('rec', id);
    if (!context.hasDetailPane) _write('view', 'detail');
  });

  void _backToList() => setState(() {
    _write('view', '');
    _write('rec', '');
  });

  void _bindForm(LumeRecordForm form) {
    _form?.dispose();
    _form = form
      ..addListener(_changed)
      ..onSettled = _settled;
    for (final MapEntry<String, TextEditingController> e in _text.entries) {
      final Object? v = form.value(e.key);
      e.value.text = v == null ? '' : '$v';
    }
  }

  void _focusFirst() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus[_schema.fields.first.name]?.requestFocus();
    });
  }

  void _startCreate() {
    _bindForm(
      LumeRecordForm.create(
        schema: _schema,
        repository: _repo,
        defaults: _family.defaults(_context()),
      ),
    );
    setState(() => _write('view', 'new'));
    _focusFirst();
  }

  void _startEdit(String id) {
    final LumeRecordContext c = _context();
    final LumeRecord? r = _repo.get(_coll, id);
    if (r == null) {
      _say?.say(c.l.recGone, tone: LumeToastTone.error);
      return;
    }
    _bindForm(
      LumeRecordForm.edit(
        schema: _schema,
        repository: _repo,
        record: r.copyWith(
          fields: <String, Object?>{
            ...r.fields,
            ..._family.editValues(_family.read(r, c)),
          },
        ),
      ),
    );
    setState(() {
      _write('view', 'edit');
      _write('rec', id);
    });
    _focusFirst();
  }

  void _closeForm() {
    _form?.dispose();
    _form = null;
    setState(
      () => _write(
        'view',
        _selected.isNotEmpty && !context.hasDetailPane ? 'detail' : '',
      ),
    );
  }

  Future<void> _leaveForm() async {
    final AppLocalizations l = AppLocalizations.of(context);
    if (!(_form?.dirty ?? false)) {
      _closeForm();
      return;
    }
    final bool discard = await _confirm(
      title: l.recDiscardAsk,
      text: l.recDiscardText,
      confirm: l.recDiscard,
      cancel: l.recKeepEditing,
      warn: true,
    );
    if (discard && mounted) _closeForm();
  }

  void _save() {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeRecordForm? form = _form;
    if (form == null) return;
    switch (form.save()) {
      case LumeSubmitStatus.invalid:
        _say?.say(l.recCheckFields, tone: LumeToastTone.error);
        final String? first = form.firstError;
        if (first != null) _focus[first]?.requestFocus();
      case LumeSubmitStatus.busy:
      case LumeSubmitStatus.saving:
        break;
    }
  }

  void _settled(LumeSaveOutcome outcome, LumeRecord? record) {
    if (!mounted) return;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeRecordForm? form = _form;
    switch (outcome) {
      case LumeSaveOutcome.conflict:
        _say?.say(l.recConflict, tone: LumeToastTone.error);
      case LumeSaveOutcome.failed:
        _say?.say(l.recSaveFailed, tone: LumeToastTone.error);
      case LumeSaveOutcome.saved:
        final bool created = form?.mode == LumeFormMode.create;
        form?.dispose();
        _form = null;
        setState(() {
          _write('rec', record!.id);
          _write('view', context.hasDetailPane ? '' : 'detail');
        });
        _say?.say(
          LumeFamilyText.sentence(
            created ? l.recAdded(_family.noun(l)) : l.recUpdated,
          ),
          actionLabel: l.recUndo,
          onAction: _undo,
        );
    }
  }

  void _undo() {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeUndone? done = _repo.undo();
    if (done == null) {
      _say?.say(l.recNothingToUndo, tone: LumeToastTone.info);
      return;
    }
    setState(() {
      if (done.record != null) {
        _write('rec', done.record!.id);
      } else {
        _write('rec', '');
        _write('view', '');
      }
    });
    _say?.say(l.recUndone);
  }

  /// `rec:toggle` — fast optimistic logging: the row flips now, with no form
  /// and no words written.
  void _toggle(T x) {
    final LumeRecordContext c = _context();
    final LumeWriteResult result = _repo.update(
      _coll,
      x.id,
      _family.toggled(x, c),
      expectVersion: x.version,
      claim: false,
    );
    if (!result.ok) {
      _say?.say(
        result.failure == LumeWriteFailure.conflict
            ? c.l.recConflict
            : c.l.recSaveFailed,
        tone: LumeToastTone.error,
      );
    }
  }

  Future<void> _askDelete(T x) async {
    final LumeRecordContext c = _context();
    final AppLocalizations l = c.l;
    final String noun = _family.noun(l);
    final bool undoable = _schema.recoverable;
    final String name = _family.row(x, c).title;
    final bool go = await _confirm(
      title: LumeFamilyText.sentence(l.recDeleteAsk(noun)),
      text: undoable ? l.recDeleteTextUndo(name) : l.recDeleteTextFinal(name),
      confirm: LumeFamilyText.sentence(l.recDelete(noun)),
      cancel: l.actionCancel,
      kind: undoable ? LumeDeleteKind.recoverable : LumeDeleteKind.irreversible,
    );
    if (!go || !mounted) return;
    final LumeWriteResult result = _repo.remove(_coll, x.id);
    if (!result.ok) {
      _say?.say(l.recDeleteFailed, tone: LumeToastTone.error);
      return;
    }
    if (!undoable) _repo.forgetUndo();
    setState(() {
      _write('rec', '');
      _write('view', '');
    });
    if (undoable) {
      _say?.say(
        LumeFamilyText.sentence(l.recDeleted(noun)),
        actionLabel: l.recUndo,
        onAction: _undo,
      );
    } else {
      _say?.say(LumeFamilyText.sentence(l.recDeletedFinal(noun)));
    }
  }

  /// `rec:bulk` then `rec:bulkgo` — confirmed, and never undoable: a bulk
  /// clear could restore only the last of what it removed.
  Future<void> _askBulk() async {
    final LumeRecordContext c = _context();
    final LumeFamilyBulk<T>? bulk = _family.bulk(c.l);
    if (bulk == null) return;
    final List<T> doomed = _items(c).where(bulk.test).toList();
    if (doomed.isEmpty) return;
    final bool go = await _confirm(
      title: bulk.label(doomed.length),
      text: bulk.confirm(doomed.length),
      confirm: bulk.label(doomed.length),
      cancel: c.l.actionCancel,
      kind: LumeDeleteKind.irreversible,
    );
    if (!go || !mounted) return;
    int removed = 0;
    for (final T x in doomed) {
      if (_repo.remove(_coll, x.id).ok) removed++;
    }
    _repo.forgetUndo();
    setState(() {
      if (doomed.any((T x) => x.id == _selected)) _write('rec', '');
    });
    _say?.say(c.l.recCleared(removed));
  }

  Future<bool> _confirm({
    required String title,
    required String text,
    required String confirm,
    required String cancel,
    bool warn = false,
    LumeDeleteKind kind = LumeDeleteKind.recoverable,
  }) async {
    final bool? answer = await showLumeSheet<bool>(
      context: context,
      barrierLabel: title,
      child: Builder(
        builder: (BuildContext sheet) => LumeSheet(
          confirm: true,
          child: LumeDeleteConfirmation(
            title: title,
            consequence: text,
            confirmLabel: confirm,
            cancelLabel: cancel,
            warn: warn,
            kind: kind,
            onConfirm: () => Navigator.of(sheet).pop(true),
            onCancel: () => Navigator.of(sheet).pop(false),
          ),
        ),
      ),
    );
    return answer ?? false;
  }

  Future<void> _choose(LumeFamilyField field) async {
    final Object? current = _form?.value(field.name);
    final String? chosen = await showLumeSheet<String>(
      context: context,
      barrierLabel: field.label,
      child: Builder(
        builder: (BuildContext sheet) => LumeSheet(
          title: field.label,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final LumeFamilyOption o in field.options)
                LumeRadioRow(
                  label: o.label,
                  selected: o.value == current,
                  onTap: () => Navigator.of(sheet).pop(o.value),
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) {
      _form?.setValue(field.name, chosen);
      _form?.touch(field.name);
    }
  }

  Future<void> _chooseDay(String name) async {
    final DateTime now = _context().today;
    final DateTime initial = LumeFamilyText.day(_form?.value(name)) ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 50),
      lastDate: DateTime(now.year + 50),
    );
    if (picked != null) {
      _form?.setValue(name, lumeIsoDay(picked, 0));
      _form?.touch(name);
    }
  }

  Future<void> _chooseTime(String name) async {
    final (int, int)? t = LumeFamilyText.clock(_form?.value(name));
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: t == null
          ? TimeOfDay.fromDateTime(_context().local)
          : TimeOfDay(hour: t.$1, minute: t.$2),
    );
    if (picked != null) {
      _form?.setValue(
        name,
        LumeFamilyText.isoClock(picked.hour, picked.minute),
      );
      _form?.touch(name);
    }
  }

  // ------------------------------------------------------------------ build

  List<T> _items(LumeRecordContext c) => <T>[
    for (final LumeRecord r in _repo.view(_coll).items) _family.read(r, c),
  ];

  @override
  Widget build(BuildContext context) {
    final LumeRecordContext c = _context();
    final Widget screen = switch (_view) {
      'new' || 'edit' when _form != null => _formScreen(c),
      'detail' => _detailScreen(c),
      _ => _listScreen(c),
    };
    if (_view.isEmpty) return screen;
    return LumeBackIntercept(
      onBack: () async {
        if (_view == 'detail') {
          _backToList();
        } else {
          await _leaveForm();
        }
        return true;
      },
      child: screen,
    );
  }

  // ------------------------------------------------------------------- list

  String? _headerSub(AppLocalizations l, LumeCollectionView v) =>
      switch (v.status) {
        LumeCollectionStatus.loading => null,
        LumeCollectionStatus.error => l.recCouldNotRefresh,
        _ when v.items.isEmpty => l.recNoneYet,
        _ => l.recCount(v.items.length),
      };

  Widget _listScreen(LumeRecordContext c) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = c.l;
    final LumeCollectionView v = _repo.view(_coll);
    final List<T> items = _items(c);
    final LumeRecordScope<T> scope = LumeRecordScope<T>._(
      this,
      c,
      items,
      v.status,
    );

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      subtitle: _headerSub(l, v),
      leadingAction: LumeTextButton(
        key: _keys.add,
        label: l.actionAdd,
        icon: LumeIcons.plus,
        semanticLabel: LumeFamilyText.sentence(l.recAdd(_family.noun(l))),
        onPressed: _startCreate,
      ),
      actions: LumeToolActions(onSearch: _searchFocus.requestFocus),
      shareCard: widget.shareCard == null
          ? null
          : () => widget.shareCard!(scope),
      floating: widget.floating?.call(context, scope),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(tight: true, child: _records(c, v, items)),
          ...widget.compose(context, scope),
        ],
      ),
    );
  }

  Widget _records(LumeRecordContext c, LumeCollectionView v, List<T> all) {
    final AppLocalizations l = c.l;
    final String noun = _family.noun(l);
    final String plural = _family.nounPlural(l);

    switch (v.status) {
      case LumeCollectionStatus.loading:
        return const LumeSkeleton(kind: LumeSkeletonKind.record, count: 4);
      case LumeCollectionStatus.error:
        return LumeCollectionState(
          key: _keys.recordState,
          kind: LumeCollectionStateKind.error,
          title: l.recLoadError(plural),
          text: l.recLoadErrorText,
          primaryAction: LumeButton.accent(
            label: l.actionTryAgain,
            onPressed: () => setState(() => _repo.retry(_coll)),
          ),
          secondaryAction: LumeButton(
            label: l.recViewCached,
            onPressed: () => setState(() => _repo.retry(_coll)),
          ),
        );
      case LumeCollectionStatus.ready:
      case LumeCollectionStatus.offline:
        break;
    }

    if (all.isEmpty) {
      return LumeCollectionState(
        key: _keys.recordState,
        kind: LumeCollectionStateKind.empty,
        icon: _family.icon,
        title: _family.emptyTitle(l),
        text: _family.emptyText(l),
        primaryAction: LumeButton.accent(
          label: LumeFamilyText.sentence(l.recAddFirst(noun)),
          onPressed: _startCreate,
        ),
        footnote: l.recImportLater,
      );
    }

    final List<LumeFamilyFilter<T>> filters = _family.filters(c);
    final String chosen = _read('cfil') ?? 'all';
    final LumeFamilyFilter<T>? active = filters
        .where((LumeFamilyFilter<T> x) => x.value == chosen)
        .firstOrNull;
    final List<T> rows = <T>[
      for (final T x in all)
        if ((active == null || active.test(x)) &&
            _family.matches(x, _query.text, c))
          x,
    ];
    final bool pane = context.hasDetailPane;
    final double gutter = LumeLayout.pageGutter(context.measureClass);
    final String? check = _family.checkLabel(l);
    final LumeFamilyBulk<T>? bulk = _family.bulk(l);
    final int bulkCount = bulk == null ? 0 : all.where(bulk.test).length;

    final Widget list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (v.isOffline) ...<Widget>[
          LumeNotice(
            kind: LumeNoticeKind.offline,
            title: l.recOffline,
            text: l.recOfflineText,
          ),
          const SizedBox(height: 18),
        ],
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: LumeSearchField(
            key: _keys.search,
            controller: _query,
            focusNode: _searchFocus,
            placeholder: l.recSearch(plural),
            onChanged: (String q) => setState(() => _write('q', q)),
          ),
        ),
        if (filters.isNotEmpty) ...<Widget>[
          // Each chip's target reaches past its drawing; those points come
          // out of the 12 either side.
          const SizedBox(height: 12 - _chipOverhang),
          SingleChildScrollView(
            key: _keys.chips,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: <Widget>[
                for (final (int i, (String value, String label, int count))
                    in <(String, String, int)>[
                      ('all', l.commonAll, all.length),
                      for (final LumeFamilyFilter<T> x in filters)
                        (x.value, x.label, all.where(x.test).length),
                    ].indexed) ...<Widget>[
                  if (i > 0) const SizedBox(width: 8),
                  LumeRecordChip(
                    key: _keys.chip(value),
                    label: label,
                    count: count,
                    selected: value == chosen,
                    onTap: () => setState(() => _write('cfil', value)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12 - _chipOverhang),
        ],
        if (rows.isEmpty)
          LumeCollectionState(
            key: _keys.recordState,
            kind: LumeCollectionStateKind.noResults,
            title: l.recNoMatch,
            text: l.recNoMatchText,
            primaryAction: LumeButton(
              label: l.actionClear,
              onPressed: () => setState(() {
                _query.clear();
                _write('q', '');
                _write('cfil', 'all');
              }),
            ),
          )
        else
          LumeRecordList(
            key: _keys.records,
            children: <Widget>[for (final T x in rows) _row(c, x, pane, check)],
          ),
        // `.cbulk { margin-top: 14px } .cbulk .btn { width: 100% }`.
        if (bulk != null && bulkCount > 0) ...<Widget>[
          const SizedBox(height: 14),
          LumeButton(
            key: _keys.bulk,
            label: bulk.label(bulkCount),
            icon: LumeIcons.trash,
            onPressed: _askBulk,
          ),
        ],
      ],
    );

    if (!pane) return list;
    final LumeRecord? selected = _selected.isEmpty
        ? null
        : _repo.get(_coll, _selected);
    return LumeMasterDetail(
      list: list,
      detailKey: ValueKey<String?>(selected?.id),
      detail: selected == null
          ? LumeCollectionState(
              kind: LumeCollectionStateKind.pane,
              icon: _family.icon,
              title: l.recSelectTitle,
              text: l.recSelectText,
            )
          : _detailBody(c, _family.read(selected, c)),
    );
  }

  Widget _row(LumeRecordContext c, T x, bool pane, String? check) {
    final LumeFamilyRow row = _family.row(x, c);
    return LumeRecordRow(
      key: _keys.row(x.id),
      initial: LumeFamilyText.initial(row.title),
      title: row.title,
      subtitle: row.subtitle,
      meta: row.meta,
      value: row.value,
      badge: row.badge,
      done: check != null && _family.checked(x),
      checkLabel: check,
      queuedLabel: x.record.queued ? c.l.recQueued : null,
      selected: pane && x.id == _selected,
      onTap: () => _open(x.id),
      onToggle: check == null ? null : (bool _) => _toggle(x),
    );
  }

  // ----------------------------------------------------------------- detail

  Widget _detailScreen(LumeRecordContext c) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = c.l;
    final LumeRecord? rec = _repo.get(_coll, _selected);
    final String noun = _family.noun(l);
    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      bare: true,
      onBack: _backToList,
      title: LumeFamilyText.sentence(l.recDetailTitle(noun)),
      subtitle: rec == null ? '' : _created(c, rec),
      headerActions: <Widget>[
        if (rec != null)
          LumeIconButton(
            icon: LumeIcons.note,
            label: LumeFamilyText.sentence(l.recEdit(noun)),
            onPressed: () => _startEdit(rec.id),
          ),
      ],
      body: LumeToolSection(
        child: rec == null
            ? LumeCollectionState(
                key: _keys.recordState,
                kind: LumeCollectionStateKind.noResults,
                title: l.recGone,
                text: l.recGoneText,
                primaryAction: LumeButton(
                  label: LumeFamilyText.sentence(
                    l.recBackToList(_family.nounPlural(l)),
                  ),
                  onPressed: _backToList,
                ),
              )
            : _detailBody(c, _family.read(rec, c)),
      ),
    );
  }

  /// `createdLabel(c, r)`.
  String _created(LumeRecordContext c, LumeRecord r) {
    final int days = LumeFamilyText.daysFrom(r.createdAt, c.now)!;
    if (days == 0) return c.l.recCreatedToday;
    if (days == -1) return c.l.recCreatedYesterday;
    return c.l.recCreated(c.f.dateShort(r.createdAt));
  }

  Widget _detailBody(LumeRecordContext c, T x) {
    final LumeColors lume = context.lume;
    final AppLocalizations l = c.l;
    final String noun = _family.noun(l);
    final LumeFamilyHero hero = _family.hero(x, c);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LumeRecordHero(
          key: _keys.hero,
          gradient: hero.gradient?.call(context.lumeGradients),
          kicker: hero.kicker,
          value: hero.value,
          title: hero.title,
          caption: hero.caption,
        ),
        Semantics(
          header: true,
          child: Text(
            l.recDetails,
            style: LumeType.tracked(
              LumeType.natural(context, context.lumeType.cardTitle),
              -0.028,
            ).copyWith(color: lume.text, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          key: _keys.facts,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          decoration: BoxDecoration(
            color: lume.card,
            borderRadius: LumeRadius.brMd,
            border: Border.all(color: lume.border, width: LumeSpace.border),
            boxShadow: context.lumeShadows.xs,
          ),
          child: LumeFactCard(facts: _family.facts(x, c)),
        ),
        const SizedBox(height: 20),
        LumeDetailActions(
          key: _keys.detailActions,
          editLabel: LumeFamilyText.sentence(l.recEdit(noun)),
          onEdit: () => _startEdit(x.id),
          deleteLabel: LumeFamilyText.sentence(l.recDelete(noun)),
          onDelete: () => _askDelete(x),
        ),
        const SizedBox(height: 18),
        LumeRecordId(
          key: _keys.recordId,
          label: l.recRecordId(x.id.toUpperCase()),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------- form

  Widget _formScreen(LumeRecordContext c) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = c.l;
    final LumeRecordForm form = _form!;
    final bool creating = form.mode == LumeFormMode.create;
    final String noun = _family.noun(l);
    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      bare: true,
      onBack: _leaveForm,
      title: LumeFamilyText.sentence(
        creating ? l.recAdd(noun) : l.recEdit(noun),
      ),
      subtitle: creating ? l.recNewRecord : l.recEditing,
      headerActions: <Widget>[
        LumeTextButton(label: l.actionSave, onPressed: _save),
      ],
      body: LumeToolSection(child: _formBody(c, form)),
    );
  }

  String? _error(
    AppLocalizations l,
    LumeRecordForm form,
    String name,
    String label,
  ) => switch (form.shownError(name)) {
    LumeFieldError.required => l.recErrRequired(label),
    LumeFieldError.positive => l.recErrPositive,
    null => null,
  };

  Widget _field(
    LumeRecordContext c,
    LumeRecordForm form,
    LumeRecordField spec,
    LumeFamilyField field,
  ) {
    final AppLocalizations l = c.l;
    final String name = spec.name;
    final String? optional = spec.required ? null : l.recOptional;
    final Object? value = form.value(name);

    switch (spec.kind) {
      case LumeRecordFieldKind.text:
      case LumeRecordFieldKind.textarea:
      case LumeRecordFieldKind.number:
      case LumeRecordFieldKind.money:
        return LumeFormField(
          key: _keys.field(name),
          label: field.label,
          optionalLabel: optional,
          controller: _text[name],
          focusNode: _focus[name],
          placeholder: field.placeholder,
          required: spec.required,
          rows: spec.rows,
          kind: switch (spec.kind) {
            LumeRecordFieldKind.textarea => LumeFieldKind.multiline,
            LumeRecordFieldKind.number => LumeFieldKind.number,
            LumeRecordFieldKind.money => LumeFieldKind.money,
            _ => LumeFieldKind.text,
          },
          prefix: spec.kind == LumeRecordFieldKind.money && c.currency != ''
              ? c.currency
              : null,
          error: _error(l, form, name, field.label),
          onChanged: (String v) => form.setValue(name, v),
          onEditingComplete: () => form.touch(name),
        );
      case LumeRecordFieldKind.select:
        final LumeFamilyOption? o = field.options
            .where((LumeFamilyOption o) => o.value == value)
            .firstOrNull;
        return LumeFormPicker(
          key: _keys.field(name),
          label: field.label,
          optionalLabel: optional,
          value: o?.label ?? '—',
          onTap: () => _choose(field),
        );
      case LumeRecordFieldKind.date:
      case LumeRecordFieldKind.time:
        final bool date = spec.kind == LumeRecordFieldKind.date;
        final String shown = date
            ? (LumeFamilyText.day(value) == null
                  ? '—'
                  : c.f.dateShort(LumeFamilyText.day(value)!))
            : (LumeFamilyText.clock(value) == null
                  ? '—'
                  : LumeFamilyText.showClock(c, value));
        final bool set = shown != '—';
        final String? error = _error(l, form, name, field.label);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LumeFormPicker(
              key: _keys.field(name),
              label: field.label,
              optionalLabel: optional,
              value: shown,
              icon: date ? LumeIcons.calendar : LumeIcons.clock,
              onTap: () => date ? _chooseDay(name) : _chooseTime(name),
            ),
            // A native date input can be emptied; a picker cannot, so an
            // optional one says how.
            if (!spec.required && set)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: LumeTextButton(
                  key: _keys.clearField(name),
                  label: l.actionClear,
                  semanticLabel:
                      field.clearLabel ?? '${l.actionClear} ${field.label}',
                  onPressed: () {
                    form.setValue(name, '');
                    form.touch(name);
                  },
                ),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  error,
                  style: LumeType.fit(
                    context,
                    context.lumeType.metaSmall,
                  ).copyWith(color: context.lume.roseInk),
                ),
              ),
          ],
        );
      case LumeRecordFieldKind.check:
        return LumeCheckbox(
          key: _keys.field(name),
          label: field.label,
          value: value == true,
          onChanged: (bool v) {
            form.setValue(name, v);
            form.touch(name);
          },
        );
      case LumeRecordFieldKind.attach:
        return LumeAttachTile(
          key: _keys.field(name),
          fieldLabel: field.label,
          label: l.recAttach,
          optionalLabel: optional,
          onTap: () => _say?.say(l.recAttachSoon, tone: LumeToastTone.info),
        );
    }
  }

  Widget _formBody(LumeRecordContext c, LumeRecordForm form) {
    final LumeColors lume = context.lume;
    final AppLocalizations l = c.l;
    final bool creating = form.mode == LumeFormMode.create;
    final String noun = _family.noun(l);
    final bool pair = context.hasDetailPane;
    final Map<String, LumeFamilyField> specs = <String, LumeFamilyField>{
      for (final LumeFamilyField x in _family.fields(c)) x.name: x,
    };

    final List<(bool, Widget)> fields = <(bool, Widget)>[
      for (final LumeRecordField f in _schema.fields)
        (
          f.wide,
          Focus(
            focusNode: _isText(f) ? null : _focus[f.name],
            child: _field(c, form, f, specs[f.name]!),
          ),
        ),
    ];

    final List<Widget> notices = <Widget>[
      if (form.conflict != null)
        LumeNotice(
          kind: LumeNoticeKind.warning,
          title: l.recConflict,
          text: l.recConflictText,
          actions: <Widget>[
            LumeNoticeAction(
              label: l.recReview,
              onPressed: form.reviewConflict,
            ),
            LumeNoticeAction(
              label: l.recReload,
              onPressed: () {
                form.reloadConflict();
                _bindForm(form);
                _say?.say(l.recReloaded);
              },
            ),
          ],
        ),
      if (form.failure != null)
        LumeNotice(
          kind: LumeNoticeKind.error,
          title: l.recSaveFailed,
          text: l.recSaveFailedText,
          actions: <Widget>[
            LumeNoticeAction(label: l.actionTryAgain, onPressed: _save),
          ],
        ),
      if (_repo.isOffline)
        LumeNotice(
          kind: LumeNoticeKind.offline,
          title: l.recOffline,
          text: l.recOfflineQueued,
        ),
    ];

    final String saveLabel = LumeFamilyText.sentence(
      creating ? l.recSave(noun) : l.recUpdate,
    );

    if (!pair) {
      return Column(
        key: _keys.form,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final Widget n in notices) ...<Widget>[
            n,
            const SizedBox(height: 18),
          ],
          for (final (int i, (bool _, Widget w)) in fields.indexed) ...<Widget>[
            if (i > 0) const SizedBox(height: 18),
            w,
          ],
          const SizedBox(height: 28),
          LumeSubmitBar(
            key: _keys.submit,
            saveLabel: saveLabel,
            onSave: _save,
            busy: form.busy,
            busyLabel: l.recSaving,
            note: l.recConfirmNote,
          ),
        ],
      );
    }

    return Container(
      key: _keys.form,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: lume.card,
        borderRadius: LumeRadius.brMd,
        border: Border.all(color: lume.border, width: LumeSpace.border),
        boxShadow: context.lumeShadows.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final Widget n in notices) ...<Widget>[
            n,
            const SizedBox(height: 18),
          ],
          Text(
            LumeFamilyText.sentence(l.recInformation(noun)),
            style: LumeType.fit(
              context,
              context.lumeType.section,
            ).copyWith(color: lume.text),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) {
              final double half = (box.maxWidth - 20) / 2;
              return Wrap(
                spacing: 20,
                runSpacing: 16,
                children: <Widget>[
                  for (final (bool wide, Widget w) in fields)
                    SizedBox(width: wide ? box.maxWidth : half, child: w),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Container(
            key: _keys.submit,
            padding: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: lume.border, width: LumeSpace.border),
              ),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 180),
                  child: LumeButton.accent(
                    label: saveLabel,
                    onPressed: _save,
                    busy: form.busy,
                    busyLabel: l.recSaving,
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 180),
                  child: LumeButton(
                    label: l.actionCancel,
                    onPressed: form.busy ? null : _leaveForm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Documents — the second family on the record layer, and the one that
/// deletes for good.
///
/// `tools/personal/documents.tool.js` under `crud-engine.js`: the reader's
/// document records lead — search and the records, each with its standing —
/// and the vault follows: what is held and what is expiring, a note when
/// something needs renewing, the category filter, the sort, and the vault's
/// documents grouped by whether they need attention. A record's detail and
/// form take the whole screen, or sit beside the list at expanded width.
///
/// A document record is not recoverable (`recoverable: false`): its delete
/// says so before it asks and offers no Undo afterwards. Records are kept in
/// memory and declared not durable, under a source line that says
/// "Encrypted on device" (C75).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/navigation/lume_back_intercept.dart';
import '../../../core/platform/lume_export.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../records/application/record_form.dart';
import '../../records/data/record_seeds.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_schema.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/documents_fixtures.dart';
import 'documents_records.dart';
import 'documents_strings.dart';

class LumeDocumentsTool extends ConsumerStatefulWidget {
  const LumeDocumentsTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeDocumentsTool(request: request);

  static const String id = 'documents';

  static const Key addKey = ValueKey<String>('documents.add');
  static const Key searchKey = ValueKey<String>('documents.search');
  static const Key recordsKey = ValueKey<String>('documents.records');
  static const Key recordStateKey = ValueKey<String>('documents.recordState');
  static const Key summaryKey = ValueKey<String>('documents.summary');
  static const Key renewKey = ValueKey<String>('documents.renew');
  static const Key filterKey = ValueKey<String>('documents.filter');
  static const Key sortKey = ValueKey<String>('documents.sort');
  static const Key emptyKey = ValueKey<String>('documents.empty');
  static const Key attentionKey = ValueKey<String>('documents.attention');
  static const Key validKey = ValueKey<String>('documents.valid');
  static const Key actionsKey = ValueKey<String>('documents.actions');
  static const Key heroKey = ValueKey<String>('documents.hero');
  static const Key factsKey = ValueKey<String>('documents.facts');
  static const Key detailActionsKey = ValueKey<String>(
    'documents.detailActions',
  );
  static const Key recordIdKey = ValueKey<String>('documents.recordId');
  static const Key formKey = ValueKey<String>('documents.form');
  static const Key submitKey = ValueKey<String>('documents.submit');

  static Key fieldKey(String name) => ValueKey<String>('documents.field.$name');

  @override
  ConsumerState<LumeDocumentsTool> createState() => _LumeDocumentsToolState();
}

class _LumeDocumentsToolState extends ConsumerState<LumeDocumentsTool> {
  static const String _id = LumeDocumentsTool.id;
  static const String _coll = 'documents';

  static const double _sortOverhang =
      (LumeSpace.tap - LumeSortBar.optionHeight) / 2;

  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final LumeRecordRepository _repo = ref.read(recordRepositoryProvider);
  late final TextEditingController _query = TextEditingController(
    text: _session.read(_id, 'q') ?? '',
  );
  final FocusNode _searchFocus = FocusNode();

  LumeRecordForm? _form;
  final Map<String, TextEditingController> _text =
      <String, TextEditingController>{
        'name': TextEditingController(),
        'num': TextEditingController(),
        'holder': TextEditingController(),
        'notes': TextEditingController(),
      };
  final Map<String, FocusNode> _focus = <String, FocusNode>{
    'name': FocusNode(),
    'num': FocusNode(),
    'holder': FocusNode(),
    'notes': FocusNode(),
  };

  @override
  void initState() {
    super.initState();
    _repo.addListener(_changed);
    _repo.open(_coll);
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

  String? _read(String k) => _session.read(_id, k);
  void _write(String k, String v) => _session.write(_id, k, v);

  String get _view => _read('view') ?? '';
  String get _selected => _read('rec') ?? '';

  LumeToolScreenState? get _say => _host.currentState;

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
      e.value.text = '${form.value(e.key) ?? ''}';
    }
  }

  void _startCreate() {
    final DateTime now = LumeClockScope.of(context).now();
    _bindForm(
      LumeRecordForm.create(
        schema: kDocumentsSchema,
        repository: _repo,
        defaults: LumeDocumentRecords.defaults(now),
      ),
    );
    setState(() => _write('view', 'new'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus['name']!.requestFocus();
    });
  }

  void _startEdit(String id) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeRecord? r = _repo.get(_coll, id);
    if (r == null) {
      _say?.say(l.recGone, tone: LumeToastTone.error);
      return;
    }
    _bindForm(
      LumeRecordForm.edit(
        schema: kDocumentsSchema,
        repository: _repo,
        record: LumeDocumentRecords.resolved(l, r),
      ),
    );
    setState(() {
      _write('view', 'edit');
      _write('rec', id);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus['name']!.requestFocus();
    });
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
          LumeDocumentRecords.sentence(
            created ? l.recAdded(l.recDocumentsNoun) : l.recUpdated,
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

  /// A document is deleted for good: the sheet says so, and nothing is
  /// offered afterwards that could not be done.
  Future<void> _askDelete(LumeRecord r) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final String noun = l.recDocumentsNoun;
    final bool go = await _confirm(
      title: LumeDocumentRecords.sentence(l.recDeleteAsk(noun)),
      text: l.recDeleteTextFinal(LumeDocumentRecords.text(l, r, 'name')),
      confirm: LumeDocumentRecords.sentence(l.recDelete(noun)),
      cancel: l.actionCancel,
    );
    if (!go || !mounted) return;
    final LumeWriteResult result = _repo.remove(_coll, r.id);
    if (!result.ok) {
      _say?.say(l.recDeleteFailed, tone: LumeToastTone.error);
      return;
    }
    _repo.forgetUndo();
    setState(() {
      _write('rec', '');
      _write('view', '');
    });
    _say?.say(LumeDocumentRecords.sentence(l.recDeletedFinal(noun)));
  }

  Future<bool> _confirm({
    required String title,
    required String text,
    required String confirm,
    required String cancel,
    bool warn = false,
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
            kind: warn
                ? LumeDeleteKind.recoverable
                : LumeDeleteKind.irreversible,
            onConfirm: () => Navigator.of(sheet).pop(true),
            onCancel: () => Navigator.of(sheet).pop(false),
          ),
        ),
      ),
    );
    return answer ?? false;
  }

  Future<void> _chooseCategory(String label) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final Object? current = _form?.value('cat');
    final String? chosen = await showLumeSheet<String>(
      context: context,
      barrierLabel: label,
      child: Builder(
        builder: (BuildContext sheet) => LumeSheet(
          title: label,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final LumeDocumentCategory c in LumeDocumentCategory.values)
                LumeRadioRow(
                  label: LumeDocumentsStrings.category(l, c),
                  selected: c.name == current,
                  onTap: () => Navigator.of(sheet).pop(c.name),
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) {
      _form?.setValue('cat', chosen);
      _form?.touch('cat');
    }
  }

  Future<void> _chooseExpiry() async {
    final DateTime now = LumeClockScope.of(context).now();
    final DateTime initial =
        LumeDocumentRecords.day(_form?.value('expires')) ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 50),
      lastDate: DateTime(now.year + 50),
    );
    if (picked != null) {
      _form?.setValue('expires', lumeIsoDay(picked, 0));
      _form?.touch('expires');
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final DateTime now = LumeClockScope.of(context).now();

    final Widget screen = switch (_view) {
      'new' || 'edit' when _form != null => _formScreen(l, f),
      'detail' => _detailScreen(l, f, now),
      _ => _listScreen(l, f, now),
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

  Widget _listScreen(AppLocalizations l, LumeFormatting f, DateTime now) {
    final LumeToolRequest r = widget.request;
    final LumeCollectionView v = _repo.view(_coll);

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      subtitle: _headerSub(l, v),
      leadingAction: LumeTextButton(
        key: LumeDocumentsTool.addKey,
        label: l.actionAdd,
        icon: LumeIcons.plus,
        semanticLabel: LumeDocumentRecords.sentence(
          l.recAdd(l.recDocumentsNoun),
        ),
        onPressed: _startCreate,
      ),
      actions: LumeToolActions(onSearch: _searchFocus.requestFocus),
      exportFile: () => _exportFile(l, f, now),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(tight: true, child: _records(l, f, now, v)),
          ..._vault(l, f, now),
        ],
      ),
    );
  }

  /// `export:documents` — the vault as it is listed: no numbers beyond the
  /// masked ones the screen already shows.
  LumeExportFile _exportFile(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
  ) => LumeExportFile.csv(
    tool: _id,
    day: now,
    rows: <List<Object?>>[
      <Object?>[
        l.commonName,
        l.docsCategory,
        l.recFieldReference,
        l.docsExpiry,
        l.recFieldHolder,
        l.docsFiles,
      ],
      for (final LumeVaultDocument d in LumeDocumentVault.documents)
        <Object?>[
          LumeDocumentsStrings.title(l, d.title),
          LumeDocumentsStrings.category(l, d.category),
          d.reference ?? '',
          d.days == null ? l.docsNoExpiry : lumeIsoDay(now, d.days!),
          LumeDocumentsStrings.holder(l, d.holder),
          d.files,
        ],
    ],
  );

  Widget _records(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    LumeCollectionView v,
  ) {
    final String noun = l.recDocumentsNoun;
    final String plural = l.recDocumentsNounPlural;

    switch (v.status) {
      case LumeCollectionStatus.loading:
        return const LumeSkeleton(kind: LumeSkeletonKind.record, count: 4);
      case LumeCollectionStatus.error:
        return LumeCollectionState(
          key: LumeDocumentsTool.recordStateKey,
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

    final List<LumeRecord> all = v.items;
    if (all.isEmpty) {
      return LumeCollectionState(
        key: LumeDocumentsTool.recordStateKey,
        kind: LumeCollectionStateKind.empty,
        icon: LumeIcons.folder,
        title: l.recDocumentsEmptyTitle,
        text: l.recDocumentsEmptyText,
        primaryAction: LumeButton.accent(
          label: LumeDocumentRecords.sentence(l.recAddFirst(noun)),
          onPressed: _startCreate,
        ),
        footnote: l.recImportLater,
      );
    }

    final List<LumeRecord> rows = <LumeRecord>[
      for (final LumeRecord x in all)
        if (LumeDocumentRecords.matches(l, f, x, _query.text)) x,
    ];
    final bool pane = context.hasDetailPane;
    final double gutter = LumeLayout.pageGutter(context.measureClass);

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
            key: LumeDocumentsTool.searchKey,
            controller: _query,
            focusNode: _searchFocus,
            placeholder: l.recSearch(plural),
            onChanged: (String q) => setState(() => _write('q', q)),
          ),
        ),
        // No chips: the family declares no filters, so the rows follow the
        // search directly.
        const SizedBox(height: 0),
        if (rows.isEmpty)
          LumeCollectionState(
            key: LumeDocumentsTool.recordStateKey,
            kind: LumeCollectionStateKind.noResults,
            title: l.recNoMatch,
            text: l.recNoMatchText,
            primaryAction: LumeButton(
              label: l.actionClear,
              onPressed: () => setState(() {
                _query.clear();
                _write('q', '');
              }),
            ),
          )
        else
          LumeRecordList(
            key: LumeDocumentsTool.recordsKey,
            children: <Widget>[
              for (final LumeRecord x in rows)
                LumeRecordRow(
                  initial: LumeDocumentRecords.initial(
                    LumeDocumentRecords.text(l, x, 'name'),
                  ),
                  title: LumeDocumentRecords.text(l, x, 'name'),
                  subtitle: LumeDocumentRecords.rowSub(l, f, x),
                  badge: LumeDocumentRecords.badge(l, x, now),
                  queuedLabel: x.queued ? l.recQueued : null,
                  selected: pane && x.id == _selected,
                  onTap: () => _open(x.id),
                ),
            ],
          ),
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
              icon: LumeIcons.folder,
              title: l.recSelectTitle,
              text: l.recSelectText,
            )
          : _detailBody(l, f, selected),
    );
  }

  // ------------------------------------------------------------------ vault

  List<Widget> _vault(AppLocalizations l, LumeFormatting f, DateTime now) {
    final LumeColors lume = context.lume;
    final String cat = _read('cat') ?? 'all';
    final String sortBy = _read('sortBy') ?? 'expiry';
    final LumeSortDirection sortDir = _read('sortDir') == 'desc'
        ? LumeSortDirection.descending
        : LumeSortDirection.ascending;
    final String q = _query.text.trim().toLowerCase();

    bool keep(LumeVaultDocument d) {
      if (cat != 'all' && d.category.name != cat) return false;
      if (q.isEmpty) return true;
      return <String>[
        LumeDocumentsStrings.title(l, d.title),
        LumeDocumentsStrings.category(l, d.category),
        LumeDocumentsStrings.holder(l, d.holder),
      ].join(' ').toLowerCase().contains(q);
    }

    // `c.sortBy(items, { expiry: days ?? 1e9, cat, updated: files })`.
    int compare(LumeVaultDocument a, LumeVaultDocument b) => switch (sortBy) {
      'cat' => a.category.index.compareTo(b.category.index),
      'updated' => a.files.compareTo(b.files),
      _ => (a.days ?? 1000000000).compareTo(b.days ?? 1000000000),
    };
    List<LumeVaultDocument> sorted(Iterable<LumeVaultDocument> items) =>
        items.where(keep).toList()..sort(
          (LumeVaultDocument a, LumeVaultDocument b) =>
              sortDir == LumeSortDirection.ascending
              ? compare(a, b)
              : compare(b, a),
        );

    final List<(String, Key, List<LumeVaultDocument>)> groups =
        <(String, Key, List<LumeVaultDocument>)>[
          (
            l.docsNeedsAttention,
            LumeDocumentsTool.attentionKey,
            sorted(
              LumeDocumentVault.documents.where(
                (LumeVaultDocument d) => d.needsAttention,
              ),
            ),
          ),
          (
            l.docsValid,
            LumeDocumentsTool.validKey,
            sorted(
              LumeDocumentVault.documents.where(
                (LumeVaultDocument d) => !d.needsAttention,
              ),
            ),
          ),
        ].where((g) => g.$3.isNotEmpty).toList();

    final int expiring = LumeDocumentVault.expiring;

    LumeBadge badgeFor(LumeVaultDocument d) => LumeBadge(
      label: LumeDocumentsStrings.standing(l, d.standing),
      tone: switch (d.standing) {
        LumeDocumentStanding.expired => LumeBadgeTone.late_,
        LumeDocumentStanding.expiring => LumeBadgeTone.warn,
        LumeDocumentStanding.valid => LumeBadgeTone.ok,
        LumeDocumentStanding.permanent => LumeBadgeTone.neutral,
      },
    );

    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeDocumentsTool.summaryKey,
          gradient: context.lumeGradients.lock,
          kicker: l.docsVault,
          value: f.integer(LumeDocumentVault.documents.length),
          caption: expiring > 0 ? l.docsExpiringSoon(expiring) : l.docsAllValid,
          // `.lockmark svg { width: 30px; opacity: .7 }`.
          aside: ExcludeSemantics(
            child: Opacity(
              opacity: 0.7,
              child: LumeIcon(
                LumeIcons.lock,
                size: 30,
                color: context.lumeGradients.lock.on,
              ),
            ),
          ),
          stats: <LumeStat>[
            LumeStat(
              value: f.integer(LumeDocumentVault.expired),
              label: l.docsExpired,
            ),
            LumeStat(value: f.integer(expiring), label: l.docsExpiring),
            LumeStat(
              value: f.integer(LumeDocumentVault.files),
              label: l.docsFiles,
            ),
          ],
        ),
      ),
      if (expiring > 0)
        LumeToolSection(
          child: LumeNoteCard(
            key: LumeDocumentsTool.renewKey,
            tone: LumeNoteTone.warn,
            icon: LumeIcons.alert,
            title: l.docsRenewTitle(expiring),
            text: l.docsRenewText,
          ),
        ),
      LumeToolSection(
        spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
        child: LumeFilterBar(
          key: LumeDocumentsTool.filterKey,
          gutters: false,
          children: <Widget>[
            LumeFilterChip(
              label: l.commonAll,
              count: LumeDocumentVault.documents.length,
              selected: cat == 'all',
              onTap: () => setState(() => _write('cat', 'all')),
            ),
            for (final (LumeDocumentCategory c, int n)
                in LumeDocumentVault.categories)
              LumeFilterChip(
                label: LumeDocumentsStrings.category(l, c),
                count: n,
                selected: cat == c.name,
                onTap: () => setState(() => _write('cat', c.name)),
              ),
          ],
        ),
      ),
      LumeToolSection(
        spaceAbove:
            LumeToolSection.gap - LumeFilterBar.overhang - _sortOverhang,
        child: LumeSortBar(
          key: LumeDocumentsTool.sortKey,
          label: l.commonSort,
          value: sortBy,
          direction: sortDir,
          items: <LumeChoice>[
            LumeChoice(value: 'expiry', label: l.docsExpiry),
            LumeChoice(value: 'cat', label: l.docsCategory),
            LumeChoice(value: 'updated', label: l.docsUpdated),
          ],
          onChanged: (String v, LumeSortDirection d) => setState(() {
            _write('sortBy', v);
            _write(
              'sortDir',
              d == LumeSortDirection.ascending ? 'asc' : 'desc',
            );
          }),
        ),
      ),
      if (groups.isEmpty)
        LumeToolSection(
          spaceAbove: LumeToolSection.gap - _sortOverhang,
          child: LumeToolState(
            key: LumeDocumentsTool.emptyKey,
            icon: LumeIcons.folder,
            title: l.docsNoMatch,
            text: l.docsNoMatchText,
            action: LumeButton(
              label: l.commonAll,
              icon: LumeIcons.refresh,
              onPressed: () => setState(() => _write('cat', 'all')),
            ),
          ),
        ),
      for (final (int i, (String title, Key key, List<LumeVaultDocument> items))
          in groups.indexed)
        LumeToolSection(
          spaceAbove: i == 0 ? LumeToolSection.gap - _sortOverhang : null,
          title: title,
          child: LumeRows(
            key: key,
            children: <Widget>[
              for (final LumeVaultDocument d in items)
                LumeRichRow(
                  icon: d.category.icon,
                  // `iconTone: x.tone` — warn for the expired and the
                  // expiring alike.
                  iconTone: d.needsAttention
                      ? lume.amber.withValues(alpha: 0.18)
                      : null,
                  iconInk: d.needsAttention ? lume.amber : null,
                  title: LumeDocumentsStrings.title(l, d.title),
                  subtitle: d.reference ?? '—',
                  meta: <String>[
                    LumeDocumentsStrings.holder(l, d.holder),
                    l.docsFilesN(d.files),
                  ],
                  badge: badgeFor(d),
                  value: d.days == null
                      ? l.docsNoExpiry
                      : f.dateMedium(d.expiresOn(now)!),
                  valueSub: d.days == null ? null : l.commonInDays(d.days!),
                  chevron: true,
                  // The reference asks for an unlock it never offers (C75).
                  onTap: () =>
                      _say?.say(l.docsUnlockToView, tone: LumeToastTone.info),
                ),
            ],
          ),
        ),
      LumeToolSection(
        child: LumeButtonRow(
          key: LumeDocumentsTool.actionsKey,
          children: <Widget>[
            LumeButton.accent(
              label: l.docsAdd,
              icon: LumeIcons.plus,
              onPressed: () => widget.request.onOpenRelated?.call('docscan'),
            ),
            LumeButton(
              label: l.commonExport,
              icon: LumeIcons.download,
              onPressed: () => _host.currentState?.export(),
            ),
          ],
        ),
      ),
    ];
  }

  // ----------------------------------------------------------------- detail

  Widget _detailScreen(AppLocalizations l, LumeFormatting f, DateTime now) {
    final LumeToolRequest r = widget.request;
    final LumeRecord? rec = _repo.get(_coll, _selected);
    final String noun = l.recDocumentsNoun;
    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      bare: true,
      onBack: _backToList,
      title: LumeDocumentRecords.sentence(l.recDetailTitle(noun)),
      subtitle: rec == null ? '' : _created(l, f, now, rec),
      headerActions: <Widget>[
        if (rec != null)
          LumeIconButton(
            icon: LumeIcons.note,
            label: LumeDocumentRecords.sentence(l.recEdit(noun)),
            onPressed: () => _startEdit(rec.id),
          ),
      ],
      body: LumeToolSection(
        child: rec == null
            ? LumeCollectionState(
                key: LumeDocumentsTool.recordStateKey,
                kind: LumeCollectionStateKind.noResults,
                title: l.recGone,
                text: l.recGoneText,
                primaryAction: LumeButton(
                  label: LumeDocumentRecords.sentence(
                    l.recBackToList(l.recDocumentsNounPlural),
                  ),
                  onPressed: _backToList,
                ),
              )
            : _detailBody(l, f, rec),
      ),
    );
  }

  String _created(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    LumeRecord r,
  ) {
    final int days = DateTime.utc(
      r.createdAt.year,
      r.createdAt.month,
      r.createdAt.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    if (days == 0) return l.recCreatedToday;
    if (days == -1) return l.recCreatedYesterday;
    return l.recCreated(f.dateShort(r.createdAt));
  }

  Widget _detailBody(AppLocalizations l, LumeFormatting f, LumeRecord rec) {
    final LumeColors lume = context.lume;
    final String noun = l.recDocumentsNoun;
    final String category = LumeDocumentsStrings.category(
      l,
      LumeDocumentRecords.category(rec),
    );
    String orDash(String v) => v.isEmpty ? '—' : v;
    final String notes = LumeDocumentRecords.text(l, rec, 'notes');
    final Object? expires = rec['expires'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LumeRecordHero(
          key: LumeDocumentsTool.heroKey,
          gradient: context.lumeGradients.lock,
          kicker: category,
          value: LumeDocumentRecords.text(l, rec, 'name'),
          caption: LumeDocumentRecords.heroCaption(l, f, rec),
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
          key: LumeDocumentsTool.factsKey,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          decoration: BoxDecoration(
            color: lume.card,
            borderRadius: LumeRadius.brMd,
            border: Border.all(color: lume.border, width: LumeSpace.border),
            boxShadow: context.lumeShadows.xs,
          ),
          child: LumeFactCard(
            facts: <LumeFact>[
              LumeFact(label: l.docsCategory, value: category),
              LumeFact(
                label: l.recFieldReference,
                value: orDash(LumeDocumentRecords.text(l, rec, 'num')),
              ),
              LumeFact(
                label: l.docsExpiry,
                value: expires == null || expires == ''
                    ? l.docsNoExpiry
                    : LumeDocumentRecords.showDate(f, expires),
              ),
              LumeFact(
                label: l.recFieldHolder,
                value: orDash(LumeDocumentRecords.text(l, rec, 'holder')),
              ),
              LumeFact(
                label: l.recFieldNotes,
                value: notes.isEmpty ? l.recNone : notes,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LumeDetailActions(
          key: LumeDocumentsTool.detailActionsKey,
          editLabel: LumeDocumentRecords.sentence(l.recEdit(noun)),
          onEdit: () => _startEdit(rec.id),
          deleteLabel: LumeDocumentRecords.sentence(l.recDelete(noun)),
          onDelete: () => _askDelete(rec),
        ),
        const SizedBox(height: 18),
        LumeRecordId(
          key: LumeDocumentsTool.recordIdKey,
          label: l.recRecordId(rec.id.toUpperCase()),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------- form

  Widget _formScreen(AppLocalizations l, LumeFormatting f) {
    final LumeToolRequest r = widget.request;
    final LumeRecordForm form = _form!;
    final bool creating = form.mode == LumeFormMode.create;
    final String noun = l.recDocumentsNoun;
    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      bare: true,
      onBack: _leaveForm,
      title: LumeDocumentRecords.sentence(
        creating ? l.recAdd(noun) : l.recEdit(noun),
      ),
      subtitle: creating ? l.recNewRecord : l.recEditing,
      headerActions: <Widget>[
        LumeTextButton(label: l.actionSave, onPressed: _save),
      ],
      body: LumeToolSection(child: _formBody(l, f, form)),
    );
  }

  Widget _formBody(AppLocalizations l, LumeFormatting f, LumeRecordForm form) {
    final LumeColors lume = context.lume;
    final bool creating = form.mode == LumeFormMode.create;
    final String noun = l.recDocumentsNoun;
    final bool pair = context.hasDetailPane;

    Widget text(
      String name,
      String label, {
      String? placeholder,
      bool required = false,
      bool multiline = false,
    }) => LumeFormField(
      key: LumeDocumentsTool.fieldKey(name),
      label: label,
      optionalLabel: required ? null : l.recOptional,
      controller: _text[name],
      focusNode: _focus[name],
      placeholder: placeholder,
      required: required,
      kind: multiline ? LumeFieldKind.multiline : LumeFieldKind.text,
      error: switch (form.shownError(name)) {
        LumeFieldError.required => l.recErrRequired(label),
        LumeFieldError.positive => l.recErrPositive,
        null => null,
      },
      onChanged: (String v) => form.setValue(name, v),
      onEditingComplete: () => form.touch(name),
    );

    final Object? expires = form.value('expires');
    final List<(bool, Widget)> fields = <(bool, Widget)>[
      (
        false,
        text(
          'name',
          l.commonName,
          placeholder: l.recDocumentsPh,
          required: true,
        ),
      ),
      (
        false,
        LumeFormPicker(
          key: LumeDocumentsTool.fieldKey('cat'),
          label: l.recFieldCategory,
          value: LumeDocumentsStrings.category(
            l,
            LumeDocumentCategory.byId(form.value('cat') as String?) ??
                LumeDocumentCategory.other,
          ),
          onTap: () => _chooseCategory(l.recFieldCategory),
        ),
      ),
      (false, text('num', l.recFieldReference)),
      (
        false,
        LumeFormPicker(
          key: LumeDocumentsTool.fieldKey('expires'),
          label: l.recFieldExpiry,
          optionalLabel: l.recOptional,
          value: expires == null || expires == ''
              ? '—'
              : LumeDocumentRecords.showDate(f, expires),
          icon: LumeIcons.calendar,
          onTap: _chooseExpiry,
        ),
      ),
      (false, text('holder', l.recFieldHolder)),
      (true, text('notes', l.recFieldNotes, multiline: true)),
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

    final String saveLabel = LumeDocumentRecords.sentence(
      creating ? l.recSave(noun) : l.recUpdate,
    );

    if (!pair) {
      return Column(
        key: LumeDocumentsTool.formKey,
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
            key: LumeDocumentsTool.submitKey,
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
      key: LumeDocumentsTool.formKey,
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
            LumeDocumentRecords.sentence(l.recInformation(noun)),
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
            key: LumeDocumentsTool.submitKey,
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

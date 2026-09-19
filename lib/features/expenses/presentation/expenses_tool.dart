/// Expenses — the reference tool for the finance dashboard, and the first on
/// the record layer.
///
/// `tools/personal/expenses.tool.js` under `crud-engine.js`: the reader's
/// expenses lead — search, filter chips, the records — and the dashboard
/// follows: the range, what was spent against the budget, the week, the
/// categories, the transactions with their filter and sort, the budgets, the
/// recurring payments and the insights. Opening a record, adding one or
/// editing one takes the whole screen, as the record engine does; at expanded
/// width a record opens beside the list instead.
///
/// Records live in [recordRepositoryProvider] — in memory in this build, and
/// declared not durable (C74). Kept as the reference has it: the dashboard is
/// fixture figures, the transactions are not the records, a record's amount is
/// shown as stored while the dashboard converts dollars. Corrected: the body's
/// "Add expense" opens the form rather than only saying "New expense"; a
/// tablet form's two actions sit side by side.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/records_provider.dart';
import '../../../app/providers/shell_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
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
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chart.dart';
import '../../../core/widgets/lume/lume_chip.dart';
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
import '../../records/application/record_form.dart';
import '../../records/data/record_seeds.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_schema.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/expenses_fixtures.dart';
import 'expenses_records.dart';
import 'expenses_strings.dart';

class LumeExpensesTool extends ConsumerStatefulWidget {
  const LumeExpensesTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeExpensesTool(request: request);

  static const String id = 'expenses';

  static const Key addKey = ValueKey<String>('expenses.add');
  static const Key searchKey = ValueKey<String>('expenses.search');
  static const Key chipsKey = ValueKey<String>('expenses.chips');
  static const Key recordsKey = ValueKey<String>('expenses.records');
  static const Key recordStateKey = ValueKey<String>('expenses.recordState');
  static const Key rangeKey = ValueKey<String>('expenses.range');
  static const Key summaryKey = ValueKey<String>('expenses.summary');
  static const Key weekKey = ValueKey<String>('expenses.week');
  static const Key categoriesKey = ValueKey<String>('expenses.categories');
  static const Key filterKey = ValueKey<String>('expenses.filter');
  static const Key sortKey = ValueKey<String>('expenses.sort');
  static const Key transactionsKey = ValueKey<String>('expenses.transactions');
  static const Key budgetsKey = ValueKey<String>('expenses.budgets');
  static const Key recurringKey = ValueKey<String>('expenses.recurring');
  static const Key insightsKey = ValueKey<String>('expenses.insights');
  static const Key actionsKey = ValueKey<String>('expenses.actions');
  static const Key heroKey = ValueKey<String>('expenses.hero');
  static const Key factsKey = ValueKey<String>('expenses.facts');
  static const Key detailActionsKey = ValueKey<String>(
    'expenses.detailActions',
  );
  static const Key recordIdKey = ValueKey<String>('expenses.recordId');
  static const Key formKey = ValueKey<String>('expenses.form');
  static const Key submitKey = ValueKey<String>('expenses.submit');

  static Key fieldKey(String name) => ValueKey<String>('expenses.field.$name');

  @override
  ConsumerState<LumeExpensesTool> createState() => _LumeExpensesToolState();
}

class _LumeExpensesToolState extends ConsumerState<LumeExpensesTool> {
  static const String _id = LumeExpensesTool.id;
  static const String _coll = 'expenses';

  static const double _chipOverhang =
      (LumeSpace.tap - LumeRecordChip.height) / 2;
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
  final TextEditingController _title = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final Map<String, FocusNode> _focus = <String, FocusNode>{
    'title': FocusNode(),
    'amount': FocusNode(),
    'notes': FocusNode(),
  };

  @override
  void initState() {
    super.initState();
    _repo.addListener(_changed);
    _repo.open(_coll);
    // A form is this screen's own; one left open when the tool was left is not
    // there to return to.
    if (_view == 'new' || _view == 'edit') _write('view', '');
  }

  @override
  void dispose() {
    _repo.removeListener(_changed);
    _form?.dispose();
    _query.dispose();
    _searchFocus.dispose();
    _title.dispose();
    _amount.dispose();
    _notes.dispose();
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
    // The width decides what opening means: beside the list at expanded,
    // the next screen below it.
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
    _title.text = '${form.value('title') ?? ''}';
    final Object? amount = form.value('amount');
    _amount.text = amount == null ? '' : '$amount';
    _notes.text = '${form.value('notes') ?? ''}';
  }

  void _startCreate() {
    final DateTime now = LumeClockScope.of(context).now();
    _bindForm(
      LumeRecordForm.create(
        schema: kExpensesSchema,
        repository: _repo,
        defaults: LumeExpenseRecords.defaults(now),
      ),
    );
    setState(() => _write('view', 'new'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus['title']!.requestFocus();
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
        schema: kExpensesSchema,
        repository: _repo,
        record: LumeExpenseRecords.resolved(l, r),
      ),
    );
    setState(() {
      _write('view', 'edit');
      _write('rec', id);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus['title']!.requestFocus();
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

  /// `leaveForm` — a changed form asks first.
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
        final String noun = l.recExpensesNoun;
        _say?.say(
          LumeExpenseRecords.sentence(
            created ? l.recAdded(noun) : l.recUpdated,
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

  Future<void> _askDelete(LumeRecord r) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final String noun = l.recExpensesNoun;
    final bool go = await _confirm(
      title: LumeExpenseRecords.sentence(l.recDeleteAsk(noun)),
      text: l.recDeleteTextUndo(LumeExpenseRecords.text(l, r, 'title')),
      confirm: LumeExpenseRecords.sentence(l.recDelete(noun)),
      cancel: l.actionCancel,
    );
    if (!go || !mounted) return;
    final LumeWriteResult result = _repo.remove(_coll, r.id);
    if (!result.ok) {
      _say?.say(l.recDeleteFailed, tone: LumeToastTone.error);
      return;
    }
    setState(() {
      _write('rec', '');
      _write('view', '');
    });
    _say?.say(
      LumeExpenseRecords.sentence(l.recDeleted(noun)),
      actionLabel: l.recUndo,
      onAction: _undo,
    );
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
            onConfirm: () => Navigator.of(sheet).pop(true),
            onCancel: () => Navigator.of(sheet).pop(false),
          ),
        ),
      ),
    );
    return answer ?? false;
  }

  Future<void> _choose(
    String field,
    String label,
    List<(String, String)> options,
  ) async {
    final Object? current = _form?.value(field);
    final String? chosen = await showLumeSheet<String>(
      context: context,
      barrierLabel: label,
      child: Builder(
        builder: (BuildContext sheet) => LumeSheet(
          title: label,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final (String value, String text) in options)
                LumeRadioRow(
                  label: text,
                  selected: value == current,
                  onTap: () => Navigator.of(sheet).pop(value),
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) {
      _form?.setValue(field, chosen);
      _form?.touch(field);
    }
  }

  Future<void> _chooseDate() async {
    final DateTime now = LumeClockScope.of(context).now();
    final DateTime initial =
        LumeExpenseRecords.day(_form?.value('date')) ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 20),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      _form?.setValue('date', lumeIsoDay(picked, 0));
      _form?.touch('date');
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
    final String ccy =
        ref
            .watch(startupControllerProvider)
            .state
            .countries
            ?.currencyOf(r.user.country) ??
        f.currency;

    final Widget screen = switch (_view) {
      'new' || 'edit' when _form != null => _formScreen(l, f, now),
      'detail' => _detailScreen(l, f, now, ccy),
      _ => _listScreen(l, f, now, ccy),
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

  Widget _listScreen(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    String ccy,
  ) {
    final LumeToolRequest r = widget.request;
    final LumeCollectionView v = _repo.view(_coll);
    final String noun = l.recExpensesNoun;
    final LumeExpensesBoard board = LumeExpensesBoard.forMarket(
      country: r.user.country,
      currency: ccy,
      now: now,
    );

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      subtitle: _headerSub(l, v),
      leadingAction: LumeTextButton(
        key: LumeExpensesTool.addKey,
        label: l.actionAdd,
        icon: LumeIcons.plus,
        semanticLabel: LumeExpenseRecords.sentence(l.recAdd(noun)),
        onPressed: _startCreate,
      ),
      actions: LumeToolActions(onSearch: _searchFocus.requestFocus),
      exportFile: () => _exportFile(l, f, now, board),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(tight: true, child: _records(l, f, now, ccy, v)),
          ..._dashboard(l, f, now, ccy, board),
        ],
      ),
    );
  }

  LumeExportFile _exportFile(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    LumeExpensesBoard board,
  ) => LumeExportFile.csv(
    tool: _id,
    day: now,
    rows: <List<Object?>>[
      <Object?>[
        l.commonDate,
        l.recFieldTitle,
        l.expensesCategory,
        l.commonAmount,
        board.currency,
      ],
      for (final LumeTransaction t in LumeExpensesBoard.transactions)
        <Object?>[
          _txWhen(l, f, now, t),
          LumeExpensesStrings.transaction(l, t.title),
          LumeExpensesStrings.category(l, t.category),
          (t.amountUsd < 0 ? -1 : 1) * board.fromUsd(t.amountUsd.abs()),
          board.currency,
        ],
    ],
  );

  Widget _records(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    String ccy,
    LumeCollectionView v,
  ) {
    final String noun = l.recExpensesNoun;
    final String plural = l.recExpensesNounPlural;

    switch (v.status) {
      case LumeCollectionStatus.loading:
        return const LumeSkeleton(kind: LumeSkeletonKind.record, count: 4);
      case LumeCollectionStatus.error:
        return LumeCollectionState(
          key: LumeExpensesTool.recordStateKey,
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
        key: LumeExpensesTool.recordStateKey,
        kind: LumeCollectionStateKind.empty,
        icon: LumeIcons.wallet,
        title: l.recExpensesEmptyTitle,
        text: l.recExpensesEmptyText,
        primaryAction: LumeButton.accent(
          label: LumeExpenseRecords.sentence(l.recAddFirst(noun)),
          onPressed: _startCreate,
        ),
        footnote: l.recImportLater,
      );
    }

    final List<LumeRecordFilter> filters = LumeExpenseRecords.filters(l, now);
    final String chosen = _read('cfil') ?? 'all';
    final LumeRecordFilter? active = filters
        .where((LumeRecordFilter x) => x.value == chosen)
        .firstOrNull;
    final List<LumeRecord> rows = <LumeRecord>[
      for (final LumeRecord x in all)
        if ((active == null || active.test(x)) &&
            LumeExpenseRecords.matches(l, f, now, ccy, x, _query.text))
          x,
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
        // The same second gutter as every tool's own search field (C69).
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: LumeSearchField(
            key: LumeExpensesTool.searchKey,
            controller: _query,
            focusNode: _searchFocus,
            placeholder: l.recSearch(plural),
            onChanged: (String q) => setState(() => _write('q', q)),
          ),
        ),
        // Each chip's target reaches 3 past its 38-point drawing, above and
        // below; those points come out of the 12 either side.
        const SizedBox(height: 12 - _chipOverhang),
        SingleChildScrollView(
          key: LumeExpensesTool.chipsKey,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: <Widget>[
              for (final (int i, (String value, String label, int count))
                  in <(String, String, int)>[
                    ('all', l.commonAll, all.length),
                    for (final LumeRecordFilter x in filters)
                      (x.value, x.label, all.where(x.test).length),
                  ].indexed) ...<Widget>[
                if (i > 0) const SizedBox(width: 8),
                LumeRecordChip(
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
        if (rows.isEmpty)
          LumeCollectionState(
            key: LumeExpensesTool.recordStateKey,
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
            key: LumeExpensesTool.recordsKey,
            children: <Widget>[
              for (final LumeRecord x in rows)
                LumeRecordRow(
                  initial: LumeExpenseRecords.initial(
                    LumeExpenseRecords.text(l, x, 'title'),
                  ),
                  title: LumeExpenseRecords.text(l, x, 'title'),
                  subtitle: LumeExpenseRecords.rowSub(l, f, now, x),
                  value: LumeExpenseRecords.amount(f, ccy, x),
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
              icon: LumeIcons.wallet,
              title: l.recSelectTitle,
              text: l.recSelectText,
            )
          : _detailBody(l, f, now, ccy, selected),
    );
  }

  // -------------------------------------------------------------- dashboard

  String _txWhen(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    LumeTransaction t,
  ) => switch (t.daysAgo) {
    0 when t.time != null => l.expensesWhenTime(l.commonToday, t.time!),
    0 => l.commonToday,
    1 => l.commonYesterday,
    _ => f.dateMedium(DateTime(now.year, now.month, now.day - t.daysAgo)),
  };

  List<Widget> _dashboard(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    String ccy,
    LumeExpensesBoard board,
  ) {
    final LumeColors lume = context.lume;
    String money(double local) =>
        f.money(LumeExpensesBoard.tidy(local), code: ccy);
    String usd(double dollars) => f.money(board.fromUsd(dollars), code: ccy);
    final String percent =
        '${f.integer((LumeExpensesBoard.ratio * 100).round())}%';

    final String cat = _read('cat') ?? 'all';
    final String sortBy = _read('sortBy') ?? 'date';
    final LumeSortDirection sortDir = _read('sortDir') == 'asc'
        ? LumeSortDirection.ascending
        : LumeSortDirection.descending;
    final String q = _query.text.trim().toLowerCase();
    final List<(int, LumeTransaction)> tx = <(int, LumeTransaction)>[
      for (final (int i, LumeTransaction t)
          in LumeExpensesBoard.transactions.indexed)
        if ((cat == 'all' || t.category.name == cat) &&
            (q.isEmpty ||
                <String>[
                  LumeExpensesStrings.transaction(l, t.title),
                  LumeExpensesStrings.category(l, t.category),
                  LumeExpensesStrings.method(l, t.method),
                ].join(' ').toLowerCase().contains(q)))
          (LumeExpensesBoard.transactions.length - i, t),
    ];
    // `c.sortBy(tx, { date: order, amount: |amount|, cat: label })`.
    int compare((int, LumeTransaction) a, (int, LumeTransaction) b) =>
        switch (sortBy) {
          'amount' => a.$2.amountUsd.abs().compareTo(b.$2.amountUsd.abs()),
          'cat' => LumeExpensesStrings.category(
            l,
            a.$2.category,
          ).compareTo(LumeExpensesStrings.category(l, b.$2.category)),
          _ => a.$1.compareTo(b.$1),
        };
    tx.sort(
      ((int, LumeTransaction) a, (int, LumeTransaction) b) =>
          sortDir == LumeSortDirection.ascending
          ? compare(a, b)
          : compare(b, a),
    );

    return <Widget>[
      LumeToolSection(
        child: LumeSegmented(
          key: LumeExpensesTool.rangeKey,
          semanticLabel: l.expensesRange,
          value: _read('range') ?? 'month',
          onChanged: (String v) => setState(() => _write('range', v)),
          items: <LumeChoice>[
            LumeChoice(value: 'week', label: l.commonWeek),
            LumeChoice(value: 'month', label: l.commonMonth),
            LumeChoice(value: 'year', label: l.commonYear),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeExpensesTool.summaryKey,
          kicker: l.expensesSpent,
          value: money(board.spent),
          caption: l.expensesOfBudget(percent, money(board.budget)),
          aside: LumeProgressRing(
            value: LumeExpensesBoard.ratio,
            centreValue: percent,
            label: l.expensesBudgetUse,
          ),
          stats: <LumeStat>[
            LumeStat(value: money(board.income), label: l.expensesIncome),
            LumeStat(value: money(board.balance), label: l.expensesBalance),
            LumeStat(
              value: money(board.dailyAverage),
              label: l.expensesDailyAvg,
            ),
          ],
          footer: LumeProgressBar(
            value: LumeExpensesBoard.ratio,
            label: l.expensesBudgetUse,
            tone: LumeExpensesBoard.ratio > 0.9 ? lume.amber : null,
          ),
        ),
      ),
      LumeToolSection(
        title: l.expensesTrend,
        child: LumeCard(
          child: LumeBarChart(
            key: LumeExpensesTool.weekKey,
            label: l.expensesTrend,
            values: LumeExpensesBoard.week,
            labels: f.weekdayNarrowFromMonday(),
            highlight: LumeExpensesBoard.week.length - 1,
            caption: Text(
              l.expensesTrendCap(money(board.dailyAverage)),
              style: LumeType.natural(
                context,
                context.lumeType.metaSmall,
              ).copyWith(color: lume.text3),
            ),
          ),
        ),
      ),
      LumeToolSection(
        title: l.expensesCategories,
        child: LumeCard(
          child: LumeDonut(
            key: LumeExpensesTool.categoriesKey,
            label: l.expensesCategories,
            centre: money(board.spent),
            centreSub: l.commonTotal,
            slices: <LumeDonutSlice>[
              for (final LumeCategorySpend s in board.categories)
                LumeDonutSlice(
                  label: LumeExpensesStrings.category(l, s.category),
                  value: s.amount,
                  color: s.category.color,
                  display: money(s.amount),
                ),
            ],
          ),
        ),
      ),
      LumeToolSection(
        spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
        child: LumeFilterBar(
          key: LumeExpensesTool.filterKey,
          gutters: false,
          children: <Widget>[
            LumeFilterChip(
              label: l.commonAll,
              selected: cat == 'all',
              onTap: () => setState(() => _write('cat', 'all')),
            ),
            for (final LumeExpenseCategory c in LumeExpenseCategory.values)
              LumeFilterChip(
                label: LumeExpensesStrings.category(l, c),
                icon: c.icon,
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
          key: LumeExpensesTool.sortKey,
          label: l.commonSort,
          value: sortBy,
          direction: sortDir,
          items: <LumeChoice>[
            LumeChoice(value: 'date', label: l.commonDate),
            LumeChoice(value: 'amount', label: l.commonAmount),
            LumeChoice(value: 'cat', label: l.expensesCategory),
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
      LumeToolSection(
        spaceAbove: LumeToolSection.gap - _sortOverhang,
        title: l.expensesTransactions,
        child: tx.isEmpty
            ? LumeToolState(
                icon: LumeIcons.wallet,
                title: l.expensesNoMatch,
                text: l.expensesNoMatchText,
                action: LumeButton(
                  label: l.commonAll,
                  icon: LumeIcons.refresh,
                  onPressed: () => setState(() => _write('cat', 'all')),
                ),
              )
            : LumeRows(
                key: LumeExpensesTool.transactionsKey,
                children: <Widget>[
                  for (final (int _, LumeTransaction t) in tx)
                    LumeRichRow(
                      icon: t.category.icon,
                      iconTone: t.income ? lume.tintAccent : null,
                      iconInk: t.income ? lume.accent : null,
                      title: LumeExpensesStrings.transaction(l, t.title),
                      subtitle: LumeExpensesStrings.category(l, t.category),
                      meta: <String>[
                        _txWhen(l, f, now, t),
                        LumeExpensesStrings.method(l, t.method),
                      ],
                      value: '${t.income ? '+' : '−'}${usd(t.amountUsd.abs())}',
                      valueColor: t.income ? lume.up : null,
                    ),
                ],
              ),
      ),
      LumeToolSection(
        title: l.expensesBudgets,
        child: LumeCard(
          child: Column(
            key: LumeExpensesTool.budgetsKey,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final (int i, LumeBudgetLine b)
                  in board.budgetLines.indexed) ...<Widget>[
                if (i > 0) const SizedBox(height: 14),
                LumeMeterRow(
                  label: LumeExpensesStrings.category(l, b.category),
                  value: '${money(b.spent)} / ${money(b.limit)}',
                  progress: b.spent / b.limit,
                  tone: b.over ? lume.amber : null,
                ),
              ],
            ],
          ),
        ),
      ),
      LumeToolSection(
        title: l.expensesRecurring,
        child: LumeRows(
          key: LumeExpensesTool.recurringKey,
          children: <Widget>[
            for (final LumeRecurringPayment p in LumeExpensesBoard.recurring)
              LumeCompactRow(
                icon: LumeIcons.refresh,
                label: p.electricity ? l.expensesRec2 : l.expensesRec1,
                subtitle: l.expensesMonthlyOn(p.day),
                value: usd(p.amountUsd),
              ),
          ],
        ),
      ),
      LumeToolSection(
        title: l.expensesInsights,
        child: LumeRows(
          key: LumeExpensesTool.insightsKey,
          children: <Widget>[
            LumeRichRow(
              icon: LumeIcons.trending,
              iconTone: lume.tintAccent,
              iconInk: lume.accent,
              title: l.expensesInsight1Title,
              subtitle: l.expensesInsight1Text,
            ),
            LumeRichRow(
              icon: LumeIcons.target,
              iconTone: lume.tintAccent,
              iconInk: lume.accent,
              title: l.expensesInsight2Title,
              subtitle: l.expensesInsight2Text,
            ),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeButtonRow(
          key: LumeExpensesTool.actionsKey,
          children: <Widget>[
            // The reference's own "Add expense" only toasts "New expense";
            // here it adds one (C74).
            LumeButton.accent(
              label: l.expensesAdd,
              icon: LumeIcons.plus,
              onPressed: _startCreate,
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

  Widget _detailScreen(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    String ccy,
  ) {
    final LumeToolRequest r = widget.request;
    final LumeRecord? rec = _repo.get(_coll, _selected);
    final String noun = l.recExpensesNoun;
    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      bare: true,
      onBack: _backToList,
      title: LumeExpenseRecords.sentence(l.recDetailTitle(noun)),
      subtitle: rec == null ? '' : LumeExpenseRecords.created(l, f, now, rec),
      headerActions: <Widget>[
        if (rec != null)
          LumeIconButton(
            icon: LumeIcons.note,
            label: LumeExpenseRecords.sentence(l.recEdit(noun)),
            onPressed: () => _startEdit(rec.id),
          ),
      ],
      body: LumeToolSection(
        child: rec == null
            ? LumeCollectionState(
                key: LumeExpensesTool.recordStateKey,
                kind: LumeCollectionStateKind.noResults,
                title: l.recGone,
                text: l.recGoneText,
                primaryAction: LumeButton(
                  label: LumeExpenseRecords.sentence(
                    l.recBackToList(l.recExpensesNounPlural),
                  ),
                  onPressed: _backToList,
                ),
              )
            : _detailBody(l, f, now, ccy, rec),
      ),
    );
  }

  Widget _detailBody(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    String ccy,
    LumeRecord rec,
  ) {
    final LumeColors lume = context.lume;
    final String noun = l.recExpensesNoun;
    final String category = LumeExpensesStrings.category(
      l,
      LumeExpenseRecords.category(rec),
    );
    final String notes = LumeExpenseRecords.text(l, rec, 'notes');
    final Object? receipt = rec['receipt'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LumeRecordHero(
          key: LumeExpensesTool.heroKey,
          gradient: context.lumeGradients.accent,
          kicker: category,
          value: LumeExpenseRecords.amount(f, ccy, rec),
          title: LumeExpenseRecords.text(l, rec, 'title'),
          caption: LumeExpenseRecords.showDate(f, rec['date']),
        ),
        // `UI.sectionHead({ title: rec.details })` — 15 / 700 on 19, 12 above
        // the facts.
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
        // `.cfacts` — its own card: `4 16` of padding, radius 16, `shadow-xs`.
        Container(
          key: LumeExpensesTool.factsKey,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          decoration: BoxDecoration(
            color: lume.card,
            borderRadius: LumeRadius.brMd,
            border: Border.all(color: lume.border, width: LumeSpace.border),
            boxShadow: context.lumeShadows.xs,
          ),
          child: LumeFactCard(
            facts: <LumeFact>[
              LumeFact(label: l.expensesCategory, value: category),
              LumeFact(
                label: l.recFieldPayment,
                value: LumeExpensesStrings.payment(l, rec['method']),
              ),
              LumeFact(
                label: l.recFieldNotes,
                value: notes.isEmpty ? l.recNone : notes,
              ),
              LumeFact(
                label: l.recFieldReceipt,
                value:
                    receipt == true || (receipt is String && receipt.isNotEmpty)
                    ? l.recAttached
                    : l.recNotAttached,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LumeDetailActions(
          key: LumeExpensesTool.detailActionsKey,
          editLabel: LumeExpenseRecords.sentence(l.recEdit(noun)),
          onEdit: () => _startEdit(rec.id),
          deleteLabel: LumeExpenseRecords.sentence(l.recDelete(noun)),
          onDelete: () => _askDelete(rec),
        ),
        const SizedBox(height: 18),
        LumeRecordIdLabel(
          key: LumeExpensesTool.recordIdKey,
          label: l.recRecordId(rec.id.toUpperCase()),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------- form

  Widget _formScreen(AppLocalizations l, LumeFormatting f, DateTime now) {
    final LumeToolRequest r = widget.request;
    final LumeRecordForm form = _form!;
    final bool creating = form.mode == LumeFormMode.create;
    final String noun = l.recExpensesNoun;
    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      bare: true,
      onBack: _leaveForm,
      title: LumeExpenseRecords.sentence(
        creating ? l.recAdd(noun) : l.recEdit(noun),
      ),
      subtitle: creating ? l.recNewRecord : l.recEditing,
      headerActions: <Widget>[
        LumeTextButton(label: l.actionSave, onPressed: _save),
      ],
      body: LumeToolSection(child: _formBody(l, f, now, form)),
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

  Widget _formBody(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    LumeRecordForm form,
  ) {
    final LumeColors lume = context.lume;
    final bool creating = form.mode == LumeFormMode.create;
    final String noun = l.recExpensesNoun;
    final bool pair = context.hasDetailPane;

    final List<(bool, Widget)> fields = <(bool, Widget)>[
      (
        false,
        LumeFormField(
          key: LumeExpensesTool.fieldKey('title'),
          label: l.recFieldTitle,
          controller: _title,
          focusNode: _focus['title'],
          placeholder: l.recExpensesPh,
          required: true,
          error: _error(l, form, 'title', l.recFieldTitle),
          onChanged: (String v) => form.setValue('title', v),
          onEditingComplete: () => form.touch('title'),
        ),
      ),
      (
        false,
        LumeFormField(
          key: LumeExpensesTool.fieldKey('amount'),
          label: l.recFieldAmount,
          controller: _amount,
          focusNode: _focus['amount'],
          kind: LumeFieldKind.money,
          required: true,
          error: _error(l, form, 'amount', l.recFieldAmount),
          onChanged: (String v) => form.setValue('amount', v),
          onEditingComplete: () => form.touch('amount'),
        ),
      ),
      (
        false,
        LumeFormPicker(
          key: LumeExpensesTool.fieldKey('cat'),
          label: l.recFieldCategory,
          value: LumeExpensesStrings.category(
            l,
            LumeExpenseCategory.byId(form.value('cat') as String?) ??
                LumeExpenseCategory.values.last,
          ),
          onTap: () => _choose('cat', l.recFieldCategory, <(String, String)>[
            for (final LumeExpenseCategory c in LumeExpenseCategory.values)
              (c.name, LumeExpensesStrings.category(l, c)),
          ]),
        ),
      ),
      (
        false,
        LumeFormPicker(
          key: LumeExpensesTool.fieldKey('date'),
          label: l.recFieldDate,
          value: LumeExpenseRecords.showDate(f, form.value('date')),
          icon: LumeIcons.calendar,
          onTap: _chooseDate,
        ),
      ),
      (
        false,
        LumeFormPicker(
          key: LumeExpensesTool.fieldKey('method'),
          label: l.recFieldPayment,
          value: LumeExpensesStrings.payment(l, form.value('method')),
          onTap: () => _choose('method', l.recFieldPayment, <(String, String)>[
            for (final String m in LumeExpenseRecords.methods)
              (m, LumeExpensesStrings.payment(l, m)),
          ]),
        ),
      ),
      (
        true,
        LumeFormField(
          key: LumeExpensesTool.fieldKey('notes'),
          label: l.recFieldNotes,
          optionalLabel: l.recOptional,
          controller: _notes,
          focusNode: _focus['notes'],
          kind: LumeFieldKind.multiline,
          onChanged: (String v) => form.setValue('notes', v),
          onEditingComplete: () => form.touch('notes'),
        ),
      ),
      (
        true,
        LumeAttachTile(
          key: LumeExpensesTool.fieldKey('receipt'),
          fieldLabel: l.recFieldReceipt,
          optionalLabel: l.recOptional,
          label: l.recAttach,
          onTap: () => _say?.say(l.recAttachSoon, tone: LumeToastTone.info),
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

    final String saveLabel = LumeExpenseRecords.sentence(
      creating ? l.recSave(noun) : l.recUpdate,
    );

    if (!pair) {
      return Column(
        key: LumeExpensesTool.formKey,
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
            key: LumeExpensesTool.submitKey,
            saveLabel: saveLabel,
            onSave: _save,
            busy: form.busy,
            busyLabel: l.recSaving,
            note: l.recConfirmNote,
          ),
        ],
      );
    }

    // `.cformcard` — the tablet form: `24` of padding, radius 16, a title 20
    // above two columns of short fields 20 apart and 16 between rows; the
    // actions side by side under a hairline (C74).
    return Container(
      key: LumeExpensesTool.formKey,
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
            LumeExpenseRecords.sentence(l.recInformation(noun)),
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
            key: LumeExpensesTool.submitKey,
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

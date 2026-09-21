/// Baby Budget — `tools/personal/babybudget.tool.js`, as a real
/// record-backed tool (`BABY_BUDGET_PROPOSAL.md` §15).
///
/// The reference's composition, in its order: the month's summary with
/// its ring, "Where it goes", "Six months", "Coming up" and "One-off
/// purchases", then the frame's source line and related tools. What it
/// only drew, this does: the budget, its categories and its spends are
/// the reader's own records — nothing seeded — every figure is worked
/// out from them, and a budget can be created, spent against, planned
/// against, corrected, archived and deleted.
///
/// Where the reference could not hold together, this does not follow it:
/// "82% of plan" is the reader's own plan or no ratio at all; the donut
/// adds to 100 because its shares come from largest remainder over minor
/// units; the bars carry the six months ending with the reader's own, in
/// their language and their budget's currency; and "Coming up" shows
/// stored dates against the reader's own day, overdue first, instead of
/// weekday names off the device clock.
///
/// It is sensitive: a record of what a family spends on a baby. The
/// frame shows its privacy note, nothing here reaches Home, and it sends
/// no notification (D-B15, D-B16).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../../app/providers/platform_services.dart';
import '../../../app/providers/records_provider.dart';
import '../../../app/providers/shell_provider.dart';
import '../../../app/providers/time_zone_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/lume_build.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/navigation/lume_tool_frame.dart';
import '../../../core/platform/lume_export.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_currency_policy.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_month_anchor.dart';
import '../../../core/values/lume_record_id.dart';
import '../../../core/widgets/lume/lume_badge.dart';
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
import '../../ledger/presentation/ledger_text.dart';
import '../../onboarding/domain/onboarding_state.dart';
import '../../records/domain/record_transaction.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/babybudget_providers.dart';
import '../domain/babybudget_book.dart';
import '../domain/babybudget_failure.dart';
import '../domain/babybudget_model.dart';
import '../domain/babybudget_repository.dart';
import '../domain/babybudget_transfer.dart';
import 'babybudget_sheets.dart';
import 'babybudget_text.dart';
import 'babybudget_transfer_sheets.dart';

enum BabyFilter { inUse, notStarted, archived, all }

enum BabySort { recent, name, spend }

enum _View { list, budget, category, spending, form, spendForm }

abstract final class LumeBabyBudgetTool {
  static const String id = 'babybudget';

  static const Key summaryKey = ValueKey<String>('baby.summary');
  static const Key filterKey = ValueKey<String>('baby.filter');
  static const Key searchKey = ValueKey<String>('baby.search');
  static const Key sortKey = ValueKey<String>('baby.sort');
  static const Key listKey = ValueKey<String>('baby.list');
  static const Key emptyKey = ValueKey<String>('baby.empty');
  static const Key noMatchKey = ValueKey<String>('baby.noMatch');
  static const Key dayUnknownKey = ValueKey<String>('baby.dayUnknown');
  static const Key notStartedKey = ValueKey<String>('baby.notStarted');
  static const Key archivedKey = ValueKey<String>('baby.archived');
  static const Key defectsKey = ValueKey<String>('baby.defects');
  static const Key damagedKey = ValueKey<String>('baby.damaged');
  static const Key addKey = ValueKey<String>('baby.add');
  static const Key budgetKey = ValueKey<String>('baby.budget');
  static const Key donutKey = ValueKey<String>('baby.donut');
  static const Key chartKey = ValueKey<String>('baby.chart');
  static const Key comingUpKey = ValueKey<String>('baby.comingUp');
  static const Key oneOffKey = ValueKey<String>('baby.oneOff');
  static const Key categoriesKey = ValueKey<String>('baby.categories');
  static const Key spendingKey = ValueKey<String>('baby.spending');
  static const Key categoryKey = ValueKey<String>('baby.category');
  static const Key spendKey = ValueKey<String>('baby.spend');
  static const Key planKey = ValueKey<String>('baby.plan');
  static const Key editKey = ValueKey<String>('baby.edit');
  static const Key archiveKey = ValueKey<String>('baby.archive');
  static const Key unarchiveKey = ValueKey<String>('baby.unarchive');
  static const Key deleteKey = ValueKey<String>('baby.delete');
  static const Key monthKey = ValueKey<String>('baby.month');
  static const Key formKey = ValueKey<String>('baby.form');
  static const Key spendFormKey = ValueKey<String>('baby.form.spend');
  static const Key saveKey = ValueKey<String>('baby.save');
  static const Key lockedKey = ValueKey<String>('baby.locked');
  static const Key nameField = ValueKey<String>('baby.field.name');
  static const Key noteField = ValueKey<String>('baby.field.note');
  static const Key currencyField = ValueKey<String>('baby.field.currency');
  static const Key planField = ValueKey<String>('baby.field.plan');
  static const Key startedField = ValueKey<String>('baby.field.started');
  static const Key categoriesField = ValueKey<String>('baby.field.categories');
  static const Key addCategoryKey = ValueKey<String>('baby.category.add');
  static const Key amountField = ValueKey<String>('baby.field.amount');
  static const Key categoryField = ValueKey<String>('baby.field.category');
  static const Key labelField = ValueKey<String>('baby.field.label');
  static const Key dayField = ValueKey<String>('baby.field.day');

  static Key filterChip(BabyFilter f) =>
      ValueKey<String>('baby.filter.${f.name}');
  static Key row(String budget) => ValueKey<String>('baby.row.$budget');
  static Key slice(String name) => ValueKey<String>('baby.slice.$name');
  static Key entry(String id) => ValueKey<String>('baby.entry.$id');
  static Key categoryRow(String id) => ValueKey<String>('baby.cat.$id');
  static Key categoryPick(String id) => ValueKey<String>('baby.pick.$id');
  static Key categoryName(int i) => ValueKey<String>('baby.field.cat.$i');
  static Key categoryPlan(int i) => ValueKey<String>('baby.field.catplan.$i');
  static Key categoryRemove(int i) => ValueKey<String>('baby.field.rm.$i');
  static Key categoryUp(int i) => ValueKey<String>('baby.field.up.$i');
  static Key categoryDown(int i) => ValueKey<String>('baby.field.down.$i');

  static Widget open(LumeToolRequest request) =>
      BabyBudgetTool(request: request);
}

class BabyBudgetTool extends ConsumerStatefulWidget {
  const BabyBudgetTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<BabyBudgetTool> createState() => _BabyBudgetToolState();
}

/// The separator a draft's dirty check joins its fields with: a character
/// no field can hold, so two different drafts never look alike.
final String _unit = String.fromCharCode(1);
final String _field = String.fromCharCode(0);

/// One category as the budget form holds it, before anything is written.
class _CategoryDraft {
  _CategoryDraft({this.id, this.version, String name = '', String plan = ''})
    : name = TextEditingController(text: name),
      plan = TextEditingController(text: plan);

  final LumeRecordId? id;
  final int? version;
  final TextEditingController name;
  final TextEditingController plan;

  String get state => '${name.text}$_field${plan.text}';

  void dispose() {
    name.dispose();
    plan.dispose();
  }
}

/// A budget form's state. [locked] once a spend exists: the currency is
/// shown and cannot be changed (D-B7).
class _BudgetDraft {
  _BudgetDraft({
    this.id,
    this.version,
    required this.currency,
    this.startedOn,
    this.locked = false,
    String name = '',
    String note = '',
    String plan = '',
    List<_CategoryDraft>? categories,
  }) : name = TextEditingController(text: name),
       note = TextEditingController(text: note),
       plan = TextEditingController(text: plan),
       categories = categories ?? <_CategoryDraft>[_CategoryDraft()] {
    _initial = _state;
  }

  final LumeRecordId? id;
  final int? version;
  final bool locked;
  LumeCurrency? currency;
  LumeDate? startedOn;
  final TextEditingController name;
  final TextEditingController note;
  final TextEditingController plan;
  final List<_CategoryDraft> categories;
  final Map<String, String> errors = <String, String>{};
  late final String _initial;

  String get _state => <Object?>[
    name.text,
    note.text,
    plan.text,
    currency?.code,
    startedOn?.toIso(),
    for (final _CategoryDraft c in categories) c.state,
  ].join(_unit);

  bool get dirty => _state != _initial;

  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      name,
      note,
      plan,
    ]) {
      c.dispose();
    }
    for (final _CategoryDraft c in categories) {
      c.dispose();
    }
  }
}

/// A spend form's state — money that went, or money the reader means to
/// spend. [planned] decides which, and never changes inside the form:
/// moving between the two is its own action (correction 1).
class _SpendDraft {
  _SpendDraft({
    this.id,
    this.version,
    required this.budget,
    required this.planned,
    this.categoryId,
    this.day,
    String amount = '',
    String label = '',
  }) : amount = TextEditingController(text: amount),
       label = TextEditingController(text: label) {
    _initial = _state;
  }

  final LumeRecordId? id;
  final int? version;
  final LumeRecordId budget;
  final bool planned;
  LumeRecordId? categoryId;
  LumeDate? day;
  final TextEditingController amount;
  final TextEditingController label;
  final Map<String, String> errors = <String, String>{};
  late final String _initial;

  String get _state => <Object?>[
    amount.text,
    label.text,
    categoryId?.value,
    day?.toIso(),
  ].join(_unit);

  bool get dirty => _state != _initial;

  void dispose() {
    amount.dispose();
    label.dispose();
  }
}

class _BabyBudgetToolState extends ConsumerState<BabyBudgetTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final BabyBudgetRepository _repo = ref.read(
    babyBudgetRepositoryProvider,
  );
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(
    text: _read('q') ?? '',
  );
  final FocusNode _searchFocus = FocusNode();

  /// The body, to find the frame's scroll from: a new view opens at its top.
  final GlobalKey _body = GlobalKey();

  _View _view = _View.list;
  LumeRecordId? _budget;
  LumeRecordId? _category;
  LumeDate? _month;
  _BudgetDraft? _draft;
  _SpendDraft? _spend;
  bool _linked = false;

  String get _id => widget.request.feature.id;
  String? _read(String key) => _session.read(_id, key);
  void _write(String key, String value) => _session.write(_id, key, value);

  BabyFilter get _filter => BabyFilter.values.firstWhere(
    (BabyFilter f) => f.name == _read('filter'),
    orElse: () => BabyFilter.inUse,
  );
  BabySort get _sort => BabySort.values.firstWhere(
    (BabySort s) => s.name == _read('sort'),
    orElse: () => BabySort.recent,
  );
  bool get _descending => _read('dir') != 'asc';

  @override
  void initState() {
    super.initState();
    _repo.open();
    _repo.changes.addListener(_changed);
    final LumeRecordId? kept = LumeRecordId.tryParse(_read('budget') ?? '');
    if (kept != null) {
      _budget = kept;
      _view = _View.budget;
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
    _spend?.dispose();
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

  LumeProfileRecord get _profile =>
      ref.read(startupControllerProvider).state.profile;

  /// The reader's calendar date in their resolved zone, or `null` when it
  /// cannot be worked out: there is then no month, no trend and nothing
  /// overdue (§8).
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

  /// The reader's currency: theirs where set, else their market's — one a
  /// new budget may use, or none.
  LumeCurrency? _currency() {
    final LumeProfileRecord p = _profile;
    final String code = p.currency != LumePreference.auto
        ? p.currency
        : (ref
                  .read(startupControllerProvider)
                  .state
                  .countries
                  ?.currencyOf(widget.request.user.country) ??
              '');
    return babyBudgetDefaultCurrency(code);
  }

  // ------------------------------------------------------------ navigation

  void _go(
    _View v, {
    LumeRecordId? budget,
    LumeRecordId? category,
    LumeDate? month,
  }) {
    final bool moved =
        v != _view ||
        (budget != null && budget != _budget) ||
        (category != null && category != _category);
    setState(() {
      _view = v;
      if (budget != null) _budget = budget;
      if (category != null) _category = category;
      if (month != null) _month = month;
      _write('budget', v == _View.list ? '' : (_budget?.value ?? ''));
    });
    if (!moved) return;
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
      case _View.budget:
        _go(_View.list);
      case _View.category:
      case _View.spending:
        _go(_View.budget);
      case _View.form:
        final _BudgetDraft? d = _draft;
        if (d != null && d.dirty && !await _confirmDiscard()) return;
        if (!mounted) return;
        _draft = null;
        d?.dispose();
        _go(d?.id != null ? _View.budget : _View.list);
      case _View.spendForm:
        final _SpendDraft? s = _spend;
        if (s != null && s.dirty && !await _confirmDiscard()) return;
        if (!mounted) return;
        _spend = null;
        s?.dispose();
        _go(_View.budget);
    }
  }

  Future<bool> _confirmDiscard() async {
    final AppLocalizations l = AppLocalizations.of(context);
    return await babyDecide(
          context,
          title: l.recDiscardAsk,
          text: l.recDiscardText,
          confirm: l.recDiscard,
          cancel: l.recKeepEditing,
          destructive: true,
        ) ??
        false;
  }

  void _addBudget(LumeDate? today) {
    _draft?.dispose();
    _draft = _BudgetDraft(currency: _currency(), startedOn: today);
    _go(_View.form);
  }

  void _editBudget(BabyBudgetView v) {
    _draft?.dispose();
    final BabyBudget b = v.budget;
    _draft = _BudgetDraft(
      id: b.id,
      version: b.version,
      currency: b.currency,
      startedOn: b.startedOn,
      locked: v.spends.isNotEmpty,
      name: b.name,
      note: b.note ?? '',
      plan: b.monthlyPlan?.toDecimalString() ?? '',
      categories: <_CategoryDraft>[
        for (final BabyCategory c in v.categories)
          _CategoryDraft(
            id: c.id,
            version: c.version,
            name: c.name,
            plan: c.monthlyPlan?.toDecimalString() ?? '',
          ),
        if (v.categories.isEmpty) _CategoryDraft(),
      ],
    );
    _go(_View.form);
  }

  void _addSpend(BabyBudgetView v, LumeDate? today, {required bool planned}) {
    _spend?.dispose();
    _spend = _SpendDraft(
      budget: v.id,
      planned: planned,
      day: planned ? null : (today ?? v.budget.startedOn),
    );
    _go(_View.spendForm);
  }

  void _editSpend(BabyBudgetView v, BabySpend s) {
    _spend?.dispose();
    _spend = _SpendDraft(
      id: s.id,
      version: s.version,
      budget: v.id,
      planned: s.planned,
      categoryId: s.categoryId,
      day: s.day,
      amount: s.amount.toDecimalString(),
      label: s.label ?? '',
    );
    _go(_View.spendForm);
  }

  // ---------------------------------------------------------------- writes

  void _failed(AppLocalizations l, BabyBudgetFailure f) {
    _say(switch (f.kind) {
      BabyBudgetFailureKind.conflict ||
      BabyBudgetFailureKind.notFound => l.babyErrConflict,
      BabyBudgetFailureKind.damaged => l.babyErrDamaged,
      BabyBudgetFailureKind.archived => l.babyErrArchived,
      BabyBudgetFailureKind.overflow => l.babyErrTooLarge,
      BabyBudgetFailureKind.beforeStart =>
        f.day == null ? l.babyErrFailed : l.babyErrBeforeStart(_dateOf(f.day!)),
      BabyBudgetFailureKind.planShape => switch (f.reason) {
        'noBudgetPlan' => l.babyErrNoBudgetPlan,
        'overPlan' => l.babyErrOverPlan,
        'belowCategories' => l.babyErrBelowCategories,
        _ => l.babyErrFailed,
      },
      _ => l.babyErrFailed,
    }, tone: LumeToastTone.error);
  }

  /// A date for a message, outside a build's formatting.
  String _dateOf(LumeDate d) => BabyBudgetText.date(
    LumeFormatting.of(context, countryCode: widget.request.user.country),
    d,
  );

  /// Offer to take a committed write back.
  void _undoable(AppLocalizations l, String message, BabyBudgetWrite w) => _say(
    message,
    actionLabel: l.recUndo,
    onAction: () {
      final BabyBudgetResult<void> r = _repo.undo(w);
      if (r.failure != null) _failed(l, r.failure!);
    },
  );

  intl.NumberFormat _numbers() => intl.NumberFormat.decimalPattern(
    Localizations.localeOf(context).toLanguageTag().replaceAll('-', '_'),
  );

  /// The reader's text as an amount, in their own digits and separators.
  LedgerParsedAmount _money(
    AppLocalizations l,
    String text,
    LumeCurrency currency,
  ) {
    final intl.NumberFormat nf = _numbers();
    return ledgerParseAmount(
      l,
      text,
      currency,
      decimalSeparator: nf.symbols.DECIMAL_SEP,
      groupSeparator: nf.symbols.GROUP_SEP,
    );
  }

  Future<void> _saveBudget(AppLocalizations l) async {
    final _BudgetDraft d = _draft!;
    final Map<String, String> errors = <String, String>{};

    final String name = d.name.text.trim();
    if (name.isEmpty) errors['name'] = l.babyErrName;
    if (name.length > kBabyNameMax) errors['name'] = l.babyErrLong;
    if (d.note.text.length > kBabyNoteMax) errors['note'] = l.babyErrLong;
    if (d.currency == null) errors['currency'] = l.babyErrDate;
    if (d.startedOn == null) errors['startedOn'] = l.babyErrDate;

    // An empty plan is no plan, which is a real answer (D-B2). A plan
    // that is entered has to be above zero (correction 2).
    LumeMoney? plan;
    if (d.currency case final LumeCurrency cur) {
      if (d.plan.text.trim().isNotEmpty) {
        final LedgerParsedAmount p = _money(l, d.plan.text, cur);
        // A plan of nothing is not a bad amount, it is no plan, and the
        // reader is told how to say that (correction 2).
        if (p.error == l.ledgerErrAmount ||
            (p.error == null && !(p.money?.isPositive ?? false))) {
          errors['plan'] = l.babyErrZeroPlan;
        } else if (p.error != null) {
          errors['plan'] = p.error!;
        }
        plan = p.money;
      }
    }

    final List<BabyCategoryDraft> categories = <BabyCategoryDraft>[];
    final List<_CategoryDraft> kept = <_CategoryDraft>[
      for (final _CategoryDraft c in d.categories)
        if (c.name.text.trim().isNotEmpty || c.plan.text.trim().isNotEmpty) c,
    ];
    int colour = 0;
    for (final _CategoryDraft c in kept) {
      final String who = c.name.text.trim();
      if (who.isEmpty) errors['categories'] = l.babyErrCategoryName;
      if (who.length > kBabyNameMax) errors['categories'] = l.babyErrLong;
      LumeMoney? share;
      if (d.currency case final LumeCurrency cur) {
        if (c.plan.text.trim().isNotEmpty) {
          final LedgerParsedAmount p = _money(l, c.plan.text, cur);
          if (p.error == l.ledgerErrAmount ||
              (p.error == null && !(p.money?.isPositive ?? false))) {
            errors['categories'] = l.babyErrZeroPlan;
          } else if (p.error != null) {
            errors['categories'] = p.error!;
          }
          share = p.money;
        }
      }
      // A share of a plan that does not exist is not a plan
      // (correction 2). The repository refuses it too; saying so here
      // means the reader sees it beside the field.
      if (share != null && plan == null) {
        errors['categories'] = l.babyErrNoBudgetPlan;
      }
      categories.add(
        BabyCategoryDraft(
          name: who,
          monthlyPlan: share,
          colour: colour % kBabyColourCount,
        ),
      );
      colour++;
    }
    if (categories.length > kBabyCategoryMax) {
      errors['categories'] = l.babyErrCategoryLimit(
        LumeFormatting.of(
          context,
          countryCode: widget.request.user.country,
        ).integer(kBabyCategoryMax),
      );
    }
    final Set<String> seen = <String>{};
    for (final BabyCategoryDraft c in categories) {
      if (!seen.add(LedgerText.fold(c.name))) {
        errors['categories'] = l.babyErrDuplicate;
      }
    }

    setState(() {
      d.errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) return;

    final BabyBudgetResult<BabyBudgetWrite> r;
    if (d.id == null) {
      r = _repo.addBudget(
        BabyBudgetDraft(
          name: name,
          note: d.note.text.trim().isEmpty ? null : d.note.text,
          currency: d.currency!,
          monthlyPlan: plan,
          startedOn: d.startedOn!,
          categories: categories,
        ),
      );
    } else {
      r = _editExisting(d, name, plan, categories);
    }
    if (!mounted) return;
    final BabyBudgetFailure? failure = r.failure;
    if (failure != null) {
      final String? field = switch (failure.field) {
        'name' || 'note' || 'startedOn' => failure.field,
        'planMinor' || 'plan' => 'plan',
        'category' || 'categories' => 'categories',
        _ => null,
      };
      if (field != null) {
        setState(
          () => d.errors[field] = switch (failure.reason) {
            'required' when field == 'name' => l.babyErrName,
            'long' => l.babyErrLong,
            'zero' => l.babyErrZeroPlan,
            'noBudgetPlan' => l.babyErrNoBudgetPlan,
            'overPlan' => l.babyErrOverPlan,
            'belowCategories' => l.babyErrBelowCategories,
            'duplicate' => l.babyErrDuplicate,
            'overflow' => l.babyErrTooLarge,
            _ => l.babyErrFailed,
          },
        );
        return;
      }
      return _failed(l, failure);
    }
    final LumeRecordId id = d.id ?? r.value!.budget!.id;
    _draft = null;
    d.dispose();
    _say(l.babySaved);
    _go(_View.budget, budget: id);
  }

  /// An existing budget's edit, as the writes the repository offers: the
  /// name and note, then the plan, then the start, then each category.
  /// Every one of them is checked where it is written, so a refusal
  /// leaves the rest as they were.
  BabyBudgetResult<BabyBudgetWrite> _editExisting(
    _BudgetDraft d,
    String name,
    LumeMoney? plan,
    List<BabyCategoryDraft> categories,
  ) {
    final BabyBudgetView? before = _repo.view().book(null).budget(d.id!);
    if (before == null) {
      return const BabyBudgetResult<BabyBudgetWrite>.failed(
        BabyBudgetFailure(BabyBudgetFailureKind.notFound),
      );
    }
    BabyBudgetResult<BabyBudgetWrite> r = _repo.editBudget(
      d.id!,
      name: name,
      note: d.note.text.trim().isEmpty ? null : d.note.text,
      version: d.version!,
    );
    if (r.failure != null) return r;

    BabyBudgetView now() => _repo.view().book(null).budget(d.id!)!;

    // The plan is set before the categories when it grows, and after
    // them when it shrinks, so a valid end state is never refused on the
    // way there (correction 2).
    final LumeMoney? was = before.plan;
    final bool growing =
        plan != null && (was == null || plan.compareTo(was) >= 0);
    if (growing && plan != was) {
      r = _repo.setPlan(d.id!, plan, version: now().budget.version);
      if (r.failure != null) return r;
    }

    // Categories the reader took out of the form: their spends stay, and
    // become uncategorised.
    final Set<String> keptIds = <String>{
      for (final _CategoryDraft c in d.categories)
        if (c.id != null) c.id!.value,
    };
    for (final BabyCategory c in before.categories) {
      if (keptIds.contains(c.id.value)) continue;
      r = _repo.deleteCategory(c.id, version: c.version);
      if (r.failure != null) return r;
    }
    for (final (int i, _CategoryDraft c) in d.categories.indexed) {
      if (i >= categories.length) break;
      final BabyCategoryDraft want = categories[i];
      final LumeRecordId? id = c.id;
      if (id == null) {
        r = _repo.addCategory(d.id!, want);
      } else {
        final BabyCategory? current = now().categoryOf(id);
        if (current == null) continue;
        if (current.name == want.name &&
            current.monthlyPlan == want.monthlyPlan) {
          continue;
        }
        r = _repo.editCategory(
          id,
          name: want.name,
          monthlyPlan: want.monthlyPlan,
          clearPlan: want.monthlyPlan == null,
          version: current.version,
        );
      }
      if (r.failure != null) return r;
    }

    if (!growing && plan != was) {
      r = _repo.setPlan(d.id!, plan, version: now().budget.version);
      if (r.failure != null) return r;
    }
    if (d.startedOn != null && d.startedOn != before.budget.startedOn) {
      r = _repo.setStartedOn(
        d.id!,
        d.startedOn!,
        version: now().budget.version,
      );
      if (r.failure != null) return r;
    }
    return r;
  }

  Future<void> _saveSpend(AppLocalizations l, BabyBudgetView v) async {
    final _SpendDraft s = _spend!;
    final Map<String, String> errors = <String, String>{};

    final LedgerParsedAmount p = _money(l, s.amount.text, v.currency);
    if (p.error != null) {
      errors['amount'] = p.error!;
    } else if (p.money == null || !p.money!.isPositive) {
      errors['amount'] = l.babyErrAmount;
    }
    if (s.label.text.length > kBabyLabelMax) errors['label'] = l.babyErrLong;
    // A spend has a day; a planned purchase may have none (D-B4).
    if (!s.planned && s.day == null) errors['day'] = l.babyErrDate;

    setState(() {
      s.errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) return;

    final String? label = s.label.text.trim().isEmpty
        ? null
        : s.label.text.trim();
    final LumeDate? today = _today(context);
    BabyBudgetResult<BabyBudgetWrite> r;
    if (s.id == null) {
      r = s.planned
          ? _repo.recordPlanned(
              v.id,
              amount: p.money!,
              expectedOn: s.day,
              categoryId: s.categoryId,
              label: label,
            )
          : _repo.recordSpend(
              v.id,
              amount: p.money!,
              spentOn: s.day!,
              categoryId: s.categoryId,
              label: label,
              today: today,
            );
    } else {
      r = _repo.editSpend(
        s.id!,
        amount: p.money,
        day: s.day,
        categoryId: s.categoryId,
        clearCategory: s.categoryId == null,
        label: label,
        clearLabel: label == null,
        clearExpected: s.planned && s.day == null,
        today: today,
        version: s.version!,
      );
    }
    if (!mounted) return;
    final BabyBudgetFailure? failure = r.failure;
    if (failure != null) {
      final String? field = switch (failure.field) {
        'amount' || 'amountMinor' => 'amount',
        'label' => 'label',
        'spentOn' || 'expectedOn' || 'day' => 'day',
        _ => null,
      };
      if (field != null && failure.kind != BabyBudgetFailureKind.beforeStart) {
        setState(
          () => s.errors[field] = switch (failure.reason) {
            'future' => l.babyErrFuture,
            'long' => l.babyErrLong,
            'zero' || 'negative' => l.babyErrAmount,
            'overflow' => l.babyErrTooLarge,
            _ => l.babyErrFailed,
          },
        );
        return;
      }
      return _failed(l, failure);
    }
    final bool planned = s.planned;
    _spend = null;
    s.dispose();
    _say(
      s.id == null
          ? (planned ? l.babyPlanSaved : l.babySpendSaved)
          : l.babySaved,
    );
    _go(_View.budget, budget: v.id);
  }

  /// A planned purchase becomes a spend: one write that clears what was
  /// expected, sets the day it happened, and takes what it actually cost
  /// (correction 1).
  Future<void> _markBought(
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetView v,
    BabySpend s,
    LumeDate? today,
    bool withCode,
  ) async {
    final BabyBoughtAnswer? answer = await BabyBoughtSheet.show(
      context,
      title: l.babyBoughtTitle,
      text: l.babyBoughtText(
        s.label ?? l.babyPlannedBadge,
        f.amount(s.amount, withCode: withCode, isolate: true),
      ),
      action: l.babyBoughtGo,
      amountLabel: l.babyActualAmount,
      amount: s.amount.toDecimalString(),
      currencyCode: v.currency.code,
      initial: today ?? s.expectedOn,
      today: today,
      dateText: (LumeDate d) => BabyBudgetText.date(f, d, today: today),
    );
    if (answer == null || !mounted) return;
    final LedgerParsedAmount p = _money(l, answer.amount, v.currency);
    if (p.money == null || !p.money!.isPositive) {
      _say(p.error ?? l.babyErrAmount, tone: LumeToastTone.error);
      return;
    }
    final BabyBudgetResult<BabyBudgetWrite> r = _repo.markBought(
      s.id,
      on: answer.on,
      actually: p.money,
      today: today,
      version: s.version,
    );
    if (r.failure != null) {
      if (r.failure!.field == 'spentOn' && r.failure!.reason == 'future') {
        _say(l.babyErrFuture, tone: LumeToastTone.error);
        return;
      }
      return _failed(l, r.failure!);
    }
    _undoable(l, l.babyBoughtToast, r.value!);
  }

  /// And back again, which is its own deliberate action — never the side
  /// effect of an edit (correction 1).
  Future<void> _markPlanned(
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetView v,
    BabySpend s,
    bool withCode,
  ) async {
    final bool? go = await babyDecide(
      context,
      title: l.babyPlannedAgainTitle,
      text: l.babyPlannedAgainText(
        f.amount(s.amount, withCode: withCode, isolate: true),
      ),
      confirm: l.babyPlannedAgainGo,
      destructive: true,
    );
    if (go != true || !mounted) return;
    final BabyBudgetResult<BabyBudgetWrite> r = _repo.markPlanned(
      s.id,
      expectedOn: s.spentOn,
      version: s.version,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _undoable(l, l.babyPlannedAgainToast, r.value!);
  }

  Future<void> _spendActions(
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetView v,
    BabySpend s,
    LumeDate? today,
    bool withCode,
  ) async {
    if (v.damaged || v.budget.archived) return;
    final List<(String, VoidCallback)> actions = <(String, VoidCallback)>[
      (l.babyEditSpend, () => _editSpend(v, s)),
      if (s.planned)
        (
          l.babyMarkBought,
          () => unawaited(_markBought(l, f, v, s, today, withCode)),
        )
      else ...<(String, VoidCallback)>[
        (
          l.babyMarkPlanned,
          () => unawaited(_markPlanned(l, f, v, s, withCode)),
        ),
        (
          s.voided ? l.babyRestoreSpend : l.babyVoidSpend,
          () => unawaited(_setVoided(l, s)),
        ),
      ],
    ];
    final VoidCallback? chosen = await showLumeSheet<VoidCallback>(
      context: context,
      barrierLabel: s.label ?? l.babyFieldAmount,
      child: Builder(
        builder: (BuildContext sheet) => LumeSheet(
          title: s.label ?? f.amount(s.amount, withCode: withCode),
          subtitle: BabyBudgetText.plannedMeta(l, f, v, s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final (String label, VoidCallback go) in actions)
                LumeRadioRow(
                  label: label,
                  selected: false,
                  onTap: () => Navigator.of(sheet).pop(go),
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null && mounted) chosen();
  }

  Future<void> _setVoided(AppLocalizations l, BabySpend s) async {
    final BabyBudgetResult<BabyBudgetWrite> r = _repo.setVoided(
      s.id,
      !s.voided,
      version: s.version,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _say(s.voided ? l.babyRestoredToast : l.babyVoidedToast);
  }

  Future<void> _archive(
    AppLocalizations l,
    BabyBudgetView v,
    LumeDate? today,
  ) async {
    if (v.budget.archived) {
      final BabyBudgetResult<BabyBudgetWrite> r = _repo.setArchived(
        v.id,
        false,
        version: v.budget.version,
      );
      if (r.failure != null) return _failed(l, r.failure!);
      _say(l.babyUnarchivedToast);
      return;
    }
    if (today == null) {
      // Archiving records the day it happened, and nothing is guessed.
      _say(l.babyDayUnknownText, tone: LumeToastTone.info);
      return;
    }
    final bool? go = await babyDecide(
      context,
      title: l.babyArchiveTitle,
      text: l.babyArchiveText,
      confirm: l.babyArchiveGo,
      cancel: l.babyKeepBudget,
    );
    if (go != true || !mounted) return;
    final BabyBudgetResult<BabyBudgetWrite> r = _repo.setArchived(
      v.id,
      true,
      on: today,
      today: today,
      version: v.budget.version,
    );
    if (r.failure != null) {
      if (r.failure!.field == 'archivedOn') {
        _say(l.babyErrArchivedFuture, tone: LumeToastTone.error);
        return;
      }
      return _failed(l, r.failure!);
    }
    _undoable(l, l.babyArchivedToast, r.value!);
  }

  Future<void> _delete(AppLocalizations l, BabyBudgetView v) async {
    final BabyBudgetCounts counts = _repo.counts(v.id);
    if (!await babyConfirmDelete(
      context,
      title: l.babyDeleteTitle,
      // Each count in its own grammar: "1 spend", not "1 spends".
      text: l.babyDeleteText(
        l.babyCountCategories(counts.categories),
        l.babyCountSpends(counts.spends),
        l.babyCountPlanned(counts.planned),
      ),
    )) {
      return;
    }
    if (!mounted) return;
    final BabyBudgetResult<BabyBudgetWrite> r = _repo.deleteBudget(
      v.id,
      version: v.budget.version,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _go(_View.list);
    _say(
      l.babyDeletedToast,
      actionLabel: l.recUndo,
      onAction: () {
        final BabyBudgetResult<void> back = _repo.undo(r.value!);
        if (back.failure != null) return _failed(l, back.failure!);
        _say(l.babyRestoredBudgetToast);
      },
    );
  }

  /// Deleting a category keeps every spend it held; the reader says
  /// where they go (D-B8).
  Future<void> _deleteCategory(
    AppLocalizations l,
    BabyBudgetView v,
    BabyCategory c,
  ) async {
    final int held = <BabySpend>[
      for (final BabySpend s in v.spends)
        if (s.categoryId == c.id) s,
    ].length;
    final List<BabyCategory> others = <BabyCategory>[
      for (final BabyCategory x in v.categories)
        if (x.id != c.id) x,
    ];
    final LumeRecordId? into = await showLumeSheet<LumeRecordId>(
      context: context,
      barrierLabel: l.babyDeleteCategoryTitle,
      child: Builder(
        builder: (BuildContext sheet) => LumeSheet(
          title: l.babyDeleteCategoryTitle,
          subtitle: l.babyDeleteCategoryText(l.babyCountSpends(held)),
          tall: others.length > 6,
          child: SingleChildScrollView(
            primary: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LumeRadioRow(
                  key: LumeBabyBudgetTool.categoryPick('none'),
                  label: l.babyMoveToNone,
                  selected: false,
                  onTap: () => Navigator.of(sheet).pop(c.id),
                ),
                for (final BabyCategory x in others)
                  LumeRadioRow(
                    key: LumeBabyBudgetTool.categoryPick(x.id.value),
                    label: l.babyMoveTo(x.name),
                    selected: false,
                    onTap: () => Navigator.of(sheet).pop(x.id),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (into == null || !mounted) return;
    final BabyBudgetResult<BabyBudgetWrite> r = _repo.deleteCategory(
      c.id,
      moveTo: into == c.id ? null : into,
      version: c.version,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    if (_category == c.id) _go(_View.budget);
    _undoable(l, l.babyCategoryDeletedToast, r.value!);
  }

  // --------------------------------------------------------- export, import

  Future<void> _export(
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetBook book,
  ) async {
    final BabyBudgetExportChoice? choice =
        await showLumeSheet<BabyBudgetExportChoice>(
          context: context,
          barrierLabel: l.babyExportTitle,
          child: BabyBudgetExportSheet(
            onImport: () => unawaited(_import(l, f)),
          ),
        );
    if (choice == null || !mounted) return;
    final DateTime now = LumeClockScope.of(context).now();
    final BabyBudgetSnapshot s = _repo.view();
    final LumeExportFile file = LumeExportFile.document(
      tool: _id,
      day: now,
      format: choice.json ? LumeExportFormat.json : LumeExportFormat.csv,
      text: choice.json
          ? babyBudgetExportJson(
              budgets: s.budgets,
              categories: s.categories,
              spends: s.spends,
              exportedAt: now,
              build: kLumeVersion,
              durable: _repo.durable,
              includeNames: choice.includeNames,
            )
          : babyBudgetExportCsv(book, includeNames: choice.includeNames),
    );
    final LumeExportOutcome outcome = await ref
        .read(exporterProvider)
        .export(file);
    if (!mounted) return;
    switch (outcome) {
      case LumeExportOutcome.saved:
        _say(l.toolExportedAs(file.fileName));
      case LumeExportOutcome.cancelled:
        break;
      case LumeExportOutcome.unavailable:
        _say(l.toolExportUnavailable, tone: LumeToastTone.info);
      case LumeExportOutcome.failed:
        _say(l.toolExportFailed, tone: LumeToastTone.error);
    }
  }

  Future<void> _import(AppLocalizations l, LumeFormatting f) async {
    final BabyBudgetImportReport? report =
        await showLumeSheet<BabyBudgetImportReport>(
          context: context,
          barrierLabel: l.babyImport,
          child: BabyBudgetImportSheet(
            store: ref.read(recordRepositoryProvider),
            f: f,
          ),
        );
    if (report == null || !mounted) return;
    final LumeTxResult<int> r = babyBudgetImportApply(
      report,
      ref.read(recordRepositoryProvider),
    );
    if (!r.ok) {
      _say(l.babyErrFailed, tone: LumeToastTone.error);
      return;
    }
    _say(l.babyImported(r.value!));
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
    final BabyBudgetSnapshot snapshot = _repo.view();

    BabyBudgetBook? book;
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
    // A second currency on screen: every amount carries its code, so a
    // shared symbol never stands for two currencies.
    final bool withCode = book != null && book.currencies.length > 1;

    final (String? title, List<Widget> body, bool bare) = switch (_view) {
      _ when book == null => (null, const <Widget>[], false),
      _View.list => (null, _list(context, l, f, book, today, withCode), false),
      _View.budget => _budgetScreen(context, l, f, book, today, withCode),
      _View.category => _categoryScreen(context, l, f, book, withCode),
      _View.spending => _spendingScreen(context, l, f, book, today, withCode),
      _View.form => (
        _draft?.id == null ? l.babyNewBudget : l.babyEditBudgetTitle,
        _budgetForm(context, l, f),
        true,
      ),
      _View.spendForm => _spendFormScreen(context, l, f, book, today),
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
          onExport: book == null || book.isEmpty
              ? null
              : () => unawaited(_export(l, f, book!)),
          onSearch: () {
            if (_view != _View.list) _go(_View.list);
            _searchFocus.requestFocus();
          },
        ),
        headerActions: _view == _View.form || _view == _View.spendForm
            ? <Widget>[
                LumeTextButton(
                  key: LumeBabyBudgetTool.saveKey,
                  label: l.actionSave,
                  onPressed: () {
                    if (_view == _View.form) {
                      unawaited(_saveBudget(l));
                    } else if (book != null && _budget != null) {
                      final BabyBudgetView? v = book.budget(_budget!);
                      if (v != null) unawaited(_saveSpend(l, v));
                    }
                  },
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

  void _deepLink(AppLocalizations l, BabyBudgetBook book) {
    final String? asked = widget.request.query['budget'];
    if (asked == null) {
      if (_budget != null && book.budget(_budget!) == null) {
        _view = _View.list;
        _budget = null;
      }
      return;
    }
    final LumeRecordId? id = LumeRecordId.tryParse(asked);
    if (id != null && book.budget(id) != null) {
      _budget = id;
      _view = _View.budget;
      return;
    }
    _view = _View.list;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _say(l.babyNotFound, tone: LumeToastTone.info),
    );
  }

  // ------------------------------------------------------------------ list

  bool _matches(BabyBudgetView v, BabyFilter f) => switch (f) {
    BabyFilter.inUse => v.status == BabyBudgetStatus.inUse,
    BabyFilter.notStarted => v.status == BabyBudgetStatus.notStarted,
    BabyFilter.archived => v.status == BabyBudgetStatus.archived,
    BabyFilter.all => true,
  };

  List<Widget> _list(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetBook book,
    LumeDate? today,
    bool withCode,
  ) {
    if (book.budgets.isEmpty) {
      return <Widget>[
        LumeToolSection(
          child: LumeToolState(
            key: LumeBabyBudgetTool.emptyKey,
            icon: LumeIcons.heart,
            title: l.babyEmptyTitle,
            text: l.babyEmptyText,
            action: LumeButton.accent(
              key: LumeBabyBudgetTool.addKey,
              label: l.babyAdd,
              icon: LumeIcons.plus,
              onPressed: () => _addBudget(today),
            ),
          ),
        ),
        if (book.defects.isNotEmpty) _defects(l, book),
      ];
    }
    final BabyFilter filter = _filter;
    final String q = LedgerText.fold(_query.text);
    final List<BabyBudgetView> budgets = book.budgets
        .where((BabyBudgetView v) => _matches(v, filter))
        .where(
          (BabyBudgetView v) =>
              q.isEmpty ||
              LedgerText.fold(
                <String>[
                  v.name,
                  v.budget.note ?? '',
                  for (final BabyCategory c in v.categories) c.name,
                ].join(' '),
              ).contains(q),
        )
        .toList();
    _order(budgets);

    return <Widget>[
      ..._summaries(l, f, book, withCode),
      if (book.defects.isNotEmpty) _defects(l, book),
      LumeToolSection(
        spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
        child: Semantics(
          label: l.babyFilterLabel,
          container: true,
          child: LumeFilterBar(
            key: LumeBabyBudgetTool.filterKey,
            gutters: false,
            children: <Widget>[
              for (final (BabyFilter v, String label) in <(BabyFilter, String)>[
                (BabyFilter.inUse, l.babyFilterInUse),
                (BabyFilter.notStarted, l.babyFilterNotStarted),
                (BabyFilter.archived, l.babyFilterArchived),
                (BabyFilter.all, l.commonAll),
              ])
                LumeFilterChip(
                  key: LumeBabyBudgetTool.filterChip(v),
                  label: label,
                  // Without the reader's day, in use and not started
                  // cannot be told apart, so neither is counted.
                  count:
                      today == null &&
                          (v == BabyFilter.inUse || v == BabyFilter.notStarted)
                      ? null
                      : book.budgets
                            .where((BabyBudgetView x) => _matches(x, v))
                            .length,
                  selected: filter == v,
                  onTap: () => setState(() => _write('filter', v.name)),
                ),
            ],
          ),
        ),
      ),
      LumeToolSection(
        spaceAbove: LumeToolSection.tightGap,
        child: LumeSearchField(
          key: LumeBabyBudgetTool.searchKey,
          controller: _query,
          focusNode: _searchFocus,
          placeholder: l.babySearch,
          semanticLabel: l.babySearch,
          onChanged: (String v) => setState(() => _write('q', v)),
          onClear: () => setState(() {
            _query.clear();
            _write('q', '');
          }),
        ),
      ),
      LumeToolSection(
        spaceAbove: LumeToolSection.tightGap,
        child: LumeSortBar(
          key: LumeBabyBudgetTool.sortKey,
          label: l.commonSort,
          value: _sort.name,
          direction: _descending
              ? LumeSortDirection.descending
              : LumeSortDirection.ascending,
          items: <LumeChoice>[
            LumeChoice(value: BabySort.recent.name, label: l.babySortRecent),
            LumeChoice(value: BabySort.name.name, label: l.babySortName),
            LumeChoice(value: BabySort.spend.name, label: l.babySortSpend),
          ],
          onChanged: (String v, LumeSortDirection d) => setState(() {
            _write('sort', v);
            _write('dir', d == LumeSortDirection.descending ? 'desc' : 'asc');
          }),
        ),
      ),
      LumeToolSection(
        title: l.babyBudgets,
        link: l.babyAdd,
        onLinkTap: () => _addBudget(today),
        child: budgets.isEmpty
            ? LumeToolState(
                key: LumeBabyBudgetTool.noMatchKey,
                icon: LumeIcons.heart,
                title: l.babyNoMatch,
                text: l.babyNoMatchText,
                action: LumeButton(
                  label: l.babyShowAll,
                  icon: LumeIcons.refresh,
                  onPressed: () => setState(() {
                    _write('filter', BabyFilter.all.name);
                    _query.clear();
                    _write('q', '');
                  }),
                ),
              )
            : LumeRows(
                key: LumeBabyBudgetTool.listKey,
                children: <Widget>[
                  for (final BabyBudgetView v in budgets)
                    _budgetRow(context, l, f, v, withCode),
                ],
              ),
      ),
      LumeToolSection(
        child: LumeButtonRow(
          children: <Widget>[
            LumeButton.accent(
              key: LumeBabyBudgetTool.addKey,
              label: l.babyAdd,
              icon: LumeIcons.plus,
              onPressed: () => _addBudget(today),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _defects(AppLocalizations l, BabyBudgetBook book) => LumeToolSection(
    child: LumeNotice(
      key: LumeBabyBudgetTool.defectsKey,
      kind: LumeNoticeKind.warning,
      title: l.babyNeedsAttention,
      text: l.babyDefects(book.defects.length),
    ),
  );

  /// One summary per currency, each the whole tool whatever is filtered —
  /// the reader's own currency first.
  List<Widget> _summaries(
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetBook book,
    bool withCode,
  ) {
    final LumeCurrency? mine = _currency();
    final List<BabyBudgetSummary> sums = <BabyBudgetSummary>[...book.summaries]
      ..sort(
        (BabyBudgetSummary a, BabyBudgetSummary b) => a.currency == mine
            ? -1
            : b.currency == mine
            ? 1
            : a.currency.compareTo(b.currency),
      );
    return <Widget>[
      for (final (int i, BabyBudgetSummary s) in sums.indexed)
        LumeToolSection(
          title: sums.length > 1
              ? l.babySummaryCurrency(s.currency.code)
              : null,
          child: LumeSummaryCard(
            key: i == 0 ? LumeBabyBudgetTool.summaryKey : null,
            kicker: l.babyThisMonth,
            // Without the reader's day there is no month, and nothing
            // stands in for one (§8).
            value: s.thisMonth == null
                ? l.babyDayUnknown
                : f.amount(s.thisMonth!, compact: true, withCode: withCode),
            caption: l.babyBudgetCount(s.budgets),
            stats: <LumeStat>[
              LumeStat(
                value: f.amount(
                  s.spentToDate,
                  compact: true,
                  withCode: withCode,
                ),
                label: l.babySpentToDate,
              ),
              LumeStat(
                value: f.amount(
                  s.plannedTotal,
                  compact: true,
                  withCode: withCode,
                ),
                label: l.babyPlannedTotal,
              ),
            ],
          ),
        ),
    ];
  }

  void _order(List<BabyBudgetView> budgets) {
    int byName(BabyBudgetView a, BabyBudgetView b) {
      final int n = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return n != 0 ? n : a.id.compareTo(b.id);
    }

    final int Function(BabyBudgetView, BabyBudgetView) compare =
        switch (_sort) {
          BabySort.name => byName,
          BabySort.recent => (BabyBudgetView a, BabyBudgetView b) {
            final int c = a.lastActivity.compareTo(b.lastActivity);
            return c != 0 ? c : byName(a, b);
          },
          BabySort.spend => (BabyBudgetView a, BabyBudgetView b) {
            final int c = a.currency.compareTo(b.currency);
            if (c != 0) return c;
            final LumeMoney? x = a.thisMonth;
            final LumeMoney? y = b.thisMonth;
            if (x == null || y == null) {
              return x == null ? (y == null ? byName(a, b) : -1) : 1;
            }
            final int m = x.compareTo(y);
            return m != 0 ? m : byName(a, b);
          },
        };
    budgets.sort(
      _descending
          ? (BabyBudgetView a, BabyBudgetView b) => compare(b, a)
          : compare,
    );
  }

  Widget _budgetRow(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetView v,
    bool withCode,
  ) {
    final LumeColors lume = context.lume;
    final int? ratio = v.ratio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LumeRichRow(
          key: LumeBabyBudgetTool.row(v.id.value),
          icon: LumeIcons.heart,
          iconTone: lume.tintAccent,
          iconInk: lume.accent,
          title: v.name,
          subtitle: v.categories.isEmpty
              ? null
              : v.categories.map((BabyCategory c) => c.name).join(' · '),
          meta: <String>[
            BabyBudgetText.status(l, v.status),
            if (v.budget.archivedOn case final LumeDate on)
              l.babyArchivedOn(BabyBudgetText.dateShort(f, on, today: v.today))
            else if (v.status == BabyBudgetStatus.notStarted)
              l.babyStartedOn(
                BabyBudgetText.dateShort(f, v.budget.startedOn, today: v.today),
              ),
          ],
          badge: v.damaged
              ? LumeBadge(label: l.babyNeedsAttention, tone: LumeBadgeTone.info)
              : v.status == BabyBudgetStatus.archived
              ? LumeBadge(label: l.babyFilterArchived, tone: LumeBadgeTone.off)
              : v.overBy != null
              ? LumeBadge(
                  label: l.babyOverBy(
                    f.amount(v.overBy!, compact: true, withCode: withCode),
                  ),
                  tone: LumeBadgeTone.late_,
                )
              : null,
          value: v.thisMonth == null
              ? l.babyDayUnknown
              : f.amount(v.thisMonth!, compact: true, withCode: withCode),
          valueSub: l.babyThisMonth,
          chevron: true,
          onTap: () => _go(_View.budget, budget: v.id),
        ),
        if (ratio != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 10),
            child: LumeProgressBar(
              // The bar fills; the caption says the true figure, which
              // may be over 100% (D-B2).
              value: (ratio / 100).clamp(0.0, 1.0),
              label: v.name,
              valueText: l.babyOfPlan(f.percent(ratio, decimals: 0)),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------- budget

  (String?, List<Widget>, bool) _budgetScreen(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetBook book,
    LumeDate? today,
    bool withCode,
  ) {
    final BabyBudgetView? v = _budget == null ? null : book.budget(_budget!);
    if (v == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _go(_View.list));
      return (null, const <Widget>[], true);
    }
    final bool open = !v.damaged && !v.budget.archived;
    final List<BabySpend> month = _spendsIn(v, today);

    return (
      v.name,
      <Widget>[
        const KeyedSubtree(
          key: LumeBabyBudgetTool.budgetKey,
          child: SizedBox(),
        ),
        if (v.damaged)
          LumeToolSection(
            child: LumeNotice(
              key: LumeBabyBudgetTool.damagedKey,
              kind: LumeNoticeKind.warning,
              title: l.babyNeedsAttention,
              text: l.babyDamagedText,
            ),
          ),
        // A budget that has not started says so, instead of showing a
        // month of nothing (correction 3).
        if (v.status == BabyBudgetStatus.notStarted)
          LumeToolSection(
            child: LumeNotice(
              key: LumeBabyBudgetTool.notStartedKey,
              kind: LumeNoticeKind.info,
              title: l.babyNotStartedTitle,
              text: l.babyNotStartedText(
                BabyBudgetText.date(f, v.budget.startedOn, today: today),
              ),
            ),
          ),
        if (v.budget.archivedOn case final LumeDate on)
          LumeToolSection(
            child: LumeNotice(
              key: LumeBabyBudgetTool.archivedKey,
              kind: LumeNoticeKind.info,
              title: l.babyFilterArchived,
              text: l.babyArchivedOn(BabyBudgetText.date(f, on, today: today)),
            ),
          ),
        if (today == null)
          LumeToolSection(
            child: LumeNotice(
              key: LumeBabyBudgetTool.dayUnknownKey,
              kind: LumeNoticeKind.info,
              title: l.recZoneUnknownTitle,
              text: l.babyDayUnknownText,
            ),
          ),
        _summary(context, l, f, v, withCode),
        LumeToolSection(
          child: LumeButtonRow(
            expand: false,
            children: <Widget>[
              if (open)
                LumeButton.accent(
                  key: LumeBabyBudgetTool.spendKey,
                  label: l.babyRecordSpend,
                  icon: LumeIcons.plus,
                  onPressed: () => _addSpend(v, today, planned: false),
                ),
              if (open)
                LumeButton(
                  key: LumeBabyBudgetTool.planKey,
                  label: l.babyPlanPurchase,
                  icon: LumeIcons.checkCircle,
                  onPressed: () => _addSpend(v, today, planned: true),
                ),
              if (!v.damaged)
                LumeButton(
                  key: LumeBabyBudgetTool.editKey,
                  label: l.babyEditBudget,
                  icon: LumeIcons.note,
                  onPressed: () => _editBudget(v),
                ),
              if (!v.damaged)
                LumeButton(
                  key: v.budget.archived
                      ? LumeBabyBudgetTool.unarchiveKey
                      : LumeBabyBudgetTool.archiveKey,
                  label: v.budget.archived ? l.babyUnarchive : l.babyArchive,
                  icon: v.budget.archived ? LumeIcons.refresh : LumeIcons.x,
                  onPressed: () => unawaited(_archive(l, v, today)),
                ),
              LumeButton.dangerGhost(
                key: LumeBabyBudgetTool.deleteKey,
                label: l.babyDeleteBudget,
                icon: LumeIcons.trash,
                onPressed: () => unawaited(_delete(l, v)),
              ),
            ],
          ),
        ),
        ?_donut(context, l, f, v, withCode),
        ?_chart(l, f, v, withCode),
        LumeToolSection(
          title: l.babyComingUp,
          child: v.comingUp.isEmpty
              ? Text(l.babyNothingPlanned)
              : LumeRows(
                  key: LumeBabyBudgetTool.comingUpKey,
                  children: <Widget>[
                    for (final BabySpend s in v.comingUp)
                      _plannedRow(l, f, v, s, today, withCode),
                  ],
                ),
        ),
        if (v.oneOff.isNotEmpty)
          LumeToolSection(
            title: l.babyOneOff,
            child: LumeRows(
              key: LumeBabyBudgetTool.oneOffKey,
              children: <Widget>[
                for (final BabySpend s in v.oneOff)
                  _plannedRow(l, f, v, s, today, withCode),
              ],
            ),
          ),
        LumeToolSection(
          title: l.babyCategories,
          link: v.categories.isEmpty ? null : l.babyEditBudget,
          onLinkTap: v.categories.isEmpty ? null : () => _editBudget(v),
          child: v.categories.isEmpty
              ? Text(l.babyNoCategories)
              : LumeRows(
                  key: LumeBabyBudgetTool.categoriesKey,
                  children: <Widget>[
                    for (final BabyCategory c in v.categories)
                      _categoryRow(context, l, f, v, c, withCode),
                  ],
                ),
        ),
        LumeToolSection(
          title: l.babyMonthSpending,
          link: v.recorded.isEmpty ? null : l.commonAll,
          onLinkTap: v.recorded.isEmpty
              ? null
              : () => _go(_View.spending, budget: v.id, month: today),
          child: month.isEmpty
              ? Text(l.babyNothingThisMonth)
              : LumeRows(
                  key: LumeBabyBudgetTool.spendingKey,
                  children: <Widget>[
                    for (final BabySpend s in month.take(8))
                      _spendRow(l, f, v, s, today, withCode),
                  ],
                ),
        ),
      ],
      true,
    );
  }

  /// The reference's summary card, with its ring — but the ratio is the
  /// reader's own plan, not a constant, and there is no ring at all when
  /// there is no plan (defect 1, D-B2).
  Widget _summary(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetView v,
    bool withCode,
  ) {
    final int? ratio = v.ratio;
    final LumeMoney? month = v.thisMonth;
    final LumeMoney? left = v.unallocated;
    final String caption = <String>[
      switch (null) {
        _ when v.status == BabyBudgetStatus.notStarted => l.babyNotStartedTitle,
        _ when v.today == null => l.babyDayUnknown,
        _ when v.plan == null => l.babyNoPlan,
        _ when v.overBy != null => l.babyOverBy(
          f.amount(v.overBy!, withCode: withCode, isolate: true),
        ),
        _ => l.babyOfPlan(f.percent(ratio ?? 0, decimals: 0)),
      },
      // What the plan has left over the categories — but only where the
      // reader actually shared it out. With no category plan at all,
      // "unallocated" would just be the plan again (correction 2).
      if (left != null &&
          left.isPositive &&
          v.categories.any((BabyCategory c) => c.monthlyPlan != null))
        l.babyUnallocated(
          f.amount(left, compact: true, withCode: withCode, isolate: true),
        ),
    ].join(' · ');
    return LumeToolSection(
      child: LumeSummaryCard(
        key: LumeBabyBudgetTool.summaryKey,
        kicker: l.babyThisMonth,
        value: month == null
            ? l.babyDayUnknown
            : f.amount(month, compact: true, withCode: withCode),
        caption: caption,
        aside: ratio == null
            ? null
            : LumeProgressRing(
                value: (ratio / 100).clamp(0.0, 1.0),
                centreValue: f.percent(ratio, decimals: 0),
                centreSub: l.babyPlanLabel,
                label: l.babyPlanLabel,
                valueText: l.babyOfPlan(f.percent(ratio, decimals: 0)),
              ),
        stats: <LumeStat>[
          LumeStat(
            value: f.amount(v.spentToDate, compact: true, withCode: withCode),
            label: l.babySpentToDate,
          ),
          LumeStat(
            value: f.amount(v.plannedTotal, compact: true, withCode: withCode),
            label: l.babyPlannedTotal,
          ),
          if (v.plan case final LumeMoney plan)
            LumeStat(
              value: f.amount(plan, compact: true, withCode: withCode),
              label: l.babyFieldPlan,
            ),
        ],
      ),
    );
  }

  /// "Where it goes". The shares come from the book, by largest
  /// remainder over minor units, so the legend adds to exactly 100
  /// (defect 2, correction 5).
  Widget? _donut(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetView v,
    bool withCode,
  ) {
    final List<BabyCategoryView> slices = v.slices;
    if (slices.isEmpty) return null;
    final LumeMoney month = v.thisMonth!;
    return LumeToolSection(
      title: l.babyWhereItGoes,
      child: LumeCard(
        child: KeyedSubtree(
          key: LumeBabyBudgetTool.donutKey,
          child: LumeDonut(
            centre: f.amount(month, compact: true, withCode: withCode),
            centreSub: l.babyAMonth,
            label: <String>[
              l.babyDonutLabel,
              for (final BabyCategoryView s in slices)
                l.babyChartEntry(
                  BabyBudgetText.slice(l, s),
                  f.amount(s.spent, withCode: withCode),
                ),
            ].join('. '),
            slices: <LumeDonutSlice>[
              for (final BabyCategoryView s in slices)
                LumeDonutSlice(
                  label: BabyBudgetText.slice(l, s),
                  value: s.spent.minor.toDouble(),
                  color: BabyBudgetText.colour(context, s),
                  // The exact share, worked out from minor units — never
                  // a percentage read back off a rounded draw. The
                  // amount itself is on the category's own row below,
                  // because a key holds one short figure at any text
                  // size.
                  display: f.percent(s.share, decimals: 0),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Six months". The months end with the reader's own, are labelled in
  /// their language, and carry the budget's currency — not the
  /// reference's hard-coded English and raw USD (defects 3, 4, 5).
  Widget? _chart(
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetView v,
    bool withCode,
  ) {
    final List<BabyMonth>? trend = v.trend;
    if (trend == null || trend.length < 2) return null;
    if (trend.every((BabyMonth m) => m.spent.isZero)) return null;
    final List<String> amounts = <String>[
      for (final BabyMonth m in trend)
        f.amount(m.spent, compact: true, withCode: withCode),
    ];
    return LumeToolSection(
      title: l.babySixMonths,
      child: LumeCard(
        child: KeyedSubtree(
          key: LumeBabyBudgetTool.chartKey,
          child: LumeBarChart(
            values: <double>[
              for (final BabyMonth m in trend) m.spent.minor / v.currency.scale,
            ],
            labels: <String>[
              for (final BabyMonth m in trend)
                BabyBudgetText.monthShort(f, m.month),
            ],
            valueLabels: amounts,
            highlight: trend.length - 1,
            label: <String>[
              l.babySixMonths,
              for (final (int i, BabyMonth m) in trend.indexed)
                l.babyChartEntry(
                  BabyBudgetText.month(f, m.month, today: v.today),
                  amounts[i],
                ),
            ].join('. '),
            caption: Text(l.babySixMonthsCap(v.currency.code)),
          ),
        ),
      ),
    );
  }

  Widget _plannedRow(
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetView v,
    BabySpend s,
    LumeDate? today,
    bool withCode,
  ) => LumeRichRow(
    key: LumeBabyBudgetTool.entry(s.id.value),
    icon: LumeIcons.checkCircle,
    title: s.label ?? BabyBudgetText.slice(l, _sliceOf(l, v, s)),
    subtitle: s.label == null
        ? null
        : (v.categoryOf(s.categoryId)?.name ?? l.babyUncategorised),
    meta: <String>[
      if (s.expectedOn case final LumeDate on)
        l.babyExpectedOn(BabyBudgetText.dateShort(f, on, today: today)),
    ],
    badge: LumeBadge(
      label: BabyBudgetText.planned(l, v.statusOf(s)),
      tone: BabyBudgetText.plannedTone(v.statusOf(s)),
    ),
    value: f.amount(s.amount, compact: true, withCode: withCode),
    valueSub: l.babyPlannedBadge,
    chevron: true,
    onTap: () => unawaited(_spendActions(l, f, v, s, today, withCode)),
  );

  Widget _spendRow(
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetView v,
    BabySpend s,
    LumeDate? today,
    bool withCode,
  ) => LumeCompactRow(
    key: LumeBabyBudgetTool.entry(s.id.value),
    icon: s.voided ? LumeIcons.x : LumeIcons.checkCircle,
    label: s.label ?? (v.categoryOf(s.categoryId)?.name ?? l.babyUncategorised),
    subtitle: <String>[
      if (s.label != null)
        v.categoryOf(s.categoryId)?.name ?? l.babyUncategorised,
      if (s.spentOn case final LumeDate on)
        l.babySpentOn(BabyBudgetText.dateShort(f, on, today: today)),
      if (s.voided) l.babyVoidedBadge,
    ].join(' · '),
    value: f.amount(s.amount, compact: true, withCode: withCode),
    onTap: () => unawaited(_spendActions(l, f, v, s, today, withCode)),
  );

  BabyCategoryView _sliceOf(
    AppLocalizations l,
    BabyBudgetView v,
    BabySpend s,
  ) => BabyCategoryView(
    category: v.categoryOf(s.categoryId),
    spent: s.amount,
    share: 0,
    count: 1,
  );

  Widget _categoryRow(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetView v,
    BabyCategory c,
    bool withCode,
  ) {
    final LumeColors lume = context.lume;
    final BabyCategoryView? slice = v.slices
        .where((BabyCategoryView s) => s.category?.id == c.id)
        .firstOrNull;
    final LumeMoney spent = slice?.spent ?? LumeMoney.zero(v.currency);
    return LumeRichRow(
      key: LumeBabyBudgetTool.categoryRow(c.id.value),
      icon: LumeIcons.cart,
      iconTone: lume.tone(
        BabyBudgetText.palette(context)[c.colour % kBabyColourCount],
      ),
      iconInk: BabyBudgetText.palette(context)[c.colour % kBabyColourCount],
      title: c.name,
      meta: <String>[
        if (slice != null)
          l.babyShareOfMonth(f.percent(slice.share, decimals: 0)),
        if (c.monthlyPlan case final LumeMoney plan)
          '${l.babyCategoryPlan}: '
              '${f.amount(plan, compact: true, withCode: withCode)}',
      ],
      value: f.amount(spent, compact: true, withCode: withCode),
      valueSub: l.babyThisMonth,
      chevron: true,
      onTap: () => _go(_View.category, budget: v.id, category: c.id),
    );
  }

  /// The spends of one month, newest first. Without the reader's day
  /// there is no month, so nothing is listed as one.
  List<BabySpend> _spendsIn(BabyBudgetView v, LumeDate? month) {
    if (month == null) return const <BabySpend>[];
    return <BabySpend>[
      for (final BabySpend s in v.spends)
        if (!s.planned && s.spentOn != null && lumeSameMonth(s.spentOn!, month))
          s,
    ];
  }

  // -------------------------------------------------------------- category

  (String?, List<Widget>, bool) _categoryScreen(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetBook book,
    bool withCode,
  ) {
    final BabyBudgetView? v = _budget == null ? null : book.budget(_budget!);
    final BabyCategory? c = v == null || _category == null
        ? null
        : v.categoryOf(_category!);
    if (v == null || c == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _go(v == null ? _View.list : _View.budget),
      );
      return (null, const <Widget>[], true);
    }
    final BabyCategoryView? slice = v.slices
        .where((BabyCategoryView s) => s.category?.id == c.id)
        .firstOrNull;
    final List<BabySpend> mine = <BabySpend>[
      for (final BabySpend s in v.spends)
        if (s.categoryId == c.id) s,
    ];
    final LumeMoney all = LumeMoney.total(<LumeMoney>[
      for (final BabySpend s in mine)
        if (s.counts) s.amount,
    ], v.currency);
    return (
      c.name,
      <Widget>[
        const KeyedSubtree(
          key: LumeBabyBudgetTool.categoryKey,
          child: SizedBox(),
        ),
        LumeToolSection(
          child: LumeSummaryCard(
            kicker: l.babyThisMonth,
            value: f.amount(
              slice?.spent ?? LumeMoney.zero(v.currency),
              compact: true,
              withCode: withCode,
            ),
            caption: slice == null
                ? l.babyNothingThisMonth
                : l.babyShareOfMonth(f.percent(slice.share, decimals: 0)),
            stats: <LumeStat>[
              LumeStat(
                value: f.amount(all, compact: true, withCode: withCode),
                label: l.babySpentToDate,
              ),
              LumeStat(
                value: l.babySpendCount(
                  mine.where((BabySpend s) => s.counts).length,
                ),
                label: l.babyCategorySpending,
              ),
              if (c.monthlyPlan case final LumeMoney plan)
                LumeStat(
                  value: f.amount(plan, compact: true, withCode: withCode),
                  label: l.babyCategoryPlan,
                ),
            ],
          ),
        ),
        if (!v.damaged && !v.budget.archived)
          LumeToolSection(
            child: LumeButtonRow(
              expand: false,
              children: <Widget>[
                LumeButton(
                  label: l.babyEditCategoryTitle,
                  icon: LumeIcons.note,
                  onPressed: () => _editBudget(v),
                ),
                LumeButton.dangerGhost(
                  label: l.babyDeleteCategory,
                  icon: LumeIcons.trash,
                  onPressed: () => unawaited(_deleteCategory(l, v, c)),
                ),
              ],
            ),
          ),
        LumeToolSection(
          title: l.babyCategorySpending,
          child: mine.isEmpty
              ? Text(l.babyNothingThisMonth)
              : LumeRows(
                  children: <Widget>[
                    for (final BabySpend s in mine)
                      s.planned
                          ? _plannedRow(l, f, v, s, v.today, withCode)
                          : _spendRow(l, f, v, s, v.today, withCode),
                  ],
                ),
        ),
      ],
      true,
    );
  }

  // -------------------------------------------------------------- spending

  (String?, List<Widget>, bool) _spendingScreen(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetBook book,
    LumeDate? today,
    bool withCode,
  ) {
    final BabyBudgetView? v = _budget == null ? null : book.budget(_budget!);
    if (v == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _go(_View.list));
      return (null, const <Widget>[], true);
    }
    // Every month the budget has covered, newest first, and never one
    // before it started (correction 3).
    final List<LumeDate> months = <LumeDate>[];
    for (final BabySpend s in v.recorded) {
      final LumeDate? on = s.spentOn;
      if (on == null) continue;
      final LumeDate m = lumeMonthStart(on, 0);
      if (!months.any((LumeDate x) => lumeSameMonth(x, m))) months.add(m);
    }
    final LumeDate? chosen = _month == null
        ? null
        : months.where((LumeDate m) => lumeSameMonth(m, _month!)).firstOrNull;
    final List<BabySpend> shown = chosen == null
        ? v.recorded
        : _spendsIn(v, chosen);
    return (
      v.name,
      <Widget>[
        LumeToolSection(
          child: LumeSortBar(
            key: LumeBabyBudgetTool.monthKey,
            label: l.babyMonthLabel,
            value: chosen == null ? 'all' : chosen.toIso(),
            direction: LumeSortDirection.descending,
            items: <LumeChoice>[
              LumeChoice(value: 'all', label: l.babyEveryMonth),
              for (final LumeDate m in months)
                LumeChoice(
                  value: m.toIso(),
                  label: BabyBudgetText.month(f, m, today: today),
                ),
            ],
            onChanged: (String value, LumeSortDirection _) => setState(() {
              _month = value == 'all' ? null : LumeDate.tryParse(value);
            }),
          ),
        ),
        LumeToolSection(
          title: l.babyMonthSpending,
          child: shown.isEmpty
              ? Text(l.babyNothingThisMonth)
              : LumeRows(
                  key: LumeBabyBudgetTool.spendingKey,
                  children: <Widget>[
                    for (final BabySpend s in shown)
                      _spendRow(l, f, v, s, today, withCode),
                  ],
                ),
        ),
      ],
      true,
    );
  }

  // ------------------------------------------------------------------ form

  List<Widget> _budgetForm(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
  ) {
    final _BudgetDraft d = _draft!;
    final bool locked = d.locked;
    Widget? error(String key) => d.errors[key] == null
        ? null
        : Semantics(
            liveRegion: true,
            child: Text(
              d.errors[key]!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );

    return <Widget>[
      if (locked)
        LumeToolSection(
          child: LumeNotice(
            key: LumeBabyBudgetTool.lockedKey,
            kind: LumeNoticeKind.info,
            title: l.babyLockedTitle,
            text: l.babyLockedText(d.currency?.code ?? ''),
          ),
        ),
      LumeToolSection(
        child: LumeFormCard(
          key: LumeBabyBudgetTool.formKey,
          children: <Widget>[
            LumeFormField(
              key: LumeBabyBudgetTool.nameField,
              label: l.babyFieldName,
              hint: l.babyNameHint,
              controller: d.name,
              required: true,
              error: d.errors['name'],
              autofocus: d.id == null,
            ),
            LumeFormPicker(
              key: LumeBabyBudgetTool.currencyField,
              label: l.babyFieldCurrency,
              value: d.currency?.code ?? '—',
              onTap: locked
                  ? null
                  : () => unawaited(
                      _pick<LumeCurrency>(
                        l.babyFieldCurrency,
                        <(LumeCurrency, String)>[
                          for (final LumeCurrency c in _currencyChoices(d))
                            (c, c.code),
                        ],
                        d.currency,
                        (LumeCurrency v) => d.currency = v,
                      ),
                    ),
            ),
            ?error('currency'),
            LumeFormField(
              key: LumeBabyBudgetTool.planField,
              label: l.babyFieldPlan,
              optionalLabel: l.commonOptional,
              hint: l.babyPlanHint,
              controller: d.plan,
              kind: LumeFieldKind.money,
              prefix: d.currency?.code,
              error: d.errors['plan'],
              onChanged: (_) => setState(() {}),
            ),
            LumeFormPicker(
              key: LumeBabyBudgetTool.startedField,
              label: l.babyFieldStartedOn,
              value: d.startedOn == null
                  ? l.babyErrDate
                  : BabyBudgetText.date(f, d.startedOn!),
              onTap: () => unawaited(
                _date(d.startedOn, (LumeDate v) => d.startedOn = v),
              ),
            ),
            ?error('startedOn'),
            Text(l.babyStartHint),
            LumeFormField(
              key: LumeBabyBudgetTool.noteField,
              label: l.babyFieldNote,
              optionalLabel: l.commonOptional,
              controller: d.note,
              kind: LumeFieldKind.multiline,
              error: d.errors['note'],
            ),
          ],
        ),
      ),
      LumeToolSection(
        title: l.babyFieldCategories,
        child: Column(
          key: LumeBabyBudgetTool.categoriesField,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(l.babyCategoriesHint),
            ),
            for (final (int i, _CategoryDraft c) in d.categories.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    LumeFormField(
                      key: LumeBabyBudgetTool.categoryName(i),
                      label: l.babyCategoryName(f.integer(i + 1)),
                      controller: c.name,
                      autofocus: false,
                    ),
                    // A category may take a share of the plan only while
                    // the budget has one (correction 2).
                    if (d.plan.text.trim().isNotEmpty)
                      LumeFormField(
                        key: LumeBabyBudgetTool.categoryPlan(i),
                        label: l.babyCategoryPlan,
                        optionalLabel: l.commonOptional,
                        controller: c.plan,
                        kind: LumeFieldKind.money,
                        prefix: d.currency?.code,
                      ),
                    Row(
                      children: <Widget>[
                        LumeTextButton(
                          key: LumeBabyBudgetTool.categoryUp(i),
                          label: l.babyMoveUp,
                          onPressed: i == 0
                              ? null
                              : () => setState(() {
                                  final _CategoryDraft x = d.categories
                                      .removeAt(i);
                                  d.categories.insert(i - 1, x);
                                }),
                        ),
                        LumeTextButton(
                          key: LumeBabyBudgetTool.categoryDown(i),
                          label: l.babyMoveDown,
                          onPressed: i == d.categories.length - 1
                              ? null
                              : () => setState(() {
                                  final _CategoryDraft x = d.categories
                                      .removeAt(i);
                                  d.categories.insert(i + 1, x);
                                }),
                        ),
                        const Spacer(),
                        LumeTextButton(
                          key: LumeBabyBudgetTool.categoryRemove(i),
                          label: l.babyRemoveCategory,
                          onPressed: d.categories.length <= 1
                              ? null
                              : () => setState(() {
                                  final _CategoryDraft x = d.categories
                                      .removeAt(i);
                                  x.dispose();
                                }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ?error('categories'),
            LumeButton(
              key: LumeBabyBudgetTool.addCategoryKey,
              label: l.babyAddCategory,
              icon: LumeIcons.plus,
              onPressed: d.categories.length >= kBabyCategoryMax
                  ? null
                  : () => setState(() => d.categories.add(_CategoryDraft())),
            ),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeSubmitBar(
          saveLabel: l.actionSave,
          cancelLabel: l.actionCancel,
          onSave: () => unawaited(_saveBudget(l)),
          onCancel: () => unawaited(_back()),
        ),
      ),
    ];
  }

  (String?, List<Widget>, bool) _spendFormScreen(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetBook book,
    LumeDate? today,
  ) {
    final _SpendDraft? s = _spend;
    final BabyBudgetView? v = s == null ? null : book.budget(s.budget);
    if (s == null || v == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _go(_View.list));
      return (null, const <Widget>[], true);
    }
    final String title = s.id == null
        ? (s.planned ? l.babyPlanTitle : l.babySpendTitle)
        : (s.planned ? l.babyEditPlanTitle : l.babyEditSpendTitle);
    return (
      title,
      <Widget>[
        LumeToolSection(
          child: LumeFormCard(
            key: LumeBabyBudgetTool.spendFormKey,
            children: <Widget>[
              LumeFormField(
                key: LumeBabyBudgetTool.amountField,
                label: l.babyFieldAmount,
                controller: s.amount,
                kind: LumeFieldKind.money,
                prefix: v.currency.code,
                required: true,
                error: s.errors['amount'],
                autofocus: s.id == null,
              ),
              LumeFormPicker(
                key: LumeBabyBudgetTool.categoryField,
                label: l.babyFieldCategory,
                value: v.categoryOf(s.categoryId)?.name ?? l.babyUncategorised,
                onTap: v.categories.isEmpty
                    ? null
                    : () => unawaited(
                        _pick<String>(
                          l.babyFieldCategory,
                          <(String, String)>[
                            ('', l.babyUncategorised),
                            for (final BabyCategory c in v.categories)
                              (c.id.value, c.name),
                          ],
                          s.categoryId?.value ?? '',
                          (String value) => s.categoryId = value.isEmpty
                              ? null
                              : LumeRecordId.tryParse(value),
                        ),
                      ),
              ),
              LumeFormField(
                key: LumeBabyBudgetTool.labelField,
                label: l.babyFieldLabel,
                optionalLabel: l.commonOptional,
                controller: s.label,
                error: s.errors['label'],
              ),
              LumeFormPicker(
                key: LumeBabyBudgetTool.dayField,
                label: s.planned ? l.babyFieldExpected : l.babyFieldDay,
                value: s.day == null
                    ? (s.planned ? l.babyNoDate : l.babyErrDate)
                    : BabyBudgetText.date(f, s.day!, today: today),
                onTap: () => unawaited(_spendDay(l, f, s, today)),
              ),
              ?(s.errors['day'] == null
                  ? null
                  : Semantics(
                      liveRegion: true,
                      child: Text(
                        s.errors['day']!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    )),
            ],
          ),
        ),
        LumeToolSection(
          child: LumeSubmitBar(
            saveLabel: l.actionSave,
            cancelLabel: l.actionCancel,
            onSave: () => unawaited(_saveSpend(l, v)),
            onCancel: () => unawaited(_back()),
          ),
        ),
      ],
      true,
    );
  }

  /// A spend's day, or a planned purchase's expected day — which may be
  /// in the future, and may be dropped altogether (D-B4, D-B5).
  Future<void> _spendDay(
    AppLocalizations l,
    LumeFormatting f,
    _SpendDraft s,
    LumeDate? today,
  ) async {
    final BabyDateChoice? chosen = await BabyDateSheet.show(
      context,
      title: s.planned ? l.babyFieldExpected : l.babyFieldDay,
      label: s.planned ? l.babyFieldExpected : l.babyFieldDay,
      action: l.actionSave,
      initial: s.day ?? (s.planned ? null : today),
      today: today,
      future: s.planned,
      clearLabel: s.planned ? l.babyClearDate : null,
      dateText: (LumeDate d) => BabyBudgetText.date(f, d, today: today),
    );
    if (chosen == null || !mounted) return;
    setState(() => s.day = chosen.day);
  }

  /// The reader's currency, those already in use, then every other one a
  /// new budget may use; a budget's own withdrawn currency only for that
  /// budget.
  List<LumeCurrency> _currencyChoices(_BudgetDraft d) {
    final LumeCurrency? mine = _currency();
    final LumeCurrency? own = d.id == null ? null : d.currency;
    final BabyBudgetBook book = _repo.view().book(null);
    final Set<LumeCurrency> used = <LumeCurrency>{
      for (final LumeCurrency c in book.currencies)
        if (c.active) c,
    };
    return <LumeCurrency>[
      ...LumeCurrencyPolicy.historical(<LumeCurrency>[?own]),
      ?mine,
      for (final LumeCurrency c in used.toList()..sort())
        if (c != mine) c,
      for (final LumeCurrency c in LumeCurrency.offered)
        if (c != mine && !used.contains(c)) c,
    ];
  }

  Future<void> _pick<T>(
    String label,
    List<(T, String)> options,
    T? current,
    void Function(T) set,
  ) async {
    final T? chosen = await showLumeSheet<T>(
      context: context,
      barrierLabel: label,
      child: Builder(
        builder: (BuildContext sheet) => LumeSheet(
          title: label,
          tall: options.length > 8,
          child: SingleChildScrollView(
            primary: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final (T value, String text) in options)
                  LumeRadioRow(
                    label: text,
                    selected: value == current,
                    onTap: () => Navigator.of(sheet).pop(value),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (chosen != null && mounted) setState(() => set(chosen));
  }

  Future<void> _date(LumeDate? initial, void Function(LumeDate) set) async {
    final DateTime base =
        initial?.toCalendarDateTime() ?? LumeClockScope.of(context).now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(base.year - 30),
      lastDate: DateTime(base.year + 30),
    );
    if (picked != null && mounted) {
      setState(() => set(LumeDate.ofWallClock(picked)));
    }
  }
}

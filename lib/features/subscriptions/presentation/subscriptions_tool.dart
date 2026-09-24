/// Subscriptions — `tools/personal/subs.tool.js`, as a real record-backed
/// tool (`SUBSCRIPTIONS_PROPOSAL.md`).
///
/// The reference's composition, in its order: the summary card, search,
/// sort, the subscription list, the category donut, the "Coming up"
/// timeline, then Add. What it only drew, this does: subscriptions are the
/// reader's own records (nothing seeded), renewal dates are computed from
/// one stored anchor and cycle rather than two independent hand-typed
/// literals, and a subscription can be added, edited, cancelled,
/// reactivated and deleted — the reference has no CRUD at all, not even a
/// stub. It is sensitive: the frame shows its privacy note and nothing
/// here reaches Home (D-S1). It sends no notification (D-S8).
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
import '../../../core/localization/lume_initials.dart';
import '../../../core/navigation/lume_tool_frame.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
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
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/subscriptions_providers.dart';
import '../domain/subscriptions_book.dart';
import '../domain/subscriptions_failure.dart';
import '../domain/subscriptions_model.dart';
import '../domain/subscriptions_repository.dart';
import 'subscriptions_sheets.dart';
import 'subscriptions_text.dart';

enum SubscriptionsFilter { active, cancelled, all }

enum SubscriptionsSort { renewal, amount, name }

enum _View { list, subscription, form }

abstract final class LumeSubscriptionsTool {
  static const String id = 'subs';

  static const Key summaryKey = ValueKey<String>('subs.summary');
  static const Key searchKey = ValueKey<String>('subs.search');
  static const Key filterKey = ValueKey<String>('subs.filter');
  static const Key sortKey = ValueKey<String>('subs.sort');
  static const Key listKey = ValueKey<String>('subs.list');
  static const Key chartKey = ValueKey<String>('subs.chart');
  static const Key timelineKey = ValueKey<String>('subs.timeline');
  static const Key emptyKey = ValueKey<String>('subs.empty');
  static const Key noMatchKey = ValueKey<String>('subs.noMatch');
  static const Key addKey = ValueKey<String>('subs.add');
  static const Key subscriptionKey = ValueKey<String>('subs.subscription');
  static const Key editKey = ValueKey<String>('subs.edit');
  static const Key cancelKey = ValueKey<String>('subs.cancel');
  static const Key reactivateKey = ValueKey<String>('subs.reactivate');
  static const Key deleteKey = ValueKey<String>('subs.delete');
  static const Key formKey = ValueKey<String>('subs.form');
  static const Key saveKey = ValueKey<String>('subs.save');
  static const Key nameField = ValueKey<String>('subs.field.name');
  static const Key categoryField = ValueKey<String>('subs.field.category');
  static const Key amountField = ValueKey<String>('subs.field.amount');
  static const Key cycleField = ValueKey<String>('subs.field.cycle');
  static const Key customDaysField = ValueKey<String>('subs.field.customDays');
  static const Key startedOnField = ValueKey<String>('subs.field.startedOn');
  static Key filterChip(SubscriptionsFilter f) => ValueKey<String>('subs.filter.${f.name}');
  static Key row(String id) => ValueKey<String>('subs.row.$id');

  static Widget open(LumeToolRequest request) => SubscriptionsTool(request: request);
}

class SubscriptionsTool extends ConsumerStatefulWidget {
  const SubscriptionsTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<SubscriptionsTool> createState() => _SubscriptionsToolState();
}

class _SubscriptionDraft {
  _SubscriptionDraft({
    this.id,
    this.version,
    required this.currency,
    this.cycle = SubscriptionCycle.monthly,
    this.startedOn,
    this.tone = SubscriptionTone.sky,
    String name = '',
    String category = '',
    String amount = '',
    String customDays = '',
  }) : name = TextEditingController(text: name),
       category = TextEditingController(text: category),
       amount = TextEditingController(text: amount),
       customDays = TextEditingController(text: customDays) {
    _initial = _state;
  }

  final LumeRecordId? id;
  final int? version;
  LumeCurrency? currency;
  SubscriptionCycle cycle;
  LumeDate? startedOn;
  SubscriptionTone tone;
  final TextEditingController name;
  final TextEditingController category;
  final TextEditingController amount;
  final TextEditingController customDays;
  final Map<String, String> errors = <String, String>{};
  late final String _initial;

  String get _state => <Object?>[
    name.text,
    category.text,
    amount.text,
    customDays.text,
    cycle.name,
    startedOn?.toIso(),
    currency?.code,
  ].join('\u0000');

  bool get dirty => _state != _initial;

  void dispose() {
    name.dispose();
    category.dispose();
    amount.dispose();
    customDays.dispose();
  }
}

class _SubscriptionsToolState extends ConsumerState<SubscriptionsTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final SubscriptionsRepository _repo = ref.read(subscriptionsRepositoryProvider);
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(text: _read('q') ?? '');
  final FocusNode _searchFocus = FocusNode();
  final GlobalKey _body = GlobalKey();

  _View _view = _View.list;
  LumeRecordId? _subscription;
  _SubscriptionDraft? _draft;
  bool _linked = false;

  String get _id => widget.request.feature.id;
  String? _read(String key) => _session.read(_id, key);
  void _write(String key, String value) => _session.write(_id, key, value);

  SubscriptionsFilter get _filter => SubscriptionsFilter.values.firstWhere(
    (SubscriptionsFilter f) => f.name == _read('filter'),
    orElse: () => SubscriptionsFilter.active,
  );
  SubscriptionsSort get _sort => SubscriptionsSort.values.firstWhere(
    (SubscriptionsSort s) => s.name == _read('sort'),
    orElse: () => SubscriptionsSort.renewal,
  );
  bool get _descending => _read('dir') == 'desc';

  @override
  void initState() {
    super.initState();
    _repo.open();
    _repo.changes.addListener(_changed);
    final LumeRecordId? kept = LumeRecordId.tryParse(_read('sub') ?? '');
    if (kept != null) {
      _subscription = kept;
      _view = _View.subscription;
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
    return SubscriptionsRepository.defaultCurrency(code);
  }

  // ------------------------------------------------------------ navigation

  void _go(_View v, {LumeRecordId? subscription}) {
    final bool moved = v != _view || (subscription != null && subscription != _subscription);
    setState(() {
      _view = v;
      if (subscription != null) _subscription = subscription;
      _write('sub', v == _View.list ? '' : (_subscription?.value ?? ''));
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
      case _View.subscription:
        _go(_View.list);
      case _View.form:
        final _SubscriptionDraft? d = _draft;
        if (d != null && d.dirty && !await _confirmDiscard()) return;
        if (!mounted) return;
        _draft = null;
        d?.dispose();
        _go(d?.id != null ? _View.subscription : _View.list);
    }
  }

  Future<bool> _confirmDiscard() async {
    final AppLocalizations l = AppLocalizations.of(context);
    return await subsDecide(
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
    _draft = _SubscriptionDraft(currency: _currency(), startedOn: today);
    _go(_View.form);
  }

  void _edit(Subscription s) {
    _draft?.dispose();
    _draft = _SubscriptionDraft(
      id: s.id,
      version: s.version,
      currency: s.currency,
      cycle: s.cycle,
      startedOn: s.startedOn,
      tone: s.tone,
      name: s.name,
      category: s.category ?? '',
      amount: s.amount.toDecimalString(),
      customDays: s.customDays?.toString() ?? '',
    );
    _go(_View.form);
  }

  // ---------------------------------------------------------------- writes

  void _failed(AppLocalizations l, SubscriptionsFailure f) {
    _say(switch (f.kind) {
      SubscriptionsFailureKind.conflict ||
      SubscriptionsFailureKind.notFound => l.subsErrConflict,
      SubscriptionsFailureKind.damaged => l.subsErrDamaged,
      SubscriptionsFailureKind.overflow => l.subsErrTooLarge,
      _ => l.subsErrFailed,
    }, tone: LumeToastTone.error);
  }

  void _undoable(AppLocalizations l, String message, SubscriptionsWrite w) => _say(
    message,
    actionLabel: l.recUndo,
    onAction: () {
      final SubscriptionsResult<void> r = _repo.undo(w);
      if (r.failure != null) _failed(l, r.failure!);
    },
  );

  Future<void> _save(AppLocalizations l) async {
    final _SubscriptionDraft d = _draft!;
    final Map<String, String> errors = <String, String>{};
    final intl.NumberFormat nf = intl.NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag().replaceAll('-', '_'),
    );

    final String name = d.name.text.trim();
    if (name.isEmpty) errors['name'] = l.subsErrName;
    if (name.length > kSubscriptionsNameMax) errors['name'] = l.subsErrLong;
    if (d.category.text.trim().length > kSubscriptionsCategoryMax) {
      errors['category'] = l.subsErrLong;
    }
    if (d.currency == null) errors['currency'] = l.subsErrAmount;
    LumeMoney? amount;
    if (d.currency != null) {
      final LedgerParsedAmount p = ledgerParseAmount(
        l,
        d.amount.text,
        d.currency!,
        decimalSeparator: nf.symbols.DECIMAL_SEP,
        groupSeparator: nf.symbols.GROUP_SEP,
      );
      if (p.error != null) {
        errors['amount'] = p.error!;
      } else {
        amount = p.money;
      }
    }
    int? customDays;
    if (d.cycle == SubscriptionCycle.custom) {
      customDays = int.tryParse(d.customDays.text.trim());
      if (customDays == null || customDays < 1 || customDays > 3660) {
        errors['customDays'] = l.subsErrCustomDays;
      }
    }
    if (d.startedOn == null) errors['startedOn'] = l.subsErrAmount;
    setState(() {
      d.errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) return;

    final SubscriptionDraft draft = SubscriptionDraft(
      name: name,
      category: d.category.text,
      amount: amount!,
      cycle: d.cycle,
      customDays: customDays,
      startedOn: d.startedOn!,
      tone: d.tone,
    );
    final SubscriptionsResult<SubscriptionsWrite> r = d.id == null
        ? _repo.add(draft)
        : _repo.edit(d.id!, draft, version: d.version!);
    if (!mounted) return;
    final SubscriptionsFailure? failure = r.failure;
    if (failure != null) {
      if (failure.field == 'currency' && failure.reason == 'withdrawn') {
        setState(() => d.errors['currency'] = l.subsErrWithdrawn(d.currency!.code));
        return;
      }
      _failed(l, failure);
      return;
    }
    final SubscriptionsWrite w = r.value!;
    _draft = null;
    d.dispose();
    _go(_View.subscription, subscription: w.subscription!.id);
    _say(l.commonSaved);
  }

  Future<void> _setCancelled(AppLocalizations l, Subscription s, bool cancelled) async {
    if (cancelled) {
      final bool? ok = await subsDecide(
        context,
        title: l.subsCancelAsk,
        text: l.subsCancelText,
        confirm: l.actionConfirm,
      );
      if (ok != true || !mounted) return;
    }
    final SubscriptionsResult<SubscriptionsWrite> r = _repo.setCancelled(
      s.id,
      cancelled,
      version: s.version,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _say(cancelled ? l.subsCancelToast : l.subsReactivatedToast);
  }

  Future<void> _delete(AppLocalizations l, Subscription s) async {
    final bool ok = await subsConfirmDelete(
      context,
      title: l.subsDeleteAsk,
      text: l.subsDeleteText,
    );
    if (!ok || !mounted) return;
    final SubscriptionsResult<SubscriptionsWrite> r = _repo.delete(s.id, version: s.version);
    if (r.failure != null) return _failed(l, r.failure!);
    _go(_View.list);
    _undoable(l, l.subsDeletedToast, r.value!);
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(context, countryCode: widget.request.user.country);
    final LumeDate? today = _today(context);
    final SubscriptionsSnapshot snapshot = _repo.view();

    SubscriptionsBook? book;
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
      _View.subscription => _subscriptionScreen(context, l, f, book),
      _View.form => (
        _draft?.id == null ? l.subsNewSubscription : l.subsEditSubscription,
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
        actions: LumeToolActions(
          onSearch: () {
            if (_view != _View.list) _go(_View.list);
            _searchFocus.requestFocus();
          },
        ),
        headerActions: _view == _View.form
            ? <Widget>[
                LumeTextButton(
                  key: LumeSubscriptionsTool.saveKey,
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

  void _deepLink(AppLocalizations l, SubscriptionsBook book) {
    final String? asked = widget.request.query['sub'];
    if (asked == null) {
      if (_subscription != null && book.subscription(_subscription!) == null) {
        _view = _View.list;
        _subscription = null;
      }
      return;
    }
    final LumeRecordId? id = LumeRecordId.tryParse(asked);
    if (id != null && book.subscription(id) != null) {
      _subscription = id;
      _view = _View.subscription;
      return;
    }
    _view = _View.list;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _say(l.subsNotFound, tone: LumeToastTone.info),
    );
  }

  // ------------------------------------------------------------------ list

  bool _matchesFilter(SubscriptionView v, SubscriptionsFilter f) => switch (f) {
    SubscriptionsFilter.active => v.active,
    SubscriptionsFilter.cancelled => !v.active,
    SubscriptionsFilter.all => true,
  };

  bool _matchesSearch(SubscriptionView v, String q) {
    if (q.isEmpty) return true;
    final String hay = '${v.subscription.name} ${v.subscription.category ?? ''}'.toLowerCase();
    return hay.contains(q.toLowerCase());
  }

  List<Widget> _list(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    SubscriptionsBook book,
    LumeDate? today,
  ) {
    if (book.isEmpty) {
      return <Widget>[
        LumeToolSection(
          child: LumeToolState(
            key: LumeSubscriptionsTool.emptyKey,
            icon: LumeIcons.refresh,
            title: l.subsEmptyTitle,
            text: l.subsEmptyText,
          ),
        ),
        LumeToolSection(
          child: LumeButton.accent(
            key: LumeSubscriptionsTool.addKey,
            label: l.subsAddSubscription,
            block: true,
            onPressed: () => _add(today),
          ),
        ),
      ];
    }

    final bool withCode = book.currencies.length > 1;
    final LumeCurrency primary = book.currencies.first;
    final SubscriptionsCurrencySummary summary = book.summary(primary);

    List<SubscriptionView> shown = <SubscriptionView>[
      for (final SubscriptionView v in book.subscriptions)
        if (_matchesFilter(v, _filter) && _matchesSearch(v, _query.text)) v,
    ];
    int cmp(SubscriptionView a, SubscriptionView b) => switch (_sort) {
      SubscriptionsSort.renewal =>
        (a.daysUntil ?? 1 << 30).compareTo(b.daysUntil ?? 1 << 30),
      SubscriptionsSort.amount => a.subscription.amount.compareTo(b.subscription.amount),
      SubscriptionsSort.name => a.subscription.name.compareTo(b.subscription.name),
    };
    shown.sort(cmp);
    if (_descending) shown = shown.reversed.toList();

    final Map<String, LumeMoney> byCategory = book.byCategory(primary, l.subsUncategorised);
    final List<SubscriptionView>? upcoming = book.upcoming();

    return <Widget>[
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeSubscriptionsTool.summaryKey,
          kicker: l.subsSummaryKicker,
          value: f.amount(summary.monthly, withCode: withCode),
          caption: l.subsSummaryCaption(f.amount(summary.yearly, withCode: withCode)),
          stats: <LumeStat>[
            LumeStat(value: f.integer(summary.activeCount), label: l.subsStatActive),
            LumeStat(
              value: summary.next?.subscription.name ?? '—',
              label: l.subsStatNext,
            ),
            LumeStat(
              value: summary.next?.daysUntil == null
                  ? '—'
                  : l.subsRenewsIn(summary.next!.daysUntil!),
              label: '',
            ),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeSearchField(
          key: LumeSubscriptionsTool.searchKey,
          controller: _query,
          focusNode: _searchFocus,
          placeholder: l.subsSearch,
          onChanged: (String _) => setState(() {}),
        ),
      ),
      LumeToolSection(
        flush: true,
        child: LumeFilterBar(
          key: LumeSubscriptionsTool.filterKey,
          children: <Widget>[
            for (final SubscriptionsFilter filt in SubscriptionsFilter.values)
              LumeFilterChip(
                key: LumeSubscriptionsTool.filterChip(filt),
                label: switch (filt) {
                  SubscriptionsFilter.active => l.subsFilterActive,
                  SubscriptionsFilter.cancelled => l.subsFilterCancelled,
                  SubscriptionsFilter.all => l.subsFilterAll,
                },
                selected: _filter == filt,
                onTap: () => setState(() => _write('filter', filt.name)),
              ),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeSortBar(
          key: LumeSubscriptionsTool.sortKey,
          value: _sort.name,
          direction: _descending ? LumeSortDirection.descending : LumeSortDirection.ascending,
          items: <LumeChoice>[
            LumeChoice(value: SubscriptionsSort.renewal.name, label: l.subsSortRenewal),
            LumeChoice(value: SubscriptionsSort.amount.name, label: l.subsSortAmount),
            LumeChoice(value: SubscriptionsSort.name.name, label: l.subsSortName),
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
            key: LumeSubscriptionsTool.noMatchKey,
            icon: LumeIcons.search,
            title: l.recNoMatch,
            text: '',
          ),
        )
      else
        LumeToolSection(
          title: l.subsAll,
          child: LumeRows(
            key: LumeSubscriptionsTool.listKey,
            children: <Widget>[
              for (final SubscriptionView v in shown) _row(context, l, f, v),
            ],
          ),
        ),
      if (byCategory.isNotEmpty)
        LumeToolSection(
          title: l.subsByCategory,
          child: LumeCard(
            key: LumeSubscriptionsTool.chartKey,
            child: LumeDonut(
              label: l.subsByCategory,
              centre: f.amount(summary.monthly, compact: true),
              centreSub: l.subsPerMonth,
              slices: <LumeDonutSlice>[
                for (final MapEntry<String, LumeMoney> e in byCategory.entries)
                  LumeDonutSlice(
                    label: e.key,
                    value: e.value.minor.toDouble(),
                    color: context.lume.accent,
                  ),
              ],
            ),
          ),
        ),
      if (upcoming != null && upcoming.isNotEmpty)
        LumeToolSection(
          title: l.subsTimeline,
          child: LumeTimeline(
            key: LumeSubscriptionsTool.timelineKey,
            entries: <LumeTimelineEntry>[
              for (final SubscriptionView v in upcoming)
                LumeTimelineEntry(
                  title: v.subscription.name,
                  time: f.dateMediumYear(v.nextRenewal!.toCalendarDateTime()),
                  state: v.dueSoon ? LumeTimelineState.now : LumeTimelineState.upcoming,
                ),
            ],
          ),
        ),
      LumeToolSection(
        child: LumeButton.accent(
          key: LumeSubscriptionsTool.addKey,
          label: l.subsAddSubscription,
          block: true,
          onPressed: () => _add(today),
        ),
      ),
    ];
  }

  Widget _row(BuildContext context, AppLocalizations l, LumeFormatting f, SubscriptionView v) {
    final Subscription s = v.subscription;
    return LumeRichRow(
      key: LumeSubscriptionsTool.row(s.id.value),
      logo: lumeInitials(s.name),
      iconTone: SubscriptionsText.tone(context.lume, s.tone),
      title: s.name,
      subtitle: s.category,
      meta: <String>[
        SubscriptionsText.cycle(l, s.cycle),
        if (v.nextRenewal != null)
          l.subsRenews(f.dateMediumYear(v.nextRenewal!.toCalendarDateTime())),
      ],
      badge: v.dueSoon && v.daysUntil != null
          ? LumeBadge(label: l.subsRenewsIn(v.daysUntil!), tone: LumeBadgeTone.warn)
          : null,
      value: f.amount(s.amount),
      valueSub: SubscriptionsText.perCycle(l, s),
      chevron: true,
      onTap: () => _go(_View.subscription, subscription: s.id),
    );
  }

  // ------------------------------------------------------------ subscription

  (String?, List<Widget>, bool) _subscriptionScreen(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    SubscriptionsBook book,
  ) {
    final SubscriptionView? v = _subscription == null ? null : book.subscription(_subscription!);
    if (v == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _go(_View.list));
      return (null, const <Widget>[], false);
    }
    final Subscription s = v.subscription;
    return (
      s.name,
      <Widget>[
        LumeToolSection(
          child: LumeSummaryCard(
            key: LumeSubscriptionsTool.subscriptionKey,
            kicker: SubscriptionsText.cycle(l, s.cycle),
            value: f.amount(s.amount),
            caption: SubscriptionsText.perCycle(l, s),
            stats: <LumeStat>[
              if (v.nextRenewal != null)
                LumeStat(
                  value: f.dateMediumYear(v.nextRenewal!.toCalendarDateTime()),
                  label: l.subsStatNext,
                ),
              LumeStat(
                value: f.amount(v.monthlyEquivalent, compact: true),
                label: l.subsSummaryKicker,
              ),
            ],
          ),
        ),
        LumeToolSection(
          child: LumeDetailActions(
            editLabel: l.actionEdit,
            onEdit: () => _edit(s),
            deleteLabel: l.actionDelete,
            onDelete: () => unawaited(_delete(l, s)),
            extra: <Widget>[
              if (s.active)
                LumeDetailAction(
                  key: LumeSubscriptionsTool.cancelKey,
                  label: l.subsCancel,
                  destructive: true,
                  onPressed: () => unawaited(_setCancelled(l, s, true)),
                )
              else
                LumeDetailAction(
                  key: LumeSubscriptionsTool.reactivateKey,
                  label: l.subsReactivate,
                  icon: LumeIcons.refresh,
                  onPressed: () => unawaited(_setCancelled(l, s, false)),
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
    final _SubscriptionDraft d = _draft!;
    return <Widget>[
      LumeToolSection(
        child: LumeFormCard(
          key: LumeSubscriptionsTool.formKey,
          children: <Widget>[
            LumeFormField(
              key: LumeSubscriptionsTool.nameField,
              label: l.subsFieldName,
              controller: d.name,
              required: true,
              autofocus: d.id == null,
              error: d.errors['name'],
            ),
            LumeFormField(
              key: LumeSubscriptionsTool.categoryField,
              label: l.subsFieldCategory,
              controller: d.category,
              optionalLabel: l.actionNotSet,
              error: d.errors['category'],
            ),
            LumeFormField(
              key: LumeSubscriptionsTool.amountField,
              label: l.subsFieldAmount,
              controller: d.amount,
              kind: LumeFieldKind.money,
              required: true,
              error: d.errors['amount'] ?? d.errors['currency'],
            ),
            LumeSegmented(
              key: LumeSubscriptionsTool.cycleField,
              value: d.cycle.name,
              items: <LumeChoice>[
                LumeChoice(value: SubscriptionCycle.monthly.name, label: l.subsCycleMonthly),
                LumeChoice(value: SubscriptionCycle.yearly.name, label: l.subsCycleYearly),
                LumeChoice(value: SubscriptionCycle.custom.name, label: l.subsCycleCustom),
              ],
              onChanged: (String v) => setState(
                () => d.cycle = SubscriptionCycle.values.firstWhere((SubscriptionCycle c) => c.name == v),
              ),
            ),
            if (d.cycle == SubscriptionCycle.custom)
              LumeFormField(
                key: LumeSubscriptionsTool.customDaysField,
                label: l.subsFieldCustomDays,
                controller: d.customDays,
                kind: LumeFieldKind.number,
                required: true,
                error: d.errors['customDays'],
              ),
            LumeFormPicker(
              key: LumeSubscriptionsTool.startedOnField,
              label: l.subsFieldStartedOn,
              value: d.startedOn == null
                  ? l.actionNotSet
                  : LumeFormatting.of(context).dateMediumYear(d.startedOn!.toCalendarDateTime()),
              onTap: () async {
                final DateTime base =
                    d.startedOn?.toCalendarDateTime() ?? LumeClockScope.of(context).now();
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: base,
                  firstDate: DateTime(base.year - 20),
                  lastDate: DateTime(base.year + 1),
                );
                if (picked != null && mounted) {
                  setState(() => d.startedOn = LumeDate.ofWallClock(picked));
                }
              },
            ),
          ],
        ),
      ),
    ];
  }
}

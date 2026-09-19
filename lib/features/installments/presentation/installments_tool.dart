/// Installments — `tools/money/installments.tool.js`, as a real
/// record-backed tool (`INSTALLMENTS_PROPOSAL.md` §40).
///
/// The reference's composition, in its order: the summary card, the filter
/// bar, the sort bar, the plans with their progress meters, the schedule
/// timeline, the monthly chart, History, then the frame's source line and
/// related tools. What it only drew, this does: plans, their schedules and
/// payments are the reader's own records (nothing seeded), every figure is
/// derived from them and agrees with every other, states come from due
/// dates and the reader's own day, and a plan can be added, paid, corrected,
/// cancelled and deleted. It is sensitive: the frame shows its privacy note
/// and nothing here reaches Home. It sends no notification (§40.11).
///
/// A dedicated host, as Ledger's: the list, a plan and the form take the
/// screen in turn; each write is one transaction through
/// [InstallmentsRepository], and each typed failure has its own answer —
/// a field to correct, the instalment to pay first, a conflict — with
/// nothing written until the reader decides.
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
import '../../../core/localization/lume_format.dart';
import '../../../core/lume_build.dart';
import '../../../core/navigation/lume_tool_frame.dart';
import '../../../core/platform/lume_export.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_currency_policy.dart';
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
import '../../records/domain/record_transaction.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/installments_providers.dart';
import '../domain/installments_book.dart';
import '../domain/installments_failure.dart';
import '../domain/installments_model.dart';
import '../domain/installments_repository.dart';
import '../domain/installments_transfer.dart';
import 'installments_sheets.dart';
import 'installments_text.dart';
import 'installments_transfer_sheets.dart';

enum InstallmentsFilter { active, late, completed, cancelled, all }

enum InstallmentsSort { next, left, amount, name, recent }

enum _View { list, plan, form }

abstract final class LumeInstallmentsTool {
  static const String id = 'installments';

  static const Key summaryKey = ValueKey<String>('inst.summary');
  static const Key filterKey = ValueKey<String>('inst.filter');
  static const Key searchKey = ValueKey<String>('inst.search');
  static const Key sortKey = ValueKey<String>('inst.sort');
  static const Key plansKey = ValueKey<String>('inst.plans');
  static const Key comingKey = ValueKey<String>('inst.coming');
  static const Key chartKey = ValueKey<String>('inst.chart');
  static const Key historyKey = ValueKey<String>('inst.history');
  static const Key emptyKey = ValueKey<String>('inst.empty');
  static const Key noMatchKey = ValueKey<String>('inst.noMatch');
  static const Key dayUnknownKey = ValueKey<String>('inst.dayUnknown');
  static const Key defectsKey = ValueKey<String>('inst.defects');
  static const Key addKey = ValueKey<String>('inst.add');
  static const Key planKey = ValueKey<String>('inst.plan');
  static const Key damagedKey = ValueKey<String>('inst.damaged');
  static const Key payKey = ValueKey<String>('inst.pay');
  static const Key editKey = ValueKey<String>('inst.edit');
  static const Key cancelKey = ValueKey<String>('inst.cancel');
  static const Key reinstateKey = ValueKey<String>('inst.reinstate');
  static const Key deleteKey = ValueKey<String>('inst.delete');
  static const Key scheduleKey = ValueKey<String>('inst.schedule');
  static const Key paymentsKey = ValueKey<String>('inst.payments');
  static const Key formKey = ValueKey<String>('inst.form');
  static const Key saveKey = ValueKey<String>('inst.save');
  static const Key lockedKey = ValueKey<String>('inst.locked');
  static const Key itemField = ValueKey<String>('inst.field.item');
  static const Key merchantField = ValueKey<String>('inst.field.merchant');
  static const Key noteField = ValueKey<String>('inst.field.note');
  static const Key currencyField = ValueKey<String>('inst.field.currency');
  static const Key amountField = ValueKey<String>('inst.field.amount');
  static const Key countField = ValueKey<String>('inst.field.count');
  static const Key firstDueField = ValueKey<String>('inst.field.firstDue');
  static const Key depositField = ValueKey<String>('inst.field.deposit');
  static const Key depositOnField = ValueKey<String>('inst.field.depositOn');
  static const Key cashField = ValueKey<String>('inst.field.cash');
  static Key filterChip(InstallmentsFilter f) =>
      ValueKey<String>('inst.filter.${f.name}');
  static Key row(String plan) => ValueKey<String>('inst.row.$plan');
  static Key instalment(String id) => ValueKey<String>('inst.instalment.$id');
  static Key payment(String id) => ValueKey<String>('inst.payment.$id');

  static Widget open(LumeToolRequest request) =>
      InstallmentsTool(request: request);
}

class InstallmentsTool extends ConsumerStatefulWidget {
  const InstallmentsTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<InstallmentsTool> createState() => _InstallmentsToolState();
}

/// A plan form's state. [locked] once payments exist: the terms are shown
/// and cannot be changed (§40.8).
class _PlanDraft {
  _PlanDraft({
    this.id,
    this.version,
    required this.currency,
    this.firstDue,
    this.depositOn,
    this.locked = false,
    String item = '',
    String merchant = '',
    String note = '',
    String amount = '',
    String count = '',
    String deposit = '',
    String cash = '',
  }) : item = TextEditingController(text: item),
       merchant = TextEditingController(text: merchant),
       note = TextEditingController(text: note),
       amount = TextEditingController(text: amount),
       count = TextEditingController(text: count),
       deposit = TextEditingController(text: deposit),
       cash = TextEditingController(text: cash) {
    _initial = _state;
  }

  final LumeRecordId? id;
  final int? version;
  final bool locked;
  LumeCurrency? currency;
  LumeDate? firstDue;
  LumeDate? depositOn;
  final TextEditingController item;
  final TextEditingController merchant;
  final TextEditingController note;
  final TextEditingController amount;
  final TextEditingController count;
  final TextEditingController deposit;
  final TextEditingController cash;
  final Map<String, String> errors = <String, String>{};
  late final String _initial;

  String get _state => <Object?>[
    item.text,
    merchant.text,
    note.text,
    amount.text,
    count.text,
    deposit.text,
    cash.text,
    currency?.code,
    firstDue?.toIso(),
    depositOn?.toIso(),
  ].join('\u0000');

  bool get dirty => _state != _initial;

  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      item,
      merchant,
      note,
      amount,
      count,
      deposit,
      cash,
    ]) {
      c.dispose();
    }
  }
}

class _InstallmentsToolState extends ConsumerState<InstallmentsTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final InstallmentsRepository _repo = ref.read(
    installmentsRepositoryProvider,
  );
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(
    text: _read('q') ?? '',
  );
  final FocusNode _searchFocus = FocusNode();

  /// The body, to find the frame's scroll from: a new view opens at its top.
  final GlobalKey _body = GlobalKey();

  _View _view = _View.list;
  LumeRecordId? _plan;
  _PlanDraft? _draft;
  bool _linked = false;

  String get _id => widget.request.feature.id;
  String? _read(String key) => _session.read(_id, key);
  void _write(String key, String value) => _session.write(_id, key, value);

  InstallmentsFilter get _filter => InstallmentsFilter.values.firstWhere(
    (InstallmentsFilter f) => f.name == _read('filter'),
    orElse: () => InstallmentsFilter.active,
  );
  InstallmentsSort get _sort => InstallmentsSort.values.firstWhere(
    (InstallmentsSort s) => s.name == _read('sort'),
    orElse: () => InstallmentsSort.next,
  );
  bool get _descending => _read('dir') == 'desc';

  @override
  void initState() {
    super.initState();
    _repo.open();
    _repo.changes.addListener(_changed);
    // Restoration: the plan the reader had open in this session.
    final LumeRecordId? kept = LumeRecordId.tryParse(_read('plan') ?? '');
    if (kept != null) {
      _plan = kept;
      _view = _View.plan;
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

  LumeProfileRecord get _profile =>
      ref.read(startupControllerProvider).state.profile;

  /// The reader's calendar date in their resolved zone, or `null` when it
  /// cannot be worked out: nothing is then late, due or upcoming.
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
  /// new plan may use, or none.
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
    return installmentsDefaultCurrency(code);
  }

  // ------------------------------------------------------------ navigation

  void _go(_View v, {LumeRecordId? plan}) {
    final bool moved = v != _view || (plan != null && plan != _plan);
    setState(() {
      _view = v;
      if (plan != null) _plan = plan;
      _write('plan', v == _View.list ? '' : (_plan?.value ?? ''));
    });
    if (!moved) return;
    // A new view opens at its top, not where the last one was scrolled to.
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
      case _View.plan:
        _go(_View.list);
      case _View.form:
        final _PlanDraft? d = _draft;
        if (d != null && d.dirty && !await _confirmDiscard()) return;
        if (!mounted) return;
        _draft = null;
        d?.dispose();
        _go(d?.id != null ? _View.plan : _View.list);
    }
  }

  Future<bool> _confirmDiscard() async {
    final AppLocalizations l = AppLocalizations.of(context);
    return await installmentsDecide(
          context,
          title: l.recDiscardAsk,
          text: l.recDiscardText,
          confirm: l.recDiscard,
          cancel: l.recKeepEditing,
          destructive: true,
        ) ??
        false;
  }

  void _addPlan(LumeDate? today) {
    _draft?.dispose();
    _draft = _PlanDraft(currency: _currency(), firstDue: today);
    _go(_View.form);
  }

  void _editPlan(InstallmentPlanView v) {
    _draft?.dispose();
    final InstallmentPlan p = v.plan;
    _draft = _PlanDraft(
      id: p.id,
      version: p.version,
      currency: p.currency,
      firstDue: p.firstDue,
      depositOn: p.depositOn,
      locked: v.hasPayments,
      item: p.item,
      merchant: p.merchant ?? '',
      note: p.note ?? '',
      amount: p.amount.toDecimalString(),
      count: '${p.count}',
      deposit: p.deposit?.toDecimalString() ?? '',
      cash: p.cashPrice?.toDecimalString() ?? '',
    );
    _go(_View.form);
  }

  // ---------------------------------------------------------------- writes

  void _failed(AppLocalizations l, InstallmentsFailure f) {
    _say(switch (f.kind) {
      InstallmentsFailureKind.conflict ||
      InstallmentsFailureKind.notFound => l.instErrConflict,
      InstallmentsFailureKind.damaged => l.instErrDamaged,
      InstallmentsFailureKind.cancelled => l.instErrCancelled,
      InstallmentsFailureKind.completed => l.instErrCompleted,
      InstallmentsFailureKind.alreadyPaid => l.instErrAlreadyPaid,
      InstallmentsFailureKind.locked => l.instLockedText,
      InstallmentsFailureKind.overflow => l.instErrTooLarge,
      _ => l.instErrFailed,
    }, tone: LumeToastTone.error);
  }

  /// Offer to take a committed write back.
  void _undoable(AppLocalizations l, String message, InstallmentsWrite w) =>
      _say(
        message,
        actionLabel: l.recUndo,
        onAction: () {
          final InstallmentsResult<void> r = _repo.undo(w);
          if (r.failure != null) _failed(l, r.failure!);
        },
      );

  Future<void> _savePlan(AppLocalizations l) async {
    final _PlanDraft d = _draft!;
    final Map<String, String> errors = <String, String>{};
    final intl.NumberFormat nf = intl.NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag().replaceAll('-', '_'),
    );
    LumeMoney? money(
      String field,
      TextEditingController c, {
      bool need = false,
    }) {
      final LumeCurrency? cur = d.currency;
      if (c.text.trim().isEmpty) {
        if (need) errors[field] = l.ledgerErrAmount;
        return null;
      }
      if (cur == null) return null;
      final LedgerParsedAmount p = ledgerParseAmount(
        l,
        c.text,
        cur,
        decimalSeparator: nf.symbols.DECIMAL_SEP,
        groupSeparator: nf.symbols.GROUP_SEP,
      );
      if (p.error != null) errors[field] = p.error!;
      return p.money;
    }

    final String item = d.item.text.trim();
    if (item.isEmpty) errors['item'] = l.instErrItem;
    if (item.length > kInstallmentsNameMax) errors['item'] = l.instErrLong;
    if (d.merchant.text.trim().length > kInstallmentsNameMax) {
      errors['merchant'] = l.instErrLong;
    }
    if (d.note.text.length > kInstallmentsNoteMax) {
      errors['note'] = l.instErrLong;
    }
    if (d.currency == null) errors['currency'] = l.instErrDate;
    final LumeMoney? amount = money('amount', d.amount, need: true);
    final int? count = _whole(d.count.text);
    if (count == null || count < 1 || count > kInstallmentsCountMax) {
      errors['count'] = l.instErrCount;
    }
    if (d.firstDue == null) errors['firstDue'] = l.instErrDate;
    final LumeMoney? deposit = money('deposit', d.deposit);
    if ((deposit == null) != (d.depositOn == null) &&
        !errors.containsKey('deposit')) {
      errors[deposit == null ? 'deposit' : 'depositOn'] = l.instErrDepositPair;
    }
    final LumeMoney? cash = money('cash', d.cash);
    setState(() {
      d.errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) return;

    final InstallmentPlanDraft draft = InstallmentPlanDraft(
      item: item,
      merchant: d.merchant.text,
      note: d.note.text,
      amount: amount!,
      count: count!,
      firstDue: d.firstDue!,
      deposit: deposit,
      depositOn: deposit == null ? null : d.depositOn,
      cashPrice: cash,
    );
    final InstallmentsResult<InstallmentsWrite> r = d.id == null
        ? _repo.addPlan(draft)
        : _repo.editPlan(d.id!, draft, version: d.version!);
    if (!mounted) return;
    final InstallmentsFailure? failure = r.failure;
    if (failure != null) {
      final String? field = switch (failure.field) {
        'amount' || 'count' || 'item' || 'merchant' || 'note' => failure.field,
        'currency' => 'currency',
        'firstDue' => 'firstDue',
        'deposit' || 'depositOn' => failure.field,
        'cashPrice' => 'cash',
        _ => null,
      };
      if (field != null && failure.kind != InstallmentsFailureKind.locked) {
        setState(
          () => d.errors[field] = switch (failure.reason) {
            'withdrawn' => l.instErrWithdrawn(d.currency!.code),
            'range' when field == 'count' => l.instErrCount,
            'range' => l.instErrRange,
            'long' => l.instErrLong,
            'required' when field == 'item' => l.instErrItem,
            'required' || 'currency' => l.instErrDepositPair,
            _ when failure.kind == InstallmentsFailureKind.overflow =>
              l.instErrTooLarge,
            _ => l.ledgerErrAmount,
          },
        );
        return;
      }
      return _failed(l, failure);
    }
    final LumeRecordId id = r.value!.plan!.id;
    _draft = null;
    d.dispose();
    _say(l.instSaved);
    _go(_View.plan, plan: id);
  }

  /// A whole number in the reader's digits, or `null`.
  static int? _whole(String text) {
    final StringBuffer ascii = StringBuffer();
    for (final int r in text.trim().runes) {
      if (r >= 0x0660 && r <= 0x0669) {
        ascii.writeCharCode(0x30 + r - 0x0660);
      } else if (r >= 0x06f0 && r <= 0x06f9) {
        ascii.writeCharCode(0x30 + r - 0x06f0);
      } else {
        ascii.writeCharCode(r);
      }
    }
    final String s = ascii.toString();
    return RegExp(r'^[0-9]{1,4}$').hasMatch(s) ? int.parse(s) : null;
  }

  Future<void> _pay(
    AppLocalizations l,
    LumeFormatting f,
    InstallmentPlanView v,
    LumeDate? today,
    bool withCode,
  ) async {
    final InstallmentRow? next = v.next;
    if (next == null) return;
    final LumeDate? on = await InstallmentsPaySheet.show(
      context,
      text: l.instPayText(
        f.integer(next.row.seq),
        f.integer(v.plan.count),
        f.amount(next.row.amount, withCode: withCode, isolate: true),
        InstallmentsText.date(f, next.row.due, today: today),
      ),
      initial: today,
      dateText: (LumeDate d) => InstallmentsText.date(f, d, today: today),
    );
    if (on == null || !mounted) return;
    final InstallmentsResult<InstallmentsWrite> r = _repo.recordPayment(
      v.plan.id,
      next.row.id,
      on,
    );
    if (r.failure != null) {
      if (r.failure!.kind == InstallmentsFailureKind.outOfOrder) {
        final InstallmentRow? first = v.rows
            .where((InstallmentRow x) => x.row.id == r.failure!.ids.first)
            .firstOrNull;
        _say(
          l.instErrOutOfOrder(f.integer(first?.row.seq ?? 1)),
          tone: LumeToastTone.info,
        );
        return;
      }
      return _failed(l, r.failure!);
    }
    _undoable(l, l.instPaidToast, r.value!);
  }

  Future<void> _paymentActions(
    AppLocalizations l,
    LumeFormatting f,
    InstallmentPlanView v,
    InstallmentRow row,
    InstallmentPayment p,
    bool withCode,
  ) async {
    if (v.plan.cancelled || v.damaged) return;
    final bool? go = await installmentsDecide(
      context,
      title: l.instInstalmentOf(
        f.integer(row.row.seq),
        f.integer(v.plan.count),
      ),
      text: <String>[
        l.instPaidOn(InstallmentsText.date(f, p.paidOn)),
        f.amount(p.amount, withCode: withCode),
        if (p.voided) l.instVoided,
      ].join(' · '),
      confirm: p.active ? l.instVoidPayment : l.instRestorePayment,
    );
    if (go != true || !mounted) return;
    final InstallmentsResult<InstallmentsWrite> r = _repo.setPaymentVoided(
      p.id,
      p.active,
      version: p.version,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _say(p.active ? l.instVoidedToast : l.instRestoredToast);
  }

  Future<void> _cancel(AppLocalizations l, InstallmentPlanView v) async {
    if (v.plan.cancelled) {
      final InstallmentsResult<InstallmentsWrite> r = _repo.setCancelled(
        v.plan.id,
        false,
        version: v.plan.version,
      );
      if (r.failure != null) return _failed(l, r.failure!);
      _say(l.instReinstatedToast);
      return;
    }
    final bool? go = await installmentsDecide(
      context,
      title: l.instCancelTitle,
      text: l.instCancelText,
      confirm: l.instCancelPlan,
      cancel: l.instKeepPlan,
      destructive: true,
    );
    if (go != true || !mounted) return;
    final InstallmentsResult<InstallmentsWrite> r = _repo.setCancelled(
      v.plan.id,
      true,
      version: v.plan.version,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _undoable(l, l.instCancelledToast, r.value!);
  }

  Future<void> _delete(
    AppLocalizations l,
    LumeFormatting f,
    InstallmentPlanView v,
  ) async {
    if (!await installmentsConfirmDelete(
      context,
      title: l.instDeleteTitle,
      text: l.instDeleteText(
        f.integer(v.rows.length),
        f.integer(v.payments.length),
      ),
    )) {
      return;
    }
    if (!mounted) return;
    final InstallmentsResult<InstallmentsWrite> r = _repo.deletePlan(
      v.plan.id,
      version: v.plan.version,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _go(_View.list);
    _say(
      l.instDeletedToast,
      actionLabel: l.recUndo,
      onAction: () {
        final InstallmentsResult<void> back = _repo.undo(r.value!);
        if (back.failure != null) return _failed(l, back.failure!);
        _say(l.instRestoredPlanToast);
      },
    );
  }

  // --------------------------------------------------------- export, import

  Future<void> _export(
    AppLocalizations l,
    LumeFormatting f,
    InstallmentsBook book,
  ) async {
    final InstallmentsExportChoice? choice =
        await showLumeSheet<InstallmentsExportChoice>(
          context: context,
          barrierLabel: l.instExportTitle,
          child: InstallmentsExportSheet(
            onImport: () => unawaited(_import(l, f)),
          ),
        );
    if (choice == null || !mounted) return;
    final DateTime now = LumeClockScope.of(context).now();
    final InstallmentsSnapshot s = _repo.view();
    final LumeExportFile file = LumeExportFile.document(
      tool: _id,
      day: now,
      format: choice.json ? LumeExportFormat.json : LumeExportFormat.csv,
      text: choice.json
          ? installmentsExportJson(
              plans: s.plans,
              schedule: s.schedule,
              payments: s.payments,
              exportedAt: now,
              build: kLumeVersion,
              durable: _repo.durable,
              includeNames: choice.includeNames,
            )
          : installmentsExportCsv(book, includeNames: choice.includeNames),
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
    final InstallmentsImportReport? report =
        await showLumeSheet<InstallmentsImportReport>(
          context: context,
          barrierLabel: l.instImport,
          child: InstallmentsImportSheet(
            store: ref.read(recordRepositoryProvider),
            f: f,
          ),
        );
    if (report == null || !mounted) return;
    final LumeTxResult<int> r = installmentsImportApply(
      report,
      ref.read(recordRepositoryProvider),
    );
    if (!r.ok) {
      _say(l.instErrFailed, tone: LumeToastTone.error);
      return;
    }
    _say(l.instImported(r.value!));
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
    final InstallmentsSnapshot snapshot = _repo.view();

    InstallmentsBook? book;
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
      _View.plan => _planScreen(context, l, f, book, today, withCode),
      _View.form => (
        _draft?.id == null ? l.instNewPlan : l.instEditPlan,
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
          onExport: book == null || book.isEmpty
              ? null
              : () => unawaited(_export(l, f, book!)),
          onSearch: () {
            if (_view != _View.list) _go(_View.list);
            _searchFocus.requestFocus();
          },
        ),
        headerActions: _view == _View.form
            ? <Widget>[
                LumeTextButton(
                  key: LumeInstallmentsTool.saveKey,
                  label: l.actionSave,
                  onPressed: () => unawaited(_savePlan(l)),
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

  void _deepLink(AppLocalizations l, InstallmentsBook book) {
    final String? asked = widget.request.query['plan'];
    if (asked == null) {
      // A restored plan that has since gone opens the list.
      if (_plan != null && book.plan(_plan!) == null) {
        _view = _View.list;
        _plan = null;
      }
      return;
    }
    final LumeRecordId? id = LumeRecordId.tryParse(asked);
    if (id != null && book.plan(id) != null) {
      _plan = id;
      _view = _View.plan;
      return;
    }
    _view = _View.list;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _say(l.instNotFound, tone: LumeToastTone.info),
    );
  }

  // ------------------------------------------------------------------ list

  bool _matches(InstallmentPlanView v, InstallmentsFilter f) => switch (f) {
    InstallmentsFilter.active => v.status == InstallmentPlanStatus.active,
    InstallmentsFilter.late =>
      v.status == InstallmentPlanStatus.active && (v.late ?? false),
    InstallmentsFilter.completed => v.status == InstallmentPlanStatus.completed,
    InstallmentsFilter.cancelled => v.status == InstallmentPlanStatus.cancelled,
    InstallmentsFilter.all => true,
  };

  List<Widget> _list(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    InstallmentsBook book,
    LumeDate? today,
    bool withCode,
  ) {
    if (book.plans.isEmpty) {
      return <Widget>[
        LumeToolSection(
          child: LumeToolState(
            key: LumeInstallmentsTool.emptyKey,
            icon: LumeIcons.calendar,
            title: l.instEmptyTitle,
            text: l.instEmptyText,
            action: LumeButton.accent(
              key: LumeInstallmentsTool.addKey,
              label: l.instAdd,
              icon: LumeIcons.plus,
              onPressed: () => _addPlan(today),
            ),
          ),
        ),
        if (book.defects.isNotEmpty) _defects(l, book),
      ];
    }
    final InstallmentsFilter filter = _filter;
    final String q = LedgerText.fold(_query.text);
    final List<InstallmentPlanView> plans = book.plans
        .where((InstallmentPlanView v) => _matches(v, filter))
        .where(
          (InstallmentPlanView v) =>
              q.isEmpty ||
              LedgerText.fold(
                <String>[
                  v.plan.item,
                  v.plan.merchant ?? '',
                  v.plan.note ?? '',
                ].join(' '),
              ).contains(q),
        )
        .toList();
    _order(plans);

    final List<InstallmentPlanView> running = <InstallmentPlanView>[
      for (final InstallmentPlanView v in book.plans)
        if (v.status == InstallmentPlanStatus.active && !v.damaged) v,
    ];
    final List<(InstallmentPlanView, InstallmentRow)> coming =
        <(InstallmentPlanView, InstallmentRow)>[
          for (final InstallmentPlanView v in running) (v, v.next!),
        ]..sort(
          (
            (InstallmentPlanView, InstallmentRow) a,
            (InstallmentPlanView, InstallmentRow) b,
          ) => a.$2.row.due.compareTo(b.$2.row.due),
        );
    final List<(InstallmentPlanView, InstallmentPayment)> history = book.history
        .take(5)
        .toList();

    return <Widget>[
      ..._summaries(l, f, book, withCode),
      if (book.defects.isNotEmpty) _defects(l, book),
      LumeToolSection(
        spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
        child: Semantics(
          label: l.instFilterLabel,
          container: true,
          child: LumeFilterBar(
            key: LumeInstallmentsTool.filterKey,
            gutters: false,
            children: <Widget>[
              for (final (InstallmentsFilter v, String label)
                  in <(InstallmentsFilter, String)>[
                    (InstallmentsFilter.active, l.instFilterActive),
                    (InstallmentsFilter.late, l.instFilterLate),
                    (InstallmentsFilter.completed, l.instFilterCompleted),
                    (InstallmentsFilter.cancelled, l.instFilterCancelled),
                    (InstallmentsFilter.all, l.commonAll),
                  ])
                LumeFilterChip(
                  key: LumeInstallmentsTool.filterChip(v),
                  label: label,
                  // Without the reader's day there is no count of late.
                  count: v == InstallmentsFilter.late && today == null
                      ? null
                      : book.plans
                            .where((InstallmentPlanView x) => _matches(x, v))
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
          key: LumeInstallmentsTool.searchKey,
          controller: _query,
          focusNode: _searchFocus,
          placeholder: l.instSearch,
          semanticLabel: l.instSearch,
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
          key: LumeInstallmentsTool.sortKey,
          label: l.commonSort,
          value: _sort.name,
          direction: _descending
              ? LumeSortDirection.descending
              : LumeSortDirection.ascending,
          items: <LumeChoice>[
            LumeChoice(
              value: InstallmentsSort.next.name,
              label: l.instSortNext,
            ),
            LumeChoice(
              value: InstallmentsSort.left.name,
              label: l.instSortLeft,
            ),
            LumeChoice(
              value: InstallmentsSort.amount.name,
              label: l.instSortAmount,
            ),
            LumeChoice(
              value: InstallmentsSort.name.name,
              label: l.instSortName,
            ),
            LumeChoice(
              value: InstallmentsSort.recent.name,
              label: l.instSortRecent,
            ),
          ],
          onChanged: (String v, LumeSortDirection d) => setState(() {
            _write('sort', v);
            _write('dir', d == LumeSortDirection.descending ? 'desc' : 'asc');
          }),
        ),
      ),
      LumeToolSection(
        title: l.instPlans,
        link: l.instAdd,
        onLinkTap: () => _addPlan(today),
        child: switch (null) {
          _ when filter == InstallmentsFilter.late && today == null =>
            LumeToolState(
              key: LumeInstallmentsTool.dayUnknownKey,
              icon: LumeIcons.clock,
              title: l.recZoneUnknownTitle,
              text: l.instDayUnknownText,
            ),
          _ when plans.isEmpty => LumeToolState(
            key: LumeInstallmentsTool.noMatchKey,
            icon: LumeIcons.calendar,
            title: l.instNoMatch,
            text: l.instNoMatchText,
            action: LumeButton(
              label: l.instShowAll,
              icon: LumeIcons.refresh,
              onPressed: () => setState(() {
                _write('filter', InstallmentsFilter.all.name);
                _query.clear();
                _write('q', '');
              }),
            ),
          ),
          _ => LumeRows(
            key: LumeInstallmentsTool.plansKey,
            children: <Widget>[
              for (final InstallmentPlanView v in plans)
                _planRow(context, l, f, v, today, withCode),
            ],
          ),
        },
      ),
      if (coming.isNotEmpty)
        LumeToolSection(
          title: l.instComingUp,
          child: KeyedSubtree(
            key: LumeInstallmentsTool.comingKey,
            child: LumeTimeline(
              entries: <LumeTimelineEntry>[
                for (final (InstallmentPlanView v, InstallmentRow r)
                    in coming.take(6))
                  LumeTimelineEntry(
                    time: InstallmentsText.dateShort(
                      f,
                      r.row.due,
                      today: today,
                    ),
                    title: v.plan.item,
                    subtitle: <String>[
                      ?v.plan.merchant,
                      if (r.status == InstallmentStatus.late ||
                          r.status == InstallmentStatus.dueToday)
                        InstallmentsText.status(l, r.status),
                    ].join(' · '),
                    value: f.amount(
                      r.row.amount,
                      compact: true,
                      withCode: withCode,
                    ),
                    state:
                        r.status == InstallmentStatus.late ||
                            r.status == InstallmentStatus.dueToday
                        ? LumeTimelineState.now
                        : LumeTimelineState.upcoming,
                  ),
              ],
            ),
          ),
        ),
      ?_chart(l, f, book, withCode),
      if (history.isNotEmpty)
        LumeToolSection(
          title: l.commonHistory,
          child: LumeRows(
            key: LumeInstallmentsTool.historyKey,
            children: <Widget>[
              for (final (InstallmentPlanView v, InstallmentPayment p)
                  in history)
                LumeCompactRow(
                  icon: LumeIcons.checkCircle,
                  label: v.plan.item,
                  subtitle: <String>[
                    l.instInstalment(
                      f.integer(
                        v.rows
                                .where(
                                  (InstallmentRow r) =>
                                      r.row.id == p.installmentId,
                                )
                                .firstOrNull
                                ?.row
                                .seq ??
                            0,
                      ),
                    ),
                    l.instPaidOn(
                      InstallmentsText.dateShort(f, p.paidOn, today: today),
                    ),
                    if (p.voided) l.instVoided,
                  ].join(' · '),
                  value: f.amount(p.amount, compact: true, withCode: withCode),
                  onTap: () => _go(_View.plan, plan: v.plan.id),
                ),
            ],
          ),
        ),
      LumeToolSection(
        child: LumeButtonRow(
          children: <Widget>[
            LumeButton.accent(
              key: LumeInstallmentsTool.addKey,
              label: l.instAdd,
              icon: LumeIcons.plus,
              onPressed: () => _addPlan(today),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _defects(AppLocalizations l, InstallmentsBook book) => LumeToolSection(
    child: LumeNotice(
      key: LumeInstallmentsTool.defectsKey,
      kind: LumeNoticeKind.warning,
      title: l.instNeedsAttention,
      text: l.instDefects(book.defects.length),
    ),
  );

  /// One summary per currency, each the whole tool whatever is filtered —
  /// the reader's own currency first.
  List<Widget> _summaries(
    AppLocalizations l,
    LumeFormatting f,
    InstallmentsBook book,
    bool withCode,
  ) {
    final LumeCurrency? mine = _currency();
    final List<InstallmentsCurrencySummary> sums =
        <InstallmentsCurrencySummary>[...book.summaries]..sort(
          (InstallmentsCurrencySummary a, InstallmentsCurrencySummary b) =>
              a.currency == mine
              ? -1
              : b.currency == mine
              ? 1
              : a.currency.compareTo(b.currency),
        );
    return <Widget>[
      for (final (int i, InstallmentsCurrencySummary s) in sums.indexed)
        LumeToolSection(
          title: sums.length > 1
              ? l.instSummaryCurrency(s.currency.code)
              : null,
          child: LumeSummaryCard(
            key: i == 0 ? LumeInstallmentsTool.summaryKey : null,
            kicker: l.instDueThisMonth,
            value: s.dueThisMonth == null
                ? l.instDayUnknown
                : f.amount(s.dueThisMonth!, compact: true, withCode: withCode),
            caption: l.instActivePlans(s.activePlans),
            stats: <LumeStat>[
              LumeStat(
                value: f.amount(s.remaining, compact: true, withCode: withCode),
                label: l.instRemaining,
              ),
              LumeStat(
                value: f.amount(
                  s.paidToDate,
                  compact: true,
                  withCode: withCode,
                ),
                label: l.instPaidToDate,
              ),
              LumeStat(
                value: s.lateInstallments == null
                    ? l.instDayUnknown
                    : f.integer(s.lateInstallments!),
                label: l.instLateInstalments,
              ),
            ],
          ),
        ),
    ];
  }

  /// "Due by month" in the reader's currency, or the first in use; the bars
  /// grow with their figures, and a screen reader hears each month and its
  /// amount in that currency — never raw numbers.
  Widget? _chart(
    AppLocalizations l,
    LumeFormatting f,
    InstallmentsBook book,
    bool withCode,
  ) {
    if (book.currencies.isEmpty) return null;
    final LumeCurrency? mine = _currency();
    final LumeCurrency c = book.currencies.contains(mine)
        ? mine!
        : book.currencies.first;
    final List<InstallmentsMonth>? months = book.months(c);
    if (months == null) return null;
    if (months.every((InstallmentsMonth m) => m.due.isZero)) return null;
    final List<String> amounts = <String>[
      for (final InstallmentsMonth m in months)
        f.amount(m.due, compact: true, withCode: withCode),
    ];
    return LumeToolSection(
      title: l.instDueByMonth,
      child: LumeCard(
        child: KeyedSubtree(
          key: LumeInstallmentsTool.chartKey,
          child: LumeBarChart(
            values: <double>[
              for (final InstallmentsMonth m in months) m.due.minor / c.scale,
            ],
            labels: <String>[
              for (final InstallmentsMonth m in months)
                f.monthNarrow(m.month.toCalendarDateTime()),
            ],
            valueLabels: amounts,
            highlight: 0,
            label: <String>[
              l.instDueByMonth,
              for (final (int i, InstallmentsMonth m) in months.indexed)
                l.instChartEntry(
                  f.monthLong(m.month.toCalendarDateTime()),
                  amounts[i],
                ),
            ].join('. '),
            caption: Text(
              <String>[
                l.instDueByMonthCap(c.code),
                if (book.currencies.length > 1) l.instOtherCurrencies,
              ].join(' '),
            ),
          ),
        ),
      ),
    );
  }

  void _order(List<InstallmentPlanView> plans) {
    int byName(InstallmentPlanView a, InstallmentPlanView b) {
      final int n = a.plan.item.toLowerCase().compareTo(
        b.plan.item.toLowerCase(),
      );
      return n != 0 ? n : a.plan.id.compareTo(b.plan.id);
    }

    int nextDue(InstallmentPlanView a, InstallmentPlanView b) {
      final LumeDate? x = a.status == InstallmentPlanStatus.active
          ? a.next?.row.due
          : null;
      final LumeDate? y = b.status == InstallmentPlanStatus.active
          ? b.next?.row.due
          : null;
      if (x == null || y == null) {
        return x == null ? (y == null ? byName(a, b) : 1) : -1;
      }
      final int c = x.compareTo(y);
      return c != 0 ? c : byName(a, b);
    }

    final int Function(InstallmentPlanView, InstallmentPlanView) compare =
        switch (_sort) {
          InstallmentsSort.next => nextDue,
          InstallmentsSort.left =>
            (InstallmentPlanView a, InstallmentPlanView b) {
              final int c = a.paymentsLeft.compareTo(b.paymentsLeft);
              return c != 0 ? c : byName(a, b);
            },
          InstallmentsSort.amount =>
            (InstallmentPlanView a, InstallmentPlanView b) {
              final int c = a.currency.compareTo(b.currency);
              if (c != 0) return c;
              final int m = a.plan.amount.compareTo(b.plan.amount);
              return m != 0 ? m : byName(a, b);
            },
          InstallmentsSort.name => byName,
          // Oldest first ascending; the bar picks a new sort descending, so
          // choosing it shows the most recent first.
          InstallmentsSort.recent =>
            (InstallmentPlanView a, InstallmentPlanView b) {
              final int c = a.lastActivity.compareTo(b.lastActivity);
              return c != 0 ? c : byName(a, b);
            },
        };
    plans.sort(
      _descending
          ? (InstallmentPlanView a, InstallmentPlanView b) => compare(b, a)
          : compare,
    );
  }

  (Color, Color) _tone(BuildContext context, LumeRecordId id) {
    final LumeColors lume = context.lume;
    // The reference's tinted discs: a tone chosen from the random record
    // id, so it is stable and says nothing about the plan.
    final List<(Color, Color)> tones = <(Color, Color)>[
      (lume.tone(lume.indigo), lume.indigo),
      (lume.toneAmber, lume.amber),
      (lume.tintAccent, lume.accent),
      (lume.tone(lume.violet), lume.violet),
      (lume.tone(lume.sky), lume.sky),
    ];
    return tones[id.value.codeUnits.fold<int>(0, (int a, int c) => a + c) %
        tones.length];
  }

  Widget _planRow(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    InstallmentPlanView v,
    LumeDate? today,
    bool withCode,
  ) {
    final (Color tone, Color ink) = _tone(context, v.plan.id);
    // The reference's disc carries the merchant's initials ("TM" for
    // TechMart); the item's where there is no merchant.
    final String? initials = LedgerText.initials(
      v.plan.merchant ?? v.plan.item,
    );
    final InstallmentRow? next = v.status == InstallmentPlanStatus.active
        ? v.next
        : null;
    final double progress = v.plan.count == 0 ? 0 : v.paidCount / v.plan.count;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LumeRichRow(
          key: LumeInstallmentsTool.row(v.plan.id.value),
          logo: initials,
          icon: initials == null ? LumeIcons.calendar : null,
          iconTone: tone,
          iconInk: ink,
          title: v.plan.item,
          subtitle: v.plan.merchant,
          meta: <String>[
            l.instPaidOf(f.integer(v.paidCount), f.integer(v.plan.count)),
            if (next != null)
              l.instNextOn(
                InstallmentsText.dateShort(f, next.row.due, today: today),
              ),
          ],
          badge: v.damaged
              ? LumeBadge(label: l.instNeedsAttention, tone: LumeBadgeTone.info)
              : v.status == InstallmentPlanStatus.cancelled
              ? LumeBadge(label: l.instFilterCancelled, tone: LumeBadgeTone.off)
              : v.status == InstallmentPlanStatus.completed
              ? LumeBadge(label: l.instFilterCompleted, tone: LumeBadgeTone.ok)
              : (v.late ?? false)
              ? LumeBadge(label: l.instFilterLate, tone: LumeBadgeTone.late_)
              : null,
          value: f.amount(v.plan.amount, compact: true, withCode: withCode),
          valueSub: l.instPerMonth,
          chevron: true,
          onTap: () => _go(_View.plan, plan: v.plan.id),
        ),
        // `.rowmeter` — progress by count, as the reference measures it.
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 10),
          child: LumeProgressBar(
            value: progress,
            label: v.plan.item,
            valueText: l.instProgressValue(
              f.percent((progress * 100).round(), decimals: 0),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ plan

  (String?, List<Widget>, bool) _planScreen(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    InstallmentsBook book,
    LumeDate? today,
    bool withCode,
  ) {
    final InstallmentPlanView? v = _plan == null ? null : book.plan(_plan!);
    if (v == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _go(_View.list));
      return (null, const <Widget>[], true);
    }
    final InstallmentPlan p = v.plan;
    String money(LumeMoney m) => f.amount(m, withCode: withCode);
    final InstallmentRow? next = v.status == InstallmentPlanStatus.active
        ? v.next
        : null;
    final double progress = p.count == 0 ? 0 : v.paidCount / p.count;
    return (
      p.item,
      <Widget>[
        const KeyedSubtree(
          key: LumeInstallmentsTool.planKey,
          child: SizedBox(),
        ),
        if (v.damaged)
          LumeToolSection(
            child: LumeNotice(
              key: LumeInstallmentsTool.damagedKey,
              kind: LumeNoticeKind.warning,
              title: l.instNeedsAttention,
              text: l.instDamagedText,
            ),
          ),
        LumeToolSection(
          child: LumeSummaryCard(
            kicker: l.instRemaining,
            value: f.amount(v.remaining, compact: true, withCode: withCode),
            caption: <String>[
              InstallmentsText.planStatus(l, v.status),
              l.instPaidOf(f.integer(v.paidCount), f.integer(p.count)),
              if (next != null)
                l.instNextOn(
                  InstallmentsText.date(f, next.row.due, today: today),
                ),
            ].join(' · '),
            // Compact on the card; exact, to the minor unit, in the facts.
            stats: <LumeStat>[
              LumeStat(
                value: f.amount(
                  v.paidToDate,
                  compact: true,
                  withCode: withCode,
                ),
                label: l.instPaidToDate,
              ),
              LumeStat(
                value: f.amount(
                  v.totalPayable,
                  compact: true,
                  withCode: withCode,
                ),
                label: l.instTotalPayable,
              ),
            ],
          ),
        ),
        LumeToolSection(
          spaceAbove: LumeToolSection.tightGap,
          child: LumeProgressBar(
            value: progress,
            label: p.item,
            valueText: l.instProgressValue(
              f.percent((progress * 100).round(), decimals: 0),
            ),
          ),
        ),
        LumeToolSection(
          child: LumeButtonRow(
            expand: false,
            children: <Widget>[
              if (next != null && !v.damaged)
                LumeButton.accent(
                  key: LumeInstallmentsTool.payKey,
                  label: l.instPayNext(f.integer(next.row.seq)),
                  icon: LumeIcons.checkCircle,
                  onPressed: () => unawaited(_pay(l, f, v, today, withCode)),
                ),
              if (!v.damaged)
                LumeButton(
                  key: LumeInstallmentsTool.editKey,
                  label: l.instEdit,
                  icon: LumeIcons.note,
                  onPressed: () => _editPlan(v),
                ),
              if (!v.damaged && v.status != InstallmentPlanStatus.completed)
                LumeButton(
                  key: p.cancelled
                      ? LumeInstallmentsTool.reinstateKey
                      : LumeInstallmentsTool.cancelKey,
                  label: p.cancelled ? l.instReinstate : l.instCancelPlan,
                  icon: p.cancelled ? LumeIcons.refresh : LumeIcons.x,
                  onPressed: () => unawaited(_cancel(l, v)),
                ),
              LumeButton.dangerGhost(
                key: LumeInstallmentsTool.deleteKey,
                label: l.instDeletePlan,
                icon: LumeIcons.trash,
                onPressed: () => unawaited(_delete(l, f, v)),
              ),
            ],
          ),
        ),
        LumeToolSection(
          child: LumeFactCard(
            facts: <LumeFact>[
              if (p.merchant case final String m)
                LumeFact(label: l.instFieldMerchant, value: m),
              LumeFact(label: l.instFieldAmount, value: money(p.amount)),
              LumeFact(label: l.instFieldCount, value: f.integer(p.count)),
              LumeFact(label: l.instFrequency, value: l.instMonthly),
              LumeFact(
                label: l.instFieldFirstDue,
                value: InstallmentsText.date(f, p.firstDue),
              ),
              LumeFact(
                label: l.instFieldDeposit,
                value: p.deposit == null
                    ? l.instNone
                    : '${money(p.deposit!)} · '
                          '${InstallmentsText.date(f, p.depositOn!)}',
              ),
              LumeFact(
                label: l.instScheduledTotal,
                value: money(v.scheduledTotal),
              ),
              LumeFact(label: l.instTotalPayable, value: money(v.totalPayable)),
              if (p.cashPrice case final LumeMoney cash) ...<LumeFact>[
                LumeFact(label: l.instFieldCashPrice, value: money(cash)),
                LumeFact(
                  label: l.instCashDifference,
                  value: money(v.cashDifference!),
                ),
              ],
              if (p.note case final String n)
                LumeFact(label: l.instFieldNote, value: n, block: true),
            ],
          ),
        ),
        if (p.cashPrice != null)
          LumeToolSection(
            spaceAbove: LumeToolSection.tightGap,
            child: Text(l.instCashDifferenceNote),
          ),
        LumeToolSection(
          title: l.instSchedule,
          child: LumeRows(
            key: LumeInstallmentsTool.scheduleKey,
            children: <Widget>[
              for (final InstallmentRow r in v.rows)
                LumeRichRow(
                  key: LumeInstallmentsTool.instalment(r.row.id.value),
                  title: l.instInstalmentOf(
                    f.integer(r.row.seq),
                    f.integer(p.count),
                  ),
                  meta: <String>[
                    l.instDueOn(
                      InstallmentsText.dateShort(f, r.row.due, today: today),
                    ),
                    if (r.payment case final InstallmentPayment x)
                      l.instPaidOn(
                        InstallmentsText.dateShort(f, x.paidOn, today: today),
                      ),
                  ],
                  badge: r.status == InstallmentStatus.upcoming
                      ? null
                      : LumeBadge(
                          label: InstallmentsText.status(l, r.status),
                          tone: InstallmentsText.tone(r.status),
                        ),
                  value: f.amount(
                    r.row.amount,
                    compact: true,
                    withCode: withCode,
                  ),
                  onTap: r.payment == null
                      ? null
                      : () => unawaited(
                          _paymentActions(l, f, v, r, r.payment!, withCode),
                        ),
                ),
            ],
          ),
        ),
        LumeToolSection(
          title: l.instPayments,
          child: v.payments.isEmpty
              ? Text(l.instNoPayments)
              : LumeRows(
                  key: LumeInstallmentsTool.paymentsKey,
                  children: <Widget>[
                    for (final InstallmentPayment x in v.payments)
                      () {
                        final InstallmentRow row = v.rows.firstWhere(
                          (InstallmentRow r) => r.row.id == x.installmentId,
                        );
                        return LumeCompactRow(
                          key: LumeInstallmentsTool.payment(x.id.value),
                          icon: x.voided ? LumeIcons.x : LumeIcons.checkCircle,
                          label: l.instInstalment(f.integer(row.row.seq)),
                          subtitle: <String>[
                            l.instPaidOn(
                              InstallmentsText.date(f, x.paidOn, today: today),
                            ),
                            if (x.voided) l.instVoided,
                          ].join(' · '),
                          value: f.amount(
                            x.amount,
                            compact: true,
                            withCode: withCode,
                          ),
                          onTap: () => unawaited(
                            _paymentActions(l, f, v, row, x, withCode),
                          ),
                        );
                      }(),
                  ],
                ),
        ),
      ],
      true,
    );
  }

  // ------------------------------------------------------------------ form

  List<Widget> _form(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
  ) {
    final _PlanDraft d = _draft!;
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
            key: LumeInstallmentsTool.lockedKey,
            kind: LumeNoticeKind.info,
            title: l.instLockedTitle,
            text: l.instLockedText,
          ),
        )
      else if (d.id != null)
        LumeToolSection(child: Text(l.instRebuildText)),
      LumeToolSection(
        child: LumeFormCard(
          key: LumeInstallmentsTool.formKey,
          children: <Widget>[
            LumeFormField(
              key: LumeInstallmentsTool.itemField,
              label: l.instFieldItem,
              controller: d.item,
              required: true,
              error: d.errors['item'],
              autofocus: d.id == null,
            ),
            LumeFormField(
              key: LumeInstallmentsTool.merchantField,
              label: l.instFieldMerchant,
              optionalLabel: l.commonOptional,
              controller: d.merchant,
              error: d.errors['merchant'],
            ),
            LumeFormPicker(
              key: LumeInstallmentsTool.currencyField,
              label: l.instFieldCurrency,
              value: d.currency?.code ?? '—',
              onTap: locked
                  ? null
                  : () => unawaited(
                      _pick<LumeCurrency>(
                        l.instFieldCurrency,
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
              key: LumeInstallmentsTool.amountField,
              label: l.instFieldAmount,
              controller: d.amount,
              kind: LumeFieldKind.money,
              prefix: d.currency?.code,
              required: true,
              enabled: !locked,
              error: d.errors['amount'],
            ),
            LumeFormField(
              key: LumeInstallmentsTool.countField,
              label: l.instFieldCount,
              controller: d.count,
              kind: LumeFieldKind.number,
              localDigits: true,
              required: true,
              enabled: !locked,
              error: d.errors['count'],
            ),
            LumeFormPicker(
              key: LumeInstallmentsTool.firstDueField,
              label: l.instFieldFirstDue,
              value: d.firstDue == null
                  ? l.instErrDate
                  : InstallmentsText.date(f, d.firstDue!),
              onTap: locked
                  ? null
                  : () => unawaited(
                      _date(d.firstDue, (LumeDate v) => d.firstDue = v),
                    ),
            ),
            ?error('firstDue'),
            LumeFormField(
              key: LumeInstallmentsTool.depositField,
              label: l.instFieldDeposit,
              optionalLabel: l.commonOptional,
              controller: d.deposit,
              kind: LumeFieldKind.money,
              prefix: d.currency?.code,
              enabled: !locked,
              error: d.errors['deposit'],
            ),
            LumeFormPicker(
              key: LumeInstallmentsTool.depositOnField,
              label: l.instFieldDepositOn,
              value: d.depositOn == null
                  ? '—'
                  : InstallmentsText.date(f, d.depositOn!),
              onTap: locked
                  ? null
                  : () => unawaited(
                      _date(d.depositOn, (LumeDate v) => d.depositOn = v),
                    ),
            ),
            ?error('depositOn'),
            LumeFormField(
              key: LumeInstallmentsTool.cashField,
              label: l.instFieldCashPrice,
              optionalLabel: l.commonOptional,
              controller: d.cash,
              kind: LumeFieldKind.money,
              prefix: d.currency?.code,
              error: d.errors['cash'],
            ),
            LumeFormField(
              key: LumeInstallmentsTool.noteField,
              label: l.instFieldNote,
              optionalLabel: l.commonOptional,
              controller: d.note,
              kind: LumeFieldKind.multiline,
              error: d.errors['note'],
            ),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeSubmitBar(
          saveLabel: l.actionSave,
          cancelLabel: l.actionCancel,
          onSave: () => unawaited(_savePlan(l)),
          onCancel: () => unawaited(_back()),
        ),
      ),
    ];
  }

  /// The reader's currency, those already in use, then every other one a
  /// new plan may use; a plan's own withdrawn currency only for that plan.
  List<LumeCurrency> _currencyChoices(_PlanDraft d) {
    final LumeCurrency? mine = _currency();
    final LumeCurrency? own = d.id == null ? null : d.currency;
    final InstallmentsBook book = _repo.view().book(null);
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

/// Lending Ledger — `tools/money/ledger.tool.js`, as a real record-backed
/// tool (`LEDGER_PROPOSAL.md`).
///
/// The reference's composition, in its order: the summary card, the filter
/// bar, People, Recent, the two buttons, then the frame's source line and
/// related tools. What it only drew, this does: people and entries are the
/// reader's own records (nothing seeded, D11), every figure is derived from
/// them and agrees with every other (§6), overdue comes from due dates and
/// the reader's own day, a row press opens the person, Add adds, the
/// reminder is a previewed hand-off that never claims delivery, and export
/// writes the whole ledger. Ledger is sensitive (D8): the frame shows its
/// privacy note and nothing here reaches Home.
///
/// A dedicated host (D10): the list, a person, an entry and the two forms
/// take the screen in turn; each write is one transaction through
/// [LedgerRepository], and each typed failure has its own answer — a credit
/// question, a conflict to resolve, a field to correct — with nothing
/// written until the reader decides.
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
import '../../../core/navigation/lume_tool_frame.dart';
import '../../../core/platform/lume_export.dart';
import '../../../core/platform/lume_share.dart';
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
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_crud.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../core/lume_build.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/domain/onboarding_state.dart';
import '../../records/domain/record_transaction.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/ledger_providers.dart';
import '../domain/ledger_book.dart';
import '../domain/ledger_failure.dart';
import '../domain/ledger_model.dart';
import '../domain/ledger_repository.dart';
import '../domain/ledger_transfer.dart';
import 'ledger_sheets.dart';
import 'ledger_text.dart';

enum LedgerFilter { all, owesYou, youOwe, overdue }

enum LedgerSort { due, amount, name, recent }

enum _View { list, person, entry, personForm, entryForm }

abstract final class LumeLedgerTool {
  static const String id = 'ledger';

  static const Key summaryKey = ValueKey<String>('ledger.summary');
  static const Key filterKey = ValueKey<String>('ledger.filter');
  static const Key searchKey = ValueKey<String>('ledger.search');
  static const Key sortKey = ValueKey<String>('ledger.sort');
  static const Key archivedKey = ValueKey<String>('ledger.archived');
  static const Key peopleKey = ValueKey<String>('ledger.people');
  static const Key recentKey = ValueKey<String>('ledger.recent');
  static const Key actionsKey = ValueKey<String>('ledger.actions');
  static const Key emptyKey = ValueKey<String>('ledger.empty');
  static const Key noMatchKey = ValueKey<String>('ledger.noMatch');
  static const Key dayUnknownKey = ValueKey<String>('ledger.dayUnknown');
  static const Key defectsKey = ValueKey<String>('ledger.defects');
  static const Key addKey = ValueKey<String>('ledger.add');
  static const Key remindKey = ValueKey<String>('ledger.remind');
  static const Key addPersonKey = ValueKey<String>('ledger.addPerson');
  static const Key personKey = ValueKey<String>('ledger.person');
  static const Key damagedKey = ValueKey<String>('ledger.damaged');
  static const Key reconcileKey = ValueKey<String>('ledger.reconcile');
  static const Key historyKey = ValueKey<String>('ledger.history');
  static const Key entryKey = ValueKey<String>('ledger.entry');
  static const Key formKey = ValueKey<String>('ledger.form');
  static const Key saveKey = ValueKey<String>('ledger.save');
  static const Key nameField = ValueKey<String>('ledger.field.name');
  static const Key noteField = ValueKey<String>('ledger.field.note');
  static const Key amountField = ValueKey<String>('ledger.field.amount');
  static const Key kindField = ValueKey<String>('ledger.field.kind');
  static const Key personField = ValueKey<String>('ledger.field.person');
  static const Key currencyField = ValueKey<String>('ledger.field.currency');
  static const Key dateField = ValueKey<String>('ledger.field.date');
  static const Key dueField = ValueKey<String>('ledger.field.due');
  static const Key applyField = ValueKey<String>('ledger.field.apply');
  static const Key voidKey = ValueKey<String>('ledger.void');
  static const Key deleteKey = ValueKey<String>('ledger.delete');
  static const Key editKey = ValueKey<String>('ledger.edit');
  static const Key settleKey = ValueKey<String>('ledger.settle');
  static const Key archiveKey = ValueKey<String>('ledger.archive');
  static const Key deletePersonKey = ValueKey<String>('ledger.deletePerson');
  static const Key personRemindKey = ValueKey<String>('ledger.personRemind');
  static const Key personAddKey = ValueKey<String>('ledger.personAdd');
  static Key filterChip(LedgerFilter f) =>
      ValueKey<String>('ledger.filter.${f.name}');
  static Key row(String party, String currency) =>
      ValueKey<String>('ledger.row.$party.$currency');
  static Key historyRow(String entry) =>
      ValueKey<String>('ledger.history.$entry');
  static Key applied(String principal) =>
      ValueKey<String>('ledger.applied.$principal');

  static Widget open(LumeToolRequest request) => LedgerTool(request: request);
}

class LedgerTool extends ConsumerStatefulWidget {
  const LedgerTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<LedgerTool> createState() => _LedgerToolState();
}

/// A person form's text.
class _PersonDraft {
  _PersonDraft({this.id, this.version, String name = '', String note = ''})
    : name = TextEditingController(text: name),
      note = TextEditingController(text: note);

  final LumeRecordId? id;
  final int? version;
  final TextEditingController name;
  final TextEditingController note;
  String? nameError;
  String? noteError;

  void dispose() {
    name.dispose();
    note.dispose();
  }
}

/// An entry form's state.
class _EntryDraft {
  _EntryDraft({
    this.id,
    this.version,
    required this.party,
    required this.kind,
    required this.currency,
    required this.on,
    this.due,
    String amount = '',
    String note = '',
  }) : amount = TextEditingController(text: amount),
       note = TextEditingController(text: note);

  final LumeRecordId? id;
  final int? version;
  LumeRecordId? party;
  LedgerKind kind;
  LumeCurrency? currency;

  /// The reader picked [currency] themselves; the form stops suggesting one.
  bool currencyChosen = false;
  LumeDate? on;
  LumeDate? due;
  final TextEditingController amount;
  final TextEditingController note;
  bool manual = false;
  final Map<LumeRecordId, TextEditingController> applied =
      <LumeRecordId, TextEditingController>{};
  final Map<String, String> errors = <String, String>{};

  TextEditingController appliedTo(LumeRecordId principal) =>
      applied.putIfAbsent(principal, TextEditingController.new);

  void dispose() {
    amount.dispose();
    note.dispose();
    for (final TextEditingController c in applied.values) {
      c.dispose();
    }
  }
}

class _LedgerToolState extends ConsumerState<LedgerTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LedgerRepository _repo = ref.read(ledgerRepositoryProvider);
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(
    text: _read('q') ?? '',
  );
  final FocusNode _searchFocus = FocusNode();

  /// The body, to find the frame's scroll from: a new view opens at its top,
  /// as Installments' do; a filter or a sort keeps the reader's place.
  final GlobalKey _body = GlobalKey();

  _View _view = _View.list;
  LumeRecordId? _person;
  LumeRecordId? _entry;
  _PersonDraft? _personDraft;
  _EntryDraft? _entryDraft;
  bool _linked = false;

  String get _id => widget.request.feature.id;
  String? _read(String key) => _session.read(_id, key);
  void _write(String key, String value) => _session.write(_id, key, value);

  LedgerFilter get _filter => LedgerFilter.values.firstWhere(
    (LedgerFilter f) => f.name == _read('filter'),
    orElse: () => LedgerFilter.all,
  );
  LedgerSort get _sort => LedgerSort.values.firstWhere(
    (LedgerSort s) => s.name == _read('sort'),
    orElse: () => LedgerSort.due,
  );
  bool get _descending => _read('dir') == 'desc';
  bool get _archived => _read('archived') == '1';

  @override
  void initState() {
    super.initState();
    _repo.open();
    _repo.changes.addListener(_changed);
    // Restoration: the person the reader had open in this session.
    final LumeRecordId? kept = LumeRecordId.tryParse(_read('person') ?? '');
    if (kept != null) {
      _person = kept;
      _view = _View.person;
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
    _personDraft?.dispose();
    _entryDraft?.dispose();
    super.dispose();
  }

  void _say(String message, {LumeToastTone tone = LumeToastTone.success}) =>
      _host.currentState?.say(message, tone: tone);

  // ---------------------------------------------------------------- context

  LumeProfileRecord get _profile =>
      ref.read(startupControllerProvider).state.profile;

  /// The reader's calendar date in their resolved zone, or `null` when it
  /// cannot be worked out (C88, C89): nothing is then overdue or not.
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
  /// new entry may use, or none.
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
    return ledgerDefaultCurrency(code);
  }

  // ------------------------------------------------------------ navigation

  void _go(_View v, {LumeRecordId? person, LumeRecordId? entry}) {
    final bool moved =
        v != _view ||
        (person != null && person != _person) ||
        (entry != null && entry != _entry);
    setState(() {
      _view = v;
      if (person != null) _person = person;
      if (entry != null) _entry = entry;
      _write('person', v == _View.list ? '' : (_person?.value ?? ''));
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

  void _back() {
    switch (_view) {
      case _View.list:
        widget.request.onBack?.call();
      case _View.person:
        _go(_View.list);
      case _View.entry:
        _go(_View.person);
      case _View.personForm:
        final LumeRecordId? id = _personDraft?.id;
        _personDraft?.dispose();
        _personDraft = null;
        _go(id == null ? _View.list : _View.person);
      case _View.entryForm:
        final _EntryDraft? d = _entryDraft;
        _entryDraft = null;
        d?.dispose();
        _go(
          d?.id != null
              ? _View.entry
              : (_person == null ? _View.list : _View.person),
        );
    }
  }

  void _addPerson() {
    _personDraft?.dispose();
    _personDraft = _PersonDraft();
    _go(_View.personForm);
  }

  void _editPerson(LedgerParty p) {
    _personDraft?.dispose();
    _personDraft = _PersonDraft(
      id: p.id,
      version: p.version,
      name: p.name,
      note: p.note ?? '',
    );
    _go(_View.personForm);
  }

  void _addEntry(
    LumeDate? today, {
    LumeRecordId? party,
    LedgerKind kind = LedgerKind.lent,
    LumeCurrency? currency,
    LumeMoney? amount,
  }) {
    _entryDraft?.dispose();
    _entryDraft = _EntryDraft(
      party: party,
      kind: kind,
      currency: currency ?? _currency(),
      on: today,
      amount: amount?.toDecimalString() ?? '',
    )..currencyChosen = currency != null;
    _go(_View.entryForm);
  }

  void _editEntry(LedgerEntry e, LedgerBook book) {
    _entryDraft?.dispose();
    final _EntryDraft d = _EntryDraft(
      id: e.id,
      version: e.version,
      party: e.partyId,
      kind: e.kind,
      currency: e.currency,
      on: e.on,
      due: e.due,
      amount: e.amount.toDecimalString(),
      note: e.note ?? '',
    );
    final List<LedgerAllocation> manual = <LedgerAllocation>[
      for (final LedgerAllocation a in book.allocationsOf(e.id))
        if (a.manual && a.repaymentId == e.id) a,
    ];
    if (manual.isNotEmpty) {
      d.manual = true;
      for (final LedgerAllocation a in manual) {
        d.appliedTo(a.principalId).text = a.amount.toDecimalString();
      }
    }
    _entryDraft = d;
    _go(_View.entryForm);
  }

  // ---------------------------------------------------------------- writes

  /// The answer to a failed write that is not the reader's to correct in a
  /// field: said, and nothing was written.
  void _failed(AppLocalizations l, LedgerFailure f) {
    _say(switch (f.kind) {
      LedgerFailureKind.conflict ||
      LedgerFailureKind.notFound => l.ledgerWriteConflict,
      LedgerFailureKind.damaged => l.ledgerWriteDamaged,
      LedgerFailureKind.partyOpen => l.ledgerArchiveOpen,
      LedgerFailureKind.partyReferenced => l.ledgerPersonReferenced(
        f.count ?? 1,
      ),
      LedgerFailureKind.overflow => l.ledgerErrTooLarge,
      _ => l.ledgerWriteFailed,
    }, tone: LumeToastTone.error);
  }

  /// Run [write]; on an overpayment ask whether the excess is credit, on a
  /// manual allocation that no longer fits whether to use oldest-due-first,
  /// and write again only on a yes.
  Future<LedgerResult<LedgerWrite>?> _resolve(
    LedgerResult<LedgerWrite> Function({bool confirmExcess, bool makeAutomatic})
    write, {
    required String name,
    required LedgerKind repaymentKind,
    required bool withCode,
    required LumeFormatting f,
  }) async {
    bool credit = false;
    bool automatic = false;
    for (int i = 0; i < 3; i++) {
      final LedgerResult<LedgerWrite> r = write(
        confirmExcess: credit,
        makeAutomatic: automatic,
      );
      final LedgerFailure? failure = r.failure;
      if (failure == null || !mounted) return r;
      if (failure.kind == LedgerFailureKind.overpayment && !credit) {
        credit = await ledgerConfirmCredit(
          context,
          f: f,
          name: name,
          excess: failure.excess,
          repaymentKind: repaymentKind,
          withCode: withCode,
        );
        if (!credit) return null;
      } else if (failure.kind == LedgerFailureKind.allocationConflict &&
          !automatic) {
        final AppLocalizations l = AppLocalizations.of(context);
        automatic =
            await ledgerDecide(
              context,
              title: l.ledgerConflictTitle,
              text: l.ledgerConflictText,
              confirm: l.ledgerApplyAuto,
            ) ??
            false;
        if (!automatic) return null;
      } else {
        return r;
      }
    }
    return null;
  }

  Future<void> _savePerson(AppLocalizations l) async {
    final _PersonDraft d = _personDraft!;
    setState(() {
      d.nameError = d.name.text.trim().isEmpty
          ? l.ledgerErrName
          : d.name.text.trim().length > kLedgerNameMax
          ? l.ledgerErrLong
          : null;
      d.noteError = d.note.text.length > kLedgerNoteMax
          ? l.ledgerErrLong
          : null;
    });
    if (d.nameError != null || d.noteError != null) return;
    if (d.id == null) {
      final LedgerResult<LedgerParty> r = _repo.addParty(
        d.name.text,
        note: d.note.text,
      );
      if (r.failure != null) return _failed(l, r.failure!);
      _personDraft = null;
      d.dispose();
      _say(l.ledgerSaved);
      _go(_View.person, person: r.value!.id);
    } else {
      final LedgerResult<LedgerWrite> r = _repo.renameParty(
        d.id!,
        d.name.text,
        note: d.note.text,
        version: d.version!,
      );
      if (r.failure != null) return _failed(l, r.failure!);
      _personDraft = null;
      d.dispose();
      _say(l.ledgerSaved);
      _go(_View.person, person: d.id);
    }
  }

  Future<void> _saveEntry(
    AppLocalizations l,
    LumeFormatting f,
    LedgerBook book,
    bool withCode,
  ) async {
    final _EntryDraft d = _entryDraft!;
    final Map<String, String> errors = <String, String>{};
    final intl.NumberFormat nf = intl.NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag().replaceAll('-', '_'),
    );
    final LedgerParty? party = d.party == null ? null : book.party(d.party!);
    if (party == null) errors['person'] = l.ledgerErrPerson;
    if (party != null && party.archived) {
      errors['person'] = l.ledgerErrArchived;
    }
    LumeMoney? amount;
    final LumeCurrency? currency = d.currency;
    if (currency == null) {
      errors['currency'] = l.ledgerErrPerson;
    } else if (party != null &&
        !ledgerCurrencyAvailability(
          book.entries,
          partyId: party.id,
          kind: d.kind,
          currency: currency,
          editing: d.id == null ? null : book.entry(d.id!),
        ).usable) {
      errors['currency'] = l.ledgerErrWithdrawn(currency.code);
    } else {
      final LedgerParsedAmount p = ledgerParseAmount(
        l,
        d.amount.text,
        currency,
        decimalSeparator: nf.symbols.DECIMAL_SEP,
        groupSeparator: nf.symbols.GROUP_SEP,
      );
      amount = p.money;
      if (p.error != null) errors['amount'] = p.error!;
    }
    if (d.on == null) errors['date'] = l.ledgerErrDate;
    if (d.kind.isPrincipal &&
        d.due != null &&
        d.on != null &&
        d.due!.isBefore(d.on!)) {
      errors['due'] = l.ledgerErrDueBefore;
    }
    if (d.note.text.length > kLedgerNoteMax) errors['note'] = l.ledgerErrLong;

    // The reader's own allocation, where they chose one.
    List<LedgerManualDraft>? manual;
    if (d.kind.isRepayment && d.manual && currency != null && party != null) {
      manual = <LedgerManualDraft>[];
      LumeMoney total = LumeMoney.zero(currency);
      for (final (LedgerPrincipalState p, LumeMoney open) in _openFor(
        book,
        d,
      )) {
        final String text = d.appliedTo(p.entry.id).text.trim();
        if (text.isEmpty) continue;
        final LedgerParsedAmount a = ledgerParseAmount(
          l,
          text,
          currency,
          decimalSeparator: nf.symbols.DECIMAL_SEP,
          groupSeparator: nf.symbols.GROUP_SEP,
        );
        if (a.error != null) {
          errors['applied.${p.entry.id}'] = a.error!;
          continue;
        }
        if (a.money!.compareTo(open) > 0) {
          errors['applied.${p.entry.id}'] = l.ledgerErrAppliedOver;
          continue;
        }
        total += a.money!;
        manual.add(LedgerManualDraft(p.entry.id, a.money!));
      }
      if (amount != null && total.compareTo(amount) > 0) {
        errors['apply'] = l.ledgerErrApplied;
      }
    }
    setState(() {
      d.errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) return;

    final LedgerEntryDraft draft = LedgerEntryDraft(
      partyId: party!.id,
      kind: d.kind,
      amount: amount!,
      on: d.on!,
      due: d.kind.isPrincipal ? d.due : null,
      note: d.note.text,
    );
    final LedgerResult<LedgerWrite>? r = await _resolve(
      ({bool confirmExcess = false, bool makeAutomatic = false}) => d.id == null
          ? _repo.addEntry(draft, manual: manual, confirmExcess: confirmExcess)
          : _repo.editEntry(
              d.id!,
              draft,
              version: d.version!,
              manual: d.kind.isRepayment
                  ? (manual ?? const <LedgerManualDraft>[])
                  : null,
              confirmExcess: confirmExcess,
              makeAutomatic: makeAutomatic,
            ),
      name: party.name,
      repaymentKind: d.kind.isRepayment ? d.kind : d.kind.counterpart,
      withCode: withCode,
      f: f,
    );
    if (r == null || !mounted) return;
    final LedgerFailure? failure = r.failure;
    if (failure != null) {
      if (failure.kind == LedgerFailureKind.validation) {
        setState(
          () =>
              d.errors[switch (failure.field) {
                'allocation' => 'apply',
                final String? f => f ?? 'amount',
              }] = switch (failure.reason) {
                'zero' => l.ledgerErrAmount,
                'beforeDate' => l.ledgerErrDueBefore,
                'withdrawn' => l.ledgerErrWithdrawn(currency!.code),
                'archived' => l.ledgerErrArchived,
                'long' => l.ledgerErrLong,
                _ => l.ledgerErrApplied,
              },
        );
        return;
      }
      if (failure.kind == LedgerFailureKind.overflow) {
        setState(() => d.errors['amount'] = l.ledgerErrTooLarge);
        return;
      }
      return _failed(l, failure);
    }
    _entryDraft = null;
    d.dispose();
    _say(l.ledgerSaved);
    _go(_View.person, person: party.id);
  }

  /// Open principals this repayment may pay: the counterpart kind, this
  /// person and currency, with what is open on each plus what this entry
  /// already paid it.
  List<(LedgerPrincipalState, LumeMoney)> _openFor(
    LedgerBook book,
    _EntryDraft d,
  ) {
    if (d.party == null || d.currency == null || !d.kind.isRepayment) {
      return const <(LedgerPrincipalState, LumeMoney)>[];
    }
    final LedgerBalance? b = book
        .balancesOf(d.party!)
        .where((LedgerBalance x) => x.currency == d.currency)
        .firstOrNull;
    if (b == null) return const <(LedgerPrincipalState, LumeMoney)>[];
    return <(LedgerPrincipalState, LumeMoney)>[
      for (final LedgerPrincipalState p in b.principals)
        if (p.entry.kind == d.kind.counterpart)
          if (_openPlusMine(book, d, p) case final LumeMoney open
              when open.isPositive)
            (p, open),
    ];
  }

  LumeMoney _openPlusMine(
    LedgerBook book,
    _EntryDraft d,
    LedgerPrincipalState p,
  ) {
    LumeMoney open = p.remaining;
    if (d.id != null) {
      for (final LedgerAllocation a in book.allocationsOf(p.entry.id)) {
        if (a.repaymentId == d.id) open += a.amount;
      }
    }
    return open;
  }

  Future<void> _setVoided(
    AppLocalizations l,
    LumeFormatting f,
    LedgerBook book,
    LedgerEntry e,
    bool withCode,
  ) async {
    final LedgerParty? party = book.party(e.partyId);
    final LedgerResult<LedgerWrite>? r = await _resolve(
      ({bool confirmExcess = false, bool makeAutomatic = false}) =>
          _repo.setVoided(
            e.id,
            e.active,
            version: e.version,
            confirmExcess: confirmExcess,
            makeAutomatic: makeAutomatic,
          ),
      name: party?.name ?? '',
      repaymentKind: e.kind.isRepayment ? e.kind : e.kind.counterpart,
      withCode: withCode,
      f: f,
    );
    if (r == null || !mounted) return;
    if (r.failure != null) return _failed(l, r.failure!);
    _say(e.active ? l.ledgerVoidedToast : l.ledgerUnvoidedToast);
  }

  Future<void> _deleteEntry(
    AppLocalizations l,
    LumeFormatting f,
    LedgerBook book,
    LedgerEntry e,
    bool withCode,
  ) async {
    if (!await ledgerConfirmDelete(
      context,
      title: l.ledgerDeleteEntryTitle,
      text: l.ledgerDeleteEntryText,
    )) {
      return;
    }
    LedgerResult<LedgerWrite> r = _repo.deleteEntry(e.id, version: e.version);
    if (r.failure?.kind == LedgerFailureKind.overpayment && mounted) {
      final bool? choice = await ledgerDecide(
        context,
        title: l.ledgerOrphanTitle,
        text: l.ledgerOrphanText(
          r.failure!.excess
              .map(
                (LumeMoney m) => f.amount(m, withCode: withCode, isolate: true),
              )
              .join(', '),
        ),
        confirm: l.ledgerKeepCredit,
        alternative: l.ledgerOrphanDelete,
      );
      if (choice == null) return;
      r = _repo.deleteEntry(
        e.id,
        version: e.version,
        orphans: choice
            ? LedgerOrphanChoice.keepAsCredit
            : LedgerOrphanChoice.deleteRepayments,
      );
    }
    if (!mounted) return;
    if (r.failure != null) return _failed(l, r.failure!);
    final LedgerWrite write = r.value!;
    _go(_View.person);
    _host.currentState?.say(
      l.ledgerDeleted,
      actionLabel: l.recUndo,
      onAction: () {
        final LedgerResult<void> back = _repo.undo(write);
        if (back.failure != null) return _failed(l, back.failure!);
        _say(l.ledgerRestoredToast);
      },
    );
  }

  Future<void> _setArchived(AppLocalizations l, LedgerParty p) async {
    final LedgerResult<LedgerWrite> r = _repo.setArchived(
      p.id,
      !p.archived,
      version: p.version,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _say(p.archived ? l.ledgerUnarchivedToast : l.ledgerArchivedToast);
  }

  Future<void> _deletePerson(
    AppLocalizations l,
    LedgerBook book,
    LedgerParty p,
  ) async {
    final int count = book.entriesOf(p.id).length;
    if (count > 0) {
      _say(l.ledgerPersonReferenced(count), tone: LumeToastTone.info);
      return;
    }
    if (!await ledgerConfirmDelete(
      context,
      title: l.ledgerDeletePersonTitle,
      text: l.ledgerDeletePersonText,
    )) {
      return;
    }
    final LedgerResult<LedgerWrite> r = _repo.deleteParty(
      p.id,
      version: p.version,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _say(l.ledgerPersonDeleted);
    _go(_View.list);
  }

  Future<void> _settle(
    AppLocalizations l,
    LumeFormatting f,
    LedgerBalance b,
    LedgerKind principalKind,
    LumeDate? today,
    bool withCode,
  ) async {
    final LedgerSettlePreview? preview = LedgerSettlePreview.of(
      b,
      principalKind,
    );
    if (preview == null) return;
    if (today == null) {
      // No day to date it with: the form, prefilled, asks for one.
      return _addEntry(
        null,
        party: b.party.id,
        kind: preview.kind,
        currency: b.currency,
        amount: preview.amount,
      );
    }
    if (!await ledgerConfirmSettle(
      context,
      f: f,
      preview: preview,
      balance: b,
      withCode: withCode,
    )) {
      return;
    }
    final LedgerResult<LedgerWrite> r = _repo.addEntry(
      LedgerEntryDraft(
        partyId: b.party.id,
        kind: preview.kind,
        amount: preview.amount,
        on: today,
      ),
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _say(l.ledgerSaved);
  }

  Future<void> _remind(
    AppLocalizations l,
    LumeFormatting f,
    LedgerBook book,
    bool withCode, {
    LedgerBalance? only,
  }) async {
    final List<LedgerBalance> eligible = only != null
        ? <LedgerBalance>[only]
        : <LedgerBalance>[
            for (final LedgerBalance b in book.balances)
              if (!b.party.archived && ledgerRemindable(b)) b,
          ];
    final LumeShareOutcome? outcome = await LedgerReminderSheet.show(
      context,
      balances: eligible,
      f: f,
      withCode: withCode,
      sharer: ref.read(textSharerProvider),
      initial: only,
    );
    if (outcome == LumeShareOutcome.shared) _say(l.ledgerRemindHanded);
  }

  Future<void> _export(AppLocalizations l, LedgerBook book) async {
    final LedgerExportChoice? choice = await showLumeSheet<LedgerExportChoice>(
      context: context,
      barrierLabel: l.ledgerExportTitle,
      child: LedgerExportSheet(onImport: () => unawaited(_import(l))),
    );
    if (choice == null || !mounted) return;
    final DateTime now = LumeClockScope.of(context).now();
    final LumeExportFile file = LumeExportFile.document(
      tool: _id,
      day: now,
      format: choice.json ? LumeExportFormat.json : LumeExportFormat.csv,
      text: choice.json
          ? ledgerExportJson(
              parties: book.parties,
              entries: book.entries,
              allocations: book.allocations,
              exportedAt: now,
              build: kLumeVersion,
              durable: _repo.durable,
              includePrivate: choice.includePrivate,
            )
          : ledgerExportCsv(book, includePrivate: choice.includePrivate),
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

  Future<void> _import(AppLocalizations l) async {
    final LedgerImportReport? report = await showLumeSheet<LedgerImportReport>(
      context: context,
      barrierLabel: l.ledgerImport,
      child: LedgerImportSheet(store: ref.read(recordRepositoryProvider)),
    );
    if (report == null || !mounted) return;
    final LumeTxResult<int> r = ledgerImportApply(
      report,
      ref.read(recordRepositoryProvider),
    );
    if (!r.ok) {
      _say(l.ledgerWriteFailed, tone: LumeToastTone.error);
      return;
    }
    _say(l.ledgerImported(r.value!));
  }

  Future<void> _repair(AppLocalizations l, LumeRecordId party) async {
    LedgerResult<LedgerWrite> r = _repo.repair(party);
    if (r.failure != null &&
        (r.failure!.kind == LedgerFailureKind.overpayment ||
            r.failure!.kind == LedgerFailureKind.allocationConflict) &&
        mounted) {
      final bool? go = await ledgerDecide(
        context,
        title: l.ledgerReconcile,
        text: l.ledgerDamagedText,
        confirm: l.ledgerReconcile,
      );
      if (go != true) return;
      r = _repo.repair(party, confirmExcess: true, makeAutomatic: true);
    }
    if (r.failure != null) return _failed(l, r.failure!);
    _say(l.ledgerReconciled);
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
    final LedgerSnapshot snapshot = _repo.view();

    LedgerBook? book;
    LumeToolStatus status = LumeToolStatus.ready;
    if (snapshot.loading) {
      status = LumeToolStatus.loading;
    } else if (snapshot.failed) {
      status = LumeToolStatus.error;
    } else {
      try {
        book = snapshot.book(today);
      } on LumeMoneyException {
        status = LumeToolStatus.error;
      }
    }
    if (book != null && !_linked) {
      _linked = true;
      _deepLink(l, book);
    }
    // A second currency on screen: every amount carries its code, so a
    // shared symbol never stands for two currencies.
    final bool withCode =
        book != null &&
        <LumeCurrency>{
              for (final LedgerEntry e in book.entries) e.currency,
            }.length >
            1;

    final (String? title, List<Widget> body, bool bare) = switch (_view) {
      _ when book == null => (null, const <Widget>[], false),
      _View.list => (null, _list(context, l, f, book, today, withCode), false),
      _View.person => _personScreen(context, l, f, book, today, withCode),
      _View.entry => _entryScreen(context, l, f, book, today, withCode),
      _View.personForm => (
        _personDraft?.id == null ? l.ledgerNewPerson : l.ledgerRename,
        _personForm(l),
        true,
      ),
      _View.entryForm => (
        _entryDraft?.id == null ? l.ledgerNewEntry : l.ledgerEditEntry,
        _entryForm(context, l, f, book, withCode),
        true,
      ),
    };

    return PopScope(
      canPop: _view == _View.list,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _back();
      },
      child: LumeToolScreen(
        key: _host,
        feature: widget.request.feature,
        user: widget.request.user,
        onBack: _back,
        onOpenRelated: widget.request.onOpenRelated,
        status: status,
        onRetry: () => setState(_repo.retry),
        title: title,
        bare: bare,
        actions: LumeToolActions(
          onExport: book == null || book.isEmpty
              ? null
              : () => unawaited(_export(l, book!)),
          onSearch: () {
            if (_view != _View.list) _go(_View.list);
            _searchFocus.requestFocus();
          },
        ),
        headerActions: _view == _View.personForm || _view == _View.entryForm
            ? <Widget>[
                LumeTextButton(
                  key: LumeLedgerTool.saveKey,
                  label: l.actionSave,
                  onPressed: () => _view == _View.personForm
                      ? unawaited(_savePerson(l))
                      : unawaited(_saveEntry(l, f, book!, withCode)),
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

  void _deepLink(AppLocalizations l, LedgerBook book) {
    final String? asked = widget.request.query['person'];
    if (asked == null) {
      // A restored person that has since gone opens the list.
      if (_person != null && book.party(_person!) == null) {
        _view = _View.list;
        _person = null;
      }
      return;
    }
    final LumeRecordId? id = LumeRecordId.tryParse(asked);
    if (id != null && book.party(id) != null) {
      _person = id;
      _view = _View.person;
      return;
    }
    _view = _View.list;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _say(l.ledgerNotFound, tone: LumeToastTone.info),
    );
  }

  // ------------------------------------------------------------------ list

  List<Widget> _list(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LedgerBook book,
    LumeDate? today,
    bool withCode,
  ) {
    if (book.parties.isEmpty) {
      return <Widget>[
        LumeToolSection(
          child: LumeToolState(
            key: LumeLedgerTool.emptyKey,
            icon: LumeIcons.users,
            title: l.ledgerEmptyTitle,
            text: l.ledgerEmptyText,
            action: LumeButton.accent(
              key: LumeLedgerTool.addPersonKey,
              label: l.ledgerAddPerson,
              icon: LumeIcons.plus,
              onPressed: _addPerson,
            ),
          ),
        ),
        if (book.defects.isNotEmpty) _defects(l, book),
      ];
    }
    final LedgerFilter filter = _filter;
    final String q = LedgerText.fold(_query.text);
    final bool archived = _archived;
    final List<_Row> rows = _rows(book)
        .where((_Row r) => archived || !r.party.archived)
        .where(
          (_Row r) =>
              q.isEmpty ||
              LedgerText.fold(
                <String>[
                  r.party.name,
                  r.party.note ?? '',
                  for (final LedgerEntry e in book.entriesOf(r.party.id))
                    e.note ?? '',
                ].join(' '),
              ).contains(q),
        )
        .where(
          (_Row r) => switch (filter) {
            LedgerFilter.all => true,
            LedgerFilter.owesYou =>
              r.balance?.direction == LedgerDirection.owesYou,
            LedgerFilter.youOwe =>
              r.balance?.direction == LedgerDirection.youOwe,
            LedgerFilter.overdue => r.balance?.overdue ?? false,
          },
        )
        .toList();
    _order(rows);

    final List<LedgerEntry> recent = book.recent.take(5).toList();

    return <Widget>[
      ..._summaries(context, l, f, book, withCode),
      if (book.defects.isNotEmpty) _defects(l, book),
      LumeToolSection(
        spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
        child: Semantics(
          label: l.ledgerFilterLabel,
          container: true,
          child: LumeFilterBar(
            key: LumeLedgerTool.filterKey,
            gutters: false,
            children: <Widget>[
              for (final (LedgerFilter v, String label)
                  in <(LedgerFilter, String)>[
                    (LedgerFilter.all, l.commonAll),
                    (LedgerFilter.owesYou, l.ledgerFilterOwesYou),
                    (LedgerFilter.youOwe, l.ledgerYouOwe),
                    (LedgerFilter.overdue, l.commonOverdue),
                  ])
                LumeFilterChip(
                  key: LumeLedgerTool.filterChip(v),
                  label: label,
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
          key: LumeLedgerTool.searchKey,
          controller: _query,
          focusNode: _searchFocus,
          placeholder: l.ledgerSearch,
          semanticLabel: l.ledgerSearch,
          onChanged: (String v) => setState(() => _write('q', v)),
          onClear: () => setState(() {
            _query.clear();
            _write('q', '');
          }),
        ),
      ),
      LumeToolSection(
        spaceAbove: LumeToolSection.tightGap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            LumeSortBar(
              key: LumeLedgerTool.sortKey,
              label: l.commonSort,
              value: _sort.name,
              direction: _descending
                  ? LumeSortDirection.descending
                  : LumeSortDirection.ascending,
              items: <LumeChoice>[
                LumeChoice(value: LedgerSort.due.name, label: l.ledgerSortDue),
                LumeChoice(
                  value: LedgerSort.amount.name,
                  label: l.commonAmount,
                ),
                LumeChoice(
                  value: LedgerSort.name.name,
                  label: l.ledgerSortName,
                ),
                LumeChoice(
                  value: LedgerSort.recent.name,
                  label: l.ledgerSortRecent,
                ),
              ],
              onChanged: (String v, LumeSortDirection d) => setState(() {
                _write('sort', v);
                _write(
                  'dir',
                  d == LumeSortDirection.descending ? 'desc' : 'asc',
                );
              }),
            ),
            if (book.parties.any((LedgerParty p) => p.archived))
              Row(
                children: <Widget>[
                  Expanded(child: Text(l.ledgerShowArchived)),
                  LumeSwitch(
                    key: LumeLedgerTool.archivedKey,
                    value: archived,
                    semanticLabel: l.ledgerShowArchived,
                    onChanged: (bool v) =>
                        setState(() => _write('archived', v ? '1' : '')),
                  ),
                ],
              ),
          ],
        ),
      ),
      LumeToolSection(
        title: l.ledgerPeople,
        link: l.ledgerAddPerson,
        onLinkTap: _addPerson,
        child: switch (null) {
          _ when filter == LedgerFilter.overdue && today == null =>
            LumeToolState(
              key: LumeLedgerTool.dayUnknownKey,
              icon: LumeIcons.clock,
              title: l.recZoneUnknownTitle,
              text: l.ledgerOverdueUnknown,
            ),
          _ when rows.isEmpty => LumeToolState(
            key: LumeLedgerTool.noMatchKey,
            icon: LumeIcons.users,
            title: l.ledgerNoMatch,
            text: l.ledgerNoMatchText,
            action: LumeButton(
              label: l.ledgerShowAll,
              icon: LumeIcons.refresh,
              onPressed: () => setState(() {
                _write('filter', LedgerFilter.all.name);
                _query.clear();
                _write('q', '');
              }),
            ),
          ),
          _ => LumeRows(
            key: LumeLedgerTool.peopleKey,
            children: <Widget>[
              for (final _Row r in rows)
                _personRow(context, l, f, book, r, withCode),
            ],
          ),
        },
      ),
      if (recent.isNotEmpty)
        LumeToolSection(
          title: l.ledgerRecent,
          child: LumeRows(
            key: LumeLedgerTool.recentKey,
            children: <Widget>[
              for (final LedgerEntry e in recent)
                _recentRow(l, f, book, e, today, withCode),
            ],
          ),
        ),
      LumeToolSection(
        child: LumeButtonRow(
          key: LumeLedgerTool.actionsKey,
          children: <Widget>[
            LumeButton.accent(
              key: LumeLedgerTool.addKey,
              label: l.ledgerAdd,
              icon: LumeIcons.plus,
              onPressed: () => _addEntry(today),
            ),
            LumeButton(
              key: LumeLedgerTool.remindKey,
              label: l.ledgerRemind,
              icon: LumeIcons.bell,
              onPressed: () => unawaited(_remind(l, f, book, withCode)),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _defects(AppLocalizations l, LedgerBook book) => LumeToolSection(
    child: LumeNotice(
      key: LumeLedgerTool.defectsKey,
      kind: LumeNoticeKind.warning,
      title: l.ledgerNeedsReconcile,
      text: l.ledgerDefects(book.defects.length),
    ),
  );

  /// One summary per currency, each the whole ledger whatever is filtered;
  /// People, the one global count, on the first.
  List<Widget> _summaries(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LedgerBook book,
    bool withCode,
  ) {
    final LumeCurrency? mine = _currency();
    final List<LedgerCurrencySummary> sums = <LedgerCurrencySummary>[
      ...book.summaries,
    ];
    if (sums.isEmpty && mine != null) {
      sums.add(
        LedgerCurrencySummary(mine, LumeMoney.zero(mine), LumeMoney.zero(mine)),
      );
    }
    // The reader's own currency first.
    sums.sort(
      (LedgerCurrencySummary a, LedgerCurrencySummary b) => a.currency == mine
          ? -1
          : b.currency == mine
          ? 1
          : a.currency.compareTo(b.currency),
    );
    return <Widget>[
      for (final (int i, LedgerCurrencySummary s) in sums.indexed)
        LumeToolSection(
          title: sums.length > 1
              ? l.ledgerSummaryCurrency(s.currency.code)
              : null,
          child: LumeSummaryCard(
            key: i == 0 ? LumeLedgerTool.summaryKey : null,
            kicker: l.ledgerNet,
            value: f.amount(s.net, compact: true, withCode: withCode),
            caption: s.net.isPositive
                ? l.ledgerOwedOverall
                : s.net.isNegative
                ? l.ledgerOweOverall
                : l.ledgerEvenOverall,
            stats: <LumeStat>[
              LumeStat(
                value: f.amount(s.owedToYou, compact: true, withCode: withCode),
                label: l.ledgerOwedToYou,
              ),
              LumeStat(
                value: f.amount(s.youOwe, compact: true, withCode: withCode),
                label: l.ledgerYouOwe,
              ),
              if (i == 0)
                LumeStat(value: f.integer(book.people), label: l.ledgerPeople),
            ],
          ),
        ),
    ];
  }

  /// A person's rows: one per currency with active entries, or one "No
  /// entries yet" row.
  List<_Row> _rows(LedgerBook book) => <_Row>[
    for (final LedgerParty p in book.parties)
      if (book.balancesOf(p.id) case final List<LedgerBalance> bs
          when bs.isNotEmpty)
        for (final LedgerBalance b in bs) _Row(p, b)
      else
        _Row(p, null),
  ];

  void _order(List<_Row> rows) {
    int rank(_Row r) => switch (r.balance) {
      null => 3,
      final LedgerBalance b when b.overdue ?? false => 0,
      final LedgerBalance b when b.direction == LedgerDirection.settled => 2,
      _ => 1,
    };
    int byName(_Row a, _Row b) {
      final int n = a.party.name.toLowerCase().compareTo(
        b.party.name.toLowerCase(),
      );
      return n != 0 ? n : a.party.id.compareTo(b.party.id);
    }

    int byAmount(_Row a, _Row b) {
      final LedgerBalance? x = a.balance;
      final LedgerBalance? y = b.balance;
      if (x == null || y == null) return x == null ? (y == null ? 0 : 1) : -1;
      final int c = x.currency.compareTo(y.currency);
      return c != 0 ? c : y.balance.magnitude.compareTo(x.balance.magnitude);
    }

    final int Function(_Row, _Row) compare = switch (_sort) {
      LedgerSort.due => (_Row a, _Row b) {
        final int r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        if (rank(a) == 0) {
          final int d = a.balance!.shownDue!.compareTo(b.balance!.shownDue!);
          if (d != 0) return d;
        }
        if (rank(a) == 1) {
          final int m = byAmount(a, b);
          if (m != 0) return m;
        }
        return byName(a, b);
      },
      LedgerSort.amount => (_Row a, _Row b) {
        final int m = byAmount(a, b);
        return m != 0 ? m : byName(a, b);
      },
      LedgerSort.name => byName,
      LedgerSort.recent => (_Row a, _Row b) {
        final LedgerEntry? x = a.balance?.lastActivity;
        final LedgerEntry? y = b.balance?.lastActivity;
        if (x == null || y == null) {
          return x == null ? (y == null ? byName(a, b) : 1) : -1;
        }
        final int r = ledgerRecentOrder(x, y);
        return r != 0 ? r : byName(a, b);
      },
    };
    rows.sort(_descending ? (_Row a, _Row b) => compare(b, a) : compare);
  }

  Widget _personRow(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LedgerBook book,
    _Row r,
    bool withCode,
  ) {
    final LumeColors lume = context.lume;
    // The reference's tinted discs: a tone chosen from the random record
    // id, so it is stable and says nothing about the person.
    final List<(Color, Color)> tones = <(Color, Color)>[
      (lume.tintAccent, lume.accent),
      (lume.tone(lume.violet), lume.violet),
      (lume.toneAmber, lume.amber),
      (lume.tone(lume.sky), lume.sky),
      (lume.tone(lume.rose), lume.rose),
    ];
    final (Color tone, Color ink) =
        tones[r.party.id.value.codeUnits.fold<int>(0, (int a, int c) => a + c) %
            tones.length];
    final LedgerBalance? b = r.balance;
    final String? initials = LedgerText.initials(r.party.name);
    final List<LedgerEntry> entries = <LedgerEntry>[
      if (b != null)
        for (final LedgerPrincipalState p in b.principals) p.entry,
    ];
    final LumeDate? since = entries.isEmpty
        ? null
        : entries
              .map((LedgerEntry e) => e.on)
              .reduce((LumeDate x, LumeDate y) => x.isBefore(y) ? x : y);
    final String? credit = b == null
        ? null
        : b.creditToThem.isPositive
        ? l.ledgerCreditToThem(
            f.amount(b.creditToThem, compact: true, withCode: withCode),
          )
        : b.creditFromThem.isPositive
        ? l.ledgerCreditFromThem(
            f.amount(b.creditFromThem, compact: true, withCode: withCode),
          )
        : null;
    // What it was for: the person's own note, else the latest loan's.
    final String? why =
        r.party.note ??
        (<LedgerEntry>[...entries]..sort(ledgerRecentOrder))
            .where((LedgerEntry e) => e.note != null)
            .firstOrNull
            ?.note;
    return LumeRichRow(
      key: LumeLedgerTool.row(r.party.id.value, b?.currency.code ?? '-'),
      logo: initials,
      icon: initials == null ? LumeIcons.user : null,
      iconTone: tone,
      iconInk: ink,
      title: r.party.name,
      subtitle: credit ?? why,
      // The reference's meta: the date it began, then when it is due.
      meta: <String>[
        if (since != null) f.dateMedium(since.toCalendarDateTime()),
        if (b?.shownDue case final LumeDate due)
          l.ledgerDue(f.dateMedium(due.toCalendarDateTime())),
        if (b == null) l.ledgerNoEntries,
      ],
      badge: b?.damaged ?? false
          ? LumeBadge(label: l.ledgerNeedsReconcile, tone: LumeBadgeTone.info)
          : b?.overdue ?? false
          ? LumeBadge(label: l.commonOverdue, tone: LumeBadgeTone.warn)
          : r.party.archived
          ? LumeBadge(label: l.ledgerArchivedBadge)
          : null,
      value: b == null
          ? null
          : f.amount(b.balance, compact: true, withCode: withCode),
      valueSub: b == null ? null : LedgerText.direction(l, b.direction),
      chevron: true,
      onTap: () => _go(_View.person, person: r.party.id),
    );
  }

  Widget _recentRow(
    AppLocalizations l,
    LumeFormatting f,
    LedgerBook book,
    LedgerEntry e,
    LumeDate? today,
    bool withCode,
  ) {
    final bool out = LedgerText.moneyOut(e.kind);
    return Semantics(
      label: out ? l.ledgerMoneyOut : l.ledgerMoneyIn,
      child: LumeCompactRow(
        icon: out ? LumeIcons.arrowUr : LumeIcons.arrowDown,
        label: book.party(e.partyId)?.name ?? '—',
        subtitle: <String>[
          LedgerText.kind(l, e.kind),
          LedgerText.date(f, e.on, today: today),
          if (e.voided) l.ledgerVoided,
        ].join(' · '),
        value: f.amount(e.amount, compact: true, withCode: withCode),
        onTap: () => _go(_View.entry, person: e.partyId, entry: e.id),
      ),
    );
  }

  // ---------------------------------------------------------------- person

  (String?, List<Widget>, bool) _personScreen(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LedgerBook book,
    LumeDate? today,
    bool withCode,
  ) {
    final LedgerParty? p = _person == null ? null : book.party(_person!);
    if (p == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _go(_View.list));
      return (null, const <Widget>[], true);
    }
    final List<LedgerBalance> balances = book.balancesOf(p.id);
    final List<LedgerEntry> history = book.entriesOf(p.id);
    return (
      p.name,
      <Widget>[
        const KeyedSubtree(key: LumeLedgerTool.personKey, child: SizedBox()),
        if (p.note != null) LumeToolSection(child: Text(p.note!)),
        for (final LedgerBalance b in balances) ...<Widget>[
          if (b.damaged)
            LumeToolSection(
              child: LumeNotice(
                key: LumeLedgerTool.damagedKey,
                kind: LumeNoticeKind.warning,
                title: l.ledgerNeedsReconcile,
                text: l.ledgerDamagedText,
                actions: <Widget>[
                  LumeNoticeAction(
                    key: LumeLedgerTool.reconcileKey,
                    label: l.ledgerReconcile,
                    onPressed: () => unawaited(_repair(l, p.id)),
                  ),
                ],
              ),
            ),
          LumeToolSection(
            title: balances.length > 1
                ? l.ledgerSummaryCurrency(b.currency.code)
                : null,
            child: LumeSummaryCard(
              value: f.amount(b.balance, withCode: withCode),
              caption: LedgerText.direction(l, b.direction),
              stats: <LumeStat>[
                LumeStat(
                  value: f.amount(
                    b.owedToYou,
                    compact: true,
                    withCode: withCode,
                  ),
                  label: l.ledgerOwedToYou,
                ),
                LumeStat(
                  value: f.amount(b.youOwe, compact: true, withCode: withCode),
                  label: l.ledgerYouOwe,
                ),
              ],
            ),
          ),
          if (b.creditToThem.isPositive || b.creditFromThem.isPositive)
            LumeToolSection(
              child: Text(
                b.creditToThem.isPositive
                    ? l.ledgerCreditToThem(
                        f.amount(b.creditToThem, withCode: withCode),
                      )
                    : l.ledgerCreditFromThem(
                        f.amount(b.creditFromThem, withCode: withCode),
                      ),
              ),
            ),
          if (b.principals.any((LedgerPrincipalState s) => s.open))
            LumeToolSection(
              title: l.ledgerOpenLoans,
              child: LumeRows(
                children: <Widget>[
                  for (final LedgerPrincipalState s in b.principals)
                    if (s.open)
                      LumeRichRow(
                        icon: LedgerText.moneyOut(s.entry.kind)
                            ? LumeIcons.arrowUr
                            : LumeIcons.arrowDown,
                        title: LedgerText.kind(l, s.entry.kind),
                        subtitle: l.ledgerLeftOf(
                          f.amount(s.remaining, withCode: withCode),
                          f.amount(s.entry.amount, withCode: withCode),
                        ),
                        meta: <String>[
                          LedgerText.date(f, s.entry.on, today: today),
                          if (s.entry.due case final LumeDate due)
                            l.ledgerDue(LedgerText.date(f, due, today: today)),
                        ],
                        badge: s.overdue ?? false
                            ? LumeBadge(
                                label: l.commonOverdue,
                                tone: LumeBadgeTone.warn,
                              )
                            : null,
                        chevron: true,
                        onTap: () => _go(_View.entry, entry: s.entry.id),
                      ),
                ],
              ),
            ),
          if (!b.damaged)
            LumeToolSection(
              child: LumeButtonRow(
                expand: false,
                children: <Widget>[
                  for (final LedgerKind k in <LedgerKind>[
                    LedgerKind.lent,
                    LedgerKind.borrowed,
                  ])
                    if (b.open(k).isNotEmpty)
                      LumeButton(
                        key: k == LedgerKind.lent
                            ? LumeLedgerTool.settleKey
                            : null,
                        label: l.ledgerSettleUp,
                        icon: LumeIcons.checkCircle,
                        onPressed: () =>
                            unawaited(_settle(l, f, b, k, today, withCode)),
                      ),
                  if (ledgerRemindable(b) && !p.archived)
                    LumeButton(
                      key: LumeLedgerTool.personRemindKey,
                      label: l.ledgerRemind,
                      icon: LumeIcons.bell,
                      onPressed: () =>
                          unawaited(_remind(l, f, book, withCode, only: b)),
                    ),
                ],
              ),
            ),
        ],
        LumeToolSection(
          child: LumeButtonRow(
            expand: false,
            children: <Widget>[
              if (!p.archived)
                LumeButton.accent(
                  key: LumeLedgerTool.personAddKey,
                  label: l.ledgerAdd,
                  icon: LumeIcons.plus,
                  onPressed: () => _addEntry(today, party: p.id),
                ),
              LumeButton(
                key: LumeLedgerTool.editKey,
                label: l.ledgerRename,
                icon: LumeIcons.note,
                onPressed: () => _editPerson(p),
              ),
              LumeButton(
                key: LumeLedgerTool.archiveKey,
                label: p.archived ? l.ledgerUnarchive : l.ledgerArchive,
                icon: LumeIcons.folder,
                onPressed: () => unawaited(_setArchived(l, p)),
              ),
              LumeButton.dangerGhost(
                key: LumeLedgerTool.deletePersonKey,
                label: l.ledgerDeletePerson,
                icon: LumeIcons.trash,
                onPressed: () => unawaited(_deletePerson(l, book, p)),
              ),
            ],
          ),
        ),
        if (history.isNotEmpty)
          LumeToolSection(
            title: l.ledgerHistory,
            child: LumeRows(
              key: LumeLedgerTool.historyKey,
              children: <Widget>[
                for (final LedgerEntry e in history)
                  LumeRichRow(
                    key: LumeLedgerTool.historyRow(e.id.value),
                    icon: LedgerText.moneyOut(e.kind)
                        ? LumeIcons.arrowUr
                        : LumeIcons.arrowDown,
                    title: LedgerText.kind(l, e.kind),
                    subtitle: e.note,
                    meta: <String>[
                      LedgerText.date(f, e.on, today: today),
                      if (e.due case final LumeDate due)
                        l.ledgerDue(LedgerText.date(f, due, today: today)),
                    ],
                    badge: e.voided ? LumeBadge(label: l.ledgerVoided) : null,
                    value: f.amount(
                      e.amount,
                      compact: true,
                      withCode: withCode,
                    ),
                    chevron: true,
                    onTap: () => _go(_View.entry, entry: e.id),
                  ),
              ],
            ),
          ),
      ],
      true,
    );
  }

  // ----------------------------------------------------------------- entry

  (String?, List<Widget>, bool) _entryScreen(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LedgerBook book,
    LumeDate? today,
    bool withCode,
  ) {
    final LedgerEntry? e = _entry == null ? null : book.entry(_entry!);
    if (e == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _go(_View.person));
      return (null, const <Widget>[], true);
    }
    final List<LedgerAllocation> allocations = book.allocationsOf(e.id);
    final LumeMoney? credit = book.credit[e.id];
    return (
      LedgerText.kind(l, e.kind),
      <Widget>[
        LumeToolSection(
          child: LumeFactCard(
            key: LumeLedgerTool.entryKey,
            facts: <LumeFact>[
              LumeFact(
                label: l.ledgerFieldPerson,
                value: book.party(e.partyId)?.name ?? '—',
              ),
              LumeFact(
                label: l.ledgerFieldAmount,
                value: f.amount(e.amount, withCode: withCode),
              ),
              LumeFact(
                label: l.ledgerFieldDate,
                value: LedgerText.date(f, e.on),
              ),
              if (e.kind.isPrincipal)
                LumeFact(
                  label: l.ledgerFieldDue,
                  value: e.due == null
                      ? l.ledgerNoDue
                      : LedgerText.date(f, e.due!),
                ),
              if (e.note != null) LumeFact(label: l.ledgerNote, value: e.note!),
              if (e.voided)
                LumeFact(label: l.ledgerVoided, value: l.ledgerVoidText),
            ],
          ),
        ),
        if (allocations.isNotEmpty ||
            (credit?.isPositive ?? false) ||
            book.remaining[e.id] != null)
          LumeToolSection(
            child: LumeRows(
              children: <Widget>[
                if (book.remaining[e.id] case final LumeMoney left)
                  LumeCompactRow(
                    label: l.ledgerLeftOf(
                      f.amount(left, withCode: withCode),
                      f.amount(e.amount, withCode: withCode),
                    ),
                    chevron: false,
                  ),
                for (final LedgerAllocation a in allocations)
                  LumeCompactRow(
                    key: LumeLedgerTool.applied(a.principalId.value),
                    icon: a.manual ? LumeIcons.target : LumeIcons.check,
                    label: a.repaymentId == e.id
                        ? l.ledgerAppliedTo(
                            f.amount(a.amount, withCode: withCode),
                            LedgerText.date(f, book.entry(a.principalId)!.on),
                          )
                        : l.ledgerPaidFrom(
                            f.amount(a.amount, withCode: withCode),
                            LedgerText.date(f, book.entry(a.repaymentId)!.on),
                          ),
                    subtitle: a.manual ? l.ledgerManualBadge : null,
                    chevron: false,
                  ),
                if (credit case final LumeMoney c when c.isPositive)
                  LumeCompactRow(
                    icon: LumeIcons.wallet,
                    label: l.ledgerKeptAsCredit(
                      f.amount(c, withCode: withCode),
                    ),
                    chevron: false,
                  ),
              ],
            ),
          ),
        LumeToolSection(
          child: LumeButtonRow(
            expand: false,
            children: <Widget>[
              LumeButton(
                key: LumeLedgerTool.editKey,
                label: l.actionEdit,
                icon: LumeIcons.note,
                onPressed: () => _editEntry(e, book),
              ),
              LumeButton(
                key: LumeLedgerTool.voidKey,
                label: e.active ? l.ledgerVoid : l.ledgerRestore,
                icon: e.active ? LumeIcons.eyeOff : LumeIcons.refresh,
                onPressed: () => unawaited(_setVoided(l, f, book, e, withCode)),
              ),
              LumeButton.dangerGhost(
                key: LumeLedgerTool.deleteKey,
                label: l.actionDelete,
                icon: LumeIcons.trash,
                onPressed: () =>
                    unawaited(_deleteEntry(l, f, book, e, withCode)),
              ),
            ],
          ),
        ),
      ],
      true,
    );
  }

  // ----------------------------------------------------------------- forms

  List<Widget> _personForm(AppLocalizations l) {
    final _PersonDraft d = _personDraft!;
    return <Widget>[
      LumeToolSection(
        child: LumeFormCard(
          key: LumeLedgerTool.formKey,
          children: <Widget>[
            LumeFormField(
              key: LumeLedgerTool.nameField,
              label: l.ledgerPersonName,
              controller: d.name,
              required: true,
              error: d.nameError,
              autofocus: true,
            ),
            LumeFormField(
              key: LumeLedgerTool.noteField,
              label: l.ledgerNote,
              optionalLabel: l.ledgerOptional,
              controller: d.note,
              kind: LumeFieldKind.multiline,
              error: d.noteError,
            ),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeSubmitBar(
          saveLabel: l.actionSave,
          cancelLabel: l.actionCancel,
          onSave: () => unawaited(_savePerson(l)),
          onCancel: _back,
        ),
      ),
    ];
  }

  List<Widget> _entryForm(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LedgerBook book,
    bool withCode,
  ) {
    final _EntryDraft d = _entryDraft!;
    final List<LedgerParty> people = <LedgerParty>[
      for (final LedgerParty p in book.parties)
        if (!p.archived || p.id == d.party) p,
    ]..sort((LedgerParty a, LedgerParty b) => a.name.compareTo(b.name));
    final LedgerParty? party = d.party == null ? null : book.party(d.party!);
    final List<(LedgerPrincipalState, LumeMoney)> open = _openFor(book, d);
    return <Widget>[
      LumeToolSection(
        child: LumeFormCard(
          key: LumeLedgerTool.formKey,
          children: <Widget>[
            LumeFormPicker(
              key: LumeLedgerTool.personField,
              label: l.ledgerFieldPerson,
              value: party?.name ?? l.ledgerErrPerson,
              onTap: () => unawaited(
                _pick<LumeRecordId>(
                  l.ledgerFieldPerson,
                  <(LumeRecordId, String)>[
                    for (final LedgerParty p in people) (p.id, p.name),
                  ],
                  d.party,
                  (LumeRecordId v) {
                    d.party = v;
                    _fitCurrency(d, book);
                  },
                ),
              ),
            ),
            if (d.errors['person'] case final String e) _error(context, e),
            LumeFieldLabel(label: l.ledgerFieldKind),
            Semantics(
              key: LumeLedgerTool.kindField,
              label: l.ledgerFieldKind,
              container: true,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final LedgerKind k in LedgerKind.values)
                    LumeFilterChip(
                      label: LedgerText.kindShort(l, k),
                      selected: d.kind == k,
                      onTap: () => setState(() {
                        d.kind = k;
                        if (!k.isPrincipal) d.due = null;
                        _fitCurrency(d, book);
                      }),
                    ),
                ],
              ),
            ),
            LumeFormField(
              key: LumeLedgerTool.amountField,
              label: l.ledgerFieldAmount,
              controller: d.amount,
              kind: LumeFieldKind.money,
              prefix: d.currency?.code,
              required: true,
              error: d.errors['amount'],
            ),
            LumeFormPicker(
              key: LumeLedgerTool.currencyField,
              label: l.ledgerFieldCurrency,
              value: d.currency == null
                  ? '—'
                  : LedgerText.currency(l, d.currency!),
              onTap: d.id != null
                  ? null
                  : () => unawaited(
                      _pick<LumeCurrency>(
                        l.ledgerFieldCurrency,
                        <(LumeCurrency, String)>[
                          for (final LumeCurrency c in _currencyChoices(
                            book,
                            d,
                          ))
                            (c, LedgerText.currency(l, c)),
                        ],
                        d.currency,
                        (LumeCurrency v) {
                          d.currency = v;
                          d.currencyChosen = true;
                        },
                      ),
                    ),
            ),
            if (d.errors['currency'] case final String e) _error(context, e),
            LumeFormPicker(
              key: LumeLedgerTool.dateField,
              label: l.ledgerFieldDate,
              value: d.on == null
                  ? l.ledgerChooseDate
                  : LedgerText.date(f, d.on!),
              icon: LumeIcons.calendar,
              onTap: () => unawaited(_date(d.on, (LumeDate v) => d.on = v)),
            ),
            if (d.errors['date'] case final String e) _error(context, e),
            if (d.kind.isPrincipal) ...<Widget>[
              LumeFormPicker(
                key: LumeLedgerTool.dueField,
                label: l.ledgerFieldDue,
                optionalLabel: l.ledgerOptional,
                value: d.due == null
                    ? l.ledgerNoDue
                    : LedgerText.date(f, d.due!),
                icon: LumeIcons.calendar,
                onTap: () =>
                    unawaited(_date(d.due ?? d.on, (LumeDate v) => d.due = v)),
              ),
              if (d.due != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: LumeTextButton(
                    label: l.ledgerNoDue,
                    onPressed: () => setState(() => d.due = null),
                  ),
                ),
              if (d.errors['due'] case final String e) _error(context, e),
            ],
            if (d.kind.isRepayment) ...<Widget>[
              LumeFieldLabel(label: l.ledgerFieldApply),
              LumeSegmented(
                key: LumeLedgerTool.applyField,
                semanticLabel: l.ledgerFieldApply,
                value: d.manual ? 'manual' : 'auto',
                onChanged: (String v) =>
                    setState(() => d.manual = v == 'manual'),
                items: <LumeChoice>[
                  LumeChoice(value: 'auto', label: l.ledgerApplyAuto),
                  LumeChoice(value: 'manual', label: l.ledgerApplyManual),
                ],
              ),
              if (d.manual)
                if (open.isEmpty)
                  Text(l.ledgerApplyNone(d.currency?.code ?? ''))
                else
                  for (final (LedgerPrincipalState p, LumeMoney left) in open)
                    LumeFormField(
                      key: LumeLedgerTool.applied(p.entry.id.value),
                      label:
                          '${LedgerText.date(f, p.entry.on)} · '
                          '${l.ledgerLeftOf(f.amount(left, withCode: withCode), f.amount(p.entry.amount, withCode: withCode))}',
                      controller: d.appliedTo(p.entry.id),
                      kind: LumeFieldKind.money,
                      prefix: d.currency?.code,
                      error: d.errors['applied.${p.entry.id}'],
                    ),
              if (d.errors['apply'] case final String e) _error(context, e),
            ],
            LumeFormField(
              key: LumeLedgerTool.noteField,
              label: l.ledgerNote,
              optionalLabel: l.ledgerOptional,
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
          onSave: () => unawaited(_saveEntry(l, f, book, withCode)),
          onCancel: _back,
        ),
      ),
    ];
  }

  /// A withdrawn currency this entry would repay or correct in, then the
  /// reader's currency, those already in the ledger, then every other
  /// currency a new entry may use. A withdrawn currency appears only when
  /// the policy allows it here (LumeCurrencyPolicy).
  List<LumeCurrency> _currencyChoices(LedgerBook book, _EntryDraft d) {
    final LumeCurrency? mine = _currency();
    final Set<LumeCurrency> used = <LumeCurrency>{
      for (final LedgerEntry e in book.entries)
        if (e.currency.active) e.currency,
    };
    return <LumeCurrency>[
      ..._historical(book, d),
      ?mine,
      for (final LumeCurrency c in used.toList()..sort())
        if (c != mine) c,
      for (final LumeCurrency c in LumeCurrency.offered)
        if (c != mine && !used.contains(c)) c,
    ];
  }

  /// The withdrawn currencies the draft services — a lev loan's lev, for
  /// its repayment — and nothing else.
  List<LumeCurrency> _historical(LedgerBook book, _EntryDraft d) =>
      d.party == null
      ? const <LumeCurrency>[]
      : LumeCurrencyPolicy.historical(
          ledgerServicedCurrencies(
            book.entries,
            partyId: d.party!,
            kind: d.kind,
            editing: d.id == null ? null : book.entry(d.id!),
          ),
        );

  /// After the person or the kind changes: a repayment starts in the
  /// currency of what it would repay, when everything open with that person
  /// is in one currency; and a currency this entry may no longer use goes
  /// back to the reader's. A currency the reader picked stays theirs.
  void _fitCurrency(_EntryDraft d, LedgerBook book) {
    if (d.id != null || d.party == null) return;
    final LumeCurrency? now = d.currency;
    if (now != null &&
        !ledgerCurrencyAvailability(
          book.entries,
          partyId: d.party!,
          kind: d.kind,
          currency: now,
        ).usable) {
      d.currency = _currency();
      d.currencyChosen = false;
    }
    if (d.currencyChosen || !d.kind.isRepayment) return;
    final Set<LumeCurrency> open = <LumeCurrency>{
      for (final LedgerBalance b in book.balancesOf(d.party!))
        if (b.open(d.kind.counterpart).isNotEmpty) b.currency,
    };
    if (open.length == 1) d.currency = open.single;
  }

  Widget _error(BuildContext context, String text) => Semantics(
    liveRegion: true,
    child: Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );

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
          // The currency list is every active ISO code — far taller than
          // the sheet — so it scrolls rather than overflowing.
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

/// One row of People: a person, and their balance in one currency — or
/// none yet.
class _Row {
  const _Row(this.party, this.balance);

  final LedgerParty party;
  final LedgerBalance? balance;
}

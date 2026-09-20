/// Committee — `tools/money/committee.tool.js`, as a real record-backed
/// tool (`COMMITTEE_PROPOSAL.md` §15).
///
/// The reference's composition, in its order: the summary card, this
/// cycle's members, the payout order, what each cycle collected, then
/// History, the frame's source line and related tools. What it only drew,
/// this does: the committee, its members, its shares, its stored cycles,
/// its contributions and its payouts are the reader's own records — nothing
/// seeded — every figure is worked out from them and agrees with every
/// other, states come from the stored due dates and the reader's own day,
/// and a committee can be created, paid into, paid out, corrected,
/// cancelled, reinstated and deleted.
///
/// Where the reference could not hold together, this does not follow it:
/// there are as many cycles as shares, so every cycle has one recipient and
/// nothing goes missing; the pool is the contribution times the shares, to
/// the paisa; a payout is recorded only when its own cycle is fully
/// collected; and "done" is a record, not a comparison of two numbers.
///
/// It is sensitive: the frame shows its privacy note, nothing here reaches
/// Home, and it sends no notification (D-C9, D-C10).
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
import '../../../core/localization/lume_initials.dart';
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
import '../application/committee_providers.dart';
import '../domain/committee_book.dart';
import '../domain/committee_failure.dart';
import '../domain/committee_model.dart';
import '../domain/committee_repository.dart';
import '../domain/committee_transfer.dart';
import 'committee_sheets.dart';
import 'committee_text.dart';
import 'committee_transfer_sheets.dart';

enum CommitteeFilter { running, late_, completed, cancelled, all }

enum CommitteeSort { next, name, amount, recent }

enum _View { list, committee, member, form }

abstract final class LumeCommitteeTool {
  static const String id = 'committee';

  static const Key summaryKey = ValueKey<String>('comm.summary');
  static const Key filterKey = ValueKey<String>('comm.filter');
  static const Key searchKey = ValueKey<String>('comm.search');
  static const Key sortKey = ValueKey<String>('comm.sort');
  static const Key listKey = ValueKey<String>('comm.list');
  static const Key emptyKey = ValueKey<String>('comm.empty');
  static const Key noMatchKey = ValueKey<String>('comm.noMatch');
  static const Key dayUnknownKey = ValueKey<String>('comm.dayUnknown');
  static const Key defectsKey = ValueKey<String>('comm.defects');
  static const Key addKey = ValueKey<String>('comm.add');
  static const Key committeeKey = ValueKey<String>('comm.committee');
  static const Key damagedKey = ValueKey<String>('comm.damaged');
  static const Key thisCycleKey = ValueKey<String>('comm.thisCycle');
  static const Key orderKey = ValueKey<String>('comm.order');
  static const Key chartKey = ValueKey<String>('comm.chart');
  static const Key historyKey = ValueKey<String>('comm.history');
  static const Key factsKey = ValueKey<String>('comm.facts');
  static const Key payKey = ValueKey<String>('comm.pay');
  static const Key payoutKey = ValueKey<String>('comm.payout');
  static const Key editKey = ValueKey<String>('comm.edit');
  static const Key cancelKey = ValueKey<String>('comm.cancel');
  static const Key reinstateKey = ValueKey<String>('comm.reinstate');
  static const Key deleteKey = ValueKey<String>('comm.delete');
  static const Key memberKey = ValueKey<String>('comm.member');
  static const Key memberCyclesKey = ValueKey<String>('comm.member.cycles');
  static const Key formKey = ValueKey<String>('comm.form');
  static const Key saveKey = ValueKey<String>('comm.save');
  static const Key lockedKey = ValueKey<String>('comm.locked');
  static const Key nameField = ValueKey<String>('comm.field.name');
  static const Key noteField = ValueKey<String>('comm.field.note');
  static const Key currencyField = ValueKey<String>('comm.field.currency');
  static const Key contributionField = ValueKey<String>(
    'comm.field.contribution',
  );
  static const Key firstDueField = ValueKey<String>('comm.field.firstDue');
  static const Key roleField = ValueKey<String>('comm.field.role');
  static const Key membersField = ValueKey<String>('comm.field.members');
  static const Key addMemberKey = ValueKey<String>('comm.member.add');

  static Key filterChip(CommitteeFilter f) =>
      ValueKey<String>('comm.filter.${f.name}');
  static Key row(String committee) => ValueKey<String>('comm.row.$committee');
  static Key cycle(int n) => ValueKey<String>('comm.cycle.$n');
  static Key memberRow(String id) => ValueKey<String>('comm.member.$id');
  static Key memberPick(String id) => ValueKey<String>('comm.pick.$id');
  static Key entry(String id) => ValueKey<String>('comm.entry.$id');
  static Key memberName(int i) => ValueKey<String>('comm.field.member.$i');
  static Key memberShares(int i) => ValueKey<String>('comm.field.shares.$i');
  static Key memberYou(int i) => ValueKey<String>('comm.field.you.$i');
  static Key memberRemove(int i) => ValueKey<String>('comm.field.remove.$i');
  static Key memberUp(int i) => ValueKey<String>('comm.field.up.$i');
  static Key memberDown(int i) => ValueKey<String>('comm.field.down.$i');

  static Widget open(LumeToolRequest request) =>
      CommitteeTool(request: request);
}

class CommitteeTool extends ConsumerStatefulWidget {
  const CommitteeTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<CommitteeTool> createState() => _CommitteeToolState();
}

/// One member as the form holds them, before anything is written.
class _MemberDraft {
  _MemberDraft({String name = '', String shares = '1', this.isReader = false})
    : name = TextEditingController(text: name),
      shares = TextEditingController(text: shares);

  final TextEditingController name;
  final TextEditingController shares;
  bool isReader;

  String get state => '${name.text}\u0000${shares.text}\u0000$isReader';

  void dispose() {
    name.dispose();
    shares.dispose();
  }
}

/// A committee form's state. [locked] once a contribution or a payout
/// exists: the terms are shown and cannot be changed (D-C6).
class _CommitteeDraft {
  _CommitteeDraft({
    this.id,
    this.version,
    required this.currency,
    this.firstDue,
    this.locked = false,
    this.role = CommitteeReaderRole.member,
    String name = '',
    String note = '',
    String contribution = '',
    List<_MemberDraft>? members,
  }) : name = TextEditingController(text: name),
       note = TextEditingController(text: note),
       contribution = TextEditingController(text: contribution),
       members =
           members ??
           <_MemberDraft>[_MemberDraft(isReader: true), _MemberDraft()] {
    _initial = _state;
  }

  final LumeRecordId? id;
  final int? version;
  final bool locked;
  LumeCurrency? currency;
  LumeDate? firstDue;
  CommitteeReaderRole role;
  final TextEditingController name;
  final TextEditingController note;
  final TextEditingController contribution;
  final List<_MemberDraft> members;
  final Map<String, String> errors = <String, String>{};
  late final String _initial;

  String get _state => <Object?>[
    name.text,
    note.text,
    contribution.text,
    currency?.code,
    firstDue?.toIso(),
    role.name,
    for (final _MemberDraft m in members) m.state,
  ].join('\u0001');

  bool get dirty => _state != _initial;

  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      name,
      note,
      contribution,
    ]) {
      c.dispose();
    }
    for (final _MemberDraft m in members) {
      m.dispose();
    }
  }
}

class _CommitteeToolState extends ConsumerState<CommitteeTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final CommitteeRepository _repo = ref.read(committeeRepositoryProvider);
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(
    text: _read('q') ?? '',
  );
  final FocusNode _searchFocus = FocusNode();

  /// The body, to find the frame's scroll from: a new view opens at its top.
  final GlobalKey _body = GlobalKey();

  _View _view = _View.list;
  LumeRecordId? _committee;
  LumeRecordId? _member;
  _CommitteeDraft? _draft;
  bool _linked = false;

  String get _id => widget.request.feature.id;
  String? _read(String key) => _session.read(_id, key);
  void _write(String key, String value) => _session.write(_id, key, value);

  CommitteeFilter get _filter => CommitteeFilter.values.firstWhere(
    (CommitteeFilter f) => f.name == _read('filter'),
    orElse: () => CommitteeFilter.running,
  );
  CommitteeSort get _sort => CommitteeSort.values.firstWhere(
    (CommitteeSort s) => s.name == _read('sort'),
    orElse: () => CommitteeSort.next,
  );
  bool get _descending => _read('dir') == 'desc';

  @override
  void initState() {
    super.initState();
    _repo.open();
    _repo.changes.addListener(_changed);
    final LumeRecordId? kept = LumeRecordId.tryParse(_read('committee') ?? '');
    if (kept != null) {
      _committee = kept;
      _view = _View.committee;
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
  /// new committee may use, or none.
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
    return committeeDefaultCurrency(code);
  }

  // ------------------------------------------------------------ navigation

  void _go(_View v, {LumeRecordId? committee, LumeRecordId? member}) {
    final bool moved =
        v != _view ||
        (committee != null && committee != _committee) ||
        (member != null && member != _member);
    setState(() {
      _view = v;
      if (committee != null) _committee = committee;
      if (member != null) _member = member;
      _write('committee', v == _View.list ? '' : (_committee?.value ?? ''));
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
      case _View.committee:
        _go(_View.list);
      case _View.member:
        _go(_View.committee);
      case _View.form:
        final _CommitteeDraft? d = _draft;
        if (d != null && d.dirty && !await _confirmDiscard()) return;
        if (!mounted) return;
        _draft = null;
        d?.dispose();
        _go(d?.id != null ? _View.committee : _View.list);
    }
  }

  Future<bool> _confirmDiscard() async {
    final AppLocalizations l = AppLocalizations.of(context);
    return await committeeDecide(
          context,
          title: l.recDiscardAsk,
          text: l.recDiscardText,
          confirm: l.recDiscard,
          cancel: l.recKeepEditing,
          destructive: true,
        ) ??
        false;
  }

  void _addCommittee(LumeDate? today) {
    _draft?.dispose();
    _draft = _CommitteeDraft(currency: _currency(), firstDue: today);
    _go(_View.form);
  }

  void _editCommittee(CommitteeView v) {
    _draft?.dispose();
    final Committee c = v.committee;
    final bool locked = v.contributions.isNotEmpty || v.payouts.isNotEmpty;
    _draft = _CommitteeDraft(
      id: c.id,
      version: c.version,
      currency: c.currency,
      firstDue: c.firstDue,
      locked: locked,
      role: c.readerRole,
      name: c.name,
      note: c.note ?? '',
      contribution: c.contribution.toDecimalString(),
      // In the payout order, so what the reader sees is what is stored.
      members: <_MemberDraft>[
        for (final CommitteeMemberView m
            in <CommitteeMemberView>[...v.members]..sort(
              (CommitteeMemberView a, CommitteeMemberView b) =>
                  a.turns.first.compareTo(b.turns.first),
            ))
          _MemberDraft(
            name: m.name,
            shares: '${m.shares}',
            isReader: m.isReader,
          ),
      ],
    );
    _go(_View.form);
  }

  // ---------------------------------------------------------------- writes

  void _failed(AppLocalizations l, CommitteeFailure f) {
    _say(switch (f.kind) {
      CommitteeFailureKind.conflict ||
      CommitteeFailureKind.notFound => l.commErrConflict,
      CommitteeFailureKind.damaged => l.commErrDamaged,
      CommitteeFailureKind.cancelled => l.commErrCancelled,
      CommitteeFailureKind.duplicate => l.commErrDuplicate,
      CommitteeFailureKind.paidOut => l.commErrPaidOut,
      CommitteeFailureKind.locked => l.commLockedText,
      CommitteeFailureKind.overflow => l.commErrTooLarge,
      _ => l.commErrFailed,
    }, tone: LumeToastTone.error);
  }

  /// Offer to take a committed write back.
  void _undoable(AppLocalizations l, String message, CommitteeWrite w) => _say(
    message,
    actionLabel: l.recUndo,
    onAction: () {
      final CommitteeResult<void> r = _repo.undo(w);
      if (r.failure != null) _failed(l, r.failure!);
    },
  );

  Future<void> _save(AppLocalizations l) async {
    final _CommitteeDraft d = _draft!;
    final Map<String, String> errors = <String, String>{};
    final intl.NumberFormat nf = intl.NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag().replaceAll('-', '_'),
    );

    final String name = d.name.text.trim();
    if (name.isEmpty) errors['name'] = l.commErrName;
    if (name.length > kCommitteeNameMax) errors['name'] = l.commErrLong;
    if (d.note.text.length > kCommitteeNoteMax) {
      errors['note'] = l.commErrLong;
    }
    if (d.currency == null) errors['currency'] = l.commErrDate;
    LumeMoney? contribution;
    if (d.currency case final LumeCurrency cur) {
      final LedgerParsedAmount p = ledgerParseAmount(
        l,
        d.contribution.text,
        cur,
        decimalSeparator: nf.symbols.DECIMAL_SEP,
        groupSeparator: nf.symbols.GROUP_SEP,
      );
      if (p.error != null) {
        errors['contribution'] = p.error!;
      } else if (p.money == null || !p.money!.isPositive) {
        errors['contribution'] = l.ledgerErrAmount;
      }
      contribution = p.money;
    }
    if (d.firstDue == null) errors['firstDue'] = l.commErrDate;

    // The members, in the order they are listed: the first receives cycle 1.
    final List<CommitteeMemberDraft> members = <CommitteeMemberDraft>[];
    int cycle = 1;
    int readers = 0;
    for (final _MemberDraft m in d.members) {
      final String who = m.name.text.trim();
      if (who.isEmpty) errors['members'] = l.commErrMemberName;
      if (who.length > kCommitteeNameMax) errors['members'] = l.commErrLong;
      final int? shares = _whole(m.shares.text);
      if (shares == null || shares < 1) {
        errors['members'] = l.commErrShares;
        continue;
      }
      if (m.isReader) readers++;
      members.add(
        CommitteeMemberDraft(
          name: who,
          isReader: m.isReader,
          cycles: <int>[for (int i = 0; i < shares; i++) cycle + i],
        ),
      );
      cycle += shares;
    }
    final int positions = cycle - 1;
    if (!errors.containsKey('members') &&
        (positions < kCommitteePositionsMin ||
            positions > kCommitteePositionsMax)) {
      errors['members'] = positions < kCommitteePositionsMin
          ? l.commErrMembers
          : l.commErrRange;
    }
    final bool wantsReader = d.role != CommitteeReaderRole.organiser;
    if (wantsReader && readers != 1) errors['role'] = l.commErrReader;
    if (!wantsReader && readers != 0) errors['role'] = l.commErrReaderNone;

    setState(() {
      d.errors
        ..clear()
        ..addAll(errors);
    });
    if (errors.isNotEmpty) return;

    final CommitteeDraft draft = CommitteeDraft(
      name: name,
      note: d.note.text,
      contribution: contribution!,
      firstDue: d.firstDue!,
      readerRole: d.role,
      members: members,
    );
    final CommitteeResult<CommitteeWrite> r = d.id == null
        ? _repo.addCommittee(draft)
        : _repo.editTerms(d.id!, draft, version: d.version!);
    if (!mounted) return;
    final CommitteeFailure? failure = r.failure;
    if (failure != null) {
      final String? field = switch (failure.field) {
        'name' || 'note' || 'currency' || 'firstDue' => failure.field,
        'contribution' => 'contribution',
        'positions' || 'member' => 'members',
        'reader' => 'role',
        _ => null,
      };
      if (field != null && failure.kind != CommitteeFailureKind.locked) {
        setState(
          () => d.errors[field] = switch (failure.reason) {
            'withdrawn' => l.commErrWithdrawn(d.currency!.code),
            'long' => l.commErrLong,
            'range' when field == 'members' => l.commErrRange,
            'range' => l.commErrRange,
            'required' when field == 'name' => l.commErrName,
            'one' || 'none' => l.commErrReader,
            'overflow' => l.commErrTooLarge,
            _ => l.commErrFailed,
          },
        );
        return;
      }
      return _failed(l, failure);
    }
    final LumeRecordId id = r.value!.committee!.id;
    _draft = null;
    d.dispose();
    _say(l.commSaved);
    _go(_View.committee, committee: id);
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

  /// Ask who is paying into this cycle, then record it. Only members with
  /// a share still unpaid are offered: the rest have nothing to record.
  Future<void> _payPick(
    AppLocalizations l,
    LumeFormatting f,
    CommitteeView v,
    CommitteeCycleView cycle,
    LumeDate? today,
    bool withCode,
  ) async {
    final List<CommitteeMemberView> owing = <CommitteeMemberView>[
      for (final CommitteeMemberView m in v.members)
        if (cycle.slots.any(
          (CommitteeSlot s) =>
              !s.paid &&
              m.positions.any((CommitteePosition p) => p.id == s.position.id),
        ))
          m,
    ];
    if (owing.isEmpty) {
      _say(l.commPayoutReady, tone: LumeToastTone.info);
      return;
    }
    final CommitteeMemberView? who = owing.length == 1
        ? owing.single
        : await showLumeSheet<CommitteeMemberView>(
            context: context,
            barrierLabel: l.commRecordContribution,
            child: Builder(
              builder: (BuildContext sheet) => LumeSheet(
                title: l.commRecordContribution,
                subtitle: l.commTurnCycle(f.integer(cycle.n)),
                tall: owing.length > 8,
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (final CommitteeMemberView m in owing)
                        LumeRadioRow(
                          key: LumeCommitteeTool.memberPick(m.member.id.value),
                          label: m.isReader
                              ? '${m.name} · ${l.commYouLabel}'
                              : m.name,
                          subtitle: m.shares > 1
                              ? l.commShareCount(m.shares)
                              : null,
                          selected: false,
                          onTap: () => Navigator.of(sheet).pop(m),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
    if (who == null || !mounted) return;
    await _pay(l, f, v, cycle, who, today, withCode);
  }

  /// Record one member's contribution for a cycle: every share they hold,
  /// in one write.
  Future<void> _pay(
    AppLocalizations l,
    LumeFormatting f,
    CommitteeView v,
    CommitteeCycleView cycle,
    CommitteeMemberView who,
    LumeDate? today,
    bool withCode,
  ) async {
    final LumeMoney amount = LumeMoney.sum(
      v.contribution.minor * who.shares,
      v.currency,
    );
    final LumeDate? on = await CommitteeDateSheet.show(
      context,
      title: l.commPayTitle,
      text: l.commPayText(
        who.name,
        f.amount(amount, withCode: withCode, isolate: true),
        f.integer(cycle.n),
        CommitteeText.date(f, cycle.due, today: today),
      ),
      detail: who.shares > 1 ? l.commPayShares(who.shares) : null,
      action: l.commPayGo,
      initial: today ?? cycle.due,
      today: today,
      dateText: (LumeDate d) => CommitteeText.date(f, d, today: today),
    );
    if (on == null || !mounted) return;
    final CommitteeResult<CommitteeWrite> r = _repo.recordContribution(
      v.committee.id,
      cycle.cycle.id,
      who.member.id,
      on,
      today: today,
    );
    if (r.failure != null) {
      if (r.failure!.field == 'paidOn') {
        _say(l.commErrFuture, tone: LumeToastTone.error);
        return;
      }
      return _failed(l, r.failure!);
    }
    _undoable(l, l.commPaidToast, r.value!);
  }

  /// Record that a cycle's pool was handed to the share that holds it.
  Future<void> _payout(
    AppLocalizations l,
    LumeFormatting f,
    CommitteeView v,
    CommitteeCycleView cycle,
    LumeDate? today,
    bool withCode,
  ) async {
    if (!cycle.complete) {
      _say(
        l.commErrIncomplete(
          f.integer(cycle.n),
          f.amount(cycle.short, withCode: withCode, isolate: true),
        ),
        tone: LumeToastTone.info,
      );
      return;
    }
    final LumeDate? on = await CommitteeDateSheet.show(
      context,
      title: l.commPayoutTitle,
      text: l.commPayoutText(
        cycle.recipientMember.name,
        f.amount(cycle.pool, withCode: withCode, isolate: true),
        f.integer(cycle.n),
      ),
      action: l.commRecordPayout,
      initial: today ?? cycle.due,
      today: today,
      dateText: (LumeDate d) => CommitteeText.date(f, d, today: today),
    );
    if (on == null || !mounted) return;
    final CommitteeResult<CommitteeWrite> r = _repo.recordPayout(
      v.committee.id,
      cycle.cycle.id,
      on,
      today: today,
    );
    if (r.failure != null) {
      if (r.failure!.kind == CommitteeFailureKind.incomplete) {
        _say(
          l.commErrIncomplete(
            f.integer(cycle.n),
            f.amount(
              r.failure!.shortfall ?? cycle.short,
              withCode: withCode,
              isolate: true,
            ),
          ),
          tone: LumeToastTone.info,
        );
        return;
      }
      if (r.failure!.field == 'paidOn') {
        _say(l.commErrFuture, tone: LumeToastTone.error);
        return;
      }
      return _failed(l, r.failure!);
    }
    _undoable(l, l.commPayoutToast, r.value!);
  }

  /// Void or restore one record the reader made.
  Future<void> _entryActions(
    AppLocalizations l,
    LumeFormatting f,
    CommitteeView v,
    CommitteeHistoryEntry e,
    LumeDate? today,
    bool withCode,
  ) async {
    if (v.damaged) return;
    final CommitteeCycleView? cycle = v.cycleOf(e.cycleId);
    final bool payout = e.isPayout;
    final bool? go = await committeeDecide(
      context,
      title: payout ? l.commPayoutTitle : l.commPayTitle,
      text: <String>[
        if (cycle != null) l.commTurnCycle(f.integer(cycle.n)),
        l.commPaidOn(CommitteeText.date(f, e.paidOn, today: today)),
        f.amount(e.amount, withCode: withCode),
        if (e.voided) l.commVoided,
      ].join(' · '),
      confirm: payout
          ? (e.voided ? l.commRestorePayout : l.commVoidPayout)
          : (e.voided ? l.commRestoreContribution : l.commVoidContribution),
      destructive: !e.voided,
    );
    if (go != true || !mounted) return;
    final CommitteeResult<CommitteeWrite> r = payout
        ? _repo.setPayoutVoided(
            e.payout!.id,
            !e.voided,
            version: e.payout!.version,
          )
        : _repo.setContributionVoided(
            e.contribution!.id,
            !e.voided,
            version: e.contribution!.version,
          );
    if (r.failure != null) return _failed(l, r.failure!);
    _say(e.voided ? l.commRestoredToast : l.commVoidedToast);
  }

  Future<void> _cancel(
    AppLocalizations l,
    CommitteeView v,
    LumeDate? today,
  ) async {
    if (v.committee.cancelled) {
      final CommitteeResult<CommitteeWrite> r = _repo.setCancelled(
        v.committee.id,
        false,
        version: v.committee.version,
      );
      if (r.failure != null) return _failed(l, r.failure!);
      _say(l.commReinstatedToast);
      return;
    }
    if (today == null) {
      // Cancelling needs the day it happened, and nothing is guessed.
      _say(l.commDayUnknownText, tone: LumeToastTone.info);
      return;
    }
    final bool? go = await committeeDecide(
      context,
      title: l.commCancelTitle,
      text: l.commCancelText,
      confirm: l.commCancelCommittee,
      cancel: l.commKeepCommittee,
      destructive: true,
    );
    if (go != true || !mounted) return;
    final CommitteeResult<CommitteeWrite> r = _repo.setCancelled(
      v.committee.id,
      true,
      on: today,
      version: v.committee.version,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _undoable(l, l.commCancelledToast, r.value!);
  }

  Future<void> _delete(
    AppLocalizations l,
    LumeFormatting f,
    CommitteeView v,
  ) async {
    final CommitteeCounts counts = _repo.counts(v.committee.id);
    if (!await committeeConfirmDelete(
      context,
      title: l.commDeleteTitle,
      // Each count in its own grammar: "1 payout", not "1 payouts".
      text: l.commDeleteText(
        l.commCountMembers(counts.members),
        l.commCountShares(counts.positions),
        l.commCountCycles(counts.cycles),
        l.commCountContributions(counts.contributions),
        l.commCountPayouts(counts.payouts),
      ),
    )) {
      return;
    }
    if (!mounted) return;
    final CommitteeResult<CommitteeWrite> r = _repo.deleteCommittee(
      v.committee.id,
      version: v.committee.version,
    );
    if (r.failure != null) return _failed(l, r.failure!);
    _go(_View.list);
    _say(
      l.commDeletedToast,
      actionLabel: l.recUndo,
      onAction: () {
        final CommitteeResult<void> back = _repo.undo(r.value!);
        if (back.failure != null) return _failed(l, back.failure!);
        _say(l.commRestoredCommitteeToast);
      },
    );
  }

  // --------------------------------------------------------- export, import

  Future<void> _export(
    AppLocalizations l,
    LumeFormatting f,
    CommitteeBook book,
  ) async {
    final CommitteeExportChoice? choice =
        await showLumeSheet<CommitteeExportChoice>(
          context: context,
          barrierLabel: l.commExportTitle,
          child: CommitteeExportSheet(onImport: () => unawaited(_import(l, f))),
        );
    if (choice == null || !mounted) return;
    final DateTime now = LumeClockScope.of(context).now();
    final CommitteeSnapshot s = _repo.view();
    final LumeExportFile file = LumeExportFile.document(
      tool: _id,
      day: now,
      format: choice.json ? LumeExportFormat.json : LumeExportFormat.csv,
      text: choice.json
          ? committeeExportJson(
              committees: s.committees,
              members: s.members,
              positions: s.positions,
              cycles: s.cycles,
              contributions: s.contributions,
              payouts: s.payouts,
              exportedAt: now,
              build: kLumeVersion,
              durable: _repo.durable,
              includeNames: choice.includeNames,
            )
          : committeeExportCsv(book, includeNames: choice.includeNames),
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
    final CommitteeImportReport? report =
        await showLumeSheet<CommitteeImportReport>(
          context: context,
          barrierLabel: l.commImport,
          child: CommitteeImportSheet(
            store: ref.read(recordRepositoryProvider),
            f: f,
          ),
        );
    if (report == null || !mounted) return;
    final LumeTxResult<int> r = committeeImportApply(
      report,
      ref.read(recordRepositoryProvider),
    );
    if (!r.ok) {
      _say(l.commErrFailed, tone: LumeToastTone.error);
      return;
    }
    _say(l.commImported(r.value!));
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
    final CommitteeSnapshot snapshot = _repo.view();

    CommitteeBook? book;
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
      _View.committee => _committeeScreen(context, l, f, book, today, withCode),
      _View.member => _memberScreen(context, l, f, book, today, withCode),
      _View.form => (
        _draft?.id == null ? l.commNewCommittee : l.commEditCommittee,
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
                  key: LumeCommitteeTool.saveKey,
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

  void _deepLink(AppLocalizations l, CommitteeBook book) {
    final String? asked = widget.request.query['committee'];
    if (asked == null) {
      // A restored committee that has since gone opens the list.
      if (_committee != null && book.committee(_committee!) == null) {
        _view = _View.list;
        _committee = null;
      }
      return;
    }
    final LumeRecordId? id = LumeRecordId.tryParse(asked);
    if (id != null && book.committee(id) != null) {
      _committee = id;
      _view = _View.committee;
      return;
    }
    _view = _View.list;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _say(l.commNotFound, tone: LumeToastTone.info),
    );
  }

  // ------------------------------------------------------------------ list

  bool _matches(CommitteeView v, CommitteeFilter f) => switch (f) {
    CommitteeFilter.running => v.status == CommitteeStatus.active,
    CommitteeFilter.late_ =>
      v.status == CommitteeStatus.active &&
          (v.outstanding?.isPositive ?? false),
    CommitteeFilter.completed => v.status == CommitteeStatus.completed,
    CommitteeFilter.cancelled => v.status == CommitteeStatus.cancelled,
    CommitteeFilter.all => true,
  };

  List<Widget> _list(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    CommitteeBook book,
    LumeDate? today,
    bool withCode,
  ) {
    if (book.committees.isEmpty) {
      return <Widget>[
        LumeToolSection(
          child: LumeToolState(
            key: LumeCommitteeTool.emptyKey,
            icon: LumeIcons.users,
            title: l.commEmptyTitle,
            text: l.commEmptyText,
            action: LumeButton.accent(
              key: LumeCommitteeTool.addKey,
              label: l.commAdd,
              icon: LumeIcons.plus,
              onPressed: () => _addCommittee(today),
            ),
          ),
        ),
        if (book.defects.isNotEmpty) _defects(l, book),
      ];
    }
    final CommitteeFilter filter = _filter;
    final String q = LedgerText.fold(_query.text);
    final List<CommitteeView> committees = book.committees
        .where((CommitteeView v) => _matches(v, filter))
        .where(
          (CommitteeView v) =>
              q.isEmpty ||
              LedgerText.fold(
                <String>[
                  v.name,
                  v.committee.note ?? '',
                  for (final CommitteeMemberView m in v.members) m.name,
                ].join(' '),
              ).contains(q),
        )
        .toList();
    _order(committees);

    return <Widget>[
      ..._summaries(l, f, book, withCode),
      if (book.defects.isNotEmpty) _defects(l, book),
      LumeToolSection(
        spaceAbove: LumeToolSection.gap - LumeFilterBar.overhang,
        child: Semantics(
          label: l.commFilterLabel,
          container: true,
          child: LumeFilterBar(
            key: LumeCommitteeTool.filterKey,
            gutters: false,
            children: <Widget>[
              for (final (CommitteeFilter v, String label)
                  in <(CommitteeFilter, String)>[
                    (CommitteeFilter.running, l.commFilterRunning),
                    (CommitteeFilter.late_, l.commFilterLate),
                    (CommitteeFilter.completed, l.commFilterCompleted),
                    (CommitteeFilter.cancelled, l.commFilterCancelled),
                    (CommitteeFilter.all, l.commonAll),
                  ])
                LumeFilterChip(
                  key: LumeCommitteeTool.filterChip(v),
                  label: label,
                  // Without the reader's day there is no count of late.
                  count: v == CommitteeFilter.late_ && today == null
                      ? null
                      : book.committees
                            .where((CommitteeView x) => _matches(x, v))
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
          key: LumeCommitteeTool.searchKey,
          controller: _query,
          focusNode: _searchFocus,
          placeholder: l.commSearch,
          semanticLabel: l.commSearch,
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
          key: LumeCommitteeTool.sortKey,
          label: l.commonSort,
          value: _sort.name,
          direction: _descending
              ? LumeSortDirection.descending
              : LumeSortDirection.ascending,
          items: <LumeChoice>[
            LumeChoice(value: CommitteeSort.next.name, label: l.commSortNext),
            LumeChoice(value: CommitteeSort.name.name, label: l.commSortName),
            LumeChoice(
              value: CommitteeSort.amount.name,
              label: l.commSortAmount,
            ),
            LumeChoice(
              value: CommitteeSort.recent.name,
              label: l.commSortRecent,
            ),
          ],
          onChanged: (String v, LumeSortDirection d) => setState(() {
            _write('sort', v);
            _write('dir', d == LumeSortDirection.descending ? 'desc' : 'asc');
          }),
        ),
      ),
      LumeToolSection(
        title: l.commCommittees,
        link: l.commAdd,
        onLinkTap: () => _addCommittee(today),
        child: switch (null) {
          _ when filter == CommitteeFilter.late_ && today == null =>
            LumeToolState(
              key: LumeCommitteeTool.dayUnknownKey,
              icon: LumeIcons.clock,
              title: l.recZoneUnknownTitle,
              text: l.commDayUnknownText,
            ),
          _ when committees.isEmpty => LumeToolState(
            key: LumeCommitteeTool.noMatchKey,
            icon: LumeIcons.users,
            title: l.commNoMatch,
            text: l.commNoMatchText,
            action: LumeButton(
              label: l.commShowAll,
              icon: LumeIcons.refresh,
              onPressed: () => setState(() {
                _write('filter', CommitteeFilter.all.name);
                _query.clear();
                _write('q', '');
              }),
            ),
          ),
          _ => LumeRows(
            key: LumeCommitteeTool.listKey,
            children: <Widget>[
              for (final CommitteeView v in committees)
                _committeeRow(context, l, f, v, today, withCode),
            ],
          ),
        },
      ),
      LumeToolSection(
        child: LumeButtonRow(
          children: <Widget>[
            LumeButton.accent(
              key: LumeCommitteeTool.addKey,
              label: l.commAdd,
              icon: LumeIcons.plus,
              onPressed: () => _addCommittee(today),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _defects(AppLocalizations l, CommitteeBook book) => LumeToolSection(
    child: LumeNotice(
      key: LumeCommitteeTool.defectsKey,
      kind: LumeNoticeKind.warning,
      title: l.commNeedsAttention,
      text: l.commDefects(book.defects.length),
    ),
  );

  /// One summary per currency, each the whole tool whatever is filtered —
  /// the reader's own currency first.
  List<Widget> _summaries(
    AppLocalizations l,
    LumeFormatting f,
    CommitteeBook book,
    bool withCode,
  ) {
    final LumeCurrency? mine = _currency();
    final List<CommitteeCurrencySummary> sums =
        <CommitteeCurrencySummary>[...book.summaries]..sort(
          (CommitteeCurrencySummary a, CommitteeCurrencySummary b) =>
              a.currency == mine
              ? -1
              : b.currency == mine
              ? 1
              : a.currency.compareTo(b.currency),
        );
    return <Widget>[
      for (final (int i, CommitteeCurrencySummary s) in sums.indexed)
        LumeToolSection(
          title: sums.length > 1
              ? l.commSummaryCurrency(s.currency.code)
              : null,
          child: LumeSummaryCard(
            key: i == 0 ? LumeCommitteeTool.summaryKey : null,
            kicker: l.commInThePot,
            value: f.amount(
              s.collected - s.paidOut,
              compact: true,
              withCode: withCode,
            ),
            caption: l.commRunning(s.running),
            stats: <LumeStat>[
              LumeStat(
                value: f.amount(s.collected, compact: true, withCode: withCode),
                label: l.commCollected,
              ),
              LumeStat(
                value: f.amount(s.paidOut, compact: true, withCode: withCode),
                label: l.commPaidOut,
              ),
              LumeStat(
                value: s.outstanding == null
                    ? l.commDayUnknown
                    : f.amount(
                        s.outstanding!,
                        compact: true,
                        withCode: withCode,
                      ),
                label: l.commOutstanding,
              ),
            ],
          ),
        ),
    ];
  }

  void _order(List<CommitteeView> committees) {
    int byName(CommitteeView a, CommitteeView b) {
      final int n = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return n != 0 ? n : a.committee.id.compareTo(b.committee.id);
    }

    int nextDue(CommitteeView a, CommitteeView b) {
      LumeDate? next(CommitteeView v) {
        if (v.status != CommitteeStatus.active) return null;
        for (final CommitteeCycleView c in v.cycles) {
          if (!c.complete) return c.due;
        }
        return null;
      }

      final LumeDate? x = next(a);
      final LumeDate? y = next(b);
      if (x == null || y == null) {
        return x == null ? (y == null ? byName(a, b) : 1) : -1;
      }
      final int c = x.compareTo(y);
      return c != 0 ? c : byName(a, b);
    }

    final int Function(CommitteeView, CommitteeView) compare = switch (_sort) {
      CommitteeSort.next => nextDue,
      CommitteeSort.name => byName,
      CommitteeSort.amount => (CommitteeView a, CommitteeView b) {
        final int c = a.currency.compareTo(b.currency);
        if (c != 0) return c;
        final int m = a.contribution.compareTo(b.contribution);
        return m != 0 ? m : byName(a, b);
      },
      // Oldest first ascending; the bar picks a new sort descending, so
      // choosing it shows the most recent first.
      CommitteeSort.recent => (CommitteeView a, CommitteeView b) {
        final int c = a.lastActivity.compareTo(b.lastActivity);
        return c != 0 ? c : byName(a, b);
      },
    };
    committees.sort(
      _descending
          ? (CommitteeView a, CommitteeView b) => compare(b, a)
          : compare,
    );
  }

  (Color, Color) _tone(BuildContext context, LumeRecordId id) {
    final LumeColors lume = context.lume;
    // The reference's tinted discs: a tone chosen from the random record
    // id, so it is stable and says nothing about the committee.
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

  Widget _committeeRow(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    CommitteeView v,
    LumeDate? today,
    bool withCode,
  ) {
    final (Color tone, Color ink) = _tone(context, v.committee.id);
    final String? initials = lumeInitials(v.name);
    final double progress = v.positionCount == 0
        ? 0
        : v.paidOutCycles / v.positionCount;
    final CommitteeCycleView? next = v.status == CommitteeStatus.active
        ? v.cycles.where((CommitteeCycleView c) => !c.complete).firstOrNull
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LumeRichRow(
          key: LumeCommitteeTool.row(v.committee.id.value),
          logo: initials,
          icon: initials == null ? LumeIcons.users : null,
          iconTone: tone,
          iconInk: ink,
          title: v.name,
          subtitle: l.commShareCount(v.positionCount),
          meta: <String>[
            l.commCycleOf(
              f.integer(v.paidOutCycles),
              f.integer(v.positionCount),
            ),
            if (next != null)
              l.commDueOn(CommitteeText.dateShort(f, next.due, today: today)),
          ],
          badge: v.damaged
              ? LumeBadge(label: l.commNeedsAttention, tone: LumeBadgeTone.info)
              : v.status == CommitteeStatus.cancelled
              ? LumeBadge(label: l.commFilterCancelled, tone: LumeBadgeTone.off)
              : v.status == CommitteeStatus.completed
              ? LumeBadge(label: l.commFilterCompleted, tone: LumeBadgeTone.ok)
              : (v.outstanding?.isPositive ?? false)
              ? LumeBadge(label: l.commFilterLate, tone: LumeBadgeTone.late_)
              : null,
          value: f.amount(v.contribution, compact: true, withCode: withCode),
          valueSub: l.commFieldContribution,
          chevron: true,
          onTap: () => _go(_View.committee, committee: v.committee.id),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 10),
          child: LumeProgressBar(
            value: progress,
            label: v.name,
            valueText: l.commCyclesPaidOut(
              f.integer(v.paidOutCycles),
              f.integer(v.positionCount),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- committee

  (String?, List<Widget>, bool) _committeeScreen(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    CommitteeBook book,
    LumeDate? today,
    bool withCode,
  ) {
    final CommitteeView? v = _committee == null
        ? null
        : book.committee(_committee!);
    if (v == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _go(_View.list));
      return (null, const <Widget>[], true);
    }
    final Committee c = v.committee;
    String money(LumeMoney m) => f.amount(m, withCode: withCode);
    final CommitteeCycleView? current = v.current(today);
    final CommitteeCycleView? ready = v.cycles
        .where(
          (CommitteeCycleView x) =>
              x.payoutStatus == CommitteeCyclePayoutStatus.ready,
        )
        .firstOrNull;
    final double progress = v.positionCount == 0
        ? 0
        : v.paidOutCycles / v.positionCount;
    final CommitteeMemberView? me = v.reader;
    final CommitteeCycleView? myTurn = v.readerNextTurn;

    return (
      v.name,
      <Widget>[
        const KeyedSubtree(
          key: LumeCommitteeTool.committeeKey,
          child: SizedBox(),
        ),
        if (v.damaged)
          LumeToolSection(
            child: LumeNotice(
              key: LumeCommitteeTool.damagedKey,
              kind: LumeNoticeKind.warning,
              title: l.commNeedsAttention,
              text: l.commDamagedText,
            ),
          ),
        LumeToolSection(
          child: LumeSummaryCard(
            key: LumeCommitteeTool.summaryKey,
            kicker: l.commPoolEachCycle,
            value: f.amount(v.pool, compact: true, withCode: withCode),
            caption: <String>[
              CommitteeText.status(l, v.status),
              if (current != null)
                l.commCycleOf(f.integer(current.n), f.integer(v.positionCount))
              else if (v.cycles.isNotEmpty)
                l.commBeforeStart(
                  CommitteeText.date(f, v.cycles.first.due, today: today),
                ),
            ].join(' · '),
            stats: <LumeStat>[
              LumeStat(
                value: f.amount(
                  v.readerPerCycle,
                  compact: true,
                  withCode: withCode,
                ),
                label: l.commYourContribution,
              ),
              LumeStat(value: f.integer(v.memberCount), label: l.commPeople),
              LumeStat(
                value: me == null
                    ? l.commTurnNone
                    : myTurn == null
                    ? l.commTurnDone
                    : l.commTurnCycle(f.integer(myTurn.n)),
                label: l.commYourTurn,
              ),
            ],
          ),
        ),
        LumeToolSection(
          spaceAbove: LumeToolSection.tightGap,
          child: LumeProgressBar(
            value: progress,
            label: v.name,
            valueText: l.commCyclesPaidOut(
              f.integer(v.paidOutCycles),
              f.integer(v.positionCount),
            ),
          ),
        ),
        LumeToolSection(
          child: LumeButtonRow(
            expand: false,
            children: <Widget>[
              if (!v.damaged && !c.cancelled && current != null)
                LumeButton.accent(
                  key: LumeCommitteeTool.payKey,
                  label: l.commRecordContribution,
                  icon: LumeIcons.checkCircle,
                  onPressed: () =>
                      unawaited(_payPick(l, f, v, current, today, withCode)),
                ),
              if (!v.damaged && !c.cancelled && ready != null)
                LumeButton(
                  key: LumeCommitteeTool.payoutKey,
                  label: l.commRecordPayout,
                  icon: LumeIcons.download,
                  onPressed: () =>
                      unawaited(_payout(l, f, v, ready, today, withCode)),
                ),
              if (!v.damaged)
                LumeButton(
                  key: LumeCommitteeTool.editKey,
                  label: l.commEdit,
                  icon: LumeIcons.note,
                  onPressed: () => _editCommittee(v),
                ),
              if (!v.damaged && v.status != CommitteeStatus.completed)
                LumeButton(
                  key: c.cancelled
                      ? LumeCommitteeTool.reinstateKey
                      : LumeCommitteeTool.cancelKey,
                  label: c.cancelled ? l.commReinstate : l.commCancelCommittee,
                  icon: c.cancelled ? LumeIcons.refresh : LumeIcons.x,
                  onPressed: () => unawaited(_cancel(l, v, today)),
                ),
              LumeButton.dangerGhost(
                key: LumeCommitteeTool.deleteKey,
                label: l.commDeleteCommittee,
                icon: LumeIcons.trash,
                onPressed: () => unawaited(_delete(l, f, v)),
              ),
            ],
          ),
        ),
        // "This month" in the reference: every member, and whether they
        // have paid into the cycle the committee is in.
        if (current != null)
          LumeToolSection(
            title: l.commThisCycle,
            child: LumeRows(
              key: LumeCommitteeTool.thisCycleKey,
              children: <Widget>[
                for (final CommitteeMemberView m in v.members)
                  _memberRow(context, l, f, v, current, m, today, withCode),
              ],
            ),
          ),
        LumeToolSection(
          title: l.commPayoutOrder,
          child: KeyedSubtree(
            key: LumeCommitteeTool.orderKey,
            child: LumeTimeline(
              entries: <LumeTimelineEntry>[
                for (final CommitteeCycleView x in v.cycles)
                  LumeTimelineEntry(
                    time: CommitteeText.dateShort(f, x.due, today: today),
                    title: x.recipientMember.isReader
                        ? '${x.recipientMember.name} · ${l.commYouLabel}'
                        : x.recipientMember.name,
                    subtitle: <String>[
                      l.commTurnCycle(f.integer(x.n)),
                      CommitteeText.payout(l, x.payoutStatus),
                      if (!x.complete && !x.collected.isZero)
                        l.commShortBy(
                          f.amount(x.short, compact: true, withCode: withCode),
                        ),
                    ].join(' · '),
                    value: f.amount(x.pool, compact: true, withCode: withCode),
                    state: x.paidOut
                        ? LumeTimelineState.done
                        : x.payoutStatus == CommitteeCyclePayoutStatus.ready ||
                              (current != null && x.n == current.n)
                        ? LumeTimelineState.now
                        : LumeTimelineState.upcoming,
                  ),
              ],
            ),
          ),
        ),
        LumeToolSection(
          spaceAbove: LumeToolSection.tightGap,
          child: Text(l.commPayoutOrderCap),
        ),
        ?_chart(l, f, v, withCode),
        LumeToolSection(
          child: LumeFactCard(
            key: LumeCommitteeTool.factsKey,
            facts: <LumeFact>[
              LumeFact(
                label: l.commFactContribution,
                value: money(v.contribution),
              ),
              LumeFact(
                label: l.commFactCycles,
                value: f.integer(v.positionCount),
              ),
              LumeFact(label: l.commFactFrequency, value: l.commMonthly),
              LumeFact(
                label: l.commFactFirstDue,
                value: CommitteeText.date(f, c.firstDue),
              ),
              LumeFact(label: l.commFactPool, value: money(v.pool)),
              LumeFact(
                label: l.commFactExpected,
                value: money(v.expectedTotal),
              ),
              LumeFact(label: l.commCollected, value: money(v.collected)),
              LumeFact(label: l.commPaidOut, value: money(v.paidOut)),
              LumeFact(label: l.commInThePot, value: money(v.held)),
              LumeFact(
                label: v.outstandingIsFinal
                    ? l.commUnpaidAtCancelTotal
                    : l.commOutstanding,
                value: v.outstanding == null
                    ? l.commDayUnknown
                    : money(v.outstanding!),
              ),
              LumeFact(label: l.commFactRole, value: CommitteeText.role(l, v)),
              if (c.cancelledOn case final LumeDate on)
                LumeFact(
                  label: l.commFactCancelledOn,
                  value: CommitteeText.date(f, on),
                ),
              if (c.note case final String note)
                LumeFact(label: l.commFieldNote, value: note, block: true),
            ],
          ),
        ),
        LumeToolSection(
          spaceAbove: LumeToolSection.tightGap,
          child: Text(l.commRoleHelp),
        ),
        LumeToolSection(
          title: l.commonHistory,
          child: _history(l, f, v, today, withCode),
        ),
      ],
      true,
    );
  }

  Widget _history(
    AppLocalizations l,
    LumeFormatting f,
    CommitteeView v,
    LumeDate? today,
    bool withCode,
  ) {
    final List<CommitteeHistoryEntry> entries =
        <CommitteeHistoryEntry>[
          for (final CommitteeContribution x in v.contributions)
            CommitteeHistoryEntry(v, contribution: x),
          for (final CommitteePayout o in v.payouts)
            CommitteeHistoryEntry(v, payout: o),
        ]..sort(
          (CommitteeHistoryEntry a, CommitteeHistoryEntry b) =>
              committeeEntryOrder(
                a.paidOn,
                a.createdAt,
                a.id,
                b.paidOn,
                b.createdAt,
                b.id,
              ),
        );
    if (entries.isEmpty) return Text(l.commNoHistory);
    return LumeRows(
      key: LumeCommitteeTool.historyKey,
      children: <Widget>[
        for (final CommitteeHistoryEntry e in entries.take(12))
          () {
            final CommitteeCycleView? cycle = v.cycleOf(e.cycleId);
            final CommitteeMemberView? who = v.members
                .where(
                  (CommitteeMemberView m) => m.positions.any(
                    (CommitteePosition p) => p.id == e.positionId,
                  ),
                )
                .firstOrNull;
            return LumeCompactRow(
              key: LumeCommitteeTool.entry(e.id.value),
              icon: e.voided
                  ? LumeIcons.x
                  : e.isPayout
                  ? LumeIcons.download
                  : LumeIcons.checkCircle,
              label: e.isPayout
                  ? l.commPayoutRecorded
                  : (who?.name ?? l.commPaid),
              subtitle: <String>[
                if (cycle != null) l.commTurnCycle(f.integer(cycle.n)),
                l.commPaidOn(
                  CommitteeText.dateShort(f, e.paidOn, today: today),
                ),
                if (e.voided) l.commVoided,
              ].join(' · '),
              value: f.amount(e.amount, compact: true, withCode: withCode),
              onTap: () =>
                  unawaited(_entryActions(l, f, v, e, today, withCode)),
            );
          }(),
      ],
    );
  }

  /// What each cycle has collected of its pool. The bars grow with their
  /// figures, and a screen reader hears each cycle and its amount.
  Widget? _chart(
    AppLocalizations l,
    LumeFormatting f,
    CommitteeView v,
    bool withCode,
  ) {
    if (v.cycles.isEmpty) return null;
    if (v.collected.isZero) return null;
    final List<String> amounts = <String>[
      for (final CommitteeCycleView c in v.cycles)
        f.amount(c.collected, compact: true, withCode: withCode),
    ];
    return LumeToolSection(
      title: l.commCollectedEachCycle,
      child: LumeCard(
        child: KeyedSubtree(
          key: LumeCommitteeTool.chartKey,
          child: LumeBarChart(
            values: <double>[
              for (final CommitteeCycleView c in v.cycles)
                c.collected.minor / v.currency.scale,
            ],
            labels: <String>[
              for (final CommitteeCycleView c in v.cycles) f.integer(c.n),
            ],
            valueLabels: amounts,
            highlight: 0,
            label: <String>[
              l.commCollectedEachCycle,
              for (final (int i, CommitteeCycleView c) in v.cycles.indexed)
                l.commChartEntry(l.commTurnCycle(f.integer(c.n)), amounts[i]),
            ].join('. '),
            caption: Text(l.commCollectedCap(v.currency.code)),
          ),
        ),
      ),
    );
  }

  Widget _memberRow(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    CommitteeView v,
    CommitteeCycleView cycle,
    CommitteeMemberView m,
    LumeDate? today,
    bool withCode,
  ) {
    final (Color tone, Color ink) = _tone(context, m.member.id);
    final String? initials = lumeInitials(m.name);
    final List<CommitteeSlot> mine = <CommitteeSlot>[
      for (final CommitteeSlot s in cycle.slots)
        if (m.positions.any((CommitteePosition p) => p.id == s.position.id)) s,
    ];
    final bool paid =
        mine.isNotEmpty && mine.every((CommitteeSlot s) => s.paid);
    final CommitteeSlotStatus status = mine.isEmpty
        ? CommitteeSlotStatus.notDue
        : paid
        ? CommitteeSlotStatus.paid
        : mine.firstWhere((CommitteeSlot s) => !s.paid).status;
    final LumeMoney owed = LumeMoney.sum(
      v.contribution.minor * m.shares,
      v.currency,
    );
    final CommitteeSlot? first = mine
        .where((CommitteeSlot s) => s.paid)
        .firstOrNull;
    return LumeRichRow(
      key: LumeCommitteeTool.memberRow(m.member.id.value),
      logo: initials,
      icon: initials == null ? LumeIcons.users : null,
      iconTone: tone,
      iconInk: ink,
      title: m.isReader ? '${m.name} · ${l.commYouLabel}' : m.name,
      subtitle: paid && first?.contribution != null
          ? l.commPaidOn(
              CommitteeText.dateShort(
                f,
                first!.contribution!.paidOn,
                today: today,
              ),
            )
          : null,
      meta: <String>[
        m.turns.length == 1
            ? l.commReceivesCycle(f.integer(m.turns.first))
            : l.commReceivesCycles(
                m.turns.map((int t) => f.integer(t)).join(', '),
              ),
        if (m.shares > 1) l.commShareCount(m.shares),
      ],
      badge: LumeBadge(
        label: CommitteeText.slot(l, status),
        tone: CommitteeText.slotTone(status),
      ),
      value: f.amount(owed, compact: true, withCode: withCode),
      chevron: true,
      onTap: () =>
          _go(_View.member, committee: v.committee.id, member: m.member.id),
    );
  }

  // ---------------------------------------------------------------- member

  (String?, List<Widget>, bool) _memberScreen(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    CommitteeBook book,
    LumeDate? today,
    bool withCode,
  ) {
    final CommitteeView? v = _committee == null
        ? null
        : book.committee(_committee!);
    final CommitteeMemberView? m = v == null || _member == null
        ? null
        : v.memberOf(_member!);
    if (v == null || m == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _go(v == null ? _View.list : _View.committee),
      );
      return (null, const <Widget>[], true);
    }
    return (
      m.isReader ? '${m.name} · ${l.commYouLabel}' : m.name,
      <Widget>[
        const KeyedSubtree(key: LumeCommitteeTool.memberKey, child: SizedBox()),
        LumeToolSection(
          child: LumeSummaryCard(
            kicker: l.commMemberPaidLabel,
            value: f.amount(m.paid, compact: true, withCode: withCode),
            caption: <String>[
              l.commShareCount(m.shares),
              m.turns.length == 1
                  ? l.commReceivesCycle(f.integer(m.turns.first))
                  : l.commReceivesCycles(
                      m.turns.map((int t) => f.integer(t)).join(', '),
                    ),
            ].join(' · '),
            stats: <LumeStat>[
              LumeStat(
                value: f.amount(m.expected, compact: true, withCode: withCode),
                label: l.commMemberExpected,
              ),
              LumeStat(
                value: f.amount(m.received, compact: true, withCode: withCode),
                label: l.commPaidOut,
              ),
              LumeStat(
                value: m.lateCount == null
                    ? l.commDayUnknown
                    : f.integer(m.lateCount!),
                label: l.commFilterLate,
              ),
            ],
          ),
        ),
        LumeToolSection(
          title: l.commTheirCycles,
          child: LumeRows(
            key: LumeCommitteeTool.memberCyclesKey,
            children: <Widget>[
              for (final CommitteeCycleView c in v.cycles)
                () {
                  final List<CommitteeSlot> mine = <CommitteeSlot>[
                    for (final CommitteeSlot s in c.slots)
                      if (m.positions.any(
                        (CommitteePosition p) => p.id == s.position.id,
                      ))
                        s,
                  ];
                  final bool paid =
                      mine.isNotEmpty &&
                      mine.every((CommitteeSlot s) => s.paid);
                  final CommitteeSlotStatus status = mine.isEmpty
                      ? CommitteeSlotStatus.notDue
                      : paid
                      ? CommitteeSlotStatus.paid
                      : mine.firstWhere((CommitteeSlot s) => !s.paid).status;
                  final bool canPay =
                      !paid &&
                      !v.damaged &&
                      !v.committee.cancelled &&
                      mine.isNotEmpty;
                  return LumeRichRow(
                    key: LumeCommitteeTool.cycle(c.n),
                    title: l.commTurnCycle(f.integer(c.n)),
                    meta: <String>[
                      l.commDueOn(
                        CommitteeText.dateShort(f, c.due, today: today),
                      ),
                      if (c.recipient.memberId == m.member.id) l.commYourTurn,
                    ],
                    badge: LumeBadge(
                      label: CommitteeText.slot(l, status),
                      tone: CommitteeText.slotTone(status),
                    ),
                    value: f.amount(
                      LumeMoney.sum(
                        v.contribution.minor * m.shares,
                        v.currency,
                      ),
                      compact: true,
                      withCode: withCode,
                    ),
                    onTap: canPay
                        ? () => unawaited(_pay(l, f, v, c, m, today, withCode))
                        : null,
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
    final _CommitteeDraft d = _draft!;
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
    int cycle = 1;
    final List<Widget> memberRows = <Widget>[];
    for (final (int i, _MemberDraft m) in d.members.indexed) {
      final int shares = _whole(m.shares.text) ?? 1;
      final List<int> turns = <int>[for (int k = 0; k < shares; k++) cycle + k];
      cycle += shares;
      memberRows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LumeFormField(
                key: LumeCommitteeTool.memberName(i),
                label: l.commMemberName(f.integer(i + 1)),
                controller: m.name,
                required: true,
                enabled: !locked,
                autofocus: false,
              ),
              LumeFormField(
                key: LumeCommitteeTool.memberShares(i),
                label: l.commFieldShares,
                controller: m.shares,
                kind: LumeFieldKind.number,
                localDigits: true,
                enabled: !locked,
                onChanged: (_) => setState(() {}),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        turns.length == 1
                            ? l.commReceivesCycle(f.integer(turns.first))
                            : l.commReceivesCycles(
                                turns.map((int t) => f.integer(t)).join(', '),
                              ),
                      ),
                    ),
                    Text(l.commThisIsYou),
                    LumeSwitch(
                      key: LumeCommitteeTool.memberYou(i),
                      value: m.isReader,
                      semanticLabel: '${l.commThisIsYou} ${m.name.text}',
                      onChanged: (bool v) => setState(() {
                        for (final _MemberDraft other in d.members) {
                          other.isReader = false;
                        }
                        m.isReader = v;
                      }),
                    ),
                  ],
                ),
              ),
              if (!locked)
                Row(
                  children: <Widget>[
                    LumeTextButton(
                      key: LumeCommitteeTool.memberUp(i),
                      label: l.commMoveUp,
                      onPressed: i == 0
                          ? null
                          : () => setState(() {
                              final _MemberDraft x = d.members.removeAt(i);
                              d.members.insert(i - 1, x);
                            }),
                    ),
                    LumeTextButton(
                      key: LumeCommitteeTool.memberDown(i),
                      label: l.commMoveDown,
                      onPressed: i == d.members.length - 1
                          ? null
                          : () => setState(() {
                              final _MemberDraft x = d.members.removeAt(i);
                              d.members.insert(i + 1, x);
                            }),
                    ),
                    const Spacer(),
                    LumeTextButton(
                      key: LumeCommitteeTool.memberRemove(i),
                      label: l.commRemoveMember,
                      onPressed: d.members.length <= 2
                          ? null
                          : () => setState(() {
                              final _MemberDraft x = d.members.removeAt(i);
                              x.dispose();
                            }),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    return <Widget>[
      if (locked)
        LumeToolSection(
          child: LumeNotice(
            key: LumeCommitteeTool.lockedKey,
            kind: LumeNoticeKind.info,
            title: l.commLockedTitle,
            text: l.commLockedText,
          ),
        ),
      LumeToolSection(
        child: LumeFormCard(
          key: LumeCommitteeTool.formKey,
          children: <Widget>[
            LumeFormField(
              key: LumeCommitteeTool.nameField,
              label: l.commFieldName,
              controller: d.name,
              required: true,
              error: d.errors['name'],
              autofocus: d.id == null,
            ),
            LumeFormPicker(
              key: LumeCommitteeTool.currencyField,
              label: l.commFieldCurrency,
              value: d.currency?.code ?? '—',
              onTap: locked
                  ? null
                  : () => unawaited(
                      _pick<LumeCurrency>(
                        l.commFieldCurrency,
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
              key: LumeCommitteeTool.contributionField,
              label: l.commFieldContribution,
              controller: d.contribution,
              kind: LumeFieldKind.money,
              prefix: d.currency?.code,
              required: true,
              enabled: !locked,
              error: d.errors['contribution'],
            ),
            LumeFormPicker(
              key: LumeCommitteeTool.firstDueField,
              label: l.commFieldFirstDue,
              value: d.firstDue == null
                  ? l.commErrDate
                  : CommitteeText.date(f, d.firstDue!),
              onTap: locked
                  ? null
                  : () => unawaited(
                      _date(d.firstDue, (LumeDate v) => d.firstDue = v),
                    ),
            ),
            ?error('firstDue'),
            LumeFormPicker(
              key: LumeCommitteeTool.roleField,
              label: l.commFieldRole,
              value: switch (d.role) {
                CommitteeReaderRole.member => l.commRoleMember,
                CommitteeReaderRole.organiser => l.commRoleOrganiser,
                CommitteeReaderRole.organiserMember => l.commRoleBoth,
              },
              onTap: () => unawaited(
                _pick<CommitteeReaderRole>(
                  l.commFieldRole,
                  <(CommitteeReaderRole, String)>[
                    (CommitteeReaderRole.member, l.commRoleMember),
                    (CommitteeReaderRole.organiserMember, l.commRoleBoth),
                    (CommitteeReaderRole.organiser, l.commRoleOrganiser),
                  ],
                  d.role,
                  (CommitteeReaderRole v) => d.role = v,
                ),
              ),
            ),
            ?error('role'),
            LumeFormField(
              key: LumeCommitteeTool.noteField,
              label: l.commFieldNote,
              optionalLabel: l.commonOptional,
              controller: d.note,
              kind: LumeFieldKind.multiline,
              error: d.errors['note'],
            ),
          ],
        ),
      ),
      LumeToolSection(
        title: l.commFieldMembers,
        child: Column(
          key: LumeCommitteeTool.membersField,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(l.commMembersHelp),
            ),
            ...memberRows,
            ?error('members'),
            if (!locked)
              LumeButton(
                key: LumeCommitteeTool.addMemberKey,
                label: l.commAddMember,
                icon: LumeIcons.plus,
                onPressed: () => setState(() => d.members.add(_MemberDraft())),
              ),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeSubmitBar(
          saveLabel: l.actionSave,
          cancelLabel: l.actionCancel,
          onSave: () => unawaited(_save(l)),
          onCancel: () => unawaited(_back()),
        ),
      ),
    ];
  }

  /// The reader's currency, those already in use, then every other one a
  /// new committee may use; a committee's own withdrawn currency only for
  /// that committee.
  List<LumeCurrency> _currencyChoices(_CommitteeDraft d) {
    final LumeCurrency? mine = _currency();
    final LumeCurrency? own = d.id == null ? null : d.currency;
    final CommitteeBook book = _repo.view().book(null);
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

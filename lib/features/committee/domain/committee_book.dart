/// What a committee's records add up to (`COMMITTEE_PROPOSAL.md` §6–§8).
///
/// Nothing here is stored. Every figure is worked out from the records each
/// time they are read, in minor units of the committee's own currency:
///
/// ```text
/// pool per cycle   = contribution × N
/// expected total   = contribution × N × N
/// collected        = Σ active contributions
/// paid out         = Σ active payouts
/// due to the day   = pool × (cycles due on or before the day)
/// outstanding      = due to the day − collected in those cycles
/// ```
///
/// The day is an input, never read from a clock here. Without it no state
/// is claimed: a cycle is neither late nor upcoming, and "outstanding" is
/// unknown rather than guessed.
///
/// A cancelled committee's cutoff is the day it was cancelled, not today
/// (D-C7). Cycles due after it never raised an obligation; a gap before it
/// stays visible as unpaid at cancellation, and stops growing.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import 'committee_model.dart';

/// What one position owes for one cycle, as it stands.
enum CommitteeSlotStatus {
  /// An active contribution is recorded.
  paid,

  /// Nothing recorded, and the cycle falls due today.
  dueToday,

  /// Nothing recorded, and the cycle fell due before today.
  late,

  /// Nothing recorded, and the cycle falls due later.
  upcoming,

  /// Nothing recorded, the committee is cancelled, and the cycle was due on
  /// or before the day it was cancelled.
  unpaidAtCancellation,

  /// The committee was cancelled before this cycle fell due: it never
  /// raised an obligation.
  notDue,

  /// Nothing recorded, and the reader's day is not available.
  unknown,
}

/// Where a cycle's pool has got to.
enum CommitteeCyclePayoutStatus {
  /// The reader has recorded the payout.
  recorded,

  /// Fully collected, and the committee is running: it can be recorded.
  ready,

  /// Part collected. Nothing may be paid out yet (D-C3).
  waiting,

  /// Nothing collected yet.
  upcoming,
}

/// The committee as a whole.
enum CommitteeStatus { active, completed, cancelled }

/// One position's obligation for one cycle.
@immutable
class CommitteeSlot {
  const CommitteeSlot(
    this.cycle,
    this.position,
    this.contribution,
    this.status,
    this.contributions,
  );

  final CommitteeCycle cycle;
  final CommitteePosition position;

  /// The active contribution, if there is one.
  final CommitteeContribution? contribution;
  final CommitteeSlotStatus status;

  /// Every contribution for this slot, voided ones included.
  final List<CommitteeContribution> contributions;

  bool get paid => contribution != null;
}

/// One cycle: who receives it, who has paid into it, and its payout.
@immutable
class CommitteeCycleView {
  const CommitteeCycleView({
    required this.cycle,
    required this.recipient,
    required this.recipientMember,
    required this.slots,
    required this.payout,
    required this.payouts,
    required this.collected,
    required this.pool,
    required this.payoutStatus,
  });

  final CommitteeCycle cycle;

  /// The position that receives this cycle's pool.
  final CommitteePosition recipient;
  final CommitteeMember recipientMember;

  /// One per position, in position order.
  final List<CommitteeSlot> slots;

  /// The active payout, if the reader has recorded it.
  final CommitteePayout? payout;
  final List<CommitteePayout> payouts;
  final LumeMoney collected;
  final LumeMoney pool;
  final CommitteeCyclePayoutStatus payoutStatus;

  int get n => cycle.n;
  LumeDate get due => cycle.due;
  bool get complete => collected.minor == pool.minor;
  bool get paidOut => payout != null;
  int get paidCount => slots.where((CommitteeSlot s) => s.paid).length;
  LumeMoney get short => pool - collected;
  int get lateCount => slots
      .where((CommitteeSlot s) => s.status == CommitteeSlotStatus.late)
      .length;
}

/// One member: their shares, and what they have paid and received.
@immutable
class CommitteeMemberView {
  const CommitteeMemberView({
    required this.member,
    required this.positions,
    required this.expected,
    required this.paid,
    required this.received,
    required this.paidCount,
    required this.lateCount,
    required this.dueCount,
  });

  final CommitteeMember member;

  /// Their positions, by the cycle each one receives.
  final List<CommitteePosition> positions;

  /// contribution × N × shares: what this member pays over the committee.
  final LumeMoney expected;
  final LumeMoney paid;
  final LumeMoney received;

  /// How many of their slots are paid.
  final int paidCount;

  /// How many are late, or `null` when the day is not available.
  final int? lateCount;

  /// How many slots they owe in all: shares × cycles.
  final int dueCount;

  int get shares => positions.length;
  bool get isReader => member.isReader;
  String get name => member.name;

  /// The cycles this member receives, in order.
  List<int> get turns =>
      <int>[for (final CommitteePosition p in positions) p.cycle]..sort();
}

/// Why a committee's records cannot be trusted as a whole.
@immutable
class CommitteeDamage {
  const CommitteeDamage(this.committee, this.reason, [this.id]);

  /// The committee id as the records name it.
  final String committee;

  /// A stable machine word: positionCount, cycleCount, cycleNumbers,
  /// positionCycles, positionMember, readerRole, currency, contribution,
  /// payoutAmount, notRecipient, payoutShort, twoContributions, twoPayouts,
  /// dueOrder, orphanMember, orphanPosition, orphanCycle,
  /// orphanContribution, orphanPayout, defect, overflow.
  final String reason;

  /// The offending record, when one record is to blame.
  final String? id;

  @override
  String toString() => '$committee: $reason${id == null ? '' : ' ($id)'}';
}

/// One committee, read.
@immutable
class CommitteeView {
  const CommitteeView._({
    required this.committee,
    required this.members,
    required this.cycles,
    required this.contributions,
    required this.payouts,
    required this.damage,
    required this.collected,
    required this.paidOut,
    required this.dueToCutoff,
    required this.cutoff,
    required this.lastActivity,
  });

  final Committee committee;

  /// Members in the order they were added, the reader first.
  final List<CommitteeMemberView> members;

  /// Cycles 1..N in order.
  final List<CommitteeCycleView> cycles;

  /// Every contribution, newest first, voided ones included.
  final List<CommitteeContribution> contributions;

  /// Every payout, newest first, voided ones included.
  final List<CommitteePayout> payouts;

  final String? damage;

  /// Σ active contributions.
  final LumeMoney collected;

  /// Σ active payouts.
  final LumeMoney paidOut;

  /// What was owed up to the cutoff — the day it was cancelled, or today —
  /// or `null` when there is no day to work from.
  final LumeMoney? dueToCutoff;

  /// The day the figures are worked out to: the day it was cancelled, or
  /// the reader's day. `null` when there is no day to work from.
  final LumeDate? cutoff;

  final DateTime lastActivity;

  bool get damaged => damage != null;
  LumeRecordId get id => committee.id;
  String get name => committee.name;
  LumeCurrency get currency => committee.currency;
  LumeMoney get contribution => committee.contribution;
  int get positionCount => committee.positions;
  int get memberCount => members.length;
  LumeMoney get pool => committee.pool;
  LumeMoney get expectedTotal => committee.expectedTotal;

  /// Collected and not yet paid out: what the committee is holding.
  LumeMoney get held => collected - paidOut;

  /// What is owed and not paid, to the cutoff. `null` without a day.
  ///
  /// While the committee runs this is what is late. Once it is cancelled
  /// this is what was unpaid when it stopped, and it does not grow.
  LumeMoney? get outstanding {
    final LumeMoney? due = dueToCutoff;
    if (due == null) return null;
    final LumeMoney inThose = LumeMoney.total(<LumeMoney>[
      for (final CommitteeCycleView c in cycles)
        if (_withinCutoff(c)) c.collected,
    ], currency);
    final LumeMoney left = due - inThose;
    return left.isNegative ? LumeMoney.zero(currency) : left;
  }

  /// True when [outstanding] is what was unpaid at cancellation rather than
  /// what is late (correction 2.1).
  bool get outstandingIsFinal => committee.cancelled;

  CommitteeStatus get status {
    if (committee.cancelled) return CommitteeStatus.cancelled;
    if (cycles.isNotEmpty &&
        cycles.every((CommitteeCycleView c) => c.paidOut)) {
      return CommitteeStatus.completed;
    }
    return CommitteeStatus.active;
  }

  bool get complete => status == CommitteeStatus.completed;

  /// How many cycles have a payout recorded.
  int get paidOutCycles =>
      cycles.where((CommitteeCycleView c) => c.paidOut).length;

  /// The member who is the reader, if this committee has one.
  CommitteeMemberView? get reader {
    for (final CommitteeMemberView m in members) {
      if (m.isReader) return m;
    }
    return null;
  }

  LumeMoney get readerPaidIn => reader?.paid ?? LumeMoney.zero(currency);
  LumeMoney get readerReceived => reader?.received ?? LumeMoney.zero(currency);
  LumeMoney get readerNet => readerReceived - readerPaidIn;

  /// What the reader owes each cycle: contribution × their shares.
  LumeMoney get readerPerCycle =>
      LumeMoney.sum(contribution.minor * (reader?.shares ?? 0), currency);

  /// The reader's next cycle to receive, or `null` if they have none left.
  CommitteeCycleView? get readerNextTurn {
    final CommitteeMemberView? me = reader;
    if (me == null) return null;
    for (final CommitteeCycleView c in cycles) {
      if (c.recipient.memberId == me.member.id && !c.paidOut) return c;
    }
    return null;
  }

  /// The latest cycle due on or before the day, or cycle 1 before it
  /// starts. `null` without a day.
  CommitteeCycleView? current(LumeDate? today) {
    if (today == null || cycles.isEmpty) return null;
    CommitteeCycleView? at;
    for (final CommitteeCycleView c in cycles) {
      if (!c.due.isAfter(today)) at = c;
    }
    return at ?? cycles.first;
  }

  CommitteeCycleView? cycleOf(LumeRecordId id) {
    for (final CommitteeCycleView c in cycles) {
      if (c.cycle.id == id) return c;
    }
    return null;
  }

  CommitteeMemberView? memberOf(LumeRecordId id) {
    for (final CommitteeMemberView m in members) {
      if (m.member.id == id) return m;
    }
    return null;
  }

  /// Whether a cycle had fallen due by the cutoff. A cycle that has not —
  /// one a member chose to pay early — owes nothing yet, and what was
  /// paid into it does not cancel out what an earlier cycle is short.
  bool _withinCutoff(CommitteeCycleView c) {
    final LumeDate? cut = cutoff;
    return cut != null && !c.due.isAfter(cut);
  }
}

/// Every committee the reader has, read together.
@immutable
class CommitteeBook {
  const CommitteeBook._({
    required this.committees,
    required this.defects,
    required this.damage,
    required this.today,
  });

  /// Committees, most recently active first.
  final List<CommitteeView> committees;

  /// Records that could not be read at all.
  final List<CommitteeDefect> defects;

  /// Committees whose records do not hold together.
  final List<CommitteeDamage> damage;

  /// The reader's day, or `null` when it could not be resolved.
  final LumeDate? today;

  bool get dayKnown => today != null;
  bool get isEmpty => committees.isEmpty;

  CommitteeView? committee(LumeRecordId id) {
    for (final CommitteeView v in committees) {
      if (v.committee.id == id) return v;
    }
    return null;
  }

  /// The currencies in play, in a stable order.
  List<LumeCurrency> get currencies {
    final List<LumeCurrency> out = <LumeCurrency>[];
    for (final CommitteeView v in committees) {
      if (!out.contains(v.currency)) out.add(v.currency);
    }
    out.sort((LumeCurrency a, LumeCurrency b) => a.code.compareTo(b.code));
    return out;
  }

  /// What a currency's committees add up to. Damaged ones are left out of
  /// every figure, as are cancelled ones from what is still expected.
  CommitteeCurrencySummary summary(LumeCurrency c) {
    final List<CommitteeView> mine = <CommitteeView>[
      for (final CommitteeView v in committees)
        if (v.currency == c && !v.damaged) v,
    ];
    final bool anyUnknown =
        today == null && mine.any((CommitteeView v) => !v.committee.cancelled);
    return CommitteeCurrencySummary(
      currency: c,
      running: mine
          .where((CommitteeView v) => v.status == CommitteeStatus.active)
          .length,
      collected: LumeMoney.total(<LumeMoney>[
        for (final CommitteeView v in mine) v.collected,
      ], c),
      paidOut: LumeMoney.total(<LumeMoney>[
        for (final CommitteeView v in mine) v.paidOut,
      ], c),
      outstanding: anyUnknown
          ? null
          : LumeMoney.total(<LumeMoney>[
              for (final CommitteeView v in mine) ?v.outstanding,
            ], c),
      readerNet: LumeMoney.total(<LumeMoney>[
        for (final CommitteeView v in mine) v.readerNet,
      ], c),
    );
  }

  List<CommitteeCurrencySummary> get summaries => <CommitteeCurrencySummary>[
    for (final LumeCurrency c in currencies) summary(c),
  ];

  /// Everything the reader recorded, newest first: contributions and
  /// payouts together.
  List<CommitteeHistoryEntry> get history {
    final List<CommitteeHistoryEntry> out = <CommitteeHistoryEntry>[];
    for (final CommitteeView v in committees) {
      for (final CommitteeContribution x in v.contributions) {
        out.add(CommitteeHistoryEntry(v, contribution: x));
      }
      for (final CommitteePayout x in v.payouts) {
        out.add(CommitteeHistoryEntry(v, payout: x));
      }
    }
    out.sort(
      (CommitteeHistoryEntry a, CommitteeHistoryEntry b) => committeeEntryOrder(
        a.paidOn,
        a.createdAt,
        a.id,
        b.paidOn,
        b.createdAt,
        b.id,
      ),
    );
    return out;
  }

  /// The rules that do not hold, as stable words. Empty means they all do.
  ///
  /// These are the arithmetic identities of §7: the structural rules are
  /// reported as [damage] instead, because a committee that breaks one
  /// cannot be summed at all.
  List<String> invariants() {
    final List<String> broken = <String>[];
    for (final CommitteeView v in committees) {
      if (v.damaged) continue;
      final String id = v.committee.id.value;
      final LumeCurrency c = v.currency;
      // The rows add to the summary.
      final LumeMoney fromCycles = LumeMoney.total(<LumeMoney>[
        for (final CommitteeCycleView x in v.cycles) x.collected,
      ], c);
      if (fromCycles.minor != v.collected.minor) broken.add('collected $id');
      final LumeMoney fromMembers = LumeMoney.total(<LumeMoney>[
        for (final CommitteeMemberView m in v.members) m.paid,
      ], c);
      if (fromMembers.minor != v.collected.minor) broken.add('members $id');
      final LumeMoney received = LumeMoney.total(<LumeMoney>[
        for (final CommitteeMemberView m in v.members) m.received,
      ], c);
      if (received.minor != v.paidOut.minor) broken.add('received $id');
      // Nothing leaves that did not come in.
      if (v.paidOut.compareTo(v.collected) > 0) broken.add('paidOut $id');
      // A cycle never holds more than its pool.
      for (final CommitteeCycleView x in v.cycles) {
        if (x.collected.compareTo(x.pool) > 0) {
          broken.add('cycle $id');
          break;
        }
      }
      // The pool and the total are the contribution, multiplied out.
      if (v.pool.minor != v.contribution.minor * v.positionCount) {
        broken.add('pool $id');
      }
      if (v.expectedTotal.minor != v.pool.minor * v.positionCount) {
        broken.add('total $id');
      }
      // Every member's expected share of the whole adds up to it.
      final int expected = LumeMoney.total(<LumeMoney>[
        for (final CommitteeMemberView m in v.members) m.expected,
      ], c).minor;
      if (expected != v.expectedTotal.minor) broken.add('expected $id');
    }
    return broken;
  }

  /// Read every committee from its records.
  factory CommitteeBook.from({
    required List<Committee> committees,
    required List<CommitteeMember> members,
    required List<CommitteePosition> positions,
    required List<CommitteeCycle> cycles,
    required List<CommitteeContribution> contributions,
    required List<CommitteePayout> payouts,
    List<CommitteeDefect> defects = const <CommitteeDefect>[],
    required LumeDate? today,
  }) {
    final List<CommitteeDamage> damage = <CommitteeDamage>[];
    final Map<String, Committee> byId = <String, Committee>{
      for (final Committee c in committees) c.id.value: c,
    };

    List<T> own<T>(List<T> all, String Function(T) owner, String id) {
      final List<T> mine = <T>[];
      for (final T x in all) {
        if (owner(x) == id) mine.add(x);
      }
      return mine;
    }

    // Anything pointing at a committee that is not there is an orphan, and
    // is reported rather than dropped in silence.
    void orphans<T>(
      List<T> all,
      String Function(T) owner,
      String Function(T) idOf,
      String reason,
    ) {
      for (final T x in all) {
        if (!byId.containsKey(owner(x))) {
          damage.add(CommitteeDamage(owner(x), reason, idOf(x)));
        }
      }
    }

    orphans<CommitteeMember>(
      members,
      (CommitteeMember x) => x.committeeId.value,
      (CommitteeMember x) => x.id.value,
      'orphanMember',
    );
    orphans<CommitteePosition>(
      positions,
      (CommitteePosition x) => x.committeeId.value,
      (CommitteePosition x) => x.id.value,
      'orphanPosition',
    );
    orphans<CommitteeCycle>(
      cycles,
      (CommitteeCycle x) => x.committeeId.value,
      (CommitteeCycle x) => x.id.value,
      'orphanCycle',
    );
    orphans<CommitteeContribution>(
      contributions,
      (CommitteeContribution x) => x.committeeId.value,
      (CommitteeContribution x) => x.id.value,
      'orphanContribution',
    );
    orphans<CommitteePayout>(
      payouts,
      (CommitteePayout x) => x.committeeId.value,
      (CommitteePayout x) => x.id.value,
      'orphanPayout',
    );

    final Set<String> defective = <String>{
      for (final CommitteeDefect d in defects) ?d.committeeId,
    };

    final List<CommitteeView> views = <CommitteeView>[];
    for (final Committee c in committees) {
      final String id = c.id.value;
      final List<CommitteeMember> ms = own<CommitteeMember>(
        members,
        (CommitteeMember x) => x.committeeId.value,
        id,
      );
      final List<CommitteePosition> ps =
          own<CommitteePosition>(
            positions,
            (CommitteePosition x) => x.committeeId.value,
            id,
          )..sort(
            (CommitteePosition a, CommitteePosition b) =>
                a.cycle.compareTo(b.cycle),
          );
      final List<CommitteeCycle> cs = own<CommitteeCycle>(
        cycles,
        (CommitteeCycle x) => x.committeeId.value,
        id,
      )..sort((CommitteeCycle a, CommitteeCycle b) => a.n.compareTo(b.n));
      final List<CommitteeContribution> xs = own<CommitteeContribution>(
        contributions,
        (CommitteeContribution x) => x.committeeId.value,
        id,
      )..sort(_contributionOrder);
      final List<CommitteePayout> os = own<CommitteePayout>(
        payouts,
        (CommitteePayout x) => x.committeeId.value,
        id,
      )..sort(_payoutOrder);

      String? why = _check(c, ms, ps, cs, xs, os);
      if (why == null && defective.contains(id)) why = 'defect';
      if (why != null) damage.add(CommitteeDamage(id, why));
      views.add(_view(c, ms, ps, cs, xs, os, why, today));
    }

    views.sort(
      (CommitteeView a, CommitteeView b) =>
          b.lastActivity.compareTo(a.lastActivity),
    );
    return CommitteeBook._(
      committees: views,
      defects: defects,
      damage: damage,
      today: today,
    );
  }

  /// Everything a committee must be for its figures to mean anything.
  /// Returns the first rule it breaks, or `null`.
  static String? _check(
    Committee c,
    List<CommitteeMember> members,
    List<CommitteePosition> positions,
    List<CommitteeCycle> cycles,
    List<CommitteeContribution> contributions,
    List<CommitteePayout> payouts,
  ) {
    final int n = c.positions;
    if (positions.length != n) return 'positionCount';
    if (cycles.length != n) return 'cycleCount';

    // Cycles are 1..N, once each, and their dates only ever go forward.
    final Set<int> seen = <int>{};
    for (final CommitteeCycle x in cycles) {
      if (x.n < 1 || x.n > n || !seen.add(x.n)) return 'cycleNumbers';
    }
    for (int i = 1; i < cycles.length; i++) {
      if (cycles[i].due.isBefore(cycles[i - 1].due)) return 'dueOrder';
    }

    // Every cycle has exactly one recipient position.
    final Set<int> held = <int>{};
    final Map<String, CommitteeMember> people = <String, CommitteeMember>{
      for (final CommitteeMember m in members) m.id.value: m,
    };
    for (final CommitteePosition p in positions) {
      if (p.cycle < 1 || p.cycle > n || !held.add(p.cycle)) {
        return 'positionCycles';
      }
      if (!people.containsKey(p.memberId.value)) return 'positionMember';
    }

    // The role and the reader flag say the same thing (correction 2.2).
    final int readers = members.where((CommitteeMember m) => m.isReader).length;
    final bool wantsOne = c.readerRole != CommitteeReaderRole.organiser;
    if (wantsOne && readers != 1) return 'readerRole';
    if (!wantsOne && readers != 0) return 'readerRole';

    final Map<String, CommitteeCycle> cycleById = <String, CommitteeCycle>{
      for (final CommitteeCycle x in cycles) x.id.value: x,
    };
    final Map<String, CommitteePosition> posById = <String, CommitteePosition>{
      for (final CommitteePosition p in positions) p.id.value: p,
    };

    // One whole share, in the committee's currency, once per slot.
    final Set<String> slots = <String>{};
    final Map<int, int> collected = <int, int>{};
    for (final CommitteeContribution x in contributions) {
      final CommitteeCycle? cy = cycleById[x.cycleId.value];
      final CommitteePosition? p = posById[x.positionId.value];
      if (cy == null || p == null) return 'contributionRef';
      if (x.currency != c.currency) return 'currency';
      if (x.amount.minor != c.contribution.minor) return 'contribution';
      if (!x.active) continue;
      if (!slots.add('${cy.n}/${p.id.value}')) return 'twoContributions';
      collected[cy.n] = (collected[cy.n] ?? 0) + x.amount.minor;
    }

    // One payout per cycle, to the position that holds it, for the pool,
    // and never more than that cycle collected.
    final Set<int> paid = <int>{};
    for (final CommitteePayout o in payouts) {
      final CommitteeCycle? cy = cycleById[o.cycleId.value];
      final CommitteePosition? p = posById[o.positionId.value];
      if (cy == null || p == null) return 'payoutRef';
      if (o.currency != c.currency) return 'currency';
      if (p.cycle != cy.n) return 'notRecipient';
      if (!o.active) continue;
      if (!paid.add(cy.n)) return 'twoPayouts';
      if (o.amount.minor != c.pool.minor) return 'payoutAmount';
      if ((collected[cy.n] ?? 0) < c.pool.minor) return 'payoutShort';
    }
    return null;
  }

  static CommitteeView _view(
    Committee c,
    List<CommitteeMember> members,
    List<CommitteePosition> positions,
    List<CommitteeCycle> cycles,
    List<CommitteeContribution> contributions,
    List<CommitteePayout> payouts,
    String? damage,
    LumeDate? today,
  ) {
    final LumeCurrency cur = c.currency;
    final Map<String, CommitteeMember> memberById = <String, CommitteeMember>{
      for (final CommitteeMember m in members) m.id.value: m,
    };

    // The cutoff: the day it was cancelled, or the reader's day.
    final LumeDate? cutoff = c.cancelledOn ?? today;

    final List<CommitteeCycleView> cycleViews = <CommitteeCycleView>[];
    for (final CommitteeCycle cy in cycles) {
      final List<CommitteeContribution> here = <CommitteeContribution>[
        for (final CommitteeContribution x in contributions)
          if (x.cycleId == cy.id) x,
      ];
      final List<CommitteeSlot> slots = <CommitteeSlot>[];
      int collected = 0;
      for (final CommitteePosition p in positions) {
        final List<CommitteeContribution> mine = <CommitteeContribution>[
          for (final CommitteeContribution x in here)
            if (x.positionId == p.id) x,
        ];
        CommitteeContribution? active;
        for (final CommitteeContribution x in mine) {
          if (x.active) active = x;
        }
        if (active != null) collected += active.amount.minor;
        slots.add(
          CommitteeSlot(
            cy,
            p,
            active,
            _slotStatus(c, cy, active != null, today),
            mine,
          ),
        );
      }
      final List<CommitteePayout> mine = <CommitteePayout>[
        for (final CommitteePayout o in payouts)
          if (o.cycleId == cy.id) o,
      ];
      CommitteePayout? active;
      for (final CommitteePayout o in mine) {
        if (o.active) active = o;
      }
      final CommitteePosition? recipient = _recipient(positions, cy.n);
      cycleViews.add(
        CommitteeCycleView(
          cycle: cy,
          recipient: recipient ?? positions.first,
          recipientMember:
              memberById[(recipient ?? positions.first).memberId.value] ??
              members.first,
          slots: slots,
          payout: active,
          payouts: mine,
          collected: LumeMoney.sum(collected, cur),
          pool: c.pool,
          payoutStatus: active != null
              ? CommitteeCyclePayoutStatus.recorded
              : collected == 0
              ? CommitteeCyclePayoutStatus.upcoming
              : collected >= c.pool.minor && !c.cancelled
              ? CommitteeCyclePayoutStatus.ready
              : CommitteeCyclePayoutStatus.waiting,
        ),
      );
    }

    // Members: their shares, and what each has paid and received.
    final List<CommitteeMemberView> memberViews = <CommitteeMemberView>[];
    for (final CommitteeMember m in members) {
      final List<CommitteePosition> mine =
          <CommitteePosition>[
            for (final CommitteePosition p in positions)
              if (p.memberId == m.id) p,
          ]..sort(
            (CommitteePosition a, CommitteePosition b) =>
                a.cycle.compareTo(b.cycle),
          );
      final Set<String> ids = <String>{
        for (final CommitteePosition p in mine) p.id.value,
      };
      int paid = 0;
      int paidCount = 0;
      for (final CommitteeContribution x in contributions) {
        if (x.active && ids.contains(x.positionId.value)) {
          paid += x.amount.minor;
          paidCount++;
        }
      }
      int received = 0;
      for (final CommitteePayout o in payouts) {
        if (o.active && ids.contains(o.positionId.value)) {
          received += o.amount.minor;
        }
      }
      int? lateCount;
      if (today != null || c.cancelled) {
        lateCount = 0;
        for (final CommitteeCycleView cv in cycleViews) {
          for (final CommitteeSlot s in cv.slots) {
            if (ids.contains(s.position.id.value) &&
                (s.status == CommitteeSlotStatus.late ||
                    s.status == CommitteeSlotStatus.unpaidAtCancellation)) {
              lateCount = lateCount! + 1;
            }
          }
        }
      }
      memberViews.add(
        CommitteeMemberView(
          member: m,
          positions: mine,
          expected: LumeMoney.sum(
            c.contribution.minor * c.positions * mine.length,
            cur,
          ),
          paid: LumeMoney.sum(paid, cur),
          received: LumeMoney.sum(received, cur),
          paidCount: paidCount,
          lateCount: lateCount,
          dueCount: c.positions * mine.length,
        ),
      );
    }
    memberViews.sort((CommitteeMemberView a, CommitteeMemberView b) {
      if (a.isReader != b.isReader) return a.isReader ? -1 : 1;
      return a.member.createdAt.compareTo(b.member.createdAt);
    });

    // What was owed up to the cutoff.
    LumeMoney? dueToCutoff;
    if (cutoff != null) {
      int cyclesDue = 0;
      for (final CommitteeCycle cy in cycles) {
        if (!cy.due.isAfter(cutoff)) cyclesDue++;
      }
      dueToCutoff = LumeMoney.sum(c.pool.minor * cyclesDue, cur);
    }

    DateTime last = c.createdAt;
    for (final CommitteeContribution x in contributions) {
      if (x.createdAt.isAfter(last)) last = x.createdAt;
    }
    for (final CommitteePayout o in payouts) {
      if (o.createdAt.isAfter(last)) last = o.createdAt;
    }

    return CommitteeView._(
      committee: c,
      members: memberViews,
      cycles: cycleViews,
      contributions: contributions,
      payouts: payouts,
      damage: damage,
      collected: LumeMoney.total(<LumeMoney>[
        for (final CommitteeContribution x in contributions)
          if (x.active) x.amount,
      ], cur),
      paidOut: LumeMoney.total(<LumeMoney>[
        for (final CommitteePayout o in payouts)
          if (o.active) o.amount,
      ], cur),
      dueToCutoff: dueToCutoff,
      cutoff: cutoff,
      lastActivity: last,
    );
  }

  static CommitteePosition? _recipient(
    List<CommitteePosition> positions,
    int cycle,
  ) {
    for (final CommitteePosition p in positions) {
      if (p.cycle == cycle) return p;
    }
    return null;
  }

  static CommitteeSlotStatus _slotStatus(
    Committee c,
    CommitteeCycle cycle,
    bool paid,
    LumeDate? today,
  ) {
    if (paid) return CommitteeSlotStatus.paid;
    final LumeDate? cancelled = c.cancelledOn;
    if (cancelled != null) {
      return cycle.due.isAfter(cancelled)
          ? CommitteeSlotStatus.notDue
          : CommitteeSlotStatus.unpaidAtCancellation;
    }
    if (today == null) return CommitteeSlotStatus.unknown;
    if (cycle.due == today) return CommitteeSlotStatus.dueToday;
    return cycle.due.isBefore(today)
        ? CommitteeSlotStatus.late
        : CommitteeSlotStatus.upcoming;
  }

  static int _contributionOrder(
    CommitteeContribution a,
    CommitteeContribution b,
  ) => committeeEntryOrder(
    a.paidOn,
    a.createdAt,
    a.id,
    b.paidOn,
    b.createdAt,
    b.id,
  );

  static int _payoutOrder(CommitteePayout a, CommitteePayout b) =>
      committeeEntryOrder(
        a.paidOn,
        a.createdAt,
        a.id,
        b.paidOn,
        b.createdAt,
        b.id,
      );
}

/// A currency's committees, added up.
@immutable
class CommitteeCurrencySummary {
  const CommitteeCurrencySummary({
    required this.currency,
    required this.running,
    required this.collected,
    required this.paidOut,
    required this.outstanding,
    required this.readerNet,
  });

  final LumeCurrency currency;
  final int running;
  final LumeMoney collected;
  final LumeMoney paidOut;

  /// `null` when the reader's day is not available for a running committee.
  final LumeMoney? outstanding;
  final LumeMoney readerNet;
}

/// One thing the reader recorded, for the history list.
@immutable
class CommitteeHistoryEntry {
  const CommitteeHistoryEntry(this.view, {this.contribution, this.payout});

  final CommitteeView view;
  final CommitteeContribution? contribution;
  final CommitteePayout? payout;

  bool get isPayout => payout != null;
  LumeRecordId get id => payout?.id ?? contribution!.id;
  LumeDate get paidOn => payout?.paidOn ?? contribution!.paidOn;
  DateTime get createdAt => payout?.createdAt ?? contribution!.createdAt;
  LumeMoney get amount => payout?.amount ?? contribution!.amount;
  bool get voided => payout?.voided ?? contribution!.voided;
  LumeRecordId get cycleId => payout?.cycleId ?? contribution!.cycleId;
  LumeRecordId get positionId => payout?.positionId ?? contribution!.positionId;
}

/// Newest first: the day it happened, then the moment it was recorded, then
/// the id, so the order never wobbles between reads.
int committeeEntryOrder(
  LumeDate aPaidOn,
  DateTime aCreatedAt,
  LumeRecordId aId,
  LumeDate bPaidOn,
  DateTime bCreatedAt,
  LumeRecordId bId,
) {
  final int d = bPaidOn.compareTo(aPaidOn);
  if (d != 0) return d;
  final int t = bCreatedAt.compareTo(aCreatedAt);
  return t != 0 ? t : aId.compareTo(bId);
}

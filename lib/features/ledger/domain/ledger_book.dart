/// Everything Ledger shows that is not stored: what remains on each loan,
/// credit, each person's balance per currency, overdue, the summary and the
/// People count (`LEDGER_PROPOSAL.md` §6, §7). A disposable projection,
/// rebuilt from entries and allocations whenever they change, and checked
/// against them ([LedgerBook.invariants]).
///
/// ```
/// remaining(p) = p.amount − Σ allocations to p        (p principal)
/// credit(r)    = r.amount − Σ allocations from r      (r repayment)
/// owedToYou    = Σ remaining(lent)     + Σ credit(repaidByMe)
/// youOwe       = Σ remaining(borrowed) + Σ credit(repaidToMe)
/// balance      = owedToYou − youOwe
///              ≡ (Σ lent − Σ repaidToMe) − (Σ borrowed − Σ repaidByMe)
/// ```
///
/// Only allocations whose repayment and principal are both active count.
/// A lent and a borrowed with one person are never offset: both stay open,
/// the net may be zero, and the person is not settled until every
/// principal has nothing remaining and no credit is left in any currency.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import 'ledger_model.dart';
import 'ledger_reconcile.dart';

/// Which way a person's balance in one currency points.
enum LedgerDirection {
  /// They owe the reader.
  owesYou,

  /// The reader owes them.
  youOwe,

  /// Something is open both ways and the net is zero — not settled.
  even,

  /// Nothing remaining, no credit.
  settled,
}

/// One principal, as it stands.
@immutable
class LedgerPrincipalState {
  const LedgerPrincipalState(this.entry, this.remaining, this.overdue);

  final LedgerEntry entry;
  final LumeMoney remaining;

  /// `null` when the reader's day is unknown.
  final bool? overdue;

  bool get open => remaining.isPositive;
}

/// One person's standing in one currency.
@immutable
class LedgerBalance {
  const LedgerBalance({
    required this.party,
    required this.currency,
    required this.owedToYou,
    required this.youOwe,
    required this.creditToThem,
    required this.creditFromThem,
    required this.principals,
    required this.overdue,
    required this.shownDue,
    required this.damaged,
    required this.lastActivity,
  });

  final LedgerParty party;
  final LumeCurrency currency;

  /// Σ remaining(lent) + credit they hold from the reader's repayments.
  final LumeMoney owedToYou;

  /// Σ remaining(borrowed) + credit the reader holds for them.
  final LumeMoney youOwe;

  /// Their overpayment, kept as credit: the reader owes it back.
  final LumeMoney creditToThem;

  /// The reader's overpayment, kept as credit: they owe it back.
  final LumeMoney creditFromThem;

  /// Every active principal in this currency, FIFO-by-obligation.
  final List<LedgerPrincipalState> principals;

  /// `null` when the reader's day is unknown.
  final bool? overdue;

  /// The oldest overdue due date, else the next due date still open.
  final LumeDate? shownDue;

  /// The allocations of this person and currency break the rules on file.
  final bool damaged;

  /// The latest entry, for "recent activity" order.
  final LedgerEntry? lastActivity;

  LumeMoney get balance => owedToYou - youOwe;

  bool get settled =>
      principals.every((LedgerPrincipalState p) => !p.open) &&
      creditToThem.isZero &&
      creditFromThem.isZero;

  LedgerDirection get direction => settled
      ? LedgerDirection.settled
      : balance.isPositive
      ? LedgerDirection.owesYou
      : balance.isNegative
      ? LedgerDirection.youOwe
      : LedgerDirection.even;

  /// Open principals of one kind.
  List<LedgerPrincipalState> open(LedgerKind kind) => <LedgerPrincipalState>[
    for (final LedgerPrincipalState p in principals)
      if (p.entry.kind == kind && p.open) p,
  ];
}

/// The summary of one currency — always the whole ledger, whatever is
/// filtered or searched.
@immutable
class LedgerCurrencySummary {
  const LedgerCurrencySummary(this.currency, this.owedToYou, this.youOwe);

  final LumeCurrency currency;

  /// Σ positive balances.
  final LumeMoney owedToYou;

  /// Σ |negative balances|.
  final LumeMoney youOwe;

  LumeMoney get net => owedToYou - youOwe;
}

/// A problem found reading the ledger back — shown, never repaired
/// silently.
@immutable
class LedgerDamage {
  const LedgerDamage(this.party, this.currency, this.reason, [this.id]);

  final LumeRecordId party;
  final LumeCurrency currency;

  /// `revision`, `dangling`, `incompatible`, `overAllocated`,
  /// `unconfirmedCredit`, `unknownParty`.
  final String reason;
  final LumeRecordId? id;
}

@immutable
class LedgerBook {
  const LedgerBook._({
    required this.parties,
    required this.entries,
    required this.allocations,
    required this.defects,
    required this.today,
    required this.balances,
    required this.remaining,
    required this.credit,
    required this.damage,
    required this.summaries,
    required this.people,
  });

  /// Derive everything from the records. [today] is the reader's calendar
  /// date in their resolved zone, or `null` when it cannot be worked out —
  /// then nothing is said to be overdue or not.
  factory LedgerBook.from({
    required List<LedgerParty> parties,
    required List<LedgerEntry> entries,
    required List<LedgerAllocation> allocations,
    List<LedgerDefect> defects = const <LedgerDefect>[],
    required LumeDate? today,
  }) {
    final Map<LumeRecordId, LedgerEntry> byId = <LumeRecordId, LedgerEntry>{
      for (final LedgerEntry e in entries) e.id: e,
    };
    final Map<LumeRecordId, LedgerParty> partyOf = <LumeRecordId, LedgerParty>{
      for (final LedgerParty p in parties) p.id: p,
    };
    final List<LedgerDamage> damage = <LedgerDamage>[];

    // The latest revision per person.
    final Map<LumeRecordId, int> latest = <LumeRecordId, int>{};
    for (final LedgerAllocation a in allocations) {
      if ((latest[a.partyId] ?? 0) < a.scopeRevision) {
        latest[a.partyId] = a.scopeRevision;
      }
    }

    // Allocations that count: both ends active and compatible.
    final Map<LumeRecordId, int> allocated = <LumeRecordId, int>{};
    for (final LedgerAllocation a in allocations) {
      final LumeCurrency cur = a.amount.currency;
      if (a.scopeRevision != latest[a.partyId]) {
        damage.add(LedgerDamage(a.partyId, cur, 'revision', a.id));
      }
      final LedgerEntry? rep = byId[a.repaymentId];
      final LedgerEntry? prin = byId[a.principalId];
      if (rep == null || prin == null) {
        damage.add(LedgerDamage(a.partyId, cur, 'dangling', a.id));
        continue;
      }
      if (!ledgerCompatible(a, rep, prin)) {
        damage.add(LedgerDamage(a.partyId, cur, 'incompatible', a.id));
        continue;
      }
      if (rep.voided || prin.voided) continue;
      allocated[rep.id] = (allocated[rep.id] ?? 0) + a.amount.minor;
      allocated[prin.id] = (allocated[prin.id] ?? 0) + a.amount.minor;
    }

    final Map<LumeRecordId, LumeMoney> remaining = <LumeRecordId, LumeMoney>{};
    final Map<LumeRecordId, LumeMoney> credit = <LumeRecordId, LumeMoney>{};
    for (final LedgerEntry e in entries) {
      if (!partyOf.containsKey(e.partyId)) {
        damage.add(LedgerDamage(e.partyId, e.currency, 'unknownParty', e.id));
      }
      if (e.voided) continue;
      final int used = allocated[e.id] ?? 0;
      if (used > e.amount.minor) {
        damage.add(LedgerDamage(e.partyId, e.currency, 'overAllocated', e.id));
        continue;
      }
      final LumeMoney left = LumeMoney.entry(e.amount.minor - used, e.currency);
      if (e.kind.isPrincipal) {
        remaining[e.id] = left;
      } else {
        credit[e.id] = left;
        if (left.isPositive && !e.excessConfirmed) {
          damage.add(
            LedgerDamage(e.partyId, e.currency, 'unconfirmedCredit', e.id),
          );
        }
      }
    }
    final Set<(LumeRecordId, LumeCurrency)> damaged =
        <(LumeRecordId, LumeCurrency)>{
          for (final LedgerDamage d in damage) (d.party, d.currency),
        };

    // Balances per person and currency.
    final List<LedgerBalance> balances = <LedgerBalance>[];
    for (final LedgerParty p in parties) {
      final List<LedgerEntry> mine = <LedgerEntry>[
        for (final LedgerEntry e in entries)
          if (e.partyId == p.id) e,
      ];
      final Set<LumeCurrency> currencies = <LumeCurrency>{
        for (final LedgerEntry e in mine)
          if (e.active) e.currency,
      };
      for (final LumeCurrency cur in currencies.toList()..sort()) {
        final List<LedgerEntry> here = <LedgerEntry>[
          for (final LedgerEntry e in mine)
            if (e.active && e.currency == cur) e,
        ];
        final bool bad = damaged.contains((p.id, cur));
        LumeMoney sumOf(LedgerKind k, Map<LumeRecordId, LumeMoney> m) =>
            LumeMoney.total(<LumeMoney>[
              for (final LedgerEntry e in here)
                if (e.kind == k && m[e.id] != null) m[e.id]!,
            ], cur);
        final List<LedgerPrincipalState> principals = <LedgerPrincipalState>[
          for (final LedgerEntry e
              in here.where((LedgerEntry e) => e.kind.isPrincipal).toList()
                ..sort(ledgerPrincipalOrder))
            LedgerPrincipalState(
              e,
              remaining[e.id] ?? LumeMoney.zero(cur),
              today == null
                  ? null
                  : e.due != null &&
                        e.due!.isBefore(today) &&
                        (remaining[e.id]?.isPositive ?? false),
            ),
        ];
        final LumeMoney creditToThem = sumOf(LedgerKind.repaidToMe, credit);
        final LumeMoney creditFromThem = sumOf(LedgerKind.repaidByMe, credit);
        final List<LedgerPrincipalState> overdue = <LedgerPrincipalState>[
          for (final LedgerPrincipalState s in principals)
            if (s.overdue ?? false) s,
        ];
        final List<LumeDate> openDue = <LumeDate>[
          for (final LedgerPrincipalState s in principals)
            if (s.open && s.entry.due != null) s.entry.due!,
        ]..sort();
        final List<LedgerEntry> recent = <LedgerEntry>[...here]
          ..sort(ledgerRecentOrder);
        balances.add(
          LedgerBalance(
            party: p,
            currency: cur,
            owedToYou: sumOf(LedgerKind.lent, remaining) + creditFromThem,
            youOwe: sumOf(LedgerKind.borrowed, remaining) + creditToThem,
            creditToThem: creditToThem,
            creditFromThem: creditFromThem,
            principals: principals,
            overdue: today == null ? null : overdue.isNotEmpty,
            shownDue: overdue.isNotEmpty
                ? overdue
                      .map((LedgerPrincipalState s) => s.entry.due!)
                      .reduce((LumeDate a, LumeDate b) => a.isBefore(b) ? a : b)
                : (openDue.isEmpty ? null : openDue.first),
            damaged: bad,
            lastActivity: recent.isEmpty ? null : recent.first,
          ),
        );
      }
    }

    // The summary per currency, over rows that can be trusted.
    final Map<LumeCurrency, (LumeMoney, LumeMoney)> sums =
        <LumeCurrency, (LumeMoney, LumeMoney)>{};
    for (final LedgerBalance b in balances) {
      if (b.damaged) continue;
      final (LumeMoney, LumeMoney) was =
          sums[b.currency] ??
          (LumeMoney.zero(b.currency), LumeMoney.zero(b.currency));
      final LumeMoney bal = b.balance;
      sums[b.currency] = bal.isPositive
          ? (was.$1 + bal, was.$2)
          : bal.isNegative
          ? (was.$1, was.$2 + bal.magnitude)
          : was;
    }
    final List<LedgerCurrencySummary> summaries = <LedgerCurrencySummary>[
      for (final LumeCurrency c in sums.keys.toList()..sort())
        LedgerCurrencySummary(c, sums[c]!.$1, sums[c]!.$2),
    ];

    return LedgerBook._(
      parties: parties,
      entries: entries,
      allocations: allocations,
      defects: defects,
      today: today,
      balances: balances,
      remaining: remaining,
      credit: credit,
      damage: damage,
      summaries: summaries,
      people: <LumeRecordId>{
        for (final LedgerBalance b in balances)
          if (!b.settled) b.party.id,
      }.length,
    );
  }

  final List<LedgerParty> parties;
  final List<LedgerEntry> entries;
  final List<LedgerAllocation> allocations;
  final List<LedgerDefect> defects;
  final LumeDate? today;

  /// One per person and currency with any active entry.
  final List<LedgerBalance> balances;

  /// Per active principal.
  final Map<LumeRecordId, LumeMoney> remaining;

  /// Per active repayment: what it has not paid off.
  final Map<LumeRecordId, LumeMoney> credit;

  final List<LedgerDamage> damage;
  final List<LedgerCurrencySummary> summaries;

  /// Distinct people with anything open in any currency — once each.
  final int people;

  bool get dayKnown => today != null;
  bool get isEmpty => parties.isEmpty && entries.isEmpty;

  LedgerParty? party(LumeRecordId id) {
    for (final LedgerParty p in parties) {
      if (p.id == id) return p;
    }
    return null;
  }

  LedgerEntry? entry(LumeRecordId id) {
    for (final LedgerEntry e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<LedgerBalance> balancesOf(LumeRecordId party) => <LedgerBalance>[
    for (final LedgerBalance b in balances)
      if (b.party.id == party) b,
  ];

  /// Settled when every principal in every currency has nothing remaining
  /// and no credit is left — a net of zero alone is not settled.
  bool settled(LumeRecordId party) =>
      balancesOf(party).every((LedgerBalance b) => b.settled);

  List<LedgerEntry> entriesOf(LumeRecordId party) => <LedgerEntry>[
    for (final LedgerEntry e in entries)
      if (e.partyId == party) e,
  ]..sort(ledgerRecentOrder);

  /// Allocations that count, from or to [entry].
  List<LedgerAllocation> allocationsOf(LumeRecordId entry) =>
      <LedgerAllocation>[
        for (final LedgerAllocation a in allocations)
          if ((a.repaymentId == entry || a.principalId == entry) &&
              (this.entry(a.repaymentId)?.active ?? false) &&
              (this.entry(a.principalId)?.active ?? false))
            a,
      ]..sort((LedgerAllocation a, LedgerAllocation b) {
        final LedgerEntry? pa = this.entry(a.principalId);
        final LedgerEntry? pb = this.entry(b.principalId);
        return pa == null || pb == null ? 0 : ledgerPrincipalOrder(pa, pb);
      });

  /// Every entry, most recent first.
  List<LedgerEntry> get recent =>
      <LedgerEntry>[...entries]..sort(ledgerRecentOrder);

  /// Each invariant of §6 checked mechanically; empty when all hold.
  List<String> invariants() {
    final List<String> broken = <String>[];
    for (final LedgerBalance b in balances) {
      if (b.damaged) continue;
      final LumeCurrency c = b.currency;
      LumeMoney total(LedgerKind k) => LumeMoney.total(<LumeMoney>[
        for (final LedgerEntry e in entries)
          if (e.active &&
              e.partyId == b.party.id &&
              e.currency == c &&
              e.kind == k)
            e.amount,
      ], c);
      final LumeMoney direct =
          (total(LedgerKind.lent) - total(LedgerKind.repaidToMe)) -
          (total(LedgerKind.borrowed) - total(LedgerKind.repaidByMe));
      if (direct != b.balance) {
        broken.add('1 ${b.party.id} $c: ${b.balance} != $direct');
      }
      if (b.owedToYou.isNegative || b.youOwe.isNegative) {
        broken.add('4 ${b.party.id} $c negative');
      }
    }
    for (final LedgerCurrencySummary s in summaries) {
      final List<LedgerBalance> rows = <LedgerBalance>[
        for (final LedgerBalance b in balances)
          if (b.currency == s.currency && !b.damaged) b,
      ];
      final LumeMoney owes = LumeMoney.total(<LumeMoney>[
        for (final LedgerBalance b in rows)
          if (b.balance.isPositive) b.balance,
      ], s.currency);
      final LumeMoney owe = LumeMoney.total(<LumeMoney>[
        for (final LedgerBalance b in rows)
          if (b.balance.isNegative) b.balance.magnitude,
      ], s.currency);
      if (owes != s.owedToYou || owe != s.youOwe) {
        broken.add('3 ${s.currency}: rows do not sum to the summary');
      }
      if (s.net != s.owedToYou - s.youOwe) broken.add('2 ${s.currency}');
    }
    for (final MapEntry<LumeRecordId, LumeMoney> c in credit.entries) {
      if (c.value.isPositive && !(entry(c.key)?.excessConfirmed ?? false)) {
        broken.add('5 ${c.key}: unconfirmed credit');
      }
    }
    final int people = <LumeRecordId>{
      for (final LedgerBalance b in balances)
        if (!b.settled) b.party.id,
    }.length;
    if (people != this.people) broken.add('9 people');
    return broken;
  }
}

/// Recent first: date descending, then creation instant descending, then
/// id.
int ledgerRecentOrder(LedgerEntry a, LedgerEntry b) {
  final int on = b.on.compareTo(a.on);
  if (on != 0) return on;
  final int t = b.createdAt.compareTo(a.createdAt);
  return t != 0 ? t : a.id.compareTo(b.id);
}

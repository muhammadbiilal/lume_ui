/// Reconciliation: which repayment pays off which principal — a pure
/// function of one person's entries and allocations (`LEDGER_PROPOSAL.md`
/// §5).
///
/// 1. **Manual** allocations whose repayment and principal are active,
///    compatible and still fit are kept as they are. One that no longer
///    fits — its principal edited below it, or voided, or moved to another
///    person or currency — is a typed [LedgerFailureKind.allocationConflict]
///    unless the reader chose to make them automatic.
/// 2. **Automatic** allocations are recomputed from scratch over what the
///    manual ones leave: repayments in their order (date, creation instant,
///    id), each filling principals FIFO-by-obligation — due date ascending,
///    undated last; then date; then creation instant; then id. Nothing reads
///    the clock, so reconciling today and tomorrow gives the same answer.
/// 3. What a repayment has left over is **credit**. Credit the reader has
///    not confirmed is a typed [LedgerFailureKind.overpayment]; confirmed
///    credit applies automatically to the next compatible principal — a
///    later loan to the same person in the same currency — as an ordinary
///    allocation, in the same order.
/// 4. The new allocations are diffed against the stored ones: a pair that
///    already has an allocation keeps its record (and id), so voiding and
///    restoring an entry returns the very same records. Allocations touching
///    a voided entry are kept and count for nothing (rule 5).
/// 5. Every allocation in the person's scope is stamped with the next
///    scope revision.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import 'ledger_failure.dart';
import 'ledger_model.dart';

/// What reconciling one person comes to: the allocation records to write.
@immutable
class LedgerPlan {
  const LedgerPlan({
    required this.create,
    required this.update,
    required this.delete,
    required this.confirm,
    required this.revision,
  });

  final List<LedgerAllocation> create;

  /// Each with the id and version of the record it replaces.
  final List<LedgerAllocation> update;
  final List<LedgerAllocation> delete;

  /// Repayments whose excess the reader has just confirmed as credit.
  final List<LedgerEntry> confirm;

  /// The scope revision every remaining allocation now carries.
  final int revision;

  bool get isEmpty =>
      create.isEmpty && update.isEmpty && delete.isEmpty && confirm.isEmpty;
}

/// FIFO-by-obligation: due ascending with undated last, then date, then
/// creation instant, then id.
int ledgerPrincipalOrder(LedgerEntry a, LedgerEntry b) {
  if (a.due != b.due) {
    if (a.due == null) return 1;
    if (b.due == null) return -1;
    final int d = a.due!.compareTo(b.due!);
    if (d != 0) return d;
  }
  final int on = a.on.compareTo(b.on);
  return on != 0 ? on : a.compareCreation(b);
}

/// Repayments are applied by date, then creation instant, then id.
int ledgerRepaymentOrder(LedgerEntry a, LedgerEntry b) {
  final int on = a.on.compareTo(b.on);
  return on != 0 ? on : a.compareCreation(b);
}

/// Whether [a] can join [rep] to [prin] at all: same person throughout,
/// same currency throughout, and the repayment discharges that kind.
bool ledgerCompatible(LedgerAllocation a, LedgerEntry rep, LedgerEntry prin) =>
    rep.kind.isRepayment &&
    prin.kind == rep.kind.counterpart &&
    rep.partyId == a.partyId &&
    prin.partyId == a.partyId &&
    rep.currency == a.amount.currency &&
    prin.currency == a.amount.currency;

/// Reconcile [party] over [entries] (every entry the store holds for it,
/// any state) and [allocations] (every allocation carrying its id).
///
/// [confirmExcess] marks every repayment that would end with credit as
/// confirmed, as the reader just did on the credit sheet. [makeAutomatic]
/// releases manual allocations that no longer fit instead of failing.
/// [newId] makes an id for an allocation that did not exist before.
///
/// Throws [LedgerFailure] — `allocationConflict`, `overpayment`,
/// `overflow`, `currencyMismatch` — and writes nothing itself.
LedgerPlan ledgerReconcile({
  required LumeRecordId party,
  required List<LedgerEntry> entries,
  required List<LedgerAllocation> allocations,
  required LumeRecordId Function() newId,
  required DateTime now,
  bool confirmExcess = false,
  bool makeAutomatic = false,
}) {
  try {
    return _reconcile(
      party,
      entries,
      allocations,
      newId,
      now,
      confirmExcess,
      makeAutomatic,
    );
  } on LumeMoneyException catch (e) {
    throw LedgerFailure(
      e.failure == LumeMoneyFailure.currencyMismatch
          ? LedgerFailureKind.currencyMismatch
          : LedgerFailureKind.overflow,
      cause: e,
    );
  }
}

LedgerPlan _reconcile(
  LumeRecordId party,
  List<LedgerEntry> entries,
  List<LedgerAllocation> allocations,
  LumeRecordId Function() newId,
  DateTime now,
  bool confirmExcess,
  bool makeAutomatic,
) {
  final Map<LumeRecordId, LedgerEntry> byId = <LumeRecordId, LedgerEntry>{
    for (final LedgerEntry e in entries) e.id: e,
  };
  final List<LedgerAllocation> mine = <LedgerAllocation>[
    for (final LedgerAllocation a in allocations)
      if (a.partyId == party) a,
  ];
  final int revision =
      mine.fold<int>(
        0,
        (int m, LedgerAllocation a) =>
            a.scopeRevision > m ? a.scopeRevision : m,
      ) +
      1;

  final List<LedgerAllocation> delete = <LedgerAllocation>[];
  final List<LedgerAllocation> kept = <LedgerAllocation>[];
  final List<LedgerAllocation> manual = <LedgerAllocation>[];
  final Map<(LumeRecordId, LumeRecordId), LedgerAllocation> automatic =
      <(LumeRecordId, LumeRecordId), LedgerAllocation>{};
  final List<LumeRecordId> conflicts = <LumeRecordId>[];

  for (final LedgerAllocation a in mine) {
    final LedgerEntry? rep = byId[a.repaymentId];
    final LedgerEntry? prin = byId[a.principalId];
    if (rep == null || prin == null || !ledgerCompatible(a, rep, prin)) {
      // Its entry is gone, or now belongs elsewhere: an automatic one is
      // simply recomputed; a manual one was the reader's choice and is
      // not dropped without them.
      if (a.manual && !makeAutomatic && rep != null && prin != null) {
        conflicts.add(a.id);
      } else {
        delete.add(a);
      }
    } else if (rep.voided || prin.voided) {
      if (a.manual && rep.active && prin.voided && !makeAutomatic) {
        // The principal a manual choice paid was voided under it.
        conflicts.add(a.id);
      } else {
        kept.add(a);
      }
    } else if (a.manual) {
      manual.add(a);
    } else {
      automatic[(a.repaymentId, a.principalId)] = a;
    }
  }

  // Manual allocations must still fit: no repayment or principal
  // over-allocated.
  final Map<LumeRecordId, LumeMoney> used = <LumeRecordId, LumeMoney>{};
  void add(LumeRecordId id, LumeMoney m) =>
      used[id] = used[id] == null ? m : used[id]! + m;
  for (final LedgerAllocation a in manual) {
    add(a.repaymentId, a.amount);
    add(a.principalId, a.amount);
  }
  final Set<LumeRecordId> over = <LumeRecordId>{
    for (final MapEntry<LumeRecordId, LumeMoney> u in used.entries)
      if (u.value.minor > byId[u.key]!.amount.minor) u.key,
  };
  if (over.isNotEmpty) {
    final List<LedgerAllocation> offending = <LedgerAllocation>[
      for (final LedgerAllocation a in manual)
        if (over.contains(a.repaymentId) || over.contains(a.principalId)) a,
    ];
    if (makeAutomatic) {
      for (final LedgerAllocation a in offending) {
        manual.remove(a);
        delete.add(a);
        used[a.repaymentId] = used[a.repaymentId]! - a.amount;
        used[a.principalId] = used[a.principalId]! - a.amount;
      }
    } else {
      conflicts.addAll(offending.map((LedgerAllocation a) => a.id));
    }
  }
  if (conflicts.isNotEmpty) {
    throw LedgerFailure(
      LedgerFailureKind.allocationConflict,
      ids: conflicts..sort(),
    );
  }

  // The automatic allocations, per currency and direction.
  final List<LedgerAllocation> create = <LedgerAllocation>[];
  final List<LedgerAllocation> update = <LedgerAllocation>[];
  final List<LedgerEntry> confirm = <LedgerEntry>[];
  final Map<LumeCurrency, LumeMoney> unconfirmed = <LumeCurrency, LumeMoney>{};
  final List<LumeRecordId> overpaid = <LumeRecordId>[];
  final Set<(LumeRecordId, LumeRecordId)> wanted =
      <(LumeRecordId, LumeRecordId)>{};

  final List<LedgerEntry> active = <LedgerEntry>[
    for (final LedgerEntry e in entries)
      if (e.active && e.partyId == party) e,
  ];
  for (final LedgerKind principalKind in <LedgerKind>[
    LedgerKind.lent,
    LedgerKind.borrowed,
  ]) {
    final LedgerKind repaymentKind = principalKind.counterpart;
    final Set<LumeCurrency> currencies = <LumeCurrency>{
      for (final LedgerEntry e in active)
        if (e.kind == principalKind || e.kind == repaymentKind) e.currency,
    };
    for (final LumeCurrency cur in currencies.toList()..sort()) {
      final List<LedgerEntry> principals = <LedgerEntry>[
        for (final LedgerEntry e in active)
          if (e.kind == principalKind && e.currency == cur) e,
      ]..sort(ledgerPrincipalOrder);
      final List<LedgerEntry> repayments = <LedgerEntry>[
        for (final LedgerEntry e in active)
          if (e.kind == repaymentKind && e.currency == cur) e,
      ]..sort(ledgerRepaymentOrder);
      final Map<LumeRecordId, int> open = <LumeRecordId, int>{
        for (final LedgerEntry p in principals)
          p.id: (p.amount - (used[p.id] ?? LumeMoney.zero(cur))).minor,
      };
      for (final LedgerEntry r in repayments) {
        int left = (r.amount - (used[r.id] ?? LumeMoney.zero(cur))).minor;
        for (final LedgerEntry p in principals) {
          if (left == 0) break;
          final int take = left < open[p.id]! ? left : open[p.id]!;
          if (take == 0) continue;
          left -= take;
          open[p.id] = open[p.id]! - take;
          final (LumeRecordId, LumeRecordId) pair = (r.id, p.id);
          wanted.add(pair);
          final LumeMoney amount = LumeMoney.entry(take, cur);
          final LedgerAllocation? had = automatic[pair];
          if (had == null) {
            create.add(
              LedgerAllocation(
                id: newId(),
                partyId: party,
                repaymentId: r.id,
                principalId: p.id,
                amount: amount,
                origin: LedgerOrigin.automatic,
                scopeRevision: revision,
                createdAt: now,
              ),
            );
          } else {
            update.add(_restamp(had, revision, amount: amount));
          }
        }
        if (left > 0 && !r.excessConfirmed) {
          if (confirmExcess) {
            confirm.add(r.copyWith(excessConfirmed: true));
          } else {
            overpaid.add(r.id);
            unconfirmed[cur] =
                (unconfirmed[cur] ?? LumeMoney.zero(cur)) +
                LumeMoney.entry(left, cur);
          }
        }
      }
    }
  }
  if (overpaid.isNotEmpty) {
    throw LedgerFailure(
      LedgerFailureKind.overpayment,
      ids: overpaid..sort(),
      excess: unconfirmed.values.toList()
        ..sort((LumeMoney a, LumeMoney b) => a.currency.compareTo(b.currency)),
    );
  }

  for (final MapEntry<(LumeRecordId, LumeRecordId), LedgerAllocation> e
      in automatic.entries) {
    if (!wanted.contains(e.key)) delete.add(e.value);
  }
  for (final LedgerAllocation a in <LedgerAllocation>[...manual, ...kept]) {
    update.add(_restamp(a, revision));
  }

  return LedgerPlan(
    create: create,
    update: update,
    delete: delete,
    confirm: confirm,
    revision: revision,
  );
}

LedgerAllocation _restamp(
  LedgerAllocation a,
  int revision, {
  LumeMoney? amount,
}) => LedgerAllocation(
  id: a.id,
  partyId: a.partyId,
  repaymentId: a.repaymentId,
  principalId: a.principalId,
  amount: amount ?? a.amount,
  origin: a.origin,
  scopeRevision: revision,
  createdAt: a.createdAt,
  version: a.version,
);

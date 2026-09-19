/// Ledger's records, read and written through the record layer's
/// transactions (`LEDGER_PROPOSAL.md` §8, §13).
///
/// Every write is one transaction: the people, entries and allocations it
/// touches, and the reconciliation of every person it affects, commit
/// together or not at all. Nothing is seeded (D11): a reader's Ledger
/// starts empty.
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import 'ledger_book.dart';
import 'ledger_failure.dart';
import 'ledger_model.dart';
import 'ledger_reconcile.dart';

/// What the reader filled in for an entry.
@immutable
class LedgerEntryDraft {
  const LedgerEntryDraft({
    required this.partyId,
    required this.kind,
    required this.amount,
    required this.on,
    this.due,
    this.note,
  });

  final LumeRecordId partyId;
  final LedgerKind kind;
  final LumeMoney amount;
  final LumeDate on;
  final LumeDate? due;
  final String? note;

  String get fingerprint => jsonEncode(<String, Object?>{
    'p': partyId.value,
    'k': kind.name,
    'a': amount.minor,
    'c': amount.currency.code,
    'o': on.toIso(),
    'd': due?.toIso(),
    'n': note,
  });
}

/// The reader's own choice: this much of a repayment to that principal.
@immutable
class LedgerManualDraft {
  const LedgerManualDraft(this.principalId, this.amount);

  final LumeRecordId principalId;
  final LumeMoney amount;
}

/// What deleting a principal does to the repayments that paid it (E8).
enum LedgerOrphanChoice {
  /// Their freed amount becomes credit to the person.
  keepAsCredit,

  /// They are deleted too, in the same transaction.
  deleteRepayments,
}

/// A committed write — enough to show it and to undo it.
@immutable
class LedgerWrite {
  const LedgerWrite(this.receipt, {this.entry, this.party});

  final LumeTxReceipt receipt;
  final LedgerEntry? entry;
  final LedgerParty? party;
}

/// Ledger's records as they stand, or why they cannot be shown.
@immutable
class LedgerSnapshot {
  const LedgerSnapshot({
    required this.status,
    this.parties = const <LedgerParty>[],
    this.entries = const <LedgerEntry>[],
    this.allocations = const <LedgerAllocation>[],
    this.defects = const <LedgerDefect>[],
  });

  final LumeCollectionStatus status;
  final List<LedgerParty> parties;
  final List<LedgerEntry> entries;
  final List<LedgerAllocation> allocations;
  final List<LedgerDefect> defects;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;

  LedgerBook book(LumeDate? today) => LedgerBook.from(
    parties: parties,
    entries: entries,
    allocations: allocations,
    defects: defects,
    today: today,
  );
}

/// Records decoded inside one transaction.
class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(LedgerCollections.parties)) {
      _read(r, LedgerParty.decode, parties);
    }
    for (final LumeRecord r in tx.all(LedgerCollections.entries)) {
      _read(r, LedgerEntry.decode, entries);
    }
    for (final LumeRecord r in tx.all(LedgerCollections.allocations)) {
      _read(r, LedgerAllocation.decode, allocations);
    }
    // Damage found before this write: nothing is written over it until the
    // reader repairs the person explicitly.
    damagedBefore = <String>{
      ...defectParties,
      for (final LedgerDamage x in book().damage) x.party.value,
    };
  }

  late final Set<String> damagedBefore;

  final LumeRecordTx tx;
  final List<LedgerParty> parties = <LedgerParty>[];
  final List<LedgerEntry> entries = <LedgerEntry>[];
  final List<LedgerAllocation> allocations = <LedgerAllocation>[];

  /// The raw `party` field of every record that could not be read.
  final Set<String> defectParties = <String>{};

  void _read<T>(LumeRecord r, T Function(LumeRecord) decode, List<T> into) {
    try {
      into.add(decode(r));
    } on LedgerDefectException {
      defectParties.add('${r['party'] ?? r.id}');
    }
  }

  LedgerParty party(LumeRecordId id) {
    for (final LedgerParty p in parties) {
      if (p.id == id) return p;
    }
    throw LedgerFailure(LedgerFailureKind.notFound, ids: <LumeRecordId>[id]);
  }

  LedgerEntry entry(LumeRecordId id) {
    for (final LedgerEntry e in entries) {
      if (e.id == id) return e;
    }
    throw LedgerFailure(LedgerFailureKind.notFound, ids: <LumeRecordId>[id]);
  }

  LedgerBook book() => LedgerBook.from(
    parties: parties,
    entries: entries,
    allocations: allocations,
    today: null,
  );
}

class LedgerRepository {
  LedgerRepository(this._store, {Random? random, DateTime Function()? now})
    : _random = random ?? Random.secure(),
      _now = now ?? DateTime.now;

  final LumeRecordRepository _store;
  final Random _random;
  final DateTime Function() _now;

  /// Told once per committed write.
  Listenable get changes => _store;

  /// Whether a write survives the app closing — the store's answer (C74).
  bool get durable => _store.durable;

  LumeRecordId _newId() => LumeRecordId.generate(_random);

  /// Start reading Ledger's collections.
  void open() {
    for (final String c in LedgerCollections.all) {
      _store.open(c);
    }
  }

  /// Try a failed read again.
  void retry() {
    for (final String c in LedgerCollections.all) {
      if (_store.view(c).status == LumeCollectionStatus.error) {
        _store.retry(c);
      }
    }
  }

  /// The records now, decoded; a record that cannot be read is a defect,
  /// listed, never dropped.
  LedgerSnapshot view() {
    final List<LumeCollectionView> views = <LumeCollectionView>[
      for (final String c in LedgerCollections.all) _store.view(c),
    ];
    if (views.any(
      (LumeCollectionView v) => v.status == LumeCollectionStatus.error,
    )) {
      return const LedgerSnapshot(status: LumeCollectionStatus.error);
    }
    if (views.any(
      (LumeCollectionView v) => v.status == LumeCollectionStatus.loading,
    )) {
      return const LedgerSnapshot(status: LumeCollectionStatus.loading);
    }
    final List<LedgerDefect> defects = <LedgerDefect>[];
    List<T> read<T>(LumeCollectionView v, T Function(LumeRecord) decode) => <T>[
      for (final LumeRecord r in v.items)
        ...() {
          try {
            return <T>[decode(r)];
          } on LedgerDefectException catch (e) {
            defects.add(e.defect);
            return <T>[];
          }
        }(),
    ];
    return LedgerSnapshot(
      status: views.first.status,
      parties: read(views[0], LedgerParty.decode),
      entries: read(views[1], LedgerEntry.decode),
      allocations: read(views[2], LedgerAllocation.decode),
      defects: defects,
    );
  }

  // ---- people -------------------------------------------------------------

  LedgerResult<LedgerParty> addParty(String name, {String? note}) =>
      _write<LedgerParty>((_Data d) {
        final LedgerParty p = LedgerParty(
          id: _newId(),
          name: _name(name),
          note: _note(note),
          createdAt: _now(),
        );
        final LumeRecord r = d.tx.create(
          LedgerCollections.parties,
          p.id.value,
          p.toFields(),
        );
        return LedgerParty.decode(r);
      }).map((LedgerWrite w) => w.party!);

  LedgerResult<LedgerWrite> renameParty(
    LumeRecordId id,
    String name, {
    String? note,
    required int version,
  }) => _write<LedgerParty>((_Data d) {
    final LedgerParty p = d.party(id);
    return _putParty(
      d,
      LedgerParty(
        id: p.id,
        name: _name(name),
        note: _note(note),
        state: p.state,
        createdAt: p.createdAt,
      ),
      version,
    );
  });

  /// Archive a settled person (hidden from the default lists, kept in
  /// history, search and export), or bring one back.
  LedgerResult<LedgerWrite> setArchived(
    LumeRecordId id,
    bool archived, {
    required int version,
  }) => _write<LedgerParty>((_Data d) {
    final LedgerParty p = d.party(id);
    if (archived && !d.book().settled(id)) {
      throw const LedgerFailure(LedgerFailureKind.partyOpen);
    }
    return _putParty(
      d,
      LedgerParty(
        id: p.id,
        name: p.name,
        note: p.note,
        state: archived ? LedgerPartyState.archived : LedgerPartyState.active,
        createdAt: p.createdAt,
      ),
      version,
    );
  });

  /// Refused while any entry — active or voided — names the person. Never
  /// cascades through their history.
  LedgerResult<LedgerWrite> deleteParty(
    LumeRecordId id, {
    required int version,
  }) => _write<LedgerParty>((_Data d) {
    final LedgerParty p = d.party(id);
    final int count = d.entries
        .where((LedgerEntry e) => e.partyId == id)
        .length;
    final bool raw = d.defectParties.contains(id.value);
    if (count > 0 || raw) {
      throw LedgerFailure(
        LedgerFailureKind.partyReferenced,
        count: count + (raw ? 1 : 0),
      );
    }
    d.tx.delete(LedgerCollections.parties, id.value, expectVersion: version);
    return p;
  });

  LedgerParty _putParty(_Data d, LedgerParty p, int version) =>
      LedgerParty.decode(
        d.tx.update(
          LedgerCollections.parties,
          p.id.value,
          p.toFields(),
          expectVersion: version,
        ),
      );

  // ---- entries ------------------------------------------------------------

  /// Add an entry. A repayment is allocated automatically unless [manual]
  /// names the principals; one larger than what is open is refused as an
  /// overpayment until [confirmExcess].
  LedgerResult<LedgerWrite> addEntry(
    LedgerEntryDraft draft, {
    List<LedgerManualDraft>? manual,
    bool confirmExcess = false,
    String? idempotencyKey,
  }) => _write<LedgerEntry>(
    (_Data d) {
      _validate(d, draft, manual);
      final LedgerEntry e = LedgerEntry(
        id: _newId(),
        partyId: draft.partyId,
        kind: draft.kind,
        amount: draft.amount,
        on: draft.on,
        due: draft.due,
        note: _note(draft.note),
        createdAt: _now(),
      );
      d.tx.create(LedgerCollections.entries, e.id.value, e.toFields());
      d.entries.add(e);
      _stageManual(d, e, manual);
      _reconcile(d, <LumeRecordId>{e.partyId}, confirmExcess: confirmExcess);
      return _entryNow(d, e.id);
    },
    idempotencyKey: idempotencyKey,
    fingerprint: idempotencyKey == null
        ? null
        : '${draft.fingerprint}|$confirmExcess|'
              '${manual?.map((LedgerManualDraft m) => '${m.principalId}:${m.amount.minor}').join(',')}',
  );

  /// Edit every field of an entry. Its person's allocations are reconciled
  /// — both people's when the person or currency changes.
  LedgerResult<LedgerWrite> editEntry(
    LumeRecordId id,
    LedgerEntryDraft draft, {
    required int version,
    List<LedgerManualDraft>? manual,
    bool confirmExcess = false,
    bool makeAutomatic = false,
  }) => _write<LedgerEntry>((_Data d) {
    final LedgerEntry was = d.entry(id);
    _validate(d, draft, manual, editing: was);
    final LedgerEntry now = LedgerEntry(
      id: was.id,
      partyId: draft.partyId,
      kind: draft.kind,
      amount: draft.amount,
      on: draft.on,
      due: draft.due,
      note: _note(draft.note),
      state: was.state,
      excessConfirmed: draft.kind.isRepayment && was.excessConfirmed,
      createdAt: was.createdAt,
    );
    _putEntry(d, now, version);
    if (manual != null) _stageManual(d, now, manual);
    _reconcile(
      d,
      <LumeRecordId>{was.partyId, now.partyId},
      confirmExcess: confirmExcess,
      makeAutomatic: makeAutomatic,
    );
    return _entryNow(d, id);
  });

  /// Void an entry (the normal correction), or restore it. It is kept, with
  /// its id and its allocations; while voided it changes no figure.
  LedgerResult<LedgerWrite> setVoided(
    LumeRecordId id,
    bool voided, {
    required int version,
    bool confirmExcess = false,
    bool makeAutomatic = false,
  }) => _write<LedgerEntry>((_Data d) {
    final LedgerEntry e = d.entry(id);
    _putEntry(
      d,
      e.copyWith(
        state: voided ? LedgerEntryState.voided : LedgerEntryState.active,
      ),
      version,
    );
    _reconcile(
      d,
      <LumeRecordId>{e.partyId},
      confirmExcess: confirmExcess,
      makeAutomatic: makeAutomatic,
    );
    return _entryNow(d, id);
  });

  /// Delete an entry made by mistake, with its allocations, in one
  /// transaction; undone by [undo] with the same ids. Deleting a principal
  /// that repayments paid needs [orphans] (E8); without it the result is an
  /// overpayment naming those repayments, and nothing is written.
  LedgerResult<LedgerWrite> deleteEntry(
    LumeRecordId id, {
    required int version,
    LedgerOrphanChoice? orphans,
  }) => _write<LedgerEntry>((_Data d) {
    final LedgerEntry e = d.entry(id);
    _deleteEntry(d, e, version);
    try {
      _reconcile(d, <LumeRecordId>{
        e.partyId,
      }, confirmExcess: orphans == LedgerOrphanChoice.keepAsCredit);
    } on LedgerFailure catch (f) {
      if (f.kind != LedgerFailureKind.overpayment ||
          orphans != LedgerOrphanChoice.deleteRepayments) {
        rethrow;
      }
      for (final LumeRecordId r in f.ids) {
        final LedgerEntry rep = d.entry(r);
        _deleteEntry(d, rep, rep.version);
      }
      _reconcile(d, <LumeRecordId>{e.partyId});
    }
    return e;
  });

  /// Reverse a committed write — a delete's Undo — restoring the same ids.
  LedgerResult<void> undo(LedgerWrite write) {
    final LumeTxResult<void> r = _store.revert(write.receipt);
    return r.ok
        ? const LedgerResult<void>.ok(null)
        : LedgerResult<void>.failed(_map(r.failure!));
  }

  /// Reconcile one person's allocations on the reader's explicit request —
  /// the way out of a damaged scope. Nothing reconciles behind their back.
  LedgerResult<LedgerWrite> repair(
    LumeRecordId party, {
    bool confirmExcess = false,
    bool makeAutomatic = false,
  }) => _write<LedgerParty>((_Data d) {
    final LedgerParty p = d.party(party);
    _reconcile(
      d,
      <LumeRecordId>{party},
      confirmExcess: confirmExcess,
      makeAutomatic: makeAutomatic,
      repairing: true,
    );
    return p;
  });

  // ---- internals ----------------------------------------------------------

  void _deleteEntry(_Data d, LedgerEntry e, int version) {
    for (final LedgerAllocation a in <LedgerAllocation>[...d.allocations]) {
      if (a.repaymentId == e.id || a.principalId == e.id) {
        d.tx.delete(
          LedgerCollections.allocations,
          a.id.value,
          expectVersion: a.version,
        );
        d.allocations.remove(a);
      }
    }
    d.tx.delete(LedgerCollections.entries, e.id.value, expectVersion: version);
    d.entries.removeWhere((LedgerEntry x) => x.id == e.id);
  }

  void _putEntry(_Data d, LedgerEntry e, int version) {
    final LumeRecord r = d.tx.update(
      LedgerCollections.entries,
      e.id.value,
      e.toFields(),
      expectVersion: version,
    );
    final int at = d.entries.indexWhere((LedgerEntry x) => x.id == e.id);
    d.entries[at] = LedgerEntry.decode(r);
  }

  LedgerEntry _entryNow(_Data d, LumeRecordId id) =>
      LedgerEntry.decode(d.tx.get(LedgerCollections.entries, id.value)!);

  /// The reader's manual allocations from [rep] replace any it had.
  void _stageManual(_Data d, LedgerEntry rep, List<LedgerManualDraft>? manual) {
    if (manual == null) return;
    for (final LedgerAllocation a in <LedgerAllocation>[...d.allocations]) {
      if (a.repaymentId == rep.id && a.manual) {
        d.tx.delete(
          LedgerCollections.allocations,
          a.id.value,
          expectVersion: a.version,
        );
        d.allocations.remove(a);
      }
    }
    for (final LedgerManualDraft m in manual) {
      final LedgerAllocation a = LedgerAllocation(
        id: _newId(),
        partyId: rep.partyId,
        repaymentId: rep.id,
        principalId: m.principalId,
        amount: m.amount,
        origin: LedgerOrigin.manual,
        scopeRevision: 1,
        createdAt: _now(),
      );
      d.tx.create(LedgerCollections.allocations, a.id.value, a.toFields());
      d.allocations.add(
        LedgerAllocation.decode(
          d.tx.get(LedgerCollections.allocations, a.id.value)!,
        ),
      );
    }
  }

  void _reconcile(
    _Data d,
    Set<LumeRecordId> parties, {
    bool confirmExcess = false,
    bool makeAutomatic = false,
    bool repairing = false,
  }) {
    for (final LumeRecordId party in parties.toList()..sort()) {
      if (!repairing && d.damagedBefore.contains(party.value)) {
        throw LedgerFailure(
          LedgerFailureKind.damaged,
          ids: <LumeRecordId>[party],
        );
      }
      final LedgerPlan plan = ledgerReconcile(
        party: party,
        entries: d.entries,
        allocations: d.allocations,
        newId: _newId,
        now: _now(),
        confirmExcess: confirmExcess,
        makeAutomatic: makeAutomatic,
      );
      for (final LedgerAllocation a in plan.delete) {
        d.tx.delete(
          LedgerCollections.allocations,
          a.id.value,
          expectVersion: a.version,
        );
        d.allocations.removeWhere((LedgerAllocation x) => x.id == a.id);
      }
      for (final LedgerAllocation a in plan.update) {
        final LumeRecord r = d.tx.update(
          LedgerCollections.allocations,
          a.id.value,
          a.toFields(),
          expectVersion: d.tx
              .get(LedgerCollections.allocations, a.id.value)!
              .version,
        );
        d.allocations[d.allocations.indexWhere(
          (LedgerAllocation x) => x.id == a.id,
        )] = LedgerAllocation.decode(
          r,
        );
      }
      for (final LedgerAllocation a in plan.create) {
        d.allocations.add(
          LedgerAllocation.decode(
            d.tx.create(
              LedgerCollections.allocations,
              a.id.value,
              a.toFields(),
            ),
          ),
        );
      }
      for (final LedgerEntry e in plan.confirm) {
        _putEntry(
          d,
          e,
          d.tx.get(LedgerCollections.entries, e.id.value)!.version,
        );
      }
    }
  }

  void _validate(
    _Data d,
    LedgerEntryDraft draft,
    List<LedgerManualDraft>? manual, {
    LedgerEntry? editing,
  }) {
    final LedgerParty p = d.party(draft.partyId);
    if (p.archived && editing?.partyId != p.id) {
      throw const LedgerFailure.validation('party', 'archived');
    }
    if (draft.amount.isZero) {
      throw const LedgerFailure.validation('amount', 'zero');
    }
    if (draft.amount.minor > LumeMoney.maxEntryMinor) {
      throw const LedgerFailure(LedgerFailureKind.overflow);
    }
    if (editing == null && !draft.amount.currency.active) {
      throw const LedgerFailure.validation('currency', 'withdrawn');
    }
    if (draft.due != null) {
      if (!draft.kind.isPrincipal) {
        throw const LedgerFailure.validation('due', 'repayment');
      }
      if (draft.due!.isBefore(draft.on)) {
        throw const LedgerFailure.validation('due', 'beforeDate');
      }
    }
    _note(draft.note);
    if (manual == null) return;
    if (!draft.kind.isRepayment) {
      throw const LedgerFailure.validation('allocation', 'principal');
    }
    final Set<LumeRecordId> seen = <LumeRecordId>{};
    for (final LedgerManualDraft m in manual) {
      final LedgerEntry prin = d.entry(m.principalId);
      if (!seen.add(m.principalId)) {
        throw const LedgerFailure.validation('allocation', 'duplicate');
      }
      if (m.amount.isZero) {
        throw const LedgerFailure.validation('allocation', 'zero');
      }
      if (m.amount.currency != draft.amount.currency ||
          prin.currency != draft.amount.currency) {
        throw const LedgerFailure(LedgerFailureKind.currencyMismatch);
      }
      if (prin.partyId != draft.partyId ||
          prin.kind != draft.kind.counterpart ||
          prin.voided) {
        throw const LedgerFailure.validation('allocation', 'incompatible');
      }
    }
  }

  static String _name(String name) {
    final String t = name.trim();
    if (t.isEmpty) throw const LedgerFailure.validation('name', 'required');
    if (t.length > kLedgerNameMax) {
      throw const LedgerFailure.validation('name', 'long');
    }
    return t;
  }

  static String? _note(String? note) {
    if (note == null || note.trim().isEmpty) return null;
    if (note.length > kLedgerNoteMax) {
      throw const LedgerFailure.validation('note', 'long');
    }
    return note.trim();
  }

  LedgerResult<LedgerWrite> _write<T>(
    T Function(_Data d) body, {
    String? idempotencyKey,
    String? fingerprint,
  }) {
    final LumeTxResult<T> r = _store.run<T>(
      (LumeRecordTx tx) {
        try {
          final _Data d = _Data(tx);
          final T v = body(d);
          _verify(d);
          return v;
        } on LedgerFailure catch (f) {
          tx.reject(f);
        } on LumeMoneyException catch (e) {
          tx.reject(
            LedgerFailure(
              e.failure == LumeMoneyFailure.currencyMismatch
                  ? LedgerFailureKind.currencyMismatch
                  : LedgerFailureKind.overflow,
              cause: e,
            ),
          );
        }
      },
      idempotencyKey: idempotencyKey,
      fingerprint: fingerprint,
    );
    if (!r.ok) return LedgerResult<LedgerWrite>.failed(_map(r.failure!));
    final T v = r.value as T;
    return LedgerResult<LedgerWrite>.ok(
      LedgerWrite(
        r.receipt!,
        entry: v is LedgerEntry ? v : null,
        party: v is LedgerParty ? v : null,
      ),
    );
  }

  /// The written state proves itself before it is published: every
  /// invariant holds, no sum overflows, and no person the write reached is
  /// left damaged. Otherwise the whole transaction rolls back.
  static void _verify(_Data d) {
    final LedgerBook book = d.book();
    final List<String> broken = book.invariants();
    final List<LedgerDamage> fresh = <LedgerDamage>[
      for (final LedgerDamage x in book.damage)
        if (!d.damagedBefore.contains(x.party.value)) x,
    ];
    if (broken.isNotEmpty || fresh.isNotEmpty) {
      throw LedgerFailure(
        LedgerFailureKind.damaged,
        ids: <LumeRecordId>[for (final LedgerDamage x in fresh) x.party],
        cause: <Object>[
          ...broken,
          for (final LedgerDamage x in fresh) x.reason,
        ],
      );
    }
  }

  static LedgerFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected => f.detail! as LedgerFailure,
    LumeTxFailureKind.conflict ||
    LumeTxFailureKind.duplicateId => LedgerFailure(
      LedgerFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => LedgerFailure(
      LedgerFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => LedgerFailure(
      LedgerFailureKind.storage,
      cause: f.kind,
    ),
  };
}

extension on LedgerResult<LedgerWrite> {
  LedgerResult<U> map<U>(U Function(LedgerWrite) f) =>
      ok ? LedgerResult<U>.ok(f(value!)) : LedgerResult<U>.failed(failure!);
}

/// What settling up would write: one repayment of everything open in one
/// direction, and the principals it would discharge (§8).
@immutable
class LedgerSettlePreview {
  const LedgerSettlePreview(this.kind, this.amount, this.principals);

  /// `repaidToMe` for what they owe the reader, `repaidByMe` the other way.
  final LedgerKind kind;
  final LumeMoney amount;
  final List<LedgerPrincipalState> principals;

  static LedgerSettlePreview? of(LedgerBalance b, LedgerKind principalKind) {
    final List<LedgerPrincipalState> open = b.open(principalKind);
    if (open.isEmpty) return null;
    return LedgerSettlePreview(
      principalKind.counterpart,
      LumeMoney.total(
        open.map((LedgerPrincipalState p) => p.remaining),
        b.currency,
      ),
      open,
    );
  }
}

/// The currency a new entry defaults to: the reader's, where it is one a
/// new entry may use.
LumeCurrency? ledgerDefaultCurrency(String code) {
  final LumeCurrency? c = LumeCurrency.tryOf(code);
  return c != null && c.active ? c : null;
}

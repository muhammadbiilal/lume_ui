/// Lending Ledger's stored records — people, entries, allocations — and
/// their codec to and from the record envelope (`LEDGER_PROPOSAL.md` §3).
///
/// **Entries are the truth.** A balance, what remains on a loan, credit and
/// overdue are never stored; they are derived (`ledger_book.dart`) from the
/// entries and the allocations that join repayments to principals.
///
/// **One codec, nothing else sees a map.** Each type decodes from a
/// [LumeRecord] strictly; a record that fails is a [LedgerDefect] — shown
/// as damaged, never dropped and never repaired silently.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

/// The stored schema — carried in every record, and in every export.
const String kLedgerSchema = 'lume.ledger/1';

/// The record collections Ledger keeps.
abstract final class LedgerCollections {
  static const String parties = 'ledger.party';
  static const String entries = 'ledger.entry';
  static const String allocations = 'ledger.allocation';
  static const List<String> all = <String>[parties, entries, allocations];
}

/// Longest name and note the reader may type.
const int kLedgerNameMax = 80;
const int kLedgerNoteMax = 500;

enum LedgerPartyState { active, archived }

enum LedgerEntryState { active, voided }

/// What an entry is. Direction is the kind, never a sign.
enum LedgerKind {
  /// The reader lent: they owe the reader.
  lent,

  /// The reader borrowed: the reader owes them.
  borrowed,

  /// They repaid the reader — discharges `lent`.
  repaidToMe,

  /// The reader repaid them — discharges `borrowed`.
  repaidByMe;

  bool get isPrincipal => this == lent || this == borrowed;
  bool get isRepayment => !isPrincipal;

  /// For a repayment, the principal kind it discharges; for a principal,
  /// the repayment kind that discharges it.
  LedgerKind get counterpart => switch (this) {
    lent => repaidToMe,
    borrowed => repaidByMe,
    repaidToMe => lent,
    repaidByMe => borrowed,
  };

  static LedgerKind? parse(Object? v) {
    for (final LedgerKind k in values) {
      if (k.name == v) return k;
    }
    return null;
  }
}

/// Whether an allocation was chosen by the reader or by the FIFO rule.
enum LedgerOrigin { automatic, manual }

/// A person the reader lends to or borrows from — typed by the reader,
/// never looked up.
@immutable
class LedgerParty {
  const LedgerParty({
    required this.id,
    required this.name,
    this.note,
    this.state = LedgerPartyState.active,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final String name;
  final String? note;
  final LedgerPartyState state;
  final DateTime createdAt;
  final int version;

  bool get archived => state == LedgerPartyState.archived;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kLedgerSchema,
    'name': name,
    'note': note,
    'state': state.name,
  };

  static LedgerParty decode(LumeRecord r) {
    final LedgerCodec c = LedgerCodec(LedgerCollections.parties, r);
    return LedgerParty(
      id: c.id,
      name: c.name('name'),
      note: c.note('note'),
      state: c.choice('state', LedgerPartyState.values),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LedgerParty &&
      other.id == id &&
      other.name == name &&
      other.note == note &&
      other.state == state &&
      other.version == version;

  @override
  int get hashCode => Object.hash(id, name, note, state, version);
}

/// One movement of money with one person. Amounts are positive; the kind
/// says which way. Only principals have a due date; only repayments carry
/// [excessConfirmed].
@immutable
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.partyId,
    required this.kind,
    required this.amount,
    required this.on,
    this.due,
    this.note,
    this.state = LedgerEntryState.active,
    this.excessConfirmed = false,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final LumeRecordId partyId;
  final LedgerKind kind;
  final LumeMoney amount;
  final LumeDate on;
  final LumeDate? due;
  final String? note;
  final LedgerEntryState state;

  /// The reader confirmed that this repayment was more than was owed, and
  /// the excess is credit (§5.4).
  final bool excessConfirmed;
  final DateTime createdAt;
  final int version;

  LumeCurrency get currency => amount.currency;
  bool get active => state == LedgerEntryState.active;
  bool get voided => !active;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kLedgerSchema,
    'party': partyId.value,
    'kind': kind.name,
    'amountMinor': amount.minor,
    'currency': amount.currency.code,
    'on': on.toIso(),
    'due': due?.toIso(),
    'note': note,
    'state': state.name,
    'excessConfirmed': excessConfirmed,
  };

  LedgerEntry copyWith({
    LedgerEntryState? state,
    bool? excessConfirmed,
    int? version,
  }) => LedgerEntry(
    id: id,
    partyId: partyId,
    kind: kind,
    amount: amount,
    on: on,
    due: due,
    note: note,
    state: state ?? this.state,
    excessConfirmed: excessConfirmed ?? this.excessConfirmed,
    createdAt: createdAt,
    version: version ?? this.version,
  );

  static LedgerEntry decode(LumeRecord r) {
    final LedgerCodec c = LedgerCodec(LedgerCollections.entries, r);
    final LedgerKind kind = c.kind('kind');
    final LumeDate on = c.date('on')!;
    final LumeDate? due = c.date('due', optional: true);
    if (due != null && !kind.isPrincipal) c.fail('due', 'repaymentHasDue');
    if (due != null && due.isBefore(on)) c.fail('due', 'dueBeforeDate');
    final bool excess = c.flag('excessConfirmed');
    if (excess && kind.isPrincipal) c.fail('excessConfirmed', 'principal');
    final LumeMoney amount = c.money('amountMinor', 'currency');
    if (amount.isZero) c.fail('amountMinor', 'zero');
    return LedgerEntry(
      id: c.id,
      partyId: c.ref('party'),
      kind: kind,
      amount: amount,
      on: on,
      due: due,
      note: c.note('note'),
      state: c.choice('state', LedgerEntryState.values),
      excessConfirmed: excess,
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  /// The FIFO tiebreak after the dates: creation instant, then id.
  int compareCreation(LedgerEntry other) {
    final int t = createdAt.compareTo(other.createdAt);
    return t != 0 ? t : id.compareTo(other.id);
  }
}

/// The part of one repayment applied to one principal.
@immutable
class LedgerAllocation {
  const LedgerAllocation({
    required this.id,
    required this.partyId,
    required this.repaymentId,
    required this.principalId,
    required this.amount,
    required this.origin,
    required this.scopeRevision,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final LumeRecordId partyId;
  final LumeRecordId repaymentId;
  final LumeRecordId principalId;
  final LumeMoney amount;
  final LedgerOrigin origin;

  /// The reconciliation it belongs to; the scope's latest is its highest.
  final int scopeRevision;
  final DateTime createdAt;
  final int version;

  bool get manual => origin == LedgerOrigin.manual;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kLedgerSchema,
    'party': partyId.value,
    'repayment': repaymentId.value,
    'principal': principalId.value,
    'amountMinor': amount.minor,
    'currency': amount.currency.code,
    'origin': origin.name,
    'scopeRevision': scopeRevision,
  };

  static LedgerAllocation decode(LumeRecord r) {
    final LedgerCodec c = LedgerCodec(LedgerCollections.allocations, r);
    final LumeMoney amount = c.money('amountMinor', 'currency');
    if (amount.isZero) c.fail('amountMinor', 'zero');
    final Object? rev = r['scopeRevision'];
    if (rev is! int || rev < 1) c.fail('scopeRevision', 'invalid');
    return LedgerAllocation(
      id: c.id,
      partyId: c.ref('party'),
      repaymentId: c.ref('repayment'),
      principalId: c.ref('principal'),
      amount: amount,
      origin: c.choice('origin', LedgerOrigin.values),
      scopeRevision: rev,
      createdAt: r.createdAt,
      version: r.version,
    );
  }
}

/// A record that could not be read as what its collection holds.
@immutable
class LedgerDefect {
  const LedgerDefect(this.collection, this.recordId, this.field, this.reason);

  final String collection;
  final String recordId;
  final String field;

  /// A stable machine reason: `missing`, `type`, `precision`, `overflow`,
  /// `currency`, `schema`, `zero`, `dueBeforeDate` …
  final String reason;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

/// Thrown by a decode; caught by whoever reads a collection.
@immutable
class LedgerDefectException implements Exception {
  const LedgerDefectException(this.defect);
  final LedgerDefect defect;

  @override
  String toString() => 'LedgerDefectException($defect)';
}

/// Strict field readers for one record.
class LedgerCodec {
  LedgerCodec(this.collection, this.record) {
    if (record['schema'] != kLedgerSchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) => throw LedgerDefectException(
    LedgerDefect(collection, record.id, field, reason),
  );

  LumeRecordId get id => LumeRecordId.tryParse(record.id) ?? fail('id', 'uuid');

  LumeRecordId ref(String field) {
    final Object? v = record[field];
    if (v is! String) fail(field, 'missing');
    return LumeRecordId.tryParse(v) ?? fail(field, 'uuid');
  }

  String name(String field) {
    final Object? v = record[field];
    if (v is! String) fail(field, 'missing');
    final String t = v.trim();
    if (t.isEmpty) fail(field, 'empty');
    if (t.length > kLedgerNameMax) fail(field, 'long');
    return t;
  }

  String? note(String field) {
    final Object? v = record[field];
    if (v == null) return null;
    if (v is! String) fail(field, 'type');
    if (v.length > kLedgerNoteMax) fail(field, 'long');
    return v.trim().isEmpty ? null : v;
  }

  T choice<T extends Enum>(String field, List<T> values) {
    final Object? v = record[field];
    for (final T x in values) {
      if (x.name == v) return x;
    }
    fail(field, 'value');
  }

  LedgerKind kind(String field) =>
      LedgerKind.parse(record[field]) ?? fail(field, 'value');

  bool flag(String field) {
    final Object? v = record[field];
    if (v is! bool) fail(field, 'type');
    return v;
  }

  LumeDate? date(String field, {bool optional = false}) {
    final Object? v = record[field];
    if (v == null && optional) return null;
    if (v is! String) fail(field, 'missing');
    return LumeDate.tryParse(v) ?? fail(field, 'date');
  }

  LumeMoney money(String minorField, String currencyField) {
    final Object? code = record[currencyField];
    if (code is! String) fail(currencyField, 'missing');
    final LumeCurrency? cur = LumeCurrency.tryOf(code);
    if (cur == null) fail(currencyField, 'currency');
    final Object? minor = record[minorField];
    if (minor is! int) fail(minorField, 'type');
    try {
      return LumeMoney.entry(minor, cur);
    } on LumeMoneyException catch (e) {
      fail(minorField, e.failure.name);
    }
  }
}

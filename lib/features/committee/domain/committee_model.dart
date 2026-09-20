/// A committee, as records: what is stored and how it is read back
/// (`COMMITTEE_PROPOSAL.md` §5).
///
/// A committee is a rotating savings circle. Every position pays the same
/// contribution each cycle, and one position is paid the whole pool each
/// cycle, in a fixed order settled when the committee is created. There are
/// as many cycles as positions, so each position receives exactly once and
/// the money balances: what a position pays in over the committee,
/// contribution × N, is what its one payout is worth.
///
/// Six collections, all under one schema. A member is a person; a position
/// is a share. One member may hold several positions without being counted
/// twice as a person (D-C4). Contributions and payouts are written against
/// a position and a stored cycle, never against a date or an index, so a
/// record keeps its meaning whatever else changes.
///
/// Nothing derived is stored: no pool, no total, no collected figure, no
/// state. Those are worked out in `committee_book.dart` and checked before
/// any write is published.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

/// The schema every committee record carries.
const String kCommitteeSchema = 'lume.committee/1';

/// Where each kind of record lives.
abstract final class CommitteeCollections {
  static const String committees = 'committee.committee';
  static const String members = 'committee.member';
  static const String positions = 'committee.position';
  static const String cycles = 'committee.cycle';
  static const String contributions = 'committee.contribution';
  static const String payouts = 'committee.payout';

  static const List<String> all = <String>[
    committees,
    members,
    positions,
    cycles,
    contributions,
    payouts,
  ];
}

/// A committee's or a member's name.
const int kCommitteeNameMax = 80;

/// A note on a committee or a member.
const int kCommitteeNoteMax = 500;

/// The fewest positions a committee can have: two people taking turns.
const int kCommitteePositionsMin = 2;

/// The most positions a committee can have — ten years of monthly cycles.
const int kCommitteePositionsMax = 120;

/// How often a cycle falls due.
///
/// Monthly only (D-C15). It is typed so that a stored value this build does
/// not know becomes a defect rather than being read as monthly.
enum CommitteeFrequency { monthly }

/// What the reader is in this committee (D-C5).
///
/// The role and [CommitteeMember.isReader] must agree: `member` and
/// `organiserMember` each need exactly one member marked as the reader, and
/// `organiser` needs none. Being the organiser earns nothing; there is no
/// fee anywhere in this model.
enum CommitteeReaderRole { member, organiser, organiserMember }

/// Whether a contribution or a payout still counts.
enum CommitteeEntryState { active, voided }

/// The committee itself: its terms, and whether it has been cancelled.
@immutable
class Committee {
  const Committee({
    required this.id,
    required this.name,
    this.note,
    required this.contribution,
    required this.positions,
    this.frequency = CommitteeFrequency.monthly,
    required this.firstDue,
    this.readerRole = CommitteeReaderRole.member,
    this.cancelledOn,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;

  /// The reader's own label: "Office committee", "Street kameti".
  final String name;
  final String? note;

  /// What one position pays, each cycle.
  final LumeMoney contribution;

  /// N: the number of shares, and so the number of cycles.
  final int positions;
  final CommitteeFrequency frequency;

  /// Cycle 1's due date, and the anchor every later cycle is worked out
  /// from.
  final LumeDate firstDue;
  final CommitteeReaderRole readerRole;

  /// The day the reader cancelled it, or `null` while it runs (D-C7).
  ///
  /// It is the cutoff, not a flag: a cycle due on or before it kept its
  /// obligation, and a cycle due after it never had one.
  final LumeDate? cancelledOn;

  final DateTime createdAt;
  final int version;

  LumeCurrency get currency => contribution.currency;
  bool get cancelled => cancelledOn != null;

  /// What one cycle collects when every position pays: contribution × N.
  LumeMoney get pool => LumeMoney.sum(contribution.minor * positions, currency);

  /// What the whole committee moves: contribution × N × N.
  LumeMoney get expectedTotal =>
      LumeMoney.sum(contribution.minor * positions * positions, currency);

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kCommitteeSchema,
    'name': name,
    'note': note,
    'contributionMinor': contribution.minor,
    'currency': currency.code,
    'positions': positions,
    'frequency': frequency.name,
    'firstDue': firstDue.toIso(),
    'readerRole': readerRole.name,
    'cancelledOn': cancelledOn?.toIso(),
  };

  /// A copy with new labels, a new role or a new cancellation date. The
  /// terms are absent on purpose: once a contribution or a payout exists
  /// they are locked, and before that the committee is rebuilt rather than
  /// patched (D-C6).
  Committee copyWith({
    String? name,
    String? note,
    bool clearNote = false,
    CommitteeReaderRole? readerRole,
    LumeDate? cancelledOn,
    bool clearCancelled = false,
  }) => Committee(
    id: id,
    name: name ?? this.name,
    note: clearNote ? null : (note ?? this.note),
    contribution: contribution,
    positions: positions,
    frequency: frequency,
    firstDue: firstDue,
    readerRole: readerRole ?? this.readerRole,
    cancelledOn: clearCancelled ? null : (cancelledOn ?? this.cancelledOn),
    createdAt: createdAt,
    version: version,
  );

  static Committee decode(LumeRecord r) {
    final CommitteeCodec c = CommitteeCodec(CommitteeCollections.committees, r);
    final LumeMoney contribution = c.money('contributionMinor', 'currency');
    if (contribution.isZero) c.fail('contributionMinor', 'zero');
    final Object? positions = r['positions'];
    if (positions is! int) c.fail('positions', 'type');
    if (positions < kCommitteePositionsMin ||
        positions > kCommitteePositionsMax) {
      c.fail('positions', 'range');
    }
    // Checked by division, never by multiplying first: contribution × N is
    // one payout, and contribution × N × N is the whole committee. Either
    // could pass a 64-bit integer before anything compared it.
    if (contribution.minor > LumeMoney.maxEntryMinor ~/ positions) {
      c.fail('contributionMinor', 'overflow');
    }
    if (contribution.minor > LumeMoney.maxSumMinor ~/ (positions * positions)) {
      c.fail('contributionMinor', 'overflow');
    }
    return Committee(
      id: c.id,
      name: c.name('name'),
      note: c.note('note'),
      contribution: contribution,
      positions: positions,
      frequency: c.choice('frequency', CommitteeFrequency.values),
      firstDue: c.date('firstDue')!,
      readerRole: c.choice('readerRole', CommitteeReaderRole.values),
      cancelledOn: c.date('cancelledOn', optional: true),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Committee &&
      other.id == id &&
      other.name == name &&
      other.note == note &&
      other.contribution == contribution &&
      other.positions == positions &&
      other.frequency == frequency &&
      other.firstDue == firstDue &&
      other.readerRole == readerRole &&
      other.cancelledOn == cancelledOn &&
      other.version == version;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    note,
    contribution,
    positions,
    frequency,
    firstDue,
    readerRole,
    cancelledOn,
    version,
  );
}

/// A person in the committee. At most one is the reader.
@immutable
class CommitteeMember {
  const CommitteeMember({
    required this.id,
    required this.committeeId,
    required this.name,
    this.isReader = false,
    this.note,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final LumeRecordId committeeId;
  final String name;

  /// Whether this member is the reader themselves.
  final bool isReader;
  final String? note;
  final DateTime createdAt;
  final int version;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kCommitteeSchema,
    'committee': committeeId.value,
    'name': name,
    'isReader': isReader,
    'note': note,
  };

  CommitteeMember copyWith({
    String? name,
    String? note,
    bool clearNote = false,
    bool? isReader,
  }) => CommitteeMember(
    id: id,
    committeeId: committeeId,
    name: name ?? this.name,
    isReader: isReader ?? this.isReader,
    note: clearNote ? null : (note ?? this.note),
    createdAt: createdAt,
    version: version,
  );

  static CommitteeMember decode(LumeRecord r) {
    final CommitteeCodec c = CommitteeCodec(CommitteeCollections.members, r);
    return CommitteeMember(
      id: c.id,
      committeeId: c.ref('committee'),
      name: c.name('name'),
      isReader: c.flag('isReader'),
      note: c.note('note'),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CommitteeMember &&
      other.id == id &&
      other.committeeId == committeeId &&
      other.name == name &&
      other.isReader == isReader &&
      other.note == note &&
      other.version == version;

  @override
  int get hashCode =>
      Object.hash(id, committeeId, name, isReader, note, version);
}

/// A share: one member's place in the payout order.
///
/// [cycle] is the cycle whose pool this position receives. Each number
/// 1..N belongs to exactly one position, so every cycle has one recipient
/// and every position receives once.
@immutable
class CommitteePosition {
  const CommitteePosition({
    required this.id,
    required this.committeeId,
    required this.memberId,
    required this.cycle,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final LumeRecordId committeeId;
  final LumeRecordId memberId;
  final int cycle;
  final DateTime createdAt;
  final int version;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kCommitteeSchema,
    'committee': committeeId.value,
    'member': memberId.value,
    'cycle': cycle,
  };

  static CommitteePosition decode(LumeRecord r) {
    final CommitteeCodec c = CommitteeCodec(CommitteeCollections.positions, r);
    final Object? cycle = r['cycle'];
    if (cycle is! int) c.fail('cycle', 'type');
    if (cycle < 1 || cycle > kCommitteePositionsMax) c.fail('cycle', 'range');
    return CommitteePosition(
      id: c.id,
      committeeId: c.ref('committee'),
      memberId: c.ref('member'),
      cycle: cycle,
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CommitteePosition &&
      other.id == id &&
      other.committeeId == committeeId &&
      other.memberId == memberId &&
      other.cycle == cycle &&
      other.version == version;

  @override
  int get hashCode => Object.hash(id, committeeId, memberId, cycle, version);
}

/// One cycle of the committee, with the day it falls due.
///
/// The dates are worked out once, from the committee's anchor, and stored
/// (D-C1). A stored schedule is never recomputed, so a contribution
/// recorded years ago still points at the day it was for.
@immutable
class CommitteeCycle {
  const CommitteeCycle({
    required this.id,
    required this.committeeId,
    required this.n,
    required this.due,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final LumeRecordId committeeId;

  /// 1..N, in order.
  final int n;
  final LumeDate due;
  final DateTime createdAt;
  final int version;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kCommitteeSchema,
    'committee': committeeId.value,
    'n': n,
    'due': due.toIso(),
  };

  static CommitteeCycle decode(LumeRecord r) {
    final CommitteeCodec c = CommitteeCodec(CommitteeCollections.cycles, r);
    final Object? n = r['n'];
    if (n is! int) c.fail('n', 'type');
    if (n < 1 || n > kCommitteePositionsMax) c.fail('n', 'range');
    return CommitteeCycle(
      id: c.id,
      committeeId: c.ref('committee'),
      n: n,
      due: c.date('due')!,
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CommitteeCycle &&
      other.id == id &&
      other.committeeId == committeeId &&
      other.n == n &&
      other.due == due &&
      other.version == version;

  @override
  int get hashCode => Object.hash(id, committeeId, n, due, version);
}

/// One position's contribution for one cycle.
///
/// Always the committee's whole contribution: there is no part payment, no
/// overpayment and no credit (D-C2). [paidOn] is the day the money changed
/// hands, which may be before the cycle falls due but never after the
/// reader's own day (D-C8).
@immutable
class CommitteeContribution {
  const CommitteeContribution({
    required this.id,
    required this.committeeId,
    required this.cycleId,
    required this.positionId,
    required this.amount,
    required this.paidOn,
    this.state = CommitteeEntryState.active,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final LumeRecordId committeeId;
  final LumeRecordId cycleId;
  final LumeRecordId positionId;
  final LumeMoney amount;
  final LumeDate paidOn;
  final CommitteeEntryState state;
  final DateTime createdAt;
  final int version;

  bool get active => state == CommitteeEntryState.active;
  bool get voided => state == CommitteeEntryState.voided;
  LumeCurrency get currency => amount.currency;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kCommitteeSchema,
    'committee': committeeId.value,
    'cycle': cycleId.value,
    'position': positionId.value,
    'amountMinor': amount.minor,
    'currency': currency.code,
    'paidOn': paidOn.toIso(),
    'state': state.name,
  };

  CommitteeContribution withState(CommitteeEntryState s) =>
      CommitteeContribution(
        id: id,
        committeeId: committeeId,
        cycleId: cycleId,
        positionId: positionId,
        amount: amount,
        paidOn: paidOn,
        state: s,
        createdAt: createdAt,
        version: version,
      );

  static CommitteeContribution decode(LumeRecord r) {
    final CommitteeCodec c = CommitteeCodec(
      CommitteeCollections.contributions,
      r,
    );
    final LumeMoney amount = c.money('amountMinor', 'currency');
    if (amount.isZero) c.fail('amountMinor', 'zero');
    return CommitteeContribution(
      id: c.id,
      committeeId: c.ref('committee'),
      cycleId: c.ref('cycle'),
      positionId: c.ref('position'),
      amount: amount,
      paidOn: c.date('paidOn')!,
      state: c.choice('state', CommitteeEntryState.values),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CommitteeContribution &&
      other.id == id &&
      other.committeeId == committeeId &&
      other.cycleId == cycleId &&
      other.positionId == positionId &&
      other.amount == amount &&
      other.paidOn == paidOn &&
      other.state == state &&
      other.version == version;

  @override
  int get hashCode => Object.hash(
    id,
    committeeId,
    cycleId,
    positionId,
    amount,
    paidOn,
    state,
    version,
  );
}

/// The reader's record that a cycle's pool was handed to the position that
/// holds it.
///
/// Lume moves no money. This says a payout happened outside Lume, for the
/// exact pool — contribution × N — and only once that cycle was fully
/// collected (D-C3).
@immutable
class CommitteePayout {
  const CommitteePayout({
    required this.id,
    required this.committeeId,
    required this.cycleId,
    required this.positionId,
    required this.amount,
    required this.paidOn,
    this.state = CommitteeEntryState.active,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final LumeRecordId committeeId;
  final LumeRecordId cycleId;

  /// The position that holds this cycle — the recipient.
  final LumeRecordId positionId;
  final LumeMoney amount;
  final LumeDate paidOn;
  final CommitteeEntryState state;
  final DateTime createdAt;
  final int version;

  bool get active => state == CommitteeEntryState.active;
  bool get voided => state == CommitteeEntryState.voided;
  LumeCurrency get currency => amount.currency;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kCommitteeSchema,
    'committee': committeeId.value,
    'cycle': cycleId.value,
    'position': positionId.value,
    'amountMinor': amount.minor,
    'currency': currency.code,
    'paidOn': paidOn.toIso(),
    'state': state.name,
  };

  CommitteePayout withState(CommitteeEntryState s) => CommitteePayout(
    id: id,
    committeeId: committeeId,
    cycleId: cycleId,
    positionId: positionId,
    amount: amount,
    paidOn: paidOn,
    state: s,
    createdAt: createdAt,
    version: version,
  );

  static CommitteePayout decode(LumeRecord r) {
    final CommitteeCodec c = CommitteeCodec(CommitteeCollections.payouts, r);
    final LumeMoney amount = c.money('amountMinor', 'currency');
    if (amount.isZero) c.fail('amountMinor', 'zero');
    return CommitteePayout(
      id: c.id,
      committeeId: c.ref('committee'),
      cycleId: c.ref('cycle'),
      positionId: c.ref('position'),
      amount: amount,
      paidOn: c.date('paidOn')!,
      state: c.choice('state', CommitteeEntryState.values),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CommitteePayout &&
      other.id == id &&
      other.committeeId == committeeId &&
      other.cycleId == cycleId &&
      other.positionId == positionId &&
      other.amount == amount &&
      other.paidOn == paidOn &&
      other.state == state &&
      other.version == version;

  @override
  int get hashCode => Object.hash(
    id,
    committeeId,
    cycleId,
    positionId,
    amount,
    paidOn,
    state,
    version,
  );
}

/// A stored record that cannot be read, and why.
///
/// [reason] is a stable machine word, never anything a reader sees:
/// missing, type, precision, overflow, currency, schema, zero, unsupported,
/// uuid, empty, long, value, date, range.
@immutable
class CommitteeDefect {
  const CommitteeDefect(
    this.collection,
    this.recordId,
    this.field,
    this.reason, {
    this.committeeId,
  });

  final String collection;
  final String recordId;
  final String field;
  final String reason;

  /// The committee the record belongs to, when it names one — the join the
  /// book uses to leave a whole committee out of the totals.
  final String? committeeId;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

/// Thrown by a decoder. Callers list the defect; nothing is repaired.
@immutable
class CommitteeDefectException implements Exception {
  const CommitteeDefectException(this.defect);

  final CommitteeDefect defect;

  @override
  String toString() => 'CommitteeDefectException($defect)';
}

/// Reads one stored record strictly. Anything unexpected is a defect.
class CommitteeCodec {
  CommitteeCodec(this.collection, this.record) {
    if (record['schema'] != kCommitteeSchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) => throw CommitteeDefectException(
    CommitteeDefect(
      collection,
      record.id,
      field,
      reason,
      committeeId: collection == CommitteeCollections.committees
          ? record.id
          : (record['committee'] is String
                ? record['committee']! as String
                : null),
    ),
  );

  LumeRecordId get id => LumeRecordId.tryParse(record.id) ?? fail('id', 'uuid');

  LumeRecordId ref(String field) {
    final Object? raw = record[field];
    if (raw is! String) fail(field, 'missing');
    return LumeRecordId.tryParse(raw) ?? fail(field, 'uuid');
  }

  String name(String field) {
    final Object? raw = record[field];
    if (raw is! String) fail(field, 'missing');
    final String text = raw.trim();
    if (text.isEmpty) fail(field, 'empty');
    if (text.length > kCommitteeNameMax) fail(field, 'long');
    return text;
  }

  String? note(String field) {
    final Object? raw = record[field];
    if (raw == null) return null;
    if (raw is! String) fail(field, 'type');
    if (raw.length > kCommitteeNoteMax) fail(field, 'long');
    return raw.trim().isEmpty ? null : raw;
  }

  bool flag(String field) {
    final Object? raw = record[field];
    if (raw == null) return false;
    if (raw is! bool) fail(field, 'type');
    return raw;
  }

  T choice<T extends Enum>(String field, List<T> values) {
    final Object? raw = record[field];
    if (raw is! String) fail(field, 'missing');
    for (final T v in values) {
      if (v.name == raw) return v;
    }
    fail(field, 'unsupported');
  }

  LumeDate? date(String field, {bool optional = false}) {
    final Object? raw = record[field];
    if (raw == null) {
      if (optional) return null;
      fail(field, 'missing');
    }
    if (raw is! String) fail(field, 'missing');
    return LumeDate.tryParse(raw) ?? fail(field, 'date');
  }

  LumeMoney money(String minorField, String currencyField) {
    final Object? code = record[currencyField];
    if (code is! String) fail(currencyField, 'missing');
    final LumeCurrency? currency = LumeCurrency.tryOf(code);
    if (currency == null) fail(currencyField, 'currency');
    final Object? minor = record[minorField];
    if (minor is! int) fail(minorField, 'missing');
    try {
      return LumeMoney.entry(minor, currency);
    } on LumeMoneyException catch (e) {
      fail(minorField, e.failure.name);
    }
  }
}

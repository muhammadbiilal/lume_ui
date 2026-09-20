/// Committee's writes (`COMMITTEE_PROPOSAL.md` §5, §7, §9).
///
/// Every write is one transaction over the record store, and every
/// transaction is checked against the whole committee before it is
/// published: if a rule would break, nothing is written and the reader is
/// told why. Creating a committee writes its members, positions and cycles
/// together; recording a member's contributions for a cycle writes one
/// record per share, together; deleting one removes everything it owns.
///
/// Nothing here reads a clock except the injected [DateTime Function()],
/// which stamps the moment a record was made. Every day a rule depends on
/// is passed in by the caller, from the reader's own zone.
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_currency_policy.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_month_anchor.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import 'committee_book.dart';
import 'committee_failure.dart';
import 'committee_model.dart';

/// A member as the reader entered them, before anything is written.
@immutable
class CommitteeMemberDraft {
  const CommitteeMemberDraft({
    required this.name,
    this.isReader = false,
    this.note,
    required this.cycles,
  });

  final String name;
  final bool isReader;
  final String? note;

  /// The cycles this member receives — one per share they hold.
  final List<int> cycles;
}

/// A committee as the reader entered it.
@immutable
class CommitteeDraft {
  const CommitteeDraft({
    required this.name,
    this.note,
    required this.contribution,
    required this.firstDue,
    this.readerRole = CommitteeReaderRole.member,
    required this.members,
  });

  final String name;
  final String? note;
  final LumeMoney contribution;
  final LumeDate firstDue;
  final CommitteeReaderRole readerRole;
  final List<CommitteeMemberDraft> members;

  LumeCurrency get currency => contribution.currency;

  /// Positions, and so cycles: every share of every member.
  int get positions {
    int n = 0;
    for (final CommitteeMemberDraft m in members) {
      n += m.cycles.length;
    }
    return n;
  }

  String get fingerprint => jsonEncode(<String, Object?>{
    'n': name,
    'o': note,
    'c': contribution.minor,
    'u': contribution.currency.code,
    'f': firstDue.toIso(),
    'r': readerRole.name,
    'm': <Object?>[
      for (final CommitteeMemberDraft m in members)
        <Object?>[m.name, m.isReader, m.note, m.cycles],
    ],
  });
}

/// What a committed write did, and what it made.
@immutable
class CommitteeWrite {
  const CommitteeWrite(
    this.receipt, {
    this.committee,
    this.contributions = const <CommitteeContribution>[],
    this.payout,
  });

  final LumeTxReceipt receipt;
  final Committee? committee;
  final List<CommitteeContribution> contributions;
  final CommitteePayout? payout;
}

/// The records as they stand, or why they cannot be read.
@immutable
class CommitteeSnapshot {
  const CommitteeSnapshot({
    required this.status,
    this.committees = const <Committee>[],
    this.members = const <CommitteeMember>[],
    this.positions = const <CommitteePosition>[],
    this.cycles = const <CommitteeCycle>[],
    this.contributions = const <CommitteeContribution>[],
    this.payouts = const <CommitteePayout>[],
    this.defects = const <CommitteeDefect>[],
  });

  final LumeCollectionStatus status;
  final List<Committee> committees;
  final List<CommitteeMember> members;
  final List<CommitteePosition> positions;
  final List<CommitteeCycle> cycles;
  final List<CommitteeContribution> contributions;
  final List<CommitteePayout> payouts;
  final List<CommitteeDefect> defects;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;

  CommitteeBook book(LumeDate? today) => CommitteeBook.from(
    committees: committees,
    members: members,
    positions: positions,
    cycles: cycles,
    contributions: contributions,
    payouts: payouts,
    defects: defects,
    today: today,
  );
}

/// Everything one transaction can see and change, decoded once.
class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(CommitteeCollections.committees)) {
      _read<Committee>(r, Committee.decode, committees);
    }
    for (final LumeRecord r in tx.all(CommitteeCollections.members)) {
      _read<CommitteeMember>(r, CommitteeMember.decode, members);
    }
    for (final LumeRecord r in tx.all(CommitteeCollections.positions)) {
      _read<CommitteePosition>(r, CommitteePosition.decode, positions);
    }
    for (final LumeRecord r in tx.all(CommitteeCollections.cycles)) {
      _read<CommitteeCycle>(r, CommitteeCycle.decode, cycles);
    }
    for (final LumeRecord r in tx.all(CommitteeCollections.contributions)) {
      _read<CommitteeContribution>(
        r,
        CommitteeContribution.decode,
        contributions,
      );
    }
    for (final LumeRecord r in tx.all(CommitteeCollections.payouts)) {
      _read<CommitteePayout>(r, CommitteePayout.decode, payouts);
    }
    damagedBefore = <String>{
      for (final CommitteeDamage d in book().damage) d.committee,
    };
  }

  final LumeRecordTx tx;
  final List<Committee> committees = <Committee>[];
  final List<CommitteeMember> members = <CommitteeMember>[];
  final List<CommitteePosition> positions = <CommitteePosition>[];
  final List<CommitteeCycle> cycles = <CommitteeCycle>[];
  final List<CommitteeContribution> contributions = <CommitteeContribution>[];
  final List<CommitteePayout> payouts = <CommitteePayout>[];
  final List<CommitteeDefect> defects = <CommitteeDefect>[];

  /// The committees that could not be read before this write began, so a
  /// write is never blamed for damage it did not cause.
  late final Set<String> damagedBefore;

  void _read<T>(LumeRecord r, T Function(LumeRecord) decode, List<T> into) {
    try {
      into.add(decode(r));
    } on CommitteeDefectException catch (e) {
      defects.add(e.defect);
    }
  }

  /// The day is never read inside a write: a rule that needs one takes it
  /// from the caller.
  CommitteeBook book() => CommitteeBook.from(
    committees: committees,
    members: members,
    positions: positions,
    cycles: cycles,
    contributions: contributions,
    payouts: payouts,
    defects: defects,
    today: null,
  );

  CommitteeView view(LumeRecordId id) {
    final CommitteeView? v = book().committee(id);
    if (v == null) {
      throw CommitteeFailure(
        CommitteeFailureKind.notFound,
        ids: <LumeRecordId>[id],
      );
    }
    return v;
  }

  /// A committee a write may touch: one that was readable to begin with.
  CommitteeView sound(LumeRecordId id) {
    final CommitteeView v = view(id);
    if (damagedBefore.contains(id.value)) {
      throw CommitteeFailure(
        CommitteeFailureKind.damaged,
        ids: <LumeRecordId>[id],
      );
    }
    return v;
  }

  Committee committeeRecord(LumeRecordId id) {
    for (final Committee c in committees) {
      if (c.id == id) return c;
    }
    throw CommitteeFailure(
      CommitteeFailureKind.notFound,
      ids: <LumeRecordId>[id],
    );
  }

  CommitteeContribution contribution(LumeRecordId id) {
    for (final CommitteeContribution x in contributions) {
      if (x.id == id) return x;
    }
    throw CommitteeFailure(
      CommitteeFailureKind.notFound,
      ids: <LumeRecordId>[id],
    );
  }

  CommitteePayout payout(LumeRecordId id) {
    for (final CommitteePayout o in payouts) {
      if (o.id == id) return o;
    }
    throw CommitteeFailure(
      CommitteeFailureKind.notFound,
      ids: <LumeRecordId>[id],
    );
  }

  // Staging: the decoded lists are kept in step with the transaction, so
  // the checks before publication see exactly what would be written.

  Committee putCommittee(Committee c, {required bool isNew}) {
    final LumeRecord r = isNew
        ? tx.create(CommitteeCollections.committees, c.id.value, c.toFields())
        : tx.update(
            CommitteeCollections.committees,
            c.id.value,
            c.toFields(),
            expectVersion: c.version,
          );
    final Committee decoded = Committee.decode(r);
    final int at = committees.indexWhere((Committee x) => x.id == c.id);
    if (at < 0) {
      committees.add(decoded);
    } else {
      committees[at] = decoded;
    }
    return decoded;
  }

  CommitteeMember putMember(CommitteeMember m, {required bool isNew}) {
    final LumeRecord r = isNew
        ? tx.create(CommitteeCollections.members, m.id.value, m.toFields())
        : tx.update(
            CommitteeCollections.members,
            m.id.value,
            m.toFields(),
            expectVersion: m.version,
          );
    final CommitteeMember decoded = CommitteeMember.decode(r);
    final int at = members.indexWhere((CommitteeMember x) => x.id == m.id);
    if (at < 0) {
      members.add(decoded);
    } else {
      members[at] = decoded;
    }
    return decoded;
  }

  void addPosition(CommitteePosition p) {
    positions.add(
      CommitteePosition.decode(
        tx.create(CommitteeCollections.positions, p.id.value, p.toFields()),
      ),
    );
  }

  void addCycle(CommitteeCycle c) {
    cycles.add(
      CommitteeCycle.decode(
        tx.create(CommitteeCollections.cycles, c.id.value, c.toFields()),
      ),
    );
  }

  CommitteeContribution putContribution(
    CommitteeContribution x, {
    required bool isNew,
  }) {
    final LumeRecord r = isNew
        ? tx.create(
            CommitteeCollections.contributions,
            x.id.value,
            x.toFields(),
          )
        : tx.update(
            CommitteeCollections.contributions,
            x.id.value,
            x.toFields(),
            expectVersion: x.version,
          );
    final CommitteeContribution decoded = CommitteeContribution.decode(r);
    final int at = contributions.indexWhere(
      (CommitteeContribution y) => y.id == x.id,
    );
    if (at < 0) {
      contributions.add(decoded);
    } else {
      contributions[at] = decoded;
    }
    return decoded;
  }

  CommitteePayout putPayout(CommitteePayout o, {required bool isNew}) {
    final LumeRecord r = isNew
        ? tx.create(CommitteeCollections.payouts, o.id.value, o.toFields())
        : tx.update(
            CommitteeCollections.payouts,
            o.id.value,
            o.toFields(),
            expectVersion: o.version,
          );
    final CommitteePayout decoded = CommitteePayout.decode(r);
    final int at = payouts.indexWhere((CommitteePayout y) => y.id == o.id);
    if (at < 0) {
      payouts.add(decoded);
    } else {
      payouts[at] = decoded;
    }
    return decoded;
  }

  void _sweep(String collection, bool Function(LumeRecord) mine) {
    for (final LumeRecord r in tx.all(collection)) {
      if (mine(r)) {
        tx.delete(collection, r.id, expectVersion: r.version);
      }
    }
  }

  /// Remove a committee's members, positions and cycles — everything the
  /// payout order is made of — leaving the committee record itself. Only
  /// for a committee with no financial record at all.
  void removeBelow(LumeRecordId id) {
    final String key = id.value;
    bool owned(LumeRecord r) => r['committee'] == key;
    _sweep(CommitteeCollections.cycles, owned);
    _sweep(CommitteeCollections.positions, owned);
    _sweep(CommitteeCollections.members, owned);
    members.removeWhere((CommitteeMember x) => x.committeeId == id);
    positions.removeWhere((CommitteePosition x) => x.committeeId == id);
    cycles.removeWhere((CommitteeCycle x) => x.committeeId == id);
  }

  /// Remove a committee and everything belonging to it, damaged records
  /// included, in this one transaction.
  void removeCommittee(LumeRecordId id, int version) {
    final String key = id.value;
    bool owned(LumeRecord r) => r['committee'] == key;
    _sweep(CommitteeCollections.payouts, owned);
    _sweep(CommitteeCollections.contributions, owned);
    _sweep(CommitteeCollections.cycles, owned);
    _sweep(CommitteeCollections.positions, owned);
    _sweep(CommitteeCollections.members, owned);
    tx.delete(CommitteeCollections.committees, key, expectVersion: version);

    committees.removeWhere((Committee x) => x.id == id);
    members.removeWhere((CommitteeMember x) => x.committeeId == id);
    positions.removeWhere((CommitteePosition x) => x.committeeId == id);
    cycles.removeWhere((CommitteeCycle x) => x.committeeId == id);
    contributions.removeWhere((CommitteeContribution x) => x.committeeId == id);
    payouts.removeWhere((CommitteePayout x) => x.committeeId == id);
    defects.removeWhere((CommitteeDefect d) => d.committeeId == key);
    damagedBefore.remove(key);
  }
}

/// Committee's records, written in transactions.
class CommitteeRepository {
  CommitteeRepository(this._store, {Random? random, DateTime Function()? now})
    : _random = random ?? Random.secure(),
      _now = now ?? DateTime.now;

  final LumeRecordRepository _store;
  final Random _random;
  final DateTime Function() _now;

  /// Told once per committed write.
  Listenable get changes => _store;

  bool get durable => _store.durable;

  void open() {
    for (final String c in CommitteeCollections.all) {
      _store.open(c);
    }
  }

  void retry() {
    for (final String c in CommitteeCollections.all) {
      if (_store.view(c).status == LumeCollectionStatus.error) {
        _store.retry(c);
      }
    }
  }

  CommitteeSnapshot view() {
    final List<LumeCollectionView> views = <LumeCollectionView>[
      for (final String c in CommitteeCollections.all) _store.view(c),
    ];
    for (final LumeCollectionView v in views) {
      if (v.status == LumeCollectionStatus.error) {
        return const CommitteeSnapshot(status: LumeCollectionStatus.error);
      }
    }
    for (final LumeCollectionView v in views) {
      if (v.status == LumeCollectionStatus.loading) {
        return const CommitteeSnapshot(status: LumeCollectionStatus.loading);
      }
    }
    final List<CommitteeDefect> defects = <CommitteeDefect>[];
    List<T> read<T>(LumeCollectionView v, T Function(LumeRecord) decode) => <T>[
      for (final LumeRecord r in v.items)
        ...() {
          try {
            return <T>[decode(r)];
          } on CommitteeDefectException catch (e) {
            defects.add(e.defect);
            return <T>[];
          }
        }(),
    ];
    return CommitteeSnapshot(
      status: LumeCollectionStatus.ready,
      committees: read<Committee>(views[0], Committee.decode),
      members: read<CommitteeMember>(views[1], CommitteeMember.decode),
      positions: read<CommitteePosition>(views[2], CommitteePosition.decode),
      cycles: read<CommitteeCycle>(views[3], CommitteeCycle.decode),
      contributions: read<CommitteeContribution>(
        views[4],
        CommitteeContribution.decode,
      ),
      payouts: read<CommitteePayout>(views[5], CommitteePayout.decode),
      defects: defects,
    );
  }

  /// Create a committee: its members, its positions, and one cycle for
  /// each position, all in one transaction (§5).
  CommitteeResult<CommitteeWrite> addCommittee(
    CommitteeDraft draft, {
    String? idempotencyKey,
  }) => _write<Committee>(
    (_Data d) {
      _validate(draft);
      if (!LumeCurrencyPolicy.of(draft.currency).usable) {
        throw const CommitteeFailure.validation('currency', 'withdrawn');
      }
      final List<LumeDate>? dues = lumeMonthlyDues(
        draft.firstDue,
        draft.positions,
      );
      if (dues == null) {
        throw const CommitteeFailure.validation('firstDue', 'range');
      }
      final DateTime at = _now();
      final Committee c = Committee(
        id: _newId(),
        name: draft.name.trim(),
        note: _optional(draft.note),
        contribution: draft.contribution,
        positions: draft.positions,
        firstDue: draft.firstDue,
        readerRole: draft.readerRole,
        createdAt: at,
      );
      d.putCommittee(c, isNew: true);
      for (final CommitteeMemberDraft m in draft.members) {
        final CommitteeMember member = CommitteeMember(
          id: _newId(),
          committeeId: c.id,
          name: m.name.trim(),
          isReader: m.isReader,
          note: _optional(m.note),
          createdAt: at,
        );
        d.putMember(member, isNew: true);
        for (final int cycle in m.cycles) {
          d.addPosition(
            CommitteePosition(
              id: _newId(),
              committeeId: c.id,
              memberId: member.id,
              cycle: cycle,
              createdAt: at,
            ),
          );
        }
      }
      for (int n = 1; n <= draft.positions; n++) {
        d.addCycle(
          CommitteeCycle(
            id: _newId(),
            committeeId: c.id,
            n: n,
            due: dues[n - 1],
            createdAt: at,
          ),
        );
      }
      return c;
    },
    idempotencyKey: idempotencyKey,
    fingerprint: draft.fingerprint,
  );

  /// Change a committee's terms while nothing financial has happened yet
  /// (D-C6): the contribution, the currency, the anchor, the members and
  /// the payout order.
  ///
  /// The members, positions and cycles are replaced with new ones in the
  /// same transaction, so the committee is never half old and half new.
  /// Once any contribution or payout exists — active or voided — this is
  /// refused as [CommitteeFailureKind.locked] and the reader is told which
  /// term is fixed.
  CommitteeResult<CommitteeWrite> editTerms(
    LumeRecordId id,
    CommitteeDraft draft, {
    required int version,
  }) => _write<Committee>((_Data d) {
    final Committee was = d.committeeRecord(id);
    final CommitteeView v = d.sound(id);
    if (was.version != version) {
      throw CommitteeFailure(
        CommitteeFailureKind.conflict,
        ids: <LumeRecordId>[id],
      );
    }
    if (v.contributions.isNotEmpty || v.payouts.isNotEmpty) {
      throw const CommitteeFailure(
        CommitteeFailureKind.locked,
        field: 'contribution',
      );
    }
    if (was.cancelled) {
      throw CommitteeFailure(
        CommitteeFailureKind.cancelled,
        ids: <LumeRecordId>[id],
      );
    }
    _validate(draft);
    if (!LumeCurrencyPolicy.of(
      draft.currency,
      existing: <LumeCurrency>[was.currency],
    ).usable) {
      throw const CommitteeFailure.validation('currency', 'withdrawn');
    }
    final List<LumeDate>? dues = lumeMonthlyDues(
      draft.firstDue,
      draft.positions,
    );
    if (dues == null) {
      throw const CommitteeFailure.validation('firstDue', 'range');
    }
    final DateTime at = _now();
    // Out with the old shares and cycles, in with the new — one write.
    d.removeBelow(id);
    for (final CommitteeMemberDraft m in draft.members) {
      final CommitteeMember member = CommitteeMember(
        id: _newId(),
        committeeId: id,
        name: m.name.trim(),
        isReader: m.isReader,
        note: _optional(m.note),
        createdAt: at,
      );
      d.putMember(member, isNew: true);
      for (final int cycle in m.cycles) {
        d.addPosition(
          CommitteePosition(
            id: _newId(),
            committeeId: id,
            memberId: member.id,
            cycle: cycle,
            createdAt: at,
          ),
        );
      }
    }
    for (int n = 1; n <= draft.positions; n++) {
      d.addCycle(
        CommitteeCycle(
          id: _newId(),
          committeeId: id,
          n: n,
          due: dues[n - 1],
          createdAt: at,
        ),
      );
    }
    return d.putCommittee(
      Committee(
        id: id,
        name: draft.name.trim(),
        note: _optional(draft.note),
        contribution: draft.contribution,
        positions: draft.positions,
        firstDue: draft.firstDue,
        readerRole: draft.readerRole,
        createdAt: was.createdAt,
        version: was.version,
      ),
      isNew: false,
    );
  });

  /// Rename a committee, or change its note. Terms are not editable here:
  /// before any financial record [editTerms] rebuilds the committee, and
  /// after one they are locked (D-C6).
  CommitteeResult<CommitteeWrite> editCommittee(
    LumeRecordId id, {
    required String name,
    String? note,
    required int version,
  }) => _write<Committee>((_Data d) {
    final Committee was = d.committeeRecord(id);
    d.sound(id);
    if (was.version != version) {
      throw CommitteeFailure(
        CommitteeFailureKind.conflict,
        ids: <LumeRecordId>[id],
      );
    }
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const CommitteeFailure.validation('name', 'required');
    }
    if (trimmed.length > kCommitteeNameMax) {
      throw const CommitteeFailure.validation('name', 'long');
    }
    return d.putCommittee(
      was.copyWith(
        name: trimmed,
        note: _optional(note),
        clearNote: note == null,
      ),
      isNew: false,
    );
  });

  /// Rename a member, or change their note.
  CommitteeResult<CommitteeWrite> editMember(
    LumeRecordId id, {
    required String name,
    String? note,
    required int version,
  }) => _write<Committee>((_Data d) {
    CommitteeMember? was;
    for (final CommitteeMember m in d.members) {
      if (m.id == id) was = m;
    }
    if (was == null) {
      throw CommitteeFailure(
        CommitteeFailureKind.notFound,
        ids: <LumeRecordId>[id],
      );
    }
    d.sound(was.committeeId);
    if (was.version != version) {
      throw CommitteeFailure(
        CommitteeFailureKind.conflict,
        ids: <LumeRecordId>[id],
      );
    }
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const CommitteeFailure.validation('name', 'required');
    }
    if (trimmed.length > kCommitteeNameMax) {
      throw const CommitteeFailure.validation('name', 'long');
    }
    d.putMember(
      was.copyWith(
        name: trimmed,
        note: _optional(note),
        clearNote: note == null,
      ),
      isNew: false,
    );
    return d.committeeRecord(was.committeeId);
  });

  /// Change what the reader is in this committee, and which member they
  /// are, as one write (correction 2.2).
  ///
  /// [reader] is the member to mark, or `null` for an organiser who holds
  /// no share. A failure leaves the previous role and the previous reader
  /// both standing.
  CommitteeResult<CommitteeWrite> setReaderRole(
    LumeRecordId id, {
    required CommitteeReaderRole role,
    LumeRecordId? reader,
    required int version,
  }) => _write<Committee>((_Data d) {
    final Committee was = d.committeeRecord(id);
    final CommitteeView v = d.sound(id);
    if (was.version != version) {
      throw CommitteeFailure(
        CommitteeFailureKind.conflict,
        ids: <LumeRecordId>[id],
      );
    }
    final bool wantsOne = role != CommitteeReaderRole.organiser;
    if (wantsOne && reader == null) {
      throw const CommitteeFailure.validation('reader', 'required');
    }
    if (!wantsOne && reader != null) {
      throw const CommitteeFailure.validation('reader', 'notAMember');
    }
    if (reader != null && v.memberOf(reader) == null) {
      throw CommitteeFailure(
        CommitteeFailureKind.notFound,
        ids: <LumeRecordId>[reader],
      );
    }
    for (final CommitteeMemberView m in v.members) {
      final bool should = reader != null && m.member.id == reader;
      if (m.member.isReader != should) {
        d.putMember(m.member.copyWith(isReader: should), isNew: false);
      }
    }
    return d.putCommittee(was.copyWith(readerRole: role), isNew: false);
  });

  /// Record one member's contribution for one cycle — one record per share
  /// they hold, in one transaction (§6).
  CommitteeResult<CommitteeWrite> recordContribution(
    LumeRecordId committeeId,
    LumeRecordId cycleId,
    LumeRecordId memberId,
    LumeDate paidOn, {
    LumeDate? today,
    String? idempotencyKey,
  }) => _write<List<CommitteeContribution>>(
    (_Data d) {
      final Committee c = d.committeeRecord(committeeId);
      final CommitteeView v = d.sound(committeeId);
      if (c.cancelled) {
        throw CommitteeFailure(
          CommitteeFailureKind.cancelled,
          ids: <LumeRecordId>[committeeId],
        );
      }
      _checkPaidOn(paidOn, today);
      final CommitteeCycleView? cycle = v.cycleOf(cycleId);
      if (cycle == null) {
        throw CommitteeFailure(
          CommitteeFailureKind.notFound,
          ids: <LumeRecordId>[cycleId],
        );
      }
      final CommitteeMemberView? member = v.memberOf(memberId);
      if (member == null) {
        throw CommitteeFailure(
          CommitteeFailureKind.notFound,
          ids: <LumeRecordId>[memberId],
        );
      }
      final List<CommitteeContribution> made = <CommitteeContribution>[];
      final DateTime at = _now();
      for (final CommitteePosition p in member.positions) {
        final bool already = cycle.slots.any(
          (CommitteeSlot s) => s.position.id == p.id && s.paid,
        );
        if (already) {
          throw CommitteeFailure(
            CommitteeFailureKind.duplicate,
            ids: <LumeRecordId>[p.id],
          );
        }
        made.add(
          d.putContribution(
            CommitteeContribution(
              id: _newId(),
              committeeId: c.id,
              cycleId: cycleId,
              positionId: p.id,
              amount: c.contribution,
              paidOn: paidOn,
              createdAt: at,
            ),
            isNew: true,
          ),
        );
      }
      return made;
    },
    idempotencyKey: idempotencyKey,
    fingerprint: <String>[
      committeeId.value,
      cycleId.value,
      memberId.value,
      paidOn.toIso(),
    ].join('|'),
  );

  /// Void a contribution, or bring one back.
  CommitteeResult<CommitteeWrite> setContributionVoided(
    LumeRecordId id,
    bool voided, {
    required int version,
  }) => _write<List<CommitteeContribution>>((_Data d) {
    final CommitteeContribution was = d.contribution(id);
    final CommitteeView v = d.sound(was.committeeId);
    if (was.version != version) {
      throw CommitteeFailure(
        CommitteeFailureKind.conflict,
        ids: <LumeRecordId>[id],
      );
    }
    if (was.voided == voided) {
      return <CommitteeContribution>[was];
    }
    final CommitteeCycleView? cycle = v.cycleOf(was.cycleId);
    if (voided && cycle != null && cycle.paidOut) {
      // The payout would then be worth more than the cycle collected.
      throw CommitteeFailure(
        CommitteeFailureKind.paidOut,
        ids: <LumeRecordId>[cycle.payout!.id],
      );
    }
    if (!voided && cycle != null) {
      final bool taken = cycle.slots.any(
        (CommitteeSlot s) => s.position.id == was.positionId && s.paid,
      );
      if (taken) {
        throw CommitteeFailure(
          CommitteeFailureKind.duplicate,
          ids: <LumeRecordId>[was.positionId],
        );
      }
    }
    return <CommitteeContribution>[
      d.putContribution(
        was.withState(
          voided ? CommitteeEntryState.voided : CommitteeEntryState.active,
        ),
        isNew: false,
      ),
    ];
  });

  /// Record that a cycle's pool was handed to the position that holds it
  /// (§7). Only when that cycle is fully collected.
  CommitteeResult<CommitteeWrite> recordPayout(
    LumeRecordId committeeId,
    LumeRecordId cycleId,
    LumeDate paidOn, {
    LumeDate? today,
    String? idempotencyKey,
  }) => _write<CommitteePayout>(
    (_Data d) {
      final Committee c = d.committeeRecord(committeeId);
      final CommitteeView v = d.sound(committeeId);
      if (c.cancelled) {
        throw CommitteeFailure(
          CommitteeFailureKind.cancelled,
          ids: <LumeRecordId>[committeeId],
        );
      }
      _checkPaidOn(paidOn, today);
      final CommitteeCycleView? cycle = v.cycleOf(cycleId);
      if (cycle == null) {
        throw CommitteeFailure(
          CommitteeFailureKind.notFound,
          ids: <LumeRecordId>[cycleId],
        );
      }
      if (cycle.paidOut) {
        throw CommitteeFailure(
          CommitteeFailureKind.duplicate,
          ids: <LumeRecordId>[cycle.payout!.id],
        );
      }
      if (!cycle.complete) {
        throw CommitteeFailure(
          CommitteeFailureKind.incomplete,
          ids: <LumeRecordId>[cycleId],
          shortfall: cycle.short,
        );
      }
      return d.putPayout(
        CommitteePayout(
          id: _newId(),
          committeeId: c.id,
          cycleId: cycleId,
          positionId: cycle.recipient.id,
          amount: c.pool,
          paidOn: paidOn,
          createdAt: _now(),
        ),
        isNew: true,
      );
    },
    idempotencyKey: idempotencyKey,
    fingerprint: <String>[
      committeeId.value,
      cycleId.value,
      paidOn.toIso(),
    ].join('|'),
  );

  /// Void a payout, or bring one back. Only its own cycle changes
  /// (correction 2.4).
  CommitteeResult<CommitteeWrite> setPayoutVoided(
    LumeRecordId id,
    bool voided, {
    required int version,
  }) => _write<CommitteePayout>((_Data d) {
    final CommitteePayout was = d.payout(id);
    final CommitteeView v = d.sound(was.committeeId);
    if (was.version != version) {
      throw CommitteeFailure(
        CommitteeFailureKind.conflict,
        ids: <LumeRecordId>[id],
      );
    }
    if (was.voided == voided) return was;
    if (!voided) {
      final CommitteeCycleView? cycle = v.cycleOf(was.cycleId);
      if (cycle != null && cycle.paidOut) {
        throw CommitteeFailure(
          CommitteeFailureKind.duplicate,
          ids: <LumeRecordId>[cycle.payout!.id],
        );
      }
      if (cycle != null && !cycle.complete) {
        throw CommitteeFailure(
          CommitteeFailureKind.incomplete,
          ids: <LumeRecordId>[was.cycleId],
          shortfall: cycle.short,
        );
      }
    }
    return d.putPayout(
      was.withState(
        voided ? CommitteeEntryState.voided : CommitteeEntryState.active,
      ),
      isNew: false,
    );
  });

  /// Cancel a committee on [on], or reinstate it (D-C7).
  ///
  /// Cancelling writes the date and nothing else; reinstating clears it.
  /// No record is rewritten, and no refund is invented.
  CommitteeResult<CommitteeWrite> setCancelled(
    LumeRecordId id,
    bool cancelled, {
    LumeDate? on,
    required int version,
  }) => _write<Committee>((_Data d) {
    final Committee was = d.committeeRecord(id);
    d.sound(id);
    if (was.version != version) {
      throw CommitteeFailure(
        CommitteeFailureKind.conflict,
        ids: <LumeRecordId>[id],
      );
    }
    if (cancelled && on == null) {
      throw const CommitteeFailure.validation('cancelledOn', 'required');
    }
    return d.putCommittee(
      cancelled
          ? was.copyWith(cancelledOn: on)
          : was.copyWith(clearCancelled: true),
      isNew: false,
    );
  });

  /// Remove a committee and everything it owns, in one transaction.
  CommitteeResult<CommitteeWrite> deleteCommittee(
    LumeRecordId id, {
    required int version,
  }) => _write<Committee>((_Data d) {
    final Committee was = d.committeeRecord(id);
    if (was.version != version) {
      throw CommitteeFailure(
        CommitteeFailureKind.conflict,
        ids: <LumeRecordId>[id],
      );
    }
    d.removeCommittee(id, version);
    return was;
  });

  /// Take a committed write back.
  CommitteeResult<void> undo(CommitteeWrite write) {
    final LumeTxResult<void> r = _store.revert(write.receipt);
    return r.ok
        ? const CommitteeResult<void>.ok(null)
        : CommitteeResult<void>.failed(_map(r.failure!));
  }

  /// How many records a committee holds, for the delete confirmation.
  CommitteeCounts counts(LumeRecordId id) {
    final CommitteeSnapshot s = view();
    final String key = id.value;
    return CommitteeCounts(
      members: s.members
          .where((CommitteeMember x) => x.committeeId.value == key)
          .length,
      positions: s.positions
          .where((CommitteePosition x) => x.committeeId.value == key)
          .length,
      cycles: s.cycles
          .where((CommitteeCycle x) => x.committeeId.value == key)
          .length,
      contributions: s.contributions
          .where((CommitteeContribution x) => x.committeeId.value == key)
          .length,
      payouts: s.payouts
          .where((CommitteePayout x) => x.committeeId.value == key)
          .length,
    );
  }

  LumeRecordId _newId() => LumeRecordId.generate(_random);

  CommitteeResult<CommitteeWrite> _write<T>(
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
        } on CommitteeFailure catch (f) {
          tx.reject(f);
        } on CommitteeDefectException catch (e) {
          tx.reject(
            CommitteeFailure(CommitteeFailureKind.damaged, cause: e.defect),
          );
        } on LumeMoneyException catch (e) {
          tx.reject(CommitteeFailure(CommitteeFailureKind.overflow, cause: e));
        }
      },
      idempotencyKey: idempotencyKey,
      fingerprint: idempotencyKey == null ? null : fingerprint,
    );
    if (!r.ok) return CommitteeResult<CommitteeWrite>.failed(_map(r.failure!));
    final T v = r.value as T;
    return CommitteeResult<CommitteeWrite>.ok(
      CommitteeWrite(
        r.receipt!,
        committee: v is Committee ? v : null,
        contributions: v is List<CommitteeContribution>
            ? v
            : const <CommitteeContribution>[],
        payout: v is CommitteePayout ? v : null,
      ),
    );
  }

  /// Everything §7 asks, against the staged state, before anything is
  /// published. A broken rule, or damage this write would cause, rolls the
  /// whole write back.
  static void _verify(_Data d) {
    final CommitteeBook book = d.book();
    final List<String> broken = book.invariants();
    final List<CommitteeDamage> fresh = <CommitteeDamage>[
      for (final CommitteeDamage x in book.damage)
        if (!d.damagedBefore.contains(x.committee)) x,
    ];
    if (broken.isNotEmpty || fresh.isNotEmpty) {
      throw CommitteeFailure(
        CommitteeFailureKind.damaged,
        ids: <LumeRecordId>[
          for (final CommitteeDamage x in fresh)
            ?LumeRecordId.tryParse(x.committee),
        ],
        cause: <Object>[
          ...broken,
          for (final CommitteeDamage x in fresh) x.reason,
        ],
      );
    }
    // A figure that cannot be shown fails the write, not the screen.
    for (final LumeCurrency c in book.currencies) {
      book.summary(c);
    }
  }

  /// A payment never happened on a day that has not arrived
  /// (correction 2.3). Without the reader's day nothing is classified, and
  /// a valid date is taken as entered.
  static void _checkPaidOn(LumeDate paidOn, LumeDate? today) {
    if (today != null && paidOn.isAfter(today)) {
      throw const CommitteeFailure.validation('paidOn', 'future');
    }
  }

  static void _validate(CommitteeDraft draft) {
    if (draft.name.trim().isEmpty) {
      throw const CommitteeFailure.validation('name', 'required');
    }
    if (draft.name.trim().length > kCommitteeNameMax) {
      throw const CommitteeFailure.validation('name', 'long');
    }
    if ((draft.note ?? '').length > kCommitteeNoteMax) {
      throw const CommitteeFailure.validation('note', 'long');
    }
    if (!draft.contribution.isPositive) {
      throw const CommitteeFailure.validation('contribution', 'required');
    }
    final int n = draft.positions;
    if (n < kCommitteePositionsMin || n > kCommitteePositionsMax) {
      throw const CommitteeFailure.validation('positions', 'range');
    }
    // Checked by division, so nothing is multiplied past what it can hold.
    if (draft.contribution.minor > LumeMoney.maxEntryMinor ~/ n) {
      throw const CommitteeFailure.validation('contribution', 'overflow');
    }
    if (draft.contribution.minor > LumeMoney.maxSumMinor ~/ (n * n)) {
      throw const CommitteeFailure.validation('contribution', 'overflow');
    }
    // Every cycle 1..N belongs to exactly one share.
    final Set<int> held = <int>{};
    int readers = 0;
    for (final CommitteeMemberDraft m in draft.members) {
      if (m.name.trim().isEmpty) {
        throw const CommitteeFailure.validation('member', 'required');
      }
      if (m.name.trim().length > kCommitteeNameMax) {
        throw const CommitteeFailure.validation('member', 'long');
      }
      if (m.isReader) readers++;
      if (m.cycles.isEmpty) {
        throw const CommitteeFailure.validation('positions', 'none');
      }
      for (final int cycle in m.cycles) {
        if (cycle < 1 || cycle > n) {
          throw const CommitteeFailure.validation('positions', 'range');
        }
        if (!held.add(cycle)) {
          throw const CommitteeFailure.validation('positions', 'duplicate');
        }
      }
    }
    if (held.length != n) {
      throw const CommitteeFailure.validation('positions', 'incomplete');
    }
    final bool wantsOne = draft.readerRole != CommitteeReaderRole.organiser;
    if (wantsOne && readers != 1) {
      throw const CommitteeFailure.validation('reader', 'one');
    }
    if (!wantsOne && readers != 0) {
      throw const CommitteeFailure.validation('reader', 'none');
    }
  }

  static String? _optional(String? text) {
    final String t = (text ?? '').trim();
    return t.isEmpty ? null : t;
  }

  static CommitteeFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected => f.detail! as CommitteeFailure,
    LumeTxFailureKind.conflict ||
    LumeTxFailureKind.duplicateId => CommitteeFailure(
      CommitteeFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => CommitteeFailure(
      CommitteeFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => CommitteeFailure(
      CommitteeFailureKind.storage,
      cause: f.kind,
    ),
  };
}

/// How many records a committee holds, named for the confirmation that
/// says what deleting it would remove.
@immutable
class CommitteeCounts {
  const CommitteeCounts({
    required this.members,
    required this.positions,
    required this.cycles,
    required this.contributions,
    required this.payouts,
  });

  final int members;
  final int positions;
  final int cycles;
  final int contributions;
  final int payouts;

  /// The committee itself, and everything below it.
  int get total => 1 + members + positions + cycles + contributions + payouts;
}

/// The currency a new committee defaults to: the reader's, when it is one a
/// new obligation may use.
LumeCurrency? committeeDefaultCurrency(String code) {
  final LumeCurrency? c = LumeCurrency.tryOf(code);
  return c != null && LumeCurrencyPolicy.of(c).usable ? c : null;
}

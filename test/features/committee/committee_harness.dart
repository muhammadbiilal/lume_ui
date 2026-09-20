/// Committee over an in-memory store, a controllable clock and seeded ids
/// — deterministic, and never the wall clock.
///
/// The reference fixture, corrected: five members, one share each, five
/// cycles, Rs 28,300 a cycle (`COMMITTEE_PROPOSAL.md` §6, Example A).
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/committee/domain/committee_book.dart';
import 'package:lume/features/committee/domain/committee_failure.dart';
import 'package:lume/features/committee/domain/committee_model.dart';
import 'package:lume/features/committee/domain/committee_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_transaction.dart';

final LumeCurrency pkr = LumeCurrency.of('PKR');
final LumeCurrency usd = LumeCurrency.of('USD');
final LumeCurrency jpy = LumeCurrency.of('JPY');

/// Rupees, in paisa.
LumeMoney rs(num rupees) => LumeMoney.entry((rupees * 100).round(), pkr);

/// Dollars, in cents.
LumeMoney dollars(num d) => LumeMoney.entry((d * 100).round(), usd);

/// 2026 dates.
LumeDate d(int month, int day) => LumeDate(2026, month, day);

/// The fixture day: 7 September 2026.
final LumeDate kToday = d(9, 7);

/// The corrected reference committee's contribution: Rs 28,300.
final LumeMoney kContribution = rs(28300);

class CommitteeHarness {
  CommitteeHarness({int seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = CommitteeRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  late final LumeMemoryRecordRepository store;
  late final CommitteeRepository repo;
  DateTime clock = DateTime.utc(2026, 9, 7, 10);

  void tick([Duration by = const Duration(minutes: 1)]) =>
      clock = clock.add(by);

  CommitteeBook book([LumeDate? today]) => repo.view().book(today ?? kToday);

  /// The same records read with no day at all: nothing is late, due or
  /// upcoming, and nothing is guessed.
  CommitteeBook bookWithoutDay() => repo.view().book(null);

  CommitteeResult<CommitteeWrite> tryAdd({
    String name = 'Office committee',
    String? note,
    LumeMoney? contribution,
    LumeDate? firstDue,
    CommitteeReaderRole role = CommitteeReaderRole.member,
    List<CommitteeMemberDraft>? members,
    String? idempotencyKey,
  }) {
    tick();
    return repo.addCommittee(
      CommitteeDraft(
        name: name,
        note: note,
        contribution: contribution ?? kContribution,
        firstDue: firstDue ?? d(6, 7),
        readerRole: role,
        members: members ?? reference(),
      ),
      idempotencyKey: idempotencyKey,
    );
  }

  /// The corrected reference's members: Ahmed 1, Bilal 2, Sara 3, You 4,
  /// Hina 5.
  static List<CommitteeMemberDraft> reference() => <CommitteeMemberDraft>[
    const CommitteeMemberDraft(name: 'Ahmed', cycles: <int>[1]),
    const CommitteeMemberDraft(name: 'Bilal', cycles: <int>[2]),
    const CommitteeMemberDraft(name: 'Sara', cycles: <int>[3]),
    const CommitteeMemberDraft(name: 'You', isReader: true, cycles: <int>[4]),
    const CommitteeMemberDraft(name: 'Hina', cycles: <int>[5]),
  ];

  Committee add({
    String name = 'Office committee',
    String? note,
    LumeMoney? contribution,
    LumeDate? firstDue,
    CommitteeReaderRole role = CommitteeReaderRole.member,
    List<CommitteeMemberDraft>? members,
  }) {
    final CommitteeResult<CommitteeWrite> r = tryAdd(
      name: name,
      note: note,
      contribution: contribution,
      firstDue: firstDue,
      role: role,
      members: members,
    );
    expect(r.failure, isNull, reason: 'add $name');
    return r.value!.committee!;
  }

  CommitteeView view(LumeRecordId id, [LumeDate? today]) =>
      book(today).committee(id)!;

  CommitteeView viewWithoutDay(LumeRecordId id) =>
      bookWithoutDay().committee(id)!;

  CommitteeMemberView member(LumeRecordId committee, String name) => view(
    committee,
  ).members.firstWhere((CommitteeMemberView m) => m.name == name);

  CommitteeCycleView cycle(LumeRecordId committee, int n) =>
      view(committee).cycles.firstWhere((CommitteeCycleView c) => c.n == n);

  /// Record one member's contribution for a cycle, on the cycle's own day
  /// unless another is given.
  CommitteeResult<CommitteeWrite> pay(
    LumeRecordId committee,
    int cycleN,
    String memberName, {
    LumeDate? on,
    LumeDate? today,
    String? idempotencyKey,
  }) {
    final CommitteeCycleView c = cycle(committee, cycleN);
    tick();
    return repo.recordContribution(
      committee,
      c.cycle.id,
      member(committee, memberName).member.id,
      on ?? c.due,
      today: today,
      idempotencyKey: idempotencyKey,
    );
  }

  /// Every member pays the cycle.
  void collect(
    LumeRecordId committee,
    int cycleN, {
    Set<String> except = const <String>{},
  }) {
    for (final CommitteeMemberView m in view(committee).members) {
      if (except.contains(m.name)) continue;
      final CommitteeResult<CommitteeWrite> r = pay(committee, cycleN, m.name);
      expect(r.failure, isNull, reason: 'pay $cycleN ${m.name}');
    }
  }

  CommitteeResult<CommitteeWrite> payout(
    LumeRecordId committee,
    int cycleN, {
    LumeDate? on,
    LumeDate? today,
  }) {
    final CommitteeCycleView c = cycle(committee, cycleN);
    tick();
    return repo.recordPayout(committee, c.cycle.id, on ?? c.due, today: today);
  }

  /// A raw record, written as it is — for damaged-state tests.
  void raw(String collection, String id, Map<String, Object?> fields) {
    final LumeTxResult<void> r = store.run<void>(
      (LumeRecordTx tx) => tx.create(collection, id, fields),
    );
    expect(r.ok, isTrue);
  }

  void expectSound() {
    final CommitteeBook b = book();
    expect(b.invariants(), isEmpty, reason: 'invariants');
    expect(b.damage, isEmpty, reason: 'damage');
    expect(b.defects, isEmpty, reason: 'defects');
  }

  /// Just the stored records, without the dump's collection headings.
  List<String> recordLines() => records()
      .split('\n')
      .where((String l) => RegExp('^[0-9a-f-]{36} ').hasMatch(l))
      .toList();

  /// Every record, byte for byte, in id order and without the store's
  /// revision counters — which an Undo advances, as it should.
  String records() =>
      (store.debugDump().replaceAll(RegExp(r'\] r[0-9]+'), ']').split('\n')
            ..sort())
          .join('\n');

  void dispose() => store.dispose();
}

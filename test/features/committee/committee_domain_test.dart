/// Committee's rules, against the records themselves
/// (`COMMITTEE_PROPOSAL.md` §5–§10). Every worked example of §6 is here by
/// name, in minor units, with the figures the proposal states.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/committee/domain/committee_book.dart';
import 'package:lume/features/committee/domain/committee_failure.dart';
import 'package:lume/features/committee/domain/committee_model.dart';
import 'package:lume/features/committee/domain/committee_repository.dart';

import 'committee_harness.dart';

void main() {
  late CommitteeHarness h;

  setUp(() => h = CommitteeHarness());
  tearDown(() => h.dispose());

  group('creation and the stored schedule', () {
    test('one transaction writes the committee, its members, its positions '
        'and one cycle each', () {
      final Committee c = h.add();
      final CommitteeView v = h.view(c.id);
      expect(v.memberCount, 5);
      expect(v.positionCount, 5);
      expect(v.cycles, hasLength(5));
      expect(
        <int>[for (final CommitteeCycleView x in v.cycles) x.n],
        <int>[1, 2, 3, 4, 5],
      );
      // Every cycle has exactly one recipient, and every member receives.
      expect(
        <String>[
          for (final CommitteeCycleView x in v.cycles) x.recipientMember.name,
        ],
        <String>['Ahmed', 'Bilal', 'Sara', 'You', 'Hina'],
      );
      h.expectSound();
    });

    test('the dates come from the anchor, and are stored', () {
      final Committee c = h.add(firstDue: d(6, 7));
      expect(
        <String>[
          for (final CommitteeCycleView x in h.view(c.id).cycles) x.due.toIso(),
        ],
        <String>[
          '2026-06-07',
          '2026-07-07',
          '2026-08-07',
          '2026-09-07',
          '2026-10-07',
        ],
      );
    });

    test('31 January: February clamps and March does not drift', () {
      final Committee c = h.add(firstDue: LumeDate(2026, 1, 31));
      expect(
        <String>[
          for (final CommitteeCycleView x in h.view(c.id).cycles) x.due.toIso(),
        ],
        <String>[
          '2026-01-31',
          '2026-02-28',
          '2026-03-31',
          '2026-04-30',
          '2026-05-31',
        ],
      );
    });

    test('29 February 2028 anchors on 28 February 2029', () {
      final Committee c = h.add(firstDue: LumeDate(2028, 2, 29));
      final List<CommitteeCycleView> cycles = h.view(c.id).cycles;
      expect(cycles[0].due.toIso(), '2028-02-29');
      expect(cycles[1].due.toIso(), '2028-03-29');
      expect(
        h
            .add(
              name: 'Long',
              firstDue: LumeDate(2028, 2, 29),
              members: <CommitteeMemberDraft>[
                const CommitteeMemberDraft(
                  name: 'You',
                  isReader: true,
                  cycles: <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
                ),
                const CommitteeMemberDraft(name: 'Ali', cycles: <int>[13]),
              ],
            )
            .id
            .value
            .isNotEmpty,
        isTrue,
      );
      final CommitteeView long = h.book().committees.firstWhere(
        (CommitteeView v) => v.name == 'Long',
      );
      expect(long.cycles[12].due.toIso(), '2029-02-28');
    });

    test('a stored schedule is read back, never recomputed', () {
      final Committee c = h.add(firstDue: LumeDate(2026, 1, 31));
      final String before = h.records();
      h.collect(c.id, 1);
      expect(h.view(c.id).cycles[1].due.toIso(), '2026-02-28');
      // The cycle rows themselves are untouched by a contribution.
      expect(
        before.split('\n').where((String l) => l.contains('committee.cycle')),
        h
            .records()
            .split('\n')
            .where((String l) => l.contains('committee.cycle')),
      );
    });

    test('a refused draft writes nothing at all', () {
      // Cycle 5 held twice, cycle 4 not held at all.
      final CommitteeResult<CommitteeWrite> r = h.tryAdd(
        members: <CommitteeMemberDraft>[
          const CommitteeMemberDraft(name: 'Ahmed', cycles: <int>[1]),
          const CommitteeMemberDraft(name: 'Bilal', cycles: <int>[2]),
          const CommitteeMemberDraft(name: 'Sara', cycles: <int>[3]),
          const CommitteeMemberDraft(
            name: 'You',
            isReader: true,
            cycles: <int>[5],
          ),
          const CommitteeMemberDraft(name: 'Hina', cycles: <int>[5]),
        ],
      );
      expect(r.failure!.kind, CommitteeFailureKind.validation);
      expect(r.failure!.field, 'positions');
      expect(h.book().isEmpty, isTrue);
      expect(h.recordLines(), isEmpty);
    });

    test('two positions and two cycles fewer than two are refused', () {
      expect(
        h
            .tryAdd(
              members: <CommitteeMemberDraft>[
                const CommitteeMemberDraft(
                  name: 'You',
                  isReader: true,
                  cycles: <int>[1],
                ),
              ],
            )
            .failure!
            .field,
        'positions',
      );
    });
  });

  group('Example A — the corrected reference', () {
    test('pool, total and every figure, in minor units', () {
      final Committee c = h.add();
      final CommitteeView v = h.view(c.id);
      expect(v.contribution.minor, 2830000);
      expect(v.pool.minor, 14150000);
      expect(v.expectedTotal.minor, 70750000);
      // Not the reference's Rs 142,000.
      expect(v.pool.minor, isNot(14200000));

      for (int n = 1; n <= 4; n++) {
        h.collect(c.id, n);
      }
      final CommitteeView after = h.view(c.id);
      expect(after.collected.minor, 56600000);
      expect(after.dueToCutoff!.minor, 56600000);
      expect(after.outstanding!.minor, 0);

      for (int n = 1; n <= 3; n++) {
        expect(h.payout(c.id, n).failure, isNull);
      }
      expect(h.view(c.id).paidOut.minor, 42450000);
      expect(h.view(c.id).held.minor, 14150000);
      h.expectSound();
    });

    test('every position pays in one pool and receives one pool; the '
        'committee nets to nothing', () {
      final Committee c = h.add();
      for (int n = 1; n <= 5; n++) {
        h.collect(c.id, n);
        expect(h.payout(c.id, n).failure, isNull);
      }
      final CommitteeView v = h.view(c.id);
      expect(v.collected.minor, 70750000);
      expect(v.paidOut.minor, 70750000);
      expect(v.held.minor, 0);
      for (final CommitteeMemberView m in v.members) {
        expect(m.paid.minor, 14150000, reason: m.name);
        expect(m.received.minor, 14150000, reason: m.name);
      }
      expect(v.readerNet.minor, 0);
      expect(v.status, CommitteeStatus.completed);
      h.expectSound();
    });
  });

  group('Example B — one missed contribution', () {
    test('collected falls by one share and outstanding names it', () {
      final Committee c = h.add();
      for (int n = 1; n <= 4; n++) {
        h.collect(c.id, n, except: n == 3 ? <String>{'Hina'} : <String>{});
      }
      final CommitteeView v = h.view(c.id);
      expect(v.collected.minor, 53770000);
      expect(v.outstanding!.minor, 2830000);
      expect(v.outstandingIsFinal, isFalse);
      final CommitteeCycleView three = h.cycle(c.id, 3);
      expect(three.collected.minor, 11320000);
      expect(three.short.minor, 2830000);
      expect(three.payoutStatus, CommitteeCyclePayoutStatus.waiting);
      expect(
        three.slots
            .where((CommitteeSlot s) => s.status == CommitteeSlotStatus.late)
            .length,
        1,
      );
      h.expectSound();
    });
  });

  group('Example C — one member, two positions', () {
    test('four people, five shares, and the member nets to nothing', () {
      final Committee c = h.add(
        members: <CommitteeMemberDraft>[
          const CommitteeMemberDraft(name: 'Ahmed', cycles: <int>[1]),
          const CommitteeMemberDraft(
            name: 'You',
            isReader: true,
            cycles: <int>[2, 4],
          ),
          const CommitteeMemberDraft(name: 'Bilal', cycles: <int>[3]),
          const CommitteeMemberDraft(name: 'Hina', cycles: <int>[5]),
        ],
      );
      final CommitteeView v = h.view(c.id);
      expect(v.memberCount, 4, reason: 'people');
      expect(v.positionCount, 5, reason: 'shares');
      expect(v.pool.minor, 14150000);
      final CommitteeMemberView me = h.member(c.id, 'You');
      expect(me.shares, 2);
      expect(me.turns, <int>[2, 4]);
      expect(me.expected.minor, 28300000);
      expect(v.readerPerCycle.minor, 5660000);

      // One action, two records: both shares are recorded together.
      final CommitteeResult<CommitteeWrite> r = h.pay(c.id, 1, 'You');
      expect(r.failure, isNull);
      expect(r.value!.contributions, hasLength(2));
      expect(h.cycle(c.id, 1).collected.minor, 5660000);

      h.collect(c.id, 1, except: <String>{'You'});
      expect(h.payout(c.id, 1).failure, isNull);
      for (int n = 2; n <= 5; n++) {
        h.collect(c.id, n);
        expect(h.payout(c.id, n).failure, isNull);
      }
      final CommitteeMemberView done = h.member(c.id, 'You');
      expect(done.paid.minor, 28300000);
      expect(done.received.minor, 28300000);
      expect(h.view(c.id).readerNet.minor, 0);
      h.expectSound();
    });
  });

  group('Example D — a payout before the cycle is collected', () {
    test('refused, with the shortfall, and nothing written', () {
      final Committee c = h.add();
      h.collect(c.id, 4, except: <String>{'Hina', 'Sara'});
      expect(h.cycle(c.id, 4).collected.minor, 8490000);
      final String before = h.records();
      final CommitteeResult<CommitteeWrite> r = h.payout(c.id, 4);
      expect(r.failure!.kind, CommitteeFailureKind.incomplete);
      expect(r.failure!.shortfall!.minor, 5660000);
      expect(h.records(), before);
      expect(h.view(c.id).paidOut.minor, 0);
    });
  });

  group('Example E — a part payment', () {
    test('a contribution is always one whole share', () {
      final Committee c = h.add();
      // There is no way to ask for a part payment: the amount is the
      // committee's own. What is stored is the whole share, every time.
      h.collect(c.id, 1);
      for (final CommitteeContribution x in h.view(c.id).contributions) {
        expect(x.amount.minor, 2830000);
      }
      // A stored part payment is damage, not a part-paid state.
      final CommitteeCycleView one = h.cycle(c.id, 1);
      h.raw(
        CommitteeCollections.contributions,
        LumeRecordId.generate().value,
        <String, Object?>{
          'schema': kCommitteeSchema,
          'committee': c.id.value,
          'cycle': one.cycle.id.value,
          'position': one.slots.first.position.id.value,
          'amountMinor': 2000000,
          'currency': 'PKR',
          'paidOn': '2026-06-07',
          'state': 'active',
        },
      );
      expect(
        h.book().damage.map((CommitteeDamage x) => x.reason),
        contains('contribution'),
      );
    });
  });

  group('Examples F and G — cancellation and Reinstate', () {
    test('the cutoff decides what was owed, and nothing keeps growing', () {
      final Committee c = h.add();
      for (int n = 1; n <= 4; n++) {
        h.collect(c.id, n, except: n == 3 ? <String>{'Hina'} : <String>{});
      }
      expect(h.payout(c.id, 1).failure, isNull);
      expect(h.payout(c.id, 2).failure, isNull);

      final CommitteeResult<CommitteeWrite> r = h.repo.setCancelled(
        c.id,
        true,
        on: d(9, 8),
        version: h.view(c.id).committee.version,
      );
      expect(r.failure, isNull);

      final CommitteeView v = h.view(c.id);
      expect(v.status, CommitteeStatus.cancelled);
      expect(v.committee.cancelledOn, d(9, 8));
      expect(v.collected.minor, 53770000);
      expect(v.paidOut.minor, 28300000);
      expect(v.held.minor, 25470000, reason: 'collected, not paid out');
      expect(v.dueToCutoff!.minor, 56600000);
      expect(v.outstanding!.minor, 2830000, reason: 'unpaid at cancellation');
      expect(v.outstandingIsFinal, isTrue);

      // Cycle 5 was due after the cutoff: it never raised an obligation.
      expect(
        h.cycle(c.id, 5).slots.map((CommitteeSlot s) => s.status),
        everyElement(CommitteeSlotStatus.notDue),
      );
      // Hina's cycle-3 gap is unpaid at cancellation, not a late payment.
      expect(
        h
            .cycle(c.id, 3)
            .slots
            .where((CommitteeSlot s) => !s.paid)
            .map((CommitteeSlot s) => s.status),
        everyElement(CommitteeSlotStatus.unpaidAtCancellation),
      );
      // Read far in the future: a cancelled committee's figures do not move.
      expect(h.view(c.id, LumeDate(2030, 1, 1)).outstanding!.minor, 2830000);
      h.expectSound();
    });

    test('Reinstate clears the date and derives the states again; every id '
        'and version survives', () {
      final Committee c = h.add();
      for (int n = 1; n <= 4; n++) {
        h.collect(c.id, n, except: n == 3 ? <String>{'Hina'} : <String>{});
      }
      expect(h.payout(c.id, 1).failure, isNull);
      expect(h.payout(c.id, 2).failure, isNull);
      // Everything but the committee record itself, which is the only
      // record cancelling and reinstating may touch.
      List<String> others() => h
          .recordLines()
          .where((String l) => !l.startsWith(c.id.value))
          .toList();
      final List<String> before = others();

      expect(
        h.repo
            .setCancelled(
              c.id,
              true,
              on: d(9, 8),
              version: h.view(c.id).committee.version,
            )
            .failure,
        isNull,
      );
      expect(
        h.repo
            .setCancelled(c.id, false, version: h.view(c.id).committee.version)
            .failure,
        isNull,
      );

      // Every record but the committee's own is byte-identical.
      expect(others(), before);
      final CommitteeView v = h.view(c.id, LumeDate(2026, 10, 9));
      expect(v.committee.cancelledOn, isNull);
      expect(v.status, CommitteeStatus.active);
      // Cycle 5 is due again, and the old gap is late again.
      expect(v.dueToCutoff!.minor, 70750000);
      expect(v.outstanding!.minor, 16980000);
      expect(v.outstandingIsFinal, isFalse);
      expect(v.paidOut.minor, 28300000);
      expect(h.cycle(c.id, 4).payoutStatus, CommitteeCyclePayoutStatus.ready);
      expect(h.cycle(c.id, 3).payoutStatus, CommitteeCyclePayoutStatus.waiting);
      h.expectSound();
    });

    test('a cancelled committee takes no new contribution or payout', () {
      final Committee c = h.add();
      h.collect(c.id, 1);
      expect(
        h.repo
            .setCancelled(
              c.id,
              true,
              on: d(9, 8),
              version: h.view(c.id).committee.version,
            )
            .failure,
        isNull,
      );
      expect(
        h.pay(c.id, 2, 'Ahmed').failure!.kind,
        CommitteeFailureKind.cancelled,
      );
      expect(h.payout(c.id, 1).failure!.kind, CommitteeFailureKind.cancelled);
    });
  });

  group('Example H — a payment date is never in the future', () {
    test('an upcoming cycle may be paid early, on the day it was paid', () {
      final Committee c = h.add();
      // Cycle 5 falls due 7 October; today is 7 September.
      final CommitteeResult<CommitteeWrite> early = h.pay(
        c.id,
        5,
        'Ahmed',
        on: kToday,
        today: kToday,
      );
      expect(early.failure, isNull);
      expect(early.value!.contributions.single.paidOn, kToday);
      expect(
        h.cycle(c.id, 5).slots.firstWhere((CommitteeSlot s) => s.paid).status,
        CommitteeSlotStatus.paid,
      );
    });

    test('a paidOn after the reader\'s day is refused on the field', () {
      final Committee c = h.add();
      final CommitteeResult<CommitteeWrite> r = h.pay(
        c.id,
        5,
        'Ahmed',
        on: d(10, 7),
        today: kToday,
      );
      expect(r.failure!.kind, CommitteeFailureKind.validation);
      expect(r.failure!.field, 'paidOn');
      expect(r.failure!.reason, 'future');
      expect(h.view(c.id).collected.minor, 0);
    });

    test('backdating is allowed', () {
      final Committee c = h.add();
      final CommitteeResult<CommitteeWrite> r = h.pay(
        c.id,
        1,
        'Ahmed',
        on: d(6, 1),
        today: kToday,
      );
      expect(r.failure, isNull);
      expect(r.value!.contributions.single.paidOn, d(6, 1));
    });

    test('without the reader\'s day an entered date is taken as entered', () {
      final Committee c = h.add();
      final CommitteeResult<CommitteeWrite> r = h.pay(
        c.id,
        5,
        'Ahmed',
        on: d(12, 25),
      );
      expect(r.failure, isNull);
      expect(r.value!.contributions.single.paidOn, d(12, 25));
    });

    test('a payout carries the same rule', () {
      final Committee c = h.add();
      h.collect(c.id, 1);
      final CommitteeResult<CommitteeWrite> r = h.payout(
        c.id,
        1,
        on: d(10, 1),
        today: kToday,
      );
      expect(r.failure!.field, 'paidOn');
      expect(h.view(c.id).paidOut.minor, 0);
    });
  });

  group('Example I — void and restore', () {
    test('voiding a contribution moves collected and outstanding, and a '
        'restore puts every figure back', () {
      final Committee c = h.add();
      for (int n = 1; n <= 4; n++) {
        h.collect(c.id, n);
      }
      expect(h.cycle(c.id, 4).collected.minor, 14150000);
      expect(h.view(c.id).outstanding!.minor, 0);
      final CommitteeContribution bilal = h
          .cycle(c.id, 4)
          .slots
          .firstWhere(
            (CommitteeSlot s) =>
                h.view(c.id).memberOf(s.position.memberId)!.name == 'Bilal',
          )
          .contribution!;

      expect(
        h.repo
            .setContributionVoided(bilal.id, true, version: bilal.version)
            .failure,
        isNull,
      );
      expect(h.cycle(c.id, 4).collected.minor, 11320000);
      expect(h.view(c.id).outstanding!.minor, 2830000);

      final CommitteeContribution voided = h
          .view(c.id)
          .contributions
          .firstWhere((CommitteeContribution x) => x.id == bilal.id);
      expect(
        h.repo
            .setContributionVoided(voided.id, false, version: voided.version)
            .failure,
        isNull,
      );
      expect(h.cycle(c.id, 4).collected.minor, 14150000);
      expect(h.view(c.id).outstanding!.minor, 0);
      h.expectSound();
    });

    test('a contribution under an active payout cannot be voided until the '
        'payout is', () {
      final Committee c = h.add();
      h.collect(c.id, 1);
      expect(h.payout(c.id, 1).failure, isNull);
      final CommitteeContribution x = h
          .cycle(c.id, 1)
          .slots
          .first
          .contribution!;
      final CommitteeResult<CommitteeWrite> r = h.repo.setContributionVoided(
        x.id,
        true,
        version: x.version,
      );
      expect(r.failure!.kind, CommitteeFailureKind.paidOut);
      expect(h.cycle(c.id, 1).collected.minor, 14150000);

      final CommitteePayout o = h.cycle(c.id, 1).payout!;
      expect(
        h.repo.setPayoutVoided(o.id, true, version: o.version).failure,
        isNull,
      );
      expect(
        h.repo.setContributionVoided(x.id, true, version: x.version).failure,
        isNull,
      );
      h.expectSound();
    });

    test('a second contribution for one slot is refused', () {
      final Committee c = h.add();
      expect(h.pay(c.id, 1, 'Ahmed').failure, isNull);
      expect(
        h.pay(c.id, 1, 'Ahmed').failure!.kind,
        CommitteeFailureKind.duplicate,
      );
      expect(h.cycle(c.id, 1).collected.minor, 2830000);
    });
  });

  group('Example J — payouts recorded out of order', () {
    test('a later cycle may be paid out first, and the earlier one is '
        'untouched', () {
      final Committee c = h.add();
      h.collect(c.id, 1);
      h.collect(c.id, 2);
      h.collect(c.id, 3, except: <String>{'Hina'});
      h.collect(c.id, 4);
      expect(h.payout(c.id, 1).failure, isNull);
      expect(h.payout(c.id, 2).failure, isNull);

      // Cycle 4 is complete; cycle 3 is not. Order is the reader's.
      expect(h.payout(c.id, 4).failure, isNull);
      expect(h.view(c.id).paidOut.minor, 42450000);
      final CommitteeCycleView three = h.cycle(c.id, 3);
      expect(three.paidOut, isFalse);
      expect(three.payoutStatus, CommitteeCyclePayoutStatus.waiting);
      expect(three.collected.minor, 11320000);
      expect(three.recipientMember.name, 'Sara');

      // Hina pays; cycle 3 becomes ready and can then be recorded.
      expect(h.pay(c.id, 3, 'Hina').failure, isNull);
      expect(h.cycle(c.id, 3).payoutStatus, CommitteeCyclePayoutStatus.ready);
      expect(h.payout(c.id, 3).failure, isNull);
      expect(h.view(c.id).paidOut.minor, 56600000);

      // Voiding cycle 4's payout touches only cycle 4.
      final CommitteePayout four = h.cycle(c.id, 4).payout!;
      expect(
        h.repo.setPayoutVoided(four.id, true, version: four.version).failure,
        isNull,
      );
      expect(h.cycle(c.id, 4).payoutStatus, CommitteeCyclePayoutStatus.ready);
      expect(h.cycle(c.id, 3).paidOut, isTrue);
      expect(h.cycle(c.id, 1).paidOut, isTrue);
      h.expectSound();
    });

    test('the recipient is the position that holds the cycle, and a second '
        'payout is refused', () {
      final Committee c = h.add();
      h.collect(c.id, 3);
      final CommitteeResult<CommitteeWrite> r = h.payout(c.id, 3);
      expect(r.failure, isNull);
      expect(r.value!.payout!.positionId, h.cycle(c.id, 3).recipient.id);
      expect(r.value!.payout!.amount.minor, 14150000);
      expect(h.payout(c.id, 3).failure!.kind, CommitteeFailureKind.duplicate);
    });
  });

  group('the reader\'s day', () {
    test('without it nothing is late, due or upcoming, and outstanding is '
        'unknown', () {
      final Committee c = h.add();
      h.collect(c.id, 1);
      final CommitteeView v = h.viewWithoutDay(c.id);
      expect(v.outstanding, isNull);
      expect(v.dueToCutoff, isNull);
      expect(v.current(null), isNull);
      expect(
        v.cycles[1].slots.map((CommitteeSlot s) => s.status),
        everyElement(CommitteeSlotStatus.unknown),
      );
      // What is recorded is still known.
      expect(v.collected.minor, 14150000);
      expect(h.bookWithoutDay().dayKnown, isFalse);
      expect(h.bookWithoutDay().summary(pkr).outstanding, isNull);
    });

    test('late begins the day after due; there is no grace', () {
      final Committee c = h.add(firstDue: d(9, 7));
      // Cycle 1 falls due today.
      expect(h.cycle(c.id, 1).slots.first.status, CommitteeSlotStatus.dueToday);
      expect(
        h.view(c.id, d(9, 8)).cycles.first.slots.first.status,
        CommitteeSlotStatus.late,
      );
      expect(
        h.view(c.id, d(9, 6)).cycles.first.slots.first.status,
        CommitteeSlotStatus.upcoming,
      );
    });

    test('the current cycle is the latest due on or before the day', () {
      final Committee c = h.add(firstDue: d(6, 7));
      expect(h.view(c.id).current(kToday)!.n, 4);
      expect(h.view(c.id, d(6, 1)).current(d(6, 1))!.n, 1);
      expect(h.view(c.id, d(12, 1)).current(d(12, 1))!.n, 5);
    });
  });

  group('the reader\'s role', () {
    test('member needs exactly one reader; organiser needs none', () {
      expect(
        h
            .tryAdd(
              role: CommitteeReaderRole.organiser,
              members: CommitteeHarness.reference(),
            )
            .failure!
            .field,
        'reader',
      );
      final Committee c = h.add(
        role: CommitteeReaderRole.organiser,
        members: <CommitteeMemberDraft>[
          const CommitteeMemberDraft(name: 'Ahmed', cycles: <int>[1]),
          const CommitteeMemberDraft(name: 'Bilal', cycles: <int>[2]),
        ],
      );
      final CommitteeView v = h.view(c.id);
      expect(v.reader, isNull);
      expect(v.readerNet.minor, 0);
      h.expectSound();
    });

    test('two readers are refused at the door', () {
      expect(
        h
            .tryAdd(
              members: <CommitteeMemberDraft>[
                const CommitteeMemberDraft(
                  name: 'You',
                  isReader: true,
                  cycles: <int>[1],
                ),
                const CommitteeMemberDraft(
                  name: 'Me',
                  isReader: true,
                  cycles: <int>[2],
                ),
              ],
            )
            .failure!
            .field,
        'reader',
      );
    });

    test('moving the reader to another member is one write', () {
      final Committee c = h.add();
      final CommitteeMemberView sara = h.member(c.id, 'Sara');
      expect(
        h.repo
            .setReaderRole(
              c.id,
              role: CommitteeReaderRole.organiserMember,
              reader: sara.member.id,
              version: h.view(c.id).committee.version,
            )
            .failure,
        isNull,
      );
      final CommitteeView v = h.view(c.id);
      expect(v.reader!.name, 'Sara');
      expect(
        v.members.where((CommitteeMemberView m) => m.isReader),
        hasLength(1),
      );
      expect(v.committee.readerRole, CommitteeReaderRole.organiserMember);
      h.expectSound();
    });

    test('a role change that would leave no reader is refused, and both the '
        'role and the reader stand', () {
      final Committee c = h.add();
      final String before = h.records();
      final CommitteeResult<CommitteeWrite> r = h.repo.setReaderRole(
        c.id,
        role: CommitteeReaderRole.organiser,
        reader: h.member(c.id, 'You').member.id,
        version: h.view(c.id).committee.version,
      );
      expect(r.failure!.kind, CommitteeFailureKind.validation);
      expect(h.records(), before);
      expect(h.view(c.id).reader!.name, 'You');
      expect(h.view(c.id).committee.readerRole, CommitteeReaderRole.member);
    });

    test('a stored committee whose role and flag disagree is damaged', () {
      final Committee c = h.add();
      final CommitteeMemberView me = h.member(c.id, 'You');
      final CommitteeResult<CommitteeWrite> r = h.repo.editMember(
        me.member.id,
        name: 'You',
        version: me.member.version,
      );
      expect(r.failure, isNull);
      // Force the flag off behind the model's back.
      h.store.run<void>(
        (tx) => tx.update(
          CommitteeCollections.members,
          me.member.id.value,
          <String, Object?>{...me.member.toFields(), 'isReader': false},
          expectVersion: h.member(c.id, 'You').member.version,
        ),
      );
      expect(
        h.book().damage.map((CommitteeDamage x) => x.reason),
        contains('readerRole'),
      );
    });
  });

  group('editing, locking and deletion', () {
    test('the name and the note stay editable; the terms never change', () {
      final Committee c = h.add();
      h.collect(c.id, 1);
      expect(
        h.repo
            .editCommittee(
              c.id,
              name: 'Street kameti',
              note: 'Fridays',
              version: h.view(c.id).committee.version,
            )
            .failure,
        isNull,
      );
      final CommitteeView v = h.view(c.id);
      expect(v.name, 'Street kameti');
      expect(v.committee.note, 'Fridays');
      expect(v.contribution.minor, 2830000);
      expect(v.positionCount, 5);
      expect(v.committee.firstDue, d(6, 7));
    });

    test('before anything financial, the terms and the order can be '
        'rebuilt — new shares, new cycles, one write', () {
      final Committee c = h.add();
      final CommitteeResult<CommitteeWrite> r = h.repo.editTerms(
        c.id,
        CommitteeDraft(
          name: 'Office committee',
          contribution: rs(30000),
          firstDue: d(7, 1),
          members: <CommitteeMemberDraft>[
            const CommitteeMemberDraft(
              name: 'You',
              isReader: true,
              cycles: <int>[1, 3],
            ),
            const CommitteeMemberDraft(name: 'Sara', cycles: <int>[2]),
          ],
        ),
        version: h.view(c.id).committee.version,
      );
      expect(r.failure, isNull);
      final CommitteeView v = h.view(c.id);
      expect(v.positionCount, 3);
      expect(v.memberCount, 2);
      expect(v.cycles, hasLength(3));
      expect(v.contribution.minor, 3000000);
      expect(v.pool.minor, 9000000);
      expect(v.cycles.first.due, d(7, 1));
      expect(h.member(c.id, 'You').turns, <int>[1, 3]);
      // The old members and cycles are gone, not left behind.
      expect(h.recordLines(), hasLength(1 + 2 + 3 + 3));
      h.expectSound();
    });

    test('once a contribution exists the terms are locked, and the refusal '
        'names one', () {
      final Committee c = h.add();
      h.collect(c.id, 1);
      final String before = h.records();
      final CommitteeResult<CommitteeWrite> r = h.repo.editTerms(
        c.id,
        CommitteeDraft(
          name: 'Office committee',
          contribution: rs(30000),
          firstDue: d(7, 1),
          members: CommitteeHarness.reference(),
        ),
        version: h.view(c.id).committee.version,
      );
      expect(r.failure!.kind, CommitteeFailureKind.locked);
      expect(r.failure!.field, 'contribution');
      expect(h.records(), before);
    });

    test('a voided contribution locks the terms too', () {
      final Committee c = h.add();
      final CommitteeResult<CommitteeWrite> paid = h.pay(c.id, 1, 'Ahmed');
      final CommitteeContribution x = paid.value!.contributions.single;
      expect(
        h.repo.setContributionVoided(x.id, true, version: x.version).failure,
        isNull,
      );
      expect(
        h.repo
            .editTerms(
              c.id,
              CommitteeDraft(
                name: 'Office committee',
                contribution: rs(30000),
                firstDue: d(7, 1),
                members: CommitteeHarness.reference(),
              ),
              version: h.view(c.id).committee.version,
            )
            .failure!
            .kind,
        CommitteeFailureKind.locked,
      );
    });

    test('a stale version is a conflict, and nothing is written', () {
      final Committee c = h.add();
      final String before = h.records();
      final CommitteeResult<CommitteeWrite> r = h.repo.editCommittee(
        c.id,
        name: 'Other',
        version: 99,
      );
      expect(r.failure!.kind, CommitteeFailureKind.conflict);
      expect(h.records(), before);
    });

    test('delete removes the committee and everything it owns; Undo brings '
        'back the same ids and versions', () {
      final Committee c = h.add();
      h.collect(c.id, 1);
      expect(h.payout(c.id, 1).failure, isNull);
      final CommitteeCounts counts = h.repo.counts(c.id);
      expect(counts.members, 5);
      expect(counts.positions, 5);
      expect(counts.cycles, 5);
      expect(counts.contributions, 5);
      expect(counts.payouts, 1);
      expect(counts.total, 22);

      final String before = h.records();
      final CommitteeResult<CommitteeWrite> r = h.repo.deleteCommittee(
        c.id,
        version: h.view(c.id).committee.version,
      );
      expect(r.failure, isNull);
      expect(h.book().isEmpty, isTrue);
      expect(h.recordLines(), isEmpty, reason: 'no orphans left behind');

      expect(h.repo.undo(r.value!).failure, isNull);
      expect(h.records(), before);
      h.expectSound();
    });

    test('a failure part-way through a delete publishes none of it', () {
      final Committee c = h.add();
      h.collect(c.id, 1);
      final String before = h.records();
      // The store fails part-way through what the delete publishes.
      h.store.publishFault = (_, int i) {
        if (i == 3) throw StateError('disk');
      };
      final CommitteeResult<CommitteeWrite> r = h.repo.deleteCommittee(
        c.id,
        version: h.view(c.id).committee.version,
      );
      expect(r.failure!.kind, CommitteeFailureKind.storage);
      h.store.publishFault = null;
      expect(h.records(), before);
      h.expectSound();
    });

    test('a failure part-way through creation publishes nothing', () {
      h.store.publishFault = (_, int i) {
        if (i == 9) throw StateError('disk');
      };
      final CommitteeResult<CommitteeWrite> r = h.tryAdd();
      expect(r.failure!.kind, CommitteeFailureKind.storage);
      h.store.publishFault = null;
      expect(h.recordLines(), isEmpty);
      expect(h.book().isEmpty, isTrue);
    });
  });

  group('transactions', () {
    test('a retried create with the same key writes one committee', () {
      final CommitteeResult<CommitteeWrite> a = h.tryAdd(
        idempotencyKey: 'once',
      );
      final CommitteeResult<CommitteeWrite> b = h.tryAdd(
        idempotencyKey: 'once',
      );
      expect(a.failure, isNull);
      expect(b.failure, isNull);
      expect(b.value!.receipt.replayed, isTrue);
      expect(h.book().committees, hasLength(1));
    });

    test('a retried contribution with the same key writes one record', () {
      final Committee c = h.add();
      expect(h.pay(c.id, 1, 'Ahmed', idempotencyKey: 'k').failure, isNull);
      expect(h.pay(c.id, 1, 'Ahmed', idempotencyKey: 'k').failure, isNull);
      expect(h.cycle(c.id, 1).collected.minor, 2830000);
      expect(h.view(c.id).contributions, hasLength(1));
    });

    test('a store that refuses writes gives a typed failure and writes '
        'nothing', () {
      h.store.refuseWrites = true;
      final CommitteeResult<CommitteeWrite> r = h.tryAdd();
      expect(r.failure!.kind, CommitteeFailureKind.storage);
      h.store.refuseWrites = false;
      expect(h.book().isEmpty, isTrue);
    });
  });

  group('currencies and bounds', () {
    test('summaries are per currency, and never added across them', () {
      h.add();
      h.add(
        name: 'Dollar circle',
        contribution: dollars(100),
        members: <CommitteeMemberDraft>[
          const CommitteeMemberDraft(
            name: 'Ann',
            isReader: true,
            cycles: <int>[1],
          ),
          const CommitteeMemberDraft(name: 'Ben', cycles: <int>[2]),
        ],
      );
      final CommitteeBook b = h.book();
      expect(b.currencies.map((c) => c.code), <String>['PKR', 'USD']);
      expect(b.summary(pkr).running, 1);
      expect(b.summary(usd).running, 1);
      expect(b.summary(usd).collected.currency, usd);
    });

    test('a contribution that would overflow the committee is refused', () {
      final CommitteeResult<CommitteeWrite> r = h.tryAdd(
        contribution: LumeMoney.entry(LumeMoney.maxEntryMinor, pkr),
      );
      expect(r.failure!.kind, CommitteeFailureKind.validation);
      expect(r.failure!.reason, 'overflow');
      expect(h.recordLines(), isEmpty);
    });

    test('the largest contribution N = 120 allows is accepted, and one more '
        'paisa is not', () {
      final List<CommitteeMemberDraft> many = <CommitteeMemberDraft>[
        CommitteeMemberDraft(
          name: 'You',
          isReader: true,
          cycles: <int>[for (int i = 1; i <= 119; i++) i],
        ),
        const CommitteeMemberDraft(name: 'Ali', cycles: <int>[120]),
      ];
      const int most = 625499948245;
      expect(
        h
            .tryAdd(contribution: LumeMoney.entry(most, pkr), members: many)
            .failure,
        isNull,
      );
      expect(
        h
            .tryAdd(
              name: 'Too big',
              contribution: LumeMoney.entry(most + 1, pkr),
              members: many,
            )
            .failure!
            .reason,
        'overflow',
      );
    });
  });

  group('stored damage', () {
    test('a record that cannot be read is a defect; its committee leaves '
        'the totals and is not written over', () {
      final Committee c = h.add();
      h.collect(c.id, 1);
      final CommitteeCycleView one = h.cycle(c.id, 1);
      h.store.run<void>(
        (tx) => tx.update(
          CommitteeCollections.cycles,
          one.cycle.id.value,
          <String, Object?>{...one.cycle.toFields(), 'due': 'the seventh'},
          expectVersion: one.cycle.version,
        ),
      );
      final CommitteeBook b = h.book();
      expect(b.defects.single.field, 'due');
      expect(b.defects.single.reason, 'date');
      expect(b.damage.map((CommitteeDamage x) => x.reason), isNotEmpty);
      // An ordinary write refuses to touch it.
      expect(
        h.pay(c.id, 2, 'Ahmed').failure!.kind,
        CommitteeFailureKind.damaged,
      );
      // Deleting it is still allowed.
      expect(
        h.repo
            .deleteCommittee(
              c.id,
              version: h.book().committees.first.committee.version,
            )
            .failure,
        isNull,
      );
    });

    test('an unsupported frequency is reported, not read as monthly', () {
      final Committee c = h.add();
      h.store.run<void>(
        (tx) => tx.update(
          CommitteeCollections.committees,
          c.id.value,
          <String, Object?>{...c.toFields(), 'frequency': 'weekly'},
          expectVersion: c.version,
        ),
      );
      final CommitteeBook b = h.book();
      expect(b.defects.single.field, 'frequency');
      expect(b.defects.single.reason, 'unsupported');
      expect(b.committees, isEmpty);
    });

    test('an orphan is reported, never dropped in silence', () {
      final Committee c = h.add();
      final CommitteeCycleView one = h.cycle(c.id, 1);
      h.raw(
        CommitteeCollections.contributions,
        LumeRecordId.generate().value,
        <String, Object?>{
          'schema': kCommitteeSchema,
          'committee': LumeRecordId.generate().value,
          'cycle': one.cycle.id.value,
          'position': one.slots.first.position.id.value,
          'amountMinor': 2830000,
          'currency': 'PKR',
          'paidOn': '2026-06-07',
          'state': 'active',
        },
      );
      expect(
        h.book().damage.map((CommitteeDamage x) => x.reason),
        contains('orphanContribution'),
      );
    });
  });
}

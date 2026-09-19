/// Ledger's domain: the worked examples E1–E10, credit carried forward,
/// opposite principals, the lifecycle, bounds and determinism — each
/// against the repository, through real transactions.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/ledger/domain/ledger_book.dart';
import 'package:lume/features/ledger/domain/ledger_failure.dart';
import 'package:lume/features/ledger/domain/ledger_model.dart';
import 'package:lume/features/ledger/domain/ledger_reconcile.dart';
import 'package:lume/features/ledger/domain/ledger_repository.dart';

import 'ledger_harness.dart';

const LedgerKind lent = LedgerKind.lent;
const LedgerKind borrowed = LedgerKind.borrowed;
const LedgerKind repaidToMe = LedgerKind.repaidToMe;
const LedgerKind repaidByMe = LedgerKind.repaidByMe;

void main() {
  late LedgerHarness h;
  setUp(() => h = LedgerHarness());
  tearDown(() => h.dispose());

  LedgerFailureKind? kind(LedgerResult<Object?> r) => r.failure?.kind;

  group('worked examples', () {
    test('E1 — one loan, one partial repayment', () {
      final LumeRecordId ahmed = h.person('Ahmed');
      final LedgerEntry l1 = h.add(
        ahmed,
        lent,
        rs(10000),
        d(8, 1),
        due: d(9, 1),
      );
      final LedgerEntry r1 = h.add(ahmed, repaidToMe, rs(4000), d(8, 20));
      expect(h.paid(r1.id), <(LumeRecordId, int)>[(l1.id, 400000)]);
      expect(h.remaining(l1.id), 600000);
      final LedgerBalance row = h.row(ahmed);
      expect(row.direction, LedgerDirection.owesYou);
      expect(row.balance.minor, 600000);
      expect(row.overdue, isTrue);
      expect(row.shownDue, d(9, 1));
      h.expectSound();
    });

    test('E2 — two loans, different due dates', () {
      final LumeRecordId ahmed = h.person('Ahmed');
      final LedgerEntry l1 = h.add(
        ahmed,
        lent,
        rs(5000),
        d(7, 1),
        due: d(9, 15),
      );
      final LedgerEntry l2 = h.add(
        ahmed,
        lent,
        rs(3000),
        d(8, 1),
        due: d(8, 31),
      );
      final LedgerBalance row = h.row(ahmed);
      expect(row.balance.minor, 800000);
      expect(row.overdue, isTrue);
      expect(row.shownDue, d(8, 31));
      final Map<LumeRecordId, bool?> overdue = <LumeRecordId, bool?>{
        for (final LedgerPrincipalState p in row.principals)
          p.entry.id: p.overdue,
      };
      expect(overdue[l2.id], isTrue);
      expect(overdue[l1.id], isFalse);
    });

    test('E3 — one repayment spanning two loans', () {
      final LumeRecordId ahmed = h.person('Ahmed');
      final LedgerEntry l1 = h.add(
        ahmed,
        lent,
        rs(5000),
        d(7, 1),
        due: d(9, 15),
      );
      final LedgerEntry l2 = h.add(
        ahmed,
        lent,
        rs(3000),
        d(8, 1),
        due: d(8, 31),
      );
      final LedgerEntry r1 = h.add(ahmed, repaidToMe, rs(4000), d(9, 5));
      expect(h.paid(r1.id), <(LumeRecordId, int)>[
        (l2.id, 300000),
        (l1.id, 100000),
      ]);
      expect(h.remaining(l2.id), 0);
      expect(h.remaining(l1.id), 400000);
      final LedgerBalance row = h.row(ahmed);
      expect(row.overdue, isFalse);
      expect(row.balance.minor, 400000);
      expect(row.shownDue, d(9, 15));
      h.expectSound();
    });

    test('E4 — borrowed, repaid by the reader; directions never cross', () {
      final LumeRecordId sara = h.person('Sara');
      final LedgerEntry b1 = h.add(
        sara,
        borrowed,
        rs(2000),
        d(9, 1),
        due: d(9, 10),
      );
      final LedgerEntry p1 = h.add(sara, repaidByMe, rs(500), d(9, 5));
      expect(h.paid(p1.id), <(LumeRecordId, int)>[(b1.id, 50000)]);
      final LedgerBalance row = h.row(sara);
      expect(row.direction, LedgerDirection.youOwe);
      expect(row.balance.minor, -150000);
      expect(row.shownDue, d(9, 10));
      expect(row.overdue, isFalse);
      // A repayment to the reader can never pay off what the reader owes.
      final LedgerResult<LedgerWrite> wrong = h.tryAdd(
        sara,
        repaidToMe,
        rs(100),
        d(9, 6),
      );
      expect(kind(wrong), LedgerFailureKind.overpayment);
    });

    test('E5 — overpayment: refused, then confirmed as credit, then '
        'applied to the next loan', () {
      final LumeRecordId bilal = h.person('Bilal');
      final LedgerEntry l1 = h.add(bilal, lent, rs(1000), d(8, 1));
      final LedgerResult<LedgerWrite> refused = h.tryAdd(
        bilal,
        repaidToMe,
        rs(1500),
        d(8, 10),
      );
      expect(kind(refused), LedgerFailureKind.overpayment);
      expect(refused.failure!.excess.single, rs(500));
      expect(h.book().entriesOf(bilal), hasLength(1));

      final LedgerEntry r1 = h.add(
        bilal,
        repaidToMe,
        rs(1500),
        d(8, 10),
        confirm: true,
      );
      expect(h.entry(r1.id).excessConfirmed, isTrue);
      expect(h.paid(r1.id), <(LumeRecordId, int)>[(l1.id, 100000)]);
      expect(h.credit(r1.id), 50000);
      LedgerBalance row = h.row(bilal);
      expect(row.direction, LedgerDirection.youOwe);
      expect(row.creditToThem.minor, 50000);
      expect(row.balance.minor, -50000);

      final LedgerEntry l2 = h.add(bilal, lent, rs(2000), d(8, 20));
      expect(h.paid(r1.id), <(LumeRecordId, int)>[
        (l1.id, 100000),
        (l2.id, 50000),
      ]);
      row = h.row(bilal);
      expect(row.direction, LedgerDirection.owesYou);
      expect(row.balance.minor, 150000);
      h.expectSound();
    });

    test('E6 — a voided repayment counts for nothing, and restoring it '
        'returns exactly E1', () {
      final LumeRecordId ahmed = h.person('Ahmed');
      final LedgerEntry l1 = h.add(
        ahmed,
        lent,
        rs(10000),
        d(8, 1),
        due: d(9, 1),
      );
      final LedgerEntry r1 = h.add(ahmed, repaidToMe, rs(4000), d(8, 20));
      final LedgerAllocation a1 = h.book().allocations.single;

      h.tick();
      expect(
        h.repo.setVoided(r1.id, true, version: h.entry(r1.id).version).ok,
        isTrue,
      );
      expect(h.remaining(l1.id), 1000000);
      expect(h.row(ahmed).overdue, isTrue);
      expect(h.row(ahmed).balance.minor, 1000000);
      // Kept, counting for nothing.
      expect(
        h.book().allocations.map((LedgerAllocation a) => a.id),
        <LumeRecordId>[a1.id],
      );

      h.tick();
      expect(
        h.repo.setVoided(r1.id, false, version: h.entry(r1.id).version).ok,
        isTrue,
      );
      final LedgerAllocation back = h.book().allocations.single;
      expect(back.id, a1.id);
      expect(back.amount, a1.amount);
      expect(h.remaining(l1.id), 600000);
      h.expectSound();
    });

    test('E7 — editing a repayment re-allocates; an overpayment asks; a '
        'manual allocation that no longer fits conflicts', () {
      final LumeRecordId ahmed = h.person('Ahmed');
      final LedgerEntry l1 = h.add(
        ahmed,
        lent,
        rs(10000),
        d(8, 1),
        due: d(9, 1),
      );
      final LedgerEntry r1 = h.add(ahmed, repaidToMe, rs(4000), d(8, 20));
      LedgerEntryDraft draft(num rupees) => LedgerEntryDraft(
        partyId: ahmed,
        kind: repaidToMe,
        amount: rs(rupees),
        on: d(8, 20),
      );

      expect(h.repo.editEntry(r1.id, draft(2000), version: 1).ok, isTrue);
      expect(h.paid(r1.id), <(LumeRecordId, int)>[(l1.id, 200000)]);
      expect(h.remaining(l1.id), 800000);

      final int v = h.entry(r1.id).version;
      final LedgerResult<LedgerWrite> over = h.repo.editEntry(
        r1.id,
        draft(12000),
        version: v,
      );
      expect(kind(over), LedgerFailureKind.overpayment);
      expect(over.failure!.excess.single, rs(2000));
      expect(h.remaining(l1.id), 800000);
      expect(
        h.repo
            .editEntry(r1.id, draft(12000), version: v, confirmExcess: true)
            .ok,
        isTrue,
      );
      expect(h.credit(r1.id), 200000);
      expect(h.row(ahmed).direction, LedgerDirection.youOwe);

      // The manual variant.
      final LedgerHarness m = LedgerHarness(seed: 2);
      final LumeRecordId a = m.person('Ahmed');
      final LedgerEntry ml1 = m.add(a, lent, rs(10000), d(8, 1), due: d(9, 1));
      final LedgerEntry mr1 = m.add(
        a,
        repaidToMe,
        rs(4000),
        d(8, 20),
        manual: <LedgerManualDraft>[LedgerManualDraft(ml1.id, rs(4000))],
      );
      final LedgerAllocation manual = m.book().allocations.single;
      expect(manual.manual, isTrue);
      final String before = m.store.debugDump();
      final LedgerResult<LedgerWrite> clash = m.repo.editEntry(
        mr1.id,
        LedgerEntryDraft(
          partyId: a,
          kind: repaidToMe,
          amount: rs(2000),
          on: d(8, 20),
        ),
        version: 1,
      );
      expect(kind(clash), LedgerFailureKind.allocationConflict);
      expect(clash.failure!.ids, <LumeRecordId>[manual.id]);
      expect(m.store.debugDump(), before);
      m.dispose();
    });

    test('E8 — deleting a principal a repayment paid asks first; either '
        'answer is one transaction; Undo restores the same ids', () {
      final LumeRecordId ahmed = h.person('Ahmed');
      final LedgerEntry l1 = h.add(
        ahmed,
        lent,
        rs(10000),
        d(8, 1),
        due: d(9, 1),
      );
      final LedgerEntry r1 = h.add(ahmed, repaidToMe, rs(4000), d(8, 20));
      final LedgerAllocation a1 = h.book().allocations.single;
      final String before = h.store.debugDump();

      final LedgerResult<LedgerWrite> asked = h.repo.deleteEntry(
        l1.id,
        version: 1,
      );
      expect(kind(asked), LedgerFailureKind.overpayment);
      expect(asked.failure!.ids, <LumeRecordId>[r1.id]);
      expect(h.store.debugDump(), before);

      final LedgerResult<LedgerWrite> credit = h.repo.deleteEntry(
        l1.id,
        version: 1,
        orphans: LedgerOrphanChoice.keepAsCredit,
      );
      expect(credit.ok, isTrue);
      expect(h.book().entry(l1.id), isNull);
      expect(h.book().allocations, isEmpty);
      expect(h.credit(r1.id), 400000);
      expect(h.entry(r1.id).excessConfirmed, isTrue);
      h.expectSound();

      expect(h.repo.undo(credit.value!).ok, isTrue);
      expect(h.entry(l1.id).id, l1.id);
      expect(h.book().allocations.single.id, a1.id);
      expect(h.entry(r1.id).excessConfirmed, isFalse);
      expect(h.remaining(l1.id), 600000);

      final LedgerResult<LedgerWrite> both = h.repo.deleteEntry(
        l1.id,
        version: h.entry(l1.id).version,
        orphans: LedgerOrphanChoice.deleteRepayments,
      );
      expect(both.ok, isTrue);
      expect(h.book().entries, isEmpty);
      expect(h.book().allocations, isEmpty);
    });

    test('E9 — mixed currencies never touch; People counts Ahmed once', () {
      final LumeRecordId ahmed = h.person('Ahmed');
      final LedgerEntry l1 = h.add(ahmed, lent, rs(10000), d(8, 1));
      final LedgerEntry l2 = h.add(ahmed, lent, usdollars(50), d(8, 2));
      final LedgerEntry r1 = h.add(ahmed, repaidToMe, usdollars(20), d(8, 3));
      expect(h.paid(r1.id), <(LumeRecordId, int)>[(l2.id, 2000)]);
      expect(h.remaining(l1.id), 1000000);
      expect(h.row(ahmed).balance.minor, 1000000);
      expect(h.row(ahmed, usd).balance.minor, 3000);
      final LedgerBook b = h.book();
      expect(
        b.summaries.map(
          (LedgerCurrencySummary s) =>
              '${s.currency} ${s.owedToYou.minor} ${s.youOwe.minor}',
        ),
        <String>['PKR 1000000 0', 'USD 3000 0'],
      );
      expect(b.people, 1);
      h.expectSound();
    });

    test('E10 — equal dates: the creation instant decides, then the id', () {
      final LumeRecordId ahmed = h.person('Ahmed');
      h.clock = DateTime.utc(2026, 9, 7, 10);
      final LedgerEntry l1 = h.add(
        ahmed,
        lent,
        rs(3000),
        d(8, 1),
        due: d(9, 1),
      );
      final LedgerEntry l2 = h.add(
        ahmed,
        lent,
        rs(2000),
        d(8, 1),
        due: d(9, 1),
      );
      expect(l1.createdAt.isBefore(l2.createdAt), isTrue);
      final LedgerEntry r1 = h.add(ahmed, repaidToMe, rs(3500), d(9, 2));
      expect(h.paid(r1.id), <(LumeRecordId, int)>[
        (l1.id, 300000),
        (l2.id, 50000),
      ]);

      // The same instant: the lower id goes first.
      final DateTime at = DateTime.utc(2026, 9, 7);
      LedgerEntry principal(String id, int minor) => LedgerEntry(
        id: LumeRecordId.parse(id),
        partyId: ahmed,
        kind: lent,
        amount: LumeMoney.entry(minor, pkr),
        on: d(8, 1),
        due: d(9, 1),
        createdAt: at,
      );
      final LedgerEntry high = principal(
        'ffffffff-0000-4000-8000-000000000000',
        300000,
      );
      final LedgerEntry low = principal(
        '00000000-0000-4000-8000-000000000000',
        200000,
      );
      final LedgerEntry rep = LedgerEntry(
        id: LumeRecordId.parse('11111111-0000-4000-8000-000000000000'),
        partyId: ahmed,
        kind: repaidToMe,
        amount: LumeMoney.entry(350000, pkr),
        on: d(9, 2),
        createdAt: at,
      );
      int n = 0;
      final LedgerPlan plan = ledgerReconcile(
        party: ahmed,
        entries: <LedgerEntry>[high, low, rep],
        allocations: const <LedgerAllocation>[],
        newId: () =>
            LumeRecordId.parse('22222222-0000-4000-8000-00000000000${n++}'),
        now: at,
      );
      expect(
        plan.create.map(
          (LedgerAllocation a) => (a.principalId, a.amount.minor),
        ),
        <(LumeRecordId, int)>[(low.id, 200000), (high.id, 150000)],
      );
    });
  });

  group('credit carried forward', () {
    late LumeRecordId bilal;
    late LedgerEntry l1;
    late LedgerEntry r1;

    /// Bilal: Rs 1,000 lent, Rs 1,500 repaid, Rs 500 confirmed credit.
    void credit500() {
      bilal = h.person('Bilal');
      l1 = h.add(bilal, lent, rs(1000), d(8, 1));
      r1 = h.add(bilal, repaidToMe, rs(1500), d(8, 10), confirm: true);
      expect(h.credit(r1.id), 50000);
    }

    test('partial: a smaller later loan takes part of it; the rest stays '
        'visible', () {
      credit500();
      final LedgerEntry l2 = h.add(bilal, lent, rs(300), d(8, 20));
      expect(h.remaining(l2.id), 0);
      expect(h.credit(r1.id), 20000);
      expect(h.row(bilal).creditToThem.minor, 20000);
      expect(h.row(bilal).direction, LedgerDirection.youOwe);
      h.expectSound();
    });

    test('fully consumed: the person is settled', () {
      credit500();
      h.add(bilal, lent, rs(500), d(8, 20));
      expect(h.credit(r1.id), 0);
      expect(h.book().settled(bilal), isTrue);
      expect(h.book().people, 0);
    });

    test('spanning several later loans, in FIFO order, with some left', () {
      credit500();
      final LedgerEntry l2 = h.add(
        bilal,
        lent,
        rs(200),
        d(8, 20),
        due: d(10, 1),
      );
      final LedgerEntry l3 = h.add(
        bilal,
        lent,
        rs(200),
        d(8, 21),
        due: d(9, 20),
      );
      expect(h.paid(r1.id), <(LumeRecordId, int)>[
        // Dated principals first (due ascending), the undated one last.
        (l3.id, 20000),
        (l2.id, 20000),
        (l1.id, 100000),
      ]);
      expect(h.credit(r1.id), 10000);
      h.expectSound();
    });

    test('remaining after a larger later loan: the loan is part-paid', () {
      credit500();
      final LedgerEntry l2 = h.add(bilal, lent, rs(2000), d(8, 20));
      expect(h.remaining(l2.id), 150000);
      expect(h.credit(r1.id), 0);
    });

    test('never across currencies', () {
      credit500();
      final LedgerEntry dollars = h.add(bilal, lent, usdollars(10), d(8, 20));
      expect(h.remaining(dollars.id), 1000);
      expect(h.credit(r1.id), 50000);
      expect(h.row(bilal, usd).direction, LedgerDirection.owesYou);
    });

    test('never across people', () {
      credit500();
      final LumeRecordId sara = h.person('Sara');
      final LedgerEntry toSara = h.add(sara, lent, rs(300), d(8, 20));
      expect(h.remaining(toSara.id), 30000);
      expect(h.credit(r1.id), 50000);
    });

    test('voiding the source repayment withdraws the credit it gave; '
        'restoring gives it back exactly', () {
      credit500();
      final LedgerEntry l2 = h.add(bilal, lent, rs(300), d(8, 20));
      final List<LedgerAllocation> before = h.book().allocations;
      h.tick();
      expect(
        h.repo.setVoided(r1.id, true, version: h.entry(r1.id).version).ok,
        isTrue,
      );
      expect(h.remaining(l1.id), 100000);
      expect(h.remaining(l2.id), 30000);
      expect(h.row(bilal).creditToThem.isZero, isTrue);
      h.tick();
      expect(
        h.repo.setVoided(r1.id, false, version: h.entry(r1.id).version).ok,
        isTrue,
      );
      expect(
        h
            .book()
            .allocations
            .map((LedgerAllocation a) => (a.id, a.amount))
            .toSet(),
        before.map((LedgerAllocation a) => (a.id, a.amount)).toSet(),
      );
      expect(h.credit(r1.id), 20000);
      h.expectSound();
    });

    test('editing the source repayment below the credit it gave shrinks '
        'what it paid forward', () {
      credit500();
      final LedgerEntry l2 = h.add(bilal, lent, rs(500), d(8, 20));
      expect(h.remaining(l2.id), 0);
      expect(
        h.repo
            .editEntry(
              r1.id,
              LedgerEntryDraft(
                partyId: bilal,
                kind: repaidToMe,
                amount: rs(1200),
                on: d(8, 10),
              ),
              version: h.entry(r1.id).version,
            )
            .ok,
        isTrue,
      );
      expect(h.remaining(l1.id), 0);
      expect(h.remaining(l2.id), 30000);
      expect(h.credit(r1.id), 0);
      h.expectSound();
    });

    test('deleting the later loan returns the credit, without asking — it '
        'was confirmed', () {
      credit500();
      final LedgerEntry l2 = h.add(bilal, lent, rs(300), d(8, 20));
      final LedgerResult<LedgerWrite> r = h.repo.deleteEntry(
        l2.id,
        version: h.entry(l2.id).version,
      );
      expect(r.ok, isTrue);
      expect(h.credit(r1.id), 50000);
      h.expectSound();
    });

    test('the history shows the repayment, the confirmed excess, where it '
        'went and what is left', () {
      credit500();
      final LedgerEntry l2 = h.add(bilal, lent, rs(300), d(8, 20));
      final LedgerBook b = h.book();
      final LedgerEntry source = b.entry(r1.id)!;
      expect(source.excessConfirmed, isTrue);
      expect(
        b.allocationsOf(r1.id).map((LedgerAllocation a) => a.principalId),
        <LumeRecordId>[l1.id, l2.id],
      );
      expect(b.credit[r1.id]!.minor, 20000);
    });

    test('a rebuild gives the same allocations, whatever order the entries '
        'were made in', () {
      List<String> play(List<int> order) {
        final LedgerHarness x = LedgerHarness(seed: 9);
        final LumeRecordId p = x.person('P');
        final List<LedgerEntry Function()> steps = <LedgerEntry Function()>[
          () => x.add(p, lent, rs(1000), d(8, 1), due: d(8, 15)),
          () => x.add(p, lent, rs(700), d(8, 2), due: d(8, 10)),
          () => x.add(p, lent, rs(400), d(8, 3)),
        ];
        final List<LedgerEntry> made = <LedgerEntry>[
          for (final int i in order) steps[i](),
        ];
        x.add(p, repaidToMe, rs(1500), d(8, 20));
        final Map<LumeRecordId, String> name = <LumeRecordId, String>{
          for (int i = 0; i < order.length; i++) made[i].id: 'L${order[i]}',
        };
        final List<String> out = <String>[
          for (final LedgerAllocation a in x.book().allocations)
            '${name[a.principalId]}=${a.amount.minor}',
        ]..sort();
        x.dispose();
        return out;
      }

      expect(play(<int>[0, 1, 2]), <String>['L0=80000', 'L1=70000']);
      expect(play(<int>[2, 1, 0]), <String>['L0=80000', 'L1=70000']);
    });
  });

  group('opposite principals are never offset', () {
    test('equal: net zero, both open, not settled, counted once', () {
      final LumeRecordId ali = h.person('Ali');
      h.add(ali, lent, rs(1000), d(8, 1));
      h.add(ali, borrowed, rs(1000), d(8, 2));
      final LedgerBalance row = h.row(ali);
      expect(row.balance.isZero, isTrue);
      expect(row.direction, LedgerDirection.even);
      expect(row.settled, isFalse);
      expect(row.open(lent), hasLength(1));
      expect(row.open(borrowed), hasLength(1));
      expect(h.book().settled(ali), isFalse);
      expect(h.book().people, 1);
      expect(h.book().allocations, isEmpty);
      expect(
        h.repo.setArchived(ali, true, version: 1).failure?.kind,
        LedgerFailureKind.partyOpen,
      );
    });

    test('unequal: the net, and both obligations', () {
      final LumeRecordId ali = h.person('Ali');
      h.add(ali, lent, rs(1000), d(8, 1));
      h.add(ali, borrowed, rs(400), d(8, 2));
      final LedgerBalance row = h.row(ali);
      expect(row.direction, LedgerDirection.owesYou);
      expect(row.balance.minor, 60000);
      expect(row.owedToYou.minor, 100000);
      expect(row.youOwe.minor, 40000);
    });

    test('one side overdue, the other not: each keeps its own date', () {
      final LumeRecordId ali = h.person('Ali');
      final LedgerEntry mine = h.add(
        ali,
        lent,
        rs(1000),
        d(7, 1),
        due: d(8, 1),
      );
      final LedgerEntry theirs = h.add(
        ali,
        borrowed,
        rs(1000),
        d(7, 2),
        due: d(10, 1),
      );
      final LedgerBalance row = h.row(ali);
      expect(row.overdue, isTrue);
      expect(row.shownDue, d(8, 1));
      final Map<LumeRecordId, bool?> o = <LumeRecordId, bool?>{
        for (final LedgerPrincipalState p in row.principals)
          p.entry.id: p.overdue,
      };
      expect(o[mine.id], isTrue);
      expect(o[theirs.id], isFalse);
    });

    test('a repayment pays only its own direction', () {
      final LumeRecordId ali = h.person('Ali');
      final LedgerEntry mine = h.add(ali, lent, rs(1000), d(8, 1));
      final LedgerEntry theirs = h.add(ali, borrowed, rs(1000), d(8, 2));
      h.add(ali, repaidToMe, rs(1000), d(8, 3));
      expect(h.remaining(mine.id), 0);
      expect(h.remaining(theirs.id), 100000);
      expect(h.row(ali).direction, LedgerDirection.youOwe);
    });

    test('People counts a person once, across currencies and directions', () {
      final LumeRecordId ali = h.person('Ali');
      h.add(ali, lent, rs(1000), d(8, 1));
      h.add(ali, borrowed, usdollars(5), d(8, 2));
      final LumeRecordId sara = h.person('Sara');
      h.add(sara, lent, rs(10), d(8, 1));
      expect(h.book().people, 2);
    });
  });

  group('people', () {
    test('a Ledger starts empty — nothing seeded', () {
      final LedgerBook b = h.book();
      expect(b.isEmpty, isTrue);
      expect(b.people, 0);
      expect(b.summaries, isEmpty);
    });

    test('names are required and bounded', () {
      expect(kind(h.repo.addParty('   ')), LedgerFailureKind.validation);
      expect(h.repo.addParty('   ').failure!.reason, 'required');
      expect(h.repo.addParty('x' * 81).failure!.reason, 'long');
      expect(h.repo.addParty('  Ahmed  ').value!.name, 'Ahmed');
    });

    test('renaming keeps every entry; a stale rename conflicts', () {
      final LumeRecordId a = h.person('Ahmed');
      final LedgerEntry e = h.add(a, lent, rs(10), d(8, 1));
      expect(h.repo.renameParty(a, 'Ahmed K', version: 1).ok, isTrue);
      expect(h.book().party(a)!.name, 'Ahmed K');
      expect(h.book().entry(e.id)!.partyId, a);
      expect(
        kind(h.repo.renameParty(a, 'X', version: 1)),
        LedgerFailureKind.conflict,
      );
    });

    test('archive only when settled; archived people stay in history; '
        'unarchive restores', () {
      final LumeRecordId a = h.person('Ahmed');
      final LedgerEntry e = h.add(a, lent, rs(10), d(8, 1));
      expect(
        kind(h.repo.setArchived(a, true, version: 1)),
        LedgerFailureKind.partyOpen,
      );
      h.add(a, repaidToMe, rs(10), d(8, 2));
      expect(h.repo.setArchived(a, true, version: 1).ok, isTrue);
      expect(h.book().party(a)!.archived, isTrue);
      expect(h.book().entry(e.id), isNotNull);
      // No new entries while archived.
      expect(h.tryAdd(a, lent, rs(1), d(8, 3)).failure!.reason, 'archived');
      expect(h.repo.setArchived(a, false, version: 2).ok, isTrue);
      expect(h.book().party(a)!.archived, isFalse);
    });

    test('delete refused while any entry — even a voided one — names them; '
        'never a cascade', () {
      final LumeRecordId a = h.person('Ahmed');
      final LedgerEntry e = h.add(a, lent, rs(10), d(8, 1));
      h.repo.setVoided(e.id, true, version: 1);
      final LedgerResult<LedgerWrite> r = h.repo.deleteParty(a, version: 1);
      expect(kind(r), LedgerFailureKind.partyReferenced);
      expect(r.failure!.count, 1);
      expect(h.book().entry(e.id), isNotNull);
      expect(h.repo.deleteEntry(e.id, version: 2).ok, isTrue);
      expect(h.repo.deleteParty(a, version: 1).ok, isTrue);
      expect(h.book().parties, isEmpty);
    });
  });

  group('entries', () {
    test('validation: zero, due on a repayment, due before the date, '
        'withdrawn currency, notes', () {
      final LumeRecordId a = h.person('A');
      expect(
        h.tryAdd(a, lent, LumeMoney.entry(0, pkr), d(8, 1)).failure!.reason,
        'zero',
      );
      expect(
        h.tryAdd(a, repaidToMe, rs(1), d(8, 1), due: d(9, 1)).failure!.reason,
        'repayment',
      );
      expect(
        h.tryAdd(a, lent, rs(1), d(8, 2), due: d(8, 1)).failure!.reason,
        'beforeDate',
      );
      expect(
        h
            .tryAdd(
              a,
              lent,
              LumeMoney.entry(100, LumeCurrency.of('HRK')),
              d(8, 1),
            )
            .failure!
            .reason,
        'withdrawn',
      );
      h.tick();
      expect(
        h.repo
            .addEntry(
              LedgerEntryDraft(
                partyId: a,
                kind: lent,
                amount: rs(1),
                on: d(8, 1),
                note: 'x' * 501,
              ),
            )
            .failure!
            .reason,
        'long',
      );
      expect(h.book().entries, isEmpty);
    });

    test('a stale edit is a conflict and changes nothing', () {
      final LumeRecordId a = h.person('A');
      final LedgerEntry e = h.add(a, lent, rs(10), d(8, 1));
      h.repo.setVoided(e.id, true, version: 1);
      final LedgerResult<LedgerWrite> r = h.repo.editEntry(
        e.id,
        LedgerEntryDraft(partyId: a, kind: lent, amount: rs(20), on: d(8, 1)),
        version: 1,
      );
      expect(kind(r), LedgerFailureKind.conflict);
      expect(h.entry(e.id).amount, rs(10));
    });

    test('moving an entry to another person reconciles both', () {
      final LumeRecordId a = h.person('A');
      final LumeRecordId b = h.person('B');
      final LedgerEntry l = h.add(a, lent, rs(100), d(8, 1));
      h.add(b, lent, rs(100), d(8, 1));
      final LedgerEntry r = h.add(a, repaidToMe, rs(100), d(8, 2));
      expect(h.remaining(l.id), 0);
      final LedgerResult<LedgerWrite> moved = h.repo.editEntry(
        r.id,
        LedgerEntryDraft(
          partyId: b,
          kind: repaidToMe,
          amount: rs(100),
          on: d(8, 2),
        ),
        version: 1,
      );
      expect(moved.ok, isTrue);
      expect(h.remaining(l.id), 10000);
      expect(h.book().settled(b), isTrue);
      h.expectSound();
    });

    test('manual allocation: the reader\'s choice is kept over FIFO', () {
      final LumeRecordId a = h.person('A');
      final LedgerEntry old = h.add(a, lent, rs(100), d(7, 1), due: d(7, 15));
      final LedgerEntry recent = h.add(
        a,
        lent,
        rs(100),
        d(8, 1),
        due: d(8, 15),
      );
      final LedgerEntry r = h.add(
        a,
        repaidToMe,
        rs(100),
        d(8, 2),
        manual: <LedgerManualDraft>[LedgerManualDraft(recent.id, rs(100))],
      );
      expect(h.paid(r.id), <(LumeRecordId, int)>[(recent.id, 10000)]);
      expect(h.remaining(old.id), 10000);
      // Voiding the manually paid principal conflicts until made automatic.
      expect(
        kind(
          h.repo.setVoided(
            recent.id,
            true,
            version: h.entry(recent.id).version,
          ),
        ),
        LedgerFailureKind.allocationConflict,
      );
      expect(
        h.repo
            .setVoided(
              recent.id,
              true,
              version: h.entry(recent.id).version,
              makeAutomatic: true,
            )
            .ok,
        isTrue,
      );
      expect(h.paid(r.id), <(LumeRecordId, int)>[(old.id, 10000)]);
      h.expectSound();
    });

    test('a manual allocation to an incompatible principal is refused', () {
      final LumeRecordId a = h.person('A');
      final LedgerEntry theirs = h.add(a, borrowed, rs(100), d(8, 1));
      final LedgerResult<LedgerWrite> r = h.tryAdd(
        a,
        repaidToMe,
        rs(100),
        d(8, 2),
        manual: <LedgerManualDraft>[LedgerManualDraft(theirs.id, rs(100))],
      );
      expect(r.failure!.reason, 'incompatible');
    });

    test('with no today, nothing is overdue or not', () {
      final LumeRecordId a = h.person('A');
      h.add(a, lent, rs(100), d(7, 1), due: d(7, 15));
      final LedgerBalance row = h.repo.view().book(null).balancesOf(a).single;
      expect(row.overdue, isNull);
      expect(row.principals.single.overdue, isNull);
      expect(row.shownDue, d(7, 15));
    });

    test('a retried add with the same idempotency key writes once', () {
      final LumeRecordId a = h.person('A');
      final LedgerEntryDraft draft = LedgerEntryDraft(
        partyId: a,
        kind: lent,
        amount: rs(5),
        on: d(8, 1),
      );
      final LedgerResult<LedgerWrite> first = h.repo.addEntry(
        draft,
        idempotencyKey: 'k',
      );
      final LedgerResult<LedgerWrite> again = h.repo.addEntry(
        draft,
        idempotencyKey: 'k',
      );
      expect(first.ok && again.ok, isTrue);
      expect(again.value!.receipt.replayed, isTrue);
      expect(h.book().entries, hasLength(1));
    });
  });

  group('bounds', () {
    test('an entry at exactly 10^15 minor units; one more is refused', () {
      final LumeRecordId a = h.person('A');
      h.add(a, lent, LumeMoney.entry(LumeMoney.maxEntryMinor, pkr), d(8, 1));
      expect(
        () => LumeMoney.entry(LumeMoney.maxEntryMinor + 1, pkr),
        throwsA(isA<LumeMoneyException>()),
      );
      expect(() => rs(-1), throwsA(isA<LumeMoneyException>()));
    });

    test('a sum past 2^53 − 1 rolls the whole write back', () {
      final LumeRecordId a = h.person('A');
      for (int i = 0; i < 9; i++) {
        h.add(a, lent, LumeMoney.entry(LumeMoney.maxEntryMinor, pkr), d(8, 1));
      }
      final String before = h.store.debugDump();
      final LedgerResult<LedgerWrite> tenth = h.tryAdd(
        a,
        lent,
        LumeMoney.entry(LumeMoney.maxEntryMinor, pkr),
        d(8, 1),
      );
      expect(kind(tenth), LedgerFailureKind.overflow);
      expect(h.store.debugDump(), before);
    });

    test('large allocation totals stay exact', () {
      final LumeRecordId a = h.person('A');
      final LedgerEntry l = h.add(
        a,
        lent,
        LumeMoney.entry(LumeMoney.maxEntryMinor, pkr),
        d(8, 1),
      );
      h.add(
        a,
        repaidToMe,
        LumeMoney.entry(LumeMoney.maxEntryMinor - 1, pkr),
        d(8, 2),
      );
      expect(h.remaining(l.id), 1);
      h.expectSound();
    });
  });

  test('determinism: the same commands from the same seed give the same '
      'store', () {
    String play() {
      final LedgerHarness x = LedgerHarness(seed: 42);
      final LumeRecordId p = x.person('P');
      x.add(p, lent, rs(1000), d(8, 1), due: d(9, 1));
      x.add(p, repaidToMe, rs(300), d(8, 5));
      x.add(p, repaidToMe, rs(900), d(8, 6), confirm: true);
      final String out = x.store.debugDump();
      x.dispose();
      return out;
    }

    expect(play(), play());
    expect(Random(1).nextInt(10), Random(1).nextInt(10));
  });
}

/// Installments' rules, against the repository and the book: the schedule,
/// deposit, fixed totals, currencies, payments in order, derived states,
/// completion, cancellation, deletion with Undo, locked fields, void and
/// restore, damage, and the invariants after every write
/// (`INSTALLMENTS_PROPOSAL.md` §40).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/installments/domain/installments_book.dart';
import 'package:lume/features/installments/domain/installments_failure.dart';
import 'package:lume/features/installments/domain/installments_model.dart';
import 'package:lume/features/installments/domain/installments_repository.dart';
import 'package:lume/core/values/lume_month_anchor.dart';

import 'installments_harness.dart';

void main() {
  group('the schedule', () {
    List<String> dues(LumeDate first, int n) =>
        lumeMonthlyDues(first, n)!.map((LumeDate x) => x.toIso()).toList();

    test('31 January: the February clamp does not carry into March', () {
      expect(dues(LumeDate(2026, 1, 31), 4), <String>[
        '2026-01-31',
        '2026-02-28',
        '2026-03-31',
        '2026-04-30',
      ]);
    });

    test('a leap year gives 29 February', () {
      expect(dues(LumeDate(2028, 1, 31), 3), <String>[
        '2028-01-31',
        '2028-02-29',
        '2028-03-31',
      ]);
    });

    test('30 January → end of February → 30 March', () {
      expect(dues(LumeDate(2026, 1, 30), 3), <String>[
        '2026-01-30',
        '2026-02-28',
        '2026-03-30',
      ]);
    });

    test('anchored on 29 February: each year its own February', () {
      final LumeDate first = LumeDate(2028, 2, 29);
      expect(lumeMonthlyDue(first, 13)!.toIso(), '2029-02-28');
      expect(lumeMonthlyDue(first, 49)!.toIso(), '2032-02-29');
      expect(lumeMonthlyDue(first, 2)!.toIso(), '2028-03-29');
    });

    test('across a year end, and past the calendar there is none', () {
      expect(dues(LumeDate(2026, 11, 15), 3), <String>[
        '2026-11-15',
        '2026-12-15',
        '2027-01-15',
      ]);
      expect(lumeMonthlyDues(LumeDate(9999, 6, 1), 12), isNull);
    });

    test('stored once: count rows, each the quoted amount, total exact', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentPlan p = h.add(
        amount: rs(9500),
        count: 12,
        firstDue: LumeDate(2026, 1, 31),
      );
      final InstallmentPlanView v = h.plan(p.id);
      expect(v.rows, hasLength(12));
      expect(
        v.rows.map((InstallmentRow r) => r.row.seq),
        List<int>.generate(12, (int i) => i + 1),
      );
      expect(
        v.rows.every((InstallmentRow r) => r.row.amount == rs(9500)),
        isTrue,
      );
      expect(v.scheduledTotal, LumeMoney.sum(950000 * 12, pkr));
      expect(v.rows[1].row.due, LumeDate(2026, 2, 28));
      expect(v.rows[2].row.due, LumeDate(2026, 3, 31));
      // Every row has its own stable id.
      expect(v.rows.map((InstallmentRow r) => r.row.id).toSet(), hasLength(12));
      h.expectSound();
      h.dispose();
    });

    test('a stored due date is read back, never recomputed', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentPlan p = h.add(firstDue: LumeDate(2026, 1, 31));
      final String before = h.store.debugDump();
      // Reading, deriving and reading again changes nothing stored.
      h.book();
      h.book(null);
      expect(h.store.debugDump(), before);
      expect(h.plan(p.id).rows[1].row.due, LumeDate(2026, 2, 28));
      h.dispose();
    });
  });

  group('totals and the deposit', () {
    test('the worked example: Rs 9,500 × 12 with Rs 20,000 down', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentPlan p = h.add(
        amount: rs(9500),
        count: 12,
        deposit: rs(20000),
        depositOn: d(3, 30),
        cashPrice: rs(120000),
      );
      InstallmentPlanView v = h.plan(p.id);
      expect(v.scheduledTotal, LumeMoney.sum(11400000, pkr)); // 114,000.00
      expect(v.totalPayable, LumeMoney.sum(13400000, pkr)); // 134,000.00
      expect(v.paidToDate, rs(20000));
      expect(v.remaining, LumeMoney.sum(11400000, pkr));
      // The deposit is not instalment zero.
      expect(v.rows.first.row.seq, 1);
      expect(v.rows, hasLength(12));
      // The cash difference is a subtraction of the reader's own numbers.
      expect(v.cashDifference, LumeMoney.sum(1400000, pkr)); // 14,000.00

      h.payNext(p.id, 5);
      v = h.plan(p.id);
      expect(v.paidToDate, LumeMoney.sum(2000000 + 5 * 950000, pkr));
      expect(v.remaining, LumeMoney.sum(7 * 950000, pkr));
      expect(v.paymentsLeft, 7);
      h.expectSound();
      h.dispose();
    });

    test('a deposit needs its date, is above zero, in the plan currency', () {
      final InstallmentsHarness h = InstallmentsHarness();
      expect(h.tryAdd(deposit: rs(100)).failure?.field, 'depositOn');
      expect(h.tryAdd(depositOn: d(1, 1)).failure?.field, 'deposit');
      expect(
        h.tryAdd(deposit: rs(0), depositOn: d(1, 1)).failure?.reason,
        'zero',
      );
      expect(
        h.tryAdd(deposit: dollars(5), depositOn: d(1, 1)).failure?.reason,
        'currency',
      );
      expect(h.book().plans, isEmpty);
      h.dispose();
    });

    test('bounds: amount × count within 2^53 − 1, count 1–600', () {
      final InstallmentsHarness h = InstallmentsHarness();
      expect(
        h
            .tryAdd(
              amount: LumeMoney.entry(LumeMoney.maxEntryMinor, pkr),
              count: 600,
            )
            .failure
            ?.kind,
        InstallmentsFailureKind.overflow,
      );
      expect(h.tryAdd(count: 0).failure?.field, 'count');
      expect(h.tryAdd(count: 601).failure?.field, 'count');
      expect(h.tryAdd(amount: rs(0)).failure?.field, 'amount');
      expect(h.tryAdd(item: '  ').failure?.field, 'item');
      expect(h.tryAdd(item: 'x' * 81).failure?.reason, 'long');
      expect(h.book().plans, isEmpty);
      // The largest that fits.
      final InstallmentPlan p = h.add(
        amount: LumeMoney.entry(LumeMoney.maxSumMinor ~/ 600, pkr),
        count: 600,
      );
      expect(
        h.plan(p.id).scheduledTotal.minor <= LumeMoney.maxSumMinor,
        isTrue,
      );
      h.dispose();
    });
  });

  group('currencies', () {
    test('a withdrawn currency is not for a new plan', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentsResult<InstallmentsWrite> r = h.tryAdd(
        amount: LumeMoney.entry(100, LumeCurrency.of('BGN')),
      );
      expect(r.failure?.field, 'currency');
      expect(r.failure?.reason, 'withdrawn');
      expect(installmentsDefaultCurrency('BGN'), isNull);
      expect(installmentsDefaultCurrency('EUR'), LumeCurrency.of('EUR'));
      h.dispose();
    });

    test('two currencies: two summaries, never added together', () {
      final InstallmentsHarness h = InstallmentsHarness();
      h.add(amount: rs(9500), count: 12, firstDue: d(9, 14));
      h.add(item: 'Phone', amount: dollars(48), count: 18, firstDue: d(9, 27));
      final List<InstallmentsCurrencySummary> s = h.book().summaries;
      expect(
        s.map((InstallmentsCurrencySummary x) => x.currency),
        <LumeCurrency>[pkr, usd],
      );
      expect(s[0].dueThisMonth, rs(9500));
      expect(s[1].dueThisMonth, dollars(48));
      expect(s[0].remaining, LumeMoney.sum(12 * 950000, pkr));
      expect(s[1].remaining, LumeMoney.sum(18 * 4800, usd));
      h.dispose();
    });
  });

  group('payments', () {
    test('in order: the next one is paid, any other names it', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentPlan p = h.add();
      final InstallmentPlanView v = h.plan(p.id);
      final InstallmentsResult<InstallmentsWrite> skip = h.repo.recordPayment(
        p.id,
        v.rows[2].row.id,
        kToday,
      );
      expect(skip.failure?.kind, InstallmentsFailureKind.outOfOrder);
      expect(skip.failure?.ids, <LumeRecordId>[v.rows[0].row.id]);
      expect(h.plan(p.id).paidCount, 0);

      final InstallmentsResult<InstallmentsWrite> ok = h.repo.recordPayment(
        p.id,
        v.rows[0].row.id,
        kToday,
      );
      expect(ok.failure, isNull);
      // At its amount, exactly.
      expect(ok.value!.payment!.amount, v.rows[0].row.amount);
      final InstallmentsResult<InstallmentsWrite> again = h.repo.recordPayment(
        p.id,
        v.rows[0].row.id,
        kToday,
      );
      expect(again.failure?.kind, InstallmentsFailureKind.alreadyPaid);
      h.expectSound();
      h.dispose();
    });

    test('paid, due today, late and upcoming — and nothing guessed '
        'without a day', () {
      final InstallmentsHarness h = InstallmentsHarness();
      // Due 7 Aug, 7 Sep, 7 Oct …
      final InstallmentPlan p = h.add(firstDue: d(7, 7), count: 6);
      h.payNext(p.id);
      final InstallmentPlanView v = h.plan(p.id, kToday);
      expect(
        v.rows.map((InstallmentRow r) => r.status).take(4),
        <InstallmentStatus>[
          InstallmentStatus.paid,
          InstallmentStatus.late,
          InstallmentStatus.dueToday,
          InstallmentStatus.upcoming,
        ],
      );
      expect(v.lateCount, 1);

      final InstallmentsBook unknown = h.repo.view().book(null);
      final InstallmentPlanView u = unknown.plan(p.id)!;
      expect(u.rows.first.status, InstallmentStatus.paid);
      expect(
        u.rows
            .skip(1)
            .every((InstallmentRow r) => r.status == InstallmentStatus.unknown),
        isTrue,
      );
      expect(u.lateCount, isNull);
      expect(unknown.summaries.single.dueThisMonth, isNull);
      expect(unknown.summaries.single.lateInstallments, isNull);
      expect(unknown.months(pkr), isNull);
      // What does not need the day is still there.
      expect(unknown.summaries.single.remaining, u.remaining);
      h.dispose();
    });

    test('completed when every instalment is paid; then nothing to pay '
        'or cancel', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentPlan p = h.add(count: 3);
      h.payNext(p.id, 3);
      final InstallmentPlanView v = h.plan(p.id);
      expect(v.status, InstallmentPlanStatus.completed);
      expect(v.next, isNull);
      expect(v.remaining.isZero, isTrue);
      expect(
        h.repo.setCancelled(p.id, true, version: v.plan.version).failure?.kind,
        InstallmentsFailureKind.completed,
      );
      h.expectSound();
      h.dispose();
    });

    test('void then restore reproduces every figure exactly', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentPlan p = h.add(deposit: rs(1000), depositOn: d(3, 1));
      h.add(item: 'Sofa', amount: rs(6200), count: 9);
      h.payNext(p.id, 3);
      InstallmentsBook b = h.book();
      final List<(int, int, int)> before = <(int, int, int)>[
        for (final InstallmentsCurrencySummary s in b.summaries)
          (s.paidToDate.minor, s.remaining.minor, s.dueThisMonth!.minor),
      ];
      final InstallmentPayment last = h.plan(p.id).payments.first;
      expect(
        h.repo.setPaymentVoided(last.id, true, version: last.version).ok,
        isTrue,
      );
      final InstallmentPlanView voided = h.plan(p.id);
      expect(voided.paidCount, 2);
      expect(voided.payments, hasLength(3)); // kept, as voided
      expect(voided.next!.row.seq, 3);
      final InstallmentPayment v = voided.payments.firstWhere(
        (InstallmentPayment x) => x.id == last.id,
      );
      expect(v.voided, isTrue);
      expect(
        h.repo.setPaymentVoided(last.id, false, version: v.version).ok,
        isTrue,
      );
      b = h.book();
      expect(<(int, int, int)>[
        for (final InstallmentsCurrencySummary s in b.summaries)
          (s.paidToDate.minor, s.remaining.minor, s.dueThisMonth!.minor),
      ], before);
      h.expectSound();
      h.dispose();
    });

    test('a void restored after the instalment was paid again is refused', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentPlan p = h.add();
      h.payNext(p.id);
      final InstallmentPayment first = h.plan(p.id).payments.single;
      h.repo.setPaymentVoided(first.id, true, version: first.version);
      h.payNext(p.id); // the same instalment, paid again
      final InstallmentPayment voided = h
          .plan(p.id)
          .payments
          .firstWhere((InstallmentPayment x) => x.id == first.id);
      final InstallmentsResult<InstallmentsWrite> r = h.repo.setPaymentVoided(
        first.id,
        false,
        version: voided.version,
      );
      expect(r.failure?.kind, InstallmentsFailureKind.alreadyPaid);
      expect(h.plan(p.id).paidCount, 1);
      h.expectSound();
      h.dispose();
    });
  });

  group('editing', () {
    InstallmentPlanDraft draftOf(
      InstallmentPlan p, {
      String? item,
      LumeMoney? amount,
      int? count,
      LumeDate? firstDue,
      LumeMoney? deposit,
      LumeDate? depositOn,
    }) => InstallmentPlanDraft(
      item: item ?? p.item,
      merchant: p.merchant,
      note: p.note,
      amount: amount ?? p.amount,
      count: count ?? p.count,
      firstDue: firstDue ?? p.firstDue,
      deposit: deposit ?? p.deposit,
      depositOn: depositOn ?? p.depositOn,
      cashPrice: p.cashPrice,
    );

    test('before any payment the terms change, and the schedule is '
        'replaced whole', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentPlan p = h.add(count: 12);
      final Set<LumeRecordId> old = h
          .plan(p.id)
          .rows
          .map((InstallmentRow r) => r.row.id)
          .toSet();
      final InstallmentsResult<InstallmentsWrite> r = h.repo.editPlan(
        p.id,
        draftOf(p, count: 6, amount: rs(19000)),
        version: p.version,
      );
      expect(r.failure, isNull);
      final InstallmentPlanView v = h.plan(p.id);
      expect(v.rows, hasLength(6));
      expect(
        v.rows.every((InstallmentRow x) => x.row.amount == rs(19000)),
        isTrue,
      );
      expect(
        v.rows.map((InstallmentRow x) => x.row.id).toSet().intersection(old),
        isEmpty,
      );
      h.expectSound();
      h.dispose();
    });

    test('once a payment exists, every term is locked; item, merchant and '
        'note are not', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentPlan p = h.add(deposit: rs(500), depositOn: d(3, 1));
      h.payNext(p.id);
      final String dump = h.store.debugDump();
      for (final (String field, InstallmentPlanDraft draft)
          in <(String, InstallmentPlanDraft)>[
            ('amount', draftOf(p, amount: rs(9000))),
            ('count', draftOf(p, count: 10)),
            ('firstDue', draftOf(p, firstDue: d(5, 1))),
            ('deposit', draftOf(p, deposit: rs(400))),
            ('depositOn', draftOf(p, depositOn: d(3, 2))),
            ('currency', draftOf(p, amount: dollars(95))),
          ]) {
        final InstallmentsResult<InstallmentsWrite> r = h.repo.editPlan(
          p.id,
          draft,
          version: p.version,
        );
        expect(r.failure?.kind, InstallmentsFailureKind.locked, reason: field);
        expect(r.failure?.field, field);
      }
      expect(h.store.debugDump(), dump);
      final InstallmentsResult<InstallmentsWrite> ok = h.repo.editPlan(
        p.id,
        draftOf(p, item: 'Work laptop'),
        version: p.version,
      );
      expect(ok.failure, isNull);
      expect(h.plan(p.id).plan.item, 'Work laptop');
      // The schedule is the one it was.
      expect(h.plan(p.id).rows.first.paid, isTrue);
      h.expectSound();
      h.dispose();
    });

    test('a voided payment still fixes the terms', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentPlan p = h.add();
      h.payNext(p.id);
      final InstallmentPayment x = h.plan(p.id).payments.single;
      h.repo.setPaymentVoided(x.id, true, version: x.version);
      expect(
        h.repo
            .editPlan(p.id, draftOf(p, count: 3), version: p.version)
            .failure
            ?.kind,
        InstallmentsFailureKind.locked,
      );
      h.dispose();
    });

    test('a stale version is a conflict, and nothing is written', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentPlan p = h.add();
      h.repo.editPlan(p.id, draftOf(p, item: 'A'), version: p.version);
      final InstallmentsResult<InstallmentsWrite> r = h.repo.editPlan(
        p.id,
        draftOf(p, item: 'B'),
        version: p.version,
      );
      expect(r.failure?.kind, InstallmentsFailureKind.conflict);
      expect(h.plan(p.id).plan.item, 'A');
      h.dispose();
    });
  });

  group('cancel and delete', () {
    test('cancel keeps everything, leaves Active, takes it out of what is '
        'left and due — and fabricates no refund', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentPlan p = h.add(firstDue: d(9, 14));
      h.payNext(p.id, 2);
      final InstallmentsCurrencySummary before = h.book().summary(pkr);
      final InstallmentsResult<InstallmentsWrite> r = h.repo.setCancelled(
        p.id,
        true,
        version: p.version,
      );
      expect(r.failure, isNull);
      final InstallmentPlanView v = h.plan(p.id);
      expect(v.status, InstallmentPlanStatus.cancelled);
      expect(v.rows, hasLength(12));
      expect(v.payments, hasLength(2));
      final InstallmentsCurrencySummary after = h.book().summary(pkr);
      expect(after.paidToDate, before.paidToDate);
      expect(after.remaining.isZero, isTrue);
      expect(after.activePlans, 0);
      expect(after.dueThisMonth!.isZero, isTrue);
      // Nothing is paid on a cancelled plan.
      expect(
        h.repo.recordPayment(p.id, v.next!.row.id, kToday).failure?.kind,
        InstallmentsFailureKind.cancelled,
      );
      // Its Undo, and Reinstate, bring it back.
      expect(h.repo.undo(r.value!).ok, isTrue);
      expect(h.plan(p.id).status, InstallmentPlanStatus.active);
      h.expectSound();
      h.dispose();
    });

    test('reinstate brings back the same plan and the same stored schedule '
        '— no new ids, no new dates', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentPlan p = h.add(firstDue: LumeDate(2026, 1, 31));
      h.payNext(p.id, 2);
      List<String> rows() => <String>[
        for (final ScheduledInstallment r in h.repo.view().schedule)
          '${r.id} ${r.seq} ${r.due} ${r.amount.minor} v${r.version}',
      ]..sort();
      final List<String> before = rows();
      final List<InstallmentPayment> paid = h.plan(p.id).payments;
      final InstallmentsResult<InstallmentsWrite> c = h.repo.setCancelled(
        p.id,
        true,
        version: p.version,
      );
      expect(c.failure, isNull);
      final InstallmentsResult<InstallmentsWrite> r = h.repo.setCancelled(
        p.id,
        false,
        version: c.value!.plan!.version,
      );
      expect(r.failure, isNull);
      final InstallmentPlanView v = h.plan(p.id);
      expect(v.plan.id, p.id);
      expect(v.status, InstallmentPlanStatus.active);
      expect(rows(), before);
      expect(
        v.payments.map((InstallmentPayment x) => x.id),
        paid.map((InstallmentPayment x) => x.id),
      );
      expect(v.rows[1].row.due, LumeDate(2026, 2, 28));
      // And it takes payments again, from where it was.
      h.payNext(p.id);
      expect(h.plan(p.id).paidCount, 3);
      h.expectSound();
      h.dispose();
    });

    test('delete removes the plan, its schedule and its payments at once; '
        'Undo restores the same ids and versions', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentPlan keep = h.add(item: 'Sofa', count: 9);
      final InstallmentPlan p = h.add(count: 12);
      h.payNext(p.id, 3);
      final String before = h.records();
      final InstallmentsResult<InstallmentsWrite> r = h.repo.deletePlan(
        p.id,
        version: p.version,
      );
      expect(r.failure, isNull);
      final InstallmentsBook b = h.book();
      expect(b.plans.map((InstallmentPlanView v) => v.plan.id), <LumeRecordId>[
        keep.id,
      ]);
      expect(h.repo.view().schedule, hasLength(9)); // no orphans
      expect(h.repo.view().payments, isEmpty);
      expect(h.repo.undo(r.value!).ok, isTrue);
      expect(h.records(), before);
      h.expectSound();
      h.dispose();
    });

    test('a stale delete writes nothing', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentPlan p = h.add();
      h.repo.setCancelled(p.id, true, version: p.version);
      final String before = h.store.debugDump();
      expect(
        h.repo.deletePlan(p.id, version: p.version).failure?.kind,
        InstallmentsFailureKind.conflict,
      );
      expect(h.store.debugDump(), before);
      h.dispose();
    });
  });

  group('summaries', () {
    test('due this month is what falls due this month — not every plan\'s '
        'amount added up', () {
      final InstallmentsHarness h = InstallmentsHarness();
      h.add(amount: rs(9500), firstDue: d(9, 14)); // one in September
      h.add(item: 'Sofa', amount: rs(6200), firstDue: d(10, 3)); // none yet
      final InstallmentsCurrencySummary s = h.book().summary(pkr);
      expect(s.dueThisMonth, rs(9500));
      expect(s.activePlans, 2);
      final List<InstallmentsMonth> m = h.book().months(pkr)!;
      expect(m.map((InstallmentsMonth x) => x.month.month), <int>[
        9,
        10,
        11,
        12,
        1,
        2,
      ]);
      expect(m.first.due, rs(9500));
      expect(m[1].due, rs(9500 + 6200));
      h.dispose();
    });
  });

  group('stored damage', () {
    test('a record that cannot be read is a defect; its plan is damaged, '
        'shown, and not written over', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentPlan p = h.add(count: 3);
      final LumeRecordId rowId = h.plan(p.id).rows.first.row.id;
      // A payment that pays a different amount than its instalment.
      h.raw(
        InstallmentsCollections.payments,
        LumeRecordId.generate(null).value,
        <String, Object?>{
          'schema': kInstallmentsSchema,
          'plan': p.id.value,
          'installment': rowId.value,
          'amountMinor': 1,
          'currency': 'PKR',
          'paidOn': '2026-09-01',
          'state': 'active',
        },
      );
      final InstallmentsBook b = h.book();
      expect(b.plan(p.id)!.damage, 'paymentAmount');
      expect(b.summaries.single.remaining.isZero, isTrue); // left out
      expect(
        h.repo.recordPayment(p.id, rowId, kToday).failure?.kind,
        InstallmentsFailureKind.damaged,
      );
      // Delete is the way out, and it leaves nothing behind.
      expect(h.repo.deletePlan(p.id, version: p.version).failure, isNull);
      expect(h.repo.view().payments, isEmpty);
      expect(h.book().damage, isEmpty);
      h.dispose();
    });

    test('an unsupported frequency is reported, not read as monthly', () {
      final InstallmentsHarness h = InstallmentsHarness();
      h.raw(
        InstallmentsCollections.plans,
        LumeRecordId.generate(null).value,
        <String, Object?>{
          'schema': kInstallmentsSchema,
          'item': 'Bike',
          'amountMinor': 100,
          'currency': 'PKR',
          'count': 2,
          'frequency': 'weekly',
          'firstDue': '2026-09-01',
          'state': 'active',
        },
      );
      final List<InstallmentsDefect> defects = h.repo.view().defects;
      expect(defects.single.field, 'frequency');
      expect(defects.single.reason, 'unsupported');
      expect(h.book().plans, isEmpty);
      h.dispose();
    });
  });

  group('transactions', () {
    test('one notification per write, with the whole schedule already '
        'there', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final List<int> seen = <int>[];
      void listen() => seen.add(h.repo.view().schedule.length);
      h.repo.changes.addListener(listen);
      h.add(count: 12);
      expect(seen, <int>[12]);
      h.repo.changes.removeListener(listen);
      h.dispose();
    });

    test('a retried add with the same key writes one plan', () {
      final InstallmentsHarness h = InstallmentsHarness();
      h.tryAdd(idempotencyKey: 'k1');
      h.tryAdd(idempotencyKey: 'k1');
      expect(h.book().plans, hasLength(1));
      expect(h.repo.view().schedule, hasLength(12));
      h.dispose();
    });

    test('a store that refuses writes: a typed failure, nothing written', () {
      final InstallmentsHarness h = InstallmentsHarness();
      h.store.refuseWrites = true;
      final InstallmentsResult<InstallmentsWrite> r = h.tryAdd();
      expect(r.failure?.kind, InstallmentsFailureKind.storage);
      h.store.refuseWrites = false;
      expect(h.repo.view().plans, isEmpty);
      expect(h.repo.view().schedule, isEmpty);
      h.dispose();
    });

    test('a failure part-way through a delete publishes none of it', () {
      final InstallmentsHarness h = InstallmentsHarness();
      final InstallmentPlan p = h.add(count: 12);
      h.payNext(p.id, 2);
      final String before = h.store.debugDump();
      // The disk fails at the sixth change the delete publishes.
      h.store.publishFault = (_, int i) {
        if (i == 5) throw StateError('disk');
      };
      final InstallmentsResult<InstallmentsWrite> r = h.repo.deletePlan(
        p.id,
        version: p.version,
      );
      h.store.publishFault = null;
      expect(r.failure?.kind, InstallmentsFailureKind.storage);
      expect(h.store.debugDump(), before);
      h.expectSound();
      h.dispose();
    });
  });
}

/// Installments over an in-memory store, a controllable clock and seeded
/// ids — deterministic, and never the wall clock.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/installments/domain/installments_book.dart';
import 'package:lume/features/installments/domain/installments_failure.dart';
import 'package:lume/features/installments/domain/installments_model.dart';
import 'package:lume/features/installments/domain/installments_repository.dart';
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

class InstallmentsHarness {
  InstallmentsHarness({int seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = InstallmentsRepository(
      store,
      random: Random(seed),
      now: () => clock,
    );
    if (readDelay == null) repo.open();
  }

  late final LumeMemoryRecordRepository store;
  late final InstallmentsRepository repo;
  DateTime clock = DateTime.utc(2026, 9, 7, 10);

  void tick([Duration by = const Duration(minutes: 1)]) =>
      clock = clock.add(by);

  InstallmentsBook book([LumeDate? today]) => repo.view().book(today ?? kToday);

  InstallmentsResult<InstallmentsWrite> tryAdd({
    String item = 'Laptop',
    String? merchant = 'TechMart',
    String? note,
    LumeMoney? amount,
    int count = 12,
    LumeDate? firstDue,
    LumeMoney? deposit,
    LumeDate? depositOn,
    LumeMoney? cashPrice,
    String? idempotencyKey,
  }) {
    tick();
    return repo.addPlan(
      InstallmentPlanDraft(
        item: item,
        merchant: merchant,
        note: note,
        amount: amount ?? rs(9500),
        count: count,
        firstDue: firstDue ?? d(4, 14),
        deposit: deposit,
        depositOn: depositOn,
        cashPrice: cashPrice,
      ),
      idempotencyKey: idempotencyKey,
    );
  }

  InstallmentPlan add({
    String item = 'Laptop',
    String? merchant = 'TechMart',
    String? note,
    LumeMoney? amount,
    int count = 12,
    LumeDate? firstDue,
    LumeMoney? deposit,
    LumeDate? depositOn,
    LumeMoney? cashPrice,
  }) {
    final InstallmentsResult<InstallmentsWrite> r = tryAdd(
      item: item,
      merchant: merchant,
      note: note,
      amount: amount,
      count: count,
      firstDue: firstDue,
      deposit: deposit,
      depositOn: depositOn,
      cashPrice: cashPrice,
    );
    expect(r.failure, isNull, reason: 'add $item');
    return r.value!.plan!;
  }

  InstallmentPlanView plan(LumeRecordId id, [LumeDate? today]) =>
      book(today).plan(id)!;

  /// Pay the next [n] instalments, each on its due date.
  void payNext(LumeRecordId plan, [int n = 1]) {
    for (int i = 0; i < n; i++) {
      final InstallmentRow next = this.plan(plan).next!;
      tick();
      final InstallmentsResult<InstallmentsWrite> r = repo.recordPayment(
        plan,
        next.row.id,
        next.row.due,
      );
      expect(r.failure, isNull, reason: 'pay ${next.row.seq}');
    }
  }

  /// A raw record, written as it is — for damaged-state tests.
  void raw(String collection, String id, Map<String, Object?> fields) {
    final LumeTxResult<void> r = store.run<void>(
      (LumeRecordTx tx) => tx.create(collection, id, fields),
    );
    expect(r.ok, isTrue);
  }

  void expectSound() {
    final InstallmentsBook b = book();
    expect(b.invariants(), isEmpty);
    expect(b.damage, isEmpty);
  }

  /// Every record, byte for byte, in id order and without the store's
  /// revision counters — which an Undo advances, as it should.
  String records() =>
      (store.debugDump().replaceAll(RegExp(r'\] r[0-9]+'), ']').split('\n')
            ..sort())
          .join('\n');

  void dispose() => store.dispose();
}

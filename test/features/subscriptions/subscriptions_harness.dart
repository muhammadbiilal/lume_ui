/// Subscriptions over an in-memory store, a controllable clock and seeded
/// ids — deterministic, and never the wall clock.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_transaction.dart';
import 'package:lume/features/subscriptions/domain/subscriptions_book.dart';
import 'package:lume/features/subscriptions/domain/subscriptions_failure.dart';
import 'package:lume/features/subscriptions/domain/subscriptions_model.dart';
import 'package:lume/features/subscriptions/domain/subscriptions_repository.dart';

final LumeCurrency pkr = LumeCurrency.of('PKR');
final LumeCurrency usd = LumeCurrency.of('USD');

LumeMoney rs(num rupees) => LumeMoney.entry((rupees * 100).round(), pkr);
LumeMoney dollars(num d) => LumeMoney.entry((d * 100).round(), usd);
LumeDate d(int month, int day) => LumeDate(2026, month, day);
final LumeDate kToday = d(9, 7);

class SubscriptionsHarness {
  SubscriptionsHarness({int seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(hydrateDelay: readDelay, now: () => clock);
    repo = SubscriptionsRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  late final LumeMemoryRecordRepository store;
  late final SubscriptionsRepository repo;
  DateTime clock = DateTime.utc(2026, 9, 7, 10);

  void tick([Duration by = const Duration(minutes: 1)]) => clock = clock.add(by);

  SubscriptionsBook book([LumeDate? today]) => repo.view().book(today ?? kToday);

  SubscriptionsResult<SubscriptionsWrite> tryAdd({
    String name = 'Netflix',
    String? category = 'Entertainment',
    LumeMoney? amount,
    SubscriptionCycle cycle = SubscriptionCycle.monthly,
    int? customDays,
    LumeDate? startedOn,
    String? idempotencyKey,
  }) {
    tick();
    return repo.add(
      SubscriptionDraft(
        name: name,
        category: category,
        amount: amount ?? rs(9),
        cycle: cycle,
        customDays: customDays,
        startedOn: startedOn ?? d(1, 14),
      ),
      idempotencyKey: idempotencyKey,
    );
  }

  Subscription add({
    String name = 'Netflix',
    String? category = 'Entertainment',
    LumeMoney? amount,
    SubscriptionCycle cycle = SubscriptionCycle.monthly,
    int? customDays,
    LumeDate? startedOn,
  }) {
    final SubscriptionsResult<SubscriptionsWrite> r = tryAdd(
      name: name,
      category: category,
      amount: amount,
      cycle: cycle,
      customDays: customDays,
      startedOn: startedOn,
    );
    expect(r.failure, isNull, reason: 'add $name');
    return r.value!.subscription!;
  }

  SubscriptionView view(LumeRecordId id, [LumeDate? today]) =>
      book(today).subscription(id)!;

  void raw(String collection, String id, Map<String, Object?> fields) {
    final LumeTxResult<void> r = store.run<void>(
      (LumeRecordTx tx) => tx.create(collection, id, fields),
    );
    expect(r.ok, isTrue);
  }

  void dispose() => store.dispose();
}

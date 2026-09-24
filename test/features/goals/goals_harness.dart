/// Goals over an in-memory store, a controllable clock and seeded ids —
/// deterministic, and never the wall clock.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/goals/domain/goals_book.dart';
import 'package:lume/features/goals/domain/goals_failure.dart';
import 'package:lume/features/goals/domain/goals_model.dart';
import 'package:lume/features/goals/domain/goals_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_transaction.dart';

final LumeCurrency pkr = LumeCurrency.of('PKR');
final LumeCurrency usd = LumeCurrency.of('USD');

/// Rupees, in paisa.
LumeMoney rs(num rupees) => LumeMoney.entry((rupees * 100).round(), pkr);

/// Dollars, in cents.
LumeMoney dollars(num d) => LumeMoney.entry((d * 100).round(), usd);

/// 2026 dates.
LumeDate d(int month, int day) => LumeDate(2026, month, day);

/// The fixture day: 7 September 2026.
final LumeDate kToday = d(9, 7);

class GoalsHarness {
  GoalsHarness({int seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(hydrateDelay: readDelay, now: () => clock);
    repo = GoalsRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  late final LumeMemoryRecordRepository store;
  late final GoalsRepository repo;
  DateTime clock = DateTime.utc(2026, 9, 7, 10);

  void tick([Duration by = const Duration(minutes: 1)]) => clock = clock.add(by);

  GoalsBook book([LumeDate? today]) => repo.view().book(today ?? kToday);

  GoalsResult<GoalsWrite> tryAdd({
    String name = 'Emergency fund',
    String? note,
    LumeMoney? target,
    LumeDate? targetDate,
    GoalIcon icon = GoalIcon.shield,
    String? idempotencyKey,
  }) {
    tick();
    return repo.addGoal(
      GoalDraft(
        name: name,
        note: note,
        target: target ?? rs(60000),
        targetDate: targetDate,
        icon: icon,
      ),
      idempotencyKey: idempotencyKey,
    );
  }

  Goal add({
    String name = 'Emergency fund',
    String? note,
    LumeMoney? target,
    LumeDate? targetDate,
    GoalIcon icon = GoalIcon.shield,
  }) {
    final GoalsResult<GoalsWrite> r = tryAdd(
      name: name,
      note: note,
      target: target,
      targetDate: targetDate,
      icon: icon,
    );
    expect(r.failure, isNull, reason: 'add $name');
    return r.value!.goal!;
  }

  GoalView view(LumeRecordId id, [LumeDate? today]) => book(today).goal(id)!;

  GoalContribution contribute(LumeRecordId goal, LumeMoney amount, [LumeDate? on]) {
    tick();
    final GoalsResult<GoalsWrite> r = repo.addContribution(goal, amount, on ?? kToday);
    expect(r.failure, isNull, reason: 'contribute $amount');
    return r.value!.contribution!;
  }

  /// A raw record, written as it is — for damaged-state tests.
  void raw(String collection, String id, Map<String, Object?> fields) {
    final LumeTxResult<void> r = store.run<void>(
      (LumeRecordTx tx) => tx.create(collection, id, fields),
    );
    expect(r.ok, isTrue);
  }

  void expectSound() {
    final GoalsBook b = book();
    expect(b.damage, isEmpty);
  }

  void dispose() => store.dispose();
}

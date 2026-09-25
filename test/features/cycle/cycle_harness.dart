/// Cycle Tracker over an in-memory store, a controllable clock and seeded
/// ids — deterministic, and never the wall clock.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/features/cycle/domain/cycle_book.dart';
import 'package:lume/features/cycle/domain/cycle_failure.dart';
import 'package:lume/features/cycle/domain/cycle_model.dart';
import 'package:lume/features/cycle/domain/cycle_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_transaction.dart';

LumeDate d(int month, int day) => LumeDate(2026, month, day);

/// The fixture day: 7 September 2026 (a Monday).
final LumeDate kToday = d(9, 7);

class CycleHarness {
  CycleHarness({int seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(hydrateDelay: readDelay, now: () => clock);
    repo = CycleRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  late final LumeMemoryRecordRepository store;
  late final CycleRepository repo;
  DateTime clock = DateTime.utc(2026, 9, 7, 10);

  void tick([Duration by = const Duration(minutes: 1)]) => clock = clock.add(by);

  CycleInsights insights([LumeDate? today]) => repo.view().insights(today ?? kToday);

  CyclePeriod log(LumeDate start, {LumeDate? end}) {
    tick();
    final CycleResult<CycleWrite> r = repo.logPeriod(start, end: end);
    expect(r.failure, isNull, reason: 'log $start..$end: ${r.failure}');
    return r.value!.period!;
  }

  void raw(String collection, String id, Map<String, Object?> fields) {
    final LumeTxResult<void> r = store.run<void>(
      (LumeRecordTx tx) => tx.create(collection, id, fields),
    );
    expect(r.ok, isTrue);
  }

  void dispose() => store.dispose();
}

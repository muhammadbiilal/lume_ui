/// Fasting Tracker over an in-memory store, a controllable clock and seeded
/// ids — deterministic, and never the wall clock.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/features/fasting/domain/fasting_book.dart';
import 'package:lume/features/fasting/domain/fasting_failure.dart';
import 'package:lume/features/fasting/domain/fasting_model.dart';
import 'package:lume/features/fasting/domain/fasting_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_transaction.dart';

LumeDate d(int month, int day) => LumeDate(2026, month, day);

/// The fixture day: 7 September 2026 (a Monday).
final LumeDate kToday = d(9, 7);

class FastingHarness {
  FastingHarness({int seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = FastingRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  late final LumeMemoryRecordRepository store;
  late final FastingRepository repo;
  DateTime clock = DateTime.utc(2026, 9, 7, 10);

  void tick([Duration by = const Duration(minutes: 1)]) =>
      clock = clock.add(by);

  FastingInsights insights([LumeDate? today]) =>
      repo.view().insights(today ?? kToday);

  FastEntry log(
    LumeDate date, {
    FastingKind kind = FastingKind.voluntary,
    bool kept = true,
  }) {
    tick();
    final FastingResult<FastingWrite> r = repo.logFast(
      date,
      kind: kind,
      kept: kept,
    );
    expect(r.failure, isNull, reason: 'log $date: ${r.failure}');
    return r.value!.entry!;
  }

  void raw(String collection, String id, Map<String, Object?> fields) {
    final LumeTxResult<void> r = store.run<void>(
      (LumeRecordTx tx) => tx.create(collection, id, fields),
    );
    expect(r.ok, isTrue);
  }

  void dispose() => store.dispose();
}

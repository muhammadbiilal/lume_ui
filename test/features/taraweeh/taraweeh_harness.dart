/// Taraweeh over an in-memory store, a controllable clock and seeded ids —
/// deterministic, and never the wall clock.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_transaction.dart';
import 'package:lume/features/taraweeh/domain/taraweeh_book.dart';
import 'package:lume/features/taraweeh/domain/taraweeh_failure.dart';
import 'package:lume/features/taraweeh/domain/taraweeh_model.dart';
import 'package:lume/features/taraweeh/domain/taraweeh_repository.dart';

LumeDate d(int month, int day) => LumeDate(2026, month, day);

/// The fixture night: 7 September 2026 (a Monday).
final LumeDate kToday = d(9, 7);

class TaraweehHarness {
  TaraweehHarness({int seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = TaraweehRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  late final LumeMemoryRecordRepository store;
  late final TaraweehRepository repo;
  DateTime clock = DateTime.utc(2026, 9, 7, 22);

  void tick([Duration by = const Duration(minutes: 1)]) =>
      clock = clock.add(by);

  TaraweehStats stats([LumeDate? today]) => repo.view().stats(today ?? kToday);

  TaraweehNight logTonight(LumeDate date, {int rakaat = 20}) {
    tick();
    final TaraweehResult<TaraweehWrite> r = repo.logTonight(
      date,
      rakaat: rakaat,
    );
    expect(r.failure, isNull, reason: 'logTonight $date');
    return r.value!.night!;
  }

  void raw(String collection, String id, Map<String, Object?> fields) {
    final LumeTxResult<void> r = store.run<void>(
      (LumeRecordTx tx) => tx.create(collection, id, fields),
    );
    expect(r.ok, isTrue);
  }

  void dispose() => store.dispose();
}

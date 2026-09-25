/// Health Records over an in-memory store, a controllable clock and seeded
/// ids — deterministic, and never the wall clock.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/health/domain/health_book.dart';
import 'package:lume/features/health/domain/health_failure.dart';
import 'package:lume/features/health/domain/health_model.dart';
import 'package:lume/features/health/domain/health_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_transaction.dart';

LumeDate d(int month, int day) => LumeDate(2026, month, day);
final LumeDate kToday = d(9, 7);

class HealthHarness {
  HealthHarness({int seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(hydrateDelay: readDelay, now: () => clock);
    repo = HealthRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  late final LumeMemoryRecordRepository store;
  late final HealthRepository repo;
  DateTime clock = DateTime.utc(2026, 9, 7, 10);

  void tick([Duration by = const Duration(minutes: 1)]) => clock = clock.add(by);

  HealthBook book([LumeDate? today]) => repo.view().book(today ?? kToday);

  HealthResult<HealthWrite> tryAdd({
    String title = 'Annual physical',
    HealthRecordKind kind = HealthRecordKind.appointment,
    LumeDate? date,
    String? source = 'City Clinic',
    String? value,
    String? notes,
    String? idempotencyKey,
  }) {
    tick();
    return repo.add(
      HealthDraft(
        title: title,
        kind: kind,
        date: date ?? d(1, 14),
        source: source,
        value: value,
        notes: notes,
      ),
      idempotencyKey: idempotencyKey,
    );
  }

  HealthRecord add({
    String title = 'Annual physical',
    HealthRecordKind kind = HealthRecordKind.appointment,
    LumeDate? date,
    String? source = 'City Clinic',
    String? value,
    String? notes,
  }) {
    final HealthResult<HealthWrite> r = tryAdd(
      title: title,
      kind: kind,
      date: date,
      source: source,
      value: value,
      notes: notes,
    );
    expect(r.failure, isNull, reason: 'add $title');
    return r.value!.record!;
  }

  HealthRecordView view(LumeRecordId id, [LumeDate? today]) =>
      book(today).record(id)!;

  void raw(String collection, String id, Map<String, Object?> fields) {
    final LumeTxResult<void> r = store.run<void>(
      (LumeRecordTx tx) => tx.create(collection, id, fields),
    );
    expect(r.ok, isTrue);
  }

  void dispose() => store.dispose();
}

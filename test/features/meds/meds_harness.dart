/// Medication over an in-memory store, a controllable clock and seeded
/// ids — deterministic, and never the wall clock.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/meds/domain/meds_book.dart';
import 'package:lume/features/meds/domain/meds_failure.dart';
import 'package:lume/features/meds/domain/meds_model.dart';
import 'package:lume/features/meds/domain/meds_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_transaction.dart';

class MedsHarness {
  MedsHarness({int seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = MedsRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  late final LumeMemoryRecordRepository store;
  late final MedsRepository repo;
  DateTime clock = DateTime.utc(2026, 9, 7, 10);

  void tick([Duration by = const Duration(minutes: 1)]) =>
      clock = clock.add(by);

  MedsBook book() => repo.view().book();

  MedsResult<MedsWrite> tryAdd({
    String name = 'Vitamin D',
    String dose = '50,000 IU',
    MedsSchedule schedule = MedsSchedule.weekly,
    String? firstDoseAt = '09:00',
    int? dosesLeft = 8,
    String? notes,
    String? idempotencyKey,
  }) {
    tick();
    return repo.add(
      MedsDraft(
        name: name,
        dose: dose,
        schedule: schedule,
        firstDoseAt: firstDoseAt,
        dosesLeft: dosesLeft,
        notes: notes,
      ),
      idempotencyKey: idempotencyKey,
    );
  }

  MedsEntry add({
    String name = 'Vitamin D',
    String dose = '50,000 IU',
    MedsSchedule schedule = MedsSchedule.weekly,
    String? firstDoseAt = '09:00',
    int? dosesLeft = 8,
    String? notes,
  }) {
    final MedsResult<MedsWrite> r = tryAdd(
      name: name,
      dose: dose,
      schedule: schedule,
      firstDoseAt: firstDoseAt,
      dosesLeft: dosesLeft,
      notes: notes,
    );
    expect(r.failure, isNull, reason: 'add $name');
    return r.value!.medication!;
  }

  void raw(String collection, String id, Map<String, Object?> fields) {
    final LumeTxResult<void> r = store.run<void>(
      (LumeRecordTx tx) => tx.create(collection, id, fields),
    );
    expect(r.ok, isTrue);
  }

  void dispose() => store.dispose();
}

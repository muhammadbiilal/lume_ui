/// Vaccinations over an in-memory store, a controllable clock and seeded
/// ids — deterministic, and never the wall clock.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_transaction.dart';
import 'package:lume/features/vaccines/domain/vaccines_book.dart';
import 'package:lume/features/vaccines/domain/vaccines_failure.dart';
import 'package:lume/features/vaccines/domain/vaccines_model.dart';
import 'package:lume/features/vaccines/domain/vaccines_repository.dart';

LumeDate d(int month, int day) => LumeDate(2026, month, day);
final LumeDate kToday = d(9, 7);

class VaccinesHarness {
  VaccinesHarness({int seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = VaccinesRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  late final LumeMemoryRecordRepository store;
  late final VaccinesRepository repo;
  DateTime clock = DateTime.utc(2026, 9, 7, 10);

  void tick([Duration by = const Duration(minutes: 1)]) =>
      clock = clock.add(by);

  VaccinesBook book([LumeDate? today]) => repo.view().book(today ?? kToday);

  VaccinesResult<VaccinesWrite> tryAdd({
    String name = 'MMR',
    String? forWhom = 'Myself',
    String? dose,
    LumeDate? date,
    VaccineStatus status = VaccineStatus.given,
    String? provider,
    String? notes,
  }) {
    tick();
    return repo.add(
      VaccineDraft(
        name: name,
        forWhom: forWhom,
        dose: dose,
        date: date ?? d(1, 14),
        status: status,
        provider: provider,
        notes: notes,
      ),
    );
  }

  VaccineRecord add({
    String name = 'MMR',
    String? forWhom = 'Myself',
    String? dose,
    LumeDate? date,
    VaccineStatus status = VaccineStatus.given,
    String? provider,
    String? notes,
  }) {
    final VaccinesResult<VaccinesWrite> r = tryAdd(
      name: name,
      forWhom: forWhom,
      dose: dose,
      date: date,
      status: status,
      provider: provider,
      notes: notes,
    );
    expect(r.failure, isNull, reason: 'add $name');
    return r.value!.record!;
  }

  VaccineView view(LumeRecordId id, [LumeDate? today]) => book(today).view(id)!;

  void raw(String collection, String id, Map<String, Object?> fields) {
    final LumeTxResult<void> r = store.run<void>(
      (LumeRecordTx tx) => tx.create(collection, id, fields),
    );
    expect(r.ok, isTrue);
  }

  void dispose() => store.dispose();
}

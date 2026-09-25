/// Prayer Tracker over an in-memory store, a controllable clock and seeded
/// ids — deterministic, and never the wall clock.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/features/praytrack/domain/praytrack_book.dart';
import 'package:lume/features/praytrack/domain/praytrack_failure.dart';
import 'package:lume/features/praytrack/domain/praytrack_model.dart';
import 'package:lume/features/praytrack/domain/praytrack_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_transaction.dart';

LumeDate d(int month, int day) => LumeDate(2026, month, day);

/// The fixture day: 7 September 2026 (a Monday).
final LumeDate kToday = d(9, 7);

class PrayTrackHarness {
  PrayTrackHarness({int seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(hydrateDelay: readDelay, now: () => clock);
    repo = PrayTrackRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  late final LumeMemoryRecordRepository store;
  late final PrayTrackRepository repo;
  DateTime clock = DateTime.utc(2026, 9, 7, 10);

  void tick([Duration by = const Duration(minutes: 1)]) => clock = clock.add(by);

  PrayTrackStats stats([LumeDate? today]) => repo.view().stats(today ?? kToday);

  PrayTrackResult<PrayTrackWrite> tryToggle(PrayerKey k, LumeDate date) {
    tick();
    return repo.toggle(k, date);
  }

  PrayerCheckin toggle(PrayerKey k, LumeDate date) {
    final PrayTrackResult<PrayTrackWrite> r = tryToggle(k, date);
    expect(r.failure, isNull, reason: 'toggle $k $date');
    expect(r.value!.checkin, isNotNull, reason: 'toggle $k $date should have created one');
    return r.value!.checkin!;
  }

  /// Marks every one of the five prayers done on [date] — a "complete" day.
  void completeDay(LumeDate date) {
    for (final PrayerKey k in PrayerKey.values) {
      toggle(k, date);
    }
  }

  void raw(String collection, String id, Map<String, Object?> fields) {
    final LumeTxResult<void> r = store.run<void>(
      (LumeRecordTx tx) => tx.create(collection, id, fields),
    );
    expect(r.ok, isTrue);
  }

  void dispose() => store.dispose();
}

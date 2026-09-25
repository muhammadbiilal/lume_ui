/// Reminders over the real, FFI-backed SQLite repository — sqflite's own
/// documented test pattern, no mock, no platform channel
/// (`REMINDERS_PROPOSAL.md` §2).
library;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lume/features/records/data/sqlite_record_repository.dart';
import 'package:lume/features/reminders/data/reminder_scheduler.dart';
import 'package:lume/features/reminders/domain/reminder_book.dart';
import 'package:lume/features/reminders/domain/reminder_failure.dart';
import 'package:lume/features/reminders/domain/reminder_model.dart';
import 'package:lume/features/reminders/domain/reminder_repository.dart';

/// Once per test process — sqflite_common_ffi's own required setup.
void initReminderTestDatabase() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

DateTime kFixtureNow = DateTime(2026, 9, 7, 8, 0);

class ReminderHarness {
  ReminderHarness({int seed = 1})
    : store = LumeSqliteRecordRepository(
        path: ':memory:',
        now: () => kFixtureNow,
        open: (String path) => databaseFactoryFfi.openDatabase(
          ':memory:',
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (Database db, int v) => db.execute(
              'CREATE TABLE records ('
              'collection TEXT NOT NULL, '
              'id TEXT NOT NULL, '
              'fields TEXT NOT NULL, '
              'version INTEGER NOT NULL, '
              'created_at TEXT NOT NULL, '
              'updated_at TEXT NOT NULL, '
              'PRIMARY KEY (collection, id))',
            ),
          ),
        ),
      ),
      scheduler = LumeFakeReminderScheduler() {
    repo = ReminderRepository(store, scheduler, random: null, now: () => kFixtureNow);
    repo.open();
  }

  final LumeSqliteRecordRepository store;
  final LumeFakeReminderScheduler scheduler;
  late final ReminderRepository repo;

  static const String zone = 'Asia/Karachi';

  Future<ReminderEntry> add({
    String label = 'Take a break',
    int atHour = 9,
    int atMinute = 0,
    ReminderRepeat repeat = ReminderRepeat.once,
    String? notes,
    String? zoneId = zone,
  }) async {
    final ReminderResult<ReminderWrite> r = await repo.add(
      label: label,
      atHour: atHour,
      atMinute: atMinute,
      repeat: repeat,
      notes: notes,
      zoneId: zoneId,
    );
    if (!r.ok) throw StateError('${r.failure}');
    return r.value!.entry!;
  }

  /// Waits for hydration (the async SQLite read) to settle.
  Future<void> settle() async {
    for (int i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
      if (!repo.view().loading) return;
    }
  }

  ReminderBook book() => repo.view().book;

  Future<void> dispose() async {
    await store.flush();
    await store.dispose();
  }
}

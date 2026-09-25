import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lume/features/records/data/sqlite_record_repository.dart';
import 'package:lume/features/reminders/data/reminder_scheduler.dart';
import 'package:lume/features/reminders/domain/reminder_book.dart';
import 'package:lume/features/reminders/domain/reminder_failure.dart';
import 'package:lume/features/reminders/domain/reminder_model.dart';
import 'package:lume/features/reminders/domain/reminder_repository.dart';

import 'reminders_harness.dart';

void main() {
  setUpAll(initReminderTestDatabase);

  group('model and codec', () {
    test('an entry round-trips through its fields', () async {
      final ReminderHarness h = ReminderHarness();
      addTearDown(h.dispose);
      final ReminderEntry e = await h.add(
        label: 'Drink water',
        atHour: 14,
        atMinute: 30,
      );
      expect(e.label, 'Drink water');
      expect(e.atHour, 14);
      expect(e.atMinute, 30);
      expect(e.repeat, ReminderRepeat.once);
      expect(e.enabled, isTrue);
      expect(e.version, 1);
    });

    test('an empty label is refused', () async {
      final ReminderHarness h = ReminderHarness();
      addTearDown(h.dispose);
      final ReminderResult<ReminderWrite> r = await h.repo.add(
        label: '   ',
        atHour: 9,
        atMinute: 0,
        zoneId: ReminderHarness.zone,
      );
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'label');
    });

    test('a record of the wrong schema is a defect, not a crash', () async {
      final ReminderHarness h = ReminderHarness();
      addTearDown(h.dispose);
      await h.add();
      h.store.run<void>((tx) {
        tx.create('reminder.entry', 'bad-id', <String, Object?>{
          'schema': 'lume.other/1',
        });
      });
      final ReminderBook book = h.book();
      expect(
        book.entries.length,
        1,
      ); // the good one only; the bad one is a defect
    });
  });

  group('edit and enable/disable', () {
    test('editing replaces fields and bumps the version', () async {
      final ReminderHarness h = ReminderHarness();
      addTearDown(h.dispose);
      final ReminderEntry e = await h.add(label: 'Old');
      final ReminderResult<ReminderWrite> r = await h.repo.edit(
        e.id,
        label: 'New',
        zoneId: ReminderHarness.zone,
      );
      expect(r.ok, isTrue);
      expect(r.value!.entry!.label, 'New');
      expect(r.value!.entry!.version, 2);
    });

    test(
      'disabling cancels the scheduled notification without deleting the record',
      () async {
        final ReminderHarness h = ReminderHarness();
        addTearDown(h.dispose);
        final ReminderEntry e = await h.add();
        expect(h.scheduler.scheduled, contains(e.id.value));
        final ReminderResult<ReminderWrite> r = await h.repo.setEnabled(
          e.id,
          false,
          zoneId: ReminderHarness.zone,
        );
        expect(r.ok, isTrue);
        expect(r.value!.entry!.enabled, isFalse);
        expect(h.scheduler.scheduled, isNot(contains(e.id.value)));
        expect(h.book().entries, hasLength(1)); // still there, just off
      },
    );
  });

  group('delete and undo', () {
    test('deleting removes the record and cancels its notification', () async {
      final ReminderHarness h = ReminderHarness();
      addTearDown(h.dispose);
      final ReminderEntry e = await h.add();
      final ReminderResult<ReminderWrite> r = await h.repo.remove(e.id);
      expect(r.ok, isTrue);
      expect(h.book().isEmpty, isTrue);
      expect(h.scheduler.cancelled, contains(e.id.value));
    });

    test('undo restores the record and reschedules it', () async {
      final ReminderHarness h = ReminderHarness();
      addTearDown(h.dispose);
      final ReminderEntry e = await h.add(label: 'Stretch');
      final ReminderResult<ReminderWrite> deleted = await h.repo.remove(e.id);
      final ReminderResult<void> u = await h.repo.undo(
        deleted.value!,
        zoneId: ReminderHarness.zone,
      );
      expect(u.ok, isTrue);
      expect(h.book().entries.single.label, 'Stretch');
      expect(h.scheduler.scheduled, contains(e.id.value));
    });
  });

  group('scheduling outcomes', () {
    test('no zone resolved: saved, but not scheduled', () async {
      final ReminderHarness h = ReminderHarness();
      addTearDown(h.dispose);
      final ReminderResult<ReminderWrite> r = await h.repo.add(
        label: 'Call mum',
        atHour: 9,
        atMinute: 0,
        zoneId: null,
      );
      expect(r.ok, isTrue);
      expect(r.value!.scheduleOutcome, ReminderScheduleOutcome.zoneUnresolved);
      expect(h.book().entries, hasLength(1)); // the record itself always saves
      expect(h.scheduler.scheduled, isEmpty);
    });
  });

  group('durable — the one repository that survives the app closing', () {
    test('LumeSqliteRecordRepository reports durable: true', () async {
      final ReminderHarness h = ReminderHarness();
      addTearDown(h.dispose);
      expect(h.repo.durable, isTrue);
      expect(h.store.durable, isTrue);
    });

    test(
      'a record written by one instance is read back by a fresh one, same file',
      () async {
        final Directory dir = await Directory.systemTemp.createTemp(
          'lume_reminders_test',
        );
        final String path = '${dir.path}/reminders.db';
        addTearDown(() async {
          try {
            await dir.delete(recursive: true);
          } on FileSystemException {
            // Windows can hold the handle briefly after close(); harmless.
          }
        });

        Future<Database> open(String p) => databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (Database db, int v) => db.execute(
              'CREATE TABLE records ('
              'collection TEXT NOT NULL, id TEXT NOT NULL, fields TEXT NOT NULL, '
              'version INTEGER NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL, '
              'PRIMARY KEY (collection, id))',
            ),
          ),
        );

        final LumeSqliteRecordRepository first = LumeSqliteRecordRepository(
          path: path,
          now: () => kFixtureNow,
          open: open,
        );
        final ReminderRepository firstRepo = ReminderRepository(
          first,
          LumeFakeReminderScheduler(),
          now: () => kFixtureNow,
        );
        firstRepo.open();
        final ReminderResult<ReminderWrite> r = await firstRepo.add(
          label: 'Survives a restart',
          atHour: 7,
          atMinute: 15,
          zoneId: ReminderHarness.zone,
        );
        expect(r.ok, isTrue);
        await first.flush();
        await first.dispose();

        final LumeSqliteRecordRepository second = LumeSqliteRecordRepository(
          path: path,
          now: () => kFixtureNow,
          open: open,
        );
        final ReminderRepository secondRepo = ReminderRepository(
          second,
          LumeFakeReminderScheduler(),
          now: () => kFixtureNow,
        );
        secondRepo.open();
        for (int i = 0; i < 200 && secondRepo.view().loading; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        expect(
          secondRepo.view().loading,
          isFalse,
          reason: 'hydration never finished',
        );
        expect(secondRepo.view().entries.single.label, 'Survives a restart');
        await second.dispose();
      },
    );
  });
}

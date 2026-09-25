import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/health/domain/health_book.dart';
import 'package:lume/features/health/domain/health_failure.dart';
import 'package:lume/features/health/domain/health_model.dart';
import 'package:lume/features/health/domain/health_repository.dart';

import 'health_harness.dart';

void main() {
  group('model and codec', () {
    test('a record round-trips through its fields', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      final HealthRecord r = h.add(
        title: 'Lipid panel',
        kind: HealthRecordKind.report,
        source: 'City Lab',
        value: '4.9 mmol/L',
        notes: 'Fasting sample',
      );
      expect(r.title, 'Lipid panel');
      expect(r.kind, HealthRecordKind.report);
      expect(r.source, 'City Lab');
      expect(r.value, '4.9 mmol/L');
      expect(r.notes, 'Fasting sample');
    });

    test('an empty title is refused', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      final HealthResult<HealthWrite> r = h.tryAdd(title: '  ');
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'title');
    });

    test('a title over the length limit is refused', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      final HealthResult<HealthWrite> r = h.tryAdd(title: 'x' * (kHealthTitleMax + 1));
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'title');
    });

    test('an optional field over its limit is refused', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      final HealthResult<HealthWrite> r = h.tryAdd(notes: 'x' * (kHealthNotesMax + 1));
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'notes');
    });

    test('source, value and notes are optional', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      final HealthRecord r = h.add(source: null, value: null, notes: null);
      expect(r.source, isNull);
      expect(r.value, isNull);
      expect(r.notes, isNull);
    });

    test('a record of the wrong schema is a defect, not a crash', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      h.raw(HealthCollections.records, 'not-a-uuid', <String, Object?>{
        'schema': 'lume.other/1',
      });
      expect(h.book().defects, hasLength(1));
      expect(h.book().defects.first.reason, 'schema');
    });

    test('an unrecognised kind is a defect', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      h.raw(HealthCollections.records, '11111111-1111-4111-8111-111111111111', <String, Object?>{
        'schema': kHealthSchema,
        'title': 'Something',
        'kind': 'diagnosis', // not a real option
        'date': '2026-01-01',
      });
      expect(h.book().defects, hasLength(1));
      expect(h.book().defects.first.field, 'kind');
    });
  });

  group('derived view — real arithmetic, never fabricated', () {
    test('a future date is upcoming, with real days-until', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      final HealthRecord r = h.add(date: d(9, 14));
      final HealthRecordView v = h.view(r.id, kToday);
      expect(v.isUpcoming, isTrue);
      expect(v.daysUntil, 7);
    });

    test('today counts as upcoming, at zero days', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      final HealthRecord r = h.add(date: kToday);
      final HealthRecordView v = h.view(r.id, kToday);
      expect(v.isUpcoming, isTrue);
      expect(v.daysUntil, 0);
    });

    test('a past date is not upcoming', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      final HealthRecord r = h.add(date: d(1, 1));
      final HealthRecordView v = h.view(r.id, kToday);
      expect(v.isUpcoming, isFalse);
      expect(v.daysUntil, isNegative);
    });

    test('without the reader\'s day, nothing is claimed upcoming', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      final HealthRecord r = h.add(date: d(9, 14));
      final HealthRecordView v = h.repo.view().book(null).record(r.id)!;
      expect(v.daysUntil, isNull);
      expect(v.isUpcoming, isFalse);
    });

    test('counts by kind are real tallies', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      h.add(kind: HealthRecordKind.appointment);
      h.add(kind: HealthRecordKind.appointment);
      h.add(kind: HealthRecordKind.report);
      final HealthBook book = h.book();
      expect(book.countsByKind[HealthRecordKind.appointment], 2);
      expect(book.countsByKind[HealthRecordKind.report], 1);
      expect(book.kindsUsed, 2);
    });

    test('upcomingCount is null without a today, and a real count with one', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      h.add(date: d(9, 14));
      h.add(date: d(1, 1));
      expect(h.repo.view().book(null).upcomingCount, isNull);
      expect(h.book().upcomingCount, 1);
    });
  });

  group('edit, delete, undo', () {
    test('editing changes every field, at any time', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      final HealthRecord r = h.add(title: 'Old title');
      final HealthResult<HealthWrite> e = h.repo.edit(
        r.id,
        HealthDraft(
          title: 'New title',
          kind: HealthRecordKind.measurement,
          date: d(2, 2),
          source: 'New source',
          value: '80 kg',
          notes: 'Updated',
        ),
        version: r.version,
      );
      expect(e.ok, isTrue);
      final HealthRecord now = e.value!.record!;
      expect(now.title, 'New title');
      expect(now.kind, HealthRecordKind.measurement);
      expect(now.value, '80 kg');
    });

    test('editing with a stale version is a conflict', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      final HealthRecord r = h.add();
      h.repo.edit(r.id, HealthDraft(title: 'First edit', kind: r.kind, date: r.date), version: r.version);
      final HealthResult<HealthWrite> stale = h.repo.edit(
        r.id,
        HealthDraft(title: 'Second edit', kind: r.kind, date: r.date),
        version: r.version, // the original, now stale
      );
      expect(stale.ok, isFalse);
      expect(stale.failure!.kind, HealthFailureKind.conflict);
    });

    test('deleting removes the record', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      final HealthRecord r = h.add();
      final HealthResult<HealthWrite> del = h.repo.delete(r.id, version: r.version);
      expect(del.ok, isTrue);
      expect(h.repo.view().records, isEmpty);
    });

    test('deleting twice is a not-found failure, not a crash', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      final HealthRecord r = h.add();
      h.repo.delete(r.id, version: r.version);
      final HealthResult<HealthWrite> again = h.repo.delete(r.id, version: r.version);
      expect(again.ok, isFalse);
      expect(again.failure!.kind, HealthFailureKind.notFound);
    });

    test('the store\'s generic revert still restores a deleted record — the '
        'proof that the mechanism the screen deliberately never offers here '
        'still works underneath it', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      final HealthRecord r = h.add();
      final HealthResult<HealthWrite> del = h.repo.delete(r.id, version: r.version);
      expect(h.repo.view().records, isEmpty);
      final HealthResult<void> u = h.repo.undo(del.value!);
      expect(u.ok, isTrue);
      expect(h.repo.view().records, hasLength(1));
    });
  });

  group('Option B — non-durability', () {
    test('the repository reports itself as not durable', () {
      final HealthHarness h = HealthHarness();
      addTearDown(h.dispose);
      expect(h.repo.durable, isFalse);
    });
  });
}

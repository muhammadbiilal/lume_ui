import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/vaccines/domain/vaccines_book.dart';
import 'package:lume/features/vaccines/domain/vaccines_failure.dart';
import 'package:lume/features/vaccines/domain/vaccines_model.dart';
import 'package:lume/features/vaccines/domain/vaccines_repository.dart';

import 'vaccines_harness.dart';

void main() {
  group('model and codec', () {
    test('a vaccination round-trips through its fields', () {
      final VaccinesHarness h = VaccinesHarness();
      addTearDown(h.dispose);
      final VaccineRecord r = h.add(
        name: 'MMR',
        forWhom: 'Amara',
        dose: '2nd dose',
        date: d(3, 1),
        status: VaccineStatus.given,
        provider: 'City Clinic',
        notes: 'No reaction',
      );
      expect(r.name, 'MMR');
      expect(r.forWhom, 'Amara');
      expect(r.dose, '2nd dose');
      expect(r.date, d(3, 1));
      expect(r.status, VaccineStatus.given);
      expect(r.provider, 'City Clinic');
      expect(r.notes, 'No reaction');
      expect(r.version, 1);
    });

    test('an empty name is refused', () {
      final VaccinesHarness h = VaccinesHarness();
      addTearDown(h.dispose);
      final VaccinesResult<VaccinesWrite> r = h.tryAdd(name: '   ');
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'name');
    });

    test('a name over the limit is refused', () {
      final VaccinesHarness h = VaccinesHarness();
      addTearDown(h.dispose);
      final VaccinesResult<VaccinesWrite> r = h.tryAdd(
        name: 'x' * (kVaccinesNameMax + 1),
      );
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'name');
      expect(r.failure!.reason, 'long');
    });

    test('optional fields left blank decode as null, never empty strings', () {
      final VaccinesHarness h = VaccinesHarness();
      addTearDown(h.dispose);
      final VaccineRecord r = h.add(
        name: 'Tetanus',
        forWhom: null,
        dose: null,
        provider: null,
      );
      expect(r.forWhom, isNull);
      expect(r.dose, isNull);
      expect(r.provider, isNull);
      expect(r.notes, isNull);
    });

    test('a record of the wrong schema is a defect, not a crash', () {
      final VaccinesHarness h = VaccinesHarness();
      addTearDown(h.dispose);
      h.raw(VaccinesCollections.records, 'not-a-uuid', <String, Object?>{
        'schema': 'lume.other/1',
      });
      expect(h.book().defects, hasLength(1));
      expect(h.book().defects.first.reason, 'schema');
    });
  });

  group('status and overdue — worked out, never a second stored fact', () {
    test('a due vaccination whose date has passed is overdue', () {
      final VaccinesHarness h = VaccinesHarness();
      addTearDown(h.dispose);
      final VaccineRecord r = h.add(status: VaccineStatus.due, date: d(1, 1));
      final VaccineView v = h.view(r.id, kToday);
      expect(v.overdue, isTrue);
      expect(v.daysUntil, lessThan(0));
    });

    test('a due vaccination in the future is not overdue', () {
      final VaccinesHarness h = VaccinesHarness();
      addTearDown(h.dispose);
      final VaccineRecord r = h.add(status: VaccineStatus.due, date: d(12, 1));
      final VaccineView v = h.view(r.id, kToday);
      expect(v.overdue, isFalse);
      expect(v.daysUntil, greaterThan(0));
    });

    test('a given vaccination is never overdue, whatever its date', () {
      final VaccinesHarness h = VaccinesHarness();
      addTearDown(h.dispose);
      final VaccineRecord r = h.add(status: VaccineStatus.given, date: d(1, 1));
      final VaccineView v = h.view(r.id, kToday);
      expect(v.overdue, isFalse);
    });

    test('without the reader\'s day, nothing is called overdue', () {
      final VaccinesHarness h = VaccinesHarness();
      addTearDown(h.dispose);
      final VaccineRecord r = h.add(status: VaccineStatus.due, date: d(1, 1));
      final VaccineView v = h.repo.view().book(null).view(r.id)!;
      expect(v.overdue, isFalse);
      expect(v.daysUntil, isNull);
    });
  });

  group('summary — real counts, never a fixture literal', () {
    test('given/due/total/progress over the reader\'s own records', () {
      final VaccinesHarness h = VaccinesHarness();
      addTearDown(h.dispose);
      h.add(name: 'MMR', status: VaccineStatus.given);
      h.add(name: 'DTP', status: VaccineStatus.given);
      h.add(name: 'Polio', status: VaccineStatus.due);
      final VaccinesBook book = h.book();
      expect(book.total, 3);
      expect(book.givenCount, 2);
      expect(book.dueCount, 1);
      expect(book.progress, closeTo(2 / 3, 1e-9));
    });

    test('an empty book has zero progress, never a division by zero crash', () {
      final VaccinesHarness h = VaccinesHarness();
      addTearDown(h.dispose);
      expect(h.book().progress, 0);
      expect(h.book().isEmpty, isTrue);
    });

    test('upcoming is the still-due records, soonest first', () {
      final VaccinesHarness h = VaccinesHarness();
      addTearDown(h.dispose);
      final VaccineRecord later = h.add(
        name: 'Later',
        status: VaccineStatus.due,
        date: d(12, 1),
      );
      final VaccineRecord soon = h.add(
        name: 'Soon',
        status: VaccineStatus.due,
        date: d(9, 10),
      );
      h.add(name: 'Given', status: VaccineStatus.given, date: d(1, 1));
      final List<VaccineView>? up = h.book().upcoming();
      expect(up, isNotNull);
      expect(up!.map((VaccineView v) => v.record.id), <dynamic>[
        soon.id,
        later.id,
      ]);
    });
  });

  group('edit', () {
    test('edits every field, including switching due to given', () {
      final VaccinesHarness h = VaccinesHarness();
      addTearDown(h.dispose);
      final VaccineRecord r = h.add(
        name: 'MMR',
        status: VaccineStatus.due,
        date: d(1, 1),
      );
      final VaccinesResult<VaccinesWrite> edited = h.repo.edit(
        r.id,
        VaccineDraft(name: 'MMR', date: d(2, 2), status: VaccineStatus.given),
        version: r.version,
      );
      expect(edited.ok, isTrue);
      expect(edited.value!.record!.status, VaccineStatus.given);
      expect(edited.value!.record!.date, d(2, 2));
      expect(edited.value!.record!.version, r.version + 1);
    });

    test('editing with a stale version is a conflict', () {
      final VaccinesHarness h = VaccinesHarness();
      addTearDown(h.dispose);
      final VaccineRecord r = h.add();
      h.repo.edit(
        r.id,
        VaccineDraft(name: 'MMR', date: d(2, 2)),
        version: r.version,
      );
      final VaccinesResult<VaccinesWrite> stale = h.repo.edit(
        r.id,
        VaccineDraft(name: 'MMR again', date: d(3, 3)),
        version: r.version, // the version before the first edit
      );
      expect(stale.ok, isFalse);
      expect(stale.failure!.kind, VaccinesFailureKind.conflict);
    });
  });

  group(
    'delete, undo — the repository stays uniform even though the UI never offers Undo',
    () {
      test('deleting removes the record', () {
        final VaccinesHarness h = VaccinesHarness();
        addTearDown(h.dispose);
        final VaccineRecord r = h.add();
        final VaccinesResult<VaccinesWrite> del = h.repo.delete(
          r.id,
          version: r.version,
        );
        expect(del.ok, isTrue);
        expect(h.repo.view().records, isEmpty);
      });

      test(
        'deleting with a stale version is a conflict, not a silent success',
        () {
          final VaccinesHarness h = VaccinesHarness();
          addTearDown(h.dispose);
          final VaccineRecord r = h.add();
          h.repo.edit(
            r.id,
            VaccineDraft(name: 'MMR', date: d(2, 2)),
            version: r.version,
          );
          final VaccinesResult<VaccinesWrite> del = h.repo.delete(
            r.id,
            version: r.version,
          );
          expect(del.ok, isFalse);
          expect(del.failure!.kind, VaccinesFailureKind.conflict);
        },
      );

      test(
        'the domain layer can still reverse a delete, even though no screen calls it',
        () {
          final VaccinesHarness h = VaccinesHarness();
          addTearDown(h.dispose);
          final VaccineRecord r = h.add();
          final VaccinesResult<VaccinesWrite> del = h.repo.delete(
            r.id,
            version: r.version,
          );
          final VaccinesResult<void> u = h.repo.undo(del.value!);
          expect(u.ok, isTrue);
          expect(h.repo.view().records, hasLength(1));
        },
      );
    },
  );

  group('Option B — non-durability', () {
    test('the repository reports itself as not durable', () {
      final VaccinesHarness h = VaccinesHarness();
      addTearDown(h.dispose);
      expect(h.repo.durable, isFalse);
    });
  });
}

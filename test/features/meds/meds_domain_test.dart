import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/meds/domain/meds_failure.dart';
import 'package:lume/features/meds/domain/meds_model.dart';
import 'package:lume/features/meds/domain/meds_repository.dart';

import 'meds_harness.dart';

void main() {
  group('model and codec', () {
    test('a medication round-trips through its fields', () {
      final MedsHarness h = MedsHarness();
      addTearDown(h.dispose);
      final MedsEntry m = h.add(
        name: 'Metformin',
        dose: '500 mg',
        schedule: MedsSchedule.twice,
        firstDoseAt: '08:00',
        dosesLeft: 22,
        notes: 'With food',
      );
      expect(m.name, 'Metformin');
      expect(m.dose, '500 mg');
      expect(m.schedule, MedsSchedule.twice);
      expect(m.firstDoseAt, '08:00');
      expect(m.dosesLeft, 22);
      expect(m.notes, 'With food');
      expect(m.version, 1);
    });

    test('an empty name is refused', () {
      final MedsHarness h = MedsHarness();
      addTearDown(h.dispose);
      final MedsResult<MedsWrite> r = h.tryAdd(name: '   ');
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'name');
    });

    test('an empty dose is refused', () {
      final MedsHarness h = MedsHarness();
      addTearDown(h.dispose);
      final MedsResult<MedsWrite> r = h.tryAdd(dose: '  ');
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'dose');
    });

    test('a name past the length limit is refused', () {
      final MedsHarness h = MedsHarness();
      addTearDown(h.dispose);
      final MedsResult<MedsWrite> r = h.tryAdd(name: 'x' * (kMedsNameMax + 1));
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'name');
    });

    test('a negative doses-left count is refused', () {
      final MedsHarness h = MedsHarness();
      addTearDown(h.dispose);
      final MedsResult<MedsWrite> r = h.tryAdd(dosesLeft: -1);
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'dosesLeft');
    });

    test('a malformed first-dose time is refused', () {
      final MedsHarness h = MedsHarness();
      addTearDown(h.dispose);
      final MedsResult<MedsWrite> r = h.tryAdd(firstDoseAt: '25:99');
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'firstDoseAt');
    });

    test(
      'no dosesLeft, no firstDoseAt and no notes are all fine — every extra field is optional',
      () {
        final MedsHarness h = MedsHarness();
        addTearDown(h.dispose);
        final MedsEntry m = h.add(
          dosesLeft: null,
          firstDoseAt: null,
          notes: null,
        );
        expect(m.dosesLeft, isNull);
        expect(m.firstDoseAt, isNull);
        expect(m.notes, isNull);
        expect(m.runningLow, isFalse);
      },
    );

    test('a record of the wrong schema is a defect, not a crash', () {
      final MedsHarness h = MedsHarness();
      addTearDown(h.dispose);
      h.raw(MedsCollections.medications, 'not-a-uuid', <String, Object?>{
        'schema': 'lume.other/1',
      });
      expect(h.book().medications, isEmpty);
      expect(h.repo.view().defects, hasLength(1));
      expect(h.repo.view().defects.first.reason, 'schema');
    });
  });

  group('running low — the reference\'s own rule, over real data', () {
    test('at or below 3 and above zero is running low', () {
      final MedsHarness h = MedsHarness();
      addTearDown(h.dispose);
      final MedsEntry m = h.add(dosesLeft: 3);
      expect(m.runningLow, isTrue);
      expect(h.book().runningLow.map((MedsEntry e) => e.id), <dynamic>[m.id]);
    });

    test('zero left is not "running low" — it is out', () {
      final MedsHarness h = MedsHarness();
      addTearDown(h.dispose);
      final MedsEntry m = h.add(dosesLeft: 0);
      expect(m.runningLow, isFalse);
    });

    test('above 3 is not running low', () {
      final MedsHarness h = MedsHarness();
      addTearDown(h.dispose);
      final MedsEntry m = h.add(dosesLeft: 4);
      expect(m.runningLow, isFalse);
      expect(h.book().runningLow, isEmpty);
    });
  });

  group('book — alphabetical and stable', () {
    test('medications are sorted by name, case-insensitively', () {
      final MedsHarness h = MedsHarness();
      addTearDown(h.dispose);
      h.add(name: 'vitamin d');
      h.add(name: 'Amoxicillin');
      h.add(name: 'Cetirizine');
      final List<String> names = h
          .book()
          .medications
          .map((MedsEntry m) => m.name)
          .toList();
      expect(names, <String>['Amoxicillin', 'Cetirizine', 'vitamin d']);
    });
  });

  group('edit', () {
    test('every field can change, including clearing the optional ones', () {
      final MedsHarness h = MedsHarness();
      addTearDown(h.dispose);
      final MedsEntry m = h.add(dosesLeft: 10, notes: 'old note');
      final MedsResult<MedsWrite> r = h.repo.edit(
        m.id,
        MedsDraft(
          name: m.name,
          dose: m.dose,
          schedule: MedsSchedule.needed,
          firstDoseAt: null,
          dosesLeft: null,
          notes: null,
        ),
        version: m.version,
      );
      expect(r.ok, isTrue);
      final MedsEntry edited = r.value!.medication!;
      expect(edited.schedule, MedsSchedule.needed);
      expect(edited.firstDoseAt, isNull);
      expect(edited.dosesLeft, isNull);
      expect(edited.notes, isNull);
      expect(edited.version, m.version + 1);
    });
  });

  group('conflict', () {
    test(
      'editing with a stale version is refused as a conflict, not overwritten',
      () {
        final MedsHarness h = MedsHarness();
        addTearDown(h.dispose);
        final MedsEntry m = h.add();
        // Someone else's edit lands first, raising the version.
        h.repo.edit(
          m.id,
          MedsDraft(name: m.name, dose: 'changed', schedule: m.schedule),
          version: m.version,
        );
        // This caller still holds the version from before that edit.
        final MedsResult<MedsWrite> stale = h.repo.edit(
          m.id,
          MedsDraft(name: m.name, dose: 'stale write', schedule: m.schedule),
          version: m.version,
        );
        expect(stale.ok, isFalse);
        expect(stale.failure!.kind, MedsFailureKind.conflict);
        // The winning edit is untouched.
        expect(h.book().medication(m.id)!.dose, 'changed');
      },
    );

    test(
      'deleting an already-deleted medication is a conflict, not a crash',
      () {
        final MedsHarness h = MedsHarness();
        addTearDown(h.dispose);
        final MedsEntry m = h.add();
        final MedsResult<MedsWrite> first = h.repo.delete(
          m.id,
          version: m.version,
        );
        expect(first.ok, isTrue);
        final MedsResult<MedsWrite> second = h.repo.delete(
          m.id,
          version: m.version,
        );
        expect(second.ok, isFalse);
      },
    );
  });

  group('delete, undo', () {
    test('deleting, then undo, restores it exactly', () {
      final MedsHarness h = MedsHarness();
      addTearDown(h.dispose);
      final MedsEntry m = h.add(name: 'Cetirizine', dosesLeft: 9);
      final MedsResult<MedsWrite> del = h.repo.delete(m.id, version: m.version);
      expect(h.repo.view().medications, isEmpty);
      final MedsResult<void> u = h.repo.undo(del.value!);
      expect(u.ok, isTrue);
      final List<MedsEntry> back = h.repo.view().medications;
      expect(back, hasLength(1));
      expect(back.single.name, 'Cetirizine');
      expect(back.single.dosesLeft, 9);
    });
  });

  group('Option B — non-durability', () {
    test('the repository reports itself as not durable', () {
      final MedsHarness h = MedsHarness();
      addTearDown(h.dispose);
      expect(h.repo.durable, isFalse);
    });
  });
}

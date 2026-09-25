import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/mealplan/domain/mealplan_book.dart';
import 'package:lume/features/mealplan/domain/mealplan_failure.dart';
import 'package:lume/features/mealplan/domain/mealplan_model.dart';
import 'package:lume/features/mealplan/domain/mealplan_repository.dart';

import 'mealplan_harness.dart';

void main() {
  group('model and codec', () {
    test('an entry round-trips through its fields', () {
      final MealPlanHarness h = MealPlanHarness();
      addTearDown(h.dispose);
      final MealPlanEntry e = h.set(kToday, MealSlot.breakfast, 'Oats');
      expect(e.date, kToday);
      expect(e.slot, MealSlot.breakfast);
      expect(e.text, 'Oats');
      expect(e.version, 1);
    });

    test(
      'blank text is refused — clearing is a delete, not an empty write',
      () {
        final MealPlanHarness h = MealPlanHarness();
        addTearDown(h.dispose);
        final MealPlanResult<MealPlanWrite> r = h.repo.setSlot(
          kToday,
          MealSlot.lunch,
          '   ',
        );
        expect(r.ok, isFalse);
        expect(r.failure!.field, 'text');
      },
    );

    test('a record of the wrong schema is a defect, not a crash', () {
      final MealPlanHarness h = MealPlanHarness();
      addTearDown(h.dispose);
      h.raw(MealPlanCollections.entries, 'not-a-uuid', <String, Object?>{
        'schema': 'lume.other/1',
      });
      expect(
        h.week().days.every((MealPlanDay d) => d.filledCount == 0),
        isTrue,
      );
    });
  });

  group('upsert — one entry per (date, slot)', () {
    test(
      'setting an already-filled slot replaces it in place, never duplicates',
      () {
        final MealPlanHarness h = MealPlanHarness();
        addTearDown(h.dispose);
        final MealPlanEntry first = h.set(kToday, MealSlot.dinner, 'Daal');
        final MealPlanEntry second = h.set(kToday, MealSlot.dinner, 'Karahi');

        expect(second.id, first.id); // same record, updated
        expect(second.version, first.version + 1);
        final MealPlanWeek week = h.week();
        expect(week.days.first.slot(MealSlot.dinner)!.text, 'Karahi');
        expect(week.filled, 1); // not 2
      },
    );

    test('different slots on the same day are independent', () {
      final MealPlanHarness h = MealPlanHarness();
      addTearDown(h.dispose);
      h.set(kToday, MealSlot.breakfast, 'Oats');
      h.set(kToday, MealSlot.lunch, 'Salad');
      final MealPlanDay today = h.week().days.first;
      expect(today.slot(MealSlot.breakfast)!.text, 'Oats');
      expect(today.slot(MealSlot.lunch)!.text, 'Salad');
      expect(today.slot(MealSlot.dinner), isNull);
      expect(today.filledCount, 2);
    });
  });

  group('the week — real dates, matching the reference\'s own window', () {
    test('is today plus the next six days, in order', () {
      final MealPlanHarness h = MealPlanHarness();
      addTearDown(h.dispose);
      final MealPlanWeek week = h.week();
      expect(week.days, hasLength(7));
      expect(week.days.first.date, kToday);
      expect(week.days.first.today, isTrue);
      expect(week.days.last.date, kToday.addDays(6));
      expect(week.days.last.today, isFalse);
    });

    test('an entry outside the visible week doesn\'t count toward filled', () {
      final MealPlanHarness h = MealPlanHarness();
      addTearDown(h.dispose);
      h.set(kToday.addDays(30), MealSlot.breakfast, 'Far future');
      expect(h.week().filled, 0);
    });

    test('filled is a real count, never the reference\'s literal 18', () {
      final MealPlanHarness h = MealPlanHarness();
      addTearDown(h.dispose);
      expect(h.week().filled, 0); // starts empty (Option B, no seeding)
      h.set(kToday, MealSlot.breakfast, 'Oats');
      h.set(kToday, MealSlot.lunch, 'Salad');
      h.set(kToday.addDays(1), MealSlot.dinner, 'Pulao');
      expect(h.week().filled, 3);
      expect(MealPlanWeek.totalSlots, 21);
    });
  });

  group('clear', () {
    test('clearing a filled slot removes it', () {
      final MealPlanHarness h = MealPlanHarness();
      addTearDown(h.dispose);
      h.set(kToday, MealSlot.breakfast, 'Oats');
      final MealPlanResult<MealPlanWrite> r = h.repo.clearSlot(
        kToday,
        MealSlot.breakfast,
      );
      expect(r.ok, isTrue);
      expect(h.week().filled, 0);
    });

    test('clearing an already-empty slot is a no-op, not a failure', () {
      final MealPlanHarness h = MealPlanHarness();
      addTearDown(h.dispose);
      final MealPlanResult<MealPlanWrite> r = h.repo.clearSlot(
        kToday,
        MealSlot.breakfast,
      );
      expect(r.ok, isTrue);
    });

    test('undo restores a cleared slot', () {
      final MealPlanHarness h = MealPlanHarness();
      addTearDown(h.dispose);
      h.set(kToday, MealSlot.breakfast, 'Oats');
      final MealPlanResult<MealPlanWrite> cleared = h.repo.clearSlot(
        kToday,
        MealSlot.breakfast,
      );
      final MealPlanResult<void> u = h.repo.undo(cleared.value!);
      expect(u.ok, isTrue);
      expect(h.week().days.first.slot(MealSlot.breakfast)!.text, 'Oats');
    });

    test('undo of a no-op clear does nothing and does not fail', () {
      final MealPlanHarness h = MealPlanHarness();
      addTearDown(h.dispose);
      final MealPlanResult<MealPlanWrite> r = h.repo.clearSlot(
        kToday,
        MealSlot.breakfast,
      );
      final MealPlanResult<void> u = h.repo.undo(r.value!);
      expect(u.ok, isTrue);
    });
  });

  group('Option B — non-durability', () {
    test('the repository reports itself as not durable', () {
      final MealPlanHarness h = MealPlanHarness();
      addTearDown(h.dispose);
      expect(h.repo.durable, isFalse);
    });
  });
}

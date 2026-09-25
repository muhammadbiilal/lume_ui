import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/features/praytrack/domain/praytrack_book.dart';
import 'package:lume/features/praytrack/domain/praytrack_failure.dart';
import 'package:lume/features/praytrack/domain/praytrack_model.dart';
import 'package:lume/features/praytrack/domain/praytrack_repository.dart';

import 'praytrack_harness.dart';

void main() {
  group('model and codec', () {
    test('a check-in round-trips through its fields', () {
      final PrayTrackHarness h = PrayTrackHarness();
      addTearDown(h.dispose);
      final PrayerCheckin c = h.toggle(PrayerKey.fajr, kToday);
      expect(c.date, kToday);
      expect(c.prayer, PrayerKey.fajr);
      expect(c.version, 1);
    });

    test('a record of the wrong schema is a defect, not a crash', () {
      final PrayTrackHarness h = PrayTrackHarness();
      addTearDown(h.dispose);
      h.raw(
        PrayTrackCollections.checkins,
        'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        <String, Object?>{'schema': 'lume.other/1'},
      );
      expect(h.repo.view().defects, hasLength(1));
      expect(h.repo.view().defects.first.reason, 'schema');
      expect(h.repo.view().checkins, isEmpty);
    });

    test('an unrecognised prayer name is a defect, not a crash', () {
      final PrayTrackHarness h = PrayTrackHarness();
      addTearDown(h.dispose);
      h.raw(
        PrayTrackCollections.checkins,
        'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        <String, Object?>{
          'schema': kPrayTrackSchema,
          'date': kToday.toIso(),
          'prayer': 'sunrise',
        },
      );
      final PrayTrackSnapshot snap = h.repo.view();
      expect(snap.defects, hasLength(1));
      expect(snap.defects.first.field, 'prayer');
      expect(snap.checkins, isEmpty);
    });

    test('a malformed date is a defect, not a crash', () {
      final PrayTrackHarness h = PrayTrackHarness();
      addTearDown(h.dispose);
      h.raw(
        PrayTrackCollections.checkins,
        'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        <String, Object?>{
          'schema': kPrayTrackSchema,
          'date': 'not-a-date',
          'prayer': 'fajr',
        },
      );
      final PrayTrackSnapshot snap = h.repo.view();
      expect(snap.defects, hasLength(1));
      expect(snap.defects.first.field, 'date');
    });

    test(
      'a defective record is silently excluded from every figure, not counted',
      () {
        final PrayTrackHarness h = PrayTrackHarness();
        addTearDown(h.dispose);
        h.raw(
          PrayTrackCollections.checkins,
          'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
          <String, Object?>{
            'schema': kPrayTrackSchema,
            'date': kToday.toIso(),
            'prayer': 'made-up',
          },
        );
        final PrayTrackStats s = h.stats();
        expect(s.doneToday, isEmpty);
        expect(s.currentStreak, 0);
      },
    );
  });

  group('toggle — one check-in per (day, prayer)', () {
    test('toggling an unmarked prayer creates a check-in', () {
      final PrayTrackHarness h = PrayTrackHarness();
      addTearDown(h.dispose);
      h.toggle(PrayerKey.asr, kToday);
      expect(h.stats().doneToday, <PrayerKey>{PrayerKey.asr});
    });

    test('toggling it again removes it', () {
      final PrayTrackHarness h = PrayTrackHarness();
      addTearDown(h.dispose);
      h.toggle(PrayerKey.asr, kToday);
      final PrayTrackResult<PrayTrackWrite> r = h.tryToggle(
        PrayerKey.asr,
        kToday,
      );
      expect(r.ok, isTrue);
      expect(r.value!.checkin, isNull);
      expect(h.stats().doneToday, isEmpty);
    });

    test('each prayer is tracked independently on the same day', () {
      final PrayTrackHarness h = PrayTrackHarness();
      addTearDown(h.dispose);
      h.toggle(PrayerKey.fajr, kToday);
      h.toggle(PrayerKey.isha, kToday);
      expect(h.stats().doneToday, <PrayerKey>{PrayerKey.fajr, PrayerKey.isha});
    });

    test('undo of a toggle restores the previous state', () {
      final PrayTrackHarness h = PrayTrackHarness();
      addTearDown(h.dispose);
      final PrayTrackResult<PrayTrackWrite> r = h.tryToggle(
        PrayerKey.dhuhr,
        kToday,
      );
      expect(h.stats().doneToday, contains(PrayerKey.dhuhr));
      final PrayTrackResult<void> u = h.repo.undo(r.value!);
      expect(u.ok, isTrue);
      expect(h.stats().doneToday, isEmpty);
    });
  });

  group(
    'doneToday — real, never the reference\'s "time has passed" literal',
    () {
      test('is empty with nothing checked in', () {
        final PrayTrackHarness h = PrayTrackHarness();
        addTearDown(h.dispose);
        expect(h.stats().doneToday, isEmpty);
      });

      test('counts exactly the prayers the reader marked, not the clock', () {
        final PrayTrackHarness h = PrayTrackHarness();
        addTearDown(h.dispose);
        h.toggle(PrayerKey.fajr, kToday);
        h.toggle(PrayerKey.dhuhr, kToday);
        h.toggle(PrayerKey.asr, kToday);
        expect(h.stats().doneToday, hasLength(3));
        expect(h.stats().doneToday, isNot(contains(PrayerKey.maghrib)));
      });
    },
  );

  group('current streak — consecutive complete days, never a literal', () {
    test('is 0 with nothing checked in', () {
      final PrayTrackHarness h = PrayTrackHarness();
      addTearDown(h.dispose);
      expect(h.stats().currentStreak, 0);
    });

    test('a partially-marked day does not count as a streak day', () {
      final PrayTrackHarness h = PrayTrackHarness();
      addTearDown(h.dispose);
      h.toggle(PrayerKey.fajr, kToday);
      h.toggle(PrayerKey.dhuhr, kToday);
      expect(h.stats().currentStreak, 0);
    });

    test('counts consecutive complete days ending today', () {
      final PrayTrackHarness h = PrayTrackHarness();
      addTearDown(h.dispose);
      h.completeDay(d(9, 5));
      h.completeDay(d(9, 6));
      h.completeDay(kToday);
      expect(h.stats().currentStreak, 3);
    });

    test(
      'stays alive, counting from yesterday, when today is not complete yet',
      () {
        final PrayTrackHarness h = PrayTrackHarness();
        addTearDown(h.dispose);
        h.completeDay(d(9, 5));
        h.completeDay(d(9, 6));
        // Today (7 Sep) untouched.
        expect(h.stats().currentStreak, 2);
      },
    );

    test('breaks on a day left incomplete', () {
      final PrayTrackHarness h = PrayTrackHarness();
      addTearDown(h.dispose);
      h.completeDay(d(9, 5));
      // 6th incomplete, 7th (today) untouched.
      h.toggle(PrayerKey.fajr, d(9, 6));
      expect(h.stats().currentStreak, 0);
    });
  });

  group(
    'best streak — the longest complete run ever, not just the live one',
    () {
      test('outlives a broken run', () {
        final PrayTrackHarness h = PrayTrackHarness();
        addTearDown(h.dispose);
        h.completeDay(d(9, 1));
        h.completeDay(d(9, 2));
        h.completeDay(d(9, 3));
        // 4th-6th untouched (a gap).
        h.completeDay(kToday);
        final PrayTrackStats s = h.stats();
        expect(s.currentStreak, 1);
        expect(s.bestStreak, 3);
      });

      test('is never smaller than the current run', () {
        final PrayTrackHarness h = PrayTrackHarness();
        addTearDown(h.dispose);
        h.completeDay(d(9, 6));
        h.completeDay(kToday);
        final PrayTrackStats s = h.stats();
        expect(s.currentStreak, 2);
        expect(s.bestStreak, 2);
      });
    },
  );

  group('this month — real, over the reader\'s own check-ins', () {
    test(
      'counts only prayers within today\'s calendar month, through today',
      () {
        final PrayTrackHarness h = PrayTrackHarness();
        addTearDown(h.dispose);
        h.toggle(
          PrayerKey.fajr,
          LumeDate(2026, 8, 31),
        ); // last day of August — excluded
        h.completeDay(LumeDate(2026, 9, 1)); // 5
        h.toggle(PrayerKey.fajr, kToday); // +1 = 6, on 7 Sep
        final PrayTrackStats s = h.stats();
        expect(s.monthDone, 6);
        // 7 days elapsed (1st-7th) * 5 prayers = 35 possible.
        expect(s.monthRate, closeTo(6 / 35, 1e-9));
      },
    );

    test('is 0 with nothing checked in this month', () {
      final PrayTrackHarness h = PrayTrackHarness();
      addTearDown(h.dispose);
      expect(h.stats().monthDone, 0);
      expect(h.stats().monthRate, 0);
    });
  });

  group(
    'qada — a real backlog of unmarked past prayers, never the reference\'s bare 7',
    () {
      test(
        'is 0 with no check-in history at all — never a fabricated starting balance',
        () {
          final PrayTrackHarness h = PrayTrackHarness();
          addTearDown(h.dispose);
          expect(h.stats().qada, 0);
          expect(h.stats().historyDone, 0);
        },
      );

      test(
        'counts every prayer left unmarked on a day before today, since the first check-in',
        () {
          final PrayTrackHarness h = PrayTrackHarness();
          addTearDown(h.dispose);
          // First check-in ever is on 5 Sep — tracking "starts" there.
          h.toggle(PrayerKey.fajr, d(9, 5)); // 1 of 5 that day: 4 outstanding
          h.completeDay(d(9, 6)); // all 5: 0 outstanding
          // Today (7 Sep) is not counted — it is not "before today" yet.
          h.toggle(PrayerKey.fajr, kToday);
          final PrayTrackStats s = h.stats();
          expect(s.qada, 4);
          expect(s.historyDone, 1 + 5);
        },
      );

      test(
        'today\'s unmarked prayers are never counted as qada — the day is not over',
        () {
          final PrayTrackHarness h = PrayTrackHarness();
          addTearDown(h.dispose);
          h.toggle(PrayerKey.fajr, kToday);
          expect(h.stats().qada, 0);
        },
      );
    },
  );

  group('heat — the reader\'s own last 35 days, never a random fixture', () {
    test('is 35 days, oldest first, ending today', () {
      final PrayTrackStats s = PrayTrackStats.compute(
        byDate: <LumeDate, Set<PrayerKey>>{},
        today: kToday,
      );
      expect(s.heat, hasLength(35));
      expect(s.heat.first.date, kToday.addDays(-34));
      expect(s.heat.last.date, kToday);
    });

    test('buckets by how many of the five prayers were marked that day', () {
      final PrayTrackHarness h = PrayTrackHarness();
      addTearDown(h.dispose);
      h.completeDay(kToday); // 5 -> level 3
      h.toggle(PrayerKey.fajr, d(9, 6));
      h.toggle(PrayerKey.dhuhr, d(9, 6)); // 2 -> level 1
      h.toggle(PrayerKey.fajr, d(9, 5));
      h.toggle(PrayerKey.dhuhr, d(9, 5));
      h.toggle(PrayerKey.asr, d(9, 5)); // 3 -> level 2
      // 4 Sep: 0 -> level 0.
      final PrayTrackStats s = h.stats();
      final Map<LumeDate, int> byDate = <LumeDate, int>{
        for (final PrayTrackHeatDay day in s.heat) day.date: day.level,
      };
      expect(byDate[kToday], 3);
      expect(byDate[d(9, 6)], 1);
      expect(byDate[d(9, 5)], 2);
      expect(byDate[d(9, 4)], 0);
    });
  });

  group(
    'by prayer — real counts over the heat window, never the reference\'s bare array',
    () {
      test(
        'counts exactly how many of the last 35 days each prayer was marked',
        () {
          final PrayTrackHarness h = PrayTrackHarness();
          addTearDown(h.dispose);
          h.toggle(PrayerKey.fajr, kToday);
          h.toggle(PrayerKey.fajr, d(9, 6));
          h.toggle(PrayerKey.isha, kToday);
          final PrayTrackStats s = h.stats();
          expect(s.byPrayer[PrayerKey.fajr], 2);
          expect(s.byPrayer[PrayerKey.isha], 1);
          expect(s.byPrayer[PrayerKey.dhuhr], 0);
        },
      );
    },
  );

  group('Option B — non-durability', () {
    test('the repository reports itself as not durable', () {
      final PrayTrackHarness h = PrayTrackHarness();
      addTearDown(h.dispose);
      expect(h.repo.durable, isFalse);
    });
  });

  group(
    'toggling a defective collection still surfaces failures, not a crash',
    () {
      test('toggle fails cleanly if the store cannot commit', () {
        final PrayTrackHarness h = PrayTrackHarness(
          readDelay: const Duration(seconds: 1),
        );
        addTearDown(h.dispose);
        // Not opened yet (constructed with a read delay): the collection is
        // unavailable, so a write is refused rather than silently accepted.
        final PrayTrackResult<PrayTrackWrite> r = h.repo.toggle(
          PrayerKey.fajr,
          kToday,
        );
        expect(r.ok, isFalse);
        expect(r.failure!.kind, PrayTrackFailureKind.storage);
      });
    },
  );
}

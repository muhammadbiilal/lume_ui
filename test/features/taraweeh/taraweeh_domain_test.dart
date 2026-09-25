import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/taraweeh/domain/taraweeh_book.dart';
import 'package:lume/features/taraweeh/domain/taraweeh_failure.dart';
import 'package:lume/features/taraweeh/domain/taraweeh_model.dart';
import 'package:lume/features/taraweeh/domain/taraweeh_repository.dart';

import 'taraweeh_harness.dart';

void main() {
  group('model and codec', () {
    test('a night round-trips through its fields', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      final TaraweehNight n = h.logTonight(kToday, rakaat: 8);
      expect(n.date, kToday);
      expect(n.rakaat, 8);
      expect(n.juz, isNull);
      expect(n.version, 1);
    });

    test('a record of the wrong schema is a defect, not a crash', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      h.raw(TaraweehCollections.nights, 'not-a-uuid', <String, Object?>{
        'schema': 'lume.other/1',
      });
      expect(h.stats().current, 0);
      expect(h.repo.view().defects, hasLength(1));
    });

    test('a rakaat outside 8/20 is a defect', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      h.raw(TaraweehCollections.nights, '11111111-1111-4111-8111-111111111111', <String, Object?>{
        'schema': kTaraweehSchema,
        'date': kToday.toIso(),
        'rakaat': 12,
      });
      expect(h.repo.view().defects, hasLength(1));
      expect(h.repo.view().nights, isEmpty);
    });

    test('a juz outside 1-30 is a defect', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      h.raw(TaraweehCollections.nights, '11111111-1111-4111-8111-111111111111', <String, Object?>{
        'schema': kTaraweehSchema,
        'date': kToday.toIso(),
        'rakaat': 20,
        'juz': 31,
      });
      expect(h.repo.view().defects, hasLength(1));
    });
  });

  group('idempotent logging — one entry per date', () {
    test('logging an already-logged night is a no-op, never a duplicate', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      h.logTonight(kToday);
      final TaraweehResult<TaraweehWrite> second = h.repo.logTonight(kToday, rakaat: 8);
      expect(second.ok, isTrue);
      expect(second.value!.receipt.revision, 0);
      expect(h.repo.view().nights, hasLength(1));
      // The second call did not overwrite the first night's rakaat either.
      expect(h.repo.view().nights.single.rakaat, 20);
    });

    test('an invalid rakaat is refused', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      final TaraweehResult<TaraweehWrite> r = h.repo.logTonight(kToday, rakaat: 12);
      expect(r.ok, isFalse);
      expect(r.failure!.kind, TaraweehFailureKind.validation);
      expect(h.repo.view().nights, isEmpty);
    });
  });

  group('current streak — a real calculation, over the reader\'s own nights', () {
    test('is 0 with nothing logged', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      expect(h.stats().current, 0);
      expect(h.stats().prayedTonight, isFalse);
    });

    test('counts the consecutive nights ending tonight', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      h.logTonight(kToday.addDays(-2));
      h.logTonight(kToday.addDays(-1));
      h.logTonight(kToday);
      expect(h.stats().current, 3);
      expect(h.stats().prayedTonight, isTrue);
    });

    test('a gap resets the streak — only the run since the gap counts', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      h.logTonight(kToday.addDays(-3));
      h.logTonight(kToday.addDays(-2));
      // kToday.addDays(-1) is missing — the gap.
      h.logTonight(kToday);
      expect(h.stats().current, 1);
    });
  });

  group('best streak — the longest run ever, even when not current', () {
    test('outlives a broken run', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      h.logTonight(kToday.addDays(-10));
      h.logTonight(kToday.addDays(-9));
      h.logTonight(kToday.addDays(-8));
      h.logTonight(kToday);
      final TaraweehStats s = h.stats();
      expect(s.current, 1);
      expect(s.best, 3);
    });
  });

  group('rakaat', () {
    test('setRakaat changes an already-logged night', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      h.logTonight(kToday, rakaat: 20);
      final TaraweehResult<TaraweehWrite> r = h.repo.setRakaat(kToday, 8);
      expect(r.ok, isTrue);
      expect(h.repo.view().nights.single.rakaat, 8);
    });

    test('setRakaat on a night that was never logged fails, not found', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      final TaraweehResult<TaraweehWrite> r = h.repo.setRakaat(kToday, 8);
      expect(r.ok, isFalse);
      expect(r.failure!.kind, TaraweehFailureKind.notFound);
    });

    test('an invalid rakaat is refused', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      h.logTonight(kToday);
      final TaraweehResult<TaraweehWrite> r = h.repo.setRakaat(kToday, 12);
      expect(r.ok, isFalse);
      expect(r.failure!.kind, TaraweehFailureKind.validation);
      expect(h.repo.view().nights.single.rakaat, 20);
    });
  });

  group('juz — the reader\'s own Khatm progress, never a literal', () {
    test('juzDone is 0 and nextJuz is 1 with nothing logged', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      expect(h.stats().juzDone, 0);
      expect(h.stats().nextJuz, 1);
      expect(h.stats().progress, 0);
      expect(h.stats().khatmComplete, isFalse);
    });

    test('setJuz notes a Juz for an already-logged night', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      h.logTonight(kToday);
      final TaraweehResult<TaraweehWrite> r = h.repo.setJuz(kToday, 5);
      expect(r.ok, isTrue);
      expect(h.repo.view().nights.single.juz, 5);
      expect(h.stats().juzDone, 1);
      expect(h.stats().nextJuz, 1);
    });

    test('setJuz(null) clears a previously noted Juz', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      h.logTonight(kToday);
      h.repo.setJuz(kToday, 5);
      final TaraweehResult<TaraweehWrite> r = h.repo.setJuz(kToday, null);
      expect(r.ok, isTrue);
      expect(h.repo.view().nights.single.juz, isNull);
      expect(h.stats().juzDone, 0);
    });

    test('the same Juz logged on two nights counts once', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      h.logTonight(kToday.addDays(-1));
      h.repo.setJuz(kToday.addDays(-1), 3);
      h.logTonight(kToday);
      h.repo.setJuz(kToday, 3);
      expect(h.stats().juzDone, 1);
    });

    test('juzDone counts distinct Juz across nights, progress is out of 30', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      for (int i = 0; i < 5; i++) {
        h.logTonight(kToday.addDays(-i));
        h.repo.setJuz(kToday.addDays(-i), i + 1);
      }
      final TaraweehStats s = h.stats();
      expect(s.juzDone, 5);
      expect(s.progress, closeTo(5 / 30, 1e-9));
      expect(s.nextJuz, 6);
    });

    test('khatmComplete once all 30 Juz are logged', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      for (int i = 0; i < 30; i++) {
        h.logTonight(kToday.addDays(-i));
        h.repo.setJuz(kToday.addDays(-i), i + 1);
      }
      final TaraweehStats s = h.stats();
      expect(s.juzDone, 30);
      expect(s.progress, 1);
      expect(s.nextJuz, isNull);
      expect(s.khatmComplete, isTrue);
    });

    test('an out-of-range juz is refused', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      h.logTonight(kToday);
      final TaraweehResult<TaraweehWrite> r = h.repo.setJuz(kToday, 31);
      expect(r.ok, isFalse);
      expect(r.failure!.kind, TaraweehFailureKind.validation);
    });

    test('setJuz on a night that was never logged fails, not found', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      final TaraweehResult<TaraweehWrite> r = h.repo.setJuz(kToday, 5);
      expect(r.ok, isFalse);
      expect(r.failure!.kind, TaraweehFailureKind.notFound);
    });
  });

  group('heat — the reader\'s own last 35 nights, never a random fixture', () {
    test('is 35 nights, oldest first, ending tonight', () {
      final TaraweehStats s = TaraweehStats.compute(nights: <TaraweehNight>[], today: kToday);
      expect(s.heat, hasLength(35));
      expect(s.heat.first.date, kToday.addDays(-34));
      expect(s.heat.last.date, kToday);
    });
  });

  group('clear', () {
    test('clearing a logged night removes it entirely', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      h.logTonight(kToday);
      h.repo.setJuz(kToday, 5);
      final TaraweehResult<TaraweehWrite> r = h.repo.clear(kToday);
      expect(r.ok, isTrue);
      expect(h.stats().prayedTonight, isFalse);
      expect(h.repo.view().nights, isEmpty);
    });

    test('clearing an already-clear night is a no-op, not a failure', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      final TaraweehResult<TaraweehWrite> r = h.repo.clear(kToday);
      expect(r.ok, isTrue);
      expect(r.value!.receipt.revision, 0);
    });

    test('undo restores a cleared night, rakaat and juz included', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      h.logTonight(kToday, rakaat: 8);
      h.repo.setJuz(kToday, 5);
      final TaraweehResult<TaraweehWrite> cleared = h.repo.clear(kToday);
      final TaraweehResult<void> u = h.repo.undo(cleared.value!);
      expect(u.ok, isTrue);
      expect(h.stats().prayedTonight, isTrue);
      expect(h.repo.view().nights.single.rakaat, 8);
      expect(h.repo.view().nights.single.juz, 5);
    });
  });

  group('Option B — non-durability', () {
    test('the repository reports itself as not durable', () {
      final TaraweehHarness h = TaraweehHarness();
      addTearDown(h.dispose);
      expect(h.repo.durable, isFalse);
    });
  });
}

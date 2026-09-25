/// Loadshedding's fixture schedule and the arithmetic `loadshed()` does over
/// it, against the reference's own figures.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/loadshed/data/loadshed_fixtures.dart';

void main() {
  group('the fixed schedule — the reference\'s own figures, ported exactly', () {
    test('five outage windows, the last one crossing midnight', () {
      expect(kLoadshedSlots, hasLength(5));
      expect(
        kLoadshedSlots.map((LumeLoadshedSlot s) => (s.from, s.to)).toList(),
        <(String, String)>[
          ('06:00', '07:00'),
          ('10:00', '11:00'),
          ('14:00', '16:00'),
          ('19:00', '20:00'),
          ('23:00', '00:00'),
        ],
      );
    });

    test('reliability is the reference\'s hardcoded 78%', () {
      expect(kLoadshedReliability, 78);
    });

    test('the week is Monday first, matching (now.getDay() + 6) % 7', () {
      expect(kLoadshedWeek, <int>[6, 5, 7, 6, 4, 5, 6]);
    });
  });

  group('resolved against the clock', () {
    test('right after midnight, every slot is still ahead', () {
      final LumeLoadshedToday ls = LumeLoadshedToday.at(
        nowMinute: 0,
        weekday: DateTime.monday,
      );
      expect(ls.current, isNull);
      expect(ls.isNow, isFalse);
      expect(ls.next.slot.from, '06:00');
      expect(ls.minutesUntil(0), 360);
      expect(
        ls.slots.map((LumeLoadshedResolvedSlot s) => s.state).toList(),
        List<LumeLoadshedState>.filled(5, LumeLoadshedState.next),
      );
    });

    test('inside a slot, that slot is now, and minutes count down to its '
        'own end — not the next one', () {
      // 15:00, inside the third slot (14:00–16:00).
      final LumeLoadshedToday ls = LumeLoadshedToday.at(
        nowMinute: 15 * 60,
        weekday: DateTime.wednesday,
      );
      expect(ls.isNow, isTrue);
      expect(ls.current!.slot.from, '14:00');
      expect(ls.slot, same(ls.current));
      expect(ls.minutesUntil(15 * 60), 60);
    });

    test('between two slots, past ones are done and the next one ahead is '
        'the one reported — matching the fixture instant, Monday 16:41', () {
      final LumeLoadshedToday ls = LumeLoadshedToday.at(
        nowMinute: 16 * 60 + 41,
        weekday: DateTime.monday,
      );
      expect(ls.current, isNull);
      expect(
        ls.slots.map((LumeLoadshedResolvedSlot s) => s.state).toList(),
        <LumeLoadshedState>[
          LumeLoadshedState.done,
          LumeLoadshedState.done,
          LumeLoadshedState.done,
          LumeLoadshedState.next,
          LumeLoadshedState.next,
        ],
      );
      expect(ls.next.slot.from, '19:00');
      expect(ls.slot, same(ls.next));
      expect(ls.minutesUntil(16 * 60 + 41), 139);
    });

    test('the last slot crosses midnight — its own end lands past 1440, '
        'exactly as `to <= from` rolls it into tomorrow', () {
      final LumeLoadshedToday ls = LumeLoadshedToday.at(
        nowMinute: 23 * 60 + 30,
        weekday: DateTime.friday,
      );
      final LumeLoadshedResolvedSlot last = ls.slots.last;
      expect(last.slot.from, '23:00');
      expect(last.fromMinute, 1380);
      expect(last.toMinute, 1440);
      expect(last.state, LumeLoadshedState.now);
      expect(last.hours, 1);
      expect(ls.current, same(last));
      expect(ls.minutesUntil(23 * 60 + 30), 30);
    });

    test('the day index runs Monday first, matching the week figures', () {
      expect(
        LumeLoadshedToday.at(nowMinute: 0, weekday: DateTime.monday).todayIndex,
        0,
      );
      expect(
        LumeLoadshedToday.at(
          nowMinute: 0,
          weekday: DateTime.wednesday,
        ).todayIndex,
        2,
      );
      expect(
        LumeLoadshedToday.at(nowMinute: 0, weekday: DateTime.sunday).todayIndex,
        6,
      );
    });

    test('hoursToday sums the day\'s own slots — six hours, worked out, not '
        'hardcoded, and the same whatever the hour', () {
      for (final int minute in <int>[0, 500, 1001, 1439]) {
        final LumeLoadshedToday ls = LumeLoadshedToday.at(
          nowMinute: minute,
          weekday: DateTime.tuesday,
        );
        expect(ls.hoursToday, 6.0, reason: 'at minute $minute');
      }
    });

    test('a slot\'s own duration is whole hours — the third slot is two', () {
      final LumeLoadshedToday ls = LumeLoadshedToday.at(
        nowMinute: 0,
        weekday: DateTime.monday,
      );
      expect(ls.slots[2].hours, 2);
      expect(ls.slots[0].hours, 1);
    });
  });
}

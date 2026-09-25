/// The Hijri date, against the reference's own arithmetic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/time/lume_hijri.dart';

void main() {
  test(
    'the fixture day is 23 Rabi‘ al-Awwal 1448, as the reference labels it',
    () {
      // `tool_calendar_muslim_pk_…` — "23 Rabi‘ al-Awwal 1448" on 7 Sep 2026.
      expect(
        LumeHijriDate.of(DateTime(2026, 9, 7, 16, 41, 32)),
        const LumeHijriDate(1448, 3, 23),
      );
    },
  );

  test('every hour of a civil day is one Hijri date', () {
    final LumeHijriDate morning = LumeHijriDate.of(DateTime(2026, 9, 7, 0, 5));
    final LumeHijriDate night = LumeHijriDate.of(DateTime(2026, 9, 7, 23, 55));
    expect(morning, night);
  });

  test('the first of September, as the reference grid writes it (17)', () {
    expect(LumeHijriDate.of(DateTime(2026, 9, 1)).day, 17);
  });

  test('a Hijri month turns over rather than counting past 30 (C71)', () {
    final List<int> days = <int>[
      for (int d = 1; d <= 30; d++) LumeHijriDate.of(DateTime(2026, 9, d)).day,
    ];
    expect(days.every((int d) => d >= 1 && d <= 30), isTrue);
    expect(days.where((int d) => d == 1), hasLength(1));
    expect(
      LumeHijriDate.of(DateTime(2026, 9, 30)).month,
      4,
      reason: 'the end of September is in Rabi‘ al-Thani',
    );
  });

  test('consecutive days never skip or repeat within a month', () {
    LumeHijriDate prev = LumeHijriDate.of(DateTime(2026, 1, 1));
    for (int i = 1; i < 800; i++) {
      final LumeHijriDate next = LumeHijriDate.of(
        DateTime(2026, 1, 1).add(Duration(days: i)),
      );
      if (next.month == prev.month) {
        expect(next.day, prev.day + 1, reason: '$prev → $next');
      } else {
        expect(next.day, 1, reason: '$prev → $next');
        expect(prev.day, anyOf(29, 30), reason: '$prev → $next');
      }
      prev = next;
    }
  });

  group('walkForward', () {
    test('daysAway is 0 when today already matches', () {
      final DateTime today = DateTime(2026, 9, 7);
      final (DateTime g, LumeHijriDate h, int away) = LumeHijriDate.walkForward(
        start: today,
        matches: (LumeHijriDate h) => h.month == 3 && h.day == 23,
        horizonDays: 400,
        reason: 'unreachable',
      );
      expect(away, 0);
      expect(g, today);
      expect(h, const LumeHijriDate(1448, 3, 23));
    });

    test('finds the next Ramadan (month 9) from just before it starts', () {
      // 2026-09-07 is 23 Rabi‘ al-Awwal 1448 — Ramadan is six lunar months
      // away, comfortably inside a 400-day horizon.
      final (DateTime g, LumeHijriDate h, int away) = LumeHijriDate.walkForward(
        start: DateTime(2026, 9, 7),
        matches: (LumeHijriDate h) => h.month == 9,
        horizonDays: 400,
        reason: 'unreachable',
      );
      expect(h.month, 9);
      expect(h.day, 1, reason: 'the first hit is the month\'s own start');
      expect(LumeHijriDate.of(g), h, reason: 'g and h agree on the same day');
      expect(away, greaterThan(0));
    });

    test('throws, rather than returning a wrong answer, once the horizon '
        'is exhausted', () {
      expect(
        () => LumeHijriDate.walkForward(
          start: DateTime(2026, 9, 7),
          matches: (LumeHijriDate h) => false,
          horizonDays: 5,
          reason: 'never matches',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

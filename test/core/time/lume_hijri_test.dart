/// The Hijri date, against the reference's own arithmetic.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/time/lume_hijri.dart';

void main() {
  test('the fixture day is 23 Rabi‘ al-Awwal 1448, as the reference labels it', () {
    // `tool_calendar_muslim_pk_…` — "23 Rabi‘ al-Awwal 1448" on 7 Sep 2026.
    expect(
      LumeHijriDate.of(DateTime(2026, 9, 7, 16, 41, 32)),
      const LumeHijriDate(1448, 3, 23),
    );
  });

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
}

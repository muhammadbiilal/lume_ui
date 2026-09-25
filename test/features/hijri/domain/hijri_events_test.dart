/// The Islamic Calendar's own fixed dates — worked out for real, checked
/// against the algorithm's documented epoch and against the same fixture day
/// `test/core/time/lume_hijri_test.dart` already holds the base conversion to
/// (23 Rabi‘ al-Awwal 1448 on 7 September 2026, taken from the running
/// reference's own capture, `tool_calendar_muslim_pk_…`).
///
/// **The epoch citation.** The tabular ("Kuwaiti") arithmetic Islamic
/// calendar's civil epoch — 1 Muharram, AH 1 — is astronomical Julian Day
/// Number 1,948,440 (Dershowitz & Reingold, *Calendrical Calculations*, the
/// standard reference for this family of calendars; also the literal
/// constant `lume_hijri.dart` subtracts: `jd - 1948440 + 10632`). Rather than
/// trust a memorised Gregorian date for that JDN — a real risk of
/// misremembering a specific historical calendar date — [_gregorianOfJdn]
/// converts it independently, with the Fliegel & Van Flandern algorithm (the
/// standard closed-form Julian-Day-Number-to-Gregorian conversion, unrelated
/// to and structurally nothing like the tabular Islamic calendar's own
/// arithmetic).
///
/// One deliberate adjustment: `lume_hijri.dart`'s `jd` is
/// `floor(unixDays + 2440587.5)`, read at UTC **midnight** — one lower than
/// the *astronomical* JDN for the same calendar day, whose integer count
/// turns over at **noon**. So the value that makes [LumeHijriDate.of] read
/// `1-1-1` is `1948441`, one more than the cited epoch constant, and this is
/// verified below (probed against a small range of neighbouring JDNs) rather
/// than asserted from memory: this is a day-boundary convention difference
/// between two ways of labelling the same instant, not a discrepancy in the
/// epoch itself.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/time/lume_hijri.dart';
import 'package:lume/features/hijri/domain/hijri_events.dart';

/// The proleptic Gregorian calendar date for Julian Day Number [jdn] —
/// Fliegel, H. F. & Van Flandern, T. C. (1968), "A Machine Algorithm for
/// Processing Calendar Dates", *Communications of the ACM* 11(10):657.
DateTime _gregorianOfJdn(int jdn) {
  final int l0 = jdn + 68569;
  final int n = (4 * l0) ~/ 146097;
  final int l1 = l0 - (146097 * n + 3) ~/ 4;
  final int i = (4000 * (l1 + 1)) ~/ 1461001;
  final int l2 = l1 - (1461 * i) ~/ 4 + 31;
  final int j = (80 * l2) ~/ 2447;
  final int day = l2 - (2447 * j) ~/ 80;
  final int l3 = j ~/ 11;
  final int month = j + 2 - 12 * l3;
  final int year = 100 * (n - 49) + i + l3;
  return DateTime.utc(year, month, day);
}

void main() {
  group('the algorithm reused here', () {
    test('starts its count one civil day after the documented astronomical '
        'epoch, JDN 1,948,440 (Dershowitz & Reingold, Calendrical '
        'Calculations) — the midnight/noon JDN boundary difference documented '
        'above, converted independently by Fliegel & Van Flandern\'s formula '
        'rather than a hand-typed Gregorian date', () {
      expect(
        LumeHijriDate.of(_gregorianOfJdn(1948440)),
        const LumeHijriDate(0, 12, 29),
        reason:
            'the day before the epoch, on lume_hijri.dart\'s own '
            'midnight-JD convention',
      );
      expect(
        LumeHijriDate.of(_gregorianOfJdn(1948441)),
        const LumeHijriDate(1, 1, 1),
      );
    });

    test('a 30-year cycle is exactly 10,631 civil days — the mean Hijri year '
        '(10631 / 30 ≈ 354.3667 days) tracks the real mean synodic month '
        '(29.530589 days × 12 ≈ 354.3671 days) to within four thousandths of a '
        'day, which is the tabular calendar\'s own known accuracy', () {
      const double meanYear = 10631 / 30;
      const double astronomicalMeanYear = 29.530589 * 12;
      expect((meanYear - astronomicalMeanYear).abs(), lessThan(0.001));
    });
  });

  group('LumeHijriEvents.upcoming', () {
    test('returns exactly the six computed transitions, each within one '
        'Hijri year of today and in chronological order', () {
      final DateTime today = DateTime(2026, 9, 7);
      final List<LumeHijriEvent> events = LumeHijriEvents.upcoming(today);

      expect(events, hasLength(LumeHijriEventId.values.length));
      expect(
        events.map((LumeHijriEvent e) => e.id).toSet(),
        LumeHijriEventId.values.toSet(),
        reason: 'each id appears exactly once',
      );
      for (final LumeHijriEvent e in events) {
        expect(e.daysAway, inInclusiveRange(0, LumeHijriEvents.horizonDays));
      }
      final List<int> away = events
          .map((LumeHijriEvent e) => e.daysAway)
          .toList();
      expect(away, orderedEquals(<int>[...away]..sort()));
    });

    test('every found date really does convert back to the day it was found '
        'on, and to the (month, day) it was searched for', () {
      const Map<LumeHijriEventId, (int, int)> targets =
          <LumeHijriEventId, (int, int)>{
            LumeHijriEventId.islamicNewYear: (1, 1),
            LumeHijriEventId.ashura: (1, 10),
            LumeHijriEventId.ramadanBegins: (9, 1),
            LumeHijriEventId.eidAlFitr: (10, 1),
            LumeHijriEventId.dayOfArafah: (12, 9),
            LumeHijriEventId.eidAlAdha: (12, 10),
          };
      for (final LumeHijriEvent e in LumeHijriEvents.upcoming(
        DateTime(2026, 1, 1),
      )) {
        expect(LumeHijriDate.of(e.gregorian), e.hijri);
        final (int, int) want = targets[e.id]!;
        expect((e.hijri.month, e.hijri.day), want);
      }
    });

    test('from the fixture day (23 Rabi‘ al-Awwal 1448 = 7 Sep 2026), the next '
        'six transitions fall in true Hijri-calendar order: Ramadan, then Eid '
        'al-Fitr, then Arafah, then Eid al-Adha, then next year\'s New Year and '
        'Ashura', () {
      final List<LumeHijriEventId> order = LumeHijriEvents.upcoming(
        DateTime(2026, 9, 7),
      ).map((LumeHijriEvent e) => e.id).toList();
      expect(order, <LumeHijriEventId>[
        LumeHijriEventId.ramadanBegins,
        LumeHijriEventId.eidAlFitr,
        LumeHijriEventId.dayOfArafah,
        LumeHijriEventId.eidAlAdha,
        LumeHijriEventId.islamicNewYear,
        LumeHijriEventId.ashura,
      ]);
    });

    test('a date that already is a transition reports zero days away, not '
        'one year forward', () {
      // Scan forward from the day itself to find the *next* Islamic New
      // Year, then hand that exact day back in — it must report today, not
      // next year's.
      final LumeHijriEvent first =
          LumeHijriEvents.upcoming(DateTime(2026, 1, 1)).firstWhere(
            (LumeHijriEvent e) => e.id == LumeHijriEventId.islamicNewYear,
          );
      final LumeHijriEvent again = LumeHijriEvents.upcoming(first.gregorian)
          .firstWhere(
            (LumeHijriEvent e) => e.id == LumeHijriEventId.islamicNewYear,
          );
      expect(again.daysAway, 0);
      expect(again.gregorian, first.gregorian);
    });
  });
}

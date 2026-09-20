/// Monthly anchoring, the calendar rule two tools share: Installments'
/// instalment dates and Committee's cycle dates. It moved here from
/// `installments_schedule.dart` unchanged, so the dates Installments
/// already stored are the dates this gives (D-C12). Every case the
/// Installments domain test asserted is asserted here too.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_month_anchor.dart';

List<String> run(LumeDate anchor, int n) =>
    lumeMonthlyDues(anchor, n)!.map((LumeDate x) => x.toIso()).toList();

void main() {
  group('the anchor decides every date', () {
    test('31 January: the February clamp does not carry into March', () {
      expect(run(LumeDate(2026, 1, 31), 4), <String>[
        '2026-01-31',
        '2026-02-28',
        '2026-03-31',
        '2026-04-30',
      ]);
    });

    test('a leap year gives 29 February', () {
      expect(run(LumeDate(2028, 1, 31), 3), <String>[
        '2028-01-31',
        '2028-02-29',
        '2028-03-31',
      ]);
    });

    test('30 January to the end of February and back to 30 March', () {
      expect(run(LumeDate(2026, 1, 30), 3), <String>[
        '2026-01-30',
        '2026-02-28',
        '2026-03-30',
      ]);
    });

    test('anchored on 29 February: each year its own February', () {
      final LumeDate first = LumeDate(2028, 2, 29);
      expect(lumeMonthlyDue(first, 13)!.toIso(), '2029-02-28');
      expect(lumeMonthlyDue(first, 49)!.toIso(), '2032-02-29');
      expect(lumeMonthlyDue(first, 2)!.toIso(), '2028-03-29');
    });

    test('across a year end, and past the calendar there is none', () {
      expect(run(LumeDate(2026, 11, 15), 3), <String>[
        '2026-11-15',
        '2026-12-15',
        '2027-01-15',
      ]);
      expect(lumeMonthlyDues(LumeDate(9999, 6, 1), 12), isNull);
      expect(lumeMonthlyDue(LumeDate(9999, 12, 1), 2), isNull);
    });

    test('the first date is the anchor itself', () {
      expect(lumeMonthlyDue(LumeDate(2026, 6, 7), 1)!.toIso(), '2026-06-07');
    });

    test('a long run stays on the anchor day, month by month', () {
      final List<String> dates = run(LumeDate(2026, 6, 7), 120);
      expect(dates.first, '2026-06-07');
      expect(dates.last, '2036-05-07');
      expect(dates.length, 120);
      // Never drifts: every date is the 7th, because the anchor is.
      expect(dates.where((String d) => d.endsWith('-07')), hasLength(120));
    });
  });

  group('month helpers', () {
    test('the first of the month, offset from a day', () {
      expect(lumeMonthStart(LumeDate(2026, 9, 20), 0).toIso(), '2026-09-01');
      expect(lumeMonthStart(LumeDate(2026, 9, 20), 3).toIso(), '2026-12-01');
      expect(lumeMonthStart(LumeDate(2026, 12, 31), 1).toIso(), '2027-01-01');
      expect(lumeMonthStart(LumeDate(2026, 1, 1), -1).toIso(), '2025-12-01');
    });

    test('same calendar month, not the same day', () {
      expect(
        lumeSameMonth(LumeDate(2026, 9, 1), LumeDate(2026, 9, 30)),
        isTrue,
      );
      expect(
        lumeSameMonth(LumeDate(2026, 9, 30), LumeDate(2026, 10, 1)),
        isFalse,
      );
      expect(
        lumeSameMonth(LumeDate(2025, 9, 7), LumeDate(2026, 9, 7)),
        isFalse,
      );
    });
  });
}

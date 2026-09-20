/// Monthly dates worked out from one anchor day.
///
/// A plan's instalments and a committee's cycles fall on the same day of
/// each month. The nth date is the anchor's day in the month n − 1 months
/// after the anchor's month, clamped to that month's last day. Every date
/// is worked out from the anchor, never from the date before it, so
/// February's clamp does not carry into March: 31 Jan → 28 Feb (29 in a
/// leap year) → 31 Mar → 30 Apr, and 29 Feb 2028 → 28 Feb 2029.
///
/// Calendar arithmetic on [LumeDate] only: no duration, no clock, no zone,
/// and nothing here reads the time. A tool runs this once, when the reader
/// creates the thing, and stores what it gives; a stored schedule is never
/// recomputed (`INSTALLMENTS_PROPOSAL.md` §40.5,
/// `COMMITTEE_PROPOSAL.md` D-C1).
library;

import 'dart:math' as math;

import 'lume_date.dart';

/// The [seq]th date (1-based) of a monthly run anchored on [anchor], or
/// `null` when that month would fall past the calendar's last year.
LumeDate? lumeMonthlyDue(LumeDate anchor, int seq) {
  assert(seq >= 1);
  final int months = anchor.year * 12 + (anchor.month - 1) + (seq - 1);
  final int year = months ~/ 12;
  final int month = months % 12 + 1;
  if (year > 9999) return null;
  return LumeDate(
    year,
    month,
    math.min(anchor.day, LumeDate.daysIn(year, month)),
  );
}

/// Every date of a monthly run of [count] anchored on [anchor], or `null`
/// when the last of them would fall past the calendar.
List<LumeDate>? lumeMonthlyDues(LumeDate anchor, int count) {
  final List<LumeDate> out = <LumeDate>[];
  for (int n = 1; n <= count; n++) {
    final LumeDate? d = lumeMonthlyDue(anchor, n);
    if (d == null) return null;
    out.add(d);
  }
  return out;
}

/// The first day of the month [offset] months after [day]'s month.
LumeDate lumeMonthStart(LumeDate day, int offset) {
  final int months = day.year * 12 + (day.month - 1) + offset;
  return LumeDate(months ~/ 12, months % 12 + 1, 1);
}

/// Whether [d] is in the same calendar month as [month].
bool lumeSameMonth(LumeDate d, LumeDate month) =>
    d.year == month.year && d.month == month.month;

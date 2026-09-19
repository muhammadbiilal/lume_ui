/// The monthly schedule: the due date of each instalment, from the first
/// due date alone (`INSTALLMENTS_PROPOSAL.md` §40.5).
///
/// Instalment n falls on the first due date's day in the month n − 1 months
/// after the first due month, clamped to that month's last day. Each date is
/// worked out from the anchor, never from the date before it, so February's
/// clamp does not carry into March: 31 Jan → 28 Feb (29 in a leap year) →
/// 31 Mar → 30 Apr. Calendar arithmetic on [LumeDate] only: no duration, no
/// clock, no zone.
///
/// This runs once, when a plan is created. The dates it gives are then
/// stored, and a stored schedule is never recomputed.
library;

import 'dart:math' as math;

import '../../../core/values/lume_date.dart';

/// The due date of instalment [seq] (1-based) of a monthly plan anchored on
/// [firstDue], or `null` when that month is past the calendar's last year.
LumeDate? installmentDue(LumeDate firstDue, int seq) {
  assert(seq >= 1);
  final int months = firstDue.year * 12 + (firstDue.month - 1) + (seq - 1);
  final int year = months ~/ 12;
  final int month = months % 12 + 1;
  if (year > 9999) return null;
  return LumeDate(
    year,
    month,
    math.min(firstDue.day, LumeDate.daysIn(year, month)),
  );
}

/// Every due date of a monthly plan of [count] instalments anchored on
/// [firstDue], or `null` when the last one would fall past the calendar.
List<LumeDate>? installmentDues(LumeDate firstDue, int count) {
  final List<LumeDate> out = <LumeDate>[];
  for (int n = 1; n <= count; n++) {
    final LumeDate? d = installmentDue(firstDue, n);
    if (d == null) return null;
    out.add(d);
  }
  return out;
}

/// The first day of the month [offset] months after [day]'s month.
LumeDate monthStart(LumeDate day, int offset) {
  final int months = day.year * 12 + (day.month - 1) + offset;
  return LumeDate(months ~/ 12, months % 12 + 1, 1);
}

/// Whether [d] is in the same calendar month as [month].
bool sameMonth(LumeDate d, LumeDate month) =>
    d.year == month.year && d.month == month.month;

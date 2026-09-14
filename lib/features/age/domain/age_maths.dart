/// An age, as `context.js` `age()` works it out.
///
/// Whole years, months and days, borrowing a month's days from the month
/// before today; the days, weeks and hours since birth; how far the next
/// birthday is, today counting as today; and the days 10 000, 15 000 and
/// 20 000 fall on.
///
/// The reference counts in milliseconds from local midnight, so where the
/// clocks change it can land an hour short and lose a day. Lume counts
/// calendar days, which is what the reference means.
library;

import 'package:flutter/foundation.dart';

@immutable
class LumeAge {
  const LumeAge({
    required this.years,
    required this.months,
    required this.days,
    required this.totalDays,
    required this.untilNext,
    required this.next,
    required this.milestones,
  });

  /// `fieldsFor('age', { dob: '1993-04-18' })`.
  static const String defaultBirth = '1993-04-18';

  static const List<int> milestoneDays = <int>[10000, 15000, 20000];

  final int years;
  final int months;
  final int days;
  final int totalDays;

  /// Days to the next birthday; 0 on the day.
  final int untilNext;
  final DateTime next;

  /// Each milestone's day count and the date it falls on.
  final List<(int, DateTime)> milestones;

  int get totalWeeks => totalDays ~/ 7;
  int get totalHours => totalDays * 24;

  /// `1 - untilNext / 365`, held to the bar.
  double get yearDone => (1 - untilNext / 365).clamp(0.0, 1.0);

  /// Whole calendar days from [a] to [b].
  static int daysBetween(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  /// The age on [now] of someone born on [birth]. A birth after today is
  /// the caller's to refuse; this works it out as the reference would.
  static LumeAge of(DateTime birth, DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime dob = DateTime(birth.year, birth.month, birth.day);
    int years = today.year - dob.year;
    int months = today.month - dob.month;
    int days = today.day - dob.day;
    if (days < 0) {
      months--;
      // `new Date(y, m, 0).getDate()` — the length of the month before.
      days += DateTime(today.year, today.month, 0).day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }
    // `new Date(y, dob.m, dob.d)` rolls 29 February to 1 March in a common
    // year, as `DateTime` does.
    DateTime next = DateTime(today.year, dob.month, dob.day);
    if (next.isBefore(today)) {
      next = DateTime(next.year + 1, next.month, next.day);
    }
    return LumeAge(
      years: years,
      months: months,
      days: days,
      totalDays: daysBetween(dob, today),
      untilNext: daysBetween(today, next),
      next: next,
      milestones: <(int, DateTime)>[
        for (final int n in milestoneDays)
          (n, DateTime(dob.year, dob.month, dob.day + n)),
      ],
    );
  }
}

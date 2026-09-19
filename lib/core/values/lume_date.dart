/// A calendar date — a year, a month and a day, and nothing else.
///
/// No time of day and no zone: "due 1 September" is the same date wherever
/// the reader is. Turning a date into an instant needs a zone policy, and
/// none is assumed here — there is deliberately no `toInstant`. Today's date
/// comes from reading the injected clock on the reader's resolved zone
/// ([LumeDate.ofWallClock]), which is the caller's to do.
///
/// Construction is strict: the 30th of February, month 13 and year 0 are
/// refused rather than rolled over as `DateTime` would. Serialised as ISO
/// 8601's `YYYY-MM-DD`, and compared as a calendar.
library;

import 'package:flutter/foundation.dart';

/// A value that is not a calendar date.
@immutable
class LumeDateException implements Exception {
  const LumeDateException(this.text);

  final String text;

  @override
  String toString() => 'LumeDateException("$text")';
}

@immutable
class LumeDate implements Comparable<LumeDate> {
  const LumeDate._(this.year, this.month, this.day);

  /// The date, when it exists: years 1 to 9999, months 1 to 12, and a day
  /// the month has (29 February only in a leap year).
  factory LumeDate(int year, int month, int day) {
    if (year < 1 ||
        year > 9999 ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > daysIn(year, month)) {
      throw LumeDateException('$year-$month-$day');
    }
    return LumeDate._(year, month, day);
  }

  /// `YYYY-MM-DD`, exactly; anything else is a [LumeDateException].
  factory LumeDate.parse(String text) {
    final LumeDate? d = tryParse(text);
    if (d == null) throw LumeDateException(text);
    return d;
  }

  /// [LumeDate.parse], or `null`.
  static LumeDate? tryParse(String text) {
    final RegExpMatch? m = _iso.firstMatch(text);
    if (m == null) return null;
    final int y = int.parse(m.group(1)!);
    final int mo = int.parse(m.group(2)!);
    final int d = int.parse(m.group(3)!);
    if (y < 1 || mo < 1 || mo > 12 || d < 1 || d > daysIn(y, mo)) return null;
    return LumeDate._(y, mo, d);
  }

  /// The date a wall clock reads — its fields, taken as they are. The
  /// caller supplies a wall clock already read in the reader's zone.
  factory LumeDate.ofWallClock(DateTime wallClock) =>
      LumeDate(wallClock.year, wallClock.month, wallClock.day);

  static final RegExp _iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  static bool isLeapYear(int year) =>
      year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

  static int daysIn(int year, int month) => switch (month) {
    2 => isLeapYear(year) ? 29 : 28,
    4 || 6 || 9 || 11 => 30,
    _ => 31,
  };

  /// The date [days] later (earlier when negative), by the calendar.
  LumeDate addDays(int days) {
    final DateTime d = DateTime.utc(year, month, day + days);
    return LumeDate(d.year, d.month, d.day);
  }

  /// Whole days from this date to [other]; negative when [other] is earlier.
  int daysUntil(LumeDate other) => DateTime.utc(
    other.year,
    other.month,
    other.day,
  ).difference(DateTime.utc(year, month, day)).inDays;

  bool isBefore(LumeDate other) => compareTo(other) < 0;
  bool isAfter(LumeDate other) => compareTo(other) > 0;

  /// A naive `DateTime` at the start of this date, for a formatter that
  /// writes dates. It names no zone and is not an instant.
  DateTime toCalendarDateTime() => DateTime(year, month, day);

  /// `YYYY-MM-DD`.
  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(LumeDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LumeDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}

/// When an exchange is shut, and why.
///
/// §26.10 of the reference says *"public holidays close a market as surely as
/// the clock does"*, and `tool-data.js` carries a `MARKET_HOLIDAYS` table and
/// an `isMarketHoliday()` to read it. **`marketSession()` never calls either**
/// — so the prototype declares its holidays and then trades through them. That
/// is the first of the four defects this file exists to correct
/// (KNOWN_DIFFERENCES C11).
///
/// The second is that its one floating holiday is pinned to a date. US
/// Thanksgiving is stored as `[11, 28]`, which was right in 2024 and is wrong
/// in 2026, when the fourth Thursday of November falls on the 26th. A floating
/// holiday has to be *derived* from the rule that defines it, so
/// [LumeFloatingHoliday] and [LumeEasterHoliday] do that.
///
/// The third is the weekend. The prototype closes every exchange on Saturday
/// and Sunday, using the **device's** weekday; the Saudi Exchange trades Sunday
/// to Thursday. A calendar carries its own [weekend].
library;

import 'package:flutter/foundation.dart';

import '../../../core/time/lume_time_zone.dart';

/// A day an exchange is shut, as the rule that decides it rather than a date.
@immutable
sealed class LumeHoliday {
  const LumeHoliday(this.name);

  /// A stable identifier for the day, used by tests and by anything that
  /// wants to say *which* holiday closed the market.
  final String name;

  /// The date this rule lands on in [year], in the exchange's own calendar.
  DateTime dateIn(int year);

  bool fallsOn(DateTime date) {
    final DateTime d = dateIn(date.year);
    return d.month == date.month && d.day == date.day;
  }
}

/// The same date every year. New Year's Day, Christmas, a national day.
class LumeFixedHoliday extends LumeHoliday {
  const LumeFixedHoliday(super.name, this.month, this.day);

  final int month;
  final int day;

  @override
  DateTime dateIn(int year) => DateTime(year, month, day);
}

/// The nth weekday of a month. `ordinal: -1` is the last one.
///
/// Thanksgiving is the fourth Thursday in November; the UK's early May bank
/// holiday is the first Monday in May; its summer one is the last Monday in
/// August. None of those is a date.
class LumeFloatingHoliday extends LumeHoliday {
  const LumeFloatingHoliday(
    super.name, {
    required this.month,
    required this.weekday,
    required this.ordinal,
  });

  final int month;

  /// `DateTime.monday` … `DateTime.sunday`.
  final int weekday;

  /// 1-based, or -1 for the last occurrence in the month.
  final int ordinal;

  @override
  DateTime dateIn(int year) =>
      LumeTimeZone.nthWeekdayOf(year, month, weekday, ordinal);
}

/// A fixed number of days from Easter Sunday. Good Friday is −2; Easter Monday
/// is +1.
///
/// Easter moves by a lunar rule, so it is computed rather than tabulated —
/// anniversary arithmetic that is wrong once every year is worse than none.
class LumeEasterHoliday extends LumeHoliday {
  const LumeEasterHoliday(super.name, {required this.offsetDays});

  final int offsetDays;

  @override
  DateTime dateIn(int year) =>
      easterSunday(year).add(Duration(days: offsetDays));

  /// Western (Gregorian) Easter — the anonymous Gregorian algorithm.
  static DateTime easterSunday(int year) {
    final int a = year % 19;
    final int b = year ~/ 100;
    final int c = year % 100;
    final int d = b ~/ 4;
    final int e = b % 4;
    final int f = (b + 8) ~/ 25;
    final int g = (b - f + 1) ~/ 3;
    final int h = (19 * a + b - d - g + 15) % 30;
    final int i = c ~/ 4;
    final int k = c % 4;
    final int l = (32 + 2 * e + 2 * i - h - k) % 7;
    final int m = (a + 11 * h + 22 * l) ~/ 451;
    final int month = (h + l - 7 * m + 114) ~/ 31;
    final int day = (h + l - 7 * m + 114) % 31 + 1;
    return DateTime(year, month, day);
  }
}

/// One exchange's trading calendar.
@immutable
class LumeMarketCalendar {
  const LumeMarketCalendar({required this.weekend, required this.holidays});

  /// The weekdays this exchange does not trade, as `DateTime.weekday` values.
  final Set<int> weekend;

  final List<LumeHoliday> holidays;

  bool isWeekend(DateTime date) => weekend.contains(date.weekday);

  /// The holiday closing [date], or `null`.
  LumeHoliday? holidayOn(DateTime date) {
    for (final LumeHoliday h in holidays) {
      if (h.fallsOn(date)) return h;
    }
    return null;
  }

  /// Saturday and Sunday — what most of the world uses.
  static const Set<int> weekendSatSun = <int>{
    DateTime.saturday,
    DateTime.sunday,
  };

  /// Friday and Saturday — the Saudi Exchange's week.
  static const Set<int> weekendFriSat = <int>{
    DateTime.friday,
    DateTime.saturday,
  };
}

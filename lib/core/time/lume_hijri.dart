/// The Hijri date of a day, as the reference computes it.
///
/// `context.js` `hijri()`: the Kuwaiti arithmetic calendar — a tabular
/// approximation that runs a 30-year cycle of 354- and 355-day years. It
/// needs no data and no platform, and it agrees with the observed calendar to
/// within a day or two, which is why the reference uses it for a label.
///
/// **Dayroz obligation:** a label is not a religious determination. Before
/// release the Hijri date must come from the authority each reader follows —
/// Umm al-Qura, a national moon-sighting committee, or the reader's own
/// setting — and say which.
library;

import 'package:flutter/foundation.dart';

@immutable
class LumeHijriDate {
  const LumeHijriDate(this.year, this.month, this.day);

  /// The Hijri date of the civil day [date] falls on.
  ///
  /// The reference computes from `Date.getTime()`, the instant, and floors a
  /// Julian day that begins at noon UTC — so its date turns over mid-afternoon
  /// in Pakistan, not at the reader's midnight. Here the day is the civil
  /// date's own, taken at its UTC midnight: every hour of a local day has one
  /// Hijri date, and it is the one the reference shows before noon UTC (C71).
  factory LumeHijriDate.of(DateTime date) {
    final int jd =
        (DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch /
                    86400000 +
                2440587.5)
            .floor();
    int l = jd - 1948440 + 10632;
    final int n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final int j =
        ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l =
        l -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final int month = (24 * l) ~/ 709;
    final int day = l - (709 * month) ~/ 24;
    final int year = 30 * n + j - 30;
    return LumeHijriDate(year, month, day);
  }

  final int year;

  /// 1–12: Muharram is 1.
  final int month;
  final int day;

  @override
  bool operator ==(Object other) =>
      other is LumeHijriDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'LumeHijriDate($year-$month-$day)';
}

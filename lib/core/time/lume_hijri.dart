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

  /// Walks forward from [start] (only its year/month/day matter — a civil
  /// date, not an instant) counting real calendar days until [matches] is
  /// true of that day's Hijri date.
  ///
  /// Field arithmetic on the date itself (`DateTime(year, month, day + i)`,
  /// which `DateTime` normalises across a month boundary on its own) — never
  /// `add(Duration)` on a local clock value, which a daylight-saving
  /// transition could carry past or short of midnight.
  ///
  /// Throws a [StateError] naming [reason] if nothing matches within
  /// [horizonDays] — a Hijri year is at most 355 days, so any predicate that
  /// is eventually true of some Hijri (month, day) is reachable well inside a
  /// generous horizon, and a genuine miss is a defect worth failing loudly
  /// over, not a silently wrong "next" date.
  static (DateTime gregorian, LumeHijriDate hijri, int daysAway) walkForward({
    required DateTime start,
    required bool Function(LumeHijriDate hijri) matches,
    required int horizonDays,
    required String reason,
  }) {
    for (int i = 0; i <= horizonDays; i++) {
      final DateTime d = DateTime(start.year, start.month, start.day + i);
      final LumeHijriDate h = LumeHijriDate.of(d);
      if (matches(h)) return (d, h, i);
    }
    throw StateError(reason);
  }
}

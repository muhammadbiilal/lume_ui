/// The date arithmetic `context.js` `dateCalc()` does.
///
/// Two modes: the days between two dates, and a date some days from another.
/// Either way the span is walked day by day — at most 4 000 days, as the
/// reference caps it — counting Saturdays and Sundays as the weekend.
library;

import 'package:flutter/foundation.dart';

enum LumeDateMode { difference, add }

@immutable
class LumeDateSpan {
  const LumeDateSpan({
    required this.days,
    required this.from,
    required this.to,
    required this.weekdays,
    required this.weekends,
  });

  /// `datecalc.days` default.
  static const int defaultDays = 30;

  /// `Math.min(abs, 4000)`.
  static const int walkCap = 4000;

  /// The span's length, never negative.
  final int days;
  final DateTime from;
  final DateTime to;
  final int weekdays;
  final int weekends;

  int get weeks => days ~/ 7;
  double get months => days / 30.44;
  double get years => days / 365.25;

  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Signed whole calendar days from [a] to [b].
  static int between(DateTime a, DateTime b) => DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  /// `new Date(a.y, a.m, a.d + n)`.
  static DateTime plus(DateTime a, int n) =>
      DateTime(a.year, a.month, a.day + n);

  static LumeDateSpan of(DateTime a, DateTime b) {
    final DateTime x = day(a), y = day(b);
    final int diff = between(x, y);
    final int abs = diff.abs();
    int weekdays = 0, weekends = 0;
    DateTime walk = diff < 0 ? y : x;
    for (int i = 0; i < (abs < walkCap ? abs : walkCap); i++) {
      if (walk.weekday == DateTime.saturday ||
          walk.weekday == DateTime.sunday) {
        weekends++;
      } else {
        weekdays++;
      }
      walk = plus(walk, 1);
    }
    return LumeDateSpan(
      days: abs,
      from: x,
      to: y,
      weekdays: weekdays,
      weekends: weekends,
    );
  }
}

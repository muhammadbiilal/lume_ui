/// Savings compounded monthly, as `context.js` `compound()` works them out.
///
/// Each month the balance grows by a twelfth of the annual return and the
/// month's addition is paid in; a year's value is what stands after its
/// twelfth month.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

@immutable
class LumeCompoundYear {
  const LumeCompoundYear({
    required this.year,
    required this.contributed,
    required this.value,
  });

  final int year;
  final double contributed;
  final double value;
}

@immutable
class LumeCompound {
  const LumeCompound._({
    required this.total,
    required this.contributed,
    required this.table,
    required this.series,
  });

  static const double defaultRate = 8;
  static const double defaultYears = 10;

  /// `Math.round(1000 * rate / 100) * 100`.
  static double openingInitial(double ratePerUsd) =>
      (1000 * ratePerUsd / 100).round() * 100.0;

  /// `Math.round(100 * rate / 10) * 10`.
  static double openingMonthly(double ratePerUsd) =>
      (100 * ratePerUsd / 10).round() * 10.0;

  final double total;
  final double contributed;
  final List<LumeCompoundYear> table;

  /// The year-end values, rounded; a single year is drawn from the start.
  final List<double> series;

  double get growth => total - contributed;

  /// `growth / Math.max(1, contributed) * 100`.
  double get returnPercent => growth / math.max(1, contributed) * 100;

  factory LumeCompound.of({
    required double initial,
    required double monthly,
    required double rate,
    required double years,
  }) {
    double v = initial, contributed = initial;
    final double r = rate / 100 / 12;
    final List<LumeCompoundYear> table = <LumeCompoundYear>[];
    final List<double> series = <double>[];
    for (int y = 1; y <= years; y++) {
      for (int m = 0; m < 12; m++) {
        v = v * (1 + r) + monthly;
        contributed += monthly;
      }
      series.add(v.roundToDouble());
      table.add(LumeCompoundYear(year: y, contributed: contributed, value: v));
    }
    return LumeCompound._(
      total: v,
      contributed: contributed,
      table: table,
      series: series.length > 1 ? series : <double>[initial, v],
    );
  }
}

/// A loan's instalment and schedule, as `context.js` `loan()` works them out.
///
/// The equal monthly instalment `P·r·(1+r)ⁿ / ((1+r)ⁿ − 1)`, or `P / n` at no
/// interest; a loan over no months has no payment (the reference's own guard
/// against `Infinity`). The schedule is year by year, at most eight years.
///
/// **One correction.** The reference declares `var principal` a second time
/// inside the schedule loop; `var` is function-scoped, so the loop overwrites
/// the loan amount with the last month's principal, and the "If the rate
/// changed" rows are worked out on that — at ±2 points the instalment falls to
/// a small fraction of the real one. Lume uses the loan amount (C83).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

@immutable
class LumeLoanYear {
  const LumeLoanYear({
    required this.year,
    required this.principal,
    required this.interest,
    required this.balance,
  });

  final int year;
  final double principal;
  final double interest;
  final double balance;
}

@immutable
class LumeLoan {
  const LumeLoan._({
    required this.principal,
    required this.rate,
    required this.years,
    required this.emi,
    required this.schedule,
  });

  static const double defaultRate = 12;
  static const double defaultYears = 5;

  /// The schedule's length cap.
  static const int scheduleYears = 8;

  /// `Math.round(20000 * rate / 1000) * 1000`.
  static double openingPrincipal(double ratePerUsd) =>
      (20000 * ratePerUsd / 1000).round() * 1000.0;

  final double principal;
  final double rate;
  final double years;
  final double emi;
  final List<LumeLoanYear> schedule;

  double get payments => math.max(0, years) * 12;
  double get totalPaid => emi * payments;
  double get totalInterest => math.max(0, totalPaid - principal);
  double get interestShare => totalPaid == 0 ? 0 : totalInterest / totalPaid;

  /// The instalment for [principal] at [rate] % a year over [payments] months.
  static double instalment(double principal, double rate, double payments) {
    if (payments <= 0) return 0;
    final double r = math.max(0, rate) / 100 / 12;
    if (r == 0) return principal / payments;
    final double g = math.pow(1 + r, payments).toDouble();
    return principal * r * g / (g - 1);
  }

  factory LumeLoan.of({
    required double principal,
    required double rate,
    required double years,
  }) {
    final double p = math.max(0, principal);
    final double n = math.max(0, years) * 12;
    final double r = math.max(0, rate) / 100 / 12;
    final double emi = instalment(p, rate, n);
    double balance = p;
    final List<LumeLoanYear> schedule = <LumeLoanYear>[];
    for (int y = 1; y <= math.min(years, scheduleYears); y++) {
      double pY = 0, iY = 0;
      for (int m = 0; m < 12 && balance > 0; m++) {
        final double interest = balance * r;
        final double part = emi - interest;
        balance -= part;
        pY += part;
        iY += interest;
      }
      schedule.add(
        LumeLoanYear(
          year: y,
          principal: pY,
          interest: iY,
          balance: math.max(0, balance),
        ),
      );
    }
    return LumeLoan._(
      principal: p,
      rate: rate,
      years: years,
      emi: emi,
      schedule: schedule,
    );
  }

  /// The instalment at [delta] points from this loan's rate.
  double at(double delta) => instalment(principal, rate + delta, payments);
}

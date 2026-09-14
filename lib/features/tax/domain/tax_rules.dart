/// Tax, worked out the way the reference works it out.
///
/// A line-by-line port of `context.js` `tax()`. Kept as a pure function over a
/// configuration so a test can hold it against the numbers the running
/// reference prints — and so the one place the arithmetic lives is not a
/// widget.
///
/// **What it is and is not.** The bands are `tool-data.js`'s `TAX` table, and
/// the reference applies them as a simple marginal schedule: each band's rate
/// on the slice of taxable income inside it. The fixed amounts the table also
/// carries (the third element of each band) are unused by the reference, and
/// unused here. This is a demonstration of a salaried calculation, not tax
/// advice, and Dayroz replaces the table with a maintained one.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Who publishes the schedule a market's bands come from.
enum LumeTaxAuthority {
  fbrSalaried,
  hmrcEngland,
  irsSingleFiler,
  indiaNewRegime,
  noPersonalIncomeTax,
}

/// A levy a salary meets besides income tax — `leviesFor()`'s keys.
enum LumeLevy {
  vat,
  pension,
  corporate,
  gosi,
  zakatRate,
  ni,
  socialSecurity,
  medicare,
  gst,
  eobi,
  pf,
}

/// Monthly or annual — the segmented control.
enum LumeTaxPeriod { month, year }

/// One band: income up to [upper] is taxed at [rate] above the band below.
@immutable
class LumeTaxBand {
  const LumeTaxBand(this.upper, this.rate);

  /// `Infinity` for the top band.
  final double upper;
  final double rate;
}

/// A market's schedule.
@immutable
class LumeTaxConfig {
  const LumeTaxConfig({
    required this.currency,
    required this.year,
    required this.authority,
    required this.bands,
  });

  final String currency;
  final String year;
  final LumeTaxAuthority authority;
  final List<LumeTaxBand> bands;

  /// `cfg.bands.length > 1` — a single zero band means no income tax.
  bool get taxable => bands.length > 1;
}

/// A levy and its headline rate, in percent.
@immutable
class LumeLevyRate {
  const LumeLevyRate(this.levy, this.rate);

  final LumeLevy levy;
  final double rate;
}

/// One row of "How it is worked out".
@immutable
class LumeTaxBandResult {
  const LumeTaxBandResult({
    required this.lower,
    required this.upper,
    required this.rate,
    required this.tax,
  });

  final double lower;
  final double upper;
  final double rate;
  final double tax;

  bool get isTop => upper == double.infinity;
}

/// The calculation, for one set of inputs.
@immutable
class LumeTaxResult {
  const LumeTaxResult({
    required this.config,
    required this.period,
    required this.taxableAnnual,
    required this.dueAnnual,
    required this.netAnnual,
    required this.effective,
    required this.marginal,
    required this.bands,
  });

  final LumeTaxConfig config;
  final LumeTaxPeriod period;
  final double taxableAnnual;
  final double dueAnnual;
  final double netAnnual;

  /// Due over gross, 0 when there is no income.
  final double effective;

  /// The rate of the highest band any income reached.
  final double marginal;

  /// The bands up to and including the one taxable income ends in.
  final List<LumeTaxBandResult> bands;

  /// The headline figure, in the period being shown.
  double get dueDisplay =>
      period == LumeTaxPeriod.month ? dueAnnual / 12 : dueAnnual;

  double get netDisplay =>
      period == LumeTaxPeriod.month ? netAnnual / 12 : netAnnual;
}

/// The reference's arithmetic.
abstract final class LumeTaxRules {
  /// `Math.round` — half rounds up, towards positive infinity.
  static double jsRound(double v) => (v + 0.5).floorToDouble();

  /// The income a taxable market's field opens on: about 3,000 dollars a
  /// month in the market's currency, to the nearest thousand —
  /// `Math.round(3000 * rate / 1000) * 1000`.
  static double openingIncome(double ratePerUsd) =>
      jsRound(3000 * ratePerUsd / 1000) * 1000;

  /// The salary a market with no income tax opens on — `3000 * rate`, not
  /// rounded.
  static double openingGross(double ratePerUsd) => 3000 * ratePerUsd;

  /// `tax()`, for [income] in [period] less [deductions] a year.
  static LumeTaxResult compute(
    LumeTaxConfig config, {
    required LumeTaxPeriod period,
    required double income,
    required double deductions,
  }) {
    final double annual = period == LumeTaxPeriod.month ? income * 12 : income;
    final double taxableAnnual = math.max(0, annual - deductions);

    double due = 0;
    double marginal = 0;
    double lower = 0;
    final List<LumeTaxBandResult> bands = <LumeTaxBandResult>[];
    for (final LumeTaxBand band in config.bands) {
      final double inBand = math.max(
        0,
        math.min(taxableAnnual, band.upper) - lower,
      );
      if (inBand > 0) {
        due += inBand * band.rate;
        marginal = band.rate;
      }
      bands.add(
        LumeTaxBandResult(
          lower: lower,
          upper: band.upper,
          rate: band.rate,
          tax: inBand * band.rate,
        ),
      );
      lower = band.upper;
      if (taxableAnnual <= band.upper) break;
    }

    return LumeTaxResult(
      config: config,
      period: period,
      taxableAnnual: taxableAnnual,
      dueAnnual: due,
      netAnnual: annual - due,
      effective: annual != 0 ? due / annual : 0,
      marginal: marginal,
      bands: List<LumeTaxBandResult>.unmodifiable(bands),
    );
  }
}

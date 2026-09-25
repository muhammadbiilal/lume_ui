/// Body Mass Index, as `context.js` `bmi()` works it out.
///
/// `assets/js/tools/personal/bmi.tool.js` composes the fields, the summary
/// card and the scale over `context.js:1147-1185`. The maths lives here so it
/// can be tested without a widget tree, exactly as [LumeAge] (`age_maths.dart`)
/// separates the calendar arithmetic from the screen that draws it.
///
/// **What is kept.** The formula — `kg / m²`, worked out from the height and
/// weight the reader typed, in whichever unit system they measure in — the
/// four WHO-style bands the reference itself defines (`BMI_BANDS`,
/// `context.js:1148-1153`), and the healthy-weight range and its midpoint
/// (`context.js:1170,1178-1179`), each worked out from the reader's own
/// height and nothing else.
///
/// **What is dropped, and why.** `context.js:1183` ships a `history` array —
/// `[value + 1.4, value + 1.1, value + 0.6, value + 0.2, value]` — offsets
/// invented from the *current* reading and drawn as a five-point trend line.
/// Nothing stores a past calculation, so there is no trend to show; the array
/// is a decoration wearing the shape of data. This is the same call Unit
/// Converter makes about its own two literal "Recent" conversions
/// (`converter_tool.dart`, "the one subtraction") and the reason is the same
/// one: a plausible-looking history of readings the reader never took is
/// worse than no history at all. It is left out rather than seeded with a
/// zero or a repeat of today's figure.
///
/// **The imperial conversion is kept approximate, on purpose.** The
/// reference's own factor is `0.453592` (`context.js:1165`) rather than the
/// pound's defined `0.45359237` that `converter/domain/unit_table.dart`
/// carries — a difference invisible at the display's rounding, and one this
/// file matches exactly rather than "fixing", because the brief for this tool
/// asks for the reference's own formula, not a re-derivation of it.
library;

import 'package:flutter/foundation.dart';

/// Which of the reference's four bands a reading falls in.
///
/// `BMI_BANDS` (`context.js:1148-1153`), in the order the reference lists
/// them and the scale draws them.
enum LumeBmiBand { underweight, healthy, overweight, obese }

/// One band's own BMI thresholds — unitless, and the same for every reader
/// regardless of which unit system they measure in.
@immutable
class LumeBmiBandRange {
  const LumeBmiBandRange({required this.band, this.lo, this.hi});

  final LumeBmiBand band;

  /// `null` means "no floor" — the reference's `lo: null` on underweight.
  final double? lo;

  /// `null` means "no ceiling" — the reference's `hi: null` on obese.
  final double? hi;
}

/// `BMI_BANDS`, exactly: under 18.5, 18.5 up to 25, 25 up to 30, 30 and over.
const List<LumeBmiBandRange> lumeBmiBands = <LumeBmiBandRange>[
  LumeBmiBandRange(band: LumeBmiBand.underweight, hi: 18.5),
  LumeBmiBandRange(band: LumeBmiBand.healthy, lo: 18.5, hi: 25),
  LumeBmiBandRange(band: LumeBmiBand.overweight, lo: 25, hi: 30),
  LumeBmiBandRange(band: LumeBmiBand.obese, lo: 30),
];

/// `BMI_BANDS.filter(b => value < b.max)[0] || BMI_BANDS[3]` — the first band
/// a value is under, or the last one when nothing is (a BMI of 99 and above,
/// which the reference's own ceiling never actually excludes either).
LumeBmiBand lumeBmiBandFor(double value) {
  for (final LumeBmiBandRange range in lumeBmiBands) {
    if (range.hi == null || value < range.hi!) return range.band;
  }
  return LumeBmiBand.obese;
}

/// One reading, worked out from a height and a weight in the reader's own
/// unit system.
@immutable
class LumeBmiResult {
  const LumeBmiResult({
    required this.value,
    required this.band,
    required this.healthyLowKg,
    required this.healthyHighKg,
    required this.idealKg,
  });

  /// `fieldsFor('bmi', { height: imperial ? 69 : 175, weight: imperial ? 165
  /// : 75 })` — the reference's own opening figures, in the unit the field
  /// opens in.
  static const double defaultHeightMetric = 175;
  static const double defaultHeightImperial = 69;
  static const double defaultWeightMetric = 75;
  static const double defaultWeightImperial = 165;

  /// `kg / (height in metres)²`.
  final double value;

  final LumeBmiBand band;

  /// The healthy-weight range for this height, in kilograms — `18.5 × m²` to
  /// `24.9 × m²` (`context.js:1170`, which stops short of the band's own 25).
  final double healthyLowKg;
  final double healthyHighKg;

  /// The midpoint of the healthy range, in kilograms (`context.js:1179`).
  final double idealKg;

  /// `bmi()`, `context.js:1161-1185`, minus the fabricated `history`.
  ///
  /// A height of zero or less — a cleared field — reads as a BMI of zero
  /// rather than dividing by it, exactly as the reference's own guard does
  /// (`context.js:1166-1167`).
  static LumeBmiResult of({
    required double height,
    required double weight,
    required bool imperial,
  }) {
    final double heightMetres = imperial ? height * 0.0254 : height / 100;
    final double weightKg = imperial ? weight * 0.453592 : weight;
    final double value = heightMetres > 0
        ? weightKg / (heightMetres * heightMetres)
        : 0;
    final double lowKg = 18.5 * heightMetres * heightMetres;
    final double highKg = 24.9 * heightMetres * heightMetres;
    return LumeBmiResult(
      value: value,
      band: lumeBmiBandFor(value),
      healthyLowKg: lowKg,
      healthyHighKg: highKg,
      idealKg: (lowKg + highKg) / 2,
    );
  }

  /// `Math.min(1, bmi / 40)` — the reference's own gauge ceiling.
  double get gauge => (value / 40).clamp(0.0, 1.0);
}

/// A weight in kilograms, in the reader's own unit — `Math.round(k /
/// 0.453592)` lb, or `Math.round(k)` kg (`context.js:1171-1174`'s `w()`).
double lumeBmiDisplayWeight(double kg, {required bool imperial}) =>
    imperial ? kg / 0.453592 : kg;

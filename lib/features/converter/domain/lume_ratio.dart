/// An exact rational, for conversions whose result does not terminate.
///
/// **Why not [LumeDecimal].** The calculator's decimal is the right model for
/// a calculator: it is exact, and where a quotient does not end it *refuses*
/// rather than rounding, because a reader pressing `1 ÷ 3` deserves to be
/// told. A unit converter cannot refuse. Metres into miles is a division by
/// 1609.344 and almost never terminates, and "that division does not end" is
/// not an answer to "how far is 5 km". So the arithmetic here is exact and
/// the **rounding happens once, at the end, for the display** — never in the
/// middle, where it would compound.
///
/// **Why not `double`.** A double would in practice be accurate enough for
/// four decimal places. It would also make the factor table a set of
/// approximations of values that are *defined* exactly — a mile is exactly
/// 1609.344 m, a pound exactly 0.45359237 kg — and it would put a rounding
/// step between every pair of units in a round trip. `BigInt` costs nothing
/// at this size and removes the question.
///
/// Every value is normalised: the denominator is positive, and numerator and
/// denominator share no factor.
library;

import 'package:flutter/foundation.dart';

@immutable
class LumeRatio {
  const LumeRatio._(this.numerator, this.denominator);

  /// [numerator] / [denominator], reduced. A zero denominator is a
  /// programming error, not a reader's input, so it asserts.
  factory LumeRatio(BigInt numerator, BigInt denominator) {
    assert(denominator != BigInt.zero, 'a ratio cannot have a zero divisor');
    if (numerator == BigInt.zero) return zero;
    BigInt n = numerator;
    BigInt d = denominator;
    if (d.isNegative) {
      n = -n;
      d = -d;
    }
    final BigInt g = n.abs().gcd(d);
    return LumeRatio._(n ~/ g, d ~/ g);
  }

  factory LumeRatio.whole(int value) =>
      LumeRatio._(BigInt.from(value), BigInt.one);

  /// A decimal literal — `'1609.344'`, `'0.45359237'`, `'-3.5'`.
  ///
  /// This is how the factor table is written, so that a factor in the source
  /// reads as the defined value does in the standard that defines it, with no
  /// arithmetic in between for a reader to check.
  factory LumeRatio.parse(String text) {
    final Match? m = _decimal.firstMatch(text.trim());
    if (m == null) {
      throw FormatException('not a decimal literal', text);
    }
    final bool negative = m.group(1) == '-';
    final String whole = m.group(2)!;
    final String fraction = m.group(3) ?? '';
    final BigInt n = BigInt.parse('$whole$fraction');
    final BigInt d = BigInt.from(10).pow(fraction.length);
    return LumeRatio(negative ? -n : n, d);
  }

  /// A reader's typed amount, or `null` where the field does not hold a
  /// number. Grouping separators are not accepted: what reaches here has
  /// already been read by the field's own parser.
  static LumeRatio? tryParse(String text) {
    final String t = text.trim();
    if (t.isEmpty) return null;
    return _decimal.hasMatch(t) ? LumeRatio.parse(t) : null;
  }

  static final RegExp _decimal = RegExp(r'^([+-])?([0-9]+)(?:\.([0-9]*))?$');

  static final LumeRatio zero = LumeRatio._(BigInt.zero, BigInt.one);
  static final LumeRatio one = LumeRatio._(BigInt.one, BigInt.one);

  final BigInt numerator;
  final BigInt denominator;

  bool get isZero => numerator == BigInt.zero;
  bool get isNegative => numerator.isNegative;

  LumeRatio operator *(LumeRatio other) =>
      LumeRatio(numerator * other.numerator, denominator * other.denominator);

  LumeRatio operator /(LumeRatio other) {
    assert(!other.isZero, 'a ratio cannot be divided by zero');
    return LumeRatio(
      numerator * other.denominator,
      denominator * other.numerator,
    );
  }

  LumeRatio operator +(LumeRatio other) => LumeRatio(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  );

  LumeRatio operator -(LumeRatio other) => LumeRatio(
    numerator * other.denominator - other.numerator * denominator,
    denominator * other.denominator,
  );

  /// The value rounded to [places] decimals, **half away from zero**, as a
  /// plain decimal string with no grouping and no exponent.
  ///
  /// Half away from zero rather than half to even because this is a figure a
  /// reader reads, not a sum that will be added to a thousand others: 2.5
  /// displayed to zero places should read 3, as it does on paper and as
  /// `Intl.NumberFormat` renders it.
  ///
  /// Trailing zeros are not kept — `1 km` in metres is `1000`, not
  /// `1000.0000` — because the reference's `maximumFractionDigits` drops them
  /// too, and a converter that padded every answer would be harder to read.
  String toStringAsFixedMax(int places) {
    assert(places >= 0);
    final BigInt scale = BigInt.from(10).pow(places);
    final BigInt scaled = numerator * scale;
    // Round half away from zero: add half a unit of the last place before
    // truncating, with the sign of the value.
    final BigInt twice = scaled.abs() * BigInt.two;
    final BigInt d2 = denominator * BigInt.two;
    BigInt rounded = (twice + denominator) ~/ d2;
    if (isNegative) rounded = -rounded;

    if (places == 0) return rounded.toString();
    final bool negative = rounded.isNegative;
    final String digits = rounded.abs().toString().padLeft(places + 1, '0');
    final String whole = digits.substring(0, digits.length - places);
    String fraction = digits.substring(digits.length - places);
    while (fraction.isNotEmpty && fraction.endsWith('0')) {
      fraction = fraction.substring(0, fraction.length - 1);
    }
    final String sign = negative && rounded != BigInt.zero ? '-' : '';
    return fraction.isEmpty ? '$sign$whole' : '$sign$whole.$fraction';
  }

  /// For a chart, a bar width or anything that only needs to be close.
  /// Never used for a figure a reader reads.
  double get approximate => numerator / denominator;

  @override
  bool operator ==(Object other) =>
      other is LumeRatio &&
      other.numerator == numerator &&
      other.denominator == denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() =>
      denominator == BigInt.one ? '$numerator' : '$numerator/$denominator';
}

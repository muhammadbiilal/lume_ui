/// An exact decimal number: a scaled integer significand.
///
/// **Why this exists.** The reference calculator is `Number` arithmetic with a
/// trim on the way out (`tool.screen.js:898-901`), and binary floating point
/// cannot represent a tenth. `0.1 + 0.2` is `0.30000000000000004`;
/// `String(1.1 / 100)` is `0.011000000000000001`, which the reference's `%`
/// key renders raw (`:935`, defect 2); and the trim itself fails above
/// |r| > 900,719.925, because `r * 1e10` passes 2^53 and rounding no longer
/// moves a digit — so `10000000 ÷ 3` comes out `3333333.3333333335`
/// (`:900, :914`, defect 3). None of those is a rounding bug that a better
/// `toFixed` would fix. They are the wrong numeric model.
///
/// So the model here is decimal, in the spirit of `LumeMoney`: an `int`
/// significand and a decimal exponent, exact arithmetic, and a **typed
/// failure** where a result cannot be represented — never a clamp, never a
/// wrap, never a rounded value presented as if it were exact.
///
/// ## The model
///
/// A value is `significand / 10^scale`, with `0 ≤ scale ≤ [maxScale]` (12) and
/// `|significand| ≤ [maxSignificand]` (2^53 − 1). Two decimals that differ
/// only in trailing zeros are equal; every operation returns its result in
/// [normalised] form, so `0.30` and `0.3` are one value with one hash.
///
/// 2^53 − 1 is the bound rather than 2^63 − 1 because it is the largest
/// integer a **web** build represents exactly, and a number must mean the
/// same thing on every platform Lume ships to. `LumeMoney.maxSumMinor` is the
/// same constant for the same reason.
///
/// ## Rounding policy: there is none
///
/// Nothing here rounds, ever. `+`, `−` and `×` are exact by construction:
/// addition and subtraction align to the wider scale, multiplication adds the
/// scales. Each result is bounds-checked; past a bound is
/// [LumeDecimalFailure.overflow].
///
/// A product can want more decimal places than the model holds
/// (`0.000001 × 0.000001` needs twelve, `0.0000001 × 0.0000001` needs
/// fourteen). Past [maxScale] the exact product cannot be stored, and that is
/// [LumeDecimalFailure.precision] — not a quiet truncation to twelve places.
///
/// ## Division policy
///
/// Division is the one operation that need not terminate. [divide] works out
/// the exact quotient or refuses:
///
/// * the fraction is reduced by its greatest common divisor;
/// * the reduced divisor is stripped of its factors of 2 and 5;
/// * **anything left is a non-terminating quotient** — `1 ÷ 3`,
///   `10000000 ÷ 3` — and that is [LumeDecimalFailure.precision]. The reader
///   is told the division does not end (`l.calcErrPrecision`); they are never
///   shown `3333333.333333333333` as though it were the answer;
/// * a quotient that terminates but past [maxScale] places (`1 ÷ 8192` needs
///   thirteen) is the same refusal, for the same reason;
/// * a quotient that terminates within [maxScale] is returned **exact**:
///   `1 ÷ 8` is `0.125`, `1.1 ÷ 100` is `0.011`, to the digit.
///
/// Division by zero is [LumeDecimalFailure.divideByZero]. The reference
/// returns `0` (`tool.screen.js:913`, defect 1), which is a wrong answer
/// wearing the clothes of a right one.
///
/// Nothing here formats for a reader: digits, separators and grouping are
/// `LumeFormatting`'s concern, and [toDecimalString] is the machine form the
/// formatter is handed.
library;

import 'package:flutter/foundation.dart';

/// Why a decimal could not be made or calculated.
enum LumeDecimalFailure {
  /// A significand past [LumeDecimal.maxSignificand].
  overflow,

  /// An exact result needs more decimal places than [LumeDecimal.maxScale],
  /// or does not terminate at all.
  precision,

  /// A divisor of zero.
  divideByZero,

  /// Not a machine decimal at all.
  malformed,
}

/// A value refused, and why. [limit] is the bound that was passed — a bare
/// number, and nothing about who was calculating.
@immutable
class LumeDecimalException implements Exception {
  const LumeDecimalException(this.failure, {this.limit});

  final LumeDecimalFailure failure;
  final int? limit;

  @override
  String toString() =>
      'LumeDecimalException(${failure.name}'
      '${limit == null ? '' : ', limit $limit'})';
}

/// An exact decimal: [significand] / 10^[scale].
@immutable
class LumeDecimal implements Comparable<LumeDecimal> {
  const LumeDecimal._(this.significand, this.scale);

  /// The most decimal places any value holds.
  static const int maxScale = 12;

  /// 2^53 − 1: the largest significand, in magnitude. The largest integer a
  /// web build represents exactly, so the bound is the same everywhere.
  static const int maxSignificand = 9007199254740991;

  static const LumeDecimal zero = LumeDecimal._(0, 0);
  static const LumeDecimal one = LumeDecimal._(1, 0);
  static const LumeDecimal hundred = LumeDecimal._(100, 0);

  /// [significand] / 10^[scale], checked.
  factory LumeDecimal.of(int significand, int scale) {
    if (scale < 0 || scale > maxScale) {
      throw const LumeDecimalException(
        LumeDecimalFailure.precision,
        limit: maxScale,
      );
    }
    _bound(significand);
    return LumeDecimal._(significand, scale).normalised;
  }

  /// [text] as a machine decimal — ASCII digits, an optional leading `-`, an
  /// optional `.`, no grouping: `0`, `-12`, `34000.50`, `1.` (a point with
  /// nothing after it yet, which is what a half-typed entry looks like).
  ///
  /// A reader's own digits and separators are normalised **before** this, the
  /// way `ledgerParseAmount` does it.
  factory LumeDecimal.parse(String text) {
    final RegExpMatch? m = _decimal.firstMatch(text);
    if (m == null) {
      throw const LumeDecimalException(LumeDecimalFailure.malformed);
    }
    final bool negative = m.group(1) != null;
    final String whole = m.group(2)!;
    final String fraction = m.group(3) ?? '';
    if (fraction.length > maxScale) {
      throw const LumeDecimalException(
        LumeDecimalFailure.precision,
        limit: maxScale,
      );
    }
    final String digits = '$whole$fraction';
    // More digits than the bound has cannot be parsed to an exact `int` on a
    // web build at all, so the length is refused before `int.parse` is asked.
    if (digits.replaceFirst(RegExp('^0+'), '').length > 16) {
      throw const LumeDecimalException(
        LumeDecimalFailure.overflow,
        limit: maxSignificand,
      );
    }
    final int value = digits.isEmpty ? 0 : int.parse(digits);
    _bound(value);
    return LumeDecimal._(negative ? -value : value, fraction.length).normalised;
  }

  static final RegExp _decimal = RegExp(r'^(-)?([0-9]+)(?:\.([0-9]*))?$');

  final int significand;
  final int scale;

  bool get isZero => significand == 0;
  bool get isNegative => significand < 0;

  /// The same value with no trailing zeros in its fraction, so equality and
  /// hashing do not depend on how a value was written.
  LumeDecimal get normalised {
    int s = significand;
    int e = scale;
    if (s == 0) return zero;
    while (e > 0 && s % 10 == 0) {
      s ~/= 10;
      e--;
    }
    return LumeDecimal._(s, e);
  }

  /// Checked addition. Exact: the operands align to the wider scale.
  LumeDecimal operator +(LumeDecimal other) => _sum(other, 1);

  /// Checked subtraction.
  LumeDecimal operator -(LumeDecimal other) => _sum(other, -1);

  LumeDecimal operator -() => LumeDecimal._(-significand, scale);

  LumeDecimal _sum(LumeDecimal other, int sign) {
    final int s = scale > other.scale ? scale : other.scale;
    final int a = _at(s);
    final int b = other._at(s);
    final int r = a + sign * b;
    _bound(r);
    return LumeDecimal._(r, s).normalised;
  }

  /// Checked multiplication. Exact, or a typed failure: the scales add, and a
  /// product needing more than [maxScale] places is
  /// [LumeDecimalFailure.precision] rather than a truncation.
  LumeDecimal operator *(LumeDecimal other) {
    final LumeDecimal a = normalised;
    final LumeDecimal b = other.normalised;
    if (a.isZero || b.isZero) return zero;
    final int ax = a.significand.abs();
    final int bx = b.significand.abs();
    if (ax > maxSignificand ~/ bx) {
      throw const LumeDecimalException(
        LumeDecimalFailure.overflow,
        limit: maxSignificand,
      );
    }
    final LumeDecimal r = LumeDecimal._(
      a.significand * b.significand,
      a.scale + b.scale,
    ).normalised;
    if (r.scale > maxScale) {
      throw const LumeDecimalException(
        LumeDecimalFailure.precision,
        limit: maxScale,
      );
    }
    return r;
  }

  /// The exact quotient, or a typed failure. See the library comment for the
  /// policy; in short: zero divisor refuses, a non-terminating quotient
  /// refuses, and everything else is exact to the digit.
  LumeDecimal divide(LumeDecimal other) {
    if (other.isZero) {
      throw const LumeDecimalException(LumeDecimalFailure.divideByZero);
    }
    if (isZero) return zero;
    final LumeDecimal a = normalised;
    final LumeDecimal b = other.normalised;
    final bool negative = a.isNegative != b.isNegative;

    // a / b = (A / B) · 10^(b.scale − a.scale). Reduce A / B, then ask
    // whether what is left of the divisor is a product of 2s and 5s — the
    // only divisors a decimal expansion terminates on.
    int p = a.significand.abs();
    int q = b.significand.abs();
    final int g = _gcd(p, q);
    p ~/= g;
    q ~/= g;
    int twos = 0;
    while (q % 2 == 0) {
      q ~/= 2;
      twos++;
    }
    int fives = 0;
    while (q % 5 == 0) {
      q ~/= 5;
      fives++;
    }
    if (q != 1) {
      // 1 ÷ 3, 10000000 ÷ 3: the expansion never ends, at any scale.
      throw const LumeDecimalException(
        LumeDecimalFailure.precision,
        limit: maxScale,
      );
    }

    // P / 10^m = p / (2^twos · 5^fives), by making the divisor a power of ten.
    final int m = twos > fives ? twos : fives;
    int product = p;
    for (int i = 0; i < m - twos; i++) {
      product = _times(product, 2);
    }
    for (int i = 0; i < m - fives; i++) {
      product = _times(product, 5);
    }

    int t = m - (b.scale - a.scale);
    if (t < 0) {
      for (int i = 0; i < -t; i++) {
        product = _times(product, 10);
      }
      t = 0;
    }
    if (t > maxScale) {
      // It terminates, but past what this holds — 1 ÷ 8192 wants thirteen
      // places. Refused rather than rounded to twelve.
      throw const LumeDecimalException(
        LumeDecimalFailure.precision,
        limit: maxScale,
      );
    }
    _bound(product);
    return LumeDecimal._(negative ? -product : product, t).normalised;
  }

  /// This value as a per cent of itself — `x ÷ 100`, exactly.
  ///
  /// The reference's `%` key is `String(Number(b) / 100)` and skips its own
  /// trim (`tool.screen.js:935`), which is how `1.1 %` renders
  /// `0.011000000000000001`. Here it is `0.011`.
  LumeDecimal get perCent => divide(hundred);

  /// Whole and fraction as a machine decimal, `.` separated, no grouping, no
  /// trailing zeros: `0`, `-12`, `0.011`. The formatter's input.
  String toDecimalString() {
    final String sign = significand < 0 ? '-' : '';
    final String digits = significand.abs().toString().padLeft(scale + 1, '0');
    if (scale == 0) return '$sign$digits';
    final int cut = digits.length - scale;
    return '$sign${digits.substring(0, cut)}.${digits.substring(cut)}';
  }

  /// The number of digits this value is written with, the decimal point and
  /// the sign not counted. An entry's length limit is measured with it.
  int get digitCount =>
      significand.abs().toString().padLeft(scale + 1, '0').length;

  /// [significand] rescaled to [target] places, checked. [target] is never
  /// smaller than [scale], so nothing is ever dropped.
  int _at(int target) {
    int v = significand;
    for (int i = scale; i < target; i++) {
      v = _times(v, 10);
    }
    return v;
  }

  static int _times(int v, int by) {
    if (v.abs() > maxSignificand ~/ by) {
      throw const LumeDecimalException(
        LumeDecimalFailure.overflow,
        limit: maxSignificand,
      );
    }
    return v * by;
  }

  static int _gcd(int a, int b) {
    int x = a;
    int y = b;
    while (y != 0) {
      final int t = x % y;
      x = y;
      y = t;
    }
    return x;
  }

  static void _bound(int v) {
    if (v > maxSignificand || v < -maxSignificand) {
      throw const LumeDecimalException(
        LumeDecimalFailure.overflow,
        limit: maxSignificand,
      );
    }
  }

  /// Orders two decimals of any scale.
  ///
  /// The alignment is done in [BigInt] so that comparing a large value with a
  /// finely scaled one cannot itself overflow. It is the one place a wide
  /// integer appears; no arithmetic result is ever built from one.
  @override
  int compareTo(LumeDecimal other) {
    if (scale == other.scale) return significand.compareTo(other.significand);
    final int s = scale > other.scale ? scale : other.scale;
    final BigInt a = BigInt.from(significand) * _pow10(s - scale);
    final BigInt b = BigInt.from(other.significand) * _pow10(s - other.scale);
    return a.compareTo(b);
  }

  static BigInt _pow10(int n) => BigInt.from(10).pow(n);

  @override
  bool operator ==(Object other) =>
      other is LumeDecimal && compareTo(other) == 0;

  @override
  int get hashCode {
    final LumeDecimal n = normalised;
    return Object.hash(n.significand, n.scale);
  }

  @override
  String toString() => toDecimalString();
}

/// An amount of money: whole minor units of one currency.
///
/// **Exact.** Minor units are an `int` — never a `double`, never a formatted
/// string — so 0.1 + 0.2 is 30 minor units and nothing else. No arithmetic
/// crosses currencies and no exchange rate exists here: adding USD to PKR is
/// a typed [LumeMoneyFailure.currencyMismatch], not a conversion.
///
/// **Bounded, the same on every platform.** An amount entered or stored is at
/// most [maxEntryMinor] (10^15 minor units: ten trillion rupees); any sum,
/// difference or projection is at most [maxSumMinor] in magnitude (2^53 − 1,
/// the largest integer a web build represents exactly). Passing either is a
/// typed [LumeMoneyFailure.overflow] — never clamped, wrapped or rounded.
///
/// **Signs belong to calculations.** An entry amount is never negative
/// ([LumeMoney.entry]); the direction of money is the record's meaning, not
/// its sign. A calculation may still produce a signed value — a balance —
/// and compare it; it is never stored as a signed presentation string.
///
/// Display is [LumeFormatting]'s concern; nothing here formats for a reader.
library;

import 'package:flutter/foundation.dart';

import 'lume_currency.dart';

/// Why an amount could not be made or calculated.
enum LumeMoneyFailure {
  /// A sum, difference or entry past its bound.
  overflow,

  /// Two currencies in one calculation.
  currencyMismatch,

  /// A negative amount where only zero or more is allowed.
  negative,

  /// More decimal places than the currency's exponent.
  precision,

  /// Not a decimal number at all.
  malformed,
}

/// An amount refused, and why. [limit] and [attempted] are diagnostic
/// metadata — minor-unit figures and nothing about whose money it is.
@immutable
class LumeMoneyException implements Exception {
  const LumeMoneyException(
    this.failure, {
    this.currency,
    this.other,
    this.limit,
    this.attempted,
  });

  final LumeMoneyFailure failure;
  final LumeCurrency? currency;

  /// The second currency of a mismatch.
  final LumeCurrency? other;

  /// The bound that was passed, or the exponent that was exceeded.
  final int? limit;

  /// What the calculation would have been, where it is representable.
  final int? attempted;

  @override
  String toString() =>
      'LumeMoneyException(${failure.name}, $currency'
      '${other == null ? '' : ' / $other'}'
      '${limit == null ? '' : ', limit $limit'})';
}

@immutable
class LumeMoney implements Comparable<LumeMoney> {
  const LumeMoney._(this.minor, this.currency);

  /// 10^15: the most one entry may be, in minor units.
  static const int maxEntryMinor = 1000000000000000;

  /// 2^53 − 1: the most any sum may be, in magnitude, in minor units.
  static const int maxSumMinor = 9007199254740991;

  /// Zero of [currency].
  const LumeMoney.zero(this.currency) : minor = 0;

  /// An amount as entered or stored: 0 ≤ [minor] ≤ [maxEntryMinor].
  factory LumeMoney.entry(int minor, LumeCurrency currency) {
    if (minor < 0) {
      throw LumeMoneyException(
        LumeMoneyFailure.negative,
        currency: currency,
        attempted: minor,
      );
    }
    if (minor > maxEntryMinor) {
      throw LumeMoneyException(
        LumeMoneyFailure.overflow,
        currency: currency,
        limit: maxEntryMinor,
        attempted: minor,
      );
    }
    return LumeMoney._(minor, currency);
  }

  /// A calculated amount, signed: |[minor]| ≤ [maxSumMinor].
  factory LumeMoney.sum(int minor, LumeCurrency currency) {
    _bound(minor, currency);
    return LumeMoney._(minor, currency);
  }

  /// [text] as a machine decimal — ASCII digits, an optional `.` and at most
  /// the currency's exponent of digits after it, no sign, no grouping:
  /// `34000`, `34000.5`, `34000.50`. More places is a typed
  /// [LumeMoneyFailure.precision]; nothing is rounded. A form normalises what
  /// the reader typed (their digits, their separators) before calling this.
  factory LumeMoney.parse(String text, LumeCurrency currency) {
    final RegExpMatch? m = _decimal.firstMatch(text);
    if (m == null) {
      throw LumeMoneyException(LumeMoneyFailure.malformed, currency: currency);
    }
    final String whole = m.group(1)!;
    final String fraction = m.group(2) ?? '';
    if (fraction.length > currency.exponent) {
      throw LumeMoneyException(
        LumeMoneyFailure.precision,
        currency: currency,
        limit: currency.exponent,
      );
    }
    // More whole digits than the bound has cannot fit, and would lose
    // precision as an int on the web before it could be compared.
    if (whole.replaceFirst(RegExp('^0+'), '').length > 16) {
      throw LumeMoneyException(
        LumeMoneyFailure.overflow,
        currency: currency,
        limit: maxEntryMinor,
      );
    }
    final int minor =
        int.parse(whole) * currency.scale +
        (fraction.isEmpty
            ? 0
            : int.parse(fraction.padRight(currency.exponent, '0')));
    return LumeMoney.entry(minor, currency);
  }

  static final RegExp _decimal = RegExp(r'^([0-9]+)(?:\.([0-9]+))?$');

  /// Minor units: paisa, cents, fils. Signed only in a calculation.
  final int minor;
  final LumeCurrency currency;

  bool get isZero => minor == 0;
  bool get isPositive => minor > 0;
  bool get isNegative => minor < 0;

  /// This amount without its sign.
  LumeMoney get magnitude => isNegative ? LumeMoney._(-minor, currency) : this;

  /// Checked addition.
  LumeMoney operator +(LumeMoney other) {
    _same(other);
    return LumeMoney.sum(minor + other.minor, currency);
  }

  /// Checked subtraction.
  LumeMoney operator -(LumeMoney other) {
    _same(other);
    return LumeMoney.sum(minor - other.minor, currency);
  }

  LumeMoney operator -() => LumeMoney._(-minor, currency);

  /// The sum of [amounts], all in [currency]; zero when there are none.
  static LumeMoney total(Iterable<LumeMoney> amounts, LumeCurrency currency) {
    LumeMoney sum = LumeMoney.zero(currency);
    for (final LumeMoney m in amounts) {
      sum += m;
    }
    return sum;
  }

  /// The lesser of two amounts of one currency.
  static LumeMoney min(LumeMoney a, LumeMoney b) => a.compareTo(b) <= 0 ? a : b;

  /// Whole and fraction as a machine decimal at the currency's exponent,
  /// `.` separated, no grouping: `34000.00`, `5000`, `-1.250`.
  String toDecimalString() {
    final int e = currency.exponent;
    final String sign = minor < 0 ? '-' : '';
    final int abs = minor.abs();
    if (e == 0) return '$sign$abs';
    final int scale = currency.scale;
    final String fraction = (abs % scale).toString().padLeft(e, '0');
    return '$sign${abs ~/ scale}.$fraction';
  }

  /// Whether every digit after the decimal point is zero, so a compact
  /// display may leave them out without rounding.
  bool get isWhole => minor % currency.scale == 0;

  void _same(LumeMoney other) {
    if (other.currency != currency) {
      throw LumeMoneyException(
        LumeMoneyFailure.currencyMismatch,
        currency: currency,
        other: other.currency,
      );
    }
  }

  static void _bound(int minor, LumeCurrency currency) {
    if (minor > maxSumMinor || minor < -maxSumMinor) {
      throw LumeMoneyException(
        LumeMoneyFailure.overflow,
        currency: currency,
        limit: maxSumMinor,
      );
    }
  }

  /// Orders amounts of one currency; a mismatch is a typed failure, never an
  /// order invented between currencies.
  @override
  int compareTo(LumeMoney other) {
    _same(other);
    return minor.compareTo(other.minor);
  }

  @override
  bool operator ==(Object other) =>
      other is LumeMoney && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() => '${toDecimalString()} ${currency.code}';
}

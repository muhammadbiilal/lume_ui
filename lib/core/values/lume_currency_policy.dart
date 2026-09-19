/// Whether a currency may be used for an amount — the one rule every money
/// tool asks, rather than each deciding for itself.
///
/// A withdrawn currency (ISO 4217 no longer lists it: the lev after
/// Bulgaria adopted the euro) is never offered for something new. It stays
/// usable only for what services an obligation **already** kept in it: a
/// repayment of a lev loan, a correction to a lev entry. Nothing converts
/// it, and no rate is applied, fixed or otherwise.
///
/// The policy does not know what a tool's obligations are. The tool says
/// which currencies the records an operation touches are kept in, and the
/// policy answers.
library;

import 'lume_currency.dart';

/// How a currency stands for one operation.
enum LumeCurrencyAvailability {
  /// ISO lists it: usable for anything.
  current,

  /// Withdrawn, and usable here only because the operation services a
  /// record already kept in it.
  historicalForExistingRecord,

  /// Withdrawn, and nothing this operation touches is kept in it.
  unsupported;

  bool get usable => this != unsupported;
}

abstract final class LumeCurrencyPolicy {
  /// How [currency] stands for an operation that services existing records
  /// kept in [existing] — none, for a new and unrelated obligation.
  static LumeCurrencyAvailability of(
    LumeCurrency currency, {
    Iterable<LumeCurrency> existing = const <LumeCurrency>[],
  }) {
    if (currency.active) return LumeCurrencyAvailability.current;
    return existing.contains(currency)
        ? LumeCurrencyAvailability.historicalForExistingRecord
        : LumeCurrencyAvailability.unsupported;
  }

  /// The withdrawn currencies among [existing], by code — what a picker may
  /// offer beside the current ones for this operation, and nothing more.
  static List<LumeCurrency> historical(Iterable<LumeCurrency> existing) =>
      <LumeCurrency>{
        for (final LumeCurrency c in existing)
          if (!c.active) c,
      }.toList()..sort();
}

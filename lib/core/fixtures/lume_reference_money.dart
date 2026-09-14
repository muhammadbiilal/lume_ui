/// Amounts authored in dollars, as the reference shows them — `locale.js`
/// `money()` and `tidy()`.
///
/// The reference writes many fixture amounts in US dollars and converts them
/// at its own rate table for the reader's currency, then tidies the result so
/// a Karachi ledger reads in round rupees rather than in a conversion's
/// decimals. Both steps are ported here once, so every dollar-authored tool
/// arrives at the same figure the reference draws.
library;

import 'lume_reference_rates.dart';

/// `tidy(v)` — thousands above 100,000, hundreds above 10,000, tens above
/// 1,000, whole units above 100, halves above 10, tenths below.
double lumeTidy(double v) {
  // `Math.round` rounds a half up; for these non-negative amounts that is
  // what `round()` does too.
  if (v >= 100000) return (v / 1000).round() * 1000.0;
  if (v >= 10000) return (v / 100).round() * 100.0;
  if (v >= 1000) return (v / 10).round() * 10.0;
  if (v >= 100) return v.roundToDouble();
  if (v >= 10) return (v * 2).round() / 2;
  return (v * 10).round() / 10;
}

/// `money(usd)`'s value before it is formatted: the dollars at the reference's
/// rate for [currency], tidied.
double lumeFromUsd(double usd, String currency) =>
    lumeTidy(usd * lumeRatePerUsd(currency));

/// Currency converter — `tools/everyday/currency.tool.js` over `context.js`
/// `currencyBoard()`.
///
/// The reference keeps one `from` and one `to` (the reader's own currency and,
/// on first open, the dollar or the euro), an amount, and a short board of
/// majors converted from `from`: `(L.RATES[to] || 1) / (L.RATES[from] || 1)` —
/// a direct ratio of two per-dollar rates from [lumeRatePerUsd], which is the
/// same arithmetic as routing the amount through a dollar leg, done in one
/// division rather than two. The board is eight fixed codes
/// (`USD, EUR, GBP, SAR, AED, PKR, INR, TRY`), minus whichever of them is the
/// current `from`, with the reference's own fixed day-changes and a seeded
/// sparkline per row ([lumeWalk]); the 30-day chart is the same generator over
/// the active pair's rate.
///
/// **Dropped, not ported: `cv.recent`.** The reference's "Recent" section is
/// two literals — `100 FROM → TO` and `1,000 FROM → TO` — captioned as
/// conversions the reader made, computed fresh on every read and never
/// actually recorded from anything the reader did. `converter.tool.js`'s own
/// "Recent" is the identical pattern and was already dropped rather than kept
/// as a plausible-looking history nobody lived (`ROLLOUT_WAVE_4.md` §2/§7);
/// the same correction applies here for the same reason and is not repeated.
///
/// **Dayroz obligation:** every rate here is fixture data from
/// [kReferenceRatesPerUsd]. A real integration needs a licensed, timestamped
/// FX feed with its delay stated — the catalogue's freshness is `delayed`.
library;

import 'package:flutter/foundation.dart';

import '../../../core/fixtures/lume_reference_rates.dart';
import '../../../core/fixtures/lume_reference_walk.dart';

/// One row of the "Popular" board: a major currency priced from `from`.
@immutable
class LumeCurrencyPair {
  const LumeCurrencyPair({
    required this.code,
    required this.flag,
    required this.rate,
    required this.pct,
  });

  final String code;

  /// `code.slice(0, 2)` — the reference's own board tile, not a currency
  /// symbol (contrast the metals board's `$`, `€`, `£`, which is a different
  /// reference function; see `goldrates_fixtures.dart`).
  final String flag;

  /// Units of [code] per one unit of the board's `from` currency.
  final double rate;

  /// The reference's own fixed day-change for this row's position in the
  /// (already-filtered) board — fixture data, like [rate].
  final double pct;

  /// `D.walk(p.code.charCodeAt(0) * 7, 16, p.rate, 0.006)`.
  List<double> get spark => lumeWalk(code.codeUnitAt(0) * 7, 16, rate, 0.006);
}

/// `currencyBoard()`, typed: a converting pair plus the board around it.
@immutable
class LumeCurrencyBoard {
  const LumeCurrencyBoard._({
    required this.from,
    required this.to,
    required this.rate,
    required this.popular,
  });

  /// The eight codes the reference's board draws from, in its own order.
  static const List<String> majors = <String>[
    'USD',
    'EUR',
    'GBP',
    'SAR',
    'AED',
    'PKR',
    'INR',
    'TRY',
  ];

  /// `[0.18, -0.24, 0.06, 0, 0.42, -0.11]` — the reference's own fixed
  /// changes, indexed by a row's position in the board once `from` is
  /// removed from [majors].
  static const List<double> changes = <double>[0.18, -0.24, 0.06, 0, 0.42, -0.11];

  /// `home === 'USD' ? 'EUR' : 'USD'` — the `to` the board opens on when the
  /// reader has never chosen one.
  static String defaultTo(String home) => home == 'USD' ? 'EUR' : 'USD';

  /// Every currency [lumeRatePerUsd] prices, for a picker that offers exactly
  /// what the shared rate table covers — nothing hardcoded smaller, nothing
  /// invented larger.
  static List<String> get allCodes =>
      kReferenceRatesPerUsd.keys.toList()..sort();

  factory LumeCurrencyBoard.forPair(String from, String to) {
    final double rate = lumeRatePerUsd(to) / lumeRatePerUsd(from);
    final List<String> shown = <String>[
      for (final String code in majors)
        if (code != from) code,
    ].take(changes.length).toList();
    return LumeCurrencyBoard._(
      from: from,
      to: to,
      rate: rate,
      popular: <LumeCurrencyPair>[
        for (int i = 0; i < shown.length; i++)
          LumeCurrencyPair(
            code: shown[i],
            flag: shown[i].substring(0, 2),
            rate: lumeRatePerUsd(shown[i]) / lumeRatePerUsd(from),
            pct: i < changes.length ? changes[i] : 0,
          ),
      ],
    );
  }

  final String from;
  final String to;

  /// Units of [to] per one unit of [from].
  final double rate;

  final List<LumeCurrencyPair> popular;

  /// `D.walk(4242, 30, cv.rate, 0.006)`.
  List<double> get history => lumeWalk(4242, 30, rate, 0.006);

  /// The amount converted at [rate], or `null` when [amount] is not a real
  /// quantity — nothing is computed from a guess. Zero converts to zero;
  /// a negative amount, like GoldRates' `worth()` on a negative weight, is
  /// refused rather than shown as a (meaningless) negative conversion.
  static double? convert(double rate, String amount) {
    final double? n = double.tryParse(amount.trim().replaceAll(',', '.'));
    if (n == null || n < 0 || !n.isFinite) return null;
    return n * rate;
  }
}

/// Gold, silver and the major currencies — `context.js` `metals()`, typed.
///
/// The reference authors its figures in dollars and converts them at its own
/// rate table ([lumeRatePerUsd]): gold at 88 dollars a gram, silver at 1.05, a
/// tola of 11.664 grams, an ounce fixed at 2,740 dollars. The currencies are
/// the dollar, euro, pound, riyal and dirham, less the reader's own, each
/// bought at 0.996 of its selling rate, with the change the reference gives
/// its place in that list. The sparklines and the 30-day chart are the
/// reference's seeded walks ([lumeWalk]).
///
/// **Dayroz obligation:** every figure here is fixture data. Rates need a
/// licensed, timestamped source with its delay stated (the catalogue's
/// freshness is `delayed`), and a gold price the reader's own market quotes.
library;

import 'package:flutter/foundation.dart';

import '../../../core/fixtures/lume_reference_rates.dart';
import '../../../core/fixtures/lume_reference_walk.dart';

@immutable
class LumeFxPair {
  const LumeFxPair({
    required this.code,
    required this.flag,
    required this.buy,
    required this.sell,
    required this.pct,
  });

  final String code;

  /// `flag` — the currency's sign, drawn in the row's tile.
  final String flag;
  final double buy;
  final double sell;
  final double pct;

  /// `D.walk(Math.round(p.sell * 10), 18, p.sell, 0.008)`.
  List<double> get spark =>
      lumeWalk((sell * 10 + 0.5).floor(), 18, sell, 0.008);
}

@immutable
class LumeMetals {
  const LumeMetals._({
    required this.currency,
    required this.goldPerGram,
    required this.silverPerGram,
    required this.pairs,
  });

  factory LumeMetals.forCurrency(String currency) {
    final double rate = lumeRatePerUsd(currency);
    const List<(String, String)> majors = <(String, String)>[
      ('USD', r'$'),
      ('EUR', '€'),
      ('GBP', '£'),
      ('SAR', '﷼'),
      ('AED', 'د.إ'),
    ];
    const List<double> changes = <double>[0.24, -0.12, 0.31, 0, -0.08];
    final List<(String, String)> shown = <(String, String)>[
      for (final (String, String) m in majors)
        if (m.$1 != currency) m,
    ];
    return LumeMetals._(
      currency: currency,
      goldPerGram: 88 * rate,
      silverPerGram: 1.05 * rate,
      pairs: <LumeFxPair>[
        for (int i = 0; i < shown.length; i++)
          () {
            final double sell =
                rate / (shown[i].$1 == 'USD' ? 1 : lumeRatePerUsd(shown[i].$1));
            return LumeFxPair(
              code: shown[i].$1,
              flag: shown[i].$2,
              buy: sell * 0.996,
              sell: sell,
              pct: i < changes.length ? changes[i] : 0,
            );
          }(),
      ],
    );
  }

  final String currency;
  final double goldPerGram;
  final double silverPerGram;
  final List<LumeFxPair> pairs;

  static const double gramsPerTola = 11.664;

  /// `perOunce: 2740` — in dollars, whatever the reader's currency.
  static const double goldPerOunceUsd = 2740;

  static const double goldPct = 0.42;
  static const double silverPct = -0.18;

  /// `gold22 = gold24 × 0.916`.
  static const double purity22 = 0.916;

  double get goldPerTola => goldPerGram * gramsPerTola;
  double get silverPerTola => silverPerGram * gramsPerTola;

  /// `chg: perTola × 0.004`.
  double get goldChange => goldPerTola * 0.004;

  /// `D.walk(9001, 30, g.gold.perTola, 0.01)`.
  List<double> get history => lumeWalk(9001, 30, goldPerTola, 0.01);
}

/// Typed shapes for the world board — `tool-data.js` `GLOBAL_INDICES`,
/// `CRYPTO` and `ETFS`, each with the sparkline `context.js` draws for it
/// (`seriesFor()` for a coin or a fund, the inline `D.walk(...)` the `world`
/// section in `markets.tool.js` draws for an index).
///
/// **Dayroz obligation:** every figure carried by an instance of either class
/// below is fixture data, frozen at the moment the reference was captured. A
/// production board needs a licensed, timestamped market-data feed for each
/// of these named instruments — this file states that once here rather than
/// once per number, exactly as `goldrates_fixtures.dart` does for its rates.
library;

import 'package:flutter/foundation.dart';

import '../../../core/fixtures/lume_reference_walk.dart';

/// One of the six national benchmarks `tool-data.js` `GLOBAL_INDICES` leads
/// the world board with — quoted in index points, not a currency.
@immutable
class LumeWorldIndex {
  const LumeWorldIndex({
    required this.index,
    required this.symbol,
    required this.name,
    required this.country,
    required this.value,
    required this.change,
    required this.percent,
  });

  /// This index's position in `GLOBAL_INDICES` — folded into its sparkline
  /// seed below, exactly as the reference folds `i` into `ix.value + i`.
  final int index;

  final String symbol;
  final String name;

  /// `ix.full` — the country the index represents. A literal, proper-noun
  /// string, kept in English as the reference authors it: not looked up
  /// against the country table `LumeToolScreen.countryName` reads, the same
  /// way `LumeExchange.name` is a proper noun and not translated.
  final String country;

  final double value;
  final double change;
  final double percent;

  bool get isUp => percent >= 0;

  /// `D.walk(ix.value + i, 20, ix.value, 0.005)`.
  ///
  /// KNOWN_DIFFERENCE: the reference hands its own `seedRand` a float
  /// (`ix.value + i`), which JavaScript's `%` accepts unchanged; [lumeWalk]'s
  /// [LumeSeedRand] is Park–Miller over integers, so the seed is rounded here
  /// exactly as the FX sparkline in `goldrates_fixtures.dart` already rounds
  /// `p.sell * 10` before handing it to the same generator.
  List<double> get sparkline =>
      lumeWalk((value + index + 0.5).floor(), 20, value, 0.005);
}

/// One coin or fund — `CRYPTO` and `ETFS`, which the reference shapes and
/// draws identically (`assetRow` in `markets.tool.js`): a ticker, a name, a
/// price in dollars, its move, and a volume and a market cap the reference
/// already formats to a magnitude (`'38.1B'`) rather than a number to
/// compute from.
@immutable
class LumeQuotedAsset {
  const LumeQuotedAsset({
    required this.symbol,
    required this.name,
    required this.logo,
    required this.price,
    required this.change,
    required this.percent,
    required this.volume,
    required this.cap,
  });

  final String symbol;
  final String name;

  /// `x.logo` — a currency glyph (`'₿'`) or a short mark (`'VO'`), already
  /// the reference's own; nothing here invents one.
  final String logo;

  final double price;
  final double change;
  final double percent;

  /// Already-formatted magnitudes, exactly as `CRYPTO`/`ETFS` carry them.
  final String volume;
  final String cap;

  bool get isUp => percent >= 0;

  /// `c.seriesFor(a, '1D').slice(0, 20)`: `D.walk(seed, 44, price, 0.004)`,
  /// kept to its first 20 points, where `seed` is `Math.round(price * 1000)`
  /// plus `'1D'.charCodeAt(0) * 31 + '1D'.length * 7` (`49 * 31 + 2 * 7 =
  /// 1533`) and `0.004` is `seriesFor`'s non-FX base volatility at the `1D`
  /// range's own multiplier of `1`.
  List<double> get sparkline =>
      lumeWalk((price * 1000 + 0.5).floor() + 1533, 44, price, 0.004)
          .take(20)
          .toList(growable: false);
}

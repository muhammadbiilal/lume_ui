/// The world board's named instruments — `tool-data.js` `GLOBAL_INDICES`,
/// `CRYPTO` and `ETFS`, ported unchanged.
///
/// Kept as the reference has it: six national benchmarks, four coins, three
/// funds, each a frozen quote from the moment the fixture was authored — no
/// ticker added, none dropped, no figure recomputed.
///
/// **Dayroz obligation:** every figure below is fixture data. A production
/// board needs a licensed, timestamped market-data feed for each of these —
/// see `markets_model.dart` for the fuller statement of that obligation.
library;

import '../domain/markets_model.dart';

abstract final class LumeMarkets {
  /// `GLOBAL_INDICES` — the world board's six benchmarks, in the reference's
  /// own order (each one's position feeds its own sparkline seed, so the
  /// order is part of the data, not incidental).
  static const List<LumeWorldIndex> worldIndices = <LumeWorldIndex>[
    LumeWorldIndex(
      index: 0,
      symbol: 'SPX',
      name: 'S&P 500',
      country: 'United States',
      value: 5812.44,
      change: 24.18,
      percent: 0.42,
    ),
    LumeWorldIndex(
      index: 1,
      symbol: 'UKX',
      name: 'FTSE 100',
      country: 'United Kingdom',
      value: 8288.60,
      change: 31.44,
      percent: 0.38,
    ),
    LumeWorldIndex(
      index: 2,
      symbol: 'N225',
      name: 'Nikkei 225',
      country: 'Japan',
      value: 38722.10,
      change: -142.80,
      percent: -0.37,
    ),
    LumeWorldIndex(
      index: 3,
      symbol: 'DAX',
      name: 'DAX',
      country: 'Germany',
      value: 19188.44,
      change: 88.10,
      percent: 0.46,
    ),
    LumeWorldIndex(
      index: 4,
      symbol: 'HSI',
      name: 'Hang Seng',
      country: 'Hong Kong',
      value: 20144.80,
      change: 210.40,
      percent: 1.06,
    ),
    LumeWorldIndex(
      index: 5,
      symbol: 'TASI',
      name: 'TASI',
      country: 'Saudi Arabia',
      value: 11844.20,
      change: 62.10,
      percent: 0.53,
    ),
  ];

  /// `CRYPTO`, quoted in dollars whatever the reader's own currency — the
  /// reference never converts a coin's price, the same way gold's per-ounce
  /// figure in `goldrates_fixtures.dart` stays in dollars.
  static const List<LumeQuotedAsset> crypto = <LumeQuotedAsset>[
    LumeQuotedAsset(
      symbol: 'BTC',
      name: 'Bitcoin',
      logo: '₿',
      price: 96420.00,
      change: 1840.00,
      percent: 1.95,
      volume: '38.1B',
      cap: '1.90T',
    ),
    LumeQuotedAsset(
      symbol: 'ETH',
      name: 'Ethereum',
      logo: 'Ξ',
      price: 3388.40,
      change: -42.10,
      percent: -1.23,
      volume: '18.4B',
      cap: '408B',
    ),
    LumeQuotedAsset(
      symbol: 'SOL',
      name: 'Solana',
      logo: 'S',
      price: 214.66,
      change: 8.42,
      percent: 4.08,
      volume: '4.2B',
      cap: '101B',
    ),
    LumeQuotedAsset(
      symbol: 'XRP',
      name: 'XRP',
      logo: 'X',
      price: 2.31,
      change: 0.11,
      percent: 5.00,
      volume: '6.8B',
      cap: '132B',
    ),
  ];

  /// `ETFS`, also quoted in dollars — every one of them trades on a US
  /// exchange in the reference.
  static const List<LumeQuotedAsset> etfs = <LumeQuotedAsset>[
    LumeQuotedAsset(
      symbol: 'VOO',
      name: 'Vanguard S&P 500 ETF',
      logo: 'VO',
      price: 534.20,
      change: 2.18,
      percent: 0.41,
      volume: '4.1M',
      cap: '520B',
    ),
    LumeQuotedAsset(
      symbol: 'QQQ',
      name: 'Invesco QQQ Trust',
      logo: 'QQ',
      price: 498.66,
      change: 3.44,
      percent: 0.69,
      volume: '28.4M',
      cap: '298B',
    ),
    LumeQuotedAsset(
      symbol: 'GLD',
      name: 'SPDR Gold Shares',
      logo: 'GL',
      price: 244.10,
      change: 1.02,
      percent: 0.42,
      volume: '6.2M',
      cap: '73B',
    ),
  ];

  /// `exchange: 'NYSE Arca'` — `assetsFor('etfs')` in `context.js`. A literal
  /// proper noun in the reference, never run through `t()`; kept literal
  /// here for the same reason `LumeExchange.name` is never translated.
  static const String etfVenue = 'NYSE Arca';
}

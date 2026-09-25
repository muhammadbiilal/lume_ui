/// Fuel prices, per market — `tool-data.js` `FUEL` / `FUEL_FALLBACK` /
/// `fuelFor(code)`.
///
/// `fuelFor` keys a small table of regulator-published notifications by ISO
/// country code and falls back to a neutral global entry for everywhere
/// else — Pakistan, Great Britain, the United States, the UAE, Saudi Arabia
/// and India each get their own grades, codes and current/previous prices;
/// every other country gets [LumeFuel.fallback] "so the tool is never blank"
/// (the reference's own comment on `FUEL_FALLBACK`). This is the global
/// mechanism §35 of the brief asks for — one lookup, extended per market,
/// never a country check scattered through a screen.
///
/// **Dayroz obligation.** Every figure here is fixture data, frozen at the
/// reference's own numbers. A real integration needs each market's actual
/// regulator or retail feed — OGRA's own notification service for Pakistan,
/// the UK's weekly road fuel survey, EIA's state averages for the US, the
/// UAE Ministry of Energy's monthly bulletin, Saudi Aramco's own tariff,
/// India's OMCs — each timestamped and licensed; nothing here is fetched.
/// `LumeToolScreen` draws that disclosure from capability metadata alone
/// (`fuel` carries no entry in [LumeDataCapability]'s durable/computed/
/// input-only/reader-record lists, so a shipping build still reads "Sample
/// data" over these figures).
///
/// **Real names as flavor text, not as a promise.** `source`s such as "OGRA
/// notification", "Ministry of Energy" and "Aramco tariff" are the
/// reference's own literal English strings — never run through translation,
/// the same choice already made for [LumeFuelSource.proper]'s sibling
/// `fuelSourceOgra` ("a proper noun, transliterated rather than
/// translated"). They are cited for authenticity; they name no live feed.
library;

import 'package:flutter/foundation.dart';

/// One grade's translation key. Shared across markets where the reference
/// shares it — Pakistan's and India's `petrol` are the same key with
/// different local codes and prices next to it.
enum LumeFuelGrade {
  petrol,
  hiOctane,
  diesel,
  lightDiesel,
  unleaded,
  superUnleaded,
  regular,
  midgrade,
  premium,
  special95,
  super98,
  ePlus91,
  petrol91,
  petrol95,
  cng,
}

/// The unit a market's pump actually prices in.
enum LumeFuelUnit { litre, gallon }

/// Where a market's own [LumeFuelMarket.source] line comes from.
enum LumeFuelSource {
  /// The reference's own literal, untranslated institution name —
  /// [LumeFuelMarket.properSource].
  proper,

  /// `fuel.src.retail` — a translated generic label.
  retail,

  /// `fuel.src.state`.
  state,

  /// `fuel.src.omc`.
  omc,

  /// `fuel.src.regional` — the fallback's own.
  regional,
}

/// How a market's effective-date line reads.
enum LumeFuelEffective {
  /// A literal date, [LumeFuelMarket.fixedEffective] — frozen, as the
  /// reference's own is.
  fixed,

  /// `common.today`.
  today,

  /// `common.thisWeek` — the fallback's own.
  thisWeek,
}

/// One grade's current and previous price, and the technical code the pump
/// itself prints (`RON 92`, `E10`, `87`) — a literal, never translated,
/// exactly as the reference's own `code` field is.
@immutable
class LumeFuelItem {
  const LumeFuelItem({
    required this.grade,
    required this.code,
    required this.price,
    required this.previous,
  });

  final LumeFuelGrade grade;
  final String code;
  final double price;
  final double previous;

  /// `i.v - i.prev`.
  double get change => price - previous;
}

/// One market's whole notification: what it prices in, every grade it
/// lists, and the source/effective-date flavor text the reference gives it
/// (or the generic, translated stand-in a market without one gets).
@immutable
class LumeFuelMarket {
  const LumeFuelMarket({
    required this.currency,
    required this.unit,
    required this.items,
    required this.sourceKind,
    this.properSource,
    required this.effectiveKind,
    this.fixedEffective,
  }) : assert(
         sourceKind != LumeFuelSource.proper || properSource != null,
         'a proper source needs its literal text',
       ),
       assert(
         effectiveKind != LumeFuelEffective.fixed || fixedEffective != null,
         'a fixed effective date needs its literal text',
       );

  /// ISO 4217 — the currency this market's own prices are quoted in. Never
  /// converted: a fuel notification is a local, regulator-published figure,
  /// not a rate table like [LumeMetals]'s.
  final String currency;
  final LumeFuelUnit unit;

  /// In the reference's own order — the first is the grade the summary
  /// leads with.
  final List<LumeFuelItem> items;

  final LumeFuelSource sourceKind;

  /// Set only when [sourceKind] is [LumeFuelSource.proper].
  final String? properSource;

  final LumeFuelEffective effectiveKind;

  /// Set only when [effectiveKind] is [LumeFuelEffective.fixed].
  final String? fixedEffective;

  /// `f.items[0]` — the grade the summary card and the trend chart lead
  /// with.
  LumeFuelItem get main => items.first;
}

/// `fuelFor(code)`, typed. One market per supported country, plus the
/// global fallback every other country reads.
abstract final class LumeFuel {
  static const LumeFuelMarket pakistan = LumeFuelMarket(
    currency: 'PKR',
    unit: LumeFuelUnit.litre,
    sourceKind: LumeFuelSource.proper,
    properSource: 'OGRA notification',
    effectiveKind: LumeFuelEffective.fixed,
    fixedEffective: '1 September',
    items: <LumeFuelItem>[
      LumeFuelItem(
        grade: LumeFuelGrade.petrol,
        code: 'RON 92',
        price: 264.61,
        previous: 262.47,
      ),
      LumeFuelItem(
        grade: LumeFuelGrade.hiOctane,
        code: 'RON 97',
        price: 284.90,
        previous: 283.10,
      ),
      LumeFuelItem(
        grade: LumeFuelGrade.diesel,
        code: 'HSD',
        price: 272.98,
        previous: 273.63,
      ),
      LumeFuelItem(
        grade: LumeFuelGrade.lightDiesel,
        code: 'LDO',
        price: 160.45,
        previous: 160.45,
      ),
    ],
  );

  static const LumeFuelMarket unitedKingdom = LumeFuelMarket(
    currency: 'GBP',
    unit: LumeFuelUnit.litre,
    sourceKind: LumeFuelSource.retail,
    effectiveKind: LumeFuelEffective.today,
    items: <LumeFuelItem>[
      LumeFuelItem(
        grade: LumeFuelGrade.unleaded,
        code: 'E10',
        price: 1.34,
        previous: 1.36,
      ),
      LumeFuelItem(
        grade: LumeFuelGrade.superUnleaded,
        code: 'E5',
        price: 1.46,
        previous: 1.47,
      ),
      LumeFuelItem(
        grade: LumeFuelGrade.diesel,
        code: 'B7',
        price: 1.41,
        previous: 1.42,
      ),
    ],
  );

  static const LumeFuelMarket unitedStates = LumeFuelMarket(
    currency: 'USD',
    unit: LumeFuelUnit.gallon,
    sourceKind: LumeFuelSource.state,
    effectiveKind: LumeFuelEffective.today,
    items: <LumeFuelItem>[
      LumeFuelItem(
        grade: LumeFuelGrade.regular,
        code: '87',
        price: 3.12,
        previous: 3.18,
      ),
      LumeFuelItem(
        grade: LumeFuelGrade.midgrade,
        code: '89',
        price: 3.58,
        previous: 3.62,
      ),
      LumeFuelItem(
        grade: LumeFuelGrade.premium,
        code: '93',
        price: 3.98,
        previous: 4.01,
      ),
      LumeFuelItem(
        grade: LumeFuelGrade.diesel,
        code: 'ULSD',
        price: 3.66,
        previous: 3.71,
      ),
    ],
  );

  static const LumeFuelMarket uae = LumeFuelMarket(
    currency: 'AED',
    unit: LumeFuelUnit.litre,
    sourceKind: LumeFuelSource.proper,
    properSource: 'Ministry of Energy',
    effectiveKind: LumeFuelEffective.fixed,
    fixedEffective: '1 September',
    items: <LumeFuelItem>[
      LumeFuelItem(
        grade: LumeFuelGrade.special95,
        code: '95',
        price: 2.61,
        previous: 2.70,
      ),
      LumeFuelItem(
        grade: LumeFuelGrade.super98,
        code: '98',
        price: 2.72,
        previous: 2.81,
      ),
      LumeFuelItem(
        grade: LumeFuelGrade.ePlus91,
        code: '91',
        price: 2.53,
        previous: 2.62,
      ),
      LumeFuelItem(
        grade: LumeFuelGrade.diesel,
        code: 'Diesel',
        price: 2.66,
        previous: 2.74,
      ),
    ],
  );

  static const LumeFuelMarket saudiArabia = LumeFuelMarket(
    currency: 'SAR',
    unit: LumeFuelUnit.litre,
    sourceKind: LumeFuelSource.proper,
    properSource: 'Aramco tariff',
    effectiveKind: LumeFuelEffective.fixed,
    fixedEffective: '11 September',
    items: <LumeFuelItem>[
      LumeFuelItem(
        grade: LumeFuelGrade.petrol91,
        code: '91',
        price: 2.18,
        previous: 2.18,
      ),
      LumeFuelItem(
        grade: LumeFuelGrade.petrol95,
        code: '95',
        price: 2.33,
        previous: 2.33,
      ),
      LumeFuelItem(
        grade: LumeFuelGrade.diesel,
        code: 'Diesel',
        price: 1.15,
        previous: 1.15,
      ),
    ],
  );

  static const LumeFuelMarket india = LumeFuelMarket(
    currency: 'INR',
    unit: LumeFuelUnit.litre,
    sourceKind: LumeFuelSource.omc,
    effectiveKind: LumeFuelEffective.today,
    items: <LumeFuelItem>[
      LumeFuelItem(
        grade: LumeFuelGrade.petrol,
        code: 'MS',
        price: 94.72,
        previous: 94.77,
      ),
      LumeFuelItem(
        grade: LumeFuelGrade.diesel,
        code: 'HSD',
        price: 87.62,
        previous: 87.67,
      ),
      LumeFuelItem(
        grade: LumeFuelGrade.cng,
        code: 'CNG',
        price: 76.59,
        previous: 76.59,
      ),
    ],
  );

  /// `FUEL_FALLBACK` — "a neutral global fallback so the tool is never
  /// blank" (§92 of the reference). Every country outside the six named
  /// markets reads this, which is the point: Fuel Prices is a global
  /// feature with deep Pakistani localization, not a Pakistan-only screen
  /// with a token international mode (§35 of the brief).
  static const LumeFuelMarket fallback = LumeFuelMarket(
    currency: 'USD',
    unit: LumeFuelUnit.litre,
    sourceKind: LumeFuelSource.regional,
    effectiveKind: LumeFuelEffective.thisWeek,
    items: <LumeFuelItem>[
      LumeFuelItem(
        grade: LumeFuelGrade.petrol,
        code: 'Unleaded',
        price: 1.28,
        previous: 1.30,
      ),
      LumeFuelItem(
        grade: LumeFuelGrade.diesel,
        code: 'Diesel',
        price: 1.34,
        previous: 1.35,
      ),
    ],
  );

  static const Map<String, LumeFuelMarket> _byCountry = <String, LumeFuelMarket>{
    'PK': pakistan,
    'GB': unitedKingdom,
    'US': unitedStates,
    'AE': uae,
    'SA': saudiArabia,
    'IN': india,
  };

  /// `fuelFor(code)` — [country]'s own market, or [fallback].
  static LumeFuelMarket forCountry(String country) =>
      _byCountry[country] ?? fallback;
}

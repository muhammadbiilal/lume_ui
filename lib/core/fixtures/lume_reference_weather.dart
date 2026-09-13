/// The reference's weather, ported rather than transcribed.
///
/// Home's live row and forecasts, Explore's card and the notification feed's
/// forecast all read weather, and until now each carried its own table — with
/// invented days for most markets and a silent default for every other one.
/// This is the one source, and it is the reference's own code:
///
/// * `WEATHER_BY_COUNTRY` (`assets/js/data/catalogue.js`) — twenty markets,
///   each a temperature, a feels-like, a condition phrase, rain, wind and an
///   icon;
/// * `WEATHER_BY_ZONE` — seven climates keyed by an IANA zone's first
///   segment, which `weatherFor(country, tz)` falls back to;
/// * `daily(base, seed)` (`assets/js/data/tool-data.js`) — the five-day
///   forecast, generated from the base temperature by a Park–Miller generator
///   seeded with the country code's first character times seventeen.
///
/// Every value it returns was checked against those functions run in Node
/// (`docs/conversion_archive/WEATHER_SOURCE_MAP.md`). **Nothing here is
/// weather.** Every figure is fixture-only; Dayroz's weather adapter replaces
/// the whole file.
///
/// What it will not do is make a market's weather up. A country outside the
/// twenty with no zone to derive a climate from is [LumeWeatherProvenance]
/// `unavailable` — `null` — and the surfaces draw nothing for it rather than
/// Pakistan's sky or Germany's.
library;

import 'package:flutter/foundation.dart';

import '../icons/lume_icons.dart';

/// Where a market's weather comes from.
enum LumeWeatherProvenance {
  /// Written down in `WEATHER_BY_COUNTRY`.
  reference,

  /// Derived by the reference's own rule — here, a zone's climate from
  /// `WEATHER_BY_ZONE` and the generated forecast over it.
  derived,

  /// Not defined by the reference at all.
  unavailable,
}

/// One generated day — `daily()`'s `{ hi, lo, rain, icon, desc }`.
@immutable
class LumeReferenceDay {
  const LumeReferenceDay({
    required this.highC,
    required this.lowC,
    required this.rainPercent,
    required this.conditionKey,
    required this.icon,
  });

  final int highC;
  final int lowC;
  final int rainPercent;

  /// `mostlyClear` or `cloudBuilding` — the only two the generator writes.
  final String conditionKey;
  final String icon;

  @override
  bool operator ==(Object other) =>
      other is LumeReferenceDay &&
      other.highC == highC &&
      other.lowC == lowC &&
      other.rainPercent == rainPercent &&
      other.conditionKey == conditionKey &&
      other.icon == icon;

  @override
  int get hashCode => Object.hash(highC, lowC, rainPercent, conditionKey, icon);
}

/// A market's climate, as the reference answers for it.
@immutable
class LumeReferenceClimate {
  const LumeReferenceClimate({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.conditionKey,
    required this.shortConditionKey,
    required this.rainPercent,
    required this.windKph,
    required this.icon,
    required this.days,
    required this.provenance,
  });

  final int temperatureC;
  final int feelsLikeC;

  /// The whole phrase — "Hazy sun · humid" — which Explore's card shows.
  final String conditionKey;

  /// `desc.split(' · ')[0]` — "Hazy sun" — which Home's live row shows.
  final String shortConditionKey;

  final int rainPercent;
  final int windKph;
  final String icon;

  /// `daily()`'s five, today first.
  final List<LumeReferenceDay> days;

  LumeReferenceDay get today => days[0];
  LumeReferenceDay get tomorrow => days[1];

  final LumeWeatherProvenance provenance;
}

typedef _Row = ({
  int temp,
  int feels,
  String condition,
  String short,
  int rain,
  int wind,
  String icon,
});

/// `WEATHER_BY_COUNTRY`, in the reference's order.
const Map<String, _Row> _byCountry = <String, _Row>{
  'PK': (
    temp: 34,
    feels: 38,
    condition: 'hazySunHumid',
    short: 'hazySun',
    rain: 8,
    wind: 14,
    icon: LumeIcons.sun,
  ),
  'IN': (
    temp: 33,
    feels: 37,
    condition: 'humidLightHaze',
    short: 'humid',
    rain: 25,
    wind: 12,
    icon: LumeIcons.sun,
  ),
  'GB': (
    temp: 21,
    feels: 19,
    condition: 'mostlyClear',
    short: 'mostlyClear',
    rain: 12,
    wind: 8,
    icon: LumeIcons.cloudSun,
  ),
  'US': (
    temp: 24,
    feels: 24,
    condition: 'lightCloud',
    short: 'lightCloud',
    rain: 20,
    wind: 10,
    icon: LumeIcons.cloudSun,
  ),
  'CA': (
    temp: 17,
    feels: 15,
    condition: 'cloudy',
    short: 'cloudy',
    rain: 35,
    wind: 13,
    icon: LumeIcons.cloudSun,
  ),
  'AE': (
    temp: 39,
    feels: 44,
    condition: 'clearVeryWarm',
    short: 'clear',
    rain: 0,
    wind: 11,
    icon: LumeIcons.sun,
  ),
  'SA': (
    temp: 40,
    feels: 42,
    condition: 'clear',
    short: 'clear',
    rain: 0,
    wind: 9,
    icon: LumeIcons.sun,
  ),
  'AU': (
    temp: 26,
    feels: 26,
    condition: 'brightAndBreezy',
    short: 'brightAndBreezy',
    rain: 10,
    wind: 18,
    icon: LumeIcons.sun,
  ),
  'DE': (
    temp: 18,
    feels: 17,
    condition: 'overcast',
    short: 'overcast',
    rain: 40,
    wind: 11,
    icon: LumeIcons.cloudSun,
  ),
  'FR': (
    temp: 21,
    feels: 20,
    condition: 'sunnySpells',
    short: 'sunnySpells',
    rain: 15,
    wind: 9,
    icon: LumeIcons.cloudSun,
  ),
  'TR': (
    temp: 27,
    feels: 27,
    condition: 'clear',
    short: 'clear',
    rain: 5,
    wind: 12,
    icon: LumeIcons.sun,
  ),
  'ID': (
    temp: 31,
    feels: 35,
    condition: 'humidShowersLater',
    short: 'humid',
    rain: 60,
    wind: 7,
    icon: LumeIcons.cloudSun,
  ),
  'MY': (
    temp: 32,
    feels: 36,
    condition: 'humidAfternoonStorms',
    short: 'humid',
    rain: 65,
    wind: 6,
    icon: LumeIcons.cloudSun,
  ),
  'BD': (
    temp: 32,
    feels: 37,
    condition: 'humid',
    short: 'humid',
    rain: 45,
    wind: 10,
    icon: LumeIcons.cloudSun,
  ),
  'EG': (
    temp: 35,
    feels: 36,
    condition: 'clearAndDry',
    short: 'clearAndDry',
    rain: 0,
    wind: 14,
    icon: LumeIcons.sun,
  ),
  'NG': (
    temp: 30,
    feels: 34,
    condition: 'humidCloudBuilding',
    short: 'humid',
    rain: 55,
    wind: 9,
    icon: LumeIcons.cloudSun,
  ),
  'ZA': (
    temp: 22,
    feels: 21,
    condition: 'clear',
    short: 'clear',
    rain: 10,
    wind: 16,
    icon: LumeIcons.sun,
  ),
  'SG': (
    temp: 31,
    feels: 36,
    condition: 'humidPassingShowers',
    short: 'humid',
    rain: 60,
    wind: 8,
    icon: LumeIcons.cloudSun,
  ),
  'JP': (
    temp: 26,
    feels: 27,
    condition: 'mildAndClear',
    short: 'mildAndClear',
    rain: 20,
    wind: 10,
    icon: LumeIcons.cloudSun,
  ),
  'CN': (
    temp: 25,
    feels: 26,
    condition: 'hazySun',
    short: 'hazySun',
    rain: 25,
    wind: 11,
    icon: LumeIcons.cloudSun,
  ),
};

/// `WEATHER_BY_ZONE`. The reference's last resort is `Europe`.
const Map<String, _Row> _byZone = <String, _Row>{
  'Africa': (
    temp: 31,
    feels: 34,
    condition: 'warmAndDry',
    short: 'warmAndDry',
    rain: 10,
    wind: 11,
    icon: LumeIcons.sun,
  ),
  'Asia': (
    temp: 29,
    feels: 32,
    condition: 'warm',
    short: 'warm',
    rain: 20,
    wind: 10,
    icon: LumeIcons.sun,
  ),
  'Europe': (
    temp: 18,
    feels: 17,
    condition: 'changeable',
    short: 'changeable',
    rain: 35,
    wind: 12,
    icon: LumeIcons.cloudSun,
  ),
  'America': (
    temp: 23,
    feels: 23,
    condition: 'lightCloud',
    short: 'lightCloud',
    rain: 25,
    wind: 11,
    icon: LumeIcons.cloudSun,
  ),
  'Pacific': (
    temp: 25,
    feels: 26,
    condition: 'breezy',
    short: 'breezy',
    rain: 30,
    wind: 17,
    icon: LumeIcons.cloudSun,
  ),
  'Indian': (
    temp: 28,
    feels: 30,
    condition: 'warmAndHumid',
    short: 'warmAndHumid',
    rain: 35,
    wind: 13,
    icon: LumeIcons.cloudSun,
  ),
  'Atlantic': (
    temp: 20,
    feels: 19,
    condition: 'fresh',
    short: 'fresh',
    rain: 30,
    wind: 20,
    icon: LumeIcons.cloudSun,
  ),
};

/// The markets `WEATHER_BY_COUNTRY` writes down, in its order.
const List<String> kReferenceWeatherMarkets = <String>[
  'PK',
  'IN',
  'GB',
  'US',
  'CA',
  'AE',
  'SA',
  'AU',
  'DE',
  'FR',
  'TR',
  'ID',
  'MY',
  'BD',
  'EG',
  'NG',
  'ZA',
  'SG',
  'JP',
  'CN',
];

/// `weatherFor(country, tz)`, and the forecast `weather()` builds over it.
///
/// [timeZone] is the reader's IANA zone when it is known. The reference always
/// has one — `L.timezone()`, the profile's own or the country's — but this
/// build knows a country's zone only for the markets it names, so a market
/// outside the twenty with no zone given is unavailable rather than guessed.
LumeReferenceClimate? lumeReferenceClimate(String country, {String? timeZone}) {
  final _Row? own = _byCountry[country];
  final _Row? row;
  final LumeWeatherProvenance provenance;
  if (own != null) {
    row = own;
    provenance = LumeWeatherProvenance.reference;
  } else if (timeZone != null && timeZone.isNotEmpty) {
    row = _byZone[timeZone.split('/').first] ?? _byZone['Europe'];
    provenance = LumeWeatherProvenance.derived;
  } else {
    return null;
  }
  if (country.isEmpty) return null;
  return LumeReferenceClimate(
    temperatureC: row!.temp,
    feelsLikeC: row.feels,
    conditionKey: row.condition,
    shortConditionKey: row.short,
    rainPercent: row.rain,
    windKph: row.wind,
    icon: row.icon,
    // `D.daily(base.temp, P().country.charCodeAt(0) * 17)`.
    days: lumeReferenceDaily(row.temp, country.codeUnitAt(0) * 17),
    provenance: provenance,
  );
}

/// `daily(base, seed)`, exactly.
List<LumeReferenceDay> lumeReferenceDaily(int base, int seed) {
  final _SeedRand r = _SeedRand(seed + 7);
  return <LumeReferenceDay>[for (int i = 0; i < 5; i++) _day(base, r)];
}

// Property order in the reference's object literal is evaluation order, so
// each draw happens in the same place: hi, lo, rain, icon, desc.
LumeReferenceDay _day(int base, _SeedRand r) {
  final int hi = _jsRound(base + 2 + (r.next() - 0.4) * 5);
  final int lo = _jsRound(hi - 8 - r.next() * 4);
  final int rain = _jsRound(r.next() * 70);
  final String icon = r.next() > 0.6 ? LumeIcons.cloudSun : LumeIcons.sun;
  final String condition = r.next() > 0.6 ? 'cloudBuilding' : 'mostlyClear';
  return LumeReferenceDay(
    highC: hi,
    lowC: lo,
    rainPercent: rain,
    conditionKey: condition,
    icon: icon,
  );
}

/// `Math.round`, which rounds a half up rather than away from zero.
int _jsRound(double x) => (x + 0.5).floor();

/// `seedRand(seed)` — Park–Miller, as the reference writes it.
class _SeedRand {
  _SeedRand(int seed) : _s = seed % 2147483647 {
    if (_s <= 0) _s += 2147483646;
  }

  int _s;

  double next() {
    _s = _s * 16807 % 2147483647;
    return (_s - 1) / 2147483646;
  }
}

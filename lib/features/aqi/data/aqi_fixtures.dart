/// Air Quality — `tools/daily/aqi.tool.js` over `tool-data.js`
/// `AQI_BY_COUNTRY` and `aqiFor(code, city)`.
///
/// The reference keeps one hardcoded national baseline AQI per country
/// (Karachi's September is not Stockholm's, and pretending otherwise would be
/// worse than saying nothing — the reference's own comment), then offsets it
/// deterministically by a hash of the city's name so two cities in the same
/// country do not read identically. That hash is the reference's own small
/// string hash (`seed = (seed * 31 + charCode) % 997`) — a different,
/// simpler generator from the seeded [LumeSeedRand] the rest of the fixture
/// system draws its walks with, kept distinct here because that is what
/// `aqiFor` itself runs. The 24-hour trend line *is* drawn from the shared
/// engine (`D.walk(aq.value, 24, aq.value, 0.08)`, [lumeWalk]).
///
/// The reference's own comment on `aqiFor` already asks for the honest
/// framing: "let the screen label the derived pollutant rows as estimated
/// rather than measured." `aqi.tool.js` wires that through on every
/// pollutant row (`sub: c.t('aqi.estimated')`) but never on the headline
/// number itself; this port repeats the same distinction on the summary
/// card too, since a reader who only looks at the big number should not
/// need to find the small print under the pollutants to learn it is a
/// derived figure.
///
/// **Dayroz obligation:** every figure here is fixture data — a national or
/// regional average standing in for a city reading, offset by nothing more
/// than the spelling of the city's name. A real integration needs a
/// licensed, per-station air-quality monitoring API: a station id, its
/// distance from the reader, and a measurement timestamp with its own
/// staleness — not a value derived from a country code and a string hash.
/// Until then, every screen this feeds must keep calling it what it is:
/// estimated, not measured.
library;

import 'dart:math' as math;

import '../../../core/fixtures/lume_reference_walk.dart';

/// `Math.round` — a half rounds up rather than away from zero, as
/// `Math.round` does and Dart's `.round()` (ties to even) does not.
int _jsRound(num x) => (x + 0.5).floor();

/// `AQI_BANDS` — each band's advice must be readable in the reader's own
/// language, so the band carries a key rather than English text.
enum LumeAirQualityBand {
  good(50),
  moderate(100),
  sensitive(150),
  unhealthy(200),
  veryUnhealthy(300),
  hazardous(999);

  const LumeAirQualityBand(this.max);

  final int max;

  /// `aqiBand(v)`.
  static LumeAirQualityBand of(int v) {
    for (final LumeAirQualityBand b in values) {
      if (v <= b.max) return b;
    }
    return hazardous;
  }
}

/// One pollutant under the index — `parts[i]`.
class LumeAirQualityPart {
  const LumeAirQualityPart({
    required this.name,
    required this.value,
    required this.unit,
  });

  /// A chemical symbol, written the same in every language ("PM2.5", "O₃").
  final String name;
  final int value;
  final String unit;
}

/// `aqiFor(code, city)`'s return value, typed.
class LumeAirQualityReading {
  const LumeAirQualityReading({required this.value, required this.parts});

  final int value;
  final List<LumeAirQualityPart> parts;

  LumeAirQualityBand get band => LumeAirQualityBand.of(value);

  /// `D.walk(aq.value, 24, aq.value, 0.08)` — the last 24 hours, drawn from
  /// the shared seeded engine rather than `aqiFor`'s own city hash.
  List<double> get trend => lumeWalk(value, 24, value.toDouble(), 0.08);
}

/// `AQI_BY_COUNTRY` — typical urban air quality by market, exactly the
/// reference's own table.
const Map<String, int> lumeAirQualityBaseline = <String, int>{
  'PK': 164,
  'IN': 178,
  'BD': 186,
  'CN': 112,
  'AE': 96,
  'SA': 104,
  'EG': 128,
  'NG': 118,
  'ID': 108,
  'TR': 74,
  'US': 42,
  'GB': 34,
  'DE': 30,
  'FR': 38,
  'CA': 26,
  'AU': 22,
  'JP': 40,
  'SE': 18,
};

/// A country the table does not name — `AQI_BY_COUNTRY[code] || 56`.
const int lumeAirQualityFallbackBaseline = 56;

/// `aqiFor(code, city)`, exactly: the national figure, offset deterministically
/// by a hash of [city] so two cities in the same country read differently —
/// the same city always reads the same number.
LumeAirQualityReading lumeAirQualityFor(String country, String city) {
  final int base =
      lumeAirQualityBaseline[country] ?? lumeAirQualityFallbackBaseline;
  // `for (var i = 0; i < city.length; i++) seed = (seed*31+city.charCodeAt(i)) % 997`.
  int seed = 0;
  for (final int unit in city.codeUnits) {
    seed = (seed * 31 + unit) % 997;
  }
  final int v = math.max(8, _jsRound(base * (0.78 + (seed % 45) / 100)));
  return LumeAirQualityReading(
    value: v,
    parts: <LumeAirQualityPart>[
      LumeAirQualityPart(
        name: 'PM2.5',
        value: _jsRound(v * 0.62),
        unit: 'µg/m³',
      ),
      LumeAirQualityPart(
        name: 'PM10',
        value: _jsRound(v * 0.94),
        unit: 'µg/m³',
      ),
      LumeAirQualityPart(name: 'O₃', value: _jsRound(v * 0.34), unit: 'ppb'),
      LumeAirQualityPart(name: 'NO₂', value: _jsRound(v * 0.22), unit: 'ppb'),
    ],
  );
}

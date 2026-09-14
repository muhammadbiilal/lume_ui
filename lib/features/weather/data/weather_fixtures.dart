/// The weather dashboard's figures beyond the reference climate —
/// `tool-data.js` `hourly()` and `aqiFor()`, and what `context.js`
/// `weather()` and `sunTimes()` derive.
///
/// Ported, not transcribed, as C61 ported `weatherFor` and `daily`: the same
/// Park–Miller generator seeded the same way, drawn in the same order, so the
/// reference run on the fixture day is the expected value. None of it is an
/// observation (F6A-D2): the host says "Delayed", never "Live".
library;

import 'dart:math' as math;

import '../../../core/fixtures/lume_reference_random.dart';
import '../../../core/fixtures/lume_reference_weather.dart';
import '../../../core/icons/lume_icons.dart';

/// `Math.round`, which rounds a half up rather than away from zero.
int _jsRound(num x) => (x + 0.5).floor();

/// One hour of `hourly(base, seed)`.
class LumeWeatherHour {
  const LumeWeatherHour({
    required this.hour,
    required this.temperatureC,
    required this.rainPercent,
    required this.icon,
  });

  final int hour;
  final int temperatureC;
  final int rainPercent;
  final String icon;
}

/// `hourly(base, seed)`, exactly: 24 hours from the current one.
List<LumeWeatherHour> lumeReferenceHourly(int base, int seed, int nowHour) {
  final LumeSeedRand r = LumeSeedRand(seed);
  return <LumeWeatherHour>[
    for (int i = 0; i < 24; i++)
      () {
        final int h = (nowHour + i) % 24;
        final double solar = math.cos((h - 15) / 24 * math.pi * 2);
        // Evaluation order is the object literal's: temp, rain, icon.
        final int temp = _jsRound(base + solar * 5 + (r.next() - 0.5) * 1.6);
        final int rain = math.max(0, _jsRound(r.next() * 40 - 12));
        final String icon = h >= 6 && h <= 18
            ? (r.next() > 0.7 ? LumeIcons.cloudSun : LumeIcons.sun)
            : LumeIcons.moon;
        return LumeWeatherHour(
          hour: h,
          temperatureC: temp,
          rainPercent: rain,
          icon: icon,
        );
      }(),
  ];
}

/// `AQI_BANDS` — each band's words are keys the screen resolves.
enum LumeAqiBand {
  good(50),
  moderate(100),
  sensitive(150),
  unhealthy(200),
  veryUnhealthy(300),
  hazardous(999);

  const LumeAqiBand(this.max);

  final int max;

  /// `aqiBand(v)`.
  static LumeAqiBand of(int v) {
    for (final LumeAqiBand b in values) {
      if (v <= b.max) return b;
    }
    return hazardous;
  }
}

class LumeAqiPart {
  const LumeAqiPart(this.name, this.value);

  /// A chemical symbol, written the same in every language.
  final String name;
  final int value;
}

class LumeAqiReading {
  const LumeAqiReading(this.value, this.parts);

  final int value;
  final List<LumeAqiPart> parts;

  LumeAqiBand get band => LumeAqiBand.of(value);
}

/// `AQI_BY_COUNTRY` — typical urban air by market.
const Map<String, int> _aqiByCountry = <String, int>{
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

/// `aqiFor(code, city)`, exactly — the national figure offset by the city's
/// name so two cities differ.
LumeAqiReading lumeReferenceAqi(String country, String city) {
  final int base = _aqiByCountry[country] ?? 56;
  int seed = 0;
  for (final int unit in city.codeUnits) {
    seed = (seed * 31 + unit) % 997;
  }
  final int v = math.max(8, _jsRound(base * (0.78 + (seed % 45) / 100)));
  return LumeAqiReading(v, <LumeAqiPart>[
    LumeAqiPart('PM2.5', _jsRound(v * 0.62)),
    LumeAqiPart('PM10', _jsRound(v * 0.94)),
    LumeAqiPart('O₃', _jsRound(v * 0.34)),
    LumeAqiPart('NO₂', _jsRound(v * 0.22)),
  ]);
}

/// The eight phases `sunTimes()` names.
enum LumeMoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  full,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

/// `sunTimes().moonPhase` — the moon's age since a known new moon, wrapped
/// by the synodic month.
LumeMoonPhase lumeMoonPhase(DateTime instant) {
  const double synodic = 29.530588853;
  final int knownNew = DateTime.utc(2000, 1, 6, 18, 14).millisecondsSinceEpoch;
  final double days = (instant.millisecondsSinceEpoch - knownNew) / 86400000;
  final double age = (days % synodic + synodic) % synodic;
  final int index = (age / synodic * 8 + 0.5).floor() % 8;
  return LumeMoonPhase.values[index];
}

/// `weather()` over `weatherFor` and `daily`, with what it derives.
class LumeWeatherBoard {
  const LumeWeatherBoard({
    required this.climate,
    required this.hourly,
    required this.aqi,
  });

  /// [nowHour] is the reader's hour; `hourly` starts from it.
  static LumeWeatherBoard? forMarket({
    required String country,
    required String city,
    required String? timeZone,
    required int nowHour,
  }) {
    final LumeReferenceClimate? climate = lumeReferenceClimate(
      country,
      timeZone: timeZone,
    );
    if (climate == null || country.length < 2) return null;
    return LumeWeatherBoard(
      climate: climate,
      // `D.hourly(base.temp, country.charCodeAt(0) * 31 + charCodeAt(1))`.
      hourly: lumeReferenceHourly(
        climate.temperatureC,
        country.codeUnitAt(0) * 31 + country.codeUnitAt(1),
        nowHour,
      ),
      // `D.aqiFor(c.profile.country)` — the tool passes no city, so every
      // city in a market reads the national figure (C76).
      aqi: lumeReferenceAqi(country, ''),
    );
  }

  final LumeReferenceClimate climate;
  final List<LumeWeatherHour> hourly;
  final LumeAqiReading aqi;

  LumeReferenceDay get today => climate.days.first;

  /// `Math.min(95, 40 + base.rain)`.
  int get humidity => math.min(95, 40 + climate.rainPercent);

  /// Fixed in the reference: 10 km and 1012 hPa.
  static const int visibilityKm = 10;
  static const int pressureHpa = 1012;

  /// `base.wind + 9`.
  int get gustsKph => climate.windKph + 9;

  /// `base.temp > 30 ? 9 : 5`.
  int get uv => climate.temperatureC > 30 ? 9 : 5;
  bool get uvHigh => climate.temperatureC > 30;

  /// `Math.round(base.temp - 8)`.
  int get dewC => climate.temperatureC - 8;

  /// `base.temp > 38` — the heat advisory.
  bool get heatAlert => climate.temperatureC > 38;

  /// The forecast's lowest low and highest high, for the bars.
  (int, int) get range {
    final int lo = climate.days
        .map((LumeReferenceDay d) => d.lowC)
        .reduce(math.min);
    final int hi = climate.days
        .map((LumeReferenceDay d) => d.highC)
        .reduce(math.max);
    return (lo, hi);
  }

  /// `lowPct` and `hiPct` for day [d]: where its bar starts and ends across
  /// the week's range, in hundredths.
  (int, int) barFor(LumeReferenceDay d) {
    final (int lo, int hi) = range;
    final int span = math.max(1, hi - lo);
    return (
      _jsRound((d.lowC - lo) / span * 100),
      _jsRound((d.highC - lo) / span * 100),
    );
  }
}

/// `sunTimes()` between a sunrise and a sunset, in minutes of the day.
class LumeSunDay {
  const LumeSunDay({required this.riseMinute, required this.setMinute});

  final int riseMinute;
  final int setMinute;

  int get lengthMinutes => setMinute - riseMinute;

  /// `max(0, min(1, (now − rise) / max(1, length)))`.
  double progressAt(int nowMinute) =>
      ((nowMinute - riseMinute) / math.max(1, lengthMinutes)).clamp(0.0, 1.0);
}

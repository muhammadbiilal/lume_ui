/// Prayer times from the sun, as the reference computes them.
///
/// `data/solar.js` `prayerTimes()`, ported line for line: the sun's
/// declination and the equation of time for the day, solar noon at the
/// longitude, and the hour angles at which the sun reaches each prayer's
/// altitude — Fajr and Isha at the method's twilight angles, Asr where a
/// shadow equals the object (or twice it, Hanafi), sunrise and Maghrib at
/// −0.833°. Above the polar circles, where a twilight angle is never reached,
/// the reference's own fallbacks apply.
///
/// The city table is the reference's `CITIES`; a city it does not carry has
/// no coordinates here, and a caller that has none shows no prayer rather
/// than a guessed one.
///
/// **Dayroz obligation:** this is the reference's approximation. A prayer
/// schedule is a religious service: before release the times must come from
/// the method and madhab the reader chooses, with the high-latitude rule they
/// follow, checked against a published timetable for each city offered.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// `METHODS` — the twilight angles, or Isha a fixed time after Maghrib.
enum LumeSolarMethod {
  karachi(18, isha: 18),
  mwl(18, isha: 17),
  isna(15, isha: 15),
  ummAlQura(18.5, ishaMinutes: 90),
  egyptian(19.5, isha: 17.5),
  tehran(17.7, isha: 14),
  gulf(19.5, ishaMinutes: 90);

  const LumeSolarMethod(this.fajr, {this.isha, this.ishaMinutes});

  final double fajr;
  final double? isha;
  final int? ishaMinutes;
}

/// One time of the day's schedule.
@immutable
class LumeSolarTime {
  const LumeSolarTime(this.key, this.hour, this.minute, {this.minor = false});

  /// `fajr`, `sunrise`, `dhuhr`, `asr`, `maghrib`, `isha`.
  final String key;
  final int hour;
  final int minute;

  /// Sunrise — shown, not prayed.
  final bool minor;

  int get minutes => hour * 60 + minute;

  @override
  bool operator ==(Object other) =>
      other is LumeSolarTime &&
      other.key == key &&
      other.hour == hour &&
      other.minute == minute &&
      other.minor == minor;

  @override
  int get hashCode => Object.hash(key, hour, minute, minor);

  @override
  String toString() =>
      '$key ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

abstract final class LumeSolar {
  /// `CITIES` — city-level coordinates, by `country:city`.
  static const Map<String, (double, double)> cities =
      <String, (double, double)>{
        'PK:Islamabad': (33.69, 73.05),
        'PK:Karachi': (24.86, 67.00),
        'PK:Lahore': (31.55, 74.34),
        'PK:Rawalpindi': (33.60, 73.04),
        'PK:Faisalabad': (31.42, 73.08),
        'PK:Peshawar': (34.02, 71.58),
        'PK:Multan': (30.16, 71.52),
        'PK:Quetta': (30.18, 66.98),
        'PK:Hyderabad': (25.40, 68.37),
        'PK:Gujranwala': (32.16, 74.19),
        'PK:Sialkot': (32.49, 74.53),
        'PK:Bahawalpur': (29.40, 71.68),
        'PK:Sukkur': (27.70, 68.86),
        'PK:Larkana': (27.56, 68.21),
        'PK:Mardan': (34.20, 72.05),
        'PK:Abbottabad': (34.15, 73.22),
        'PK:Swat': (34.78, 72.36),
        'PK:Gwadar': (25.12, 62.32),
        'PK:Gilgit': (35.92, 74.31),
        'PK:Skardu': (35.30, 75.63),
        'PK:Muzaffarabad': (34.37, 73.47),
        'GB:London': (51.51, -0.13),
        'GB:Manchester': (53.48, -2.24),
        'GB:Birmingham': (52.49, -1.89),
        'GB:Glasgow': (55.86, -4.25),
        'GB:Edinburgh': (55.95, -3.19),
        'GB:Leeds': (53.80, -1.55),
        'GB:Liverpool': (53.41, -2.98),
        'GB:Bristol': (51.45, -2.59),
        'GB:Cardiff': (51.48, -3.18),
        'GB:Belfast': (54.60, -5.93),
        'GB:Sheffield': (53.38, -1.47),
        'GB:Newcastle': (54.98, -1.61),
        'GB:Aberdeen': (57.15, -2.09),
        'GB:Swansea': (51.62, -3.94),
        'US:New York': (40.71, -74.01),
        'US:Los Angeles': (34.05, -118.24),
        'US:Chicago': (41.88, -87.63),
        'US:Houston': (29.76, -95.37),
        'US:Dallas': (32.78, -96.80),
        'US:Austin': (30.27, -97.74),
        'US:Miami': (25.76, -80.19),
        'US:Seattle': (47.61, -122.33),
        'US:Boston': (42.36, -71.06),
        'US:Atlanta': (33.75, -84.39),
        'US:Detroit': (42.33, -83.05),
        'US:Dearborn': (42.32, -83.18),
        'US:Philadelphia': (39.95, -75.17),
        'US:Phoenix': (33.45, -112.07),
        'US:Las Vegas': (36.17, -115.14),
        'US:San Francisco': (37.77, -122.42),
        'US:San Diego': (32.72, -117.16),
        'US:San Jose': (37.34, -121.89),
        'CA:Toronto': (43.65, -79.38),
        'CA:Montreal': (45.50, -73.57),
        'CA:Vancouver': (49.28, -123.12),
        'CA:Calgary': (51.05, -114.07),
        'CA:Edmonton': (53.55, -113.49),
        'CA:Ottawa': (45.42, -75.70),
        'AE:Dubai': (25.20, 55.27),
        'AE:Abu Dhabi': (24.45, 54.38),
        'AE:Sharjah': (25.35, 55.39),
        'SA:Riyadh': (24.71, 46.68),
        'SA:Jeddah': (21.49, 39.19),
        'SA:Makkah': (21.42, 39.83),
        'SA:Madinah': (24.52, 39.57),
        'SA:Dammam': (26.43, 50.10),
        'IN:New Delhi': (28.61, 77.21),
        'IN:Mumbai': (19.08, 72.88),
        'IN:Bengaluru': (12.97, 77.59),
        'IN:Chennai': (13.08, 80.27),
        'IN:Hyderabad': (17.39, 78.49),
        'IN:Kolkata': (22.57, 88.36),
        'AU:Sydney': (-33.87, 151.21),
        'AU:Melbourne': (-37.81, 144.96),
        'AU:Perth': (-31.95, 115.86),
        'AU:Brisbane': (-27.47, 153.03),
        'TR:Istanbul': (41.01, 28.98),
        'TR:Ankara': (39.93, 32.86),
        'ID:Jakarta': (-6.21, 106.85),
        'MY:Kuala Lumpur': (3.14, 101.69),
        'EG:Cairo': (30.04, 31.24),
        'ZA:Johannesburg': (-26.20, 28.05),
        'ZA:Cape Town': (-33.92, 18.42),
        'NG:Lagos': (6.52, 3.38),
        'NG:Abuja': (9.06, 7.49),
        'JP:Tokyo': (35.68, 139.69),
        'DE:Berlin': (52.52, 13.40),
        'FR:Paris': (48.86, 2.35),
        'SG:Singapore': (1.35, 103.82),
      };

  /// `coordsFor` — the city's coordinates, or `null` where the table has
  /// none.
  static (double lat, double lon)? coordsFor(String country, String city) =>
      cities['$country:$city'];

  static double _rad(double d) => d * math.pi / 180;
  static double _deg(double r) => r * 180 / math.pi;
  static double _sin(double d) => math.sin(_rad(d));
  static double _cos(double d) => math.cos(_rad(d));
  static double _tan(double d) => math.tan(_rad(d));

  static double _fix(double a, double n) {
    final double v = a - n * (a / n).floorToDouble();
    return v < 0 ? v + n : v;
  }

  /// `julian(date)` — the civil date's Julian day at midnight.
  static double _julian(DateTime date) {
    int y = date.year, m = date.month;
    final int d = date.day;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final int a = (y / 100).floor();
    final int b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floorToDouble() +
        (30.6001 * (m + 1)).floorToDouble() +
        d +
        b -
        1524.5;
  }

  /// The day's schedule at [lat], [lon], in a zone [offsetHours] from UTC on
  /// that date.
  static List<LumeSolarTime> prayerTimes({
    required DateTime date,
    required double lat,
    required double lon,
    required double offsetHours,
    LumeSolarMethod method = LumeSolarMethod.mwl,
    bool hanafi = false,
  }) {
    final double jd = _julian(date) - lon / (15 * 24);
    final double dd = jd - 2451545.0;
    final double g = _fix(357.529 + 0.98560028 * dd, 360);
    final double q = _fix(280.459 + 0.98564736 * dd, 360);
    final double l = _fix(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g), 360);
    final double e = 23.439 - 0.00000036 * dd;
    final double decl = _deg(math.asin(_sin(e) * _sin(l)));
    final double ra = _fix(
      _deg(math.atan2(_cos(e) * _sin(l), _cos(l))) / 15,
      24,
    );
    final double eqt = q / 15 - ra;

    final double noon = 12 - eqt - lon / 15 + offsetHours;

    double? hourAngle(double alt) {
      final double c =
          (_sin(alt) - _sin(lat) * _sin(decl)) / (_cos(lat) * _cos(decl));
      if (c > 1 || c < -1) return null;
      return _deg(math.acos(c)) / 15;
    }

    double? before(double alt) {
      final double? ha = hourAngle(alt);
      return ha == null ? null : noon - ha;
    }

    double? after(double alt) {
      final double? ha = hourAngle(alt);
      return ha == null ? null : noon + ha;
    }

    final double asrAlt = _deg(
      math.atan(1 / ((hanafi ? 2 : 1) + _tan(lat - decl).abs())),
    );

    double? sunrise = before(-0.833);
    double? sunset = after(-0.833);
    double? fajr = before(-method.fajr);
    double? asr = after(asrAlt);
    double? isha = method.ishaMinutes != null
        ? (sunset == null ? null : sunset + method.ishaMinutes! / 60)
        : after(-method.isha!);

    if (fajr == null && sunrise != null) fajr = sunrise - 1.2;
    if (isha == null && sunset != null) isha = sunset + 1.2;
    if (sunrise == null) {
      sunrise = 6;
      sunset = 18;
      fajr = 4.8;
      isha = 19.2;
      asr = 15.5;
    }

    LumeSolarTime hm(double hours, String key, {bool minor = false}) {
      final double v = _fix(hours, 24);
      int h = v.floor();
      // `Math.round` — half rounds up.
      int m = ((v - h) * 60 + 0.5).floor();
      if (m == 60) {
        m = 0;
        h = (h + 1) % 24;
      }
      return LumeSolarTime(key, h, m, minor: minor);
    }

    return <LumeSolarTime>[
      hm(fajr!, 'fajr'),
      hm(sunrise, 'sunrise', minor: true),
      hm(noon + 1 / 60, 'dhuhr'),
      hm(asr!, 'asr'),
      hm(sunset!, 'maghrib'),
      hm(isha!, 'isha'),
    ];
  }

  /// `prayerState().next` — the first prayer after [minuteOfDay], or the
  /// first of tomorrow's.
  static LumeSolarTime nextPrayer(List<LumeSolarTime> day, double minuteOfDay) {
    final List<LumeSolarTime> main = <LumeSolarTime>[
      for (final LumeSolarTime t in day)
        if (!t.minor) t,
    ];
    for (final LumeSolarTime t in main) {
      if (t.minutes > minuteOfDay) return t;
    }
    return main.first;
  }
}

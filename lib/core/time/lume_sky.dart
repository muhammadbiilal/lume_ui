/// The sun's day and the moon's phase — `context.js` `sunTimes()`, worked out
/// rather than read.
///
/// **The sun.** The same low-precision solar position [LumeSolar] uses for
/// prayer times (declination and the equation of time for the day), so the
/// two tools never disagree about sunrise. Sunrise and sunset are the sun's
/// upper edge at −0.833° (refraction included); solar noon is between them.
/// Dawn and dusk are **civil twilight**, the sun 6° below the horizon — the
/// reference puts them a fixed hour either side of sunrise and sunset, which
/// is not a measurement (C86).
///
/// Where the sun does not cross the horizon the day says so: [LumeSunKind]
/// is polar day or polar night, and no rise or set is invented (the prayer
/// schedule's 06:00 / 18:00 fallback is not used here). Where it never sinks
/// 6° below, there is no dawn or dusk.
///
/// **The moon.** Its age is days since a known new moon (6 January 2000,
/// 18:14 UTC) modulo the mean synodic month, as the reference computes it;
/// the phase is the nearest of eight, and illumination is
/// `(1 − cos 2π·age/month) / 2`. A mean month, so a phase can be up to about
/// half a day early or late against a published almanac; the figure is a
/// calculation, never a live observation.
///
/// Every input is a parameter — the instant, the place, the zone's offset —
/// so a test pins all of them.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Whether the sun crosses the horizon on the day.
enum LumeSunKind { normal, polarDay, polarNight }

/// `phases` — nearest of eight.
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

/// One day of the sun at a place, in hours of that day's local clock
/// (0–24; a value outside the day stays outside it rather than wrapping).
@immutable
class LumeSunDay {
  const LumeSunDay({
    required this.kind,
    required this.noon,
    this.sunrise,
    this.sunset,
    this.dawn,
    this.dusk,
  });

  final LumeSunKind kind;

  /// Solar noon — there is one even in polar day and night.
  final double noon;

  final double? sunrise;
  final double? sunset;

  /// Civil dawn and dusk; `null` where the sun never goes 6° below.
  final double? dawn;
  final double? dusk;

  /// Hours of daylight: rise to set, all of it in polar day, none in polar
  /// night.
  double get daylight => switch (kind) {
    LumeSunKind.polarDay => 24,
    LumeSunKind.polarNight => 0,
    LumeSunKind.normal => sunset! - sunrise!,
  };
}

@immutable
class LumeMoon {
  const LumeMoon({required this.age, required this.phase, required this.lit});

  /// Days since the last new moon, 0 to [LumeSky.synodic].
  final double age;

  final LumeMoonPhase phase;

  /// Percent of the disc lit, 0 at new and 100 at full.
  final int lit;
}

abstract final class LumeSky {
  /// The mean synodic month, in days.
  static const double synodic = 29.530588853;

  /// A known new moon: 6 January 2000, 18:14 UTC.
  static final DateTime knownNew = DateTime.utc(2000, 1, 6, 18, 14);

  /// Sunrise and sunset: the upper limb, with refraction.
  static const double horizon = -0.833;

  /// Civil twilight.
  static const double civil = -6;

  static double _rad(double d) => d * math.pi / 180;
  static double _deg(double r) => r * 180 / math.pi;

  static double _fix(double a, double n) {
    final double v = a - n * (a / n).floorToDouble();
    return v < 0 ? v + n : v;
  }

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

  /// The sun on [date] (its calendar day) at [lat], [lon], on a clock
  /// [offsetHours] from UTC.
  static LumeSunDay sun({
    required DateTime date,
    required double lat,
    required double lon,
    required double offsetHours,
  }) {
    final double jd = _julian(date) - lon / (15 * 24);
    final double dd = jd - 2451545.0;
    final double g = _fix(357.529 + 0.98560028 * dd, 360);
    final double q = _fix(280.459 + 0.98564736 * dd, 360);
    final double l = _fix(
      q + 1.915 * math.sin(_rad(g)) + 0.020 * math.sin(_rad(2 * g)),
      360,
    );
    final double e = 23.439 - 0.00000036 * dd;
    final double decl = _deg(math.asin(math.sin(_rad(e)) * math.sin(_rad(l))));
    final double ra = _fix(
      _deg(
            math.atan2(
              math.cos(_rad(e)) * math.sin(_rad(l)),
              math.cos(_rad(l)),
            ),
          ) /
          15,
      24,
    );
    final double eqt = q / 15 - ra;
    final double noon = 12 - eqt - lon / 15 + offsetHours;

    /// The cosine of the hour angle at which the sun is at [alt]: above 1
    /// it never climbs that high, below −1 it never sinks that low.
    double cosAt(double alt) =>
        (math.sin(_rad(alt)) - math.sin(_rad(lat)) * math.sin(_rad(decl))) /
        (math.cos(_rad(lat)) * math.cos(_rad(decl)));

    double? half(double alt) {
      final double c = cosAt(alt);
      if (c > 1 || c < -1) return null;
      return _deg(math.acos(c)) / 15;
    }

    final double c0 = cosAt(horizon);
    if (c0 > 1) {
      // Never up: twilight may still come and go around noon.
      final double? t = half(civil);
      return LumeSunDay(
        kind: LumeSunKind.polarNight,
        noon: noon,
        dawn: t == null ? null : noon - t,
        dusk: t == null ? null : noon + t,
      );
    }
    if (c0 < -1) {
      return LumeSunDay(kind: LumeSunKind.polarDay, noon: noon);
    }
    final double h = half(horizon)!;
    final double? t = half(civil);
    return LumeSunDay(
      kind: LumeSunKind.normal,
      noon: noon,
      sunrise: noon - h,
      sunset: noon + h,
      dawn: t == null ? null : noon - t,
      dusk: t == null ? null : noon + t,
    );
  }

  /// The moon at [instant].
  static LumeMoon moon(DateTime instant) {
    final double days =
        instant.toUtc().difference(knownNew).inMilliseconds / 86400000;
    final double age = (days % synodic + synodic) % synodic;
    final double frac = age / synodic;
    return LumeMoon(
      age: age,
      phase: LumeMoonPhase.values[(frac * 8 + 0.5).floor() % 8],
      lit: ((1 - math.cos(frac * 2 * math.pi)) / 2 * 100).round(),
    );
  }

  /// `(hour, minute)` for an hour of the day, rounded to the minute, half
  /// up (`Math.round`), wrapped onto the clock.
  static (int, int) clock(double hours) {
    final double v = _fix(hours, 24);
    int h = v.floor();
    int m = ((v - h) * 60 + 0.5).floor();
    if (m == 60) {
      m = 0;
      h = (h + 1) % 24;
    }
    return (h, m);
  }
}

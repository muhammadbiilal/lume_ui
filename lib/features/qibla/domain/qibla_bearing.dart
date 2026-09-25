/// Qibla — the great-circle bearing to the Kaaba, and the distance to it.
///
/// `data/solar.js`'s `qibla(lat, lon)` and the haversine distance inside
/// `context.js`'s `qibla()`, ported line for line: the initial bearing of the
/// great-circle route from the reader's coordinates to the Kaaba (21.4225°N,
/// 39.8262°E), clockwise from true north, and the great-circle distance
/// between the two points.
///
/// Both are worked out from real coordinates every time this is called —
/// never a fixture, and never a live device sensor: this build reads no
/// magnetometer and no device orientation, so there is no "true" needle to
/// correct against a magnetic one. What is shown is the direction a reader
/// would face if they lined this bearing up against true north themselves,
/// with a compass or a map — the reference's own `magnetic` field is not a
/// declination calculation either, only the fixed label "True north"
/// (`qibla.trueNorth`), carried here as [basisIsTrueNorth].
library;

import 'dart:math' as math;

/// Pure Qibla geometry: no widget, no locale, no clock.
abstract final class LumeQiblaMath {
  /// The Kaaba, as the reference states it.
  static const double kaabaLat = 21.4225;
  static const double kaabaLon = 39.8262;

  /// Every bearing here is measured against true north, never a magnetic
  /// one — there is no device sensor behind it to correct for declination.
  static const bool basisIsTrueNorth = true;

  static const double _earthRadiusKm = 6371;

  static double _rad(double d) => d * math.pi / 180;
  static double _deg(double r) => r * 180 / math.pi;

  static double _fix(double a, double n) {
    final double v = a - n * (a / n).floorToDouble();
    return v < 0 ? v + n : v;
  }

  /// The initial great-circle bearing from ([lat], [lon]) to the Kaaba, in
  /// degrees clockwise from true north, `[0, 360)`.
  ///
  /// `SOLAR.qibla`: `atan2(sin(dLon), cos(lat)·tan(kaabaLat) − sin(lat)·cos(dLon))`,
  /// fixed into a full turn. Equivalent to the standard initial-bearing
  /// formula divided through by `cos(kaabaLat)` — atan2 of a pair and of that
  /// same pair scaled by a positive constant is the same angle — so it is
  /// carried over as the reference states it rather than the more common
  /// textbook form.
  static double bearing(double lat, double lon) {
    final double dLon = _rad(kaabaLon - lon);
    final double y = math.sin(dLon);
    final double x =
        math.cos(_rad(lat)) * math.tan(_rad(kaabaLat)) -
        math.sin(_rad(lat)) * math.cos(dLon);
    return _fix(_deg(math.atan2(y, x)), 360);
  }

  /// The great-circle distance from ([lat], [lon]) to the Kaaba, in whole
  /// kilometres — the haversine formula, as `context.js`'s `qibla()` rounds
  /// it.
  static int distanceKm(double lat, double lon) {
    final double dLat = _rad(kaabaLat - lat);
    final double dLon = _rad(kaabaLon - lon);
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat)) *
            math.cos(_rad(kaabaLat)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return (_earthRadiusKm * c).round();
  }

  /// `SOLAR.compassPoint` — the nearest of eight points.
  ///
  /// Kept in Latin letters in every language, as the reference's own
  /// `compassPoint()` returns them untranslated regardless of locale, and as
  /// `toolStatusQibla` keeps its degree-and-letter reading untranslated for
  /// the same reason (D22): an abbreviation like this is not prose to carry
  /// across scripts.
  static const List<String> points = <String>[
    'N',
    'NE',
    'E',
    'SE',
    'S',
    'SW',
    'W',
    'NW',
  ];

  static String compassPoint(double bearingDegrees) {
    final int i = (_fix(bearingDegrees, 360) / 45).round() % 8;
    return points[i];
  }
}

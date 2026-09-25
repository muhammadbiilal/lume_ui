/// A position, turned into the country and city the picker would show.
///
/// The nearest known city by great-circle distance, over
/// [LumeSolar.cities] and [kLumePrimaryCityPoints]. The reference compared
/// squared differences of latitude and longitude, which stretches distances
/// east–west the further a reader is from the equator; this measures on the
/// sphere. It is still "the nearest city Lume knows", not a street address —
/// which is why the result is offered as the picker's selection for the
/// reader to confirm, never committed on its own.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/time/lume_solar.dart';
import '../../../core/time/lume_place_points.dart';

@immutable
class LumeResolvedPlace {
  const LumeResolvedPlace({
    required this.country,
    required this.city,
    required this.kilometres,
  });

  final String country;
  final String city;

  /// How far the position was from [city] — for tests and for deciding
  /// nothing else; the screen does not show it.
  final double kilometres;
}

abstract final class LumePlaceResolver {
  /// Every point, as `(country, city, latitude, longitude)`.
  static final List<(String, String, double, double)> points =
      <(String, String, double, double)>[
        for (final MapEntry<String, (double, double)> e
            in LumeSolar.cities.entries)
          (e.key.substring(0, 2), e.key.substring(3), e.value.$1, e.value.$2),
        ...kLumePrimaryCityPoints,
      ];

  /// The nearest point to [latitude], [longitude] whose city [isKnown]
  /// accepts — the caller passes the picker's own city list, so the answer is
  /// always a city the reader could have chosen by hand. `null` only when no
  /// point qualifies.
  static LumeResolvedPlace? nearest(
    double latitude,
    double longitude, {
    required bool Function(String country, String city) isKnown,
  }) {
    LumeResolvedPlace? best;
    for (final (String country, String city, double lat, double lon)
        in points) {
      if (!isKnown(country, city)) continue;
      final double d = kilometresBetween(latitude, longitude, lat, lon);
      if (best == null || d < best.kilometres) {
        best = LumeResolvedPlace(country: country, city: city, kilometres: d);
      }
    }
    return best;
  }

  /// Great-circle distance (haversine), on a sphere of the Earth's mean
  /// radius.
  static double kilometresBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double r = 6371.0088;
    double rad(double d) => d * math.pi / 180;
    final double dLat = rad(lat2 - lat1);
    final double dLon = rad(lon2 - lon1);
    final double a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.min(1, math.sqrt(a)));
  }
}

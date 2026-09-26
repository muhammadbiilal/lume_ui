/// Nearby Mosques' own words: a mosque's name, its facilities, and a
/// distance as the reference writes one (`L.distance`).
library;

import '../../../core/localization/lume_format.dart';
import '../../../l10n/app_localizations.dart';
import '../data/mosques_fixtures.dart';

abstract final class LumeMosquesText {
  /// `n + ' ' + P().city` — the reference's name, then the reader's city.
  static String name(AppLocalizations l, LumeNearbyMosque m, String city) {
    final String base = switch (m.name) {
      LumeMosqueName.central => l.mosquesCentral,
      LumeMosqueName.jamia => l.mosquesJamia,
      LumeMosqueName.alNoor => l.mosquesMasjidA,
      LumeMosqueName.bilal => l.mosquesMasjidB,
    };
    return city.isEmpty ? base : '$base $city';
  }

  /// `m.facilities.join(' · ')`.
  static String facilities(AppLocalizations l, LumeNearbyMosque m) => <String>[
    for (final LumeMosqueFacility x in m.facilities)
      switch (x) {
        LumeMosqueFacility.parking => l.mosquesFacParking,
        LumeMosqueFacility.women => l.mosquesFacWomen,
        LumeMosqueFacility.wudu => l.mosquesFacWudu,
      },
  ].join(' · ');

  /// `L.distance(km)` — miles for an imperial reader, a tenth under ten,
  /// metres under one kilometre.
  static String distance(AppLocalizations l, LumeFormatting f, num km) {
    if (f.units == LumeUnits.imperial) {
      final double mi = km * 0.621;
      return '${mi < 10 ? mi.toStringAsFixed(1) : mi.round()} ${l.unitMi}';
    }
    if (km < 1) return '${(km * 1000).round()} m';
    if (km == km.roundToDouble()) return '${km.round()} ${l.unitKm}';
    return '${km < 10 ? km.toStringAsFixed(1) : km.round()} ${l.unitKm}';
  }
}

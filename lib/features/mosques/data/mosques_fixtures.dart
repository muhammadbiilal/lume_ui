/// Four mosques near the reader — `context.js` `nearbyMosques()`, typed.
///
/// The reference writes the same four rows for every city: a fixed name
/// list suffixed with the reader's own city, a distance of `0.4 + i × 0.7`
/// km, a walking time of twelve minutes a kilometre, a fixed set of
/// facilities, and a map pin placed from `i` alone. This is that list, as
/// sample data — the tool's capability says so on the source line, the same
/// as every other fixture tool. The one figure that is not sample is each
/// row's next prayer: that is the reader's own city's schedule, worked out by
/// `prayer_schedule.dart`, which is what the reference reads too
/// (`set[next.index]`).
///
/// **Dayroz obligation:** a real list needs a licensed places source
/// (Google Places, OpenStreetMap, or an owned directory) searched from the
/// reader's coordinates, with each mosque's own name, address, distance,
/// facilities and — where the mosque publishes it — its own jamaat time,
/// rather than the city's calculated one.
library;

import 'package:flutter/foundation.dart';

/// Which of the reference's four names a row carries.
enum LumeMosqueName { central, jamia, alNoor, bilal }

/// What a mosque offers, by key.
enum LumeMosqueFacility { parking, women, wudu }

@immutable
class LumeNearbyMosque {
  const LumeNearbyMosque({
    required this.name,
    required this.km,
    required this.facilities,
    required this.x,
    required this.y,
    required this.reciter,
    required this.rakaat,
    required this.taraweehMinute,
  });

  /// Taraweeh at this mosque (the reference: "Taraweeh belongs to the
  /// mosque, not to the row that draws it") — who leads it, how many
  /// rakaat, and when it starts, as minutes after midnight.
  final String reciter;
  final int rakaat;
  final int taraweehMinute;

  final LumeMosqueName name;

  /// Kilometres from the reader — the reference's own `0.4 + i × 0.7`.
  final double km;

  final List<LumeMosqueFacility> facilities;

  /// The map pin, 0–100 across and down.
  final double x;
  final double y;

  /// `Math.round(km * 12)` — twelve minutes a kilometre, on foot.
  int get walkMinutes => (km * 12).round();
}

abstract final class LumeMosquesFixtures {
  static const List<LumeNearbyMosque> all = <LumeNearbyMosque>[
    LumeNearbyMosque(
      name: LumeMosqueName.central,
      km: 0.4,
      facilities: <LumeMosqueFacility>[
        LumeMosqueFacility.parking,
        LumeMosqueFacility.women,
      ],
      x: 22,
      y: 30,
      reciter: 'Qari Ahmed',
      rakaat: 20,
      taraweehMinute: 20 * 60 + 45,
    ),
    LumeNearbyMosque(
      name: LumeMosqueName.jamia,
      km: 1.1,
      facilities: <LumeMosqueFacility>[LumeMosqueFacility.wudu],
      x: 41,
      y: 64,
      reciter: 'Hafiz Bilal',
      rakaat: 8,
      taraweehMinute: 20 * 60 + 50,
    ),
    LumeNearbyMosque(
      name: LumeMosqueName.alNoor,
      km: 1.8,
      facilities: <LumeMosqueFacility>[LumeMosqueFacility.parking],
      x: 60,
      y: 30,
      reciter: 'Qari Usman',
      rakaat: 20,
      taraweehMinute: 20 * 60 + 55,
    ),
    LumeNearbyMosque(
      name: LumeMosqueName.bilal,
      km: 2.5,
      facilities: <LumeMosqueFacility>[
        LumeMosqueFacility.women,
        LumeMosqueFacility.wudu,
      ],
      x: 79,
      y: 64,
      reciter: 'Hafiz Salman',
      rakaat: 8,
      taraweehMinute: 20 * 60 + 40,
    ),
  ];

  /// The radius chips, in kilometres — `1`, `3`, `5`; `3` is the default.
  static const List<int> radii = <int>[1, 3, 5];
  static const int defaultRadius = 3;

  /// `list.filter(...)`: within [radiusKm], and — where [query] is not
  /// empty — whose displayed name contains it, case-folded.
  static List<LumeNearbyMosque> shown({
    required int radiusKm,
    required String query,
    required String Function(LumeNearbyMosque m) nameOf,
  }) {
    final String q = query.trim().toLowerCase();
    return <LumeNearbyMosque>[
      for (final LumeNearbyMosque m in all)
        if (m.km <= radiusKm &&
            (q.isEmpty || nameOf(m).toLowerCase().contains(q)))
          m,
    ];
  }
}

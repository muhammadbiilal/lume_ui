/// A real local instant plus [LumeSolar]'s own raw times for it — the one
/// orchestration step every "prayer times at a place, on a zone, right now"
/// tool needs before its own domain shaping.
///
/// [LumeSolar] stays pure — every input a parameter, no zone or clock concept
/// inside it (its own doc comment says as much) — so resolving a real city's
/// coordinates and a real, resolved [LumeZone] into that day's local wall
/// clock and raw solar times is the piece Prayer Times
/// (`prayer_schedule.dart`) and Ramadan (`ramadan_tool.dart`) each derived
/// identically before this existed: `zone.wallClockAt(now)` for the local
/// instant, `zone.offsetAt(now)` for the UTC offset [LumeSolar.prayerTimes]
/// needs. Extracted here rather than kept as two copies of the same lines.
library;

import 'package:flutter/foundation.dart';

import 'lume_solar.dart';
import 'lume_zone.dart';

@immutable
class LumeSolarDay {
  const LumeSolarDay({required this.local, required this.raw});

  /// [zone]'s wall clock at the instant this was resolved for — a naive
  /// value, its fields the zone's own.
  final DateTime local;

  /// [LumeSolar.prayerTimes] for [local]'s day, at the resolved coordinates.
  final List<LumeSolarTime> raw;

  /// Resolves [now] against [zone] and asks [LumeSolar] for that day's raw
  /// times at [coords]. The caller has already turned a country/city and a
  /// [LumeZoneResolution] into real [coords] and a real [zone] — this does
  /// only the part that follows from having both.
  static LumeSolarDay at({
    required DateTime now,
    required (double, double) coords,
    required LumeZone zone,
  }) {
    final DateTime local = zone.wallClockAt(now);
    return LumeSolarDay(
      local: local,
      raw: LumeSolar.prayerTimes(
        date: local,
        lat: coords.$1,
        lon: coords.$2,
        offsetHours: zone.offsetAt(now).inMinutes / 60,
      ),
    );
  }
}

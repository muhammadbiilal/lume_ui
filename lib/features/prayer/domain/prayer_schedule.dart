/// Prayer Times — the day's five prayers, from the sun.
///
/// `data/solar.js`'s `prayerTimes()` — already ported at [LumeSolar], the same
/// low-precision solar-position calculation [LumeSky] uses for Sun & Moon — and
/// `context.js`'s `prayerState()` / `upcomingPrayerDays()`: worked out for the
/// reader's city and clock every time this is called, never a fixture and
/// never a live network feed (this app makes none). The method is fixed to
/// the Muslim World League's angles (18° Fajr, 17° Isha) and the standard
/// (Shafi'i/Maliki/Hanbali) Asr shadow ratio — [LumeSolar.prayerTimes]'s own
/// defaults, and the only method/madhab this build offers; there is no
/// central preference yet for a reader to choose another (§ report).
///
/// **What differs from the reference.** `context.js`'s `prayerState()` reads
/// `now.getSeconds()` for a live, second-precise countdown; this build never
/// starts its own clock inside a tool (Qibla's own note on why: nothing here
/// is a sensor, and nothing here self-ticks either — matching Sun & Moon, the
/// reading is worked out fresh from the ambient [LumeClockScope] each time the
/// screen rebuilds, not advanced by an internal timer). Once the day's last
/// prayer (Isha) has passed, "next" wraps to tomorrow's Fajr *at today's clock
/// time* rather than a freshly recomputed one — the reference's own
/// approximation (`prayerState()`'s wrap-around arithmetic does the same,
/// implicitly); the drift this introduces is at most a minute or two.
///
/// **Dayroz obligation**, carried over from [LumeSolar]'s own: a prayer
/// schedule is a religious service. Before release these times must come from
/// the method and madhab the reader actually chooses, with a high-latitude
/// rule, checked against a published timetable for each city offered — the
/// in-tool note says as much.
library;

import 'package:flutter/foundation.dart';

import '../../../core/time/lume_iana_zones.dart';
import '../../../core/time/lume_solar.dart';
import '../../../core/time/lume_solar_day.dart';
import '../../../core/time/lume_zone.dart';

/// Which real-world input stops a schedule from being worked out.
enum LumePrayerMissing { city, zone }

/// One of the five daily prayers, at a real clock time.
@immutable
class LumePrayerSlot {
  const LumePrayerSlot(this.key, this.at);

  /// `fajr`, `dhuhr`, `asr`, `maghrib`, `isha` — [LumeFeatureStrings.prayerName]'s
  /// own vocabulary, so this tool names them exactly as Home already does.
  final String key;
  final DateTime at;

  @override
  bool operator ==(Object other) =>
      other is LumePrayerSlot && other.key == key && other.at == at;

  @override
  int get hashCode => Object.hash(key, at);
}

/// One day ahead, for the drift table — `upcomingPrayerDays()`.
@immutable
class LumePrayerOutlookDay {
  const LumePrayerOutlookDay({
    required this.day,
    required this.fajr,
    required this.dhuhr,
    required this.maghrib,
  });

  final DateTime day;
  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime maghrib;
}

/// Today's schedule at a place, on a clock.
@immutable
class LumePrayerDay {
  const LumePrayerDay({
    required this.slots,
    required this.sunrise,
    required this.sunset,
  });

  /// The five, Fajr through Isha, in order. Sunrise is never among them —
  /// shown, not prayed ([LumeSolarTime.minor]) — which is why it is carried
  /// separately as [sunrise].
  final List<LumePrayerSlot> slots;

  final DateTime sunrise;

  /// The same instant as Maghrib — carried under its own name for the
  /// sunrise/sunset pairing, matching the reference's own `sunTimes()`, which
  /// reads Maghrib as the day's sunset.
  final DateTime sunset;

  /// `prayerState()` — the next prayer at [now] and how long until it, having
  /// wrapped to tomorrow's Fajr (see the library note) once Isha has passed.
  (LumePrayerSlot next, Duration remaining, double progress) state(
    DateTime now,
  ) {
    for (int i = 0; i < slots.length; i++) {
      final LumePrayerSlot slot = slots[i];
      if (slot.at.isAfter(now)) {
        final DateTime prevAt = i == 0
            ? slots.last.at.subtract(const Duration(days: 1))
            : slots[i - 1].at;
        final Duration span = slot.at.difference(prevAt);
        final Duration remaining = slot.at.difference(now);
        final double progress = span.inSeconds <= 0
            ? 0
            : 1 - remaining.inSeconds / span.inSeconds;
        return (slot, remaining, _unit(progress));
      }
    }
    final LumePrayerSlot first = slots.first;
    final LumePrayerSlot tomorrow = LumePrayerSlot(
      first.key,
      first.at.add(const Duration(days: 1)),
    );
    final Duration span = tomorrow.at.difference(slots.last.at);
    final Duration remaining = tomorrow.at.difference(now);
    final double progress = span.inSeconds <= 0
        ? 0
        : 1 - remaining.inSeconds / span.inSeconds;
    return (tomorrow, remaining, _unit(progress));
  }

  /// `Math.max(0, Math.min(1, v))` — clamped to `[0, 1]`, kept as a `double`
  /// rather than `num.clamp`'s widened return type.
  static double _unit(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  /// Worked out at [country]/[city]'s coordinates, on [zone]'s clock, for the
  /// civil day [now] falls on there. `null` with [LumePrayerMissing] set where
  /// either input is missing — said, not guessed (no fabricated data).
  static (LumePrayerDay?, LumePrayerMissing?) at({
    required DateTime now,
    required String country,
    required String city,
    required LumeZoneResolution zone,
  }) {
    final (double, double)? coords = LumeSolar.coordsFor(country, city);
    if (coords == null) return (null, LumePrayerMissing.city);
    final LumeZone? z = zone.zone;
    if (z == null) return (null, LumePrayerMissing.zone);
    return (_on(LumeSolarDay.at(now: now, coords: coords, zone: z)), null);
  }

  static LumePrayerDay _on(LumeSolarDay solarDay) {
    final DateTime local = solarDay.local;
    final List<LumeSolarTime> raw = solarDay.raw;
    DateTime at(LumeSolarTime t) =>
        DateTime(local.year, local.month, local.day, t.hour, t.minute);
    LumeSolarTime byKey(String k) =>
        raw.firstWhere((LumeSolarTime t) => t.key == k);
    return LumePrayerDay(
      slots: <LumePrayerSlot>[
        for (final LumeSolarTime t in raw)
          if (!t.minor) LumePrayerSlot(t.key, at(t)),
      ],
      sunrise: at(byKey('sunrise')),
      sunset: at(byKey('maghrib')),
    );
  }

  /// `upcomingPrayerDays(n)` — Fajr, Dhuhr and Maghrib drift over the next
  /// [days] days, which is what a reader actually plans around.
  static List<LumePrayerOutlookDay> outlook({
    required DateTime local,
    required (double, double) coords,
    required double offsetHours,
    int days = 4,
  }) {
    final List<LumePrayerOutlookDay> out = <LumePrayerOutlookDay>[];
    for (int i = 1; i <= days; i++) {
      final DateTime day = local.add(Duration(days: i));
      final List<LumeSolarTime> raw = LumeSolar.prayerTimes(
        date: day,
        lat: coords.$1,
        lon: coords.$2,
        offsetHours: offsetHours,
      );
      DateTime at(String key) {
        final LumeSolarTime t = raw.firstWhere(
          (LumeSolarTime t) => t.key == key,
        );
        return DateTime(day.year, day.month, day.day, t.hour, t.minute);
      }

      out.add(
        LumePrayerOutlookDay(
          day: day,
          fajr: at('fajr'),
          dhuhr: at('dhuhr'),
          maghrib: at('maghrib'),
        ),
      );
    }
    return out;
  }
}

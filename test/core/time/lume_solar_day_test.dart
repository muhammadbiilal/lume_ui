/// [LumeSolarDay] — the shared local-instant-plus-raw-solar-times step
/// Prayer Times and Ramadan both derive from a resolved city and zone.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/time/lume_solar.dart';
import 'package:lume/core/time/lume_solar_day.dart';
import 'package:lume/core/time/lume_zone.dart';

/// A zone with a constant offset from UTC — the same minimal fake
/// `prayer_schedule_test.dart`'s own `_FixedZone` uses, so this stays
/// deterministic without the real IANA database.
class _FixedZone implements LumeZone {
  const _FixedZone(this.offset);

  final Duration offset;

  @override
  String get id => 'Fixed/${offset.inMinutes}';

  @override
  Duration offsetAt(DateTime instant) => offset;

  @override
  DateTime wallClockAt(DateTime instant) => instant.toUtc().add(offset);
}

void main() {
  test('local is the zone\'s own wall clock at now, not now itself', () {
    final DateTime now = DateTime.utc(2026, 9, 7, 12);
    const _FixedZone zone = _FixedZone(Duration(hours: 5));
    final LumeSolarDay day = LumeSolarDay.at(
      now: now,
      coords: (33.7, 73.1),
      zone: zone,
    );
    expect(day.local, now.toUtc().add(const Duration(hours: 5)));
  });

  test('raw carries every key LumeSolar.prayerTimes gives that day, at the '
      'resolved coordinates and offset', () {
    final DateTime now = DateTime.utc(2026, 9, 7, 12);
    const _FixedZone zone = _FixedZone(Duration(hours: 5));
    final LumeSolarDay day = LumeSolarDay.at(
      now: now,
      coords: (33.7, 73.1),
      zone: zone,
    );
    final List<LumeSolarTime> expected = LumeSolar.prayerTimes(
      date: day.local,
      lat: 33.7,
      lon: 73.1,
      offsetHours: 5,
    );
    expect(day.raw.map((LumeSolarTime t) => t.key), <String>[
      for (final LumeSolarTime t in expected) t.key,
    ]);
    expect(day.raw, expected);
  });
}

/// The sun's schedule, against what the reference computes.
///
/// The expected times were produced by running the reference's own
/// `data/solar.js` for the fixture day — `prayerTimes({ lat, lon, tz,
/// method: 'MWL', date: 7 Sep 2026 })` — for the two cities its measured
/// Calendar cells show.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/time/lume_solar.dart';

void main() {
  final DateTime day = DateTime(2026, 9, 7, 16, 41, 32);

  List<String> schedule(String country, String city, double offset) {
    final (double lat, double lon) = LumeSolar.coordsFor(country, city)!;
    return <String>[
      for (final LumeSolarTime t in LumeSolar.prayerTimes(
        date: day,
        lat: lat,
        lon: lon,
        offsetHours: offset,
      ))
        t.toString(),
    ];
  }

  test('Islamabad, as the reference computes it', () {
    expect(schedule('PK', 'Islamabad', 5), <String>[
      'fajr 04:20',
      'sunrise 05:45',
      'dhuhr 12:07',
      'asr 15:41',
      'maghrib 18:27',
      'isha 19:47',
    ]);
  });

  test('London, in summer time, as the reference computes it', () {
    expect(schedule('GB', 'London', 1), <String>[
      'fajr 04:21',
      'sunrise 06:22',
      'dhuhr 13:00',
      'asr 16:36',
      'maghrib 19:35',
      'isha 21:28',
    ]);
  });

  test('the next prayer after 16:41 is Maghrib in both', () {
    for (final (String country, String city, double offset, String next)
        in <(String, String, double, String)>[
          ('PK', 'Islamabad', 5, 'maghrib 18:27'),
          ('GB', 'London', 1, 'maghrib 19:35'),
        ]) {
      final (double lat, double lon) = LumeSolar.coordsFor(country, city)!;
      final List<LumeSolarTime> list = LumeSolar.prayerTimes(
        date: day,
        lat: lat,
        lon: lon,
        offsetHours: offset,
      );
      expect(
        LumeSolar.nextPrayer(list, 16 * 60 + 41 + 32 / 60).toString(),
        next,
      );
    }
  });

  test('after Isha, the next prayer is the first of the day', () {
    final List<LumeSolarTime> list = LumeSolar.prayerTimes(
      date: day,
      lat: 33.69,
      lon: 73.05,
      offsetHours: 5,
    );
    expect(LumeSolar.nextPrayer(list, 23 * 60).key, 'fajr');
  });

  test('a city the table does not carry has no coordinates, not a guess', () {
    expect(LumeSolar.coordsFor('PK', 'Nowhere'), isNull);
  });

  test('inside the Arctic summer the reference fallbacks still give a day', () {
    final List<LumeSolarTime> list = LumeSolar.prayerTimes(
      date: DateTime(2026, 6, 21),
      lat: 78.2,
      lon: 15.6,
      offsetHours: 2,
    );
    expect(list, hasLength(6));
    expect(list.map((LumeSolarTime t) => t.key), <String>[
      'fajr',
      'sunrise',
      'dhuhr',
      'asr',
      'maghrib',
      'isha',
    ]);
  });
}

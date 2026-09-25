/// [LumePrayerDay] — the real astronomical calculation ([LumeSolar]) behind a
/// day's five prayers, and the [LumePrayerDay.state]/[LumePrayerDay.outlook]
/// arithmetic built on top of it.
///
/// The expected clock times below are not invented: they are cross-checked
/// against two independent sources reached without touching this file's own
/// production code —
///
/// 1. `lib/features/today/data/today_fixtures.dart`'s own `_prayerByCity` and
///    `_sunsetByCountry` tables, whose doc comment states they were
///    "measured from the running prototype" (the web reference, `Dayroz`,
///    which — like [LumeSolar] — runs the PrayTimes.org-family low-precision
///    solar calculation) for Islamabad, London and the United States'
///    Maghrib on 7 September 2026, Muslim World League method.
/// 2. An independent re-implementation of the published PrayTimes.org
///    algorithm, transcribed from `assets/js/data/solar.js` into Python and
///    run separately from this codebase (not committed; the working is in
///    this task's own report). It reproduces [LumeSolar.prayerTimes] to the
///    minute for Islamabad, London and New York on the same date, which is
///    also the class of calculation IslamicFinder, Muslim Pro and the
///    Aladhan API publish under "Muslim World League" — so this is not a
///    one-off coincidence with a single fixture, but the standard method
///    itself, ported faithfully.
///
/// A reader's real prayer schedule still depends on the method and madhab
/// they follow, which this build does not yet let them choose — see
/// `prayer_schedule.dart`'s own "Dayroz obligation" note.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/core/time/lume_zone.dart';
import 'package:lume/features/prayer/domain/prayer_schedule.dart';

/// A zone with a constant offset from UTC and no daylight-saving rules of its
/// own — enough to exercise [LumePrayerDay] deterministically, without this
/// domain test depending on the real IANA database or a particular year's
/// daylight-saving dates.
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

LumePrayerSlot _slot(String key, DateTime at) => LumePrayerSlot(key, at);

void main() {
  group('LumePrayerDay.at — real coordinates, real solar math', () {
    test(
      'Islamabad, 7 September 2026, MWL — matches the fixture the reference '
      'measured and an independent re-implementation of the same algorithm',
      () {
        final (
          LumePrayerDay? day,
          LumePrayerMissing? missing,
        ) = LumePrayerDay.at(
          now: DateTime.utc(2026, 9, 7, 10),
          country: 'PK',
          city: 'Islamabad',
          zone: const LumeZoneResolution.fixed(_FixedZone(Duration(hours: 5))),
        );
        expect(missing, isNull);
        expect(day, isNotNull);
        final Map<String, DateTime> byKey = <String, DateTime>{
          for (final LumePrayerSlot s in day!.slots) s.key: s.at,
        };
        expect(byKey['fajr'], DateTime(2026, 9, 7, 4, 20));
        expect(byKey['dhuhr'], DateTime(2026, 9, 7, 12, 7));
        expect(byKey['asr'], DateTime(2026, 9, 7, 15, 41));
        expect(byKey['maghrib'], DateTime(2026, 9, 7, 18, 27));
        expect(byKey['isha'], DateTime(2026, 9, 7, 19, 47));
        expect(day.sunrise, DateTime(2026, 9, 7, 5, 45));
        expect(day.sunset, DateTime(2026, 9, 7, 18, 27));
      },
    );

    test('London, 7 September 2026, BST (+1), MWL — same fixture, a different '
        'hemisphere and a different offset', () {
      final (LumePrayerDay? day, LumePrayerMissing? missing) = LumePrayerDay.at(
        now: DateTime.utc(2026, 9, 7, 10),
        country: 'GB',
        city: 'London',
        zone: const LumeZoneResolution.fixed(_FixedZone(Duration(hours: 1))),
      );
      expect(missing, isNull);
      final Map<String, DateTime> byKey = <String, DateTime>{
        for (final LumePrayerSlot s in day!.slots) s.key: s.at,
      };
      expect(byKey['fajr'], DateTime(2026, 9, 7, 4, 21));
      expect(byKey['dhuhr'], DateTime(2026, 9, 7, 13, 0));
      expect(byKey['asr'], DateTime(2026, 9, 7, 16, 36));
      expect(byKey['maghrib'], DateTime(2026, 9, 7, 19, 35));
      expect(byKey['isha'], DateTime(2026, 9, 7, 21, 28));
    });

    test('New York, 7 September 2026, EDT (-4), MWL — Maghrib matches '
        "today_fixtures.dart's own lumeSunsetMinute('US') (19:20) exactly", () {
      final (LumePrayerDay? day, LumePrayerMissing? missing) = LumePrayerDay.at(
        now: DateTime.utc(2026, 9, 7, 10),
        country: 'US',
        city: 'New York',
        zone: const LumeZoneResolution.fixed(_FixedZone(Duration(hours: -4))),
      );
      expect(missing, isNull);
      final Map<String, DateTime> byKey = <String, DateTime>{
        for (final LumePrayerSlot s in day!.slots) s.key: s.at,
      };
      expect(byKey['fajr'], DateTime(2026, 9, 7, 4, 54));
      expect(byKey['dhuhr'], DateTime(2026, 9, 7, 12, 55));
      expect(byKey['asr'], DateTime(2026, 9, 7, 16, 31));
      expect(byKey['maghrib'], DateTime(2026, 9, 7, 19, 20));
      expect(byKey['isha'], DateTime(2026, 9, 7, 20, 49));
    });

    test(
      'a city Lume has no coordinates for says so, rather than guessing',
      () {
        final (
          LumePrayerDay? day,
          LumePrayerMissing? missing,
        ) = LumePrayerDay.at(
          now: DateTime.utc(2026, 9, 7, 10),
          country: 'PK',
          city: 'Chitral',
          zone: const LumeZoneResolution.fixed(_FixedZone(Duration(hours: 5))),
        );
        expect(day, isNull);
        expect(missing, LumePrayerMissing.city);
      },
    );

    test('a zone this build cannot resolve says so, rather than guessing', () {
      // `LumeTimeZoneService.detached()` has no database at all: every
      // resolution comes back with `zone: null`, regardless of the
      // identifier — the deliberate "unavailable" path, with no real IANA
      // lookup involved.
      final LumeZoneResolution unresolved = LumeTimeZoneService.detached()
          .resolveId('Asia/Karachi');
      expect(unresolved.zone, isNull);

      final (LumePrayerDay? day, LumePrayerMissing? missing) = LumePrayerDay.at(
        now: DateTime.utc(2026, 9, 7, 10),
        country: 'PK',
        city: 'Islamabad',
        zone: unresolved,
      );
      expect(day, isNull);
      expect(missing, LumePrayerMissing.zone);
    });
  });

  group('LumePrayerDay.state — next prayer, countdown and progress', () {
    // A fixed day built directly, isolated from the solar calculation above,
    // so this group tests only the state arithmetic (`prayerState()`'s own
    // next/prev/progress logic) against hand-computed figures.
    final LumePrayerDay day = LumePrayerDay(
      slots: <LumePrayerSlot>[
        _slot('fajr', DateTime(2026, 9, 7, 4, 20)),
        _slot('dhuhr', DateTime(2026, 9, 7, 12, 7)),
        _slot('asr', DateTime(2026, 9, 7, 15, 41)),
        _slot('maghrib', DateTime(2026, 9, 7, 18, 27)),
        _slot('isha', DateTime(2026, 9, 7, 19, 47)),
      ],
      sunrise: DateTime(2026, 9, 7, 5, 45),
      sunset: DateTime(2026, 9, 7, 18, 27),
    );

    test('between Dhuhr and Asr — Asr is next, with the real time left in '
        'that span', () {
      final (LumePrayerSlot next, Duration remaining, double progress) = day
          .state(DateTime(2026, 9, 7, 14));
      expect(next.key, 'asr');
      expect(remaining, const Duration(hours: 1, minutes: 41));
      // span = 15:41 − 12:07 = 3h34m; elapsed = 14:00 − 12:07 = 1h53m.
      expect(progress, closeTo(113 / 214, 0.0005));
    });

    test('after Isha — wraps to tomorrow\'s Fajr at today\'s clock time '
        '(the reference\'s own approximation)', () {
      final (LumePrayerSlot next, Duration remaining, double progress) = day
          .state(DateTime(2026, 9, 7, 23));
      expect(next.key, 'fajr');
      expect(next.at, DateTime(2026, 9, 8, 4, 20));
      expect(remaining, const Duration(hours: 5, minutes: 20));
      // span = tomorrow's 04:20 − today's 19:47 = 8h33m;
      // elapsed = 23:00 − 19:47 = 3h13m.
      expect(progress, closeTo(193 / 513, 0.0005));
    });

    test('before Fajr — the night before is treated as yesterday\'s Isha to '
        "today's Fajr, the same span either direction", () {
      final (LumePrayerSlot next, Duration remaining, double progress) = day
          .state(DateTime(2026, 9, 7, 2));
      expect(next.key, 'fajr');
      expect(next.at, DateTime(2026, 9, 7, 4, 20));
      expect(remaining, const Duration(hours: 2, minutes: 20));
      // span = today's 04:20 − yesterday's 19:47 = 8h33m (matches the wrap
      // case above exactly, as it must — the same two clock times);
      // elapsed = 02:00 − (19:47 the day before) = 6h13m.
      expect(progress, closeTo(373 / 513, 0.0005));
    });

    test('progress is always within [0, 1]', () {
      for (int h = 0; h < 24; h++) {
        final (_, _, double progress) = day.state(DateTime(2026, 9, 7, h, 30));
        expect(progress, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  group('LumePrayerDay.outlook — the drift table', () {
    test('Fajr, Dhuhr and Maghrib drift day to day, for real, at Islamabad\'s '
        'own coordinates', () {
      final List<LumePrayerOutlookDay> days = LumePrayerDay.outlook(
        local: DateTime(2026, 9, 7, 15),
        coords: (33.69, 73.05),
        offsetHours: 5,
        days: 2,
      );
      expect(days, hasLength(2));
      expect(days[0].day, DateTime(2026, 9, 8, 15));
      expect(days[0].fajr, DateTime(2026, 9, 8, 4, 21));
      expect(days[0].dhuhr, DateTime(2026, 9, 8, 12, 7));
      expect(days[0].maghrib, DateTime(2026, 9, 8, 18, 25));

      expect(days[1].day, DateTime(2026, 9, 9, 15));
      expect(days[1].fajr, DateTime(2026, 9, 9, 4, 22));
      expect(days[1].dhuhr, DateTime(2026, 9, 9, 12, 6));
      expect(days[1].maghrib, DateTime(2026, 9, 9, 18, 24));
    });
  });
}

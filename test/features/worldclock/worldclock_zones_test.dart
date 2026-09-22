/// World Clock's arithmetic, against the IANA database and nothing else.
///
/// Every instant here is written as UTC and every expectation is a figure
/// that can be checked against the tz database by hand. No test reads the
/// wall clock, and none of them builds a widget.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/core/time/lume_zone.dart';
import 'package:lume/features/worldclock/presentation/worldclock_tool.dart';
import 'package:lume/l10n/app_localizations.dart';
import 'package:lume/l10n/app_localizations_en.dart';

/// 16:41:32 in Karachi on Monday 7 September 2026 — the fixture instant, said
/// as the moment it is rather than as a device's local fields.
final DateTime kAt = DateTime.utc(2026, 9, 7, 11, 41, 32);

final LumeTimeZoneService service = LumeTimeZoneService.shared;

final AppLocalizations l = AppLocalizationsEn();

const LumeFormatting f = LumeFormatting(locale: Locale('en'));

LumeZone zone(String id) {
  final LumeZone? z = service.resolveId(id).zone;
  if (z == null) throw StateError('$id did not resolve');
  return z;
}

/// The offset of [id] from Karachi at [instant].
Duration offsetFrom(String id, {String from = 'Asia/Karachi', DateTime? at}) {
  final DateTime instant = at ?? kAt;
  return zone(id).offsetAt(instant) - zone(from).offsetAt(instant);
}

/// The place's day against the reader's at [instant].
int shift(String id, {String from = 'Asia/Karachi', DateTime? at}) {
  final DateTime instant = at ?? kAt;
  return LumeWorldClock.dayShift(
    zone(from).wallClockAt(instant),
    zone(id).wallClockAt(instant),
  );
}

String hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

void main() {
  // The date formats a day label falls back on; a widget test gets these
  // from the localization delegate, and this one asks for them itself.
  setUpAll(() => initializeDateFormatting());

  group('identifiers', () {
    test('a canonical zone resolves as itself', () {
      final LumeZoneResolution r = service.resolveId('Asia/Karachi');
      expect(r.outcome, LumeZoneOutcome.canonical);
      expect(r.canonicalId, 'Asia/Karachi');
      expect(r.requested, 'Asia/Karachi');
    });

    test('an alias resolves to its canonical zone and is not rewritten', () {
      for (final (String stored, String canonical) in <(String, String)>[
        ('Asia/Calcutta', 'Asia/Kolkata'),
        ('Europe/Kiev', 'Europe/Kyiv'),
        ('US/Eastern', 'America/New_York'),
      ]) {
        final LumeZoneResolution r = service.resolveId(stored);
        expect(r.outcome, LumeZoneOutcome.alias, reason: stored);
        expect(r.canonicalId, canonical);
        // The read leaves the stored identifier exactly as it found it.
        expect(r.requested, stored);
        expect(LumeClockPlace(stored, r).isAlias, isTrue);
        expect(LumeClockPlace(stored, r).id, canonical);
        // And it is the same moment through either name.
        expect(zone(stored).wallClockAt(kAt), zone(canonical).wallClockAt(kAt));
      }
    });

    test('UTC is a zone, and its offset is zero', () {
      final LumeZoneResolution r = service.resolveId('UTC');
      expect(r.resolved, isTrue);
      expect(r.zone!.offsetAt(kAt), Duration.zero);
      expect(hm(r.zone!.wallClockAt(kAt)), '11:41');
    });

    test('a malformed value is said, not resolved', () {
      for (final String bad in <String>[
        'PKT',
        'EST',
        '+05:00',
        'UTC+5',
        'Etc/GMT+5',
        '',
        'not a zone',
      ]) {
        final LumeZoneResolution r = service.resolveId(bad);
        expect(r.outcome, LumeZoneOutcome.malformed, reason: bad);
        expect(
          LumeWorldClock.troubleOf(r.outcome),
          LumeClockTrouble.zoneUnknown,
        );
        expect(r.zone, isNull);
      }
    });

    test('an unknown identifier is said, not substituted', () {
      final LumeZoneResolution r = service.resolveId('Asia/Atlantis');
      expect(r.outcome, LumeZoneOutcome.unknown);
      expect(r.requested, 'Asia/Atlantis');
      expect(r.zone, isNull);
      expect(LumeWorldClock.troubleOf(r.outcome), LumeClockTrouble.zoneUnknown);
    });

    test('with no database, nothing is worked out', () {
      final LumeTimeZoneService detached = LumeTimeZoneService.detached();
      final LumeZoneResolution r = detached.resolveId('Asia/Karachi');
      expect(r.outcome, LumeZoneOutcome.databaseUnavailable);
      expect(r.zone, isNull);
      expect(LumeWorldClock.troubleOf(r.outcome), LumeClockTrouble.database);
      expect(
        LumeWorldClock.read(
          service: detached,
          instant: kAt,
          reader: zone('Asia/Karachi'),
          place: LumeClockPlace('Asia/Dubai', r),
        ),
        isNull,
      );
    });

    test('a device that has not said where it is, and a country that has '
        'several zones, are each their own state', () {
      expect(
        LumeWorldClock.troubleOf(LumeZoneOutcome.missingDevice),
        LumeClockTrouble.device,
      );
      expect(
        LumeWorldClock.troubleOf(LumeZoneOutcome.selectionRequired),
        LumeClockTrouble.choose,
      );
      expect(
        LumeWorldClock.troubleOf(LumeZoneOutcome.conversionFailed),
        LumeClockTrouble.database,
      );
    });
  });

  group('offsets, exact to the minute', () {
    test('the half and three-quarter hours the reference rounds away', () {
      // The reference rounds each of these to a whole hour (defect 7).
      expect(offsetFrom('Asia/Kolkata'), const Duration(minutes: 30));
      expect(offsetFrom('Asia/Kathmandu'), const Duration(minutes: 45));
      expect(
        offsetFrom('Australia/Eucla'),
        const Duration(hours: 3, minutes: 45),
      );
      // Iran left daylight saving in 2022 and sits at +03:30.
      expect(offsetFrom('Asia/Tehran'), const Duration(minutes: -90));
      expect(
        // Chatham is +12:45 until its own summer time begins.
        offsetFrom('Pacific/Chatham'),
        const Duration(hours: 7, minutes: 45),
      );
    });

    test('they are written with their minutes', () {
      expect(
        LumeWorldClock.duration(f, const Duration(minutes: 30)),
        '\u20680:30\u2069',
      );
      expect(
        LumeWorldClock.duration(f, const Duration(minutes: 45)),
        '\u20680:45\u2069',
      );
      expect(
        LumeWorldClock.duration(f, const Duration(hours: 5, minutes: 30)),
        '\u20685:30\u2069',
      );
      expect(
        LumeWorldClock.duration(f, const Duration(hours: -4)),
        '\u20684:00\u2069',
      );
    });

    test('the direction is said with the figure, never after it', () {
      expect(
        LumeWorldClock.offsetLabel(l, f, const Duration(minutes: 30)),
        l.clockAhead('\u20680:30\u2069'),
      );
      expect(
        LumeWorldClock.offsetLabel(l, f, const Duration(hours: -9)),
        l.clockBehind('\u20689:00\u2069'),
      );
    });

    test('"Same time" is a difference of zero, never a failure', () {
      expect(LumeWorldClock.offsetLabel(l, f, Duration.zero), l.clockSameTime);
      expect(offsetFrom('Asia/Karachi'), Duration.zero);
      // Two zones that agree today are still two zones.
      expect(offsetFrom('Asia/Tashkent'), Duration.zero);
    });

    test('the reference\'s own eight, from Karachi', () {
      expect(offsetFrom('Asia/Dubai'), const Duration(hours: -1));
      expect(offsetFrom('Europe/London'), const Duration(hours: -4));
      expect(offsetFrom('America/New_York'), const Duration(hours: -9));
      expect(offsetFrom('Asia/Tokyo'), const Duration(hours: 4));
      expect(offsetFrom('Asia/Singapore'), const Duration(hours: 3));
      expect(offsetFrom('Europe/Istanbul'), const Duration(hours: -2));
      expect(offsetFrom('Australia/Sydney'), const Duration(hours: 5));
    });
  });

  group('which day it is there', () {
    test('yesterday, today and tomorrow', () {
      expect(shift('Asia/Dubai'), 0);
      expect(shift('Pacific/Kiritimati'), 1);
      // 02:00 in Karachi on the 7th is 11:00 in Honolulu on the 6th.
      final DateTime early = DateTime.utc(2026, 9, 6, 21);
      expect(hm(zone('Asia/Karachi').wallClockAt(early)), '02:00');
      expect(shift('Pacific/Honolulu', at: early), -1);
      expect(
        LumeWorldClock.dayLabel(l, f, -1, DateTime(2026, 9, 6)),
        l.clockYesterday,
      );
      expect(
        LumeWorldClock.dayLabel(l, f, 0, DateTime(2026, 9, 7)),
        l.clockToday,
      );
      expect(
        LumeWorldClock.dayLabel(l, f, 1, DateTime(2026, 9, 8)),
        l.clockTomorrow,
      );
    });

    test('across the date line, two days apart, the date is shown', () {
      // 23:30 on Midway is already half past midnight two days later on
      // Kiritimati: no word for that, so the date itself is said.
      final DateTime at = DateTime.utc(2026, 9, 8, 10, 30);
      expect(hm(zone('Pacific/Midway').wallClockAt(at)), '23:30');
      expect(hm(zone('Pacific/Kiritimati').wallClockAt(at)), '00:30');
      final int d = shift('Pacific/Kiritimati', from: 'Pacific/Midway', at: at);
      expect(d, 2);
      // Neither yesterday nor tomorrow: a word that would be wrong is not
      // said, and the date is.
      expect(
        LumeWorldClock.dayLabel(l, f, d, DateTime(2026, 9, 10)),
        isNot(anyOf(l.clockToday, l.clockYesterday, l.clockTomorrow)),
      );
      // …and the other way round.
      expect(shift('Pacific/Midway', from: 'Pacific/Kiritimati', at: at), -2);
    });

    test('a leap day is a day', () {
      // 01:00 on 1 March in Karachi is still 10:00 on 29 February in
      // Honolulu.
      final DateTime at = DateTime.utc(2024, 2, 29, 20);
      expect(zone('Asia/Karachi').wallClockAt(at).day, 1);
      expect(zone('Asia/Karachi').wallClockAt(at).month, 3);
      expect(zone('Pacific/Honolulu').wallClockAt(at).day, 29);
      expect(zone('Pacific/Honolulu').wallClockAt(at).month, 2);
      expect(shift('Pacific/Honolulu', at: at), -1);
    });

    test('a year boundary is a day', () {
      final DateTime at = DateTime.utc(2025, 12, 31, 20);
      expect(zone('Asia/Karachi').wallClockAt(at).year, 2026);
      expect(zone('America/New_York').wallClockAt(at).year, 2025);
      expect(shift('America/New_York', at: at), -1);
    });
  });

  group("New York's two transitions in 2026", () {
    final LumeZone ny = zone('America/New_York');

    test('the clocks go forward on 8 March', () {
      // 06:59 UTC is 01:59 EST; one minute later it is 03:00 EDT.
      expect(hm(ny.wallClockAt(DateTime.utc(2026, 3, 8, 6, 59))), '01:59');
      expect(hm(ny.wallClockAt(DateTime.utc(2026, 3, 8, 7))), '03:00');
      expect(
        ny.offsetAt(DateTime.utc(2026, 3, 8, 6, 59)),
        const Duration(hours: -5),
      );
      expect(
        ny.offsetAt(DateTime.utc(2026, 3, 8, 7)),
        const Duration(hours: -4),
      );
      expect(
        offsetFrom('America/New_York', at: DateTime.utc(2026, 1, 15)),
        const Duration(hours: -10),
      );
    });

    test('the skipped local hour is not invented', () {
      // 02:30 never happens on 8 March. Converting to it lands on the
      // instant after the jump — 03:30 — rather than on an hour the zone
      // never showed.
      final DateTime instant = LumeWorldClock.instantOf(
        DateTime(2026, 3, 8, 2, 30),
        ny,
      );
      expect(instant, DateTime.utc(2026, 3, 8, 7, 30));
      expect(hm(ny.wallClockAt(instant)), '03:30');
    });

    test('the clocks go back on 1 November', () {
      expect(hm(ny.wallClockAt(DateTime.utc(2026, 11, 1, 5, 59))), '01:59');
      expect(hm(ny.wallClockAt(DateTime.utc(2026, 11, 1, 6))), '01:00');
    });

    test('the repeated local hour takes the first of the two', () {
      // 01:30 happens twice on 1 November: 05:30 UTC on the summer offset
      // and 06:30 UTC on the standard one. The first is taken.
      expect(hm(ny.wallClockAt(DateTime.utc(2026, 11, 1, 5, 30))), '01:30');
      expect(hm(ny.wallClockAt(DateTime.utc(2026, 11, 1, 6, 30))), '01:30');
      expect(
        LumeWorldClock.instantOf(DateTime(2026, 11, 1, 1, 30), ny),
        DateTime.utc(2026, 11, 1, 5, 30),
      );
    });

    test('an ordinary hour converts back to itself', () {
      for (final DateTime wall in <DateTime>[
        DateTime(2026, 9, 7, 16, 41),
        DateTime(2026, 3, 8, 4, 30),
        DateTime(2026, 11, 1, 9),
        DateTime(2026, 1, 1),
      ]) {
        final DateTime instant = LumeWorldClock.instantOf(wall, ny);
        expect(hm(ny.wallClockAt(instant)), hm(wall), reason: '$wall');
      }
    });

    test('summer time is the zone\'s own, in either hemisphere', () {
      expect(LumeWorldClock.summerTime(zone('Europe/London'), kAt), isTrue);
      expect(
        LumeWorldClock.summerTime(
          zone('Europe/London'),
          DateTime.utc(2026, 1, 15),
        ),
        isFalse,
      );
      expect(LumeWorldClock.summerTime(zone('America/New_York'), kAt), isTrue);
      expect(LumeWorldClock.summerTime(zone('Asia/Karachi'), kAt), isFalse);
      expect(LumeWorldClock.summerTime(zone('Asia/Kolkata'), kAt), isFalse);
      expect(
        LumeWorldClock.summerTime(
          zone('Australia/Sydney'),
          DateTime.utc(2026, 1, 15),
        ),
        isTrue,
      );
    });
  });

  group('the minute tick', () {
    test('it waits exactly as long as the minute has left', () {
      expect(
        LumeWorldClock.untilNextMinute(DateTime.utc(2026, 9, 7, 11, 41, 32)),
        const Duration(seconds: 28),
      );
      expect(
        LumeWorldClock.untilNextMinute(
          DateTime.utc(2026, 9, 7, 11, 41, 59, 999),
        ),
        const Duration(milliseconds: 1),
      );
      expect(
        LumeWorldClock.untilNextMinute(DateTime.utc(2026, 9, 7, 11, 41)),
        const Duration(minutes: 1),
      );
    });

    test('a thousand ticks accumulate no drift', () {
      DateTime t = DateTime.utc(2026, 9, 7, 11, 41, 32, 500);
      for (int i = 0; i < 1000; i++) {
        t = t.add(LumeWorldClock.untilNextMinute(t));
        expect(t.second, 0, reason: 'tick $i');
        expect(t.millisecond, 0, reason: 'tick $i');
        expect(t.microsecond, 0, reason: 'tick $i');
      }
      // 1000 minutes after the first boundary, to the microsecond.
      expect(
        t,
        DateTime.utc(2026, 9, 7, 11, 42).add(const Duration(minutes: 999)),
      );
    });

    test('a late tick shortens the next wait instead of pushing it out', () {
      DateTime t = DateTime.utc(2026, 9, 7, 11, 41, 32);
      for (int i = 0; i < 500; i++) {
        // Every tick arrives 3.4 seconds late, as a busy frame would.
        t = t
            .add(LumeWorldClock.untilNextMinute(t))
            .add(const Duration(milliseconds: 3400));
      }
      // Still inside the minute it belongs to — never a minute behind.
      expect(t.second, 3);
      expect(t, DateTime.utc(2026, 9, 7, 20, 1, 3, 400));
    });
  });

  group('the list', () {
    test('it seeds with the reference\'s eight, less the reader\'s own', () {
      expect(LumeWorldClock.seed('Asia/Karachi'), <String>[
        'Asia/Dubai',
        'Europe/London',
        'America/New_York',
        'Asia/Tokyo',
        'Asia/Singapore',
        'Europe/Istanbul',
        'Australia/Sydney',
      ]);
      expect(LumeWorldClock.seed('Europe/Paris').length, 8);
    });

    test('it is read and written as identifiers, and nothing else', () {
      expect(LumeWorldClock.parse('Asia/Dubai,Europe/London'), <String>[
        'Asia/Dubai',
        'Europe/London',
      ]);
      expect(LumeWorldClock.parse(''), isEmpty);
      expect(LumeWorldClock.parse(null), isEmpty);
      expect(
        LumeWorldClock.encode(<String>['Asia/Dubai', 'UTC']),
        'Asia/Dubai,UTC',
      );
    });

    test('a zone is held once, under any of its names', () {
      const List<String> ids = <String>['Asia/Kolkata', 'Europe/London'];
      expect(LumeWorldClock.holds(ids, 'Asia/Kolkata'), isTrue);
      expect(LumeWorldClock.holds(ids, 'Asia/Calcutta'), isTrue);
      expect(LumeWorldClock.holds(ids, 'Asia/Karachi'), isFalse);
    });

    test('ordering moves one place and never off the end', () {
      const List<String> ids = <String>['a', 'b', 'c'];
      expect(LumeWorldClock.move(ids, 1, -1), <String>['b', 'a', 'c']);
      expect(LumeWorldClock.move(ids, 1, 1), <String>['a', 'c', 'b']);
      expect(LumeWorldClock.move(ids, 0, -1), ids);
      expect(LumeWorldClock.move(ids, 2, 1), ids);
      expect(LumeWorldClock.move(ids, 9, 1), ids);
    });

    test('search reaches a zone by its label or its identifier', () {
      List<String> found(String q) => <String>[
        for (final LumeClockChoice c in LumeWorldClock.choices(
          query: q,
          language: 'en',
        ))
          c.zone,
      ];
      expect(found('new york'), contains('America/New_York'));
      expect(found('America/New_York'), contains('America/New_York'));
      expect(found('america/new_york'), contains('America/New_York'));
      expect(found('pakistan'), contains('Asia/Karachi'));
      expect(found('nowhere at all'), isEmpty);
    });

    test('the clock preference is read, and auto leaves the market\'s', () {
      expect(LumeWorldClock.hour12('12'), isTrue);
      expect(LumeWorldClock.hour12('24'), isFalse);
      expect(LumeWorldClock.hour12('auto'), isNull);
    });
  });

  group('one reading', () {
    test('it carries the time, the offset, the day and the season', () {
      final LumeClockReading? r = LumeWorldClock.read(
        service: service,
        instant: kAt,
        reader: zone('Asia/Karachi'),
        place: LumeClockPlace(
          'Europe/London',
          service.resolveId('Europe/London'),
        ),
      );
      expect(r, isNotNull);
      expect(hm(r!.local), '12:41');
      expect(r.offset, const Duration(hours: -4));
      expect(r.dayShift, 0);
      expect(r.summer, isTrue);
    });

    test('an alias reads the same moment as the zone it names', () {
      final LumeClockReading? a = LumeWorldClock.read(
        service: service,
        instant: kAt,
        reader: zone('Asia/Karachi'),
        place: LumeClockPlace(
          'Asia/Calcutta',
          service.resolveId('Asia/Calcutta'),
        ),
      );
      expect(a!.local, zone('Asia/Kolkata').wallClockAt(kAt));
      expect(a.offset, const Duration(minutes: 30));
      expect(a.place.isAlias, isTrue);
      expect(a.place.stored, 'Asia/Calcutta');
      expect(a.place.id, 'Asia/Kolkata');
    });

    test('a place that cannot be read is not read as another', () {
      expect(
        LumeWorldClock.read(
          service: service,
          instant: kAt,
          reader: zone('Asia/Karachi'),
          place: LumeClockPlace(
            'Asia/Atlantis',
            service.resolveId('Asia/Atlantis'),
          ),
        ),
        isNull,
      );
    });
  });
}

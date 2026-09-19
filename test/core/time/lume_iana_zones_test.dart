/// The IANA time-zone service: loaded once, typed outcomes, aliases kept
/// apart from labels, migration planned and never applied by a read.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/core/time/lume_zone.dart';
import 'package:lume/core/time/lume_zone_aliases.dart';
import 'package:timezone/timezone.dart' as tz;

class _Broken implements LumeZone {
  @override
  String get id => 'Test/Broken';
  @override
  Duration offsetAt(DateTime instant) => throw StateError('broken');
  @override
  DateTime wallClockAt(DateTime instant) => throw StateError('broken');
}

void main() {
  final LumeTimeZoneService zones = LumeTimeZoneService.shared;

  group('the database', () {
    test('is loaded once and shared', () {
      expect(identical(LumeTimeZoneService.shared, zones), isTrue);
      expect(tz.timeZoneDatabase.isInitialized, isTrue);
      expect(LumeTimeZoneService.databaseVersion, '2025c');
    });

    test('the generated tables match the bundled data exactly', () {
      final Set<String> all = tz.timeZoneDatabase.locations.keys.toSet();
      // Every identifier is either canonical or an alias; nothing else.
      expect(
        all
            .difference(kLumeCanonicalZones)
            .difference(kLumeZoneAliases.keys.toSet()),
        isEmpty,
      );
      expect(kLumeCanonicalZones.difference(all), isEmpty);
      expect(kLumeZoneAliases.keys.toSet().difference(all), isEmpty);
      // An alias names a canonical zone, never another alias.
      expect(
        kLumeZoneAliases.values.where(
          (String t) => !kLumeCanonicalZones.contains(t),
        ),
        isEmpty,
      );
      expect(
        kLumeCanonicalZones.intersection(kLumeZoneAliases.keys.toSet()),
        isEmpty,
      );
    });

    test('nothing sets the package\'s local location', () {
      // The package's own "local" stays UTC: every calculation names its zone.
      expect(tz.local.name, anyOf('UTC', 'Etc/UTC'));
    });
  });

  group('typed outcomes', () {
    test('a canonical zone', () {
      final LumeZoneResolution r = zones.resolveId('Asia/Karachi');
      expect(r.outcome, LumeZoneOutcome.canonical);
      expect(r.source, LumeZoneSource.explicit);
      expect(r.canonicalId, 'Asia/Karachi');
      expect(r.resolved, isTrue);
    });

    test('a deprecated alias: resolved through its canonical zone, the '
        'identifier asked for kept', () {
      final LumeZoneResolution r = zones.resolveId('Europe/Kiev');
      expect(r.outcome, LumeZoneOutcome.alias);
      expect(r.source, LumeZoneSource.migratedAlias);
      expect(r.requested, 'Europe/Kiev');
      expect(r.canonicalId, 'Europe/Kyiv');
      expect(r.zone!.id, 'Europe/Kyiv');
      for (final DateTime t in <DateTime>[
        DateTime.utc(2026, 1, 15, 12),
        DateTime.utc(2026, 3, 29, 0, 30),
        DateTime.utc(2026, 3, 29, 1, 30),
        DateTime.utc(2026, 10, 25, 0, 30),
        DateTime.utc(1990, 6, 1),
      ]) {
        expect(
          r.zone!.wallClockAt(t),
          zones.resolveId('Europe/Kyiv').zone!.wallClockAt(t),
          reason: '$t',
        );
      }
    });

    for (final String bad in <String>[
      '',
      ' ',
      '+05:00',
      'UTC+5',
      'Etc/GMT+5',
      'PKT',
      'EST',
      'CST',
      'Asia/',
      '/Asia',
      '../etc/passwd',
      'Asia Karachi',
    ]) {
      test('"$bad" is not an identifier', () {
        final LumeZoneResolution r = zones.resolveId(bad);
        expect(r.outcome, LumeZoneOutcome.malformed);
        expect(r.source, LumeZoneSource.unavailable);
        expect(r.requested, bad);
        expect(r.resolved, isFalse);
      });
    }

    test('UTC and GMT are fixed zones, not refused abbreviations', () {
      expect(zones.resolveId('UTC').canonicalId, 'Etc/UTC');
      expect(zones.resolveId('GMT').resolved, isTrue);
    });

    test('an identifier the database does not hold', () {
      final LumeZoneResolution r = zones.resolveId('Mars/Olympus_Mons');
      expect(r.outcome, LumeZoneOutcome.unknown);
      expect(r.requested, 'Mars/Olympus_Mons');
      expect(r.canonicalId, isNull);
    });

    test('no database', () {
      final LumeZoneResolution r = LumeTimeZoneService.detached().resolveId(
        'Asia/Karachi',
      );
      expect(r.outcome, LumeZoneOutcome.databaseUnavailable);
      expect(r.source, LumeZoneSource.unavailable);
    });

    test('a conversion that fails says so', () {
      final LumeZoneClock c = zones.clock(
        DateTime.utc(2026),
        LumeZoneResolution.fixed(_Broken()),
      );
      expect(c.ok, isFalse);
      expect(c.failure, LumeZoneOutcome.conversionFailed);
    });
  });

  group('the reader\'s zone', () {
    test(
      'an explicit choice wins, and an unreadable one is never replaced',
      () {
        expect(
          zones
              .reader(explicit: 'Asia/Tokyo', country: 'PK', city: 'Lahore')
              .canonicalId,
          'Asia/Tokyo',
        );
        for (final String bad in <String>['Mars/Olympus_Mons', 'PKT']) {
          final LumeZoneResolution r = zones.reader(
            explicit: bad,
            country: 'PK',
            city: 'Lahore',
            device: const LumeDeviceZone('Asia/Karachi'),
          );
          expect(r.resolved, isFalse, reason: bad);
          expect(r.requested, bad);
        }
      },
    );

    test('the device\'s zone only under "Follow this device", and only '
        'verified', () {
      final LumeZoneResolution d = zones.reader(
        follow: LumeZoneFollow.device,
        country: 'PK',
        device: const LumeDeviceZone('Asia/Karachi'),
      );
      expect(d.outcome, LumeZoneOutcome.device);
      expect(d.source, LumeZoneSource.device);
      final LumeZoneResolution none = zones.reader(
        follow: LumeZoneFollow.device,
        country: 'PK',
      );
      expect(none.outcome, LumeZoneOutcome.missingDevice);
      expect(none.resolved, isFalse);
      // Follow region never reads the device, even a verified one.
      expect(
        zones
            .reader(
              country: 'US',
              device: const LumeDeviceZone('America/Denver'),
            )
            .outcome,
        LumeZoneOutcome.selectionRequired,
      );
    });

    test('a second zone reads the same instant, never another', () {
      final DateTime t = DateTime.utc(2026, 9, 7, 20, 30);
      final LumeZoneClock khi = zones.clock(t, zones.resolveId('Asia/Karachi'));
      final LumeZoneClock ny = zones.clock(
        t,
        zones.resolveId('America/New_York'),
      );
      expect(khi.local, DateTime(2026, 9, 8, 1, 30));
      expect(ny.local, DateTime(2026, 9, 7, 16, 30));
      // Back to the instant from either: the same moment.
      DateTime back(LumeZoneClock c) => DateTime.utc(
        c.local!.year,
        c.local!.month,
        c.local!.day,
        c.local!.hour,
        c.local!.minute,
      ).subtract(c.offset!);
      expect(back(khi), t);
      expect(back(ny), t);
    });
  });

  group('migration', () {
    test('an alias is planned to its canonical zone; the instant is kept', () {
      final LumeZoneMigration m = zones.plan('Europe/Kiev');
      expect(m.changes, isTrue);
      expect(m.to, 'Europe/Kyiv');
      final DateTime t = DateTime.utc(2026, 10, 25, 1, 30);
      expect(
        zones.resolveId(m.from).zone!.wallClockAt(t),
        zones.resolveId(m.to!).zone!.wallClockAt(t),
      );
    });

    test('idempotent: a migrated identifier plans no change', () {
      final LumeZoneMigration once = zones.plan('Asia/Calcutta');
      final LumeZoneMigration twice = zones.plan(once.to!);
      expect(once.changes, isTrue);
      expect(twice.changes, isFalse);
      expect(twice.to, once.to);
    });

    test('an unreadable identifier is left as it is', () {
      expect(zones.plan('Mars/Olympus_Mons').to, isNull);
      expect(zones.plan('Mars/Olympus_Mons').changes, isFalse);
      expect(zones.plan('PKT').changes, isFalse);
    });

    test('reading an alias again and again changes nothing', () {
      const String stored = 'Europe/Kiev';
      for (int i = 0; i < 3; i++) {
        final LumeZoneResolution r = zones.resolveId(stored);
        expect(r.requested, stored);
        expect(r.outcome, LumeZoneOutcome.alias);
      }
    });
  });
}

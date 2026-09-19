/// "Follow my region" as the reader's explicit preference: the city's zone,
/// else the country's one civil time, else a zone to choose — never one of
/// several guessed, and never from language, religion or currency.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/time_zone_provider.dart';
import 'package:lume/core/time/lume_city_zones.dart';
import 'package:lume/core/time/lume_country_zones.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/core/time/lume_zone_aliases.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';

void main() {
  final LumeTimeZoneService zones = LumeTimeZoneService.shared;
  const LumeDeviceZone none = LumeDeviceZone.unknown();

  LumeZoneResolution region(String country, [String city = '']) =>
      zones.reader(country: country, city: city);

  group('Follow my region', () {
    test('Pakistan: its one civil time, said as region policy', () {
      final LumeZoneResolution r = region('PK', 'Islamabad');
      expect(r.canonicalId, 'Asia/Karachi');
      expect(r.source, LumeZoneSource.regionPolicy);
      expect(r.outcome, LumeZoneOutcome.canonical);
    });

    for (final String country in <String>['US', 'CA', 'AU', 'RU', 'BR', 'MX']) {
      test('$country with no city: a zone to choose, never one guessed', () {
        final LumeZoneResolution r = region(country);
        expect(r.outcome, LumeZoneOutcome.selectionRequired);
        expect(r.source, LumeZoneSource.unavailable);
        expect(r.resolved, isFalse);
        expect(r.canonicalId, isNull);
        expect(r.requested, isNull);
      });
    }

    test('the United States with New York: New York\'s zone, by city', () {
      final LumeZoneResolution r = region('US', 'New York');
      expect(r.canonicalId, 'America/New_York');
      expect(r.source, LumeZoneSource.cityPolicy);
      expect(region('US', 'Los Angeles').canonicalId, 'America/Los_Angeles');
      expect(region('US', 'Phoenix').canonicalId, 'America/Phoenix');
    });

    test('the United States with New York named as the zone: explicit', () {
      final LumeZoneResolution r = zones.reader(
        explicit: 'America/New_York',
        country: 'US',
      );
      expect(r.canonicalId, 'America/New_York');
      expect(r.source, LumeZoneSource.explicit);
    });

    test('Australia with no city: a zone to choose; with Perth, Perth\'s', () {
      expect(region('AU').outcome, LumeZoneOutcome.selectionRequired);
      expect(region('AU', 'Perth').canonicalId, 'Australia/Perth');
      expect(region('AU', 'Brisbane').canonicalId, 'Australia/Brisbane');
    });

    test('a city the table does not know, in a country with several zones: '
        'a zone to choose', () {
      expect(
        region('US', 'Anchorage').outcome,
        LumeZoneOutcome.selectionRequired,
      );
    });

    test('one civil time under several identifiers is one zone', () {
      // Büsingen keeps Zurich's identifier and Berlin's clock.
      expect(region('DE').canonicalId, 'Europe/Berlin');
      // Kazakhstan's zones have read one clock since 2024.
      expect(region('KZ').outcome, LumeZoneOutcome.canonical);
      expect(region('GB', 'London').canonicalId, 'Europe/London');
    });

    test('an explicit zone overrides the region', () {
      final LumeZoneResolution r = zones.reader(
        explicit: 'Asia/Tokyo',
        country: 'PK',
        city: 'Islamabad',
      );
      expect(r.canonicalId, 'Asia/Tokyo');
      expect(r.source, LumeZoneSource.explicit);
    });

    test('never the device, even a verified one', () {
      final LumeZoneResolution r = zones.reader(
        country: 'US',
        device: const LumeDeviceZone('America/Chicago'),
      );
      expect(r.outcome, LumeZoneOutcome.selectionRequired);
    });
  });

  group('Follow this device', () {
    test('a verified device zone', () {
      final LumeZoneResolution r = zones.reader(
        follow: LumeZoneFollow.device,
        country: 'US',
        device: const LumeDeviceZone('America/Chicago'),
      );
      expect(r.outcome, LumeZoneOutcome.device);
      expect(r.source, LumeZoneSource.device);
      expect(r.canonicalId, 'America/Chicago');
    });

    test('no device-zone capability: missing, not the region\'s', () {
      final LumeZoneResolution r = zones.reader(
        follow: LumeZoneFollow.device,
        country: 'PK',
        city: 'Islamabad',
      );
      expect(r.outcome, LumeZoneOutcome.missingDevice);
      expect(r.resolved, isFalse);
    });
  });

  group('what cannot change the zone', () {
    const LumeProfileRecord base = LumeProfileRecord(
      country: 'US',
      region: 'New York',
      city: 'New York',
      islamic: false,
    );
    final String? want = zones.readerZone(base, none).canonicalId;

    test('the baseline', () => expect(want, 'America/New_York'));

    test('religion', () {
      expect(
        zones.readerZone(base.copyWith(islamic: true), none).canonicalId,
        want,
      );
    });

    test('currency', () {
      for (final String currency in <String>['PKR', 'GBP', 'JPY']) {
        expect(
          zones.readerZone(base.copyWith(currency: currency), none).canonicalId,
          want,
        );
      }
    });

    test('interests and units', () {
      expect(
        zones
            .readerZone(
              base.copyWith(
                interests: <String>['prayer', 'quran'],
                units: LumeUnitsPreference.metric,
              ),
              none,
            )
            .canonicalId,
        want,
      );
    });

    test('a preference, not a default reading of the country: follow-device '
        'on the same profile reads no region at all', () {
      expect(
        zones
            .readerZone(base.copyWith(zoneFollow: LumeZoneFollow.device), none)
            .outcome,
        LumeZoneOutcome.missingDevice,
      );
    });
  });

  group('the tables', () {
    test('every country zone is canonical; every civil zone is one of its '
        'country\'s', () {
      for (final MapEntry<String, List<String>> e
          in kLumeCountryZones.entries) {
        for (final String z in e.value) {
          expect(kLumeCanonicalZones, contains(z), reason: '${e.key} $z');
        }
      }
      for (final MapEntry<String, String> e in kLumeCountryCivilZone.entries) {
        expect(kLumeCountryZones[e.key], contains(e.value), reason: e.key);
      }
    });

    test('the countries with several civil times have none', () {
      for (final String c in <String>['US', 'CA', 'AU', 'RU', 'BR', 'MX']) {
        expect(kLumeCountryCivilZone.containsKey(c), isFalse, reason: c);
      }
      for (final String c in <String>['PK', 'GB', 'AE', 'SA', 'JP', 'IN']) {
        expect(kLumeCountryCivilZone.containsKey(c), isTrue, reason: c);
      }
    });

    test('every city of every several-zone country has a zone of its own '
        'country', () {
      final Map<String, dynamic> table =
          jsonDecode(File('assets/data/countries.json').readAsStringSync())
              as Map<String, dynamic>;
      for (final dynamic c in table['countries'] as List<dynamic>) {
        final String code = (c as Map<String, dynamic>)['code'] as String;
        if (kLumeCountryCivilZone.containsKey(code)) continue;
        for (final dynamic city in c['cities'] as List<dynamic>) {
          final String? z = kLumeCityZones['$code:$city'];
          expect(z, isNotNull, reason: '$code:$city');
          expect(kLumeCountryZones[code], contains(z), reason: '$code:$city');
        }
      }
      for (final MapEntry<String, String> e in kLumeCityZones.entries) {
        final String code = e.key.split(':').first;
        expect(kLumeCountryZones[code], contains(e.value), reason: e.key);
      }
    });

    test('"fixture" is kept for zones a fixture supplies, never a policy', () {
      for (final LumeZoneResolution r in <LumeZoneResolution>[
        region('PK', 'Islamabad'),
        region('US', 'New York'),
      ]) {
        expect(r.source, isNot(LumeZoneSource.fixture));
      }
    });
  });
}

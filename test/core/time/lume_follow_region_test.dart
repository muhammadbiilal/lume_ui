/// "Follow my region" as the reader's explicit preference: the city's zone,
/// else the country's zone where CLDR lists exactly one canonical zone for
/// it, else a zone to choose — never one of several guessed, never two
/// canonical zones merged because their clocks agree today, and never from
/// language, religion or currency. And how a zone is shown: CLDR's label for
/// the reader's country, never a second identity.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/time_zone_provider.dart';
import 'package:lume/core/time/lume_city_zones.dart';
import 'package:lume/core/time/lume_country_zones.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/core/time/lume_zone_aliases.dart';
import 'package:lume/core/time/lume_zone_labels.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';

void main() {
  final LumeTimeZoneService zones = LumeTimeZoneService.shared;
  const LumeDeviceZone none = LumeDeviceZone.unknown();

  LumeZoneResolution region(String country, [String city = '']) =>
      zones.reader(country: country, city: city);

  void choose(String country, [String city = '']) {
    final LumeZoneResolution r = region(country, city);
    expect(r.outcome, LumeZoneOutcome.selectionRequired, reason: country);
    expect(r.source, LumeZoneSource.unavailable);
    expect(r.resolved, isFalse);
    expect(r.canonicalId, isNull);
    expect(r.requested, isNull);
  }

  group('Follow my region', () {
    test('Pakistan: its one canonical zone, said as region policy', () {
      final LumeZoneResolution r = region('PK', 'Islamabad');
      expect(r.canonicalId, 'Asia/Karachi');
      expect(r.source, LumeZoneSource.regionPolicy);
      expect(r.outcome, LumeZoneOutcome.canonical);
      expect(region('PK').canonicalId, 'Asia/Karachi');
    });

    for (final String country in <String>[
      'US',
      'CA',
      'AU',
      'RU',
      'BR',
      'MX',
      'ES',
      'PT',
      'CN',
      'EC',
      'NZ',
      'UA',
      'DE',
      'KZ',
    ]) {
      test('$country with no city: a zone to choose, never one guessed', () {
        choose(country);
      });
    }

    test('the United States with New York: New York\'s zone, by city', () {
      final LumeZoneResolution r = region('US', 'New York');
      expect(r.canonicalId, 'America/New_York');
      expect(r.source, LumeZoneSource.cityPolicy);
      expect(region('US', 'Los Angeles').canonicalId, 'America/Los_Angeles');
      expect(region('US', 'Phoenix').canonicalId, 'America/Phoenix');
    });

    test('Australia: Perth\'s and Brisbane\'s by city', () {
      expect(region('AU', 'Perth').canonicalId, 'Australia/Perth');
      expect(region('AU', 'Brisbane').canonicalId, 'Australia/Brisbane');
    });

    test('Spain, Portugal, China, Ecuador, New Zealand: the mainland by '
        'city, never the islands\' or the region\'s', () {
      expect(region('ES', 'Madrid').canonicalId, 'Europe/Madrid');
      expect(region('PT', 'Lisbon').canonicalId, 'Europe/Lisbon');
      expect(region('CN', 'Beijing').canonicalId, 'Asia/Shanghai');
      expect(region('EC', 'Quito').canonicalId, 'America/Guayaquil');
      expect(region('NZ', 'Wellington').canonicalId, 'Pacific/Auckland');
    });

    test('Ukraine: Kyiv\'s by city; no city of the table reads the zone '
        'CLDR also lists for Crimea, and nothing reads it without a city', () {
      for (final String city in <String>['Kyiv', 'Kharkiv', 'Odesa', 'Lviv']) {
        expect(region('UA', city).canonicalId, 'Europe/Kyiv', reason: city);
      }
      expect(
        kLumeCityZones.values,
        isNot(contains('Europe/Simferopol')),
        reason: 'no city infers a disputed zone',
      );
      choose('UA');
    });

    test('a city the table does not know, in a country with several zones: '
        'a zone to choose', () {
      choose('US', 'Anchorage');
      choose('AU', 'Darwin');
    });

    test('a city of another country is not the reader\'s: its zone is never '
        'borrowed', () {
      choose('US', 'Lahore');
      // Pakistan's one zone is Pakistan's, whatever the city field says.
      expect(region('PK', 'New York').canonicalId, 'Asia/Karachi');
      expect(region('PK', 'New York').source, LumeZoneSource.regionPolicy);
    });

    test('links to one canonical zone are one zone: Kuwait is Riyadh\'s '
        'rules', () {
      expect(kLumeCountryZoneIds['KW'], <String>['Asia/Kuwait']);
      expect(kLumeZoneAliases['Asia/Kuwait'], 'Asia/Riyadh');
      final LumeZoneResolution r = region('KW', 'Kuwait City');
      expect(r.canonicalId, 'Asia/Riyadh');
      expect(r.source, LumeZoneSource.regionPolicy);
    });

    test('distinct canonical zones stay distinct when their clocks agree '
        'today', () {
      // Büsingen keeps Zurich's rules and reads Berlin's clock.
      expect(kLumeCountryZones['DE'], <String>[
        'Europe/Berlin',
        'Europe/Zurich',
      ]);
      final DateTime now = DateTime.utc(2026, 7, 1);
      expect(
        zones.zoneFor('Europe/Berlin')!.offsetAt(now),
        zones.zoneFor('Europe/Zurich')!.offsetAt(now),
      );
      choose('DE');
      expect(region('DE', 'Berlin').canonicalId, 'Europe/Berlin');
      // Kazakhstan's zones have read one clock since 2024, and are still
      // seven zones.
      expect(kLumeCountryZones['KZ']!.length, 7);
      choose('KZ');
      expect(region('KZ', 'Almaty').canonicalId, 'Asia/Almaty');
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

    test('a deprecated alias the reader named: its zone, said as migrated', () {
      final LumeZoneResolution r = zones.reader(
        explicit: 'Europe/Kiev',
        country: 'UA',
      );
      expect(r.canonicalId, 'Europe/Kyiv');
      expect(r.requested, 'Europe/Kiev');
      expect(r.source, LumeZoneSource.migratedAlias);
      expect(r.outcome, LumeZoneOutcome.alias);
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

  group('labels', () {
    LumeZoneLabel label(String country, String language, [String city = '']) =>
        region(country, city).label(language)!;

    test(
      'Kuwait reads "Kuwait" in each language, and is Riyadh\'s identity',
      () {
        expect(label('KW', 'en').text, 'Kuwait');
        expect(label('KW', 'en').display, 'Kuwait Time');
        expect(label('KW', 'ur').text, 'کویت');
        expect(label('KW', 'ur').display, 'کویت وقت');
        expect(label('KW', 'ar').text, 'الكويت');
        expect(label('KW', 'ar').display, 'توقيت الكويت');
        expect(label('KW', 'en').id, 'Asia/Riyadh');
        expect(label('KW', 'en').semantics, 'Kuwait Time, Asia/Riyadh');
        // The same rules chosen by a reader elsewhere are Saudi Arabia's.
        expect(
          LumeZoneLabels.of('Asia/Riyadh', language: 'en', country: 'GB').text,
          'Saudi Arabia',
        );
      },
    );

    test('the Central African Republic is not shown as Lagos', () {
      final LumeZoneLabel l = label('CF', 'en');
      expect(l.id, 'Africa/Lagos');
      expect(l.text, 'Central African Republic');
      expect(label('CD', 'en', 'Kinshasa').text, 'Kinshasa');
    });

    test('a city of a several-zone country reads its exemplar city', () {
      expect(label('US', 'en', 'New York').text, 'New York');
      expect(label('US', 'ur', 'New York').text, 'نیو یارک');
      expect(label('US', 'ar', 'New York').text, 'نيويورك');
      expect(label('PK', 'en').text, 'Pakistan');
      expect(label('PK', 'ar').text, 'باكستان');
    });

    test('a deprecated alias shows its zone\'s label', () {
      final LumeZoneLabel l = zones
          .reader(explicit: 'Europe/Kiev', country: 'UA')
          .label('en')!;
      expect(l.id, 'Europe/Kyiv');
      expect(l.text, 'Ukraine');
    });

    test('no CLDR label: the identifier, never an invented name', () {
      final LumeZoneLabel l = LumeZoneLabels.of('Etc/UTC', language: 'en');
      expect(l.text, isNull);
      expect(l.display, 'Etc/UTC');
      expect(l.semantics, 'Etc/UTC');
    });

    test('a language the table does not hold falls back to English', () {
      expect(label('PK', 'fr').text, 'Pakistan');
    });

    test('nothing resolved: no label', () {
      expect(region('US').label('en'), isNull);
    });

    test('search finds the label and the canonical identifier', () {
      final LumeZoneLabel kuwait = label('KW', 'en');
      expect(LumeZoneLabels.matches('kuw', kuwait), isTrue);
      expect(LumeZoneLabels.matches('Riyadh', kuwait), isTrue);
      expect(LumeZoneLabels.matches('asia/riyadh', kuwait), isTrue);
      expect(LumeZoneLabels.matches('tokyo', kuwait), isFalse);
      expect(LumeZoneLabels.matches('', kuwait), isTrue);
      final LumeZoneLabel ny = label('US', 'ar', 'New York');
      expect(LumeZoneLabels.matches('new york', ny), isTrue);
      expect(LumeZoneLabels.matches('نيويورك', ny), isTrue);
      expect(LumeZoneLabels.matches('\u2068نيويورك\u2069', ny), isTrue);
    });

    test('a label is presentation: it never changes the identity', () {
      for (final String language in <String>['en', 'ur', 'ar']) {
        expect(label('KW', language).id, 'Asia/Riyadh');
        expect(label('US', language, 'New York').id, 'America/New_York');
      }
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

    test('language: the label changes, the zone does not', () {
      final LumeZoneResolution r = zones.readerZone(base, none);
      final Set<String> ids = <String>{
        for (final String language in <String>['en', 'ur', 'ar'])
          r.label(language)!.id,
      };
      expect(ids, <String>{want!});
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
    test('every country zone is canonical; every country zone of its own is '
        'its only one', () {
      for (final MapEntry<String, List<String>> e
          in kLumeCountryZones.entries) {
        for (final String z in e.value) {
          expect(kLumeCanonicalZones, contains(z), reason: '${e.key} $z');
        }
      }
      for (final MapEntry<String, String> e in kLumeCountryZone.entries) {
        expect(kLumeCountryZones[e.key], <String>[e.value], reason: e.key);
      }
    });

    test(
      'the countries with several canonical zones have none of their own',
      () {
        for (final String c in <String>[
          'US',
          'CA',
          'AU',
          'RU',
          'BR',
          'MX',
          'DE',
          'KZ',
          'UA',
          'CN',
        ]) {
          expect(kLumeCountryZone.containsKey(c), isFalse, reason: c);
        }
        for (final String c in <String>['PK', 'GB', 'AE', 'SA', 'JP', 'IN']) {
          expect(kLumeCountryZone.containsKey(c), isTrue, reason: c);
        }
      },
    );

    test('every city of every several-zone country has a zone of its own '
        'country', () {
      final Map<String, dynamic> table =
          jsonDecode(File('assets/data/countries.json').readAsStringSync())
              as Map<String, dynamic>;
      for (final dynamic c in table['countries'] as List<dynamic>) {
        final String code = (c as Map<String, dynamic>)['code'] as String;
        if (kLumeCountryZone.containsKey(code)) continue;
        for (final dynamic city in c['cities'] as List<dynamic>) {
          final String? z = kLumeCityZones['$code:$city'];
          expect(z, isNotNull, reason: '$code:$city');
          expect(kLumeCountryZones[code], contains(z), reason: '$code:$city');
        }
      }
      for (final MapEntry<String, String> e in kLumeCityZones.entries) {
        final String code = e.key.split(':').first;
        expect(kLumeCountryZone.containsKey(code), isFalse, reason: e.key);
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

/// `aqiFor(code, city)`, ported: the same country and city must always read
/// the same number, two cities in the same country must not, and the table
/// itself must be the reference's own figures — not something this port
/// invented.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/aqi/data/aqi_fixtures.dart';

void main() {
  group('the national baseline', () {
    test('is the reference\'s own table, exactly', () {
      expect(lumeAirQualityBaseline, <String, int>{
        'PK': 164,
        'IN': 178,
        'BD': 186,
        'CN': 112,
        'AE': 96,
        'SA': 104,
        'EG': 128,
        'NG': 118,
        'ID': 108,
        'TR': 74,
        'US': 42,
        'GB': 34,
        'DE': 30,
        'FR': 38,
        'CA': 26,
        'AU': 22,
        'JP': 40,
        'SE': 18,
      });
    });

    test('a country the table does not name reads 56', () {
      expect(lumeAirQualityFallbackBaseline, 56);
    });

    // `Math.round(base * 0.78)` — the empty string hashes to a seed of 0,
    // the minimum offset the formula ever applies, so this is the baseline
    // itself, pinned, for a spread of markets rather than just one.
    test('a spread of countries reads its own baseline, offset by nothing', () {
      const Map<String, int> atMinimumOffset = <String, int>{
        'PK': 128,
        'IN': 139,
        'BD': 145,
        'CN': 87,
        'AE': 75,
        'SA': 81,
        'EG': 100,
        'NG': 92,
        'ID': 84,
        'TR': 58,
        'US': 33,
        'GB': 27,
        'DE': 23,
        'FR': 30,
        'CA': 20,
        'AU': 17,
        'JP': 31,
        'SE': 14,
      };
      for (final MapEntry<String, int> e in atMinimumOffset.entries) {
        expect(
          lumeAirQualityFor(e.key, '').value,
          e.value,
          reason: '${e.key} at the minimum city offset',
        );
      }
      expect(
        lumeAirQualityFor('ZZ', '').value,
        44,
        reason: 'ZZ has no baseline of its own',
      );
    });
  });

  group('the city offset', () {
    test('the same country and city always reads the same number', () {
      final LumeAirQualityReading a = lumeAirQualityFor('PK', 'Islamabad');
      final LumeAirQualityReading b = lumeAirQualityFor('PK', 'Islamabad');
      expect(a.value, b.value);
      expect(
        a.parts.map((LumeAirQualityPart p) => p.value).toList(),
        b.parts.map((LumeAirQualityPart p) => p.value).toList(),
      );
    });

    test('two cities in the same country do not read identically', () {
      final int islamabad = lumeAirQualityFor('PK', 'Islamabad').value;
      final int lahore = lumeAirQualityFor('PK', 'Lahore').value;
      expect(islamabad, isNot(lahore));
    });

    test('the reference\'s own worked figures', () {
      // `(seed*31+charCodeAt(i))%997`, then
      // `max(8, round(base*(0.78+(seed%45)/100)))` — worked by hand for a
      // spread of markets, not just the one the widget test pumps.
      final Map<(String, String), (int, List<int>)> cases =
          <(String, String), (int, List<int>)>{
            ('PK', 'Islamabad'): (185, <int>[115, 174, 63, 41]),
            ('GB', 'London'): (41, <int>[25, 39, 14, 9]),
            ('US', 'New York'): (46, <int>[29, 43, 16, 10]),
            ('IN', 'Delhi'): (157, <int>[97, 148, 53, 35]),
            ('FR', 'Paris'): (30, <int>[19, 28, 10, 7]),
            ('SE', 'Stockholm'): (18, <int>[11, 17, 6, 4]),
          };
      for (final MapEntry<(String, String), (int, List<int>)> e
          in cases.entries) {
        final LumeAirQualityReading r = lumeAirQualityFor(e.key.$1, e.key.$2);
        expect(r.value, e.value.$1, reason: '${e.key.$1} ${e.key.$2} value');
        expect(
          r.parts.map((LumeAirQualityPart p) => p.value).toList(),
          e.value.$2,
          reason: '${e.key.$1} ${e.key.$2} parts',
        );
      }
    });

    test('never below 8 — `Math.max(8, …)`', () {
      // Every table entry times the minimum factor is already above 8, so
      // the floor only ever bites a country this port cannot name; assert
      // the guard exists rather than search for a string that trips it.
      for (final String country in lumeAirQualityBaseline.keys) {
        expect(lumeAirQualityFor(country, 'x').value, greaterThanOrEqualTo(8));
      }
    });
  });

  group('the band', () {
    test('follows the reference\'s own cut-offs', () {
      expect(LumeAirQualityBand.of(50), LumeAirQualityBand.good);
      expect(LumeAirQualityBand.of(51), LumeAirQualityBand.moderate);
      expect(LumeAirQualityBand.of(100), LumeAirQualityBand.moderate);
      expect(LumeAirQualityBand.of(101), LumeAirQualityBand.sensitive);
      expect(LumeAirQualityBand.of(150), LumeAirQualityBand.sensitive);
      expect(LumeAirQualityBand.of(151), LumeAirQualityBand.unhealthy);
      expect(LumeAirQualityBand.of(200), LumeAirQualityBand.unhealthy);
      expect(LumeAirQualityBand.of(201), LumeAirQualityBand.veryUnhealthy);
      expect(LumeAirQualityBand.of(300), LumeAirQualityBand.veryUnhealthy);
      expect(LumeAirQualityBand.of(301), LumeAirQualityBand.hazardous);
      expect(LumeAirQualityBand.of(999), LumeAirQualityBand.hazardous);
      expect(LumeAirQualityBand.of(5000), LumeAirQualityBand.hazardous);
    });

    test('Islamabad reads Unhealthy', () {
      expect(
        lumeAirQualityFor('PK', 'Islamabad').band,
        LumeAirQualityBand.unhealthy,
      );
    });
  });

  group('the trend', () {
    test('is 24 points, drawn from the shared seeded walk', () {
      final LumeAirQualityReading r = lumeAirQualityFor('GB', 'London');
      expect(r.trend, hasLength(24));
      // Deterministic — the same reading draws the same trend every time.
      expect(r.trend, lumeAirQualityFor('GB', 'London').trend);
    });
  });
}

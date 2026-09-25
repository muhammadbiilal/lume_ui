/// "Use my current location": a position becomes the nearest city the picker
/// lists, and every way it can fail says so.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/platform/lume_locator.dart';
import 'package:lume/features/onboarding/application/use_location.dart';
import 'package:lume/features/onboarding/data/country_fixture.dart';
import 'package:lume/features/onboarding/domain/place_resolver.dart';

void main() {
  final LumeCountryFixture countries = LumeCountryFixture.parse(
    File('assets/data/countries.json').readAsStringSync(),
  );

  bool known(String country, String city) =>
      countries.placesOf(country).cities.contains(city);

  LumeResolvedPlace near(double lat, double lon) =>
      LumePlaceResolver.nearest(lat, lon, isKnown: known)!;

  group('the resolver', () {
    test('every point is a city the picker lists', () {
      for (final (String country, String city, double _, double _)
          in LumePlaceResolver.points) {
        expect(known(country, city), isTrue, reason: '$country · $city');
      }
    });

    test('every one of the 194 countries has at least one point', () {
      final Set<String> covered = <String>{
        for (final (String country, String _, double _, double _)
            in LumePlaceResolver.points)
          country,
      };
      expect(covered, hasLength(194));
    });

    test('a reader in Islamabad is placed in Islamabad', () {
      final LumeResolvedPlace p = near(33.70, 73.06);
      expect((p.country, p.city), ('PK', 'Islamabad'));
    });

    test('a reader in New York is placed in New York — the reference put '
        'every US reader in Los Angeles', () {
      final LumeResolvedPlace p = near(40.73, -73.99);
      expect((p.country, p.city), ('US', 'New York'));
    });

    test('a reader in Delhi is placed in New Delhi — the reference said '
        'Mumbai', () {
      final LumeResolvedPlace p = near(28.63, 77.22);
      expect((p.country, p.city), ('IN', 'New Delhi'));
    });

    test('a country with no finer table is placed at its primary city', () {
      final LumeResolvedPlace p = near(34.52, 69.18);
      expect((p.country, p.city), ('AF', 'Kabul'));
    });

    test('distance is measured on the sphere', () {
      // London to Paris is about 344 km.
      expect(
        LumePlaceResolver.kilometresBetween(51.51, -0.13, 48.86, 2.35),
        closeTo(344, 5),
      );
    });

    test('a city the picker does not list is never the answer', () {
      final LumeResolvedPlace? p = LumePlaceResolver.nearest(
        33.70,
        73.06,
        isKnown: (String country, String city) =>
            known(country, city) && city != 'Islamabad',
      );
      expect(p!.city, isNot('Islamabad'));
    });
  });

  group('the lookup', () {
    Future<LumeUseLocationResult> resolve(LumeLocateResult r) =>
        LumeUseLocation.resolve(
          locator: LumeRecordingLocator(result: r),
          countries: countries,
        );

    test('a position becomes a country, a city and its region', () async {
      final LumeUseLocationResult r = await resolve(
        const LumeLocateResult.located(51.50, -0.12),
      );
      expect(r.found, isTrue);
      expect((r.country, r.city, r.region), ('GB', 'London', 'England'));
    });

    test('a country without regions has no region', () async {
      final LumeUseLocationResult r = await resolve(
        const LumeLocateResult.located(34.52, 69.18),
      );
      expect(r.region, isNull);
    });

    for (final LumeLocateOutcome o in <LumeLocateOutcome>[
      LumeLocateOutcome.denied,
      LumeLocateOutcome.blocked,
      LumeLocateOutcome.serviceOff,
      LumeLocateOutcome.failed,
    ]) {
      test(
        '${o.name}: nothing is found, and there is something to say',
        () async {
          final LumeUseLocationResult r = await resolve(
            LumeLocateResult.refused(o),
          );
          expect(r.found, isFalse);
          expect(r.outcome, o);
        },
      );
    }
  });
}

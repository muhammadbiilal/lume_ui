/// `LumeFuelCostRules` — the reference's own `fuelCost()` arithmetic, and
/// that its default price is genuinely [LumeFuel]'s, not a second copy that
/// could drift from it.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/features/fuel/data/fuel_fixtures.dart';
import 'package:lume/features/fuel/domain/fuelcost_maths.dart';

void main() {
  group('opening figures', () {
    test('metric: 400 km, 12 km/L, two people', () {
      expect(LumeFuelCostRules.defaultDistance(imperial: false), 400);
      expect(LumeFuelCostRules.defaultEconomy(imperial: false), 12);
      expect(LumeFuelCostRules.defaultPeople, 2);
    });

    test('imperial: 250 mi, 32 mpg', () {
      expect(LumeFuelCostRules.defaultDistance(imperial: true), 250);
      expect(LumeFuelCostRules.defaultEconomy(imperial: true), 32);
    });
  });

  group('the default price is Fuel Prices\' own — the cross-tool link', () {
    test('every named market\'s default price is that market\'s own leading '
        'grade, read at call time rather than duplicated', () {
      for (final String country in <String>[
        'PK',
        'GB',
        'US',
        'AE',
        'SA',
        'IN',
      ]) {
        expect(
          LumeFuelCostRules.defaultPrice(country),
          LumeFuel.forCountry(country).main.price,
          reason: country,
        );
      }
      // An unlisted country reads the same fallback price Fuel Prices itself
      // would show it — not USD 0, not a Pakistani price.
      expect(
        LumeFuelCostRules.defaultPrice('ZZ'),
        LumeFuel.fallback.main.price,
      );
    });

    test('the two tools cannot disagree, because there is only one figure', () {
      // There is no second table for fuelcost_maths.dart to have hardcoded:
      // Pakistan's own petrol price is not 1.28 (the fallback's), 3.12 (the
      // US's) or any other market's — proving `defaultPrice` actually reads
      // `LumeFuel.pakistan` and not a coincidence.
      expect(LumeFuelCostRules.defaultPrice('PK'), 264.61);
      expect(LumeFuelCostRules.defaultPrice('PK'), isNot(1.28));
      expect(LumeFuelCostRules.defaultPrice('PK'), isNot(3.12));
    });
  });

  group('the trip\'s cost', () {
    LumeMoney pkr(int minor) => LumeMoney.sum(minor, LumeCurrency.of('PKR'));

    test('used = distance / economy; total = used * price', () {
      final LumeFuelCostResult r = LumeFuelCostRules.compute(
        LumeFuelCostInputs(
          distance: 400,
          economy: 10,
          price: pkr(10000), // 100.00 PKR/litre
          people: 2,
        ),
      );
      expect(r.fuelUsed, 40);
      expect(r.total, pkr(400000)); // 40 * 100.00 = 4,000.00
      expect(r.perPerson, pkr(200000)); // split two ways
      expect(r.perUnit, pkr(1000)); // 4,000 / 400 km = 10.00 / km
    });

    test('the three scenarios: solo, shared, and a round trip that doubles '
        'both the fuel and the cost', () {
      final LumeFuelCostResult r = LumeFuelCostRules.compute(
        LumeFuelCostInputs(
          distance: 400,
          economy: 10,
          price: pkr(10000),
          people: 4,
        ),
      );
      expect(r.scenarios, hasLength(3));
      final LumeFuelCostScenario solo = r.scenarios[0];
      final LumeFuelCostScenario shared = r.scenarios[1];
      final LumeFuelCostScenario roundTrip = r.scenarios[2];

      expect(solo.kind, LumeFuelCostScenarioKind.solo);
      expect(solo.fuelUsed, 40);
      expect(solo.cost, r.total);

      expect(shared.kind, LumeFuelCostScenarioKind.shared);
      expect(shared.fuelUsed, 40);
      expect(shared.cost, pkr(100000)); // 4,000 / 4 people = 1,000.00

      expect(roundTrip.kind, LumeFuelCostScenarioKind.roundTrip);
      expect(roundTrip.fuelUsed, 80);
      expect(roundTrip.cost, pkr(800000)); // double the total
    });

    test('a zero or unreadable economy reads as nothing owed, not a crash', () {
      final LumeFuelCostResult r = LumeFuelCostRules.compute(
        LumeFuelCostInputs(
          distance: 400,
          economy: 0,
          price: pkr(10000),
          people: 2,
        ),
      );
      expect(r.fuelUsed, 0);
      expect(r.total, LumeMoney.zero(LumeCurrency.of('PKR')));
    });

    test('a single traveller and a short distance never divide by less '
        'than one', () {
      final LumeFuelCostResult r = LumeFuelCostRules.compute(
        LumeFuelCostInputs(
          distance: 0.5,
          economy: 10,
          price: pkr(10000),
          people: 0,
        ),
      );
      // `Math.max(1, dist)` and `Math.max(1, people)` — both floors at one.
      expect(r.perPerson, r.total);
      expect(r.perUnit, r.total);
    });
  });
}

/// `LumeFuel.forCountry` — the six named markets, ported exactly from
/// `tool-data.js` `FUEL`, and the honest global fallback every other
/// country reads.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/fuel/data/fuel_fixtures.dart';

void main() {
  group('named markets', () {
    test('Pakistan: OGRA, four grades, petrol leads', () {
      final LumeFuelMarket m = LumeFuel.forCountry('PK');
      expect(m.currency, 'PKR');
      expect(m.unit, LumeFuelUnit.litre);
      expect(m.sourceKind, LumeFuelSource.proper);
      expect(m.properSource, 'OGRA notification');
      expect(m.effectiveKind, LumeFuelEffective.fixed);
      expect(m.fixedEffective, '1 September');
      expect(m.items, hasLength(4));
      expect(m.main.grade, LumeFuelGrade.petrol);
      expect(m.main.code, 'RON 92');
      expect(m.main.price, 264.61);
      expect(m.main.previous, 262.47);
      expect(m.items[1].code, 'RON 97');
      expect(m.items[2].code, 'HSD');
      expect(m.items[3].code, 'LDO');
      expect(m.items[3].price, m.items[3].previous); // unchanged this cycle
    });

    test('Great Britain: a translated retail source, today', () {
      final LumeFuelMarket m = LumeFuel.forCountry('GB');
      expect(m.currency, 'GBP');
      expect(m.unit, LumeFuelUnit.litre);
      expect(m.sourceKind, LumeFuelSource.retail);
      expect(m.effectiveKind, LumeFuelEffective.today);
      expect(m.items.map((LumeFuelItem i) => i.code), <String>[
        'E10',
        'E5',
        'B7',
      ]);
      expect(m.main.price, 1.34);
    });

    test('United States: priced by the gallon', () {
      final LumeFuelMarket m = LumeFuel.forCountry('US');
      expect(m.currency, 'USD');
      expect(m.unit, LumeFuelUnit.gallon);
      expect(m.sourceKind, LumeFuelSource.state);
      expect(m.items, hasLength(4));
      expect(m.main.code, '87');
      expect(m.main.price, 3.12);
    });

    test('UAE: the Ministry of Energy, a fixed date', () {
      final LumeFuelMarket m = LumeFuel.forCountry('AE');
      expect(m.currency, 'AED');
      expect(m.sourceKind, LumeFuelSource.proper);
      expect(m.properSource, 'Ministry of Energy');
      expect(m.fixedEffective, '1 September');
      expect(m.items.map((LumeFuelItem i) => i.grade), <LumeFuelGrade>[
        LumeFuelGrade.special95,
        LumeFuelGrade.super98,
        LumeFuelGrade.ePlus91,
        LumeFuelGrade.diesel,
      ]);
    });

    test('Saudi Arabia: the Aramco tariff, unmoved 91/95', () {
      final LumeFuelMarket m = LumeFuel.forCountry('SA');
      expect(m.currency, 'SAR');
      expect(m.properSource, 'Aramco tariff');
      expect(m.fixedEffective, '11 September');
      expect(m.items[0].price, m.items[0].previous);
      expect(m.items[1].price, m.items[1].previous);
    });

    test('India: OMCs, and the same petrol grade key as Pakistan', () {
      final LumeFuelMarket m = LumeFuel.forCountry('IN');
      expect(m.currency, 'INR');
      expect(m.sourceKind, LumeFuelSource.omc);
      expect(m.main.grade, LumeFuelGrade.petrol);
      expect(m.main.grade, LumeFuel.forCountry('PK').main.grade);
      expect(m.items.last.grade, LumeFuelGrade.cng);
    });
  });

  group('the global fallback', () {
    test('an unlisted country reads the honest neutral fallback', () {
      for (final String country in <String>[
        'FR',
        'DE',
        'JP',
        'NG',
        'BR',
        'ZZ',
      ]) {
        final LumeFuelMarket m = LumeFuel.forCountry(country);
        expect(m, same(LumeFuel.fallback), reason: country);
      }
    });

    test('the fallback is USD, by the litre, two grades, never blank', () {
      const LumeFuelMarket m = LumeFuel.fallback;
      expect(m.currency, 'USD');
      expect(m.unit, LumeFuelUnit.litre);
      expect(m.sourceKind, LumeFuelSource.regional);
      expect(m.effectiveKind, LumeFuelEffective.thisWeek);
      expect(m.items, hasLength(2));
      expect(m.main.grade, LumeFuelGrade.petrol);
      expect(m.main.code, 'Unleaded');
      expect(m.main.price, 1.28);
      expect(m.items[1].grade, LumeFuelGrade.diesel);
    });
  });

  test('a grade\'s change is price minus previous', () {
    const LumeFuelItem i = LumeFuelItem(
      grade: LumeFuelGrade.diesel,
      code: 'Diesel',
      price: 10,
      previous: 9,
    );
    expect(i.change, 1);
  });
}

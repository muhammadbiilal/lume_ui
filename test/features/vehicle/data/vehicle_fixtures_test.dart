/// Vehicle & Fines' fixture fleet and the arithmetic `vehicleCosts()` and
/// `vehicle.tool.js`'s own `filter`/`reduce` calls do over it, against the
/// reference's own figures.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/features/vehicle/data/vehicle_fixtures.dart';

final LumeCurrency _pkr = LumeCurrency.of('PKR');

void main() {
  group('the fixture fleet — the reference\'s own two vehicles, ported '
      'exactly', () {
    test('exactly two vehicles, in the reference\'s own order', () {
      expect(kVehicles, hasLength(2));
      expect(kVehicles.map((LumeVehicle v) => v.plate).toList(), <String>[
        'ABC-124',
        'LEB-8842',
      ]);
    });

    test('ABC-124 — Toyota Corolla, 2019, token due in 22 days, 1 open '
        'fine, insured to 14 Dec, 84,200 km', () {
      final LumeVehicle v = kVehicles[0];
      expect(v.make, 'Toyota Corolla');
      expect(v.year, 2019);
      expect(v.tone, LumeVehicleTone.sky);
      expect(v.token, '30 Sep');
      expect(v.tokenDays, 22);
      expect(v.insurance, '14 Dec');
      expect(v.fines, 1);
      expect(v.fineAmount, 12);
      expect(v.odometerKm, 84200);
      expect(v.logo, 'ABC');
    });

    test('LEB-8842 — Honda CD-70, 2022, token due in 64 days, no open '
        'fines, no insurance on record, 21,400 km', () {
      final LumeVehicle v = kVehicles[1];
      expect(v.make, 'Honda CD-70');
      expect(v.year, 2022);
      expect(v.tone, LumeVehicleTone.amber);
      expect(v.token, '11 Nov');
      expect(v.tokenDays, 64);
      // `insurance: '—'` in the reference — no record at all.
      expect(v.insurance, isNull);
      expect(v.fines, 0);
      expect(v.fineAmount, 0);
      expect(v.odometerKm, 21400);
      expect(v.logo, 'LEB');
    });
  });

  group('LumeVehicleCosts — the reference\'s own USD figures, converted at '
      'its own demo PKR rate (283) and tidied exactly as `tidy()` does', () {
    test('tokenCar: 43 USD × 283 = 12,169 → tidied to 12,200', () {
      final LumeMoney m = LumeVehicleCosts.tokenCar(_pkr);
      expect(m.currency, _pkr);
      expect(m.toDecimalString(), '12200.00');
    });

    test('tokenBike: 6 USD × 283 = 1,698 → tidied to 1,700', () {
      final LumeMoney m = LumeVehicleCosts.tokenBike(_pkr);
      expect(m.toDecimalString(), '1700.00');
    });

    test('insurance: 150 USD × 283 = 42,450 → tidied to 42,500', () {
      final LumeMoney m = LumeVehicleCosts.insurance(_pkr);
      expect(m.toDecimalString(), '42500.00');
    });

    test('fineTotal: (12 + 0) USD × 283 = 3,396 → tidied to 3,400 — the '
        'summary card\'s own "Outstanding" figure', () {
      final LumeMoney m = LumeVehicleCosts.fineTotal(kVehicles, _pkr);
      expect(m.toDecimalString(), '3400.00');
    });

    test('tokenFor — `i === 0 ? tokenCar : tokenBike`, the reference\'s own '
        'ternary by fleet position, never by vehicle kind', () {
      expect(
        LumeVehicleCosts.tokenFor(0, _pkr),
        LumeVehicleCosts.tokenCar(_pkr),
      );
      expect(
        LumeVehicleCosts.tokenFor(1, _pkr),
        LumeVehicleCosts.tokenBike(_pkr),
      );
      // Ported literally: a third vehicle would also fall to the bike rate,
      // the same `: cfg.tokenBike` else-branch the reference's own ternary
      // has for every index past zero.
      expect(
        LumeVehicleCosts.tokenFor(2, _pkr),
        LumeVehicleCosts.tokenBike(_pkr),
      );
    });

    test('a different currency scales by its own minor-unit exponent, not '
        'PKR\'s', () {
      final LumeCurrency jpy = LumeCurrency.of('JPY');
      // JPY has no minor unit (exponent 0): the same tidied major-unit
      // figure, at a different scale.
      expect(LumeVehicleCosts.tokenCar(jpy).minor, 12200);
      expect(LumeVehicleCosts.tokenCar(jpy).toDecimalString(), '12200');
    });
  });

  group('lumeVehicleFilter — `(plate + \' \' + make)` against the query, '
      'exactly as `vehicle.tool.js`\'s own `.filter` does', () {
    test('an empty query returns the whole fleet', () {
      expect(lumeVehicleFilter(kVehicles, ''), kVehicles);
      expect(lumeVehicleFilter(kVehicles, '   '), kVehicles);
    });

    test('a plate substring matches only that vehicle', () {
      final List<LumeVehicle> found = lumeVehicleFilter(kVehicles, 'abc');
      expect(found.map((LumeVehicle v) => v.plate), <String>['ABC-124']);
    });

    test('a make substring matches only that vehicle, case-insensitively', () {
      final List<LumeVehicle> found = lumeVehicleFilter(kVehicles, 'HONDA');
      expect(found.map((LumeVehicle v) => v.plate), <String>['LEB-8842']);
    });

    test('a query matching neither plate nor make matches nothing — never '
        'an invented row', () {
      expect(lumeVehicleFilter(kVehicles, 'zzz-not-real'), isEmpty);
    });
  });
}

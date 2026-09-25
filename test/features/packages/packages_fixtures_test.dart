/// Mobile Packages' fixture data, on its own: the sort keys the reference
/// reads out of its display strings, and the country lookup that draws the
/// line between Pakistan and everywhere else.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/packages/data/packages_fixtures.dart';

void main() {
  group('LumeMobilePackages.forCountry', () {
    test('answers Pakistan with the real, named carrier bundles', () {
      final List<LumeMobilePackage>? pk = LumeMobilePackages.forCountry('PK');
      expect(pk, isNotNull);
      expect(
        pk!.map((LumeMobilePackage p) => p.operatorName).toList(),
        <String>['Jazz', 'Zong', 'Ufone', 'Telenor'],
      );
      // The reference's own figures — `tool-data.js`'s `MOBILE_PACKAGES.PK`,
      // ported without rounding or conversion.
      expect(pk.map((LumeMobilePackage p) => p.price).toList(), <int>[
        1150,
        1200,
        1050,
        1000,
      ]);
      expect(
        pk.firstWhere((LumeMobilePackage p) => p.operatorName == 'Jazz').name,
        'Super Duper Card',
      );
    });

    test('answers every other country with null, not an empty list — the '
        'two mean different things', () {
      expect(LumeMobilePackages.forCountry('US'), isNull);
      expect(LumeMobilePackages.forCountry('GB'), isNull);
      expect(LumeMobilePackages.forCountry('IN'), isNull);
    });
  });

  group('the sort keys a bundle exposes', () {
    test('dataGb reads the number out of its own display string', () {
      const LumeMobilePackage p = LumeMobilePackage(
        operatorName: 'Jazz',
        name: 'Super Duper Card',
        data: '15 GB',
        mins: '3000 On-net',
        sms: '3000',
        valid: '30 days',
        price: 1150,
      );
      expect(p.dataGb, 15);
      expect(p.validDays, 30);
    });

    test('sorts every Pakistani bundle by price, data and validity without '
        'throwing', () {
      final List<LumeMobilePackage> pk = LumeMobilePackages.forCountry('PK')!;
      final List<double> byData =
          pk.map((LumeMobilePackage p) => p.dataGb).toList()..sort();
      expect(byData, <double>[10, 12, 15, 20]);
      final List<int> byValid = pk
          .map((LumeMobilePackage p) => p.validDays)
          .toSet()
          .toList();
      expect(byValid, <int>[30]);
    });
  });
}

/// National Savings' data, against the reference's own `D.NAT_SAVINGS`
/// table, and the tool's own sort and search.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/natsavings/data/natsavings_fixtures.dart';

void main() {
  group('D.NAT_SAVINGS', () {
    test('has exactly one country — Pakistan — and no invented equivalent '
        'for anywhere else', () {
      expect(LumeNatSavingsScheme.forCountry('PK'), isNotNull);
      for (final String other in <String>['US', 'GB', 'AE', 'SA', 'IN', 'JP']) {
        expect(
          LumeNatSavingsScheme.forCountry(other),
          isNull,
          reason: '$other has no national savings scheme in the reference',
        );
      }
    });

    test('carries the reference\'s five certificates exactly — names, rates, '
        'terms, payout, minimum and eligibility', () {
      final LumeNatSavingsScheme pk = LumeNatSavingsScheme.forCountry('PK')!;
      expect(pk.instruments, hasLength(5));

      final Map<String, LumeSavingsInstrument> byName =
          <String, LumeSavingsInstrument>{
            for (final LumeSavingsInstrument p in pk.instruments) p.name: p,
          };
      expect(byName.keys.toSet(), <String>{
        'Behbood Savings Certificate',
        'Defence Savings Certificate',
        'Regular Income Certificate',
        'Special Savings Certificate',
        'Pensioners’ Benefit Account',
      });

      final LumeSavingsInstrument behbood =
          byName['Behbood Savings Certificate']!;
      expect(behbood.rate, 15.36);
      expect(behbood.term, '10 years');
      expect(behbood.payout, 'Monthly');
      expect(behbood.min, 5000);
      expect(behbood.eligible, 'Widows, seniors, disabled');

      final LumeSavingsInstrument defence =
          byName['Defence Savings Certificate']!;
      expect(defence.rate, 13.02);
      expect(defence.term, '10 years');
      expect(defence.payout, 'On maturity');
      expect(defence.min, 500);
      expect(defence.eligible, 'All');

      final LumeSavingsInstrument regular =
          byName['Regular Income Certificate']!;
      expect(regular.rate, 13.44);
      expect(regular.term, '5 years');
      expect(regular.payout, 'Monthly');
      expect(regular.min, 50000);
      expect(regular.eligible, 'All');

      final LumeSavingsInstrument special =
          byName['Special Savings Certificate']!;
      expect(special.rate, 12.60);
      expect(special.term, '3 years');
      expect(special.payout, 'Half-yearly');
      expect(special.min, 500);
      expect(special.eligible, 'All');

      final LumeSavingsInstrument pensioners =
          byName['Pensioners’ Benefit Account']!;
      expect(pensioners.rate, 15.36);
      expect(pensioners.term, '10 years');
      expect(pensioners.payout, 'Monthly');
      expect(pensioners.min, 5000);
      expect(pensioners.eligible, 'Pensioners');
    });

    test('term years are parsed from the free-text term, for the sort bar', () {
      final LumeNatSavingsScheme pk = LumeNatSavingsScheme.forCountry('PK')!;
      final Map<String, LumeSavingsInstrument> byName =
          <String, LumeSavingsInstrument>{
            for (final LumeSavingsInstrument p in pk.instruments) p.name: p,
          };
      expect(byName['Behbood Savings Certificate']!.termYears, 10);
      expect(byName['Regular Income Certificate']!.termYears, 5);
      expect(byName['Special Savings Certificate']!.termYears, 3);
    });

    test(
      'the best rate is the highest — and, on a tie, the first of them in '
      'the reference\'s own order (Behbood before Pensioners, both 15.36)',
      () {
        final LumeNatSavingsScheme pk = LumeNatSavingsScheme.forCountry('PK')!;
        expect(pk.best.name, 'Behbood Savings Certificate');
        expect(pk.best.rate, 15.36);

        // A scrambled order still resolves to the highest rate — but the tie
        // now breaks toward whichever of the two 15.36% instruments comes
        // first in *that* order, exactly as `list.slice().sort((a,b) => b.rate
        // - a.rate)[0]` would with a stable sort.
        final LumeNatSavingsScheme reversed = LumeNatSavingsScheme(
          List<LumeSavingsInstrument>.from(pk.instruments.reversed),
        );
        expect(reversed.best.name, 'Pensioners’ Benefit Account');
      },
    );
  });

  group('lumeNatSavingsFilter', () {
    final List<LumeSavingsInstrument> pk = LumeNatSavingsScheme.forCountry(
      'PK',
    )!.instruments;

    test('matches the name, case-insensitively', () {
      expect(
        lumeNatSavingsFilter(
          pk,
          'behbood',
        ).map((LumeSavingsInstrument p) => p.name),
        <String>['Behbood Savings Certificate'],
      );
      expect(
        lumeNatSavingsFilter(
          pk,
          'BEHBOOD',
        ).map((LumeSavingsInstrument p) => p.name),
        <String>['Behbood Savings Certificate'],
      );
    });

    test('matches eligibility as well as the name', () {
      expect(
        lumeNatSavingsFilter(
          pk,
          'pensioners',
        ).map((LumeSavingsInstrument p) => p.name),
        <String>['Pensioners’ Benefit Account'],
      );
      expect(
        lumeNatSavingsFilter(
          pk,
          'widows',
        ).map((LumeSavingsInstrument p) => p.name),
        <String>['Behbood Savings Certificate'],
      );
    });

    test('an empty query keeps every instrument, in order', () {
      expect(lumeNatSavingsFilter(pk, ''), pk);
    });

    test('a query matching nothing returns an empty list, never another '
        'country\'s data', () {
      expect(lumeNatSavingsFilter(pk, 'zzz'), isEmpty);
    });
  });

  group('lumeNatSavingsSort', () {
    final List<LumeSavingsInstrument> pk = LumeNatSavingsScheme.forCountry(
      'PK',
    )!.instruments;

    List<String> names(List<LumeSavingsInstrument> list) =>
        list.map((LumeSavingsInstrument p) => p.name).toList();

    test('by rate, descending — ties keep the reference\'s own order '
        '(dir only flips a real difference, never a zero)', () {
      expect(
        names(lumeNatSavingsSort(pk, sort: 'rate', descending: true)),
        <String>[
          'Behbood Savings Certificate',
          'Pensioners’ Benefit Account',
          'Regular Income Certificate',
          'Defence Savings Certificate',
          'Special Savings Certificate',
        ],
      );
    });

    test('by rate, ascending — the same tie still keeps original order', () {
      expect(
        names(lumeNatSavingsSort(pk, sort: 'rate', descending: false)),
        <String>[
          'Special Savings Certificate',
          'Defence Savings Certificate',
          'Regular Income Certificate',
          'Behbood Savings Certificate',
          'Pensioners’ Benefit Account',
        ],
      );
    });

    test('by term, descending', () {
      final List<LumeSavingsInstrument> sorted = lumeNatSavingsSort(
        pk,
        sort: 'term',
        descending: true,
      );
      expect(sorted.first.termYears, 10);
      expect(sorted.last.termYears, 3);
    });

    test('by minimum deposit, ascending', () {
      final List<LumeSavingsInstrument> sorted = lumeNatSavingsSort(
        pk,
        sort: 'min',
        descending: false,
      );
      expect(sorted.first.min, 500);
      expect(sorted.last.min, 50000);
    });

    test('sorting never drops or invents an instrument', () {
      for (final String dim in <String>['rate', 'term', 'min']) {
        for (final bool desc in <bool>[true, false]) {
          final List<LumeSavingsInstrument> sorted = lumeNatSavingsSort(
            pk,
            sort: dim,
            descending: desc,
          );
          expect(sorted.toSet(), pk.toSet());
          expect(sorted, hasLength(pk.length));
        }
      }
    });
  });
}

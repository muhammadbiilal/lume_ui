/// `currencyBoard()`'s arithmetic, against the reference's own rate table.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_reference_rates.dart';
import 'package:lume/features/currency/domain/currency_maths.dart';

void main() {
  group('the rate', () {
    test('USD to PKR is the table\'s PKR rate, unscaled', () {
      final LumeCurrencyBoard b = LumeCurrencyBoard.forPair('USD', 'PKR');
      expect(b.rate, kReferenceRatesPerUsd['PKR']);
    });

    test('EUR to GBP is a ratio of two per-dollar rates', () {
      final LumeCurrencyBoard b = LumeCurrencyBoard.forPair('EUR', 'GBP');
      expect(
        b.rate,
        kReferenceRatesPerUsd['GBP']! / kReferenceRatesPerUsd['EUR']!,
      );
    });

    test('a currency the table does not name converts at one, like '
        'lumeRatePerUsd itself', () {
      final LumeCurrencyBoard fromUnknown = LumeCurrencyBoard.forPair(
        'ZZZ',
        'USD',
      );
      expect(fromUnknown.rate, 1 / kReferenceRatesPerUsd['USD']!);
      final LumeCurrencyBoard toUnknown = LumeCurrencyBoard.forPair(
        'USD',
        'ZZZ',
      );
      expect(toUnknown.rate, lumeRatePerUsd('ZZZ') / kReferenceRatesPerUsd['USD']!);
      expect(lumeRatePerUsd('ZZZ'), 1);
    });

    test('a currency converted to itself is one', () {
      expect(LumeCurrencyBoard.forPair('EUR', 'EUR').rate, 1);
    });
  });

  group('defaultTo', () {
    test('opens on EUR for a dollar reader', () {
      expect(LumeCurrencyBoard.defaultTo('USD'), 'EUR');
    });

    test('opens on USD for everyone else', () {
      expect(LumeCurrencyBoard.defaultTo('PKR'), 'USD');
      expect(LumeCurrencyBoard.defaultTo('EUR'), 'USD');
    });
  });

  group('the Popular board', () {
    test('is the eight majors, minus the active from, in the reference\'s '
        'own order and change figures', () {
      final LumeCurrencyBoard b = LumeCurrencyBoard.forPair('PKR', 'USD');
      expect(
        b.popular.map((LumeCurrencyPair p) => p.code).toList(),
        <String>['USD', 'EUR', 'GBP', 'SAR', 'AED', 'INR'],
      );
      expect(
        b.popular.map((LumeCurrencyPair p) => p.pct).toList(),
        <double>[0.18, -0.24, 0.06, 0, 0.42, -0.11],
      );
      // Every row prices from `from` (PKR), not from USD.
      for (final LumeCurrencyPair p in b.popular) {
        expect(
          p.rate,
          lumeRatePerUsd(p.code) / kReferenceRatesPerUsd['PKR']!,
        );
      }
    });

    test('drops the active from out of the board entirely', () {
      final LumeCurrencyBoard b = LumeCurrencyBoard.forPair('EUR', 'USD');
      expect(
        b.popular.map((LumeCurrencyPair p) => p.code),
        isNot(contains('EUR')),
      );
    });

    test('the flag is the code\'s first two letters, not a symbol', () {
      final LumeCurrencyBoard b = LumeCurrencyBoard.forPair('PKR', 'USD');
      final LumeCurrencyPair usd = b.popular.firstWhere(
        (LumeCurrencyPair p) => p.code == 'USD',
      );
      expect(usd.flag, 'US');
    });
  });

  group('history and spark', () {
    test('the 30-day chart is 30 points, seeded from the active rate', () {
      final LumeCurrencyBoard b = LumeCurrencyBoard.forPair('USD', 'EUR');
      expect(b.history, hasLength(30));
    });

    test('a row\'s sparkline is 16 points', () {
      final LumeCurrencyBoard b = LumeCurrencyBoard.forPair('PKR', 'USD');
      expect(b.popular.first.spark, hasLength(16));
    });
  });

  group('allCodes', () {
    test('covers exactly the shared rate table, sorted', () {
      final List<String> sorted = kReferenceRatesPerUsd.keys.toList()..sort();
      expect(LumeCurrencyBoard.allCodes, sorted);
      expect(LumeCurrencyBoard.allCodes.length, kReferenceRatesPerUsd.length);
    });
  });

  group('convert', () {
    test('a real amount converts at the rate', () {
      expect(LumeCurrencyBoard.convert(283.0, '100'), 28300.0);
    });

    test('a decimal typed with a comma reads as one', () {
      expect(LumeCurrencyBoard.convert(2, '1,5'), 3.0);
    });

    test('zero converts to zero, not to null', () {
      expect(LumeCurrencyBoard.convert(283.0, '0'), 0.0);
    });

    test('a negative amount is refused, like GoldRates\' worth() on a '
        'negative weight', () {
      expect(LumeCurrencyBoard.convert(283.0, '-5'), isNull);
    });

    test('anything that is not a number is refused, never thrown', () {
      expect(LumeCurrencyBoard.convert(283.0, 'abc'), isNull);
      expect(LumeCurrencyBoard.convert(283.0, ''), isNull);
      expect(LumeCurrencyBoard.convert(283.0, 'NaN'), isNull);
      expect(LumeCurrencyBoard.convert(283.0, '∞'), isNull);
    });
  });
}

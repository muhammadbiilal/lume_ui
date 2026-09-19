/// One rule for a withdrawn currency, asked by every money tool.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_currency_policy.dart';

void main() {
  final LumeCurrency eur = LumeCurrency.of('EUR');
  final LumeCurrency bgn = LumeCurrency.of('BGN');
  final LumeCurrency hrk = LumeCurrency.of('HRK');

  test('a current currency is usable for anything', () {
    expect(LumeCurrencyPolicy.of(eur), LumeCurrencyAvailability.current);
    expect(
      LumeCurrencyPolicy.of(eur, existing: <LumeCurrency>[bgn]),
      LumeCurrencyAvailability.current,
    );
  });

  test('a withdrawn currency is not usable for something new', () {
    expect(LumeCurrencyPolicy.of(bgn), LumeCurrencyAvailability.unsupported);
    expect(LumeCurrencyPolicy.of(bgn).usable, isFalse);
  });

  test('it is usable to service a record already kept in it', () {
    final LumeCurrencyAvailability a = LumeCurrencyPolicy.of(
      bgn,
      existing: <LumeCurrency>[eur, bgn],
    );
    expect(a, LumeCurrencyAvailability.historicalForExistingRecord);
    expect(a.usable, isTrue);
  });

  test('a record in another withdrawn currency does not open this one', () {
    expect(
      LumeCurrencyPolicy.of(bgn, existing: <LumeCurrency>[hrk, eur]),
      LumeCurrencyAvailability.unsupported,
    );
  });

  test('historical lists only the withdrawn ones, once, by code', () {
    expect(
      LumeCurrencyPolicy.historical(<LumeCurrency>[eur, hrk, bgn, bgn]),
      <LumeCurrency>[bgn, hrk],
    );
    expect(LumeCurrencyPolicy.historical(<LumeCurrency>[eur]), isEmpty);
  });
}

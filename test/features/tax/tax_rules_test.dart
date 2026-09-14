/// The arithmetic, against what the running reference prints.
///
/// Every expected figure below was read off a web capture
/// (`measurements/tool_tax_*.json`), not worked out by hand: the reference is
/// the oracle, and the port is right when it agrees with it.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_reference_rates.dart';
import 'package:lume/features/tax/data/tax_fixtures.dart';
import 'package:lume/features/tax/domain/tax_rules.dart';

LumeTaxResult taxFor(
  String country, {
  LumeTaxPeriod period = LumeTaxPeriod.month,
  double? income,
  double deductions = 0,
}) {
  final LumeTaxConfig cfg = lumeTaxConfigFor(country)!;
  return LumeTaxRules.compute(
    cfg,
    period: period,
    income: income ?? LumeTaxRules.openingIncome(lumeRatePerUsd(cfg.currency)),
    deductions: deductions,
  );
}

void main() {
  group('the opening figure', () {
    test('is about three thousand dollars, to the thousand', () {
      // `Math.round(3000 * RATES[ccy] / 1000) * 1000` — the field values the
      // captures show.
      expect(LumeTaxRules.openingIncome(lumeRatePerUsd('PKR')), 849000);
      expect(LumeTaxRules.openingIncome(lumeRatePerUsd('USD')), 3000);
      expect(LumeTaxRules.openingIncome(lumeRatePerUsd('GBP')), 2000);
      expect(LumeTaxRules.openingIncome(lumeRatePerUsd('INR')), 252000);
    });

    test('and an untaxed market opens on the unrounded product', () {
      expect(LumeTaxRules.openingGross(lumeRatePerUsd('AED')), 11010);
    });

    test('the rate table is the reference’s, all of it', () {
      expect(kReferenceRatesPerUsd, hasLength(145));
      expect(kReferenceRatesPerUsd['PKR'], 283);
      expect(lumeRatePerUsd('XXX'), 1, reason: '`RATES[code] || 1`');
    });
  });

  group('Pakistan, a month', () {
    final LumeTaxResult t = taxFor('PK');

    test('the headline the capture prints', () {
      expect(t.dueDisplay, 228900);
      expect(t.netDisplay, 620100);
      expect(t.taxableAnnual, 10188000);
      expect(t.marginal, 0.35);
      expect((t.effective * 1000).round() / 10, 27);
    });

    test('all six bands, and the tax inside each', () {
      expect(t.bands, hasLength(6));
      expect(t.bands.map((LumeTaxBandResult b) => b.tax).toList(), <double>[
        0,
        6000,
        110000,
        230000,
        270000,
        2130800,
      ]);
      expect(t.bands.last.isTop, isTrue);
    });
  });

  test('Pakistan, a year: the same figure read as annual', () {
    // `period:year` keeps the field's 849,000 and reads it as a year.
    final LumeTaxResult t = taxFor('PK', period: LumeTaxPeriod.year);
    expect(t.dueDisplay, 2490);
    expect(t.netDisplay, 846510);
    expect(t.marginal, 0.01);
    expect(
      t.bands,
      hasLength(2),
      reason: 'it stops at the band income ends in',
    );
  });

  test('the United States', () {
    final LumeTaxResult t = taxFor('US');
    // 4,081.50 a year is 340.125 a month; the capture prints it whole.
    expect(t.dueDisplay, 340.125);
    expect(t.netDisplay.round(), 2660);
    expect(t.bands.map((LumeTaxBandResult b) => b.tax).toList(), <double>[
      1192.5,
      2889,
    ]);
    expect((t.effective * 1000).round() / 10, 11.3);
  });

  test('the United Kingdom', () {
    final LumeTaxResult t = taxFor('GB');
    expect(t.dueDisplay.round(), 191);
    expect(t.netDisplay.round(), 1810);
    expect((t.effective * 1000).round() / 10, 9.5);
    expect(t.marginal, 0.2);
  });

  group('the edges', () {
    test('deductions can take income below the first band', () {
      final LumeTaxResult t = taxFor('PK', income: 50000, deductions: 600000);
      expect(t.taxableAnnual, 0);
      expect(t.dueAnnual, 0);
      expect(t.marginal, 0);
      expect(t.bands, hasLength(1));
    });

    test('no income is no tax and a zero rate, not a division by zero', () {
      final LumeTaxResult t = taxFor('PK', income: 0);
      expect(t.effective, 0);
      expect(t.netAnnual, 0);
    });

    test(
      'deductions larger than income do not make taxable income negative',
      () {
        final LumeTaxResult t = taxFor('GB', income: 1000, deductions: 99999);
        expect(t.taxableAnnual, 0);
      },
    );

    test('a market with one zero band is not taxable', () {
      expect(lumeTaxConfigFor('AE')!.taxable, isFalse);
      expect(lumeTaxConfigFor('SA')!.taxable, isFalse);
      expect(lumeTaxConfigFor('PK')!.taxable, isTrue);
      expect(lumeTaxConfigFor('JP'), isNull);
    });

    test('levies fall back to VAT at twenty', () {
      expect(lumeLeviesFor('AE').map((LumeLevyRate l) => l.rate), <double>[
        5,
        5,
        9,
      ]);
      expect(lumeLeviesFor('JP').single.rate, 20);
    });

    test('Math.round rounds a half up', () {
      expect(LumeTaxRules.jsRound(2.5), 3);
      expect(LumeTaxRules.jsRound(-2.5), -2);
    });
  });
}

/// Zakat's arithmetic — a line-by-line port of `context.js` `zakat()`.
///
/// No web capture exists for this tool (`docs/conversion_archive/measurements`
/// has none named `tool_zakat_*`), so every expected figure below is worked
/// out by hand from the reference's own formula, not read off a capture. Two
/// currencies are covered — USD, where the reference's rate table is exactly
/// 1 and the arithmetic is easiest to check by eye, and PKR, the app's other
/// primary market — plus the boundary the reference's own comment calls out:
/// the *silver* nisab is the lower one, and the one `eligible` is tested
/// against.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_reference_rates.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/features/goldrates/data/goldrates_fixtures.dart';
import 'package:lume/features/zakat/domain/zakat_maths.dart';

LumeMoney money(double major, LumeCurrency currency) =>
    LumeMoney.sum((major * currency.scale).round(), currency);

LumeZakatResult zakatFor(
  String code, {
  double cash = 0,
  double gold = 0,
  double silver = 0,
  double investments = 0,
  double business = 0,
  double liabilities = 0,
}) {
  final LumeCurrency currency = LumeCurrency.of(code);
  return LumeZakatRules.compute(
    inputs: LumeZakatInputs(
      cash: money(cash, currency),
      goldGrams: gold,
      silverGrams: silver,
      investments: money(investments, currency),
      business: money(business, currency),
      liabilities: money(liabilities, currency),
    ),
    metals: LumeMetals.forCurrency(code),
  );
}

void main() {
  group('the opening fields', () {
    test('are the reference\'s own defaults, rounded to the hundred', () {
      final LumeCurrency usd = LumeCurrency.of('USD');
      final LumeCurrency pkr = LumeCurrency.of('PKR');
      // `Math.round(4000 * rate / 100) * 100`.
      expect(LumeZakatRules.openingCash(1, usd).minor, 400000); // $4,000.00
      expect(
        LumeZakatRules.openingCash(lumeRatePerUsd('PKR'), pkr).minor,
        113200000, // Rs 1,132,000.00
      );
      // `Math.round(2000 * rate / 100) * 100`.
      expect(LumeZakatRules.openingInvestments(1, usd).minor, 200000);
      expect(
        LumeZakatRules.openingInvestments(lumeRatePerUsd('PKR'), pkr).minor,
        56600000, // Rs 566,000.00
      );
      // `Math.round(500 * rate / 100) * 100`.
      expect(LumeZakatRules.openingLiabilities(1, usd).minor, 50000);
      expect(
        LumeZakatRules.openingLiabilities(lumeRatePerUsd('PKR'), pkr).minor,
        14150000, // Rs 141,500.00
      );
    });
  });

  group('nisab — the reference tests against the lower threshold', () {
    test('silver, not gold, is the one eligibility is tested against', () {
      // goldPerGram = 88, silverPerGram = 1.05 at USD's rate of 1.
      // nisabGold = 87.48 * 88 = 7,698.24 — nisabSilver = 612.36 * 1.05 =
      // 642.978. The comment in `context.js` says plainly the silver one is
      // lower, and this is the number `net >= nisab` actually reads.
      final LumeZakatResult z = zakatFor('USD');
      expect(z.nisabGold.minor, 769824);
      expect(z.nisabSilver.minor, 64298); // rounds 642.978 → 642.98
      expect(z.nisab, z.nisabSilver);
      expect(z.nisab.minor, lessThan(z.nisabGold.minor));
    });

    test('the same holds in PKR, at the reference\'s own rate', () {
      final LumeZakatResult z = zakatFor('PKR');
      // goldPerGram = 88 * 283 = 24,904 — nisabGold = 87.48 * 24,904 =
      // 2,178,601.92. silverPerGram = 1.05 * 283 = 297.15 — nisabSilver =
      // 612.36 * 297.15 = 181,962.774, rounding to the paisa.
      expect(z.nisabGold.minor, 217860192);
      expect(z.nisabSilver.minor, 18196277);
      expect(z.nisab, z.nisabSilver);
    });
  });

  group('the headline figure, at the reference\'s own opening fields', () {
    test('Pakistan: eligible, and 2.5% of net assets', () {
      final LumeZakatResult z = zakatFor(
        'PKR',
        cash: 1132000,
        gold: 40,
        investments: 566000,
        liabilities: 141500,
      );
      // goldValue = 40 * 24,904 = 996,160.
      expect(z.goldValue.minor, 99616000);
      expect(z.silverValue.minor, 0);
      // net = 1,132,000 + 996,160 + 566,000 − 141,500 = 2,552,660.
      expect(z.net.minor, 255266000);
      expect(z.eligible, isTrue);
      // due = 2,552,660 * 0.025 = 63,816.50.
      expect(z.due.minor, 6381650);
    });

    test('the United States, at its own opening fields', () {
      final LumeZakatResult z = zakatFor(
        'USD',
        cash: 4000,
        gold: 40,
        investments: 2000,
        liabilities: 500,
      );
      // goldValue = 40 * 88 = 3,520. net = 4,000 + 3,520 + 2,000 − 500 =
      // 9,020. due = 9,020 * 0.025 = 225.50.
      expect(z.goldValue.minor, 352000);
      expect(z.net.minor, 902000);
      expect(z.eligible, isTrue);
      expect(z.due.minor, 22550);
    });
  });

  group('below nisab', () {
    test('nothing owned at all is not eligible, and due is zero, not refused', () {
      final LumeZakatResult z = zakatFor('USD');
      expect(z.net.minor, 0);
      expect(z.eligible, isFalse);
      expect(z.due, LumeMoney.zero(LumeCurrency.of('USD')));
    });

    test('cash alone, under the silver nisab, stays under', () {
      // $600 is under $642.978; $650 clears it.
      final LumeZakatResult under = zakatFor('USD', cash: 600);
      expect(under.eligible, isFalse);
      expect(under.due.minor, 0);

      final LumeZakatResult over = zakatFor('USD', cash: 650);
      expect(over.eligible, isTrue);
      expect(over.due.minor, greaterThan(0));
    });

    test('liabilities can take net below zero, never clamped', () {
      final LumeZakatResult z = zakatFor(
        'USD',
        cash: 1000,
        liabilities: 5000,
      );
      expect(z.net.minor, -400000); // −$4,000.00, signed, not floored at 0
      expect(z.eligible, isFalse);
      expect(z.due.minor, 0);
    });
  });

  group('the eight breakdown rows, in the reference\'s own order', () {
    test('cash, gold, silver, investments, business, liabilities, net, due', () {
      final LumeZakatResult z = zakatFor(
        'USD',
        cash: 1000,
        gold: 10,
        silver: 50,
        investments: 500,
        business: 200,
        liabilities: 300,
      );
      expect(z.lines.map((LumeZakatLine l) => l.kind).toList(), <
        LumeZakatLineKind
      >[
        LumeZakatLineKind.cash,
        LumeZakatLineKind.gold,
        LumeZakatLineKind.silver,
        LumeZakatLineKind.investments,
        LumeZakatLineKind.business,
        LumeZakatLineKind.liabilities,
        LumeZakatLineKind.netAssets,
        LumeZakatLineKind.payable,
      ]);
      // The liabilities row is signed negative — `-Number(f.liab)`.
      final LumeZakatLine liab = z.lines[5];
      expect(liab.amount.isNegative, isTrue);
      expect(liab.amount.minor, -30000);
      // Gold and silver carry the grams they were valued at; nothing else
      // does.
      expect(z.lines[1].grams, 10);
      expect(z.lines[2].grams, 50);
      expect(z.lines[0].grams, isNull);
      expect(z.lines[3].grams, isNull);
    });
  });

  group('rate and scaling', () {
    test('the rate is exactly 2.5%', () {
      expect(LumeZakatRules.rate, 0.025);
    });

    test('scale rounds to the nearest minor unit, not truncates', () {
      final LumeMoney m = LumeMoney.sum(1000000001, LumeCurrency.of('USD'));
      // 1,000,000,001 * 0.025 = 25,000,000.025 → rounds to 25,000,000.
      expect(LumeZakatRules.scale(m, 0.025).minor, 25000000);
    });
  });
}

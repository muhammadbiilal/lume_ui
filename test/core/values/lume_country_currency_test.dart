/// A country's current currency: the reference's table, dated corrections
/// on top, and never a reinterpretation of a stored amount.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/core/values/lume_country_currency.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/features/onboarding/data/country_fixture.dart';

void main() {
  setUpAll(initializeDateFormatting);

  final String asset = File(LumeCountryFixture.assetPath).readAsStringSync();

  group('the table', () {
    test('the reference half is the bundled country table, exactly', () {
      final Map<String, Object?> json =
          jsonDecode(asset) as Map<String, Object?>;
      final Map<String, String> bundled = <String, String>{
        for (final Object? c in json['countries']! as List<Object?>)
          (c! as Map<String, Object?>)['code']! as String:
              (c as Map<String, Object?>)['currency']! as String,
      };
      expect(LumeCountryCurrency.reference, bundled);
      expect(bundled, hasLength(194));
    });

    test('every change is dated, sourced, and moves off the reference', () {
      for (final LumeCurrencyChange c in LumeCountryCurrency.changes) {
        expect(LumeCountryCurrency.reference[c.country], c.from);
        expect(LumeCurrency.of(c.to).active, isTrue, reason: c.to);
        expect(LumeCurrency.of(c.from).active, isFalse, reason: c.from);
        expect(c.effective.toIso(), c.effectiveIso);
        expect(c.source, isNotEmpty);
      }
      // The version is the newest change's date.
      expect(
        LumeCountryCurrency.asOf,
        (LumeCountryCurrency.changes
                .map((LumeCurrencyChange c) => c.effective)
                .toList()
              ..sort())
            .last
            .toIso(),
      );
    });

    test('Bulgaria: the euro from 1 January 2026, at the fixed rate', () {
      final LumeCurrencyChange bg = LumeCountryCurrency.changes.single;
      expect(bg.country, 'BG');
      expect((bg.from, bg.to), ('BGN', 'EUR'));
      expect(bg.effective, LumeDate(2026, 1, 1));
      expect(bg.fixedRate, '1.95583');
      expect(LumeCountryCurrency.current('BG'), 'EUR');
      expect(LumeCountryCurrency.reference['BG'], 'BGN');
    });

    test('no current default is a withdrawn currency', () {
      for (final String country in LumeCountryCurrency.reference.keys) {
        final String code = LumeCountryCurrency.current(country)!;
        expect(LumeCurrency.of(code).active, isTrue, reason: country);
      }
    });

    test('an unknown country has no current currency', () {
      expect(LumeCountryCurrency.current('ZZ'), isNull);
    });
  });

  group('a new Bulgarian profile', () {
    test('the country table offers EUR, not the lev', () {
      final LumeCountryFixture table = LumeCountryFixture.parse(asset);
      expect(table.currencyOf('BG'), 'EUR');
      expect(
        table
            .forLanguage('en')
            .where((c) => c.currency == 'BGN')
            .map((c) => c.code),
        isEmpty,
      );
      // The rest of the table is the reference's.
      expect(table.currencyOf('PK'), 'PKR');
      expect(table.currencyOf('HR'), 'EUR');
    });

    test('automatic currency follows the table, in every language', () {
      for (final String language in <String>['en', 'ur', 'ar']) {
        final LumeFormatting f = LumeFormatting(
          locale: Locale(language),
          countryCode: 'BG',
        );
        expect(f.currency, 'EUR', reason: language);
      }
      // Beyond the markets the formatter used to name: the table's own.
      expect(
        const LumeFormatting(locale: Locale('en'), countryCode: 'DE').currency,
        'EUR',
      );
      expect(
        const LumeFormatting(locale: Locale('en'), countryCode: 'NP').currency,
        'NPR',
      );
      // The reader's own choice still wins.
      expect(
        const LumeFormatting(
          locale: Locale('en'),
          countryCode: 'BG',
          currencyCode: 'BGN',
        ).currency,
        'BGN',
      );
    });
  });

  group('precision and formatting', () {
    final LumeCurrency eur = LumeCurrency.of('EUR');
    final LumeCurrency bgn = LumeCurrency.of('BGN');

    test('both keep two decimal places; neither rounds', () {
      expect(eur.exponent, 2);
      expect(bgn.exponent, 2);
      expect(eur.active, isTrue);
      expect(bgn.active, isFalse);
      expect(LumeMoney.parse('1234.56', eur).minor, 123456);
      expect(LumeMoney.parse('1234.56', bgn).minor, 123456);
      expect(
        () => LumeMoney.parse('1.005', eur),
        throwsA(isA<LumeMoneyException>()),
      );
      expect(
        () => LumeMoney.parse('1.005', bgn),
        throwsA(isA<LumeMoneyException>()),
      );
    });

    test('each shows its own code — the lev is never drawn as the euro', () {
      for (final String language in <String>['en', 'ur', 'ar']) {
        final LumeFormatting f = LumeFormatting(
          locale: Locale(language),
          countryCode: 'BG',
        );
        final String e = f.amount(LumeMoney.entry(123456, eur));
        final String b = f.amount(LumeMoney.entry(123456, bgn));
        expect(e, contains('EUR'), reason: language);
        expect(e, contains('1,234.56'), reason: language);
        expect(b, contains('BGN'), reason: language);
        expect(b, contains('1,234.56'), reason: language);
        expect(b, isNot(contains('EUR')));
        expect(e, isNot(contains('BGN')));
      }
    });

    test('the same minor units are never equal across the two', () {
      expect(LumeMoney.entry(100, eur) == LumeMoney.entry(100, bgn), isFalse);
      expect(
        () => LumeMoney.entry(100, eur) + LumeMoney.entry(100, bgn),
        throwsA(isA<LumeMoneyException>()),
      );
    });
  });
}

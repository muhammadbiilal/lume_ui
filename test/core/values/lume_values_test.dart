/// The shared financial value types: LumeCurrency, LumeMoney, LumeRecordId
/// and LumeDate — small, immutable, exact, and strict at construction.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';

final LumeCurrency pkr = LumeCurrency.of('PKR');
final LumeCurrency usd = LumeCurrency.of('USD');
final LumeCurrency jpy = LumeCurrency.of('JPY');
final LumeCurrency kwd = LumeCurrency.of('KWD');

Matcher throwsMoney(LumeMoneyFailure f) => throwsA(
  isA<LumeMoneyException>().having(
    (LumeMoneyException e) => e.failure,
    'failure',
    f,
  ),
);

void main() {
  group('LumeCurrency', () {
    test('the code is the identity; the exponent is ISO\'s', () {
      expect(pkr.exponent, 2);
      expect(jpy.exponent, 0);
      expect(kwd.exponent, 3);
      expect(LumeCurrency.of('CLF').exponent, 4);
      expect(LumeCurrency.of('ISK').exponent, 0);
      expect(LumeCurrency.of('IQD').exponent, 3);
      expect(LumeCurrency.of('PKR'), pkr);
      expect(LumeCurrency.of('PKR').hashCode, pkr.hashCode);
      expect(pkr, isNot(usd));
      expect(pkr.scale, 100);
      expect(kwd.scale, 1000);
      expect(jpy.scale, 1);
    });

    test('an unknown or malformed code is a typed refusal', () {
      for (final (String code, LumeCurrencyFailure why)
          in <(String, LumeCurrencyFailure)>[
            ('XYZ', LumeCurrencyFailure.unknown),
            ('XAU', LumeCurrencyFailure.unknown),
            ('XXX', LumeCurrencyFailure.unknown),
            ('pkr', LumeCurrencyFailure.malformed),
            ('PK', LumeCurrencyFailure.malformed),
            ('', LumeCurrencyFailure.malformed),
            (r'$', LumeCurrencyFailure.malformed),
          ]) {
        expect(
          () => LumeCurrency.of(code),
          throwsA(
            isA<LumeCurrencyException>().having(
              (LumeCurrencyException e) => e.failure,
              'failure',
              why,
            ),
          ),
          reason: code,
        );
        expect(LumeCurrency.tryOf(code), isNull);
      }
    });

    test('a withdrawn code still reads, and is never offered', () {
      final LumeCurrency hrk = LumeCurrency.of('HRK');
      expect(hrk.active, isFalse);
      expect(hrk.exponent, 2);
      expect(LumeCurrency.offered, isNot(contains(hrk)));
      expect(LumeCurrency.offered, contains(pkr));
      expect(LumeCurrency.offered.every((LumeCurrency c) => c.active), isTrue);
    });

    test('every currency the country table names is known', () {
      final Map<String, dynamic> table =
          jsonDecode(File('assets/data/countries.json').readAsStringSync())
              as Map<String, dynamic>;
      final Set<String> withdrawn = <String>{};
      for (final dynamic c in table['countries'] as List<dynamic>) {
        final String code = (c as Map<String, dynamic>)['currency'] as String;
        final LumeCurrency? cur = LumeCurrency.tryOf(code);
        expect(cur, isNotNull, reason: code);
        if (!cur!.active) withdrawn.add(code);
      }
      // Bulgaria's table entry predates its 2026 move to the euro.
      expect(withdrawn, <String>{'BGN'});
    });
  });

  group('LumeMoney', () {
    test('equality and hashing are minor units and currency', () {
      expect(LumeMoney.entry(100, pkr), LumeMoney.entry(100, pkr));
      expect(
        LumeMoney.entry(100, pkr).hashCode,
        LumeMoney.entry(100, pkr).hashCode,
      );
      expect(LumeMoney.entry(100, pkr), isNot(LumeMoney.entry(100, usd)));
      expect(LumeMoney.entry(100, pkr), isNot(LumeMoney.entry(101, pkr)));
    });

    test('parsing at exactly the exponent, never rounding', () {
      expect(LumeMoney.parse('34000', pkr).minor, 3400000);
      expect(LumeMoney.parse('34000.5', pkr).minor, 3400050);
      expect(LumeMoney.parse('34000.50', pkr).minor, 3400050);
      expect(LumeMoney.parse('0.01', pkr).minor, 1);
      expect(LumeMoney.parse('5000', jpy).minor, 5000);
      expect(LumeMoney.parse('1.250', kwd).minor, 1250);
      expect(LumeMoney.parse('1.25', kwd).minor, 1250);
      expect(
        () => LumeMoney.parse('12.345', pkr),
        throwsMoney(LumeMoneyFailure.precision),
      );
      expect(
        () => LumeMoney.parse('1.5', jpy),
        throwsMoney(LumeMoneyFailure.precision),
      );
      expect(
        () => LumeMoney.parse('1.2345', kwd),
        throwsMoney(LumeMoneyFailure.precision),
      );
    });

    test('anything but a machine decimal is malformed', () {
      for (final String t in <String>[
        '',
        '-1',
        '+1',
        '1,000',
        '1.',
        '.5',
        '1e3',
        ' 1',
        '١٢',
        'NaN',
      ]) {
        expect(
          () => LumeMoney.parse(t, pkr),
          throwsMoney(LumeMoneyFailure.malformed),
          reason: t,
        );
      }
    });

    test('an entry is bounded at 10^15 minor units, exactly', () {
      expect(
        LumeMoney.entry(LumeMoney.maxEntryMinor, pkr).minor,
        1000000000000000,
      );
      expect(
        () => LumeMoney.entry(LumeMoney.maxEntryMinor + 1, pkr),
        throwsMoney(LumeMoneyFailure.overflow),
      );
      expect(
        LumeMoney.parse('10000000000000', pkr).minor,
        LumeMoney.maxEntryMinor,
      );
      expect(
        () => LumeMoney.parse('10000000000000.01', pkr),
        throwsMoney(LumeMoneyFailure.overflow),
      );
      expect(
        () => LumeMoney.parse('99999999999999999999', pkr),
        throwsMoney(LumeMoneyFailure.overflow),
      );
      expect(
        () => LumeMoney.entry(-1, pkr),
        throwsMoney(LumeMoneyFailure.negative),
      );
      expect(LumeMoney.entry(0, pkr).isZero, isTrue);
    });

    test('sums are bounded at 2^53 − 1 in magnitude; never wrapped', () {
      final LumeMoney top = LumeMoney.sum(LumeMoney.maxSumMinor, pkr);
      expect(top.minor, 9007199254740991);
      expect(
        () => top + LumeMoney.entry(1, pkr),
        throwsMoney(LumeMoneyFailure.overflow),
      );
      expect(
        () => -top - LumeMoney.entry(1, pkr),
        throwsMoney(LumeMoneyFailure.overflow),
      );
      expect(
        () => LumeMoney.sum(LumeMoney.maxSumMinor + 1, pkr),
        throwsMoney(LumeMoneyFailure.overflow),
      );
      // Nine maximal entries fit; the tenth total of maxima does not.
      final List<LumeMoney> many = List<LumeMoney>.filled(
        9,
        LumeMoney.entry(LumeMoney.maxEntryMinor, pkr),
      );
      expect(LumeMoney.total(many, pkr).minor, 9 * LumeMoney.maxEntryMinor);
      expect(
        () => LumeMoney.total(<LumeMoney>[...many, many.first], pkr),
        throwsMoney(LumeMoneyFailure.overflow),
      );
    });

    test('no arithmetic or comparison crosses currencies', () {
      final LumeMoney a = LumeMoney.entry(100, pkr);
      final LumeMoney b = LumeMoney.entry(100, usd);
      expect(() => a + b, throwsMoney(LumeMoneyFailure.currencyMismatch));
      expect(() => a - b, throwsMoney(LumeMoneyFailure.currencyMismatch));
      expect(
        () => a.compareTo(b),
        throwsMoney(LumeMoneyFailure.currencyMismatch),
      );
      expect(
        () => LumeMoney.total(<LumeMoney>[a, b], pkr),
        throwsMoney(LumeMoneyFailure.currencyMismatch),
      );
    });

    test('checked arithmetic is exact where binary floating point is not', () {
      final LumeMoney a = LumeMoney.parse('0.1', usd);
      final LumeMoney b = LumeMoney.parse('0.2', usd);
      expect((a + b).minor, 30);
      expect((a - b).minor, -10);
      expect((a - b).magnitude.minor, 10);
      expect((a - b).isNegative, isTrue);
      expect(LumeMoney.min(a, b), a);
    });

    test('the machine decimal round-trips at the exponent', () {
      for (final (LumeMoney m, String s) in <(LumeMoney, String)>[
        (LumeMoney.entry(3400000, pkr), '34000.00'),
        (LumeMoney.entry(3400050, pkr), '34000.50'),
        (LumeMoney.entry(1, pkr), '0.01'),
        (LumeMoney.entry(5000, jpy), '5000'),
        (LumeMoney.entry(1250, kwd), '1.250'),
        (LumeMoney.sum(-1250, kwd), '-1.250'),
      ]) {
        expect(m.toDecimalString(), s);
        if (!m.isNegative) expect(LumeMoney.parse(s, m.currency), m);
      }
      expect(LumeMoney.entry(3400000, pkr).isWhole, isTrue);
      expect(LumeMoney.entry(3400050, pkr).isWhole, isFalse);
    });
  });

  group('formatting a stored amount', () {
    LumeFormatting fmt(String lang, [String country = 'PK']) =>
        LumeFormatting(locale: Locale(lang), countryCode: country);

    test('full precision by default; compact drops only zero digits', () {
      final LumeFormatting f = fmt('en');
      expect(f.amount(LumeMoney.entry(3400000, pkr)), 'Rs\u00a034,000.00');
      expect(
        f.amount(LumeMoney.entry(3400000, pkr), compact: true),
        'Rs\u00a034,000',
      );
      expect(
        f.amount(LumeMoney.entry(3400050, pkr), compact: true),
        'Rs\u00a034,000.50',
      );
      expect(f.amount(LumeMoney.entry(5000, jpy)), '¥5,000');
      expect(f.amount(LumeMoney.entry(1250, kwd)), 'KWD\u00a01.250');
      expect(
        f.amount(LumeMoney.entry(1250, kwd), compact: true),
        'KWD\u00a01.250',
      );
      expect(f.amount(LumeMoney.entry(1000, kwd), compact: true), 'KWD\u00a01');
    });

    test('exact past double precision', () {
      final LumeMoney big = LumeMoney.sum(LumeMoney.maxSumMinor, pkr);
      expect(fmt('en').amount(big), 'Rs\u00a090,071,992,547,409.91');
      final LumeMoney k = LumeMoney.sum(9007199254740991, kwd);
      expect(fmt('en').amount(k), 'KWD\u00a09,007,199,254,740.991');
    });

    test('the magnitude is written; the sign never carries direction', () {
      expect(
        fmt('en').amount(LumeMoney.sum(-3400000, pkr)),
        'Rs\u00a034,000.00',
      );
    });

    test('the code in place of a shared symbol', () {
      expect(fmt('en', 'US').amount(LumeMoney.entry(5000, usd)), r'$50.00');
      expect(
        fmt('en', 'US').amount(LumeMoney.entry(5000, usd), withCode: true),
        'USD\u00a050.00',
      );
    });

    test('bidi-safe: isolated, and the digits are the locale\'s', () {
      for (final String lang in <String>['en', 'ur', 'ar']) {
        final String s = fmt(
          lang,
        ).amount(LumeMoney.entry(3400050, pkr), isolate: true);
        expect(s.startsWith('\u2068'), isTrue, reason: lang);
        expect(s.endsWith('\u2069'), isTrue, reason: lang);
        final String plain = fmt(lang).amount(LumeMoney.entry(3400050, pkr));
        // The fraction written into the whole is in the same digits as it.
        final String zero = plain.contains('٠') || plain.contains('٣')
            ? '٠'
            : '0';
        expect(
          plain.contains(zero == '0' ? '50' : '٥٠'),
          isTrue,
          reason: '$lang $plain',
        );
      }
    });
  });

  group('LumeRecordId', () {
    test('canonical lowercase; equality, hash and order by the text', () {
      final LumeRecordId a = LumeRecordId.parse(
        '3F2504E0-4F89-41D3-9A0C-0305E82C3301',
      );
      expect(a.value, '3f2504e0-4f89-41d3-9a0c-0305e82c3301');
      expect(a, LumeRecordId.parse('3f2504e0-4f89-41d3-9a0c-0305e82c3301'));
      expect(a.hashCode, LumeRecordId.parse(a.value).hashCode);
      final LumeRecordId b = LumeRecordId.parse(
        '3f2504e0-4f89-41d3-9a0c-0305e82c3302',
      );
      expect(a.compareTo(b), lessThan(0));
      expect(<LumeRecordId>[b, a]..sort(), <LumeRecordId>[a, b]);
    });

    test('strict: no braces, urn, missing hyphens or stray text', () {
      for (final String t in <String>[
        '',
        '{3f2504e0-4f89-41d3-9a0c-0305e82c3301}',
        'urn:uuid:3f2504e0-4f89-41d3-9a0c-0305e82c3301',
        '3f2504e04f8941d39a0c0305e82c3301',
        '3f2504e0-4f89-41d3-9a0c-0305e82c330',
        '3f2504e0-4f89-41d3-9a0c-0305e82c3301 ',
        'g f2504e0-4f89-41d3-9a0c-0305e82c3301',
        'tod-1',
      ]) {
        expect(
          () => LumeRecordId.parse(t),
          throwsA(isA<LumeRecordIdException>()),
          reason: t,
        );
      }
    });

    test('generated: version 4, the variant bits, canonical, and '
        'reproducible from a seeded source', () {
      final LumeRecordId a = LumeRecordId.generate(Random(7));
      expect(LumeRecordId.parse(a.value), a);
      expect(a.value[14], '4');
      expect('89ab'.contains(a.value[19]), isTrue);
      expect(LumeRecordId.generate(Random(7)), a);
      final Set<LumeRecordId> many = <LumeRecordId>{
        for (int i = 0; i < 1000; i++) LumeRecordId.generate(),
      };
      expect(many.length, 1000);
    });
  });

  group('LumeDate', () {
    test('strict construction, leap years included', () {
      expect(LumeDate(2028, 2, 29).toIso(), '2028-02-29');
      expect(LumeDate(2000, 2, 29).day, 29);
      for (final (int y, int m, int d) in <(int, int, int)>[
        (2026, 2, 29),
        (1900, 2, 29),
        (2026, 2, 30),
        (2026, 4, 31),
        (2026, 13, 1),
        (2026, 0, 1),
        (2026, 1, 0),
        (0, 1, 1),
        (10000, 1, 1),
      ]) {
        expect(
          () => LumeDate(y, m, d),
          throwsA(isA<LumeDateException>()),
          reason: '$y-$m-$d',
        );
      }
    });

    test('ISO serialisation round-trips; anything else is refused', () {
      final LumeDate d = LumeDate.parse('2026-09-07');
      expect(d, LumeDate(2026, 9, 7));
      expect(d.toIso(), '2026-09-07');
      expect(d.hashCode, LumeDate(2026, 9, 7).hashCode);
      for (final String t in <String>[
        '2026-9-7',
        '2026-09-07T00:00',
        '07/09/2026',
        '2026-02-30',
        '',
      ]) {
        expect(LumeDate.tryParse(t), isNull, reason: t);
      }
    });

    test('calendar comparison and day arithmetic', () {
      final LumeDate a = LumeDate(2026, 8, 31);
      final LumeDate b = LumeDate(2026, 9, 1);
      expect(a.isBefore(b), isTrue);
      expect(b.isAfter(a), isTrue);
      expect(a.compareTo(a), 0);
      expect(a.addDays(1), b);
      expect(LumeDate(2028, 2, 28).addDays(1), LumeDate(2028, 2, 29));
      expect(LumeDate(2026, 12, 31).addDays(1), LumeDate(2027, 1, 1));
      expect(a.daysUntil(b), 1);
      expect(b.daysUntil(a), -1);
      // Across a daylight-saving change the count is still whole days.
      expect(LumeDate(2026, 3, 1).daysUntil(LumeDate(2026, 4, 1)), 31);
    });

    test('a wall clock gives its own date — no zone is applied', () {
      expect(
        LumeDate.ofWallClock(DateTime(2026, 9, 7, 23, 59)),
        LumeDate(2026, 9, 7),
      );
    });
  });
}

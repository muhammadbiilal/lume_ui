/// The factor table, checked against the standards that define the units.
///
/// This file is the reason Unit Converter was held for three waves. The
/// reference's digital-storage factors are binary under decimal names and its
/// gallon is a US gallon shown to every reader, and both are the kind of
/// defect that looks like a rounding difference in a screenshot and is a
/// wrong answer in the reader's hand. So every factor is asserted here
/// against its defining value, and the two policy rules are asserted as
/// rules, not only as rows — a future unit added under a decimal name with a
/// binary factor has to fail something.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/converter/domain/lume_ratio.dart';
import 'package:lume/features/converter/domain/unit_table.dart';

/// `amount` of `from` in `to`, to four decimals — what the screen shows.
String shown(String amount, String from, String to, {int places = 4}) =>
    lumeConvert(
      LumeRatio.parse(amount),
      lumeUnit(from),
      lumeUnit(to),
    ).toStringAsFixedMax(places);

/// The exact ratio, for an assertion that must not round at all.
LumeRatio exact(String amount, String from, String to) =>
    lumeConvert(LumeRatio.parse(amount), lumeUnit(from), lumeUnit(to));

void main() {
  group('the table itself', () {
    test('32 units across six categories', () {
      expect(kLumeUnits, hasLength(32));
      expect(lumeUnitsOf(LumeUnitKind.length), hasLength(6));
      expect(lumeUnitsOf(LumeUnitKind.mass), hasLength(5));
      expect(lumeUnitsOf(LumeUnitKind.volume), hasLength(5));
      expect(lumeUnitsOf(LumeUnitKind.area), hasLength(4));
      expect(lumeUnitsOf(LumeUnitKind.speed), hasLength(3));
      expect(lumeUnitsOf(LumeUnitKind.data), hasLength(9));
      // The reference ships 25 and badges "32 units". The corrected table
      // happens to be 32 — the badge is true now, which it was not.
      expect(kLumeUnits.length, 32);
    });

    test('every id is unique and every category has exactly one base', () {
      expect(kLumeUnits.map((LumeUnit u) => u.id).toSet(), hasLength(32));
      for (final LumeUnitKind kind in LumeUnitKind.values) {
        final List<LumeUnit> units = lumeUnitsOf(kind);
        expect(
          units.where((LumeUnit u) => u.factor == LumeRatio.one),
          hasLength(1),
          reason: '$kind',
        );
        expect(units.first.factor, LumeRatio.one, reason: '$kind leads');
      }
    });

    test('no factor is zero or negative', () {
      for (final LumeUnit u in kLumeUnits) {
        expect(u.factor.isZero, isFalse, reason: u.id);
        expect(u.factor.isNegative, isFalse, reason: u.id);
      }
    });

    test('every default pair names two real units of its own category', () {
      for (final MapEntry<LumeUnitKind, (String, String)> e
          in kLumeUnitDefaults.entries) {
        final LumeUnit from = lumeUnit(e.value.$1);
        final LumeUnit to = lumeUnit(e.value.$2);
        expect(from.kind, e.key);
        expect(to.kind, e.key);
        expect(from.id, isNot(to.id));
      }
    });
  });

  group('digital storage — decimal names, decimal factors', () {
    test('the SI family is powers of a thousand', () {
      expect(shown('1', 'kB', 'B'), '1000');
      expect(shown('1', 'MB', 'B'), '1000000');
      expect(shown('1', 'GB', 'B'), '1000000000');
      expect(shown('1', 'TB', 'B'), '1000000000000');
      // And so 1 GB is a thousand MB, not the reference's 1024.
      expect(shown('1', 'GB', 'MB'), '1000');
      expect(shown('1', 'TB', 'MB'), '1000000');
    });

    test('the binary family is powers of 1024, under its own names', () {
      expect(shown('1', 'KiB', 'B'), '1024');
      expect(shown('1', 'MiB', 'B'), '1048576');
      expect(shown('1', 'GiB', 'B'), '1073741824');
      expect(shown('1', 'TiB', 'B'), '1099511627776');
    });

    test('no decimal name carries a binary factor', () {
      const Set<String> decimal = <String>{'kB', 'MB', 'GB', 'TB'};
      const Set<String> binary = <String>{'KiB', 'MiB', 'GiB', 'TiB'};
      final Set<LumeRatio> binaryFactors = <LumeRatio>{
        for (final String id in binary) lumeUnit(id).factor,
      };
      for (final String id in decimal) {
        expect(
          binaryFactors,
          isNot(contains(lumeUnit(id).factor)),
          reason: '$id must not be a power of 1024',
        );
      }
      // Stated the other way round, so a new unit cannot slip past: every
      // data unit whose factor is a power of 1024 above 1 is named with the
      // IEC `i`.
      for (final LumeUnit u in lumeUnitsOf(LumeUnitKind.data)) {
        final String bytes = u.factor.toStringAsFixedMax(0);
        final bool isPowerOf1024 = <String>[
          '1024',
          '1048576',
          '1073741824',
          '1099511627776',
        ].contains(bytes);
        expect(
          isPowerOf1024,
          u.symbol.contains('i'),
          reason: '${u.id} is $bytes bytes and is named ${u.symbol}',
        );
      }
    });

    test('the reference is wrong by these amounts, and this says so', () {
      // Its GB is 1024 MB: 2.4 % over. Its TB is 1024² MB: 4.9 % over.
      expect(shown('1', 'GiB', 'MB'), '1073.7418');
      expect(shown('1', 'TiB', 'MB'), '1099511.6278');
    });
  });

  group('volume — two gallons, both named', () {
    test('no unit is ever a bare gallon', () {
      final List<LumeUnit> gallons = kLumeUnits
          .where((LumeUnit u) => u.id.startsWith('gal'))
          .toList();
      expect(gallons, hasLength(2));
      expect(gallons.map((LumeUnit u) => u.id), <String>['gal_us', 'gal_imp']);
    });

    test('each is its defined size', () {
      expect(shown('1', 'gal_us', 'L'), '3.7854');
      expect(shown('1', 'gal_imp', 'L'), '4.5461');
      expect(shown('1', 'gal_us', 'L', places: 9), '3.785411784');
      expect(shown('1', 'gal_imp', 'L', places: 9), '4.54609');
    });

    test('an Imperial gallon is 20.1 % larger than a US one', () {
      expect(shown('1', 'gal_imp', 'gal_us', places: 4), '1.2009');
      // Which is why the reference's bare `gal` tells a UK reader 16.7 %
      // too little: ten of their gallons read as 37.85 L, not 45.46.
      expect(shown('10', 'gal_us', 'L'), '37.8541');
      expect(shown('10', 'gal_imp', 'L'), '45.4609');
    });

    test('the cup is the US legal cup, which is what 0.24 is', () {
      expect(shown('1', 'cup_us', 'mL'), '240');
    });
  });

  group('the truncated factors the reference ships', () {
    test('a mile is 1609.344 m, not 1609.34', () {
      expect(shown('1', 'mi', 'm', places: 3), '1609.344');
      expect(shown('1', 'mi', 'm', places: 3), isNot('1609.34'));
    });

    test('a pound is 0.45359237 kg, not 0.453592', () {
      expect(shown('1', 'lb', 'kg', places: 8), '0.45359237');
      expect(shown('1', 'lb', 'g', places: 5), '453.59237');
    });

    test('an ounce is a sixteenth of that pound, exactly', () {
      expect(
        exact('16', 'oz', 'kg'),
        exact('1', 'lb', 'kg'),
        reason: 'not approximately — the same rational',
      );
      expect(shown('1', 'oz', 'g', places: 9), '28.349523125');
    });

    test('mph is 1.609344 km/h', () {
      expect(shown('1', 'mph', 'kmh', places: 6), '1.609344');
      expect(shown('100', 'kmh', 'mph'), '62.1371');
    });

    test('an acre is 4840 square yards and a marla 272.25 square feet', () {
      expect(shown('1', 'ac', 'm2', places: 7), '4046.8564224');
      expect(
        exact('272.25', 'ft2', 'm2'),
        exact('1', 'marla', 'm2'),
        reason: 'the marla is defined from the foot, so it must agree exactly',
      );
    });

    test('a tola is three eighths of a troy ounce', () {
      expect(shown('1', 'tola', 'g', places: 7), '11.6638038');
    });
  });

  group('round trips', () {
    test('a value through a unit and back is the same value, exactly', () {
      for (final LumeUnitKind kind in LumeUnitKind.values) {
        final List<LumeUnit> units = lumeUnitsOf(kind);
        for (final LumeUnit a in units) {
          for (final LumeUnit b in units) {
            final LumeRatio there = lumeConvert(LumeRatio.parse('7.25'), a, b);
            final LumeRatio back = lumeConvert(there, b, a);
            expect(
              back,
              LumeRatio.parse('7.25'),
              reason: '${a.id} → ${b.id} → ${a.id}',
            );
          }
        }
      }
    });

    test('and is still the same value when the display has rounded it', () {
      // The display shows four decimals. A round trip *through the display*
      // can differ in the last place — this asserts how much, rather than
      // pretending it cannot happen.
      const int places = 4;
      for (final LumeUnitKind kind in LumeUnitKind.values) {
        final List<LumeUnit> units = lumeUnitsOf(kind);
        for (final LumeUnit a in units) {
          for (final LumeUnit b in units) {
            final String shownThere = lumeConvert(
              LumeRatio.parse('7.25'),
              a,
              b,
            ).toStringAsFixedMax(places);
            final LumeRatio back = lumeConvert(
              LumeRatio.parse(shownThere),
              b,
              a,
            );
            final LumeRatio drift = back - LumeRatio.parse('7.25');
            // Half a display unit of b, carried back into a.
            final LumeRatio tolerance =
                LumeRatio(BigInt.one, BigInt.from(10).pow(places)) *
                b.factor /
                a.factor;
            expect(
              drift.approximate.abs() <= tolerance.approximate,
              isTrue,
              reason:
                  '${a.id} → ${b.id} → ${a.id} drifted ${drift.approximate} '
                  'past ${tolerance.approximate}',
            );
          }
        }
      }
    });
  });

  group('rounding is for the display and happens once', () {
    test('half goes away from zero', () {
      expect(LumeRatio.parse('2.5').toStringAsFixedMax(0), '3');
      expect(LumeRatio.parse('3.5').toStringAsFixedMax(0), '4');
      expect(LumeRatio.parse('-2.5').toStringAsFixedMax(0), '-3');
      expect(LumeRatio.parse('0.00005').toStringAsFixedMax(4), '0.0001');
    });

    test('trailing zeros are dropped, so a whole answer reads whole', () {
      expect(shown('1', 'km', 'm'), '1000');
      expect(shown('1', 'm', 'km'), '0.001');
      expect(shown('0', 'km', 'mi'), '0');
    });

    test('a non-terminating conversion is answered, not refused', () {
      // The calculator refuses 1 ÷ 3. A converter cannot: this is the whole
      // reason the arithmetic here is a rational and not a `LumeDecimal`.
      expect(shown('1', 'm', 'mi', places: 12), '0.000621371192');
      expect(shown('5', 'km', 'mi'), '3.1069');
    });

    test('a large answer keeps every digit it needs', () {
      expect(shown('1', 'TiB', 'B'), '1099511627776');
    });
  });

  group('the shared table answers the question the built tools got wrong', () {
    // `lume_format.dart:476`, `flights_tool.dart:109` and
    // `weather_tool.dart:186` each hard-code km → miles as 0.621. They are
    // deliberately not changed by this wave (ROLLOUT_WAVE_4.md §4); this
    // records what the difference is, so the migration decision has a figure.
    test('0.621 against the defined factor', () {
      expect(shown('1', 'km', 'mi', places: 12), '0.621371192237');
      expect(shown('6000', 'km', 'mi', places: 3), '3728.227');
      expect(
        (6000 * 0.621).toStringAsFixed(3),
        '3726.000',
        reason: 'what Flights draws today — two miles short',
      );
      expect(shown('500', 'km', 'mi', places: 1), '310.7');
      expect(
        (500 * 0.621).toStringAsFixed(1),
        '310.5',
        reason: 'what Weather draws today',
      );
    });
  });
}

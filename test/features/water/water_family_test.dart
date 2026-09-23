/// Water's arithmetic, on its own: what a day adds up to, what a glass is,
/// what is left, how full the ring is, and what happens to a record the store
/// cannot read.
///
/// No widget is pumped here. Every figure the screen shows comes from one of
/// these functions, so if the sums are right the screen is right about them.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/data/record_seeds.dart';
import 'package:lume/features/records/presentation/record_family.dart';
import 'package:lume/features/water/domain/water_family.dart';
import 'package:lume/l10n/app_localizations_en.dart';

final LumeTimeZoneService zones = LumeTimeZoneService.shared;

LumeRecordContext ctx({
  LumeUnits units = LumeUnits.metric,
  String zone = 'Asia/Karachi',
}) => LumeRecordContext(
  l: AppLocalizationsEn(),
  f: LumeFormatting(
    locale: const Locale('en'),
    countryCode: 'PK',
    units: units,
  ),
  now: kFixtureInstant,
  zone: zones.resolveId(zone),
  currency: 'PKR',
);

final LumeMemoryRecordRepository store = LumeMemoryRecordRepository(
  seeds: (String c, DateTime n) => null,
  now: () => kFixtureInstant,
  hydrateDelay: null,
)..open('water');

const LumeWaterFamily family = LumeWaterFamily();

final DateTime today = DateTime(2026, 9, 7);

/// "Not given", so a test can store a literal `null` date.
const Object unset = Object();

/// One drink, straight into the store and back out through the family — so
/// what is tested is the reading, not a hand-built value object.
LumeDrink drink({
  Object? ml = 250,
  Object? kind = 'water',
  Object? at = '08:10',
  Object? date = unset,
  DateTime? on,
}) => family.read(
  store.create('water', <String, Object?>{
    'ml': ml,
    'kind': kind,
    'at': at,
    'date': identical(date, unset) ? lumeIsoDay(on ?? today, 0) : date,
  }).record!,
  ctx(),
);

void main() {
  group('totalMl counts one day and no other', () {
    test('a mix of days adds up only the one asked for', () {
      final List<LumeDrink> all = <LumeDrink>[
        drink(ml: 250, at: '08:10'),
        drink(ml: 500, at: '10:30'),
        drink(ml: 250, at: '13:05', kind: 'tea'),
        drink(ml: 250, at: '15:40'),
        // Yesterday and tomorrow, which the reference's schema cannot tell
        // apart from today because it stores no day at all.
        drink(ml: 900, at: '09:00', on: DateTime(2026, 9, 6)),
        drink(ml: 900, at: '09:00', on: DateTime(2026, 9, 8)),
      ];

      expect(LumeWaterFamily.totalMl(all, today), 1250);
      expect(LumeWaterFamily.totalMl(all, DateTime(2026, 9, 6)), 900);
      expect(LumeWaterFamily.totalMl(all, DateTime(2026, 9, 8)), 900);
      expect(LumeWaterFamily.totalMl(all, DateTime(2026, 9, 9)), 0);
    });

    test('a day with nothing on it is nothing, not a default', () {
      expect(LumeWaterFamily.totalMl(const <LumeDrink>[], today), 0);
      expect(LumeWaterFamily.today(const <LumeDrink>[], today), isEmpty);
    });

    test('the hour of the instant does not move a drink between days', () {
      final List<LumeDrink> all = <LumeDrink>[drink(ml: 250, at: '23:59')];
      expect(LumeWaterFamily.totalMl(all, DateTime(2026, 9, 7, 23, 59)), 250);
      expect(LumeWaterFamily.totalMl(all, DateTime(2026, 9, 7)), 250);
    });
  });

  group('glasses', () {
    // `Math.round(ml / 250)` — the reference's own rule, at the half.
    test('124 ml is no glass, 125 is one, 126 is one', () {
      expect(LumeWaterFamily.glasses(124), 0);
      expect(LumeWaterFamily.glasses(125), 1);
      expect(LumeWaterFamily.glasses(126), 1);
    });

    test('the parity day is five glasses', () {
      expect(LumeWaterFamily.glasses(1250), 5);
    });

    test('nothing logged is no glasses', () {
      expect(LumeWaterFamily.glasses(0), 0);
    });

    test('374 rounds down and 375 rounds up', () {
      expect(LumeWaterFamily.glasses(374), 1);
      expect(LumeWaterFamily.glasses(375), 2);
    });
  });

  group('remaining never goes below zero', () {
    test('under, exactly at, and past the goal', () {
      expect(LumeWaterFamily.remaining(1250, 2000), 750);
      expect(LumeWaterFamily.remaining(2000, 2000), 0);
      expect(LumeWaterFamily.remaining(2500, 2000), 0);
      expect(LumeWaterFamily.remaining(0, 2000), 2000);
    });

    test('a different goal moves it', () {
      expect(LumeWaterFamily.remaining(1250, 3000), 1750);
      expect(LumeWaterFamily.remaining(1250, 1000), 0);
    });
  });

  group('fraction is clamped, and only ever feeds the ring', () {
    test('at and above the goal it is one', () {
      expect(LumeWaterFamily.fraction(2000, 2000), 1);
      expect(LumeWaterFamily.fraction(20000, 2000), 1);
    });

    test('below it, it is the share', () {
      expect(LumeWaterFamily.fraction(1250, 2000), closeTo(0.625, 1e-12));
      expect(LumeWaterFamily.fraction(0, 2000), 0);
    });

    test('a goal of nothing fills nothing rather than dividing by zero', () {
      expect(LumeWaterFamily.fraction(1250, 0), 0);
      expect(LumeWaterFamily.fraction(1250, -5), 0);
    });
  });

  group('percent rounds half up, as Math.round does', () {
    test('1250 of 2000 is 63, not 62', () {
      expect(LumeWaterFamily.percent(1250, 2000), 63);
    });

    test('it stops at a hundred', () {
      expect(LumeWaterFamily.percent(2000, 2000), 100);
      expect(LumeWaterFamily.percent(9000, 2000), 100);
    });

    test('nothing logged is nothing', () {
      expect(LumeWaterFamily.percent(0, 2000), 0);
      expect(LumeWaterFamily.percent(1250, 0), 0);
    });
  });

  group("today's drinks are in time order", () {
    test('earliest first, whatever order they were written in', () {
      final List<LumeDrink> all = <LumeDrink>[
        drink(ml: 250, at: '15:40'),
        drink(ml: 250, at: '08:10'),
        drink(ml: 250, at: '13:05'),
        drink(ml: 500, at: '10:30'),
      ];
      expect(
        LumeWaterFamily.today(all, today).map((LumeDrink x) => x.at).toList(),
        <(int, int)>[(8, 10), (10, 30), (13, 5), (15, 40)],
      );
    });

    test('two at the same minute keep the order they were written in', () {
      final LumeDrink first = drink(ml: 250, at: '09:00');
      final LumeDrink second = drink(ml: 500, at: '09:00');
      final List<LumeDrink> order = LumeWaterFamily.today(<LumeDrink>[
        second,
        first,
      ], today);
      expect(order.map((LumeDrink x) => x.id).toList(), <String>[
        first.id,
        second.id,
      ]);
    });
  });

  group('a record the store cannot read is not counted', () {
    test('an amount that is not a whole positive number of millilitres', () {
      for (final Object? bad in <Object?>[
        null,
        '',
        0,
        -250,
        'a lot',
        250.5,
        double.nan,
        double.infinity,
      ]) {
        final LumeDrink x = drink(ml: bad);
        expect(x.ml, isNull, reason: 'ml: $bad');
        expect(x.countable, isFalse, reason: 'ml: $bad');
        expect(LumeWaterFamily.totalMl(<LumeDrink>[x], today), 0);
        expect(LumeWaterFamily.today(<LumeDrink>[x], today), isEmpty);
      }
    });

    test('a number written as text still reads', () {
      expect(drink(ml: '250').ml, 250);
    });

    test('a time that is not a time', () {
      for (final Object? bad in <Object?>[null, '', '25:00', '8.10', 'later']) {
        final LumeDrink x = drink(at: bad);
        expect(x.at, isNull, reason: 'at: $bad');
        expect(LumeWaterFamily.totalMl(<LumeDrink>[x], today), 0);
      }
    });

    // `2026-13-40` is not in this list: the shared `LumeFamilyText.day`
    // hands it to `DateTime.tryParse`, which rolls it over to 2027-02-09
    // rather than refusing it. That is the record layer's behaviour for every
    // family, not Water's, and it is not changed from here.
    test('a day that is not a day', () {
      for (final Object? bad in <Object?>[
        null,
        '',
        'yesterday',
        'not-a-date',
      ]) {
        final LumeDrink x = drink(date: bad);
        expect(x.date, isNull, reason: 'date: $bad');
        expect(LumeWaterFamily.totalMl(<LumeDrink>[x], today), 0);
      }
    });

    test('one unreadable drink does not take the rest of the day with it', () {
      final List<LumeDrink> all = <LumeDrink>[
        drink(ml: 250, at: '08:10'),
        drink(ml: 'nonsense', at: '09:00'),
        drink(ml: 500, at: '10:30'),
      ];
      expect(LumeWaterFamily.totalMl(all, today), 750);
      expect(LumeWaterFamily.today(all, today).length, 2);
    });

    test('a kind nobody wrote reads as Water, as the reference does', () {
      expect(drink(kind: null).kind, LumeDrinkKind.water);
      expect(drink(kind: 'fizzy').kind, LumeDrinkKind.water);
      expect(drink(kind: 'tea').kind, LumeDrinkKind.tea);
      // The reference's own schema stores a translation key.
      expect(drink(kind: '@water.kindTea').kind, LumeDrinkKind.tea);
    });
  });

  group('how much, in the reader\'s units', () {
    test('a total is litres to one decimal, rounded half away from zero', () {
      final LumeRecordContext c = ctx();
      expect(LumeWaterVolume.total(c, 1250), '1.3 L');
      expect(LumeWaterVolume.total(c, 750), '0.8 L');
      expect(LumeWaterVolume.total(c, 2000), '2.0 L');
      expect(LumeWaterVolume.total(c, 0), '0.0 L');
    });

    test('one drink is millilitres', () {
      final LumeRecordContext c = ctx();
      expect(LumeWaterVolume.amount(c, 250), '250 ml');
      expect(LumeWaterVolume.amount(c, 500), '500 ml');
    });

    test('an imperial reader gets the exact fluid ounce', () {
      final LumeRecordContext c = ctx(units: LumeUnits.imperial);
      // 250 / 29.5735295625 = 8.4535…; 500 / … = 16.907…
      expect(LumeWaterVolume.amount(c, 250), '8 fl oz');
      expect(LumeWaterVolume.amount(c, 500), '17 fl oz');
      expect(LumeWaterVolume.total(c, 1250), '42 fl oz');
      expect(LumeWaterVolume.total(c, 2000), '68 fl oz');
    });

    test('the factor is the defined one, not the reference\'s 29.574', () {
      expect(LumeWaterVolume.flOz.toStringAsFixedMax(10), '29.5735295625');
    });
  });
}

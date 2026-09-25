/// `LumeHolidaysFixtures` against `tool-data.js`'s own `HOLIDAYS` table —
/// no widget, no router: this is the data the tool draws from, checked on
/// its own.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/holidays/data/holidays_fixtures.dart';

void main() {
  group('each named country round-trips the reference table', () {
    test('Pakistan — six national holidays, table order kept', () {
      final List<LumeHoliday> pk = LumeHolidaysFixtures.holidaysFor('PK');
      expect(pk, hasLength(6));
      expect(pk.map((LumeHoliday h) => h.name), <LumeHolidayName>[
        LumeHolidayName.iqbalDay,
        LumeHolidayName.quaidDay,
        LumeHolidayName.kashmirDay,
        LumeHolidayName.pakistanDay,
        LumeHolidayName.labourDay,
        LumeHolidayName.independenceDay,
      ]);
      expect(
        pk.every((LumeHoliday h) => h.kind == LumeHolidayKind.national),
        isTrue,
      );
      expect(pk.map((LumeHoliday h) => (h.month, h.day)), <(int, int)>[
        (11, 9),
        (12, 25),
        (2, 5),
        (3, 23),
        (5, 1),
        (8, 14),
      ]);
    });

    test('United States — federal holidays', () {
      final List<LumeHoliday> us = LumeHolidaysFixtures.holidaysFor('US');
      expect(us, hasLength(6));
      expect(
        us.every((LumeHoliday h) => h.kind == LumeHolidayKind.federal),
        isTrue,
      );
      expect(
        us.map((LumeHoliday h) => (h.name, h.month, h.day)),
        <(LumeHolidayName, int, int)>[
          (LumeHolidayName.thanksgiving, 11, 28),
          (LumeHolidayName.christmasDay, 12, 25),
          (LumeHolidayName.newYearsDay, 1, 1),
          (LumeHolidayName.mlkDay, 1, 20),
          (LumeHolidayName.independenceDay, 7, 4),
          (LumeHolidayName.laborDay, 9, 2),
        ],
      );
    });

    test('United Kingdom — bank holidays', () {
      final List<LumeHoliday> gb = LumeHolidaysFixtures.holidaysFor('GB');
      expect(gb, hasLength(6));
      expect(
        gb.every((LumeHoliday h) => h.kind == LumeHolidayKind.bank),
        isTrue,
      );
      expect(gb.map((LumeHoliday h) => h.name), <LumeHolidayName>[
        LumeHolidayName.christmasDay,
        LumeHolidayName.boxingDay,
        LumeHolidayName.newYearsDay,
        LumeHolidayName.goodFriday,
        LumeHolidayName.earlyMay,
        LumeHolidayName.summer,
      ]);
    });

    test('UAE — public holidays, including its lunar-calendar entries', () {
      final List<LumeHoliday> ae = LumeHolidaysFixtures.holidaysFor('AE');
      expect(ae, hasLength(6));
      expect(
        ae.every((LumeHoliday h) => h.kind == LumeHolidayKind.public),
        isTrue,
      );
      expect(
        ae.map((LumeHoliday h) => h.name),
        contains(LumeHolidayName.eidAlFitr),
      );
      expect(
        ae.map((LumeHoliday h) => h.name),
        contains(LumeHolidayName.eidAlAdha),
      );
      expect(
        ae.map((LumeHoliday h) => h.name),
        contains(LumeHolidayName.islamicNewYear),
      );
    });

    test('Saudi Arabia — four public holidays', () {
      final List<LumeHoliday> sa = LumeHolidaysFixtures.holidaysFor('SA');
      expect(sa, hasLength(4));
      expect(
        sa.every((LumeHoliday h) => h.kind == LumeHolidayKind.public),
        isTrue,
      );
      expect(sa.map((LumeHoliday h) => h.name), <LumeHolidayName>[
        LumeHolidayName.nationalDay,
        LumeHolidayName.foundingDay,
        LumeHolidayName.eidAlFitr,
        LumeHolidayName.eidAlAdha,
      ]);
    });

    test('India — gazetted holidays', () {
      final List<LumeHoliday> india = LumeHolidaysFixtures.holidaysFor('IN');
      expect(india, hasLength(6));
      expect(
        india.every((LumeHoliday h) => h.kind == LumeHolidayKind.gazetted),
        isTrue,
      );
      expect(india.map((LumeHoliday h) => h.name), <LumeHolidayName>[
        LumeHolidayName.gandhiJayanti,
        LumeHolidayName.christmas,
        LumeHolidayName.republicDay,
        LumeHolidayName.independenceDay,
        LumeHolidayName.holi,
        LumeHolidayName.diwali,
      ]);
    });

    test('a lower-case or mixed-case country code still resolves', () {
      expect(
        LumeHolidaysFixtures.holidaysFor('pk'),
        LumeHolidaysFixtures.holidaysFor('PK'),
      );
    });
  });

  group('the generic fallback', () {
    test('applies to any country without its own table', () {
      for (final String code in <String>['FR', 'JP', 'DE', 'BR', 'ZZ']) {
        expect(
          LumeHolidaysFixtures.holidaysFor(code),
          same(LumeHolidaysFixtures.fallback),
        );
      }
    });

    test('is the reference\'s own three global holidays', () {
      expect(LumeHolidaysFixtures.fallback, hasLength(3));
      expect(
        LumeHolidaysFixtures.fallback.map((LumeHoliday h) => h.name),
        <LumeHolidayName>[
          LumeHolidayName.newYearsDay,
          LumeHolidayName.christmasDay,
          LumeHolidayName.labourDay,
        ],
      );
      expect(
        LumeHolidaysFixtures.fallback.every(
          (LumeHoliday h) => h.kind == LumeHolidayKind.public,
        ),
        isTrue,
      );
    });
  });

  group('kindsOf', () {
    test('is the distinct kinds, first-seen order', () {
      final List<LumeHoliday> pk = LumeHolidaysFixtures.holidaysFor('PK');
      expect(LumeHolidaysFixtures.kindsOf(pk), <LumeHolidayKind>[
        LumeHolidayKind.national,
      ]);

      final List<LumeHoliday> ae = LumeHolidaysFixtures.holidaysFor('AE');
      expect(LumeHolidaysFixtures.kindsOf(ae), <LumeHolidayKind>[
        LumeHolidayKind.public,
      ]);
    });
  });
}

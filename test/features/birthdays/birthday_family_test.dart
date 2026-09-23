/// The arithmetic the reference states as constants, checked without a
/// screen.
///
/// `context.js:1581-1589` sets `days`, `turning` and `thisMonth` by hand;
/// `record-schemas.js:765-802` computes them from the stored date. These are
/// the computed ones, on a `today` the test names, so nothing here depends
/// on the day it is run.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/birthdays/domain/birthday_family.dart';

void main() {
  group('nextOn — the next time the stored day comes round', () {
    // (what it is called, born, today, the next occurrence)
    for (final (String name, DateTime born, DateTime today, DateTime next)
        in <(String, DateTime, DateTime, DateTime)>[
          (
            'later this year',
            DateTime(1997, 9, 11),
            DateTime(2026, 9, 7),
            DateTime(2026, 9, 11),
          ),
          (
            'earlier this year, so next year',
            DateTime(1990, 3, 2),
            DateTime(2026, 9, 7),
            DateTime(2027, 3, 2),
          ),
          (
            'yesterday, so next year',
            DateTime(1990, 9, 6),
            DateTime(2026, 9, 7),
            DateTime(2027, 9, 6),
          ),
          // The reference's `next < today` is strict, and today is today.
          (
            'exactly today',
            DateTime(2000, 9, 7),
            DateTime(2026, 9, 7),
            DateTime(2026, 9, 7),
          ),
          (
            'the last day of the year',
            DateTime(1980, 12, 31),
            DateTime(2026, 12, 31),
            DateTime(2026, 12, 31),
          ),
        ]) {
      test(name, () {
        expect(LumeBirthdayFamily.nextOn(born, today), next);
      });
    }

    test('a date that could not be read has no next occurrence', () {
      expect(LumeBirthdayFamily.nextOn(null, DateTime(2026, 9, 7)), isNull);
      expect(LumeBirthdayFamily.daysUntil(null, DateTime(2026, 9, 7)), isNull);
      expect(LumeBirthdayFamily.inMonthOf(null, DateTime(2026, 9, 7)), isFalse);
    });
  });

  group('29 February', () {
    final DateTime born = DateTime(2000, 2, 29);

    test('a leap target year keeps the 29th', () {
      expect(
        LumeBirthdayFamily.nextOn(born, DateTime(2028, 1, 10)),
        DateTime(2028, 2, 29),
      );
    });

    test('a non-leap target year is observed on 1 March', () {
      expect(
        LumeBirthdayFamily.nextOn(born, DateTime(2027, 1, 10)),
        DateTime(2027, 3, 1),
      );
    });

    test('and 1 March in a non-leap year is that day, not a year away', () {
      expect(
        LumeBirthdayFamily.nextOn(born, DateTime(2027, 3, 1)),
        DateTime(2027, 3, 1),
      );
      expect(LumeBirthdayFamily.daysUntil(born, DateTime(2027, 3, 1)), 0);
    });

    test('28 February in a non-leap year is one day short of it', () {
      expect(LumeBirthdayFamily.daysUntil(born, DateTime(2027, 2, 28)), 1);
    });

    // The reference adds a year to the value it has already rolled
    // (`record-schemas.js:772`), which would answer 1 March 2028 — a day
    // that leap year does not need. The stored month and day are used
    // instead.
    test('rolling into the following year re-reads the stored day', () {
      expect(
        LumeBirthdayFamily.nextOn(born, DateTime(2027, 6, 1)),
        DateTime(2028, 2, 29),
      );
    });
  });

  group('daysUntil — calendar days, never elapsed hours', () {
    // (what it is called, born, today, days)
    for (final (String name, DateTime born, DateTime today, int days)
        in <(String, DateTime, DateTime, int)>[
          // The parity seeds, on the fixture day.
          ('Ayesha', DateTime(1997, 9, 11), DateTime(2026, 9, 7), 4),
          ('the anniversary', DateTime(2020, 9, 25), DateTime(2026, 9, 7), 18),
          ('Musa', DateTime(2021, 10, 28), DateTime(2026, 9, 7), 51),
          ('today is nought', DateTime(1990, 9, 7), DateTime(2026, 9, 7), 0),
          // Across the end of daylight saving in the Americas and Europe
          // (1 November 2026, 25 October 2026): an hour is repeated, and
          // the count of days is unmoved.
          (
            'across an autumn clock change',
            DateTime(1990, 11, 5),
            DateTime(2026, 10, 25),
            11,
          ),
          (
            'across a whole month of one',
            DateTime(1990, 11, 30),
            DateTime(2026, 10, 25),
            36,
          ),
          // And across the spring one (14 March 2027), where an hour is
          // skipped.
          (
            'across a spring clock change',
            DateTime(1990, 3, 20),
            DateTime(2027, 3, 10),
            10,
          ),
        ]) {
      test(name, () {
        expect(LumeBirthdayFamily.daysUntil(born, today), days);
      });
    }

    test('a whole year, less a day, is the most it can be', () {
      final DateTime today = DateTime(2026, 9, 7);
      for (int i = 0; i < 366; i++) {
        final DateTime born = DateTime(1990, 1, 1 + i);
        final int? n = LumeBirthdayFamily.daysUntil(born, today);
        expect(n, isNotNull);
        expect(n, inInclusiveRange(0, 365));
      }
    });
  });

  group('turning — the age reached, or the years counted', () {
    final DateTime today = DateTime(2026, 9, 7);

    int? of(DateTime born) => LumeBirthdayFamily.turning(
      born,
      LumeBirthdayFamily.nextOn(born, today),
    );

    test('a birthday: the next occurrence, less the year born', () {
      expect(of(DateTime(1997, 9, 11)), 29);
      expect(of(DateTime(2021, 10, 28)), 5);
    });

    test('an anniversary counts the same way', () {
      expect(of(DateTime(2020, 9, 25)), 6);
    });

    test('a year still to come counts nothing', () {
      expect(of(DateTime(2030, 5, 1)), isNull);
    });

    test('a date stored in the year it next falls turns nobody', () {
      // Born later this year: the next occurrence is this year, so the
      // difference is nought and there is no age to announce.
      expect(of(DateTime(2026, 12, 25)), isNull);
    });

    test('an unreadable date, and a missing occurrence, both give nothing', () {
      expect(LumeBirthdayFamily.turning(null, DateTime(2026, 9, 11)), isNull);
      expect(LumeBirthdayFamily.turning(DateTime(1997, 9, 11), null), isNull);
      expect(LumeBirthdayFamily.turning(null, null), isNull);
    });
  });

  group('inMonthOf — the reference\'s constant `thisMonth: 2`', () {
    final DateTime today = DateTime(2026, 9, 7);

    test('the two parity seeds that fall in September, and not the third', () {
      expect(
        LumeBirthdayFamily.inMonthOf(DateTime(1997, 9, 11), today),
        isTrue,
      );
      expect(
        LumeBirthdayFamily.inMonthOf(DateTime(2020, 9, 25), today),
        isTrue,
      );
      expect(
        LumeBirthdayFamily.inMonthOf(DateTime(2021, 10, 28), today),
        isFalse,
      );
    });

    test('today itself is in this month', () {
      expect(LumeBirthdayFamily.inMonthOf(DateTime(1990, 9, 7), today), isTrue);
    });

    test('a day already gone this month rolls to next year, and is not', () {
      expect(
        LumeBirthdayFamily.inMonthOf(DateTime(1990, 9, 1), today),
        isFalse,
      );
    });
  });

  group('the occasion', () {
    test('an unknown stored value reads as a birthday, as the reference\'s '
        '`r.kind || \'birthday\'` does', () {
      expect(LumeOccasion.byId('birthday'), LumeOccasion.birthday);
      expect(LumeOccasion.byId('anniversary'), LumeOccasion.anniversary);
      expect(LumeOccasion.byId(null), LumeOccasion.birthday);
      expect(LumeOccasion.byId(''), LumeOccasion.birthday);
      expect(LumeOccasion.byId('wedding'), LumeOccasion.birthday);
      expect(LumeOccasion.byId(7), LumeOccasion.birthday);
    });

    test('the select stores the plain value, not a translation key', () {
      expect(LumeOccasion.values.map((LumeOccasion o) => o.name), <String>[
        'birthday',
        'anniversary',
      ]);
    });
  });

  test('the schema is the reference\'s, in its order, and holds no reminder, '
      'repeat or alert', () {
    expect(LumeBirthdayFamily.kSchema.fields.map((f) => f.name), <String>[
      'name',
      'kind',
      'date',
      'notes',
    ]);
    expect(LumeBirthdayFamily.kSchema.collection, 'birthdays');
    expect(LumeBirthdayFamily.kSchema.recoverable, isTrue);
  });
}

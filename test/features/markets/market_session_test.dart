/// Is the market open? — at every boundary the prototype gets wrong.
///
/// The prototype reads the device's clock, treats the close as inclusive,
/// never consults the holiday table it ships, and gives every exchange a
/// Monday-to-Friday week. Each of those is a test here.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/time/lume_time_zone.dart';
import 'package:lume/features/markets/data/exchange_fixtures.dart';
import 'package:lume/features/markets/domain/market_calendar.dart';
import 'package:lume/features/markets/domain/market_session.dart';

/// A moment in Karachi, as an absolute instant. PKT is UTC+5 all year.
DateTime karachi(int y, int m, int d, int h, [int min = 0]) =>
    DateTime.utc(y, m, d, h, min).subtract(const Duration(hours: 5));

/// A moment in New York, in whichever offset applies that day.
DateTime newYork(int y, int m, int d, int h, [int min = 0]) {
  final DateTime guess = DateTime.utc(y, m, d, h, min);
  return guess.subtract(LumeTimeZones.newYork.offsetAt(guess));
}

void main() {
  group('the clock is the exchange\'s, not the device\'s', () {
    test('Karachi opens at 09:32 Karachi time, wherever the phone is', () {
      // The same absolute instant, asked for by a phone that could be
      // anywhere: the answer is a property of the exchange.
      final DateTime open = karachi(2026, 9, 7, 9, 32);
      expect(LumeExchanges.psx.stateAt(open).isOpen, isTrue);
      expect(LumeExchanges.psx.stateAt(open.toUtc()).isOpen, isTrue);
    });

    test('a London phone does not open Karachi at 09:32 London time', () {
      // 09:32 in London is 13:32 in Karachi — open, but for the right reason.
      // 05:00 in London is 10:00 in Karachi, which the device-clock version
      // would have called shut.
      final DateTime fiveAm = DateTime.utc(2026, 9, 7, 4, 0);
      final LumeMarketState s = LumeExchanges.psx.stateAt(fiveAm);
      expect(s.localTime.hour, 9);
      expect(s.isOpen, isFalse, reason: '09:00 is before the 09:32 open');
    });

    test('the state carries the exchange\'s own wall clock', () {
      final LumeMarketState s = LumeExchanges.psx.stateAt(
        karachi(2026, 9, 7, 14, 5),
      );
      expect(s.localTime.hour, 14);
      expect(s.localTime.minute, 5);
    });
  });

  group('the boundaries', () {
    test('one minute before the open is shut', () {
      final LumeMarketState s = LumeExchanges.psx.stateAt(
        karachi(2026, 9, 7, 9, 31),
      );
      expect(s.isOpen, isFalse);
      expect(s.closure, LumeMarketClosure.outsideHours);
    });

    test('the opening minute is open', () {
      expect(
        LumeExchanges.psx.stateAt(karachi(2026, 9, 7, 9, 32)).isOpen,
        isTrue,
      );
    });

    test('one minute after the open is open', () {
      expect(
        LumeExchanges.psx.stateAt(karachi(2026, 9, 7, 9, 33)).isOpen,
        isTrue,
      );
    });

    test('one minute before the close is open', () {
      expect(
        LumeExchanges.psx.stateAt(karachi(2026, 9, 7, 15, 29)).isOpen,
        isTrue,
      );
    });

    test('the closing minute is SHUT — the close is exclusive', () {
      // The prototype's `h >= o && h <= cl` calls this open, which is the
      // second of its four defects.
      final LumeMarketState s = LumeExchanges.psx.stateAt(
        karachi(2026, 9, 7, 15, 30),
      );
      expect(s.isOpen, isFalse);
      expect(s.closure, LumeMarketClosure.outsideHours);
    });

    test('one minute after the close is shut', () {
      expect(
        LumeExchanges.psx.stateAt(karachi(2026, 9, 7, 15, 31)).isOpen,
        isFalse,
      );
    });

    test('minutes are whole, so 09:32 is not 9.53 hours', () {
      // A decimal-hour comparison makes 09:32 into 9.5333…, and a float
      // comparison at the boundary is a coin toss.
      expect(LumeTradingHours.parse('09:32', '15:30').openMinute, 572);
      expect(LumeTradingHours.parse('09:32', '15:30').closeMinute, 930);
    });
  });

  group('the week', () {
    test('Karachi is shut on Saturday and Sunday', () {
      for (final int day in <int>[5, 6]) {
        // 5 and 6 September 2026 are a Saturday and a Sunday.
        final LumeMarketState s = LumeExchanges.psx.stateAt(
          karachi(2026, 9, day, 12),
        );
        expect(s.isOpen, isFalse);
        expect(s.closure, LumeMarketClosure.weekend);
      }
    });

    test('Riyadh trades on Sunday and is shut on Friday', () {
      // The prototype hard-codes Monday-to-Friday for every exchange, which
      // opens Tadawul on the one day it is certainly closed.
      DateTime riyadh(int d, int h) =>
          DateTime.utc(2026, 9, d, h).subtract(const Duration(hours: 3));

      expect(
        LumeExchanges.tadawul.stateAt(riyadh(6, 12)).isOpen,
        isTrue,
        reason: 'Sunday is a trading day in Riyadh',
      );
      expect(
        LumeExchanges.tadawul.stateAt(riyadh(4, 12)).closure,
        LumeMarketClosure.weekend,
        reason: 'Friday is not',
      );
    });
  });

  group('holidays close a market as surely as the clock does', () {
    test('a fixed holiday: 14 August in Karachi', () {
      // 14 August 2026 is a Friday, and mid-morning.
      final LumeMarketState s = LumeExchanges.psx.stateAt(
        karachi(2026, 8, 14, 11),
      );
      expect(s.isOpen, isFalse);
      expect(s.closure, LumeMarketClosure.holiday);
      expect(s.holiday?.name, 'independence-day');
    });

    test('a floating holiday: Thanksgiving is the fourth Thursday', () {
      // The prototype pins it to 28 November. In 2026 the fourth Thursday is
      // the 26th, so the prototype trades through Thanksgiving and shuts on an
      // ordinary Saturday.
      expect(
        const LumeFloatingHoliday(
          'thanksgiving',
          month: DateTime.november,
          weekday: DateTime.thursday,
          ordinal: 4,
        ).dateIn(2026),
        DateTime(2026, 11, 26),
      );
      final LumeMarketState s = LumeExchanges.nasdaq.stateAt(
        newYork(2026, 11, 26, 11),
      );
      expect(s.closure, LumeMarketClosure.holiday);
      expect(s.holiday?.name, 'thanksgiving');

      // And the 28th, which the prototype calls a holiday, is a Saturday —
      // shut, but for the honest reason.
      expect(
        LumeExchanges.nasdaq.stateAt(newYork(2026, 11, 28, 11)).closure,
        LumeMarketClosure.weekend,
      );
    });

    test('a floating holiday: the last Monday in August in London', () {
      expect(
        const LumeFloatingHoliday(
          'summer',
          month: DateTime.august,
          weekday: DateTime.monday,
          ordinal: -1,
        ).dateIn(2026),
        DateTime(2026, 8, 31),
      );
    });

    test('Good Friday moves with Easter', () {
      // Easter Sunday 2026 is 5 April; 2025 was 20 April.
      expect(LumeEasterHoliday.easterSunday(2026), DateTime(2026, 4, 5));
      expect(LumeEasterHoliday.easterSunday(2025), DateTime(2025, 4, 20));
      expect(
        const LumeEasterHoliday('good-friday', offsetDays: -2).dateIn(2026),
        DateTime(2026, 4, 3),
      );
      expect(
        LumeExchanges.lse.stateAt(DateTime.utc(2026, 4, 3, 10)).holiday?.name,
        'good-friday',
      );
    });

    test(
      'a holiday outranks the weekend, so the reason is the specific one',
      () {
        // 25 December 2027 is a Saturday. Both apply; the holiday is what a
        // person would say.
        expect(
          LumeExchanges.psx.stateAt(karachi(2027, 12, 25, 11)).closure,
          LumeMarketClosure.holiday,
        );
      },
    );

    test('11:00 on Christmas morning is never open', () {
      expect(
        LumeExchanges.nasdaq.stateAt(newYork(2026, 12, 25, 11)).isOpen,
        isFalse,
      );
    });
  });

  group('daylight saving', () {
    test('New York is five behind in winter and four in summer', () {
      expect(
        LumeTimeZones.newYork.offsetAt(DateTime.utc(2026, 1, 15, 12)),
        const Duration(hours: -5),
      );
      expect(
        LumeTimeZones.newYork.offsetAt(DateTime.utc(2026, 7, 15, 12)),
        const Duration(hours: -4),
      );
    });

    test('it turns on the second Sunday in March, at 02:00 local standard', () {
      // 8 March 2026, 07:00 UTC.
      expect(
        LumeTimeZones.newYork.isSaving(DateTime.utc(2026, 3, 8, 6, 59)),
        isFalse,
      );
      expect(
        LumeTimeZones.newYork.isSaving(DateTime.utc(2026, 3, 8, 7, 0)),
        isTrue,
      );
    });

    test('and back on the first Sunday in November', () {
      // 1 November 2026, 06:00 UTC.
      expect(
        LumeTimeZones.newYork.isSaving(DateTime.utc(2026, 11, 1, 5, 59)),
        isTrue,
      );
      expect(
        LumeTimeZones.newYork.isSaving(DateTime.utc(2026, 11, 1, 6, 0)),
        isFalse,
      );
    });

    test('London turns at 01:00 UTC on the last Sunday in March', () {
      expect(
        LumeTimeZones.london.isSaving(DateTime.utc(2026, 3, 29, 0, 59)),
        isFalse,
      );
      expect(
        LumeTimeZones.london.isSaving(DateTime.utc(2026, 3, 29, 1, 0)),
        isTrue,
      );
      expect(
        LumeTimeZones.london.isSaving(DateTime.utc(2026, 10, 25, 1, 0)),
        isFalse,
      );
    });

    test('the London open is 08:00 local in both halves of the year', () {
      // Winter: 08:00 GMT is 08:00 UTC. Summer: 08:00 BST is 07:00 UTC.
      expect(
        LumeExchanges.lse.stateAt(DateTime.utc(2026, 1, 15, 8)).isOpen,
        isTrue,
      );
      expect(
        LumeExchanges.lse.stateAt(DateTime.utc(2026, 7, 15, 7)).isOpen,
        isTrue,
      );
      expect(
        LumeExchanges.lse.stateAt(DateTime.utc(2026, 7, 15, 6, 59)).isOpen,
        isFalse,
      );
    });

    test('a zone with no rule never moves', () {
      for (final int month in <int>[1, 4, 7, 10]) {
        expect(
          LumeTimeZones.karachi.offsetAt(DateTime.utc(2026, month, 15)),
          const Duration(hours: 5),
        );
      }
    });

    test('Kolkata keeps its half hour', () {
      expect(
        LumeTimeZones.kolkata.wallClockAt(DateTime.utc(2026, 9, 7, 4, 0)).hour,
        9,
      );
      expect(
        LumeTimeZones.kolkata
            .wallClockAt(DateTime.utc(2026, 9, 7, 4, 0))
            .minute,
        30,
      );
    });
  });

  group('the fixture is complete', () {
    test('every exchange names a zone this build can answer for', () {
      for (final LumeExchange e in LumeExchanges.all) {
        expect(
          LumeTimeZones.byId(e.hours.zone.id),
          isNotNull,
          reason: '${e.code} names ${e.hours.zone.id}',
        );
      }
    });

    test('a market with no exchange gets null, not somebody else\'s', () {
      expect(LumeExchanges.forCountry('JP'), isNull);
      expect(LumeExchanges.forCountry('PK')?.code, 'PSX');
    });

    test('every exchange opens before it closes', () {
      for (final LumeExchange e in LumeExchanges.all) {
        expect(
          e.hours.hours.openMinute,
          lessThan(e.hours.hours.closeMinute),
          reason: e.code,
        );
      }
    });
  });
}

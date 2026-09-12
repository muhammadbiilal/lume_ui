/// The six exchanges the reference carries, with their hours, their zone and
/// their calendar.
///
/// Hours, names, currencies, cities and the lead index come from
/// `assets/js/data/tool-data.js` unchanged — they are the design's data and
/// the screens are measured against them. The three things around them are
/// corrections, and each is marked where it appears:
///
/// * **the zone** is now used. The prototype stores `tz` and then reads the
///   device's clock.
/// * **the weekend** is per exchange. The prototype hard-codes Monday–Friday,
///   and the Saudi Exchange trades Sunday–Thursday.
/// * **the calendar** is consulted, and its floating days are derived.
///   `MARKET_HOLIDAYS` exists in the prototype and is never read; its one
///   floating entry, US Thanksgiving, is pinned to 28 November, which is the
///   wrong Thursday in most years.
///
/// The London calendar also carries the bank holidays the prototype lists in
/// its *country* table (`HOLIDAYS.GB`) but leaves out of its market table —
/// pinned there to their 2025 dates, and derived here.
library;

import 'package:flutter/foundation.dart';

// The one file that names the conversion's rule table. `LumeExchangeHours`
// takes a `LumeZone`, so a maintained zone database replaces these six
// constants and nothing else moves. See `lume_zone.dart`.
import '../../../core/time/lume_time_zone.dart';
import '../domain/market_calendar.dart';
import '../domain/market_session.dart';

/// One market, as the fixtures know it.
@immutable
class LumeExchange {
  const LumeExchange({
    required this.countryCode,
    required this.code,
    required this.name,
    required this.city,
    required this.currency,
    required this.hours,
    required this.leadIndex,
  });

  /// The market this exchange is the local one for.
  final String countryCode;

  /// `PSX`, `NASDAQ`, `LSE`, …
  final String code;

  /// The exchange's own name — a proper noun, not translated.
  final String name;

  final String city;
  final String currency;

  final LumeExchangeHours hours;

  /// The index Home's live card shows.
  final LumeIndexQuote leadIndex;

  LumeMarketState stateAt(DateTime instant) => hours.stateAt(instant);
}

/// One index, at the moment the fixture was taken.
@immutable
class LumeIndexQuote {
  const LumeIndexQuote({
    required this.symbol,
    required this.name,
    required this.value,
    required this.change,
    required this.percent,
  });

  final String symbol;
  final String name;
  final double value;
  final double change;
  final double percent;

  bool get isUp => percent >= 0;
}

/// The exchanges, keyed by the market they serve.
abstract final class LumeExchanges {
  static const LumeExchange psx = LumeExchange(
    countryCode: 'PK',
    code: 'PSX',
    name: 'Pakistan Stock Exchange',
    city: 'Karachi',
    currency: 'PKR',
    hours: LumeExchangeHours(
      zone: LumeTimeZones.karachi,
      hours: LumeTradingHours(
        openMinute: 9 * 60 + 32,
        closeMinute: 15 * 60 + 30,
      ),
      calendar: LumeMarketCalendar(
        weekend: LumeMarketCalendar.weekendSatSun,
        holidays: <LumeHoliday>[
          LumeFixedHoliday('labour-day', 5, 1),
          LumeFixedHoliday('independence-day', 8, 14),
          LumeFixedHoliday('quaid-day', 12, 25),
        ],
      ),
    ),
    leadIndex: LumeIndexQuote(
      symbol: 'KSE100',
      name: 'KSE-100',
      value: 154230.42,
      change: 1248.23,
      percent: 0.82,
    ),
  );

  static const LumeExchange nasdaq = LumeExchange(
    countryCode: 'US',
    code: 'NASDAQ',
    name: 'Nasdaq · NYSE',
    city: 'New York',
    currency: 'USD',
    hours: LumeExchangeHours(
      zone: LumeTimeZones.newYork,
      hours: LumeTradingHours(openMinute: 9 * 60 + 30, closeMinute: 16 * 60),
      calendar: LumeMarketCalendar(
        weekend: LumeMarketCalendar.weekendSatSun,
        holidays: <LumeHoliday>[
          LumeFixedHoliday('new-year', 1, 1),
          LumeFixedHoliday('independence-day', 7, 4),
          // Derived. The prototype pins this to 28 November.
          LumeFloatingHoliday(
            'thanksgiving',
            month: DateTime.november,
            weekday: DateTime.thursday,
            ordinal: 4,
          ),
          LumeFixedHoliday('christmas', 12, 25),
        ],
      ),
    ),
    leadIndex: LumeIndexQuote(
      symbol: 'SPX',
      name: 'S&P 500',
      value: 5812.44,
      change: 24.18,
      percent: 0.42,
    ),
  );

  static const LumeExchange lse = LumeExchange(
    countryCode: 'GB',
    code: 'LSE',
    name: 'London Stock Exchange',
    city: 'London',
    currency: 'GBP',
    hours: LumeExchangeHours(
      zone: LumeTimeZones.london,
      hours: LumeTradingHours(openMinute: 8 * 60, closeMinute: 16 * 60 + 30),
      calendar: LumeMarketCalendar(
        weekend: LumeMarketCalendar.weekendSatSun,
        holidays: <LumeHoliday>[
          LumeFixedHoliday('new-year', 1, 1),
          LumeEasterHoliday('good-friday', offsetDays: -2),
          LumeEasterHoliday('easter-monday', offsetDays: 1),
          LumeFloatingHoliday(
            'early-may',
            month: DateTime.may,
            weekday: DateTime.monday,
            ordinal: 1,
          ),
          LumeFloatingHoliday(
            'spring',
            month: DateTime.may,
            weekday: DateTime.monday,
            ordinal: -1,
          ),
          LumeFloatingHoliday(
            'summer',
            month: DateTime.august,
            weekday: DateTime.monday,
            ordinal: -1,
          ),
          LumeFixedHoliday('christmas', 12, 25),
          LumeFixedHoliday('boxing-day', 12, 26),
        ],
      ),
    ),
    leadIndex: LumeIndexQuote(
      symbol: 'UKX',
      name: 'FTSE 100',
      value: 8288.60,
      change: 31.44,
      percent: 0.38,
    ),
  );

  static const LumeExchange dfm = LumeExchange(
    countryCode: 'AE',
    code: 'DFM',
    name: 'Dubai Financial Market',
    city: 'Dubai',
    currency: 'AED',
    hours: LumeExchangeHours(
      zone: LumeTimeZones.dubai,
      hours: LumeTradingHours(openMinute: 10 * 60, closeMinute: 15 * 60),
      calendar: LumeMarketCalendar(
        // The UAE working week moved to Monday–Friday in January 2022.
        weekend: LumeMarketCalendar.weekendSatSun,
        holidays: <LumeHoliday>[
          LumeFixedHoliday('new-year', 1, 1),
          LumeFixedHoliday('national-day', 12, 2),
        ],
      ),
    ),
    leadIndex: LumeIndexQuote(
      symbol: 'DFMGI',
      name: 'DFM General',
      value: 4488.20,
      change: 12.40,
      percent: 0.28,
    ),
  );

  static const LumeExchange tadawul = LumeExchange(
    countryCode: 'SA',
    code: 'Tadawul',
    name: 'Saudi Exchange',
    city: 'Riyadh',
    currency: 'SAR',
    hours: LumeExchangeHours(
      zone: LumeTimeZones.riyadh,
      hours: LumeTradingHours(openMinute: 10 * 60, closeMinute: 15 * 60),
      calendar: LumeMarketCalendar(
        // Sunday to Thursday. The prototype's Monday–Friday would open this
        // market on Friday and close it on Sunday, both wrong.
        weekend: LumeMarketCalendar.weekendFriSat,
        holidays: <LumeHoliday>[LumeFixedHoliday('national-day', 9, 23)],
      ),
    ),
    leadIndex: LumeIndexQuote(
      symbol: 'TASI',
      name: 'TASI',
      value: 12044.80,
      change: -38.20,
      percent: -0.32,
    ),
  );

  static const LumeExchange nse = LumeExchange(
    countryCode: 'IN',
    code: 'NSE',
    name: 'National Stock Exchange',
    city: 'Mumbai',
    currency: 'INR',
    hours: LumeExchangeHours(
      zone: LumeTimeZones.kolkata,
      hours: LumeTradingHours(
        openMinute: 9 * 60 + 15,
        closeMinute: 15 * 60 + 30,
      ),
      calendar: LumeMarketCalendar(
        weekend: LumeMarketCalendar.weekendSatSun,
        holidays: <LumeHoliday>[
          LumeFixedHoliday('republic-day', 1, 26),
          LumeFixedHoliday('independence-day', 8, 15),
          LumeFixedHoliday('gandhi-jayanti', 10, 2),
        ],
      ),
    ),
    leadIndex: LumeIndexQuote(
      symbol: 'NIFTY',
      name: 'NIFTY 50',
      value: 24812.30,
      change: 96.55,
      percent: 0.39,
    ),
  );

  static const List<LumeExchange> all = <LumeExchange>[
    psx,
    nasdaq,
    lse,
    dfm,
    tadawul,
    nse,
  ];

  /// The exchange for a market, or `null` where the product has none yet.
  ///
  /// `null` is a real answer: a user in Japan has no local board in these
  /// fixtures, and Home shows no market card rather than inventing one.
  static LumeExchange? forCountry(String code) {
    for (final LumeExchange e in all) {
      if (e.countryCode == code) return e;
    }
    return null;
  }
}

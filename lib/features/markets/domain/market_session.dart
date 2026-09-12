/// Is this exchange open? — answered once, correctly.
///
/// The prototype's `marketSession()` is four defects in six lines:
///
/// ```js
/// var now = new Date();
/// var h = now.getHours() + now.getMinutes() / 60;          // the DEVICE's clock
/// var o  = parseFloat(ex.open.split(':')[0]) + …;
/// var cl = parseFloat(ex.close.split(':')[0]) + …;
/// var open = h >= o && h <= cl                             // close is INCLUSIVE
///            && now.getDay() > 0 && now.getDay() < 6;      // one weekend for all
/// ```
///
/// 1. **The device's timezone, not the exchange's.** A phone in London says the
///    Karachi exchange opens at 09:32 London time — four or five hours late,
///    depending on the season.
/// 2. **An inclusive close.** At exactly 15:30 the Pakistan Stock Exchange
///    reads as open. A session that is over is over.
/// 3. **No holidays at all.** `MARKET_HOLIDAYS` and `isMarketHoliday()` are
///    both defined in `tool-data.js` and neither is called from here.
/// 4. **One weekend for every market.** Monday-to-Friday is hard-coded, and
///    the Saudi Exchange trades Sunday to Thursday.
///
/// Every one of them is corrected here, and the clock is injected so all of it
/// is testable at a boundary rather than at whatever moment the suite runs.
library;

import 'package:flutter/foundation.dart';

import '../../../core/time/lume_time_zone.dart';
import 'market_calendar.dart';

/// Minutes past midnight, in the exchange's own wall clock.
@immutable
class LumeTradingHours {
  const LumeTradingHours({required this.openMinute, required this.closeMinute});

  /// `'09:32'` → 572.
  factory LumeTradingHours.parse(String open, String close) => LumeTradingHours(
    openMinute: _minutes(open),
    closeMinute: _minutes(close),
  );

  final int openMinute;
  final int closeMinute;

  static int _minutes(String hhmm) {
    final List<String> parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String format(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:'
      '${(minute % 60).toString().padLeft(2, '0')}';

  String get openLabel => format(openMinute);
  String get closeLabel => format(closeMinute);

  /// **Half-open**: open at the opening minute, shut at the closing one.
  ///
  /// The comparison is on whole minutes rather than on a float of hours, so
  /// 09:32 is 572 and not 9.533333333333333.
  bool contains(int minute) => minute >= openMinute && minute < closeMinute;
}

/// Why a market is shut, when it is.
enum LumeMarketClosure {
  /// Outside trading hours on a trading day.
  outsideHours,

  /// Not a trading day of the week for this exchange.
  weekend,

  /// A holiday this exchange observes.
  holiday,
}

/// What the session machine answers.
@immutable
class LumeMarketState {
  const LumeMarketState({
    required this.isOpen,
    required this.closure,
    required this.localTime,
    required this.hours,
    this.holiday,
  });

  final bool isOpen;

  /// `null` while open.
  final LumeMarketClosure? closure;

  /// The exchange's own wall clock at the moment asked about. What the screen
  /// shows when it names a local time, and what a test asserts against.
  final DateTime localTime;

  final LumeTradingHours hours;

  /// The holiday that closed it, when [closure] is [LumeMarketClosure.holiday].
  final LumeHoliday? holiday;

  int get localMinute => localTime.hour * 60 + localTime.minute;

  @override
  bool operator ==(Object other) =>
      other is LumeMarketState &&
      other.isOpen == isOpen &&
      other.closure == closure &&
      other.localTime == localTime &&
      other.holiday?.name == holiday?.name;

  @override
  int get hashCode => Object.hash(isOpen, closure, localTime, holiday?.name);
}

/// One exchange, as the session machine needs it.
@immutable
class LumeExchangeHours {
  const LumeExchangeHours({
    required this.zone,
    required this.hours,
    required this.calendar,
  });

  final LumeTimeZone zone;
  final LumeTradingHours hours;
  final LumeMarketCalendar calendar;

  /// The state at [instant] — an absolute moment, from an injected clock.
  ///
  /// The order is deliberate and is the order a trader would use: *is the
  /// market shut today at all*, then *is it within hours*. A holiday outranks
  /// the weekend so the reason is the specific one; both outrank the clock, so
  /// 11:00 on Christmas morning never reads as open.
  LumeMarketState stateAt(DateTime instant) {
    final DateTime local = zone.wallClockAt(instant);
    final DateTime day = DateTime(local.year, local.month, local.day);

    final LumeHoliday? holiday = calendar.holidayOn(day);
    if (holiday != null) {
      return LumeMarketState(
        isOpen: false,
        closure: LumeMarketClosure.holiday,
        localTime: local,
        hours: hours,
        holiday: holiday,
      );
    }
    if (calendar.isWeekend(day)) {
      return LumeMarketState(
        isOpen: false,
        closure: LumeMarketClosure.weekend,
        localTime: local,
        hours: hours,
      );
    }

    final bool within = hours.contains(local.hour * 60 + local.minute);
    return LumeMarketState(
      isOpen: within,
      closure: within ? null : LumeMarketClosure.outsideHours,
      localTime: local,
      hours: hours,
    );
  }
}

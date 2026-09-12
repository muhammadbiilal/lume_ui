/// The values Home quotes, as types rather than as sentences.
///
/// Every one of these is a number, a date or a key. Nothing here is a
/// user-facing string, which is the point: the same content renders in English,
/// Urdu and Arabic without the repository knowing which, and a test can assert
/// "three bills overdue" without matching text.
///
/// Each type also names where the reference gets it, because at F6 each tool's
/// own repository takes the field over and the fixture here retires. Preserving
/// the identifiers is what makes that a substitution rather than a rewrite —
/// see `docs/conversion_archive/HOME_SOURCE_MAP.md`.
library;

import 'package:flutter/foundation.dart';

import '../../markets/data/exchange_fixtures.dart';
import '../../markets/domain/market_session.dart';

/// `catalogue.js` → `weatherFor(country, tz)`.
@immutable
class LumeWeatherNow {
  const LumeWeatherNow({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.conditionKey,
    required this.rainPercent,
    required this.windKph,
    required this.icon,
    required this.today,
    required this.tomorrow,
  });

  final int temperatureC;
  final int feelsLikeC;

  /// A key into the condition vocabulary — `weather.c.hazySun`. The reference
  /// stores an English sentence in the catalogue and shows it untranslated in
  /// every language.
  final String conditionKey;

  final int rainPercent;
  final int windKph;
  final String icon;

  final LumeDayForecast today;
  final LumeDayForecast tomorrow;
}

@immutable
class LumeDayForecast {
  const LumeDayForecast({
    required this.highC,
    required this.lowC,
    required this.conditionKey,
    required this.rainPercent,
  });

  final int highC;
  final int lowC;
  final String conditionKey;
  final int rainPercent;
}

/// `services/prayer.js` → `prayerState()`.
@immutable
class LumePrayerTimetable {
  const LumePrayerTimetable({required this.times});

  /// Today's five, in order, as wall-clock times in the user's own zone.
  final List<LumePrayerTime> times;

  /// The next prayer at [now], or the first of tomorrow when the day is done.
  ///
  /// Returns tomorrow's Fajr with its date advanced, so "in 8 hours" is a
  /// subtraction rather than a special case.
  LumePrayerTime nextAt(DateTime now) {
    for (final LumePrayerTime p in times) {
      if (p.at.isAfter(now)) return p;
    }
    final LumePrayerTime first = times.first;
    return LumePrayerTime(
      key: first.key,
      at: first.at.add(const Duration(days: 1)),
    );
  }
}

@immutable
class LumePrayerTime {
  const LumePrayerTime({required this.key, required this.at});

  /// `fajr`, `dhuhr`, `asr`, `maghrib`, `isha`.
  final String key;
  final DateTime at;
}

/// `tools/context.js` → `loadshed()`. A market with a published schedule.
@immutable
class LumeOutage {
  const LumeOutage({required this.area, required this.slots});

  final String area;

  /// Today's schedule, in order.
  final List<LumeOutageSlot> slots;

  /// The slot covering [now], or `null`.
  LumeOutageSlot? activeAt(DateTime now) {
    for (final LumeOutageSlot s in slots) {
      if (!now.isBefore(s.from) && now.isBefore(s.to)) return s;
    }
    return null;
  }

  /// The next slot after [now], or `null` when the day is done.
  LumeOutageSlot? nextAfter(DateTime now) {
    for (final LumeOutageSlot s in slots) {
      if (s.from.isAfter(now)) return s;
    }
    return null;
  }
}

@immutable
class LumeOutageSlot {
  const LumeOutageSlot({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  Duration get length => to.difference(from);
}

/// `tools/context.js` → `bills()`.
@immutable
class LumeBillsSummary {
  const LumeBillsSummary({
    required this.overdueCount,
    required this.overdueTotal,
    required this.dueThisMonth,
    required this.due,
  });

  final int overdueCount;
  final double overdueTotal;
  final double dueThisMonth;

  /// The bills that are due or overdue, soonest first.
  final List<LumeBillDue> due;
}

@immutable
class LumeBillDue {
  const LumeBillDue({
    required this.name,
    required this.icon,
    required this.amount,
    required this.dueOn,
    required this.isOverdue,
  });

  final String name;
  final String icon;
  final double amount;
  final DateTime dueOn;
  final bool isOverdue;
}

/// `tools/context.js` → `subscriptions().next`.
@immutable
class LumeSubscriptionRenewal {
  const LumeSubscriptionRenewal({
    required this.name,
    required this.renewsOn,
    required this.days,
  });

  final String name;
  final DateTime renewsOn;
  final int days;
}

/// `tools/context.js` → `birthdays().next`.
@immutable
class LumeBirthdayNext {
  const LumeBirthdayNext({
    required this.name,
    required this.on,
    required this.days,
    required this.kindKey,
  });

  final String name;
  final DateTime on;
  final int days;

  /// `birthday` or `anniversary`.
  final String kindKey;
}

/// `tools/context.js` → `documents()`. Sensitive: Home names the renewal, never
/// the document's contents or its number.
@immutable
class LumeDocumentRenewal {
  const LumeDocumentRenewal({
    required this.name,
    required this.expiresOn,
    required this.days,
  });

  final String name;
  final DateTime expiresOn;
  final int days;
}

/// The Qur'an reading position. Faith-gated everywhere it is read.
@immutable
class LumeReadingProgress {
  const LumeReadingProgress({
    required this.surahKey,
    required this.ayah,
    required this.ayahCount,
    required this.minutesLeft,
  });

  /// `surah.alKahf` — a key, so the name is written in the reader's script.
  final String surahKey;

  final int ayah;
  final int ayahCount;
  final int minutesLeft;

  double get fraction => ayahCount == 0 ? 0 : ayah / ayahCount;
}

/// What is left of today's list.
@immutable
class LumeTaskSummary {
  const LumeTaskSummary({
    required this.remaining,
    required this.total,
    required this.nextTitle,
    required this.nextAt,
  });

  final int remaining;
  final int total;

  /// A task the user wrote. Not a key — it is their text.
  final String nextTitle;
  final DateTime nextAt;

  double get fraction => total == 0 ? 0 : (total - remaining) / total;
}

/// `tool-data.js` → `fuelFor(country)`. The lead grade only; the tool screen
/// shows the rest.
@immutable
class LumeFuelPrice {
  const LumeFuelPrice({
    required this.gradeKey,
    required this.price,
    required this.previous,
    required this.currency,
    required this.effectiveOn,
    required this.sourceKey,
  });

  /// `fuel.g.petrol`.
  final String gradeKey;

  final double price;
  final double previous;
  final String currency;
  final DateTime effectiveOn;

  /// `fuel.src.ogra` — the regulator, named because §108 says a figure without
  /// its source is a figure nobody can check.
  final String sourceKey;

  double get change => price - previous;
  bool get isUp => change >= 0;
}

/// The market snapshot Home quotes, with the session it was taken in.
@immutable
class LumeMarketSnapshot {
  const LumeMarketSnapshot({required this.exchange, required this.state});

  final LumeExchange exchange;
  final LumeMarketState state;

  LumeIndexQuote get index => exchange.leadIndex;
}

/// `tool-data.js` → the cricket fixture. Content, not a calculation.
@immutable
class LumeCricketScore {
  const LumeCricketScore({
    required this.team,
    required this.runs,
    required this.wickets,
    required this.matchKey,
    required this.day,
  });

  /// A three-letter side, which is a proper noun in every language.
  final String team;
  final int runs;
  final int wickets;

  /// `cricket.m.secondTest`.
  final String matchKey;
  final int day;
}

/// `tools/context.js` → `parcels().next`.
@immutable
class LumeParcelStatus {
  const LumeParcelStatus({
    required this.carrier,
    required this.stageKey,
    required this.arrivesToday,
  });

  /// The courier's name — a proper noun.
  final String carrier;

  /// `parcel.s.outForDelivery`.
  final String stageKey;

  final bool arrivesToday;
}

/// Everything Home's repository supplies, before any of it is composed.
///
/// A field is `null` when this user has no such thing — no local exchange, no
/// outage schedule in this market, no bills recorded. `null` is a real answer
/// and Home draws nothing rather than a placeholder.
@immutable
class LumeHomeContent {
  const LumeHomeContent({
    this.weather,
    this.prayer,
    this.market,
    this.outage,
    this.bills,
    this.subscription,
    this.birthday,
    this.document,
    this.reading,
    this.tasks,
    this.fuel,
    this.cricket,
    this.parcel,
    this.nextEventAt,
    this.notificationCount = 0,
  });

  final LumeWeatherNow? weather;
  final LumePrayerTimetable? prayer;
  final LumeMarketSnapshot? market;
  final LumeOutage? outage;
  final LumeBillsSummary? bills;
  final LumeSubscriptionRenewal? subscription;
  final LumeBirthdayNext? birthday;
  final LumeDocumentRenewal? document;
  final LumeReadingProgress? reading;
  final LumeTaskSummary? tasks;
  final LumeFuelPrice? fuel;
  final LumeCricketScore? cricket;
  final LumeParcelStatus? parcel;

  /// The next thing on the calendar. The context strip's trailing value is the
  /// next *event*, which is a different question from the next *task* — the
  /// card lower down answers that one, and the two legitimately differ.
  final DateTime? nextEventAt;

  final int notificationCount;

  LumeHomeContent copyWith({
    LumeWeatherNow? weather,
    LumePrayerTimetable? prayer,
    LumeMarketSnapshot? market,
    LumeOutage? outage,
    LumeBillsSummary? bills,
    LumeSubscriptionRenewal? subscription,
    LumeBirthdayNext? birthday,
    LumeDocumentRenewal? document,
    LumeReadingProgress? reading,
    LumeTaskSummary? tasks,
    LumeFuelPrice? fuel,
    LumeCricketScore? cricket,
    LumeParcelStatus? parcel,
    DateTime? nextEventAt,
    int? notificationCount,
    bool clearWeather = false,
    bool clearMarket = false,
    bool clearBills = false,
  }) => LumeHomeContent(
    weather: clearWeather ? null : (weather ?? this.weather),
    prayer: prayer ?? this.prayer,
    market: clearMarket ? null : (market ?? this.market),
    outage: outage ?? this.outage,
    bills: clearBills ? null : (bills ?? this.bills),
    subscription: subscription ?? this.subscription,
    birthday: birthday ?? this.birthday,
    document: document ?? this.document,
    reading: reading ?? this.reading,
    tasks: tasks ?? this.tasks,
    fuel: fuel ?? this.fuel,
    cricket: cricket ?? this.cricket,
    parcel: parcel ?? this.parcel,
    nextEventAt: nextEventAt ?? this.nextEventAt,
    notificationCount: notificationCount ?? this.notificationCount,
  );
}

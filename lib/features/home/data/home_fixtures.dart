/// Home's deterministic fixture repository.
///
/// Every figure here is the prototype's, read out of `catalogue.js`,
/// `tool-data.js` and `tools/context.js` and then *measured against the
/// rendered screen* — `docs/conversion_archive/HOME_SOURCE_MAP.md` pairs each
/// field with where it came from and where it is drawn.
///
/// Three rules it keeps, and they are the reason it is a class rather than a
/// map of constants:
///
/// * **no clock.** `load` takes the moment; nothing here reads `DateTime.now`.
/// * **no locale.** Everything returned is a number, a date or a key.
/// * **every state is reachable.** [LumeFakeHomeRepository] can be told to
///   fail a section, to answer slowly, to come back stale or offline, or to
///   return nothing at all — so the screen's loading, partial, stale, offline,
///   empty and failed states are each a test rather than a hope.
///
/// It connects to nothing. At Dayroz integration each tool's own repository
/// takes its field over.
library;

import 'dart:async';

import '../../../core/icons/lume_icons.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../markets/data/exchange_fixtures.dart';
import '../domain/home_content.dart';
import '../domain/home_repository.dart';

/// The weather a market gets.
///
/// The prototype carries twenty countries and a climate fallback read off the
/// IANA zone; the conditions are English sentences it never translates. Here
/// they are keys, and the vocabulary is the seven the fixtures need — a
/// deliberate narrowing, recorded rather than hidden.
typedef _Climate = ({
  int temp,
  int feels,
  String condition,
  String discoverCondition,
  int rain,
  int wind,
  String icon,
  int high,
  int low,
  String todayCondition,
  int todayRain,
  int tomorrowHigh,
  int tomorrowLow,
  String tomorrowCondition,
  int tomorrowRain,
});

const Map<String, _Climate> _climate = <String, _Climate>{
  'PK': (
    temp: 34,
    feels: 38,
    condition: 'hazySun',
    discoverCondition: 'hazy',
    rain: 8,
    wind: 14,
    icon: LumeIcons.sun,
    high: 34,
    low: 23,
    todayCondition: 'mostlyClear',
    todayRain: 64,
    tomorrowHigh: 36,
    tomorrowLow: 25,
    tomorrowCondition: 'cloudBuilding',
    tomorrowRain: 1,
  ),
  'IN': (
    temp: 33,
    feels: 37,
    condition: 'hazySun',
    discoverCondition: 'hazy',
    rain: 25,
    wind: 12,
    icon: LumeIcons.sun,
    high: 34,
    low: 24,
    todayCondition: 'mostlyClear',
    todayRain: 40,
    tomorrowHigh: 35,
    tomorrowLow: 25,
    tomorrowCondition: 'cloudBuilding',
    tomorrowRain: 55,
  ),
  'GB': (
    temp: 21,
    feels: 19,
    condition: 'mostlyClear',
    discoverCondition: 'mostlyClear',
    rain: 12,
    wind: 8,
    icon: LumeIcons.cloudSun,
    high: 22,
    low: 13,
    todayCondition: 'mostlyClear',
    todayRain: 20,
    tomorrowHigh: 20,
    tomorrowLow: 12,
    tomorrowCondition: 'overcast',
    tomorrowRain: 55,
  ),
  'US': (
    temp: 24,
    feels: 24,
    condition: 'lightCloud',
    discoverCondition: 'lightCloud',
    rain: 20,
    wind: 10,
    icon: LumeIcons.cloudSun,
    high: 26,
    low: 17,
    todayCondition: 'lightCloud',
    todayRain: 25,
    tomorrowHigh: 25,
    tomorrowLow: 16,
    tomorrowCondition: 'mostlyClear',
    tomorrowRain: 10,
  ),
  'AE': (
    temp: 39,
    feels: 44,
    condition: 'clear',
    discoverCondition: 'clear',
    rain: 0,
    wind: 11,
    icon: LumeIcons.sun,
    high: 40,
    low: 30,
    todayCondition: 'clear',
    todayRain: 0,
    tomorrowHigh: 41,
    tomorrowLow: 31,
    tomorrowCondition: 'clear',
    tomorrowRain: 0,
  ),
  'SA': (
    temp: 40,
    feels: 42,
    condition: 'clear',
    discoverCondition: 'clear',
    rain: 0,
    wind: 9,
    icon: LumeIcons.sun,
    high: 42,
    low: 29,
    todayCondition: 'clear',
    todayRain: 0,
    tomorrowHigh: 42,
    tomorrowLow: 30,
    tomorrowCondition: 'clear',
    tomorrowRain: 0,
  ),
};

const _Climate _defaultClimate = (
  temp: 18,
  feels: 17,
  condition: 'overcast',
  discoverCondition: 'overcast',
  rain: 35,
  wind: 12,
  icon: LumeIcons.cloudSun,
  high: 19,
  low: 11,
  todayCondition: 'overcast',
  todayRain: 35,
  tomorrowHigh: 20,
  tomorrowLow: 12,
  tomorrowCondition: 'lightCloud',
  tomorrowRain: 25,
);

/// The fixture.
class LumeFakeHomeRepository implements LumeHomeRepository {
  LumeFakeHomeRepository({
    this.delay = Duration.zero,
    this.failing = const <LumeHomeSection>{},
    this.sources = const <LumeHomeSection, LumeSourceState>{},
    this.empty = false,
    this.pending = false,
  });

  /// A repository that never answers, for the loading state.
  ///
  /// A future that never completes rather than a long delay: a pending timer
  /// outlives the widget tree and fails the test it was meant to serve.
  factory LumeFakeHomeRepository.slow() =>
      LumeFakeHomeRepository(pending: true);

  /// How long [load] takes. Zero in a test that is not about loading.
  final Duration delay;

  /// [load] never returns. The loading state, held still.
  final bool pending;

  /// Sections whose sources could not be reached at all.
  final Set<LumeHomeSection> failing;

  /// Sections that answered, but not freshly.
  final Map<LumeHomeSection, LumeSourceState> sources;

  /// A user with nothing recorded: no bills, no subscriptions, no birthdays,
  /// no reading position, no tasks. Home then has no "Coming up" and no
  /// progress cards, which is a composition it has to draw honestly.
  final bool empty;

  /// How many times [load] has been called. A refresh is supposed to be one.
  int loads = 0;

  @override
  LumeToolStatuses statusesFor(LumeUserContext user, {required DateTime now}) {
    final _Climate c = _climate[user.country] ?? _defaultClimate;
    final DateTime day = DateTime(now.year, now.month, now.day);
    return LumeToolStatuses(
      prayer: user.islamic ? _timetable(day).nextAt(now) : null,
      weather: LumeWeatherNow(
        temperatureC: c.temp,
        feelsLikeC: c.feels,
        conditionKey: c.condition,
        discoverConditionKey: c.discoverCondition,
        rainPercent: c.rain,
        windKph: c.wind,
        icon: c.icon,
        today: LumeDayForecast(
          highC: c.high,
          lowC: c.low,
          conditionKey: c.todayCondition,
          rainPercent: c.todayRain,
        ),
        tomorrow: LumeDayForecast(
          highC: c.tomorrowHigh,
          lowC: c.tomorrowLow,
          conditionKey: c.tomorrowCondition,
          rainPercent: c.tomorrowRain,
        ),
      ),
    );
  }

  /// What the header badge says, per state, measured rather than guessed.
  ///
  /// The reference's badge is `NOTIFY.unreadCount()`, which counts the
  /// notification *sources* that survive a profile: `build()` walks sixteen
  /// declared sources and `allowed(src)` drops each one whose tool the user
  /// cannot see — the same eligibility gate the catalogue asks — and then the
  /// ones their category and type preferences switch off.
  ///
  /// So it is not a number to invent. These are the counts the running
  /// prototype produces at the pinned instant, read off
  /// `docs/conversion_archive/tool/probe_notifications.mjs`, with the sources
  /// that account for each step:
  ///
  /// | state | count | what changed |
  /// |---|---|---|
  /// | Pakistan | 13 | — |
  /// | Pakistan, the switches off | 12 | `markets.move` ("KSE-100 moved +0.82%") |
  /// | abroad | 10 | also `loadshed.next` and `trains.delay`, whose tools are `countries: ['PK']` |
  ///
  /// The full engine is §48's work. Until it arrives the reference fixture
  /// still has to carry the reference's value, because a badge that says 13
  /// in London when Lume says 10 is a parity failure whether or not the
  /// machinery behind it is built yet.
  static int unreadFor(LumeUserContext user) {
    // Loadshedding and Trains are Pakistan-only, so their two sources cannot
    // fire anywhere else, and the market source follows the country's own
    // exchange.
    if (user.country != 'PK') return 10;
    // `markets.move` is the one the content switches reach.
    return user.prefs.finance ? 13 : 12;
  }

  /// The city's timetable for a day. One definition, so the strip, the hero,
  /// the upcoming row and the tile all name the same prayer.
  static LumePrayerTimetable _timetable(DateTime day) {
    DateTime at(int h, int m) => DateTime(day.year, day.month, day.day, h, m);
    return LumePrayerTimetable(
      times: <LumePrayerTime>[
        LumePrayerTime(key: 'fajr', at: at(4, 38)),
        LumePrayerTime(key: 'dhuhr', at: at(12, 12)),
        LumePrayerTime(key: 'asr', at: at(15, 53)),
        LumePrayerTime(key: 'maghrib', at: at(18, 27)),
        LumePrayerTime(key: 'isha', at: at(19, 52)),
      ],
    );
  }

  @override
  Future<LumeHomeSnapshot> load(
    LumeUserContext user, {
    required DateTime now,
  }) async {
    loads++;
    if (pending) return Completer<LumeHomeSnapshot>().future;
    if (delay > Duration.zero) await Future<void>.delayed(delay);

    final _Climate c = _climate[user.country] ?? _defaultClimate;
    final bool pakistan = user.country == 'PK';
    final LumeExchange? exchange = LumeExchanges.forCountry(user.country);

    final Map<LumeHomeSection, LumeSourceState> state =
        <LumeHomeSection, LumeSourceState>{
          ...sources,
          for (final LumeHomeSection s in failing) s: LumeSourceState.failed,
        };

    final DateTime day = DateTime(now.year, now.month, now.day);
    DateTime at(int hour, int minute) =>
        DateTime(day.year, day.month, day.day, hour, minute);

    return LumeHomeSnapshot(
      fetchedAt: now,
      sources: state,
      content: LumeHomeContent(
        notificationCount: empty ? 0 : unreadFor(user),

        weather: failing.contains(LumeHomeSection.live)
            ? null
            : LumeWeatherNow(
                temperatureC: c.temp,
                feelsLikeC: c.feels,
                conditionKey: c.condition,
                discoverConditionKey: c.discoverCondition,
                rainPercent: c.rain,
                windKph: c.wind,
                icon: c.icon,
                today: LumeDayForecast(
                  highC: c.high,
                  lowC: c.low,
                  conditionKey: c.todayCondition,
                  rainPercent: c.todayRain,
                ),
                tomorrow: LumeDayForecast(
                  highC: c.tomorrowHigh,
                  lowC: c.tomorrowLow,
                  conditionKey: c.tomorrowCondition,
                  rainPercent: c.tomorrowRain,
                ),
              ),

        // The timetable is the city's, and the clock it is compared against is
        // the user's own — not an exchange's, and not the device's.
        prayer: _timetable(day),

        market: exchange == null
            ? null
            : LumeMarketSnapshot(
                exchange: exchange,
                state: exchange.stateAt(now),
              ),

        // A published schedule rather than a sentence. The prototype's Discover
        // card says "Next outage 14:00" in fixed markup while its own schedule
        // has that slot ending at 16:00 — so at 16:41 it named an outage that
        // was already over (C17).
        outage: pakistan
            ? LumeOutage(
                area: 'Gulshan',
                slots: <LumeOutageSlot>[
                  LumeOutageSlot(from: at(6, 0), to: at(7, 0)),
                  LumeOutageSlot(from: at(10, 0), to: at(11, 0)),
                  LumeOutageSlot(from: at(14, 0), to: at(16, 0)),
                  LumeOutageSlot(from: at(19, 0), to: at(20, 0)),
                  LumeOutageSlot(from: at(23, 0), to: at(23, 59)),
                ],
              )
            : null,

        bills: empty
            ? null
            : LumeBillsSummary(
                overdueCount: 1,
                overdueTotal: _money(7920, user.country),
                dueThisMonth: _money(37400, user.country),
                due: <LumeBillDue>[
                  LumeBillDue(
                    name: 'Electricity',
                    icon: LumeIcons.bolt,
                    amount: _money(20900, user.country),
                    dueOn: day.add(const Duration(days: 4)),
                    isOverdue: false,
                  ),
                  LumeBillDue(
                    name: 'Internet',
                    icon: LumeIcons.wifi,
                    amount: _money(7920, user.country),
                    dueOn: day.subtract(const Duration(days: 5)),
                    isOverdue: true,
                  ),
                ],
              ),

        subscription: empty
            ? null
            : LumeSubscriptionRenewal(
                name: 'Netflix',
                renewsOn: day.add(const Duration(days: 7)),
                days: 7,
              ),

        birthday: empty
            ? null
            : LumeBirthdayNext(
                name: 'Ayesha',
                on: day.add(const Duration(days: 4)),
                days: 4,
                kindKey: 'birthday',
              ),

        // Sensitive: Home names the renewal, never the document.
        document: empty
            ? null
            : LumeDocumentRenewal(
                name: 'Passport',
                expiresOn: day.add(const Duration(days: 22)),
                days: 22,
              ),

        reading: empty
            ? null
            : const LumeReadingProgress(
                surahKey: 'alKahf',
                ayah: 42,
                ayahCount: 110,
                minutesLeft: 6,
              ),

        tasks: empty
            ? null
            : LumeTaskSummary(
                remaining: 3,
                total: 5,
                nextTitle: 'Finish the Q3 summary',
                nextAt: at(15, 0),
              ),

        // Only where a regulator publishes one national price. Pakistan's OGRA
        // does; the UK's figure is a retail average, which is why the
        // prototype's Home shows no fuel row there either.
        fuel: pakistan
            ? LumeFuelPrice(
                gradeKey: 'petrol',
                price: 264.61,
                previous: 262.47,
                currency: 'PKR',
                effectiveOn: DateTime(now.year, now.month, 1),
                sourceKey: 'ogra',
              )
            : null,

        cricket: pakistan
            ? const LumeCricketScore(
                team: 'PAK',
                runs: 214,
                wickets: 4,
                matchKey: 'secondTest',
                day: 2,
              )
            : null,

        parcel: pakistan
            ? const LumeParcelStatus(
                carrier: 'TCS',
                stageKey: 'outForDelivery',
                arrivesToday: true,
              )
            : null,

        nextEventAt: empty ? null : at(14, 0),
      ),
    );
  }

  /// The Pakistani figures converted at the fixture's own rate.
  ///
  /// The prototype stores bills in a base unit and multiplies by a per-market
  /// rate. Preserved so the numbers on a UK Home are plausible rather than
  /// Karachi's figures with a pound sign.
  static double _money(double pkr, String country) => switch (country) {
    'PK' => pkr,
    'IN' => pkr * 0.32,
    'GB' => pkr * 0.0028,
    'US' => pkr * 0.0036,
    'AE' => pkr * 0.0131,
    'SA' => pkr * 0.0134,
    _ => pkr * 0.0036,
  };
}

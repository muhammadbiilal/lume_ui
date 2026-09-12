/// Explore's context, as a deterministic fixture.
///
/// Read off the running prototype at the pinned instant with
/// `measure_destinations.mjs --screen explore`, in five profiles. Every value
/// that the reference derives per market is derived here per market too; the
/// two that it writes down as literals are written down here, by decision, and
/// each says so where it is declared.
///
/// **Nothing here is labelled live.** `LumeExploreSnapshot.freshness` reports
/// `fixture` for every source, which is what it is.
library;

import 'dart:async';

import '../../../core/icons/lume_icons.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../home/domain/home_model.dart';
import '../../today/data/today_fixtures.dart';
import '../domain/explore_model.dart';
import '../domain/explore_repository.dart';

/// The weather a market reads, measured from `WEATHER_BY_COUNTRY`.
///
/// The condition is the market's *whole phrase* — Pakistan's entry is
/// `'Hazy sun · humid'`, not `'Hazy sun'` — because that is what Explore's
/// card shows. Home's live row reads a shorter one from a different field;
/// three surfaces, three levels of detail, as C21 records.
typedef _Weather = ({
  int temp,
  int feels,
  String condition,
  int rain,
  int wind,
  String icon,
});

const Map<String, _Weather> _weather = <String, _Weather>{
  'PK': (
    temp: 34,
    feels: 38,
    condition: 'hazySunHumid',
    rain: 8,
    wind: 14,
    icon: LumeIcons.sun,
  ),
  'GB': (
    temp: 21,
    feels: 19,
    condition: 'mostlyClear',
    rain: 12,
    wind: 8,
    icon: LumeIcons.cloudSun,
  ),
  'US': (
    temp: 24,
    feels: 24,
    condition: 'lightCloud',
    rain: 20,
    wind: 10,
    icon: LumeIcons.cloudSun,
  ),
  'IN': (
    temp: 33,
    feels: 37,
    condition: 'humidLightHaze',
    rain: 25,
    wind: 12,
    icon: LumeIcons.sun,
  ),
  'AE': (
    temp: 39,
    feels: 44,
    condition: 'clearVeryWarm',
    rain: 0,
    wind: 11,
    icon: LumeIcons.sun,
  ),
  'SA': (
    temp: 40,
    feels: 42,
    condition: 'clear',
    rain: 0,
    wind: 9,
    icon: LumeIcons.sun,
  ),
};

const _Weather _defaultWeather = (
  temp: 18,
  feels: 17,
  condition: 'overcast',
  rain: 40,
  wind: 11,
  icon: LumeIcons.cloudSun,
);

/// **The literal.** `explore.screen.js` writes `L.num(4)` into the weather
/// subtitle: "updated 4 min ago", the same claim in every market, forever,
/// with no fetch behind it (E1). Reproduced by decision so the reference
/// renders the same; Dayroz's weather adapter must replace it with the real
/// age of the data it is showing.
const int kReferenceWeatherAgeMinutes = 4;

/// What each local service says, per market. Measured row by row.
typedef _Service = ({String value, String subtitle});

const Map<String, Map<String, _Service>>
_around = <String, Map<String, _Service>>{
  'PK': <String, _Service>{
    'fuel': (value: 'Rs\u00a0264.61', subtitle: 'Petrol · Hi-Octane · Diesel'),
    'loadshed': (value: '19:00', subtitle: 'Islamabad · 19:00 to 20:00'),
    'goldrates': (value: 'Rs\u00a0290,480', subtitle: 'Open market · Gold 24k'),
    'trains': (value: '', subtitle: 'Green Line Express · On time'),
    'emergency': (value: '1122', subtitle: 'Rescue 1122'),
    'holidays': (value: '9 Nov', subtitle: 'Iqbal Day'),
  },
  'GB': <String, _Service>{
    'fuel': (value: '£1.34', subtitle: 'Unleaded · Super Unleaded · Diesel'),
    'goldrates': (value: '£811', subtitle: 'Open market · Gold 24k'),
    'emergency': (value: '999', subtitle: 'Emergency'),
    'holidays': (value: '25 Dec', subtitle: 'Christmas Day'),
  },
  'US': <String, _Service>{
    'fuel': (value: r'$3.12', subtitle: 'Regular · Mid-grade · Premium'),
    'goldrates': (value: r'$1,026', subtitle: 'Open market · Gold 24k'),
    'emergency': (value: '911', subtitle: 'Emergency'),
    'holidays': (value: '28 Nov', subtitle: 'Thanksgiving'),
  },
};

/// The market names the "Around you" tag shows.
///
/// The reference asks `Intl.DisplayNames('region')`, which a browser has and
/// Dart's `intl` does not ship. The markets the captures cover are named here;
/// anywhere else the tag falls back to the code rather than inventing a name.
/// Dayroz supplies real region display names with its locale data.
const Map<String, String> _countryNames = <String, String>{
  'PK': 'Pakistan',
  'GB': 'United Kingdom',
  'US': 'United States',
  'IN': 'India',
  'AE': 'United Arab Emirates',
  'SA': 'Saudi Arabia',
};

/// The order the reference declares, which is the order they render in.
const List<(String, String)> _serviceOrder = <(String, String)>[
  ('fuel', LumeIcons.fuel),
  ('loadshed', LumeIcons.bolt),
  ('goldrates', LumeIcons.coins),
  ('trains', LumeIcons.train),
  ('emergency', LumeIcons.shield),
  ('holidays', LumeIcons.calendar),
];

/// `catalogue.js` → `NEWS.PK` and `NEWS.GLOBAL`.
const List<LumeNewsArticle> _newsPk = <LumeNewsArticle>[
  LumeNewsArticle(
    id: 'rupee',
    tone: LumeArticleTone.accent,
    categoryKey: 'business',
  ),
  LumeNewsArticle(
    id: 'loadshed',
    tone: LumeArticleTone.amber,
    categoryKey: 'karachi',
  ),
  LumeNewsArticle(
    id: 'squad',
    tone: LumeArticleTone.violet,
    categoryKey: 'sport',
  ),
];

const List<LumeNewsArticle> _newsGlobal = <LumeNewsArticle>[
  LumeNewsArticle(
    id: 'reset',
    tone: LumeArticleTone.accent,
    categoryKey: 'wellbeing',
  ),
  LumeNewsArticle(
    id: 'shortList',
    tone: LumeArticleTone.violet,
    categoryKey: 'productivity',
  ),
  LumeNewsArticle(
    id: 'savings',
    tone: LumeArticleTone.amber,
    categoryKey: 'money',
  ),
];

const List<LumeCollectionCard> _collections = <LumeCollectionCard>[
  LumeCollectionCard(
    id: 'nightSurahs',
    target: LumeHomeTarget.tool('quran'),
    faithOnly: true,
  ),
  LumeCollectionCard(id: 'focus', target: LumeHomeTarget.tool('focus')),
  LumeCollectionCard(id: 'gratitude', target: LumeHomeTarget.tool('notes')),
  LumeCollectionCard(id: 'budget', target: LumeHomeTarget.tool('expenses')),
];

/// **Fabricated content, reproduced by decision (E2).**
///
/// Three Karachi venues with metre distances, which the reference shows to
/// every reader in every market with no city gate and no source. A reader in
/// London is told Masjid-e-Tooba is 650 m away.
///
/// Kept identical to the reference so the conversion reproduces rather than
/// redesigns. **Dayroz must back this with a real places source keyed to the
/// reader's city, or not ship it.**
const List<LumeNearbyPlace> _nearby = <LumeNearbyPlace>[
  LumeNearbyPlace(
    id: 'tooba',
    icon: LumeIcons.mosque,
    distanceMetres: 650,
    faithOnly: true,
  ),
  LumeNearbyPlace(id: 'chaiShai', icon: LumeIcons.pin, distanceMetres: 1100),
  LumeNearbyPlace(id: 'hillPark', icon: LumeIcons.globe, distanceMetres: 1400),
];

/// Composes Explore. Pure, so the composition can be asserted without a frame.
abstract final class LumeExploreComposer {
  /// The local services this reader's market actually has.
  ///
  /// Two gates, in the reference's order: the feature must be visible to this
  /// reader, and the service must have something to say. *"A service that
  /// cannot answer right now is left out rather than shown with a blank where
  /// its number should be."*
  static List<LumeAroundService> around({
    required LumeUserContext user,
    required LumeEligibility eligibility,
  }) {
    final Map<String, _Service> market =
        _around[user.country] ?? const <String, _Service>{};
    return <LumeAroundService>[
      for (final (String id, String icon) in _serviceOrder)
        if (eligibility.visibleById(id, user) != null)
          if (market[id] case final _Service s)
            LumeAroundService(
              featureId: id,
              icon: icon,
              subtitle: s.subtitle,
              value: s.value.isEmpty ? null : s.value,
            ),
    ];
  }

  /// The reader's news edition.
  static List<LumeNewsArticle> news(LumeUserContext user) =>
      user.country == 'PK' ? _newsPk : _newsGlobal;

  /// The collections this reader can see.
  static List<LumeCollectionCard> collections(LumeUserContext user) =>
      <LumeCollectionCard>[
        for (final LumeCollectionCard c in _collections)
          if (user.islamic || !c.faithOnly) c,
      ];

  /// The nearby rows this reader can see. See [_nearby].
  static List<LumeNearbyPlace> nearby(LumeUserContext user) =>
      <LumeNearbyPlace>[
        for (final LumeNearbyPlace p in _nearby)
          if (user.islamic || !p.faithOnly) p,
      ];

  /// The weather card's reading, taken [now] less its pinned age.
  static LumeExploreWeather weather(
    LumeUserContext user, {
    required DateTime now,
  }) {
    final _Weather w = _weather[user.country] ?? _defaultWeather;
    return LumeExploreWeather(
      city: user.city,
      temperatureC: w.temp,
      feelsLikeC: w.feels,
      conditionKey: w.condition,
      rainPercent: w.rain,
      windKph: w.wind,
      icon: w.icon,
      // Maghrib, from the same table Today's agenda reads.
      sunsetMinute: lumeSunsetMinute(user.country) ?? 18 * 60 + 30,
      observedAt: now.subtract(
        const Duration(minutes: kReferenceWeatherAgeMinutes),
      ),
    );
  }

  /// The live score, when the reader has asked for cricket.
  ///
  /// `data-int="cricket"` in the reference: shown when the reader has the
  /// cricket interest, or has chosen no interests at all.
  static LumeExploreScore? score(LumeUserContext user) {
    final bool wanted = user.interests.isEmpty || user.hasInterest('cricket');
    if (!wanted) return null;
    return const LumeExploreScore(
      homeTeam: 'PAK',
      homeRuns: 214,
      homeWickets: 4,
      homeOvers: 58.2,
      awayTeam: 'SA',
      awayRuns: 301,
      trailBy: 87,
      topScorer: 'Babar',
      topScore: 78,
    );
  }
}

/// The fixture repository.
class LumeFakeExploreRepository implements LumeExploreRepository {
  LumeFakeExploreRepository({
    required this.eligibility,
    this.delay = Duration.zero,
    this.pending = false,
    this.failing = const <LumeExploreSource>{},
  });

  /// A load that never returns.
  factory LumeFakeExploreRepository.slow({
    required LumeEligibility eligibility,
  }) => LumeFakeExploreRepository(eligibility: eligibility, pending: true);

  final LumeEligibility eligibility;
  final Duration delay;
  final bool pending;

  /// Sources that could not answer. The reference has no such state; a real
  /// provider does, and a section that says so is better than one that
  /// vanishes.
  final Set<LumeExploreSource> failing;

  int loads = 0;

  @override
  Future<LumeExploreSnapshot> load(
    LumeUserContext user, {
    required DateTime now,
  }) async {
    loads++;
    if (pending) return Completer<LumeExploreSnapshot>().future;
    if (delay > Duration.zero) await Future<void>.delayed(delay);

    final List<LumeAroundService> around =
        failing.contains(LumeExploreSource.around)
        ? const <LumeAroundService>[]
        : LumeExploreComposer.around(user: user, eligibility: eligibility);

    return LumeExploreSnapshot(
      fetchedAt: now,
      freshness: <LumeExploreSource, LumeSourceFreshness>{
        for (final LumeExploreSource s in LumeExploreSource.values)
          s: failing.contains(s)
              ? LumeSourceFreshness.unavailable
              // Never `live`: this is a fixture and says so.
              : LumeSourceFreshness.fixture,
      },
      data: LumeExploreData(
        countryCode: user.country,
        countryName: _countryNames[user.country] ?? user.country,
        localised: eligibility.localisedCountries.contains(user.country),
        featured: LumeFeaturedCollection(
          id: user.islamic ? LumeFeatureId.duas : LumeFeatureId.calmWeek,
          target: LumeHomeTarget.tool(user.islamic ? 'duas' : 'habits'),
        ),
        weather: LumeExploreComposer.weather(user, now: now),
        around: around,
        score: failing.contains(LumeExploreSource.score)
            ? null
            : LumeExploreComposer.score(user),
        news: failing.contains(LumeExploreSource.news)
            ? const <LumeNewsArticle>[]
            : LumeExploreComposer.news(user),
        collections: LumeExploreComposer.collections(user),
        nearby: failing.contains(LumeExploreSource.nearby)
            ? const <LumeNearbyPlace>[]
            : LumeExploreComposer.nearby(user),
      ),
    );
  }
}

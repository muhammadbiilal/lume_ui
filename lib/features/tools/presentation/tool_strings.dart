/// The words the tool frame says about any tool, from its specification.
///
/// `engine.js` builds these the same way for all 85 — the header's sub-line,
/// the freshness mark and the "Updated …" line — so they live in one place and
/// a tool supplies none of them.
library;

import '../../../core/localization/lume_format.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../catalogue/domain/lume_feature.dart';

abstract final class LumeToolStrings {
  /// `archetype.<a>`.
  static String archetype(AppLocalizations l, LumeToolArchetype a) =>
      switch (a) {
        LumeToolArchetype.action => l.archetypeAction,
        LumeToolArchetype.calculator => l.archetypeCalculator,
        LumeToolArchetype.dashboard => l.archetypeDashboard,
        LumeToolArchetype.explorer => l.archetypeExplorer,
        LumeToolArchetype.instrument => l.archetypeInstrument,
        LumeToolArchetype.library => l.archetypeLibrary,
        LumeToolArchetype.manager => l.archetypeManager,
        LumeToolArchetype.planner => l.archetypePlanner,
        LumeToolArchetype.reader => l.archetypeReader,
        LumeToolArchetype.tracker => l.archetypeTracker,
        LumeToolArchetype.tracking => l.archetypeTracking,
      };

  /// `archetypeLine()` — the city for a city-aware tool, else the country for
  /// a country-aware one, then the archetype.
  static String subtitle(
    AppLocalizations l,
    LumeFeature feature,
    LumeUserContext user,
    String countryName,
  ) => <String>[
    if (feature.aware.contains('city') && user.city.isNotEmpty)
      user.city
    else if (feature.aware.contains('country') && countryName.isNotEmpty)
      countryName,
    archetype(l, feature.archetype),
  ].join(' · ');

  /// `FRESH_TEXT[kind].quality` — ten words, six drawn qualities.
  static LumeFreshnessQuality quality(LumeFreshnessKind kind) => switch (kind) {
    LumeFreshnessKind.live => LumeFreshnessQuality.live,
    LumeFreshnessKind.delayed => LumeFreshnessQuality.delayed,
    LumeFreshnessKind.computed => LumeFreshnessQuality.computed,
    LumeFreshnessKind.local => LumeFreshnessQuality.local,
    LumeFreshnessKind.cached ||
    LumeFreshnessKind.daily ||
    LumeFreshnessKind.weekly ||
    LumeFreshnessKind.annual ||
    LumeFreshnessKind.draw ||
    LumeFreshnessKind.reference => LumeFreshnessQuality.cached,
  };

  /// `FRESH_TEXT[kind].key`.
  static String freshness(AppLocalizations l, LumeFreshnessKind kind) =>
      switch (kind) {
        LumeFreshnessKind.live => l.freshLive,
        LumeFreshnessKind.cached => l.freshCached,
        LumeFreshnessKind.delayed => l.freshDelayed,
        LumeFreshnessKind.daily => l.freshDaily,
        LumeFreshnessKind.weekly => l.freshWeekly,
        LumeFreshnessKind.annual => l.freshAnnual,
        LumeFreshnessKind.draw => l.freshDraw,
        LumeFreshnessKind.computed => l.freshComputed,
        LumeFreshnessKind.reference => l.freshStatic,
        LumeFreshnessKind.local => l.freshLocal,
      };

  /// `updatedLabel()`. A live or delayed feed says when it last moved; a
  /// daily one the hour it is published; a weekly or annual one the day; a
  /// computed one whose place it was worked out for; the rest say nothing.
  ///
  /// The thirty seconds and fifteen minutes are the reference's own fixed
  /// figures — no feed has been read, so nothing here is measured from one.
  static String? updated(
    AppLocalizations l,
    LumeFormatting f,
    LumeFreshnessKind kind, {
    required DateTime now,
    required String city,
  }) => switch (kind) {
    LumeFreshnessKind.live => l.freshAgoSec(30),
    LumeFreshnessKind.delayed => l.freshAgoMin(15),
    LumeFreshnessKind.daily || LumeFreshnessKind.draw => l.freshAt(
      f.time(DateTime(now.year, now.month, now.day, 6)),
    ),
    LumeFreshnessKind.weekly ||
    LumeFreshnessKind.annual => l.freshOn(f.dateShort(now)),
    LumeFreshnessKind.computed => l.freshForCity(city),
    _ => null,
  };

  /// `src.<id>`, or the spec's own `src`, in the reader's language.
  static String source(AppLocalizations l, LumeFeature feature) =>
      feature.id == 'tax'
      ? l.toolSourceTax
      : sourceName(l, feature.fallbackSource) ?? feature.fallbackSource;

  /// A catalogue `fallbackSource`, translated — `null` for one with no
  /// key, which `tool_strings_test.dart` fails on. The catalogue keeps the
  /// English, because the claim rules in `source_claims.dart` match on it.
  static String? sourceName(AppLocalizations l, String source) =>
      switch (source) {
        'On device' => l.toolSourceOnDevice,
        'Statutory slabs' => l.toolSourceTax,
        'ADS-B network' => l.toolSourceAdsb,
        'Asma ul Husna' => l.toolSourceAsmaUlHusna,
        'Astronomical calculation' => l.toolSourceAstronomical,
        'Bullion + open market' => l.toolSourceBullion,
        'Camera' => l.toolSourceCamera,
        'Carrier tracking' => l.toolSourceCarrier,
        'Classical faraid rules' => l.toolSourceFaraid,
        'Current pump price' => l.toolSourcePumpPrice,
        'Distribution company' => l.toolSourceDistribution,
        'Dua collection' => l.toolSourceDuas,
        'Encrypted on device' => l.toolSourceEncrypted,
        'Exchange feed' => l.toolSourceExchange,
        'Excise records' => l.toolSourceExcise,
        'Forecast model' => l.toolSourceForecast,
        'Great-circle bearing' => l.toolSourceGreatCircle,
        'Hadith collections' => l.toolSourceHadith,
        'Hijri calendar + solar times' => l.toolSourceHijriSolar,
        'IANA time zones' => l.toolSourceIana,
        'ICAO + national specs' => l.toolSourceIcao,
        'Interbank composite' => l.toolSourceInterbank,
        'Match feed' => l.toolSourceMatchFeed,
        'Monitoring stations' => l.toolSourceMonitoring,
        'National Savings schedule' => l.toolSourceNatSavings,
        'National calendars' => l.toolSourceNationalCalendars,
        'National directory' => l.toolSourceNationalDirectory,
        'Nisab from live metal rates' => l.toolSourceNisab,
        'Official draw results' => l.toolSourceDrawResults,
        'On device + provider' => l.toolSourceOnDeviceProvider,
        'Operator live feed' => l.toolSourceOperatorFeed,
        'Operator tariffs' => l.toolSourceOperatorTariffs,
        'Places directory' => l.toolSourcePlaces,
        'Nearest test server' => l.toolSourceTestServer,
        'Publisher feeds' => l.toolSourcePublishers,
        'Qur’an text' => l.toolSourceQuranText,
        'Recipe library' => l.toolSourceRecipes,
        'Regulator notification' => l.toolSourceRegulator,
        'Tabular Islamic calendar' => l.toolSourceTabularHijri,
        _ => null,
      };
}

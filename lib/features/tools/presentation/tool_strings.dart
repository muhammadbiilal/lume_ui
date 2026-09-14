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

  /// `src.<id>`, or the spec's own `src`. A converted tool's source is
  /// translated; the rest keep the reference's English until they are.
  static String source(AppLocalizations l, LumeFeature feature) =>
      switch (feature.id) {
        'tax' => l.toolSourceTax,
        _ when feature.fallbackSource == 'On device' => l.toolSourceOnDevice,
        _ => feature.fallbackSource,
      };
}

/// The feature registry's types: what a feature *is*, and what decides whether
/// this user can see it.
///
/// §19 makes the catalogue the single source of truth, and §63 forbids
/// scattering `if country == PK` and `if Muslim` across screens. Both rules
/// land here: a feature declares its own gating once, and every surface —
/// Home, the Tools hub, search, notifications, recents, deep links — asks the
/// same [LumeEligibility] rather than each re-deriving it.
///
/// **Two gates, deliberately not mixed** (`eligibility.js` says this in so many
/// words):
///
/// * [LumeFeature.faith] — the feature belongs to the Islamic experience and
///   appears only when that is switched on.
/// * [LumeFeature.countries] — the markets a feature has *launched in*. This
///   is availability, not localisation. A global feature whose content adapts
///   ([LumeFeature.adapts]) stays visible everywhere; only a feature with no
///   meaning elsewhere carries the list.
///
/// A third gate lives on the profile rather than on the feature: four features
/// are switched off by a content preference the user set in Personalisation.
library;

import 'package:flutter/foundation.dart';

/// The Tools hub's category headers.
///
/// A category is a *presentation* grouping — which block of the hub a tool is
/// drawn in. It is not the same axis as [LumeFeatureGroup], which is the
/// product taxonomy the specification lists features under, and the two
/// genuinely disagree: BMI Calculator is a `personal` category card and a
/// `daily` product feature.
enum LumeToolCategory { everyday, planning, islamic, money, daily, personal }

/// The product group a feature belongs to — `g` in the catalogue.
enum LumeFeatureGroup { daily, money, islam, personal }

/// One feature.
@immutable
class LumeFeature {
  const LumeFeature({
    required this.id,
    required this.fallbackName,
    required this.icon,
    required this.category,
    required this.group,
    this.interests = const <String>{},
    this.keywords = const <String>{},
    this.faith = false,
    this.countries,
    this.adapts = false,
    this.shareable = false,
    this.requiresCity = false,
    this.sensitive = false,
    this.staple = false,
    this.androidOnly = false,
    this.homeEligible = false,
    this.quickEligible = false,
    this.related = const <String>{},
  });

  /// The stable identity. It is the route parameter, the status key, the
  /// recents entry and the favourite, so it must never be re-spelled.
  final String id;

  /// The English name from the catalogue.
  ///
  /// A **fallback only**: `featureName` reads the ARB first, and
  /// `catalogue_test.dart` requires every feature to have a key in all three
  /// languages, so this is never what the product renders.
  final String fallbackName;

  /// The glyph, by [LumeIcons] name.
  final String icon;

  final LumeToolCategory category;
  final LumeFeatureGroup group;

  /// The interests that make this feature "for you".
  final Set<String> interests;

  /// Extra search terms — what people actually type. "petrol" finds Fuel
  /// Prices; "namaz" and "salah" find Prayer Times.
  final Set<String> keywords;

  /// Part of the Islamic experience. Hidden unless the user has switched it on.
  final bool faith;

  /// The markets this feature has launched in. `null` means global.
  final Set<String>? countries;

  /// A global feature whose *content* localises. Visibility is unaffected;
  /// this is documentation of why it has no [countries] list.
  final bool adapts;

  /// Supports the visual share-card flow (§38).
  final bool shareable;

  /// Needs a city to mean anything.
  final bool requiresCity;

  /// Sensitive (§61). Never promoted as a Home card; may still be a quick
  /// action, because *adding* an expense is a task and does not disclose one.
  final bool sensitive;

  /// A tool almost everyone wants, so it survives the "For you" shortlist even
  /// when it matches none of the user's interests.
  final bool staple;

  /// Implemented on Android only.
  final bool androidOnly;

  /// §117 — may appear as a Home card.
  final bool homeEligible;

  /// §118 — may appear as a Home quick action.
  final bool quickEligible;

  /// §97 — the tools this one connects to.
  final Set<String> related;

  /// Whether this feature is restricted to particular markets.
  bool get isCountryRestricted => countries != null;

  /// Lower-cased haystack for search — the reference's `data-hay`, which is
  /// the name and the keywords and nothing else.
  ///
  /// The localised name is added by the search index at query time, because a
  /// catalogue constant cannot know what language the user reads.
  String get fallbackHaystack =>
      '${fallbackName.toLowerCase()} ${keywords.join(' ')}'.trim();
}

/// One Tools-hub category header.
@immutable
class LumeCategory {
  const LumeCategory({
    required this.id,
    required this.fallbackLabel,
    required this.icon,
    this.faith = false,
  });

  final LumeToolCategory id;

  /// English, and a fallback only — see [LumeFeature.fallbackName].
  final String fallbackLabel;

  final String icon;

  /// The whole category disappears when the Islamic experience is off. The
  /// chip that selected it disappears with it, which is why
  /// [LumeToolsFilter] re-validates its selection on every rebuild.
  final bool faith;
}

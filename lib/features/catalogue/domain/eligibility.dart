/// Whether a feature exists for this user — decided here and nowhere else.
///
/// `eligibility.js` opens with the rule this file keeps: *"Home, Tools, Today,
/// Explore, search, the tab bar, notifications, recents, related tools and
/// deep links all ask the same `visible()`, so a feature cannot be hidden from
/// one surface and reachable from another."* §63 forbids scattering the
/// checks; §64 asks for defence in depth, which only works when every layer is
/// asking one question rather than each writing its own.
///
/// Three gates, kept apart on purpose:
///
/// | gate | source | means |
/// |---|---|---|
/// | faith | [LumeFeature.faith] | part of the Islamic experience |
/// | country | [LumeFeature.countries] | the markets it has launched in |
/// | preference | [LumeContentPrefs] | content the user switched off |
///
/// None of them is derived from another. A Muslim user in Japan sees the
/// Islamic experience and no Pakistani service; a non-Muslim user in Pakistan
/// sees the services and none of the Islamic experience (§3, §66).
library;

import 'package:flutter/foundation.dart';

import '../../onboarding/domain/onboarding_state.dart';
import 'lume_feature.dart';

/// The personalisation this selector reads, and nothing else.
///
/// A view of the profile rather than the profile itself, so eligibility can be
/// answered for a *candidate* context — an onboarding draft previewing another
/// country, a test asserting four markets — without writing anything.
@immutable
class LumeUserContext {
  const LumeUserContext({
    this.country = 'PK',
    this.city = 'Islamabad',
    this.islamic = false,
    this.interests = const <String>{},
    this.recents = const <String>[],
    this.favourites = const <String>[],
    this.prefs = LumeContentPrefs.on,
    this.displayName = '',
  });

  /// Read a context out of a stored record.
  factory LumeUserContext.from(LumeProfileRecord record) => LumeUserContext(
    country: record.country,
    city: record.city,
    // `null` is "never expressed", and the migration has already turned every
    // cohort it could name into a decision. Off is the safe reading of what
    // is left — never an inference from country, language or interests.
    islamic: record.islamic ?? false,
    // `app-store.js`'s `load()`: a record with nothing chosen falls back to
    // the general defaults, because somebody who skipped the picker still gets
    // a personal app. The *empty* shortlist is still expressible — a user who
    // deliberately deselects everything gets it — but a fresh record is not
    // that, and greeting a new user with an empty hub would be.
    interests: record.interests.isEmpty
        ? LumeOnboardingState.defaultInterests.toSet()
        : record.interests.toSet(),
    recents: record.recents,
    favourites: record.favourites,
    prefs: record.prefs,
    displayName: record.displayName,
  );

  final String country;
  final String city;
  final bool islamic;
  final Set<String> interests;
  final List<String> recents;
  final List<String> favourites;
  final LumeContentPrefs prefs;
  final String displayName;

  LumeUserContext copyWith({
    String? country,
    String? city,
    bool? islamic,
    Set<String>? interests,
    List<String>? recents,
    List<String>? favourites,
    LumeContentPrefs? prefs,
    String? displayName,
  }) => LumeUserContext(
    country: country ?? this.country,
    city: city ?? this.city,
    islamic: islamic ?? this.islamic,
    interests: interests ?? this.interests,
    recents: recents ?? this.recents,
    favourites: favourites ?? this.favourites,
    prefs: prefs ?? this.prefs,
    displayName: displayName ?? this.displayName,
  );

  bool hasInterest(String id) => interests.contains(id);

  @override
  bool operator ==(Object other) =>
      other is LumeUserContext &&
      other.country == country &&
      other.city == city &&
      other.islamic == islamic &&
      setEquals(other.interests, interests) &&
      listEquals(other.recents, recents) &&
      listEquals(other.favourites, favourites) &&
      other.prefs == prefs &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(
    country,
    city,
    islamic,
    Object.hashAllUnordered(interests),
    Object.hashAll(recents),
    Object.hashAll(favourites),
    prefs,
    displayName,
  );
}

/// Why a feature is not available, when it is not.
///
/// A reason rather than a bare `false`, because §64's "honest unavailable
/// state" needs to say *which* wall the user hit — and because a test that
/// asserts only "hidden" cannot tell a faith gate from a country gate.
enum LumeUnavailableReason {
  /// The Islamic experience is switched off.
  faith,

  /// Not launched in this market.
  country,

  /// The user switched this kind of content off.
  preference,
}

/// The one visibility selector.
class LumeEligibility {
  const LumeEligibility({required this.features, required this.categories});

  /// The whole registry, in catalogue order.
  final List<LumeFeature> features;

  /// The Tools hub's categories, in catalogue order.
  final List<LumeCategory> categories;

  /// `PREF_GATED` — the four features a content switch can hide, and which
  /// switch hides each.
  static bool _prefAllows(LumeFeature f, LumeContentPrefs p) => switch (f.id) {
    'cricket' => p.cricket,
    'news' => p.news,
    'markets' || 'goldrates' => p.finance,
    _ => true,
  };

  /// Why [f] is unavailable to [ctx], or `null` when it is available.
  ///
  /// Checked in declaration order so the reason is stable: a Pakistani
  /// Islamic feature seen by a non-Muslim in the UK reports [faith], not
  /// [country], every time.
  LumeUnavailableReason? reasonFor(LumeFeature f, LumeUserContext ctx) {
    if (f.faith && !ctx.islamic) return LumeUnavailableReason.faith;
    if (f.countries != null && !f.countries!.contains(ctx.country)) {
      return LumeUnavailableReason.country;
    }
    if (!_prefAllows(f, ctx.prefs)) return LumeUnavailableReason.preference;
    return null;
  }

  /// `visible()`.
  bool isVisible(LumeFeature f, LumeUserContext ctx) =>
      reasonFor(f, ctx) == null;

  /// `visibleFeatures()` — the catalogue this user actually has, in catalogue
  /// order.
  List<LumeFeature> visibleFeatures(LumeUserContext ctx) =>
      features.where((LumeFeature f) => isVisible(f, ctx)).toList();

  /// The categories that have at least one visible feature.
  ///
  /// A faith category disappears with the experience, and an ordinary one
  /// disappears when this market has emptied it — the reference drops a
  /// category with no items rather than drawing an empty heading.
  List<LumeCategory> visibleCategories(LumeUserContext ctx) => categories
      .where(
        (LumeCategory c) =>
            (!c.faith || ctx.islamic) &&
            features.any(
              (LumeFeature f) => f.category == c.id && isVisible(f, ctx),
            ),
      )
      .toList();

  /// Look a feature up by id, or `null`.
  LumeFeature? byId(String id) {
    for (final LumeFeature f in features) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// A feature by id, but only when this user may see it.
  ///
  /// This is the one a deep link, a notification and a recents entry go
  /// through: `byId` answers "does this exist", and this answers "may they
  /// have it", and confusing the two is exactly how a hidden feature leaks
  /// back in (§64).
  LumeFeature? visibleById(String id, LumeUserContext ctx) {
    final LumeFeature? f = byId(id);
    if (f == null) return null;
    return isVisible(f, ctx) ? f : null;
  }

  /// The recents list, filtered on the way out.
  ///
  /// *"A hidden feature must not resurface through history, so the list is
  /// filtered on the way out as well as on the way in."*
  List<LumeFeature> recentFeatures(LumeUserContext ctx) => <LumeFeature>[
    for (final String id in ctx.recents)
      if (visibleById(id, ctx) case final LumeFeature f) f,
  ];

  /// The markets that have any localised feature of their own.
  ///
  /// Computed from the catalogue rather than listed, so adding a
  /// country-specific feature is all it takes for that country to count.
  Set<String> get localisedCountries => <String>{
    for (final LumeFeature f in features) ...?f.countries,
  };
}

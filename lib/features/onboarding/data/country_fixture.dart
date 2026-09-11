/// The 194 countries, and the adapter that turns them into a view model.
///
/// `assets/data/countries.json` is generated from the reference's own table by
/// `docs/conversion_archive/tool/gen_countries.mjs`: the same 194 rows, the
/// same twenty popular codes, and each name read from the same ICU data the
/// prototype renders through `Intl.DisplayNames('region')`. So a Flutter list
/// in Urdu holds the strings an Urdu browser would have shown.
///
/// This is a **fixture adapter**, not a repository: it loads a bundled asset
/// and answers synchronously once warmed. The interface it presents —
/// "give me the countries" — is what a Dayroz provider will implement later,
/// which is why the screen depends on the model and not on this.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../domain/country_picker_model.dart';

/// Loads and caches the bundled country table.
class LumeCountryFixture {
  LumeCountryFixture._(this._byLanguage, this.popularOrder, this._order);

  final Map<String, List<LumeCountry>> _byLanguage;

  /// `GEO.POPULAR`, in its declared order — which is the order the Popular
  /// section renders in, so it is carried rather than re-sorted.
  final List<String> popularOrder;

  /// The "All countries" order per language.
  ///
  /// `renderCountry` sorts with `localeCompare(a, b, L.lang())` — ICU
  /// collation. Dart has no collator and `String.compareTo` is code-unit
  /// order, which gets Urdu and Arabic subtly wrong. So the order is computed
  /// once by the generator with the same ICU the prototype used and carried
  /// here as a list of codes.
  final Map<String, List<String>> _order;

  static const String assetPath = 'assets/data/countries.json';

  /// The languages the generated table carries names for.
  static const List<String> languages = <String>['en', 'ur', 'ar'];

  static LumeCountryFixture? _cache;

  /// The table, loaded once per process.
  static Future<LumeCountryFixture> load() async {
    final LumeCountryFixture? cached = _cache;
    if (cached != null) return cached;

    final String raw = await rootBundle.loadString(assetPath);
    final LumeCountryFixture parsed = parse(raw);
    _cache = parsed;
    return parsed;
  }

  /// Exposed so a test can build one from a string without the asset bundle.
  @visibleForTesting
  static LumeCountryFixture parse(String raw) {
    final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;

    final List<String> popular = (json['popular'] as List<dynamic>)
        .cast<String>();

    final Map<String, List<String>> order = <String, List<String>>{
      for (final MapEntry<String, dynamic> e
          in (json['order'] as Map<String, dynamic>).entries)
        e.key: (e.value as List<dynamic>).cast<String>(),
    };

    final Map<String, List<LumeCountry>> byLanguage =
        <String, List<LumeCountry>>{};
    for (final String lang in languages) {
      byLanguage[lang] = <LumeCountry>[
        for (final dynamic entry in json['countries'] as List<dynamic>)
          _country(entry as Map<String, dynamic>, lang),
      ];
    }
    return LumeCountryFixture._(byLanguage, popular, order);
  }

  static LumeCountry _country(Map<String, dynamic> e, String lang) {
    final Map<String, dynamic> names = e['names'] as Map<String, dynamic>;
    return LumeCountry(
      code: e['code'] as String,
      // English is the fallback the generator already applied for a code ICU
      // could not name; this second one only fires for a language the table
      // was not generated for.
      name: (names[lang] ?? names['en']) as String,
      currency: e['currency'] as String,
      popular: e['popular'] as bool,
    );
  }

  /// Every country, with names in [languageCode].
  List<LumeCountry> forLanguage(String languageCode) =>
      _byLanguage[languageCode] ?? _byLanguage['en']!;

  /// The codes of the "All countries" section, in the order [languageCode]
  /// renders them.
  List<String> orderFor(String languageCode) =>
      _order[languageCode] ?? _order['en']!;

  int get count => _byLanguage['en']!.length;

  /// Clears the process cache. Tests that parse their own table use this so
  /// one test's fixture cannot leak into the next.
  @visibleForTesting
  static void reset() => _cache = null;
}

/// Where the fixture's opening state comes from.
///
/// The prototype's onboarding draft starts at Pakistan with an empty recent
/// list, because `app-store.js` defaults `country` to `PK` and a first run has
/// no history. Modelling a returning user is what [recent] is for.
abstract final class LumeCountryFixtureState {
  /// `onbDraft = { country: 'PK', … }`.
  static const String defaultCountry = 'PK';

  /// A first run has none. The reference reads `profile.recentCountries`,
  /// which is empty until a country has been chosen at least once.
  static const List<String> noRecent = <String>[];

  /// A returning user, for the state the screen must also render.
  static const List<String> someRecent = <String>['GB', 'AE', 'US'];
}

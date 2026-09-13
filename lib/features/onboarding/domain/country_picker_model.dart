/// What the country step shows, as data rather than as widgets.
///
/// The screen takes one of these and renders it. It does not sort, filter,
/// search or know where the list came from — which is what makes the same
/// widget usable against a Dayroz provider later without being rewritten. The
/// fixture adapter in `data/` produces one today; a repository produces one
/// tomorrow; neither is visible from the presentation layer.
///
/// The rules are `makeLocationPicker`'s, unchanged:
///
/// * with no query — **Recent** (at most four, only those that resolve),
///   **Popular** (the twenty in `GEO.POPULAR`, in their declared order), then
///   **All countries** sorted by localised name in the reading language;
/// * with a query — one flat list, at most sixty, matching a name that
///   *contains* the query, or a country code that *equals* it, or a currency
///   code that *equals* it;
/// * no matches — the "nothing matches" state, not an empty list;
/// * a section with nothing in it is not rendered at all, which is why Recent
///   disappears rather than showing a heading over nothing.
library;

import 'package:flutter/foundation.dart';

/// One country, already localised.
@immutable
class LumeCountry {
  const LumeCountry({
    required this.code,
    required this.name,
    required this.currency,
    this.timeZone = 'UTC',
    this.popular = false,
  });

  /// ISO 3166-1 alpha-2. Shown in the row's leading column.
  final String code;

  /// The name in the reading language — `Intl.DisplayNames('region')` in the
  /// prototype, and the same ICU strings bundled for Flutter.
  final String name;

  /// ISO 4217. Shown as the row's trailing meta.
  final String currency;

  /// The IANA zone the country implies — `geo.js`'s own `tz` column.
  ///
  /// It is a *default*, not a fact about the reader: a country can span
  /// several zones, and the Time route lets them say which. Carried here
  /// because the table is already loaded and a second source would disagree
  /// with it.
  final String timeZone;

  final bool popular;

  @override
  bool operator ==(Object other) =>
      other is LumeCountry &&
      other.code == code &&
      other.name == name &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(code, name, currency);

  @override
  String toString() => 'LumeCountry($code, $name, $currency)';
}

/// A titled run of rows. `.locgroup` + `.loclist`.
@immutable
class LumeCountrySection {
  const LumeCountrySection({required this.title, required this.countries});

  /// `null` for the flat search result, which has no heading in the reference.
  final String? title;

  final List<LumeCountry> countries;

  bool get isEmpty => countries.isEmpty;
}

/// Everything the country step renders.
@immutable
class LumeCountryPickerModel {
  const LumeCountryPickerModel({
    required this.sections,
    required this.query,
    required this.selected,
    required this.canContinue,
  });

  /// Empty when a search matched nothing — the screen shows the no-results
  /// state, which is a different thing from a list with no rows in it.
  final List<LumeCountrySection> sections;

  final String query;

  /// The country code the draft currently holds. Never null: the reference
  /// opens on `PK` and the step cannot be completed without one.
  final String selected;

  /// The reference's Continue is always enabled here, because a country is
  /// always selected. Kept as a field so the screen never re-derives it.
  final bool canContinue;

  bool get isSearching => query.trim().isNotEmpty;
  bool get hasResults => sections.any((LumeCountrySection s) => !s.isEmpty);
}

/// Turns a country list plus a query into a [LumeCountryPickerModel].
///
/// A pure function of its inputs, so the whole composition — which sections
/// appear, in what order, with what in them — is testable without a widget.
abstract final class LumeCountryPicker {
  /// `.slice(0, 4)` on the recent list.
  static const int recentLimit = 4;

  /// `.slice(0, 60)` on a search.
  static const int searchLimit = 60;

  static LumeCountryPickerModel build({
    required List<LumeCountry> all,
    required List<String> popularOrder,
    required String selected,
    required String query,
    required String recentTitle,
    required String popularTitle,
    required String allTitle,
    List<String> recent = const <String>[],
    List<String>? allOrder,
  }) {
    final Map<String, LumeCountry> byCode = <String, LumeCountry>{
      for (final LumeCountry c in all) c.code: c,
    };

    final String q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      final List<LumeCountry> hits = all
          .where(
            (LumeCountry c) =>
                c.name.toLowerCase().contains(q) ||
                c.code.toLowerCase() == q ||
                c.currency.toLowerCase() == q,
          )
          .take(searchLimit)
          .toList();
      return LumeCountryPickerModel(
        sections: hits.isEmpty
            ? const <LumeCountrySection>[]
            : <LumeCountrySection>[
                LumeCountrySection(title: null, countries: hits),
              ],
        query: query,
        selected: selected,
        canContinue: true,
      );
    }

    // A recent code that no longer resolves is dropped rather than rendered as
    // a blank row — `.filter(function (c) { return GEO.get(c); })`.
    final List<LumeCountry> recentRows = recent
        .map((String code) => byCode[code])
        .whereType<LumeCountry>()
        .take(recentLimit)
        .toList();

    final List<LumeCountry> popularRows = popularOrder
        .map((String code) => byCode[code])
        .whereType<LumeCountry>()
        .toList();

    // The reference sorts by localised name with ICU collation. That order is
    // precomputed per language and passed in; without one, fall back to the
    // list's own order rather than to a comparator that would be wrong for
    // Urdu and Arabic.
    final List<LumeCountry> allRows = allOrder == null
        ? List<LumeCountry>.of(all)
        : <LumeCountry>[
            for (final String code in allOrder)
              if (byCode[code] != null) byCode[code]!,
          ];

    return LumeCountryPickerModel(
      sections: <LumeCountrySection>[
        if (recentRows.isNotEmpty)
          LumeCountrySection(title: recentTitle, countries: recentRows),
        if (popularRows.isNotEmpty)
          LumeCountrySection(title: popularTitle, countries: popularRows),
        if (allRows.isNotEmpty)
          LumeCountrySection(title: allTitle, countries: allRows),
      ],
      query: query,
      selected: selected,
      canContinue: true,
    );
  }
}

/// The step's mutable state: what is typed, and what is chosen.
///
/// A [ChangeNotifier] rather than a provider so the screen can be driven from
/// a test, a fixture or a Dayroz notifier without any of them knowing about
/// the others.
class LumeCountryPickerController extends ChangeNotifier {
  LumeCountryPickerController({required String selected, String query = ''})
    : _selected = selected,
      _query = query;

  String _selected;
  String get selected => _selected;
  set selected(String code) {
    if (_selected == code) return;
    _selected = code;
    notifyListeners();
  }

  String _query;
  String get query => _query;
  set query(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void clearQuery() => query = '';
}

/// What the city step shows.
///
/// `renderCity` in `ui/pickers.js`, unchanged:
///
/// * a country with regions and **no query** renders one section per region,
///   each holding that region's cities, in the table's own order;
/// * otherwise — a country without regions, or any query — one flat list of
///   every city, each carrying the region it belongs to as trailing meta;
/// * no match is the "nothing found" state, not an empty list;
/// * a "use my current location" action sits above the list, always.
///
/// Choosing a country elsewhere resets the city to that country's first and
/// the region to the one it sits in, which is [LumeCityPicker.defaultCityFor].
library;

import 'package:flutter/foundation.dart';

/// One city, and the region it belongs to.
@immutable
class LumeCity {
  const LumeCity({required this.name, this.region});

  final String name;

  /// `null` for a country with no region layer — which is most of them.
  final String? region;

  @override
  bool operator ==(Object other) =>
      other is LumeCity && other.name == name && other.region == region;

  @override
  int get hashCode => Object.hash(name, region);

  @override
  String toString() => 'LumeCity($name${region == null ? '' : ', $region'})';
}

/// A titled run of cities. `.locgroup` + `.loclist`.
@immutable
class LumeCitySection {
  const LumeCitySection({required this.title, required this.cities});

  /// The region's name, or `null` for the flat list.
  final String? title;

  final List<LumeCity> cities;

  bool get isEmpty => cities.isEmpty;
}

/// Everything the city step renders.
@immutable
class LumeCityPickerModel {
  const LumeCityPickerModel({
    required this.sections,
    required this.query,
    required this.selected,
    required this.countryName,
  });

  final List<LumeCitySection> sections;
  final String query;

  /// The city the draft holds.
  final String selected;

  /// The kicker: the country's localised name, which is what the step uses
  /// instead of a fixed one.
  final String countryName;

  bool get isSearching => query.trim().isNotEmpty;
  bool get hasResults => sections.any((LumeCitySection s) => !s.isEmpty);
}

/// Turns a country's cities plus a query into a [LumeCityPickerModel].
abstract final class LumeCityPicker {
  static LumeCityPickerModel build({
    required Map<String, List<String>>? regions,
    required List<String> cities,
    required String selected,
    required String query,
    required String countryName,
  }) {
    final String q = query.trim().toLowerCase();

    // Regions, but only while nothing is typed: a search flattens, because a
    // hit in one region and a hit in another read better together than as two
    // one-row sections.
    if (regions != null && regions.isNotEmpty && q.isEmpty) {
      return LumeCityPickerModel(
        sections: <LumeCitySection>[
          for (final MapEntry<String, List<String>> e in regions.entries)
            LumeCitySection(
              title: e.key,
              cities: <LumeCity>[
                for (final String c in e.value)
                  LumeCity(name: c, region: e.key),
              ],
            ),
        ],
        query: query,
        selected: selected,
        countryName: countryName,
      );
    }

    final List<LumeCity> all = <LumeCity>[
      for (final String c in cities)
        LumeCity(name: c, region: regionOf(regions, c)),
    ];
    final List<LumeCity> hits = q.isEmpty
        ? all
        : all.where((LumeCity c) => c.name.toLowerCase().contains(q)).toList();

    return LumeCityPickerModel(
      sections: hits.isEmpty
          ? const <LumeCitySection>[]
          : <LumeCitySection>[LumeCitySection(title: null, cities: hits)],
      query: query,
      selected: selected,
      countryName: countryName,
    );
  }

  /// Which region a city sits in, or `null`.
  static String? regionOf(Map<String, List<String>>? regions, String city) {
    if (regions == null) return null;
    for (final MapEntry<String, List<String>> e in regions.entries) {
      if (e.value.contains(city)) return e.key;
    }
    return null;
  }

  /// The city a country opens on when it is chosen: its first.
  ///
  /// `d.city = cities[0] || ''` — and the region follows from it, so a country
  /// change never leaves a city from the previous country standing.
  static ({String city, String? region}) defaultCityFor({
    required Map<String, List<String>>? regions,
    required List<String> cities,
  }) {
    final String city = cities.isEmpty ? '' : cities.first;
    return (city: city, region: regionOf(regions, city));
  }
}

/// The step's mutable state.
class LumeCityPickerController extends ChangeNotifier {
  LumeCityPickerController({
    required String selected,
    String? region,
    String query = '',
  }) : _selected = selected,
       _region = region,
       _query = query;

  String _selected;
  String get selected => _selected;

  String? _region;

  /// The region the chosen city sits in, carried so the profile can record
  /// country → region → city rather than country → city.
  String? get region => _region;

  void choose(String city, String? region) {
    if (_selected == city && _region == region) return;
    _selected = city;
    _region = region;
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

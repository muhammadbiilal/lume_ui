/// Where "Nearby Mosques" actually gets its "nearby" from.
///
/// `tools/islamic/mosques.tool.js`'s own `nearbyMosques()` (`context.js`) does
/// not read a real directory at all: it takes the reader's city and writes
/// four rows from a fixed name list ('Central Mosque', 'Jamia Mosque', 'Masjid
/// A', 'Masjid B'), each suffixed with the city's own name, a distance that is
/// `0.4 + i * 0.7` km for row `i`, a walking time derived from that same
/// number, canned reciter names ('Qari Ahmed', 'Hafiz Bilal', ...) and map
/// pin coordinates picked from `i` alone. None of it is a real mosque — it is
/// a per-city template with the reader's own city name spliced in, which
/// would read as real names, real distances and a real nearby search if
/// ported as data. §"no fabricated data" is explicit that where the
/// reference fabricates something, the honest port drops it rather than
/// reproducing it as though it were real, so nothing here is a fixture of
/// invented mosques.
///
/// What replaces it: a live text search, handed to the reader's own maps
/// app, for real mosques the reader's own map data actually knows about
/// near their place — the same shape as [LumeLinkOpener] already gives
/// Documents' and News' outbound links, and the same "hand off to a real
/// service rather than invent one" choice Qibla makes when it computes a
/// real bearing instead of faking a live compass.
///
/// **Dayroz obligation:** a first-class "nearby mosques" screen — one with
/// its own list, distances and facilities Lume can stand behind — needs a
/// licensed places source (Google Places, OpenStreetMap Overpass, or an
/// owned directory) and the reader's coordinates, neither of which exists in
/// this build.
library;

/// Builds the one real, checkable address this tool ever opens.
abstract final class LumeMosquesSearch {
  /// A Google Maps text search for mosques near [place] ("Islamabad,
  /// Pakistan") — `https`, so it passes [LumeLinkOpener.allows] like any other
  /// outbound link, and it is a genuine live search rather than anything
  /// worked out here.
  static Uri mapsUri(String place) => Uri.https(
    'www.google.com',
    '/maps/search/',
    <String, String>{'api': '1', 'query': 'mosques near $place'},
  );
}

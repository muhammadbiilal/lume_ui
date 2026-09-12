/// Where Home's values come from.
///
/// One contract, because Home quotes eleven different things and a screen that
/// reached for eleven repositories would have eleven places to get a gate
/// wrong. What it returns is [LumeHomeContent] — numbers, dates and keys — plus
/// a per-source state, which is what makes *partial* a state the screen can
/// draw rather than a state it has to collapse.
///
/// **No backend.** The implementation in `data/` is a deterministic fixture
/// carrying the prototype's own figures. At Dayroz integration each tool's real
/// repository takes its field over; the identifiers are preserved so that is a
/// substitution rather than a rewrite.
library;

import 'package:flutter/foundation.dart';

import '../../catalogue/domain/eligibility.dart';
import 'home_content.dart';

/// Which of Home's three fetched regions a source belongs to.
///
/// Not one state for the page: a market card beside a failed weather card is a
/// partial Home, and the two sections say different things about themselves.
enum LumeHomeSection {
  /// The strip under the header.
  context,

  /// "Right now".
  live,

  /// "Coming up".
  upcoming,
}

/// How a section's data arrived.
enum LumeSourceState {
  /// Fetched now.
  live,

  /// Real, but older than it should be.
  stale,

  /// From the cache, with no connection behind it.
  offline,

  /// Could not be fetched at all.
  failed,
}

/// One load.
@immutable
class LumeHomeSnapshot {
  const LumeHomeSnapshot({
    required this.content,
    this.sources = const <LumeHomeSection, LumeSourceState>{},
    this.fetchedAt,
  });

  final LumeHomeContent content;

  /// Anything absent is [LumeSourceState.live].
  final Map<LumeHomeSection, LumeSourceState> sources;

  /// When this was true. Shown by anything that says how old it is.
  final DateTime? fetchedAt;

  LumeSourceState stateOf(LumeHomeSection section) =>
      sources[section] ?? LumeSourceState.live;
}

/// A status line the device can answer without opening the tool.
///
/// `syncFeatureMeta` in the reference refreshes four of the catalogue's static
/// lines at runtime — the weather, the next prayer, and two money figures that
/// follow the market's budget — so the tile does not still claim 34° in New
/// York. Both Home and the Tools hub read this, so the two screens cannot
/// disagree about the same tool.
///
/// It is **synchronous** on purpose: the hub has nothing to load, and giving it
/// a future so one line could be live would have put a spinner on a catalogue.
@immutable
class LumeToolStatuses {
  const LumeToolStatuses({this.prayer, this.weather});

  /// The next prayer, when the Islamic experience is on.
  final LumePrayerTime? prayer;

  /// The weather where the user is.
  final LumeWeatherNow? weather;

  static const LumeToolStatuses none = LumeToolStatuses();
}

/// The contract.
abstract interface class LumeHomeRepository {
  /// Everything Home quotes, for this user, at this moment.
  ///
  /// [now] is passed rather than read, because a repository that calls
  /// `DateTime.now()` is a repository no test can put at a boundary.
  Future<LumeHomeSnapshot> load(LumeUserContext user, {required DateTime now});

  /// The handful of tile status lines that would otherwise go stale.
  LumeToolStatuses statusesFor(LumeUserContext user, {required DateTime now});
}

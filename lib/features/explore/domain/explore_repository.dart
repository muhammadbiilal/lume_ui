/// Where Explore's context comes from.
///
/// Explore reads five genuinely different kinds of source, and separating them
/// is the point of this contract: a weather outage must not empty the news,
/// and a country with no local services must not look like a failure.
///
/// | Explore shows | Dayroz source |
/// |---|---|
/// | weather | the weather provider, through its cache, with a real fetch time |
/// | sunset | the same solar calculation the prayer schedule uses |
/// | Around you | the feature catalogue, each row asking its own tool for a current value |
/// | cricket | the sports provider, gated by the reader's interests |
/// | Today's reads | the news provider's edition for the reader's country |
/// | Collections | curated content, from the content catalogue |
/// | Nearby | **a real places source keyed to the reader's city** — see below |
///
/// **Two of those do not exist in the reference and must not be faked by
/// Dayroz either.** Nearby is three hard-coded Karachi venues with metre
/// distances, shown in every market (E2); the weather's "updated 4 min ago" is
/// a literal (E1). Both are reproduced here by decision, to keep the reference
/// faithful, and both are recorded as obligations: a real places source and a
/// real fetch timestamp before either ships.
library;

import '../../catalogue/domain/eligibility.dart';
import 'explore_model.dart';

/// The contract. Dayroz implements it; this repository ships only doubles.
abstract interface class LumeExploreRepository {
  /// Everything Explore draws, for this reader, at this instant.
  ///
  /// One call rather than five, because the reference composes the screen
  /// synchronously and a fixture that pretended otherwise would be inventing
  /// states — see [LumeExploreSources] for how a real implementation reports
  /// a partial answer.
  Future<LumeExploreSnapshot> load(
    LumeUserContext user, {
    required DateTime now,
  });
}

/// Which of Explore's sources answered.
///
/// The reference has no failure path at all: every section is static markup or
/// a synchronous read, and nothing can be stale. This exists so a real adapter
/// has somewhere to say "the news is yesterday's" without the screen having to
/// invent a vocabulary for it — and so the fixture can say, truthfully, that
/// nothing here was fetched.
enum LumeExploreSource { weather, around, score, news, collections, nearby }

/// What a source had to say for itself.
enum LumeSourceFreshness {
  /// Fetched now.
  live,

  /// Served from a cache, and the reader is told.
  cached,

  /// The source did not answer; the section says so rather than disappearing.
  unavailable,

  /// A deterministic fixture. Never labelled live.
  fixture,
}

/// The snapshot, with each source's own account of itself.
class LumeExploreSnapshot {
  const LumeExploreSnapshot({
    required this.data,
    required this.freshness,
    required this.fetchedAt,
  });

  final LumeExploreData data;

  /// Per source, so one stale provider cannot make the whole screen look old.
  final Map<LumeExploreSource, LumeSourceFreshness> freshness;

  final DateTime fetchedAt;

  LumeSourceFreshness of(LumeExploreSource source) =>
      freshness[source] ?? LumeSourceFreshness.fixture;
}

/// What Trains reads, and what keeps a journey.
///
/// **Two contracts, not one.** Running status and the departure roster come
/// from an operator's feed and are nobody's private data; a saved journey is
/// the reader's own and belongs wherever their other lists do. Merging them
/// would make every caller depend on both, and would put a personal list
/// behind a network that is allowed to fail.
///
/// Neither reads a clock: the moment arrives as an argument, so a fixture, a
/// test and a real feed all answer the same question.
library;

import 'package:flutter/foundation.dart';

import '../../catalogue/domain/eligibility.dart';
import 'trains_model.dart';

/// The parts of the screen that can fail independently.
///
/// The reference has no such notion — its roster is rendered synchronously
/// from a constant — but a real feed has three separate answers and one
/// loading state cannot carry them.
enum LumeTrainsSource {
  /// The tracked service's position.
  tracked,

  /// Today's departures from the origin.
  departures,

  /// The editorial route cards.
  routes,
}

/// What a source had to say for itself.
enum LumeTrainsFreshness {
  /// Read now, from the operator.
  live,

  /// Served from a cache, and the reader is told how old it is.
  cached,

  /// The source did not answer; the section says so rather than disappearing.
  unavailable,

  /// A deterministic fixture. Never labelled live.
  fixture,
}

/// A reading, with each source's own account of itself.
@immutable
class LumeTrainsSnapshot {
  const LumeTrainsSnapshot({
    required this.data,
    required this.freshness,
    required this.fetchedAt,
  });

  final LumeTrainsData data;

  final Map<LumeTrainsSource, LumeTrainsFreshness> freshness;

  final DateTime fetchedAt;

  LumeTrainsFreshness of(LumeTrainsSource source) =>
      freshness[source] ?? LumeTrainsFreshness.fixture;
}

/// Why a read failed, in terms the screen can draw.
///
/// A repository never hands a widget an exception, a status code or a driver
/// message: it hands it one of these, and the screen decides what to say.
enum LumeTrainsFailure {
  /// The operator's feed did not answer at all.
  unreachable,

  /// This market has no rail service in the product.
  unsupported,
}

/// Thrown by a repository, caught by a host, never seen by a widget.
class LumeTrainsException implements Exception {
  const LumeTrainsException(this.failure);

  final LumeTrainsFailure failure;

  @override
  String toString() => 'LumeTrainsException(${failure.name})';
}

/// Running status and the roster.
abstract interface class LumeTrainsRepository {
  /// The whole destination, for a reader at a moment.
  ///
  /// Throws [LumeTrainsException] when nothing could be read. A source that
  /// failed on its own reports `unavailable` in the snapshot instead.
  Future<LumeTrainsSnapshot> load(
    LumeUserContext user, {
    required DateTime now,
  });

  /// Run the search the route card is asking.
  ///
  /// Returns a fresh snapshot rather than mutating one, so the screen is a
  /// function of what came back.
  Future<LumeTrainsSnapshot> search(
    LumeUserContext user, {
    required DateTime now,
    required LumeJourneyQuery query,
  });
}

/// The reader's own journeys.
///
/// Separate from [LumeTrainsRepository] on purpose: this is personal data with
/// no network behind it, and it must keep working when the operator's feed
/// does not.
abstract interface class LumeJourneyStore {
  /// Newest first.
  Future<List<LumeSavedJourney>> saved();

  /// Keeps [query]. Returns the whole list, so the caller never has to guess
  /// where the new one went.
  Future<List<LumeSavedJourney>> save(
    LumeJourneyQuery query, {
    required DateTime now,
  });

  Future<List<LumeSavedJourney>> remove(String id);

  /// Whether a write survives the process.
  ///
  /// `false` for every fixture in this build. Reported rather than assumed, so
  /// nothing upstream can mistake a fixture for storage.
  bool get isDurable;
}

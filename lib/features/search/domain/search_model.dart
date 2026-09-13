/// Global search: what a hit is, and what a search can answer.
///
/// The index is **one index over everything the reader can actually reach**,
/// and it is built from the same eligibility selector Home, the hub and the
/// notification engine ask. A feature hidden by faith or by country cannot be
/// found by typing its name — which is the entry point people most often
/// forget to gate (§64).
///
/// The repository is asynchronous and may fail even though this build's
/// fixture does neither. That is deliberate: Dayroz will answer from a real
/// index across a network, and a synchronous contract would have to be
/// rewritten rather than implemented. What the *screen* draws is only what
/// the reference draws — idle, results, nothing found — because a state the
/// reference has no design for is a state this conversion must not invent.
library;

import 'package:flutter/foundation.dart';

/// What a hit does when it is chosen.
///
/// The reference spells these as an `act` string — `tool:calculator`,
/// `sheet:personalise`, `theme`, `toast:…` — and runs them through one action
/// vocabulary. They are an enum here so an unknown verb cannot reach the
/// widget layer as a string nobody handles.
enum LumeSearchAction {
  /// Open a tool on the branch search was opened from.
  tool,

  /// Open a destination tab.
  destination,

  /// Raise another sheet — Personalisation.
  sheet,

  /// Flip the appearance mode.
  theme,

  /// Say something and stay. The reference uses it for a placeholder result
  /// that has nowhere to go yet.
  say,
}

/// One row in the result list, or in the "jump back in" list.
@immutable
class LumeSearchHit {
  const LumeSearchHit({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.action,
    this.target = '',
    this.featureId,
  });

  /// What the row reads. Already localised.
  final String title;

  /// The line under it — a category name, a description, a place.
  final String subtitle;

  /// A [LumeIcons] name.
  final String icon;

  final LumeSearchAction action;

  /// The action's argument: a tool id, a destination name, a sheet name, or
  /// the sentence to say.
  final String target;

  /// Set when the hit is a catalogue feature, so opening it can be noted in
  /// recents the way opening it anywhere else is.
  final String? featureId;

  @override
  bool operator ==(Object other) =>
      other is LumeSearchHit &&
      other.title == title &&
      other.subtitle == subtitle &&
      other.icon == icon &&
      other.action == action &&
      other.target == target &&
      other.featureId == featureId;

  @override
  int get hashCode =>
      Object.hash(title, subtitle, icon, action, target, featureId);

  @override
  String toString() => 'LumeSearchHit($title · $subtitle)';
}

/// What the idle sheet offers before anything is typed.
@immutable
class LumeSearchIdle {
  const LumeSearchIdle({required this.suggestions, required this.recent});

  /// The chips. Words, not ids: the reference puts them straight into the
  /// field, so they are searched exactly as a reader would have typed them.
  final List<String> suggestions;

  /// Tools the reader opened lately, filtered on the way out (§64).
  final List<LumeSearchHit> recent;
}

/// The answer to one query.
@immutable
class LumeSearchResults {
  const LumeSearchResults({required this.query, required this.hits});

  final String query;
  final List<LumeSearchHit> hits;

  bool get isEmpty => hits.isEmpty;
}

/// Why a search could not be answered.
///
/// **Unreachable in this build.** The fixture indexes the catalogue in
/// process and cannot fail, so no screen draws any of these. They exist
/// because a remote index can fail and the contract has to be able to say
/// so before one is wired up.
enum LumeSearchFailure {
  /// The index could not be reached.
  unreachable,

  /// It answered, badly.
  unusable,
}

/// Thrown by a repository that cannot answer. See [LumeSearchFailure].
class LumeSearchException implements Exception {
  const LumeSearchException(this.failure);

  final LumeSearchFailure failure;

  @override
  String toString() => 'LumeSearchException(${failure.name})';
}

/// What global search asks of whatever is behind it.
///
/// One index, built from the catalogue, the reader's own profile and the
/// eligibility selector. Implementations must not widen what a reader can
/// find beyond what they can reach.
abstract interface class LumeSearchRepository {
  /// The chips and the recents, for an empty field.
  Future<LumeSearchIdle> idle();

  /// Hits for [query], ranked. An empty or blank query returns no hits —
  /// the caller shows [idle] instead.
  Future<LumeSearchResults> search(String query);
}

/// Whether what is behind the repository survives a restart.
///
/// `false` for every fixture in this conversion, and the surfaces say so
/// rather than implying a live index.
abstract interface class LumeSearchDurability {
  bool get isDurable;
}

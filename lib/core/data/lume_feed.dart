/// What a screen knows about one piece of data, including how sure it is.
///
/// §108 of the specification says quality is never implied: a cached figure and
/// a live one must not look the same. A nullable value cannot carry that, and
/// an `AsyncValue` carries only three of the seven states a destination has to
/// draw — loading, success, empty, partial, stale, offline and failed.
///
/// So a section holds a [LumeFeed]. Each section holds its own, which is what
/// makes *partial* expressible at all: Home with a market card and a failed
/// weather card is not a failed Home, and a screen that models one state for
/// the whole page has no way to say so.
library;

import 'package:flutter/foundation.dart';

/// How current a ready value is.
enum LumeFeedFreshness {
  /// Fetched now.
  live,

  /// Older than it should be, and the screen says so.
  stale,

  /// From the cache, with no connection to refresh it.
  offline,
}

/// One section's data.
@immutable
sealed class LumeFeed<T> {
  const LumeFeed();

  /// Nothing yet. The screen draws its skeleton.
  const factory LumeFeed.loading() = LumeFeedLoading<T>;

  /// A value, with how current it is.
  const factory LumeFeed.ready(
    T value, {
    LumeFeedFreshness freshness,
    DateTime? asOf,
  }) = LumeFeedReady<T>;

  /// It could not be fetched. [fallback] is the last thing known, when there
  /// is one — an error state that still shows yesterday's figure is kinder
  /// than one that shows nothing, as long as it says which it is.
  const factory LumeFeed.failed({T? fallback}) = LumeFeedFailed<T>;

  /// The value, or `null` while loading or failed without a fallback.
  T? get valueOrNull => switch (this) {
    LumeFeedReady<T>(:final T value) => value,
    LumeFeedFailed<T>(:final T? fallback) => fallback,
    LumeFeedLoading<T>() => null,
  };

  bool get isLoading => this is LumeFeedLoading<T>;
  bool get hasFailed => this is LumeFeedFailed<T>;

  /// True when the value is real but not current.
  bool get isStale => switch (this) {
    LumeFeedReady<T>(:final LumeFeedFreshness freshness) =>
      freshness != LumeFeedFreshness.live,
    _ => false,
  };

  bool get isOffline => switch (this) {
    LumeFeedReady<T>(:final LumeFeedFreshness freshness) =>
      freshness == LumeFeedFreshness.offline,
    _ => false,
  };
}

final class LumeFeedLoading<T> extends LumeFeed<T> {
  const LumeFeedLoading();

  @override
  bool operator ==(Object other) => other is LumeFeedLoading<T>;

  @override
  int get hashCode => (LumeFeedLoading<T>).hashCode;
}

final class LumeFeedReady<T> extends LumeFeed<T> {
  const LumeFeedReady(
    this.value, {
    this.freshness = LumeFeedFreshness.live,
    this.asOf,
  });

  final T value;
  final LumeFeedFreshness freshness;

  /// When the value was true. Shown by anything that says "updated 4 min ago".
  final DateTime? asOf;

  @override
  bool operator ==(Object other) =>
      other is LumeFeedReady<T> &&
      other.value == value &&
      other.freshness == freshness &&
      other.asOf == asOf;

  @override
  int get hashCode => Object.hash(value, freshness, asOf);
}

final class LumeFeedFailed<T> extends LumeFeed<T> {
  const LumeFeedFailed({this.fallback});

  /// The last thing known, when there is one. Never a message: what a failed
  /// section *says* is the screen's business and comes from the ARBs, because
  /// a screen that renders whatever the transport said is a screen that leaks
  /// the transport.
  final T? fallback;

  @override
  bool operator ==(Object other) =>
      other is LumeFeedFailed<T> && other.fallback == fallback;

  @override
  int get hashCode => fallback.hashCode;
}

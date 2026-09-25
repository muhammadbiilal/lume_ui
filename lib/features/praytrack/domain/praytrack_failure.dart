/// Why a Prayer Tracker write did not happen — typed, never a message
/// string.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';

enum PrayTrackFailureKind {
  /// Another write got there first.
  conflict,

  /// A record named is not there.
  notFound,

  /// The records are not loaded, or the store refused.
  storage,
}

@immutable
class PrayTrackFailure implements Exception {
  const PrayTrackFailure(
    this.kind, {
    this.ids = const <LumeRecordId>[],
    this.cause,
  });

  final PrayTrackFailureKind kind;
  final List<LumeRecordId> ids;
  final Object? cause;

  @override
  String toString() =>
      'PrayTrackFailure(${kind.name}${ids.isEmpty ? '' : ', $ids'})';
}

/// A Prayer Tracker operation's outcome.
@immutable
class PrayTrackResult<T> {
  const PrayTrackResult.ok(T this.value) : failure = null;
  const PrayTrackResult.failed(PrayTrackFailure this.failure) : value = null;

  final T? value;
  final PrayTrackFailure? failure;

  bool get ok => failure == null;
}

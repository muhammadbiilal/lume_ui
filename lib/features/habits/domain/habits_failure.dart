/// Why a Habits write did not happen — typed, never a message string.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';

enum HabitsFailureKind {
  /// A field the reader typed is not acceptable ([HabitsFailure.field],
  /// [HabitsFailure.reason]).
  validation,

  /// Another write got there first.
  conflict,

  /// A record named is not there.
  notFound,

  /// The records are not loaded, or the store refused.
  storage,

  /// The records on file break Habits' rules; nothing is written over them.
  damaged,
}

@immutable
class HabitsFailure implements Exception {
  const HabitsFailure(
    this.kind, {
    this.field,
    this.reason,
    this.ids = const <LumeRecordId>[],
    this.cause,
  });

  const HabitsFailure.validation(String this.field, String this.reason)
    : kind = HabitsFailureKind.validation,
      ids = const <LumeRecordId>[],
      cause = null;

  final HabitsFailureKind kind;
  final String? field;
  final String? reason;
  final List<LumeRecordId> ids;

  /// Diagnostic only — never a habit's own name.
  final Object? cause;

  @override
  String toString() =>
      'HabitsFailure(${kind.name}'
      '${field == null ? '' : ', $field'}'
      '${reason == null ? '' : ': $reason'}'
      '${ids.isEmpty ? '' : ', $ids'})';
}

/// A Habits operation's outcome.
@immutable
class HabitsResult<T> {
  const HabitsResult.ok(T this.value) : failure = null;
  const HabitsResult.failed(HabitsFailure this.failure) : value = null;

  final T? value;
  final HabitsFailure? failure;

  bool get ok => failure == null;
}

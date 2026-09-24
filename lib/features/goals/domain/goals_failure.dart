/// Why a Goals write did not happen — typed, never a message string.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';

enum GoalsFailureKind {
  /// A field the reader typed is not acceptable ([GoalsFailure.field],
  /// [GoalsFailure.reason]).
  validation,

  /// Another write got there first.
  conflict,

  /// A record named is not there.
  notFound,

  /// A sum past its bound (10^15 per amount, 2^53 − 1 per sum).
  overflow,

  /// The goal is completed or abandoned; nothing is added to it until it
  /// is reactivated.
  closed,

  /// The records are not loaded, or the store refused.
  storage,

  /// The records on file break Goals' rules; nothing is written over them.
  damaged,
}

@immutable
class GoalsFailure implements Exception {
  const GoalsFailure(
    this.kind, {
    this.field,
    this.reason,
    this.ids = const <LumeRecordId>[],
    this.cause,
  });

  const GoalsFailure.validation(String this.field, String this.reason)
    : kind = GoalsFailureKind.validation,
      ids = const <LumeRecordId>[],
      cause = null;

  final GoalsFailureKind kind;
  final String? field;
  final String? reason;
  final List<LumeRecordId> ids;

  /// Diagnostic only — minor-unit figures and failure kinds, never a
  /// goal's name or note.
  final Object? cause;

  @override
  String toString() =>
      'GoalsFailure(${kind.name}'
      '${field == null ? '' : ', $field'}'
      '${reason == null ? '' : ': $reason'}'
      '${ids.isEmpty ? '' : ', $ids'})';
}

/// A Goals operation's outcome.
@immutable
class GoalsResult<T> {
  const GoalsResult.ok(T this.value) : failure = null;
  const GoalsResult.failed(GoalsFailure this.failure) : value = null;

  final T? value;
  final GoalsFailure? failure;

  bool get ok => failure == null;
}

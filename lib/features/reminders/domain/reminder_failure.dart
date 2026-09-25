/// Why a Reminders write did not happen — typed, never a message string.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';

enum ReminderFailureKind { validation, conflict, notFound, storage, damaged }

@immutable
class ReminderFailure implements Exception {
  const ReminderFailure(
    this.kind, {
    this.field,
    this.reason,
    this.ids = const <LumeRecordId>[],
    this.cause,
  });

  const ReminderFailure.validation(String this.field, String this.reason)
    : kind = ReminderFailureKind.validation,
      ids = const <LumeRecordId>[],
      cause = null;

  final ReminderFailureKind kind;
  final String? field;
  final String? reason;
  final List<LumeRecordId> ids;
  final Object? cause;

  @override
  String toString() =>
      'ReminderFailure(${kind.name}'
      '${field == null ? '' : ', $field'}'
      '${reason == null ? '' : ': $reason'}'
      '${ids.isEmpty ? '' : ', $ids'})';
}

@immutable
class ReminderResult<T> {
  const ReminderResult.ok(T this.value) : failure = null;
  const ReminderResult.failed(ReminderFailure this.failure) : value = null;

  final T? value;
  final ReminderFailure? failure;

  bool get ok => failure == null;
}

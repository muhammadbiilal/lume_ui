/// Why a Fasting Tracker write did not happen — typed, never a message
/// string.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';

enum FastingFailureKind { validation, conflict, notFound, storage }

@immutable
class FastingFailure implements Exception {
  const FastingFailure(
    this.kind, {
    this.field,
    this.reason,
    this.ids = const <LumeRecordId>[],
    this.cause,
  });

  const FastingFailure.validation(String this.field, String this.reason)
    : kind = FastingFailureKind.validation,
      ids = const <LumeRecordId>[],
      cause = null;

  final FastingFailureKind kind;
  final String? field;
  final String? reason;
  final List<LumeRecordId> ids;
  final Object? cause;

  @override
  String toString() =>
      'FastingFailure(${kind.name}'
      '${field == null ? '' : ', $field'}'
      '${reason == null ? '' : ': $reason'}'
      '${ids.isEmpty ? '' : ', $ids'})';
}

@immutable
class FastingResult<T> {
  const FastingResult.ok(T this.value) : failure = null;
  const FastingResult.failed(FastingFailure this.failure) : value = null;

  final T? value;
  final FastingFailure? failure;

  bool get ok => failure == null;
}

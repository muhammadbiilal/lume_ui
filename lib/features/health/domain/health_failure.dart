/// Why a Health Records write did not happen — typed, never a message
/// string.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';

enum HealthFailureKind { validation, conflict, notFound, storage, damaged }

@immutable
class HealthFailure implements Exception {
  const HealthFailure(
    this.kind, {
    this.field,
    this.reason,
    this.ids = const <LumeRecordId>[],
    this.cause,
  });

  const HealthFailure.validation(String this.field, String this.reason)
    : kind = HealthFailureKind.validation,
      ids = const <LumeRecordId>[],
      cause = null;

  final HealthFailureKind kind;
  final String? field;
  final String? reason;
  final List<LumeRecordId> ids;
  final Object? cause;

  @override
  String toString() =>
      'HealthFailure(${kind.name}'
      '${field == null ? '' : ', $field'}'
      '${reason == null ? '' : ': $reason'}'
      '${ids.isEmpty ? '' : ', $ids'})';
}

@immutable
class HealthResult<T> {
  const HealthResult.ok(T this.value) : failure = null;
  const HealthResult.failed(HealthFailure this.failure) : value = null;

  final T? value;
  final HealthFailure? failure;

  bool get ok => failure == null;
}

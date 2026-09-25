/// Why a Cycle Tracker write did not happen — typed, never a message string.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';

enum CycleFailureKind { validation, conflict, notFound, storage, damaged }

@immutable
class CycleFailure implements Exception {
  const CycleFailure(
    this.kind, {
    this.field,
    this.reason,
    this.ids = const <LumeRecordId>[],
    this.cause,
  });

  const CycleFailure.validation(String this.field, String this.reason)
    : kind = CycleFailureKind.validation,
      ids = const <LumeRecordId>[],
      cause = null;

  final CycleFailureKind kind;
  final String? field;
  final String? reason;
  final List<LumeRecordId> ids;
  final Object? cause;

  @override
  String toString() =>
      'CycleFailure(${kind.name}'
      '${field == null ? '' : ', $field'}'
      '${reason == null ? '' : ': $reason'}'
      '${ids.isEmpty ? '' : ', $ids'})';
}

@immutable
class CycleResult<T> {
  const CycleResult.ok(T this.value) : failure = null;
  const CycleResult.failed(CycleFailure this.failure) : value = null;

  final T? value;
  final CycleFailure? failure;

  bool get ok => failure == null;
}

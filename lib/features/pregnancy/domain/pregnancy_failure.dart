/// Why a Pregnancy write did not happen — typed, never a message string.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';

enum PregnancyFailureKind { validation, conflict, notFound, storage }

@immutable
class PregnancyFailure implements Exception {
  const PregnancyFailure(
    this.kind, {
    this.field,
    this.reason,
    this.ids = const <LumeRecordId>[],
    this.cause,
  });

  const PregnancyFailure.validation(String this.field, String this.reason)
    : kind = PregnancyFailureKind.validation,
      ids = const <LumeRecordId>[],
      cause = null;

  final PregnancyFailureKind kind;
  final String? field;
  final String? reason;
  final List<LumeRecordId> ids;
  final Object? cause;

  @override
  String toString() =>
      'PregnancyFailure(${kind.name}'
      '${field == null ? '' : ', $field'}'
      '${reason == null ? '' : ': $reason'}'
      '${ids.isEmpty ? '' : ', $ids'})';
}

@immutable
class PregnancyResult<T> {
  const PregnancyResult.ok(T this.value) : failure = null;
  const PregnancyResult.failed(PregnancyFailure this.failure) : value = null;

  final T? value;
  final PregnancyFailure? failure;

  bool get ok => failure == null;
}

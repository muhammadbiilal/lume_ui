/// Why a Vaccinations write did not happen — typed, never a message string.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';

enum VaccinesFailureKind { validation, conflict, notFound, storage, damaged }

@immutable
class VaccinesFailure implements Exception {
  const VaccinesFailure(
    this.kind, {
    this.field,
    this.reason,
    this.ids = const <LumeRecordId>[],
    this.cause,
  });

  const VaccinesFailure.validation(String this.field, String this.reason)
    : kind = VaccinesFailureKind.validation,
      ids = const <LumeRecordId>[],
      cause = null;

  final VaccinesFailureKind kind;
  final String? field;
  final String? reason;
  final List<LumeRecordId> ids;
  final Object? cause;

  @override
  String toString() =>
      'VaccinesFailure(${kind.name}'
      '${field == null ? '' : ', $field'}'
      '${reason == null ? '' : ': $reason'}'
      '${ids.isEmpty ? '' : ', $ids'})';
}

@immutable
class VaccinesResult<T> {
  const VaccinesResult.ok(T this.value) : failure = null;
  const VaccinesResult.failed(VaccinesFailure this.failure) : value = null;

  final T? value;
  final VaccinesFailure? failure;

  bool get ok => failure == null;
}

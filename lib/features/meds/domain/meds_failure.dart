/// Why a Medication write did not happen — typed, never a message string.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';

enum MedsFailureKind { validation, conflict, notFound, storage, damaged }

@immutable
class MedsFailure implements Exception {
  const MedsFailure(
    this.kind, {
    this.field,
    this.reason,
    this.ids = const <LumeRecordId>[],
    this.cause,
  });

  const MedsFailure.validation(String this.field, String this.reason)
    : kind = MedsFailureKind.validation,
      ids = const <LumeRecordId>[],
      cause = null;

  final MedsFailureKind kind;
  final String? field;
  final String? reason;
  final List<LumeRecordId> ids;
  final Object? cause;

  @override
  String toString() =>
      'MedsFailure(${kind.name}'
      '${field == null ? '' : ', $field'}'
      '${reason == null ? '' : ': $reason'}'
      '${ids.isEmpty ? '' : ', $ids'})';
}

@immutable
class MedsResult<T> {
  const MedsResult.ok(T this.value) : failure = null;
  const MedsResult.failed(MedsFailure this.failure) : value = null;

  final T? value;
  final MedsFailure? failure;

  bool get ok => failure == null;
}

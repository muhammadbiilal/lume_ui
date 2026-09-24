/// Why a Meal Plan write did not happen — typed, never a message string.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';

enum MealPlanFailureKind { validation, conflict, notFound, storage, damaged }

@immutable
class MealPlanFailure implements Exception {
  const MealPlanFailure(
    this.kind, {
    this.field,
    this.reason,
    this.ids = const <LumeRecordId>[],
    this.cause,
  });

  const MealPlanFailure.validation(String this.field, String this.reason)
    : kind = MealPlanFailureKind.validation,
      ids = const <LumeRecordId>[],
      cause = null;

  final MealPlanFailureKind kind;
  final String? field;
  final String? reason;
  final List<LumeRecordId> ids;
  final Object? cause;

  @override
  String toString() =>
      'MealPlanFailure(${kind.name}'
      '${field == null ? '' : ', $field'}'
      '${reason == null ? '' : ': $reason'}'
      '${ids.isEmpty ? '' : ', $ids'})';
}

@immutable
class MealPlanResult<T> {
  const MealPlanResult.ok(T this.value) : failure = null;
  const MealPlanResult.failed(MealPlanFailure this.failure) : value = null;

  final T? value;
  final MealPlanFailure? failure;

  bool get ok => failure == null;
}

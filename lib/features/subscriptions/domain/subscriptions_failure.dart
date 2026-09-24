/// Why a Subscriptions write did not happen — typed, never a message string.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';

enum SubscriptionsFailureKind {
  validation,
  conflict,
  notFound,
  overflow,
  storage,
  damaged,
}

@immutable
class SubscriptionsFailure implements Exception {
  const SubscriptionsFailure(
    this.kind, {
    this.field,
    this.reason,
    this.ids = const <LumeRecordId>[],
    this.cause,
  });

  const SubscriptionsFailure.validation(String this.field, String this.reason)
    : kind = SubscriptionsFailureKind.validation,
      ids = const <LumeRecordId>[],
      cause = null;

  final SubscriptionsFailureKind kind;
  final String? field;
  final String? reason;
  final List<LumeRecordId> ids;
  final Object? cause;

  @override
  String toString() =>
      'SubscriptionsFailure(${kind.name}'
      '${field == null ? '' : ', $field'}'
      '${reason == null ? '' : ': $reason'}'
      '${ids.isEmpty ? '' : ', $ids'})';
}

@immutable
class SubscriptionsResult<T> {
  const SubscriptionsResult.ok(T this.value) : failure = null;
  const SubscriptionsResult.failed(SubscriptionsFailure this.failure) : value = null;

  final T? value;
  final SubscriptionsFailure? failure;

  bool get ok => failure == null;
}

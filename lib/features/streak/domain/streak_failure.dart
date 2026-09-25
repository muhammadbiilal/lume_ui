/// Why a Daily Streak write did not happen — typed, never a message string.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';

enum StreakFailureKind { conflict, notFound, storage }

@immutable
class StreakFailure implements Exception {
  const StreakFailure(
    this.kind, {
    this.ids = const <LumeRecordId>[],
    this.cause,
  });

  final StreakFailureKind kind;
  final List<LumeRecordId> ids;
  final Object? cause;

  @override
  String toString() =>
      'StreakFailure(${kind.name}${ids.isEmpty ? '' : ', $ids'})';
}

@immutable
class StreakResult<T> {
  const StreakResult.ok(T this.value) : failure = null;
  const StreakResult.failed(StreakFailure this.failure) : value = null;

  final T? value;
  final StreakFailure? failure;

  bool get ok => failure == null;
}

/// Why a Taraweeh write did not happen — typed, never a message string.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';

enum TaraweehFailureKind { conflict, notFound, storage, validation }

@immutable
class TaraweehFailure implements Exception {
  const TaraweehFailure(
    this.kind, {
    this.ids = const <LumeRecordId>[],
    this.field,
    this.cause,
  });

  const TaraweehFailure.validation(String field)
    : this(TaraweehFailureKind.validation, field: field);

  final TaraweehFailureKind kind;
  final List<LumeRecordId> ids;

  /// Set on [TaraweehFailureKind.validation] — the field the reader's own
  /// input failed on ("rakaat", "juz").
  final String? field;
  final Object? cause;

  @override
  String toString() =>
      'TaraweehFailure(${kind.name}'
      '${ids.isEmpty ? '' : ', $ids'}'
      '${field == null ? '' : ', $field'})';
}

@immutable
class TaraweehResult<T> {
  const TaraweehResult.ok(T this.value) : failure = null;
  const TaraweehResult.failed(TaraweehFailure this.failure) : value = null;

  final T? value;
  final TaraweehFailure? failure;

  bool get ok => failure == null;
}

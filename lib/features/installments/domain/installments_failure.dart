/// Why an Installments write did not happen — typed, never a message string.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';

enum InstallmentsFailureKind {
  /// A field the reader typed is not acceptable ([InstallmentsFailure.field],
  /// [InstallmentsFailure.reason]).
  validation,

  /// Another write got there first.
  conflict,

  /// A record named is not there.
  notFound,

  /// A sum past its bound (10^15 per amount, 2^53 − 1 per sum).
  overflow,

  /// Not the earliest unpaid instalment ([InstallmentsFailure.ids] — the
  /// one to pay first).
  outOfOrder,

  /// The instalment already has an active payment.
  alreadyPaid,

  /// A term that payments have fixed ([InstallmentsFailure.field]).
  locked,

  /// The plan is cancelled; nothing is paid on it until it is reinstated.
  cancelled,

  /// Every instalment is paid; there is nothing to pay or cancel.
  completed,

  /// The records are not loaded, or the store refused.
  storage,

  /// The records on file break Installments' rules; nothing is written
  /// over them.
  damaged,
}

@immutable
class InstallmentsFailure implements Exception {
  const InstallmentsFailure(
    this.kind, {
    this.field,
    this.reason,
    this.ids = const <LumeRecordId>[],
    this.cause,
  });

  const InstallmentsFailure.validation(String this.field, String this.reason)
    : kind = InstallmentsFailureKind.validation,
      ids = const <LumeRecordId>[],
      cause = null;

  final InstallmentsFailureKind kind;
  final String? field;
  final String? reason;
  final List<LumeRecordId> ids;

  /// Diagnostic only — minor-unit figures and failure kinds, never an item,
  /// a merchant or a note.
  final Object? cause;

  @override
  String toString() =>
      'InstallmentsFailure(${kind.name}'
      '${field == null ? '' : ', $field'}'
      '${reason == null ? '' : ': $reason'}'
      '${ids.isEmpty ? '' : ', $ids'})';
}

/// An Installments operation's outcome.
@immutable
class InstallmentsResult<T> {
  const InstallmentsResult.ok(T this.value) : failure = null;
  const InstallmentsResult.failed(InstallmentsFailure this.failure)
    : value = null;

  final T? value;
  final InstallmentsFailure? failure;

  bool get ok => failure == null;
}

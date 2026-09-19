/// Why a Ledger write did not happen — typed, never a message string.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';

enum LedgerFailureKind {
  /// A field the reader typed is not acceptable ([LedgerFailure.field],
  /// [LedgerFailure.reason]).
  validation,

  /// Another write got there first ([LedgerFailure.ids]).
  conflict,

  /// A record named is not there.
  notFound,

  /// Two currencies in one calculation or one allocation.
  currencyMismatch,

  /// A sum past its bound (10^15 per entry, 2^53 − 1 per sum).
  overflow,

  /// A repayment larger than what is open, not confirmed as credit
  /// ([LedgerFailure.excess], [LedgerFailure.ids] — the repayments).
  overpayment,

  /// Manual allocations that no longer fit ([LedgerFailure.ids]).
  allocationConflict,

  /// A person still referenced by entries ([LedgerFailure.count]).
  partyReferenced,

  /// A person with an open balance cannot be archived.
  partyOpen,

  /// The records are not loaded, or the store refused.
  storage,

  /// The records on file break Ledger's rules; nothing is written over
  /// them until the reader reconciles.
  damaged,
}

@immutable
class LedgerFailure implements Exception {
  const LedgerFailure(
    this.kind, {
    this.field,
    this.reason,
    this.ids = const <LumeRecordId>[],
    this.excess = const <LumeMoney>[],
    this.count,
    this.cause,
  });

  const LedgerFailure.validation(String this.field, String this.reason)
    : kind = LedgerFailureKind.validation,
      ids = const <LumeRecordId>[],
      excess = const <LumeMoney>[],
      count = null,
      cause = null;

  final LedgerFailureKind kind;
  final String? field;
  final String? reason;
  final List<LumeRecordId> ids;

  /// Per currency, for an overpayment.
  final List<LumeMoney> excess;
  final int? count;

  /// Diagnostic only — minor-unit figures and failure kinds, never names or
  /// notes.
  final Object? cause;

  @override
  String toString() =>
      'LedgerFailure(${kind.name}'
      '${field == null ? '' : ', $field'}'
      '${reason == null ? '' : ': $reason'}'
      '${ids.isEmpty ? '' : ', $ids'}'
      '${excess.isEmpty ? '' : ', excess $excess'}'
      '${count == null ? '' : ', $count'})';
}

/// A Ledger operation's outcome.
@immutable
class LedgerResult<T> {
  const LedgerResult.ok(T this.value) : failure = null;
  const LedgerResult.failed(LedgerFailure this.failure) : value = null;

  final T? value;
  final LedgerFailure? failure;

  bool get ok => failure == null;
}

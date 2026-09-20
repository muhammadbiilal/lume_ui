/// Why a committee write was refused (`COMMITTEE_PROPOSAL.md` §5, §7).
///
/// Every refusal is typed and carries stable machine words. Nothing a
/// reader sees is built here: the screen turns a kind into a sentence in
/// their own language.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';

enum CommitteeFailureKind {
  /// A field the reader can correct: [CommitteeFailure.field] names it and
  /// [CommitteeFailure.reason] says what is wrong with it.
  validation,

  /// Someone else changed the record first, or the version is stale.
  conflict,

  /// The record is not there.
  notFound,

  /// A figure that cannot be held or added.
  overflow,

  /// A payout asked for before its cycle was fully collected (D-C3).
  incomplete,

  /// A second active contribution for one position and cycle, or a second
  /// active payout for one cycle.
  duplicate,

  /// The payout's position does not hold that cycle.
  notRecipient,

  /// A contribution under an active payout: void the payout first.
  paidOut,

  /// A term financial activity has fixed (D-C6). [CommitteeFailure.field]
  /// names it.
  locked,

  /// The committee is cancelled, and this write needs a running one.
  cancelled,

  /// The store refused, or is not there.
  storage,

  /// The write would leave the committee unreadable, or it was already.
  damaged,
}

@immutable
class CommitteeFailure implements Exception {
  const CommitteeFailure(
    this.kind, {
    this.field,
    this.reason,
    this.ids = const <LumeRecordId>[],
    this.shortfall,
    this.cause,
  });

  const CommitteeFailure.validation(String this.field, String this.reason)
    : kind = CommitteeFailureKind.validation,
      ids = const <LumeRecordId>[],
      shortfall = null,
      cause = null;

  final CommitteeFailureKind kind;
  final String? field;
  final String? reason;
  final List<LumeRecordId> ids;

  /// What a cycle is still short, for [CommitteeFailureKind.incomplete].
  final LumeMoney? shortfall;

  /// Diagnostic only: minor units and failure kinds, never reader text.
  final Object? cause;

  @override
  String toString() =>
      'CommitteeFailure(${kind.name}'
      '${field == null ? '' : ', $field'}'
      '${reason == null ? '' : '/$reason'})';
}

@immutable
class CommitteeResult<T> {
  const CommitteeResult.ok(T this.value) : failure = null;
  const CommitteeResult.failed(CommitteeFailure this.failure) : value = null;

  final T? value;
  final CommitteeFailure? failure;

  bool get ok => failure == null;
}

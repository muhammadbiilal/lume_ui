/// Why a baby-budget write was refused (`BABY_BUDGET_PROPOSAL.md` §7,
/// §9).
///
/// Every refusal is typed and carries stable machine words. Nothing a
/// reader sees is built here: the screen turns a kind into a sentence in
/// their own language.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';

enum BabyBudgetFailureKind {
  /// A field the reader can correct: [BabyBudgetFailure.field] names it
  /// and [BabyBudgetFailure.reason] says what is wrong with it.
  validation,

  /// Someone else changed the record first, or the version is stale.
  conflict,

  /// The record is not there.
  notFound,

  /// A figure that cannot be held or added.
  overflow,

  /// The budget is archived, and this write needs a live one.
  archived,

  /// A record would fall before the budget's first day, or the start
  /// would move past a record that already exists (correction 3).
  /// [BabyBudgetFailure.day] and [BabyBudgetFailure.ids] name it.
  beforeStart,

  /// A category plan without a budget plan, or category plans over it
  /// (correction 2).
  planShape,

  /// The store refused, or is not there.
  storage,

  /// The write would leave the budget unreadable, or it already was.
  damaged,
}

@immutable
class BabyBudgetFailure implements Exception {
  const BabyBudgetFailure(
    this.kind, {
    this.field,
    this.reason,
    this.ids = const <LumeRecordId>[],
    this.day,
    this.label,
    this.cause,
  });

  const BabyBudgetFailure.validation(String this.field, String this.reason)
    : kind = BabyBudgetFailureKind.validation,
      ids = const <LumeRecordId>[],
      day = null,
      label = null,
      cause = null;

  final BabyBudgetFailureKind kind;
  final String? field;
  final String? reason;
  final List<LumeRecordId> ids;

  /// The day that made the refusal, for [BabyBudgetFailureKind.beforeStart]:
  /// the earliest record's own day.
  final LumeDate? day;

  /// That record's label, so the reader is told which one stands in the
  /// way rather than being left to guess (correction 3).
  final String? label;

  /// Diagnostic only: minor units and failure kinds, never reader text.
  final Object? cause;

  @override
  String toString() =>
      'BabyBudgetFailure(${kind.name}'
      '${field == null ? '' : ', $field'}'
      '${reason == null ? '' : '/$reason'})';
}

@immutable
class BabyBudgetResult<T> {
  const BabyBudgetResult.ok(T this.value) : failure = null;
  const BabyBudgetResult.failed(BabyBudgetFailure this.failure) : value = null;

  final T? value;
  final BabyBudgetFailure? failure;

  bool get ok => failure == null;
}

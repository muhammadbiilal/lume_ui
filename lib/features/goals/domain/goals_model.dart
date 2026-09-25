/// Goals' stored records — a goal and its contributions — and their codec
/// to and from the record envelope (`GOALS_PROPOSAL.md` §2).
///
/// **A goal is a target the reader named, and a date it saves toward.**
/// Nothing here is a plan or a rate: there is no "monthly pace" stored,
/// because the reference's own `monthly` field is never checked against
/// what the reader actually saves. The pace shown is derived from real
/// contributions, in `goals_book.dart`.
///
/// **A contribution is append-only.** It can be voided, kept in the
/// record and excluded from every sum, but never edited in place — the
/// same rule Installments' payments and Ledger's entries already keep.
///
/// **One codec, nothing else sees a map.** Each type decodes from a
/// [LumeRecord] strictly; a record that fails is a [GoalsDefect], shown
/// as damaged, never dropped and never repaired silently.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

/// The stored schema — in every record, and in every export.
const String kGoalsSchema = 'lume.goals/1';

/// The record collections Goals keeps.
abstract final class GoalsCollections {
  static const String goals = 'goals.goal';
  static const String contributions = 'goals.contribution';
  static const List<String> all = <String>[goals, contributions];
}

/// Longest name, and longest note, the reader may type.
const int kGoalsNameMax = 80;
const int kGoalsNoteMax = 500;

enum GoalState { active, completed, abandoned }

enum GoalContributionState { active, voided }

/// A small fixed palette a goal is drawn with (D-G6) — decorative, never
/// derived from anything about the goal. `grid` is the reference's own
/// choice for a device/gadget goal ("New laptop" is drawn with `i-grid`,
/// `tool-data.js:781`); `star` and `home` round the palette out for goals
/// the reference doesn't have an example of.
enum GoalIcon { target, plane, grid, home, star, shield }

/// A savings goal — the reader is the saver.
@immutable
class Goal {
  const Goal({
    required this.id,
    required this.name,
    this.note,
    required this.target,
    this.targetDate,
    this.icon = GoalIcon.target,
    this.state = GoalState.active,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final String name;
  final String? note;

  /// What the goal is for.
  final LumeMoney target;

  /// When the reader wants to reach it. Optional (D-G4): the reference
  /// always has one, but nothing requires a reader to set one.
  final LumeDate? targetDate;
  final GoalIcon icon;
  final GoalState state;
  final DateTime createdAt;
  final int version;

  LumeCurrency get currency => target.currency;
  bool get active => state == GoalState.active;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kGoalsSchema,
    'name': name,
    'note': note,
    'targetMinor': target.minor,
    'currency': currency.code,
    'targetDate': targetDate?.toIso(),
    'icon': icon.name,
    'state': state.name,
  };

  Goal copyWith({
    String? name,
    String? note,
    bool clearNote = false,
    LumeMoney? target,
    LumeDate? targetDate,
    bool clearTargetDate = false,
    GoalIcon? icon,
    GoalState? state,
  }) => Goal(
    id: id,
    name: name ?? this.name,
    note: clearNote ? null : (note ?? this.note),
    target: target ?? this.target,
    targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
    icon: icon ?? this.icon,
    state: state ?? this.state,
    createdAt: createdAt,
    version: version,
  );

  static Goal decode(LumeRecord r) {
    final GoalsCodec c = GoalsCodec(GoalsCollections.goals, r);
    final LumeMoney target = c.money('targetMinor', 'currency');
    if (target.isZero) c.fail('targetMinor', 'zero');
    return Goal(
      id: c.id,
      name: c.name('name'),
      note: c.note('note'),
      target: target,
      targetDate: c.date('targetDate', optional: true),
      icon: c.choice('icon', GoalIcon.values),
      state: c.choice('state', GoalState.values),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Goal &&
      other.id == id &&
      other.name == name &&
      other.note == note &&
      other.target == target &&
      other.targetDate == targetDate &&
      other.icon == icon &&
      other.state == state &&
      other.version == version;

  @override
  int get hashCode =>
      Object.hash(id, name, note, target, targetDate, icon, state, version);
}

/// One contribution toward a goal, on one date, append-only.
@immutable
class GoalContribution {
  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.on,
    this.state = GoalContributionState.active,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final LumeRecordId goalId;
  final LumeMoney amount;
  final LumeDate on;
  final GoalContributionState state;
  final DateTime createdAt;
  final int version;

  bool get active => state == GoalContributionState.active;
  bool get voided => !active;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kGoalsSchema,
    'goal': goalId.value,
    'amountMinor': amount.minor,
    'currency': amount.currency.code,
    'on': on.toIso(),
    'state': state.name,
  };

  GoalContribution withState(GoalContributionState s) => GoalContribution(
    id: id,
    goalId: goalId,
    amount: amount,
    on: on,
    state: s,
    createdAt: createdAt,
    version: version,
  );

  static GoalContribution decode(LumeRecord r) {
    final GoalsCodec c = GoalsCodec(GoalsCollections.contributions, r);
    final LumeMoney amount = c.money('amountMinor', 'currency');
    if (amount.isZero) c.fail('amountMinor', 'zero');
    return GoalContribution(
      id: c.id,
      goalId: c.ref('goal'),
      amount: amount,
      on: c.date('on')!,
      state: c.choice('state', GoalContributionState.values),
      createdAt: r.createdAt,
      version: r.version,
    );
  }
}

/// A record that could not be read as what its collection holds.
@immutable
class GoalsDefect {
  const GoalsDefect(
    this.collection,
    this.recordId,
    this.field,
    this.reason, {
    this.goalId,
  });

  final String collection;
  final String recordId;
  final String field;

  /// A stable machine reason: `missing`, `type`, `precision`, `overflow`,
  /// `currency`, `schema`, `zero`, `unsupported` …
  final String reason;

  /// The goal the record says it belongs to, when it says one.
  final String? goalId;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

/// Thrown by a decode; caught by whoever reads a collection.
@immutable
class GoalsDefectException implements Exception {
  const GoalsDefectException(this.defect);
  final GoalsDefect defect;

  @override
  String toString() => 'GoalsDefectException($defect)';
}

/// Strict field readers for one record.
class GoalsCodec {
  GoalsCodec(this.collection, this.record) {
    if (record['schema'] != kGoalsSchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) => throw GoalsDefectException(
    GoalsDefect(
      collection,
      record.id,
      field,
      reason,
      goalId: collection == GoalsCollections.goals
          ? record.id
          : (record['goal'] is String ? record['goal']! as String : null),
    ),
  );

  LumeRecordId get id => LumeRecordId.tryParse(record.id) ?? fail('id', 'uuid');

  LumeRecordId ref(String field) {
    final Object? v = record[field];
    if (v is! String) fail(field, 'missing');
    return LumeRecordId.tryParse(v) ?? fail(field, 'uuid');
  }

  String name(String field) {
    final Object? v = record[field];
    if (v is! String) fail(field, 'missing');
    final String t = v.trim();
    if (t.isEmpty) fail(field, 'empty');
    if (t.length > kGoalsNameMax) fail(field, 'long');
    return t;
  }

  String? note(String field) {
    final Object? v = record[field];
    if (v == null) return null;
    if (v is! String) fail(field, 'type');
    if (v.length > kGoalsNoteMax) fail(field, 'long');
    return v.trim().isEmpty ? null : v;
  }

  T choice<T extends Enum>(String field, List<T> values) {
    final Object? v = record[field];
    for (final T x in values) {
      if (x.name == v) return x;
    }
    fail(field, 'value');
  }

  LumeDate? date(String field, {bool optional = false}) {
    final Object? v = record[field];
    if (v == null && optional) return null;
    if (v is! String) fail(field, 'missing');
    return LumeDate.tryParse(v) ?? fail(field, 'date');
  }

  LumeMoney money(String minorField, String currencyField) {
    final Object? code = record[currencyField];
    if (code is! String) fail(currencyField, 'missing');
    final LumeCurrency? cur = LumeCurrency.tryOf(code);
    if (cur == null) fail(currencyField, 'currency');
    final Object? minor = record[minorField];
    if (minor is! int) fail(minorField, 'type');
    try {
      return LumeMoney.entry(minor, cur);
    } on LumeMoneyException catch (e) {
      fail(minorField, e.failure.name);
    }
  }
}

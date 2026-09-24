/// Meal Plan's stored records — one entry per day and slot the reader has
/// filled in — and their codec to and from the record envelope
/// (`MEALPLAN_PROPOSAL.md` §2).
///
/// **The reference has no such thing.** It rotates through a 6-item
/// recipe fixture and reports five headline numbers that are bare
/// literals with no computation behind them — `kcal: 1980` doesn't even
/// agree with the real day-sums the reference computes beside it from
/// the same fixture (`context.js:1646-1666`). This model stores only
/// what the reader actually plans: free text, per day, per slot.
///
/// **At most one entry per (date, slot).** The 21 slots in a week always
/// exist as structure; only their content is optional. Setting an
/// already-filled slot replaces its text — this is an upsert, not an
/// open-ended list the reader adds to.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

/// The stored schema — in every record, and in every export.
const String kMealPlanSchema = 'lume.mealplan/1';

abstract final class MealPlanCollections {
  static const String entries = 'mealplan.entry';
  static const List<String> all = <String>[entries];
}

const int kMealPlanTextMax = 200;

enum MealSlot { breakfast, lunch, dinner }

@immutable
class MealPlanEntry {
  const MealPlanEntry({
    required this.id,
    required this.date,
    required this.slot,
    required this.text,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final LumeDate date;
  final MealSlot slot;

  /// What the reader plans to eat — free text. No kcal, no cost, no link
  /// to a nutrition source: nothing here claims a figure the reference
  /// never actually computed either (D-M2).
  final String text;
  final DateTime createdAt;
  final int version;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kMealPlanSchema,
    'date': date.toIso(),
    'slot': slot.name,
    'text': text,
  };

  MealPlanEntry copyWith({String? text}) => MealPlanEntry(
    id: id,
    date: date,
    slot: slot,
    text: text ?? this.text,
    createdAt: createdAt,
    version: version,
  );

  static MealPlanEntry decode(LumeRecord r) {
    final MealPlanCodec c = MealPlanCodec(MealPlanCollections.entries, r);
    return MealPlanEntry(
      id: c.id,
      date: c.date('date')!,
      slot: c.choice('slot', MealSlot.values),
      text: c.text('text'),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MealPlanEntry &&
      other.id == id &&
      other.date == date &&
      other.slot == slot &&
      other.text == text &&
      other.version == version;

  @override
  int get hashCode => Object.hash(id, date, slot, text, version);
}

@immutable
class MealPlanDefect {
  const MealPlanDefect(this.collection, this.recordId, this.field, this.reason);

  final String collection;
  final String recordId;
  final String field;
  final String reason;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

@immutable
class MealPlanDefectException implements Exception {
  const MealPlanDefectException(this.defect);
  final MealPlanDefect defect;

  @override
  String toString() => 'MealPlanDefectException($defect)';
}

class MealPlanCodec {
  MealPlanCodec(this.collection, this.record) {
    if (record['schema'] != kMealPlanSchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) => throw MealPlanDefectException(
    MealPlanDefect(collection, record.id, field, reason),
  );

  LumeRecordId get id => LumeRecordId.tryParse(record.id) ?? fail('id', 'uuid');

  String text(String field) {
    final Object? v = record[field];
    if (v is! String) fail(field, 'missing');
    final String t = v.trim();
    if (t.isEmpty) fail(field, 'empty');
    if (t.length > kMealPlanTextMax) fail(field, 'long');
    return t;
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
}

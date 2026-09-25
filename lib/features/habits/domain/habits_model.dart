/// Habits' stored records — a habit the reader named, and the days they
/// checked it off — and their codec to and from the record envelope.
///
/// **The reference has no real streak.** `context.js`'s `habits()` returns
/// `streak: 12, best: 28, rate: 0.82` and a `heatDays(35, 7731, 0.3)` heatmap
/// — every one of those a bare literal with a fixed seed, none of it worked
/// out from the four habits it draws beside them
/// (`tools/personal/habits.tool.js`). The persisted schema itself
/// (`record-schemas.js` `habits:`) only ever asks the reader for a name, a
/// cadence and a note — no daily log at all. This model keeps that name and
/// cadence, and adds the one thing the reference never stored: a check-in
/// per day the habit was actually kept. Every streak, best streak and
/// completion figure is derived from those check-ins, every time
/// (`habits_book.dart`) — never a hand-typed number that could disagree
/// with the record of what was actually checked off.
///
/// **A check-in is at most one per (habit, date).** Tapping a habit's row a
/// second time on the same day removes it rather than adding a duplicate —
/// the toggle is the write.
///
/// **One codec, nothing else sees a map.** A record that fails is a
/// [HabitsDefect], shown as damaged, never dropped or repaired silently.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

/// The stored schema — in every record, and in every export.
const String kHabitsSchema = 'lume.habits/1';

/// The record collections Habits keeps.
abstract final class HabitsCollections {
  static const String habits = 'habits.habit';
  static const String checkins = 'habits.checkin';
  static const List<String> all = <String>[habits, checkins];
}

/// Longest name, and longest note, the reader may type.
const int kHabitsNameMax = 80;
const int kHabitsNoteMax = 500;

/// How often the reader means to keep a habit — the reference's own three
/// (`rec.freq.daily/weekdays/weekly`, `record-schemas.js`), and never a
/// free-typed cadence a streak calculation could not reason about.
enum HabitFrequency { daily, weekdays, weekly }

/// A habit the reader is keeping — its name and cadence. What was actually
/// done about it lives in [HabitCheckin], not here.
@immutable
class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.frequency,
    this.notes,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final String name;
  final HabitFrequency frequency;
  final String? notes;
  final DateTime createdAt;
  final int version;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kHabitsSchema,
    'name': name,
    'frequency': frequency.name,
    'notes': notes,
  };

  Habit copyWith({
    String? name,
    HabitFrequency? frequency,
    String? notes,
    bool clearNotes = false,
  }) => Habit(
    id: id,
    name: name ?? this.name,
    frequency: frequency ?? this.frequency,
    notes: clearNotes ? null : (notes ?? this.notes),
    createdAt: createdAt,
    version: version,
  );

  static Habit decode(LumeRecord r) {
    final HabitsCodec c = HabitsCodec(HabitsCollections.habits, r);
    return Habit(
      id: c.id,
      name: c.name('name'),
      frequency: c.choice('frequency', HabitFrequency.values),
      notes: c.note('notes'),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Habit &&
      other.id == id &&
      other.name == name &&
      other.frequency == frequency &&
      other.notes == notes &&
      other.version == version;

  @override
  int get hashCode => Object.hash(id, name, frequency, notes, version);
}

/// One day the reader checked a habit off. Toggled, never edited in place:
/// removing one *is* "unchecking" that day.
@immutable
class HabitCheckin {
  const HabitCheckin({
    required this.id,
    required this.habitId,
    required this.date,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final LumeRecordId habitId;
  final LumeDate date;
  final DateTime createdAt;
  final int version;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kHabitsSchema,
    'habit': habitId.value,
    'date': date.toIso(),
  };

  static HabitCheckin decode(LumeRecord r) {
    final HabitsCodec c = HabitsCodec(HabitsCollections.checkins, r);
    return HabitCheckin(
      id: c.id,
      habitId: c.ref('habit'),
      date: c.date('date')!,
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HabitCheckin &&
      other.id == id &&
      other.habitId == habitId &&
      other.date == date &&
      other.version == version;

  @override
  int get hashCode => Object.hash(id, habitId, date, version);
}

/// A record that could not be read as what its collection holds.
@immutable
class HabitsDefect {
  const HabitsDefect(
    this.collection,
    this.recordId,
    this.field,
    this.reason, {
    this.habitId,
  });

  final String collection;
  final String recordId;
  final String field;

  /// A stable machine reason: `missing`, `type`, `long`, `empty`, `schema`,
  /// `uuid`, `date`, `value` …
  final String reason;

  /// The habit the record says it belongs to, when it says one.
  final String? habitId;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

/// Thrown by a decode; caught by whoever reads a collection.
@immutable
class HabitsDefectException implements Exception {
  const HabitsDefectException(this.defect);
  final HabitsDefect defect;

  @override
  String toString() => 'HabitsDefectException($defect)';
}

/// Strict field readers for one record.
class HabitsCodec {
  HabitsCodec(this.collection, this.record) {
    if (record['schema'] != kHabitsSchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) => throw HabitsDefectException(
    HabitsDefect(
      collection,
      record.id,
      field,
      reason,
      habitId: collection == HabitsCollections.habits
          ? record.id
          : (record['habit'] is String ? record['habit']! as String : null),
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
    if (t.length > kHabitsNameMax) fail(field, 'long');
    return t;
  }

  String? note(String field) {
    final Object? v = record[field];
    if (v == null) return null;
    if (v is! String) fail(field, 'type');
    if (v.length > kHabitsNoteMax) fail(field, 'long');
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
}

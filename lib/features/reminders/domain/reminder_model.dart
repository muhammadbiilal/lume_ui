/// Reminders' stored records and their codec to and from the record
/// envelope (`REMINDERS_PROPOSAL.md` §1). The schema is
/// `record-schemas.js:196-241`, unchanged: `label`, `at`, `repeat`,
/// `notes`. `enabled` is new here — the reference has no way to pause a
/// reminder without deleting it, and once delivery is real (wave 7),
/// silencing one without losing its configuration is not optional the
/// way it was when nothing ever fired.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

const String kReminderSchema = 'lume.reminder/1';

abstract final class ReminderCollections {
  static const String entries = 'reminder.entry';
  static const List<String> all = <String>[entries];
}

const int kReminderLabelMax = 120;
const int kReminderNotesMax = 400;

/// `rec.reminders.once` / `.daily` / `.weekly` — the schema's own three
/// options, in that order.
enum ReminderRepeat { once, daily, weekly }

@immutable
class ReminderEntry {
  const ReminderEntry({
    required this.id,
    required this.label,
    required this.atHour,
    required this.atMinute,
    required this.repeat,
    required this.createdAt,
    this.notes,
    this.enabled = true,
    this.version = 1,
  });

  final LumeRecordId id;
  final String label;

  /// 0–23, 0–59 — a time of day, no date, no zone (D-R1: a reminder fires
  /// on the reader's local clock, wherever that is today).
  final int atHour;
  final int atMinute;
  final ReminderRepeat repeat;
  final String? notes;

  /// Paused reminders keep their configuration and stop firing, rather
  /// than being deleted to go quiet.
  final bool enabled;
  final DateTime createdAt;
  final int version;

  int get minuteOfDay => atHour * 60 + atMinute;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kReminderSchema,
    'label': label,
    'atHour': atHour,
    'atMinute': atMinute,
    'repeat': repeat.name,
    if (notes != null) 'notes': notes,
    'enabled': enabled,
  };

  ReminderEntry copyWith({
    String? label,
    int? atHour,
    int? atMinute,
    ReminderRepeat? repeat,
    Object? notes = _sentinel,
    bool? enabled,
  }) => ReminderEntry(
    id: id,
    label: label ?? this.label,
    atHour: atHour ?? this.atHour,
    atMinute: atMinute ?? this.atMinute,
    repeat: repeat ?? this.repeat,
    notes: identical(notes, _sentinel) ? this.notes : notes as String?,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt,
    version: version,
  );

  static ReminderEntry decode(LumeRecord r) {
    final ReminderCodec c = ReminderCodec(ReminderCollections.entries, r);
    return ReminderEntry(
      id: c.id,
      label: c.text('label', kReminderLabelMax),
      atHour: c.hour('atHour'),
      atMinute: c.minute('atMinute'),
      repeat: c.choice('repeat', ReminderRepeat.values),
      notes: c.textOrNull('notes', kReminderNotesMax),
      enabled: c.boolean('enabled'),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderEntry &&
      other.id == id &&
      other.label == label &&
      other.atHour == atHour &&
      other.atMinute == atMinute &&
      other.repeat == repeat &&
      other.notes == notes &&
      other.enabled == enabled &&
      other.version == version;

  @override
  int get hashCode =>
      Object.hash(id, label, atHour, atMinute, repeat, notes, enabled, version);
}

const Object _sentinel = Object();

@immutable
class ReminderDefect {
  const ReminderDefect(this.collection, this.recordId, this.field, this.reason);

  final String collection;
  final String recordId;
  final String field;
  final String reason;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

@immutable
class ReminderDefectException implements Exception {
  const ReminderDefectException(this.defect);
  final ReminderDefect defect;

  @override
  String toString() => 'ReminderDefectException($defect)';
}

class ReminderCodec {
  ReminderCodec(this.collection, this.record) {
    if (record['schema'] != kReminderSchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) => throw ReminderDefectException(
    ReminderDefect(collection, record.id, field, reason),
  );

  LumeRecordId get id => LumeRecordId.tryParse(record.id) ?? fail('id', 'uuid');

  String text(String field, int max) {
    final Object? v = record[field];
    if (v is! String) fail(field, 'missing');
    final String t = v.trim();
    if (t.isEmpty) fail(field, 'empty');
    if (t.length > max) fail(field, 'long');
    return t;
  }

  String? textOrNull(String field, int max) {
    final Object? v = record[field];
    if (v == null) return null;
    if (v is! String) fail(field, 'type');
    final String t = v.trim();
    if (t.isEmpty) return null;
    if (t.length > max) fail(field, 'long');
    return t;
  }

  int hour(String field) {
    final Object? v = record[field];
    if (v is! int || v < 0 || v > 23) fail(field, 'range');
    return v;
  }

  int minute(String field) {
    final Object? v = record[field];
    if (v is! int || v < 0 || v > 59) fail(field, 'range');
    return v;
  }

  bool boolean(String field) {
    final Object? v = record[field];
    if (v is! bool) fail(field, 'missing');
    return v;
  }

  T choice<T extends Enum>(String field, List<T> values) {
    final Object? v = record[field];
    for (final T x in values) {
      if (x.name == v) return x;
    }
    fail(field, 'value');
  }
}

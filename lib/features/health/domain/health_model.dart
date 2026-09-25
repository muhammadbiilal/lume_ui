/// Health Records' stored records — one per visit, result, prescription,
/// vaccination or measurement the reader typed in themselves — and their
/// codec to and from the record envelope.
///
/// The reference (`tools/personal/health.tool.js`) draws a family switcher,
/// a "blood type"/"age" hero, a six-month weight chart and a spend-per-year
/// figure — none of which this build can produce honestly: there is no
/// family-member model here, and a chart or a running total needs a series
/// of real entries this schema does not keep. What survives is the actual
/// record shape from `record-schemas.js`'s `health` entry: a title, a kind,
/// a date, an optional source, an optional value and optional notes — the
/// reader's own words, never a reference range or a diagnosis this codebase
/// has no medical authority to state.
///
/// **One codec, nothing else sees a map.** A record that fails is a
/// [HealthDefect], shown as damaged, never dropped or repaired silently.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

/// The stored schema — in every record, and in every export.
const String kHealthSchema = 'lume.health/1';

/// The record collection Health Records keeps. One flat collection: a record
/// is a single row, never a parent with children.
abstract final class HealthCollections {
  static const String records = 'health.record';
  static const List<String> all = <String>[records];
}

const int kHealthTitleMax = 120;
const int kHealthSourceMax = 80;
const int kHealthValueMax = 60;
const int kHealthNotesMax = 1000;

/// `rec.health.kinds` — the reference's fixed option list, in its order.
enum HealthRecordKind {
  appointment,
  report,
  prescription,
  vaccination,
  measurement,
}

@immutable
class HealthRecord {
  const HealthRecord({
    required this.id,
    required this.title,
    required this.kind,
    required this.date,
    this.source,
    this.value,
    this.notes,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final String title;
  final HealthRecordKind kind;
  final LumeDate date;

  /// "Who" in the reference — a doctor, a clinic, a lab. Free text, since the
  /// reference never constrains it either.
  final String? source;

  /// A value the reader typed themselves — "4.9 mmol/L", "75 kg". Never a
  /// computed figure and never checked against a range this app does not
  /// have the authority to state.
  final String? value;

  final String? notes;
  final DateTime createdAt;
  final int version;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kHealthSchema,
    'title': title,
    'kind': kind.name,
    'date': date.toIso(),
    'source': source,
    'value': value,
    'notes': notes,
  };

  HealthRecord copyWith({
    String? title,
    HealthRecordKind? kind,
    LumeDate? date,
    String? source,
    bool clearSource = false,
    String? value,
    bool clearValue = false,
    String? notes,
    bool clearNotes = false,
  }) => HealthRecord(
    id: id,
    title: title ?? this.title,
    kind: kind ?? this.kind,
    date: date ?? this.date,
    source: clearSource ? null : (source ?? this.source),
    value: clearValue ? null : (value ?? this.value),
    notes: clearNotes ? null : (notes ?? this.notes),
    createdAt: createdAt,
    version: version,
  );

  static HealthRecord decode(LumeRecord r) {
    final HealthCodec c = HealthCodec(HealthCollections.records, r);
    return HealthRecord(
      id: c.id,
      title: c.name('title', max: kHealthTitleMax),
      kind: c.choice('kind', HealthRecordKind.values),
      date: c.date('date')!,
      source: c.optionalName('source', max: kHealthSourceMax),
      value: c.optionalName('value', max: kHealthValueMax),
      notes: c.optionalName('notes', max: kHealthNotesMax),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HealthRecord &&
      other.id == id &&
      other.title == title &&
      other.kind == kind &&
      other.date == date &&
      other.source == source &&
      other.value == value &&
      other.notes == notes &&
      other.version == version;

  @override
  int get hashCode =>
      Object.hash(id, title, kind, date, source, value, notes, version);
}

/// A record that could not be read as what its collection holds.
@immutable
class HealthDefect {
  const HealthDefect(this.collection, this.recordId, this.field, this.reason);

  final String collection;
  final String recordId;
  final String field;
  final String reason;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

@immutable
class HealthDefectException implements Exception {
  const HealthDefectException(this.defect);
  final HealthDefect defect;

  @override
  String toString() => 'HealthDefectException($defect)';
}

/// Strict field readers for one record.
class HealthCodec {
  HealthCodec(this.collection, this.record) {
    if (record['schema'] != kHealthSchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) => throw HealthDefectException(
    HealthDefect(collection, record.id, field, reason),
  );

  LumeRecordId get id => LumeRecordId.tryParse(record.id) ?? fail('id', 'uuid');

  String name(String field, {int max = kHealthTitleMax}) {
    final Object? v = record[field];
    if (v is! String) fail(field, 'missing');
    final String t = v.trim();
    if (t.isEmpty) fail(field, 'empty');
    if (t.length > max) fail(field, 'long');
    return t;
  }

  String? optionalName(String field, {required int max}) {
    final Object? v = record[field];
    if (v == null) return null;
    if (v is! String) fail(field, 'type');
    final String t = v.trim();
    if (t.length > max) fail(field, 'long');
    return t.isEmpty ? null : t;
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

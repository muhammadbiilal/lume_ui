/// Vaccinations' stored records — one per vaccination the reader has logged,
/// for themselves or anyone in their household — and their codec to and from
/// the record envelope.
///
/// **The reference has no records at all.** `tools/personal/vaccines.tool.js`
/// draws a person switcher over `HEALTH_PEOPLE` (three named fixture people —
/// "You", "Sana", "Musa") and a fixed `VACCINES` fixture keyed to those
/// invented names (`tool-data.js`). None of that is real: a reader's
/// household is not three people with those names, and inventing a family to
/// stand in for theirs would be exactly the fabrication §64 of this
/// project's brief forbids. This model keeps the shape the reference draws —
/// a vaccine's name, its dose, a date, who it was for, who gave it, whether
/// it has been given or is still due, and a note — but every field is the
/// reader's own words. `forWhom` is free text, not a picker over a fixture
/// roster: the reader types "Amara" or "Myself" or leaves it blank, and nine
/// other households never see three names that were never theirs.
///
/// **No schedule is invented either.** The reference's dose labels ("2 of
/// 2", "Annual") are examples on fixture rows, not a published immunisation
/// schedule for any country — there is no real schedule data behind them to
/// carry forward. `date` is the date the reader is logging: when it was
/// given, or when it is next due. Nothing here computes a recommended due
/// date, and nothing schedules a reminder for it — a due date is stored and
/// shown as what it is, the reader's own note to themselves, never a promise
/// that Lume will alert them.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

/// The stored schema — in every record, and in every export.
const String kVaccinesSchema = 'lume.vaccines/1';

/// One flat collection, matching Subscriptions rather than Meal Plan: a
/// vaccination is a single row with no child records and no fixed slots to
/// upsert into.
abstract final class VaccinesCollections {
  static const String records = 'vaccines.record';
  static const List<String> all = <String>[records];
}

const int kVaccinesNameMax = 80;
const int kVaccinesForWhomMax = 60;
const int kVaccinesDoseMax = 40;
const int kVaccinesProviderMax = 80;
const int kVaccinesNotesMax = 300;

/// Whether the reader has already had this vaccination, or is still waiting
/// on it — the reference's own two states (`state: 'done' | 'due'`,
/// `tool-data.js`). There is no third state: a reference row is one or the
/// other, never "overdue" as a stored fact — overdue is worked out from
/// [VaccineRecord.date] against today (`vaccines_book.dart`), not typed in
/// twice.
enum VaccineStatus { given, due }

@immutable
class VaccineRecord {
  const VaccineRecord({
    required this.id,
    required this.name,
    this.forWhom,
    this.dose,
    required this.date,
    this.status = VaccineStatus.given,
    this.provider,
    this.notes,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;

  /// The vaccine's name — "MMR", "Tetanus booster". The reader's own words,
  /// never matched against a manufacturer or a schedule database that does
  /// not exist here.
  final String name;

  /// Who it was for. Free text — "Myself", a child's name, anyone the
  /// reader is keeping records for — never a picker over an invented
  /// household roster (D-V1).
  final String? forWhom;

  /// "2nd dose", "Annual", "Booster" — the reader's own label, matching the
  /// reference's free-text `dose` field.
  final String? dose;

  /// The date this vaccination was given, or is due — whichever [status]
  /// says. One date, doing one job; there is no second "due date" field to
  /// disagree with it.
  final LumeDate date;
  final VaccineStatus status;

  /// The clinic, doctor or pharmacy — the reference's `by`.
  final String? provider;
  final String? notes;

  final DateTime createdAt;
  final int version;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kVaccinesSchema,
    'name': name,
    'forWhom': forWhom,
    'dose': dose,
    'date': date.toIso(),
    'status': status.name,
    'provider': provider,
    'notes': notes,
  };

  VaccineRecord copyWith({
    String? name,
    String? forWhom,
    bool clearForWhom = false,
    String? dose,
    bool clearDose = false,
    LumeDate? date,
    VaccineStatus? status,
    String? provider,
    bool clearProvider = false,
    String? notes,
    bool clearNotes = false,
  }) => VaccineRecord(
    id: id,
    name: name ?? this.name,
    forWhom: clearForWhom ? null : (forWhom ?? this.forWhom),
    dose: clearDose ? null : (dose ?? this.dose),
    date: date ?? this.date,
    status: status ?? this.status,
    provider: clearProvider ? null : (provider ?? this.provider),
    notes: clearNotes ? null : (notes ?? this.notes),
    createdAt: createdAt,
    version: version,
  );

  static VaccineRecord decode(LumeRecord r) {
    final VaccinesCodec c = VaccinesCodec(VaccinesCollections.records, r);
    return VaccineRecord(
      id: c.id,
      name: c.name('name', max: kVaccinesNameMax),
      forWhom: c.optional('forWhom', max: kVaccinesForWhomMax),
      dose: c.optional('dose', max: kVaccinesDoseMax),
      date: c.date('date')!,
      status: c.choice('status', VaccineStatus.values),
      provider: c.optional('provider', max: kVaccinesProviderMax),
      notes: c.optional('notes', max: kVaccinesNotesMax),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VaccineRecord &&
      other.id == id &&
      other.name == name &&
      other.forWhom == forWhom &&
      other.dose == dose &&
      other.date == date &&
      other.status == status &&
      other.provider == provider &&
      other.notes == notes &&
      other.version == version;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    forWhom,
    dose,
    date,
    status,
    provider,
    notes,
    version,
  );
}

/// A record that could not be read as what its collection holds.
@immutable
class VaccinesDefect {
  const VaccinesDefect(this.collection, this.recordId, this.field, this.reason);

  final String collection;
  final String recordId;
  final String field;
  final String reason;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

@immutable
class VaccinesDefectException implements Exception {
  const VaccinesDefectException(this.defect);
  final VaccinesDefect defect;

  @override
  String toString() => 'VaccinesDefectException($defect)';
}

/// Strict field readers for one record. A record that fails any of these is
/// a [VaccinesDefect], shown as damaged — never dropped or repaired silently.
class VaccinesCodec {
  VaccinesCodec(this.collection, this.record) {
    if (record['schema'] != kVaccinesSchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) => throw VaccinesDefectException(
    VaccinesDefect(collection, record.id, field, reason),
  );

  LumeRecordId get id => LumeRecordId.tryParse(record.id) ?? fail('id', 'uuid');

  String name(String field, {required int max}) {
    final Object? v = record[field];
    if (v is! String) fail(field, 'missing');
    final String t = v.trim();
    if (t.isEmpty) fail(field, 'empty');
    if (t.length > max) fail(field, 'long');
    return t;
  }

  String? optional(String field, {required int max}) {
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

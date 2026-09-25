/// Medication's stored records — one entry per medicine the reader tracks —
/// and their codec to and from the record envelope.
///
/// **The reference (`meds.tool.js`, `tool-data.js:735-738`) rotates a
/// three-item fixture whose `adherence` (0.94, 0.88, `null`) and `next`
/// ("Sun 09:00", "Today 20:00") are bare literals with no log behind them —
/// nothing counts a dose as taken anywhere in the reference. This build has
/// no dose log either (one was not asked for, and inventing one here would
/// be exactly the fabrication this conversion avoids), so this model stores
/// only what `record-schemas.js`'s `meds` entry actually asks the reader to
/// type: a name, a dose, a schedule, an optional first-dose time of day, an
/// optional count of doses left, and a note. No adherence figure and no
/// "next dose" countdown are computed from that — there is nothing honest to
/// compute them from.
///
/// **`at` is a time of day, not an alarm.** It is stored exactly like a
/// subscription's renewal date or a goal's target date: plain data the
/// reader typed, read back and shown. It does not schedule a notification —
/// that pipeline belongs to Reminders alone — and nothing in this feature
/// claims Lume will alert the reader at that time.
///
/// **Strict codec.** A record that fails is a [MedsDefect], shown as
/// damaged, never dropped or silently repaired.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

/// The stored schema — in every record, and in every export.
const String kMedsSchema = 'lume.meds/1';

/// One flat collection, no aggregate parent — a medication is a single row,
/// edited in place, matching `record-schemas.js`'s `meds` entry.
abstract final class MedsCollections {
  static const String medications = 'meds.medication';
  static const List<String> all = <String>[medications];
}

const int kMedsNameMax = 80;
const int kMedsDoseMax = 60;
const int kMedsNoteMax = 500;

/// `left` — the reader's own count of doses remaining, never a pack size the
/// reader never typed (the reference's fixture also carries an `of` total;
/// the schema this build follows does not, so no fraction is drawn — only
/// the plain count, and a running-low flag once it is at or below 3, exactly
/// `record-schemas.js`'s own row rule).
const int kMedsDosesLeftMax = 9999;

/// `rec.sched.*` — the reference's own four choices, matching `options.
/// schedule` in `record-schemas.js`.
enum MedsSchedule { daily, twice, weekly, needed }

@immutable
class MedsEntry {
  const MedsEntry({
    required this.id,
    required this.name,
    required this.dose,
    required this.schedule,
    this.firstDoseAt,
    this.dosesLeft,
    this.notes,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final String name;
  final String dose;
  final MedsSchedule schedule;

  /// `HH:mm`, 24-hour, or `null` — a time of day the reader typed, not a
  /// scheduled alert (see the library note).
  final String? firstDoseAt;

  /// `null` when the reader has not counted, distinct from `0` ("none
  /// left").
  final int? dosesLeft;
  final String? notes;
  final DateTime createdAt;
  final int version;

  /// `record-schemas.js` `meds.row()`: `Number(r.left) > 0 && <= 3`.
  bool get runningLow =>
      dosesLeft != null && dosesLeft! > 0 && dosesLeft! <= 3;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kMedsSchema,
    'name': name,
    'dose': dose,
    'schedule': schedule.name,
    'firstDoseAt': firstDoseAt,
    'dosesLeft': dosesLeft,
    'notes': notes,
  };

  MedsEntry copyWith({
    String? name,
    String? dose,
    MedsSchedule? schedule,
    String? firstDoseAt,
    bool clearFirstDoseAt = false,
    int? dosesLeft,
    bool clearDosesLeft = false,
    String? notes,
    bool clearNotes = false,
  }) => MedsEntry(
    id: id,
    name: name ?? this.name,
    dose: dose ?? this.dose,
    schedule: schedule ?? this.schedule,
    firstDoseAt: clearFirstDoseAt ? null : (firstDoseAt ?? this.firstDoseAt),
    dosesLeft: clearDosesLeft ? null : (dosesLeft ?? this.dosesLeft),
    notes: clearNotes ? null : (notes ?? this.notes),
    createdAt: createdAt,
    version: version,
  );

  static MedsEntry decode(LumeRecord r) {
    final MedsCodec c = MedsCodec(MedsCollections.medications, r);
    return MedsEntry(
      id: c.id,
      name: c.name('name'),
      dose: c.dose('dose'),
      schedule: c.choice('schedule', MedsSchedule.values),
      firstDoseAt: c.optionalClock('firstDoseAt'),
      dosesLeft: c.optionalCount('dosesLeft'),
      notes: c.optionalNote('notes'),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MedsEntry &&
      other.id == id &&
      other.name == name &&
      other.dose == dose &&
      other.schedule == schedule &&
      other.firstDoseAt == firstDoseAt &&
      other.dosesLeft == dosesLeft &&
      other.notes == notes &&
      other.version == version;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    dose,
    schedule,
    firstDoseAt,
    dosesLeft,
    notes,
    version,
  );
}

/// A record that could not be read as what its collection holds.
@immutable
class MedsDefect {
  const MedsDefect(this.collection, this.recordId, this.field, this.reason);

  final String collection;
  final String recordId;
  final String field;
  final String reason;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

@immutable
class MedsDefectException implements Exception {
  const MedsDefectException(this.defect);
  final MedsDefect defect;

  @override
  String toString() => 'MedsDefectException($defect)';
}

/// Strict field readers for one record. Never repairs — a bad field fails
/// the whole record as a defect.
class MedsCodec {
  MedsCodec(this.collection, this.record) {
    if (record['schema'] != kMedsSchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) =>
      throw MedsDefectException(MedsDefect(collection, record.id, field, reason));

  LumeRecordId get id => LumeRecordId.tryParse(record.id) ?? fail('id', 'uuid');

  String name(String field) {
    final Object? v = record[field];
    if (v is! String) fail(field, 'missing');
    final String t = v.trim();
    if (t.isEmpty) fail(field, 'empty');
    if (t.length > kMedsNameMax) fail(field, 'long');
    return t;
  }

  String dose(String field) {
    final Object? v = record[field];
    if (v is! String) fail(field, 'missing');
    final String t = v.trim();
    if (t.isEmpty) fail(field, 'empty');
    if (t.length > kMedsDoseMax) fail(field, 'long');
    return t;
  }

  String? optionalNote(String field) {
    final Object? v = record[field];
    if (v == null) return null;
    if (v is! String) fail(field, 'type');
    final String t = v.trim();
    if (t.length > kMedsNoteMax) fail(field, 'long');
    return t.isEmpty ? null : t;
  }

  T choice<T extends Enum>(String field, List<T> values) {
    final Object? v = record[field];
    for (final T x in values) {
      if (x.name == v) return x;
    }
    fail(field, 'value');
  }

  /// `HH:mm`, 24-hour, or `null`.
  String? optionalClock(String field) {
    final Object? v = record[field];
    if (v == null) return null;
    if (v is! String) fail(field, 'type');
    final RegExpMatch? m = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(v);
    if (m == null) fail(field, 'clock');
    return v;
  }

  int? optionalCount(String field) {
    final Object? v = record[field];
    if (v == null) return null;
    if (v is! int || v < 0 || v > kMedsDosesLeftMax) fail(field, 'range');
    return v;
  }
}

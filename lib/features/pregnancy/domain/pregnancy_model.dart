/// Pregnancy's one stored value — the first day of the reader's last
/// period — and its codec to and from the record envelope.
///
/// **The reference has no real input at all.** `pregnancy.tool.js` calls a
/// single fixture, `context.js` `pregnancy()`, which hardcodes `week: 22`
/// forever, a due date 126 days out from whatever "now" happens to be, an
/// invented weekly note ("Hearing is developing quickly…"), a size
/// ("a papaya"), a weight ("430 g"), two appointments and a six-point
/// weight series — none of it computed from anything the reader entered,
/// because the reference never asks. This model stores exactly the one
/// fact a due-date estimate actually needs.
///
/// **At most one record.** Pregnancy is a single running estimate, not a
/// list: setting a new last-period date replaces the one on file rather
/// than adding another.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

/// The stored schema — in every record.
const String kPregnancySchema = 'lume.pregnancy/1';

abstract final class PregnancyCollections {
  static const String profile = 'pregnancy.profile';
  static const List<String> all = <String>[profile];
}

@immutable
class PregnancyProfile {
  const PregnancyProfile({
    required this.id,
    required this.lmp,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;

  /// The first day of the reader's last menstrual period — the one fact
  /// every figure on screen is worked out from ([LumePregnancy.of]).
  final LumeDate lmp;
  final DateTime createdAt;
  final int version;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kPregnancySchema,
    'lmp': lmp.toIso(),
  };

  PregnancyProfile copyWith({LumeDate? lmp}) => PregnancyProfile(
    id: id,
    lmp: lmp ?? this.lmp,
    createdAt: createdAt,
    version: version,
  );

  static PregnancyProfile decode(LumeRecord r) {
    final PregnancyCodec c = PregnancyCodec(PregnancyCollections.profile, r);
    return PregnancyProfile(
      id: c.id,
      lmp: c.date('lmp'),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PregnancyProfile &&
      other.id == id &&
      other.lmp == lmp &&
      other.version == version;

  @override
  int get hashCode => Object.hash(id, lmp, version);
}

@immutable
class PregnancyDefect {
  const PregnancyDefect(
    this.collection,
    this.recordId,
    this.field,
    this.reason,
  );

  final String collection;
  final String recordId;
  final String field;
  final String reason;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

@immutable
class PregnancyDefectException implements Exception {
  const PregnancyDefectException(this.defect);
  final PregnancyDefect defect;

  @override
  String toString() => 'PregnancyDefectException($defect)';
}

class PregnancyCodec {
  PregnancyCodec(this.collection, this.record) {
    if (record['schema'] != kPregnancySchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) => throw PregnancyDefectException(
    PregnancyDefect(collection, record.id, field, reason),
  );

  LumeRecordId get id => LumeRecordId.tryParse(record.id) ?? fail('id', 'uuid');

  LumeDate date(String field) {
    final Object? v = record[field];
    if (v is! String) fail(field, 'missing');
    return LumeDate.tryParse(v) ?? fail(field, 'date');
  }
}

/// Daily Streak's stored records — one check-in per day the reader marks —
/// and their codec to and from the record envelope.
///
/// **The reference has no schema for this at all.** `streak.tool.js` is a
/// pure display over `context.js`'s `streaks()`, which returns five bare
/// literals (`current: 12, best: 28, thisMonth: 21, rate: 0.78,
/// nextMilestone: 14`) and a random 35-day heat grid — no record family, no
/// write path, nothing a reader ever taps. Rather than invent a
/// cross-feature integration the reference never had (counting some other
/// tool's records), this stores exactly what a standalone streak counter
/// needs and nothing else: the dates the reader marked as done, here, in
/// Daily Streak. Every figure this feature shows is computed from that set
/// in `streak_book.dart` — never a literal.
///
/// **At most one check-in per date.** Marking an already-checked-in day is a
/// no-op, not a duplicate.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

/// The stored schema — in every record.
const String kStreakSchema = 'lume.streak/1';

abstract final class StreakCollections {
  static const String checkIns = 'streak.checkin';
  static const List<String> all = <String>[checkIns];
}

@immutable
class StreakCheckIn {
  const StreakCheckIn({
    required this.id,
    required this.date,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final LumeDate date;
  final DateTime createdAt;
  final int version;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kStreakSchema,
    'date': date.toIso(),
  };

  static StreakCheckIn decode(LumeRecord r) {
    final StreakCodec c = StreakCodec(StreakCollections.checkIns, r);
    return StreakCheckIn(
      id: c.id,
      date: c.date('date'),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StreakCheckIn &&
      other.id == id &&
      other.date == date &&
      other.version == version;

  @override
  int get hashCode => Object.hash(id, date, version);
}

@immutable
class StreakDefect {
  const StreakDefect(this.collection, this.recordId, this.field, this.reason);

  final String collection;
  final String recordId;
  final String field;
  final String reason;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

@immutable
class StreakDefectException implements Exception {
  const StreakDefectException(this.defect);
  final StreakDefect defect;

  @override
  String toString() => 'StreakDefectException($defect)';
}

class StreakCodec {
  StreakCodec(this.collection, this.record) {
    if (record['schema'] != kStreakSchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) => throw StreakDefectException(
    StreakDefect(collection, record.id, field, reason),
  );

  LumeRecordId get id => LumeRecordId.tryParse(record.id) ?? fail('id', 'uuid');

  LumeDate date(String field) {
    final Object? v = record[field];
    if (v is! String) fail(field, 'missing');
    return LumeDate.tryParse(v) ?? fail(field, 'date');
  }
}

/// Cycle Tracker's stored records — one entry per logged period — and their
/// codec to and from the record envelope.
///
/// **The reference has no such thing.** `tools/personal/cycle.tool.js` calls
/// a single `c.cycle()` (`context.js:1714-1726`) that computes
/// `day: (new Date().getDate() % 28) + 1` — today's day-of-month, not a
/// cycle day at all — against a hard-coded `length: 28`, and reports three
/// months of fixture history that are bare literals (`length: 28/29/27`,
/// every one of them `note: 'Regular'`). None of it reads anything the
/// reader has entered, because the reference has nowhere for the reader to
/// enter it. This model stores only what the reader actually logs: when a
/// period started, and — optionally — when it ended. Everything Cycle Tracker
/// shows beyond that (the current cycle day, the phase, the average length,
/// the estimated next date) is a real derived calculation over these
/// records, in `cycle_book.dart` — never a stored field, and never a
/// fixture.
///
/// **One of the app's most sensitive record families.** Nothing here is
/// promoted on Home, nothing here is shareable, and nothing here implies any
/// of it leaves the device — the catalogue's `cycle` entry is `sensitive:
/// true` with the default `LumeOutbound.none`, so the shared tool frame's
/// privacy note already says so without this feature naming itself.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

/// The stored schema — in every record, and in every export.
const String kCycleSchema = 'lume.cycle/1';

abstract final class CycleCollections {
  static const String periods = 'cycle.period';
  static const List<String> all = <String>[periods];
}

@immutable
class CyclePeriod {
  const CyclePeriod({
    required this.id,
    required this.startDate,
    required this.createdAt,
    this.endDate,
    this.version = 1,
  });

  final LumeRecordId id;

  /// The day the period started. Required — there is no entry without one.
  final LumeDate startDate;

  /// The day it ended, once the reader logs it. `null` while it is ongoing —
  /// this is never inferred or guessed forward.
  final LumeDate? endDate;

  final DateTime createdAt;
  final int version;

  /// Still bleeding, so far as the reader has told Lume.
  bool get ongoing => endDate == null;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kCycleSchema,
    'start': startDate.toIso(),
    'end': endDate?.toIso(),
  };

  CyclePeriod copyWith({
    LumeDate? startDate,
    LumeDate? endDate,
    bool clearEnd = false,
  }) => CyclePeriod(
    id: id,
    startDate: startDate ?? this.startDate,
    endDate: clearEnd ? null : (endDate ?? this.endDate),
    createdAt: createdAt,
    version: version,
  );

  static CyclePeriod decode(LumeRecord r) {
    final CycleCodec c = CycleCodec(CycleCollections.periods, r);
    return CyclePeriod(
      id: c.id,
      startDate: c.date('start')!,
      endDate: c.date('end', optional: true),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CyclePeriod &&
      other.id == id &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.version == version;

  @override
  int get hashCode => Object.hash(id, startDate, endDate, version);
}

@immutable
class CycleDefect {
  const CycleDefect(this.collection, this.recordId, this.field, this.reason);

  final String collection;
  final String recordId;
  final String field;
  final String reason;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

@immutable
class CycleDefectException implements Exception {
  const CycleDefectException(this.defect);
  final CycleDefect defect;

  @override
  String toString() => 'CycleDefectException($defect)';
}

/// Strict decoding: a record that does not match [kCycleSchema] or whose
/// fields do not parse is a defect, reported and skipped — never silently
/// repaired and never allowed to crash the read.
class CycleCodec {
  CycleCodec(this.collection, this.record) {
    if (record['schema'] != kCycleSchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) => throw CycleDefectException(
    CycleDefect(collection, record.id, field, reason),
  );

  LumeRecordId get id => LumeRecordId.tryParse(record.id) ?? fail('id', 'uuid');

  LumeDate? date(String field, {bool optional = false}) {
    final Object? v = record[field];
    if (v == null && optional) return null;
    if (v is! String) fail(field, 'missing');
    return LumeDate.tryParse(v) ?? fail(field, 'date');
  }
}

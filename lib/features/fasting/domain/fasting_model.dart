/// Fasting Tracker's stored records — one entry per day the reader logs a
/// fast for — and their codec to and from the record envelope.
///
/// **The reference invents every figure it shows.** `tools/islamic/
/// fasting.tool.js` is a pure display over `context.js`'s `fasting()`
/// (`:335-346`), which returns `kept: 8, target: 12, streak: 3, voluntary: 5,
/// obligatory: 3, missed: 1` — six bare literals with no schema behind any of
/// them — plus a `heatDays(30, 9182, 0.45)` calendar seeded from a fixed
/// random seed, and a four-row "recent" list whose `kept: true/false` values
/// are hand-typed literals (`{ label: t('common.yesterday'), kind:
/// t('fast.qada'), kept: true }` and so on), not a read of anything the
/// reader ever entered — there is nowhere in the reference for a reader to
/// log a fast at all. This model stores exactly what a reader can actually
/// tell Lume: which day they fasted (or attempted to and did not complete),
/// and whether it was a voluntary fast or one made up for a missed
/// obligatory one. Every figure Fasting Tracker shows beyond that — the
/// month's kept count, the current streak, the voluntary/obligatory/missed
/// breakdown, the calendar, the recent list — is a real derived calculation
/// over these records, in `fasting_book.dart`, never a stored field and
/// never a fixture.
///
/// **At most one entry per date.** Logging a second fast on an already-
/// logged day corrects that day's entry rather than creating a duplicate —
/// the write path enforces this the same way Cycle Tracker refuses two
/// periods starting on the same date.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

/// The stored schema — in every record, and in every export.
const String kFastingSchema = 'lume.fasting/1';

abstract final class FastingCollections {
  static const String entries = 'fasting.entry';
  static const List<String> all = <String>[entries];
}

/// The reference's own two kind values (`fast.sunnah` / `fast.qada`,
/// `fasting.tool.js:31-32`) — a voluntary fast the reader chose to keep, or
/// one kept to make up ("qada") a missed obligatory fast. There is no third
/// value: the reference's filter bar never offers one, and inventing an
/// obligatory-Ramadan-fast kind here would need a real Hijri calendar this
/// build does not have (see `fasting_book.dart`).
enum FastingKind { voluntary, makeup }

@immutable
class FastEntry {
  const FastEntry({
    required this.id,
    required this.date,
    required this.kind,
    required this.kept,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;

  /// The day this fast was for. Required — there is no entry without one.
  final LumeDate date;

  final FastingKind kind;

  /// Whether the reader completed the fast. `false` records an attempt that
  /// was broken or missed — never omitted, so the reference's own "Missed"
  /// stat and "Not kept" recent rows can be real counts of something the
  /// reader actually told Lume, not an invented complement of [kept] counts.
  final bool kept;

  final DateTime createdAt;
  final int version;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kFastingSchema,
    'date': date.toIso(),
    'kind': kind.name,
    'kept': kept,
  };

  FastEntry copyWith({LumeDate? date, FastingKind? kind, bool? kept}) =>
      FastEntry(
        id: id,
        date: date ?? this.date,
        kind: kind ?? this.kind,
        kept: kept ?? this.kept,
        createdAt: createdAt,
        version: version,
      );

  static FastEntry decode(LumeRecord r) {
    final FastingCodec c = FastingCodec(FastingCollections.entries, r);
    return FastEntry(
      id: c.id,
      date: c.date('date')!,
      kind: c.choice('kind', FastingKind.values),
      kept: c.flag('kept'),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FastEntry &&
      other.id == id &&
      other.date == date &&
      other.kind == kind &&
      other.kept == kept &&
      other.version == version;

  @override
  int get hashCode => Object.hash(id, date, kind, kept, version);
}

@immutable
class FastingDefect {
  const FastingDefect(this.collection, this.recordId, this.field, this.reason);

  final String collection;
  final String recordId;
  final String field;
  final String reason;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

@immutable
class FastingDefectException implements Exception {
  const FastingDefectException(this.defect);
  final FastingDefect defect;

  @override
  String toString() => 'FastingDefectException($defect)';
}

/// Strict decoding: a record that does not match [kFastingSchema] or whose
/// fields do not parse is a defect, reported and skipped — never silently
/// repaired and never allowed to crash the read.
class FastingCodec {
  FastingCodec(this.collection, this.record) {
    if (record['schema'] != kFastingSchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) => throw FastingDefectException(
    FastingDefect(collection, record.id, field, reason),
  );

  LumeRecordId get id => LumeRecordId.tryParse(record.id) ?? fail('id', 'uuid');

  LumeDate? date(String field, {bool optional = false}) {
    final Object? v = record[field];
    if (v == null && optional) return null;
    if (v is! String) fail(field, 'missing');
    return LumeDate.tryParse(v) ?? fail(field, 'date');
  }

  T choice<T extends Enum>(String field, List<T> values) {
    final Object? v = record[field];
    for (final T x in values) {
      if (x.name == v) return x;
    }
    fail(field, 'value');
  }

  bool flag(String field) {
    final Object? v = record[field];
    if (v is! bool) fail(field, 'type');
    return v;
  }
}

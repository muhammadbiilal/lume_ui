/// Prayer Tracker's stored records — which of the five daily prayers the
/// reader marked prayed, on which day — and their codec to and from the
/// record envelope.
///
/// **The reference has no real streak, month or qada at all.**
/// `praytrack.tool.js` draws a summary card, a "mark today" list, a 35-day
/// heatmap, a per-prayer bar chart and a qada meter, all from
/// `context.js`'s `prayerTracker()`:
///
/// ```js
/// function prayerTracker() {
///   var st = prayerState();
///   var set = prayerTimes();
///   var nowM = ...;
///   var done = set.filter(function (p) { return p.h * 60 + p.m <= nowM; }).length;
///   return {
///     doneToday: done, streak: 12, month: 0.86, qada: 7,
///     heat: heatDays(35, 4211, 0.35),
///     byPrayer: [28, 30, 26, 29, 24]
///   };
/// }
/// ```
///
/// Only `doneToday` is real there, and even it is the wrong real thing: it
/// counts prayers whose *time has passed today*, not prayers the reader
/// actually prayed — the reference has no log of what was actually done at
/// all. `streak: 12`, `month: 0.86`, `qada: 7`, the 35-day `heatDays(35,
/// 4211, 0.35)` heatmap (a seeded-random grid, never real days) and
/// `byPrayer: [28, 30, 26, 29, 24]` are every one of them bare literals with
/// nothing behind them in `record-schemas.js` — `praytrack` has no schema
/// there at all.
///
/// This build keeps the reference's five-prayer, five-figure composition,
/// and adds the one thing the reference never stored: a check-in per prayer,
/// per day, that the reader taps themselves. Every figure Prayer Tracker
/// shows — `doneToday`, the streak, the month rate, the qada backlog, the
/// 35-day heatmap and the per-prayer bar chart — is computed from those
/// check-ins in `praytrack_book.dart`, never a literal.
///
/// **At most one check-in per (day, prayer).** Marking an already-checked
/// prayer un-marks it — the toggle is the write, the same rule Habits' and
/// Daily Streak's own check-ins keep.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';

/// The stored schema — in every record.
const String kPrayTrackSchema = 'lume.praytrack/1';

abstract final class PrayTrackCollections {
  static const String checkins = 'praytrack.checkin';
  static const List<String> all = <String>[checkins];
}

/// The five daily prayers this tool tracks. Sunrise is deliberately not one
/// of them — the reference's own `prayerTimes()` filters it out
/// (`context.js:82-86`, `p.minor`) because it is shown, not prayed. Order
/// matches the reference's own `byPrayer` labels
/// (`['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']`, `praytrack.tool.js:45`)
/// and `LumeSolar.prayerTimes`'s own keys, so a prayer's real computed clock
/// time (§ below) matches it by name, never by position.
enum PrayerKey { fajr, dhuhr, asr, maghrib, isha }

/// One prayer the reader marked as prayed, on one day.
@immutable
class PrayerCheckin {
  const PrayerCheckin({
    required this.id,
    required this.date,
    required this.prayer,
    required this.createdAt,
    this.version = 1,
  });

  final LumeRecordId id;
  final LumeDate date;
  final PrayerKey prayer;
  final DateTime createdAt;
  final int version;

  Map<String, Object?> toFields() => <String, Object?>{
    'schema': kPrayTrackSchema,
    'date': date.toIso(),
    'prayer': prayer.name,
  };

  static PrayerCheckin decode(LumeRecord r) {
    final PrayTrackCodec c = PrayTrackCodec(PrayTrackCollections.checkins, r);
    return PrayerCheckin(
      id: c.id,
      date: c.date('date'),
      prayer: c.choice('prayer', PrayerKey.values),
      createdAt: r.createdAt,
      version: r.version,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PrayerCheckin &&
      other.id == id &&
      other.date == date &&
      other.prayer == prayer &&
      other.version == version;

  @override
  int get hashCode => Object.hash(id, date, prayer, version);
}

/// A record that could not be read as what its collection holds.
@immutable
class PrayTrackDefect {
  const PrayTrackDefect(
    this.collection,
    this.recordId,
    this.field,
    this.reason,
  );

  final String collection;
  final String recordId;
  final String field;

  /// A stable machine reason: `schema`, `missing`, `date`, `value` …
  final String reason;

  @override
  String toString() => '$collection/$recordId.$field: $reason';
}

/// Thrown by a decode; caught by whoever reads a collection.
@immutable
class PrayTrackDefectException implements Exception {
  const PrayTrackDefectException(this.defect);
  final PrayTrackDefect defect;

  @override
  String toString() => 'PrayTrackDefectException($defect)';
}

/// Strict field readers for one record.
class PrayTrackCodec {
  PrayTrackCodec(this.collection, this.record) {
    if (record['schema'] != kPrayTrackSchema) fail('schema', 'schema');
  }

  final String collection;
  final LumeRecord record;

  Never fail(String field, String reason) => throw PrayTrackDefectException(
    PrayTrackDefect(collection, record.id, field, reason),
  );

  LumeRecordId get id => LumeRecordId.tryParse(record.id) ?? fail('id', 'uuid');

  LumeDate date(String field) {
    final Object? v = record[field];
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
}

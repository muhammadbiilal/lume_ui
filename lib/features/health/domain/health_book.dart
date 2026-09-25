/// Everything Health Records shows, derived from the stored records — never
/// stored itself.
///
/// The reference computes a "days" figure and a chart series from records it
/// never actually keeps (`health.tool.js`). Here, [HealthRecordView.daysUntil]
/// is real arithmetic on the reader's own stored date, against the reader's
/// resolved day — never a hand-typed pair, and never shown without a `today`
/// to compute it from.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import 'health_model.dart';

/// One record with its date worked out against the reader's day.
@immutable
class HealthRecordView {
  const HealthRecordView._({required this.record, required this.daysUntil});

  final HealthRecord record;

  /// Whole days from the reader's day to [HealthRecord.date]; negative for a
  /// date already past. `null` without the reader's day.
  final int? daysUntil;

  LumeRecordId get id => record.id;

  /// The record's date is today or later. `false` without the reader's day —
  /// nothing is claimed "upcoming" when there is nothing to compare it to.
  bool get isUpcoming => daysUntil != null && daysUntil! >= 0;
}

@immutable
class HealthBook {
  const HealthBook._({
    required this.records,
    required this.defects,
    required this.today,
  });

  factory HealthBook.from({
    required List<HealthRecord> records,
    List<HealthDefect> defects = const <HealthDefect>[],
    required LumeDate? today,
  }) {
    final List<HealthRecordView> views = <HealthRecordView>[
      for (final HealthRecord r in records)
        HealthRecordView._(record: r, daysUntil: today?.daysUntil(r.date)),
    ];
    return HealthBook._(records: views, defects: defects, today: today);
  }

  final List<HealthRecordView> records;
  final List<HealthDefect> defects;
  final LumeDate? today;

  bool get isEmpty => records.isEmpty;
  int get totalCount => records.length;

  HealthRecordView? record(LumeRecordId id) {
    for (final HealthRecordView v in records) {
      if (v.id == id) return v;
    }
    return null;
  }

  /// Real counts per kind, for the filter chips — never a fabricated figure.
  Map<HealthRecordKind, int> get countsByKind {
    final Map<HealthRecordKind, int> out = <HealthRecordKind, int>{};
    for (final HealthRecordView v in records) {
      out[v.record.kind] = (out[v.record.kind] ?? 0) + 1;
    }
    return out;
  }

  /// How many of the reader's own records fall today or later. `null`
  /// without the reader's day, so the summary can say "—" rather than a
  /// false zero.
  int? get upcomingCount {
    if (today == null) return null;
    return records.where((HealthRecordView v) => v.isUpcoming).length;
  }

  /// The distinct kinds actually used, for the "Types" stat.
  int get kindsUsed => countsByKind.keys.length;
}

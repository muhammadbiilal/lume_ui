/// Everything Vaccinations shows, derived from the stored records — never
/// stored itself.
///
/// `overdue` is worked out from [VaccineRecord.date] against today, every
/// time — never a second stored flag that could disagree with the date
/// (the same discipline Subscriptions' `nextRenewal` and Meal Plan's
/// `filled` follow). Nothing here schedules anything: a due vaccination that
/// has passed its date is *shown* as overdue, never alerted on.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import 'vaccines_model.dart';

/// One vaccination with everything worked out from its record.
@immutable
class VaccineView {
  const VaccineView._({
    required this.record,
    required this.daysUntil,
    required this.overdue,
  });

  final VaccineRecord record;

  /// Whole days from today to [VaccineRecord.date]; negative when the date
  /// has passed. `null` without the reader's day.
  final int? daysUntil;

  /// Still due, and its date has passed. `null`-safe: `false` without
  /// today's date, never a guess.
  final bool overdue;

  VaccineStatus get status => record.status;
  bool get given => record.status == VaccineStatus.given;
}

@immutable
class VaccinesBook {
  const VaccinesBook._({
    required this.records,
    required this.defects,
    required this.today,
  });

  factory VaccinesBook.from({
    required List<VaccineRecord> records,
    List<VaccinesDefect> defects = const <VaccinesDefect>[],
    required LumeDate? today,
  }) {
    final List<VaccineView> views = <VaccineView>[
      for (final VaccineRecord r in records)
        VaccineView._(
          record: r,
          daysUntil: today?.daysUntil(r.date),
          overdue:
              today != null &&
              r.status == VaccineStatus.due &&
              r.date.isBefore(today),
        ),
    ];
    return VaccinesBook._(records: views, defects: defects, today: today);
  }

  final List<VaccineView> records;
  final List<VaccinesDefect> defects;
  final LumeDate? today;

  bool get isEmpty => records.isEmpty;
  int get total => records.length;
  int get givenCount => records.where((VaccineView v) => v.given).length;
  int get dueCount => records.where((VaccineView v) => !v.given).length;
  int get overdueCount => records.where((VaccineView v) => v.overdue).length;

  /// 0–1, for the summary's progress ring. `0` on an empty book, never a
  /// division by zero.
  double get progress => total == 0 ? 0 : givenCount / total;

  VaccineView? view(LumeRecordId id) {
    for (final VaccineView v in records) {
      if (v.record.id == id) return v;
    }
    return null;
  }

  /// Still-due vaccinations, soonest first — `null` without the reader's
  /// day, never sorted on a value that is not there.
  List<VaccineView>? upcoming({int count = 4}) {
    if (today == null) return null;
    final List<VaccineView> due =
        <VaccineView>[
          for (final VaccineView v in records)
            if (!v.given) v,
        ]..sort(
          (VaccineView a, VaccineView b) =>
              a.daysUntil!.compareTo(b.daysUntil!),
        );
    return due.take(count).toList();
  }
}

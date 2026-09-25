/// Everything Medication shows, derived from the stored records — never
/// stored itself.
///
/// No day, no zone, no clock: unlike Meal Plan or Subscriptions, nothing
/// here groups by the reader's calendar date or counts down to one, so
/// there is nothing that can be wrong about a timezone the reader has not
/// resolved. A medication's schedule and first-dose time are shown exactly
/// as typed.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';
import 'meds_model.dart';

/// One medication, in the order the reader added it.
@immutable
class MedsBook {
  const MedsBook._({required this.medications, required this.defects});

  factory MedsBook.from({
    required List<MedsEntry> medications,
    List<MedsDefect> defects = const <MedsDefect>[],
  }) {
    // Alphabetical by name, case-insensitive: predictable and stable, unlike
    // the store's own "newest write first" order, which would reorder a row
    // the reader is looking at the moment another one is edited.
    final List<MedsEntry> sorted = List<MedsEntry>.of(medications)
      ..sort(
        (MedsEntry a, MedsEntry b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    return MedsBook._(medications: sorted, defects: defects);
  }

  final List<MedsEntry> medications;
  final List<MedsDefect> defects;

  bool get isEmpty => medications.isEmpty;

  MedsEntry? medication(LumeRecordId id) {
    for (final MedsEntry m in medications) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Matches `record-schemas.js`'s own low-stock rule: `left > 0 && <= 3`.
  List<MedsEntry> get runningLow => <MedsEntry>[
    for (final MedsEntry m in medications)
      if (m.runningLow) m,
  ];
}

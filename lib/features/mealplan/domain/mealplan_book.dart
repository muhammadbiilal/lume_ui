/// Everything Meal Plan shows, derived from the stored records — never
/// stored itself (`MEALPLAN_PROPOSAL.md` §2).
///
/// `filled` replaces the reference's `planned: 18` literal with a real
/// count. Nothing here computes a calorie, a shopping-item count or a
/// cost — those are dropped entirely (D-M2), not approximated.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import 'mealplan_model.dart';

/// One calendar day's three slots, filled or not.
@immutable
class MealPlanDay {
  const MealPlanDay(this.date, this.today, this.entries);

  final LumeDate date;
  final bool today;

  /// By slot; a slot with no entry is absent from this map.
  final Map<MealSlot, MealPlanEntry> entries;

  MealPlanEntry? slot(MealSlot s) => entries[s];
  int get filledCount => entries.length;
}

@immutable
class MealPlanWeek {
  const MealPlanWeek._(this.days);

  /// The reader's today plus the next six days, matching the reference's
  /// own window (D-M3) — real calendar dates, not a template day-index.
  factory MealPlanWeek.from({
    required List<MealPlanEntry> entries,
    required LumeDate today,
  }) {
    final Map<LumeDate, Map<MealSlot, MealPlanEntry>> byDate =
        <LumeDate, Map<MealSlot, MealPlanEntry>>{};
    for (final MealPlanEntry e in entries) {
      (byDate[e.date] ??= <MealSlot, MealPlanEntry>{})[e.slot] = e;
    }
    final List<MealPlanDay> days = <MealPlanDay>[
      for (int i = 0; i < 7; i++)
        () {
          final LumeDate d = today.addDays(i);
          return MealPlanDay(d, i == 0, byDate[d] ?? const <MealSlot, MealPlanEntry>{});
        }(),
    ];
    return MealPlanWeek._(days);
  }

  final List<MealPlanDay> days;

  /// Of the 21 slots in view, how many the reader has filled in — real,
  /// replacing the reference's `planned: 18`.
  int get filled => days.fold(0, (int a, MealPlanDay d) => a + d.filledCount);

  static const int totalSlots = 21;
}

/// Small string mappings for Habits — no state, no logic beyond a lookup and
/// the choice of unit a habit's own cadence implies.
library;

import '../../../l10n/app_localizations.dart';
import '../domain/habits_model.dart';

abstract final class HabitsText {
  static String frequency(AppLocalizations l, HabitFrequency f) => switch (f) {
    HabitFrequency.daily => l.habitsFreqDaily,
    HabitFrequency.weekdays => l.habitsFreqWeekdays,
    HabitFrequency.weekly => l.habitsFreqWeekly,
  };

  /// "5 day streak" / "3 week streak" — the unit follows the habit's own
  /// cadence, never a bare number the reader has to interpret themselves.
  static String streakSentence(AppLocalizations l, HabitFrequency f, int n) =>
      f == HabitFrequency.weekly
      ? l.habitsStreakWeeks(n)
      : l.habitsStreakDays(n);

  /// "days" / "weeks" (or "day" / "week") — the bare unit word, for a figure
  /// that already carries its own number apart from the word.
  static String unit(AppLocalizations l, HabitFrequency f, int n) =>
      f == HabitFrequency.weekly ? l.habitsUnitWeeks(n) : l.habitsUnitDays(n);
}

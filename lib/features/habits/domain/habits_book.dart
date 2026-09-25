/// Everything Habits shows, derived from the stored records — never stored
/// itself.
///
/// ```text
/// currentStreak(habit) = consecutive required periods, ending at (or just
///                        before) today, each with a check-in
/// bestStreak(habit)    = the longest such run since the habit was made
/// completionRate(habit)= check-ins ÷ required periods since the habit was
///                        made, through today
/// ```
///
/// A "required period" is a calendar day for `daily` and `weekdays`
/// (weekends are never required, and never break a `weekdays` habit's
/// streak) and a calendar week for `weekly`. A habit not yet due today —
/// because today has not finished — never has its streak broken by an
/// empty "today": the streak counts backward from yesterday (or last week)
/// until today is actually checked or missed.
///
/// Every figure that needs "today" is `null` without the reader's day; a
/// habit whose check-ins cannot be trusted (an orphaned or malformed
/// check-in naming it) is **damaged**: listed, its figures not shown,
/// nothing written over it.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import 'habits_model.dart';

/// Why a habit's records cannot be trusted.
@immutable
class HabitsDamage {
  const HabitsDamage(this.habit, this.reason, [this.id]);

  /// The habit's id, as the records name it.
  final String habit;
  final String reason;

  /// The record at fault, when one is.
  final String? id;

  @override
  String toString() => '$habit: $reason${id == null ? '' : ' ($id)'}';
}

/// One habit, and everything worked out from its check-ins.
@immutable
class HabitView {
  const HabitView._({
    required this.habit,
    required this.checkinDates,
    required this.damage,
    required this.doneToday,
    required this.currentStreak,
    required this.bestStreak,
    required this.completionRate,
    required this.lastCheckin,
  });

  final Habit habit;

  /// Every date this habit was checked off, most recent first.
  final List<LumeDate> checkinDates;

  /// Why its records cannot be trusted, or `null`.
  final String? damage;
  bool get damaged => damage != null;

  /// Whether today has a check-in; `null` without the reader's day or when
  /// [damaged].
  final bool? doneToday;

  /// `null` without the reader's day or when [damaged].
  final int? currentStreak;

  /// Since the habit was made — `0` when [damaged], never guessed.
  final int bestStreak;

  /// 0–1, since the habit was made through today; `null` without the
  /// reader's day, when [damaged], or before the habit's first required
  /// day has passed.
  final double? completionRate;

  /// The most recent day checked off, or `null`.
  final LumeDate? lastCheckin;

  LumeRecordId get id => habit.id;
  HabitFrequency get frequency => habit.frequency;

  bool get hasStreak => (currentStreak ?? 0) > 0;
}

@immutable
class HabitsBook {
  const HabitsBook._({
    required this.habits,
    required this.defects,
    required this.damage,
    required this.today,
  });

  /// Derive the book from the reader's own records.
  factory HabitsBook.from({
    required List<Habit> habits,
    required List<HabitCheckin> checkins,
    List<HabitsDefect> defects = const <HabitsDefect>[],
    required LumeDate? today,
  }) {
    final Map<LumeRecordId, Habit> byId = <LumeRecordId, Habit>{
      for (final Habit h in habits) h.id: h,
    };
    final List<HabitsDamage> damage = <HabitsDamage>[];
    final Map<LumeRecordId, List<LumeDate>> ofHabit =
        <LumeRecordId, List<LumeDate>>{};
    for (final HabitCheckin c in checkins) {
      if (!byId.containsKey(c.habitId)) {
        damage.add(HabitsDamage(c.habitId.value, 'orphanCheckin', c.id.value));
        continue;
      }
      (ofHabit[c.habitId] ??= <LumeDate>[]).add(c.date);
    }
    final Set<String> defective = <String>{
      for (final HabitsDefect d in defects) ?d.habitId,
    };

    final List<HabitView> views = <HabitView>[];
    for (final Habit habit in habits) {
      final List<LumeDate> dates = <LumeDate>[...?ofHabit[habit.id]]
        ..sort((LumeDate a, LumeDate b) => b.compareTo(a));
      String? why;
      if (defective.contains(habit.id.value)) why = 'defect';
      if (why != null) damage.add(HabitsDamage(habit.id.value, why));

      final Set<LumeDate> dateSet = dates.toSet();
      final LumeDate created = LumeDate.ofWallClock(habit.createdAt);

      bool? doneToday;
      int? currentStreak;
      double? completionRate;
      if (why == null && today != null) {
        doneToday = dateSet.contains(today);
        currentStreak = _currentStreak(habit.frequency, dateSet, today);
        completionRate = _completionRate(
          habit.frequency,
          dateSet,
          created,
          today,
        );
      }
      final int best = why != null
          ? 0
          : _bestStreak(
              habit.frequency,
              dateSet,
              created,
              today ?? (dates.isEmpty ? created : dates.first),
            );

      views.add(
        HabitView._(
          habit: habit,
          checkinDates: dates,
          damage: why,
          doneToday: doneToday,
          currentStreak: currentStreak,
          bestStreak: best,
          completionRate: completionRate,
          lastCheckin: dates.isEmpty ? null : dates.first,
        ),
      );
    }
    return HabitsBook._(
      habits: views,
      defects: defects,
      damage: damage,
      today: today,
    );
  }

  final List<HabitView> habits;
  final List<HabitsDefect> defects;
  final List<HabitsDamage> damage;
  final LumeDate? today;

  bool get isEmpty => habits.isEmpty;
  bool get dayKnown => today != null;

  HabitView? habit(LumeRecordId id) {
    for (final HabitView h in habits) {
      if (h.habit.id == id) return h;
    }
    return null;
  }

  /// How many undamaged habits have a check-in today; `null` without the
  /// reader's day.
  int? get doneTodayCount {
    if (today == null) return null;
    int n = 0;
    for (final HabitView h in habits) {
      if (!h.damaged && (h.doneToday ?? false)) n++;
    }
    return n;
  }

  /// How many undamaged habits have a live streak right now; `null` without
  /// the reader's day.
  int? get activeStreakCount {
    if (today == null) return null;
    int n = 0;
    for (final HabitView h in habits) {
      if (!h.damaged && h.hasStreak) n++;
    }
    return n;
  }

  // ---- calendar helpers -----------------------------------------------

  static bool _isWeekend(LumeDate d) {
    final int wd = d.toCalendarDateTime().weekday;
    return wd == DateTime.saturday || wd == DateTime.sunday;
  }

  /// The Monday on or before [d].
  static LumeDate _weekStart(LumeDate d) {
    final int wd = d.toCalendarDateTime().weekday; // 1 Mon .. 7 Sun
    return d.addDays(-(wd - 1));
  }

  static bool _required(HabitFrequency f, LumeDate d) => switch (f) {
    HabitFrequency.daily => true,
    HabitFrequency.weekdays => !_isWeekend(d),
    // Weekly cadence is reckoned in whole weeks, not days; callers branch on
    // it before asking a single day whether it is "required".
    HabitFrequency.weekly => true,
  };

  // ---- streaks -----------------------------------------------------------

  static int _currentStreak(
    HabitFrequency f,
    Set<LumeDate> dates,
    LumeDate today,
  ) {
    if (f == HabitFrequency.weekly) {
      final Set<LumeDate> weeks = <LumeDate>{
        for (final LumeDate d in dates) _weekStart(d),
      };
      LumeDate? week = _weekStart(today);
      if (!weeks.contains(week)) week = _prevDays(week, 7);
      int n = 0;
      while (week != null && weeks.contains(week)) {
        n++;
        week = _prevDays(week, 7);
      }
      return n;
    }
    LumeDate? cursor = today;
    if (_required(f, cursor) && !dates.contains(cursor)) {
      cursor = _prevDays(cursor, 1);
    }
    int n = 0;
    while (cursor != null) {
      if (!_required(f, cursor)) {
        cursor = _prevDays(cursor, 1);
        continue;
      }
      if (!dates.contains(cursor)) break;
      n++;
      cursor = _prevDays(cursor, 1);
    }
    return n;
  }

  /// [d] minus [days], or `null` at the calendar's own floor (year 1)
  /// rather than letting a walk past it throw.
  static LumeDate? _prevDays(LumeDate d, int days) {
    try {
      return d.addDays(-days);
    } on LumeDateException {
      return null;
    }
  }

  static int _bestStreak(
    HabitFrequency f,
    Set<LumeDate> dates,
    LumeDate from,
    LumeDate to,
  ) {
    if (to.isBefore(from)) return 0;
    if (f == HabitFrequency.weekly) {
      final Set<LumeDate> weeks = <LumeDate>{
        for (final LumeDate d in dates) _weekStart(d),
      };
      int best = 0;
      int run = 0;
      LumeDate week = _weekStart(from);
      final LumeDate last = _weekStart(to);
      while (!week.isAfter(last)) {
        if (weeks.contains(week)) {
          run++;
          if (run > best) best = run;
        } else {
          run = 0;
        }
        week = week.addDays(7);
      }
      return best;
    }
    int best = 0;
    int run = 0;
    LumeDate d = from;
    while (!d.isAfter(to)) {
      if (_required(f, d)) {
        if (dates.contains(d)) {
          run++;
          if (run > best) best = run;
        } else {
          run = 0;
        }
      }
      d = d.addDays(1);
    }
    return best;
  }

  static double? _completionRate(
    HabitFrequency f,
    Set<LumeDate> dates,
    LumeDate from,
    LumeDate today,
  ) {
    if (today.isBefore(from)) return null;
    if (f == HabitFrequency.weekly) {
      final Set<LumeDate> weeks = <LumeDate>{
        for (final LumeDate d in dates) _weekStart(d),
      };
      LumeDate week = _weekStart(from);
      final LumeDate last = _weekStart(today);
      int total = 0;
      int done = 0;
      while (!week.isAfter(last)) {
        total++;
        if (weeks.contains(week)) done++;
        week = week.addDays(7);
      }
      return total == 0 ? null : done / total;
    }
    int total = 0;
    int done = 0;
    LumeDate d = from;
    while (!d.isAfter(today)) {
      if (_required(f, d)) {
        total++;
        if (dates.contains(d)) done++;
      }
      d = d.addDays(1);
    }
    return total == 0 ? null : done / total;
  }
}

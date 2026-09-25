/// Everything Daily Streak shows, computed from the reader's own check-in
/// dates — never stored itself.
///
/// The reference's `current: 12, best: 28, thisMonth: 21, rate: 0.78,
/// nextMilestone: 14` are bare literals with a random 35-day heat grid
/// behind them (`context.js:1609-1618`). Every figure here replaces one of
/// those literals with a real calculation over the reader's own check-ins:
/// [StreakStats.current] is a real consecutive-day count ending today or
/// yesterday, [StreakStats.best] the longest run ever recorded,
/// [StreakStats.thisMonth] a real count within the calendar month,
/// [StreakStats.rate] that count divided by the days elapsed so far this
/// month, and [StreakStats.heat] the reader's own last 35 days — never a
/// randomised fixture.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';

/// One day in the trailing 35-day window.
@immutable
class StreakHeatDay {
  const StreakHeatDay(this.date, this.checkedIn);

  final LumeDate date;
  final bool checkedIn;
}

/// One streak-length milestone and how it stands for the reader today.
@immutable
class StreakMilestone {
  const StreakMilestone({
    required this.threshold,
    required this.done,
    required this.inDays,
  });

  /// The streak length this milestone marks — 7, 14, 30 or 100 days.
  final int threshold;

  /// Whether the reader's current streak has already reached it.
  final bool done;

  /// Days of streak still needed to reach it. `0` once [done].
  final int inDays;
}

/// The reader's streak, computed fresh from their check-in dates every time
/// [StreakStats.compute] is called — nothing here is cached or stored.
@immutable
class StreakStats {
  const StreakStats({
    required this.checkedInToday,
    required this.current,
    required this.best,
    required this.thisMonth,
    required this.rate,
    required this.nextMilestone,
    required this.heat,
    required this.milestones,
  });

  /// Whether today already has a check-in.
  final bool checkedInToday;

  /// The current run of consecutive days, ending today if checked in today,
  /// otherwise ending yesterday. A day missed today does not zero this out
  /// until tomorrow passes with still nothing logged.
  final int current;

  /// The longest run of consecutive days the reader has ever recorded,
  /// including the current run if it is the longest.
  final int best;

  /// Check-ins within the calendar month [heat]'s last day falls in.
  final int thisMonth;

  /// [thisMonth] divided by the number of days elapsed in that month so
  /// far — `0` to `1`.
  final double rate;

  /// The next not-yet-reached entry in [milestoneThresholds], or `null` once
  /// the reader has passed every one of them.
  final int? nextMilestone;

  /// The trailing 35 days, oldest first, ending today.
  final List<StreakHeatDay> heat;

  final List<StreakMilestone> milestones;

  /// 7, 14, 30 and 100 days — the reference's own thresholds
  /// (`context.js:1613-1616`).
  static const List<int> milestoneThresholds = <int>[7, 14, 30, 100];

  static const int heatWindow = 35;

  factory StreakStats.compute({
    required Set<LumeDate> checkIns,
    required LumeDate today,
  }) {
    final bool checkedInToday = checkIns.contains(today);
    final int current = _currentStreak(checkIns, today);
    final int best = _bestStreak(checkIns, current);
    final int thisMonth = checkIns
        .where((LumeDate d) => d.year == today.year && d.month == today.month)
        .length;
    final double rate = today.day == 0 ? 0 : thisMonth / today.day;

    final List<StreakHeatDay> heat = <StreakHeatDay>[
      for (int i = heatWindow - 1; i >= 0; i--)
        () {
          final LumeDate d = today.addDays(-i);
          return StreakHeatDay(d, checkIns.contains(d));
        }(),
    ];

    final List<StreakMilestone> milestones = <StreakMilestone>[
      for (final int t in milestoneThresholds)
        StreakMilestone(
          threshold: t,
          done: current >= t,
          inDays: current >= t ? 0 : t - current,
        ),
    ];
    int? nextMilestone;
    for (final StreakMilestone m in milestones) {
      if (!m.done) {
        nextMilestone = m.threshold;
        break;
      }
    }

    return StreakStats(
      checkedInToday: checkedInToday,
      current: current,
      best: best,
      thisMonth: thisMonth,
      rate: rate.clamp(0, 1),
      nextMilestone: nextMilestone,
      heat: heat,
      milestones: milestones,
    );
  }

  /// The run of consecutive days ending today (if checked in today) or
  /// yesterday (if not) — a day not yet logged today does not reset the
  /// streak until tomorrow arrives with it still missing.
  static int _currentStreak(Set<LumeDate> checkIns, LumeDate today) {
    LumeDate cursor = checkIns.contains(today) ? today : today.addDays(-1);
    int n = 0;
    while (checkIns.contains(cursor)) {
      n++;
      cursor = cursor.addDays(-1);
    }
    return n;
  }

  /// The longest run of consecutive dates ever recorded.
  static int _bestStreak(Set<LumeDate> checkIns, int current) {
    if (checkIns.isEmpty) return 0;
    final List<LumeDate> sorted = checkIns.toList()..sort();
    int best = 1;
    int run = 1;
    for (int i = 1; i < sorted.length; i++) {
      run = sorted[i - 1].daysUntil(sorted[i]) == 1 ? run + 1 : 1;
      if (run > best) best = run;
    }
    return best > current ? best : current;
  }
}

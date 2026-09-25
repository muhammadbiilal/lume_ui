/// Everything Prayer Tracker shows, computed from the reader's own
/// check-ins — never stored itself.
///
/// The reference's `streak: 12, month: 0.86, qada: 7`, its 35-day
/// `heatDays(35, 4211, 0.35)` grid and its `byPrayer: [28, 30, 26, 29, 24]`
/// bar chart are bare literals (`context.js` `prayerTracker()`,
/// `praytrack_model.dart`'s own doc has the full quote). Every one of those
/// five figures is replaced here with a real calculation over the dates and
/// prayers the reader actually checked off:
///
/// * [PrayTrackStats.currentStreak] — consecutive **complete** days (all
///   five prayers checked) ending today, or yesterday if today is not
///   complete yet — the same "today is not over yet" rule Habits' and Daily
///   Streak's own streaks already use.
/// * [PrayTrackStats.bestStreak] — the longest such run ever, walked day by
///   day from the reader's first check-in through today.
/// * [PrayTrackStats.monthRate] — prayers checked this calendar month,
///   divided by five times the days elapsed so far (Daily Streak's own
///   `rate` shape, `today.day` as the denominator's day count).
/// * [PrayTrackStats.qada] — prayers **not** checked, on a day strictly
///   before today, from the reader's first check-in onward: a real backlog
///   of unmarked prayers, never the reference's unexplained `7`. Before any
///   check-in exists there is nothing to be behind on, so this starts at
///   `0` — never a fabricated starting balance.
/// * [PrayTrackStats.heat] — the reader's own last 35 days, bucketed by how
///   many of the five prayers were checked that day (`0` → none, `1`-`2` →
///   some, `3`-`4` → most, `5` → all) — never a random seed.
/// * [PrayTrackStats.byPrayer] — how many of the last 35 days each prayer was
///   checked, counted from the same check-ins.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import 'praytrack_model.dart';

/// One day in the trailing heat window.
@immutable
class PrayTrackHeatDay {
  const PrayTrackHeatDay(this.date, this.count, this.level);

  final LumeDate date;

  /// How many of the five prayers were checked, `0`-`5`.
  final int count;

  /// `count` bucketed to the heatmap's four levels: `0` none, `1` some
  /// (`1`-`2`), `2` most (`3`-`4`), `3` all (`5`).
  final int level;
}

/// The reader's Prayer Tracker figures, computed fresh from their check-ins
/// every time [PrayTrackStats.compute] is called — nothing here is cached or
/// stored.
@immutable
class PrayTrackStats {
  const PrayTrackStats({
    required this.today,
    required this.doneToday,
    required this.currentStreak,
    required this.bestStreak,
    required this.monthDone,
    required this.monthRate,
    required this.historyDone,
    required this.qada,
    required this.heat,
    required this.byPrayer,
  });

  final LumeDate today;

  /// Which of the five prayers already have a check-in today.
  final Set<PrayerKey> doneToday;

  /// Consecutive complete days (§ above), ending today or yesterday.
  final int currentStreak;

  /// The longest run of complete days ever recorded.
  final int bestStreak;

  /// Prayers checked within [today]'s calendar month, through today.
  final int monthDone;

  /// [monthDone] divided by five times the days elapsed this month — `0` to
  /// `1`.
  final double monthRate;

  /// Prayers checked on a day before today, since the first check-in — the
  /// same window [qada] is counted over, so `historyDone + qada` is the
  /// total number of prayers the reader has been asked for since they
  /// started, and `historyDone / (historyDone + qada)` is their real
  /// lifetime completion rate. `0` with no check-in history at all.
  final int historyDone;

  /// Prayers left unchecked on a day before today, since the first
  /// check-in. `0` with no check-in history at all.
  final int qada;

  /// The trailing 35 days, oldest first, ending today.
  final List<PrayTrackHeatDay> heat;

  /// How many days, within [heat]'s window, each prayer was checked.
  final Map<PrayerKey, int> byPrayer;

  static const int heatWindow = 35;

  bool isDoneToday(PrayerKey k) => doneToday.contains(k);

  factory PrayTrackStats.compute({
    required Map<LumeDate, Set<PrayerKey>> byDate,
    required LumeDate today,
  }) {
    Set<PrayerKey> on(LumeDate d) => byDate[d] ?? const <PrayerKey>{};
    bool complete(LumeDate d) => on(d).length == PrayerKey.values.length;

    final Set<PrayerKey> doneToday = on(today);

    // -- current streak: complete days ending today, or yesterday if today
    // is not (yet) complete.
    LumeDate cursor = complete(today) ? today : today.addDays(-1);
    int current = 0;
    while (complete(cursor)) {
      current++;
      cursor = cursor.addDays(-1);
    }

    final List<LumeDate> touched = byDate.keys.toList()..sort();

    // -- best streak, historyDone and qada all walk from the first day the
    // reader ever touched this tracker; before that, there is nothing to
    // score. historyDone and qada share the same before-today window, so
    // together they are the total the reader has ever been asked for.
    int best = 0;
    int historyDone = 0;
    int qada = 0;
    if (touched.isNotEmpty) {
      final LumeDate from = touched.first;
      int run = 0;
      LumeDate d = from;
      while (!d.isAfter(today)) {
        if (complete(d)) {
          run++;
          if (run > best) best = run;
        } else {
          run = 0;
        }
        if (d.isBefore(today)) {
          final int count = on(d).length;
          historyDone += count;
          qada += PrayerKey.values.length - count;
        }
        d = d.addDays(1);
      }
    }
    if (best < current) best = current;

    // -- this month, through today.
    int monthDone = 0;
    for (int day = 1; day <= today.day; day++) {
      monthDone += on(LumeDate(today.year, today.month, day)).length;
    }
    final int monthPossible = today.day * PrayerKey.values.length;
    final double monthRate = monthPossible == 0
        ? 0
        : (monthDone / monthPossible).clamp(0, 1);

    // -- the trailing window: heat and per-prayer counts.
    final List<PrayTrackHeatDay> heat = <PrayTrackHeatDay>[
      for (int i = heatWindow - 1; i >= 0; i--)
        () {
          final LumeDate d = today.addDays(-i);
          final int count = on(d).length;
          final int level = count == 0
              ? 0
              : count <= 2
              ? 1
              : count <= 4
              ? 2
              : 3;
          return PrayTrackHeatDay(d, count, level);
        }(),
    ];
    final Map<PrayerKey, int> byPrayer = <PrayerKey, int>{
      for (final PrayerKey k in PrayerKey.values)
        k: heat.where((PrayTrackHeatDay h) => on(h.date).contains(k)).length,
    };

    return PrayTrackStats(
      today: today,
      doneToday: doneToday,
      currentStreak: current,
      bestStreak: best,
      monthDone: monthDone,
      monthRate: monthRate,
      historyDone: historyDone,
      qada: qada,
      heat: heat,
      byPrayer: byPrayer,
    );
  }
}

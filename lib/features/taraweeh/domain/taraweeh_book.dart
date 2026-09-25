/// Everything Taraweeh shows, computed from the reader's own logged
/// nights — never stored itself.
///
/// The reference has no figures like these at all to replace: its
/// `nearbyMosques()` fixture carries a start time and a rakaat count per
/// invented mosque, not a streak or a completion count (see
/// `taraweeh_model.dart`). [TaraweehStats.current] and [TaraweehStats.best]
/// use the exact same real consecutive-night calculation Daily Streak's
/// [StreakStats] does, over the reader's own dates. [TaraweehStats.juzDone]
/// and [TaraweehStats.progress] are new to this feature and equally real: the
/// distinct Juz numbers the reader has actually logged against a night,
/// never a random or seeded fixture.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import 'taraweeh_model.dart';

/// One day in the trailing 35-day window.
@immutable
class TaraweehHeatDay {
  const TaraweehHeatDay(this.date, this.prayed);

  final LumeDate date;
  final bool prayed;
}

/// The reader's Taraweeh, computed fresh from their logged nights every time
/// [TaraweehStats.compute] is called — nothing here is cached or stored.
@immutable
class TaraweehStats {
  const TaraweehStats({
    required this.prayedTonight,
    required this.tonight,
    required this.current,
    required this.best,
    required this.totalNights,
    required this.juzDone,
    required this.progress,
    required this.nextJuz,
    required this.heat,
  });

  /// Whether tonight already has an entry.
  final bool prayedTonight;

  /// Tonight's own entry, when one has been logged.
  final TaraweehNight? tonight;

  /// The current run of consecutive nights, ending tonight if logged,
  /// otherwise last night. A night not yet logged tonight does not reset the
  /// streak until tomorrow passes with it still missing — the same rule
  /// Daily Streak's [current](StreakStats.current) keeps.
  final int current;

  /// The longest run of consecutive nights ever recorded, including the
  /// current run if it is the longest.
  final int best;

  /// How many nights the reader has ever logged, in total.
  final int totalNights;

  /// The distinct Juz numbers (1–30) the reader has logged against any
  /// night — a Juz noted twice counts once.
  final int juzDone;

  /// [juzDone] divided by the Qur'an's 30 Juz — `0` to `1`.
  final double progress;

  /// The lowest Juz (1–30) not yet logged, or `null` once every one of the
  /// 30 has been.
  final int? nextJuz;

  /// The trailing 35 nights, oldest first, ending tonight.
  final List<TaraweehHeatDay> heat;

  static const int heatWindow = 35;

  bool get khatmComplete => juzDone >= kTaraweehJuzMax;

  factory TaraweehStats.compute({
    required List<TaraweehNight> nights,
    required LumeDate today,
  }) {
    final Map<LumeDate, TaraweehNight> byDate = <LumeDate, TaraweehNight>{
      for (final TaraweehNight n in nights) n.date: n,
    };
    final Set<LumeDate> dates = byDate.keys.toSet();
    final TaraweehNight? tonight = byDate[today];
    final int current = _currentStreak(dates, today);
    final int best = _bestStreak(dates, current);

    final Set<int> juzSeen = <int>{
      for (final TaraweehNight n in nights)
        if (n.juz != null) n.juz!,
    };
    final int juzDone = juzSeen.length;
    int? nextJuz;
    for (int j = kTaraweehJuzMin; j <= kTaraweehJuzMax; j++) {
      if (!juzSeen.contains(j)) {
        nextJuz = j;
        break;
      }
    }

    final List<TaraweehHeatDay> heat = <TaraweehHeatDay>[
      for (int i = heatWindow - 1; i >= 0; i--)
        () {
          final LumeDate d = today.addDays(-i);
          return TaraweehHeatDay(d, dates.contains(d));
        }(),
    ];

    return TaraweehStats(
      prayedTonight: tonight != null,
      tonight: tonight,
      current: current,
      best: best,
      totalNights: nights.length,
      juzDone: juzDone,
      progress: (juzDone / kTaraweehJuzMax).clamp(0, 1),
      nextJuz: nextJuz,
      heat: heat,
    );
  }

  /// The run of consecutive nights ending tonight (if logged) or last night
  /// (if not) — a night not yet logged tonight does not reset the streak
  /// until tomorrow arrives with it still missing.
  static int _currentStreak(Set<LumeDate> dates, LumeDate today) {
    LumeDate cursor = dates.contains(today) ? today : today.addDays(-1);
    int n = 0;
    while (dates.contains(cursor)) {
      n++;
      cursor = cursor.addDays(-1);
    }
    return n;
  }

  /// The longest run of consecutive dates ever recorded.
  static int _bestStreak(Set<LumeDate> dates, int current) {
    if (dates.isEmpty) return 0;
    final List<LumeDate> sorted = dates.toList()..sort();
    int best = 1;
    int run = 1;
    for (int i = 1; i < sorted.length; i++) {
      run = sorted[i - 1].daysUntil(sorted[i]) == 1 ? run + 1 : 1;
      if (run > best) best = run;
    }
    return best > current ? best : current;
  }
}

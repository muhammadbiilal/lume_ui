/// Everything Fasting Tracker shows, derived from the reader's own logged
/// fasts — never stored itself.
///
/// The reference's `context.js` `fasting()` (`:335-346`) returns `kept: 8,
/// target: 12, streak: 3, voluntary: 5, obligatory: 3, missed: 1` — six bare
/// literals, none computed from anything — beside a random-seeded 30-day
/// heatmap and a four-row "recent" list of hand-typed `kept: true/false`
/// values. Every one of those is replaced here with a real calculation over
/// [FastEntry]s the reader actually logged:
///
/// - `kept` (the reference's month figure) → [FastingInsights.keptThisMonth],
///   entries kept within the current calendar month.
/// - `streak` → [FastingInsights.currentStreak], the run of consecutive kept
///   entries counting back from the reader's most recently logged day —
///   never a calendar-day walk, because a voluntary fast is not expected
///   every day, only a walk over the days the reader actually logged.
/// - `voluntary` / `obligatory` / `missed` →
///   [FastingInsights.voluntaryKept], [FastingInsights.makeupKept] and
///   [FastingInsights.missedCount], real counts by [FastingKind] and by
///   [FastEntry.kept].
/// - `target` (the reference's `f.kept / f.target` progress ring) is
///   **dropped, not replaced** — `target: 12` is a bare literal, and there is
///   no honest denominator this build can put in its place. A Ramadan-day
///   target would need a real Hijri calendar, which `lib/features/hijri/`
///   does not yet provide in this codebase (checked directly; not assumed).
///   [FastingInsights.completionRate] — kept ÷ logged, over the reader's own
///   attempts — replaces the ring's meaning without claiming a fixed goal
///   the reference never actually computed either.
/// - `heat` → [FastingInsights.heat], the reader's own trailing 30 days,
///   never a randomised fixture.
/// - `recent` → [FastingInsights.recent], every logged entry, most recent
///   first — a real list, not four literals.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import 'fasting_model.dart';

/// One day in the trailing calendar window: [FastEntry] logged as kept,
/// logged as not kept, or never logged at all.
enum FastingDayState { none, kept, missed }

@immutable
class FastingHeatDay {
  const FastingHeatDay(this.date, this.state);

  final LumeDate date;
  final FastingDayState state;
}

@immutable
class FastingInsights {
  const FastingInsights({
    required this.today,
    required this.loggedCount,
    required this.keptCount,
    required this.missedCount,
    required this.keptThisMonth,
    required this.voluntaryKept,
    required this.makeupKept,
    required this.currentStreak,
    required this.recent,
    required this.heat,
    this.completionRate,
  });

  factory FastingInsights.empty(LumeDate today) => FastingInsights(
    today: today,
    loggedCount: 0,
    keptCount: 0,
    missedCount: 0,
    keptThisMonth: 0,
    voluntaryKept: 0,
    makeupKept: 0,
    currentStreak: 0,
    recent: const <FastEntry>[],
    heat: _heatWindow(const <LumeDate, FastEntry>{}, today),
  );

  final LumeDate today;

  /// How many fasts the reader has logged in total, kept or not.
  final int loggedCount;

  /// Logged entries where [FastEntry.kept] is `true`, all time.
  final int keptCount;

  /// Logged entries where [FastEntry.kept] is `false`, all time — a real
  /// count of days the reader told Lume they did not complete, never an
  /// invented complement of [keptCount].
  final int missedCount;

  /// Kept entries whose date falls in [today]'s calendar month — the
  /// reference's own "This month" kicker, worked out for real.
  final int keptThisMonth;

  /// Kept entries logged as [FastingKind.voluntary].
  final int voluntaryKept;

  /// Kept entries logged as [FastingKind.makeup].
  final int makeupKept;

  /// The run of consecutive kept entries counting back from the most
  /// recently logged date — `0` when there are no logged entries, or the
  /// most recent one was not kept.
  final int currentStreak;

  /// `keptCount` ÷ `loggedCount`. `null` until at least one fast is logged —
  /// never a ratio against the reference's invented fixed target.
  final double? completionRate;

  /// Every logged entry, most recent date first.
  final List<FastEntry> recent;

  /// The reader's own last 30 days, oldest first, ending [today] — the
  /// reference's own window (`context.js:338`), over real entries.
  final List<FastingHeatDay> heat;

  static const int heatWindowDays = 30;

  bool get isEmpty => loggedCount == 0;

  /// The one entry point. Pure: the same [entries] and [today] always
  /// produce the same [FastingInsights] — nothing here reads a clock or a
  /// random source of its own.
  factory FastingInsights.compute({
    required List<FastEntry> entries,
    required LumeDate today,
  }) {
    if (entries.isEmpty) return FastingInsights.empty(today);

    final List<FastEntry> sortedDesc = List<FastEntry>.of(entries)
      ..sort((FastEntry a, FastEntry b) => b.date.compareTo(a.date));

    int keptCount = 0;
    int missedCount = 0;
    int keptThisMonth = 0;
    int voluntaryKept = 0;
    int makeupKept = 0;
    for (final FastEntry e in sortedDesc) {
      if (e.kept) {
        keptCount++;
        if (e.date.year == today.year && e.date.month == today.month) {
          keptThisMonth++;
        }
        switch (e.kind) {
          case FastingKind.voluntary:
            voluntaryKept++;
          case FastingKind.makeup:
            makeupKept++;
        }
      } else {
        missedCount++;
      }
    }

    int streak = 0;
    for (final FastEntry e in sortedDesc) {
      if (!e.kept) break;
      streak++;
    }

    final double completionRate = keptCount / entries.length;

    final Map<LumeDate, FastEntry> byDate = <LumeDate, FastEntry>{
      for (final FastEntry e in entries) e.date: e,
    };

    return FastingInsights(
      today: today,
      loggedCount: entries.length,
      keptCount: keptCount,
      missedCount: missedCount,
      keptThisMonth: keptThisMonth,
      voluntaryKept: voluntaryKept,
      makeupKept: makeupKept,
      currentStreak: streak,
      completionRate: completionRate,
      recent: sortedDesc,
      heat: _heatWindow(byDate, today),
    );
  }

  static List<FastingHeatDay> _heatWindow(
    Map<LumeDate, FastEntry> byDate,
    LumeDate today,
  ) => <FastingHeatDay>[
    for (int i = heatWindowDays - 1; i >= 0; i--)
      () {
        final LumeDate d = today.addDays(-i);
        final FastEntry? e = byDate[d];
        final FastingDayState state = e == null
            ? FastingDayState.none
            : (e.kept ? FastingDayState.kept : FastingDayState.missed);
        return FastingHeatDay(d, state);
      }(),
  ];
}

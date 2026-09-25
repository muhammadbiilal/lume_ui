/// Everything Cycle Tracker shows, derived from the reader's own logged
/// periods — never stored itself.
///
/// The reference's `context.js` `cycle()` (`:1714-1726`) returns
/// `day: (new Date().getDate() % 28) + 1` — today's day-of-month wrapped at
/// 28, which is not a cycle day for anybody — beside a hard-coded
/// `length: 28` and three months of fixture history whose lengths (28, 29,
/// 27) and captions ("Regular" every time) are bare literals with nothing
/// behind them. None of that is reproduced: a day-of-month is not a cycle
/// day, and a fixture is not history.
///
/// What is reproduced is the reference's own *shape* — a day within a
/// length, a phase named from where that day falls, and a short history of
/// past cycle lengths — computed for real from what the reader has logged.
/// [CycleBook.compute] is a pure function of the reader's own dates: it does
/// not run until there is at least one logged period, it does not predict
/// anything until there are at least two (one real interval to average),
/// and it never claims more certainty than that — every value here is an
/// estimate from the reader's own history, not a diagnosis or a promise.
library;

import '../../../core/values/lume_date.dart';
import 'cycle_model.dart';

/// Where in the cycle [CycleInsights.currentDay] falls, once an average
/// length is known. Named and bounded exactly as the reference's own
/// thresholds are (`day <= 5`, `<= 13`, `<= 16`, else) — scaled to the
/// reader's real average length instead of the reference's fixed 28,
/// because a reader's cycle is rarely exactly 28 days.
enum CyclePhase { menstrual, follicular, ovulation, luteal }

/// One completed cycle in the reader's history: a past period, and the real
/// number of days until the one that followed it — never the reference's
/// literal 28/29/27.
class CycleHistoryEntry {
  const CycleHistoryEntry({
    required this.start,
    required this.length,
    this.end,
  });

  final LumeDate start;
  final LumeDate? end;

  /// Days from this period's start to the next one's — a real interval, from
  /// the reader's own two logged dates.
  final int length;
}

/// The reference's `cycle.day / cycle.length / cycle.phaseLabel /
/// cycle.history`, worked out for real over [CycleBook.compute]'s input.
class CycleInsights {
  const CycleInsights({
    required this.today,
    required this.loggedCount,
    this.currentPeriod,
    this.currentDay,
    this.averageLength,
    this.predictedNextStart,
    this.phase,
    this.daysUntilNext,
    this.history = const <CycleHistoryEntry>[],
  });

  factory CycleInsights.empty(LumeDate today) =>
      CycleInsights(today: today, loggedCount: 0);

  final LumeDate today;

  /// How many periods the reader has logged in total.
  final int loggedCount;

  /// The most recently started logged period — what [currentDay] counts
  /// from, whether or not its bleeding has ended yet.
  final CyclePeriod? currentPeriod;

  /// Day 1 is [CyclePeriod.startDate] itself. `null` only when there is no
  /// logged period to count from, or it is dated after [today].
  final int? currentDay;

  /// The mean of every interval between two consecutive logged starts, in
  /// days. `null` until there are at least two logged periods — one
  /// interval is the least a mean can be taken over.
  final double? averageLength;

  /// [currentPeriod]'s start plus [averageLength], rounded — an estimate,
  /// never a schedule. `null` wherever [averageLength] is.
  final LumeDate? predictedNextStart;

  /// `null` until [averageLength] and [currentDay] are both known.
  final CyclePhase? phase;

  /// Days from [today] to [predictedNextStart]; negative once that date has
  /// passed without a new period being logged. `null` wherever
  /// [predictedNextStart] is.
  final int? daysUntilNext;

  /// Completed cycles, most recent first. Empty until a second period has
  /// been logged.
  final List<CycleHistoryEntry> history;

  bool get hasPrediction => averageLength != null;
  bool get isOngoing => currentPeriod?.ongoing ?? false;
  bool get isOverdue => (daysUntilNext ?? 0) < 0;
  int? get overdueByDays => isOverdue ? -daysUntilNext! : null;
  int? get averageLengthRounded => averageLength?.round();

  /// The reference's own phase thresholds (`day <= 5/13/16`, else), scaled
  /// from its fixed 28 onto a real [len] — so a 32-day cycle's menstrual
  /// window is proportionally wider than a 24-day one's, rather than reusing
  /// the reference's absolute day counts on a length they were never meant
  /// for.
  static CyclePhase phaseFor(int day, int len) {
    final int safeLen = len < 1 ? 1 : len;
    final int menstrualEnd = _scaled(5, safeLen).clamp(1, safeLen);
    final int follicularEnd = _scaled(13, safeLen).clamp(menstrualEnd, safeLen);
    final int ovulationEnd = _scaled(16, safeLen).clamp(follicularEnd, safeLen);
    if (day <= menstrualEnd) return CyclePhase.menstrual;
    if (day <= follicularEnd) return CyclePhase.follicular;
    if (day <= ovulationEnd) return CyclePhase.ovulation;
    return CyclePhase.luteal;
  }

  static int _scaled(int referenceDay, int len) =>
      (referenceDay * len / 28).round();

  /// The one entry point. Pure: the same [periods] and [today] always
  /// produce the same [CycleInsights] — nothing here reads a clock or a
  /// random source of its own.
  factory CycleInsights.compute({
    required List<CyclePeriod> periods,
    required LumeDate today,
  }) {
    if (periods.isEmpty) return CycleInsights.empty(today);

    final List<CyclePeriod> sorted = List<CyclePeriod>.of(periods)
      ..sort(
        (CyclePeriod a, CyclePeriod b) => a.startDate.compareTo(b.startDate),
      );
    final CyclePeriod current = sorted.last;

    final int sinceStart = current.startDate.daysUntil(today);
    final int? currentDay = sinceStart >= 0 ? sinceStart + 1 : null;

    // Real intervals only: two consecutive logged starts, in order. A
    // caller that (against the repository's own rule) ever handed in two
    // periods on the same day contributes nothing rather than skewing the
    // average with a zero or negative span.
    final List<int> intervals = <int>[];
    final List<CycleHistoryEntry> history = <CycleHistoryEntry>[];
    for (int i = 0; i < sorted.length - 1; i++) {
      final int span = sorted[i].startDate.daysUntil(sorted[i + 1].startDate);
      if (span <= 0) continue;
      intervals.add(span);
      history.add(
        CycleHistoryEntry(
          start: sorted[i].startDate,
          end: sorted[i].endDate,
          length: span,
        ),
      );
    }
    history.sort(
      (CycleHistoryEntry a, CycleHistoryEntry b) => b.start.compareTo(a.start),
    );

    final double? averageLength = intervals.isEmpty
        ? null
        : intervals.reduce((int a, int b) => a + b) / intervals.length;

    final LumeDate? predictedNextStart = averageLength == null
        ? null
        : current.startDate.addDays(averageLength.round());

    final int? daysUntilNext = predictedNextStart == null
        ? null
        : today.daysUntil(predictedNextStart);

    final CyclePhase? phase = (averageLength == null || currentDay == null)
        ? null
        : phaseFor(currentDay, averageLength.round());

    return CycleInsights(
      today: today,
      loggedCount: sorted.length,
      currentPeriod: current,
      currentDay: currentDay,
      averageLength: averageLength,
      predictedNextStart: predictedNextStart,
      phase: phase,
      daysUntilNext: daysUntilNext,
      history: history,
    );
  }
}

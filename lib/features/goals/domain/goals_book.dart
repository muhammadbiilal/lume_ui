/// Everything Goals shows, derived from the stored records — never stored
/// itself (`GOALS_PROPOSAL.md` §2).
///
/// ```text
/// saved(goal)     = Σ goal's own active contributions
/// pct(goal)       = saved / target
/// remaining(goal) = max(0, target − saved)
/// projected(goal) = months to reach target at the goal's own pace since
///                   it was created, or null before a month of history
///                   exists — never the reference's fabricated chart
/// ```
///
/// A goal whose records break the rules is **damaged**: listed with the
/// reason, its figures not trusted, nothing written over it.
///
/// The reader's day is an input, needed for "this month's contributions"
/// and a goal's projection. Without it, both are unknown, not guessed.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import 'goals_model.dart';

/// Why a goal's records cannot be trusted.
@immutable
class GoalsDamage {
  const GoalsDamage(this.goal, this.reason, [this.id]);

  /// The goal's id as the records name it.
  final String goal;
  final String reason;

  /// The record at fault, when one is.
  final String? id;

  @override
  String toString() => '$goal: $reason${id == null ? '' : ' ($id)'}';
}

/// One goal, and everything worked out from its records.
@immutable
class GoalView {
  const GoalView._({
    required this.goal,
    required this.contributions,
    required this.damage,
    required this.saved,
    required this.projectedMonths,
    required this.lastActivity,
  });

  final Goal goal;

  /// Active contributions, newest first.
  final List<GoalContribution> contributions;

  /// Why its records cannot be trusted, or `null`.
  final String? damage;

  /// Σ active contributions.
  final LumeMoney saved;

  /// Months to reach the target at this goal's own pace since it was
  /// created, or `null` when there is not yet a month of history to pace
  /// from, or the goal has no target date to project against.
  final int? projectedMonths;

  /// The latest creation instant among the goal and its contributions —
  /// real timestamps only.
  final DateTime lastActivity;

  bool get damaged => damage != null;
  LumeCurrency get currency => goal.currency;
  LumeMoney get target => goal.target;

  LumeMoney get remaining {
    final LumeMoney r = target - saved;
    return r.isNegative ? LumeMoney.zero(currency) : r;
  }

  /// 0–1, and beyond 1 when the goal is over-saved.
  double get pct => target.isZero ? 0 : saved.minor / target.minor;

  bool get reached => saved.compareTo(target) >= 0;
}

/// The figures of one currency.
@immutable
class GoalsCurrencySummary {
  const GoalsCurrencySummary({
    required this.currency,
    required this.saved,
    required this.target,
    required this.activeGoals,
    required this.thisMonth,
    required this.nextComplete,
  });

  final LumeCurrency currency;

  /// Every active goal's saved amount, summed.
  final LumeMoney saved;

  /// Every active goal's target, summed.
  final LumeMoney target;
  final int activeGoals;

  /// Active contributions on the reader's calendar month; `null` without
  /// the reader's day.
  final LumeMoney? thisMonth;

  /// The active goal closest to its target, or `null` with none.
  final GoalView? nextComplete;

  double get ratio => target.isZero ? 0 : saved.minor / target.minor;
}

/// One month of the "Contributions" chart.
@immutable
class GoalsMonth {
  const GoalsMonth(this.month, this.total);

  /// Its first day.
  final LumeDate month;
  final LumeMoney total;
}

@immutable
class GoalsBook {
  const GoalsBook._({
    required this.goals,
    required this.defects,
    required this.damage,
    required this.today,
  });

  /// Derive the book. Throws [LumeMoneyException] only when a sum passes
  /// its bound — the caller shows that as an error, never a wrong figure.
  factory GoalsBook.from({
    required List<Goal> goals,
    required List<GoalContribution> contributions,
    List<GoalsDefect> defects = const <GoalsDefect>[],
    required LumeDate? today,
  }) {
    final Map<LumeRecordId, Goal> byId = <LumeRecordId, Goal>{
      for (final Goal g in goals) g.id: g,
    };
    final List<GoalsDamage> damage = <GoalsDamage>[];
    final Map<LumeRecordId, List<GoalContribution>> ofGoal =
        <LumeRecordId, List<GoalContribution>>{};
    for (final GoalContribution c in contributions) {
      if (!byId.containsKey(c.goalId)) {
        damage.add(
          GoalsDamage(c.goalId.value, 'orphanContribution', c.id.value),
        );
        continue;
      }
      if (c.amount.currency != byId[c.goalId]!.currency) {
        damage.add(GoalsDamage(c.goalId.value, 'currency', c.id.value));
        continue;
      }
      (ofGoal[c.goalId] ??= <GoalContribution>[]).add(c);
    }
    final Set<String> defective = <String>{
      for (final GoalsDefect d in defects) ?d.goalId,
    };

    final List<GoalView> views = <GoalView>[];
    for (final Goal goal in goals) {
      final List<GoalContribution> mine = <GoalContribution>[
        ...?ofGoal[goal.id],
      ]..sort(goalsContributionOrder);
      final List<GoalContribution> active = <GoalContribution>[
        for (final GoalContribution c in mine)
          if (c.active) c,
      ];
      String? why;
      if (defective.contains(goal.id.value)) why = 'defect';
      if (why != null) damage.add(GoalsDamage(goal.id.value, why));

      LumeMoney saved = LumeMoney.zero(goal.currency);
      if (why == null) {
        for (final GoalContribution c in active) {
          saved += c.amount;
        }
      }
      DateTime last = goal.createdAt;
      for (final GoalContribution c in mine) {
        if (c.createdAt.isAfter(last)) last = c.createdAt;
      }
      final int? months = why != null || today == null
          ? null
          : _projectedMonths(goal, saved, today);
      views.add(
        GoalView._(
          goal: goal,
          contributions: active,
          damage: why,
          saved: saved,
          projectedMonths: months,
          lastActivity: last,
        ),
      );
    }
    return GoalsBook._(
      goals: views,
      defects: defects,
      damage: damage,
      today: today,
    );
  }

  final List<GoalView> goals;
  final List<GoalsDefect> defects;
  final List<GoalsDamage> damage;
  final LumeDate? today;

  bool get dayKnown => today != null;
  bool get isEmpty => goals.isEmpty;

  GoalView? goal(LumeRecordId id) {
    for (final GoalView g in goals) {
      if (g.goal.id == id) return g;
    }
    return null;
  }

  /// The currencies in use, by code.
  List<LumeCurrency> get currencies =>
      <LumeCurrency>{for (final GoalView g in goals) g.currency}.toList()
        ..sort();

  /// One summary per currency; damaged goals are left out of every figure.
  List<GoalsCurrencySummary> get summaries => <GoalsCurrencySummary>[
    for (final LumeCurrency c in currencies) summary(c),
  ];

  GoalsCurrencySummary summary(LumeCurrency c) {
    final List<GoalView> mine = <GoalView>[
      for (final GoalView g in goals)
        if (g.currency == c && !g.damaged) g,
    ];
    LumeMoney saved = LumeMoney.zero(c);
    LumeMoney target = LumeMoney.zero(c);
    LumeMoney? thisMonth = today == null ? null : LumeMoney.zero(c);
    int active = 0;
    GoalView? next;
    for (final GoalView g in mine) {
      if (g.goal.state != GoalState.active) continue;
      saved += g.saved;
      target += g.target;
      active++;
      if (next == null || g.pct > next.pct) next = g;
      if (thisMonth != null) {
        for (final GoalContribution ct in g.contributions) {
          if (lumeSameCalendarMonth(ct.on, today!)) {
            thisMonth = thisMonth! + ct.amount;
          }
        }
      }
    }
    return GoalsCurrencySummary(
      currency: c,
      saved: saved,
      target: target,
      activeGoals: active,
      thisMonth: thisMonth,
      nextComplete: next,
    );
  }

  /// For each of the [count] calendar months up to and including the
  /// reader's, the active contributions of [c] made in it; `null` without
  /// the reader's day.
  List<GoalsMonth>? months(LumeCurrency c, {int count = 6}) {
    final LumeDate? day = today;
    if (day == null) return null;
    final List<LumeDate> starts = <LumeDate>[
      for (int m = count - 1; m >= 0; m--) _monthStart(day, -m),
    ];
    return <GoalsMonth>[
      for (final LumeDate start in starts)
        () {
          LumeMoney sum = LumeMoney.zero(c);
          for (final GoalView g in goals) {
            if (g.currency != c || g.damaged) continue;
            for (final GoalContribution ct in g.contributions) {
              if (lumeSameCalendarMonth(ct.on, start)) sum += ct.amount;
            }
          }
          return GoalsMonth(start, sum);
        }(),
    ];
  }

  /// Every active contribution, newest first — for a goal's own history.
  List<GoalContribution> history(LumeRecordId goalId) =>
      goal(goalId)?.contributions ?? const <GoalContribution>[];

  static LumeDate _monthStart(LumeDate day, int offset) {
    final int months = day.year * 12 + (day.month - 1) + offset;
    return LumeDate(months ~/ 12, months % 12 + 1, 1);
  }

  /// Whole months from the goal's creation to [today], at least 1 once a
  /// month has genuinely passed; `null` before that, so a goal a day old
  /// never claims a pace.
  static int? _projectedMonths(Goal goal, LumeMoney saved, LumeDate today) {
    final LumeDate? due = goal.targetDate;
    if (due == null) return null;
    final LumeDate created = LumeDate.ofWallClock(goal.createdAt);
    int elapsed =
        (today.year - created.year) * 12 + (today.month - created.month);
    if (today.day < created.day) elapsed -= 1;
    if (elapsed < 1 || saved.isZero) return null;
    final LumeMoney remaining = goal.target - saved;
    if (remaining.isNegative || remaining.isZero) return 0;
    final double pace = saved.minor / elapsed;
    if (pace <= 0) return null;
    return (remaining.minor / pace).ceil();
  }
}

/// Newest first: the date, then the moment recorded, then the id.
int goalsContributionOrder(GoalContribution a, GoalContribution b) {
  final int d = b.on.compareTo(a.on);
  if (d != 0) return d;
  final int t = b.createdAt.compareTo(a.createdAt);
  return t != 0 ? t : a.id.compareTo(b.id);
}

/// Whether [d] is in the same calendar month as [month].
bool lumeSameCalendarMonth(LumeDate d, LumeDate month) =>
    d.year == month.year && d.month == month.month;

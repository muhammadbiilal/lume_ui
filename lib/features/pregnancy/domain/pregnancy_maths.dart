/// A pregnancy estimate, worked out from one date — the first day of the
/// reader's last menstrual period (LMP) — on Naegele's rule: a due date 280
/// days (40 weeks) after it. Every figure here is arithmetic on that one
/// date and "today"; nothing is a per-week fixture (D-P1, mirroring
/// `MEALPLAN_PROPOSAL.md` §2's D-M2: the reference's own weekly note,
/// size, weight and weight-series are bare literals with no computation
/// behind them, and are not reproduced).
///
/// **Week counting.** Gestational age in *completed* weeks — the figure a
/// clinician means by "36 weeks" and the one mainstream trackers (BabyCenter,
/// Ovia and the rest) show as the headline number: 0 on the LMP date itself,
/// rising by one every seven days, so the due date lands on exactly week 40
/// rather than 41. `week = daysPregnant ~/ 7`.
///
/// **This is an estimate from a date the reader typed, never medical
/// advice and never a guarantee.** A real due date depends on the reader's
/// actual cycle and on what a clinician observes; this only reproduces the
/// standard 280-day rule of thumb.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';

@immutable
class LumePregnancyMilestone {
  const LumePregnancyMilestone({
    required this.week,
    required this.date,
    required this.done,
  });

  /// The week of gestation this milestone marks.
  final int week;

  /// The calendar date it falls on, for this reader's LMP.
  final LumeDate date;

  /// Whether the reader has reached it yet.
  final bool done;
}

@immutable
class LumePregnancy {
  const LumePregnancy({
    required this.lmp,
    required this.dueDate,
    required this.daysPregnant,
    required this.week,
    required this.trimester,
    required this.daysUntilDue,
    required this.milestones,
  });

  final LumeDate lmp;

  /// `lmp + 280 days` — Naegele's rule.
  final LumeDate dueDate;

  /// Whole days since [lmp], never negative (a future LMP is the caller's
  /// to refuse before this is worked out — [of] clamps defensively rather
  /// than counting backwards).
  final int daysPregnant;

  /// `daysPregnant ~/ 7` — completed weeks, 0 on the LMP date itself and
  /// exactly [gestationWeeks] on the due date.
  final int week;

  /// 1 (weeks 1–13), 2 (14–27) or 3 (28 and on).
  final int trimester;

  /// Days from today to [dueDate]; negative once the due date has passed.
  final int daysUntilDue;

  /// The four standard gestational-age markers, each with the real date it
  /// falls on for this LMP: end of the first trimester, the usual anatomy-
  /// scan window, the start of the third trimester, and full term.
  final List<LumePregnancyMilestone> milestones;

  bool get overdue => daysUntilDue < 0;

  /// `week / 40`, held to the ring/bar's own ceiling — a week past 40 does
  /// not draw past full.
  double get progress => (week / gestationWeeks).clamp(0.0, 1.0);

  static const int gestationWeeks = 40;
  static const int gestationDays = gestationWeeks * 7;

  /// The outer bound this build treats an LMP as still describing an
  /// active pregnancy: 45 weeks, well past the 42-week point clinicians
  /// treat as post-term, so an honestly overdue reading is never refused
  /// while an implausible one still is (§ [LumePregnancyValidity]).
  static const int maxPlausibleDays = 315;

  static const List<int> milestoneWeeks = <int>[12, 20, 28, 37];

  /// The estimate for [lmp] as of [today]. The caller is expected to have
  /// validated [lmp] first ([LumePregnancyValidity.check]); a future LMP is
  /// clamped to zero days pregnant rather than counted as negative.
  static LumePregnancy of(LumeDate lmp, LumeDate today) {
    final int daysPregnant = math.max(0, lmp.daysUntil(today));
    final int week = daysPregnant ~/ 7;
    final int trimester = week <= 13
        ? 1
        : week <= 27
        ? 2
        : 3;
    final LumeDate dueDate = lmp.addDays(gestationDays);
    return LumePregnancy(
      lmp: lmp,
      dueDate: dueDate,
      daysPregnant: daysPregnant,
      week: week,
      trimester: trimester,
      daysUntilDue: today.daysUntil(dueDate),
      milestones: <LumePregnancyMilestone>[
        for (final int w in milestoneWeeks)
          LumePregnancyMilestone(
            week: w,
            date: lmp.addDays(w * 7),
            done: week >= w,
          ),
      ],
    );
  }
}

/// Why an LMP date is not one this build will estimate from.
enum LumePregnancyInvalid {
  /// A last period cannot start after today.
  future,

  /// Further back than [LumePregnancy.maxPlausibleDays] — no longer a
  /// plausible active pregnancy.
  tooOld,
}

/// The one validation rule, kept beside the maths it protects rather than
/// duplicated in the repository and the date picker's bounds.
abstract final class LumePregnancyValidity {
  static LumePregnancyInvalid? check(LumeDate lmp, LumeDate today) {
    if (lmp.isAfter(today)) return LumePregnancyInvalid.future;
    if (lmp.daysUntil(today) > LumePregnancy.maxPlausibleDays) {
      return LumePregnancyInvalid.tooOld;
    }
    return null;
  }
}

/// How Baby Budget's states, figures and slices are worded
/// (`BABY_BUDGET_PROPOSAL.md` §11, §15).
///
/// Amounts go through [LumeFormatting.amount] — exact, never through a
/// `double`. Dates are calendar dates written out; the reference's
/// weekday names off the device clock are not repeated (defect 6).
/// Nothing here says money moved: a spend is what the reader recorded.
library;

import 'package:flutter/material.dart';

import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/babybudget_book.dart';
import '../domain/babybudget_model.dart';

abstract final class BabyBudgetText {
  /// Where a planned purchase stands. Without the reader's day nothing is
  /// called overdue (§8).
  static String planned(AppLocalizations l, BabyPlannedStatus s) => switch (s) {
    BabyPlannedStatus.overdue => l.babyOverdue,
    BabyPlannedStatus.expected => l.babyExpected,
    BabyPlannedStatus.undated => l.babyUndated,
    BabyPlannedStatus.unknown => l.babyDayUnknown,
  };

  /// Its badge tone. Overdue is said in words as well as colour.
  static LumeBadgeTone plannedTone(BabyPlannedStatus s) => switch (s) {
    BabyPlannedStatus.overdue => LumeBadgeTone.late_,
    BabyPlannedStatus.expected => LumeBadgeTone.neutral,
    BabyPlannedStatus.undated => LumeBadgeTone.off,
    BabyPlannedStatus.unknown => LumeBadgeTone.off,
  };

  static String status(AppLocalizations l, BabyBudgetStatus s) => switch (s) {
    BabyBudgetStatus.inUse => l.babyFilterInUse,
    BabyBudgetStatus.notStarted => l.babyFilterNotStarted,
    BabyBudgetStatus.archived => l.babyFilterArchived,
    BabyBudgetStatus.unknown => l.babyDayUnknown,
  };

  /// What a row of the planned list says about itself, under its name.
  static String plannedMeta(
    AppLocalizations l,
    LumeFormatting f,
    BabyBudgetView v,
    BabySpend s,
  ) => <String>[
    planned(l, v.statusOf(s)),
    if (s.expectedOn case final LumeDate on)
      l.babyExpectedOn(dateShort(f, on, today: v.today)),
  ].join(' · ');

  /// The name a slice carries, including the one for spends with no
  /// category of their own — a real slice, not a remainder (§6 B).
  static String slice(AppLocalizations l, BabyCategoryView s) =>
      s.uncategorised ? l.babyUncategorised : s.name;

  /// A category's tone. It comes from the stored colour, so renaming a
  /// category never recolours its slice; uncategorised is neutral, and is
  /// never mistaken for one of the reader's own.
  static Color colour(BuildContext context, BabyCategoryView s) {
    final LumeColors lume = context.lume;
    if (s.uncategorised) return lume.text3;
    return palette(context)[s.colour % kBabyColourCount];
  }

  static List<Color> palette(BuildContext context) {
    final LumeColors lume = context.lume;
    return <Color>[lume.accent, lume.indigo, lume.amber, lume.violet, lume.sky];
  }

  /// A calendar date, the year shown when it is not the reader's.
  static String date(LumeFormatting f, LumeDate d, {LumeDate? today}) {
    final DateTime t = d.toCalendarDateTime();
    return today != null && today.year == d.year
        ? f.dateLong(t)
        : f.dateLongYear(t);
  }

  /// The shorter form a row's meta takes.
  static String dateShort(LumeFormatting f, LumeDate d, {LumeDate? today}) {
    final DateTime t = d.toCalendarDateTime();
    return today != null && today.year == d.year
        ? f.dateMedium(t)
        : f.dateMediumYear(t);
  }

  /// A month, in the reader's language — never the reference's hard-coded
  /// English (defect 3). The year is shown when it is not the reader's.
  static String month(LumeFormatting f, LumeDate m, {LumeDate? today}) {
    final DateTime t = m.toCalendarDateTime();
    return today != null && today.year == m.year
        ? f.monthLong(t)
        : f.monthYear(t);
  }

  /// The short month a bar is labelled with — "Sep", not "S", because a
  /// six-month run holds two months beginning with J.
  static String monthShort(LumeFormatting f, LumeDate m) =>
      f.monthShort(m.toCalendarDateTime());
}

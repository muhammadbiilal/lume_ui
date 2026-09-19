/// How Installments' states and figures are worded.
///
/// Amounts go through [LumeFormatting.amount] — exact, never through a
/// `double`. Dates are calendar dates written out; relative words ("in 2
/// days") are never used. Text reading, digits and search folding are
/// Ledger's (`INSTALLMENTS_PROPOSAL.md` §31): the same reader types the same
/// digits into both.
library;

import '../../../core/localization/lume_format.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/installments_book.dart';

abstract final class InstallmentsText {
  /// An instalment's state, in words.
  static String status(AppLocalizations l, InstallmentStatus s) => switch (s) {
    InstallmentStatus.paid => l.instPaid,
    InstallmentStatus.dueToday => l.instDueToday,
    InstallmentStatus.late => l.instFilterLate,
    InstallmentStatus.upcoming => l.instUpcoming,
    InstallmentStatus.unknown => l.instDayUnknown,
  };

  /// Its badge tone: late is marked by the word as well as the colour.
  static LumeBadgeTone tone(InstallmentStatus s) => switch (s) {
    InstallmentStatus.paid => LumeBadgeTone.ok,
    InstallmentStatus.dueToday => LumeBadgeTone.warn,
    InstallmentStatus.late => LumeBadgeTone.late_,
    InstallmentStatus.upcoming => LumeBadgeTone.neutral,
    InstallmentStatus.unknown => LumeBadgeTone.off,
  };

  static String planStatus(AppLocalizations l, InstallmentPlanStatus s) =>
      switch (s) {
        InstallmentPlanStatus.active => l.instFilterActive,
        InstallmentPlanStatus.completed => l.instFilterCompleted,
        InstallmentPlanStatus.cancelled => l.instFilterCancelled,
      };

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
}

/// How Committee's states and figures are worded
/// (`COMMITTEE_PROPOSAL.md` §11, §15).
///
/// Amounts go through [LumeFormatting.amount] — exact, never through a
/// `double`. Dates are calendar dates written out; relative words ("in 2
/// days") are never used. Nothing here says money moved: a payout is
/// "recorded", which is what the reader did.
library;

import '../../../core/localization/lume_format.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/committee_book.dart';

abstract final class CommitteeText {
  /// What one share owes for one cycle, in words.
  static String slot(AppLocalizations l, CommitteeSlotStatus s) => switch (s) {
    CommitteeSlotStatus.paid => l.commPaid,
    CommitteeSlotStatus.dueToday => l.commDueToday,
    CommitteeSlotStatus.late => l.commLate,
    CommitteeSlotStatus.upcoming => l.commUpcoming,
    CommitteeSlotStatus.unpaidAtCancellation => l.commUnpaidAtCancel,
    CommitteeSlotStatus.notDue => l.commNotDue,
    CommitteeSlotStatus.unknown => l.commDayUnknown,
  };

  /// Its badge tone. Late is said in words as well as colour.
  static LumeBadgeTone slotTone(CommitteeSlotStatus s) => switch (s) {
    CommitteeSlotStatus.paid => LumeBadgeTone.ok,
    CommitteeSlotStatus.dueToday => LumeBadgeTone.warn,
    CommitteeSlotStatus.late => LumeBadgeTone.late_,
    CommitteeSlotStatus.upcoming => LumeBadgeTone.neutral,
    CommitteeSlotStatus.unpaidAtCancellation => LumeBadgeTone.late_,
    CommitteeSlotStatus.notDue => LumeBadgeTone.off,
    CommitteeSlotStatus.unknown => LumeBadgeTone.off,
  };

  /// Where a cycle's pool has got to. Never "paid" or "sent": Lume moves
  /// no money, and only knows what the reader recorded.
  static String payout(AppLocalizations l, CommitteeCyclePayoutStatus s) =>
      switch (s) {
        CommitteeCyclePayoutStatus.recorded => l.commPayoutRecorded,
        CommitteeCyclePayoutStatus.ready => l.commPayoutReady,
        CommitteeCyclePayoutStatus.waiting => l.commPayoutWaiting,
        CommitteeCyclePayoutStatus.upcoming => l.commUpcoming,
      };

  static LumeBadgeTone payoutTone(CommitteeCyclePayoutStatus s) => switch (s) {
    CommitteeCyclePayoutStatus.recorded => LumeBadgeTone.ok,
    CommitteeCyclePayoutStatus.ready => LumeBadgeTone.live,
    CommitteeCyclePayoutStatus.waiting => LumeBadgeTone.warn,
    CommitteeCyclePayoutStatus.upcoming => LumeBadgeTone.neutral,
  };

  static String status(AppLocalizations l, CommitteeStatus s) => switch (s) {
    CommitteeStatus.active => l.commFilterRunning,
    CommitteeStatus.completed => l.commFilterCompleted,
    CommitteeStatus.cancelled => l.commFilterCancelled,
  };

  /// The reader's part in the committee, said plainly. None of these say
  /// Lume holds, moves or manages anyone's money.
  static String role(AppLocalizations l, CommitteeView v) =>
      switch (v.committee.readerRole) {
        _ when v.reader == null => l.commRoleOrganiser,
        _ =>
          v.committee.readerRole.name == 'organiserMember'
              ? l.commRoleBoth
              : l.commRoleMember,
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

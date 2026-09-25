/// Small display helpers Reminders needs more than once.
library;

import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/reminder_model.dart';

abstract final class ReminderText {
  static String repeat(AppLocalizations l, ReminderRepeat r) => switch (r) {
    ReminderRepeat.once => l.remRepeatOnce,
    ReminderRepeat.daily => l.remRepeatDaily,
    ReminderRepeat.weekly => l.remRepeatWeekly,
  };

  static String time(LumeFormatting f, int hour, int minute) =>
      f.time(DateTime(2000, 1, 1, hour, minute));

  static String icon(ReminderRepeat r) => switch (r) {
    ReminderRepeat.once => LumeIcons.bellRing,
    ReminderRepeat.daily => LumeIcons.clock,
    ReminderRepeat.weekly => LumeIcons.clock,
  };
}

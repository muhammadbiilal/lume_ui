/// The words Alarms draws that its fixture does not carry, plus the one
/// locale-aware figure it does: the wake time itself.
library;

import '../../../core/localization/lume_format.dart';
import '../../../l10n/app_localizations.dart';
import '../data/alarms_fixtures.dart';

abstract final class LumeAlarmText {
  static String label(AppLocalizations l, LumeAlarmLabel v) => switch (v) {
    LumeAlarmLabel.work => l.alarmsA1,
    LumeAlarmLabel.lieIn => l.alarmsA2,
    LumeAlarmLabel.windDown => l.alarmsA3,
  };

  static String repeat(AppLocalizations l, LumeAlarmRepeat v) => switch (v) {
    LumeAlarmRepeat.weekdays => l.alarmsWeekdays,
    LumeAlarmRepeat.weekend => l.alarmsWeekend,
    LumeAlarmRepeat.daily => l.alarmsDaily,
  };

  /// `L.time(hour, minute)` — the reader's own locale and 12/24-hour
  /// preference, the same route `ReminderText.time` takes rather than a
  /// fixed `HH:MM`.
  static String time(LumeFormatting f, int hour, int minute) =>
      f.time(DateTime(2000, 1, 1, hour, minute));
}

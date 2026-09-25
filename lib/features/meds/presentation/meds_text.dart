/// Small string mappings for Medication — no state, no logic beyond a
/// lookup.
library;

import '../../../l10n/app_localizations.dart';
import '../domain/meds_model.dart';

abstract final class MedsText {
  static String schedule(AppLocalizations l, MedsSchedule s) => switch (s) {
    MedsSchedule.daily => l.medsScheduleDaily,
    MedsSchedule.twice => l.medsScheduleTwice,
    MedsSchedule.weekly => l.medsScheduleWeekly,
    MedsSchedule.needed => l.medsScheduleNeeded,
  };
}

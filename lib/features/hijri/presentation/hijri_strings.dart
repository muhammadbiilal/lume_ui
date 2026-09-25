/// Islamic Calendar's own strings, over what Calendar already localises.
///
/// Three of the six computed transitions ([LumeHijriEventId.islamicNewYear],
/// [LumeHijriEventId.eidAlFitr], [LumeHijriEventId.eidAlAdha]) are names
/// Public Holidays already carries as [LumeHolidayName] entries with their own
/// ARB keys (`holidayIslamicNewYear`, `holidayEidAlFitr`, `holidayEidAlAdha`)
/// — reused here rather than duplicated, so the same event has the same name
/// wherever Lume names it. The other three ([LumeHijriEventId.ashura],
/// [LumeHijriEventId.ramadanBegins], [LumeHijriEventId.dayOfArafah]) have no
/// existing key and are new to this tool.
library;

import '../../../l10n/app_localizations.dart';
import '../../calendar/presentation/calendar_strings.dart';
import '../domain/hijri_events.dart';

abstract final class LumeHijriStrings {
  static String eventName(AppLocalizations l, LumeHijriEventId id) =>
      switch (id) {
        LumeHijriEventId.islamicNewYear => l.holidayIslamicNewYear,
        LumeHijriEventId.eidAlFitr => l.holidayEidAlFitr,
        LumeHijriEventId.eidAlAdha => l.holidayEidAlAdha,
        LumeHijriEventId.ashura => l.hijriEventAshura,
        LumeHijriEventId.ramadanBegins => l.hijriEventRamadanBegins,
        LumeHijriEventId.dayOfArafah => l.hijriEventDayOfArafah,
      };

  /// `HIJRI_MONTHS[month - 1]` — Calendar's own mapping, kept in one place.
  static String month(AppLocalizations l, int month) =>
      LumeCalendarStrings.hijriMonth(l, month);
}

/// What a holiday's name and kind say — resolved to the reader's language.
///
/// Every name and kind here is an existing reference string
/// (`holidayIqbalDay`, `holidayKindNational`, …): the same generic `holiday*`
/// keys `calendar_fixtures.dart`'s own holiday strip already resolves through
/// `calendar_strings.dart`. No new key is needed for a name or a kind —
/// only for the words this tool adds around them (`holidays_tool.dart`).
library;

import '../../../l10n/app_localizations.dart';
import '../data/holidays_fixtures.dart';

abstract final class LumeHolidaysText {
  static String name(AppLocalizations l, LumeHolidayName n) => switch (n) {
    LumeHolidayName.iqbalDay => l.holidayIqbalDay,
    LumeHolidayName.quaidDay => l.holidayQuaidDay,
    LumeHolidayName.kashmirDay => l.holidayKashmirDay,
    LumeHolidayName.pakistanDay => l.holidayPakistanDay,
    LumeHolidayName.labourDay => l.holidayLabourDay,
    LumeHolidayName.independenceDay => l.holidayIndependenceDay,
    LumeHolidayName.thanksgiving => l.holidayThanksgiving,
    LumeHolidayName.christmasDay => l.holidayChristmasDay,
    LumeHolidayName.newYearsDay => l.holidayNewYearsDay,
    LumeHolidayName.mlkDay => l.holidayMlkDay,
    LumeHolidayName.laborDay => l.holidayLaborDay,
    LumeHolidayName.boxingDay => l.holidayBoxingDay,
    LumeHolidayName.goodFriday => l.holidayGoodFriday,
    LumeHolidayName.earlyMay => l.holidayEarlyMay,
    LumeHolidayName.summer => l.holidaySummer,
    LumeHolidayName.nationalDay => l.holidayNationalDay,
    LumeHolidayName.eidAlFitr => l.holidayEidAlFitr,
    LumeHolidayName.eidAlAdha => l.holidayEidAlAdha,
    LumeHolidayName.islamicNewYear => l.holidayIslamicNewYear,
    LumeHolidayName.commemorationDay => l.holidayCommemorationDay,
    LumeHolidayName.foundingDay => l.holidayFoundingDay,
    LumeHolidayName.gandhiJayanti => l.holidayGandhiJayanti,
    LumeHolidayName.christmas => l.holidayChristmas,
    LumeHolidayName.republicDay => l.holidayRepublicDay,
    LumeHolidayName.holi => l.holidayHoli,
    LumeHolidayName.diwali => l.holidayDiwali,
  };

  static String kind(AppLocalizations l, LumeHolidayKind k) => switch (k) {
    LumeHolidayKind.national => l.holidayKindNational,
    LumeHolidayKind.federal => l.holidayKindFederal,
    LumeHolidayKind.bank => l.holidayKindBank,
    LumeHolidayKind.public => l.holidayKindPublic,
    LumeHolidayKind.gazetted => l.holidayKindGazetted,
  };
}

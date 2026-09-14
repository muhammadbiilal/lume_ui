/// The Calendar's datasets, in the reader's language.
library;

import '../../../l10n/app_localizations.dart';
import '../data/calendar_fixtures.dart';

abstract final class LumeCalendarStrings {
  /// `HIJRI_MONTHS[month - 1]`.
  static String hijriMonth(AppLocalizations l, int month) => switch (month) {
    1 => l.hijriMonth1,
    2 => l.hijriMonth2,
    3 => l.hijriMonth3,
    4 => l.hijriMonth4,
    5 => l.hijriMonth5,
    6 => l.hijriMonth6,
    7 => l.hijriMonth7,
    8 => l.hijriMonth8,
    9 => l.hijriMonth9,
    10 => l.hijriMonth10,
    11 => l.hijriMonth11,
    _ => l.hijriMonth12,
  };

  static String holiday(AppLocalizations l, LumeHolidayName n) => switch (n) {
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

  static String itemTitle(AppLocalizations l, String id) => switch (id) {
    'standup' => l.calendarStandup,
    'review' => l.calendarReview,
    _ => l.calendarGroceries,
  };

  static String itemWhere(AppLocalizations l, String id) => switch (id) {
    'standup' => l.calendarStandupWhere,
    'review' => l.calendarReviewWhere,
    _ => l.calendarGroceriesWhere,
  };

  /// `t('prayer.' + key)`.
  static String prayer(AppLocalizations l, String key) => switch (key) {
    'fajr' => l.prayerFajr,
    'dhuhr' => l.prayerDhuhr,
    'asr' => l.prayerAsr,
    'maghrib' => l.prayerMaghrib,
    _ => l.prayerIsha,
  };
}

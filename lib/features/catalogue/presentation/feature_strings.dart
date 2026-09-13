/// Feature and category names, in the reader's language.
///
/// §19 makes the catalogue the source of truth for *what* a feature is; the
/// ARBs are the source of truth for what it is *called*. This is the join, and
/// it is exhaustive on purpose: a `switch` over every id means adding a feature
/// without a name is a compile error rather than a screen that renders a key.
///
/// [LumeFeature.fallbackName] is the last resort and is never reached —
/// `catalogue_test.dart` asserts every id resolves here in all three languages.
///
/// The status line is the same idea. The prototype keeps it in the catalogue as
/// an English string and renders it untranslated in Urdu and Arabic (D22); here
/// it is a key, and a tool's own repository may override it at runtime with a
/// live value the way `syncFeatureMeta` does for four of them.
library;

import '../../../core/localization/lume_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/domain/home_repository.dart';
import '../domain/lume_feature.dart';

/// The localised name and status of every feature.
abstract final class LumeFeatureStrings {
  /// What this feature is called.
  static String name(AppLocalizations l, String id) => switch (id) {
    'calculator' => l.featureCalculator,
    'converter' => l.featureConverter,
    'currency' => l.featureCurrency,
    'stopwatch' => l.featureStopwatch,
    'timer' => l.featureTimer,
    'age' => l.featureAge,
    'focus' => l.featureFocus,
    'datecalc' => l.featureDatecalc,
    'calendar' => l.featureCalendar,
    'reminders' => l.featureReminders,
    'notes' => l.featureNotes,
    'todos' => l.featureTodos,
    'events' => l.featureEvents,
    'prayer' => l.featurePrayer,
    'qibla' => l.featureQibla,
    'mosques' => l.featureMosques,
    'praytrack' => l.featurePraytrack,
    'ramadan' => l.featureRamadan,
    'fasting' => l.featureFasting,
    'taraweeh' => l.featureTaraweeh,
    'ayah' => l.featureAyah,
    'quran' => l.featureQuran,
    'quransearch' => l.featureQuransearch,
    'hadith' => l.featureHadith,
    'duas' => l.featureDuas,
    'names99' => l.featureNames99,
    'hijri' => l.featureHijri,
    'tasbih' => l.featureTasbih,
    'zakat' => l.featureZakat,
    'faraid' => l.featureFaraid,
    'compound' => l.featureCompound,
    'goldrates' => l.featureGoldrates,
    'markets' => l.featureMarkets,
    'fuel' => l.featureFuel,
    'fuelcost' => l.featureFuelcost,
    'tax' => l.featureTax,
    'natsavings' => l.featureNatsavings,
    'prizebonds' => l.featurePrizebonds,
    'bills' => l.featureBills,
    'packages' => l.featurePackages,
    'loan' => l.featureLoan,
    'tipsplit' => l.featureTipsplit,
    'ledger' => l.featureLedger,
    'installments' => l.featureInstallments,
    'committee' => l.featureCommittee,
    'aqi' => l.featureAqi,
    'sunmoon' => l.featureSunmoon,
    'worldclock' => l.featureWorldclock,
    'holidays' => l.featureHolidays,
    'weather' => l.featureWeather,
    'loadshed' => l.featureLoadshed,
    'trains' => l.featureTrains,
    'flights' => l.featureFlights,
    'news' => l.featureNews,
    'cricket' => l.featureCricket,
    'emergency' => l.featureEmergency,
    'qr' => l.featureQr,
    'docscan' => l.featureDocscan,
    'passport' => l.featurePassport,
    'vehicle' => l.featureVehicle,
    'mediasaver' => l.featureMediasaver,
    'wastatus' => l.featureWastatus,
    'speedtest' => l.featureSpeedtest,
    'parcel' => l.featureParcel,
    'shopping' => l.featureShopping,
    'birthdays' => l.featureBirthdays,
    'streak' => l.featureStreak,
    'recipes' => l.featureRecipes,
    'mealplan' => l.featureMealplan,
    'alarms' => l.featureAlarms,
    'learning' => l.featureLearning,
    'documents' => l.featureDocuments,
    'vaccines' => l.featureVaccines,
    'health' => l.featureHealth,
    'play' => l.featurePlay,
    'babybudget' => l.featureBabybudget,
    'habits' => l.featureHabits,
    'water' => l.featureWater,
    'bmi' => l.featureBmi,
    'cycle' => l.featureCycle,
    'pregnancy' => l.featurePregnancy,
    'expenses' => l.featureExpenses,
    'goals' => l.featureGoals,
    'subs' => l.featureSubs,
    'meds' => l.featureMeds,
    _ => id,
  };

  /// The small line under the name. `null` where a feature has none.
  static String? status(AppLocalizations l, String id) => switch (id) {
    'calculator' => l.toolStatusCalculator,
    'converter' => l.toolStatusConverter,
    'currency' => l.toolStatusCurrency,
    'stopwatch' => l.toolStatusStopwatch,
    'timer' => l.toolStatusTimer,
    'age' => l.toolStatusAge,
    'focus' => l.toolStatusFocus,
    'datecalc' => l.toolStatusDatecalc,
    'calendar' => l.toolStatusCalendar,
    'reminders' => l.toolStatusReminders,
    'notes' => l.toolStatusNotes,
    'todos' => l.toolStatusTodos,
    'events' => l.toolStatusEvents,
    'prayer' => l.toolStatusPrayer,
    'qibla' => l.toolStatusQibla,
    'mosques' => l.toolStatusMosques,
    'praytrack' => l.toolStatusPraytrack,
    'ramadan' => l.toolStatusRamadan,
    'fasting' => l.toolStatusFasting,
    'taraweeh' => l.toolStatusTaraweeh,
    'ayah' => l.toolStatusAyah,
    'quran' => l.toolStatusQuran,
    'quransearch' => l.toolStatusQuransearch,
    'hadith' => l.toolStatusHadith,
    'duas' => l.toolStatusDuas,
    'names99' => l.toolStatusNames99,
    'hijri' => l.toolStatusHijri,
    'tasbih' => l.toolStatusTasbih,
    'zakat' => l.toolStatusZakat,
    'faraid' => l.toolStatusFaraid,
    'compound' => l.toolStatusCompound,
    'goldrates' => l.toolStatusGoldrates,
    'markets' => l.toolStatusMarkets,
    'fuel' => l.toolStatusFuel,
    'fuelcost' => l.toolStatusFuelcost,
    'tax' => l.toolStatusTax,
    'natsavings' => l.toolStatusNatsavings,
    'prizebonds' => l.toolStatusPrizebonds,
    'bills' => l.toolStatusBills,
    'packages' => l.toolStatusPackages,
    'loan' => l.toolStatusLoan,
    'tipsplit' => l.toolStatusTipsplit,
    'ledger' => l.toolStatusLedger,
    'installments' => l.toolStatusInstallments,
    'committee' => l.toolStatusCommittee,
    'aqi' => l.toolStatusAqi,
    'sunmoon' => l.toolStatusSunmoon,
    'worldclock' => l.toolStatusWorldclock,
    'holidays' => l.toolStatusHolidays,
    'weather' => l.toolStatusWeather,
    'loadshed' => l.toolStatusLoadshed,
    'trains' => l.toolStatusTrains,
    'flights' => l.toolStatusFlights,
    'news' => l.toolStatusNews,
    'cricket' => l.toolStatusCricket,
    'emergency' => l.toolStatusEmergency,
    'qr' => l.toolStatusQr,
    'docscan' => l.toolStatusDocscan,
    'passport' => l.toolStatusPassport,
    'vehicle' => l.toolStatusVehicle,
    'mediasaver' => l.toolStatusMediasaver,
    'wastatus' => l.toolStatusWastatus,
    'speedtest' => l.toolStatusSpeedtest,
    'parcel' => l.toolStatusParcel,
    'shopping' => l.toolStatusShopping,
    'birthdays' => l.toolStatusBirthdays,
    'streak' => l.toolStatusStreak,
    'recipes' => l.toolStatusRecipes,
    'mealplan' => l.toolStatusMealplan,
    'alarms' => l.toolStatusAlarms,
    'learning' => l.toolStatusLearning,
    'documents' => l.toolStatusDocuments,
    'vaccines' => l.toolStatusVaccines,
    'health' => l.toolStatusHealth,
    'play' => l.toolStatusPlay,
    'babybudget' => l.toolStatusBabybudget,
    'habits' => l.toolStatusHabits,
    'water' => l.toolStatusWater,
    'bmi' => l.toolStatusBmi,
    'cycle' => l.toolStatusCycle,
    'pregnancy' => l.toolStatusPregnancy,
    'expenses' => l.toolStatusExpenses,
    'goals' => l.toolStatusGoals,
    'subs' => l.toolStatusSubs,
    'meds' => l.toolStatusMeds,
    _ => null,
  };

  /// A category's heading.
  static String category(AppLocalizations l, LumeToolCategory c) => switch (c) {
    LumeToolCategory.everyday => l.toolCategoryEveryday,
    LumeToolCategory.planning => l.toolCategoryPlanning,
    LumeToolCategory.islamic => l.toolCategoryIslamic,
    LumeToolCategory.money => l.toolCategoryMoney,
    LumeToolCategory.daily => l.toolCategoryDaily,
    LumeToolCategory.personal => l.toolCategoryPersonal,
  };

  /// A category's supporting line.
  static String categorySub(AppLocalizations l, LumeToolCategory c) =>
      switch (c) {
        LumeToolCategory.everyday => l.toolCategorySubEveryday,
        LumeToolCategory.planning => l.toolCategorySubPlanning,
        LumeToolCategory.islamic => l.toolCategorySubIslamic,
        LumeToolCategory.money => l.toolCategorySubMoney,
        LumeToolCategory.daily => l.toolCategorySubDaily,
        LumeToolCategory.personal => l.toolCategorySubPersonal,
      };

  /// The line under a tile's name, live where the device can answer and the
  /// catalogue's otherwise.
  ///
  /// `syncFeatureMeta` does this in the reference so a tile does not still
  /// claim 34° in New York or name a prayer that has already passed. One
  /// resolver, read by Home and by the hub, so the two cannot disagree.
  static String? tileStatus(
    AppLocalizations l,
    LumeFormatting f,
    String id,
    LumeToolStatuses live,
  ) {
    if (id == 'prayer' && live.prayer != null) {
      return '${prayerName(l, live.prayer!.key)} ${f.time(live.prayer!.at)}';
    }
    if (id == 'weather' && live.weather != null) {
      return '${f.temperature(live.weather!.temperatureC)} '
          '${weatherCondition(l, live.weather!.conditionKey)}';
    }
    return status(l, id);
  }

  /// The five daily prayers, by key.
  static String prayerName(AppLocalizations l, String key) => switch (key) {
    'fajr' => l.prayerFajr,
    'dhuhr' => l.prayerDhuhr,
    'asr' => l.prayerAsr,
    'maghrib' => l.prayerMaghrib,
    'isha' => l.prayerIsha,
    _ => key,
  };

  /// The fixture's condition vocabulary, by key.
  static String weatherCondition(AppLocalizations l, String key) =>
      switch (key) {
        'hazySun' => l.weatherHazySun,
        // The whole phrase a market's own entry carries, which Explore shows
        // and the shorter surfaces do not.
        'hazySunHumid' => l.weatherHazySunHumid,
        'humidLightHaze' => l.weatherHumidLightHaze,
        'clearVeryWarm' => l.weatherClearVeryWarm,
        'mostlyClear' => l.weatherMostlyClear,
        'cloudBuilding' => l.weatherCloudBuilding,
        'clear' => l.weatherClear,
        'lightCloud' => l.weatherLightCloud,
        'overcast' => l.weatherOvercast,
        // The rest of `WEATHER_BY_COUNTRY` and `WEATHER_BY_ZONE`, so every
        // market the reference writes down reads its own phrase.
        'cloudy' => l.weatherCloudy,
        'brightAndBreezy' => l.weatherBrightAndBreezy,
        'sunnySpells' => l.weatherSunnySpells,
        'humid' => l.weatherHumid,
        'humidShowersLater' => l.weatherHumidShowersLater,
        'humidAfternoonStorms' => l.weatherHumidAfternoonStorms,
        'humidCloudBuilding' => l.weatherHumidCloudBuilding,
        'humidPassingShowers' => l.weatherHumidPassingShowers,
        'clearAndDry' => l.weatherClearAndDry,
        'mildAndClear' => l.weatherMildAndClear,
        'warmAndDry' => l.weatherWarmAndDry,
        'warm' => l.weatherWarm,
        'changeable' => l.weatherChangeable,
        'breezy' => l.weatherBreezy,
        'warmAndHumid' => l.weatherWarmAndHumid,
        'fresh' => l.weatherFresh,
        _ => key,
      };

  /// Everything a search matches on: the localised name, the catalogue's
  /// English name and the keywords.
  ///
  /// The prototype indexes `f.n + f.kw` — the *English* name — so an Urdu
  /// reader cannot find a tool by the name they can see (C18). Both are
  /// indexed here, because someone who learned a tool's English name should
  /// not lose it by switching language.
  static String haystack(AppLocalizations l, LumeFeature f) =>
      '${name(l, f.id).toLowerCase()} ${f.fallbackHaystack}';
}

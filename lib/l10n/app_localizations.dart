import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('ur'),
  ];

  /// Reference key a.add
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// Reference key a.all
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get actionAll;

  /// Reference key a.back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// Reference key a.bookmark
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get actionBookmark;

  /// Reference key a.cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Reference key a.clear
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// Reference key a.close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// Reference key a.continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// Reference key a.delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Reference key a.done
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// Reference key a.edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// Reference key a.getStarted
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get actionGetStarted;

  /// Reference key a.looksGood
  ///
  /// In en, this message translates to:
  /// **'Looks good'**
  String get actionLooksGood;

  /// Reference key a.next
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// Reference key a.notSet
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get actionNotSet;

  /// Reference key a.refresh
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// Reference key a.remove
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// Reference key a.save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Reference key a.saveImage
  ///
  /// In en, this message translates to:
  /// **'Save image'**
  String get actionSaveImage;

  /// Reference key a.search
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// Reference key a.share
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// Reference key a.skip
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// Reference key a.tryAgain
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// Reference key a.week
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get actionWeek;

  /// Reference key a11y.back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get a11yBack;

  /// Reference key a11y.search
  ///
  /// In en, this message translates to:
  /// **'Search this tool'**
  String get a11ySearch;

  /// Reference key a11y.share
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get a11yShare;

  /// Reference key app.tagline
  ///
  /// In en, this message translates to:
  /// **'Your day, in one place'**
  String get appTagline;

  /// Reference key common.all
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// Reference key common.days
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get commonDays;

  /// Reference key common.done
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// Reference key common.due
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get commonDue;

  /// Reference key common.export
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get commonExport;

  /// Reference key common.history
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get commonHistory;

  /// Reference key common.inDays
  ///
  /// In en, this message translates to:
  /// **'in {n} days'**
  String commonInDays(Object n);

  /// Reference key common.locked
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get commonLocked;

  /// Reference key common.month
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get commonMonth;

  /// Reference key common.no
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// Reference key common.now
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get commonNow;

  /// Reference key common.overdue
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get commonOverdue;

  /// Reference key common.paid
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get commonPaid;

  /// Reference key common.reset
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// Reference key common.save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Reference key common.share
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// Reference key common.sort
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get commonSort;

  /// Reference key common.status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get commonStatus;

  /// Reference key common.thisMonth
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get commonThisMonth;

  /// Reference key common.today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// Reference key common.tomorrow
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get commonTomorrow;

  /// Reference key common.total
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get commonTotal;

  /// Reference key common.week
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get commonWeek;

  /// Reference key common.year
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get commonYear;

  /// Reference key common.yes
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// Reference key common.yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// Reference key nav.explore
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// Reference key nav.home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Reference key nav.profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Reference key nav.today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// Reference key nav.tools
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get navTools;

  /// Reference key nav.trains
  ///
  /// In en, this message translates to:
  /// **'Trains'**
  String get navTrains;

  /// Reference key rec.conflict
  ///
  /// In en, this message translates to:
  /// **'This record changed elsewhere'**
  String get recConflict;

  /// Reference key rec.conflictText
  ///
  /// In en, this message translates to:
  /// **'A newer version exists. Review your changes or reload the newer one.'**
  String get recConflictText;

  /// Reference key rec.deleteFailed
  ///
  /// In en, this message translates to:
  /// **'Could not delete this record'**
  String get recDeleteFailed;

  /// Reference key rec.loadError
  ///
  /// In en, this message translates to:
  /// **'We could not load {noun}'**
  String recLoadError(Object noun);

  /// Reference key rec.loadErrorText
  ///
  /// In en, this message translates to:
  /// **'Check your connection. Your saved data is still safe on this device.'**
  String get recLoadErrorText;

  /// Reference key rec.nothingToUndo
  ///
  /// In en, this message translates to:
  /// **'Nothing left to undo'**
  String get recNothingToUndo;

  /// Reference key rec.offline
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get recOffline;

  /// Reference key rec.offlineQueued
  ///
  /// In en, this message translates to:
  /// **'This will be saved here and synced when you are back.'**
  String get recOfflineQueued;

  /// Reference key rec.offlineText
  ///
  /// In en, this message translates to:
  /// **'Showing records saved on this device.'**
  String get recOfflineText;

  /// Reference key rec.saveFailed
  ///
  /// In en, this message translates to:
  /// **'Could not save changes'**
  String get recSaveFailed;

  /// Reference key rec.saveFailedText
  ///
  /// In en, this message translates to:
  /// **'Nothing you typed was lost. Try again.'**
  String get recSaveFailedText;

  /// Reference key search.jumpBack
  ///
  /// In en, this message translates to:
  /// **'Jump back in'**
  String get searchJumpBack;

  /// Reference key search.nothing
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get searchNothing;

  /// Reference key search.placeholder
  ///
  /// In en, this message translates to:
  /// **'Search anything — tools, rates, places'**
  String get searchPlaceholder;

  /// Reference key search.try
  ///
  /// In en, this message translates to:
  /// **'Try searching for'**
  String get searchTry;

  /// Reference key tool.private.text
  ///
  /// In en, this message translates to:
  /// **'This information stays on your device, is never shown on Home and is never included in shared content.'**
  String get toolPrivateText;

  /// Reference key tool.private.title
  ///
  /// In en, this message translates to:
  /// **'Private to you'**
  String get toolPrivateTitle;

  /// Reference key tools.nothingYet
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get toolsNothingYet;

  /// Reference: aria-label="Main" on both navigations
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get a11yMainNavigation;

  /// Reference key home.notifications
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// Reference key acct.account
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// Announced while a tool is still assembling
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get toolLoading;

  /// Tool host error state
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get toolErrorTitle;

  /// Tool host error state
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load this. Try again in a moment.'**
  String get toolErrorText;

  /// Tool host unavailable state
  ///
  /// In en, this message translates to:
  /// **'Not part of your setup'**
  String get toolUnavailableTitle;

  /// Reference key tool.unavailable
  ///
  /// In en, this message translates to:
  /// **'That tool isn’t part of your setup.'**
  String get toolUnavailableText;

  /// Unrecognised location
  ///
  /// In en, this message translates to:
  /// **'We can’t find that'**
  String get routeMissingTitle;

  /// Unrecognised location
  ///
  /// In en, this message translates to:
  /// **'The link may be old, or the page may have moved.'**
  String get routeMissingText;

  /// Master-detail pane before a record is chosen
  ///
  /// In en, this message translates to:
  /// **'Nothing selected'**
  String get recordsNoSelectionTitle;

  /// Master-detail pane before a record is chosen
  ///
  /// In en, this message translates to:
  /// **'Choose a record to see it here.'**
  String get recordsNoSelectionText;

  /// Reference key onb.localKicker
  ///
  /// In en, this message translates to:
  /// **'Make it local'**
  String get onbLocalKicker;

  /// Reference key onb.whereTitle
  ///
  /// In en, this message translates to:
  /// **'Where are you based?'**
  String get onbWhereTitle;

  /// Reference key onb.whereText
  ///
  /// In en, this message translates to:
  /// **'This helps us personalise local information and services. It says nothing about who you are.'**
  String get onbWhereText;

  /// Reference key onb.yoursKicker
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get onbYoursKicker;

  /// Reference key onb.hereForTitle
  ///
  /// In en, this message translates to:
  /// **'What are you here for?'**
  String get onbHereForTitle;

  /// The interests step’s supporting copy. Untranslated in the reference; see D12
  ///
  /// In en, this message translates to:
  /// **'Pick 5 to 10. Your home screen, tools and reading are built around them — change them whenever you like.'**
  String get onbHereForText;

  /// Reference key pers.searchCountries
  ///
  /// In en, this message translates to:
  /// **'Search countries'**
  String get persSearchCountries;

  /// Reference key pers.recent
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get persRecent;

  /// Reference key pers.popular
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get persPopular;

  /// Reference key pers.allCountries
  ///
  /// In en, this message translates to:
  /// **'All countries'**
  String get persAllCountries;

  /// Reference key onb.minimum, shown below the minimum
  ///
  /// In en, this message translates to:
  /// **'{count} of {min} minimum'**
  String onbMinimum(String count, String min);

  /// Reference key onb.selected, shown at or above the minimum
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} selected'**
  String onbSelected(String count, String max);

  /// Refuses a tap once the cap is reached
  ///
  /// In en, this message translates to:
  /// **'Up to {max} — remove one first'**
  String onbAtCap(String max);

  /// Reference key pers.islamic
  ///
  /// In en, this message translates to:
  /// **'Islamic features'**
  String get persIslamic;

  /// Reference key pers.islamicSub
  ///
  /// In en, this message translates to:
  /// **'Prayer times, Qur’an, duas, zakat and Ramadan'**
  String get persIslamicSub;

  /// Reference key ig.everyday
  ///
  /// In en, this message translates to:
  /// **'Everyday life'**
  String get igEveryday;

  /// Reference key ig.money
  ///
  /// In en, this message translates to:
  /// **'Money & finance'**
  String get igMoney;

  /// Reference key ig.health
  ///
  /// In en, this message translates to:
  /// **'Health & wellness'**
  String get igHealth;

  /// Reference key ig.travel
  ///
  /// In en, this message translates to:
  /// **'Travel & getting around'**
  String get igTravel;

  /// Reference key ig.news
  ///
  /// In en, this message translates to:
  /// **'News & entertainment'**
  String get igNews;

  /// Reference key ig.faith
  ///
  /// In en, this message translates to:
  /// **'Islamic features'**
  String get igFaith;

  /// Interest "weather". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get intWeather;

  /// Interest "calendar". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get intCalendar;

  /// Interest "tasks". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Tasks & to-dos'**
  String get intTasks;

  /// Interest "notes". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get intNotes;

  /// Interest "convert". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Converters'**
  String get intConvert;

  /// Interest "maths". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Calculators'**
  String get intMaths;

  /// Interest "alarms". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Alarms & timers'**
  String get intAlarms;

  /// Interest "expenses". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get intExpenses;

  /// Interest "rates". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Rates & gold'**
  String get intRates;

  /// Interest "bills". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get intBills;

  /// Interest "savings". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Saving & goals'**
  String get intSavings;

  /// Interest "markets". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get intMarkets;

  /// Interest "habits". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get intHabits;

  /// Interest "water". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get intWater;

  /// Interest "fitness". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get intFitness;

  /// Interest "meds". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get intMeds;

  /// Interest "sleep". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get intSleep;

  /// Interest "trains". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Trains'**
  String get intTrains;

  /// Interest "flights". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get intFlights;

  /// Interest "nearby". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Nearby places'**
  String get intNearby;

  /// Interest "fuel". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get intFuel;

  /// Interest "news". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get intNews;

  /// Interest "cricket". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Cricket'**
  String get intCricket;

  /// Interest "reading". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get intReading;

  /// Interest "quotes". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Daily quotes'**
  String get intQuotes;

  /// Interest "prayer". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get intPrayer;

  /// Interest "quran". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Qur’an'**
  String get intQuran;

  /// Interest "hadith". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get intHadith;

  /// Interest "duas". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Duas & dhikr'**
  String get intDuas;

  /// Interest "zakat". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Zakat & giving'**
  String get intZakat;

  /// Interest "ramadan". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get intRamadan;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

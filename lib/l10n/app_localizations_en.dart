// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get actionAdd => 'Add';

  @override
  String get actionAll => 'All';

  @override
  String get actionBack => 'Back';

  @override
  String get actionBookmark => 'Bookmark';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionClose => 'Close';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionDone => 'Done';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionGetStarted => 'Get started';

  @override
  String get actionLooksGood => 'Looks good';

  @override
  String get actionNext => 'Next';

  @override
  String get actionNotSet => 'Not set';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionSave => 'Save';

  @override
  String get actionSaveImage => 'Save image';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionShare => 'Share';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String get actionWeek => 'Week';

  @override
  String get a11yBack => 'Back';

  @override
  String get a11ySearch => 'Search this tool';

  @override
  String get a11yShare => 'Share';

  @override
  String get appTagline => 'Your day, in one place';

  @override
  String get commonAll => 'All';

  @override
  String get commonDays => 'days';

  @override
  String get commonDone => 'Done';

  @override
  String get commonDue => 'Due';

  @override
  String get commonExport => 'Export';

  @override
  String get commonHistory => 'History';

  @override
  String commonInDays(Object n) {
    return 'in $n days';
  }

  @override
  String get commonLocked => 'Locked';

  @override
  String get commonMonth => 'Month';

  @override
  String get commonNo => 'No';

  @override
  String get commonNow => 'Now';

  @override
  String get commonOverdue => 'Overdue';

  @override
  String get commonPaid => 'Paid';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonSave => 'Save';

  @override
  String get commonShare => 'Share';

  @override
  String get commonSort => 'Sort';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonThisMonth => 'This month';

  @override
  String get commonToday => 'Today';

  @override
  String get commonTomorrow => 'Tomorrow';

  @override
  String get commonTotal => 'Total';

  @override
  String get commonWeek => 'Week';

  @override
  String get commonYear => 'Year';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get navExplore => 'Explore';

  @override
  String get navHome => 'Home';

  @override
  String get navProfile => 'Profile';

  @override
  String get navToday => 'Today';

  @override
  String get navTools => 'Tools';

  @override
  String get navTrains => 'Trains';

  @override
  String get recConflict => 'This record changed elsewhere';

  @override
  String get recConflictText =>
      'A newer version exists. Review your changes or reload the newer one.';

  @override
  String get recDeleteFailed => 'Could not delete this record';

  @override
  String recLoadError(Object noun) {
    return 'We could not load $noun';
  }

  @override
  String get recLoadErrorText =>
      'Check your connection. Your saved data is still safe on this device.';

  @override
  String get recNothingToUndo => 'Nothing left to undo';

  @override
  String get recOffline => 'You are offline';

  @override
  String get recOfflineQueued =>
      'This will be saved here and synced when you are back.';

  @override
  String get recOfflineText => 'Showing records saved on this device.';

  @override
  String get recSaveFailed => 'Could not save changes';

  @override
  String get recSaveFailedText => 'Nothing you typed was lost. Try again.';

  @override
  String get searchJumpBack => 'Jump back in';

  @override
  String get searchNothing => 'Nothing found';

  @override
  String get searchPlaceholder => 'Search anything — tools, rates, places';

  @override
  String get searchTry => 'Try searching for';

  @override
  String get toolPrivateText =>
      'This information stays on your device, is never shown on Home and is never included in shared content.';

  @override
  String get toolPrivateTitle => 'Private to you';

  @override
  String get toolsNothingYet => 'Nothing here yet';

  @override
  String get a11yMainNavigation => 'Main';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navAccount => 'Account';

  @override
  String get toolLoading => 'Loading';

  @override
  String get toolErrorTitle => 'Something went wrong';

  @override
  String get toolErrorText => 'We couldn’t load this. Try again in a moment.';

  @override
  String get toolUnavailableTitle => 'Not part of your setup';

  @override
  String get toolUnavailableText => 'That tool isn’t part of your setup.';

  @override
  String get routeMissingTitle => 'We can’t find that';

  @override
  String get routeMissingText =>
      'The link may be old, or the page may have moved.';

  @override
  String get recordsNoSelectionTitle => 'Nothing selected';

  @override
  String get recordsNoSelectionText => 'Choose a record to see it here.';

  @override
  String get onbLocalKicker => 'Make it local';

  @override
  String get onbWhereTitle => 'Where are you based?';

  @override
  String get onbWhereText =>
      'This helps us personalise local information and services. It says nothing about who you are.';

  @override
  String get onbYoursKicker => 'Make it yours';

  @override
  String get onbHereForTitle => 'What are you here for?';

  @override
  String get onbHereForText =>
      'Pick 5 to 10. Your home screen, tools and reading are built around them — change them whenever you like.';

  @override
  String get persSearchCountries => 'Search countries';

  @override
  String get persRecent => 'Recent';

  @override
  String get persPopular => 'Popular';

  @override
  String get persAllCountries => 'All countries';

  @override
  String onbMinimum(String count, String min) {
    return '$count of $min minimum';
  }

  @override
  String onbSelected(String count, String max) {
    return '$count of $max selected';
  }

  @override
  String onbAtCap(String max) {
    return 'Up to $max — remove one first';
  }

  @override
  String get persIslamic => 'Islamic features';

  @override
  String get persIslamicSub => 'Prayer times, Qur’an, duas, zakat and Ramadan';

  @override
  String get igEveryday => 'Everyday life';

  @override
  String get igMoney => 'Money & finance';

  @override
  String get igHealth => 'Health & wellness';

  @override
  String get igTravel => 'Travel & getting around';

  @override
  String get igNews => 'News & entertainment';

  @override
  String get igFaith => 'Islamic features';

  @override
  String get intWeather => 'Weather';

  @override
  String get intCalendar => 'Calendar';

  @override
  String get intTasks => 'Tasks & to-dos';

  @override
  String get intNotes => 'Notes';

  @override
  String get intConvert => 'Converters';

  @override
  String get intMaths => 'Calculators';

  @override
  String get intAlarms => 'Alarms & timers';

  @override
  String get intExpenses => 'Expenses';

  @override
  String get intRates => 'Rates & gold';

  @override
  String get intBills => 'Bills';

  @override
  String get intSavings => 'Saving & goals';

  @override
  String get intMarkets => 'Markets';

  @override
  String get intHabits => 'Habits';

  @override
  String get intWater => 'Water';

  @override
  String get intFitness => 'Fitness';

  @override
  String get intMeds => 'Medication';

  @override
  String get intSleep => 'Sleep';

  @override
  String get intTrains => 'Trains';

  @override
  String get intFlights => 'Flights';

  @override
  String get intNearby => 'Nearby places';

  @override
  String get intFuel => 'Fuel';

  @override
  String get intNews => 'News';

  @override
  String get intCricket => 'Cricket';

  @override
  String get intReading => 'Reading';

  @override
  String get intQuotes => 'Daily quotes';

  @override
  String get intPrayer => 'Prayer times';

  @override
  String get intQuran => 'Qur’an';

  @override
  String get intHadith => 'Hadith';

  @override
  String get intDuas => 'Duas & dhikr';

  @override
  String get intZakat => 'Zakat & giving';

  @override
  String get intRamadan => 'Ramadan';
}

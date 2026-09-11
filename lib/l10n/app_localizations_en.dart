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
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get a11yBack => 'Back';

  @override
  String get a11yExport => 'Export';

  @override
  String get a11yFavourite => 'Save to favourites';

  @override
  String get a11yMainNavigation => 'Main';

  @override
  String get a11ySearch => 'Search this tool';

  @override
  String get a11ySearchTool => 'Search this tool';

  @override
  String get a11yShare => 'Share';

  @override
  String get acctAboutText =>
      'A global daily-life super-app. Built to work anywhere, in your language, with the parts of it you asked for.';

  @override
  String get acctAboutTitle => 'About Lume';

  @override
  String get acctAppearanceDark => 'Dark';

  @override
  String get acctAppearanceLight => 'Light';

  @override
  String get acctAppearanceSystem => 'Follow the system';

  @override
  String get acctAppearanceTitle => 'Appearance';

  @override
  String get acctBuild => 'Build';

  @override
  String acctCatsOn(int n, int total) {
    return '$n of $total on';
  }

  @override
  String get acctChangePassword => 'Change password';

  @override
  String get acctChangePasswordSub =>
      'Last changed is not recorded on this device';

  @override
  String get acctClock12 => '12-hour';

  @override
  String get acctClock24 => '24-hour';

  @override
  String get acctClockFormat => 'Clock';

  @override
  String get acctCompleteCta => 'Add your name';

  @override
  String get acctCompleteText =>
      'Add your name so Lume can greet you properly.';

  @override
  String get acctCompleteTitle => 'Complete your profile';

  @override
  String get acctCurrencyAuto => 'Follow my region';

  @override
  String get acctCurrencyNote =>
      'Some tools quote their own market’s currency regardless.';

  @override
  String get acctCurrencyTitle => 'Currency';

  @override
  String get acctDangerZone => 'Danger zone';

  @override
  String get acctDataAccount => 'Your account and sessions';

  @override
  String get acctDataNotes => 'Notes, tasks, expenses and trackers';

  @override
  String get acctDataNotify => 'Notification settings and history';

  @override
  String get acctDataPrefs => 'Preferences, region and language';

  @override
  String get acctDataSample =>
      'Sample data — nothing is saved, synced or encrypted in this build';

  @override
  String get acctDataTitle => 'Data';

  @override
  String get acctDataTools => 'Tools, favourites and recent screens';

  @override
  String get acctDeleteConfirmText =>
      'Enter your password to delete the account.';

  @override
  String get acctDeleteConfirmTitle => 'Confirm it’s you';

  @override
  String get acctDeleteCta => 'Delete my account';

  @override
  String get acctDeleteFinalText =>
      'This removes the account for good. There is no way back.';

  @override
  String get acctDeleteFinalTitle => 'Delete your account?';

  @override
  String get acctDeleteK1 =>
      'Notes, tasks, expenses and preferences remain on this device.';

  @override
  String get acctDeleteKeeps => 'What stays';

  @override
  String get acctDeleteRow => 'Delete account';

  @override
  String get acctDeleteRowSub => 'Permanently remove your Lume account';

  @override
  String get acctDeleteTitle => 'Delete account';

  @override
  String get acctDeleteW1 => 'Your account and email are removed.';

  @override
  String get acctDeleteW2 => 'Every signed-in device is signed out.';

  @override
  String get acctDeleteW3 => 'This cannot be undone.';

  @override
  String get acctDeleteWhat => 'What this does';

  @override
  String get acctDeleted => 'Account deleted';

  @override
  String get acctDeviceAndroid => 'Android phone';

  @override
  String get acctDeviceBrowser => 'Web browser';

  @override
  String get acctDeviceIos => 'iPhone';

  @override
  String get acctDeviceMac => 'Mac';

  @override
  String get acctDeviceWindows => 'Windows PC';

  @override
  String get acctDiscardCta => 'Discard';

  @override
  String get acctDiscardText =>
      'You’ve edited this screen without saving. Leaving now loses those edits.';

  @override
  String get acctDiscardTitle => 'Discard your changes?';

  @override
  String get acctEditProfile => 'Edit profile';

  @override
  String get acctEditSaved => 'Profile updated';

  @override
  String get acctEditTitle => 'Edit profile';

  @override
  String get acctEmailChanged => 'Email updated';

  @override
  String get acctEmailPending => 'Pending verification';

  @override
  String acctEmailPendingText(String email) {
    return '$email becomes your address once you verify it.';
  }

  @override
  String get acctEmailTitle => 'Email address';

  @override
  String get acctErrCurrentRequired => 'Enter your current password.';

  @override
  String get acctErrCurrentWrong => 'That current password is incorrect.';

  @override
  String get acctErrNameRequired =>
      'Enter a name, or leave it blank to use your email address.';

  @override
  String get acctErrPasswordSame =>
      'Choose a password you haven’t used here before.';

  @override
  String get acctErrPhoneInvalid => 'Enter a phone number Lume can read.';

  @override
  String get acctErrPhotoTooBig =>
      'That image is too large for this device to keep. Try a smaller one.';

  @override
  String get acctErrStorage =>
      'Lume couldn’t save to this device. Check that there is space free and try again.';

  @override
  String get acctFavourites => 'Your favourites';

  @override
  String get acctFieldConfirmNew => 'Confirm new password';

  @override
  String get acctFieldCurrent => 'Current password';

  @override
  String get acctFieldDisplayName => 'Display name';

  @override
  String get acctFieldFirst => 'First name';

  @override
  String get acctFieldLast => 'Last name';

  @override
  String get acctFieldNewEmail => 'New email address';

  @override
  String get acctFieldPhone => 'Phone';

  @override
  String get acctGuestBadge => 'Guest';

  @override
  String get acctGuestEditNote =>
      'This name is kept on this device. Creating an account brings it with you.';

  @override
  String get acctGuestNotifText =>
      'Alerts belong to this device while you’re a guest. Signing in never shows you another account’s notifications.';

  @override
  String get acctGuestNotifTitle => 'Notifications on this device';

  @override
  String get acctGuestText =>
      'You’re using Lume as a guest. Everything you’ve set up is saved on this device.';

  @override
  String get acctGuestTitle => 'Welcome to Lume';

  @override
  String get acctGuestWhy => 'Create an account to';

  @override
  String get acctGuestWhy1 => 'keep your Lume across devices';

  @override
  String get acctGuestWhy2 => 'recover your settings if you lose this phone';

  @override
  String get acctGuestWhy3 => 'use account-based features as they arrive';

  @override
  String get acctHelpContact => 'Send feedback';

  @override
  String get acctHelpText =>
      'Lume is a single-screen product: everything is one or two taps from Home.';

  @override
  String get acctHelpTitle => 'Help';

  @override
  String get acctHelpTour => 'Replay the welcome tour';

  @override
  String get acctLanguageNote =>
      'Changing the language never changes anything you wrote.';

  @override
  String get acctLanguageTitle => 'Language';

  @override
  String acctLastSeen(String when) {
    return 'Last seen $when';
  }

  @override
  String get acctLoggedOut => 'Signed out';

  @override
  String get acctLogoutText =>
      'You’ll need to sign in again to reach your account. Everything on this device stays where it is.';

  @override
  String get acctLogoutTitle => 'Log out?';

  @override
  String acctMemberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get acctNameNote => 'This is the name Lume greets you with.';

  @override
  String get acctNoFavourites => 'Nothing saved yet';

  @override
  String get acctNoFavouritesText =>
      'Tap the star on any tool and it lands here.';

  @override
  String get acctNoOtherDevices => 'No other devices are signed in.';

  @override
  String get acctNothingChanged => 'Nothing to save yet';

  @override
  String get acctPersonalTitle => 'Personal information';

  @override
  String get acctPhoneNote => 'Optional. Stored on this device.';

  @override
  String get acctPhoneSaved => 'Phone number saved';

  @override
  String get acctPhoneScope => 'What this is for';

  @override
  String get acctPhoneScopeText =>
      'Kept on this device so a tool can offer it. Lume has no phone sign-in or phone recovery, so it does nothing else.';

  @override
  String get acctPhoneTitle => 'Phone number';

  @override
  String get acctPhoto => 'Profile photo';

  @override
  String get acctPhotoAdd => 'Add photo';

  @override
  String get acctPhotoNote => 'Optional. Stored on this device.';

  @override
  String get acctPhotoRemove => 'Remove photo';

  @override
  String get acctPhotoReplace => 'Replace photo';

  @override
  String get acctPrefsTitle => 'Preferences';

  @override
  String get acctPrivacyAnalytics => 'Usage analytics';

  @override
  String get acctPrivacyAnalyticsSub =>
      'Lume collects none. There is nothing to turn off.';

  @override
  String get acctPrivacyPersonal => 'Personalisation';

  @override
  String get acctPrivacyPersonalSub =>
      'Use what you do in Lume to order what you see';

  @override
  String get acctPrivacyPreview => 'Notification previews';

  @override
  String get acctPrivacyPreviewSub =>
      'Show the content of an alert on the lock screen';

  @override
  String get acctPrivacySensitive => 'Sensitive content in previews';

  @override
  String get acctPrivacySensitiveSub =>
      'Health, money and documents stay hidden until opened';

  @override
  String get acctPrivacyTitle => 'Privacy';

  @override
  String get acctPushAsk => 'Not asked yet';

  @override
  String get acctPushDenied => 'Blocked in your device settings';

  @override
  String get acctPushDeniedHelp =>
      'Notifications are blocked. Allow them for Lume in your device settings.';

  @override
  String get acctPushGranted => 'Allowed on this device';

  @override
  String get acctPushOff => 'Off';

  @override
  String get acctPushOn => 'On';

  @override
  String get acctPushThanks => 'Notifications are on';

  @override
  String get acctPushUnsupported => 'This device can’t show push notifications';

  @override
  String get acctPwStrengthLabel => 'Strength';

  @override
  String get acctRegionChange => 'Change country or city';

  @override
  String get acctRegionTitle => 'Region & currency';

  @override
  String get acctRegionWarn =>
      'Changing your region may update your currency, markets, holidays, emergency numbers and local services.';

  @override
  String get acctRowAbout => 'About Lume';

  @override
  String get acctRowAboutSub => 'Version, licences and credits';

  @override
  String get acctRowAppearance => 'Appearance';

  @override
  String get acctRowAppearanceSub => 'Light, dark or follow your system';

  @override
  String get acctRowHelp => 'Help';

  @override
  String get acctRowHelpSub => 'Answers, and a way to reach us';

  @override
  String get acctRowInterests => 'Your interests';

  @override
  String get acctRowInterestsSub => 'Shapes your home, tools and reading';

  @override
  String get acctRowLanguage => 'Language';

  @override
  String get acctRowLibrary => 'Your library';

  @override
  String get acctRowLibrarySub => 'Saved reads, notes and favourites';

  @override
  String get acctRowNotificationsSub =>
      'Push alerts, in-app updates and quiet hours';

  @override
  String get acctRowPersonal => 'Personal information';

  @override
  String get acctRowPersonalSub => 'Name, email, phone and region';

  @override
  String get acctRowPreferences => 'Preferences';

  @override
  String get acctRowPreferencesSub => 'Language, currency, units and time';

  @override
  String get acctRowPrivacy => 'Privacy';

  @override
  String get acctRowPrivacySub => 'What Lume shows, keeps and shares';

  @override
  String get acctRowRegion => 'Region & currency';

  @override
  String get acctRowRegionSub =>
      'Country, city and the services that follow them';

  @override
  String get acctRowSecurity => 'Security';

  @override
  String get acctRowSecuritySub => 'Password, sessions and account protection';

  @override
  String get acctRowSync => 'Data & sync';

  @override
  String get acctRowSyncSub => 'Where each part of your Lume is stored';

  @override
  String get acctRowTour => 'Replay the welcome tour';

  @override
  String get acctRowTourSub => 'A quick reminder of what’s here';

  @override
  String get acctSaveChanges => 'Save changes';

  @override
  String get acctSecurityScope => 'What Lume protects';

  @override
  String get acctSecurityScopeText =>
      'Your password and your signed-in devices. There is no two-factor or biometric unlock in this build, so nothing here claims otherwise.';

  @override
  String get acctSecurityTitle => 'Security';

  @override
  String acctSessionsSub(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n signed in',
      one: '1 signed in',
    );
    return '$_temp0';
  }

  @override
  String get acctSessionsTitle => 'Active sessions';

  @override
  String get acctSignOut => 'Log out';

  @override
  String get acctSignOutDevice => 'Sign out';

  @override
  String get acctSignOutOthers => 'Sign out all other devices';

  @override
  String get acctSignOutOthersText =>
      'Every other signed-in device will need to sign in again.';

  @override
  String acctSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String acctSignedOutOthers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Signed out $n other devices',
      one: 'Signed out 1 other device',
    );
    return '$_temp0';
  }

  @override
  String get acctSince => 'Member since';

  @override
  String get acctStatus => 'Account status';

  @override
  String get acctStatusActive => 'Active';

  @override
  String get acctStatusLocked => 'Locked';

  @override
  String get acctSupport => 'Support';

  @override
  String get acctSyncDevice => 'Stored on this device';

  @override
  String get acctSyncNone =>
      'Nothing syncs yet. Lume has no server in this build, so everything above stays on this device — including your account.';

  @override
  String get acctSyncSynced => 'Synced to your account';

  @override
  String get acctSyncTitle => 'Data & sync';

  @override
  String acctThemeSwitched(String mode) {
    return 'Appearance: $mode';
  }

  @override
  String get acctThisDevice => 'This device';

  @override
  String get acctTimeTitle => 'Time & timezone';

  @override
  String get acctTimezoneAuto => 'Follow this device';

  @override
  String get acctTimezoneChoose => 'Choose a time zone';

  @override
  String get acctTimezoneFollowDevice => 'Follow this device';

  @override
  String get acctTimezoneFollowRegion => 'Follow my region';

  @override
  String get acctTimezoneNoDevice => 'This device’s time zone isn’t available';

  @override
  String get acctTimezoneNote =>
      'Markets, flights and trains always use their own timezone.';

  @override
  String get acctTimezoneTitle => 'Time';

  @override
  String get acctUnitsAuto => 'Follow my region';

  @override
  String get acctUnitsImperial => 'Imperial';

  @override
  String get acctUnitsMetric => 'Metric';

  @override
  String get acctUnitsTitle => 'Units';

  @override
  String get acctVersion => 'Version';

  @override
  String get acctYourLume => 'Your Lume';

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
  String get actionChange => 'Change';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionClose => 'Close';

  @override
  String get actionConfirm => 'Confirm';

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
  String get actionResend => 'Resend';

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
  String get actionVerify => 'Verify';

  @override
  String get actionWeek => 'Week';

  @override
  String ageDaysCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get ageDaysLived => 'Days lived';

  @override
  String get ageDob => 'Date of birth';

  @override
  String ageExact(String months, String days) {
    return '$months and $days';
  }

  @override
  String get ageFuture => 'That date hasn’t happened yet';

  @override
  String get ageHours => 'Hours';

  @override
  String ageMilestone(String n) {
    return '$n days old';
  }

  @override
  String get ageMilestones => 'Milestones';

  @override
  String ageMonthsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get ageNextBirthday => 'Next birthday';

  @override
  String ageUntil(int n, String count) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in $count days',
      one: 'in 1 day',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String get ageWeeks => 'Weeks';

  @override
  String ageYearsUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'years',
      one: 'year',
    );
    return '$_temp0';
  }

  @override
  String get ageYouAre => 'You are';

  @override
  String get agendaAdhanOn => 'Adhan · reminder on';

  @override
  String get agendaGroceries => 'Pick up groceries';

  @override
  String get agendaGroceriesMeta => 'On the way home';

  @override
  String get agendaOutage => 'Outage';

  @override
  String agendaOutageMeta(String area, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '${hours}h',
      one: '1h',
    );
    return '$area · $_temp0';
  }

  @override
  String get agendaPrayed => 'Prayed';

  @override
  String get agendaReview => 'Design review';

  @override
  String get agendaReviewMeta => '45 min · Meeting room 2';

  @override
  String get agendaStandup => 'Team standup';

  @override
  String get agendaStandupMeta => '15 min · Video call';

  @override
  String get anniversaryKind => 'Anniversary';

  @override
  String get appTagline => 'Your day, in one place';

  @override
  String get aqiGoodAdvice => 'Air quality is satisfactory.';

  @override
  String get aqiGoodLabel => 'Good';

  @override
  String get aqiHazardousAdvice =>
      'Stay indoors and use filtration where possible.';

  @override
  String get aqiHazardousLabel => 'Hazardous';

  @override
  String get aqiModerateAdvice =>
      'Unusually sensitive people should limit long outdoor exertion.';

  @override
  String get aqiModerateLabel => 'Moderate';

  @override
  String get aqiSensitiveAdvice =>
      'Children and people with asthma should limit outdoor exertion.';

  @override
  String get aqiSensitiveLabel => 'Unhealthy for sensitive groups';

  @override
  String get aqiUnhealthyAdvice =>
      'Everyone should reduce prolonged outdoor exertion.';

  @override
  String get aqiUnhealthyLabel => 'Unhealthy';

  @override
  String get aqiUnit => 'AQI';

  @override
  String get aqiVeryUnhealthyAdvice =>
      'Avoid outdoor exertion. Keep windows closed.';

  @override
  String get aqiVeryUnhealthyLabel => 'Very unhealthy';

  @override
  String get archetypeAction => 'Emergency actions';

  @override
  String get archetypeCalculator => 'Calculator';

  @override
  String get archetypeDashboard => 'Dashboard';

  @override
  String get archetypeExplorer => 'Data explorer';

  @override
  String get archetypeInstrument => 'Instrument';

  @override
  String get archetypeLibrary => 'Library';

  @override
  String get archetypeManager => 'Records manager';

  @override
  String get archetypePlanner => 'Planner';

  @override
  String get archetypeReader => 'Reader';

  @override
  String get archetypeTracker => 'Tracker';

  @override
  String get archetypeTracking => 'Live tracking';

  @override
  String get authAsideText =>
      'Prayer, weather, money, travel and the small things — wherever you are.';

  @override
  String get authAsideTitle => 'One app for the day ahead.';

  @override
  String get authBackToSignIn => 'Back to sign in';

  @override
  String get authContinue => 'Continue';

  @override
  String get authContinueAsGuest => 'Continue as a guest';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authCreateOne => 'Create one';

  @override
  String get authCreatedText => 'Your Lume account is ready.';

  @override
  String authCreatedTextNamed(String name) {
    return 'Your Lume account is ready, $name.';
  }

  @override
  String get authCreatedTitle => 'You’re all set';

  @override
  String get authCreatingAccount => 'Creating your account…';

  @override
  String get authEmailPlaceholder => 'you@example.com';

  @override
  String get authEnterCta => 'Enter Lume';

  @override
  String get authErrCodeExpired => 'That code has expired. Ask for a new one.';

  @override
  String get authErrCodeIncorrect => 'That code is incorrect.';

  @override
  String get authErrCodeRequired => 'Enter the code we sent you.';

  @override
  String get authErrConfirmMismatch => 'These passwords don’t match.';

  @override
  String get authErrConfirmRequired => 'Confirm your password.';

  @override
  String get authErrCredentials => 'Email or password is incorrect.';

  @override
  String get authErrEmailInvalid => 'That doesn’t look like an email address.';

  @override
  String get authErrEmailRequired => 'Enter your email address.';

  @override
  String get authErrEmailSame => 'That’s already your email address.';

  @override
  String get authErrEmailTaken => 'An account already exists for this email.';

  @override
  String get authErrLinkExpired =>
      'This reset link has expired. Request a new one.';

  @override
  String get authErrLinkInvalid => 'This reset link is no longer valid.';

  @override
  String get authErrLocked =>
      'This account is locked. Reset your password to unlock it.';

  @override
  String get authErrNetwork =>
      'Lume couldn’t reach the network. Nothing was lost.';

  @override
  String get authErrNothingPending => 'There’s no email change waiting.';

  @override
  String get authErrPasswordRequired => 'Enter a password.';

  @override
  String get authErrPasswordWeak =>
      'Your password doesn’t meet all the requirements yet.';

  @override
  String get authErrRateLimited =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get authErrSignedOut => 'You’re signed out. Sign in to continue.';

  @override
  String get authErrStorage =>
      'Lume couldn’t save to this device. Check its storage settings and try again.';

  @override
  String get authExpiredCta => 'Sign in again';

  @override
  String get authExpiredText =>
      'Sign in again and Lume will take you back to where you were.';

  @override
  String get authExpiredTitle => 'Your session has expired';

  @override
  String get authFieldCode => 'Verification code';

  @override
  String get authFieldConfirm => 'Confirm password';

  @override
  String get authFieldEmail => 'Email';

  @override
  String get authFieldName => 'Name';

  @override
  String get authFieldNewPassword => 'New password';

  @override
  String get authFieldPassword => 'Password';

  @override
  String get authForgotAction => 'Forgot password?';

  @override
  String get authForgotCta => 'Send reset link';

  @override
  String get authForgotText =>
      'Enter the email associated with your Lume account.';

  @override
  String get authForgotTitle => 'Forgot password?';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authLegal =>
      'Creating an account means Lume keeps this information for you.';

  @override
  String get authLegalLink => 'How Lume handles your data';

  @override
  String authLocalCode(String code) {
    return 'This build has no mail server. Your code is $code.';
  }

  @override
  String get authNameHint => 'So Lume knows what to call you.';

  @override
  String get authNeedAccountText =>
      'This part of Lume belongs to your account.';

  @override
  String get authNoAccount => 'Don’t have an account?';

  @override
  String get authOpenLink => 'Open the reset link';

  @override
  String get authPasswordRuleDigit => 'a number';

  @override
  String get authPasswordRuleLength => 'at least 8 characters';

  @override
  String get authPasswordRuleLower => 'a lowercase letter';

  @override
  String get authPasswordRuleUpper => 'an uppercase letter';

  @override
  String get authPasswordRulesTitle => 'Password must contain';

  @override
  String get authRememberPassword => 'Remember your password?';

  @override
  String get authResend => 'Send it again';

  @override
  String authResendIn(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'You can ask again in $seconds seconds',
      one: 'You can ask again in $seconds second',
    );
    return '$_temp0';
  }

  @override
  String get authResendNone => 'Didn’t receive it?';

  @override
  String get authResetCta => 'Update password';

  @override
  String get authResetText => 'Choose something you haven’t used here before.';

  @override
  String get authResetTitle => 'Create a new password';

  @override
  String get authSentLocal =>
      'This build has no mail server, so the link opens here.';

  @override
  String get authSentNote => 'The link works for one hour.';

  @override
  String get authSentText =>
      'If an account exists for this email, we’ve sent instructions to reset your password.';

  @override
  String get authSentTitle => 'Check your email';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignInText => 'Continue to your Lume.';

  @override
  String get authSignInTitle => 'Welcome back';

  @override
  String get authSignUpPasswordText => 'This is what keeps your Lume yours.';

  @override
  String get authSignUpPasswordTitle => 'Choose a password';

  @override
  String get authSignUpText =>
      'Your Lume, kept safe and reachable from anywhere.';

  @override
  String get authSignUpTitle => 'Create your Lume account';

  @override
  String get authSigningIn => 'Signing you in…';

  @override
  String authStepOf(int n, int total) {
    return 'Step $n of $total';
  }

  @override
  String get authStrength0 => 'Enter a password';

  @override
  String get authStrength1 => 'Weak';

  @override
  String get authStrength2 => 'Fair';

  @override
  String get authStrength3 => 'Good';

  @override
  String get authStrength4 => 'Strong';

  @override
  String get authTroubleCta => 'Request a new link';

  @override
  String get authTroubleExpired =>
      'Recovery links stop working after an hour, so this one has expired. Ask for a new one and it will arrive the same way.';

  @override
  String get authTroubleText =>
      'A recovery link can be used once, and only by the address it was sent to. Ask for a new one and it will arrive the same way.';

  @override
  String get authTroubleTitle => 'That link didn’t work';

  @override
  String get authUpdatedText => 'You can now sign in with your new password.';

  @override
  String get authUpdatedTitle => 'Password updated';

  @override
  String get authVerifyCta => 'Verify email';

  @override
  String get authVerifyText => 'We sent a six-digit code to';

  @override
  String get authVerifyTitle => 'Check your inbox';

  @override
  String authWelcomeBack(String name) {
    return 'Welcome back, $name';
  }

  @override
  String get authWorking => 'One moment…';

  @override
  String billsDueIn(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'due in $n days',
      one: 'due in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get billsDueThisMonth => 'Due this month';

  @override
  String billsNeedAttention(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n bills need attention',
      one: '1 bill needs attention',
    );
    return '$_temp0';
  }

  @override
  String billsOverdueBy(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String get birthdayKind => 'Birthday';

  @override
  String get calendarAdd => 'Add an event';

  @override
  String get calendarAdding => 'New event';

  @override
  String get calendarAgenda => 'Today’s agenda';

  @override
  String get calendarDay => 'Day';

  @override
  String get calendarGroceries => 'Groceries';

  @override
  String get calendarGroceriesWhere => 'On the way home';

  @override
  String get calendarHolidays => 'Public holidays';

  @override
  String get calendarMonth => 'Month';

  @override
  String get calendarReview => 'Design review';

  @override
  String get calendarReviewWhere => 'Meeting room 2';

  @override
  String get calendarStandup => 'Morning standup';

  @override
  String get calendarStandupWhere => 'Team call';

  @override
  String get calendarView => 'View';

  @override
  String get calendarWeek => 'Week';

  @override
  String get captureNotQr => 'That isn\'t a QR code. Lume reads QR codes.';

  @override
  String get capturePaused => 'Camera paused';

  @override
  String get captureStarting => 'Starting the camera…';

  @override
  String get captureTitle => 'Scan a QR code';

  @override
  String get ccyAed => 'UAE Dirham';

  @override
  String get ccyEur => 'Euro';

  @override
  String get ccyGbp => 'Pound Sterling';

  @override
  String get ccySar => 'Saudi Riyal';

  @override
  String get ccyUsd => 'US Dollar';

  @override
  String get collectionBudget => 'Budget basics';

  @override
  String collectionBudgetMeta(int n) {
    return '$n lessons';
  }

  @override
  String get collectionFocus => 'Focus sounds';

  @override
  String collectionFocusMeta(int n) {
    return '$n tracks';
  }

  @override
  String get collectionGratitude => 'Gratitude prompts';

  @override
  String collectionGratitudeMeta(int n) {
    return '$n days';
  }

  @override
  String get collectionNightSurahs => 'Night surahs';

  @override
  String collectionNightSurahsMeta(int surahs, int minutes) {
    return '$surahs surahs · $minutes min';
  }

  @override
  String get commonAll => 'All';

  @override
  String get commonAmount => 'Amount';

  @override
  String get commonChange => 'Change';

  @override
  String get commonDate => 'Date';

  @override
  String get commonDays => 'days';

  @override
  String get commonDone => 'Done';

  @override
  String get commonDue => 'Due';

  @override
  String get commonExport => 'Export';

  @override
  String get commonField => 'Field';

  @override
  String get commonHistory => 'History';

  @override
  String commonInDays(Object n) {
    return 'in $n days';
  }

  @override
  String get commonLess => 'Less';

  @override
  String get commonLocked => 'Locked';

  @override
  String get commonMonth => 'Month';

  @override
  String get commonMore => 'More';

  @override
  String get commonName => 'Name';

  @override
  String get commonNo => 'No';

  @override
  String get commonNow => 'Now';

  @override
  String get commonOffline => 'Offline';

  @override
  String get commonOptional => 'Optional';

  @override
  String get commonOr => 'or';

  @override
  String get commonOverdue => 'Overdue';

  @override
  String get commonPaid => 'Paid';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaved => 'Saved';

  @override
  String get commonShare => 'Share';

  @override
  String get commonSort => 'Sort';

  @override
  String get commonStale => 'Not current';

  @override
  String get commonStart => 'Start';

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
  String get commonValue => 'Value';

  @override
  String get commonWeek => 'Week';

  @override
  String get commonYear => 'Year';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String compoundAfter(int n, String count) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'after $count years',
      one: 'after 1 year',
    );
    return '$_temp0';
  }

  @override
  String compoundAxisYears(String count) {
    return '${count}y';
  }

  @override
  String get compoundByYear => 'Year by year';

  @override
  String get compoundContributed => 'Contributed';

  @override
  String get compoundFinalValue => 'Projected value';

  @override
  String get compoundGrowth => 'Growth';

  @override
  String get compoundInitial => 'Starting amount';

  @override
  String get compoundMonthly => 'Added each month';

  @override
  String get compoundProjection => 'Projection';

  @override
  String get compoundRate => 'Annual return';

  @override
  String get compoundReturn => 'Return';

  @override
  String get compoundValue => 'Value';

  @override
  String get compoundYears => 'Years';

  @override
  String cricketScore(String team, int runs, int wickets) {
    return '$team $runs/$wickets';
  }

  @override
  String cricketSecondTest(int n) {
    return '2nd Test · Day $n';
  }

  @override
  String get datecalcAddDays => 'Add days';

  @override
  String get datecalcBetween => 'Between the dates';

  @override
  String get datecalcBusiness => 'Working days';

  @override
  String datecalcDays(int n, String count) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get datecalcDaysToAdd => 'Days to add';

  @override
  String get datecalcDifference => 'Difference';

  @override
  String get datecalcFrom => 'From';

  @override
  String datecalcFromStart(int n, String count) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$count days from the start date',
      one: '$count day from the start date',
    );
    return '$_temp0';
  }

  @override
  String get datecalcHolidays => 'Public holidays in the year';

  @override
  String get datecalcMode => 'Mode';

  @override
  String get datecalcResult => 'Result date';

  @override
  String get datecalcStart => 'Start date';

  @override
  String get datecalcStatMonths => 'months';

  @override
  String get datecalcStatWeeks => 'weeks';

  @override
  String get datecalcStatYears => 'years';

  @override
  String get datecalcTo => 'To';

  @override
  String get datecalcWeekdays => 'Weekdays';

  @override
  String get datecalcWeekends => 'Weekend days';

  @override
  String get discoverDuasMeta => 'For ordinary days';

  @override
  String get discoverDuasTitle => 'Forty duas';

  @override
  String get docsAdd => 'Add a document';

  @override
  String get docsAllValid => 'Everything is valid';

  @override
  String get docsCategory => 'Category';

  @override
  String get docsExpired => 'Expired';

  @override
  String get docsExpiring => 'Expiring';

  @override
  String docsExpiringSoon(int n) {
    return '$n expiring soon';
  }

  @override
  String get docsExpiringSoonShort => 'Expiring';

  @override
  String get docsExpiry => 'Expiry';

  @override
  String get docsFiles => 'Files';

  @override
  String docsFilesN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get docsFxDegree => 'Degree Certificate';

  @override
  String get docsFxInsurance => 'Health Insurance';

  @override
  String get docsFxLicence => 'Driving Licence';

  @override
  String get docsFxNid => 'National ID';

  @override
  String get docsFxPassport => 'Passport';

  @override
  String get docsFxRegistration => 'Car Registration';

  @override
  String get docsFxTenancy => 'Tenancy Agreement';

  @override
  String get docsHolderHousehold => 'Household';

  @override
  String get docsNeedsAttention => 'Needs attention';

  @override
  String get docsNoExpiry => 'No expiry';

  @override
  String get docsNoMatch => 'No documents match';

  @override
  String get docsNoMatchText => 'Try another category or clear the search.';

  @override
  String docsRenewSoon(String name) {
    return 'Renew your $name';
  }

  @override
  String get docsRenewText =>
      'Renewing early avoids the queue and the late fee.';

  @override
  String docsRenewTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n documents need renewing',
      one: '1 document needs renewing',
    );
    return '$_temp0';
  }

  @override
  String get docsUnlockToView => 'Unlock with device authentication to view';

  @override
  String get docsUpdated => 'Recently updated';

  @override
  String get docsValid => 'Valid';

  @override
  String get docsVault => 'Documents';

  @override
  String durationHm(String h, String m) {
    return '${h}h ${m}m';
  }

  @override
  String get emergKindAll3 => 'Police · Fire · Medical';

  @override
  String get emergKindAllServices => 'All services';

  @override
  String get emergKindAmbRescue => 'Ambulance & rescue';

  @override
  String get emergKindAmbulance => 'Ambulance';

  @override
  String get emergKindFire => 'Fire';

  @override
  String get emergKindFireRescue => 'Fire & rescue';

  @override
  String get emergKindGas => 'Gas leak';

  @override
  String get emergKindGsm => 'Works on most GSM networks';

  @override
  String get emergKindHelpline => 'Helpline';

  @override
  String get emergKindHighway => 'Highway';

  @override
  String get emergKindMaritime => 'Maritime';

  @override
  String get emergKindMedAdvice => 'Urgent medical advice';

  @override
  String get emergKindMedical => 'Medical';

  @override
  String get emergKindMental => 'Mental health';

  @override
  String get emergKindNonUrgent => 'Non-urgent';

  @override
  String get emergKindPoison => 'Poison';

  @override
  String get emergKindPolice => 'Police emergency';

  @override
  String get emergKindRouted => 'Widely routed';

  @override
  String get emergKindTraffic => 'Traffic';

  @override
  String get emergKindTrafficInfo => 'Traffic information';

  @override
  String get emergNameAmbulance => 'Ambulance';

  @override
  String get emergNameCivilDefence => 'Civil Defence';

  @override
  String get emergNameCoastGuard => 'Coast Guard';

  @override
  String get emergNameCrisisLifeline => 'Crisis Lifeline';

  @override
  String get emergNameEdhiAmbulance => 'Edhi Ambulance';

  @override
  String get emergNameEmergency => 'Emergency';

  @override
  String get emergNameFire => 'Fire';

  @override
  String get emergNameFireBrigade => 'Fire Brigade';

  @override
  String get emergNameFireCivilDefence => 'Fire (Civil Defence)';

  @override
  String get emergNameGasEmergency => 'Gas emergency';

  @override
  String get emergNameInternational => 'International Emergency';

  @override
  String get emergNameLocal => 'Local Emergency';

  @override
  String get emergNameMotorwayPolice => 'Motorway Police';

  @override
  String get emergNameNhs111 => 'NHS 111';

  @override
  String get emergNamePoisonControl => 'Poison Control';

  @override
  String get emergNamePolice => 'Police';

  @override
  String get emergNamePoliceNonEmergency => 'Police non-emergency';

  @override
  String get emergNameRedCrescent => 'Red Crescent';

  @override
  String get emergNameRescue1122 => 'Rescue 1122';

  @override
  String get emergNameRoadside => 'Roadside';

  @override
  String get emergNameTraffic => 'Traffic';

  @override
  String get emergNameUnifiedEmergency => 'Unified Emergency';

  @override
  String get emergNameWomenHelpline => 'Women Helpline';

  @override
  String emergencyCall(String service, String number) {
    return 'Call $service at $number';
  }

  @override
  String emergencyDialFailed(String number) {
    return 'Couldn’t open the phone app. Dial $number yourself.';
  }

  @override
  String emergencyDialUnavailable(String number) {
    return 'This device can’t make calls. Dial $number from a phone.';
  }

  @override
  String get emergencyDocuments => 'Identity documents';

  @override
  String get emergencyLocationShared => 'Location copied to share';

  @override
  String get emergencyMedical => 'Medical details';

  @override
  String get emergencyNoteText =>
      'Emergency numbers can usually be dialled with no credit and no SIM. 112 is routed in most countries.';

  @override
  String get emergencyNoteTitle => 'Numbers work without signal';

  @override
  String get emergencyServices => 'Other services';

  @override
  String get emergencySetUp => 'Set up';

  @override
  String get emergencyShareLocation => 'Share my location';

  @override
  String get emergencyYourInfo => 'Your information';

  @override
  String get eventsNoMatch => 'No events match';

  @override
  String get eventsNoMatchText => 'Try a different word.';

  @override
  String eventsPeople(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n going',
      one: '1 going',
    );
    return '$_temp0';
  }

  @override
  String get eventsSeedE2 => 'Team lunch';

  @override
  String get eventsSeedE3 => 'Dentist';

  @override
  String get eventsSeedW2 => 'The corner place';

  @override
  String get eventsSeedW3 => 'Smile Studio';

  @override
  String get eventsUpcoming => 'Upcoming';

  @override
  String get expensesAdd => 'Add expense';

  @override
  String get expensesBalance => 'Balance';

  @override
  String get expensesBudgetUse => 'Budget used';

  @override
  String get expensesBudgets => 'Budgets';

  @override
  String get expensesCatBills => 'Bills';

  @override
  String get expensesCatEating => 'Eating out';

  @override
  String get expensesCatGroceries => 'Groceries';

  @override
  String get expensesCatHealth => 'Health';

  @override
  String get expensesCatOther => 'Other';

  @override
  String get expensesCatTransport => 'Transport';

  @override
  String get expensesCategories => 'By category';

  @override
  String get expensesCategory => 'Category';

  @override
  String get expensesDailyAvg => 'Daily average';

  @override
  String get expensesIncome => 'Income';

  @override
  String get expensesInsight1Text => 'Compared with your three-month average.';

  @override
  String get expensesInsight1Title => 'Groceries are up 12%';

  @override
  String get expensesInsight2Text =>
      'At this pace you finish about 8% under budget.';

  @override
  String get expensesInsight2Title => 'On track for the month';

  @override
  String get expensesInsights => 'Insights';

  @override
  String get expensesMethodAutoDebit => 'Auto-debit';

  @override
  String expensesMonthlyOn(int day) {
    return 'monthly, on the ${day}th';
  }

  @override
  String get expensesNoMatch => 'No transactions match';

  @override
  String get expensesNoMatchText => 'Try another category or clear the search.';

  @override
  String expensesOfBudget(String pct, String budget) {
    return '$pct of your $budget budget';
  }

  @override
  String get expensesRange => 'Range';

  @override
  String get expensesRec1 => 'Internet';

  @override
  String get expensesRec2 => 'Electricity';

  @override
  String get expensesRecurring => 'Recurring';

  @override
  String get expensesSpent => 'Spent this month';

  @override
  String get expensesTransactions => 'Transactions';

  @override
  String get expensesTrend => 'This week';

  @override
  String expensesTrendCap(String avg) {
    return 'Averaging $avg a day';
  }

  @override
  String get expensesTxAirport => 'Ride to airport';

  @override
  String get expensesTxCoffee => 'Coffee — Chaaye Khana';

  @override
  String get expensesTxElectricity => 'Electricity bill';

  @override
  String get expensesTxFuel => 'Fuel — Shell';

  @override
  String get expensesTxInternet => 'Internet';

  @override
  String get expensesTxMetro => 'Metro Cash & Carry';

  @override
  String get expensesTxPharmacy => 'Pharmacy';

  @override
  String get expensesTxSalary => 'Salary';

  @override
  String expensesWhenTime(String day, String time) {
    return '$day · $time';
  }

  @override
  String get exploreAround => 'Around you';

  @override
  String get exploreAroundSub => 'Local services, kept current';

  @override
  String get exploreBackToHome => 'Back to home';

  @override
  String get exploreCollections => 'Collections';

  @override
  String get exploreCollectionsSub => 'Curated for a quiet moment';

  @override
  String get exploreCricket => 'Cricket';

  @override
  String get exploreCricketSub => 'Live · 2nd Test, day 2';

  @override
  String get exploreFeatured => 'Featured collection';

  @override
  String get exploreNearby => 'Nearby';

  @override
  String get exploreNearbySub => 'Within walking distance';

  @override
  String exploreRainLabel(String value) {
    return 'Rain $value';
  }

  @override
  String get exploreReads => 'Today’s reads';

  @override
  String get exploreReadsSub => 'Balanced, no doomscroll';

  @override
  String get exploreScorecard => 'Scorecard';

  @override
  String get exploreSubGlobal => 'Weather, reading and what’s around you';

  @override
  String get exploreSubLocal => 'Local services, scores and reading';

  @override
  String exploreSunsetLabel(String value) {
    return 'Sunset $value';
  }

  @override
  String get exploreWeather => 'Weather';

  @override
  String exploreWeatherDesc(String condition, String feels) {
    return '$condition · $feels';
  }

  @override
  String exploreWeatherSub(String city, int n) {
    return '$city · updated $n min ago';
  }

  @override
  String get exploreWeatherToast => 'Weather refreshed';

  @override
  String exploreWindLabel(String value) {
    return 'Wind $value';
  }

  @override
  String exploreWindValue(String value, String unit) {
    return '$value $unit';
  }

  @override
  String get featureAge => 'Age Calculator';

  @override
  String get featureAlarms => 'Alarms';

  @override
  String get featureAqi => 'Air Quality';

  @override
  String get featureAyah => 'Ayah of the Day';

  @override
  String get featureBabybudget => 'Baby Budget';

  @override
  String get featureBills => 'Bills';

  @override
  String get featureBirthdays => 'Birthdays';

  @override
  String get featureBmi => 'BMI Calculator';

  @override
  String get featureCalculator => 'Calculator';

  @override
  String get featureCalendar => 'Calendar';

  @override
  String get featureCommittee => 'Committee';

  @override
  String get featureCompound => 'Compound Interest';

  @override
  String get featureConverter => 'Unit Converter';

  @override
  String get featureCricket => 'Cricket';

  @override
  String get featureCurrency => 'Currency';

  @override
  String get featureCycle => 'Cycle Tracker';

  @override
  String get featureDatecalc => 'Date Calculator';

  @override
  String get featureDocscan => 'Document Scanner';

  @override
  String get featureDocuments => 'Documents';

  @override
  String get featureDuas => 'Daily Duas';

  @override
  String get featureEmergency => 'Emergency';

  @override
  String get featureEvents => 'Events';

  @override
  String get featureExpenses => 'Expenses';

  @override
  String get featureFaraid => 'Faraid';

  @override
  String get featureFasting => 'Fasting Tracker';

  @override
  String get featureFlights => 'Flights';

  @override
  String get featureFocus => 'Focus Timer';

  @override
  String get featureFuel => 'Fuel Prices';

  @override
  String get featureFuelcost => 'Fuel Cost';

  @override
  String get featureGoals => 'Savings Goals';

  @override
  String get featureGoldrates => 'Currency & Gold';

  @override
  String get featureHabits => 'Habits';

  @override
  String get featureHadith => 'Hadith';

  @override
  String get featureHealth => 'Health Records';

  @override
  String get featureHijri => 'Islamic Calendar';

  @override
  String get featureHolidays => 'Public Holidays';

  @override
  String get featureInstallments => 'Installments';

  @override
  String get featureLearning => 'Learning & Growth';

  @override
  String get featureLedger => 'Lending Ledger';

  @override
  String get featureLoadshed => 'Loadshedding';

  @override
  String get featureLoan => 'Loan / EMI';

  @override
  String get featureMarkets => 'Markets';

  @override
  String get featureMealplan => 'Meal Planner';

  @override
  String get featureMediasaver => 'Media Saver';

  @override
  String get featureMeds => 'Medication';

  @override
  String get featureMosques => 'Nearby Mosques';

  @override
  String get featureNames99 => '99 Names';

  @override
  String get featureNatsavings => 'National Savings';

  @override
  String get featureNews => 'News';

  @override
  String get featureNotes => 'Notes';

  @override
  String get featurePackages => 'Mobile Packages';

  @override
  String get featureParcel => 'Parcel Tracker';

  @override
  String get featurePassport => 'Passport Photos';

  @override
  String get featurePlay => 'Play';

  @override
  String get featurePrayer => 'Prayer Times';

  @override
  String get featurePraytrack => 'Prayer Tracker';

  @override
  String get featurePregnancy => 'Pregnancy';

  @override
  String get featurePrizebonds => 'Prize Bonds';

  @override
  String get featureQibla => 'Qibla Compass';

  @override
  String get featureQr => 'QR Scanner';

  @override
  String get featureQuran => 'Al-Qur’an';

  @override
  String get featureQuransearch => 'Search the Qur’an';

  @override
  String get featureRamadan => 'Ramadan';

  @override
  String get featureRecipes => 'Recipes';

  @override
  String get featureReminders => 'Reminders';

  @override
  String get featureShopping => 'Shopping List';

  @override
  String get featureSpeedtest => 'Speed Test';

  @override
  String get featureStopwatch => 'Stopwatch';

  @override
  String get featureStreak => 'Daily Streak';

  @override
  String get featureSubs => 'Subscriptions';

  @override
  String get featureSunmoon => 'Sun & Moon';

  @override
  String get featureTaraweeh => 'Taraweeh';

  @override
  String get featureTasbih => 'Tasbih';

  @override
  String get featureTax => 'Tax Calculator';

  @override
  String get featureTimer => 'Timer';

  @override
  String get featureTipsplit => 'Tip & Split';

  @override
  String get featureTodos => 'To-dos';

  @override
  String get featureTrains => 'Trains';

  @override
  String get featureVaccines => 'Vaccinations';

  @override
  String get featureVehicle => 'Vehicle & Fines';

  @override
  String get featureWastatus => 'WhatsApp Status';

  @override
  String get featureWater => 'Water';

  @override
  String get featureWeather => 'Weather';

  @override
  String get featureWorldclock => 'World Clock';

  @override
  String get featureZakat => 'Zakat Calculator';

  @override
  String featuredCalmDays(int n) {
    return '$n days';
  }

  @override
  String featuredCalmEach(int n) {
    return '$n min each';
  }

  @override
  String get featuredCalmText =>
      'Small routines for planning, spending and winding down — one for each day.';

  @override
  String get featuredCalmTitle => 'A calmer week, in seven steps';

  @override
  String get featuredDuasAudio => 'Audio included';

  @override
  String featuredDuasCount(int n) {
    return '$n duas';
  }

  @override
  String get featuredDuasText =>
      'Short supplications for the commute, the queue and the quiet minute before sleep.';

  @override
  String get featuredDuasTitle => 'Forty duas for ordinary days';

  @override
  String get featuredFree => 'Free';

  @override
  String featuredMinutes(int n) {
    return '$n min';
  }

  @override
  String get fixtureSampleA11y =>
      'Sample data. The figures in this tool are examples, not your own.';

  @override
  String get flightsActualDep => 'Actual departure';

  @override
  String get flightsAircraft => 'Aircraft & route';

  @override
  String get flightsAltitude => 'Altitude';

  @override
  String flightsAltitudeFeet(String feet) {
    return '$feet ft';
  }

  @override
  String get flightsArrivals => 'Arrivals';

  @override
  String get flightsBoard => 'Board';

  @override
  String get flightsCruise => 'Cruising';

  @override
  String flightsCruiseSub(String altitude, String speed) {
    return '$altitude · $speed';
  }

  @override
  String get flightsDelayed => 'Delayed';

  @override
  String get flightsDepartures => 'Departures';

  @override
  String get flightsDistance => 'Route distance';

  @override
  String get flightsEnRoute => 'En route';

  @override
  String get flightsEstArrival => 'Estimated arrival';

  @override
  String flightsEta(String time) {
    return 'ETA $time';
  }

  @override
  String flightsGate(String gate) {
    return 'Gate $gate';
  }

  @override
  String flightsLateBy(int n) {
    return '$n minutes late';
  }

  @override
  String flightsLateShort(int n) {
    return '+${n}m';
  }

  @override
  String get flightsLive => 'Live board';

  @override
  String get flightsMap => 'Live position';

  @override
  String get flightsNoMatch => 'No flights on this board';

  @override
  String get flightsNoMatchText =>
      'Try arrivals, or search a flight number or airport.';

  @override
  String get flightsOnTime => 'On time';

  @override
  String get flightsRegistration => 'Registration';

  @override
  String flightsRemaining(String distance) {
    return '$distance to run';
  }

  @override
  String get flightsScheduled => 'Scheduled';

  @override
  String get flightsScheduledDep => 'Scheduled departure';

  @override
  String get flightsSearch => 'Flight number, route or airport';

  @override
  String flightsShareText(String flight, String from, String to, String time) {
    return '$flight · $from → $to · ETA $time';
  }

  @override
  String get flightsSpeed => 'Ground speed';

  @override
  String get flightsStDelayed => 'Delayed';

  @override
  String get flightsStEnroute => 'En route';

  @override
  String get flightsStLanded => 'Landed';

  @override
  String get flightsStScheduled => 'Scheduled';

  @override
  String get flightsTerminal => 'Terminal';

  @override
  String flightsTerminalGate(String terminal, String gate) {
    return '$terminal · Gate $gate';
  }

  @override
  String get flightsTimeline => 'Timeline';

  @override
  String get flightsTotal => 'Flights';

  @override
  String get flightsTrack => 'Track this flight';

  @override
  String get flightsTracked => 'Tracked';

  @override
  String flightsTracking(String flight) {
    return 'Tracking $flight';
  }

  @override
  String get flightsType => 'Aircraft';

  @override
  String freshAgoMin(int n) {
    return 'Updated $n min ago';
  }

  @override
  String freshAgoSec(int n) {
    return 'Updated $n sec ago';
  }

  @override
  String get freshAnnual => 'Current tax year';

  @override
  String freshAt(String time) {
    return 'Updated at $time';
  }

  @override
  String get freshCached => 'Cached';

  @override
  String get freshComputed => 'Calculated for your location';

  @override
  String get freshComputedLive => 'Calculated live';

  @override
  String get freshDaily => 'Updated today';

  @override
  String get freshDelayed => 'Delayed 15 min';

  @override
  String get freshDraw => 'Latest draw';

  @override
  String freshForCity(String city) {
    return 'For $city';
  }

  @override
  String get freshLive => 'Live';

  @override
  String get freshLocal => 'Stored on this device';

  @override
  String freshOn(String date) {
    return 'Updated $date';
  }

  @override
  String get freshSample => 'Sample data';

  @override
  String freshReferenceCopy(String claim) {
    return '$claim. Reference copy, not a claim about this build';
  }

  @override
  String get freshSession => 'Kept until you close Lume';

  @override
  String get freshStatic => 'Reference text';

  @override
  String get freshWeekly => 'Updated this week';

  @override
  String get fuelPetrol => 'Petrol';

  @override
  String get fuelSourceOgra => 'OGRA';

  @override
  String get greetAfternoon => 'Good afternoon';

  @override
  String get greetEvening => 'Good evening';

  @override
  String get greetLate => 'Still up';

  @override
  String get greetMorning => 'Good morning';

  @override
  String greetNamed(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get greetWindDown => 'Winding down';

  @override
  String get habitFajr => 'Fajr on time';

  @override
  String get habitQuran => 'Qur’an daily';

  @override
  String get habitSteps => 'Walk 6k steps';

  @override
  String get habitWater => '8 glasses';

  @override
  String get hadithBrowse => 'Browse';

  @override
  String get hadithCollection => 'Collection';

  @override
  String get hadithGradeHasan => 'Hasan';

  @override
  String get hadithGradeSahih => 'Sahih';

  @override
  String hadithNarratedBy(String name) {
    return 'Narrated by: $name';
  }

  @override
  String get hadithNoMatch => 'Nothing found';

  @override
  String get hadithNoMatchText => 'Try another collection or a shorter search.';

  @override
  String hadithOpened(String source, String number) {
    return '$source $number';
  }

  @override
  String hadithReference(String source, String number) {
    return '$source · $number';
  }

  @override
  String get hadithSaved => 'Saved to your reading';

  @override
  String get hadithSavedLabel => 'Saved';

  @override
  String get hadithSearch => 'Search hadith';

  @override
  String get hadithUnsaved => 'Removed from your reading';

  @override
  String get heatLevelAll => 'all';

  @override
  String get heatLevelMost => 'most';

  @override
  String get heatLevelNone => 'none';

  @override
  String get heatLevelSome => 'some';

  @override
  String get heroHighlights => 'Highlights';

  @override
  String get hijriMonth1 => 'Muharram';

  @override
  String get hijriMonth10 => 'Shawwal';

  @override
  String get hijriMonth11 => 'Dhul-Qa‘dah';

  @override
  String get hijriMonth12 => 'Dhul-Hijjah';

  @override
  String get hijriMonth2 => 'Safar';

  @override
  String get hijriMonth3 => 'Rabi‘ al-Awwal';

  @override
  String get hijriMonth4 => 'Rabi‘ al-Thani';

  @override
  String get hijriMonth5 => 'Jumada al-Ula';

  @override
  String get hijriMonth6 => 'Jumada al-Akhirah';

  @override
  String get hijriMonth7 => 'Rajab';

  @override
  String get hijriMonth8 => 'Sha‘ban';

  @override
  String get hijriMonth9 => 'Ramadan';

  @override
  String get holidayBoxingDay => 'Boxing Day';

  @override
  String get holidayChristmas => 'Christmas';

  @override
  String get holidayChristmasDay => 'Christmas Day';

  @override
  String get holidayCommemorationDay => 'Commemoration Day';

  @override
  String get holidayDiwali => 'Diwali';

  @override
  String get holidayEarlyMay => 'Early May';

  @override
  String get holidayEidAlAdha => 'Eid al-Adha';

  @override
  String get holidayEidAlFitr => 'Eid al-Fitr';

  @override
  String get holidayFoundingDay => 'Founding Day';

  @override
  String get holidayGandhiJayanti => 'Gandhi Jayanti';

  @override
  String get holidayGoodFriday => 'Good Friday';

  @override
  String get holidayHoli => 'Holi';

  @override
  String get holidayIndependenceDay => 'Independence Day';

  @override
  String get holidayIqbalDay => 'Iqbal Day';

  @override
  String get holidayIslamicNewYear => 'Islamic New Year';

  @override
  String get holidayKashmirDay => 'Kashmir Day';

  @override
  String get holidayKindBank => 'Bank holiday';

  @override
  String get holidayKindFederal => 'Federal';

  @override
  String get holidayKindGazetted => 'Gazetted';

  @override
  String get holidayKindNational => 'National';

  @override
  String get holidayKindPublic => 'Public';

  @override
  String get holidayLaborDay => 'Labor Day';

  @override
  String get holidayLabourDay => 'Labour Day';

  @override
  String get holidayMlkDay => 'MLK Jr. Day';

  @override
  String get holidayNationalDay => 'National Day';

  @override
  String get holidayNewYearsDay => 'New Year’s Day';

  @override
  String get holidayPakistanDay => 'Pakistan Day';

  @override
  String get holidayQuaidDay => 'Quaid-e-Azam Day';

  @override
  String get holidayRepublicDay => 'Republic Day';

  @override
  String get holidaySummer => 'Summer';

  @override
  String get holidayThanksgiving => 'Thanksgiving';

  @override
  String homeAyahProgress(int n, int total, int min) {
    return 'Ayah $n of $total · about $min min left';
  }

  @override
  String homeContinueSurah(String surah) {
    return 'Continue $surah';
  }

  @override
  String get homeDiscover => 'Discover';

  @override
  String get homeDiscoverSub => 'Because you check these often';

  @override
  String homeEffective(String date, String source) {
    return 'Effective $date · $source';
  }

  @override
  String homeFeelsLike(String temp) {
    return 'Feels like $temp';
  }

  @override
  String get homeGlance => 'At a glance';

  @override
  String get homeGlanceGeneral => 'What matters in the next few hours';

  @override
  String get homeGlanceMuslim => 'Prayer, reading and what’s next';

  @override
  String get homeLiveNow => 'Right now';

  @override
  String homeLiveNowSub(String time) {
    return 'As of $time';
  }

  @override
  String homeNextOutage(String time) {
    return 'Next outage $time';
  }

  @override
  String get homeNextPrayer => 'Next prayer';

  @override
  String get homeNextUp => 'next up';

  @override
  String homeOutageArea(String area, int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours hours',
      one: '1 hour',
    );
    return '$area · $_temp0';
  }

  @override
  String get homeQuickDefault => 'The eight you reach for most';

  @override
  String get homeQuickFromInterests => 'Picked from your interests';

  @override
  String get homeQuickTools => 'Quick tools';

  @override
  String get homeRightNow => 'Right now';

  @override
  String get homeSearchEverything => 'Search everything';

  @override
  String homeTasksLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tasks left today',
      one: '1 task left today',
      zero: 'Nothing left today',
    );
    return '$_temp0';
  }

  @override
  String homeTasksNext(String task, String time) {
    return 'Next: $task · $time';
  }

  @override
  String get homeToGo => 'to go';

  @override
  String homeTomorrowIn(String city) {
    return 'Tomorrow in $city';
  }

  @override
  String get homeUpcoming => 'Coming up';

  @override
  String get homeUpcomingSub => 'The next few days';

  @override
  String homeWeatherAnd(String temp, String condition) {
    return '$temp and $condition';
  }

  @override
  String get homeYourProfile => 'Your profile';

  @override
  String get igEveryday => 'Everyday life';

  @override
  String get igFaith => 'Islamic features';

  @override
  String get igHealth => 'Health & wellness';

  @override
  String get igMoney => 'Money & finance';

  @override
  String get igNews => 'News & entertainment';

  @override
  String get igTravel => 'Travel & getting around';

  @override
  String get intAlarms => 'Alarms & timers';

  @override
  String get intBills => 'Bills';

  @override
  String get intCalendar => 'Calendar';

  @override
  String get intConvert => 'Converters';

  @override
  String get intCricket => 'Cricket';

  @override
  String get intDuas => 'Duas & dhikr';

  @override
  String get intExpenses => 'Expenses';

  @override
  String get intFitness => 'Fitness';

  @override
  String get intFlights => 'Flights';

  @override
  String get intFuel => 'Fuel';

  @override
  String get intHabits => 'Habits';

  @override
  String get intHadith => 'Hadith';

  @override
  String get intMarkets => 'Markets';

  @override
  String get intMaths => 'Calculators';

  @override
  String get intMeds => 'Medication';

  @override
  String get intNearby => 'Nearby places';

  @override
  String get intNews => 'News';

  @override
  String get intNotes => 'Notes';

  @override
  String get intPrayer => 'Prayer times';

  @override
  String get intQuotes => 'Daily quotes';

  @override
  String get intQuran => 'Qur’an';

  @override
  String get intRamadan => 'Ramadan';

  @override
  String get intRates => 'Rates & gold';

  @override
  String get intReading => 'Reading';

  @override
  String get intSavings => 'Saving & goals';

  @override
  String get intSleep => 'Sleep';

  @override
  String get intTasks => 'Tasks & to-dos';

  @override
  String get intTrains => 'Trains';

  @override
  String get intWater => 'Water';

  @override
  String get intWeather => 'Weather';

  @override
  String get intZakat => 'Zakat & giving';

  @override
  String get learningConsistency => 'Consistency';

  @override
  String learningCourseMeta(String provider, String minutes) {
    return '$provider · $minutes min';
  }

  @override
  String get learningCourses => 'Courses';

  @override
  String get learningGoal => 'Weekly goal';

  @override
  String get learningInProgress => 'In progress';

  @override
  String get learningInsight1Text =>
      'Your 20-minute sessions are completed twice as often as your hour-long ones.';

  @override
  String get learningInsight1Title => 'Short sessions stick';

  @override
  String get learningInsight2Text =>
      'Nine days running, well ahead of your other courses.';

  @override
  String get learningInsight2Title => 'Arabic is your strongest streak';

  @override
  String get learningMilestone => 'Next milestone';

  @override
  String learningMilestoneValue(String n) {
    return '$n min';
  }

  @override
  String learningStreak(String n) {
    return '$n-day streak';
  }

  @override
  String get learningStreakLabel => 'Streak';

  @override
  String get learningThisWeek => 'This week';

  @override
  String get learningWeek => 'This week';

  @override
  String get levyCorporate => 'Corporate tax';

  @override
  String get levyEobi => 'EOBI';

  @override
  String get levyGosi => 'Social insurance (GOSI)';

  @override
  String get levyGst => 'GST';

  @override
  String get levyMedicare => 'Medicare';

  @override
  String get levyNi => 'National Insurance';

  @override
  String get levyPension => 'Pension contribution';

  @override
  String get levyPf => 'Provident Fund';

  @override
  String get levySocialSecurity => 'Social Security';

  @override
  String get levyVat => 'VAT';

  @override
  String get levyZakatRate => 'Zakat';

  @override
  String get loadshedOff => 'Power is off';

  @override
  String loadshedUntil(String time) {
    return 'until $time';
  }

  @override
  String get loanAmortisation => 'Amortisation';

  @override
  String get loanBalance => 'Balance';

  @override
  String get loanCompare => 'If the rate changed';

  @override
  String get loanHigherRate => 'Two points higher';

  @override
  String get loanInterest => 'Interest';

  @override
  String get loanInterestShare => 'Interest share';

  @override
  String get loanLowerRate => 'Two points lower';

  @override
  String get loanMonthly => 'Monthly payment';

  @override
  String loanOver(int n, String count) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'over $count payments',
      one: 'over 1 payment',
    );
    return '$_temp0';
  }

  @override
  String get loanPrincipal => 'Loan amount';

  @override
  String get loanPrincipalShort => 'Principal';

  @override
  String get loanRate => 'Interest rate';

  @override
  String loanRateAt(String rate) {
    return 'At $rate%';
  }

  @override
  String get loanSplit => 'Principal vs interest';

  @override
  String get loanTenure => 'Tenure';

  @override
  String get loanTotalInterest => 'Total interest';

  @override
  String get loanTotalPaid => 'Total repaid';

  @override
  String get loanYourRate => 'Your rate';

  @override
  String get marketPk => 'Pakistan';

  @override
  String get marketsClosed => 'Market closed';

  @override
  String marketsHoliday(String holiday) {
    return 'Closed for $holiday';
  }

  @override
  String get marketsOpen => 'Market open';

  @override
  String get marketsWeekend => 'Closed for the weekend';

  @override
  String get methodEgyptian => 'Egyptian';

  @override
  String get methodIsna => 'ISNA';

  @override
  String get methodKarachi => 'University of Karachi';

  @override
  String get methodMwl => 'Muslim World League';

  @override
  String get methodUmmAlQura => 'Umm al-Qura';

  @override
  String get moonFirstQuarter => 'First quarter';

  @override
  String get moonFull => 'Full';

  @override
  String get moonLastQuarter => 'Last quarter';

  @override
  String get moonNew => 'New';

  @override
  String get moonWanCrescent => 'Waning crescent';

  @override
  String get moonWanGibbous => 'Waning gibbous';

  @override
  String get moonWaxCrescent => 'Waxing crescent';

  @override
  String get moonWaxGibbous => 'Waxing gibbous';

  @override
  String get nActComplete => 'Open tasks';

  @override
  String get nActPay => 'Pay';

  @override
  String get nActTrack => 'Track';

  @override
  String get nActViewDoc => 'View document';

  @override
  String get nActViewFlight => 'View flight';

  @override
  String get nActViewMarket => 'View market';

  @override
  String get nActViewPrayer => 'View prayer';

  @override
  String get nActViewTrain => 'View train';

  @override
  String get nActViewWeather => 'View weather';

  @override
  String get nActioned => 'Done';

  @override
  String get nAllRead => 'You’re all caught up';

  @override
  String nBillBody(String amount) {
    return '$amount is past its due date.';
  }

  @override
  String nBillDueTitle(String name) {
    return '$name is due soon';
  }

  @override
  String get nBillPrivate => 'A bill is past its due date.';

  @override
  String nBillTitle(int n) {
    return '$n bill needs attention';
  }

  @override
  String get nCategory => 'Category';

  @override
  String nDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n d ago',
      one: '1 d ago',
    );
    return '$_temp0';
  }

  @override
  String get nDismiss => 'Dismiss';

  @override
  String nDocBody(int n, String date) {
    return 'Expires in $n days, on $date.';
  }

  @override
  String get nDocPrivate => 'A document is expiring soon.';

  @override
  String nDocTitle(String name) {
    return 'Renew your $name';
  }

  @override
  String nDueInDays(int n) {
    return 'due in $n days';
  }

  @override
  String get nEmptyCaughtUp => 'You’re all caught up';

  @override
  String get nEmptyText => 'New alerts and updates will appear here.';

  @override
  String get nEmptyTitle => 'Nothing to tell you';

  @override
  String get nErrorText => 'Nothing was lost. Try again.';

  @override
  String get nErrorTitle => 'Notifications could not be loaded';

  @override
  String get nExpired => 'Expired';

  @override
  String nFlightBody(int n, String eta, String to) {
    return '$n minutes late · now arriving $eta at $to';
  }

  @override
  String nFlightTitle(String no) {
    return '$no is delayed';
  }

  @override
  String nForecastBody(String hi, String lo, String rain) {
    return 'High $hi · Low $lo · $rain% Rain';
  }

  @override
  String nGroupBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n more updates',
      one: '1 more update',
    );
    return '$_temp0';
  }

  @override
  String nGroupTitle(String name) {
    return '$name activity';
  }

  @override
  String nHabitBody(int n) {
    return 'You’re on a $n-day streak.';
  }

  @override
  String nHabitTitle(int n) {
    return '$n habits left today';
  }

  @override
  String get nHidden => 'Content hidden';

  @override
  String nHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hr ago',
      one: '1 hr ago',
    );
    return '$_temp0';
  }

  @override
  String get nMarkAllRead => 'Mark all as read';

  @override
  String nMarketBody(String value, String exchange) {
    return 'Now $value on $exchange.';
  }

  @override
  String nMarketTitle(String name, String pct) {
    return '$name moved $pct';
  }

  @override
  String nMedBody(String at) {
    return 'Your next dose is at $at.';
  }

  @override
  String get nMedPrivate => 'You have a dose due.';

  @override
  String get nMedTitle => 'Time for your medication';

  @override
  String nMinsAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n min ago',
      one: '1 min ago',
    );
    return '$_temp0';
  }

  @override
  String get nNow => 'just now';

  @override
  String nOutageTitle(String time) {
    return 'Power off at $time';
  }

  @override
  String nParcelBody(String carrier, String eta) {
    return '$carrier · expected $eta';
  }

  @override
  String nParcelTitle(String item) {
    return '$item is on its way';
  }

  @override
  String get nPriCritical => 'Critical';

  @override
  String get nPriHigh => 'Important';

  @override
  String get nPushAllow => 'Enable notifications';

  @override
  String get nPushNotNow => 'Not now';

  @override
  String get nPushOff => 'Off';

  @override
  String get nPushOn => 'On';

  @override
  String get nPushText =>
      'Useful alerts for the things you already follow — and nothing else.';

  @override
  String get nPushTitle => 'Stay informed';

  @override
  String get nQuietText =>
      'Nothing will interrupt you, but everything still arrives here.';

  @override
  String get nQuietTitle => 'Quiet hours are on';

  @override
  String get nRestored => 'Dismissed notifications restored';

  @override
  String get nSettings => 'Notification settings';

  @override
  String get nSettingsSub => 'What Lume may tell you, and when';

  @override
  String nSubBody(int n, String amount) {
    return 'In $n days · $amount';
  }

  @override
  String nSubPrivate(int n) {
    return 'A subscription renews in $n days.';
  }

  @override
  String nSubTitle(String name) {
    return '$name renews soon';
  }

  @override
  String get nTabImportant => 'Important';

  @override
  String get nTabUnread => 'Unread';

  @override
  String nTaskNext(String title) {
    return 'Next: $title';
  }

  @override
  String nTasksLeft(int n) {
    return '$n tasks left today';
  }

  @override
  String nTrainBody(int n, String next) {
    return '$n minutes behind · next stop $next';
  }

  @override
  String nTrainTitle(String name) {
    return '$name is running late';
  }

  @override
  String get nUnread => 'Unread';

  @override
  String nUnreadCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n unread',
      one: '1 unread',
    );
    return '$_temp0';
  }

  @override
  String nWeatherTitle(String city) {
    return 'Tomorrow in $city';
  }

  @override
  String get navAccount => 'Account';

  @override
  String get navExplore => 'Explore';

  @override
  String get navHome => 'Home';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navProfile => 'Profile';

  @override
  String get navToday => 'Today';

  @override
  String get navTools => 'Tools';

  @override
  String get navTrains => 'Trains';

  @override
  String get ncatDocuments => 'Documents';

  @override
  String get ncatFaith => 'Faith';

  @override
  String get ncatFinance => 'Money';

  @override
  String get ncatHealth => 'Health';

  @override
  String get ncatMarkets => 'Markets';

  @override
  String get ncatNews => 'News';

  @override
  String get ncatPersonal => 'Personal';

  @override
  String get ncatReminders => 'Reminders';

  @override
  String get ncatSystem => 'System';

  @override
  String get ncatTravel => 'Travel';

  @override
  String get ncatWeather => 'Weather';

  @override
  String get nearbyChaiShai => 'Chai Shai';

  @override
  String nearbyChaiShaiSub(String time) {
    return 'Quiet café · open till $time';
  }

  @override
  String get nearbyHillPark => 'Hill Park';

  @override
  String get nearbyHillParkSub => 'Good for a sunset walk';

  @override
  String nearbyKilometres(String n) {
    return '$n km';
  }

  @override
  String nearbyMetres(int n) {
    return '$n m';
  }

  @override
  String get nearbyTooba => 'Masjid-e-Tooba';

  @override
  String nearbyToobaSub(String time) {
    return 'Jamaat for Asr at $time';
  }

  @override
  String newsAgoHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hr',
      one: '1 hr',
    );
    return '$_temp0';
  }

  @override
  String newsAgoMinutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n min',
      one: '1 min',
    );
    return '$_temp0';
  }

  @override
  String get newsCatBusiness => 'Business';

  @override
  String get newsCatHealth => 'Health';

  @override
  String get newsCatKarachi => 'Karachi';

  @override
  String get newsCatLifestyle => 'Lifestyle';

  @override
  String get newsCatMoney => 'Money';

  @override
  String get newsCatProductivity => 'Productivity';

  @override
  String get newsCatSport => 'Sport';

  @override
  String get newsCatTechnology => 'Technology';

  @override
  String get newsCatTop => 'Top';

  @override
  String get newsCatWellbeing => 'Wellbeing';

  @override
  String get newsCatWorld => 'World';

  @override
  String get newsEdition => 'Your edition';

  @override
  String get newsEmptyText =>
      'Try another category, or widen your sources in settings.';

  @override
  String get newsEmptyTitle => 'Nothing in this category yet';

  @override
  String get newsHeadlineGlobalCoastal =>
      'Coastal cities publish a shared adaptation blueprint';

  @override
  String get newsHeadlineGlobalOnDevice =>
      'On-device models are quietly reshaping what phones can do offline';

  @override
  String get newsHeadlineGlobalRates =>
      'Central banks signal a slower path on rate cuts into the new year';

  @override
  String get newsHeadlineGlobalTactics =>
      'The tactical shift that decided the weekend’s biggest fixture';

  @override
  String get newsHeadlineGlobalWalk =>
      'A short walk after meals does more than a long one before bed';

  @override
  String get newsHeadlinePkDengue =>
      'Provincial dengue surveillance moves to a weekly reporting cycle';

  @override
  String get newsHeadlinePkSquad =>
      'Pakistan name a 16-player squad for the home Test series';

  @override
  String get newsHeadlinePkStartups =>
      'Karachi start-ups raised \$84m this quarter, led by fintech';

  @override
  String get newsHeadlinePkTrade =>
      'Regional trade corridor talks resume after a six-month pause';

  @override
  String get newsLatest => 'Latest';

  @override
  String get newsLoadshed =>
      'K-Electric announces revised loadshedding schedule for September';

  @override
  String newsReadTime(int n) {
    return '$n min read';
  }

  @override
  String get newsReset => 'The two-minute reset that beats a coffee break';

  @override
  String get newsRupee =>
      'Rupee holds steady as remittances climb for a third month';

  @override
  String get newsSaved => 'Your reading';

  @override
  String newsSavedCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n saved stories',
      one: '1 saved story',
    );
    return '$_temp0';
  }

  @override
  String get newsSavedOpen => 'Opening saved stories';

  @override
  String get newsSavings => 'A plain-English guide to your first savings goal';

  @override
  String get newsSearch => 'Search stories';

  @override
  String newsShareSource(String source, String ago) {
    return '$source · $ago';
  }

  @override
  String get newsShortList => 'Why a shorter to-do list finishes more work';

  @override
  String get newsSources => 'Sources';

  @override
  String get newsSourcesEdit => 'Choose your sources';

  @override
  String newsSourcesValue(String n) {
    return '$n following';
  }

  @override
  String get newsSquad => 'Pakistan name squad for the home Test series';

  @override
  String get newsTop => 'Top story';

  @override
  String get notesFolderIdeas => 'Ideas';

  @override
  String get notesFolderPersonal => 'Personal';

  @override
  String get notesFolderWork => 'Work';

  @override
  String get notesFolders => 'Folders';

  @override
  String get notesNew => 'New note';

  @override
  String get notesNoMatch => 'No notes match';

  @override
  String get notesNoMatchText => 'Try a different word, or a folder name.';

  @override
  String get notesPinned => 'Pinned';

  @override
  String get notesRecent => 'Recent';

  @override
  String get notesSeedN1 => 'Sprint retro points';

  @override
  String get notesSeedN1x =>
      'Ship the onboarding fix first, then revisit the empty states…';

  @override
  String get notesSeedN2 => 'Reading list';

  @override
  String get notesSeedN2x =>
      'Three books recommended over dinner — start with the shorter one…';

  @override
  String get notesSeedN3 => 'App idea';

  @override
  String get notesSeedN3x =>
      'A tool that quietly tracks what you actually reread…';

  @override
  String get notesSeedN4 => 'Meeting notes';

  @override
  String get notesSeedN4x =>
      'Budget signed off, revisit headcount in November…';

  @override
  String get notesTotal => 'Notes';

  @override
  String get notifPrefBadge => 'Badge count';

  @override
  String get notifPrefBadgeSub => 'Show the unread count on the bell';

  @override
  String get notifPrefCategories => 'Categories';

  @override
  String get notifPrefCategoriesSub =>
      'Switch off anything you don’t want to hear about';

  @override
  String get notifPrefEarlier => 'Earlier';

  @override
  String get notifPrefFrom => 'from';

  @override
  String get notifPrefGeneral => 'General';

  @override
  String get notifPrefHaptics => 'Vibration';

  @override
  String get notifPrefInApp => 'In-app notifications';

  @override
  String get notifPrefInAppSub => 'Banners and the notification centre';

  @override
  String get notifPrefLater => 'Later';

  @override
  String get notifPrefPerTool => 'By tool';

  @override
  String get notifPrefPerToolSub =>
      'Fine-grained control over each kind of alert';

  @override
  String get notifPrefPreview => 'Show previews';

  @override
  String get notifPrefPreviewSub => 'Include the detail, not just the title';

  @override
  String get notifPrefPrivacySub => 'What a notification is allowed to reveal';

  @override
  String get notifPrefPush => 'Push notifications';

  @override
  String get notifPrefQuiet => 'Quiet hours';

  @override
  String get notifPrefQuietOn => 'Quiet hours';

  @override
  String get notifPrefQuietSub =>
      'Nothing interrupts you; everything still arrives';

  @override
  String get notifPrefRestore => 'Restore dismissed';

  @override
  String get notifPrefSensitive => 'Preview sensitive content';

  @override
  String get notifPrefSensitiveSub =>
      'Health, documents and money say only that something changed';

  @override
  String get notifPrefSound => 'Sound';

  @override
  String get notifPrefTo => 'Until';

  @override
  String get ntypeBillDue => 'Bills due soon';

  @override
  String get ntypeBillOverdue => 'Overdue bills';

  @override
  String get ntypeDocExpiry => 'Document expiry';

  @override
  String get ntypeFlightChange => 'Flight changes';

  @override
  String get ntypeForecast => 'Daily forecast';

  @override
  String get ntypeHabitReminder => 'Habit reminders';

  @override
  String get ntypeMarketMove => 'Market movement';

  @override
  String get ntypeMedication => 'Medication reminders';

  @override
  String get ntypeOutage => 'Power outages';

  @override
  String get ntypeParcelUpdate => 'Parcel updates';

  @override
  String get ntypePrayerReminder => 'Prayer reminder';

  @override
  String get ntypeSevereWeather => 'Severe weather';

  @override
  String get ntypeSubRenewal => 'Subscription renewals';

  @override
  String get ntypeTaskReminder => 'Task reminders';

  @override
  String get ntypeTrainDelay => 'Train delays';

  @override
  String get onbAllSet => 'All set';

  @override
  String onbAtCap(String max) {
    return 'Up to $max — remove one first';
  }

  @override
  String get onbCityText =>
      'Used for weather, prayer times where relevant, and anything local.';

  @override
  String get onbCityTitle => 'Which city are you in?';

  @override
  String get onbEnterLume => 'Enter Lume';

  @override
  String get onbHereForText =>
      'Pick 5 to 10. Your home screen, tools and reading are built around them — change them whenever you like.';

  @override
  String get onbHereForTitle => 'What are you here for?';

  @override
  String get onbLocalKicker => 'Make it local';

  @override
  String get onbMethodLabel => 'Prayer calculation method';

  @override
  String onbMinimum(String count, String min) {
    return '$count of $min minimum';
  }

  @override
  String get onbNameKicker => 'One last thing';

  @override
  String get onbNameLabel => 'Display name';

  @override
  String get onbNameNote => 'Lume keeps this on your device.';

  @override
  String get onbNamePlaceholder => 'Your name';

  @override
  String get onbNameSkip => 'Skip for now';

  @override
  String get onbNameText =>
      'Only used to greet you. You can change it later, or skip it entirely.';

  @override
  String get onbNameTitle => 'What should we call you?';

  @override
  String get onbOnDevice =>
      'Lume keeps this on your device. Nothing is uploaded.';

  @override
  String get onbPermLocation => 'Use your location';

  @override
  String get onbPermLocationSub =>
      'For weather, local services and nearby places';

  @override
  String get onbPermLocationSubFaith =>
      'For prayer times, Qibla, weather and nearby places';

  @override
  String get onbPermNotify => 'Gentle reminders';

  @override
  String get onbPermNotifySub =>
      'A quiet nudge for the things you asked us to watch';

  @override
  String get onbPermNotifySubFaith =>
      'A quiet nudge 5 minutes before each adhan';

  @override
  String get onbPlanKicker => 'Plan';

  @override
  String get onbPlanText =>
      'Tasks, reminders and events on one timeline — with everything that matters already in the right place.';

  @override
  String get onbPlanTitle => 'Your day, laid out before it starts';

  @override
  String onbReadyFaith(String prayer) {
    return 'Your next prayer is $prayer, and today’s plan is waiting on the home screen.';
  }

  @override
  String get onbReadyGeneral => 'Today’s plan is waiting on the home screen.';

  @override
  String onbReadyNamed(String name) {
    return 'You’re ready, $name';
  }

  @override
  String get onbReadyTitle => 'You’re all set';

  @override
  String get onbRevisit => 'You can revisit this tour any time from Profile.';

  @override
  String onbSelected(String count, String max) {
    return '$count of $max selected';
  }

  @override
  String get onbSetupText =>
      'Two permissions, and you can change either of them later.';

  @override
  String get onbSetupTitle => 'Set it up once';

  @override
  String get onbSignInAction => 'Sign in';

  @override
  String get onbSignInPrompt => 'Already have an account?';

  @override
  String get onbSkippedDefaults =>
      'Set up with our defaults — edit them in Profile';

  @override
  String get onbSkippedTour => 'Tour skipped — find it again in Profile';

  @override
  String get onbToolsKicker => 'Tools';

  @override
  String get onbToolsText =>
      'Calculator, converters, weather, scanner, rates, trackers — sorted, so you never hunt for them.';

  @override
  String onbToolsTitle(String count) {
    return '$count-odd tools, one or two taps away';
  }

  @override
  String get onbWelcomeBack => 'Welcome to Lume';

  @override
  String get onbWelcomeText =>
      'Plans, money, travel, reading and the small tools you reach for — without the clutter.';

  @override
  String get onbWelcomeTitle => 'Everything your day needs, quietly organised.';

  @override
  String get onbWhereText =>
      'This helps us personalise local information and services. It says nothing about who you are.';

  @override
  String get onbWhereTitle => 'Where are you based?';

  @override
  String get onbYoursKicker => 'Make it yours';

  @override
  String parcelArrivesToday(String carrier) {
    return '$carrier · arrives today';
  }

  @override
  String get parcelOutForDelivery => 'Out for delivery';

  @override
  String get persAllCountries => 'All countries';

  @override
  String get persAppLanguage => 'App language';

  @override
  String get persCity => 'City';

  @override
  String get persCitySub =>
      'Used for weather, local information and nearby places';

  @override
  String get persContent => 'Content';

  @override
  String get persCountry => 'Country';

  @override
  String get persCountrySub => 'Unlocks local services — nothing else';

  @override
  String get persCurrency => 'Currency';

  @override
  String persCurrencyAuto(String code) {
    return 'Automatic ($code)';
  }

  @override
  String get persDataSafe =>
      'Changing any of this only changes what you see. Your notes, tasks and records stay exactly where they are.';

  @override
  String get persFinance => 'Financial information';

  @override
  String get persFinanceSub => 'Rates, gold and markets';

  @override
  String get persFormatting => 'Language & formatting';

  @override
  String get persInterests => 'Your interests';

  @override
  String persInterestsHint(int min) {
    return 'Pick at least $min. They decide what fills your home screen.';
  }

  @override
  String get persIslamic => 'Islamic features';

  @override
  String get persIslamicSub => 'Prayer times, Qur’an, duas, zakat and Ramadan';

  @override
  String get persNews => 'News';

  @override
  String get persNewsSub => 'Headlines on Explore and Today';

  @override
  String get persPopular => 'Popular';

  @override
  String get persRecent => 'Recent';

  @override
  String get persRecos => 'Recommendations';

  @override
  String get persRecosSub => 'Suggest tools based on how you use Lume';

  @override
  String get persRegion => 'Region';

  @override
  String get persSavePrefs => 'Save preferences';

  @override
  String get persSaved => 'Your app has been updated';

  @override
  String get persSearchCities => 'Search cities';

  @override
  String get persSearchCountries => 'Search countries';

  @override
  String get persSport => 'Sport';

  @override
  String get persSportSub => 'Live cricket scores';

  @override
  String get persSub => 'Change any of this whenever you like';

  @override
  String get persTime12 => '12-hour';

  @override
  String get persTime24 => '24-hour';

  @override
  String get persTimeFormat => 'Time';

  @override
  String get persTitle => 'Personalisation';

  @override
  String get persUnits => 'Units';

  @override
  String get persUnitsAuto => 'Automatic';

  @override
  String get persUnitsImperial => 'Imperial';

  @override
  String get persUnitsMetric => 'Metric';

  @override
  String get persUseLocation => 'Use my current location';

  @override
  String get persUseLocationSub => 'Optional — you can always set this by hand';

  @override
  String get persWhereYouAre => 'Where you are';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get profileSub => 'Preferences and your saved things';

  @override
  String get qaDocscan => 'Scan doc';

  @override
  String get qaExpense => 'Add expense';

  @override
  String get qaNote => 'New note';

  @override
  String get qaParcel => 'Track parcel';

  @override
  String get qaScan => 'Scan QR';

  @override
  String get qaShop => 'Shopping';

  @override
  String get qaTasbih => 'Tasbih';

  @override
  String get qaTask => 'Add task';

  @override
  String get qaTimer => 'Start timer';

  @override
  String get qaWater => 'Log water';

  @override
  String get qrCopied => 'Copied';

  @override
  String get qrCopy => 'Copy';

  @override
  String get qrCopyNetwork => 'Copy network name';

  @override
  String get qrDetects => 'What it recognises';

  @override
  String get qrFullText => 'What the code says';

  @override
  String get qrHint => 'Point the camera at a code';

  @override
  String get qrKindContact => 'Contact';

  @override
  String get qrKindEmail => 'Email address';

  @override
  String get qrKindLink => 'Website';

  @override
  String get qrKindLocation => 'Location';

  @override
  String get qrKindMessage => 'Text message';

  @override
  String get qrKindPhone => 'Phone number';

  @override
  String get qrKindRefused => 'A link Lume won\'t open';

  @override
  String get qrKindText => 'Text';

  @override
  String get qrKindWifi => 'Wi-Fi network';

  @override
  String get qrNoteContact => 'Lume doesn\'t add contacts';

  @override
  String get qrNoteEmail =>
      'The code\'s own subject and text aren\'t filled in';

  @override
  String get qrNoteInsecure =>
      'Not secure — this site\'s connection isn\'t encrypted';

  @override
  String get qrNoteLocation => 'Lume doesn\'t open maps yet';

  @override
  String get qrNoteMessage => 'The code\'s own message text isn\'t filled in';

  @override
  String get qrNoteRefused =>
      'Lume doesn\'t open this kind of link. You can copy it.';

  @override
  String get qrNoteWifi =>
      'Lume doesn\'t join networks. The password stays hidden.';

  @override
  String get qrOpenEmail => 'Write an email';

  @override
  String get qrOpenFailed => 'Couldn\'t open it';

  @override
  String get qrOpenMessage => 'Open in Messages';

  @override
  String get qrOpenPhone => 'Open in Phone';

  @override
  String get qrOpenSite => 'Open website';

  @override
  String get qrOpenUnavailable => 'Nothing on this device can open it';

  @override
  String get qrResultNote => 'Nothing opens unless you choose it';

  @override
  String get qrScan => 'Scan';

  @override
  String get qrStepAct => 'Open, copy or save';

  @override
  String get qrStepDetect => 'Lume reads it automatically';

  @override
  String get qrStepPoint => 'Point at the code';

  @override
  String ratesBuyValue(String value) {
    return 'Buy $value';
  }

  @override
  String get ratesConverter => 'What is my gold worth?';

  @override
  String get ratesCurrencies => 'Currencies';

  @override
  String ratesDaysAgo(int n) {
    return '${n}d';
  }

  @override
  String get ratesGold22 => 'Gold 22k';

  @override
  String get ratesGold24 => 'Gold 24k';

  @override
  String get ratesGoldHistory => 'Gold per tola';

  @override
  String get ratesGoldHistoryCap => 'Open market close, last 30 days';

  @override
  String get ratesHistory => 'Gold, 30 days';

  @override
  String ratesHistoryRange(String from, String to) {
    return 'From $from to $to';
  }

  @override
  String get ratesMetal => 'Metal';

  @override
  String get ratesMetals => 'Metals';

  @override
  String get ratesNoMatch => 'No currency matches';

  @override
  String get ratesNoMatchText => 'Try a three-letter code such as USD or EUR.';

  @override
  String get ratesOpenMarket => 'Open market';

  @override
  String ratesPerUnit(String unit) {
    return '/ $unit';
  }

  @override
  String get ratesSearch => 'Search currencies';

  @override
  String ratesSellValue(String value) {
    return 'Sell $value';
  }

  @override
  String ratesShareText(String metal, String value, String unit) {
    return '$metal: $value $unit';
  }

  @override
  String get ratesSilver => 'Silver';

  @override
  String get ratesSilverTola => 'Silver / tola';

  @override
  String get ratesWeight => 'Weight';

  @override
  String get ratesWorth => 'Worth';

  @override
  String get readerFallbackEnglish =>
      'Shown in English — no verified translation in this language yet';

  @override
  String recAdd(String noun) {
    return 'Add $noun';
  }

  @override
  String recAddFirst(String noun) {
    return 'Add first $noun';
  }

  @override
  String recAdded(String noun) {
    return '$noun added';
  }

  @override
  String get recAttach => 'Add photo or document';

  @override
  String get recAttachSoon => 'Attachments are coming soon';

  @override
  String get recAttached => 'Attached';

  @override
  String recBackToList(String noun) {
    return 'Back to $noun';
  }

  @override
  String get recCheckFields => 'Check the highlighted fields';

  @override
  String get recClearDueDate => 'Clear due date';

  @override
  String get recClearEventTime => 'Clear event time';

  @override
  String recCleared(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n removed',
      one: '1 removed',
    );
    return '$_temp0';
  }

  @override
  String get recConfirmNote => 'Changes are saved only after confirmation';

  @override
  String get recConflict => 'This record changed elsewhere';

  @override
  String get recConflictText =>
      'A newer version exists. Review your changes or reload the newer one.';

  @override
  String get recCouldNotRefresh => 'Could not refresh';

  @override
  String recCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n records',
      one: '1 record',
    );
    return '$_temp0';
  }

  @override
  String recCreated(String when) {
    return 'Created $when';
  }

  @override
  String get recCreatedToday => 'Created today';

  @override
  String get recCreatedYesterday => 'Created yesterday';

  @override
  String recDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String recDelete(String noun) {
    return 'Delete $noun';
  }

  @override
  String recDeleteAsk(String noun) {
    return 'Delete this $noun?';
  }

  @override
  String get recDeleteFailed => 'Could not delete this record';

  @override
  String recDeleteTextFinal(String name) {
    return '$name will be removed. This action cannot be undone.';
  }

  @override
  String recDeleteTextUndo(String name) {
    return '$name will be removed. You can undo this straight away.';
  }

  @override
  String recDeleted(String noun) {
    return '$noun deleted';
  }

  @override
  String recDeletedFinal(String noun) {
    return '$noun deleted permanently';
  }

  @override
  String recDetailTitle(String noun) {
    return '$noun details';
  }

  @override
  String get recDetails => 'Details';

  @override
  String get recDiscard => 'Discard';

  @override
  String get recDiscardAsk => 'Discard your changes?';

  @override
  String get recDiscardText => 'What you typed will not be saved.';

  @override
  String get recDocEducation => 'Education';

  @override
  String get recDocIdentity => 'Identity';

  @override
  String get recDocInsurance => 'Insurance';

  @override
  String get recDocOther => 'Other';

  @override
  String get recDocProperty => 'Property';

  @override
  String get recDocVehicle => 'Vehicle';

  @override
  String get recDocumentsEmptyText =>
      'Add one and Lume will remind you before it expires.';

  @override
  String get recDocumentsEmptyTitle => 'No documents yet';

  @override
  String get recDocumentsNoun => 'document';

  @override
  String get recDocumentsNounPlural => 'documents';

  @override
  String get recDocumentsPh => 'Passport, licence, policy…';

  @override
  String get recDone => 'Done';

  @override
  String recEdit(String noun) {
    return 'Edit $noun';
  }

  @override
  String get recEditing => 'Editing';

  @override
  String get recErrPositive => 'Enter an amount greater than zero';

  @override
  String recErrRequired(String field) {
    return '$field is required';
  }

  @override
  String get recEventsEmptyText => 'Add an event and it will appear here.';

  @override
  String get recEventsEmptyTitle => 'Nothing planned';

  @override
  String get recEventsNoun => 'event';

  @override
  String get recEventsNounPlural => 'events';

  @override
  String get recEventsPh => 'What is happening?';

  @override
  String get recExpensesEmptyText =>
      'Add a record to understand where your money goes and build useful summaries.';

  @override
  String get recExpensesEmptyTitle => 'Track your first expense';

  @override
  String get recExpensesNoun => 'expense';

  @override
  String get recExpensesNounPlural => 'expenses';

  @override
  String get recExpensesPh => 'What did you spend on?';

  @override
  String recExpiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String get recFieldAisle => 'Aisle';

  @override
  String get recFieldAmount => 'Amount';

  @override
  String get recFieldCategory => 'Category';

  @override
  String get recFieldCompleted => 'Completed';

  @override
  String get recFieldDate => 'Date';

  @override
  String get recFieldDue => 'Due';

  @override
  String get recFieldEstimate => 'Estimate';

  @override
  String get recFieldExpiry => 'Expiry';

  @override
  String get recFieldFolder => 'Folder';

  @override
  String get recFieldHolder => 'Holder';

  @override
  String get recFieldInBasket => 'In basket';

  @override
  String get recFieldItem => 'Item';

  @override
  String get recFieldList => 'List';

  @override
  String get recFieldNote => 'Note';

  @override
  String get recFieldNotes => 'Notes';

  @override
  String get recFieldPayment => 'Payment';

  @override
  String get recFieldPeople => 'People';

  @override
  String get recFieldPinned => 'Pinned';

  @override
  String get recFieldPriority => 'Priority';

  @override
  String get recFieldQuantity => 'Quantity';

  @override
  String get recFieldReceipt => 'Receipt';

  @override
  String get recFieldReference => 'Reference';

  @override
  String get recFieldTask => 'Task';

  @override
  String get recFieldTime => 'Time';

  @override
  String get recFieldTimezone => 'Timezone';

  @override
  String get recFieldTitle => 'Title';

  @override
  String get recFieldWhere => 'Where';

  @override
  String get recGone => 'That record is no longer here';

  @override
  String get recGoneText => 'It may have been deleted.';

  @override
  String get recImportLater => 'You can import records later';

  @override
  String recInformation(String noun) {
    return '$noun information';
  }

  @override
  String get recKeepEditing => 'Keep editing';

  @override
  String recLoadError(Object noun) {
    return 'We could not load $noun';
  }

  @override
  String get recLoadErrorText =>
      'Check your connection. Your saved data is still safe on this device.';

  @override
  String recModified(String when) {
    return 'Edited $when';
  }

  @override
  String get recNewRecord => 'New record';

  @override
  String get recNoDue => 'No due date';

  @override
  String get recNoMatch => 'Nothing matches';

  @override
  String get recNoMatchText => 'Try a different word, or clear the filters.';

  @override
  String get recNoTime => 'No time set';

  @override
  String get recNone => 'None';

  @override
  String get recNoneYet => 'No records yet';

  @override
  String get recNotAttached => 'Not attached';

  @override
  String get recNotesEmptyText =>
      'Notes are searchable the moment you save them.';

  @override
  String get recNotesEmptyTitle => 'Nothing written down yet';

  @override
  String get recNotesNoun => 'note';

  @override
  String get recNotesNounPlural => 'notes';

  @override
  String get recNotesPh => 'Give it a title';

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
  String get recOpen => 'Open';

  @override
  String get recOptional => 'Optional';

  @override
  String get recPayCard => 'Card';

  @override
  String get recPayCash => 'Cash';

  @override
  String get recPayTransfer => 'Transfer';

  @override
  String get recPayWallet => 'Wallet';

  @override
  String get recPinned => 'Pinned';

  @override
  String get recPriorityHigh => 'High';

  @override
  String get recPriorityNormal => 'Normal';

  @override
  String get recQueued => 'Queued';

  @override
  String recRecordId(String id) {
    return 'Record ID $id';
  }

  @override
  String get recReload => 'Reload';

  @override
  String get recReloaded => 'Loaded the newer version';

  @override
  String get recReview => 'Review';

  @override
  String recSave(String noun) {
    return 'Save $noun';
  }

  @override
  String get recSaveFailed => 'Could not save changes';

  @override
  String get recSaveFailedText => 'Nothing you typed was lost. Try again.';

  @override
  String get recSaving => 'Saving…';

  @override
  String recSearch(String noun) {
    return 'Search $noun';
  }

  @override
  String get recSeedCoffee => 'Coffee';

  @override
  String get recSeedFamily => 'Family';

  @override
  String get recSeedGroceries => 'Groceries';

  @override
  String get recSeedGroceriesNote => 'Weekly household groceries';

  @override
  String get recSeedInsurance => 'Health insurance';

  @override
  String get recSeedInternet => 'Internet bill';

  @override
  String get recSeedLicence => 'Driving licence';

  @override
  String get recSeedNid => 'National ID';

  @override
  String get recSeedPassport => 'Passport';

  @override
  String get recSeedPharmacy => 'Pharmacy';

  @override
  String get recSeedTaxi => 'Taxi';

  @override
  String get recSeedYou => 'You';

  @override
  String get recSelectText => 'Choose one from the list to see it here.';

  @override
  String get recSelectTitle => 'Nothing selected';

  @override
  String recShoppingClear(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Clear $n in the basket',
      one: 'Clear 1 in the basket',
    );
    return '$_temp0';
  }

  @override
  String recShoppingClearConfirm(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items will be removed from the list. This cannot be undone.',
      one: '1 item will be removed from the list. This cannot be undone.',
    );
    return '$_temp0';
  }

  @override
  String get recShoppingEmptyText =>
      'Add what you need and tick it off as you shop.';

  @override
  String get recShoppingEmptyTitle => 'Your list is empty';

  @override
  String get recShoppingNoun => 'item';

  @override
  String get recShoppingNounPlural => 'shopping list';

  @override
  String get recShoppingPh => 'What do you need?';

  @override
  String get recShoppingQtyPh => '2 kg';

  @override
  String get recToBuy => 'To buy';

  @override
  String get recTodosEmptyText => 'Add a task and it will show up here.';

  @override
  String get recTodosEmptyTitle => 'Nothing on your list';

  @override
  String get recTodosNoun => 'task';

  @override
  String get recTodosNounPlural => 'tasks';

  @override
  String get recTodosPh => 'What needs doing?';

  @override
  String get recUndo => 'Undo';

  @override
  String get recUndone => 'Restored';

  @override
  String get recUpdate => 'Save changes';

  @override
  String get recUpdated => 'Saved';

  @override
  String get recViewCached => 'View cached records';

  @override
  String get recZoneChooseText =>
      'Your region has more than one time zone, so nothing here is grouped by day. Your records are all listed above. Choose a time zone in Profile › Time.';

  @override
  String get recZoneMissingText =>
      'No time zone is set and this device’s isn’t known, so nothing here is grouped by day. Your records are all listed above. Choose a time zone in Profile › Time.';

  @override
  String recZoneUnknownText(String zone) {
    return 'Lume can’t read the time zone $zone, so nothing here is grouped by day. Your records are all listed above. Choose a time zone in Profile › Time.';
  }

  @override
  String get recZoneUnknownTitle => 'Your day can’t be worked out';

  @override
  String get recipeCuisineGlobal => 'Global';

  @override
  String get recipeCuisineLevantine => 'Levantine';

  @override
  String get recipeCuisineMediterranean => 'Mediterranean';

  @override
  String get recipeCuisinePakistani => 'Pakistani';

  @override
  String get recipeNameBeefPulao => 'Beef Pulao';

  @override
  String get recipeNameChickenKarahi => 'Chicken Karahi';

  @override
  String get recipeNameDaalChawal => 'Daal Chawal';

  @override
  String get recipeNameGreekSalad => 'Greek Salad';

  @override
  String get recipeNameOvernightOats => 'Overnight Oats';

  @override
  String get recipeNameShakshuka => 'Shakshuka';

  @override
  String get recipeTagBreakfast => 'Breakfast';

  @override
  String get recipeTagBudget => 'Budget';

  @override
  String get recipeTagDinner => 'Dinner';

  @override
  String get recipeTagFamily => 'Family';

  @override
  String get recipeTagLight => 'Light';

  @override
  String get recipeTagLunch => 'Lunch';

  @override
  String get recipeTagMakeAhead => 'Make ahead';

  @override
  String get recipeTagNoCook => 'No cook';

  @override
  String get recipeTagSpicy => 'Spicy';

  @override
  String get recipeTagVegetarian => 'Vegetarian';

  @override
  String get recipesAll => 'All recipes';

  @override
  String get recipesFavourites => 'Your favourites';

  @override
  String recipesIngredients(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ingredients',
      one: '1 ingredient',
    );
    return '$_temp0';
  }

  @override
  String get recipesNoMatch => 'No recipes match';

  @override
  String get recipesNoMatchText => 'Try a cuisine, an ingredient or a tag.';

  @override
  String recipesPrepCook(String prep, String cook) {
    return '$prep + $cook min';
  }

  @override
  String get recipesRelated => 'Do more with this';

  @override
  String get recipesSearch => 'Search recipes';

  @override
  String recipesServes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'serves $n',
      one: 'serves 1',
    );
    return '$_temp0';
  }

  @override
  String recipesShareText(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes',
      one: '1 recipe',
    );
    return '$_temp0 · Your favourites: $names';
  }

  @override
  String recipesSteps(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n steps',
      one: '1 step',
    );
    return '$_temp0';
  }

  @override
  String get recordsNoSelectionText => 'Choose a record to see it here.';

  @override
  String get recordsNoSelectionTitle => 'Nothing selected';

  @override
  String get routeMissingText =>
      'The link may be old, or the page may have moved.';

  @override
  String get routeMissingTitle => 'We can’t find that';

  @override
  String get scanBlocked =>
      'Camera access for Lume is off. Turn it on in Settings to scan.';

  @override
  String get scanDenied =>
      'Lume can\'t use the camera. Press Scan to be asked again.';

  @override
  String get scanEmptyText =>
      'Anything you capture appears here and stays on this device.';

  @override
  String get scanEmptyTitle => 'Nothing scanned yet';

  @override
  String get scanFailed => 'Couldn\'t scan. Try again.';

  @override
  String get scanFromGallery => 'From gallery';

  @override
  String get scanMultiple =>
      'That image has more than one QR code. Choose one with a single code.';

  @override
  String get scanNothing => 'No code found';

  @override
  String get scanOpenSettings => 'Settings';

  @override
  String get scanPhotosDenied =>
      'Lume can\'t open your photos. You can allow it in Settings.';

  @override
  String get scanRestricted =>
      'The camera is turned off on this device by a restriction or its administrator.';

  @override
  String get scanSettingsFailed =>
      'Settings didn\'t open. You\'ll find Lume under Apps in your phone\'s Settings.';

  @override
  String get scanTooLarge => 'That image is too large to read';

  @override
  String get scanUnavailable => 'Scanning isn\'t available on this device';

  @override
  String get scanUndetermined =>
      'Lume can\'t use the camera. Press Scan to be asked again, or turn it on in Settings if Android doesn\'t ask.';

  @override
  String get scanUnreadable => 'Lume couldn\'t read that image';

  @override
  String get scanUnsupported => 'That code isn\'t a QR code';

  @override
  String get scoreAllOut => 'all out';

  @override
  String scoreOvers(String n) {
    return '$n ov';
  }

  @override
  String scoreTrail(String team, int runs, String player, int score) {
    return '$team trail by $runs runs · $player $score*';
  }

  @override
  String get scoreVersus => 'vs';

  @override
  String get searchDarkMode => 'Dark mode';

  @override
  String get searchEverything => 'Search everything';

  @override
  String get searchInSettings => 'Settings';

  @override
  String get searchJumpBack => 'Jump back in';

  @override
  String get searchNothing => 'Nothing found';

  @override
  String get searchNothingSub =>
      'Try another word, or turn on more interests in Personalisation.';

  @override
  String get searchPlaceholder => 'Search anything — tools, rates, places';

  @override
  String get searchTry => 'Try searching for';

  @override
  String get shareCardReady => 'Your card is ready';

  @override
  String get shareFailed => 'Couldn’t share the card';

  @override
  String get shareGenerating => 'Creating your card…';

  @override
  String get sharePreviewLabel => 'Share card preview';

  @override
  String get shareSaveDenied => 'Lume can’t save to your photos';

  @override
  String get shareSaveFailed => 'Couldn’t save the image';

  @override
  String get shareSaveNoSpace => 'Not enough space to save the image';

  @override
  String get shareSaveUnavailable =>
      'Saving images isn’t available on this device — use Share to save it';

  @override
  String get shareSaved => 'Image saved';

  @override
  String get shareShared => 'Shared';

  @override
  String get shareUnavailable => 'Sharing isn’t available on this device';

  @override
  String get shopAisleDairy => 'Dairy';

  @override
  String get shopAisleHousehold => 'Household';

  @override
  String get shopAisleProduce => 'Produce';

  @override
  String get shopSeedI1 => 'Tomatoes';

  @override
  String get shopSeedI2 => 'Milk';

  @override
  String get shopSeedI3 => 'Yoghurt';

  @override
  String get shopSeedI4 => 'Lemons';

  @override
  String get shopSeedI5 => 'Washing powder';

  @override
  String get shoppingClear => 'Clear checked';

  @override
  String shoppingEstimated(String amount) {
    return 'about $amount';
  }

  @override
  String get shoppingList => 'Still to get';

  @override
  String get shoppingProgress => 'Checked off';

  @override
  String get shoppingShare => 'Share the list';

  @override
  String shoppingShareSource(String date) {
    return 'Shopping list · $date';
  }

  @override
  String get slideMoneyCta => 'See money';

  @override
  String get slideMoneyKicker => 'Money';

  @override
  String get slideMoneyText => 'Rates, bills and expenses in one place.';

  @override
  String get slideMoneyTitle => 'Stay on top of your money';

  @override
  String slideOf(int n, int total) {
    return 'Slide $n of $total';
  }

  @override
  String get slidePlanCta => 'Open today';

  @override
  String get slidePlanKicker => 'Today';

  @override
  String get slidePlanText => 'Tasks, reminders and events on one timeline.';

  @override
  String get slidePlanTitle => 'Plan your day before it starts';

  @override
  String get slidePrayerCta => 'Prayer times';

  @override
  String get slidePrayerKicker => 'Your next prayer';

  @override
  String slidePrayerLine(String time, String city) {
    return 'Adhan at $time · $city';
  }

  @override
  String get slideReadCta => 'Continue';

  @override
  String get slideReadKicker => 'Read';

  @override
  String get slideReadText =>
      'You’re 42 ayahs into Al-Kahf. Two minutes is enough.';

  @override
  String get slideReadTitle => 'Read something meaningful';

  @override
  String get slideToolsCta => 'Browse tools';

  @override
  String get slideToolsKicker => 'Tools';

  @override
  String get slideToolsText => 'Calculator, converters, scanner and more.';

  @override
  String get slideToolsTitle => 'Useful tools, all in one place';

  @override
  String get slideTrainsCta => 'Find a train';

  @override
  String get slideTrainsKicker => 'Travel';

  @override
  String get slideTrainsText => 'Live running status, fares and seats.';

  @override
  String get slideTrainsTitle => 'Trains, without the guesswork';

  @override
  String get startupLoading => 'Starting Lume';

  @override
  String get stopwatchEmptyText =>
      'Start the stopwatch and tap Lap to record one.';

  @override
  String get stopwatchEmptyTitle => 'No laps yet';

  @override
  String get stopwatchHint => 'Start, then Lap to mark each lap';

  @override
  String stopwatchLap(String n) {
    return 'Lap $n';
  }

  @override
  String get stopwatchLapAction => 'Lap';

  @override
  String get stopwatchLaps => 'Laps';

  @override
  String get stopwatchPause => 'Pause';

  @override
  String subsRenews(String date) {
    return 'renews $date';
  }

  @override
  String get sunDawn => 'Dawn';

  @override
  String get sunDawnNote => 'First light';

  @override
  String get sunDaylength => 'Daylight';

  @override
  String get sunDusk => 'Dusk';

  @override
  String get sunDuskNote => 'Last light';

  @override
  String get sunIllumination => 'Illuminated';

  @override
  String get sunMoon => 'Moon phase';

  @override
  String get sunNoCityText =>
      'Sun and moon times are worked out from a city’s coordinates, and Lume has none for this one. Choose another city in Profile to see them.';

  @override
  String sunNoCityTitle(String city) {
    return 'No position for $city';
  }

  @override
  String get sunNoTwilight => 'Not dark enough tonight';

  @override
  String get sunNoZoneText =>
      'Times can’t be shown on your local clock without its time zone, so none are shown.';

  @override
  String sunNoZoneTitle(String zone) {
    return 'No clock for $zone';
  }

  @override
  String get sunNoon => 'Solar noon';

  @override
  String get sunPolarDay => 'The sun stays up all day';

  @override
  String get sunPolarNight => 'The sun stays below the horizon all day';

  @override
  String sunRange(String a, String b) {
    return '$a to $b';
  }

  @override
  String sunShareSource(String city, String date) {
    return '$city · $date';
  }

  @override
  String get sunSunrise => 'Sunrise';

  @override
  String get sunSunset => 'Sunset';

  @override
  String get sunTitle => 'Sun & moon';

  @override
  String get sunToday => 'Today';

  @override
  String get sunZoneChooseText =>
      'Sunrise and sunset are worked out on your clock, so they need your time zone. Choose one in Profile › Time.';

  @override
  String get surahAlKahf => 'Al-Kahf';

  @override
  String get taskAlKahf => 'Read two pages of Al-Kahf';

  @override
  String get taskCallHome => 'Call home';

  @override
  String get taskElectricity => 'Pay the electricity bill';

  @override
  String get taskElectricityPk => 'Pay the K-Electric bill';

  @override
  String get taskEmail => 'Reply to Sara’s email';

  @override
  String get taskEvening => 'Evening';

  @override
  String get taskSummary => 'Finish the Q3 summary';

  @override
  String taxAbove(String v) {
    return 'Above $v';
  }

  @override
  String get taxAnnual => 'Annual';

  @override
  String get taxAuthorityFbrSalaried => 'FBR salaried slabs';

  @override
  String get taxAuthorityHmrcEngland => 'HMRC income tax (England)';

  @override
  String get taxAuthorityIndiaNewRegime => 'New regime slabs';

  @override
  String get taxAuthorityIrsSingleFiler => 'IRS single filer';

  @override
  String get taxAuthorityNone => 'No personal income tax';

  @override
  String get taxBand => 'Band';

  @override
  String get taxDeductions => 'Deductions';

  @override
  String get taxDueAnnual => 'Tax a year';

  @override
  String get taxDueMonthly => 'Tax a month';

  @override
  String taxEffective(String rate) {
    return 'Effective rate $rate';
  }

  @override
  String get taxIncomeAnnual => 'Annual income';

  @override
  String get taxIncomeMonthly => 'Monthly income';

  @override
  String get taxIncomeTax => 'Income tax';

  @override
  String get taxLeviesNote => 'Worth knowing';

  @override
  String get taxLeviesNoteText =>
      'These are headline rates. Consumption taxes are paid on what you buy rather than deducted from pay, and social contributions are usually split between you and your employer.';

  @override
  String get taxLevy => 'Levy';

  @override
  String get taxMarginal => 'Marginal rate';

  @override
  String get taxMonthly => 'Monthly';

  @override
  String get taxNoneCaption =>
      'Your salary is not subject to personal income tax here.';

  @override
  String taxNoneText(String authority) {
    return '$authority. Nothing to calculate for salaried income here.';
  }

  @override
  String get taxNoneTitle => 'No personal income tax';

  @override
  String get taxOtherLevies => 'What does apply';

  @override
  String get taxPeriod => 'Period';

  @override
  String get taxRate => 'Rate';

  @override
  String get taxSlabs => 'How it is worked out';

  @override
  String get taxSplit => 'Where it goes';

  @override
  String get taxTakeHome => 'Take-home';

  @override
  String get taxTax => 'Tax';

  @override
  String get taxTaxable => 'Taxable income';

  @override
  String get taxTaxedHere => 'Tax in band';

  @override
  String get taxUnsupportedText =>
      'Tax rules are country-specific. Switch country to use a market Lume has configured, or check back — new markets are added regularly.';

  @override
  String taxUnsupportedTitle(String country) {
    return 'Not yet localised for $country';
  }

  @override
  String get taxYear => 'Year';

  @override
  String get timerDone => 'Timer finished';

  @override
  String get timerHint => 'Choose a preset or set your own';

  @override
  String get timerPresets => 'Presets';

  @override
  String get tipBill => 'Bill';

  @override
  String get tipFewer => 'Fewer';

  @override
  String get tipMore => 'More';

  @override
  String get tipPeople => 'People';

  @override
  String get tipPerPerson => 'Each person pays';

  @override
  String tipPerson(String n) {
    return 'Person $n';
  }

  @override
  String get tipSplit => 'Split';

  @override
  String get tipTip => 'Tip';

  @override
  String get tipTotal => 'Total';

  @override
  String get todayAddToast => 'New task added';

  @override
  String get todayAgendaGeneral => 'Events and reminders, in order';

  @override
  String get todayAgendaMuslim => 'Prayers and events, in order';

  @override
  String get todayAyah => 'Ayah of the day';

  @override
  String todayAyahCitation(String surah, String verse) {
    return '$surah $verse';
  }

  @override
  String todayAyahReference(String surah, String verse) {
    return '$surah · $verse';
  }

  @override
  String get todayDailyStreak => 'Daily streak';

  @override
  String todayHabitSummary(String name, int done, int streak) {
    return '$name, $done of 7 days, $streak day streak';
  }

  @override
  String get todayHabits => 'Habits';

  @override
  String get todayHabitsSub => 'Last seven days';

  @override
  String get todayOfDay => 'of day';

  @override
  String get todayOnTrack => 'You’re on track';

  @override
  String get todayPrayerStreak => 'Prayer streak';

  @override
  String get todayPrivate => 'Private';

  @override
  String get todayPrivateSub => 'Only on this device, only for you';

  @override
  String get todayPrivateText =>
      'Records, medication and expenses stay locked until you open them.';

  @override
  String get todayPrivateTitle => 'Health, documents & money';

  @override
  String get todayPrivateToast => 'Unlock to see private records';

  @override
  String get todayReadToday => 'Read today';

  @override
  String todayRingSummary(int done, int total, int meetings) {
    String _temp0 = intl.Intl.pluralLogic(
      meetings,
      locale: localeName,
      other: '$meetings meetings left this afternoon.',
      one: 'One meeting left this afternoon.',
      zero: 'Nothing else scheduled.',
    );
    return '$done of $total tasks done. $_temp0';
  }

  @override
  String get todaySteps => 'Steps today';

  @override
  String get todayTaskDone => 'Nice — one less thing';

  @override
  String get todayTaskUndone => 'Back on the list';

  @override
  String get todayTasks => 'Tasks';

  @override
  String get todayTasksDone => 'Tasks done';

  @override
  String get todayTasksSub => 'Tap to tick one off';

  @override
  String get todayThought => 'Today’s thought';

  @override
  String get todayThoughtSub => 'A minute of perspective';

  @override
  String get todayWeekToast => 'Switched to week view';

  @override
  String get todayYourDay => 'Your day';

  @override
  String get todosAdd => 'Add a task';

  @override
  String get todosClear => 'Nothing left';

  @override
  String get todosClearText => 'No tasks match this filter.';

  @override
  String get todosDone7 => 'Done this week';

  @override
  String get todosHigh => 'High';

  @override
  String get todosListHome => 'Home';

  @override
  String get todosListPersonal => 'Personal';

  @override
  String get todosListWork => 'Work';

  @override
  String get todosLists => 'Lists';

  @override
  String get todosNormal => 'Normal';

  @override
  String get todosOnTrack => 'Nothing overdue';

  @override
  String todosOpenN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n open',
      one: '1 open',
    );
    return '$_temp0';
  }

  @override
  String todosOverdueN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n overdue',
      one: '1 overdue',
    );
    return '$_temp0';
  }

  @override
  String get todosPriority => 'Priority';

  @override
  String get todosSeedItem1 => 'Send the quarterly summary';

  @override
  String get todosSeedItem2 => 'Pick up the prescription';

  @override
  String get todosSeedItem3 => 'Review the design feedback';

  @override
  String get todosSeedItem4 => 'Book the car service';

  @override
  String get todosToday => 'Today';

  @override
  String get todosUpcoming => 'Coming up';

  @override
  String get todosWeekSpoken => 'Next seven days';

  @override
  String get todosWhen => 'When';

  @override
  String get toolCategoryDaily => 'Daily Life';

  @override
  String get toolCategoryEveryday => 'Everyday';

  @override
  String get toolCategoryIslamic => 'Islamic';

  @override
  String get toolCategoryMoney => 'Money';

  @override
  String get toolCategoryPersonal => 'Personal';

  @override
  String get toolCategoryPlanning => 'Planning';

  @override
  String get toolCategorySubDaily => 'What’s happening around you';

  @override
  String get toolCategorySubEveryday => 'The ones you reach for daily';

  @override
  String get toolCategorySubIslamic => 'Prayer, Qur’an and giving';

  @override
  String get toolCategorySubMoney => 'Rates, bills and budgets';

  @override
  String get toolCategorySubPersonal => 'Private to you, on this device';

  @override
  String get toolCategorySubPlanning => 'Your time and your lists';

  @override
  String get toolChangeCountry => 'Change country';

  @override
  String get toolErrorText => 'We couldn’t load this. Try again in a moment.';

  @override
  String get toolErrorTitle => 'Something went wrong';

  @override
  String get toolExportFailed => 'Couldn’t write the file';

  @override
  String get toolExportUnavailable =>
      'Exporting isn’t available on this device';

  @override
  String toolExportedAs(String name) {
    return 'Saved $name';
  }

  @override
  String toolFavourited(String name) {
    return 'Added $name to favourites';
  }

  @override
  String get toolInputs => 'Inputs';

  @override
  String get toolInsights => 'Insights';

  @override
  String get toolLoading => 'Loading';

  @override
  String get toolLocalService => 'Local service';

  @override
  String toolNeedsAttention(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n need attention',
      one: '1 needs attention',
    );
    return '$_temp0';
  }

  @override
  String get toolPrivate => 'Private';

  @override
  String get toolPrivateReviewedText =>
      'This information stays on your device and is never shown on Home. Only what you review and choose to share leaves Lume. Notes, record IDs and anything you did not review are never included.';

  @override
  String get toolPrivateReviewedTitle => 'Private by default';

  @override
  String get toolPrivateText =>
      'This information stays on your device, is never shown on Home and is never included in shared content.';

  @override
  String get toolPrivateFullText =>
      'This information stays on your device. It is never shown on Home or in its suggestions, and never included in shared content.';

  @override
  String get toolPrivateTitle => 'Private to you';

  @override
  String get toolRelated => 'Related tools';

  @override
  String get toolSourceOnDevice => 'On device';

  @override
  String get toolSourceTax => 'Statutory slabs';

  @override
  String get toolStatusAge => 'Exact days';

  @override
  String get toolStatusAlarms => '2 set';

  @override
  String get toolStatusAqi => 'AQI';

  @override
  String get toolStatusAyah => 'Ar-Ra’d 28';

  @override
  String get toolStatusBabybudget => 'Plan costs';

  @override
  String get toolStatusBills => '2 due';

  @override
  String get toolStatusBirthdays => 'Dates you add';

  @override
  String get toolStatusBmi => 'Track weight';

  @override
  String get toolStatusCalculator => 'Standard';

  @override
  String get toolStatusCalendar => '3 events';

  @override
  String get toolStatusCommittee => 'Track a savings committee';

  @override
  String get toolStatusCompound => 'Project growth';

  @override
  String get toolStatusConverter => '32 units';

  @override
  String get toolStatusCricket => 'PAK 214/4';

  @override
  String get toolStatusCurrency => 'Live rates';

  @override
  String get toolStatusCycle => 'Private';

  @override
  String get toolStatusDatecalc => 'Add · diff';

  @override
  String get toolStatusDocscan => 'PDF ready';

  @override
  String get toolStatusDocuments => 'Locked';

  @override
  String get toolStatusDuas => '42 saved';

  @override
  String get toolStatusEmergency => '15 · 1122';

  @override
  String get toolStatusEvents => 'Next 14:00';

  @override
  String get toolStatusExpenses => 'This month';

  @override
  String get toolStatusFaraid => 'Inheritance';

  @override
  String get toolStatusFasting => '3 kept';

  @override
  String get toolStatusFlights => 'Track live';

  @override
  String get toolStatusFocus => '25 min';

  @override
  String get toolStatusFuel => 'Pump prices';

  @override
  String get toolStatusFuelcost => 'Trip cost';

  @override
  String get toolStatusGoals => 'Track your savings goals';

  @override
  String get toolStatusGoldrates => 'Gold & FX';

  @override
  String get toolStatusHabits => '12-day streak';

  @override
  String get toolStatusHadith => 'Daily';

  @override
  String get toolStatusHealth => 'Private';

  @override
  String get toolStatusHijri => '15 Rabi’ I';

  @override
  String get toolStatusHolidays => 'This year';

  @override
  String get toolStatusInstallments => 'Track fixed payment plans';

  @override
  String get toolStatusLearning => '3 courses';

  @override
  String get toolStatusLedger => 'Lend and borrow';

  @override
  String get toolStatusLoadshed => '14:00–16:00';

  @override
  String get toolStatusLoan => 'Instalments';

  @override
  String get toolStatusMarkets => 'KSE-100 ▲ 0.8%';

  @override
  String get toolStatusMealplan => 'This week';

  @override
  String get toolStatusMediasaver => 'Save posts';

  @override
  String get toolStatusMeds => 'Private';

  @override
  String get toolStatusMosques => '3 within 1 km';

  @override
  String get toolStatusNames99 => 'Asma ul Husna';

  @override
  String get toolStatusNatsavings => 'Profit rates';

  @override
  String get toolStatusNews => '12 new';

  @override
  String get toolStatusNotes => '12 saved';

  @override
  String get toolStatusPackages => 'Jazz · Zong';

  @override
  String get toolStatusParcel => '1 in transit';

  @override
  String get toolStatusPassport => 'NADRA sizes';

  @override
  String get toolStatusPlay => 'Puzzles';

  @override
  String get toolStatusPrayer => 'Asr 15:53';

  @override
  String get toolStatusPraytrack => '12-day streak';

  @override
  String get toolStatusPregnancy => 'Private';

  @override
  String get toolStatusPrizebonds => 'Draw 15 Sep';

  @override
  String get toolStatusQibla => '267° W';

  @override
  String get toolStatusQr => 'Scan & pay';

  @override
  String get toolStatusQuran => 'Al-Kahf 42';

  @override
  String get toolStatusQuransearch => 'By word';

  @override
  String get toolStatusRamadan => 'In 172 days';

  @override
  String get toolStatusRecipes => '24 saved';

  @override
  String get toolStatusReminders => '4 today';

  @override
  String get toolStatusShopping => '6 items';

  @override
  String get toolStatusSpeedtest => 'Test now';

  @override
  String get toolStatusStopwatch => 'Laps';

  @override
  String get toolStatusStreak => '12 days';

  @override
  String get toolStatusSubs => 'Track recurring subscriptions';

  @override
  String get toolStatusSunmoon => 'Sunrise · sunset';

  @override
  String get toolStatusTaraweeh => 'Ramadan';

  @override
  String get toolStatusTasbih => 'Counter';

  @override
  String get toolStatusTax => 'FBR 2025-26';

  @override
  String get toolStatusTimer => 'Presets';

  @override
  String get toolStatusTipsplit => 'Split a bill';

  @override
  String get toolStatusTodos => '2 of 5 done';

  @override
  String get toolStatusTrains => 'Green Line';

  @override
  String get toolStatusVaccines => 'Private';

  @override
  String get toolStatusVehicle => 'Check challan';

  @override
  String get toolStatusWastatus => 'Android';

  @override
  String get toolStatusWater => 'Daily intake';

  @override
  String get toolStatusWeather => '34° Clear';

  @override
  String get toolStatusWorldclock => '8 cities';

  @override
  String get toolStatusZakat => 'Nisab check';

  @override
  String toolUnavailableHere(String country) {
    return 'Not available in $country yet';
  }

  @override
  String get toolUnavailableText => 'That tool isn’t part of your setup.';

  @override
  String get toolUnavailableTitle => 'Not part of your setup';

  @override
  String toolUnfavourited(String name) {
    return 'Removed $name from favourites';
  }

  @override
  String get toolsForYou => 'For you';

  @override
  String get toolsNoMatch => 'No tools match';

  @override
  String get toolsNoMatchSub =>
      'Try a different word — or browse a category above.';

  @override
  String get toolsNothingYet => 'Nothing here yet';

  @override
  String get toolsNothingYetSub =>
      'Add a few more interests, or browse the full list under All.';

  @override
  String get toolsPersonalise => 'Personalise';

  @override
  String get toolsRecent => 'Recently used';

  @override
  String get toolsRecentSub => 'Straight back to where you were';

  @override
  String toolsResultCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n tools',
      one: '1 tool',
      zero: 'No tools',
    );
    return '$_temp0';
  }

  @override
  String get toolsSearchExample => 'currency';

  @override
  String get toolsSearchExamplePk => 'petrol';

  @override
  String toolsSearchHint(String example) {
    return 'Search tools — try “$example”';
  }

  @override
  String get toolsSearchLabel => 'Search tools';

  @override
  String toolsSub(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n utilities, neatly sorted',
      one: '1 utility, neatly sorted',
    );
    return '$_temp0';
  }

  @override
  String get toolsTitle => 'Tools';

  @override
  String get trainsAllDepartures => 'All departures';

  @override
  String get trainsChooseDestination => 'Choose a destination';

  @override
  String get trainsChooseOrigin => 'Choose a departure station';

  @override
  String trainsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n trains',
      one: '1 train',
    );
    return '$_temp0';
  }

  @override
  String trainsDayOn(String date) {
    return 'Departures for $date';
  }

  @override
  String get trainsDayToday => 'Departures for today';

  @override
  String get trainsDayTomorrow => 'Departures for tomorrow';

  @override
  String get trainsDepartures => 'Departures';

  @override
  String trainsDeparturesSub(String station) {
    return 'From $station';
  }

  @override
  String trainsDuration(String h, String m) {
    return '${h}h ${m}m';
  }

  @override
  String trainsFareFrom(String fare) {
    return 'from $fare';
  }

  @override
  String get trainsFrom => 'From';

  @override
  String trainsHeadSub(String operator) {
    return '$operator · live running status';
  }

  @override
  String get trainsNow => 'Now';

  @override
  String get trainsPickDate => 'Pick a date';

  @override
  String get trainsPickedDate => 'Pick a departure date';

  @override
  String get trainsPopular => 'Popular routes';

  @override
  String get trainsPopularSub => 'Tap to check fares and seats';

  @override
  String get trainsRefreshed => 'Live status refreshed';

  @override
  String trainsRoute(String from, String to) {
    return '$from → $to';
  }

  @override
  String get trainsRouteInvalidText =>
      'A journey needs somewhere to leave from and somewhere to go.';

  @override
  String get trainsRouteInvalidTitle => 'Choose two different stations';

  @override
  String trainsRouteToast(String from, String to, String trains, String fare) {
    return '$from → $to · $trains · $fare';
  }

  @override
  String get trainsSaved => 'Saved journeys';

  @override
  String trainsSearchResult(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n trains on this route today',
      one: '1 train on this route today',
    );
    return '$_temp0';
  }

  @override
  String trainsServiceLine(
    String depart,
    String arrive,
    String duration,
    String fare,
  ) {
    return '$depart → $arrive · $duration · $fare';
  }

  @override
  String get trainsStatusDeparted => 'Departed';

  @override
  String trainsStatusLate(int n) {
    return '$n min late';
  }

  @override
  String get trainsStatusOnTime => 'On time';

  @override
  String get trainsSwap => 'Swap stations';

  @override
  String get trainsSwapped => 'Stations swapped';

  @override
  String trainsSwappedTo(String origin, String destination) {
    return 'Stations swapped: $origin to $destination';
  }

  @override
  String get trainsTo => 'To';

  @override
  String get trainsToday => 'Today';

  @override
  String get trainsTomorrow => 'Tomorrow';

  @override
  String trainsTrackedSummary(
    String name,
    String number,
    String route,
    String status,
    String percent,
  ) {
    return '$name $number, $route, $status, $percent';
  }

  @override
  String get trainsTracking => 'You are tracking';

  @override
  String get trainsUnavailableTitle => 'Trains are not in your setup';

  @override
  String trainsUpdated(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Updated $n minutes ago',
      one: 'Updated 1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String get unitDays => 'days';

  @override
  String get unitGram => 'g';

  @override
  String get unitHpa => 'hPa';

  @override
  String unitKcalCount(String n) {
    return '$n kcal';
  }

  @override
  String get unitKm => 'km';

  @override
  String get unitKmh => 'km/h';

  @override
  String get unitMi => 'mi';

  @override
  String get unitMinutes => 'min';

  @override
  String unitMinutesCount(String n) {
    return '$n min';
  }

  @override
  String get unitMph => 'mph';

  @override
  String unitOfTotal(int total) {
    return '/$total';
  }

  @override
  String get unitOunce => 'oz';

  @override
  String get unitThousand => 'k';

  @override
  String get unitTola => 'tola';

  @override
  String get unitYearsSuffix => 'years';

  @override
  String get weatherAir => 'Air quality';

  @override
  String get weatherAlertHeat => 'Heat advisory';

  @override
  String get weatherAlertHeatText =>
      'Temperatures above 38° through the afternoon. Limit outdoor exertion and drink more than usual.';

  @override
  String get weatherBreezy => 'Breezy';

  @override
  String get weatherBrightAndBreezy => 'Bright and breezy';

  @override
  String get weatherChangeable => 'Changeable';

  @override
  String get weatherClear => 'Clear';

  @override
  String get weatherClearAndDry => 'Clear and dry';

  @override
  String get weatherClearVeryWarm => 'Clear · very warm';

  @override
  String get weatherCloudBuilding => 'Cloud building';

  @override
  String get weatherCloudy => 'Cloudy';

  @override
  String get weatherDetails => 'Conditions';

  @override
  String get weatherDew => 'Dew point';

  @override
  String weatherFeels(String t) {
    return 'Feels like $t';
  }

  @override
  String get weatherForecast => 'Five days';

  @override
  String get weatherFresh => 'Fresh';

  @override
  String get weatherGusts => 'Gusts';

  @override
  String get weatherHazy => 'hazy';

  @override
  String get weatherHazySun => 'Hazy sun';

  @override
  String get weatherHazySunHumid => 'Hazy sun · humid';

  @override
  String weatherHighLow(String high, String low) {
    return '$high / $low';
  }

  @override
  String weatherHilo(String hi, String lo) {
    return 'High $hi · Low $lo';
  }

  @override
  String get weatherHourly => 'Next 12 hours';

  @override
  String get weatherHumid => 'Humid';

  @override
  String get weatherHumidAfternoonStorms => 'Humid · afternoon storms';

  @override
  String get weatherHumidCloudBuilding => 'Humid · cloud building';

  @override
  String get weatherHumidLightHaze => 'Humid · light haze';

  @override
  String get weatherHumidPassingShowers => 'Humid · passing showers';

  @override
  String get weatherHumidShowersLater => 'Humid · showers later';

  @override
  String get weatherHumidity => 'Humidity';

  @override
  String get weatherLightCloud => 'Light cloud';

  @override
  String get weatherMildAndClear => 'Mild and clear';

  @override
  String get weatherMostlyClear => 'Mostly clear';

  @override
  String get weatherOvercast => 'Overcast';

  @override
  String get weatherPressure => 'Pressure';

  @override
  String get weatherRain => 'Rain';

  @override
  String weatherRainChance(String pct) {
    return '$pct% Rain';
  }

  @override
  String get weatherStatRain => 'Rain';

  @override
  String get weatherSunnySpells => 'Sunny spells';

  @override
  String get weatherUv => 'UV index';

  @override
  String get weatherUvHigh => 'High';

  @override
  String get weatherUvModerate => 'Moderate';

  @override
  String weatherUvValue(String n, String band) {
    return '$n · $band';
  }

  @override
  String get weatherVisibility => 'Visibility';

  @override
  String get weatherWarm => 'Warm';

  @override
  String get weatherWarmAndDry => 'Warm and dry';

  @override
  String get weatherWarmAndHumid => 'Warm and humid';

  @override
  String get weatherWind => 'Wind';

  @override
  String get ledgerNet => 'Net position';

  @override
  String get ledgerOwedOverall => 'owed to you overall';

  @override
  String get ledgerOweOverall => 'you owe overall';

  @override
  String get ledgerEvenOverall => 'even overall';

  @override
  String get ledgerOwedToYou => 'Owed to you';

  @override
  String get ledgerYouOwe => 'You owe';

  @override
  String get ledgerPeople => 'People';

  @override
  String ledgerSummaryCurrency(String code) {
    return 'In $code';
  }

  @override
  String get ledgerFilterLabel => 'Show people by their current balance';

  @override
  String get ledgerFilterOwesYou => 'Owes you';

  @override
  String get ledgerOwesYou => 'owes you';

  @override
  String get ledgerYouOweShort => 'you owe';

  @override
  String get ledgerEvenRow => 'open both ways';

  @override
  String get ledgerSettledRow => 'settled';

  @override
  String ledgerCreditToThem(String amount) {
    return '$amount credit to them';
  }

  @override
  String ledgerCreditFromThem(String amount) {
    return '$amount your credit';
  }

  @override
  String ledgerDue(String date) {
    return 'due $date';
  }

  @override
  String get ledgerNoEntries => 'No entries yet';

  @override
  String get ledgerNeedsReconcile => 'Needs reconciling';

  @override
  String get ledgerArchivedBadge => 'Archived';

  @override
  String get ledgerRecent => 'Recent';

  @override
  String get ledgerAdd => 'Add an entry';

  @override
  String get ledgerRemind => 'Send a reminder';

  @override
  String get ledgerAddPerson => 'Add a person';

  @override
  String get ledgerEmptyTitle => 'Money lent and borrowed, in one place';

  @override
  String get ledgerEmptyText =>
      'Add a person, then record what you lend, borrow and get back. Balances, overdue dates and credit are worked out from your entries.';

  @override
  String get ledgerNoMatch => 'Nobody here';

  @override
  String get ledgerNoMatchText => 'No one matches this filter or search.';

  @override
  String get ledgerShowAll => 'Show all';

  @override
  String get ledgerSearch => 'Search people and notes';

  @override
  String get ledgerSortDue => 'Due date';

  @override
  String get ledgerSortName => 'Name';

  @override
  String get ledgerSortRecent => 'Recent activity';

  @override
  String get ledgerShowArchived => 'Include archived';

  @override
  String get ledgerOverdueUnknown =>
      'Overdue needs your day, and it can\'t be worked out. Dates are written out in full.';

  @override
  String get ledgerMoneyOut => 'Money out';

  @override
  String get ledgerMoneyIn => 'Money in';

  @override
  String get ledgerKindLent => 'You lent';

  @override
  String get ledgerKindBorrowed => 'You borrowed';

  @override
  String get ledgerKindRepaidToMe => 'They paid you back';

  @override
  String get ledgerKindRepaidByMe => 'You paid them back';

  @override
  String get ledgerKindLentShort => 'Lent';

  @override
  String get ledgerKindBorrowedShort => 'Borrowed';

  @override
  String get ledgerKindRepaidToMeShort => 'Got back';

  @override
  String get ledgerKindRepaidByMeShort => 'Paid back';

  @override
  String get ledgerVoided => 'Voided';

  @override
  String get ledgerHistory => 'History';

  @override
  String get ledgerOpenLoans => 'Open';

  @override
  String ledgerLeftOf(String left, String total) {
    return '$left left of $total';
  }

  @override
  String ledgerAppliedTo(String amount, String date) {
    return '$amount to the $date entry';
  }

  @override
  String ledgerPaidFrom(String amount, String date) {
    return '$amount from the $date repayment';
  }

  @override
  String ledgerKeptAsCredit(String amount) {
    return '$amount kept as credit';
  }

  @override
  String get ledgerManualBadge => 'Chosen';

  @override
  String get ledgerSettleUp => 'Settle up';

  @override
  String ledgerSettleOwes(String name, String amount) {
    return 'Record $name paying back $amount';
  }

  @override
  String ledgerSettleOwe(String name, String amount) {
    return 'Record paying $name back $amount';
  }

  @override
  String get ledgerSettleText => 'One repayment, dated today, that clears:';

  @override
  String get ledgerSettleConfirm => 'Record it';

  @override
  String get ledgerRename => 'Edit person';

  @override
  String get ledgerArchive => 'Archive';

  @override
  String get ledgerUnarchive => 'Unarchive';

  @override
  String get ledgerDeletePerson => 'Delete person';

  @override
  String get ledgerArchiveOpen => 'Only a settled person can be archived.';

  @override
  String ledgerPersonReferenced(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n entries still name this person. Delete them first — nothing is deleted with them.',
      one:
          '1 entry still names this person. Delete it first — nothing is deleted with them.',
    );
    return '$_temp0';
  }

  @override
  String get ledgerDeletePersonTitle => 'Delete this person?';

  @override
  String get ledgerDeletePersonText =>
      'They have no entries. This can\'t be undone.';

  @override
  String get ledgerReconcile => 'Reconcile';

  @override
  String get ledgerDamagedText =>
      'The allocations on file for this person don\'t add up. Nothing is recalculated until you reconcile.';

  @override
  String ledgerDefects(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n records can\'t be read and are shown as damaged.',
      one: '1 record can\'t be read and is shown as damaged.',
    );
    return '$_temp0';
  }

  @override
  String get ledgerVoid => 'Void';

  @override
  String get ledgerRestore => 'Restore';

  @override
  String get ledgerVoidText =>
      'Voiding keeps the entry and its history, and takes it out of every figure.';

  @override
  String get ledgerNewPerson => 'New person';

  @override
  String get ledgerPersonName => 'Name';

  @override
  String get ledgerNote => 'Note';

  @override
  String get ledgerOptional => 'Optional';

  @override
  String get ledgerNewEntry => 'New entry';

  @override
  String get ledgerEditEntry => 'Edit entry';

  @override
  String get ledgerFieldPerson => 'Person';

  @override
  String get ledgerFieldKind => 'What happened';

  @override
  String get ledgerFieldAmount => 'Amount';

  @override
  String get ledgerFieldCurrency => 'Currency';

  @override
  String get ledgerFieldDate => 'Date';

  @override
  String get ledgerFieldDue => 'Due';

  @override
  String get ledgerNoDue => 'No due date';

  @override
  String get ledgerChooseDate => 'Choose a date';

  @override
  String get ledgerFieldApply => 'Apply to';

  @override
  String get ledgerApplyAuto => 'Oldest due first';

  @override
  String get ledgerApplyManual => 'Choose';

  @override
  String ledgerApplyNone(String code) {
    return 'Nothing is open in $code for this person.';
  }

  @override
  String get ledgerErrName => 'Enter a name';

  @override
  String get ledgerErrLong => 'That\'s too long';

  @override
  String get ledgerErrPerson => 'Choose a person';

  @override
  String get ledgerErrAmount => 'Enter an amount above zero';

  @override
  String get ledgerErrNumber => 'Enter a number, like 1500 or 1500.50';

  @override
  String ledgerErrPrecision(String code, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n decimal places',
      one: 'one decimal place',
      zero: 'no decimal places',
    );
    return '$code takes $_temp0';
  }

  @override
  String get ledgerErrTooLarge =>
      'That amount is larger than a ledger entry can hold';

  @override
  String get ledgerErrDate => 'Choose a date';

  @override
  String get ledgerErrDueBefore => 'Due can\'t be before the date';

  @override
  String get ledgerErrApplied =>
      'The amounts you apply can\'t add up to more than the repayment';

  @override
  String get ledgerErrAppliedOver => 'More than is open on this entry';

  @override
  String ledgerErrWithdrawn(String code) {
    return '$code is no longer issued. Use it only to repay or correct an amount already kept in $code.';
  }

  @override
  String currencyWithdrawnValue(String code) {
    return '$code · no longer issued';
  }

  @override
  String get instEmptyTitle => 'No payment plans yet';

  @override
  String get instEmptyText =>
      'Add something you are paying for in fixed monthly instalments. Lume keeps its schedule and works out what is paid, due and left.';

  @override
  String get instAdd => 'Add a plan';

  @override
  String get instDueThisMonth => 'Due this month';

  @override
  String get instPaidToDate => 'Paid so far';

  @override
  String get instRemaining => 'Remaining';

  @override
  String instActivePlans(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n active plans',
      one: '1 active plan',
      zero: 'No active plans',
    );
    return '$_temp0';
  }

  @override
  String get instLateInstalments => 'Late instalments';

  @override
  String instSummaryCurrency(String code) {
    return 'In $code';
  }

  @override
  String get instDayUnknown => 'Day unknown';

  @override
  String get instDayUnknownText =>
      'Your time zone can\'t be worked out, so no instalment is marked late or due this month. Set your city in Account › Time.';

  @override
  String get instFilterLabel => 'Plans shown';

  @override
  String get instFilterActive => 'Active';

  @override
  String get instFilterLate => 'Late';

  @override
  String get instFilterCompleted => 'Completed';

  @override
  String get instFilterCancelled => 'Cancelled';

  @override
  String get instSortNext => 'Next due';

  @override
  String get instSortLeft => 'Payments left';

  @override
  String get instSortAmount => 'Monthly amount';

  @override
  String get instSortName => 'Name';

  @override
  String get instSortRecent => 'Recent activity';

  @override
  String get instSearch => 'Search plans';

  @override
  String get instPlans => 'Plans';

  @override
  String get instComingUp => 'Coming up';

  @override
  String get instDueByMonth => 'Due by month';

  @override
  String instDueByMonthCap(String code) {
    return 'What falls due each month on plans still running, in $code.';
  }

  @override
  String get instOtherCurrencies =>
      'Plans in other currencies are counted separately above.';

  @override
  String instChartEntry(String month, String amount) {
    return '$month: $amount';
  }

  @override
  String instPaidOf(String paid, String count) {
    return '$paid of $count paid';
  }

  @override
  String instNextOn(String date) {
    return 'next $date';
  }

  @override
  String get instPerMonth => 'a month';

  @override
  String instProgressValue(String percent) {
    return '$percent paid';
  }

  @override
  String get instPaid => 'Paid';

  @override
  String get instDueToday => 'Due today';

  @override
  String get instUpcoming => 'Upcoming';

  @override
  String get instVoided => 'Voided';

  @override
  String get instNeedsAttention => 'Needs attention';

  @override
  String get instDamagedText =>
      'This plan\'s records don\'t agree. Its figures are left out of the totals, and nothing is written over it. You can delete it.';

  @override
  String instDefects(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n records can\'t be read. They are kept as they are, and their plans are left out of the totals.',
      one:
          '1 record can\'t be read. It is kept as it is, and its plan is left out of the totals.',
    );
    return '$_temp0';
  }

  @override
  String instInstalment(String n) {
    return 'Instalment $n';
  }

  @override
  String instInstalmentOf(String n, String count) {
    return 'Instalment $n of $count';
  }

  @override
  String instDueOn(String date) {
    return 'Due $date';
  }

  @override
  String instPaidOn(String date) {
    return 'Paid $date';
  }

  @override
  String get instFieldItem => 'What you bought';

  @override
  String get instFieldMerchant => 'Merchant';

  @override
  String get instFieldNote => 'Note';

  @override
  String get instFieldCurrency => 'Currency';

  @override
  String get instFieldAmount => 'Instalment amount';

  @override
  String get instFieldCount => 'Number of instalments';

  @override
  String get instFieldFirstDue => 'First instalment due';

  @override
  String get instFieldDeposit => 'Deposit already paid';

  @override
  String get instFieldDepositOn => 'Deposit paid on';

  @override
  String get instFieldCashPrice => 'Cash price';

  @override
  String get instFrequency => 'How often';

  @override
  String get instMonthly => 'Monthly';

  @override
  String get instNone => 'None';

  @override
  String get instTotalPayable => 'Total payable';

  @override
  String get instScheduledTotal => 'Instalments total';

  @override
  String get instCashDifference => 'Difference from cash price';

  @override
  String get instCashDifferenceNote =>
      'Total payable less the cash price you entered. Lume works out no interest.';

  @override
  String get instSchedule => 'Schedule';

  @override
  String get instPayments => 'Payments';

  @override
  String get instNoPayments => 'No payments yet';

  @override
  String instPayNext(String n) {
    return 'Pay instalment $n';
  }

  @override
  String get instEdit => 'Edit';

  @override
  String get instCancelPlan => 'Cancel plan';

  @override
  String get instReinstate => 'Reinstate';

  @override
  String get instDeletePlan => 'Delete plan';

  @override
  String get instVoidPayment => 'Void payment';

  @override
  String get instRestorePayment => 'Restore payment';

  @override
  String get instPayTitle => 'Record a payment';

  @override
  String instPayText(String n, String count, String amount, String date) {
    return 'Instalment $n of $count: $amount, due $date. It is recorded as paid in full.';
  }

  @override
  String get instPaidOnLabel => 'Paid on';

  @override
  String get instPayConfirm => 'Record payment';

  @override
  String get instPaidToast => 'Payment recorded';

  @override
  String get instVoidedToast => 'Payment voided';

  @override
  String get instRestoredToast => 'Payment restored';

  @override
  String get instCancelTitle => 'Cancel this plan?';

  @override
  String get instCancelText =>
      'The plan, its schedule and its payments are kept. It moves to Cancelled and no longer counts in what is due or left. Nothing is refunded.';

  @override
  String get instKeepPlan => 'Keep plan';

  @override
  String get instCancelledToast => 'Plan cancelled';

  @override
  String get instReinstatedToast => 'Plan reinstated';

  @override
  String get instDeleteTitle => 'Delete this plan?';

  @override
  String instDeleteText(String rows, String payments) {
    return 'This removes the plan, all $rows of its scheduled instalments and $payments recorded payments. It is for a plan added by mistake — to stop a real plan, cancel it.';
  }

  @override
  String get instDeletedToast => 'Plan deleted';

  @override
  String get instRestoredPlanToast => 'Plan restored';

  @override
  String get instNewPlan => 'New plan';

  @override
  String get instEditPlan => 'Edit plan';

  @override
  String get instLockedTitle => 'Terms are fixed';

  @override
  String get instLockedText =>
      'Payments are recorded, so the amount, number of instalments, currency, dates and deposit are fixed. To change them, cancel this plan and add a new one.';

  @override
  String get instRebuildText =>
      'Changing the amount, count, currency or dates rebuilds the schedule.';

  @override
  String get instSaved => 'Saved';

  @override
  String get instErrItem => 'Enter what you bought';

  @override
  String get instErrLong => 'That is too long';

  @override
  String get instErrCount => 'Enter a whole number from 1 to 600';

  @override
  String get instErrDate => 'Choose a date';

  @override
  String get instErrDepositPair => 'A deposit needs both an amount and a date';

  @override
  String get instErrRange => 'That schedule runs past the calendar';

  @override
  String get instErrTooLarge => 'That total is too large';

  @override
  String instErrWithdrawn(String code) {
    return '$code is no longer issued. Choose a current currency.';
  }

  @override
  String get instErrFailed => 'Couldn\'t save. Nothing was changed.';

  @override
  String get instErrConflict =>
      'This plan changed somewhere else. Nothing was saved.';

  @override
  String get instErrDamaged =>
      'This plan\'s records don\'t agree, so nothing was written.';

  @override
  String instErrOutOfOrder(String n) {
    return 'Pay instalment $n first.';
  }

  @override
  String get instErrCancelled =>
      'This plan is cancelled. Reinstate it to record a payment.';

  @override
  String get instErrCompleted =>
      'Every instalment is paid; there is nothing to cancel.';

  @override
  String get instErrAlreadyPaid => 'That instalment is already paid.';

  @override
  String get instNoMatch => 'No plans here';

  @override
  String get instNoMatchText => 'Nothing matches this filter or search.';

  @override
  String get instShowAll => 'Show all';

  @override
  String get instNotFound => 'That plan isn\'t here any more.';

  @override
  String get instExportTitle => 'Export plans';

  @override
  String get instExportJson => 'Backup (JSON)';

  @override
  String get instExportJsonSub =>
      'Everything, exactly. It can be imported back.';

  @override
  String get instExportCsv => 'Spreadsheet (CSV)';

  @override
  String get instExportCsvSub =>
      'One row per instalment. It can\'t be imported.';

  @override
  String get instIncludeNames => 'Include items, merchants and notes';

  @override
  String get instIncludeNamesOff =>
      'Plans are written as numbered labels (“Plan 1”). Merchants and notes are left out.';

  @override
  String get instIncludeNamesOn =>
      'Items, merchants and notes are written as you entered them.';

  @override
  String get instExportAction => 'Export';

  @override
  String get instImport => 'Import a backup';

  @override
  String get instImportPaste => 'Paste a Lume installments backup (JSON)';

  @override
  String get instImportCheck => 'Check';

  @override
  String instImportReady(String create, String update, String unchanged) {
    return '$create new · $update updated · $unchanged unchanged. Nothing is written until you import.';
  }

  @override
  String instImportIssues(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n problems — nothing will be imported',
      one: '1 problem — nothing will be imported',
    );
    return '$_temp0';
  }

  @override
  String get instImportAction => 'Import';

  @override
  String instImported(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Imported $n records',
      one: 'Imported 1 record',
    );
    return '$_temp0';
  }

  @override
  String get instImportNoNames =>
      'This backup has no names; plans come in as “Plan 1”, “Plan 2”.';

  @override
  String get goalsSummaryKicker => 'Saved so far';

  @override
  String goalsSummaryCaption(String target) {
    return 'of $target across all goals';
  }

  @override
  String get goalsStatActive => 'Active goals';

  @override
  String get goalsStatThisMonth => 'This month';

  @override
  String get goalsStatNext => 'Next to complete';

  @override
  String get goalsYourGoals => 'Your goals';

  @override
  String get goalsOtherGoals => 'Completed & abandoned';

  @override
  String goalsOfTarget(String saved, String target) {
    return '$saved of $target';
  }

  @override
  String goalsByDate(String date) {
    return 'by $date';
  }

  @override
  String goalsToGo(String amount) {
    return '$amount to go';
  }

  @override
  String goalsProjectedDate(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in $n months',
      one: 'in 1 month',
      zero: 'Any time now',
    );
    return '$_temp0';
  }

  @override
  String get goalsReached => 'Target reached';

  @override
  String get goalsChartTitle => 'Contributions';

  @override
  String get goalsAddGoal => 'Add a goal';

  @override
  String get goalsAddContribution => 'Add a contribution';

  @override
  String get goalsEmptyTitle => 'No savings goals yet';

  @override
  String get goalsEmptyText =>
      'A goal turns a vague intention into a monthly number.';

  @override
  String get goalsNewGoal => 'New goal';

  @override
  String get goalsEditGoal => 'Edit goal';

  @override
  String get goalsFieldName => 'Name';

  @override
  String get goalsFieldNote => 'Note';

  @override
  String get goalsFieldTarget => 'Target amount';

  @override
  String get goalsFieldTargetDate => 'Target date';

  @override
  String get goalsFieldIcon => 'Icon';

  @override
  String get goalsFieldCurrency => 'Currency';

  @override
  String get goalsErrName => 'Name this goal';

  @override
  String get goalsErrLong => 'That is too long';

  @override
  String get goalsErrTarget => 'Enter a target amount';

  @override
  String goalsErrWithdrawn(String code) {
    return '$code is no longer issued. Choose a current currency.';
  }

  @override
  String goalsErrCurrencyLocked(String code) {
    return 'This goal already has contributions in $code. Delete them first to change its currency.';
  }

  @override
  String get goalsErrAmount => 'Enter an amount';

  @override
  String get goalsErrConflict => 'This goal changed elsewhere';

  @override
  String get goalsErrClosed => 'This goal is completed or abandoned';

  @override
  String get goalsErrDamaged =>
      'This goal\'s records don\'t add up and can\'t be shown safely';

  @override
  String get goalsErrTooLarge => 'That amount is too large';

  @override
  String get goalsErrFailed => 'That didn\'t save. Try again.';

  @override
  String get goalsNotFound => 'That goal isn\'t there any more';

  @override
  String get goalsStateActive => 'Active';

  @override
  String get goalsStateCompleted => 'Completed';

  @override
  String get goalsStateAbandoned => 'Abandoned';

  @override
  String get goalsMarkComplete => 'Mark completed';

  @override
  String get goalsMarkCompleteAsk => 'Mark this goal completed?';

  @override
  String get goalsMarkCompleteText =>
      'It stays in your history, just no longer counted toward what\'s left to save.';

  @override
  String get goalsMarkCompleteToast => 'Goal completed';

  @override
  String get goalsAbandon => 'Abandon goal';

  @override
  String get goalsAbandonAsk => 'Abandon this goal?';

  @override
  String get goalsAbandonText =>
      'It stays in your history. You can reactivate it any time.';

  @override
  String get goalsAbandonToast => 'Goal abandoned';

  @override
  String get goalsReactivate => 'Reactivate';

  @override
  String get goalsReactivatedToast => 'Goal reactivated';

  @override
  String get goalsDeleteAsk => 'Delete this goal?';

  @override
  String get goalsDeleteText =>
      'This removes the goal and every contribution logged to it.';

  @override
  String get goalsDeletedToast => 'Goal deleted';

  @override
  String get goalsContributionAdded => 'Contribution added';

  @override
  String get goalsVoidContribution => 'Remove this contribution';

  @override
  String get goalsContributionVoidedToast => 'Contribution removed';

  @override
  String get goalsHistoryTitle => 'Contribution history';

  @override
  String get goalsHistoryEmpty => 'No contributions yet';

  @override
  String goalsShareText(String saved, String target, String pct) {
    return '$saved of $target — $pct%';
  }

  @override
  String get subsSummaryKicker => 'Every month';

  @override
  String subsSummaryCaption(String amount) {
    return '$amount a year';
  }

  @override
  String get subsStatActive => 'Active';

  @override
  String get subsStatNext => 'Next renewal';

  @override
  String subsRenewsIn(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in $n days',
      one: 'in 1 day',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String get subsSearch => 'Search subscriptions';

  @override
  String get subsAll => 'All subscriptions';

  @override
  String get subsPerMonth => 'per month';

  @override
  String get subsPerYear => 'per year';

  @override
  String subsEveryDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'every $n days',
      one: 'every day',
    );
    return '$_temp0';
  }

  @override
  String get subsByCategory => 'By category';

  @override
  String get subsUncategorised => 'Other';

  @override
  String get subsTimeline => 'Coming up';

  @override
  String get subsAddSubscription => 'Add a subscription';

  @override
  String get subsEmptyTitle => 'No subscriptions yet';

  @override
  String get subsEmptyText => 'Track what renews, and when, in one place.';

  @override
  String get subsNewSubscription => 'New subscription';

  @override
  String get subsEditSubscription => 'Edit subscription';

  @override
  String get subsFieldName => 'Name';

  @override
  String get subsFieldCategory => 'Category';

  @override
  String get subsFieldAmount => 'Amount';

  @override
  String get subsFieldCycle => 'Billing cycle';

  @override
  String get subsFieldCustomDays => 'Every how many days';

  @override
  String get subsFieldStartedOn => 'Started on';

  @override
  String get subsFieldCurrency => 'Currency';

  @override
  String get subsCycleMonthly => 'Monthly';

  @override
  String get subsCycleYearly => 'Yearly';

  @override
  String get subsCycleCustom => 'Custom';

  @override
  String get subsErrName => 'Name this subscription';

  @override
  String get subsErrLong => 'That is too long';

  @override
  String get subsErrAmount => 'Enter an amount';

  @override
  String get subsErrCustomDays => 'Enter a day count between 1 and 3,660';

  @override
  String subsErrWithdrawn(String code) {
    return '$code is no longer issued. Choose a current currency.';
  }

  @override
  String get subsErrConflict => 'This subscription changed elsewhere';

  @override
  String get subsErrDamaged =>
      'This subscription\'s records don\'t add up and can\'t be shown safely';

  @override
  String get subsErrTooLarge => 'That amount is too large';

  @override
  String get subsErrFailed => 'That didn\'t save. Try again.';

  @override
  String get subsNotFound => 'That subscription isn\'t there any more';

  @override
  String get subsFilterActive => 'Active';

  @override
  String get subsFilterCancelled => 'Cancelled';

  @override
  String get subsFilterAll => 'All';

  @override
  String get subsSortRenewal => 'Renewal';

  @override
  String get subsSortAmount => 'Amount';

  @override
  String get subsSortName => 'Name';

  @override
  String get subsCancelAsk => 'Cancel this subscription?';

  @override
  String get subsCancelText =>
      'It stays in your history under Cancelled. You can reactivate it any time.';

  @override
  String get subsCancelToast => 'Subscription cancelled';

  @override
  String get subsCancel => 'Cancel subscription';

  @override
  String get subsReactivate => 'Reactivate';

  @override
  String get subsReactivatedToast => 'Subscription reactivated';

  @override
  String get subsDeleteAsk => 'Delete this subscription?';

  @override
  String get subsDeleteText => 'This removes the subscription completely.';

  @override
  String get subsDeletedToast => 'Subscription deleted';

  @override
  String get ledgerErrArchived =>
      'This person is archived. Unarchive them to add entries.';

  @override
  String get ledgerOverpayTitle => 'More than is open';

  @override
  String ledgerOverpayToMe(String name, String amount) {
    return '$name has paid back $amount more than is open. Keep it as credit to $name? It will count against the next loan to them.';
  }

  @override
  String ledgerOverpayByMe(String name, String amount) {
    return 'You\'re paying $name back $amount more than is open. Keep it as your credit with $name? It will count against the next time you borrow from them.';
  }

  @override
  String get ledgerKeepCredit => 'Keep as credit';

  @override
  String get ledgerConflictTitle => 'Your chosen allocation no longer fits';

  @override
  String get ledgerConflictText =>
      'This change leaves less open than you applied by hand. Nothing was saved. Switch those to oldest due first and save?';

  @override
  String get ledgerDeleteEntryTitle => 'Delete this entry?';

  @override
  String get ledgerDeleteEntryText =>
      'Only for a mistake — to correct history, void it instead. It\'s removed with its allocations, and you can undo for a few seconds.';

  @override
  String get ledgerOrphanTitle => 'Repayments paid this entry';

  @override
  String ledgerOrphanText(String amount) {
    return '$amount was paid back against it. Keep that as credit, or delete those repayments too?';
  }

  @override
  String get ledgerOrphanDelete => 'Delete them too';

  @override
  String get ledgerSaved => 'Saved';

  @override
  String get ledgerDeleted => 'Entry deleted';

  @override
  String get ledgerRestoredToast => 'Brought back';

  @override
  String get ledgerVoidedToast => 'Entry voided';

  @override
  String get ledgerUnvoidedToast => 'Entry restored';

  @override
  String get ledgerArchivedToast => 'Archived';

  @override
  String get ledgerUnarchivedToast => 'Unarchived';

  @override
  String get ledgerPersonDeleted => 'Person deleted';

  @override
  String get ledgerReconciled => 'Reconciled';

  @override
  String get ledgerWriteFailed => 'Couldn\'t save. Nothing was changed.';

  @override
  String get ledgerWriteConflict =>
      'This changed while you were editing. Nothing was saved.';

  @override
  String get ledgerWriteDamaged =>
      'This person\'s records need reconciling first. Nothing was saved.';

  @override
  String get ledgerNotFound => 'That person isn\'t in your Ledger.';

  @override
  String get ledgerRemindTitle => 'Reminder';

  @override
  String get ledgerRemindChoose => 'Who to remind';

  @override
  String get ledgerRemindNone =>
      'No one owes you anything to remind them about.';

  @override
  String ledgerRemindBody(String name, String amount, String date) {
    return 'Hi $name, a reminder about $amount from $date.';
  }

  @override
  String ledgerRemindBodyDue(
    String name,
    String amount,
    String date,
    String due,
  ) {
    return 'Hi $name, a reminder about $amount from $date, due $due.';
  }

  @override
  String get ledgerRemindMessage => 'Message';

  @override
  String get ledgerRemindFields => 'Included: name, amount and currency, date.';

  @override
  String get ledgerRemindFieldsDue =>
      'Included: name, amount and currency, date, due date.';

  @override
  String get ledgerRemindExcluded =>
      'Not included: notes, other people, other currencies, record ids.';

  @override
  String get ledgerRemindHow =>
      'Lume doesn\'t send this. Your share sheet does, to whoever you choose there.';

  @override
  String get ledgerRemindShare => 'Share';

  @override
  String get ledgerRemindHanded => 'Handed to your share sheet';

  @override
  String get ledgerRemindUnavailable =>
      'Sharing isn\'t available on this device';

  @override
  String get ledgerRemindFailed => 'The share sheet couldn\'t open';

  @override
  String get ledgerExportTitle => 'Export your Ledger';

  @override
  String get ledgerExportJson => 'Full backup (JSON)';

  @override
  String get ledgerExportJsonSub =>
      'Every entry and allocation. It can be imported again.';

  @override
  String get ledgerExportCsv => 'Spreadsheet (CSV)';

  @override
  String get ledgerExportCsvSub =>
      'One row per entry. It can\'t be imported — use the full backup for that.';

  @override
  String get ledgerIncludeNames => 'Include names and notes';

  @override
  String get ledgerIncludeNamesOn =>
      'This file will contain the names and notes you typed. Anyone you give it to can read them.';

  @override
  String get ledgerIncludeNamesOff =>
      'People are written as Person 1, Person 2… and notes are left out.';

  @override
  String get ledgerExportAction => 'Export';

  @override
  String get ledgerImport => 'Import a backup';

  @override
  String get ledgerImportPaste =>
      'Paste the contents of a lume.ledger/1 backup';

  @override
  String get ledgerImportCheck => 'Check';

  @override
  String ledgerImportReady(int c, int u, int s) {
    return 'Ready: $c to add, $u to update, $s already here. Nothing is written until you import.';
  }

  @override
  String ledgerImportIssues(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n problems. Nothing will be imported.',
      one: '1 problem. Nothing will be imported.',
    );
    return '$_temp0';
  }

  @override
  String get ledgerImportNoNames =>
      'This backup has no names: people will be named Person 1, Person 2…';

  @override
  String get ledgerImportAction => 'Import';

  @override
  String ledgerImported(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Imported $n records',
      one: 'Imported 1 record',
    );
    return '$_temp0';
  }

  @override
  String get commEmptyTitle => 'No committees yet';

  @override
  String get commEmptyText =>
      'Add a savings committee you are part of. Lume keeps its members, its turns and its cycles, and works out what is collected, paid out and still owed.';

  @override
  String get commAdd => 'Add a committee';

  @override
  String get commCommittees => 'Committees';

  @override
  String get commSearch => 'Search committees';

  @override
  String get commFilterLabel => 'Filter committees';

  @override
  String get commFilterRunning => 'Running';

  @override
  String get commFilterLate => 'Late';

  @override
  String get commFilterCompleted => 'Completed';

  @override
  String get commFilterCancelled => 'Cancelled';

  @override
  String get commSortNext => 'Next cycle';

  @override
  String get commSortName => 'Name';

  @override
  String get commSortAmount => 'Contribution';

  @override
  String get commSortRecent => 'Recent activity';

  @override
  String get commNoMatch => 'Nothing matches';

  @override
  String get commNoMatchText => 'No committee matches this filter and search.';

  @override
  String get commShowAll => 'Show all';

  @override
  String get commNotFound => 'That committee is not here';

  @override
  String get commInThePot => 'Collected, not paid out';

  @override
  String get commCollected => 'Collected';

  @override
  String get commPaidOut => 'Paid out';

  @override
  String get commOutstanding => 'Outstanding';

  @override
  String commRunning(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n running committees',
      one: '1 running committee',
      zero: 'No running committees',
    );
    return '$_temp0';
  }

  @override
  String commSummaryCurrency(String code) {
    return 'In $code';
  }

  @override
  String get commPoolEachCycle => 'Pool each cycle';

  @override
  String commCycleOf(String n, String total) {
    return 'Cycle $n of $total';
  }

  @override
  String commBeforeStart(String date) {
    return 'Starts $date';
  }

  @override
  String get commYourContribution => 'Your contribution';

  @override
  String get commPeople => 'People';

  @override
  String get commShares => 'Shares';

  @override
  String get commYourTurn => 'Your turn';

  @override
  String commTurnCycle(String n) {
    return 'Cycle $n';
  }

  @override
  String get commTurnDone => 'Received';

  @override
  String get commTurnNone => 'No turn';

  @override
  String get commThisCycle => 'This cycle';

  @override
  String get commPayoutOrder => 'Payout order';

  @override
  String get commPayoutOrderCap =>
      'Settled when the committee was created. The order records are entered in does not change it.';

  @override
  String get commCollectedEachCycle => 'Collected each cycle';

  @override
  String commCollectedCap(String code) {
    return 'What each cycle has collected of its pool, in $code.';
  }

  @override
  String get commOtherCurrencies =>
      'Committees in other currencies are counted on their own.';

  @override
  String commChartEntry(String cycle, String amount) {
    return '$cycle: $amount';
  }

  @override
  String get commMembersSection => 'Members';

  @override
  String commReceivesCycle(String n) {
    return 'Receives cycle $n';
  }

  @override
  String commReceivesCycles(String list) {
    return 'Receives cycles $list';
  }

  @override
  String commShareCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n shares',
      one: '1 share',
    );
    return '$_temp0';
  }

  @override
  String get commYouLabel => 'You';

  @override
  String commPaidOn(String date) {
    return 'Paid $date';
  }

  @override
  String commDueOn(String date) {
    return 'Due $date';
  }

  @override
  String commCollectedOf(String collected, String pool) {
    return '$collected of $pool';
  }

  @override
  String commShortBy(String amount) {
    return 'Short $amount';
  }

  @override
  String commCyclesPaidOut(String done, String total) {
    return '$done of $total cycles paid out';
  }

  @override
  String get commNoHistory => 'Nothing recorded yet';

  @override
  String get commFactContribution => 'Contribution a cycle';

  @override
  String get commFactCycles => 'Cycles';

  @override
  String get commFactFrequency => 'How often';

  @override
  String get commMonthly => 'Monthly';

  @override
  String get commFactFirstDue => 'First cycle due';

  @override
  String get commFactPool => 'Pool a cycle';

  @override
  String get commFactExpected => 'Over the committee';

  @override
  String get commFactRole => 'Your part';

  @override
  String get commFactCancelledOn => 'Cancelled on';

  @override
  String get commUnpaidAtCancelTotal => 'Unpaid at cancellation';

  @override
  String get commRoleMember => 'A member';

  @override
  String get commRoleOrganiser => 'The organiser';

  @override
  String get commRoleBoth => 'Organiser and member';

  @override
  String get commRoleHelp =>
      'Lume keeps your own record of this committee. It holds no money and moves none.';

  @override
  String get commPaid => 'Paid';

  @override
  String get commDueToday => 'Due today';

  @override
  String get commLate => 'Late';

  @override
  String get commUpcoming => 'Upcoming';

  @override
  String get commUnpaidAtCancel => 'Unpaid at cancellation';

  @override
  String get commNotDue => 'Not due';

  @override
  String get commDayUnknown => 'Not known';

  @override
  String get commDayUnknownText =>
      'Lume cannot work out your day, so it does not say what is late or due. The dates themselves are shown as they are.';

  @override
  String get commPayoutRecorded => 'Payout recorded';

  @override
  String get commPayoutReady => 'Ready to pay out';

  @override
  String get commPayoutWaiting => 'Waiting on contributions';

  @override
  String get commRecordContribution => 'Record contribution';

  @override
  String get commRecordPayout => 'Record payout';

  @override
  String get commEdit => 'Edit';

  @override
  String get commCancelCommittee => 'Cancel committee';

  @override
  String get commKeepCommittee => 'Keep it running';

  @override
  String get commReinstate => 'Reinstate';

  @override
  String get commDeleteCommittee => 'Delete committee';

  @override
  String get commPayTitle => 'Record contribution';

  @override
  String commPayText(String name, String amount, String n, String due) {
    return '$name pays $amount for cycle $n, due $due.';
  }

  @override
  String commPayShares(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n shares, recorded together',
      one: 'One share',
    );
    return '$_temp0';
  }

  @override
  String get commPaidOnLabel => 'Day it was paid';

  @override
  String get commPayGo => 'Record';

  @override
  String get commPayoutTitle => 'Record payout';

  @override
  String commPayoutText(String name, String amount, String n) {
    return '$name receives $amount for cycle $n. Lume records it; it moves no money.';
  }

  @override
  String get commPaidToast => 'Contribution recorded';

  @override
  String get commPayoutToast => 'Payout recorded';

  @override
  String get commVoidContribution => 'Void this contribution';

  @override
  String get commRestoreContribution => 'Restore this contribution';

  @override
  String get commVoidPayout => 'Void this payout';

  @override
  String get commRestorePayout => 'Restore this payout';

  @override
  String get commVoided => 'Voided';

  @override
  String get commVoidedToast => 'Taken out of the figures';

  @override
  String get commRestoredToast => 'Put back';

  @override
  String get commCancelTitle => 'Cancel this committee?';

  @override
  String get commCancelText =>
      'Every record is kept. Cycles after today raise nothing; what was already owed stays as unpaid at cancellation. No refund is worked out, and nothing is paid back.';

  @override
  String get commCancelledToast => 'Committee cancelled';

  @override
  String get commReinstatedToast => 'Committee reinstated';

  @override
  String get commDeleteTitle => 'Delete this committee?';

  @override
  String commDeleteText(
    String members,
    String shares,
    String cycles,
    String contributions,
    String payouts,
  ) {
    return 'This removes the committee, $members, $shares, $cycles, $contributions and $payouts.';
  }

  @override
  String get commDeletedToast => 'Committee deleted';

  @override
  String get commRestoredCommitteeToast => 'Committee restored';

  @override
  String get commNeedsAttention => 'Needs attention';

  @override
  String commDefects(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other:
          '$n records can\'t be read. They are kept as they are, and their committees are left out of the totals.',
      one:
          '1 record can\'t be read. It is kept as it is, and its committee is left out of the totals.',
    );
    return '$_temp0';
  }

  @override
  String get commDamagedText =>
      'Some of this committee\'s records do not hold together, so its figures are left out. You can look at it and delete it; nothing else will write over it.';

  @override
  String get commNewCommittee => 'New committee';

  @override
  String get commEditCommittee => 'Edit committee';

  @override
  String get commFieldName => 'Name';

  @override
  String get commFieldNote => 'Note';

  @override
  String get commFieldCurrency => 'Currency';

  @override
  String get commFieldContribution => 'Contribution a cycle';

  @override
  String get commFieldFirstDue => 'First cycle due';

  @override
  String get commFieldRole => 'Your part';

  @override
  String get commFieldMembers => 'Members and turns';

  @override
  String get commMembersHelp =>
      'They are paid in this order: the first receives cycle 1. A member with two shares pays twice a cycle and is paid twice.';

  @override
  String commMemberName(String n) {
    return 'Member $n';
  }

  @override
  String get commAddMember => 'Add a member';

  @override
  String get commRemoveMember => 'Remove';

  @override
  String get commMoveUp => 'Move up';

  @override
  String get commMoveDown => 'Move down';

  @override
  String get commFieldShares => 'Shares';

  @override
  String get commThisIsYou => 'This is you';

  @override
  String get commLockedTitle => 'The terms are fixed';

  @override
  String get commLockedText =>
      'A contribution or a payout has been recorded, so the amount, the currency, the shares, the first day and the order stay as they are. The names and the note can still be changed.';

  @override
  String get commSaved => 'Committee saved';

  @override
  String get commErrName => 'Give the committee a name';

  @override
  String get commErrMemberName => 'Give every member a name';

  @override
  String get commErrLong => 'That is too long';

  @override
  String get commErrDate => 'Choose a date';

  @override
  String get commErrMembers => 'A committee needs at least two shares';

  @override
  String get commErrShares => 'Shares must be a whole number of at least one';

  @override
  String get commErrReader =>
      'Mark exactly one member as you, or say you are the organiser only';

  @override
  String get commErrReaderNone =>
      'An organiser who holds no share has no member to mark';

  @override
  String get commErrRange => 'That is outside what this can hold';

  @override
  String get commErrTooLarge => 'That figure is too large to work with';

  @override
  String commErrWithdrawn(String code) {
    return '$code is no longer in use for a new committee';
  }

  @override
  String get commErrFuture => 'A payment cannot be dated after today';

  @override
  String get commErrDuplicate => 'That is already recorded';

  @override
  String commErrIncomplete(String n, String amount) {
    return 'Cycle $n is still short $amount. A payout is recorded once it is fully collected.';
  }

  @override
  String get commErrPaidOut => 'Void this cycle\'s payout first';

  @override
  String get commErrCancelled => 'This committee is cancelled';

  @override
  String get commErrConflict =>
      'It changed while you were working. Open it again.';

  @override
  String get commErrDamaged => 'This committee\'s records do not hold together';

  @override
  String get commErrFailed => 'That could not be saved. Nothing was changed.';

  @override
  String get commExportTitle => 'Export committees';

  @override
  String get commExportJson => 'Backup file (JSON)';

  @override
  String get commExportJsonHelp => 'Everything, and it can be imported again.';

  @override
  String get commExportCsv => 'Spreadsheet (CSV)';

  @override
  String get commExportCsvHelp =>
      'One row per share per cycle. It cannot be imported.';

  @override
  String get commExportNames => 'Include names';

  @override
  String get commExportNamesHelp =>
      'Off, the file says Committee 1 and Member 2, and leaves notes out. On, it carries the names of everyone in your committees.';

  @override
  String get commExportGo => 'Export';

  @override
  String get commImport => 'Import a backup';

  @override
  String get commImportText => 'Paste a Lume committee backup file';

  @override
  String get commImportCheck => 'Check it';

  @override
  String commImportReady(String c, String u, String s) {
    return 'Ready: $c to add, $u to update, $s already here. Nothing is written until you import.';
  }

  @override
  String commImportIssues(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n problems. Nothing will be imported.',
      one: '1 problem. Nothing will be imported.',
    );
    return '$_temp0';
  }

  @override
  String get commImportNoNames =>
      'No names in this backup: members will be called Member 1, Member 2…';

  @override
  String get commImportAction => 'Import';

  @override
  String commImported(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Imported $n records',
      one: 'Imported 1 record',
    );
    return '$_temp0';
  }

  @override
  String get commMemberPaidLabel => 'Paid in';

  @override
  String get commMemberExpected => 'Owed over the committee';

  @override
  String get commTheirCycles => 'Their cycles';

  @override
  String commCountMembers(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String commCountShares(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n shares',
      one: '1 share',
    );
    return '$_temp0';
  }

  @override
  String commCountCycles(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cycles',
      one: '1 cycle',
    );
    return '$_temp0';
  }

  @override
  String commCountContributions(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n contributions',
      one: '1 contribution',
      zero: 'no contributions',
    );
    return '$_temp0';
  }

  @override
  String commCountPayouts(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n payouts',
      one: '1 payout',
      zero: 'no payouts',
    );
    return '$_temp0';
  }

  @override
  String get babyBudgets => 'Budgets';

  @override
  String get babyAdd => 'New budget';

  @override
  String get babyEmptyTitle => 'No budgets yet';

  @override
  String get babyEmptyText =>
      'Start a budget to see what a month costs, where it goes and what is coming up. Everything stays on this device.';

  @override
  String get babySearch => 'Search budgets and categories';

  @override
  String get babyNoMatch => 'Nothing matches';

  @override
  String get babyNoMatchText => 'Try another word, or show every budget.';

  @override
  String get babyShowAll => 'Show all';

  @override
  String get babyFilterLabel => 'Filter budgets';

  @override
  String get babyFilterInUse => 'In use';

  @override
  String get babyFilterNotStarted => 'Not started';

  @override
  String get babyFilterArchived => 'Archived';

  @override
  String get babySortName => 'Name';

  @override
  String get babySortSpend => 'This month';

  @override
  String get babySortRecent => 'Recent';

  @override
  String get babyNeedsAttention => 'Needs attention';

  @override
  String babyDefects(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n records could not be read. Nothing was changed.',
      one: '1 record could not be read. Nothing was changed.',
    );
    return '$_temp0';
  }

  @override
  String get babyDamagedText =>
      'Part of this budget could not be read, so its figures are left out. You can still delete it.';

  @override
  String get babyNotFound => 'That budget is no longer here.';

  @override
  String babySummaryCurrency(String code) {
    return 'In $code';
  }

  @override
  String get babyThisMonth => 'This month';

  @override
  String get babySpentToDate => 'Spent to date';

  @override
  String get babyPlannedTotal => 'Planned';

  @override
  String babyBudgetCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n budgets',
      one: '1 budget',
    );
    return '$_temp0';
  }

  @override
  String get babyPlanLabel => 'Plan';

  @override
  String babyOfPlan(String percent) {
    return '$percent of plan';
  }

  @override
  String babyOverBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String get babyNoPlan => 'No plan set';

  @override
  String get babyNotStartedTitle => 'Not started yet';

  @override
  String babyNotStartedText(String date) {
    return 'This budget starts on $date. Nothing is counted before then.';
  }

  @override
  String babyArchivedOn(String date) {
    return 'Archived on $date';
  }

  @override
  String babyStartedOn(String date) {
    return 'Started on $date';
  }

  @override
  String babyUnallocated(String amount) {
    return '$amount unallocated';
  }

  @override
  String get babyWhereItGoes => 'Where it goes';

  @override
  String get babyAMonth => 'a month';

  @override
  String get babyDonutLabel => 'Where this month’s spending goes';

  @override
  String get babySixMonths => 'Six months';

  @override
  String babySixMonthsCap(String code) {
    return 'Monthly spending in $code, without planned purchases';
  }

  @override
  String babyChartEntry(String month, String amount) {
    return '$month: $amount';
  }

  @override
  String get babyComingUp => 'Coming up';

  @override
  String get babyOneOff => 'One-off purchases';

  @override
  String get babyNothingPlanned => 'Nothing planned.';

  @override
  String get babyNothingThisMonth => 'Nothing recorded this month.';

  @override
  String get babyUncategorised => 'Uncategorised';

  @override
  String get babyCategories => 'Categories';

  @override
  String get babyNoCategories =>
      'No categories yet. Spends without one are counted together.';

  @override
  String get babyMonthSpending => 'Spending';

  @override
  String get babyEveryMonth => 'Every month';

  @override
  String get babyMonthLabel => 'Month';

  @override
  String get babyCategorySpending => 'In this category';

  @override
  String babyShareOfMonth(String percent) {
    return '$percent of this month';
  }

  @override
  String get babyCategoryPlan => 'Category plan';

  @override
  String babySpendCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n spends',
      one: '1 spend',
      zero: 'nothing recorded',
    );
    return '$_temp0';
  }

  @override
  String get babyOverdue => 'Overdue';

  @override
  String get babyExpected => 'Expected';

  @override
  String get babyUndated => 'No date';

  @override
  String get babyPlannedBadge => 'Planned';

  @override
  String get babyVoidedBadge => 'Voided';

  @override
  String get babyDayUnknown => 'Day unknown';

  @override
  String get babyDayUnknownText =>
      'Your time zone could not be worked out, so nothing is called overdue and no month is shown.';

  @override
  String babyExpectedOn(String date) {
    return 'Expected $date';
  }

  @override
  String babySpentOn(String date) {
    return 'Spent $date';
  }

  @override
  String get babyRecordSpend => 'Record a spend';

  @override
  String get babyPlanPurchase => 'Plan a purchase';

  @override
  String get babyMarkBought => 'Mark as bought';

  @override
  String get babyMarkPlanned => 'Move back to planned';

  @override
  String get babyEditBudget => 'Edit budget';

  @override
  String get babyEditSpend => 'Edit';

  @override
  String get babyArchive => 'Archive';

  @override
  String get babyUnarchive => 'Bring back';

  @override
  String get babyDeleteBudget => 'Delete budget';

  @override
  String get babyAddCategory => 'Add category';

  @override
  String get babyEditCategoryTitle => 'Edit category';

  @override
  String get babyDeleteCategory => 'Delete category';

  @override
  String get babyVoidSpend => 'Void';

  @override
  String get babyRestoreSpend => 'Restore';

  @override
  String get babyOpenCategory => 'Open category';

  @override
  String get babyNewBudget => 'New budget';

  @override
  String get babyEditBudgetTitle => 'Edit budget';

  @override
  String get babyFieldName => 'Name';

  @override
  String get babyNameHint =>
      'Whatever you call it. Nothing here has to name a child.';

  @override
  String get babyFieldCurrency => 'Currency';

  @override
  String get babyFieldPlan => 'Monthly plan';

  @override
  String get babyPlanHint =>
      'Leave it empty for no plan. Without one there is no percentage.';

  @override
  String get babyFieldStartedOn => 'Started on';

  @override
  String get babyStartHint => 'Nothing may be recorded before this day.';

  @override
  String get babyFieldNote => 'Note';

  @override
  String get babyFieldCategories => 'Categories';

  @override
  String get babyCategoriesHint =>
      'Name the things you spend on. Anything without a category is counted on its own.';

  @override
  String babyCategoryName(String n) {
    return 'Category $n';
  }

  @override
  String get babyRemoveCategory => 'Remove';

  @override
  String get babyMoveUp => 'Move up';

  @override
  String get babyMoveDown => 'Move down';

  @override
  String get babyFieldColour => 'Colour';

  @override
  String babyColourName(String n) {
    return 'Colour $n';
  }

  @override
  String get babyFieldAmount => 'Amount';

  @override
  String get babyFieldCategory => 'Category';

  @override
  String get babyFieldLabel => 'What it is';

  @override
  String get babyFieldDay => 'Day';

  @override
  String get babyFieldExpected => 'Expected on';

  @override
  String get babyNoDate => 'No date';

  @override
  String get babyClearDate => 'Clear the date';

  @override
  String get babyLockedTitle => 'The currency is fixed';

  @override
  String babyLockedText(String code) {
    return 'This budget already has records in $code. To use another currency, archive it and start a new one.';
  }

  @override
  String get babySpendTitle => 'Record a spend';

  @override
  String get babyPlanTitle => 'Plan a purchase';

  @override
  String get babyEditSpendTitle => 'Edit spend';

  @override
  String get babyEditPlanTitle => 'Edit planned purchase';

  @override
  String get babyActualAmount => 'What it actually cost';

  @override
  String get babyBoughtTitle => 'Mark as bought';

  @override
  String babyBoughtText(String label, String amount) {
    return '$label was planned at $amount. Record it as spent, and change the amount if it cost something else.';
  }

  @override
  String get babyBoughtGo => 'Record it';

  @override
  String get babyPlannedAgainTitle => 'Move back to planned';

  @override
  String babyPlannedAgainText(String amount) {
    return 'This takes $amount out of the month’s figures and puts it back on the planned list. The record itself is kept.';
  }

  @override
  String get babyPlannedAgainGo => 'Move it back';

  @override
  String get babyArchiveTitle => 'Archive this budget?';

  @override
  String get babyArchiveText =>
      'Every record is kept and every figure stays. Nothing new can be added until you bring it back.';

  @override
  String get babyArchiveGo => 'Archive it';

  @override
  String get babyKeepBudget => 'Keep it open';

  @override
  String get babyDeleteTitle => 'Delete this budget?';

  @override
  String babyDeleteText(String categories, String spends, String planned) {
    return 'This removes the budget, $categories, $spends and $planned.';
  }

  @override
  String babyCountCategories(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n categories',
      one: '1 category',
      zero: 'no categories',
    );
    return '$_temp0';
  }

  @override
  String babyCountSpends(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n spends',
      one: '1 spend',
      zero: 'no spends',
    );
    return '$_temp0';
  }

  @override
  String babyCountPlanned(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n planned purchases',
      one: '1 planned purchase',
      zero: 'no planned purchases',
    );
    return '$_temp0';
  }

  @override
  String get babyDeleteCategoryTitle => 'Delete this category?';

  @override
  String babyDeleteCategoryText(String spends) {
    return 'Its $spends are kept. Choose where they should go.';
  }

  @override
  String get babyMoveToNone => 'Leave them uncategorised';

  @override
  String babyMoveTo(String name) {
    return 'Move them to $name';
  }

  @override
  String get babySaved => 'Budget saved.';

  @override
  String get babySpendSaved => 'Spend recorded.';

  @override
  String get babyPlanSaved => 'Purchase planned.';

  @override
  String get babyBoughtToast => 'Recorded as bought.';

  @override
  String get babyPlannedAgainToast => 'Moved back to planned.';

  @override
  String get babyVoidedToast => 'Spend voided.';

  @override
  String get babyRestoredToast => 'Spend restored.';

  @override
  String get babyCategorySaved => 'Category saved.';

  @override
  String get babyCategoryDeletedToast => 'Category deleted.';

  @override
  String get babyArchivedToast => 'Budget archived.';

  @override
  String get babyUnarchivedToast => 'Budget brought back.';

  @override
  String get babyDeletedToast => 'Budget deleted.';

  @override
  String get babyRestoredBudgetToast => 'Budget restored.';

  @override
  String get babyErrName => 'Give the budget a name.';

  @override
  String get babyErrCategoryName => 'Give every category a name.';

  @override
  String get babyErrLong => 'That is too long.';

  @override
  String get babyErrAmount => 'Enter an amount above zero.';

  @override
  String get babyErrDate => 'Choose a date.';

  @override
  String get babyErrFuture => 'A spend cannot be dated after today.';

  @override
  String get babyErrArchivedFuture =>
      'A budget cannot be archived on a day that has not arrived.';

  @override
  String babyErrBeforeStart(String date) {
    return 'This budget starts on $date. Nothing can be recorded before then.';
  }

  @override
  String babyErrStartAfter(String label, String date) {
    return '$label is dated $date. Move or remove it before changing the start.';
  }

  @override
  String get babyErrZeroPlan =>
      'A plan has to be above zero. Leave it empty for no plan.';

  @override
  String get babyErrNoBudgetPlan =>
      'Set a monthly plan for the budget before giving a category one.';

  @override
  String get babyErrOverPlan =>
      'The category plans add up to more than the budget’s plan.';

  @override
  String get babyErrBelowCategories =>
      'That is less than the categories already hold. Lower them first.';

  @override
  String babyErrCategoryLimit(String n) {
    return 'A budget can hold $n categories.';
  }

  @override
  String get babyErrDuplicate => 'There is already a category with that name.';

  @override
  String get babyErrArchived =>
      'This budget is archived. Bring it back to change anything.';

  @override
  String get babyErrConflict => 'This changed somewhere else. Open it again.';

  @override
  String get babyErrDamaged =>
      'Part of this budget could not be read, so nothing was changed.';

  @override
  String get babyErrTooLarge => 'That number is too large to store.';

  @override
  String get babyErrFailed => 'That could not be saved.';

  @override
  String get babyExportTitle => 'Export this budget';

  @override
  String get babyExportText =>
      'A file saved to this device. Names and notes are left out unless you keep them.';

  @override
  String get babyExportJson => 'Full backup (JSON)';

  @override
  String get babyExportJsonText =>
      'Everything, so it can be brought back into Lume.';

  @override
  String get babyExportCsv => 'Spreadsheet (CSV)';

  @override
  String get babyExportCsvText =>
      'One row per spend. It cannot be brought back in.';

  @override
  String get babyKeepNames => 'Keep names and notes';

  @override
  String get babyKeepNamesText =>
      'Off, the budget is called Budget 1 and categories Category 1, Category 2 and so on.';

  @override
  String get babyImport => 'Import a backup';

  @override
  String get babyImportText =>
      'Choose a Lume budget file. Nothing already here is touched, and nothing is written unless the whole file reads cleanly.';

  @override
  String get babyImportNoNames =>
      'This backup has no names: budgets will be called Budget 1, Budget 2 and so on.';

  @override
  String get babyImportAction => 'Import';

  @override
  String babyImported(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n records imported',
      one: '1 record imported',
    );
    return '$_temp0';
  }

  @override
  String get babyExportGo => 'Export';

  @override
  String get babyImportCheck => 'Check it';

  @override
  String babyImportReady(String c, String u, String s) {
    return 'Ready: $c to add, $u to update, $s already here. Nothing is written until you import.';
  }

  @override
  String babyImportIssues(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n problems. Nothing will be imported.',
      one: '1 problem. Nothing will be imported.',
    );
    return '$_temp0';
  }

  @override
  String get clockYourTime => 'Your time';

  @override
  String get clockYourZone => 'Your time zone';

  @override
  String get clockCities => 'Clocks';

  @override
  String get clockAdd => 'Add a place';

  @override
  String get clockAddTitle => 'Add a place';

  @override
  String get clockSearch => 'Search cities and time zones';

  @override
  String get clockNoMatch => 'Nothing matches';

  @override
  String get clockNoMatchText => 'Try a city, a country or a time zone name.';

  @override
  String get clockShowAll => 'Show all';

  @override
  String get clockEmptyTitle => 'No places yet';

  @override
  String get clockEmptyText =>
      'Add a city to see its time beside yours. Your own time is always here.';

  @override
  String clockCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String get clockSameTime => 'Same time';

  @override
  String clockAhead(String offset) {
    return '$offset ahead';
  }

  @override
  String clockBehind(String offset) {
    return '$offset behind';
  }

  @override
  String get clockYesterday => 'Yesterday';

  @override
  String get clockToday => 'Today';

  @override
  String get clockTomorrow => 'Tomorrow';

  @override
  String get clockSummerTime => 'Summer time';

  @override
  String clockRowSemantics(
    String place,
    String time,
    String day,
    String offset,
  ) {
    return '$place, $time, $day, $offset';
  }

  @override
  String get clockConvert => 'Convert a time';

  @override
  String get clockConvertFrom => 'From';

  @override
  String get clockConvertTo => 'To';

  @override
  String get clockConvertAt => 'At';

  @override
  String clockConvertResult(String time, String day) {
    return '$time on $day';
  }

  @override
  String get clockConvertSame => 'Pick two different places';

  @override
  String get clockRemove => 'Remove';

  @override
  String get clockMoveUp => 'Move up';

  @override
  String get clockMoveDown => 'Move down';

  @override
  String clockAdded(String place) {
    return '$place added';
  }

  @override
  String clockRemovedToast(String place) {
    return '$place removed';
  }

  @override
  String clockAlready(String place) {
    return '$place is already on the list';
  }

  @override
  String get clockZoneUnknownTitle => 'That time zone is not known';

  @override
  String clockZoneUnknownText(String id) {
    return 'Lume could not find “$id” in the time-zone database it carries. Nothing has been guessed in its place.';
  }

  @override
  String get clockDatabaseTitle => 'The time-zone database is unavailable';

  @override
  String get clockDatabaseText =>
      'Without it no time anywhere can be worked out, and none is shown.';

  @override
  String get clockDeviceTitle => 'This device has not said where it is';

  @override
  String get clockDeviceText =>
      'Choose your time zone in Settings, and your own clock will appear here.';

  @override
  String get clockChooseTitle => 'Your country has more than one time zone';

  @override
  String get clockChooseText =>
      'Choose the one you are in, and your own clock will appear here.';

  @override
  String clockAliasNote(String stored, String canonical) {
    return '$stored is now called $canonical';
  }

  @override
  String clockDatabaseVersion(String version) {
    return 'IANA time-zone database $version';
  }

  @override
  String get calcKeypad => 'Calculator keypad';

  @override
  String get calcDisplay => 'Result';

  @override
  String get calcExpression => 'Expression';

  @override
  String get calcHistory => 'History';

  @override
  String get calcNoHistory => 'Nothing worked out yet.';

  @override
  String get calcClear => 'Clear';

  @override
  String get calcClearEntry => 'Clear entry';

  @override
  String get calcBackspace => 'Backspace';

  @override
  String get calcEquals => 'Equals';

  @override
  String get calcPlus => 'Plus';

  @override
  String get calcMinus => 'Minus';

  @override
  String get calcTimes => 'Times';

  @override
  String get calcDivide => 'Divided by';

  @override
  String get calcPercent => 'Per cent';

  @override
  String get calcDecimal => 'Decimal point';

  @override
  String get calcSign => 'Change sign';

  @override
  String calcDigit(String n) {
    return 'Digit $n';
  }

  @override
  String get calcErrDivZero => 'Nothing can be divided by zero';

  @override
  String get calcErrTooLong => 'That is as many digits as this can hold';

  @override
  String get calcErrOverflow => 'That number is too large to work with';

  @override
  String get calcErrPrecision => 'That division does not end';

  @override
  String calcHistoryRow(String expression, String result) {
    return '$expression = $result';
  }

  @override
  String get calcCleared => 'Cleared';

  @override
  String calcPrecisionNote(String places) {
    return 'Worked out exactly, to $places decimal places.';
  }

  @override
  String get focusFocus => 'Focus';

  @override
  String get focusBreak => 'Break';

  @override
  String get focusStart => 'Start focus';

  @override
  String get focusPause => 'Pause';

  @override
  String get focusResume => 'Resume';

  @override
  String get focusReset => 'Reset';

  @override
  String get focusSkip => 'Skip';

  @override
  String get focusDone => 'Focus finished';

  @override
  String get focusBreakOver => 'Break over';

  @override
  String focusSession(String n, String of) {
    return 'Session $n of $of';
  }

  @override
  String get focusRunning => 'Running';

  @override
  String get focusPaused => 'Paused';

  @override
  String get focusReady => 'Ready';

  @override
  String get focusLength => 'Focus length';

  @override
  String get focusBreakLength => 'Break length';

  @override
  String get focusToday => 'Minutes today';

  @override
  String get focusStreakLabel => 'Day streak';

  @override
  String get focusSessionsLabel => 'Sessions';

  @override
  String get focusThisWeek => 'This week';

  @override
  String focusChartEntry(String day, String minutes) {
    return '$day: $minutes';
  }

  @override
  String get focusThisSession => 'This session';

  @override
  String get focusNothingYet =>
      'Nothing yet — start a session and it will count here.';

  @override
  String get focusKeptSession =>
      'Counted since you opened Lume. Nothing here survives closing it.';

  @override
  String get tasbihCounter => 'Counter';

  @override
  String get tasbihTap => 'Tap to count';

  @override
  String tasbihOf(String count, String target) {
    return '$count of $target';
  }

  @override
  String tasbihSets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n rounds',
      one: '1 round',
      zero: 'No rounds',
    );
    return '$_temp0';
  }

  @override
  String get tasbihReset => 'Reset';

  @override
  String get tasbihResetAsk => 'Reset the counter?';

  @override
  String get tasbihResetText =>
      'The count and the rounds go back to zero. Nothing is kept.';

  @override
  String get tasbihResetGo => 'Reset it';

  @override
  String get tasbihKeepCount => 'Keep counting';

  @override
  String get tasbihComplete => 'Round complete';

  @override
  String get tasbihPhrase => 'Phrase';

  @override
  String get tasbihPickTitle => 'Choose a phrase';

  @override
  String get tasbihSwitchAsk => 'Change the phrase?';

  @override
  String get tasbihSwitchText =>
      'The count goes back to zero. The rounds you have finished are kept.';

  @override
  String get tasbihSwitchGo => 'Change it';

  @override
  String get tasbihMax => 'That is as high as the counter goes';

  @override
  String get tasbihNotKept =>
      'The count is here while Lume is open. Nothing is written down.';

  @override
  String tasbihTargetLabel(String n) {
    return 'Round of $n';
  }

  @override
  String get tasbihMeaning => 'Meaning';

  @override
  String get playGames => 'Games';

  @override
  String get playKind => 'Kind';

  @override
  String get playKindPuzzle => 'Puzzle';

  @override
  String get playKindWord => 'Word';

  @override
  String get playKindMemory => 'Memory';

  @override
  String get playKindArithmetic => 'Arithmetic';

  @override
  String get playGameNumberGrid => 'Number Grid';

  @override
  String get playGameWordChain => 'Word Chain';

  @override
  String get playGameMemoryMatch => 'Memory Match';

  @override
  String get playGameQuickMaths => 'Quick Maths';

  @override
  String get playNotYet => 'Not playable yet';

  @override
  String get playNotYetText =>
      'None of these can be played yet, and nothing here is a score of yours.';

  @override
  String playCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n games',
      one: '1 game',
    );
    return '$_temp0';
  }

  @override
  String get ucLength => 'Length';

  @override
  String get ucMass => 'Weight';

  @override
  String get ucVolume => 'Volume';

  @override
  String get ucArea => 'Area';

  @override
  String get ucSpeed => 'Speed';

  @override
  String get ucData => 'Data';

  @override
  String get ucMetre => 'Metre';

  @override
  String get ucKilometre => 'Kilometre';

  @override
  String get ucCentimetre => 'Centimetre';

  @override
  String get ucMile => 'Mile';

  @override
  String get ucFoot => 'Foot';

  @override
  String get ucInch => 'Inch';

  @override
  String get ucKilogram => 'Kilogram';

  @override
  String get ucGram => 'Gram';

  @override
  String get ucPound => 'Pound';

  @override
  String get ucOunce => 'Ounce';

  @override
  String get ucTola => 'Tola';

  @override
  String get ucLitre => 'Litre';

  @override
  String get ucMillilitre => 'Millilitre';

  @override
  String get ucGallonUs => 'Gallon (US)';

  @override
  String get ucGallonImp => 'Gallon (imperial)';

  @override
  String get ucCupUs => 'Cup (US)';

  @override
  String get ucSqmetre => 'Square metre';

  @override
  String get ucSqfoot => 'Square foot';

  @override
  String get ucAcre => 'Acre';

  @override
  String get ucMarla => 'Marla';

  @override
  String get ucKmh => 'Kilometres per hour';

  @override
  String get ucMph => 'Miles per hour';

  @override
  String get ucMs => 'Metres per second';

  @override
  String get ucByte => 'Byte';

  @override
  String get ucKilobyte => 'Kilobyte';

  @override
  String get ucMegabyte => 'Megabyte';

  @override
  String get ucGigabyte => 'Gigabyte';

  @override
  String get ucTerabyte => 'Terabyte';

  @override
  String get ucKibibyte => 'Kibibyte';

  @override
  String get ucMebibyte => 'Mebibyte';

  @override
  String get ucGibibyte => 'Gibibyte';

  @override
  String get ucTebibyte => 'Tebibyte';

  @override
  String get convertSwap => 'Swap';

  @override
  String get convertAllUnits => 'All units';

  @override
  String get convertAmount => 'Amount';

  @override
  String get convertFrom => 'From';

  @override
  String get convertTo => 'To';

  @override
  String get convertChooseUnit => 'Choose a unit';

  @override
  String get convertCategory => 'What to convert';

  @override
  String convertEquals(String from, String to) {
    return '$from is $to';
  }

  @override
  String get convertDataNote =>
      'kB, MB, GB and TB are powers of 1,000. KiB, MiB, GiB and TiB are powers of 1,024.';

  @override
  String get birthdaysNext => 'Next up';

  @override
  String get birthdaysTracked => 'Tracked';

  @override
  String get birthdaysThisMonth => 'This month';

  @override
  String get birthdaysTurning => 'Turning';

  @override
  String birthdaysTurns(int n) {
    return 'turns $n';
  }

  @override
  String birthdaysYears(int n) {
    return '$n years';
  }

  @override
  String get birthdaysUpcoming => 'Coming up';

  @override
  String get birthdaysBirthday => 'Birthday';

  @override
  String get birthdaysAnniversary => 'Anniversary';

  @override
  String get birthdaysAdd => 'Add a date';

  @override
  String get birthdaysNothingTitle => 'Nothing coming up';

  @override
  String get birthdaysNothingText =>
      'Dates you add appear here, soonest first.';

  @override
  String get recBirthdaysNoun => 'date';

  @override
  String get recBirthdaysNounPlural => 'birthdays & anniversaries';

  @override
  String get recBirthdaysEmptyTitle => 'No dates saved';

  @override
  String get recBirthdaysEmptyText =>
      'Add a birthday and it is counted down here.';

  @override
  String get recBirthdaysPh => 'Whose day is it?';

  @override
  String get recFieldOccasion => 'Occasion';

  @override
  String get recNextOne => 'Next one';

  @override
  String get recTurning => 'Turning';

  @override
  String get recSeedOurAnniversary => 'Our anniversary';

  @override
  String get waterToday => 'Today';

  @override
  String waterOfTarget(String target) {
    return 'of a $target goal';
  }

  @override
  String waterOfDefault(String target) {
    return 'of the default $target goal';
  }

  @override
  String get waterProgress => 'Progress';

  @override
  String get waterRemaining => 'Remaining';

  @override
  String get waterGlasses => 'Glasses';

  @override
  String get waterLogged => 'Logged';

  @override
  String get waterTimeline => 'Today’s intake';

  @override
  String get waterKindWater => 'Water';

  @override
  String get waterKindTea => 'Tea';

  @override
  String waterAdded(String amount) {
    return '$amount logged';
  }

  @override
  String get waterGoal => 'Daily goal';

  @override
  String get waterGoalDefault => 'Default goal';

  @override
  String get waterSetGoal => 'Change goal';

  @override
  String get waterGoalHint => 'A goal to fill, not a health recommendation.';

  @override
  String get waterGoalMl => 'Goal in ml';

  @override
  String get waterNothingTitle => 'Nothing logged today';

  @override
  String get waterNothingText =>
      'Log a glass and today’s total starts filling.';

  @override
  String waterAddSmall(String amount) {
    return 'Add $amount';
  }

  @override
  String get recWaterNoun => 'drink';

  @override
  String get recWaterNounPlural => 'drinks';

  @override
  String get recWaterEmptyTitle => 'Nothing logged yet';

  @override
  String get recWaterEmptyText =>
      'Log a glass and your daily total starts filling.';

  @override
  String get recFieldAmountMl => 'Amount in ml';

  @override
  String get recFieldDrink => 'Drink';
}

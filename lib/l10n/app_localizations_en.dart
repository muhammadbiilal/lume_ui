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
  String get a11yMainNavigation => 'Main';

  @override
  String get a11ySearch => 'Search this tool';

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
  String get acctDeviceBrowser => 'This browser';

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
  String get acctPushDenied => 'Blocked in your browser settings';

  @override
  String get acctPushDeniedHelp =>
      'Notifications are blocked. Allow them in your browser’s site settings.';

  @override
  String get acctPushGranted => 'Allowed by your browser';

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
  String get acctTimezoneFollowRegion => 'Follow my region';

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
  String get commonShare => 'Share';

  @override
  String get commonSort => 'Sort';

  @override
  String get commonStale => 'Not current';

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
  String cricketScore(String team, int runs, int wickets) {
    return '$team $runs/$wickets';
  }

  @override
  String cricketSecondTest(int n) {
    return '2nd Test · Day $n';
  }

  @override
  String get discoverDuasMeta => 'For ordinary days';

  @override
  String get discoverDuasTitle => 'Forty duas';

  @override
  String docsRenewSoon(String name) {
    return 'Renew your $name';
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
  String get heroHighlights => 'Highlights';

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
  String get loadshedOff => 'Power is off';

  @override
  String loadshedUntil(String time) {
    return 'until $time';
  }

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
  String get newsCatBusiness => 'Business';

  @override
  String get newsCatKarachi => 'Karachi';

  @override
  String get newsCatMoney => 'Money';

  @override
  String get newsCatProductivity => 'Productivity';

  @override
  String get newsCatSport => 'Sport';

  @override
  String get newsCatWellbeing => 'Wellbeing';

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
  String get newsSavings => 'A plain-English guide to your first savings goal';

  @override
  String get newsShortList => 'Why a shorter to-do list finishes more work';

  @override
  String get newsSquad => 'Pakistan name squad for the home Test series';

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
  String get notifPrefGeneral => 'General';

  @override
  String get notifPrefHaptics => 'Vibration';

  @override
  String get notifPrefInApp => 'In-app notifications';

  @override
  String get notifPrefInAppSub => 'Banners and the notification centre';

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
  String get recordsNoSelectionText => 'Choose a record to see it here.';

  @override
  String get recordsNoSelectionTitle => 'Nothing selected';

  @override
  String get routeMissingText =>
      'The link may be old, or the page may have moved.';

  @override
  String get routeMissingTitle => 'We can’t find that';

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
  String get searchJumpBack => 'Jump back in';

  @override
  String get searchNothing => 'Nothing found';

  @override
  String get searchPlaceholder => 'Search anything — tools, rates, places';

  @override
  String get searchTry => 'Try searching for';

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
  String subsRenews(String date) {
    return 'renews $date';
  }

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
  String get toolErrorText => 'We couldn’t load this. Try again in a moment.';

  @override
  String get toolErrorTitle => 'Something went wrong';

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
  String get toolPrivateText =>
      'This information stays on your device, is never shown on Home and is never included in shared content.';

  @override
  String get toolPrivateTitle => 'Private to you';

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
  String get toolStatusBirthdays => 'Ayesha in 4d';

  @override
  String get toolStatusBmi => 'Track weight';

  @override
  String get toolStatusCalculator => 'Standard';

  @override
  String get toolStatusCalendar => '3 events';

  @override
  String get toolStatusCommittee => 'Month 4 of 10';

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
  String get toolStatusGoals => '2 active';

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
  String get toolStatusInstallments => '3 running';

  @override
  String get toolStatusLearning => '3 courses';

  @override
  String get toolStatusLedger => '3 people';

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
  String get toolStatusSubs => '6 active';

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
  String get toolStatusWater => '5 / 8';

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
  String get unitKmh => 'km/h';

  @override
  String get unitMinutes => 'min';

  @override
  String get unitMph => 'mph';

  @override
  String unitOfTotal(int total) {
    return '/$total';
  }

  @override
  String get unitThousand => 'k';

  @override
  String get weatherClear => 'Clear';

  @override
  String get weatherClearVeryWarm => 'Clear · very warm';

  @override
  String get weatherCloudBuilding => 'Cloud building';

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
  String get weatherHumidLightHaze => 'Humid · light haze';

  @override
  String get weatherLightCloud => 'Light cloud';

  @override
  String get weatherMostlyClear => 'Mostly clear';

  @override
  String get weatherOvercast => 'Overcast';

  @override
  String get weatherRain => 'Rain';
}

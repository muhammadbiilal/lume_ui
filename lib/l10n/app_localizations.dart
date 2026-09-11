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

  /// Reference key a11y.back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get a11yBack;

  /// Reference: aria-label="Main" on both navigations
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get a11yMainNavigation;

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

  /// Reference key app.tagline
  ///
  /// In en, this message translates to:
  /// **'Your day, in one place'**
  String get appTagline;

  /// Reference key auth.asideText
  ///
  /// In en, this message translates to:
  /// **'Prayer, weather, money, travel and the small things — wherever you are.'**
  String get authAsideText;

  /// Reference key auth.asideTitle; the desktop aside
  ///
  /// In en, this message translates to:
  /// **'One app for the day ahead.'**
  String get authAsideTitle;

  /// Reference key auth.backToSignIn
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authBackToSignIn;

  /// Reference key auth.continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authContinue;

  /// Reference key auth.continueAsGuest
  ///
  /// In en, this message translates to:
  /// **'Continue as a guest'**
  String get authContinueAsGuest;

  /// Reference key acct.create
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// Reference key auth.createOne
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get authCreateOne;

  /// Reference key auth.createdText
  ///
  /// In en, this message translates to:
  /// **'Your Lume account is ready.'**
  String get authCreatedText;

  /// Reference key auth.createdTextNamed
  ///
  /// In en, this message translates to:
  /// **'Your Lume account is ready, {name}.'**
  String authCreatedTextNamed(String name);

  /// Reference key auth.createdTitle
  ///
  /// In en, this message translates to:
  /// **'You’re all set'**
  String get authCreatedTitle;

  /// Reference key auth.creating
  ///
  /// In en, this message translates to:
  /// **'Creating your account…'**
  String get authCreatingAccount;

  /// Reference key auth.emailPh; a sample address, not a translated phrase
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authEmailPlaceholder;

  /// Reference key auth.enterCta
  ///
  /// In en, this message translates to:
  /// **'Enter Lume'**
  String get authEnterCta;

  /// A verification code past its window; distinct from a wrong one
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Ask for a new one.'**
  String get authErrCodeExpired;

  /// Reference key acct.err.codeWrong
  ///
  /// In en, this message translates to:
  /// **'That code is incorrect.'**
  String get authErrCodeIncorrect;

  /// The verification field was left empty
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent you.'**
  String get authErrCodeRequired;

  /// Reference key acct.err.confirmMismatch
  ///
  /// In en, this message translates to:
  /// **'These passwords don’t match.'**
  String get authErrConfirmMismatch;

  /// Reference key acct.err.confirmRequired
  ///
  /// In en, this message translates to:
  /// **'Confirm your password.'**
  String get authErrConfirmRequired;

  /// Reference key acct.err.credentials; one message for an unknown account and a wrong password alike
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authErrCredentials;

  /// Reference key acct.err.emailInvalid
  ///
  /// In en, this message translates to:
  /// **'That doesn’t look like an email address.'**
  String get authErrEmailInvalid;

  /// Reference key acct.err.emailRequired
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get authErrEmailRequired;

  /// Reference key acct.err.emailSame
  ///
  /// In en, this message translates to:
  /// **'That’s already your email address.'**
  String get authErrEmailSame;

  /// Reference key acct.err.emailTaken
  ///
  /// In en, this message translates to:
  /// **'An account already exists for this email.'**
  String get authErrEmailTaken;

  /// Reference key acct.err.linkExpired
  ///
  /// In en, this message translates to:
  /// **'This reset link has expired. Request a new one.'**
  String get authErrLinkExpired;

  /// Reference key acct.err.linkInvalid
  ///
  /// In en, this message translates to:
  /// **'This reset link is no longer valid.'**
  String get authErrLinkInvalid;

  /// Reference key acct.err.locked
  ///
  /// In en, this message translates to:
  /// **'This account is locked. Reset your password to unlock it.'**
  String get authErrLocked;

  /// Reference key acct.err.network
  ///
  /// In en, this message translates to:
  /// **'Lume couldn’t reach the network. Nothing was lost.'**
  String get authErrNetwork;

  /// Reference key acct.err.nothingPending
  ///
  /// In en, this message translates to:
  /// **'There’s no email change waiting.'**
  String get authErrNothingPending;

  /// Reference key acct.err.passwordRequired
  ///
  /// In en, this message translates to:
  /// **'Enter a password.'**
  String get authErrPasswordRequired;

  /// Reference key acct.err.passwordWeak
  ///
  /// In en, this message translates to:
  /// **'Your password doesn’t meet all the requirements yet.'**
  String get authErrPasswordWeak;

  /// Too many attempts too quickly
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get authErrRateLimited;

  /// Reference key acct.err.signedOut
  ///
  /// In en, this message translates to:
  /// **'You’re signed out. Sign in to continue.'**
  String get authErrSignedOut;

  /// Reference key acct.err.storage
  ///
  /// In en, this message translates to:
  /// **'Lume couldn’t save to this device. Check its storage settings and try again.'**
  String get authErrStorage;

  /// Reference key auth.expiredCta
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get authExpiredCta;

  /// Reference key auth.expiredText
  ///
  /// In en, this message translates to:
  /// **'Sign in again and Lume will take you back to where you were.'**
  String get authExpiredText;

  /// Reference key auth.expiredTitle
  ///
  /// In en, this message translates to:
  /// **'Your session has expired'**
  String get authExpiredTitle;

  /// Reference key acct.f.code
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get authFieldCode;

  /// Reference key acct.f.confirm
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authFieldConfirm;

  /// Reference key acct.f.email
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authFieldEmail;

  /// Reference key acct.f.name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get authFieldName;

  /// Reference key acct.f.new
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authFieldNewPassword;

  /// Reference key acct.f.password
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authFieldPassword;

  /// Reference key auth.forgot
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotAction;

  /// Reference key auth.forgotCta
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get authForgotCta;

  /// Reference key auth.forgotText
  ///
  /// In en, this message translates to:
  /// **'Enter the email associated with your Lume account.'**
  String get authForgotText;

  /// Reference key auth.forgotTitle
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotTitle;

  /// Reference key auth.haveAccount
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// Reference key acct.pw.hide
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// Reference key auth.legal
  ///
  /// In en, this message translates to:
  /// **'Creating an account means Lume keeps this information for you.'**
  String get authLegal;

  /// Reference key auth.legalLink
  ///
  /// In en, this message translates to:
  /// **'How Lume handles your data'**
  String get authLegalLink;

  /// Shown only by a repository with no mail server behind it
  ///
  /// In en, this message translates to:
  /// **'This build has no mail server. Your code is {code}.'**
  String authLocalCode(String code);

  /// Reference key auth.nameHint
  ///
  /// In en, this message translates to:
  /// **'So Lume knows what to call you.'**
  String get authNameHint;

  /// Reference key auth.needAccountText
  ///
  /// In en, this message translates to:
  /// **'This part of Lume belongs to your account.'**
  String get authNeedAccountText;

  /// Reference key auth.noAccount
  ///
  /// In en, this message translates to:
  /// **'Don’t have an account?'**
  String get authNoAccount;

  /// Reference key auth.openLink
  ///
  /// In en, this message translates to:
  /// **'Open the reset link'**
  String get authOpenLink;

  /// Reference key acct.pw.digit
  ///
  /// In en, this message translates to:
  /// **'a number'**
  String get authPasswordRuleDigit;

  /// Reference key acct.pw.len
  ///
  /// In en, this message translates to:
  /// **'at least 8 characters'**
  String get authPasswordRuleLength;

  /// Reference key acct.pw.lower
  ///
  /// In en, this message translates to:
  /// **'a lowercase letter'**
  String get authPasswordRuleLower;

  /// Reference key acct.pw.upper
  ///
  /// In en, this message translates to:
  /// **'an uppercase letter'**
  String get authPasswordRuleUpper;

  /// Reference key acct.pw.title
  ///
  /// In en, this message translates to:
  /// **'Password must contain'**
  String get authPasswordRulesTitle;

  /// Reference key auth.rememberPw
  ///
  /// In en, this message translates to:
  /// **'Remember your password?'**
  String get authRememberPassword;

  /// Reference key auth.resend
  ///
  /// In en, this message translates to:
  /// **'Send it again'**
  String get authResend;

  /// Reference key auth.resendIn; a live countdown
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, one {You can ask again in {seconds} second} other {You can ask again in {seconds} seconds}}'**
  String authResendIn(int seconds);

  /// Reference key auth.resendNone
  ///
  /// In en, this message translates to:
  /// **'Didn’t receive it?'**
  String get authResendNone;

  /// Reference key auth.resetCta
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get authResetCta;

  /// Reference key auth.resetText
  ///
  /// In en, this message translates to:
  /// **'Choose something you haven’t used here before.'**
  String get authResetText;

  /// Reference key auth.resetTitle
  ///
  /// In en, this message translates to:
  /// **'Create a new password'**
  String get authResetTitle;

  /// Reference key auth.sentLocal
  ///
  /// In en, this message translates to:
  /// **'This build has no mail server, so the link opens here.'**
  String get authSentLocal;

  /// Reference key auth.sentNote
  ///
  /// In en, this message translates to:
  /// **'The link works for one hour.'**
  String get authSentNote;

  /// Reference key auth.sentText; identical whether or not the account exists
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, we’ve sent instructions to reset your password.'**
  String get authSentText;

  /// Reference key auth.sentTitle
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get authSentTitle;

  /// Reference key acct.pw.show
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// Reference key acct.signIn
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// Reference key auth.signInText
  ///
  /// In en, this message translates to:
  /// **'Continue to your Lume.'**
  String get authSignInText;

  /// Reference key auth.signInTitle
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authSignInTitle;

  /// Reference key auth.signUpPwText
  ///
  /// In en, this message translates to:
  /// **'This is what keeps your Lume yours.'**
  String get authSignUpPasswordText;

  /// Reference key auth.signUpPwTitle
  ///
  /// In en, this message translates to:
  /// **'Choose a password'**
  String get authSignUpPasswordTitle;

  /// Reference key auth.signUpText
  ///
  /// In en, this message translates to:
  /// **'Your Lume, kept safe and reachable from anywhere.'**
  String get authSignUpText;

  /// Reference key auth.signUpTitle
  ///
  /// In en, this message translates to:
  /// **'Create your Lume account'**
  String get authSignUpTitle;

  /// Reference key auth.signingIn
  ///
  /// In en, this message translates to:
  /// **'Signing you in…'**
  String get authSigningIn;

  /// Reference key auth.stepOf
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}'**
  String authStepOf(int n, int total);

  /// Reference key acct.pw.strength0
  ///
  /// In en, this message translates to:
  /// **'Enter a password'**
  String get authStrength0;

  /// Reference key acct.pw.strength1
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get authStrength1;

  /// Reference key acct.pw.strength2
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get authStrength2;

  /// Reference key acct.pw.strength3
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get authStrength3;

  /// Reference key acct.pw.strength4
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get authStrength4;

  /// Reference key auth.troubleCta
  ///
  /// In en, this message translates to:
  /// **'Request a new link'**
  String get authTroubleCta;

  /// Reference key auth.troubleExpired
  ///
  /// In en, this message translates to:
  /// **'Recovery links stop working after an hour, so this one has expired. Ask for a new one and it will arrive the same way.'**
  String get authTroubleExpired;

  /// Reference key auth.troubleText
  ///
  /// In en, this message translates to:
  /// **'A recovery link can be used once, and only by the address it was sent to. Ask for a new one and it will arrive the same way.'**
  String get authTroubleText;

  /// Reference key auth.troubleTitle
  ///
  /// In en, this message translates to:
  /// **'That link didn’t work'**
  String get authTroubleTitle;

  /// Reference key auth.updatedText
  ///
  /// In en, this message translates to:
  /// **'You can now sign in with your new password.'**
  String get authUpdatedText;

  /// Reference key auth.updatedTitle
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get authUpdatedTitle;

  /// Reference key auth.verifyCta
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get authVerifyCta;

  /// Reference key auth.verifyText; the masked address follows on its own line
  ///
  /// In en, this message translates to:
  /// **'We sent a six-digit code to'**
  String get authVerifyText;

  /// Reference key auth.verifyTitle
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get authVerifyTitle;

  /// Reference key auth.welcomeBack
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String authWelcomeBack(String name);

  /// Reference key auth.working
  ///
  /// In en, this message translates to:
  /// **'One moment…'**
  String get authWorking;

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

  /// Reference key a.optional; §8 marks optional fields rather than required ones
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get commonOptional;

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

  /// Reference key ig.everyday
  ///
  /// In en, this message translates to:
  /// **'Everyday life'**
  String get igEveryday;

  /// Reference key ig.faith
  ///
  /// In en, this message translates to:
  /// **'Islamic features'**
  String get igFaith;

  /// Reference key ig.health
  ///
  /// In en, this message translates to:
  /// **'Health & wellness'**
  String get igHealth;

  /// Reference key ig.money
  ///
  /// In en, this message translates to:
  /// **'Money & finance'**
  String get igMoney;

  /// Reference key ig.news
  ///
  /// In en, this message translates to:
  /// **'News & entertainment'**
  String get igNews;

  /// Reference key ig.travel
  ///
  /// In en, this message translates to:
  /// **'Travel & getting around'**
  String get igTravel;

  /// Interest "alarms". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Alarms & timers'**
  String get intAlarms;

  /// Interest "bills". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get intBills;

  /// Interest "calendar". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get intCalendar;

  /// Interest "convert". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Converters'**
  String get intConvert;

  /// Interest "cricket". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Cricket'**
  String get intCricket;

  /// Interest "duas". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Duas & dhikr'**
  String get intDuas;

  /// Interest "expenses". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get intExpenses;

  /// Interest "fitness". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get intFitness;

  /// Interest "flights". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get intFlights;

  /// Interest "fuel". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get intFuel;

  /// Interest "habits". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get intHabits;

  /// Interest "hadith". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get intHadith;

  /// Interest "markets". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get intMarkets;

  /// Interest "maths". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Calculators'**
  String get intMaths;

  /// Interest "meds". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get intMeds;

  /// Interest "nearby". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Nearby places'**
  String get intNearby;

  /// Interest "news". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get intNews;

  /// Interest "notes". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get intNotes;

  /// Interest "prayer". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get intPrayer;

  /// Interest "quotes". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Daily quotes'**
  String get intQuotes;

  /// Interest "quran". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Qur’an'**
  String get intQuran;

  /// Interest "ramadan". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get intRamadan;

  /// Interest "rates". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Rates & gold'**
  String get intRates;

  /// Interest "reading". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get intReading;

  /// Interest "savings". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Saving & goals'**
  String get intSavings;

  /// Interest "sleep". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get intSleep;

  /// Interest "tasks". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Tasks & to-dos'**
  String get intTasks;

  /// Interest "trains". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Trains'**
  String get intTrains;

  /// Interest "water". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get intWater;

  /// Interest "weather". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get intWeather;

  /// Interest "zakat". The reference hard-codes the English label and never translates it; see D12
  ///
  /// In en, this message translates to:
  /// **'Zakat & giving'**
  String get intZakat;

  /// Prayer calculation method
  ///
  /// In en, this message translates to:
  /// **'Egyptian'**
  String get methodEgyptian;

  /// Prayer calculation method
  ///
  /// In en, this message translates to:
  /// **'ISNA'**
  String get methodIsna;

  /// Prayer calculation method
  ///
  /// In en, this message translates to:
  /// **'University of Karachi'**
  String get methodKarachi;

  /// Prayer calculation method
  ///
  /// In en, this message translates to:
  /// **'Muslim World League'**
  String get methodMwl;

  /// Prayer calculation method
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura'**
  String get methodUmmAlQura;

  /// Reference key acct.account
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

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

  /// Reference key home.notifications
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

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

  /// Reference key onb.allSet
  ///
  /// In en, this message translates to:
  /// **'All set'**
  String get onbAllSet;

  /// Refuses a tap once the cap is reached
  ///
  /// In en, this message translates to:
  /// **'Up to {max} — remove one first'**
  String onbAtCap(String max);

  /// Reference key onb.cityText; untranslated in the prototype (D12)
  ///
  /// In en, this message translates to:
  /// **'Used for weather, prayer times where relevant, and anything local.'**
  String get onbCityText;

  /// Reference key onb.cityTitle
  ///
  /// In en, this message translates to:
  /// **'Which city are you in?'**
  String get onbCityTitle;

  /// The final step’s action
  ///
  /// In en, this message translates to:
  /// **'Enter Lume'**
  String get onbEnterLume;

  /// The interests step’s supporting copy. Untranslated in the reference; see D12
  ///
  /// In en, this message translates to:
  /// **'Pick 5 to 10. Your home screen, tools and reading are built around them — change them whenever you like.'**
  String get onbHereForText;

  /// Reference key onb.hereForTitle
  ///
  /// In en, this message translates to:
  /// **'What are you here for?'**
  String get onbHereForTitle;

  /// Reference key onb.localKicker
  ///
  /// In en, this message translates to:
  /// **'Make it local'**
  String get onbLocalKicker;

  /// The faith-gated group heading on the set-up step
  ///
  /// In en, this message translates to:
  /// **'Prayer calculation method'**
  String get onbMethodLabel;

  /// Reference key onb.minimum, shown below the minimum
  ///
  /// In en, this message translates to:
  /// **'{count} of {min} minimum'**
  String onbMinimum(String count, String min);

  /// Reference key onb.nameKicker; untranslated in the prototype (D12)
  ///
  /// In en, this message translates to:
  /// **'One last thing'**
  String get onbNameKicker;

  /// Reference key acct.f.displayName
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get onbNameLabel;

  /// Reference key onb.nameNote; untranslated in the prototype (D12)
  ///
  /// In en, this message translates to:
  /// **'Lume keeps this on your device.'**
  String get onbNameNote;

  /// Reference key onb.namePlaceholder
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get onbNamePlaceholder;

  /// Reference key onb.nameSkip
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get onbNameSkip;

  /// Reference key onb.nameText
  ///
  /// In en, this message translates to:
  /// **'Only used to greet you. You can change it later, or skip it entirely.'**
  String get onbNameText;

  /// Reference key onb.nameTitle
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get onbNameTitle;

  /// Reference key onb.onDevice
  ///
  /// In en, this message translates to:
  /// **'Lume keeps this on your device. Nothing is uploaded.'**
  String get onbOnDevice;

  /// Reference key onb.permLocation
  ///
  /// In en, this message translates to:
  /// **'Use your location'**
  String get onbPermLocation;

  /// Shown when the Islamic experience is off
  ///
  /// In en, this message translates to:
  /// **'For weather, local services and nearby places'**
  String get onbPermLocationSub;

  /// Shown when the Islamic experience is on
  ///
  /// In en, this message translates to:
  /// **'For prayer times, Qibla, weather and nearby places'**
  String get onbPermLocationSubFaith;

  /// Reference key onb.permNotify
  ///
  /// In en, this message translates to:
  /// **'Gentle reminders'**
  String get onbPermNotify;

  /// Shown when the Islamic experience is off
  ///
  /// In en, this message translates to:
  /// **'A quiet nudge for the things you asked us to watch'**
  String get onbPermNotifySub;

  /// Shown when the Islamic experience is on
  ///
  /// In en, this message translates to:
  /// **'A quiet nudge 5 minutes before each adhan'**
  String get onbPermNotifySubFaith;

  /// Reference key onb.planKicker
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get onbPlanKicker;

  /// The plan step’s supporting copy; untranslated in the prototype (D12)
  ///
  /// In en, this message translates to:
  /// **'Tasks, reminders and events on one timeline — with everything that matters already in the right place.'**
  String get onbPlanText;

  /// Reference key onb.planTitle
  ///
  /// In en, this message translates to:
  /// **'Your day, laid out before it starts'**
  String get onbPlanTitle;

  /// Reference key onb.readyFaith; untranslated in the prototype (D12)
  ///
  /// In en, this message translates to:
  /// **'Your next prayer is {prayer}, and today’s plan is waiting on the home screen.'**
  String onbReadyFaith(String prayer);

  /// Reference key onb.readyGeneral; untranslated in the prototype (D12)
  ///
  /// In en, this message translates to:
  /// **'Today’s plan is waiting on the home screen.'**
  String get onbReadyGeneral;

  /// Reference key onb.readyNamed
  ///
  /// In en, this message translates to:
  /// **'You’re ready, {name}'**
  String onbReadyNamed(String name);

  /// Reference key onb.readyTitle — account.js wins over core.js; see ONBOARDING_INVENTORY F2
  ///
  /// In en, this message translates to:
  /// **'You’re all set'**
  String get onbReadyTitle;

  /// Reference key onb.revisit; untranslated in the prototype (D12)
  ///
  /// In en, this message translates to:
  /// **'You can revisit this tour any time from Profile.'**
  String get onbRevisit;

  /// Reference key onb.selected, shown at or above the minimum
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} selected'**
  String onbSelected(String count, String max);

  /// Reference key onb.setupText; untranslated in the prototype (D12)
  ///
  /// In en, this message translates to:
  /// **'Two permissions, and you can change either of them later.'**
  String get onbSetupText;

  /// Reference key onb.setupTitle
  ///
  /// In en, this message translates to:
  /// **'Set it up once'**
  String get onbSetupTitle;

  /// The accent half of the welcome step’s link
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get onbSignInAction;

  /// The quiet half of the welcome step’s link
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get onbSignInPrompt;

  /// Shown when Skip is used before any interest is chosen
  ///
  /// In en, this message translates to:
  /// **'Set up with our defaults — edit them in Profile'**
  String get onbSkippedDefaults;

  /// Shown when Skip is used after interests are already stored
  ///
  /// In en, this message translates to:
  /// **'Tour skipped — find it again in Profile'**
  String get onbSkippedTour;

  /// Reference key onb.toolsKicker
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get onbToolsKicker;

  /// The tools step’s supporting copy; untranslated in the prototype (D12)
  ///
  /// In en, this message translates to:
  /// **'Calculator, converters, weather, scanner, rates, trackers — sorted, so you never hunt for them.'**
  String get onbToolsText;

  /// The tools step’s title. The count is the whole catalogue, not the eligible subset — see ONBOARDING_INVENTORY F5
  ///
  /// In en, this message translates to:
  /// **'{count}-odd tools, one or two taps away'**
  String onbToolsTitle(String count);

  /// Shown when the flow completes
  ///
  /// In en, this message translates to:
  /// **'Welcome to Lume'**
  String get onbWelcomeBack;

  /// Reference key onb.welcomeText; untranslated in the prototype (D12)
  ///
  /// In en, this message translates to:
  /// **'Plans, money, travel, reading and the small tools you reach for — without the clutter.'**
  String get onbWelcomeText;

  /// Reference key onb.welcomeTitle
  ///
  /// In en, this message translates to:
  /// **'Everything your day needs, quietly organised.'**
  String get onbWelcomeTitle;

  /// Reference key onb.whereText
  ///
  /// In en, this message translates to:
  /// **'This helps us personalise local information and services. It says nothing about who you are.'**
  String get onbWhereText;

  /// Reference key onb.whereTitle
  ///
  /// In en, this message translates to:
  /// **'Where are you based?'**
  String get onbWhereTitle;

  /// Reference key onb.yoursKicker
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get onbYoursKicker;

  /// Reference key pers.allCountries
  ///
  /// In en, this message translates to:
  /// **'All countries'**
  String get persAllCountries;

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

  /// Reference key pers.popular
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get persPopular;

  /// Reference key pers.recent
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get persRecent;

  /// Reference key pers.searchCities
  ///
  /// In en, this message translates to:
  /// **'Search cities'**
  String get persSearchCities;

  /// Reference key pers.searchCountries
  ///
  /// In en, this message translates to:
  /// **'Search countries'**
  String get persSearchCountries;

  /// Reference key pers.useLocation
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get persUseLocation;

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

  /// Master-detail pane before a record is chosen
  ///
  /// In en, this message translates to:
  /// **'Choose a record to see it here.'**
  String get recordsNoSelectionText;

  /// Master-detail pane before a record is chosen
  ///
  /// In en, this message translates to:
  /// **'Nothing selected'**
  String get recordsNoSelectionTitle;

  /// Unrecognised location
  ///
  /// In en, this message translates to:
  /// **'The link may be old, or the page may have moved.'**
  String get routeMissingText;

  /// Unrecognised location
  ///
  /// In en, this message translates to:
  /// **'We can’t find that'**
  String get routeMissingTitle;

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

  /// Announced while the launch is still deciding where to go
  ///
  /// In en, this message translates to:
  /// **'Starting Lume'**
  String get startupLoading;

  /// Tool host error state
  ///
  /// In en, this message translates to:
  /// **'We couldn’t load this. Try again in a moment.'**
  String get toolErrorText;

  /// Tool host error state
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get toolErrorTitle;

  /// Announced while a tool is still assembling
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get toolLoading;

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

  /// Reference key tool.unavailable
  ///
  /// In en, this message translates to:
  /// **'That tool isn’t part of your setup.'**
  String get toolUnavailableText;

  /// Tool host unavailable state
  ///
  /// In en, this message translates to:
  /// **'Not part of your setup'**
  String get toolUnavailableTitle;

  /// Reference key tools.nothingYet
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get toolsNothingYet;
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

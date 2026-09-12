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

  /// Reference: a prayer still to come
  ///
  /// In en, this message translates to:
  /// **'Adhan · reminder on'**
  String get agendaAdhanOn;

  /// Reference: an agenda errand
  ///
  /// In en, this message translates to:
  /// **'Pick up groceries'**
  String get agendaGroceries;

  /// Reference: an agenda errand’s detail
  ///
  /// In en, this message translates to:
  /// **'On the way home'**
  String get agendaGroceriesMeta;

  /// Reference: the loadshedding entry in the agenda
  ///
  /// In en, this message translates to:
  /// **'Outage'**
  String get agendaOutage;

  /// Reference: the outage entry’s area and length
  ///
  /// In en, this message translates to:
  /// **'{area} · {hours, plural, =1{1h} other{{hours}h}}'**
  String agendaOutageMeta(String area, int hours);

  /// Reference: a prayer that has passed
  ///
  /// In en, this message translates to:
  /// **'Prayed'**
  String get agendaPrayed;

  /// Reference: an agenda event
  ///
  /// In en, this message translates to:
  /// **'Design review'**
  String get agendaReview;

  /// Reference: an agenda event’s detail
  ///
  /// In en, this message translates to:
  /// **'45 min · Meeting room 2'**
  String get agendaReviewMeta;

  /// Reference: an agenda event
  ///
  /// In en, this message translates to:
  /// **'Team standup'**
  String get agendaStandup;

  /// Reference: an agenda event’s detail
  ///
  /// In en, this message translates to:
  /// **'15 min · Video call'**
  String get agendaStandupMeta;

  /// The kind line on an anniversary row
  ///
  /// In en, this message translates to:
  /// **'Anniversary'**
  String get anniversaryKind;

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

  /// Reference: a bill row in Coming up
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{due in 1 day} other{due in {n} days}}'**
  String billsDueIn(int n);

  /// Reference key bills.dueThisMonth
  ///
  /// In en, this message translates to:
  /// **'Due this month'**
  String get billsDueThisMonth;

  /// Reference key bills.overdue.title, pluralised
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 bill needs attention} other{{n} bills need attention}}'**
  String billsNeedAttention(int n);

  /// Reference key bills.overdueBy
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day overdue} other{{n} days overdue}}'**
  String billsOverdueBy(int n);

  /// The kind line on a birthday row
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthdayKind;

  /// Reference: a collection card
  ///
  /// In en, this message translates to:
  /// **'Budget basics'**
  String get collectionBudget;

  /// Reference: a collection card’s detail
  ///
  /// In en, this message translates to:
  /// **'{n} lessons'**
  String collectionBudgetMeta(int n);

  /// Reference: a collection card
  ///
  /// In en, this message translates to:
  /// **'Focus sounds'**
  String get collectionFocus;

  /// Reference: a collection card’s detail
  ///
  /// In en, this message translates to:
  /// **'{n} tracks'**
  String collectionFocusMeta(int n);

  /// Reference: a collection card
  ///
  /// In en, this message translates to:
  /// **'Gratitude prompts'**
  String get collectionGratitude;

  /// Reference: a collection card’s detail
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String collectionGratitudeMeta(int n);

  /// Reference: a collection card
  ///
  /// In en, this message translates to:
  /// **'Night surahs'**
  String get collectionNightSurahs;

  /// Reference: a collection card’s detail
  ///
  /// In en, this message translates to:
  /// **'{surahs} surahs · {minutes} min'**
  String collectionNightSurahsMeta(int surahs, int minutes);

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

  /// Shown on a section whose figures came from the cache
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get commonOffline;

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

  /// Shown on a section whose figures are older than they should be
  ///
  /// In en, this message translates to:
  /// **'Not current'**
  String get commonStale;

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

  /// Reference: the cricket Discover card’s title. The side is a three-letter code
  ///
  /// In en, this message translates to:
  /// **'{team} {runs}/{wickets}'**
  String cricketScore(String team, int runs, int wickets);

  /// Reference: the cricket Discover card’s meta
  ///
  /// In en, this message translates to:
  /// **'2nd Test · Day {n}'**
  String cricketSecondTest(int n);

  /// Reference: the duas Discover card’s meta
  ///
  /// In en, this message translates to:
  /// **'For ordinary days'**
  String get discoverDuasMeta;

  /// Reference: the duas Discover card
  ///
  /// In en, this message translates to:
  /// **'Forty duas'**
  String get discoverDuasTitle;

  /// Reference key docs.renewSoon
  ///
  /// In en, this message translates to:
  /// **'Renew your {name}'**
  String docsRenewSoon(String name);

  /// Reference: the local services section
  ///
  /// In en, this message translates to:
  /// **'Around you'**
  String get exploreAround;

  /// Reference: under “Around you”
  ///
  /// In en, this message translates to:
  /// **'Local services, kept current'**
  String get exploreAroundSub;

  /// The way back out of Explore in a market where it is not a tab. Reference: explore.screen.js #exploreBack aria-label.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get exploreBackToHome;

  /// Reference: the collections section
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get exploreCollections;

  /// Reference: under “Collections”
  ///
  /// In en, this message translates to:
  /// **'Curated for a quiet moment'**
  String get exploreCollectionsSub;

  /// Reference: the live sport section
  ///
  /// In en, this message translates to:
  /// **'Cricket'**
  String get exploreCricket;

  /// Reference: under “Cricket”. A live claim the prototype writes as a literal (E3)
  ///
  /// In en, this message translates to:
  /// **'Live · 2nd Test, day 2'**
  String get exploreCricketSub;

  /// Reference: the tag on the featured card
  ///
  /// In en, this message translates to:
  /// **'Featured collection'**
  String get exploreFeatured;

  /// Reference: the nearby section
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get exploreNearby;

  /// Reference: under “Nearby”
  ///
  /// In en, this message translates to:
  /// **'Within walking distance'**
  String get exploreNearbySub;

  /// The weather card’s rain figure, read aloud
  ///
  /// In en, this message translates to:
  /// **'Rain {value}'**
  String exploreRainLabel(String value);

  /// Reference: the news section
  ///
  /// In en, this message translates to:
  /// **'Today’s reads'**
  String get exploreReads;

  /// Reference: under “Today’s reads”
  ///
  /// In en, this message translates to:
  /// **'Balanced, no doomscroll'**
  String get exploreReadsSub;

  /// Reference: the link on the cricket section
  ///
  /// In en, this message translates to:
  /// **'Scorecard'**
  String get exploreScorecard;

  /// Reference: under “Explore” elsewhere
  ///
  /// In en, this message translates to:
  /// **'Weather, reading and what’s around you'**
  String get exploreSubGlobal;

  /// Reference: under “Explore” in a market with localised services
  ///
  /// In en, this message translates to:
  /// **'Local services, scores and reading'**
  String get exploreSubLocal;

  /// The weather card’s sunset, read aloud
  ///
  /// In en, this message translates to:
  /// **'Sunset {value}'**
  String exploreSunsetLabel(String value);

  /// Reference: the weather section
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get exploreWeather;

  /// Reference: the weather card’s line — the condition and the feels-like
  ///
  /// In en, this message translates to:
  /// **'{condition} · {feels}'**
  String exploreWeatherDesc(String condition, String feels);

  /// Reference: under “Weather”. The prototype writes the number as a literal and it never changes (E1)
  ///
  /// In en, this message translates to:
  /// **'{city} · updated {n} min ago'**
  String exploreWeatherSub(String city, int n);

  /// Reference: the toast behind the Refresh link
  ///
  /// In en, this message translates to:
  /// **'Weather refreshed'**
  String get exploreWeatherToast;

  /// The weather card’s wind figure, read aloud
  ///
  /// In en, this message translates to:
  /// **'Wind {value}'**
  String exploreWindLabel(String value);

  /// Reference: a wind speed and its unit
  ///
  /// In en, this message translates to:
  /// **'{value} {unit}'**
  String exploreWindValue(String value, String unit);

  /// Reference key f.age; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Age Calculator'**
  String get featureAge;

  /// Reference key f.alarms; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get featureAlarms;

  /// Reference key f.aqi; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Air Quality'**
  String get featureAqi;

  /// Reference key f.ayah; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Ayah of the Day'**
  String get featureAyah;

  /// Reference key f.babybudget; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Baby Budget'**
  String get featureBabybudget;

  /// Reference key f.bills; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get featureBills;

  /// Reference key f.birthdays; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Birthdays'**
  String get featureBirthdays;

  /// Reference key f.bmi; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'BMI Calculator'**
  String get featureBmi;

  /// Reference key f.calculator; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get featureCalculator;

  /// Reference key f.calendar; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get featureCalendar;

  /// Reference key f.committee; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Committee'**
  String get featureCommittee;

  /// Reference key f.compound; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Compound Interest'**
  String get featureCompound;

  /// Reference key f.converter; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Unit Converter'**
  String get featureConverter;

  /// Reference key f.cricket; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Cricket'**
  String get featureCricket;

  /// Reference key f.currency; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get featureCurrency;

  /// Reference key f.cycle; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Cycle Tracker'**
  String get featureCycle;

  /// Reference key f.datecalc; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Date Calculator'**
  String get featureDatecalc;

  /// Reference key f.docscan; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Document Scanner'**
  String get featureDocscan;

  /// Reference key f.documents; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get featureDocuments;

  /// Reference key f.duas; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Daily Duas'**
  String get featureDuas;

  /// Reference key f.emergency; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get featureEmergency;

  /// Reference key f.events; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get featureEvents;

  /// Reference key f.expenses; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get featureExpenses;

  /// Reference key f.faraid; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Faraid'**
  String get featureFaraid;

  /// Reference key f.fasting; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Fasting Tracker'**
  String get featureFasting;

  /// Reference key f.flights; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get featureFlights;

  /// Reference key f.focus; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Focus Timer'**
  String get featureFocus;

  /// Reference key f.fuel; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Fuel Prices'**
  String get featureFuel;

  /// Reference key f.fuelcost; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Fuel Cost'**
  String get featureFuelcost;

  /// Reference key f.goals; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Savings Goals'**
  String get featureGoals;

  /// Reference key f.goldrates; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Currency & Gold'**
  String get featureGoldrates;

  /// Reference key f.habits; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get featureHabits;

  /// Reference key f.hadith; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get featureHadith;

  /// Reference key f.health; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Health Records'**
  String get featureHealth;

  /// Reference key f.hijri; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Islamic Calendar'**
  String get featureHijri;

  /// Reference key f.holidays; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Public Holidays'**
  String get featureHolidays;

  /// Reference key f.installments; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get featureInstallments;

  /// Reference key f.learning; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Learning & Growth'**
  String get featureLearning;

  /// Reference key f.ledger; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Lending Ledger'**
  String get featureLedger;

  /// Reference key f.loadshed; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Loadshedding'**
  String get featureLoadshed;

  /// Reference key f.loan; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Loan / EMI'**
  String get featureLoan;

  /// Reference key f.markets; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get featureMarkets;

  /// Reference key f.mealplan; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Meal Planner'**
  String get featureMealplan;

  /// Reference key f.mediasaver; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Media Saver'**
  String get featureMediasaver;

  /// Reference key f.meds; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get featureMeds;

  /// Reference key f.mosques; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Nearby Mosques'**
  String get featureMosques;

  /// Reference key f.names99; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'99 Names'**
  String get featureNames99;

  /// Reference key f.natsavings; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'National Savings'**
  String get featureNatsavings;

  /// Reference key f.news; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get featureNews;

  /// Reference key f.notes; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get featureNotes;

  /// Reference key f.packages; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Mobile Packages'**
  String get featurePackages;

  /// Reference key f.parcel; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Parcel Tracker'**
  String get featureParcel;

  /// Reference key f.passport; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Passport Photos'**
  String get featurePassport;

  /// Reference key f.play; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get featurePlay;

  /// Reference key f.prayer; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get featurePrayer;

  /// Reference key f.praytrack; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Prayer Tracker'**
  String get featurePraytrack;

  /// Reference key f.pregnancy; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Pregnancy'**
  String get featurePregnancy;

  /// Reference key f.prizebonds; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Prize Bonds'**
  String get featurePrizebonds;

  /// Reference key f.qibla; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Qibla Compass'**
  String get featureQibla;

  /// Reference key f.qr; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'QR Scanner'**
  String get featureQr;

  /// Reference key f.quran; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Al-Qur’an'**
  String get featureQuran;

  /// Reference key f.quransearch; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Search the Qur’an'**
  String get featureQuransearch;

  /// Reference key f.ramadan; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get featureRamadan;

  /// Reference key f.recipes; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get featureRecipes;

  /// Reference key f.reminders; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get featureReminders;

  /// Reference key f.shopping; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get featureShopping;

  /// Reference key f.speedtest; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Speed Test'**
  String get featureSpeedtest;

  /// Reference key f.stopwatch; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Stopwatch'**
  String get featureStopwatch;

  /// Reference key f.streak; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Daily Streak'**
  String get featureStreak;

  /// Reference key f.subs; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get featureSubs;

  /// Reference key f.sunmoon; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Sun & Moon'**
  String get featureSunmoon;

  /// Reference key f.taraweeh; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Taraweeh'**
  String get featureTaraweeh;

  /// Reference key f.tasbih; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get featureTasbih;

  /// Reference key f.tax; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Tax Calculator'**
  String get featureTax;

  /// Reference key f.timer; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get featureTimer;

  /// Reference key f.tipsplit; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Tip & Split'**
  String get featureTipsplit;

  /// Reference key f.todos; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'To-dos'**
  String get featureTodos;

  /// Reference key f.trains; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Trains'**
  String get featureTrains;

  /// Reference key f.vaccines; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Vaccinations'**
  String get featureVaccines;

  /// Reference key f.vehicle; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Vehicle & Fines'**
  String get featureVehicle;

  /// Reference key f.wastatus; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Status'**
  String get featureWastatus;

  /// Reference key f.water; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get featureWater;

  /// Reference key f.weather; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get featureWeather;

  /// Reference key f.worldclock; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'World Clock'**
  String get featureWorldclock;

  /// Reference key f.zakat; the catalogue is the source of the English
  ///
  /// In en, this message translates to:
  /// **'Zakat Calculator'**
  String get featureZakat;

  /// Reference: the featured card’s first fact
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String featuredCalmDays(int n);

  /// Reference: the featured card’s second fact
  ///
  /// In en, this message translates to:
  /// **'{n} min each'**
  String featuredCalmEach(int n);

  /// Reference: the featured card’s body
  ///
  /// In en, this message translates to:
  /// **'Small routines for planning, spending and winding down — one for each day.'**
  String get featuredCalmText;

  /// Reference: the featured card for everyone else
  ///
  /// In en, this message translates to:
  /// **'A calmer week, in seven steps'**
  String get featuredCalmTitle;

  /// Reference: the featured card’s second fact
  ///
  /// In en, this message translates to:
  /// **'Audio included'**
  String get featuredDuasAudio;

  /// Reference: the featured card’s first fact
  ///
  /// In en, this message translates to:
  /// **'{n} duas'**
  String featuredDuasCount(int n);

  /// Reference: the featured card’s body
  ///
  /// In en, this message translates to:
  /// **'Short supplications for the commute, the queue and the quiet minute before sleep.'**
  String get featuredDuasText;

  /// Reference: the featured card with the Islamic experience on
  ///
  /// In en, this message translates to:
  /// **'Forty duas for ordinary days'**
  String get featuredDuasTitle;

  /// Reference: the featured card’s third fact
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get featuredFree;

  /// Reference: a duration on a card
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String featuredMinutes(int n);

  /// Reference key fuel.g.petrol
  ///
  /// In en, this message translates to:
  /// **'Petrol'**
  String get fuelPetrol;

  /// The Pakistani fuel regulator. A proper noun, transliterated rather than translated
  ///
  /// In en, this message translates to:
  /// **'OGRA'**
  String get fuelSourceOgra;

  /// Reference key greet.afternoon
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetAfternoon;

  /// Reference key greet.evening
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetEvening;

  /// Reference key greet.late
  ///
  /// In en, this message translates to:
  /// **'Still up'**
  String get greetLate;

  /// Reference key greet.morning
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetMorning;

  /// Reference key greet.named
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String greetNamed(String greeting, String name);

  /// Reference key greet.winddown
  ///
  /// In en, this message translates to:
  /// **'Winding down'**
  String get greetWindDown;

  /// Reference: a habit
  ///
  /// In en, this message translates to:
  /// **'Fajr on time'**
  String get habitFajr;

  /// Reference: a habit
  ///
  /// In en, this message translates to:
  /// **'Qur’an daily'**
  String get habitQuran;

  /// Reference: a habit
  ///
  /// In en, this message translates to:
  /// **'Walk 6k steps'**
  String get habitSteps;

  /// Reference: a habit
  ///
  /// In en, this message translates to:
  /// **'8 glasses'**
  String get habitWater;

  /// Reference: aria-label="Highlights" on the carousel
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get heroHighlights;

  /// Reference key home.ayahProgress
  ///
  /// In en, this message translates to:
  /// **'Ayah {n} of {total} · about {min} min left'**
  String homeAyahProgress(int n, int total, int min);

  /// Reference key home.continueSurah
  ///
  /// In en, this message translates to:
  /// **'Continue {surah}'**
  String homeContinueSurah(String surah);

  /// Reference key home.discover
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get homeDiscover;

  /// Reference key home.discoverSub
  ///
  /// In en, this message translates to:
  /// **'Because you check these often'**
  String get homeDiscoverSub;

  /// Reference: the fuel row’s meta line
  ///
  /// In en, this message translates to:
  /// **'Effective {date} · {source}'**
  String homeEffective(String date, String source);

  /// Reference: the weather Discover card
  ///
  /// In en, this message translates to:
  /// **'Feels like {temp}'**
  String homeFeelsLike(String temp);

  /// Reference key home.glance
  ///
  /// In en, this message translates to:
  /// **'At a glance'**
  String get homeGlance;

  /// Reference key home.glanceGeneral
  ///
  /// In en, this message translates to:
  /// **'What matters in the next few hours'**
  String get homeGlanceGeneral;

  /// Reference key home.glanceMuslim
  ///
  /// In en, this message translates to:
  /// **'Prayer, reading and what’s next'**
  String get homeGlanceMuslim;

  /// Reference key home.liveNow
  ///
  /// In en, this message translates to:
  /// **'Right now'**
  String get homeLiveNow;

  /// Reference key home.liveNowSub
  ///
  /// In en, this message translates to:
  /// **'As of {time}'**
  String homeLiveNowSub(String time);

  /// Reference: the loadshedding Discover card
  ///
  /// In en, this message translates to:
  /// **'Next outage {time}'**
  String homeNextOutage(String time);

  /// Reference key home.nextPrayer
  ///
  /// In en, this message translates to:
  /// **'Next prayer'**
  String get homeNextPrayer;

  /// Reference key home.nextUp
  ///
  /// In en, this message translates to:
  /// **'next up'**
  String get homeNextUp;

  /// Reference: the loadshedding Discover card’s meta
  ///
  /// In en, this message translates to:
  /// **'{area} · {hours, plural, =1{1 hour} other{{hours} hours}}'**
  String homeOutageArea(String area, int hours);

  /// Reference key home.quickDefault
  ///
  /// In en, this message translates to:
  /// **'The eight you reach for most'**
  String get homeQuickDefault;

  /// Reference key home.quickFromInterests
  ///
  /// In en, this message translates to:
  /// **'Picked from your interests'**
  String get homeQuickFromInterests;

  /// Reference key home.quickTools
  ///
  /// In en, this message translates to:
  /// **'Quick tools'**
  String get homeQuickTools;

  /// Reference key home.rightNow
  ///
  /// In en, this message translates to:
  /// **'Right now'**
  String get homeRightNow;

  /// Reference key home.searchEverything
  ///
  /// In en, this message translates to:
  /// **'Search everything'**
  String get homeSearchEverything;

  /// Reference key home.tasksLeft, pluralised
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Nothing left today} =1{1 task left today} other{{n} tasks left today}}'**
  String homeTasksLeft(int n);

  /// Reference key home.tasksNext
  ///
  /// In en, this message translates to:
  /// **'Next: {task} · {time}'**
  String homeTasksNext(String task, String time);

  /// Reference key home.toGo
  ///
  /// In en, this message translates to:
  /// **'to go'**
  String get homeToGo;

  /// Reference key home.tomorrowIn
  ///
  /// In en, this message translates to:
  /// **'Tomorrow in {city}'**
  String homeTomorrowIn(String city);

  /// Reference key home.upcoming
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get homeUpcoming;

  /// Reference key home.upcomingSub
  ///
  /// In en, this message translates to:
  /// **'The next few days'**
  String get homeUpcomingSub;

  /// Reference: the weather Discover card’s title
  ///
  /// In en, this message translates to:
  /// **'{temp} and {condition}'**
  String homeWeatherAnd(String temp, String condition);

  /// Reference key a11y.yourProfile
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get homeYourProfile;

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

  /// Reference key loadshed.currentlyOff
  ///
  /// In en, this message translates to:
  /// **'Power is off'**
  String get loadshedOff;

  /// Reference key loadshed.until
  ///
  /// In en, this message translates to:
  /// **'until {time}'**
  String loadshedUntil(String time);

  /// The market a national pump price applies to. Only the markets whose regulator publishes one need a key
  ///
  /// In en, this message translates to:
  /// **'Pakistan'**
  String get marketPk;

  /// Reference key markets.closed
  ///
  /// In en, this message translates to:
  /// **'Market closed'**
  String get marketsClosed;

  /// A market shut by a holiday rather than by the clock
  ///
  /// In en, this message translates to:
  /// **'Closed for {holiday}'**
  String marketsHoliday(String holiday);

  /// Reference key markets.open
  ///
  /// In en, this message translates to:
  /// **'Market open'**
  String get marketsOpen;

  /// A market outside its trading week
  ///
  /// In en, this message translates to:
  /// **'Closed for the weekend'**
  String get marketsWeekend;

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

  /// Reference: a nearby place
  ///
  /// In en, this message translates to:
  /// **'Chai Shai'**
  String get nearbyChaiShai;

  /// Reference: a nearby place’s detail
  ///
  /// In en, this message translates to:
  /// **'Quiet café · open till {time}'**
  String nearbyChaiShaiSub(String time);

  /// Reference: a nearby place
  ///
  /// In en, this message translates to:
  /// **'Hill Park'**
  String get nearbyHillPark;

  /// Reference: a nearby place’s detail
  ///
  /// In en, this message translates to:
  /// **'Good for a sunset walk'**
  String get nearbyHillParkSub;

  /// Reference: a distance over a kilometre
  ///
  /// In en, this message translates to:
  /// **'{n} km'**
  String nearbyKilometres(String n);

  /// Reference: a distance under a kilometre
  ///
  /// In en, this message translates to:
  /// **'{n} m'**
  String nearbyMetres(int n);

  /// Reference: a nearby place. Fixed Karachi content shown in every market (E2)
  ///
  /// In en, this message translates to:
  /// **'Masjid-e-Tooba'**
  String get nearbyTooba;

  /// Reference: a nearby place’s detail
  ///
  /// In en, this message translates to:
  /// **'Jamaat for Asr at {time}'**
  String nearbyToobaSub(String time);

  /// Reference: a news category
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get newsCatBusiness;

  /// Reference: a news category
  ///
  /// In en, this message translates to:
  /// **'Karachi'**
  String get newsCatKarachi;

  /// Reference: a news category
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get newsCatMoney;

  /// Reference: a news category
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get newsCatProductivity;

  /// Reference: a news category
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get newsCatSport;

  /// Reference: a news category
  ///
  /// In en, this message translates to:
  /// **'Wellbeing'**
  String get newsCatWellbeing;

  /// Reference: a Pakistan headline
  ///
  /// In en, this message translates to:
  /// **'K-Electric announces revised loadshedding schedule for September'**
  String get newsLoadshed;

  /// Reference: a story’s reading time
  ///
  /// In en, this message translates to:
  /// **'{n} min read'**
  String newsReadTime(int n);

  /// Reference: a global headline
  ///
  /// In en, this message translates to:
  /// **'The two-minute reset that beats a coffee break'**
  String get newsReset;

  /// Reference: a Pakistan headline
  ///
  /// In en, this message translates to:
  /// **'Rupee holds steady as remittances climb for a third month'**
  String get newsRupee;

  /// Reference: a global headline
  ///
  /// In en, this message translates to:
  /// **'A plain-English guide to your first savings goal'**
  String get newsSavings;

  /// Reference: a global headline
  ///
  /// In en, this message translates to:
  /// **'Why a shorter to-do list finishes more work'**
  String get newsShortList;

  /// Reference: a Pakistan headline
  ///
  /// In en, this message translates to:
  /// **'Pakistan name squad for the home Test series'**
  String get newsSquad;

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

  /// Reference: the parcel Discover card’s meta
  ///
  /// In en, this message translates to:
  /// **'{carrier} · arrives today'**
  String parcelArrivesToday(String carrier);

  /// Reference: the parcel Discover card
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get parcelOutForDelivery;

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

  /// Reference key prayer.asr
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// Reference key prayer.dhuhr
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// Reference key prayer.fajr
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// Reference key prayer.isha
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// Reference key prayer.maghrib
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// Reference key qa.docscan
  ///
  /// In en, this message translates to:
  /// **'Scan doc'**
  String get qaDocscan;

  /// Reference key qa.expense
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get qaExpense;

  /// Reference key qa.note
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get qaNote;

  /// Reference key qa.parcel
  ///
  /// In en, this message translates to:
  /// **'Track parcel'**
  String get qaParcel;

  /// Reference key qa.scan
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get qaScan;

  /// Reference key qa.shop
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get qaShop;

  /// Reference key qa.tasbih
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get qaTasbih;

  /// Reference key qa.task
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get qaTask;

  /// Reference key qa.timer
  ///
  /// In en, this message translates to:
  /// **'Start timer'**
  String get qaTimer;

  /// Reference key qa.water
  ///
  /// In en, this message translates to:
  /// **'Log water'**
  String get qaWater;

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

  /// Reference: a side that has lost every wicket
  ///
  /// In en, this message translates to:
  /// **'all out'**
  String get scoreAllOut;

  /// Reference: how many overs a side has faced
  ///
  /// In en, this message translates to:
  /// **'{n} ov'**
  String scoreOvers(String n);

  /// Reference: the note under the score
  ///
  /// In en, this message translates to:
  /// **'{team} trail by {runs} runs · {player} {score}*'**
  String scoreTrail(String team, int runs, String player, int score);

  /// Reference: between the two sides
  ///
  /// In en, this message translates to:
  /// **'vs'**
  String get scoreVersus;

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

  /// Reference key slide.money.cta
  ///
  /// In en, this message translates to:
  /// **'See money'**
  String get slideMoneyCta;

  /// Reference key slide.money.k
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get slideMoneyKicker;

  /// Reference key slide.money.x
  ///
  /// In en, this message translates to:
  /// **'Rates, bills and expenses in one place.'**
  String get slideMoneyText;

  /// Reference key slide.money.t
  ///
  /// In en, this message translates to:
  /// **'Stay on top of your money'**
  String get slideMoneyTitle;

  /// Reference: aria-label on each carousel dot
  ///
  /// In en, this message translates to:
  /// **'Slide {n} of {total}'**
  String slideOf(int n, int total);

  /// Reference key slide.plan.cta
  ///
  /// In en, this message translates to:
  /// **'Open today'**
  String get slidePlanCta;

  /// Reference key slide.plan.k
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get slidePlanKicker;

  /// Reference key slide.plan.x
  ///
  /// In en, this message translates to:
  /// **'Tasks, reminders and events on one timeline.'**
  String get slidePlanText;

  /// Reference key slide.plan.t
  ///
  /// In en, this message translates to:
  /// **'Plan your day before it starts'**
  String get slidePlanTitle;

  /// Reference key slide.prayer.cta
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get slidePrayerCta;

  /// Reference key slide.prayer.k
  ///
  /// In en, this message translates to:
  /// **'Your next prayer'**
  String get slidePrayerKicker;

  /// Reference key slide.prayer.x
  ///
  /// In en, this message translates to:
  /// **'Adhan at {time} · {city}'**
  String slidePrayerLine(String time, String city);

  /// Reference key slide.read.cta
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get slideReadCta;

  /// Reference key slide.read.k
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get slideReadKicker;

  /// Reference key slide.read.x
  ///
  /// In en, this message translates to:
  /// **'You’re 42 ayahs into Al-Kahf. Two minutes is enough.'**
  String get slideReadText;

  /// Reference key slide.read.t
  ///
  /// In en, this message translates to:
  /// **'Read something meaningful'**
  String get slideReadTitle;

  /// Reference key slide.tools.cta
  ///
  /// In en, this message translates to:
  /// **'Browse tools'**
  String get slideToolsCta;

  /// Reference key slide.tools.k
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get slideToolsKicker;

  /// Reference key slide.tools.x
  ///
  /// In en, this message translates to:
  /// **'Calculator, converters, scanner and more.'**
  String get slideToolsText;

  /// Reference key slide.tools.t
  ///
  /// In en, this message translates to:
  /// **'Useful tools, all in one place'**
  String get slideToolsTitle;

  /// Reference key slide.trains.cta
  ///
  /// In en, this message translates to:
  /// **'Find a train'**
  String get slideTrainsCta;

  /// Reference key slide.trains.k
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get slideTrainsKicker;

  /// Reference key slide.trains.x
  ///
  /// In en, this message translates to:
  /// **'Live running status, fares and seats.'**
  String get slideTrainsText;

  /// Reference key slide.trains.t
  ///
  /// In en, this message translates to:
  /// **'Trains, without the guesswork'**
  String get slideTrainsTitle;

  /// Announced while the launch is still deciding where to go
  ///
  /// In en, this message translates to:
  /// **'Starting Lume'**
  String get startupLoading;

  /// Reference key subs.renews
  ///
  /// In en, this message translates to:
  /// **'renews {date}'**
  String subsRenews(String date);

  /// The surah the reading fixture is open at
  ///
  /// In en, this message translates to:
  /// **'Al-Kahf'**
  String get surahAlKahf;

  /// Reference: a task, with the Islamic experience on
  ///
  /// In en, this message translates to:
  /// **'Read two pages of Al-Kahf'**
  String get taskAlKahf;

  /// Reference: a task
  ///
  /// In en, this message translates to:
  /// **'Call home'**
  String get taskCallHome;

  /// Reference: the same task elsewhere
  ///
  /// In en, this message translates to:
  /// **'Pay the electricity bill'**
  String get taskElectricity;

  /// Reference: a task, in Pakistan
  ///
  /// In en, this message translates to:
  /// **'Pay the K-Electric bill'**
  String get taskElectricityPk;

  /// Reference: a task
  ///
  /// In en, this message translates to:
  /// **'Reply to Sara’s email'**
  String get taskEmail;

  /// Reference: a task with no clock time
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get taskEvening;

  /// Reference: a task
  ///
  /// In en, this message translates to:
  /// **'Finish the Q3 summary'**
  String get taskSummary;

  /// Reference: the toast behind the Add control
  ///
  /// In en, this message translates to:
  /// **'New task added'**
  String get todayAddToast;

  /// Reference: the agenda subtitle otherwise
  ///
  /// In en, this message translates to:
  /// **'Events and reminders, in order'**
  String get todayAgendaGeneral;

  /// Reference: the agenda subtitle with the Islamic experience on
  ///
  /// In en, this message translates to:
  /// **'Prayers and events, in order'**
  String get todayAgendaMuslim;

  /// Reference: the faith-swapped reflection section
  ///
  /// In en, this message translates to:
  /// **'Ayah of the day'**
  String get todayAyah;

  /// The same citation at the foot of the card, which the reference writes without the dot. Reference: today.screen.js quote__by.
  ///
  /// In en, this message translates to:
  /// **'{surah} {verse}'**
  String todayAyahCitation(String surah, String verse);

  /// The citation under "Ayah of the day". Reference: today.screen.js section__sub.
  ///
  /// In en, this message translates to:
  /// **'{surah} · {verse}'**
  String todayAyahReference(String surah, String verse);

  /// Reference: a Today statistic
  ///
  /// In en, this message translates to:
  /// **'Daily streak'**
  String get todayDailyStreak;

  /// A habit row read aloud: a line of coloured squares says nothing to a screen reader
  ///
  /// In en, this message translates to:
  /// **'{name}, {done} of 7 days, {streak} day streak'**
  String todayHabitSummary(String name, int done, int streak);

  /// Reference: the habit section
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get todayHabits;

  /// Reference: under “Habits”
  ///
  /// In en, this message translates to:
  /// **'Last seven days'**
  String get todayHabitsSub;

  /// Reference: under the day ring
  ///
  /// In en, this message translates to:
  /// **'of day'**
  String get todayOfDay;

  /// Reference: the ring card’s title
  ///
  /// In en, this message translates to:
  /// **'You’re on track'**
  String get todayOnTrack;

  /// Reference: a Today statistic
  ///
  /// In en, this message translates to:
  /// **'Prayer streak'**
  String get todayPrayerStreak;

  /// Reference: the private section
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get todayPrivate;

  /// Reference: under “Private”
  ///
  /// In en, this message translates to:
  /// **'Only on this device, only for you'**
  String get todayPrivateSub;

  /// Reference: the locked card’s body
  ///
  /// In en, this message translates to:
  /// **'Records, medication and expenses stay locked until you open them.'**
  String get todayPrivateText;

  /// Reference: the locked card’s title
  ///
  /// In en, this message translates to:
  /// **'Health, documents & money'**
  String get todayPrivateTitle;

  /// Reference: the toast behind the private card
  ///
  /// In en, this message translates to:
  /// **'Unlock to see private records'**
  String get todayPrivateToast;

  /// Reference: a Today statistic
  ///
  /// In en, this message translates to:
  /// **'Read today'**
  String get todayReadToday;

  /// Reference: the ring card’s line. The prototype writes it as static English and never updates it (T1)
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} tasks done. {meetings, plural, =0{Nothing else scheduled.} =1{One meeting left this afternoon.} other{{meetings} meetings left this afternoon.}}'**
  String todayRingSummary(int done, int total, int meetings);

  /// Reference: a Today statistic
  ///
  /// In en, this message translates to:
  /// **'Steps today'**
  String get todaySteps;

  /// Reference: the toast after ticking a task
  ///
  /// In en, this message translates to:
  /// **'Nice — one less thing'**
  String get todayTaskDone;

  /// Reference: the toast after un-ticking a task
  ///
  /// In en, this message translates to:
  /// **'Back on the list'**
  String get todayTaskUndone;

  /// Reference: the task section
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get todayTasks;

  /// Reference: a Today statistic
  ///
  /// In en, this message translates to:
  /// **'Tasks done'**
  String get todayTasksDone;

  /// Reference: under “Tasks”
  ///
  /// In en, this message translates to:
  /// **'Tap to tick one off'**
  String get todayTasksSub;

  /// Reference: the reflection section for everyone else
  ///
  /// In en, this message translates to:
  /// **'Today’s thought'**
  String get todayThought;

  /// Reference: under “Today’s thought”
  ///
  /// In en, this message translates to:
  /// **'A minute of perspective'**
  String get todayThoughtSub;

  /// Reference: the toast behind the Week link
  ///
  /// In en, this message translates to:
  /// **'Switched to week view'**
  String get todayWeekToast;

  /// Reference: the agenda section
  ///
  /// In en, this message translates to:
  /// **'Your day'**
  String get todayYourDay;

  /// Reference key cat.daily
  ///
  /// In en, this message translates to:
  /// **'Daily Life'**
  String get toolCategoryDaily;

  /// Reference key cat.everyday
  ///
  /// In en, this message translates to:
  /// **'Everyday'**
  String get toolCategoryEveryday;

  /// Reference key cat.islamic
  ///
  /// In en, this message translates to:
  /// **'Islamic'**
  String get toolCategoryIslamic;

  /// Reference key cat.money
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get toolCategoryMoney;

  /// Reference key cat.personal
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get toolCategoryPersonal;

  /// Reference key cat.planning
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get toolCategoryPlanning;

  /// Reference key cat.dailySub
  ///
  /// In en, this message translates to:
  /// **'What’s happening around you'**
  String get toolCategorySubDaily;

  /// Reference key cat.everydaySub
  ///
  /// In en, this message translates to:
  /// **'The ones you reach for daily'**
  String get toolCategorySubEveryday;

  /// Reference key cat.islamicSub
  ///
  /// In en, this message translates to:
  /// **'Prayer, Qur’an and giving'**
  String get toolCategorySubIslamic;

  /// Reference key cat.moneySub
  ///
  /// In en, this message translates to:
  /// **'Rates, bills and budgets'**
  String get toolCategorySubMoney;

  /// Reference key cat.personalSub
  ///
  /// In en, this message translates to:
  /// **'Private to you, on this device'**
  String get toolCategorySubPersonal;

  /// Reference key cat.planningSub
  ///
  /// In en, this message translates to:
  /// **'Your time and your lists'**
  String get toolCategorySubPlanning;

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

  /// Reference: aria-label on a country-restricted tool’s marker
  ///
  /// In en, this message translates to:
  /// **'Local service'**
  String get toolLocalService;

  /// Reference key n.needsAttention
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 needs attention} other{{n} need attention}}'**
  String toolNeedsAttention(int n);

  /// Reference: aria-label on a sensitive tool’s lock marker
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get toolPrivate;

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

  /// The status line on the age tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Exact days'**
  String get toolStatusAge;

  /// The status line on the alarms tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'2 set'**
  String get toolStatusAlarms;

  /// The status line on the aqi tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'AQI'**
  String get toolStatusAqi;

  /// The status line on the ayah tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Ar-Ra’d 28'**
  String get toolStatusAyah;

  /// The status line on the babybudget tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Plan costs'**
  String get toolStatusBabybudget;

  /// The status line on the bills tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'2 due'**
  String get toolStatusBills;

  /// The status line on the birthdays tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Ayesha in 4d'**
  String get toolStatusBirthdays;

  /// The status line on the bmi tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Track weight'**
  String get toolStatusBmi;

  /// The status line on the calculator tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get toolStatusCalculator;

  /// The status line on the calendar tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'3 events'**
  String get toolStatusCalendar;

  /// The status line on the committee tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Month 4 of 10'**
  String get toolStatusCommittee;

  /// The status line on the compound tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Project growth'**
  String get toolStatusCompound;

  /// The status line on the converter tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'32 units'**
  String get toolStatusConverter;

  /// The status line on the cricket tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'PAK 214/4'**
  String get toolStatusCricket;

  /// The status line on the currency tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Live rates'**
  String get toolStatusCurrency;

  /// The status line on the cycle tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get toolStatusCycle;

  /// The status line on the datecalc tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Add · diff'**
  String get toolStatusDatecalc;

  /// The status line on the docscan tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'PDF ready'**
  String get toolStatusDocscan;

  /// The status line on the documents tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get toolStatusDocuments;

  /// The status line on the duas tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'42 saved'**
  String get toolStatusDuas;

  /// The status line on the emergency tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'15 · 1122'**
  String get toolStatusEmergency;

  /// The status line on the events tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Next 14:00'**
  String get toolStatusEvents;

  /// The status line on the expenses tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get toolStatusExpenses;

  /// The status line on the faraid tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Inheritance'**
  String get toolStatusFaraid;

  /// The status line on the fasting tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'3 kept'**
  String get toolStatusFasting;

  /// The status line on the flights tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Track live'**
  String get toolStatusFlights;

  /// The status line on the focus tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'25 min'**
  String get toolStatusFocus;

  /// The status line on the fuel tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Pump prices'**
  String get toolStatusFuel;

  /// The status line on the fuelcost tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Trip cost'**
  String get toolStatusFuelcost;

  /// The status line on the goals tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'2 active'**
  String get toolStatusGoals;

  /// The status line on the goldrates tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Gold & FX'**
  String get toolStatusGoldrates;

  /// The status line on the habits tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'12-day streak'**
  String get toolStatusHabits;

  /// The status line on the hadith tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get toolStatusHadith;

  /// The status line on the health tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get toolStatusHealth;

  /// The status line on the hijri tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'15 Rabi’ I'**
  String get toolStatusHijri;

  /// The status line on the holidays tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get toolStatusHolidays;

  /// The status line on the installments tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'3 running'**
  String get toolStatusInstallments;

  /// The status line on the learning tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'3 courses'**
  String get toolStatusLearning;

  /// The status line on the ledger tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'3 people'**
  String get toolStatusLedger;

  /// The status line on the loadshed tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'14:00–16:00'**
  String get toolStatusLoadshed;

  /// The status line on the loan tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Instalments'**
  String get toolStatusLoan;

  /// The status line on the markets tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'KSE-100 ▲ 0.8%'**
  String get toolStatusMarkets;

  /// The status line on the mealplan tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get toolStatusMealplan;

  /// The status line on the mediasaver tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Save posts'**
  String get toolStatusMediasaver;

  /// The status line on the meds tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get toolStatusMeds;

  /// The status line on the mosques tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'3 within 1 km'**
  String get toolStatusMosques;

  /// The status line on the names99 tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Asma ul Husna'**
  String get toolStatusNames99;

  /// The status line on the natsavings tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Profit rates'**
  String get toolStatusNatsavings;

  /// The status line on the news tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'12 new'**
  String get toolStatusNews;

  /// The status line on the notes tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'12 saved'**
  String get toolStatusNotes;

  /// The status line on the packages tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Jazz · Zong'**
  String get toolStatusPackages;

  /// The status line on the parcel tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'1 in transit'**
  String get toolStatusParcel;

  /// The status line on the passport tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'NADRA sizes'**
  String get toolStatusPassport;

  /// The status line on the play tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Puzzles'**
  String get toolStatusPlay;

  /// The status line on the prayer tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Asr 15:53'**
  String get toolStatusPrayer;

  /// The status line on the praytrack tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'12-day streak'**
  String get toolStatusPraytrack;

  /// The status line on the pregnancy tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get toolStatusPregnancy;

  /// The status line on the prizebonds tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Draw 15 Sep'**
  String get toolStatusPrizebonds;

  /// The status line on the qibla tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'267° W'**
  String get toolStatusQibla;

  /// The status line on the qr tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Scan & pay'**
  String get toolStatusQr;

  /// The status line on the quran tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Al-Kahf 42'**
  String get toolStatusQuran;

  /// The status line on the quransearch tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'By word'**
  String get toolStatusQuransearch;

  /// The status line on the ramadan tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'In 172 days'**
  String get toolStatusRamadan;

  /// The status line on the recipes tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'24 saved'**
  String get toolStatusRecipes;

  /// The status line on the reminders tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'4 today'**
  String get toolStatusReminders;

  /// The status line on the shopping tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'6 items'**
  String get toolStatusShopping;

  /// The status line on the speedtest tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Test now'**
  String get toolStatusSpeedtest;

  /// The status line on the stopwatch tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Laps'**
  String get toolStatusStopwatch;

  /// The status line on the streak tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'12 days'**
  String get toolStatusStreak;

  /// The status line on the subs tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'6 active'**
  String get toolStatusSubs;

  /// The status line on the sunmoon tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Sunrise · sunset'**
  String get toolStatusSunmoon;

  /// The status line on the taraweeh tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get toolStatusTaraweeh;

  /// The status line on the tasbih tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get toolStatusTasbih;

  /// The status line on the tax tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'FBR 2025-26'**
  String get toolStatusTax;

  /// The status line on the timer tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get toolStatusTimer;

  /// The status line on the tipsplit tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Split a bill'**
  String get toolStatusTipsplit;

  /// The status line on the todos tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'2 of 5 done'**
  String get toolStatusTodos;

  /// The status line on the trains tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Green Line'**
  String get toolStatusTrains;

  /// The status line on the vaccines tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get toolStatusVaccines;

  /// The status line on the vehicle tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Check challan'**
  String get toolStatusVehicle;

  /// The status line on the wastatus tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get toolStatusWastatus;

  /// The status line on the water tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'5 / 8'**
  String get toolStatusWater;

  /// The status line on the weather tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'34° Clear'**
  String get toolStatusWeather;

  /// The status line on the worldclock tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'8 cities'**
  String get toolStatusWorldclock;

  /// The status line on the zakat tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'Nisab check'**
  String get toolStatusZakat;

  /// The honest unavailable state for a tool this market has not launched
  ///
  /// In en, this message translates to:
  /// **'Not available in {country} yet'**
  String toolUnavailableHere(String country);

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

  /// Reference key tools.forYou
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get toolsForYou;

  /// Reference key tools.noMatch
  ///
  /// In en, this message translates to:
  /// **'No tools match'**
  String get toolsNoMatch;

  /// Reference key tools.noMatchSub
  ///
  /// In en, this message translates to:
  /// **'Try a different word — or browse a category above.'**
  String get toolsNoMatchSub;

  /// Reference key tools.nothingYet
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get toolsNothingYet;

  /// Reference key tools.nothingYetSub
  ///
  /// In en, this message translates to:
  /// **'Add a few more interests, or browse the full list under All.'**
  String get toolsNothingYetSub;

  /// Reference: aria-label on the hub’s header control
  ///
  /// In en, this message translates to:
  /// **'Personalise'**
  String get toolsPersonalise;

  /// Reference key tools.recent
  ///
  /// In en, this message translates to:
  /// **'Recently used'**
  String get toolsRecent;

  /// Reference key tools.recentSub
  ///
  /// In en, this message translates to:
  /// **'Straight back to where you were'**
  String get toolsRecentSub;

  /// Announced after a search so the result count is spoken
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No tools} =1{1 tool} other{{n} tools}}'**
  String toolsResultCount(int n);

  /// The example in the hub’s placeholder everywhere else
  ///
  /// In en, this message translates to:
  /// **'currency'**
  String get toolsSearchExample;

  /// The example in the hub’s placeholder for a market with fuel prices
  ///
  /// In en, this message translates to:
  /// **'petrol'**
  String get toolsSearchExamplePk;

  /// Reference key tools.searchPlaceholder
  ///
  /// In en, this message translates to:
  /// **'Search tools — try “{example}”'**
  String toolsSearchHint(String example);

  /// Reference: aria-label on the hub’s search field
  ///
  /// In en, this message translates to:
  /// **'Search tools'**
  String get toolsSearchLabel;

  /// Reference key tools.sub
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 utility, neatly sorted} other{{n} utilities, neatly sorted}}'**
  String toolsSub(int n);

  /// Reference key tools.title
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsTitle;

  /// Reference: a statistic’s unit
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get unitDays;

  /// Reference: a wind speed unit
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get unitKmh;

  /// Reference: a statistic’s unit
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get unitMinutes;

  /// Reference: a wind speed unit
  ///
  /// In en, this message translates to:
  /// **'mph'**
  String get unitMph;

  /// Reference: the denominator of a ratio statistic
  ///
  /// In en, this message translates to:
  /// **'/{total}'**
  String unitOfTotal(int total);

  /// Reference: a statistic’s unit
  ///
  /// In en, this message translates to:
  /// **'k'**
  String get unitThousand;

  /// A weather condition. The prototype stores these as English sentences in the catalogue and never translates them
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherClear;

  /// Reference: WEATHER_BY_COUNTRY.AE
  ///
  /// In en, this message translates to:
  /// **'Clear · very warm'**
  String get weatherClearVeryWarm;

  /// A weather condition. The prototype stores these as English sentences in the catalogue and never translates them
  ///
  /// In en, this message translates to:
  /// **'Cloud building'**
  String get weatherCloudBuilding;

  /// A weather condition. The prototype stores these as English sentences in the catalogue and never translates them
  ///
  /// In en, this message translates to:
  /// **'hazy'**
  String get weatherHazy;

  /// A weather condition. The prototype stores these as English sentences in the catalogue and never translates them
  ///
  /// In en, this message translates to:
  /// **'Hazy sun'**
  String get weatherHazySun;

  /// Reference: WEATHER_BY_COUNTRY.PK
  ///
  /// In en, this message translates to:
  /// **'Hazy sun · humid'**
  String get weatherHazySunHumid;

  /// Reference: the livecard sub line
  ///
  /// In en, this message translates to:
  /// **'{high} / {low}'**
  String weatherHighLow(String high, String low);

  /// Reference: WEATHER_BY_COUNTRY.IN
  ///
  /// In en, this message translates to:
  /// **'Humid · light haze'**
  String get weatherHumidLightHaze;

  /// A weather condition. The prototype stores these as English sentences in the catalogue and never translates them
  ///
  /// In en, this message translates to:
  /// **'Light cloud'**
  String get weatherLightCloud;

  /// A weather condition. The prototype stores these as English sentences in the catalogue and never translates them
  ///
  /// In en, this message translates to:
  /// **'Mostly clear'**
  String get weatherMostlyClear;

  /// A weather condition. The prototype stores these as English sentences in the catalogue and never translates them
  ///
  /// In en, this message translates to:
  /// **'Overcast'**
  String get weatherOvercast;

  /// Reference key weather.rain
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;
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

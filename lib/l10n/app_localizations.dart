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

  /// Reference key a11y.export — the tool header export action
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get a11yExport;

  /// Reference key a11y.favourite — the tool header favourite action. The reference has no Urdu or Arabic for it; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Save to favourites'**
  String get a11yFavourite;

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

  /// Reference key a11y.search — the tool header search action, in the reference's own Urdu and Arabic
  ///
  /// In en, this message translates to:
  /// **'Search this tool'**
  String get a11ySearchTool;

  /// Reference key a11y.share
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get a11yShare;

  /// Reference: `acct.aboutText`.
  ///
  /// In en, this message translates to:
  /// **'A global daily-life super-app. Built to work anywhere, in your language, with the parts of it you asked for.'**
  String get acctAboutText;

  /// Reference: `acct.aboutTitle`.
  ///
  /// In en, this message translates to:
  /// **'About Lume'**
  String get acctAboutTitle;

  /// Reference: `acct.appearanceDark`.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get acctAppearanceDark;

  /// Reference: `acct.appearanceLight`.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get acctAppearanceLight;

  /// Reference: `acct.appearanceSystem`.
  ///
  /// In en, this message translates to:
  /// **'Follow the system'**
  String get acctAppearanceSystem;

  /// Reference: `acct.appearanceTitle`.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get acctAppearanceTitle;

  /// Reference: `acct.build`.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get acctBuild;

  /// Reference: `acct.catsOn`.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total} on'**
  String acctCatsOn(int n, int total);

  /// Reference: `acct.changePassword`.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get acctChangePassword;

  /// Reference: `acct.changePasswordSub`.
  ///
  /// In en, this message translates to:
  /// **'Last changed is not recorded on this device'**
  String get acctChangePasswordSub;

  /// Reference: `acct.clock12`.
  ///
  /// In en, this message translates to:
  /// **'12-hour'**
  String get acctClock12;

  /// Reference: `acct.clock24`.
  ///
  /// In en, this message translates to:
  /// **'24-hour'**
  String get acctClock24;

  /// Reference: `acct.clockFormat`.
  ///
  /// In en, this message translates to:
  /// **'Clock'**
  String get acctClockFormat;

  /// Reference: `acct.completeCta`.
  ///
  /// In en, this message translates to:
  /// **'Add your name'**
  String get acctCompleteCta;

  /// Reference: `acct.completeText`.
  ///
  /// In en, this message translates to:
  /// **'Add your name so Lume can greet you properly.'**
  String get acctCompleteText;

  /// Reference: `acct.completeTitle`.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get acctCompleteTitle;

  /// Reference: `acct.currencyAuto`.
  ///
  /// In en, this message translates to:
  /// **'Follow my region'**
  String get acctCurrencyAuto;

  /// Reference: `acct.currencyNote`.
  ///
  /// In en, this message translates to:
  /// **'Some tools quote their own market’s currency regardless.'**
  String get acctCurrencyNote;

  /// Reference: `acct.currencyTitle`.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get acctCurrencyTitle;

  /// Reference: `acct.dangerZone`.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get acctDangerZone;

  /// Reference: `acct.data.account`.
  ///
  /// In en, this message translates to:
  /// **'Your account and sessions'**
  String get acctDataAccount;

  /// Reference: `acct.data.notes`.
  ///
  /// In en, this message translates to:
  /// **'Notes, tasks, expenses and trackers'**
  String get acctDataNotes;

  /// Reference: `acct.data.notify`.
  ///
  /// In en, this message translates to:
  /// **'Notification settings and history'**
  String get acctDataNotify;

  /// Reference: `acct.data.prefs`.
  ///
  /// In en, this message translates to:
  /// **'Preferences, region and language'**
  String get acctDataPrefs;

  /// About, parity and development builds only: the data is fixtures
  ///
  /// In en, this message translates to:
  /// **'Sample data — nothing is saved, synced or encrypted in this build'**
  String get acctDataSample;

  /// About: the row saying what this build’s data is
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get acctDataTitle;

  /// Reference: `acct.data.tools`.
  ///
  /// In en, this message translates to:
  /// **'Tools, favourites and recent screens'**
  String get acctDataTools;

  /// Reference: `acct.deleteConfirmText`.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to delete the account.'**
  String get acctDeleteConfirmText;

  /// Reference: `acct.deleteConfirmTitle`.
  ///
  /// In en, this message translates to:
  /// **'Confirm it’s you'**
  String get acctDeleteConfirmTitle;

  /// Reference: `acct.deleteCta`.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get acctDeleteCta;

  /// Reference: `acct.deleteFinalText`.
  ///
  /// In en, this message translates to:
  /// **'This removes the account for good. There is no way back.'**
  String get acctDeleteFinalText;

  /// Reference: `acct.deleteFinalTitle`.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get acctDeleteFinalTitle;

  /// Reference: `acct.deleteK1`.
  ///
  /// In en, this message translates to:
  /// **'Notes, tasks, expenses and preferences remain on this device.'**
  String get acctDeleteK1;

  /// Reference: `acct.deleteKeeps`.
  ///
  /// In en, this message translates to:
  /// **'What stays'**
  String get acctDeleteKeeps;

  /// Reference: `acct.deleteRow`.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get acctDeleteRow;

  /// Reference: `acct.deleteRowSub`.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your Lume account'**
  String get acctDeleteRowSub;

  /// Reference: `acct.deleteTitle`.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get acctDeleteTitle;

  /// Reference: `acct.deleteW1`.
  ///
  /// In en, this message translates to:
  /// **'Your account and email are removed.'**
  String get acctDeleteW1;

  /// Reference: `acct.deleteW2`.
  ///
  /// In en, this message translates to:
  /// **'Every signed-in device is signed out.'**
  String get acctDeleteW2;

  /// Reference: `acct.deleteW3`.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get acctDeleteW3;

  /// Reference: `acct.deleteWhat`.
  ///
  /// In en, this message translates to:
  /// **'What this does'**
  String get acctDeleteWhat;

  /// Reference: `acct.deleted`.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get acctDeleted;

  /// Reference: `acct.device.android`.
  ///
  /// In en, this message translates to:
  /// **'Android phone'**
  String get acctDeviceAndroid;

  /// The platform a session was opened from, beside `acctDeviceAndroid`, `acctDeviceIos`, `acctDeviceMac` and `acctDeviceWindows`. The reference said "This browser" because the reference *was* the browser; here it names one platform among five, and never the reader’s own device.
  ///
  /// In en, this message translates to:
  /// **'Web browser'**
  String get acctDeviceBrowser;

  /// Reference: `acct.device.ios`.
  ///
  /// In en, this message translates to:
  /// **'iPhone'**
  String get acctDeviceIos;

  /// Reference: `acct.device.mac`.
  ///
  /// In en, this message translates to:
  /// **'Mac'**
  String get acctDeviceMac;

  /// Reference: `acct.device.windows`.
  ///
  /// In en, this message translates to:
  /// **'Windows PC'**
  String get acctDeviceWindows;

  /// Reference: `acct.discardCta`.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get acctDiscardCta;

  /// Reference: `acct.discardText`.
  ///
  /// In en, this message translates to:
  /// **'You’ve edited this screen without saving. Leaving now loses those edits.'**
  String get acctDiscardText;

  /// Reference: `acct.discardTitle`.
  ///
  /// In en, this message translates to:
  /// **'Discard your changes?'**
  String get acctDiscardTitle;

  /// Reference: `acct.editProfile`.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get acctEditProfile;

  /// Reference: `acct.editSaved`.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get acctEditSaved;

  /// Reference: `acct.editTitle`.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get acctEditTitle;

  /// Reference: `acct.emailChanged`.
  ///
  /// In en, this message translates to:
  /// **'Email updated'**
  String get acctEmailChanged;

  /// Reference: `acct.emailPending`.
  ///
  /// In en, this message translates to:
  /// **'Pending verification'**
  String get acctEmailPending;

  /// Reference: `acct.emailPendingText`.
  ///
  /// In en, this message translates to:
  /// **'{email} becomes your address once you verify it.'**
  String acctEmailPendingText(String email);

  /// Reference: `acct.emailTitle`.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get acctEmailTitle;

  /// Reference: `acct.err.currentRequired`.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password.'**
  String get acctErrCurrentRequired;

  /// Reference: `acct.err.currentWrong`.
  ///
  /// In en, this message translates to:
  /// **'That current password is incorrect.'**
  String get acctErrCurrentWrong;

  /// A name refusal. No fixture returns it — `updateUser` in `account.js` accepts a blank name — but `LumeAccountFailure.nameRequired` is part of the repository contract a real service may use, and a contract value with no sentence would render the network error instead.
  ///
  /// In en, this message translates to:
  /// **'Enter a name, or leave it blank to use your email address.'**
  String get acctErrNameRequired;

  /// Reference: `acct.err.passwordSame`.
  ///
  /// In en, this message translates to:
  /// **'Choose a password you haven’t used here before.'**
  String get acctErrPasswordSame;

  /// Reference: `acct.err.phoneInvalid`.
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number Lume can read.'**
  String get acctErrPhoneInvalid;

  /// Reference: `acct.err.photoTooBig`.
  ///
  /// In en, this message translates to:
  /// **'That image is too large for this device to keep. Try a smaller one.'**
  String get acctErrPhotoTooBig;

  /// Reference: `acct.err.storage`. The prototype says "check your browser’s storage settings", which is advice a phone cannot act on. C49.
  ///
  /// In en, this message translates to:
  /// **'Lume couldn’t save to this device. Check that there is space free and try again.'**
  String get acctErrStorage;

  /// Reference: `acct.favourites`.
  ///
  /// In en, this message translates to:
  /// **'Your favourites'**
  String get acctFavourites;

  /// Reference: `acct.f.confirmNew`.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get acctFieldConfirmNew;

  /// Reference: `acct.f.current`.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get acctFieldCurrent;

  /// Reference: `acct.f.displayName`.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get acctFieldDisplayName;

  /// Reference: `acct.f.first`.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get acctFieldFirst;

  /// Reference: `acct.f.last`.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get acctFieldLast;

  /// Reference: `acct.f.newEmail`.
  ///
  /// In en, this message translates to:
  /// **'New email address'**
  String get acctFieldNewEmail;

  /// Reference: `acct.f.phone`.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get acctFieldPhone;

  /// Reference: `acct.guestBadge`.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get acctGuestBadge;

  /// Reference: `acct.guestEditNote`.
  ///
  /// In en, this message translates to:
  /// **'This name is kept on this device. Creating an account brings it with you.'**
  String get acctGuestEditNote;

  /// Reference: `acct.guestNotifText`.
  ///
  /// In en, this message translates to:
  /// **'Alerts belong to this device while you’re a guest. Signing in never shows you another account’s notifications.'**
  String get acctGuestNotifText;

  /// Reference: `acct.guestNotifTitle`.
  ///
  /// In en, this message translates to:
  /// **'Notifications on this device'**
  String get acctGuestNotifTitle;

  /// Reference: `acct.guestText`.
  ///
  /// In en, this message translates to:
  /// **'You’re using Lume as a guest. Everything you’ve set up is saved on this device.'**
  String get acctGuestText;

  /// Reference: `acct.guestTitle`.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Lume'**
  String get acctGuestTitle;

  /// Reference: `acct.guestWhy`.
  ///
  /// In en, this message translates to:
  /// **'Create an account to'**
  String get acctGuestWhy;

  /// Reference: `acct.guestWhy1`.
  ///
  /// In en, this message translates to:
  /// **'keep your Lume across devices'**
  String get acctGuestWhy1;

  /// Reference: `acct.guestWhy2`.
  ///
  /// In en, this message translates to:
  /// **'recover your settings if you lose this phone'**
  String get acctGuestWhy2;

  /// Reference: `acct.guestWhy3`.
  ///
  /// In en, this message translates to:
  /// **'use account-based features as they arrive'**
  String get acctGuestWhy3;

  /// Reference: `acct.helpContact`.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get acctHelpContact;

  /// Reference: `acct.helpText`.
  ///
  /// In en, this message translates to:
  /// **'Lume is a single-screen product: everything is one or two taps from Home.'**
  String get acctHelpText;

  /// Reference: `acct.helpTitle`.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get acctHelpTitle;

  /// Reference: `acct.helpTour`.
  ///
  /// In en, this message translates to:
  /// **'Replay the welcome tour'**
  String get acctHelpTour;

  /// Reference: `acct.languageNote`.
  ///
  /// In en, this message translates to:
  /// **'Changing the language never changes anything you wrote.'**
  String get acctLanguageNote;

  /// Reference: `acct.languageTitle`.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get acctLanguageTitle;

  /// Reference: `acct.lastSeen`.
  ///
  /// In en, this message translates to:
  /// **'Last seen {when}'**
  String acctLastSeen(String when);

  /// Reference: `acct.loggedOut`.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get acctLoggedOut;

  /// Reference: `acct.logoutText`.
  ///
  /// In en, this message translates to:
  /// **'You’ll need to sign in again to reach your account. Everything on this device stays where it is.'**
  String get acctLogoutText;

  /// Reference: `acct.logoutTitle`.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get acctLogoutTitle;

  /// Reference: `acct.memberSince`.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String acctMemberSince(String date);

  /// Reference: `acct.nameNote`.
  ///
  /// In en, this message translates to:
  /// **'This is the name Lume greets you with.'**
  String get acctNameNote;

  /// Reference: `acct.noFavourites`.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get acctNoFavourites;

  /// Reference: `acct.noFavouritesText`.
  ///
  /// In en, this message translates to:
  /// **'Tap the star on any tool and it lands here.'**
  String get acctNoFavouritesText;

  /// Reference: `acct.noOtherDevices`.
  ///
  /// In en, this message translates to:
  /// **'No other devices are signed in.'**
  String get acctNoOtherDevices;

  /// Reference: `acct.nothingChanged`.
  ///
  /// In en, this message translates to:
  /// **'Nothing to save yet'**
  String get acctNothingChanged;

  /// Reference: `acct.personalTitle`.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get acctPersonalTitle;

  /// Reference: `acct.phoneNote`.
  ///
  /// In en, this message translates to:
  /// **'Optional. Stored on this device.'**
  String get acctPhoneNote;

  /// Reference: `acct.phoneSaved`.
  ///
  /// In en, this message translates to:
  /// **'Phone number saved'**
  String get acctPhoneSaved;

  /// Reference: `acct.phoneScope`.
  ///
  /// In en, this message translates to:
  /// **'What this is for'**
  String get acctPhoneScope;

  /// Reference: `acct.phoneScopeText`.
  ///
  /// In en, this message translates to:
  /// **'Kept on this device so a tool can offer it. Lume has no phone sign-in or phone recovery, so it does nothing else.'**
  String get acctPhoneScopeText;

  /// Reference: `acct.phoneTitle`.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get acctPhoneTitle;

  /// Reference: `acct.photo`.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get acctPhoto;

  /// Reference: `acct.photoAdd`.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get acctPhotoAdd;

  /// Reference: `acct.photoNote`.
  ///
  /// In en, this message translates to:
  /// **'Optional. Stored on this device.'**
  String get acctPhotoNote;

  /// Reference: `acct.photoRemove`.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get acctPhotoRemove;

  /// Reference: `acct.photoReplace`.
  ///
  /// In en, this message translates to:
  /// **'Replace photo'**
  String get acctPhotoReplace;

  /// Reference: `acct.prefsTitle`.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get acctPrefsTitle;

  /// Reference: `acct.privacyAnalytics`.
  ///
  /// In en, this message translates to:
  /// **'Usage analytics'**
  String get acctPrivacyAnalytics;

  /// Reference: `acct.privacyAnalyticsSub`.
  ///
  /// In en, this message translates to:
  /// **'Lume collects none. There is nothing to turn off.'**
  String get acctPrivacyAnalyticsSub;

  /// Reference: `acct.privacyPersonal`.
  ///
  /// In en, this message translates to:
  /// **'Personalisation'**
  String get acctPrivacyPersonal;

  /// Reference: `acct.privacyPersonalSub`.
  ///
  /// In en, this message translates to:
  /// **'Use what you do in Lume to order what you see'**
  String get acctPrivacyPersonalSub;

  /// Reference: `acct.privacyPreview`.
  ///
  /// In en, this message translates to:
  /// **'Notification previews'**
  String get acctPrivacyPreview;

  /// Reference: `acct.privacyPreviewSub`.
  ///
  /// In en, this message translates to:
  /// **'Show the content of an alert on the lock screen'**
  String get acctPrivacyPreviewSub;

  /// Reference: `acct.privacySensitive`.
  ///
  /// In en, this message translates to:
  /// **'Sensitive content in previews'**
  String get acctPrivacySensitive;

  /// Reference: `acct.privacySensitiveSub`.
  ///
  /// In en, this message translates to:
  /// **'Health, money and documents stay hidden until opened'**
  String get acctPrivacySensitiveSub;

  /// Reference: `acct.privacyTitle`.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get acctPrivacyTitle;

  /// Reference: `n.push.ask`.
  ///
  /// In en, this message translates to:
  /// **'Not asked yet'**
  String get acctPushAsk;

  /// Reference: `n.push.denied`. Reworded in F5C: the reference is a web page and said "browser", which is a claim a Flutter build cannot make (C49).
  ///
  /// In en, this message translates to:
  /// **'Blocked in your device settings'**
  String get acctPushDenied;

  /// Reference: `n.push.deniedHelp`. Reworded in F5C: the reference is a web page and said "browser", which is a claim a Flutter build cannot make (C49).
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked. Allow them for Lume in your device settings.'**
  String get acctPushDeniedHelp;

  /// Reference: `n.push.granted`. Reworded in F5C: the reference is a web page and said "browser", which is a claim a Flutter build cannot make (C49).
  ///
  /// In en, this message translates to:
  /// **'Allowed on this device'**
  String get acctPushGranted;

  /// Reference: `n.push.off`.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get acctPushOff;

  /// Reference: `n.push.on`.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get acctPushOn;

  /// Reference: `n.push.thanks`.
  ///
  /// In en, this message translates to:
  /// **'Notifications are on'**
  String get acctPushThanks;

  /// Reference: `n.push.unsupported`.
  ///
  /// In en, this message translates to:
  /// **'This device can’t show push notifications'**
  String get acctPushUnsupported;

  /// Reference: `acct.pw.strengthLabel`.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get acctPwStrengthLabel;

  /// Reference: `acct.regionChange`.
  ///
  /// In en, this message translates to:
  /// **'Change country or city'**
  String get acctRegionChange;

  /// Reference: `acct.regionTitle`.
  ///
  /// In en, this message translates to:
  /// **'Region & currency'**
  String get acctRegionTitle;

  /// Reference: `acct.regionWarn`.
  ///
  /// In en, this message translates to:
  /// **'Changing your region may update your currency, markets, holidays, emergency numbers and local services.'**
  String get acctRegionWarn;

  /// Reference: `acct.row.about`.
  ///
  /// In en, this message translates to:
  /// **'About Lume'**
  String get acctRowAbout;

  /// Reference: `acct.row.aboutSub`.
  ///
  /// In en, this message translates to:
  /// **'Version, licences and credits'**
  String get acctRowAboutSub;

  /// Reference: `acct.row.appearance`.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get acctRowAppearance;

  /// Reference: `acct.row.appearanceSub`.
  ///
  /// In en, this message translates to:
  /// **'Light, dark or follow your system'**
  String get acctRowAppearanceSub;

  /// Reference: `acct.row.help`.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get acctRowHelp;

  /// Reference: `acct.row.helpSub`.
  ///
  /// In en, this message translates to:
  /// **'Answers, and a way to reach us'**
  String get acctRowHelpSub;

  /// Reference: `acct.row.interests`.
  ///
  /// In en, this message translates to:
  /// **'Your interests'**
  String get acctRowInterests;

  /// Reference: `acct.row.interestsSub`.
  ///
  /// In en, this message translates to:
  /// **'Shapes your home, tools and reading'**
  String get acctRowInterestsSub;

  /// Reference: `acct.row.language`.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get acctRowLanguage;

  /// Reference: `acct.row.library`.
  ///
  /// In en, this message translates to:
  /// **'Your library'**
  String get acctRowLibrary;

  /// Reference: `acct.row.librarySub`.
  ///
  /// In en, this message translates to:
  /// **'Saved reads, notes and favourites'**
  String get acctRowLibrarySub;

  /// Reference: `acct.row.notificationsSub`.
  ///
  /// In en, this message translates to:
  /// **'Push alerts, in-app updates and quiet hours'**
  String get acctRowNotificationsSub;

  /// Reference: `acct.row.personal`.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get acctRowPersonal;

  /// Reference: `acct.row.personalSub`.
  ///
  /// In en, this message translates to:
  /// **'Name, email, phone and region'**
  String get acctRowPersonalSub;

  /// Reference: `acct.row.preferences`.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get acctRowPreferences;

  /// Reference: `acct.row.preferencesSub`.
  ///
  /// In en, this message translates to:
  /// **'Language, currency, units and time'**
  String get acctRowPreferencesSub;

  /// Reference: `acct.row.privacy`.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get acctRowPrivacy;

  /// Reference: `acct.row.privacySub`.
  ///
  /// In en, this message translates to:
  /// **'What Lume shows, keeps and shares'**
  String get acctRowPrivacySub;

  /// Reference: `acct.row.region`.
  ///
  /// In en, this message translates to:
  /// **'Region & currency'**
  String get acctRowRegion;

  /// Reference: `acct.row.regionSub`.
  ///
  /// In en, this message translates to:
  /// **'Country, city and the services that follow them'**
  String get acctRowRegionSub;

  /// Reference: `acct.row.security`.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get acctRowSecurity;

  /// Reference: `acct.row.securitySub`.
  ///
  /// In en, this message translates to:
  /// **'Password, sessions and account protection'**
  String get acctRowSecuritySub;

  /// Reference: `acct.row.sync`.
  ///
  /// In en, this message translates to:
  /// **'Data & sync'**
  String get acctRowSync;

  /// Reference: `acct.row.syncSub`.
  ///
  /// In en, this message translates to:
  /// **'Where each part of your Lume is stored'**
  String get acctRowSyncSub;

  /// Reference: `acct.row.tour`.
  ///
  /// In en, this message translates to:
  /// **'Replay the welcome tour'**
  String get acctRowTour;

  /// Reference: `acct.row.tourSub`.
  ///
  /// In en, this message translates to:
  /// **'A quick reminder of what’s here'**
  String get acctRowTourSub;

  /// Reference: `acct.saveChanges`.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get acctSaveChanges;

  /// Reference: `acct.securityScope`.
  ///
  /// In en, this message translates to:
  /// **'What Lume protects'**
  String get acctSecurityScope;

  /// Reference: `acct.securityScopeText`.
  ///
  /// In en, this message translates to:
  /// **'Your password and your signed-in devices. There is no two-factor or biometric unlock in this build, so nothing here claims otherwise.'**
  String get acctSecurityScopeText;

  /// Reference: `acct.securityTitle`.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get acctSecurityTitle;

  /// Reference: `acct.sessionsSub`.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 signed in} other{{n} signed in}}'**
  String acctSessionsSub(int n);

  /// Reference: `acct.sessionsTitle`.
  ///
  /// In en, this message translates to:
  /// **'Active sessions'**
  String get acctSessionsTitle;

  /// Reference: `acct.signOut`.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get acctSignOut;

  /// Reference: `acct.signOutDevice`.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get acctSignOutDevice;

  /// Reference: `acct.signOutOthers`.
  ///
  /// In en, this message translates to:
  /// **'Sign out all other devices'**
  String get acctSignOutOthers;

  /// Reference: `acct.signOutOthersText`.
  ///
  /// In en, this message translates to:
  /// **'Every other signed-in device will need to sign in again.'**
  String get acctSignOutOthersText;

  /// Reference: `acct.signedInAs`.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String acctSignedInAs(String email);

  /// Reference: `acct.signedOutOthers`.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Signed out 1 other device} other{Signed out {n} other devices}}'**
  String acctSignedOutOthers(int n);

  /// Reference: `acct.since`.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get acctSince;

  /// Reference: `acct.status`.
  ///
  /// In en, this message translates to:
  /// **'Account status'**
  String get acctStatus;

  /// Reference: `acct.statusActive`.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get acctStatusActive;

  /// Reference: `acct.statusLocked`.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get acctStatusLocked;

  /// Reference: `acct.support`.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get acctSupport;

  /// Reference: `acct.syncDevice`.
  ///
  /// In en, this message translates to:
  /// **'Stored on this device'**
  String get acctSyncDevice;

  /// Reference: `acct.syncNone`.
  ///
  /// In en, this message translates to:
  /// **'Nothing syncs yet. Lume has no server in this build, so everything above stays on this device — including your account.'**
  String get acctSyncNone;

  /// Reference: `acct.syncSynced`.
  ///
  /// In en, this message translates to:
  /// **'Synced to your account'**
  String get acctSyncSynced;

  /// Reference: `acct.syncTitle`.
  ///
  /// In en, this message translates to:
  /// **'Data & sync'**
  String get acctSyncTitle;

  /// Reference: `acct.themeSwitched`.
  ///
  /// In en, this message translates to:
  /// **'Appearance: {mode}'**
  String acctThemeSwitched(String mode);

  /// Reference: `acct.thisDevice`.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get acctThisDevice;

  /// Reference: `acct.timeTitle`.
  ///
  /// In en, this message translates to:
  /// **'Time & timezone'**
  String get acctTimeTitle;

  /// Reference: `acct.timezoneAuto`.
  ///
  /// In en, this message translates to:
  /// **'Follow this device'**
  String get acctTimezoneAuto;

  /// Follow my region, where the region has several time zones and the city does not decide
  ///
  /// In en, this message translates to:
  /// **'Choose a time zone'**
  String get acctTimezoneChoose;

  /// Time zone preference: the device’s own zone
  ///
  /// In en, this message translates to:
  /// **'Follow this device'**
  String get acctTimezoneFollowDevice;

  /// Reference: `acct.timezoneFollowRegion`.
  ///
  /// In en, this message translates to:
  /// **'Follow my region'**
  String get acctTimezoneFollowRegion;

  /// Follow this device, where the build cannot read the device’s zone
  ///
  /// In en, this message translates to:
  /// **'This device’s time zone isn’t available'**
  String get acctTimezoneNoDevice;

  /// Reference: `acct.timezoneNote`.
  ///
  /// In en, this message translates to:
  /// **'Markets, flights and trains always use their own timezone.'**
  String get acctTimezoneNote;

  /// Reference: `acct.timezoneTitle`.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get acctTimezoneTitle;

  /// Reference: `acct.unitsAuto`.
  ///
  /// In en, this message translates to:
  /// **'Follow my region'**
  String get acctUnitsAuto;

  /// Reference: `acct.unitsImperial`.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get acctUnitsImperial;

  /// Reference: `acct.unitsMetric`.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get acctUnitsMetric;

  /// Reference: `acct.unitsTitle`.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get acctUnitsTitle;

  /// Reference: `acct.version`.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get acctVersion;

  /// Reference: `acct.yourLume`.
  ///
  /// In en, this message translates to:
  /// **'Your Lume'**
  String get acctYourLume;

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

  /// Reference: `a.change`.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get actionChange;

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

  /// Reference: `a.confirm`.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

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

  /// Reference: `a.resend`.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get actionResend;

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

  /// Reference: `a.verify`.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get actionVerify;

  /// Reference key a.week
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get actionWeek;

  /// Days in an exact age
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day} other{{n} days}}'**
  String ageDaysCount(int n);

  /// Reference key age.days
  ///
  /// In en, this message translates to:
  /// **'Days lived'**
  String get ageDaysLived;

  /// Reference key age.dob
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get ageDob;

  /// Reference key age.exact, composed from the two counts so each has its own singular
  ///
  /// In en, this message translates to:
  /// **'{months} and {days}'**
  String ageExact(String months, String days);

  /// Under a date of birth after today; the age is not worked out from it
  ///
  /// In en, this message translates to:
  /// **'That date hasn’t happened yet'**
  String get ageFuture;

  /// Reference key age.hours
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get ageHours;

  /// Reference key age.milestone
  ///
  /// In en, this message translates to:
  /// **'{n} days old'**
  String ageMilestone(String n);

  /// Reference key age.milestones
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get ageMilestones;

  /// Months in an exact age
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 month} other{{n} months}}'**
  String ageMonthsCount(int n);

  /// Reference key age.nextBirthday
  ///
  /// In en, this message translates to:
  /// **'Next birthday'**
  String get ageNextBirthday;

  /// Days to the next birthday; the reference says "in 0 days" on the day itself
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{today} =1{in 1 day} other{in {count} days}}'**
  String ageUntil(int n, String count);

  /// Reference key age.weeks
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get ageWeeks;

  /// The unit beside an age in whole years
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{year} other{years}}'**
  String ageYearsUnit(int n);

  /// Reference key age.youAre
  ///
  /// In en, this message translates to:
  /// **'You are'**
  String get ageYouAre;

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

  /// Reference key aqi.good.advice
  ///
  /// In en, this message translates to:
  /// **'Air quality is satisfactory.'**
  String get aqiGoodAdvice;

  /// Reference key aqi.good.label
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get aqiGoodLabel;

  /// Reference key aqi.hazardous.advice
  ///
  /// In en, this message translates to:
  /// **'Stay indoors and use filtration where possible.'**
  String get aqiHazardousAdvice;

  /// Reference key aqi.hazardous.label
  ///
  /// In en, this message translates to:
  /// **'Hazardous'**
  String get aqiHazardousLabel;

  /// Reference key aqi.moderate.advice
  ///
  /// In en, this message translates to:
  /// **'Unusually sensitive people should limit long outdoor exertion.'**
  String get aqiModerateAdvice;

  /// Reference key aqi.moderate.label
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get aqiModerateLabel;

  /// Reference key aqi.sensitive.advice
  ///
  /// In en, this message translates to:
  /// **'Children and people with asthma should limit outdoor exertion.'**
  String get aqiSensitiveAdvice;

  /// Reference key aqi.sensitive.label
  ///
  /// In en, this message translates to:
  /// **'Unhealthy for sensitive groups'**
  String get aqiSensitiveLabel;

  /// Reference key aqi.unhealthy.advice
  ///
  /// In en, this message translates to:
  /// **'Everyone should reduce prolonged outdoor exertion.'**
  String get aqiUnhealthyAdvice;

  /// Reference key aqi.unhealthy.label
  ///
  /// In en, this message translates to:
  /// **'Unhealthy'**
  String get aqiUnhealthyLabel;

  /// The index's abbreviation under its value — the reference writes it in every language
  ///
  /// In en, this message translates to:
  /// **'AQI'**
  String get aqiUnit;

  /// Reference key aqi.veryUnhealthy.advice
  ///
  /// In en, this message translates to:
  /// **'Avoid outdoor exertion. Keep windows closed.'**
  String get aqiVeryUnhealthyAdvice;

  /// Reference key aqi.veryUnhealthy.label
  ///
  /// In en, this message translates to:
  /// **'Very unhealthy'**
  String get aqiVeryUnhealthyLabel;

  /// Reference key archetype.action — the word in a tool header's sub-line
  ///
  /// In en, this message translates to:
  /// **'Emergency actions'**
  String get archetypeAction;

  /// Reference key archetype.calculator
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get archetypeCalculator;

  /// Reference key archetype.dashboard
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get archetypeDashboard;

  /// Reference key archetype.explorer
  ///
  /// In en, this message translates to:
  /// **'Data explorer'**
  String get archetypeExplorer;

  /// Reference key archetype.instrument
  ///
  /// In en, this message translates to:
  /// **'Instrument'**
  String get archetypeInstrument;

  /// Reference key archetype.library
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get archetypeLibrary;

  /// Reference key archetype.manager
  ///
  /// In en, this message translates to:
  /// **'Records manager'**
  String get archetypeManager;

  /// Reference key archetype.planner
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get archetypePlanner;

  /// Reference key archetype.reader
  ///
  /// In en, this message translates to:
  /// **'Reader'**
  String get archetypeReader;

  /// Reference key archetype.tracker
  ///
  /// In en, this message translates to:
  /// **'Tracker'**
  String get archetypeTracker;

  /// Reference key archetype.tracking
  ///
  /// In en, this message translates to:
  /// **'Live tracking'**
  String get archetypeTracking;

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

  /// Reference key calendar.add — the floating action's name, always announced (C71)
  ///
  /// In en, this message translates to:
  /// **'Add an event'**
  String get calendarAdd;

  /// Reference key calendar.agenda
  ///
  /// In en, this message translates to:
  /// **'Today’s agenda'**
  String get calendarAgenda;

  /// Reference key calendar.day
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get calendarDay;

  /// Reference key calendar.a3
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get calendarGroceries;

  /// Reference key calendar.a3s
  ///
  /// In en, this message translates to:
  /// **'On the way home'**
  String get calendarGroceriesWhere;

  /// Reference key calendar.holidays
  ///
  /// In en, this message translates to:
  /// **'Public holidays'**
  String get calendarHolidays;

  /// Reference key calendar.month
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get calendarMonth;

  /// Reference key calendar.a2
  ///
  /// In en, this message translates to:
  /// **'Design review'**
  String get calendarReview;

  /// Reference key calendar.a2s
  ///
  /// In en, this message translates to:
  /// **'Meeting room 2'**
  String get calendarReviewWhere;

  /// Reference key calendar.a1
  ///
  /// In en, this message translates to:
  /// **'Morning standup'**
  String get calendarStandup;

  /// Reference key calendar.a1s
  ///
  /// In en, this message translates to:
  /// **'Team call'**
  String get calendarStandupWhere;

  /// Reference key calendar.view — the segmented control's name
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get calendarView;

  /// Reference key calendar.week
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get calendarWeek;

  /// Camera page status when a barcode that is not a QR code is in view; scanning continues
  ///
  /// In en, this message translates to:
  /// **'That isn\'t a QR code. Lume reads QR codes.'**
  String get captureNotQr;

  /// Camera page status while the app is away or the page is covered; the camera is closed
  ///
  /// In en, this message translates to:
  /// **'Camera paused'**
  String get capturePaused;

  /// Camera page status while the camera starts, before any picture
  ///
  /// In en, this message translates to:
  /// **'Starting the camera…'**
  String get captureStarting;

  /// Title of the full-screen camera page
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code'**
  String get captureTitle;

  /// Reference key ccy.aed — a currency's name
  ///
  /// In en, this message translates to:
  /// **'UAE Dirham'**
  String get ccyAed;

  /// Reference key ccy.eur — a currency's name
  ///
  /// In en, this message translates to:
  /// **'Euro'**
  String get ccyEur;

  /// Reference key ccy.gbp — a currency's name
  ///
  /// In en, this message translates to:
  /// **'Pound Sterling'**
  String get ccyGbp;

  /// Reference key ccy.sar — a currency's name
  ///
  /// In en, this message translates to:
  /// **'Saudi Riyal'**
  String get ccySar;

  /// Reference key ccy.usd — a currency's name
  ///
  /// In en, this message translates to:
  /// **'US Dollar'**
  String get ccyUsd;

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

  /// Reference key common.amount — a sort option and an export column
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get commonAmount;

  /// Reference key common.change — a column head
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get commonChange;

  /// Reference key common.date — a sort option and an export column
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get commonDate;

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

  /// Reference key common.field — a table column head
  ///
  /// In en, this message translates to:
  /// **'Field'**
  String get commonField;

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

  /// Reference key common.less — a heatmap key
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get commonLess;

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

  /// Reference key common.more — a heatmap key
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// Reference key common.name — a form field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commonName;

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

  /// Reference: `a.or`.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get commonOr;

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

  /// Reference key common.saved — a badge on a saved item
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get commonSaved;

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

  /// Reference key common.start — a clock's primary action. The reference has no Urdu or Arabic for it; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get commonStart;

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

  /// Reference key common.value — a table column head
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get commonValue;

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

  /// Reference key compound.after
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{after 1 year} other{after {count} years}}'**
  String compoundAfter(int n, String count);

  /// A projection axis label; the reference writes a literal English "y"
  ///
  /// In en, this message translates to:
  /// **'{count}y'**
  String compoundAxisYears(String count);

  /// Reference key compound.byYear
  ///
  /// In en, this message translates to:
  /// **'Year by year'**
  String get compoundByYear;

  /// Reference key compound.contributed
  ///
  /// In en, this message translates to:
  /// **'Contributed'**
  String get compoundContributed;

  /// Reference key compound.finalValue
  ///
  /// In en, this message translates to:
  /// **'Projected value'**
  String get compoundFinalValue;

  /// Reference key compound.growth
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get compoundGrowth;

  /// Reference key compound.initial
  ///
  /// In en, this message translates to:
  /// **'Starting amount'**
  String get compoundInitial;

  /// Reference key compound.monthly
  ///
  /// In en, this message translates to:
  /// **'Added each month'**
  String get compoundMonthly;

  /// Reference key compound.projection
  ///
  /// In en, this message translates to:
  /// **'Projection'**
  String get compoundProjection;

  /// Reference key compound.rate
  ///
  /// In en, this message translates to:
  /// **'Annual return'**
  String get compoundRate;

  /// Reference key compound.return
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get compoundReturn;

  /// Reference key compound.value
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get compoundValue;

  /// Reference key compound.years
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get compoundYears;

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

  /// Reference key datecalc.addSubtract
  ///
  /// In en, this message translates to:
  /// **'Add days'**
  String get datecalcAddDays;

  /// Reference key datecalc.between
  ///
  /// In en, this message translates to:
  /// **'Between the dates'**
  String get datecalcBetween;

  /// Reference key datecalc.business
  ///
  /// In en, this message translates to:
  /// **'Working days'**
  String get datecalcBusiness;

  /// The days between two dates; n chooses the form, count is n as the locale writes it
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{{count} day} other{{count} days}}'**
  String datecalcDays(int n, String count);

  /// Reference key datecalc.days
  ///
  /// In en, this message translates to:
  /// **'Days to add'**
  String get datecalcDaysToAdd;

  /// Reference key datecalc.difference
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get datecalcDifference;

  /// Reference key datecalc.from
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get datecalcFrom;

  /// Reference key datecalc.fromStart; count keeps the sign of the days added
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{{count} day from the start date} other{{count} days from the start date}}'**
  String datecalcFromStart(int n, String count);

  /// Reference key datecalc.holidays
  ///
  /// In en, this message translates to:
  /// **'Public holidays in the year'**
  String get datecalcHolidays;

  /// Reference key datecalc.mode
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get datecalcMode;

  /// Reference key datecalc.result
  ///
  /// In en, this message translates to:
  /// **'Result date'**
  String get datecalcResult;

  /// Reference key datecalc.start
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get datecalcStart;

  /// Reference key common.months, as a summary figure label
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get datecalcStatMonths;

  /// Reference key common.weeks, as a summary figure label
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get datecalcStatWeeks;

  /// Reference key common.years, as a summary figure label
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get datecalcStatYears;

  /// Reference key datecalc.to
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get datecalcTo;

  /// Reference key datecalc.weekdays
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get datecalcWeekdays;

  /// Reference key datecalc.weekends
  ///
  /// In en, this message translates to:
  /// **'Weekend days'**
  String get datecalcWeekends;

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

  /// Reference key docs.add
  ///
  /// In en, this message translates to:
  /// **'Add a document'**
  String get docsAdd;

  /// Reference key docs.allValid
  ///
  /// In en, this message translates to:
  /// **'Everything is valid'**
  String get docsAllValid;

  /// Reference key docs.category
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get docsCategory;

  /// Reference key docs.expired
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get docsExpired;

  /// Reference key docs.expiring — a stat label
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get docsExpiring;

  /// Reference key docs.expiringSoon
  ///
  /// In en, this message translates to:
  /// **'{n} expiring soon'**
  String docsExpiringSoon(int n);

  /// Reference key docs.expiringSoonShort — a badge
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get docsExpiringSoonShort;

  /// Reference key docs.expiry — a sort option and a fact
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get docsExpiry;

  /// Reference key docs.files
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get docsFiles;

  /// Reference key docs.filesN. The reference writes "1 files"; this is plural
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 file} other{{n} files}}'**
  String docsFilesN(int n);

  /// Documents fixture name
  ///
  /// In en, this message translates to:
  /// **'Degree Certificate'**
  String get docsFxDegree;

  /// Documents fixture name
  ///
  /// In en, this message translates to:
  /// **'Health Insurance'**
  String get docsFxInsurance;

  /// Documents fixture name
  ///
  /// In en, this message translates to:
  /// **'Driving Licence'**
  String get docsFxLicence;

  /// Documents fixture name
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get docsFxNid;

  /// Documents fixture name
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get docsFxPassport;

  /// Documents fixture name
  ///
  /// In en, this message translates to:
  /// **'Car Registration'**
  String get docsFxRegistration;

  /// Documents fixture name
  ///
  /// In en, this message translates to:
  /// **'Tenancy Agreement'**
  String get docsFxTenancy;

  /// Documents fixture holder
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get docsHolderHousehold;

  /// Reference key docs.needsAttention — a group title
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get docsNeedsAttention;

  /// Reference key docs.noExpiry
  ///
  /// In en, this message translates to:
  /// **'No expiry'**
  String get docsNoExpiry;

  /// Reference key docs.noMatch
  ///
  /// In en, this message translates to:
  /// **'No documents match'**
  String get docsNoMatch;

  /// Reference key docs.noMatchText
  ///
  /// In en, this message translates to:
  /// **'Try another category or clear the search.'**
  String get docsNoMatchText;

  /// Reference key docs.renewSoon
  ///
  /// In en, this message translates to:
  /// **'Renew your {name}'**
  String docsRenewSoon(String name);

  /// Reference key docs.renew.text
  ///
  /// In en, this message translates to:
  /// **'Renewing early avoids the queue and the late fee.'**
  String get docsRenewText;

  /// Reference key docs.renew.title. The reference writes "{n} document needs renewing" for two as well; this is plural
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 document needs renewing} other{{n} documents need renewing}}'**
  String docsRenewTitle(int n);

  /// Reference key docs.unlockToView
  ///
  /// In en, this message translates to:
  /// **'Unlock with device authentication to view'**
  String get docsUnlockToView;

  /// Reference key docs.updated — a sort option
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get docsUpdated;

  /// Reference key docs.valid — a group title and a badge
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get docsValid;

  /// Reference key docs.vault — the summary kicker
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get docsVault;

  /// Reference key duration.hm
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String durationHm(String h, String m);

  /// Reference key emerg.all3 — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Police · Fire · Medical'**
  String get emergKindAll3;

  /// Reference key emerg.allServices — what a number is for
  ///
  /// In en, this message translates to:
  /// **'All services'**
  String get emergKindAllServices;

  /// Reference key emerg.ambRescue — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Ambulance & rescue'**
  String get emergKindAmbRescue;

  /// Reference key emerg.ambulance — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Ambulance'**
  String get emergKindAmbulance;

  /// Reference key emerg.fire — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get emergKindFire;

  /// Reference key emerg.fireRescue — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Fire & rescue'**
  String get emergKindFireRescue;

  /// Reference key emerg.gas — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Gas leak'**
  String get emergKindGas;

  /// Reference key emerg.gsm — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Works on most GSM networks'**
  String get emergKindGsm;

  /// Reference key emerg.helpline — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Helpline'**
  String get emergKindHelpline;

  /// Reference key emerg.highway — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Highway'**
  String get emergKindHighway;

  /// Reference key emerg.maritime — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Maritime'**
  String get emergKindMaritime;

  /// Reference key emerg.medAdvice — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Urgent medical advice'**
  String get emergKindMedAdvice;

  /// Reference key emerg.medical — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get emergKindMedical;

  /// Reference key emerg.mental — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Mental health'**
  String get emergKindMental;

  /// Reference key emerg.nonUrgent — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Non-urgent'**
  String get emergKindNonUrgent;

  /// Reference key emerg.poison — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Poison'**
  String get emergKindPoison;

  /// Reference key emerg.police — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Police emergency'**
  String get emergKindPolice;

  /// Reference key emerg.routed — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Widely routed'**
  String get emergKindRouted;

  /// Reference key emerg.traffic — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get emergKindTraffic;

  /// Reference key emerg.trafficInfo — what a number is for
  ///
  /// In en, this message translates to:
  /// **'Traffic information'**
  String get emergKindTrafficInfo;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Ambulance'**
  String get emergNameAmbulance;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Civil Defence'**
  String get emergNameCivilDefence;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Coast Guard'**
  String get emergNameCoastGuard;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Crisis Lifeline'**
  String get emergNameCrisisLifeline;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Edhi Ambulance'**
  String get emergNameEdhiAmbulance;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergNameEmergency;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get emergNameFire;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Fire Brigade'**
  String get emergNameFireBrigade;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Fire (Civil Defence)'**
  String get emergNameFireCivilDefence;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Gas emergency'**
  String get emergNameGasEmergency;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'International Emergency'**
  String get emergNameInternational;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Local Emergency'**
  String get emergNameLocal;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Motorway Police'**
  String get emergNameMotorwayPolice;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'NHS 111'**
  String get emergNameNhs111;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Poison Control'**
  String get emergNamePoisonControl;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get emergNamePolice;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Police non-emergency'**
  String get emergNamePoliceNonEmergency;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Red Crescent'**
  String get emergNameRedCrescent;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Rescue 1122'**
  String get emergNameRescue1122;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Roadside'**
  String get emergNameRoadside;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get emergNameTraffic;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Unified Emergency'**
  String get emergNameUnifiedEmergency;

  /// The name of an emergency service in tool-data.js EMERGENCY. The reference writes it in English in every language; named in the reader's language here (§11), proper nouns transliterated
  ///
  /// In en, this message translates to:
  /// **'Women Helpline'**
  String get emergNameWomenHelpline;

  /// The accessible name of a call tile (D6). The number is the one on the tile, isolated left to right
  ///
  /// In en, this message translates to:
  /// **'Call {service} at {number}'**
  String emergencyCall(String service, String number);

  /// Said when the platform refused or failed to open the dialer. Lume has no such message; the toast is its mechanism (D6)
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open the phone app. Dial {number} yourself.'**
  String emergencyDialFailed(String number);

  /// Said when nothing on the device can dial (D6)
  ///
  /// In en, this message translates to:
  /// **'This device can’t make calls. Dial {number} from a phone.'**
  String emergencyDialUnavailable(String number);

  /// Reference key emergency.documents
  ///
  /// In en, this message translates to:
  /// **'Identity documents'**
  String get emergencyDocuments;

  /// Reference key emergency.locationShared — said only once the city and country are on the clipboard (C67)
  ///
  /// In en, this message translates to:
  /// **'Location copied to share'**
  String get emergencyLocationShared;

  /// Reference key emergency.medical. The reference has no Urdu or Arabic; translated here (§11)
  ///
  /// In en, this message translates to:
  /// **'Medical details'**
  String get emergencyMedical;

  /// Reference key emergency.note.text
  ///
  /// In en, this message translates to:
  /// **'Emergency numbers can usually be dialled with no credit and no SIM. 112 is routed in most countries.'**
  String get emergencyNoteText;

  /// Reference key emergency.note.title
  ///
  /// In en, this message translates to:
  /// **'Numbers work without signal'**
  String get emergencyNoteTitle;

  /// Reference key emergency.services
  ///
  /// In en, this message translates to:
  /// **'Other services'**
  String get emergencyServices;

  /// Reference key emergency.setUp
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get emergencySetUp;

  /// Reference key emergency.shareLocation
  ///
  /// In en, this message translates to:
  /// **'Share my location'**
  String get emergencyShareLocation;

  /// Reference key emergency.yourInfo
  ///
  /// In en, this message translates to:
  /// **'Your information'**
  String get emergencyYourInfo;

  /// Reference key events.noMatch
  ///
  /// In en, this message translates to:
  /// **'No events match'**
  String get eventsNoMatch;

  /// Reference key events.noMatchText
  ///
  /// In en, this message translates to:
  /// **'Try a different word.'**
  String get eventsNoMatchText;

  /// Reference key events.people
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 going} other{{n} going}}'**
  String eventsPeople(int n);

  /// Reference key events.e2 — a sample event
  ///
  /// In en, this message translates to:
  /// **'Team lunch'**
  String get eventsSeedE2;

  /// Reference key events.e3
  ///
  /// In en, this message translates to:
  /// **'Dentist'**
  String get eventsSeedE3;

  /// Reference key events.w2
  ///
  /// In en, this message translates to:
  /// **'The corner place'**
  String get eventsSeedW2;

  /// Reference key events.w3 — a business name, kept as written
  ///
  /// In en, this message translates to:
  /// **'Smile Studio'**
  String get eventsSeedW3;

  /// Reference key events.upcoming
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get eventsUpcoming;

  /// Reference key expenses.add
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get expensesAdd;

  /// Reference key expenses.balance
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get expensesBalance;

  /// Reference key expenses.budgetUse
  ///
  /// In en, this message translates to:
  /// **'Budget used'**
  String get expensesBudgetUse;

  /// Reference key expenses.budgets
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get expensesBudgets;

  /// EXPENSE_CATEGORIES bills
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get expensesCatBills;

  /// EXPENSE_CATEGORIES eating
  ///
  /// In en, this message translates to:
  /// **'Eating out'**
  String get expensesCatEating;

  /// tool-data.js EXPENSE_CATEGORIES groceries — written in English in the reference
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get expensesCatGroceries;

  /// EXPENSE_CATEGORIES health
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get expensesCatHealth;

  /// EXPENSE_CATEGORIES other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get expensesCatOther;

  /// EXPENSE_CATEGORIES transport
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get expensesCatTransport;

  /// Reference key expenses.categories
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get expensesCategories;

  /// Reference key expenses.category
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expensesCategory;

  /// Reference key expenses.dailyAvg
  ///
  /// In en, this message translates to:
  /// **'Daily average'**
  String get expensesDailyAvg;

  /// Reference key expenses.income
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get expensesIncome;

  /// Reference key expenses.insight1.text
  ///
  /// In en, this message translates to:
  /// **'Compared with your three-month average.'**
  String get expensesInsight1Text;

  /// Reference key expenses.insight1.title
  ///
  /// In en, this message translates to:
  /// **'Groceries are up 12%'**
  String get expensesInsight1Title;

  /// Reference key expenses.insight2.text
  ///
  /// In en, this message translates to:
  /// **'At this pace you finish about 8% under budget.'**
  String get expensesInsight2Text;

  /// Reference key expenses.insight2.title
  ///
  /// In en, this message translates to:
  /// **'On track for the month'**
  String get expensesInsight2Title;

  /// Reference key expenses.insights
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get expensesInsights;

  /// TRANSACTIONS method "Auto-debit"
  ///
  /// In en, this message translates to:
  /// **'Auto-debit'**
  String get expensesMethodAutoDebit;

  /// Reference key expenses.monthlyOn — the reference writes "th" for every day
  ///
  /// In en, this message translates to:
  /// **'monthly, on the {day}th'**
  String expensesMonthlyOn(int day);

  /// Reference key expenses.noMatch
  ///
  /// In en, this message translates to:
  /// **'No transactions match'**
  String get expensesNoMatch;

  /// Reference key expenses.noMatchText
  ///
  /// In en, this message translates to:
  /// **'Try another category or clear the search.'**
  String get expensesNoMatchText;

  /// Reference key expenses.ofBudget — both arrive formatted
  ///
  /// In en, this message translates to:
  /// **'{pct} of your {budget} budget'**
  String expensesOfBudget(String pct, String budget);

  /// Reference key expenses.range — the segmented control's name
  ///
  /// In en, this message translates to:
  /// **'Range'**
  String get expensesRange;

  /// Reference key expenses.rec1
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get expensesRec1;

  /// Reference key expenses.rec2
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get expensesRec2;

  /// Reference key expenses.recurring
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get expensesRecurring;

  /// Reference key expenses.spent
  ///
  /// In en, this message translates to:
  /// **'Spent this month'**
  String get expensesSpent;

  /// Reference key expenses.transactions
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get expensesTransactions;

  /// Reference key expenses.trend
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get expensesTrend;

  /// Reference key expenses.trendCap
  ///
  /// In en, this message translates to:
  /// **'Averaging {avg} a day'**
  String expensesTrendCap(String avg);

  /// TRANSACTIONS
  ///
  /// In en, this message translates to:
  /// **'Ride to airport'**
  String get expensesTxAirport;

  /// TRANSACTIONS — coffee, and the café's name
  ///
  /// In en, this message translates to:
  /// **'Coffee — Chaaye Khana'**
  String get expensesTxCoffee;

  /// TRANSACTIONS
  ///
  /// In en, this message translates to:
  /// **'Electricity bill'**
  String get expensesTxElectricity;

  /// TRANSACTIONS — fuel, and the station's name
  ///
  /// In en, this message translates to:
  /// **'Fuel — Shell'**
  String get expensesTxFuel;

  /// TRANSACTIONS
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get expensesTxInternet;

  /// tool-data.js TRANSACTIONS — a shop's name, kept as written
  ///
  /// In en, this message translates to:
  /// **'Metro Cash & Carry'**
  String get expensesTxMetro;

  /// TRANSACTIONS
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get expensesTxPharmacy;

  /// TRANSACTIONS
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get expensesTxSalary;

  /// TRANSACTIONS when — "Today · 11:20": a day and a clock time, both formatted
  ///
  /// In en, this message translates to:
  /// **'{day} · {time}'**
  String expensesWhenTime(String day, String time);

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

  /// What a screen reader says for the "Sample data" mark at the head of a tool's source line, in the parity build (F6B closure)
  ///
  /// In en, this message translates to:
  /// **'Sample data. The figures in this tool are examples, not your own.'**
  String get fixtureSampleA11y;

  /// Reference key flights.actualDep
  ///
  /// In en, this message translates to:
  /// **'Actual departure'**
  String get flightsActualDep;

  /// Reference key flights.aircraft
  ///
  /// In en, this message translates to:
  /// **'Aircraft & route'**
  String get flightsAircraft;

  /// Reference key flights.altitude
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get flightsAltitude;

  /// Reference: `c.num(alt) + " " + t("unit.ft")` — the number arrives formatted
  ///
  /// In en, this message translates to:
  /// **'{feet} ft'**
  String flightsAltitudeFeet(String feet);

  /// Reference key flights.arrivals
  ///
  /// In en, this message translates to:
  /// **'Arrivals'**
  String get flightsArrivals;

  /// Reference key flights.board — the segmented control's name
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get flightsBoard;

  /// Reference key flights.cruise
  ///
  /// In en, this message translates to:
  /// **'Cruising'**
  String get flightsCruise;

  /// Reference: altitude and ground speed, each formatted with its unit
  ///
  /// In en, this message translates to:
  /// **'{altitude} · {speed}'**
  String flightsCruiseSub(String altitude, String speed);

  /// Reference key flights.delayed — a metric label
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get flightsDelayed;

  /// Reference key flights.departures
  ///
  /// In en, this message translates to:
  /// **'Departures'**
  String get flightsDepartures;

  /// Reference key flights.distance
  ///
  /// In en, this message translates to:
  /// **'Route distance'**
  String get flightsDistance;

  /// Reference key flights.enRoute — a metric label
  ///
  /// In en, this message translates to:
  /// **'En route'**
  String get flightsEnRoute;

  /// Reference key flights.estArrival
  ///
  /// In en, this message translates to:
  /// **'Estimated arrival'**
  String get flightsEstArrival;

  /// Reference: `t("flights.eta") + " " + eta`
  ///
  /// In en, this message translates to:
  /// **'ETA {time}'**
  String flightsEta(String time);

  /// Reference: `t("flights.gate") + " " + gate`
  ///
  /// In en, this message translates to:
  /// **'Gate {gate}'**
  String flightsGate(String gate);

  /// Reference key flights.lateBy
  ///
  /// In en, this message translates to:
  /// **'{n} minutes late'**
  String flightsLateBy(int n);

  /// Reference: `"+" + delay + "m"` — minutes late, in a row's meta line
  ///
  /// In en, this message translates to:
  /// **'+{n}m'**
  String flightsLateShort(int n);

  /// Reference key flights.live — a section title
  ///
  /// In en, this message translates to:
  /// **'Live board'**
  String get flightsLive;

  /// Reference key flights.map — the map's accessible name
  ///
  /// In en, this message translates to:
  /// **'Live position'**
  String get flightsMap;

  /// Reference key flights.noMatch
  ///
  /// In en, this message translates to:
  /// **'No flights on this board'**
  String get flightsNoMatch;

  /// Reference key flights.noMatchText
  ///
  /// In en, this message translates to:
  /// **'Try arrivals, or search a flight number or airport.'**
  String get flightsNoMatchText;

  /// Reference key flights.onTime
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get flightsOnTime;

  /// Reference key flights.registration
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get flightsRegistration;

  /// Reference key flights.remaining — the distance arrives formatted with its unit
  ///
  /// In en, this message translates to:
  /// **'{distance} to run'**
  String flightsRemaining(String distance);

  /// Reference key flights.scheduled — under an arrival time that has not moved
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get flightsScheduled;

  /// Reference key flights.scheduledDep
  ///
  /// In en, this message translates to:
  /// **'Scheduled departure'**
  String get flightsScheduledDep;

  /// Reference key flights.search
  ///
  /// In en, this message translates to:
  /// **'Flight number, route or airport'**
  String get flightsSearch;

  /// The share card for the selected flight — codes and a clock time
  ///
  /// In en, this message translates to:
  /// **'{flight} · {from} → {to} · ETA {time}'**
  String flightsShareText(String flight, String from, String to, String time);

  /// Reference key flights.speed
  ///
  /// In en, this message translates to:
  /// **'Ground speed'**
  String get flightsSpeed;

  /// Reference key flights.st.delayed
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get flightsStDelayed;

  /// Reference key flights.st.enroute — a flight's status badge
  ///
  /// In en, this message translates to:
  /// **'En route'**
  String get flightsStEnroute;

  /// Reference key flights.st.landed
  ///
  /// In en, this message translates to:
  /// **'Landed'**
  String get flightsStLanded;

  /// Reference key flights.st.scheduled
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get flightsStScheduled;

  /// Reference key flights.terminal
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get flightsTerminal;

  /// Reference: `term + " · " + t("flights.gate") + " " + gate`
  ///
  /// In en, this message translates to:
  /// **'{terminal} · Gate {gate}'**
  String flightsTerminalGate(String terminal, String gate);

  /// Reference key flights.timeline
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get flightsTimeline;

  /// Reference key flights.total — a metric label
  ///
  /// In en, this message translates to:
  /// **'Flights'**
  String get flightsTotal;

  /// Reference key flights.track
  ///
  /// In en, this message translates to:
  /// **'Track this flight'**
  String get flightsTrack;

  /// Reference key flights.tracked
  ///
  /// In en, this message translates to:
  /// **'Tracked'**
  String get flightsTracked;

  /// Reference key flights.tracking — the toast
  ///
  /// In en, this message translates to:
  /// **'Tracking {flight}'**
  String flightsTracking(String flight);

  /// Reference key flights.type
  ///
  /// In en, this message translates to:
  /// **'Aircraft'**
  String get flightsType;

  /// Reference key fresh.agoMin — the source line of a delayed tool
  ///
  /// In en, this message translates to:
  /// **'Updated {n} min ago'**
  String freshAgoMin(int n);

  /// Reference key fresh.agoSec — the source line of a live tool
  ///
  /// In en, this message translates to:
  /// **'Updated {n} sec ago'**
  String freshAgoSec(int n);

  /// Reference key fresh.annual — Tax's own reference wording, still used for Tax specifically (source_claims.dart special-cases it). A tool other than Tax with annual freshness uses freshAnnualGeneric instead (wave 9).
  ///
  /// In en, this message translates to:
  /// **'Current tax year'**
  String get freshAnnual;

  /// The annual-freshness label for a tool other than Tax — Public Holidays, and any future annual tool (wave 9). Matches the freshDaily/freshWeekly 'Updated ...' pattern rather than Tax's own tax-specific reference wording.
  ///
  /// In en, this message translates to:
  /// **'Updated annually'**
  String get freshAnnualGeneric;

  /// Reference key fresh.at — a daily source, in the reader's clock
  ///
  /// In en, this message translates to:
  /// **'Updated at {time}'**
  String freshAt(String time);

  /// Reference key fresh.cached
  ///
  /// In en, this message translates to:
  /// **'Cached'**
  String get freshCached;

  /// Reference key fresh.computed
  ///
  /// In en, this message translates to:
  /// **'Calculated for your location'**
  String get freshComputed;

  /// The freshness word for a figure that moves but is worked out on the device from data compiled into the app rather than fetched, as World Clock is. Distinguishes it from the plain live label, which reads as a feed.
  ///
  /// In en, this message translates to:
  /// **'Calculated live'**
  String get freshComputedLive;

  /// Reference key fresh.daily
  ///
  /// In en, this message translates to:
  /// **'Updated today'**
  String get freshDaily;

  /// Reference key fresh.delayed
  ///
  /// In en, this message translates to:
  /// **'Delayed 15 min'**
  String get freshDelayed;

  /// Reference key fresh.draw
  ///
  /// In en, this message translates to:
  /// **'Latest draw'**
  String get freshDraw;

  /// Reference key fresh.forCity — a figure computed for the reader's city
  ///
  /// In en, this message translates to:
  /// **'For {city}'**
  String freshForCity(String city);

  /// Reference key fresh.live — a live source
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get freshLive;

  /// Reference key fresh.local
  ///
  /// In en, this message translates to:
  /// **'Stored on this device'**
  String get freshLocal;

  /// Reference key fresh.on — a weekly or annual source
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String freshOn(String date);

  /// A release build’s source line where nothing real supports a freshness or feed claim
  ///
  /// In en, this message translates to:
  /// **'Sample data'**
  String get freshSample;

  /// What a screen reader hears for a source-line claim a parity (visual-reference) build reproduces from the web reference, such as "Stored on this device"
  ///
  /// In en, this message translates to:
  /// **'{claim}. Reference copy, not a claim about this build'**
  String freshReferenceCopy(String claim);

  /// A development or release build’s word for data held only for the session; replaces "Stored on this device" without a durable store
  ///
  /// In en, this message translates to:
  /// **'Kept until you close Lume'**
  String get freshSession;

  /// Reference key fresh.static
  ///
  /// In en, this message translates to:
  /// **'Reference text'**
  String get freshStatic;

  /// Reference key fresh.weekly
  ///
  /// In en, this message translates to:
  /// **'Updated this week'**
  String get freshWeekly;

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

  /// Reference key hadith.browse
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get hadithBrowse;

  /// Reference key hadith.collection
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get hadithCollection;

  /// A hadith's grade: good. A term of the science of hadith, written as scholars write it in each language
  ///
  /// In en, this message translates to:
  /// **'Hasan'**
  String get hadithGradeHasan;

  /// A hadith's grade: authentic. A term of the science of hadith, written as scholars write it in each language
  ///
  /// In en, this message translates to:
  /// **'Sahih'**
  String get hadithGradeSahih;

  /// Reference: t("hadith.narrator") + ": " + narrator — the name is the narrator's, as the collection gives it
  ///
  /// In en, this message translates to:
  /// **'Narrated by: {name}'**
  String hadithNarratedBy(String name);

  /// Reference key hadith.noMatch
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get hadithNoMatch;

  /// Reference key hadith.noMatchText
  ///
  /// In en, this message translates to:
  /// **'Try another collection or a shorter search.'**
  String get hadithNoMatchText;

  /// The toast a browse row says: src + " " + ref
  ///
  /// In en, this message translates to:
  /// **'{source} {number}'**
  String hadithOpened(String source, String number);

  /// A hadith's source and number — src + " · " + ref; both are the collection's own
  ///
  /// In en, this message translates to:
  /// **'{source} · {number}'**
  String hadithReference(String source, String number);

  /// Said after Save keeps the day's hadith (C77)
  ///
  /// In en, this message translates to:
  /// **'Saved to your reading'**
  String get hadithSaved;

  /// The Save button once the day's hadith is kept
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get hadithSavedLabel;

  /// Reference key hadith.search
  ///
  /// In en, this message translates to:
  /// **'Search hadith'**
  String get hadithSearch;

  /// Said after Save is pressed again
  ///
  /// In en, this message translates to:
  /// **'Removed from your reading'**
  String get hadithUnsaved;

  /// A heatmap cell's level
  ///
  /// In en, this message translates to:
  /// **'all'**
  String get heatLevelAll;

  /// A heatmap cell's level
  ///
  /// In en, this message translates to:
  /// **'most'**
  String get heatLevelMost;

  /// A heatmap cell's level, as a screen reader hears it. The reference announces the English word in every language; translated here.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get heatLevelNone;

  /// A heatmap cell's level
  ///
  /// In en, this message translates to:
  /// **'some'**
  String get heatLevelSome;

  /// Reference: aria-label="Highlights" on the carousel
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get heroHighlights;

  /// tool-data.js HIJRI_MONTHS[0] — the Hijri month
  ///
  /// In en, this message translates to:
  /// **'Muharram'**
  String get hijriMonth1;

  /// tool-data.js HIJRI_MONTHS[9] — the Hijri month
  ///
  /// In en, this message translates to:
  /// **'Shawwal'**
  String get hijriMonth10;

  /// tool-data.js HIJRI_MONTHS[10] — the Hijri month
  ///
  /// In en, this message translates to:
  /// **'Dhul-Qa‘dah'**
  String get hijriMonth11;

  /// tool-data.js HIJRI_MONTHS[11] — the Hijri month
  ///
  /// In en, this message translates to:
  /// **'Dhul-Hijjah'**
  String get hijriMonth12;

  /// tool-data.js HIJRI_MONTHS[1] — the Hijri month
  ///
  /// In en, this message translates to:
  /// **'Safar'**
  String get hijriMonth2;

  /// tool-data.js HIJRI_MONTHS[2] — the Hijri month
  ///
  /// In en, this message translates to:
  /// **'Rabi‘ al-Awwal'**
  String get hijriMonth3;

  /// tool-data.js HIJRI_MONTHS[3] — the Hijri month
  ///
  /// In en, this message translates to:
  /// **'Rabi‘ al-Thani'**
  String get hijriMonth4;

  /// tool-data.js HIJRI_MONTHS[4] — the Hijri month
  ///
  /// In en, this message translates to:
  /// **'Jumada al-Ula'**
  String get hijriMonth5;

  /// tool-data.js HIJRI_MONTHS[5] — the Hijri month
  ///
  /// In en, this message translates to:
  /// **'Jumada al-Akhirah'**
  String get hijriMonth6;

  /// tool-data.js HIJRI_MONTHS[6] — the Hijri month
  ///
  /// In en, this message translates to:
  /// **'Rajab'**
  String get hijriMonth7;

  /// tool-data.js HIJRI_MONTHS[7] — the Hijri month
  ///
  /// In en, this message translates to:
  /// **'Sha‘ban'**
  String get hijriMonth8;

  /// tool-data.js HIJRI_MONTHS[8] — the Hijri month
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get hijriMonth9;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Boxing Day'**
  String get holidayBoxingDay;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Christmas'**
  String get holidayChristmas;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Christmas Day'**
  String get holidayChristmasDay;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Commemoration Day'**
  String get holidayCommemorationDay;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Diwali'**
  String get holidayDiwali;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Early May'**
  String get holidayEarlyMay;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Eid al-Adha'**
  String get holidayEidAlAdha;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Eid al-Fitr'**
  String get holidayEidAlFitr;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Founding Day'**
  String get holidayFoundingDay;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Gandhi Jayanti'**
  String get holidayGandhiJayanti;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Good Friday'**
  String get holidayGoodFriday;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Holi'**
  String get holidayHoli;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Independence Day'**
  String get holidayIndependenceDay;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Iqbal Day'**
  String get holidayIqbalDay;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Islamic New Year'**
  String get holidayIslamicNewYear;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Kashmir Day'**
  String get holidayKashmirDay;

  /// The kind of a public holiday in tool-data.js HOLIDAYS
  ///
  /// In en, this message translates to:
  /// **'Bank holiday'**
  String get holidayKindBank;

  /// The kind of a public holiday in tool-data.js HOLIDAYS
  ///
  /// In en, this message translates to:
  /// **'Federal'**
  String get holidayKindFederal;

  /// The kind of a public holiday in tool-data.js HOLIDAYS
  ///
  /// In en, this message translates to:
  /// **'Gazetted'**
  String get holidayKindGazetted;

  /// The kind of a public holiday in tool-data.js HOLIDAYS
  ///
  /// In en, this message translates to:
  /// **'National'**
  String get holidayKindNational;

  /// The kind of a public holiday in tool-data.js HOLIDAYS
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get holidayKindPublic;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Labor Day'**
  String get holidayLaborDay;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Labour Day'**
  String get holidayLabourDay;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'MLK Jr. Day'**
  String get holidayMlkDay;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'National Day'**
  String get holidayNationalDay;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'New Year’s Day'**
  String get holidayNewYearsDay;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Pakistan Day'**
  String get holidayPakistanDay;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Quaid-e-Azam Day'**
  String get holidayQuaidDay;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Republic Day'**
  String get holidayRepublicDay;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Summer'**
  String get holidaySummer;

  /// A public holiday in tool-data.js HOLIDAYS. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Thanksgiving'**
  String get holidayThanksgiving;

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

  /// Reference key learning.consistency — the heatmap's section head and name
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get learningConsistency;

  /// A course's provider and session length — `x.provider + " · " + x.mins + " " + t("unit.min")`
  ///
  /// In en, this message translates to:
  /// **'{provider} · {minutes} min'**
  String learningCourseMeta(String provider, String minutes);

  /// Reference key learning.courses — a summary figure
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get learningCourses;

  /// Reference key learning.goal — the ring's accessible name
  ///
  /// In en, this message translates to:
  /// **'Weekly goal'**
  String get learningGoal;

  /// Reference key learning.inProgress — a section head
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get learningInProgress;

  /// Reference key learning.insight1.text
  ///
  /// In en, this message translates to:
  /// **'Your 20-minute sessions are completed twice as often as your hour-long ones.'**
  String get learningInsight1Text;

  /// Reference key learning.insight1.title
  ///
  /// In en, this message translates to:
  /// **'Short sessions stick'**
  String get learningInsight1Title;

  /// Reference key learning.insight2.text
  ///
  /// In en, this message translates to:
  /// **'Nine days running, well ahead of your other courses.'**
  String get learningInsight2Text;

  /// Reference key learning.insight2.title
  ///
  /// In en, this message translates to:
  /// **'Arabic is your strongest streak'**
  String get learningInsight2Title;

  /// Reference key learning.milestone — a summary figure
  ///
  /// In en, this message translates to:
  /// **'Next milestone'**
  String get learningMilestone;

  /// Reference key learning.milestoneValue — the reference writes the literal "200 min"; the figure is a placeholder here so its digits follow the locale
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String learningMilestoneValue(String n);

  /// Reference key learning.streak — the summary's caption
  ///
  /// In en, this message translates to:
  /// **'{n}-day streak'**
  String learningStreak(String n);

  /// Reference key learning.streakLabel — a summary figure
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get learningStreakLabel;

  /// Reference key learning.thisWeek — the summary's kicker
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get learningThisWeek;

  /// Reference key learning.week — the bar chart's section head and name
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get learningWeek;

  /// Reference key levy.corporate
  ///
  /// In en, this message translates to:
  /// **'Corporate tax'**
  String get levyCorporate;

  /// Reference key levy.eobi
  ///
  /// In en, this message translates to:
  /// **'EOBI'**
  String get levyEobi;

  /// Reference key levy.gosi
  ///
  /// In en, this message translates to:
  /// **'Social insurance (GOSI)'**
  String get levyGosi;

  /// Reference key levy.gst
  ///
  /// In en, this message translates to:
  /// **'GST'**
  String get levyGst;

  /// Reference key levy.medicare
  ///
  /// In en, this message translates to:
  /// **'Medicare'**
  String get levyMedicare;

  /// Reference key levy.ni
  ///
  /// In en, this message translates to:
  /// **'National Insurance'**
  String get levyNi;

  /// Reference key levy.pension
  ///
  /// In en, this message translates to:
  /// **'Pension contribution'**
  String get levyPension;

  /// Reference key levy.pf
  ///
  /// In en, this message translates to:
  /// **'Provident Fund'**
  String get levyPf;

  /// Reference key levy.socialSecurity
  ///
  /// In en, this message translates to:
  /// **'Social Security'**
  String get levySocialSecurity;

  /// Reference key levy.vat
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get levyVat;

  /// Reference key levy.zakatRate
  ///
  /// In en, this message translates to:
  /// **'Zakat'**
  String get levyZakatRate;

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

  /// Reference key loan.amortisation
  ///
  /// In en, this message translates to:
  /// **'Amortisation'**
  String get loanAmortisation;

  /// Reference key loan.balance
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get loanBalance;

  /// Reference key loan.compare
  ///
  /// In en, this message translates to:
  /// **'If the rate changed'**
  String get loanCompare;

  /// Reference key loan.higherRate
  ///
  /// In en, this message translates to:
  /// **'Two points higher'**
  String get loanHigherRate;

  /// Reference key loan.interest
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get loanInterest;

  /// Reference key loan.interestShare
  ///
  /// In en, this message translates to:
  /// **'Interest share'**
  String get loanInterestShare;

  /// Reference key loan.lowerRate
  ///
  /// In en, this message translates to:
  /// **'Two points lower'**
  String get loanLowerRate;

  /// Reference key loan.monthly
  ///
  /// In en, this message translates to:
  /// **'Monthly payment'**
  String get loanMonthly;

  /// Reference key loan.over
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{over 1 payment} other{over {count} payments}}'**
  String loanOver(int n, String count);

  /// Reference key loan.principal
  ///
  /// In en, this message translates to:
  /// **'Loan amount'**
  String get loanPrincipal;

  /// Reference key loan.principalShort
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get loanPrincipalShort;

  /// Reference key loan.rate
  ///
  /// In en, this message translates to:
  /// **'Interest rate'**
  String get loanRate;

  /// Reference key loan.rateAt
  ///
  /// In en, this message translates to:
  /// **'At {rate}%'**
  String loanRateAt(String rate);

  /// Reference key loan.split
  ///
  /// In en, this message translates to:
  /// **'Principal vs interest'**
  String get loanSplit;

  /// Reference key loan.tenure
  ///
  /// In en, this message translates to:
  /// **'Tenure'**
  String get loanTenure;

  /// Reference key loan.totalInterest
  ///
  /// In en, this message translates to:
  /// **'Total interest'**
  String get loanTotalInterest;

  /// Reference key loan.totalPaid
  ///
  /// In en, this message translates to:
  /// **'Total repaid'**
  String get loanTotalPaid;

  /// Reference key loan.yourRate
  ///
  /// In en, this message translates to:
  /// **'Your rate'**
  String get loanYourRate;

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

  /// Reference key moon.firstQuarter
  ///
  /// In en, this message translates to:
  /// **'First quarter'**
  String get moonFirstQuarter;

  /// Reference key moon.full
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get moonFull;

  /// Reference key moon.lastQuarter
  ///
  /// In en, this message translates to:
  /// **'Last quarter'**
  String get moonLastQuarter;

  /// Reference key moon.new
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get moonNew;

  /// Reference key moon.wanCrescent
  ///
  /// In en, this message translates to:
  /// **'Waning crescent'**
  String get moonWanCrescent;

  /// Reference key moon.wanGibbous
  ///
  /// In en, this message translates to:
  /// **'Waning gibbous'**
  String get moonWanGibbous;

  /// Reference key moon.waxCrescent
  ///
  /// In en, this message translates to:
  /// **'Waxing crescent'**
  String get moonWaxCrescent;

  /// Reference key moon.waxGibbous
  ///
  /// In en, this message translates to:
  /// **'Waxing gibbous'**
  String get moonWaxGibbous;

  /// Reference: `n.act.complete`. It opens the task list; it does not complete anything, whatever its key says.
  ///
  /// In en, this message translates to:
  /// **'Open tasks'**
  String get nActComplete;

  /// Reference: `n.act.pay`.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get nActPay;

  /// Reference: `n.act.track`.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get nActTrack;

  /// Reference: `n.act.viewDoc`.
  ///
  /// In en, this message translates to:
  /// **'View document'**
  String get nActViewDoc;

  /// Reference: `n.act.viewFlight`.
  ///
  /// In en, this message translates to:
  /// **'View flight'**
  String get nActViewFlight;

  /// Reference: `n.act.viewMarket`.
  ///
  /// In en, this message translates to:
  /// **'View market'**
  String get nActViewMarket;

  /// Reference: `n.act.viewPrayer`.
  ///
  /// In en, this message translates to:
  /// **'View prayer'**
  String get nActViewPrayer;

  /// Reference: `n.act.viewTrain`.
  ///
  /// In en, this message translates to:
  /// **'View train'**
  String get nActViewTrain;

  /// Reference: `n.act.viewWeather`.
  ///
  /// In en, this message translates to:
  /// **'View weather'**
  String get nActViewWeather;

  /// Reference: `n.actioned`. A row that has been acted on stays in history and stops asking.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get nActioned;

  /// Reference: `n.allRead`. The centre’s subtitle when nothing is unread.
  ///
  /// In en, this message translates to:
  /// **'You’re all caught up'**
  String get nAllRead;

  /// Reference: `n.bill.body`. Shown only when sensitive previews are on.
  ///
  /// In en, this message translates to:
  /// **'{amount} is past its due date.'**
  String nBillBody(String amount);

  /// Reference: `n.billDue.title`.
  ///
  /// In en, this message translates to:
  /// **'{name} is due soon'**
  String nBillDueTitle(String name);

  /// Reference: `n.bill.private`.
  ///
  /// In en, this message translates to:
  /// **'A bill is past its due date.'**
  String get nBillPrivate;

  /// Reference: `n.bill.title`. **Not a plural, on purpose** — the reference’s is not, so "2 bill needs attention" is what it would say. C52.
  ///
  /// In en, this message translates to:
  /// **'{n} bill needs attention'**
  String nBillTitle(int n);

  /// Reference: `n.category`. The filter bar’s own label.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get nCategory;

  /// Reference: `n.daysAgo`. A day or more.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 d ago} other{{n} d ago}}'**
  String nDaysAgo(int n);

  /// Reference: `n.dismiss`. The ✕ on a row, and the banner’s close control.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get nDismiss;

  /// Reference: `n.doc.body`. Shown only when sensitive previews are on.
  ///
  /// In en, this message translates to:
  /// **'Expires in {n} days, on {date}.'**
  String nDocBody(int n, String date);

  /// Reference: `n.doc.private`.
  ///
  /// In en, this message translates to:
  /// **'A document is expiring soon.'**
  String get nDocPrivate;

  /// Reference: `n.doc.title`.
  ///
  /// In en, this message translates to:
  /// **'Renew your {name}'**
  String nDocTitle(String name);

  /// Reference: the bills tool’s `dueLabel`, which is also what a due bill says while sensitive previews are off. Lower case, as the reference renders it.
  ///
  /// In en, this message translates to:
  /// **'due in {n} days'**
  String nDueInDays(int n);

  /// Reference: `n.empty.caughtUp`. The Unread tab’s own empty state, which is a different sentence from the general one because it means something different.
  ///
  /// In en, this message translates to:
  /// **'You’re all caught up'**
  String get nEmptyCaughtUp;

  /// Reference: `n.empty.text`.
  ///
  /// In en, this message translates to:
  /// **'New alerts and updates will appear here.'**
  String get nEmptyText;

  /// Reference: `n.empty.title`.
  ///
  /// In en, this message translates to:
  /// **'Nothing to tell you'**
  String get nEmptyTitle;

  /// Reference: `n.error.text`.
  ///
  /// In en, this message translates to:
  /// **'Nothing was lost. Try again.'**
  String get nErrorText;

  /// Reference: `n.error.title`. An engine that throws still leaves the reader somewhere.
  ///
  /// In en, this message translates to:
  /// **'Notifications could not be loaded'**
  String get nErrorTitle;

  /// Reference: `n.expired`. Past the moment it was about.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get nExpired;

  /// Reference: `n.flight.body`. Not a plural in the reference.
  ///
  /// In en, this message translates to:
  /// **'{n} minutes late · now arriving {eta} at {to}'**
  String nFlightBody(int n, String eta, String to);

  /// Reference: `n.flight.title`. `{no}` is a flight code and is direction-isolated where it is drawn.
  ///
  /// In en, this message translates to:
  /// **'{no} is delayed'**
  String nFlightTitle(String no);

  /// Reference: `weather.hilo` joined to `weather.rain` by the forecast source. The reference translates only the last word, so its Urdu reads "High 36° · Low 27° · 1% بارش".
  ///
  /// In en, this message translates to:
  /// **'High {hi} · Low {lo} · {rain}% Rain'**
  String nForecastBody(String hi, String lo, String rain);

  /// Reference: `n.group.body`.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 more update} other{{n} more updates}}'**
  String nGroupBody(int n);

  /// Reference: `n.group.title`. Three or more updates of one event fold into a single row.
  ///
  /// In en, this message translates to:
  /// **'{name} activity'**
  String nGroupTitle(String name);

  /// Reference: `n.habit.body`.
  ///
  /// In en, this message translates to:
  /// **'You’re on a {n}-day streak.'**
  String nHabitBody(int n);

  /// Reference: `n.habit.title`. **Not a plural, on purpose** — the reference renders "1 habits left today". C52.
  ///
  /// In en, this message translates to:
  /// **'{n} habits left today'**
  String nHabitTitle(int n);

  /// Reference: `n.hidden`. What a row says instead of its body when previews are off. The detail never reaches the screen rather than being hidden on it.
  ///
  /// In en, this message translates to:
  /// **'Content hidden'**
  String get nHidden;

  /// Reference: `n.hoursAgo`. Under a day.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 hr ago} other{{n} hr ago}}'**
  String nHoursAgo(int n);

  /// Reference: `n.markAllRead`. Offered only while something is unread.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get nMarkAllRead;

  /// Reference: `n.market.body`.
  ///
  /// In en, this message translates to:
  /// **'Now {value} on {exchange}.'**
  String nMarketBody(String value, String exchange);

  /// Reference: `n.market.title`. `{pct}` carries its own sign and is direction-isolated.
  ///
  /// In en, this message translates to:
  /// **'{name} moved {pct}'**
  String nMarketTitle(String name, String pct);

  /// Reference: `n.med.body`. Shown only when sensitive previews are on.
  ///
  /// In en, this message translates to:
  /// **'Your next dose is at {at}.'**
  String nMedBody(String at);

  /// Reference: `n.med.private`. What a medication row says while sensitive previews are off — the default.
  ///
  /// In en, this message translates to:
  /// **'You have a dose due.'**
  String get nMedPrivate;

  /// Reference: `n.med.title`.
  ///
  /// In en, this message translates to:
  /// **'Time for your medication'**
  String get nMedTitle;

  /// Reference: `n.minsAgo`. Under an hour. A plural because Arabic has a dual and a paucal for it.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 min ago} other{{n} min ago}}'**
  String nMinsAgo(int n);

  /// Reference: `n.now`. Under a minute old.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get nNow;

  /// Reference: `n.outage.title`.
  ///
  /// In en, this message translates to:
  /// **'Power off at {time}'**
  String nOutageTitle(String time);

  /// Reference: `n.parcel.body`.
  ///
  /// In en, this message translates to:
  /// **'{carrier} · expected {eta}'**
  String nParcelBody(String carrier, String eta);

  /// Reference: `n.parcel.title`.
  ///
  /// In en, this message translates to:
  /// **'{item} is on its way'**
  String nParcelTitle(String item);

  /// Reference: `n.pri.critical`. The badge on a critical row.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get nPriCritical;

  /// Reference: `n.pri.high`. The badge on a high-priority row.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get nPriHigh;

  /// Reference: `n.ask.enable`.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get nPushAllow;

  /// Reference: `n.ask.later`. Declining is a choice, not the absence of one.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get nPushNotNow;

  /// Reference: `n.push.off`.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get nPushOff;

  /// Reference: `n.push.on`. Whether push has been allowed on this device.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get nPushOn;

  /// Reference: `n.ask.text`. It names what will be sent and, in the same breath, what will not.
  ///
  /// In en, this message translates to:
  /// **'Useful alerts for the things you already follow — and nothing else.'**
  String get nPushText;

  /// Reference: `n.ask.title`.
  ///
  /// In en, this message translates to:
  /// **'Stay informed'**
  String get nPushTitle;

  /// Reference: `n.quiet.text`. Quiet hours silence the interruption, not the delivery — and the note says so, because a reader who thought otherwise would stop checking.
  ///
  /// In en, this message translates to:
  /// **'Nothing will interrupt you, but everything still arrives here.'**
  String get nQuietText;

  /// Reference: `n.quiet.title`.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours are on'**
  String get nQuietTitle;

  /// Reference: `n.restored`. The toast after the preferences' Restore dismissed control brings every dismissed row back.
  ///
  /// In en, this message translates to:
  /// **'Dismissed notifications restored'**
  String get nRestored;

  /// Reference: `n.settings`. The header action and the trailing row, both of which open the preferences.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get nSettings;

  /// Reference: `n.settingsSub`. The line under the notification preferences sheet's title.
  ///
  /// In en, this message translates to:
  /// **'What Lume may tell you, and when'**
  String get nSettingsSub;

  /// Reference: `n.sub.body`. Shown only when sensitive previews are on.
  ///
  /// In en, this message translates to:
  /// **'In {n} days · {amount}'**
  String nSubBody(int n, String amount);

  /// Reference: `n.sub.private`.
  ///
  /// In en, this message translates to:
  /// **'A subscription renews in {n} days.'**
  String nSubPrivate(int n);

  /// Reference: `n.sub.title`.
  ///
  /// In en, this message translates to:
  /// **'{name} renews soon'**
  String nSubTitle(String name);

  /// Reference: `n.tab.important`. Priority rank 2 and above, expired rows excluded.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get nTabImportant;

  /// Reference: `n.tab.unread`.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get nTabUnread;

  /// Reference: `notif.taskNext`.
  ///
  /// In en, this message translates to:
  /// **'Next: {title}'**
  String nTaskNext(String title);

  /// Reference: `notif.tasksLeft`. **Not a plural, on purpose** — C52.
  ///
  /// In en, this message translates to:
  /// **'{n} tasks left today'**
  String nTasksLeft(int n);

  /// Reference: `n.train.body`. Not a plural in the reference.
  ///
  /// In en, this message translates to:
  /// **'{n} minutes behind · next stop {next}'**
  String nTrainBody(int n, String next);

  /// Reference: `n.train.title`.
  ///
  /// In en, this message translates to:
  /// **'{name} is running late'**
  String nTrainTitle(String name);

  /// Reference: `n.unread`. What the dot on an unread row is called to a screen reader.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get nUnread;

  /// Reference: `n.unreadCount`. The centre’s subtitle while anything is unread.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 unread} other{{n} unread}}'**
  String nUnreadCount(int n);

  /// Reference: `n.weather.title`.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow in {city}'**
  String nWeatherTitle(String city);

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

  /// Reference: `ncat.documents`.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get ncatDocuments;

  /// Reference: `ncat.faith`.
  ///
  /// In en, this message translates to:
  /// **'Faith'**
  String get ncatFaith;

  /// Reference: `ncat.finance`.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get ncatFinance;

  /// Reference: `ncat.health`.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get ncatHealth;

  /// Reference: `ncat.markets`.
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get ncatMarkets;

  /// Reference: `ncat.news`.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get ncatNews;

  /// Reference: `ncat.personal`.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get ncatPersonal;

  /// Reference: `ncat.reminders`.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get ncatReminders;

  /// Reference: `ncat.system`.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get ncatSystem;

  /// Reference: `ncat.travel`.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get ncatTravel;

  /// Reference: `ncat.weather`.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get ncatWeather;

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

  /// How long ago a story was published, in hours — the reference writes "1 hr", "2 hr"
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 hr} other{{n} hr}}'**
  String newsAgoHours(int n);

  /// How long ago a story was published, in minutes — the reference writes "18 min"
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 min} other{{n} min}}'**
  String newsAgoMinutes(int n);

  /// Reference: a news category
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get newsCatBusiness;

  /// A category in tool-data.js NEWS_CATEGORIES. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get newsCatHealth;

  /// Reference: a news category
  ///
  /// In en, this message translates to:
  /// **'Karachi'**
  String get newsCatKarachi;

  /// A category in tool-data.js NEWS_CATEGORIES. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get newsCatLifestyle;

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

  /// A category in tool-data.js NEWS_CATEGORIES. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get newsCatTechnology;

  /// A category in tool-data.js NEWS_CATEGORIES. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get newsCatTop;

  /// Reference: a news category
  ///
  /// In en, this message translates to:
  /// **'Wellbeing'**
  String get newsCatWellbeing;

  /// A category in tool-data.js NEWS_CATEGORIES. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'World'**
  String get newsCatWorld;

  /// Reference key news.edition
  ///
  /// In en, this message translates to:
  /// **'Your edition'**
  String get newsEdition;

  /// Reference key news.empty.text
  ///
  /// In en, this message translates to:
  /// **'Try another category, or widen your sources in settings.'**
  String get newsEmptyText;

  /// Reference key news.empty.title
  ///
  /// In en, this message translates to:
  /// **'Nothing in this category yet'**
  String get newsEmptyTitle;

  /// A headline in tool-data.js NEWS — fixture content, translated so no screen mixes languages
  ///
  /// In en, this message translates to:
  /// **'Coastal cities publish a shared adaptation blueprint'**
  String get newsHeadlineGlobalCoastal;

  /// A headline in tool-data.js NEWS — fixture content, translated so no screen mixes languages
  ///
  /// In en, this message translates to:
  /// **'On-device models are quietly reshaping what phones can do offline'**
  String get newsHeadlineGlobalOnDevice;

  /// A headline in tool-data.js NEWS — fixture content, translated so no screen mixes languages
  ///
  /// In en, this message translates to:
  /// **'Central banks signal a slower path on rate cuts into the new year'**
  String get newsHeadlineGlobalRates;

  /// A headline in tool-data.js NEWS — fixture content, translated so no screen mixes languages
  ///
  /// In en, this message translates to:
  /// **'The tactical shift that decided the weekend’s biggest fixture'**
  String get newsHeadlineGlobalTactics;

  /// A headline in tool-data.js NEWS — fixture content, translated so no screen mixes languages
  ///
  /// In en, this message translates to:
  /// **'A short walk after meals does more than a long one before bed'**
  String get newsHeadlineGlobalWalk;

  /// A headline in tool-data.js NEWS — fixture content, translated so no screen mixes languages
  ///
  /// In en, this message translates to:
  /// **'Provincial dengue surveillance moves to a weekly reporting cycle'**
  String get newsHeadlinePkDengue;

  /// A headline in tool-data.js NEWS — fixture content, translated so no screen mixes languages
  ///
  /// In en, this message translates to:
  /// **'Pakistan name a 16-player squad for the home Test series'**
  String get newsHeadlinePkSquad;

  /// A headline in tool-data.js NEWS — fixture content, translated so no screen mixes languages
  ///
  /// In en, this message translates to:
  /// **'Karachi start-ups raised \$84m this quarter, led by fintech'**
  String get newsHeadlinePkStartups;

  /// A headline in tool-data.js NEWS — fixture content, translated so no screen mixes languages
  ///
  /// In en, this message translates to:
  /// **'Regional trade corridor talks resume after a six-month pause'**
  String get newsHeadlinePkTrade;

  /// Reference key news.latest
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get newsLatest;

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

  /// Reference key news.saved
  ///
  /// In en, this message translates to:
  /// **'Your reading'**
  String get newsSaved;

  /// Reference key news.savedCount, pluralised
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 saved story} other{{n} saved stories}}'**
  String newsSavedCount(int n);

  /// Reference key news.savedOpen — the toast the saved row speaks
  ///
  /// In en, this message translates to:
  /// **'Opening saved stories'**
  String get newsSavedOpen;

  /// Reference: a global headline
  ///
  /// In en, this message translates to:
  /// **'A plain-English guide to your first savings goal'**
  String get newsSavings;

  /// Reference key news.search
  ///
  /// In en, this message translates to:
  /// **'Search stories'**
  String get newsSearch;

  /// The source line of a shared top story: the publisher and how long ago
  ///
  /// In en, this message translates to:
  /// **'{source} · {ago}'**
  String newsShareSource(String source, String ago);

  /// Reference: a global headline
  ///
  /// In en, this message translates to:
  /// **'Why a shorter to-do list finishes more work'**
  String get newsShortList;

  /// Reference key news.sources
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get newsSources;

  /// Reference key news.sourcesEdit — the toast the sources row speaks
  ///
  /// In en, this message translates to:
  /// **'Choose your sources'**
  String get newsSourcesEdit;

  /// Reference key news.sourcesValue. The number arrives formatted
  ///
  /// In en, this message translates to:
  /// **'{n} following'**
  String newsSourcesValue(String n);

  /// Reference: a Pakistan headline
  ///
  /// In en, this message translates to:
  /// **'Pakistan name squad for the home Test series'**
  String get newsSquad;

  /// Reference key news.top
  ///
  /// In en, this message translates to:
  /// **'Top story'**
  String get newsTop;

  /// Reference key notes.fIdeas
  ///
  /// In en, this message translates to:
  /// **'Ideas'**
  String get notesFolderIdeas;

  /// Reference key notes.fPersonal
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get notesFolderPersonal;

  /// Reference key notes.fWork
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get notesFolderWork;

  /// Reference key notes.folders
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get notesFolders;

  /// Reference key notes.new — the button that opens the form
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get notesNew;

  /// Reference key notes.noMatch
  ///
  /// In en, this message translates to:
  /// **'No notes match'**
  String get notesNoMatch;

  /// Reference key notes.noMatchText
  ///
  /// In en, this message translates to:
  /// **'Try a different word, or a folder name.'**
  String get notesNoMatchText;

  /// Reference key notes.pinned
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get notesPinned;

  /// Reference key notes.recent
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get notesRecent;

  /// Reference key notes.n1 — a sample note
  ///
  /// In en, this message translates to:
  /// **'Sprint retro points'**
  String get notesSeedN1;

  /// Reference key notes.n1x
  ///
  /// In en, this message translates to:
  /// **'Ship the onboarding fix first, then revisit the empty states…'**
  String get notesSeedN1x;

  /// Reference key notes.n2
  ///
  /// In en, this message translates to:
  /// **'Reading list'**
  String get notesSeedN2;

  /// Reference key notes.n2x
  ///
  /// In en, this message translates to:
  /// **'Three books recommended over dinner — start with the shorter one…'**
  String get notesSeedN2x;

  /// Reference key notes.n3
  ///
  /// In en, this message translates to:
  /// **'App idea'**
  String get notesSeedN3;

  /// Reference key notes.n3x
  ///
  /// In en, this message translates to:
  /// **'A tool that quietly tracks what you actually reread…'**
  String get notesSeedN3x;

  /// Reference key notes.n4
  ///
  /// In en, this message translates to:
  /// **'Meeting notes'**
  String get notesSeedN4;

  /// Reference key notes.n4x
  ///
  /// In en, this message translates to:
  /// **'Budget signed off, revisit headcount in November…'**
  String get notesSeedN4x;

  /// Reference key notes.total
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTotal;

  /// Reference: `n.pref.badge`.
  ///
  /// In en, this message translates to:
  /// **'Badge count'**
  String get notifPrefBadge;

  /// Reference: `n.pref.badgeSub`.
  ///
  /// In en, this message translates to:
  /// **'Show the unread count on the bell'**
  String get notifPrefBadgeSub;

  /// Reference: `n.pref.categories`.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get notifPrefCategories;

  /// Reference: `n.pref.categoriesSub`.
  ///
  /// In en, this message translates to:
  /// **'Switch off anything you don’t want to hear about'**
  String get notifPrefCategoriesSub;

  /// Reference: `n.pref.earlier`. The quiet-hours stepper's decrement.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get notifPrefEarlier;

  /// Reference: `n.pref.from`, lowercase as the reference renders it. The first quiet-hours stepper row.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get notifPrefFrom;

  /// Reference: `n.pref.general`.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get notifPrefGeneral;

  /// Reference: `n.pref.haptics`.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get notifPrefHaptics;

  /// Reference: `n.pref.inApp`.
  ///
  /// In en, this message translates to:
  /// **'In-app notifications'**
  String get notifPrefInApp;

  /// Reference: `n.pref.inAppSub`.
  ///
  /// In en, this message translates to:
  /// **'Banners and the notification centre'**
  String get notifPrefInAppSub;

  /// Reference: `n.pref.later`. The quiet-hours stepper's increment.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get notifPrefLater;

  /// Reference: `n.pref.perTool`.
  ///
  /// In en, this message translates to:
  /// **'By tool'**
  String get notifPrefPerTool;

  /// Reference: `n.pref.perToolSub`.
  ///
  /// In en, this message translates to:
  /// **'Fine-grained control over each kind of alert'**
  String get notifPrefPerToolSub;

  /// Reference: `n.pref.p`. The Notifications screen and the Privacy route show the *same* preference with different words and opposite polarity, which is deliberate in the reference: one asks whether to show, the other whether to hide.review
  ///
  /// In en, this message translates to:
  /// **'Show previews'**
  String get notifPrefPreview;

  /// Reference: `n.pref.p`. The Notifications screen and the Privacy route show the *same* preference with different words and opposite polarity, which is deliberate in the reference: one asks whether to show, the other whether to hide.reviewSub
  ///
  /// In en, this message translates to:
  /// **'Include the detail, not just the title'**
  String get notifPrefPreviewSub;

  /// Reference: `n.pref.privacySub`.
  ///
  /// In en, this message translates to:
  /// **'What a notification is allowed to reveal'**
  String get notifPrefPrivacySub;

  /// Reference: `n.pref.push`.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get notifPrefPush;

  /// Reference: `n.pref.quiet`.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get notifPrefQuiet;

  /// Reference: `n.pref.quietOn`.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get notifPrefQuietOn;

  /// Reference: `n.pref.quietSub`.
  ///
  /// In en, this message translates to:
  /// **'Nothing interrupts you; everything still arrives'**
  String get notifPrefQuietSub;

  /// Reference: `n.pref.restore`.
  ///
  /// In en, this message translates to:
  /// **'Restore dismissed'**
  String get notifPrefRestore;

  /// Reference: `n.pref.s`. The Notifications screen and the Privacy route show the *same* preference with different words and opposite polarity, which is deliberate in the reference: one asks whether to show, the other whether to hide.ensitive
  ///
  /// In en, this message translates to:
  /// **'Preview sensitive content'**
  String get notifPrefSensitive;

  /// Reference: `n.pref.s`. The Notifications screen and the Privacy route show the *same* preference with different words and opposite polarity, which is deliberate in the reference: one asks whether to show, the other whether to hide.ensitiveSub
  ///
  /// In en, this message translates to:
  /// **'Health, documents and money say only that something changed'**
  String get notifPrefSensitiveSub;

  /// Reference: `n.pref.sound`.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get notifPrefSound;

  /// Reference: `n.pref.to`. The second quiet-hours stepper row.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get notifPrefTo;

  /// Reference: `ntype.billDue`.
  ///
  /// In en, this message translates to:
  /// **'Bills due soon'**
  String get ntypeBillDue;

  /// Reference: `ntype.billOverdue`.
  ///
  /// In en, this message translates to:
  /// **'Overdue bills'**
  String get ntypeBillOverdue;

  /// Reference: `ntype.docExpiry`.
  ///
  /// In en, this message translates to:
  /// **'Document expiry'**
  String get ntypeDocExpiry;

  /// Reference: `ntype.flightChange`.
  ///
  /// In en, this message translates to:
  /// **'Flight changes'**
  String get ntypeFlightChange;

  /// Reference: `ntype.forecast`.
  ///
  /// In en, this message translates to:
  /// **'Daily forecast'**
  String get ntypeForecast;

  /// Reference: `ntype.habitReminder`.
  ///
  /// In en, this message translates to:
  /// **'Habit reminders'**
  String get ntypeHabitReminder;

  /// Reference: `ntype.marketMove`.
  ///
  /// In en, this message translates to:
  /// **'Market movement'**
  String get ntypeMarketMove;

  /// Reference: `ntype.medication`.
  ///
  /// In en, this message translates to:
  /// **'Medication reminders'**
  String get ntypeMedication;

  /// Reference: `ntype.outage`.
  ///
  /// In en, this message translates to:
  /// **'Power outages'**
  String get ntypeOutage;

  /// Reference: `ntype.parcelUpdate`.
  ///
  /// In en, this message translates to:
  /// **'Parcel updates'**
  String get ntypeParcelUpdate;

  /// Reference: `ntype.prayerReminder`.
  ///
  /// In en, this message translates to:
  /// **'Prayer reminder'**
  String get ntypePrayerReminder;

  /// Reference: `ntype.severeWeather`.
  ///
  /// In en, this message translates to:
  /// **'Severe weather'**
  String get ntypeSevereWeather;

  /// Reference: `ntype.subRenewal`.
  ///
  /// In en, this message translates to:
  /// **'Subscription renewals'**
  String get ntypeSubRenewal;

  /// Reference: `ntype.taskReminder`.
  ///
  /// In en, this message translates to:
  /// **'Task reminders'**
  String get ntypeTaskReminder;

  /// Reference: `ntype.trainDelay`.
  ///
  /// In en, this message translates to:
  /// **'Train delays'**
  String get ntypeTrainDelay;

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

  /// Reference: `pers.appLanguage`.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get persAppLanguage;

  /// Reference: `pers.city`.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get persCity;

  /// Reference: `pers.citySub`.
  ///
  /// In en, this message translates to:
  /// **'Used for weather, local information and nearby places'**
  String get persCitySub;

  /// Reference: `pers.content`.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get persContent;

  /// Reference: `pers.country`.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get persCountry;

  /// Reference: `pers.countrySub`.
  ///
  /// In en, this message translates to:
  /// **'Unlocks local services — nothing else'**
  String get persCountrySub;

  /// Reference: `pers.currency`.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get persCurrency;

  /// Reference: `pers.currencyAuto`.
  ///
  /// In en, this message translates to:
  /// **'Automatic ({code})'**
  String persCurrencyAuto(String code);

  /// Reference: `pers.dataSafe`.
  ///
  /// In en, this message translates to:
  /// **'Changing any of this only changes what you see. Your notes, tasks and records stay exactly where they are.'**
  String get persDataSafe;

  /// Reference: `pers.finance`.
  ///
  /// In en, this message translates to:
  /// **'Financial information'**
  String get persFinance;

  /// Reference: `pers.financeSub`.
  ///
  /// In en, this message translates to:
  /// **'Rates, gold and markets'**
  String get persFinanceSub;

  /// Reference: `pers.formatting`.
  ///
  /// In en, this message translates to:
  /// **'Language & formatting'**
  String get persFormatting;

  /// Reference: `pers.interests`.
  ///
  /// In en, this message translates to:
  /// **'Your interests'**
  String get persInterests;

  /// Reference: `pers.interestsHint`.
  ///
  /// In en, this message translates to:
  /// **'Pick at least {min}. They decide what fills your home screen.'**
  String persInterestsHint(int min);

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

  /// Reference: `pers.news`.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get persNews;

  /// Reference: `pers.newsSub`.
  ///
  /// In en, this message translates to:
  /// **'Headlines on Explore and Today'**
  String get persNewsSub;

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

  /// Reference: `pers.recos`.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get persRecos;

  /// Reference: `pers.recosSub`.
  ///
  /// In en, this message translates to:
  /// **'Suggest tools based on how you use Lume'**
  String get persRecosSub;

  /// Reference: `pers.region`.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get persRegion;

  /// Reference: `pers.savePrefs`.
  ///
  /// In en, this message translates to:
  /// **'Save preferences'**
  String get persSavePrefs;

  /// Reference: `pers.saved`.
  ///
  /// In en, this message translates to:
  /// **'Your app has been updated'**
  String get persSaved;

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

  /// Reference: `pers.sport`.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get persSport;

  /// Reference: `pers.sportSub`.
  ///
  /// In en, this message translates to:
  /// **'Live cricket scores'**
  String get persSportSub;

  /// Reference: `pers.sub`.
  ///
  /// In en, this message translates to:
  /// **'Change any of this whenever you like'**
  String get persSub;

  /// Reference: `pers.time12`.
  ///
  /// In en, this message translates to:
  /// **'12-hour'**
  String get persTime12;

  /// Reference: `pers.time24`.
  ///
  /// In en, this message translates to:
  /// **'24-hour'**
  String get persTime24;

  /// Reference: `pers.timeFormat`.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get persTimeFormat;

  /// Reference: `pers.title`.
  ///
  /// In en, this message translates to:
  /// **'Personalisation'**
  String get persTitle;

  /// Reference: `pers.units`.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get persUnits;

  /// Reference: `pers.unitsAuto`.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get persUnitsAuto;

  /// Reference: `pers.unitsImperial`.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get persUnitsImperial;

  /// Reference: `pers.unitsMetric`.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get persUnitsMetric;

  /// Reference key pers.useLocation
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get persUseLocation;

  /// Reference: `pers.useLocationSub`.
  ///
  /// In en, this message translates to:
  /// **'Optional — you can always set this by hand'**
  String get persUseLocationSub;

  /// Shown on the "Use my current location" row while one position is read.
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get persLocating;

  /// No position could be read, or it timed out.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable — choose your city by hand.'**
  String get persLocationUnavailable;

  /// The reader declined the location permission this time.
  ///
  /// In en, this message translates to:
  /// **'Location wasn\'t allowed — choose your city by hand.'**
  String get persLocationDenied;

  /// The location permission was refused for good; only system Settings can change it.
  ///
  /// In en, this message translates to:
  /// **'Location is off for Lume in your phone\'s Settings — choose your city by hand.'**
  String get persLocationBlocked;

  /// The device's location service is off.
  ///
  /// In en, this message translates to:
  /// **'Location is switched off on this device — choose your city by hand.'**
  String get persLocationOff;

  /// Reference: `pers.whereYouAre`.
  ///
  /// In en, this message translates to:
  /// **'Where you are'**
  String get persWhereYouAre;

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

  /// Reference: `profile.sub`.
  ///
  /// In en, this message translates to:
  /// **'Preferences and your saved things'**
  String get profileSub;

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

  /// Said once the text is on the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get qrCopied;

  /// Copies the decoded text
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get qrCopy;

  /// Copies a Wi-Fi code's network name, never its password
  ///
  /// In en, this message translates to:
  /// **'Copy network name'**
  String get qrCopyNetwork;

  /// Reference key qr.detects
  ///
  /// In en, this message translates to:
  /// **'What it recognises'**
  String get qrDetects;

  /// Label over the full decoded text
  ///
  /// In en, this message translates to:
  /// **'What the code says'**
  String get qrFullText;

  /// Reference key qr.hint
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a code'**
  String get qrHint;

  /// Kind of QR code: a vCard or MeCard
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get qrKindContact;

  /// Kind of QR code: a mailto: address
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get qrKindEmail;

  /// Reference key qr.kind.link
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get qrKindLink;

  /// Kind of QR code: geo: coordinates
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get qrKindLocation;

  /// Kind of QR code: an SMS to a number
  ///
  /// In en, this message translates to:
  /// **'Text message'**
  String get qrKindMessage;

  /// Kind of QR code: a tel: number
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get qrKindPhone;

  /// Kind of QR code: a scheme Lume refuses, or an address that fails its checks
  ///
  /// In en, this message translates to:
  /// **'A link Lume won\'t open'**
  String get qrKindRefused;

  /// Kind of QR code: plain text
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get qrKindText;

  /// Reference key qr.kind.wifi
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi network'**
  String get qrKindWifi;

  /// Under a contact code
  ///
  /// In en, this message translates to:
  /// **'Lume doesn\'t add contacts'**
  String get qrNoteContact;

  /// Under an email code that carried a subject or body, which Lume drops
  ///
  /// In en, this message translates to:
  /// **'The code\'s own subject and text aren\'t filled in'**
  String get qrNoteEmail;

  /// Under an http:// destination
  ///
  /// In en, this message translates to:
  /// **'Not secure — this site\'s connection isn\'t encrypted'**
  String get qrNoteInsecure;

  /// Under a location code
  ///
  /// In en, this message translates to:
  /// **'Lume doesn\'t open maps yet'**
  String get qrNoteLocation;

  /// Under an SMS code that carried a prefilled message, which Lume drops
  ///
  /// In en, this message translates to:
  /// **'The code\'s own message text isn\'t filled in'**
  String get qrNoteMessage;

  /// Under a refused code
  ///
  /// In en, this message translates to:
  /// **'Lume doesn\'t open this kind of link. You can copy it.'**
  String get qrNoteRefused;

  /// Under a Wi-Fi code
  ///
  /// In en, this message translates to:
  /// **'Lume doesn\'t join networks. The password stays hidden.'**
  String get qrNoteWifi;

  /// Opens a new email to the address
  ///
  /// In en, this message translates to:
  /// **'Write an email'**
  String get qrOpenEmail;

  /// Said when opening the address fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open it'**
  String get qrOpenFailed;

  /// Opens Messages to the number
  ///
  /// In en, this message translates to:
  /// **'Open in Messages'**
  String get qrOpenMessage;

  /// Opens the dialer with the number; never calls
  ///
  /// In en, this message translates to:
  /// **'Open in Phone'**
  String get qrOpenPhone;

  /// Opens a checked web address in the browser
  ///
  /// In en, this message translates to:
  /// **'Open website'**
  String get qrOpenSite;

  /// Said when no app takes the address
  ///
  /// In en, this message translates to:
  /// **'Nothing on this device can open it'**
  String get qrOpenUnavailable;

  /// Subtitle of the sheet showing what a QR code said
  ///
  /// In en, this message translates to:
  /// **'Nothing opens unless you choose it'**
  String get qrResultNote;

  /// Reference key qr.scan
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get qrScan;

  /// Reference key qr.step.act
  ///
  /// In en, this message translates to:
  /// **'Open, copy or save'**
  String get qrStepAct;

  /// Reference key qr.step.detect
  ///
  /// In en, this message translates to:
  /// **'Lume reads it automatically'**
  String get qrStepDetect;

  /// Reference key qr.step.point
  ///
  /// In en, this message translates to:
  /// **'Point at the code'**
  String get qrStepPoint;

  /// Reference: `t("rates.buy") + " " + num` — the buying rate. The number arrives formatted
  ///
  /// In en, this message translates to:
  /// **'Buy {value}'**
  String ratesBuyValue(String value);

  /// Reference key rates.converter
  ///
  /// In en, this message translates to:
  /// **'What is my gold worth?'**
  String get ratesConverter;

  /// Reference key rates.currencies
  ///
  /// In en, this message translates to:
  /// **'Currencies'**
  String get ratesCurrencies;

  /// A chart axis label, days before today — the reference writes "30d", "15d"
  ///
  /// In en, this message translates to:
  /// **'{n}d'**
  String ratesDaysAgo(int n);

  /// Reference key rates.gold22
  ///
  /// In en, this message translates to:
  /// **'Gold 22k'**
  String get ratesGold22;

  /// Reference key rates.gold24
  ///
  /// In en, this message translates to:
  /// **'Gold 24k'**
  String get ratesGold24;

  /// Reference key rates.goldHistory — the chart's accessible name
  ///
  /// In en, this message translates to:
  /// **'Gold per tola'**
  String get ratesGoldHistory;

  /// Reference key rates.goldHistoryCap
  ///
  /// In en, this message translates to:
  /// **'Open market close, last 30 days'**
  String get ratesGoldHistoryCap;

  /// Reference key rates.history
  ///
  /// In en, this message translates to:
  /// **'Gold, 30 days'**
  String get ratesHistory;

  /// What the 30-day chart says to a screen reader after its name — the first and last close, formatted
  ///
  /// In en, this message translates to:
  /// **'From {from} to {to}'**
  String ratesHistoryRange(String from, String to);

  /// Reference key rates.metal
  ///
  /// In en, this message translates to:
  /// **'Metal'**
  String get ratesMetal;

  /// Reference key rates.metals
  ///
  /// In en, this message translates to:
  /// **'Metals'**
  String get ratesMetals;

  /// Reference key rates.noMatch
  ///
  /// In en, this message translates to:
  /// **'No currency matches'**
  String get ratesNoMatch;

  /// Reference key rates.noMatchText
  ///
  /// In en, this message translates to:
  /// **'Try a three-letter code such as USD or EUR.'**
  String get ratesNoMatchText;

  /// Reference key rates.openMarket
  ///
  /// In en, this message translates to:
  /// **'Open market'**
  String get ratesOpenMarket;

  /// Reference: `"/ " + t("unit.tola")` — a price per unit, after the figure
  ///
  /// In en, this message translates to:
  /// **'/ {unit}'**
  String ratesPerUnit(String unit);

  /// Reference key rates.search
  ///
  /// In en, this message translates to:
  /// **'Search currencies'**
  String get ratesSearch;

  /// Reference: `t("rates.sell") + " " + num` — the selling rate. The number arrives formatted
  ///
  /// In en, this message translates to:
  /// **'Sell {value}'**
  String ratesSellValue(String value);

  /// The share card: a metal, its price, and the unit ("/ tola"), all formatted
  ///
  /// In en, this message translates to:
  /// **'{metal}: {value} {unit}'**
  String ratesShareText(String metal, String value, String unit);

  /// Reference key rates.silver
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get ratesSilver;

  /// Reference key rates.silverTola
  ///
  /// In en, this message translates to:
  /// **'Silver / tola'**
  String get ratesSilverTola;

  /// Reference key rates.weight
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get ratesWeight;

  /// Reference key rates.worth
  ///
  /// In en, this message translates to:
  /// **'Worth'**
  String get ratesWorth;

  /// Under a religious passage shown in its verified English because no verified translation into the interface language exists. Describes the passage; never a translation of it
  ///
  /// In en, this message translates to:
  /// **'Shown in English — no verified translation in this language yet'**
  String get readerFallbackEnglish;

  /// Reference key rec.add
  ///
  /// In en, this message translates to:
  /// **'Add {noun}'**
  String recAdd(String noun);

  /// Reference key rec.addFirst
  ///
  /// In en, this message translates to:
  /// **'Add first {noun}'**
  String recAddFirst(String noun);

  /// Reference key rec.added
  ///
  /// In en, this message translates to:
  /// **'{noun} added'**
  String recAdded(String noun);

  /// Reference key rec.attach
  ///
  /// In en, this message translates to:
  /// **'Add photo or document'**
  String get recAttach;

  /// Reference key rec.attachSoon
  ///
  /// In en, this message translates to:
  /// **'Attachments are coming soon'**
  String get recAttachSoon;

  /// Reference key rec.attached
  ///
  /// In en, this message translates to:
  /// **'Attached'**
  String get recAttached;

  /// Reference key rec.backToList
  ///
  /// In en, this message translates to:
  /// **'Back to {noun}'**
  String recBackToList(String noun);

  /// Reference key rec.checkFields
  ///
  /// In en, this message translates to:
  /// **'Check the highlighted fields'**
  String get recCheckFields;

  /// Spoken label of the Clear action under a task's optional due date
  ///
  /// In en, this message translates to:
  /// **'Clear due date'**
  String get recClearDueDate;

  /// Spoken label of the Clear action under an event's optional time
  ///
  /// In en, this message translates to:
  /// **'Clear event time'**
  String get recClearEventTime;

  /// Reference key rec.cleared, after a bulk clear
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 removed} other{{n} removed}}'**
  String recCleared(int n);

  /// Reference key rec.confirmNote
  ///
  /// In en, this message translates to:
  /// **'Changes are saved only after confirmation'**
  String get recConfirmNote;

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

  /// Reference key rec.couldNotRefresh
  ///
  /// In en, this message translates to:
  /// **'Could not refresh'**
  String get recCouldNotRefresh;

  /// Reference key rec.count — the collection's condition under the tool's name. The reference writes "{n} records" for one as well; this is plural
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 record} other{{n} records}}'**
  String recCount(int n);

  /// Reference key rec.created
  ///
  /// In en, this message translates to:
  /// **'Created {when}'**
  String recCreated(String when);

  /// Reference key rec.createdToday
  ///
  /// In en, this message translates to:
  /// **'Created today'**
  String get recCreatedToday;

  /// Reference key rec.createdYesterday
  ///
  /// In en, this message translates to:
  /// **'Created yesterday'**
  String get recCreatedYesterday;

  /// Reference key rec.daysAgo — only ever 2 to 30 in the reference
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 day ago} other{{n} days ago}}'**
  String recDaysAgo(int n);

  /// Reference key rec.delete
  ///
  /// In en, this message translates to:
  /// **'Delete {noun}'**
  String recDelete(String noun);

  /// Reference key rec.deleteAsk
  ///
  /// In en, this message translates to:
  /// **'Delete this {noun}?'**
  String recDeleteAsk(String noun);

  /// Reference key rec.deleteFailed
  ///
  /// In en, this message translates to:
  /// **'Could not delete this record'**
  String get recDeleteFailed;

  /// Reference key rec.deleteTextFinal
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed. This action cannot be undone.'**
  String recDeleteTextFinal(String name);

  /// Reference key rec.deleteTextUndo
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed. You can undo this straight away.'**
  String recDeleteTextUndo(String name);

  /// Reference key rec.deleted
  ///
  /// In en, this message translates to:
  /// **'{noun} deleted'**
  String recDeleted(String noun);

  /// Reference key rec.deletedFinal
  ///
  /// In en, this message translates to:
  /// **'{noun} deleted permanently'**
  String recDeletedFinal(String noun);

  /// Reference key rec.detailTitle
  ///
  /// In en, this message translates to:
  /// **'{noun} details'**
  String recDetailTitle(String noun);

  /// Reference key rec.details
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get recDetails;

  /// Reference key rec.discard
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get recDiscard;

  /// Reference key rec.discardAsk
  ///
  /// In en, this message translates to:
  /// **'Discard your changes?'**
  String get recDiscardAsk;

  /// Reference key rec.discardText
  ///
  /// In en, this message translates to:
  /// **'What you typed will not be saved.'**
  String get recDiscardText;

  /// Reference key rec.doc.education
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get recDocEducation;

  /// Reference key rec.doc.identity
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get recDocIdentity;

  /// Reference key rec.doc.insurance
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get recDocInsurance;

  /// Reference key rec.doc.other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get recDocOther;

  /// Reference key rec.doc.property
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get recDocProperty;

  /// Reference key rec.doc.vehicle
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get recDocVehicle;

  /// Reference key rec.documents.emptyText
  ///
  /// In en, this message translates to:
  /// **'Add one and Lume will remind you before it expires.'**
  String get recDocumentsEmptyText;

  /// Reference key rec.documents.emptyTitle
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get recDocumentsEmptyTitle;

  /// Reference key rec.documents.noun — the noun inside a sentence
  ///
  /// In en, this message translates to:
  /// **'document'**
  String get recDocumentsNoun;

  /// Reference key rec.documents.nounPlural
  ///
  /// In en, this message translates to:
  /// **'documents'**
  String get recDocumentsNounPlural;

  /// Reference key rec.documents.ph
  ///
  /// In en, this message translates to:
  /// **'Passport, licence, policy…'**
  String get recDocumentsPh;

  /// Reference key rec.done
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get recDone;

  /// Reference key rec.edit
  ///
  /// In en, this message translates to:
  /// **'Edit {noun}'**
  String recEdit(String noun);

  /// Reference key rec.editing
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get recEditing;

  /// Reference key rec.err.positive
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero'**
  String get recErrPositive;

  /// Reference key rec.err.required
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String recErrRequired(String field);

  /// Reference key rec.events.emptyText, without its promise of the calendar and Today: neither build shows events there (C86)
  ///
  /// In en, this message translates to:
  /// **'Add an event and it will appear here.'**
  String get recEventsEmptyText;

  /// Reference key rec.events.emptyTitle
  ///
  /// In en, this message translates to:
  /// **'Nothing planned'**
  String get recEventsEmptyTitle;

  /// Reference key rec.events.noun
  ///
  /// In en, this message translates to:
  /// **'event'**
  String get recEventsNoun;

  /// Reference key rec.events.nounPlural
  ///
  /// In en, this message translates to:
  /// **'events'**
  String get recEventsNounPlural;

  /// Reference key rec.events.ph
  ///
  /// In en, this message translates to:
  /// **'What is happening?'**
  String get recEventsPh;

  /// Reference key rec.expenses.emptyText
  ///
  /// In en, this message translates to:
  /// **'Add a record to understand where your money goes and build useful summaries.'**
  String get recExpensesEmptyText;

  /// Reference key rec.expenses.emptyTitle
  ///
  /// In en, this message translates to:
  /// **'Track your first expense'**
  String get recExpensesEmptyTitle;

  /// Reference key rec.expenses.noun — sentence-internal; a line that starts with it is capitalised where the script has case
  ///
  /// In en, this message translates to:
  /// **'expense'**
  String get recExpensesNoun;

  /// Reference key rec.expenses.nounPlural
  ///
  /// In en, this message translates to:
  /// **'expenses'**
  String get recExpensesNounPlural;

  /// Reference key rec.expenses.ph
  ///
  /// In en, this message translates to:
  /// **'What did you spend on?'**
  String get recExpensesPh;

  /// Reference key rec.expiresOn
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String recExpiresOn(String date);

  /// Reference key rec.f.aisle
  ///
  /// In en, this message translates to:
  /// **'Aisle'**
  String get recFieldAisle;

  /// Reference key rec.f.amount
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get recFieldAmount;

  /// Reference key rec.f.category
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get recFieldCategory;

  /// Reference key rec.f.completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get recFieldCompleted;

  /// Reference key rec.f.date
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get recFieldDate;

  /// Reference key rec.f.due
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get recFieldDue;

  /// Reference key rec.f.estimate
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get recFieldEstimate;

  /// Reference key rec.f.expiry
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get recFieldExpiry;

  /// Reference key rec.f.folder
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get recFieldFolder;

  /// Reference key rec.f.holder
  ///
  /// In en, this message translates to:
  /// **'Holder'**
  String get recFieldHolder;

  /// Reference key rec.f.inBasket
  ///
  /// In en, this message translates to:
  /// **'In basket'**
  String get recFieldInBasket;

  /// Reference key rec.f.item
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get recFieldItem;

  /// Reference key rec.f.list
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get recFieldList;

  /// Reference key rec.f.note
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get recFieldNote;

  /// Reference key rec.f.notes
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get recFieldNotes;

  /// Reference key rec.f.payment
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get recFieldPayment;

  /// Reference key rec.f.people
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get recFieldPeople;

  /// Reference key rec.f.pinned
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get recFieldPinned;

  /// Reference key rec.f.priority
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get recFieldPriority;

  /// Reference key rec.f.quantity
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get recFieldQuantity;

  /// Reference key rec.f.receipt
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get recFieldReceipt;

  /// Reference key rec.f.reference
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get recFieldReference;

  /// Reference key rec.f.task
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get recFieldTask;

  /// Reference key rec.f.time
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get recFieldTime;

  /// Reference key rec.f.timezone
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get recFieldTimezone;

  /// Reference key rec.f.title
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get recFieldTitle;

  /// Reference key rec.f.where
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get recFieldWhere;

  /// Reference key rec.gone
  ///
  /// In en, this message translates to:
  /// **'That record is no longer here'**
  String get recGone;

  /// Reference key rec.goneText
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted.'**
  String get recGoneText;

  /// Reference key rec.importLater
  ///
  /// In en, this message translates to:
  /// **'You can import records later'**
  String get recImportLater;

  /// Reference key rec.information
  ///
  /// In en, this message translates to:
  /// **'{noun} information'**
  String recInformation(String noun);

  /// Reference key rec.keepEditing
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get recKeepEditing;

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

  /// Reference key rec.modified
  ///
  /// In en, this message translates to:
  /// **'Edited {when}'**
  String recModified(String when);

  /// Reference key rec.newRecord
  ///
  /// In en, this message translates to:
  /// **'New record'**
  String get recNewRecord;

  /// Reference key rec.noDue
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get recNoDue;

  /// Reference key rec.noMatch
  ///
  /// In en, this message translates to:
  /// **'Nothing matches'**
  String get recNoMatch;

  /// Reference key rec.noMatchText
  ///
  /// In en, this message translates to:
  /// **'Try a different word, or clear the filters.'**
  String get recNoMatchText;

  /// An event saved without a time; the reference stores an empty string and shows a dash
  ///
  /// In en, this message translates to:
  /// **'No time set'**
  String get recNoTime;

  /// Reference key rec.none
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get recNone;

  /// Reference key rec.noneYet
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get recNoneYet;

  /// Reference key rec.notAttached
  ///
  /// In en, this message translates to:
  /// **'Not attached'**
  String get recNotAttached;

  /// Reference key rec.notes.emptyText, without "stay on this device": this build keeps records only while Lume is open (C74, C86)
  ///
  /// In en, this message translates to:
  /// **'Notes are searchable the moment you save them.'**
  String get recNotesEmptyText;

  /// Reference key rec.notes.emptyTitle
  ///
  /// In en, this message translates to:
  /// **'Nothing written down yet'**
  String get recNotesEmptyTitle;

  /// Reference key rec.notes.noun
  ///
  /// In en, this message translates to:
  /// **'note'**
  String get recNotesNoun;

  /// Reference key rec.notes.nounPlural
  ///
  /// In en, this message translates to:
  /// **'notes'**
  String get recNotesNounPlural;

  /// Reference key rec.notes.ph
  ///
  /// In en, this message translates to:
  /// **'Give it a title'**
  String get recNotesPh;

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

  /// Reference key rec.open
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get recOpen;

  /// Reference key rec.optional
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get recOptional;

  /// Reference key rec.pay.card
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get recPayCard;

  /// Reference key rec.pay.cash
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get recPayCash;

  /// Reference key rec.pay.transfer
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get recPayTransfer;

  /// Reference key rec.pay.wallet
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get recPayWallet;

  /// Reference key rec.pinned — a badge
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get recPinned;

  /// Reference key rec.priority.high
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get recPriorityHigh;

  /// Reference key rec.priority.normal
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get recPriorityNormal;

  /// Reference key rec.queued
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get recQueued;

  /// Reference key rec.recordId
  ///
  /// In en, this message translates to:
  /// **'Record ID {id}'**
  String recRecordId(String id);

  /// Reference key rec.reload
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get recReload;

  /// Reference key rec.reloaded
  ///
  /// In en, this message translates to:
  /// **'Loaded the newer version'**
  String get recReloaded;

  /// Reference key rec.review
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get recReview;

  /// Reference key rec.save
  ///
  /// In en, this message translates to:
  /// **'Save {noun}'**
  String recSave(String noun);

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

  /// Reference key rec.saving
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get recSaving;

  /// Reference key rec.search — the plural noun
  ///
  /// In en, this message translates to:
  /// **'Search {noun}'**
  String recSearch(String noun);

  /// Reference key rec.seed.coffee
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get recSeedCoffee;

  /// Reference key rec.seed.family — a sample holder
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get recSeedFamily;

  /// Reference key rec.seed.groceries — a demonstration record
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get recSeedGroceries;

  /// Reference key rec.seed.groceriesNote
  ///
  /// In en, this message translates to:
  /// **'Weekly household groceries'**
  String get recSeedGroceriesNote;

  /// Reference key rec.seed.insurance — a sample record
  ///
  /// In en, this message translates to:
  /// **'Health insurance'**
  String get recSeedInsurance;

  /// Reference key rec.seed.internet
  ///
  /// In en, this message translates to:
  /// **'Internet bill'**
  String get recSeedInternet;

  /// Reference key rec.seed.licence — a sample record
  ///
  /// In en, this message translates to:
  /// **'Driving licence'**
  String get recSeedLicence;

  /// Reference key rec.seed.nid — a sample record
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get recSeedNid;

  /// Reference key rec.seed.passport — a sample record
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get recSeedPassport;

  /// Reference key rec.seed.pharmacy
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get recSeedPharmacy;

  /// Reference key rec.seed.taxi
  ///
  /// In en, this message translates to:
  /// **'Taxi'**
  String get recSeedTaxi;

  /// Reference key rec.seed.you — a sample holder
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get recSeedYou;

  /// Reference key rec.selectText
  ///
  /// In en, this message translates to:
  /// **'Choose one from the list to see it here.'**
  String get recSelectText;

  /// Reference key rec.selectTitle
  ///
  /// In en, this message translates to:
  /// **'Nothing selected'**
  String get recSelectTitle;

  /// Reference key rec.shopping.clear — the bulk clear of ticked items
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Clear 1 in the basket} other{Clear {n} in the basket}}'**
  String recShoppingClear(int n);

  /// Reference key rec.shopping.clearConfirm
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 item will be removed from the list. This cannot be undone.} other{{n} items will be removed from the list. This cannot be undone.}}'**
  String recShoppingClearConfirm(int n);

  /// Reference key rec.shopping.emptyText
  ///
  /// In en, this message translates to:
  /// **'Add what you need and tick it off as you shop.'**
  String get recShoppingEmptyText;

  /// Reference key rec.shopping.emptyTitle
  ///
  /// In en, this message translates to:
  /// **'Your list is empty'**
  String get recShoppingEmptyTitle;

  /// Reference key rec.shopping.noun
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get recShoppingNoun;

  /// Reference key rec.shopping.nounPlural
  ///
  /// In en, this message translates to:
  /// **'shopping list'**
  String get recShoppingNounPlural;

  /// Reference key rec.shopping.ph
  ///
  /// In en, this message translates to:
  /// **'What do you need?'**
  String get recShoppingPh;

  /// Reference key rec.shopping.qtyPh
  ///
  /// In en, this message translates to:
  /// **'2 kg'**
  String get recShoppingQtyPh;

  /// Reference key rec.toBuy
  ///
  /// In en, this message translates to:
  /// **'To buy'**
  String get recToBuy;

  /// Reference key rec.todos.emptyText, without its promise of Today: neither build shows tasks there (C86)
  ///
  /// In en, this message translates to:
  /// **'Add a task and it will show up here.'**
  String get recTodosEmptyText;

  /// Reference key rec.todos.emptyTitle
  ///
  /// In en, this message translates to:
  /// **'Nothing on your list'**
  String get recTodosEmptyTitle;

  /// Reference key rec.todos.noun
  ///
  /// In en, this message translates to:
  /// **'task'**
  String get recTodosNoun;

  /// Reference key rec.todos.nounPlural
  ///
  /// In en, this message translates to:
  /// **'tasks'**
  String get recTodosNounPlural;

  /// Reference key rec.todos.ph
  ///
  /// In en, this message translates to:
  /// **'What needs doing?'**
  String get recTodosPh;

  /// Reference key rec.undo
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get recUndo;

  /// Reference key rec.undone
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get recUndone;

  /// Reference key rec.update
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get recUpdate;

  /// Reference key rec.updated
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get recUpdated;

  /// Reference key rec.viewCached
  ///
  /// In en, this message translates to:
  /// **'View cached records'**
  String get recViewCached;

  /// Follow my region, where the region has several time zones and the city does not decide
  ///
  /// In en, this message translates to:
  /// **'Your region has more than one time zone, so nothing here is grouped by day. Your records are all listed above. Choose a time zone in Profile › Time.'**
  String get recZoneChooseText;

  /// No configured zone and no verified device zone
  ///
  /// In en, this message translates to:
  /// **'No time zone is set and this device’s isn’t known, so nothing here is grouped by day. Your records are all listed above. Choose a time zone in Profile › Time.'**
  String get recZoneMissingText;

  /// An explicit time zone that is unknown or malformed; {zone} is the identifier as stored, isolated for direction
  ///
  /// In en, this message translates to:
  /// **'Lume can’t read the time zone {zone}, so nothing here is grouped by day. Your records are all listed above. Choose a time zone in Profile › Time.'**
  String recZoneUnknownText(String zone);

  /// Tools that group by the reader’s day, when their time zone cannot be resolved
  ///
  /// In en, this message translates to:
  /// **'Your day can’t be worked out'**
  String get recZoneUnknownTitle;

  /// A cuisine in tool-data.js RECIPES. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get recipeCuisineGlobal;

  /// A cuisine in tool-data.js RECIPES. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Levantine'**
  String get recipeCuisineLevantine;

  /// A cuisine in tool-data.js RECIPES. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Mediterranean'**
  String get recipeCuisineMediterranean;

  /// A cuisine in tool-data.js RECIPES. The reference writes it in English in every language
  ///
  /// In en, this message translates to:
  /// **'Pakistani'**
  String get recipeCuisinePakistani;

  /// A dish in tool-data.js RECIPES — a name, transliterated where it is one and translated where it describes
  ///
  /// In en, this message translates to:
  /// **'Beef Pulao'**
  String get recipeNameBeefPulao;

  /// A dish in tool-data.js RECIPES — a name, transliterated where it is one and translated where it describes
  ///
  /// In en, this message translates to:
  /// **'Chicken Karahi'**
  String get recipeNameChickenKarahi;

  /// A dish in tool-data.js RECIPES — a name, transliterated where it is one and translated where it describes
  ///
  /// In en, this message translates to:
  /// **'Daal Chawal'**
  String get recipeNameDaalChawal;

  /// A dish in tool-data.js RECIPES — a name, transliterated where it is one and translated where it describes
  ///
  /// In en, this message translates to:
  /// **'Greek Salad'**
  String get recipeNameGreekSalad;

  /// A dish in tool-data.js RECIPES — a name, transliterated where it is one and translated where it describes
  ///
  /// In en, this message translates to:
  /// **'Overnight Oats'**
  String get recipeNameOvernightOats;

  /// A dish in tool-data.js RECIPES — a name, transliterated where it is one and translated where it describes
  ///
  /// In en, this message translates to:
  /// **'Shakshuka'**
  String get recipeNameShakshuka;

  /// A tag in tool-data.js RECIPES
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get recipeTagBreakfast;

  /// A tag in tool-data.js RECIPES
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get recipeTagBudget;

  /// A tag in tool-data.js RECIPES
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get recipeTagDinner;

  /// A tag in tool-data.js RECIPES
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get recipeTagFamily;

  /// A tag in tool-data.js RECIPES
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get recipeTagLight;

  /// A tag in tool-data.js RECIPES
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get recipeTagLunch;

  /// A tag in tool-data.js RECIPES
  ///
  /// In en, this message translates to:
  /// **'Make ahead'**
  String get recipeTagMakeAhead;

  /// A tag in tool-data.js RECIPES
  ///
  /// In en, this message translates to:
  /// **'No cook'**
  String get recipeTagNoCook;

  /// A tag in tool-data.js RECIPES
  ///
  /// In en, this message translates to:
  /// **'Spicy'**
  String get recipeTagSpicy;

  /// A tag in tool-data.js RECIPES
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get recipeTagVegetarian;

  /// Reference key recipes.all
  ///
  /// In en, this message translates to:
  /// **'All recipes'**
  String get recipesAll;

  /// Reference key recipes.favourites
  ///
  /// In en, this message translates to:
  /// **'Your favourites'**
  String get recipesFavourites;

  /// Reference: `r.ingredients + " " + t("recipes.ingredients")`, pluralised
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 ingredient} other{{n} ingredients}}'**
  String recipesIngredients(int n);

  /// Reference key recipes.noMatch
  ///
  /// In en, this message translates to:
  /// **'No recipes match'**
  String get recipesNoMatch;

  /// Reference key recipes.noMatchText
  ///
  /// In en, this message translates to:
  /// **'Try a cuisine, an ingredient or a tag.'**
  String get recipesNoMatchText;

  /// Reference key recipes.prepCook — preparation and cooking, in minutes
  ///
  /// In en, this message translates to:
  /// **'{prep} + {cook} min'**
  String recipesPrepCook(String prep, String cook);

  /// Reference key recipes.related
  ///
  /// In en, this message translates to:
  /// **'Do more with this'**
  String get recipesRelated;

  /// Reference key recipes.search
  ///
  /// In en, this message translates to:
  /// **'Search recipes'**
  String get recipesSearch;

  /// Reference key recipes.serves, pluralised
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{serves 1} other{serves {n}}}'**
  String recipesServes(int n);

  /// The Recipes share card (C68). The reference shares an unrelated quote; this says what the library holds
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recipe} other{{count} recipes}} · Your favourites: {names}'**
  String recipesShareText(int count, String names);

  /// Reference key recipes.stepsN, pluralised
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 step} other{{n} steps}}'**
  String recipesSteps(int n);

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

  /// Said when the camera permission is off for good or restricted, and the system will not ask again
  ///
  /// In en, this message translates to:
  /// **'Camera access for Lume is off. Turn it on in Settings to scan.'**
  String get scanBlocked;

  /// Said when the camera permission is refused and the platform will ask again the next time Scan is pressed (C80)
  ///
  /// In en, this message translates to:
  /// **'Lume can\'t use the camera. Press Scan to be asked again.'**
  String get scanDenied;

  /// Reference key scan.empty.text
  ///
  /// In en, this message translates to:
  /// **'Anything you capture appears here and stays on this device.'**
  String get scanEmptyText;

  /// Reference key scan.empty.title
  ///
  /// In en, this message translates to:
  /// **'Nothing scanned yet'**
  String get scanEmptyTitle;

  /// Said when the scanner fails
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t scan. Try again.'**
  String get scanFailed;

  /// Reference key scan.fromGallery
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get scanFromGallery;

  /// Said when a chosen image holds several QR codes; Lume does not guess which one
  ///
  /// In en, this message translates to:
  /// **'That image has more than one QR code. Choose one with a single code.'**
  String get scanMultiple;

  /// Said when a scan ends without reading a code
  ///
  /// In en, this message translates to:
  /// **'No code found'**
  String get scanNothing;

  /// The action on a camera message that opens Lume's own page in the device's Settings; offered only where Settings can change the permission
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get scanOpenSettings;

  /// Said when choosing an image is refused access to photos
  ///
  /// In en, this message translates to:
  /// **'Lume can\'t open your photos. You can allow it in Settings.'**
  String get scanPhotosDenied;

  /// Said when a device policy, Screen Time or a profile has turned the camera off; the reader's Settings page cannot change it (C80)
  ///
  /// In en, this message translates to:
  /// **'The camera is turned off on this device by a restriction or its administrator.'**
  String get scanRestricted;

  /// Said when the system would not open Lume's page in Settings
  ///
  /// In en, this message translates to:
  /// **'Settings didn\'t open. You\'ll find Lume under Apps in your phone\'s Settings.'**
  String get scanSettingsFailed;

  /// Said when a chosen image is larger than Lume decodes on the device
  ///
  /// In en, this message translates to:
  /// **'That image is too large to read'**
  String get scanTooLarge;

  /// Said when Scan or From gallery is pressed and this build has no camera scanner — the reference says "Scanning" while nothing scans
  ///
  /// In en, this message translates to:
  /// **'Scanning isn\'t available on this device'**
  String get scanUnavailable;

  /// Said when the camera was refused and Android does not say whether it will ask again: Scan may ask, and Settings certainly can (C80)
  ///
  /// In en, this message translates to:
  /// **'Lume can\'t use the camera. Press Scan to be asked again, or turn it on in Settings if Android doesn\'t ask.'**
  String get scanUndetermined;

  /// Said when a chosen image cannot be decoded, or its code is damaged
  ///
  /// In en, this message translates to:
  /// **'Lume couldn\'t read that image'**
  String get scanUnreadable;

  /// Said when a chosen image holds a barcode that is not a QR code
  ///
  /// In en, this message translates to:
  /// **'That code isn\'t a QR code'**
  String get scanUnsupported;

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

  /// Reference: `extra.darkMode`. One of two settings the search index carries beside the catalogue, so a reader looking for "night" or "theme" finds the switch rather than nothing.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get searchDarkMode;

  /// Reference: the `aria-label` on `#globalSearch` and on the app bar’s search control. What a screen reader is told the field and the button are for.
  ///
  /// In en, this message translates to:
  /// **'Search everything'**
  String get searchEverything;

  /// The subtitle on a search hit that is a setting rather than a tool. The reference writes it as a bare English literal in `services/search.js`; here it is a key, because it is a UI label rather than a proper noun (§47, §106).
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get searchInSettings;

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

  /// Reference: `search.nothingSub`. The empty result state’s second line. It names Personalisation because turning on an interest is what actually widens the index.
  ///
  /// In en, this message translates to:
  /// **'Try another word, or turn on more interests in Personalisation.'**
  String get searchNothingSub;

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

  /// Reference key share.cardReady
  ///
  /// In en, this message translates to:
  /// **'Your card is ready'**
  String get shareCardReady;

  /// Said when the share sheet failed (D7). The reference has none
  ///
  /// In en, this message translates to:
  /// **'Couldn’t share the card'**
  String get shareFailed;

  /// Reference key share.generating
  ///
  /// In en, this message translates to:
  /// **'Creating your card…'**
  String get shareGenerating;

  /// Reference: aria-label on the share canvas
  ///
  /// In en, this message translates to:
  /// **'Share card preview'**
  String get sharePreviewLabel;

  /// Said when the reader refused the photo library (D7)
  ///
  /// In en, this message translates to:
  /// **'Lume can’t save to your photos'**
  String get shareSaveDenied;

  /// Said when saving the image failed (D7)
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save the image'**
  String get shareSaveFailed;

  /// Said when the photo library reports no space
  ///
  /// In en, this message translates to:
  /// **'Not enough space to save the image'**
  String get shareSaveNoSpace;

  /// Said by Save image while the photo-library permission is undecided (D7)
  ///
  /// In en, this message translates to:
  /// **'Saving images isn’t available on this device — use Share to save it'**
  String get shareSaveUnavailable;

  /// Reference key share.saved — said only once the photo library has the image (D7)
  ///
  /// In en, this message translates to:
  /// **'Image saved'**
  String get shareSaved;

  /// Reference key share.shared — said only when the share sheet reports a destination was chosen (D7)
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get shareShared;

  /// Said when the platform has no share sheet (D7). The reference has none
  ///
  /// In en, this message translates to:
  /// **'Sharing isn’t available on this device'**
  String get shareUnavailable;

  /// Reference key shop.gDairy
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get shopAisleDairy;

  /// Reference key shop.gHousehold
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get shopAisleHousehold;

  /// Reference key shop.gProduce
  ///
  /// In en, this message translates to:
  /// **'Produce'**
  String get shopAisleProduce;

  /// Reference key shop.i1 — a sample item
  ///
  /// In en, this message translates to:
  /// **'Tomatoes'**
  String get shopSeedI1;

  /// Reference key shop.i2
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get shopSeedI2;

  /// Reference key shop.i3
  ///
  /// In en, this message translates to:
  /// **'Yoghurt'**
  String get shopSeedI3;

  /// Reference key shop.i4
  ///
  /// In en, this message translates to:
  /// **'Lemons'**
  String get shopSeedI4;

  /// Reference key shop.i5
  ///
  /// In en, this message translates to:
  /// **'Washing powder'**
  String get shopSeedI5;

  /// Reference key shopping.clear
  ///
  /// In en, this message translates to:
  /// **'Clear checked'**
  String get shoppingClear;

  /// Reference key shopping.estimated
  ///
  /// In en, this message translates to:
  /// **'about {amount}'**
  String shoppingEstimated(String amount);

  /// Reference key shopping.list
  ///
  /// In en, this message translates to:
  /// **'Still to get'**
  String get shoppingList;

  /// Reference key shopping.progress
  ///
  /// In en, this message translates to:
  /// **'Checked off'**
  String get shoppingProgress;

  /// Reference key shopping.share
  ///
  /// In en, this message translates to:
  /// **'Share the list'**
  String get shoppingShare;

  /// The source line of a shared shopping list: the day it was shared
  ///
  /// In en, this message translates to:
  /// **'Shopping list · {date}'**
  String shoppingShareSource(String date);

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

  /// Reference key stopwatch.empty.text
  ///
  /// In en, this message translates to:
  /// **'Start the stopwatch and tap Lap to record one.'**
  String get stopwatchEmptyText;

  /// Reference key stopwatch.empty.title
  ///
  /// In en, this message translates to:
  /// **'No laps yet'**
  String get stopwatchEmptyTitle;

  /// Reference key stopwatch.hint, corrected: the reference says "tap again to lap", and tapping again pauses
  ///
  /// In en, this message translates to:
  /// **'Start, then Lap to mark each lap'**
  String get stopwatchHint;

  /// Reference key stopwatch.lap
  ///
  /// In en, this message translates to:
  /// **'Lap {n}'**
  String stopwatchLap(String n);

  /// Records a lap while the stopwatch runs
  ///
  /// In en, this message translates to:
  /// **'Lap'**
  String get stopwatchLapAction;

  /// Reference key stopwatch.laps
  ///
  /// In en, this message translates to:
  /// **'Laps'**
  String get stopwatchLaps;

  /// Pauses the running stopwatch
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get stopwatchPause;

  /// Reference key sun.dawn — here civil dawn, the sun 6° below the horizon (C86)
  ///
  /// In en, this message translates to:
  /// **'Dawn'**
  String get sunDawn;

  /// Reference key sun.dawnNote
  ///
  /// In en, this message translates to:
  /// **'First light'**
  String get sunDawnNote;

  /// Reference key sun.daylength
  ///
  /// In en, this message translates to:
  /// **'Daylight'**
  String get sunDaylength;

  /// Reference key sun.dusk — here civil dusk
  ///
  /// In en, this message translates to:
  /// **'Dusk'**
  String get sunDusk;

  /// Reference key sun.duskNote
  ///
  /// In en, this message translates to:
  /// **'Last light'**
  String get sunDuskNote;

  /// Reference key sun.illumination
  ///
  /// In en, this message translates to:
  /// **'Illuminated'**
  String get sunIllumination;

  /// Reference key sun.moon
  ///
  /// In en, this message translates to:
  /// **'Moon phase'**
  String get sunMoon;

  /// Sun & Moon: the text under the missing-city title
  ///
  /// In en, this message translates to:
  /// **'Sun and moon times are worked out from a city’s coordinates, and Lume has none for this one. Choose another city in Profile to see them.'**
  String get sunNoCityText;

  /// Sun & Moon: the city has no coordinates in Lume’s table
  ///
  /// In en, this message translates to:
  /// **'No position for {city}'**
  String sunNoCityTitle(String city);

  /// Civil twilight lasts all night, so there is no dawn or dusk to show
  ///
  /// In en, this message translates to:
  /// **'Not dark enough tonight'**
  String get sunNoTwilight;

  /// Sun & Moon: the text under the missing-zone title
  ///
  /// In en, this message translates to:
  /// **'Times can’t be shown on your local clock without its time zone, so none are shown.'**
  String get sunNoZoneText;

  /// Sun & Moon: the reader’s time zone is not in this build’s zone table
  ///
  /// In en, this message translates to:
  /// **'No clock for {zone}'**
  String sunNoZoneTitle(String zone);

  /// Reference key sun.noon
  ///
  /// In en, this message translates to:
  /// **'Solar noon'**
  String get sunNoon;

  /// The sun does not set on this date at this latitude
  ///
  /// In en, this message translates to:
  /// **'The sun stays up all day'**
  String get sunPolarDay;

  /// The sun does not rise on this date at this latitude
  ///
  /// In en, this message translates to:
  /// **'The sun stays below the horizon all day'**
  String get sunPolarNight;

  /// Reference key sun.range
  ///
  /// In en, this message translates to:
  /// **'{a} to {b}'**
  String sunRange(String a, String b);

  /// The source line of a shared sun card
  ///
  /// In en, this message translates to:
  /// **'{city} · {date}'**
  String sunShareSource(String city, String date);

  /// Reference key sun.sunrise
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunSunrise;

  /// Reference key sun.sunset
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get sunSunset;

  /// Reference key sun.title
  ///
  /// In en, this message translates to:
  /// **'Sun & moon'**
  String get sunTitle;

  /// Reference key sun.today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get sunToday;

  /// Sun & Moon, when the reader’s zone is missing or must be chosen
  ///
  /// In en, this message translates to:
  /// **'Sunrise and sunset are worked out on your clock, so they need your time zone. Choose one in Profile › Time.'**
  String get sunZoneChooseText;

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

  /// Reference key tax.above — the top band's label
  ///
  /// In en, this message translates to:
  /// **'Above {v}'**
  String taxAbove(String v);

  /// Reference key tax.annual — the period control
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get taxAnnual;

  /// tool-data.js TAX.PK.authority. The reference prints the data string in every language; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'FBR salaried slabs'**
  String get taxAuthorityFbrSalaried;

  /// tool-data.js TAX.GB.authority
  ///
  /// In en, this message translates to:
  /// **'HMRC income tax (England)'**
  String get taxAuthorityHmrcEngland;

  /// tool-data.js TAX.IN.authority
  ///
  /// In en, this message translates to:
  /// **'New regime slabs'**
  String get taxAuthorityIndiaNewRegime;

  /// tool-data.js TAX.US.authority
  ///
  /// In en, this message translates to:
  /// **'IRS single filer'**
  String get taxAuthorityIrsSingleFiler;

  /// tool-data.js TAX.AE/SA.authority
  ///
  /// In en, this message translates to:
  /// **'No personal income tax'**
  String get taxAuthorityNone;

  /// Reference key tax.band — a table column
  ///
  /// In en, this message translates to:
  /// **'Band'**
  String get taxBand;

  /// Reference key tax.deductions — a field
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get taxDeductions;

  /// Reference key tax.dueAnnual — the result's kicker
  ///
  /// In en, this message translates to:
  /// **'Tax a year'**
  String get taxDueAnnual;

  /// Reference key tax.dueMonthly — the result's kicker
  ///
  /// In en, this message translates to:
  /// **'Tax a month'**
  String get taxDueMonthly;

  /// Reference key tax.effective — the result's caption
  ///
  /// In en, this message translates to:
  /// **'Effective rate {rate}'**
  String taxEffective(String rate);

  /// Reference key tax.incomeAnnual — a field
  ///
  /// In en, this message translates to:
  /// **'Annual income'**
  String get taxIncomeAnnual;

  /// Reference key tax.incomeMonthly — a field
  ///
  /// In en, this message translates to:
  /// **'Monthly income'**
  String get taxIncomeMonthly;

  /// Reference key tax.incomeTax
  ///
  /// In en, this message translates to:
  /// **'Income tax'**
  String get taxIncomeTax;

  /// Reference key tax.leviesNote — a section head
  ///
  /// In en, this message translates to:
  /// **'Worth knowing'**
  String get taxLeviesNote;

  /// Reference key tax.leviesNoteText
  ///
  /// In en, this message translates to:
  /// **'These are headline rates. Consumption taxes are paid on what you buy rather than deducted from pay, and social contributions are usually split between you and your employer.'**
  String get taxLeviesNoteText;

  /// Reference key tax.levy — a table column
  ///
  /// In en, this message translates to:
  /// **'Levy'**
  String get taxLevy;

  /// Reference key tax.marginal
  ///
  /// In en, this message translates to:
  /// **'Marginal rate'**
  String get taxMarginal;

  /// Reference key tax.monthly — the period control
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get taxMonthly;

  /// Reference key tax.noneCaption
  ///
  /// In en, this message translates to:
  /// **'Your salary is not subject to personal income tax here.'**
  String get taxNoneCaption;

  /// Reference key tax.none.text
  ///
  /// In en, this message translates to:
  /// **'{authority}. Nothing to calculate for salaried income here.'**
  String taxNoneText(String authority);

  /// Reference key tax.none.title
  ///
  /// In en, this message translates to:
  /// **'No personal income tax'**
  String get taxNoneTitle;

  /// Reference key tax.otherLevies — a section head
  ///
  /// In en, this message translates to:
  /// **'What does apply'**
  String get taxOtherLevies;

  /// Reference key tax.period — the period control's accessible name
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get taxPeriod;

  /// Reference key tax.rate — a table column
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get taxRate;

  /// Reference key tax.slabs — the breakdown's head
  ///
  /// In en, this message translates to:
  /// **'How it is worked out'**
  String get taxSlabs;

  /// Reference key tax.split — the donut's accessible name
  ///
  /// In en, this message translates to:
  /// **'Where it goes'**
  String get taxSplit;

  /// Reference key tax.takeHome
  ///
  /// In en, this message translates to:
  /// **'Take-home'**
  String get taxTakeHome;

  /// Reference key tax.tax — the donut's tax slice
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get taxTax;

  /// Reference key tax.taxable
  ///
  /// In en, this message translates to:
  /// **'Taxable income'**
  String get taxTaxable;

  /// Reference key tax.taxedHere — a table column
  ///
  /// In en, this message translates to:
  /// **'Tax in band'**
  String get taxTaxedHere;

  /// Reference key tax.unsupported.text
  ///
  /// In en, this message translates to:
  /// **'Tax rules are country-specific. Switch country to use a market Lume has configured, or check back — new markets are added regularly.'**
  String get taxUnsupportedText;

  /// Reference key tax.unsupported.title
  ///
  /// In en, this message translates to:
  /// **'Not yet localised for {country}'**
  String taxUnsupportedTitle(String country);

  /// Reference key tax.year
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get taxYear;

  /// Reference key timer.done — the toast when a countdown reaches zero
  ///
  /// In en, this message translates to:
  /// **'Timer finished'**
  String get timerDone;

  /// Reference key timer.hint — under the clock face
  ///
  /// In en, this message translates to:
  /// **'Choose a preset or set your own'**
  String get timerHint;

  /// Reference key timer.presets — a section head
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get timerPresets;

  /// Reference key tip.bill
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get tipBill;

  /// The people stepper’s decrease action
  ///
  /// In en, this message translates to:
  /// **'Fewer'**
  String get tipFewer;

  /// The people stepper’s increase action
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tipMore;

  /// Reference key tip.people
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get tipPeople;

  /// Reference key tip.perPerson
  ///
  /// In en, this message translates to:
  /// **'Each person pays'**
  String get tipPerPerson;

  /// Reference key tip.person
  ///
  /// In en, this message translates to:
  /// **'Person {n}'**
  String tipPerson(String n);

  /// Reference key tip.custom
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get tipSplit;

  /// Reference keys tip.tip and tip.tipAmount
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tipTip;

  /// Reference key tip.total
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get tipTotal;

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

  /// Reference key todos.add — the button that opens the form
  ///
  /// In en, this message translates to:
  /// **'Add a task'**
  String get todosAdd;

  /// Reference key todos.clear
  ///
  /// In en, this message translates to:
  /// **'Nothing left'**
  String get todosClear;

  /// Reference key todos.clearText
  ///
  /// In en, this message translates to:
  /// **'No tasks match this filter.'**
  String get todosClearText;

  /// Reference key todos.done7 — tasks ticked in the last seven days
  ///
  /// In en, this message translates to:
  /// **'Done this week'**
  String get todosDone7;

  /// Reference key todos.high
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get todosHigh;

  /// Reference key todos.listHome
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get todosListHome;

  /// Reference key todos.listPersonal
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get todosListPersonal;

  /// Reference key todos.listWork
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get todosListWork;

  /// Reference key todos.lists
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get todosLists;

  /// Reference key todos.normal
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get todosNormal;

  /// Reference key todos.onTrack
  ///
  /// In en, this message translates to:
  /// **'Nothing overdue'**
  String get todosOnTrack;

  /// Reference: the count and todos.open composed; a plural here
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 open} other{{n} open}}'**
  String todosOpenN(int n);

  /// Reference key todos.overdueN
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 overdue} other{{n} overdue}}'**
  String todosOverdueN(int n);

  /// Reference key todos.priority
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get todosPriority;

  /// Reference key todos.item1 — a sample task
  ///
  /// In en, this message translates to:
  /// **'Send the quarterly summary'**
  String get todosSeedItem1;

  /// Reference key todos.item2
  ///
  /// In en, this message translates to:
  /// **'Pick up the prescription'**
  String get todosSeedItem2;

  /// Reference key todos.item3
  ///
  /// In en, this message translates to:
  /// **'Review the design feedback'**
  String get todosSeedItem3;

  /// Reference key todos.item4
  ///
  /// In en, this message translates to:
  /// **'Book the car service'**
  String get todosSeedItem4;

  /// Reference key todos.today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todosToday;

  /// Reference key todos.upcoming
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get todosUpcoming;

  /// Spoken for To-dos' Week chip: today and the six calendar dates after it (C86)
  ///
  /// In en, this message translates to:
  /// **'Next seven days'**
  String get todosWeekSpoken;

  /// Reference key todos.when
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get todosWhen;

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

  /// Reference key settings.changeCountry — a tool that is not localised for the reader's country offers this
  ///
  /// In en, this message translates to:
  /// **'Change country'**
  String get toolChangeCountry;

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

  /// Reference key tool.exportFailed
  ///
  /// In en, this message translates to:
  /// **'Couldn’t write the file'**
  String get toolExportFailed;

  /// Said when the platform cannot write a file (D7). The reference has none
  ///
  /// In en, this message translates to:
  /// **'Exporting isn’t available on this device'**
  String get toolExportUnavailable;

  /// Reference key tool.exportedAs — said only when the reader chose where the file went (D7). The name is a file name
  ///
  /// In en, this message translates to:
  /// **'Saved {name}'**
  String toolExportedAs(String name);

  /// Reference key tool.favourited — the toast after the header's favourite action
  ///
  /// In en, this message translates to:
  /// **'Added {name} to favourites'**
  String toolFavourited(String name);

  /// Reference key tool.inputs — a calculator’s inputs section
  ///
  /// In en, this message translates to:
  /// **'Inputs'**
  String get toolInputs;

  /// Reference key habits.insights — a tracker's insight section head
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get toolInsights;

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

  /// Privacy note for a sensitive tool that can share content the reader has reviewed in a preview, such as Ledger's reminder. Must not claim the content is never shared.
  ///
  /// In en, this message translates to:
  /// **'This information stays on your device and is never shown on Home. Only what you review and choose to share leaves Lume. Notes, record IDs and anything you did not review are never included.'**
  String get toolPrivateReviewedText;

  /// Title of the privacy note for a sensitive tool that shares only reviewed content
  ///
  /// In en, this message translates to:
  /// **'Private by default'**
  String get toolPrivateReviewedTitle;

  /// Reference key tool.private.text
  ///
  /// In en, this message translates to:
  /// **'This information stays on your device, is never shown on Home and is never included in shared content.'**
  String get toolPrivateText;

  /// Privacy note of a sensitive tool that shares nothing, in development and release builds: private to the reader, never on Home or its suggestions, never in shared content. The parity flavor shows toolPrivateText, the reference's own wording.
  ///
  /// In en, this message translates to:
  /// **'This information stays on your device. It is never shown on Home or in its suggestions, and never included in shared content.'**
  String get toolPrivateFullText;

  /// Reference key tool.private.title
  ///
  /// In en, this message translates to:
  /// **'Private to you'**
  String get toolPrivateTitle;

  /// Reference key tool.related — the related-tools section head
  ///
  /// In en, this message translates to:
  /// **'Related tools'**
  String get toolRelated;

  /// tools.js mosques.map — the map's label and name.
  ///
  /// In en, this message translates to:
  /// **'Mosques near you'**
  String get mosquesMap;

  /// tools.js mosques.search — search placeholder.
  ///
  /// In en, this message translates to:
  /// **'Search mosques'**
  String get mosquesSearch;

  /// tools.js mosques.radius — the radius chips' group, for a screen reader.
  ///
  /// In en, this message translates to:
  /// **'Within'**
  String get mosquesRadius;

  /// tools.js mosques.nearby — list section title.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get mosquesNearby;

  /// tools.js mosques.directions — button.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get mosquesDirections;

  /// tools.js mosques.opening — the Directions toast (Dayroz: hands off to maps).
  ///
  /// In en, this message translates to:
  /// **'Opening directions'**
  String get mosquesOpening;

  /// tools.js mosques.addyours — button.
  ///
  /// In en, this message translates to:
  /// **'Suggest a mosque'**
  String get mosquesAddYours;

  /// tools.js mosques.suggest — the Suggest toast (Dayroz: submits it).
  ///
  /// In en, this message translates to:
  /// **'Thanks — we’ll review it'**
  String get mosquesSuggest;

  /// tools.js mosques.central — a sample mosque's name, before the city.
  ///
  /// In en, this message translates to:
  /// **'Central Mosque'**
  String get mosquesCentral;

  /// tools.js mosques.jamia — a sample mosque's name, before the city.
  ///
  /// In en, this message translates to:
  /// **'Jamia Masjid'**
  String get mosquesJamia;

  /// tools.js mosques.masjidA — a sample mosque's name, before the city.
  ///
  /// In en, this message translates to:
  /// **'Masjid Al-Noor'**
  String get mosquesMasjidA;

  /// tools.js mosques.masjidB — a sample mosque's name, before the city.
  ///
  /// In en, this message translates to:
  /// **'Masjid Bilal'**
  String get mosquesMasjidB;

  /// tools.js mosques.addr — a sample mosque's address.
  ///
  /// In en, this message translates to:
  /// **'Near the main road, {city}'**
  String mosquesAddr(String city);

  /// tools.js mosques.fac.parking
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get mosquesFacParking;

  /// tools.js mosques.fac.women
  ///
  /// In en, this message translates to:
  /// **'Women’s area'**
  String get mosquesFacWomen;

  /// tools.js mosques.fac.wudu
  ///
  /// In en, this message translates to:
  /// **'Wudu facilities'**
  String get mosquesFacWudu;

  /// tools.js mosques.noneNear — empty state title.
  ///
  /// In en, this message translates to:
  /// **'Nothing within this distance'**
  String get mosquesNoneNear;

  /// tools.js mosques.noneNearText — empty state text.
  ///
  /// In en, this message translates to:
  /// **'Widen the search radius to see more.'**
  String get mosquesNoneNearText;

  /// m.walk + ' ' + unit.walk — the walking time in a row's meta.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min walk'**
  String mosquesWalk(int minutes);

  /// tool-specs.js src "Places directory" — Nearby Mosques' source line.
  ///
  /// In en, this message translates to:
  /// **'Places directory'**
  String get toolSourcePlaces;

  /// tools.js speed.start — the gauge's button.
  ///
  /// In en, this message translates to:
  /// **'Start test'**
  String get speedStart;

  /// tools.js speed.download
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get speedDownload;

  /// tools.js speed.upload
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get speedUpload;

  /// tools.js speed.ping
  ///
  /// In en, this message translates to:
  /// **'Ping'**
  String get speedPing;

  /// tools.js speed.connection — section title.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get speedConnection;

  /// tools.js speed.type
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get speedType;

  /// tools.js speed.server
  ///
  /// In en, this message translates to:
  /// **'Test server'**
  String get speedServer;

  /// tools.js speed.isp
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get speedIsp;

  /// tools.js speed.wifi
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get speedWifi;

  /// tools.js speed.mobile
  ///
  /// In en, this message translates to:
  /// **'Mobile data'**
  String get speedMobile;

  /// tools.js speed.yourIsp
  ///
  /// In en, this message translates to:
  /// **'Your provider'**
  String get speedYourIsp;

  /// tools.js speed.done — the toast when a run ends. n is a formatted number.
  ///
  /// In en, this message translates to:
  /// **'{n} Mbps down'**
  String speedDone(String n);

  /// tools.js unit.mbps — megabits a second.
  ///
  /// In en, this message translates to:
  /// **'Mbps'**
  String get unitMbps;

  /// tools.js unit.ms — milliseconds.
  ///
  /// In en, this message translates to:
  /// **'ms'**
  String get unitMs;

  /// tool-specs.js src "Nearest test server" — Speed Test's source line.
  ///
  /// In en, this message translates to:
  /// **'Nearest test server'**
  String get toolSourceTestServer;

  /// tools.js media.link — the link field's label.
  ///
  /// In en, this message translates to:
  /// **'Paste a link'**
  String get mediaLink;

  /// tools.js media.fetch — button.
  ///
  /// In en, this message translates to:
  /// **'Fetch'**
  String get mediaFetch;

  /// tools.js media.fetching — the Fetch toast (Dayroz: fetches the linked media).
  ///
  /// In en, this message translates to:
  /// **'Fetching media'**
  String get mediaFetching;

  /// tools.js media.saved — metric label.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get mediaSaved;

  /// tools.js media.storage — metric label.
  ///
  /// In en, this message translates to:
  /// **'Storage used'**
  String get mediaStorage;

  /// tools.js media.lastSave — metric label.
  ///
  /// In en, this message translates to:
  /// **'Last save'**
  String get mediaLastSave;

  /// tools.js media.library — section title.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get mediaLibrary;

  /// tools.js media.item1 — a sample saved item.
  ///
  /// In en, this message translates to:
  /// **'Recipe video'**
  String get mediaItem1;

  /// tools.js media.item2 — a sample saved item.
  ///
  /// In en, this message translates to:
  /// **'Travel photo'**
  String get mediaItem2;

  /// tools.js media.item3 — a sample saved item.
  ///
  /// In en, this message translates to:
  /// **'Podcast clip'**
  String get mediaItem3;

  /// tools.js media.empty.text
  ///
  /// In en, this message translates to:
  /// **'Paste a link and Lume saves the media to this device.'**
  String get mediaEmptyText;

  /// tools.js unit.mb — megabytes.
  ///
  /// In en, this message translates to:
  /// **'MB'**
  String get unitMb;

  /// tools.js wastatus.android.title — the note card's title.
  ///
  /// In en, this message translates to:
  /// **'Android only'**
  String get wastatusAndroidTitle;

  /// tools.js wastatus.android.text
  ///
  /// In en, this message translates to:
  /// **'Reading another app’s status folder needs Android’s folder access, which iOS does not offer.'**
  String get wastatusAndroidText;

  /// tools.js wastatus.detected — section title.
  ///
  /// In en, this message translates to:
  /// **'Detected statuses'**
  String get wastatusDetected;

  /// tools.js wastatus.empty.title
  ///
  /// In en, this message translates to:
  /// **'No statuses found'**
  String get wastatusEmptyTitle;

  /// tools.js wastatus.empty.text
  ///
  /// In en, this message translates to:
  /// **'Grant folder access so Lume can list the statuses currently on your device.'**
  String get wastatusEmptyText;

  /// tools.js wastatus.grant — the empty state's button.
  ///
  /// In en, this message translates to:
  /// **'Grant folder access'**
  String get wastatusGrant;

  /// tools.js wastatus.granting — the Grant toast (Dayroz: opens Android's folder picker).
  ///
  /// In en, this message translates to:
  /// **'Requesting access'**
  String get wastatusGranting;

  /// shell.js data-bookmark — the reflection card's Bookmark, turned on.
  ///
  /// In en, this message translates to:
  /// **'Saved to your bookmarks'**
  String get todayBookmarked;

  /// shell.js data-bookmark — the reflection card's Bookmark, turned off.
  ///
  /// In en, this message translates to:
  /// **'Removed from bookmarks'**
  String get todayUnbookmarked;

  /// account.js auth.needAccount — the signed-out refusal's title.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get authNeedAccount;

  /// account.js auth.legalTitle — the sign-up legal link's sheet (the web's own ur/ar).
  ///
  /// In en, this message translates to:
  /// **'How Lume handles your data'**
  String get authLegalTitle;

  /// account.js auth.legalBody
  ///
  /// In en, this message translates to:
  /// **'Your account, your settings and everything you create in Lume are stored on this device. Lume does not sell your information and does not share it with anyone.'**
  String get authLegalBody;

  /// account.js auth.legalWhere
  ///
  /// In en, this message translates to:
  /// **'The full detail lives under Privacy in your profile, and you can delete your account and everything in it at any time.'**
  String get authLegalWhere;

  /// tool-specs.js src "On device" — shared by every tool whose figures live on the device. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'On device'**
  String get toolSourceOnDevice;

  /// tool-specs.js src for tax. The reference prints this English string in every language; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Statutory slabs'**
  String get toolSourceTax;

  /// tool-specs.js src "ADS-B network" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'ADS-B network'**
  String get toolSourceAdsb;

  /// tool-specs.js src "Asma ul Husna" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Asma ul Husna'**
  String get toolSourceAsmaUlHusna;

  /// tool-specs.js src "Astronomical calculation" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Astronomical calculation'**
  String get toolSourceAstronomical;

  /// tool-specs.js src "Bullion + open market" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Bullion + open market'**
  String get toolSourceBullion;

  /// tool-specs.js src "Camera" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get toolSourceCamera;

  /// tool-specs.js src "Carrier tracking" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Carrier tracking'**
  String get toolSourceCarrier;

  /// tool-specs.js src "Classical faraid rules" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Classical faraid rules'**
  String get toolSourceFaraid;

  /// tool-specs.js src "Current pump price" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Current pump price'**
  String get toolSourcePumpPrice;

  /// tool-specs.js src "Distribution company" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Distribution company'**
  String get toolSourceDistribution;

  /// tool-specs.js src "Dua collection" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Dua collection'**
  String get toolSourceDuas;

  /// tool-specs.js src "Encrypted on device" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Encrypted on device'**
  String get toolSourceEncrypted;

  /// tool-specs.js src "Exchange feed" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Exchange feed'**
  String get toolSourceExchange;

  /// tool-specs.js src "Excise records" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Excise records'**
  String get toolSourceExcise;

  /// tool-specs.js src "Forecast model" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Forecast model'**
  String get toolSourceForecast;

  /// tool-specs.js src "Great-circle bearing" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Great-circle bearing'**
  String get toolSourceGreatCircle;

  /// tool-specs.js src "Hadith collections" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Hadith collections'**
  String get toolSourceHadith;

  /// tool-specs.js src "Hijri calendar + solar times" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Hijri calendar + solar times'**
  String get toolSourceHijriSolar;

  /// tool-specs.js src "IANA time zones" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'IANA time zones'**
  String get toolSourceIana;

  /// tool-specs.js src "ICAO + national specs" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'ICAO + national specs'**
  String get toolSourceIcao;

  /// tool-specs.js src "Interbank composite" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Interbank composite'**
  String get toolSourceInterbank;

  /// tool-specs.js src "Match feed" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Match feed'**
  String get toolSourceMatchFeed;

  /// tool-specs.js src "Monitoring stations" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Monitoring stations'**
  String get toolSourceMonitoring;

  /// tool-specs.js src "National Savings schedule" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'National Savings schedule'**
  String get toolSourceNatSavings;

  /// tool-specs.js src "National calendars" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'National calendars'**
  String get toolSourceNationalCalendars;

  /// tool-specs.js src "National directory" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'National directory'**
  String get toolSourceNationalDirectory;

  /// tool-specs.js src "Nisab from live metal rates" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Nisab from live metal rates'**
  String get toolSourceNisab;

  /// tool-specs.js src "Official draw results" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Official draw results'**
  String get toolSourceDrawResults;

  /// tool-specs.js src "On device + provider" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'On device + provider'**
  String get toolSourceOnDeviceProvider;

  /// tool-specs.js src "Operator live feed" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Operator live feed'**
  String get toolSourceOperatorFeed;

  /// tool-specs.js src "Operator tariffs" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Operator tariffs'**
  String get toolSourceOperatorTariffs;

  /// tool-specs.js src "Publisher feeds" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Publisher feeds'**
  String get toolSourcePublishers;

  /// tool-specs.js src "Qur’an text" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Qur’an text'**
  String get toolSourceQuranText;

  /// tool-specs.js src "Recipe library" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Recipe library'**
  String get toolSourceRecipes;

  /// tool-specs.js src "Regulator notification" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Regulator notification'**
  String get toolSourceRegulator;

  /// tool-specs.js src "Tabular Islamic calendar" — a tool source line. The reference prints it in English everywhere; translated here (§11).
  ///
  /// In en, this message translates to:
  /// **'Tabular Islamic calendar'**
  String get toolSourceTabularHijri;

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

  /// Reference key catalogue.js f.m for birthdays. The reference writes "Ayesha in 4d" - a fixture person and a countdown from a constant. The tool reads the reader own records, which start empty, so the tile says what the tool is (C100)
  ///
  /// In en, this message translates to:
  /// **'Dates you add'**
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
  /// **'Track a savings committee'**
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

  /// The status line on the goals tile. States a purpose, not a count: the prototype's '2 active' disagrees with its own 3-goal seed data (GOALS_PROPOSAL.md D-G10)
  ///
  /// In en, this message translates to:
  /// **'Track your savings goals'**
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
  /// **'Track fixed payment plans'**
  String get toolStatusInstallments;

  /// The status line on the learning tile. The prototype keeps it in the catalogue and renders it untranslated in every language (D22)
  ///
  /// In en, this message translates to:
  /// **'3 courses'**
  String get toolStatusLearning;

  /// The status line on the ledger tile: what the tool is for, never a figure from the reader's own ledger (sensitive; C90)
  ///
  /// In en, this message translates to:
  /// **'Lend and borrow'**
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

  /// The status line on the mealplan tile. States a purpose, not the prototype's stale 'This week' (MEALPLAN_PROPOSAL.md D-M7)
  ///
  /// In en, this message translates to:
  /// **'Plan your week\'s meals'**
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

  /// The status line on the subs tile. States a purpose, not a count: the prototype's '6 active' disagrees with its own 5-subscription seed data (SUBSCRIPTIONS_PROPOSAL.md D-S9)
  ///
  /// In en, this message translates to:
  /// **'Track recurring subscriptions'**
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

  /// Reference key catalogue.js f.m for water. The reference writes "5 / 8" - a glass count from a constant. The tile says what the tool is (C100)
  ///
  /// In en, this message translates to:
  /// **'Daily intake'**
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

  /// Reference key tool.unfavourited
  ///
  /// In en, this message translates to:
  /// **'Removed {name} from favourites'**
  String toolUnfavourited(String name);

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

  /// Reference: the departures All link’s data-toast.
  ///
  /// In en, this message translates to:
  /// **'All departures'**
  String get trainsAllDepartures;

  /// Reference: the To field’s data-toast.
  ///
  /// In en, this message translates to:
  /// **'Choose a destination'**
  String get trainsChooseDestination;

  /// Reference: the From field’s data-toast.
  ///
  /// In en, this message translates to:
  /// **'Choose a departure station'**
  String get trainsChooseOrigin;

  /// How many services a popular route has.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 train} other{{n} trains}}'**
  String trainsCount(int n);

  /// Announced after a date is picked from the calendar chip (R3).
  ///
  /// In en, this message translates to:
  /// **'Departures for {date}'**
  String trainsDayOn(String date);

  /// Announced after the day chips change the day (R3).
  ///
  /// In en, this message translates to:
  /// **'Departures for today'**
  String get trainsDayToday;

  /// Announced after the day chips change the day (R3).
  ///
  /// In en, this message translates to:
  /// **'Departures for tomorrow'**
  String get trainsDayTomorrow;

  /// Reference key trains.departures. `i18n/core.js` declares "Today’s departures" and `i18n/tools.js` overrides it to "Departures"; the rendered screen shows the override, and the rendered screen is the authority.
  ///
  /// In en, this message translates to:
  /// **'Departures'**
  String get trainsDepartures;

  /// Reference key trains.departuresSub.
  ///
  /// In en, this message translates to:
  /// **'From {station}'**
  String trainsDeparturesSub(String station);

  /// A journey length. Reference: the roster’s `dur` field, which is written in English in the data.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String trainsDuration(String h, String m);

  /// Reference: `.routecard__fare`, "from ₨ 2,400".
  ///
  /// In en, this message translates to:
  /// **'from {fare}'**
  String trainsFareFrom(String fare);

  /// Reference key trains.from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get trainsFrom;

  /// The Trains page head. Reference: trains.screen.js .page-head__sub, which writes the operator and the phrase as one literal.
  ///
  /// In en, this message translates to:
  /// **'{operator} · live running status'**
  String trainsHeadSub(String operator);

  /// Reference key trains.now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get trainsNow;

  /// Reference: the calendar chip’s aria-label.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get trainsPickDate;

  /// The platform date picker’s title. The picker itself is OS furniture, like the keyboard — the reference’s chip is labelled "Pick a date" and has nothing behind it (R3).
  ///
  /// In en, this message translates to:
  /// **'Pick a departure date'**
  String get trainsPickedDate;

  /// Reference key trains.popular.
  ///
  /// In en, this message translates to:
  /// **'Popular routes'**
  String get trainsPopular;

  /// Reference key trains.popularSub.
  ///
  /// In en, this message translates to:
  /// **'Tap to check fares and seats'**
  String get trainsPopularSub;

  /// Reference: the Refresh link’s data-toast.
  ///
  /// In en, this message translates to:
  /// **'Live status refreshed'**
  String get trainsRefreshed;

  /// Reference: `.live-train__route`. The arrow follows the reading direction, which is why it is in the string rather than a glyph.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String trainsRoute(String from, String to);

  /// The explanation under trainsRouteInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'A journey needs somewhere to leave from and somewhere to go.'**
  String get trainsRouteInvalidText;

  /// Shown on the departures section when the route asked for is not one — a missing end, or the same station twice (R2).
  ///
  /// In en, this message translates to:
  /// **'Choose two different stations'**
  String get trainsRouteInvalidTitle;

  /// Reference: a route card’s data-toast.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to} · {trains} · {fare}'**
  String trainsRouteToast(String from, String to, String trains, String fare);

  /// Reference key trains.saved.
  ///
  /// In en, this message translates to:
  /// **'Saved journeys'**
  String get trainsSaved;

  /// Reference: the Search button’s data-toast.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 train on this route today} other{{n} trains on this route today}}'**
  String trainsSearchResult(int n);

  /// Reference: a departure row’s `.list-row__sub`.
  ///
  /// In en, this message translates to:
  /// **'{depart} → {arrive} · {duration} · {fare}'**
  String trainsServiceLine(
    String depart,
    String arrive,
    String duration,
    String fare,
  );

  /// Reference key trains.st.departed.
  ///
  /// In en, this message translates to:
  /// **'Departed'**
  String get trainsStatusDeparted;

  /// Reference key trains.st.late.
  ///
  /// In en, this message translates to:
  /// **'{n} min late'**
  String trainsStatusLate(int n);

  /// Reference key trains.st.onTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get trainsStatusOnTime;

  /// Reference: the swap control’s aria-label.
  ///
  /// In en, this message translates to:
  /// **'Swap stations'**
  String get trainsSwap;

  /// Reference: the swap control’s data-toast.
  ///
  /// In en, this message translates to:
  /// **'Stations swapped'**
  String get trainsSwapped;

  /// Announced after a swap has actually happened (R2). The reference says only "Stations swapped" and swaps nothing; this says what changed, and says it after the change.
  ///
  /// In en, this message translates to:
  /// **'Stations swapped: {origin} to {destination}'**
  String trainsSwappedTo(String origin, String destination);

  /// Reference key trains.to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get trainsTo;

  /// Reference key trains.today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get trainsToday;

  /// Reference key trains.tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get trainsTomorrow;

  /// What a screen reader is told about the tracked card, which is a progress bar it would otherwise read as nothing.
  ///
  /// In en, this message translates to:
  /// **'{name} {number}, {route}, {status}, {percent}'**
  String trainsTrackedSummary(
    String name,
    String number,
    String route,
    String status,
    String percent,
  );

  /// Reference key trains.tracking.
  ///
  /// In en, this message translates to:
  /// **'You are tracking'**
  String get trainsTracking;

  /// Shown when a deep link reaches Trains in a market that has no rail service. Deliberately identical in shape to the tool refusal, so "you may not have this" and "there is no such thing" read the same.
  ///
  /// In en, this message translates to:
  /// **'Trains are not in your setup'**
  String get trainsUnavailableTitle;

  /// Reference key trains.updated.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Updated 1 minute ago} other{Updated {n} minutes ago}}'**
  String trainsUpdated(int n);

  /// Reference: a statistic’s unit
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get unitDays;

  /// Reference key unit.gram
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unitGram;

  /// Reference key unit.hpa — the symbol is written the same way in every language
  ///
  /// In en, this message translates to:
  /// **'hPa'**
  String get unitHpa;

  /// Reference: `c.num(r.kcal) + " " + t("unit.kcal")`. The number arrives formatted
  ///
  /// In en, this message translates to:
  /// **'{n} kcal'**
  String unitKcalCount(String n);

  /// Reference key unit.km
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unitKm;

  /// Reference: a wind speed unit
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get unitKmh;

  /// Reference key unit.mi
  ///
  /// In en, this message translates to:
  /// **'mi'**
  String get unitMi;

  /// Reference: a statistic’s unit
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get unitMinutes;

  /// A length in minutes — `n + " " + t("unit.min")`, as a preset and a history row write it
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String unitMinutesCount(String n);

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

  /// Reference key unit.ounce — a troy ounce
  ///
  /// In en, this message translates to:
  /// **'oz'**
  String get unitOunce;

  /// Reference: a statistic’s unit
  ///
  /// In en, this message translates to:
  /// **'k'**
  String get unitThousand;

  /// Reference key unit.tola — 11.664 grams
  ///
  /// In en, this message translates to:
  /// **'tola'**
  String get unitTola;

  /// A field suffix: the value is a number of years
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get unitYearsSuffix;

  /// Reference key weather.air
  ///
  /// In en, this message translates to:
  /// **'Air quality'**
  String get weatherAir;

  /// Reference key weather.alert.heat
  ///
  /// In en, this message translates to:
  /// **'Heat advisory'**
  String get weatherAlertHeat;

  /// Reference key weather.alert.heatText
  ///
  /// In en, this message translates to:
  /// **'Temperatures above 38° through the afternoon. Limit outdoor exertion and drink more than usual.'**
  String get weatherAlertHeatText;

  /// Reference: WEATHER_BY_COUNTRY / WEATHER_BY_ZONE condition phrase.
  ///
  /// In en, this message translates to:
  /// **'Breezy'**
  String get weatherBreezy;

  /// Reference: WEATHER_BY_COUNTRY / WEATHER_BY_ZONE condition phrase.
  ///
  /// In en, this message translates to:
  /// **'Bright and breezy'**
  String get weatherBrightAndBreezy;

  /// Reference: WEATHER_BY_COUNTRY / WEATHER_BY_ZONE condition phrase.
  ///
  /// In en, this message translates to:
  /// **'Changeable'**
  String get weatherChangeable;

  /// A weather condition. The prototype stores these as English sentences in the catalogue and never translates them
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get weatherClear;

  /// Reference: WEATHER_BY_COUNTRY / WEATHER_BY_ZONE condition phrase.
  ///
  /// In en, this message translates to:
  /// **'Clear and dry'**
  String get weatherClearAndDry;

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

  /// Reference: WEATHER_BY_COUNTRY / WEATHER_BY_ZONE condition phrase.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherCloudy;

  /// Reference key weather.details
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get weatherDetails;

  /// Reference key weather.dew
  ///
  /// In en, this message translates to:
  /// **'Dew point'**
  String get weatherDew;

  /// Reference key weather.feels
  ///
  /// In en, this message translates to:
  /// **'Feels like {t}'**
  String weatherFeels(String t);

  /// Reference key weather.forecast
  ///
  /// In en, this message translates to:
  /// **'Five days'**
  String get weatherForecast;

  /// Reference: WEATHER_BY_COUNTRY / WEATHER_BY_ZONE condition phrase.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get weatherFresh;

  /// Reference key weather.gusts
  ///
  /// In en, this message translates to:
  /// **'Gusts'**
  String get weatherGusts;

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

  /// Reference key weather.hilo
  ///
  /// In en, this message translates to:
  /// **'High {hi} · Low {lo}'**
  String weatherHilo(String hi, String lo);

  /// Reference key weather.hourly
  ///
  /// In en, this message translates to:
  /// **'Next 12 hours'**
  String get weatherHourly;

  /// Reference: WEATHER_BY_COUNTRY / WEATHER_BY_ZONE condition phrase.
  ///
  /// In en, this message translates to:
  /// **'Humid'**
  String get weatherHumid;

  /// Reference: WEATHER_BY_COUNTRY / WEATHER_BY_ZONE condition phrase.
  ///
  /// In en, this message translates to:
  /// **'Humid · afternoon storms'**
  String get weatherHumidAfternoonStorms;

  /// Reference: WEATHER_BY_COUNTRY / WEATHER_BY_ZONE condition phrase.
  ///
  /// In en, this message translates to:
  /// **'Humid · cloud building'**
  String get weatherHumidCloudBuilding;

  /// Reference: WEATHER_BY_COUNTRY.IN
  ///
  /// In en, this message translates to:
  /// **'Humid · light haze'**
  String get weatherHumidLightHaze;

  /// Reference: WEATHER_BY_COUNTRY / WEATHER_BY_ZONE condition phrase.
  ///
  /// In en, this message translates to:
  /// **'Humid · passing showers'**
  String get weatherHumidPassingShowers;

  /// Reference: WEATHER_BY_COUNTRY / WEATHER_BY_ZONE condition phrase.
  ///
  /// In en, this message translates to:
  /// **'Humid · showers later'**
  String get weatherHumidShowersLater;

  /// Reference key weather.humidity
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get weatherHumidity;

  /// A weather condition. The prototype stores these as English sentences in the catalogue and never translates them
  ///
  /// In en, this message translates to:
  /// **'Light cloud'**
  String get weatherLightCloud;

  /// Reference: WEATHER_BY_COUNTRY / WEATHER_BY_ZONE condition phrase.
  ///
  /// In en, this message translates to:
  /// **'Mild and clear'**
  String get weatherMildAndClear;

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

  /// Reference key weather.pressure
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get weatherPressure;

  /// Reference key weather.rain
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// The forecast row's meta: num(rain) + "% " + t("weather.rain")
  ///
  /// In en, this message translates to:
  /// **'{pct}% Rain'**
  String weatherRainChance(String pct);

  /// Reference key weather.rain — the stat label; weatherRain is the condition phrase
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherStatRain;

  /// Reference: WEATHER_BY_COUNTRY / WEATHER_BY_ZONE condition phrase.
  ///
  /// In en, this message translates to:
  /// **'Sunny spells'**
  String get weatherSunnySpells;

  /// Reference key weather.uv
  ///
  /// In en, this message translates to:
  /// **'UV index'**
  String get weatherUv;

  /// Reference key weather.uvHigh
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get weatherUvHigh;

  /// Reference key weather.uvModerate
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get weatherUvModerate;

  /// The UV row: w.uv + " · " + w.uvLabel
  ///
  /// In en, this message translates to:
  /// **'{n} · {band}'**
  String weatherUvValue(String n, String band);

  /// Reference key weather.visibility
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get weatherVisibility;

  /// Reference: WEATHER_BY_COUNTRY / WEATHER_BY_ZONE condition phrase.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get weatherWarm;

  /// Reference: WEATHER_BY_COUNTRY / WEATHER_BY_ZONE condition phrase.
  ///
  /// In en, this message translates to:
  /// **'Warm and dry'**
  String get weatherWarmAndDry;

  /// Reference: WEATHER_BY_COUNTRY / WEATHER_BY_ZONE condition phrase.
  ///
  /// In en, this message translates to:
  /// **'Warm and humid'**
  String get weatherWarmAndHumid;

  /// Reference key weather.wind
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get weatherWind;

  /// Summary kicker (reference ledger.net)
  ///
  /// In en, this message translates to:
  /// **'Net position'**
  String get ledgerNet;

  /// Summary caption when the net is owed to the reader (reference ledger.owedToYou)
  ///
  /// In en, this message translates to:
  /// **'owed to you overall'**
  String get ledgerOwedOverall;

  /// Summary caption when the reader owes overall (reference ledger.youOwe)
  ///
  /// In en, this message translates to:
  /// **'you owe overall'**
  String get ledgerOweOverall;

  /// Summary caption when the net is exactly zero
  ///
  /// In en, this message translates to:
  /// **'even overall'**
  String get ledgerEvenOverall;

  /// Summary stat: the sum of positive balances
  ///
  /// In en, this message translates to:
  /// **'Owed to you'**
  String get ledgerOwedToYou;

  /// Summary stat and filter: the sum of negative balances
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get ledgerYouOwe;

  /// Summary stat and section title (reference ledger.people)
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get ledgerPeople;

  /// Heading of a per-currency summary when there are several currencies
  ///
  /// In en, this message translates to:
  /// **'In {code}'**
  String ledgerSummaryCurrency(String code);

  /// Accessibility label of the filter bar (D4)
  ///
  /// In en, this message translates to:
  /// **'Show people by their current balance'**
  String get ledgerFilterLabel;

  /// Filter: people whose balance is owed to the reader
  ///
  /// In en, this message translates to:
  /// **'Owes you'**
  String get ledgerFilterOwesYou;

  /// Under a row amount (reference ledger.owesYou)
  ///
  /// In en, this message translates to:
  /// **'owes you'**
  String get ledgerOwesYou;

  /// Under a row amount (reference ledger.youOweShort)
  ///
  /// In en, this message translates to:
  /// **'you owe'**
  String get ledgerYouOweShort;

  /// Under a row whose net is zero but which is not settled
  ///
  /// In en, this message translates to:
  /// **'open both ways'**
  String get ledgerEvenRow;

  /// Under a settled row
  ///
  /// In en, this message translates to:
  /// **'settled'**
  String get ledgerSettledRow;

  /// A person overpaid; the reader holds it as credit and owes it back
  ///
  /// In en, this message translates to:
  /// **'{amount} credit to them'**
  String ledgerCreditToThem(String amount);

  /// The reader overpaid; the person holds it as the reader's credit
  ///
  /// In en, this message translates to:
  /// **'{amount} your credit'**
  String ledgerCreditFromThem(String amount);

  /// Row meta (reference ledger.due)
  ///
  /// In en, this message translates to:
  /// **'due {date}'**
  String ledgerDue(String date);

  /// A person with no entries
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get ledgerNoEntries;

  /// Badge on a person and currency whose stored allocations break the rules
  ///
  /// In en, this message translates to:
  /// **'Needs reconciling'**
  String get ledgerNeedsReconcile;

  /// Badge on an archived person
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get ledgerArchivedBadge;

  /// Section title: the latest entries
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get ledgerRecent;

  /// Button (reference ledger.add)
  ///
  /// In en, this message translates to:
  /// **'Add an entry'**
  String get ledgerAdd;

  /// Button (reference ledger.remind); opens a preview, never sends by itself
  ///
  /// In en, this message translates to:
  /// **'Send a reminder'**
  String get ledgerRemind;

  /// Button
  ///
  /// In en, this message translates to:
  /// **'Add a person'**
  String get ledgerAddPerson;

  /// First use: title (D11 — no sample people)
  ///
  /// In en, this message translates to:
  /// **'Money lent and borrowed, in one place'**
  String get ledgerEmptyTitle;

  /// First use: text
  ///
  /// In en, this message translates to:
  /// **'Add a person, then record what you lend, borrow and get back. Balances, overdue dates and credit are worked out from your entries.'**
  String get ledgerEmptyText;

  /// Filter or search with no match (reference ledger.noMatch)
  ///
  /// In en, this message translates to:
  /// **'Nobody here'**
  String get ledgerNoMatch;

  /// Filter or search with no match
  ///
  /// In en, this message translates to:
  /// **'No one matches this filter or search.'**
  String get ledgerNoMatchText;

  /// Clears the filter and the search
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get ledgerShowAll;

  /// Search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search people and notes'**
  String get ledgerSearch;

  /// Sort option (default)
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get ledgerSortDue;

  /// Sort option
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get ledgerSortName;

  /// Sort option
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get ledgerSortRecent;

  /// Switch: show archived people
  ///
  /// In en, this message translates to:
  /// **'Include archived'**
  String get ledgerShowArchived;

  /// The Overdue filter when the reader's day is unknown
  ///
  /// In en, this message translates to:
  /// **'Overdue needs your day, and it can\'t be worked out. Dates are written out in full.'**
  String get ledgerOverdueUnknown;

  /// Accessibility: the icon of an entry where money left the reader
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get ledgerMoneyOut;

  /// Accessibility: the icon of an entry where money came to the reader
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get ledgerMoneyIn;

  /// Entry kind, in a sentence
  ///
  /// In en, this message translates to:
  /// **'You lent'**
  String get ledgerKindLent;

  /// Entry kind, in a sentence
  ///
  /// In en, this message translates to:
  /// **'You borrowed'**
  String get ledgerKindBorrowed;

  /// Entry kind, in a sentence
  ///
  /// In en, this message translates to:
  /// **'They paid you back'**
  String get ledgerKindRepaidToMe;

  /// Entry kind, in a sentence
  ///
  /// In en, this message translates to:
  /// **'You paid them back'**
  String get ledgerKindRepaidByMe;

  /// Entry kind, segmented control
  ///
  /// In en, this message translates to:
  /// **'Lent'**
  String get ledgerKindLentShort;

  /// Entry kind, segmented control
  ///
  /// In en, this message translates to:
  /// **'Borrowed'**
  String get ledgerKindBorrowedShort;

  /// Entry kind, segmented control
  ///
  /// In en, this message translates to:
  /// **'Got back'**
  String get ledgerKindRepaidToMeShort;

  /// Entry kind, segmented control
  ///
  /// In en, this message translates to:
  /// **'Paid back'**
  String get ledgerKindRepaidByMeShort;

  /// Badge on a voided entry
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get ledgerVoided;

  /// Person detail: every entry
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get ledgerHistory;

  /// Person detail: principals with something remaining
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get ledgerOpenLoans;

  /// A principal's remaining
  ///
  /// In en, this message translates to:
  /// **'{left} left of {total}'**
  String ledgerLeftOf(String left, String total);

  /// An allocation, on a repayment
  ///
  /// In en, this message translates to:
  /// **'{amount} to the {date} entry'**
  String ledgerAppliedTo(String amount, String date);

  /// An allocation, on a principal
  ///
  /// In en, this message translates to:
  /// **'{amount} from the {date} repayment'**
  String ledgerPaidFrom(String amount, String date);

  /// A repayment's confirmed excess, still unapplied
  ///
  /// In en, this message translates to:
  /// **'{amount} kept as credit'**
  String ledgerKeptAsCredit(String amount);

  /// An allocation the reader chose rather than oldest-due-first
  ///
  /// In en, this message translates to:
  /// **'Chosen'**
  String get ledgerManualBadge;

  /// Person detail action
  ///
  /// In en, this message translates to:
  /// **'Settle up'**
  String get ledgerSettleUp;

  /// Settle-up preview title, when they owe the reader
  ///
  /// In en, this message translates to:
  /// **'Record {name} paying back {amount}'**
  String ledgerSettleOwes(String name, String amount);

  /// Settle-up preview title, when the reader owes
  ///
  /// In en, this message translates to:
  /// **'Record paying {name} back {amount}'**
  String ledgerSettleOwe(String name, String amount);

  /// Settle-up preview: the principals it discharges follow
  ///
  /// In en, this message translates to:
  /// **'One repayment, dated today, that clears:'**
  String get ledgerSettleText;

  /// Settle-up confirm
  ///
  /// In en, this message translates to:
  /// **'Record it'**
  String get ledgerSettleConfirm;

  /// Person action
  ///
  /// In en, this message translates to:
  /// **'Edit person'**
  String get ledgerRename;

  /// Person action
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get ledgerArchive;

  /// Person action
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get ledgerUnarchive;

  /// Person action
  ///
  /// In en, this message translates to:
  /// **'Delete person'**
  String get ledgerDeletePerson;

  /// Archive refused
  ///
  /// In en, this message translates to:
  /// **'Only a settled person can be archived.'**
  String get ledgerArchiveOpen;

  /// Delete person refused while entries reference them (no cascade)
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 entry still names this person. Delete it first — nothing is deleted with them.} other{{n} entries still name this person. Delete them first — nothing is deleted with them.}}'**
  String ledgerPersonReferenced(int n);

  /// Delete person confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete this person?'**
  String get ledgerDeletePersonTitle;

  /// Delete person confirmation
  ///
  /// In en, this message translates to:
  /// **'They have no entries. This can\'t be undone.'**
  String get ledgerDeletePersonText;

  /// Rebuild a damaged person's allocations, on the reader's request
  ///
  /// In en, this message translates to:
  /// **'Reconcile'**
  String get ledgerReconcile;

  /// Damaged scope notice
  ///
  /// In en, this message translates to:
  /// **'The allocations on file for this person don\'t add up. Nothing is recalculated until you reconcile.'**
  String get ledgerDamagedText;

  /// Records that failed to decode — never dropped
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 record can\'t be read and is shown as damaged.} other{{n} records can\'t be read and are shown as damaged.}}'**
  String ledgerDefects(int n);

  /// Entry action: the normal correction
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get ledgerVoid;

  /// Entry action: undo a void
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get ledgerRestore;

  /// Entry detail note
  ///
  /// In en, this message translates to:
  /// **'Voiding keeps the entry and its history, and takes it out of every figure.'**
  String get ledgerVoidText;

  /// Person form title
  ///
  /// In en, this message translates to:
  /// **'New person'**
  String get ledgerNewPerson;

  /// Person form field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get ledgerPersonName;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get ledgerNote;

  /// Beside an optional field
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get ledgerOptional;

  /// Entry form title
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get ledgerNewEntry;

  /// Entry form title
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get ledgerEditEntry;

  /// Entry form field
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get ledgerFieldPerson;

  /// Entry form field
  ///
  /// In en, this message translates to:
  /// **'What happened'**
  String get ledgerFieldKind;

  /// Entry form field
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get ledgerFieldAmount;

  /// Entry form field
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get ledgerFieldCurrency;

  /// Entry form field
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get ledgerFieldDate;

  /// Entry form field, principals only
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get ledgerFieldDue;

  /// Due picker value when none
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get ledgerNoDue;

  /// Date picker value when none (no today)
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get ledgerChooseDate;

  /// Repayment allocation mode
  ///
  /// In en, this message translates to:
  /// **'Apply to'**
  String get ledgerFieldApply;

  /// Automatic allocation
  ///
  /// In en, this message translates to:
  /// **'Oldest due first'**
  String get ledgerApplyAuto;

  /// Manual allocation
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get ledgerApplyManual;

  /// Manual allocation with no open principal
  ///
  /// In en, this message translates to:
  /// **'Nothing is open in {code} for this person.'**
  String ledgerApplyNone(String code);

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get ledgerErrName;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'That\'s too long'**
  String get ledgerErrLong;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Choose a person'**
  String get ledgerErrPerson;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above zero'**
  String get ledgerErrAmount;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Enter a number, like 1500 or 1500.50'**
  String get ledgerErrNumber;

  /// Validation: more decimals than the currency's ISO exponent — never rounded
  ///
  /// In en, this message translates to:
  /// **'{code} takes {n, plural, =0{no decimal places} =1{one decimal place} other{{n} decimal places}}'**
  String ledgerErrPrecision(String code, int n);

  /// Validation: past 10^15 minor units, or a sum past 2^53 − 1
  ///
  /// In en, this message translates to:
  /// **'That amount is larger than a ledger entry can hold'**
  String get ledgerErrTooLarge;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get ledgerErrDate;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Due can\'t be before the date'**
  String get ledgerErrDueBefore;

  /// Validation: manual allocations over the repayment
  ///
  /// In en, this message translates to:
  /// **'The amounts you apply can\'t add up to more than the repayment'**
  String get ledgerErrApplied;

  /// Validation: a manual allocation over a principal's remaining
  ///
  /// In en, this message translates to:
  /// **'More than is open on this entry'**
  String get ledgerErrAppliedOver;

  /// Validation: a withdrawn ISO currency for a new entry
  ///
  /// In en, this message translates to:
  /// **'{code} is no longer issued. Use it only to repay or correct an amount already kept in {code}.'**
  String ledgerErrWithdrawn(String code);

  /// A withdrawn ISO currency as a picker and a form name it: offered only to repay or correct a record already kept in it
  ///
  /// In en, this message translates to:
  /// **'{code} · no longer issued'**
  String currencyWithdrawnValue(String code);

  /// Installments first use: nothing seeded
  ///
  /// In en, this message translates to:
  /// **'No payment plans yet'**
  String get instEmptyTitle;

  /// Installments first use: what the tool is for
  ///
  /// In en, this message translates to:
  /// **'Add something you are paying for in fixed monthly instalments. Lume keeps its schedule and works out what is paid, due and left.'**
  String get instEmptyText;

  /// Installments: add a payment plan
  ///
  /// In en, this message translates to:
  /// **'Add a plan'**
  String get instAdd;

  /// Installments summary kicker: instalments due in the reader's calendar month
  ///
  /// In en, this message translates to:
  /// **'Due this month'**
  String get instDueThisMonth;

  /// Installments summary stat: deposits and active payments
  ///
  /// In en, this message translates to:
  /// **'Paid so far'**
  String get instPaidToDate;

  /// Installments summary stat: what is left on plans not cancelled
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get instRemaining;

  /// Installments summary caption: each plan counted once
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No active plans} =1{1 active plan} other{{n} active plans}}'**
  String instActivePlans(int n);

  /// Installments summary stat label
  ///
  /// In en, this message translates to:
  /// **'Late instalments'**
  String get instLateInstalments;

  /// Installments: one summary per currency
  ///
  /// In en, this message translates to:
  /// **'In {code}'**
  String instSummaryCurrency(String code);

  /// Installments: a state or figure that needs the reader's day, which cannot be worked out
  ///
  /// In en, this message translates to:
  /// **'Day unknown'**
  String get instDayUnknown;

  /// Installments day-unavailable state
  ///
  /// In en, this message translates to:
  /// **'Your time zone can\'t be worked out, so no instalment is marked late or due this month. Set your city in Account › Time.'**
  String get instDayUnknownText;

  /// Installments filter bar, for a screen reader
  ///
  /// In en, this message translates to:
  /// **'Plans shown'**
  String get instFilterLabel;

  /// Installments filter and plan state
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get instFilterActive;

  /// Installments filter, and an unpaid instalment due before today
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get instFilterLate;

  /// Installments filter and plan state: every instalment paid
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get instFilterCompleted;

  /// Installments filter and plan state
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get instFilterCancelled;

  /// Installments sort: earliest unpaid due date
  ///
  /// In en, this message translates to:
  /// **'Next due'**
  String get instSortNext;

  /// Installments sort: the reference's mislabelled 'Remaining'
  ///
  /// In en, this message translates to:
  /// **'Payments left'**
  String get instSortLeft;

  /// Installments sort
  ///
  /// In en, this message translates to:
  /// **'Monthly amount'**
  String get instSortAmount;

  /// Installments sort
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get instSortName;

  /// Installments sort, from creation instants
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get instSortRecent;

  /// Installments search: item, merchant and note
  ///
  /// In en, this message translates to:
  /// **'Search plans'**
  String get instSearch;

  /// Installments section title
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get instPlans;

  /// Installments section: the next unpaid instalment of each running plan
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get instComingUp;

  /// Installments chart title
  ///
  /// In en, this message translates to:
  /// **'Due by month'**
  String get instDueByMonth;

  /// Installments chart caption
  ///
  /// In en, this message translates to:
  /// **'What falls due each month on plans still running, in {code}.'**
  String instDueByMonthCap(String code);

  /// Installments chart: it shows one currency
  ///
  /// In en, this message translates to:
  /// **'Plans in other currencies are counted separately above.'**
  String get instOtherCurrencies;

  /// Installments chart bar, for a screen reader
  ///
  /// In en, this message translates to:
  /// **'{month}: {amount}'**
  String instChartEntry(String month, String amount);

  /// Installments row: instalments paid of the count — not which is next
  ///
  /// In en, this message translates to:
  /// **'{paid} of {count} paid'**
  String instPaidOf(String paid, String count);

  /// Installments row: the next unpaid due date
  ///
  /// In en, this message translates to:
  /// **'next {date}'**
  String instNextOn(String date);

  /// Installments row: under the instalment amount
  ///
  /// In en, this message translates to:
  /// **'a month'**
  String get instPerMonth;

  /// Installments progress bar, for a screen reader
  ///
  /// In en, this message translates to:
  /// **'{percent} paid'**
  String instProgressValue(String percent);

  /// Installments instalment state
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get instPaid;

  /// Installments instalment state
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get instDueToday;

  /// Installments instalment state
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get instUpcoming;

  /// Installments payment state: kept, counted nowhere
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get instVoided;

  /// Installments: a damaged plan
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get instNeedsAttention;

  /// Installments damaged plan
  ///
  /// In en, this message translates to:
  /// **'This plan\'s records don\'t agree. Its figures are left out of the totals, and nothing is written over it. You can delete it.'**
  String get instDamagedText;

  /// Installments: records that failed to decode — never dropped
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 record can\'t be read. It is kept as it is, and its plan is left out of the totals.} other{{n} records can\'t be read. They are kept as they are, and their plans are left out of the totals.}}'**
  String instDefects(int n);

  /// Installments: one scheduled instalment
  ///
  /// In en, this message translates to:
  /// **'Instalment {n}'**
  String instInstalment(String n);

  /// Installments: one scheduled instalment, with the count
  ///
  /// In en, this message translates to:
  /// **'Instalment {n} of {count}'**
  String instInstalmentOf(String n, String count);

  /// Installments: an instalment's due date
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String instDueOn(String date);

  /// Installments: a payment's date
  ///
  /// In en, this message translates to:
  /// **'Paid {date}'**
  String instPaidOn(String date);

  /// Installments form field
  ///
  /// In en, this message translates to:
  /// **'What you bought'**
  String get instFieldItem;

  /// Installments form field
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get instFieldMerchant;

  /// Installments form field
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get instFieldNote;

  /// Installments form field
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get instFieldCurrency;

  /// Installments form field: every instalment is this
  ///
  /// In en, this message translates to:
  /// **'Instalment amount'**
  String get instFieldAmount;

  /// Installments form field
  ///
  /// In en, this message translates to:
  /// **'Number of instalments'**
  String get instFieldCount;

  /// Installments form field: the schedule's anchor
  ///
  /// In en, this message translates to:
  /// **'First instalment due'**
  String get instFieldFirstDue;

  /// Installments form field: money paid before the schedule
  ///
  /// In en, this message translates to:
  /// **'Deposit already paid'**
  String get instFieldDeposit;

  /// Installments form field
  ///
  /// In en, this message translates to:
  /// **'Deposit paid on'**
  String get instFieldDepositOn;

  /// Installments form field: informational only
  ///
  /// In en, this message translates to:
  /// **'Cash price'**
  String get instFieldCashPrice;

  /// Installments fact label
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get instFrequency;

  /// Installments frequency
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get instMonthly;

  /// Installments: no deposit
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get instNone;

  /// Installments: deposit plus every instalment
  ///
  /// In en, this message translates to:
  /// **'Total payable'**
  String get instTotalPayable;

  /// Installments: amount times count
  ///
  /// In en, this message translates to:
  /// **'Instalments total'**
  String get instScheduledTotal;

  /// Installments: total payable less the cash price — never called interest
  ///
  /// In en, this message translates to:
  /// **'Difference from cash price'**
  String get instCashDifference;

  /// Installments: what the difference is, and is not
  ///
  /// In en, this message translates to:
  /// **'Total payable less the cash price you entered. Lume works out no interest.'**
  String get instCashDifferenceNote;

  /// Installments plan detail section
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get instSchedule;

  /// Installments plan detail section
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get instPayments;

  /// Installments plan detail
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get instNoPayments;

  /// Installments action: the earliest unpaid instalment
  ///
  /// In en, this message translates to:
  /// **'Pay instalment {n}'**
  String instPayNext(String n);

  /// Installments action
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get instEdit;

  /// Installments action: keeps everything
  ///
  /// In en, this message translates to:
  /// **'Cancel plan'**
  String get instCancelPlan;

  /// Installments action: a cancelled plan back to active
  ///
  /// In en, this message translates to:
  /// **'Reinstate'**
  String get instReinstate;

  /// Installments action: for a plan added by mistake
  ///
  /// In en, this message translates to:
  /// **'Delete plan'**
  String get instDeletePlan;

  /// Installments action
  ///
  /// In en, this message translates to:
  /// **'Void payment'**
  String get instVoidPayment;

  /// Installments action
  ///
  /// In en, this message translates to:
  /// **'Restore payment'**
  String get instRestorePayment;

  /// Installments payment sheet title
  ///
  /// In en, this message translates to:
  /// **'Record a payment'**
  String get instPayTitle;

  /// Installments payment sheet: exactly what is recorded
  ///
  /// In en, this message translates to:
  /// **'Instalment {n} of {count}: {amount}, due {date}. It is recorded as paid in full.'**
  String instPayText(String n, String count, String amount, String date);

  /// Installments payment sheet field
  ///
  /// In en, this message translates to:
  /// **'Paid on'**
  String get instPaidOnLabel;

  /// Installments payment sheet confirm
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get instPayConfirm;

  /// Installments toast
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get instPaidToast;

  /// Installments toast
  ///
  /// In en, this message translates to:
  /// **'Payment voided'**
  String get instVoidedToast;

  /// Installments toast
  ///
  /// In en, this message translates to:
  /// **'Payment restored'**
  String get instRestoredToast;

  /// Installments cancel confirmation
  ///
  /// In en, this message translates to:
  /// **'Cancel this plan?'**
  String get instCancelTitle;

  /// Installments cancel confirmation: what it does, and does not
  ///
  /// In en, this message translates to:
  /// **'The plan, its schedule and its payments are kept. It moves to Cancelled and no longer counts in what is due or left. Nothing is refunded.'**
  String get instCancelText;

  /// Installments cancel confirmation: the way out
  ///
  /// In en, this message translates to:
  /// **'Keep plan'**
  String get instKeepPlan;

  /// Installments toast
  ///
  /// In en, this message translates to:
  /// **'Plan cancelled'**
  String get instCancelledToast;

  /// Installments toast
  ///
  /// In en, this message translates to:
  /// **'Plan reinstated'**
  String get instReinstatedToast;

  /// Installments destructive confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete this plan?'**
  String get instDeleteTitle;

  /// Installments destructive confirmation: exactly what goes
  ///
  /// In en, this message translates to:
  /// **'This removes the plan, all {rows} of its scheduled instalments and {payments} recorded payments. It is for a plan added by mistake — to stop a real plan, cancel it.'**
  String instDeleteText(String rows, String payments);

  /// Installments toast, with Undo
  ///
  /// In en, this message translates to:
  /// **'Plan deleted'**
  String get instDeletedToast;

  /// Installments toast after Undo
  ///
  /// In en, this message translates to:
  /// **'Plan restored'**
  String get instRestoredPlanToast;

  /// Installments form title
  ///
  /// In en, this message translates to:
  /// **'New plan'**
  String get instNewPlan;

  /// Installments form title
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get instEditPlan;

  /// Installments form: payments exist
  ///
  /// In en, this message translates to:
  /// **'Terms are fixed'**
  String get instLockedTitle;

  /// Installments form: why the terms cannot change
  ///
  /// In en, this message translates to:
  /// **'Payments are recorded, so the amount, number of instalments, currency, dates and deposit are fixed. To change them, cancel this plan and add a new one.'**
  String get instLockedText;

  /// Installments form before any payment
  ///
  /// In en, this message translates to:
  /// **'Changing the amount, count, currency or dates rebuilds the schedule.'**
  String get instRebuildText;

  /// Installments toast
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get instSaved;

  /// Installments validation
  ///
  /// In en, this message translates to:
  /// **'Enter what you bought'**
  String get instErrItem;

  /// Installments validation
  ///
  /// In en, this message translates to:
  /// **'That is too long'**
  String get instErrLong;

  /// Installments validation
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number from 1 to 600'**
  String get instErrCount;

  /// Installments validation
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get instErrDate;

  /// Installments validation
  ///
  /// In en, this message translates to:
  /// **'A deposit needs both an amount and a date'**
  String get instErrDepositPair;

  /// Installments validation
  ///
  /// In en, this message translates to:
  /// **'That schedule runs past the calendar'**
  String get instErrRange;

  /// Installments validation: past 2^53 − 1 minor units
  ///
  /// In en, this message translates to:
  /// **'That total is too large'**
  String get instErrTooLarge;

  /// Installments validation: a new plan in a withdrawn currency
  ///
  /// In en, this message translates to:
  /// **'{code} is no longer issued. Choose a current currency.'**
  String instErrWithdrawn(String code);

  /// Installments storage failure
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Nothing was changed.'**
  String get instErrFailed;

  /// Installments conflict
  ///
  /// In en, this message translates to:
  /// **'This plan changed somewhere else. Nothing was saved.'**
  String get instErrConflict;

  /// Installments damaged scope
  ///
  /// In en, this message translates to:
  /// **'This plan\'s records don\'t agree, so nothing was written.'**
  String get instErrDamaged;

  /// Installments: payments are made in order
  ///
  /// In en, this message translates to:
  /// **'Pay instalment {n} first.'**
  String instErrOutOfOrder(String n);

  /// Installments
  ///
  /// In en, this message translates to:
  /// **'This plan is cancelled. Reinstate it to record a payment.'**
  String get instErrCancelled;

  /// Installments
  ///
  /// In en, this message translates to:
  /// **'Every instalment is paid; there is nothing to cancel.'**
  String get instErrCompleted;

  /// Installments
  ///
  /// In en, this message translates to:
  /// **'That instalment is already paid.'**
  String get instErrAlreadyPaid;

  /// Installments filtered list is empty
  ///
  /// In en, this message translates to:
  /// **'No plans here'**
  String get instNoMatch;

  /// Installments filtered list is empty
  ///
  /// In en, this message translates to:
  /// **'Nothing matches this filter or search.'**
  String get instNoMatchText;

  /// Installments: clear the filter and search
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get instShowAll;

  /// Installments deep link to a plan that is gone
  ///
  /// In en, this message translates to:
  /// **'That plan isn\'t here any more.'**
  String get instNotFound;

  /// Installments export sheet title
  ///
  /// In en, this message translates to:
  /// **'Export plans'**
  String get instExportTitle;

  /// Installments export format
  ///
  /// In en, this message translates to:
  /// **'Backup (JSON)'**
  String get instExportJson;

  /// Installments export format
  ///
  /// In en, this message translates to:
  /// **'Everything, exactly. It can be imported back.'**
  String get instExportJsonSub;

  /// Installments export format
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet (CSV)'**
  String get instExportCsv;

  /// Installments export format: a view, not a backup
  ///
  /// In en, this message translates to:
  /// **'One row per instalment. It can\'t be imported.'**
  String get instExportCsvSub;

  /// Installments export: off by default
  ///
  /// In en, this message translates to:
  /// **'Include items, merchants and notes'**
  String get instIncludeNames;

  /// Installments export: what the default writes
  ///
  /// In en, this message translates to:
  /// **'Plans are written as numbered labels (“Plan 1”). Merchants and notes are left out.'**
  String get instIncludeNamesOff;

  /// Installments export: what the reader turned on
  ///
  /// In en, this message translates to:
  /// **'Items, merchants and notes are written as you entered them.'**
  String get instIncludeNamesOn;

  /// Installments export sheet action
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get instExportAction;

  /// Installments import
  ///
  /// In en, this message translates to:
  /// **'Import a backup'**
  String get instImport;

  /// Installments import field
  ///
  /// In en, this message translates to:
  /// **'Paste a Lume installments backup (JSON)'**
  String get instImportPaste;

  /// Installments import: check, write nothing
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get instImportCheck;

  /// Installments import check result
  ///
  /// In en, this message translates to:
  /// **'{create} new · {update} updated · {unchanged} unchanged. Nothing is written until you import.'**
  String instImportReady(String create, String update, String unchanged);

  /// Installments import: all or nothing
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 problem — nothing will be imported} other{{n} problems — nothing will be imported}}'**
  String instImportIssues(int n);

  /// Installments import action
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get instImportAction;

  /// Installments import toast
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Imported 1 record} other{Imported {n} records}}'**
  String instImported(int n);

  /// Installments import: names left out of the file
  ///
  /// In en, this message translates to:
  /// **'This backup has no names; plans come in as “Plan 1”, “Plan 2”.'**
  String get instImportNoNames;

  /// Goals summary card kicker (goals.tool.js 'goals.saved')
  ///
  /// In en, this message translates to:
  /// **'Saved so far'**
  String get goalsSummaryKicker;

  /// Goals summary card caption (goals.tool.js 'goals.ofTarget')
  ///
  /// In en, this message translates to:
  /// **'of {target} across all goals'**
  String goalsSummaryCaption(String target);

  /// Goals summary stat label
  ///
  /// In en, this message translates to:
  /// **'Active goals'**
  String get goalsStatActive;

  /// Goals summary stat label — real, derived from the reader's own contributions (D-G2), replacing the reference's untracked 'Monthly' plan figure
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get goalsStatThisMonth;

  /// Goals summary stat label (goals.tool.js 'goals.nextDone')
  ///
  /// In en, this message translates to:
  /// **'Next to complete'**
  String get goalsStatNext;

  /// Goals list section title (goals.tool.js 'goals.yours')
  ///
  /// In en, this message translates to:
  /// **'Your goals'**
  String get goalsYourGoals;

  /// Section title for goals not currently active — the reference has no such state, so no section, but a goal needs to stay reachable once it leaves the active list
  ///
  /// In en, this message translates to:
  /// **'Completed & abandoned'**
  String get goalsOtherGoals;

  /// A goal card's progress line
  ///
  /// In en, this message translates to:
  /// **'{saved} of {target}'**
  String goalsOfTarget(String saved, String target);

  /// A goal card's target date, appended to goalsOfTarget (goals.tool.js 'goals.by')
  ///
  /// In en, this message translates to:
  /// **'by {date}'**
  String goalsByDate(String date);

  /// A goal card's footer (goals.tool.js 'goals.remaining')
  ///
  /// In en, this message translates to:
  /// **'{amount} to go'**
  String goalsToGo(String amount);

  /// A goal's projection, real and derived from its own pace (GOALS_PROPOSAL.md §2), never the reference's fabricated chart
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Any time now} =1{in 1 month} other{in {n} months}}'**
  String goalsProjectedDate(int n);

  /// Shown in place of a projection once a goal's saved amount meets its target
  ///
  /// In en, this message translates to:
  /// **'Target reached'**
  String get goalsReached;

  /// The real, derived monthly-contributions chart (goals.tool.js has a 'Contributions' chart, but its six values are a hardcoded literal array unrelated to any goal — this one is not)
  ///
  /// In en, this message translates to:
  /// **'Contributions'**
  String get goalsChartTitle;

  /// Button — replaces the reference's 'Create your first goal' toast stub with a real form
  ///
  /// In en, this message translates to:
  /// **'Add a goal'**
  String get goalsAddGoal;

  /// Button — replaces the reference's 'Add a contribution' toast stub with a real form (goals.tool.js 'goals.contribute')
  ///
  /// In en, this message translates to:
  /// **'Add a contribution'**
  String get goalsAddContribution;

  /// Empty state title (goals.tool.js 'goals.empty.title') — dead code in the reference since its seed always has 3 goals; live here
  ///
  /// In en, this message translates to:
  /// **'No savings goals yet'**
  String get goalsEmptyTitle;

  /// Empty state text (goals.tool.js 'goals.empty.text')
  ///
  /// In en, this message translates to:
  /// **'A goal turns a vague intention into a monthly number.'**
  String get goalsEmptyText;

  /// Form title, creating
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get goalsNewGoal;

  /// Form title, editing
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalsEditGoal;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get goalsFieldName;

  /// Form field, optional
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get goalsFieldNote;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get goalsFieldTarget;

  /// Form field, optional (D-G4)
  ///
  /// In en, this message translates to:
  /// **'Target date'**
  String get goalsFieldTargetDate;

  /// Form field — a fixed small palette (D-G6)
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get goalsFieldIcon;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get goalsFieldCurrency;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Name this goal'**
  String get goalsErrName;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'That is too long'**
  String get goalsErrLong;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Enter a target amount'**
  String get goalsErrTarget;

  /// Validation: a new goal in a withdrawn currency
  ///
  /// In en, this message translates to:
  /// **'{code} is no longer issued. Choose a current currency.'**
  String goalsErrWithdrawn(String code);

  /// Validation: a currency change would orphan existing contributions
  ///
  /// In en, this message translates to:
  /// **'This goal already has contributions in {code}. Delete them first to change its currency.'**
  String goalsErrCurrencyLocked(String code);

  /// Contribution form validation
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get goalsErrAmount;

  /// Toast — a write lost a version race
  ///
  /// In en, this message translates to:
  /// **'This goal changed elsewhere'**
  String get goalsErrConflict;

  /// Toast — a contribution to a non-active goal
  ///
  /// In en, this message translates to:
  /// **'This goal is completed or abandoned'**
  String get goalsErrClosed;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'This goal\'s records don\'t add up and can\'t be shown safely'**
  String get goalsErrDamaged;

  /// Toast — a sum would overflow
  ///
  /// In en, this message translates to:
  /// **'That amount is too large'**
  String get goalsErrTooLarge;

  /// Toast — a generic storage failure
  ///
  /// In en, this message translates to:
  /// **'That didn\'t save. Try again.'**
  String get goalsErrFailed;

  /// Toast — a deep link to a goal that no longer exists
  ///
  /// In en, this message translates to:
  /// **'That goal isn\'t there any more'**
  String get goalsNotFound;

  /// Goal state
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get goalsStateActive;

  /// Goal state
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get goalsStateCompleted;

  /// Goal state
  ///
  /// In en, this message translates to:
  /// **'Abandoned'**
  String get goalsStateAbandoned;

  /// Detail action
  ///
  /// In en, this message translates to:
  /// **'Mark completed'**
  String get goalsMarkComplete;

  /// Confirmation sheet title
  ///
  /// In en, this message translates to:
  /// **'Mark this goal completed?'**
  String get goalsMarkCompleteAsk;

  /// Confirmation sheet text
  ///
  /// In en, this message translates to:
  /// **'It stays in your history, just no longer counted toward what\'s left to save.'**
  String get goalsMarkCompleteText;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Goal completed'**
  String get goalsMarkCompleteToast;

  /// Detail action
  ///
  /// In en, this message translates to:
  /// **'Abandon goal'**
  String get goalsAbandon;

  /// Confirmation sheet title
  ///
  /// In en, this message translates to:
  /// **'Abandon this goal?'**
  String get goalsAbandonAsk;

  /// Confirmation sheet text
  ///
  /// In en, this message translates to:
  /// **'It stays in your history. You can reactivate it any time.'**
  String get goalsAbandonText;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Goal abandoned'**
  String get goalsAbandonToast;

  /// Detail action — undoes completed/abandoned back to active
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get goalsReactivate;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Goal reactivated'**
  String get goalsReactivatedToast;

  /// Confirmation sheet title
  ///
  /// In en, this message translates to:
  /// **'Delete this goal?'**
  String get goalsDeleteAsk;

  /// Confirmation sheet text
  ///
  /// In en, this message translates to:
  /// **'This removes the goal and every contribution logged to it.'**
  String get goalsDeleteText;

  /// Toast, with Undo
  ///
  /// In en, this message translates to:
  /// **'Goal deleted'**
  String get goalsDeletedToast;

  /// Toast, with Undo
  ///
  /// In en, this message translates to:
  /// **'Contribution added'**
  String get goalsContributionAdded;

  /// Row action — voids, does not delete
  ///
  /// In en, this message translates to:
  /// **'Remove this contribution'**
  String get goalsVoidContribution;

  /// Toast, with Undo
  ///
  /// In en, this message translates to:
  /// **'Contribution removed'**
  String get goalsContributionVoidedToast;

  /// Goal detail section title
  ///
  /// In en, this message translates to:
  /// **'Contribution history'**
  String get goalsHistoryTitle;

  /// Goal detail — empty history
  ///
  /// In en, this message translates to:
  /// **'No contributions yet'**
  String get goalsHistoryEmpty;

  /// Share-card quote, mirroring the reference's own working share feature (goals.tool.js, tool.screen.js:993-998)
  ///
  /// In en, this message translates to:
  /// **'{saved} of {target} — {pct}%'**
  String goalsShareText(String saved, String target, String pct);

  /// Subscriptions summary card kicker (subs.tool.js 'subs.monthly')
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get subsSummaryKicker;

  /// Subscriptions summary card caption (subs.tool.js 'subs.yearly')
  ///
  /// In en, this message translates to:
  /// **'{amount} a year'**
  String subsSummaryCaption(String amount);

  /// Subscriptions summary stat label (subs.tool.js 'subs.active')
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subsStatActive;

  /// Subscriptions summary stat label (subs.tool.js 'subs.nextRenewal')
  ///
  /// In en, this message translates to:
  /// **'Next renewal'**
  String get subsStatNext;

  /// Subscriptions summary stat value (subs.tool.js 'subs.renewsIn'), from the real derived daysUntil, not the reference's hand-typed literal
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{today} =1{in 1 day} other{in {n} days}}'**
  String subsRenewsIn(int n);

  /// Search field placeholder (subs.tool.js 'subs.search')
  ///
  /// In en, this message translates to:
  /// **'Search subscriptions'**
  String get subsSearch;

  /// List section title (subs.tool.js 'subs.all')
  ///
  /// In en, this message translates to:
  /// **'All subscriptions'**
  String get subsAll;

  /// Row meta line (subs.tool.js 'subs.renews'), from the real derived nextRenewal
  ///
  /// In en, this message translates to:
  /// **'renews {date}'**
  String subsRenews(String date);

  /// Row trailing sub-label for a monthly subscription. Corrected from the reference, which shows this label unconditionally even on its one Yearly item (subs.tool.js:49)
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get subsPerMonth;

  /// Row trailing sub-label for a yearly subscription — the reference has no equivalent (D-S5)
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get subsPerYear;

  /// Row trailing sub-label for a custom-cycle subscription — the reference has no equivalent (D-S4)
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{every day} other{every {n} days}}'**
  String subsEveryDays(int n);

  /// Donut chart title (subs.tool.js 'subs.byCategory')
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get subsByCategory;

  /// The donut's group for a subscription with no category set
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get subsUncategorised;

  /// Timeline title (subs.tool.js 'subs.timeline'), fed by real upcoming records
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get subsTimeline;

  /// Button — the reference has no creation affordance of any kind, not even a stub (SUBSCRIPTIONS_PROPOSAL.md §0)
  ///
  /// In en, this message translates to:
  /// **'Add a subscription'**
  String get subsAddSubscription;

  /// Empty state title — the reference has none; its own seed data would throw if empty (SUBSCRIPTIONS_PROPOSAL.md §1)
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet'**
  String get subsEmptyTitle;

  /// Empty state text
  ///
  /// In en, this message translates to:
  /// **'Track what renews, and when, in one place.'**
  String get subsEmptyText;

  /// Form title, creating
  ///
  /// In en, this message translates to:
  /// **'New subscription'**
  String get subsNewSubscription;

  /// Form title, editing
  ///
  /// In en, this message translates to:
  /// **'Edit subscription'**
  String get subsEditSubscription;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get subsFieldName;

  /// Form field, optional, free text (matches the reference's own unconstrained 'cat' field)
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get subsFieldCategory;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get subsFieldAmount;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'Billing cycle'**
  String get subsFieldCycle;

  /// Form field, shown only when the custom cycle is chosen (D-S4)
  ///
  /// In en, this message translates to:
  /// **'Every how many days'**
  String get subsFieldCustomDays;

  /// Form field — the one real anchor date that replaces the reference's two independent literals (D-S2)
  ///
  /// In en, this message translates to:
  /// **'Started on'**
  String get subsFieldStartedOn;

  /// Form field
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get subsFieldCurrency;

  /// Cycle option
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subsCycleMonthly;

  /// Cycle option
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get subsCycleYearly;

  /// Cycle option
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get subsCycleCustom;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Name this subscription'**
  String get subsErrName;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'That is too long'**
  String get subsErrLong;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get subsErrAmount;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'Enter a day count between 1 and 3,660'**
  String get subsErrCustomDays;

  /// Validation: a new subscription in a withdrawn currency
  ///
  /// In en, this message translates to:
  /// **'{code} is no longer issued. Choose a current currency.'**
  String subsErrWithdrawn(String code);

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'This subscription changed elsewhere'**
  String get subsErrConflict;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'This subscription\'s records don\'t add up and can\'t be shown safely'**
  String get subsErrDamaged;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'That amount is too large'**
  String get subsErrTooLarge;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'That didn\'t save. Try again.'**
  String get subsErrFailed;

  /// Toast — a deep link to a subscription that no longer exists
  ///
  /// In en, this message translates to:
  /// **'That subscription isn\'t there any more'**
  String get subsNotFound;

  /// Filter chip (D-S6 — satisfies the reference's unimplemented 'history' capability claim honestly)
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subsFilterActive;

  /// Filter chip (D-S6)
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get subsFilterCancelled;

  /// Filter chip (D-S6)
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get subsFilterAll;

  /// Sort option (subs.tool.js sort default)
  ///
  /// In en, this message translates to:
  /// **'Renewal'**
  String get subsSortRenewal;

  /// Sort option (subs.tool.js)
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get subsSortAmount;

  /// Sort option (subs.tool.js)
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get subsSortName;

  /// Confirmation sheet title
  ///
  /// In en, this message translates to:
  /// **'Cancel this subscription?'**
  String get subsCancelAsk;

  /// Confirmation sheet text
  ///
  /// In en, this message translates to:
  /// **'It stays in your history under Cancelled. You can reactivate it any time.'**
  String get subsCancelText;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Subscription cancelled'**
  String get subsCancelToast;

  /// Detail action
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get subsCancel;

  /// Detail action
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get subsReactivate;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Subscription reactivated'**
  String get subsReactivatedToast;

  /// Confirmation sheet title
  ///
  /// In en, this message translates to:
  /// **'Delete this subscription?'**
  String get subsDeleteAsk;

  /// Confirmation sheet text
  ///
  /// In en, this message translates to:
  /// **'This removes the subscription completely.'**
  String get subsDeleteText;

  /// Toast, with Undo
  ///
  /// In en, this message translates to:
  /// **'Subscription deleted'**
  String get subsDeletedToast;

  /// Meal Plan summary card kicker (mealplan.tool.js 'meal.thisWeek')
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get mealSummaryKicker;

  /// Meal Plan summary card caption (mealplan.tool.js 'meal.planned'); the value beside it is a real count, replacing the reference's 'planned: 18' literal (MEALPLAN_PROPOSAL.md D-M1)
  ///
  /// In en, this message translates to:
  /// **'meals planned'**
  String get mealPlannedCaption;

  /// Section title (mealplan.tool.js 'meal.week')
  ///
  /// In en, this message translates to:
  /// **'Your week'**
  String get mealWeekTitle;

  /// Slot label (mealplan.tool.js 'meal.breakfast')
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealBreakfast;

  /// Slot label (mealplan.tool.js 'meal.lunch')
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealLunch;

  /// Slot label (mealplan.tool.js 'meal.dinner')
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealDinner;

  /// Placeholder for a slot the reader hasn't filled in yet
  ///
  /// In en, this message translates to:
  /// **'Tap to add'**
  String get mealEmptySlot;

  /// Navigation button, unchanged from the reference (mealplan.tool.js 'meal.toShopping') — real navigation to the Shopping tool, kept as-is
  ///
  /// In en, this message translates to:
  /// **'Build a shopping list'**
  String get mealToShopping;

  /// Navigation button, unchanged from the reference (mealplan.tool.js 'meal.browse') — real navigation to the Recipes tool, kept as-is
  ///
  /// In en, this message translates to:
  /// **'Browse recipes'**
  String get mealBrowseRecipes;

  /// The edit sheet's text field label — free text, no nutrition data (D-M2)
  ///
  /// In en, this message translates to:
  /// **'What are you planning?'**
  String get mealFieldText;

  /// Edit sheet action — deletes the entry for this slot
  ///
  /// In en, this message translates to:
  /// **'Clear this slot'**
  String get mealClearSlot;

  /// Toast after filling in or editing a slot
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get mealSlotSavedToast;

  /// Toast after clearing a slot, with Undo
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get mealSlotClearedToast;

  /// Toast — a generic storage failure
  ///
  /// In en, this message translates to:
  /// **'That didn\'t save. Try again.'**
  String get mealErrFailed;

  /// Toast — a write lost a version race
  ///
  /// In en, this message translates to:
  /// **'This slot changed elsewhere'**
  String get mealErrConflict;

  /// Validation
  ///
  /// In en, this message translates to:
  /// **'This person is archived. Unarchive them to add entries.'**
  String get ledgerErrArchived;

  /// Overpayment sheet title
  ///
  /// In en, this message translates to:
  /// **'More than is open'**
  String get ledgerOverpayTitle;

  /// Overpayment sheet, a repayment to the reader
  ///
  /// In en, this message translates to:
  /// **'{name} has paid back {amount} more than is open. Keep it as credit to {name}? It will count against the next loan to them.'**
  String ledgerOverpayToMe(String name, String amount);

  /// Overpayment sheet, a repayment by the reader
  ///
  /// In en, this message translates to:
  /// **'You\'re paying {name} back {amount} more than is open. Keep it as your credit with {name}? It will count against the next time you borrow from them.'**
  String ledgerOverpayByMe(String name, String amount);

  /// Overpayment confirm
  ///
  /// In en, this message translates to:
  /// **'Keep as credit'**
  String get ledgerKeepCredit;

  /// Allocation conflict sheet title
  ///
  /// In en, this message translates to:
  /// **'Your chosen allocation no longer fits'**
  String get ledgerConflictTitle;

  /// Allocation conflict sheet text
  ///
  /// In en, this message translates to:
  /// **'This change leaves less open than you applied by hand. Nothing was saved. Switch those to oldest due first and save?'**
  String get ledgerConflictText;

  /// Hard delete confirmation — void is the normal correction
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get ledgerDeleteEntryTitle;

  /// Hard delete confirmation text
  ///
  /// In en, this message translates to:
  /// **'Only for a mistake — to correct history, void it instead. It\'s removed with its allocations, and you can undo for a few seconds.'**
  String get ledgerDeleteEntryText;

  /// Delete principal with repayments (E8)
  ///
  /// In en, this message translates to:
  /// **'Repayments paid this entry'**
  String get ledgerOrphanTitle;

  /// E8 sheet text
  ///
  /// In en, this message translates to:
  /// **'{amount} was paid back against it. Keep that as credit, or delete those repayments too?'**
  String ledgerOrphanText(String amount);

  /// E8 choice
  ///
  /// In en, this message translates to:
  /// **'Delete them too'**
  String get ledgerOrphanDelete;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get ledgerSaved;

  /// Toast, with Undo
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get ledgerDeleted;

  /// Toast after Undo
  ///
  /// In en, this message translates to:
  /// **'Brought back'**
  String get ledgerRestoredToast;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Entry voided'**
  String get ledgerVoidedToast;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Entry restored'**
  String get ledgerUnvoidedToast;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get ledgerArchivedToast;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Unarchived'**
  String get ledgerUnarchivedToast;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Person deleted'**
  String get ledgerPersonDeleted;

  /// Toast
  ///
  /// In en, this message translates to:
  /// **'Reconciled'**
  String get ledgerReconciled;

  /// Toast: storage failure, rolled back
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Nothing was changed.'**
  String get ledgerWriteFailed;

  /// Toast: a stale version
  ///
  /// In en, this message translates to:
  /// **'This changed while you were editing. Nothing was saved.'**
  String get ledgerWriteConflict;

  /// Toast: write refused over a damaged scope
  ///
  /// In en, this message translates to:
  /// **'This person\'s records need reconciling first. Nothing was saved.'**
  String get ledgerWriteDamaged;

  /// A deep link to a person who is not there
  ///
  /// In en, this message translates to:
  /// **'That person isn\'t in your Ledger.'**
  String get ledgerNotFound;

  /// Reminder sheet title
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get ledgerRemindTitle;

  /// Reminder: choose a balance
  ///
  /// In en, this message translates to:
  /// **'Who to remind'**
  String get ledgerRemindChoose;

  /// Reminder: nothing eligible
  ///
  /// In en, this message translates to:
  /// **'No one owes you anything to remind them about.'**
  String get ledgerRemindNone;

  /// Reminder text, no due date
  ///
  /// In en, this message translates to:
  /// **'Hi {name}, a reminder about {amount} from {date}.'**
  String ledgerRemindBody(String name, String amount, String date);

  /// Reminder text with the shown due date
  ///
  /// In en, this message translates to:
  /// **'Hi {name}, a reminder about {amount} from {date}, due {due}.'**
  String ledgerRemindBodyDue(
    String name,
    String amount,
    String date,
    String due,
  );

  /// Reminder: the editable text
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get ledgerRemindMessage;

  /// Reminder: the fields in the text
  ///
  /// In en, this message translates to:
  /// **'Included: name, amount and currency, date.'**
  String get ledgerRemindFields;

  /// Reminder: the fields in the text
  ///
  /// In en, this message translates to:
  /// **'Included: name, amount and currency, date, due date.'**
  String get ledgerRemindFieldsDue;

  /// Reminder: what is left out
  ///
  /// In en, this message translates to:
  /// **'Not included: notes, other people, other currencies, record ids.'**
  String get ledgerRemindExcluded;

  /// Reminder: honesty about delivery
  ///
  /// In en, this message translates to:
  /// **'Lume doesn\'t send this. Your share sheet does, to whoever you choose there.'**
  String get ledgerRemindHow;

  /// Reminder: the explicit second action
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get ledgerRemindShare;

  /// Reminder result — never "sent" or "delivered"
  ///
  /// In en, this message translates to:
  /// **'Handed to your share sheet'**
  String get ledgerRemindHanded;

  /// Reminder: no share adapter
  ///
  /// In en, this message translates to:
  /// **'Sharing isn\'t available on this device'**
  String get ledgerRemindUnavailable;

  /// Reminder: the platform threw
  ///
  /// In en, this message translates to:
  /// **'The share sheet couldn\'t open'**
  String get ledgerRemindFailed;

  /// Export sheet title
  ///
  /// In en, this message translates to:
  /// **'Export your Ledger'**
  String get ledgerExportTitle;

  /// Export format
  ///
  /// In en, this message translates to:
  /// **'Full backup (JSON)'**
  String get ledgerExportJson;

  /// Export format
  ///
  /// In en, this message translates to:
  /// **'Every entry and allocation. It can be imported again.'**
  String get ledgerExportJsonSub;

  /// Export format
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet (CSV)'**
  String get ledgerExportCsv;

  /// Export format
  ///
  /// In en, this message translates to:
  /// **'One row per entry. It can\'t be imported — use the full backup for that.'**
  String get ledgerExportCsvSub;

  /// Export option, off by default
  ///
  /// In en, this message translates to:
  /// **'Include names and notes'**
  String get ledgerIncludeNames;

  /// Export option on: the privacy line
  ///
  /// In en, this message translates to:
  /// **'This file will contain the names and notes you typed. Anyone you give it to can read them.'**
  String get ledgerIncludeNamesOn;

  /// Export option off
  ///
  /// In en, this message translates to:
  /// **'People are written as Person 1, Person 2… and notes are left out.'**
  String get ledgerIncludeNamesOff;

  /// Export confirm
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get ledgerExportAction;

  /// Import action
  ///
  /// In en, this message translates to:
  /// **'Import a backup'**
  String get ledgerImport;

  /// Import field
  ///
  /// In en, this message translates to:
  /// **'Paste the contents of a lume.ledger/1 backup'**
  String get ledgerImportPaste;

  /// Import: validate before anything is written
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get ledgerImportCheck;

  /// Import preview
  ///
  /// In en, this message translates to:
  /// **'Ready: {c} to add, {u} to update, {s} already here. Nothing is written until you import.'**
  String ledgerImportReady(int c, int u, int s);

  /// Import report: all or nothing
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 problem. Nothing will be imported.} other{{n} problems. Nothing will be imported.}}'**
  String ledgerImportIssues(int n);

  /// Import preview of a redacted backup
  ///
  /// In en, this message translates to:
  /// **'This backup has no names: people will be named Person 1, Person 2…'**
  String get ledgerImportNoNames;

  /// Import confirm
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get ledgerImportAction;

  /// Import toast
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Imported 1 record} other{Imported {n} records}}'**
  String ledgerImported(int n);

  /// Committee first use: nothing seeded
  ///
  /// In en, this message translates to:
  /// **'No committees yet'**
  String get commEmptyTitle;

  /// Committee first use: what the tool is for
  ///
  /// In en, this message translates to:
  /// **'Add a savings committee you are part of. Lume keeps its members, its turns and its cycles, and works out what is collected, paid out and still owed.'**
  String get commEmptyText;

  /// Committee: add action
  ///
  /// In en, this message translates to:
  /// **'Add a committee'**
  String get commAdd;

  /// Committee: the list's section title
  ///
  /// In en, this message translates to:
  /// **'Committees'**
  String get commCommittees;

  /// Committee: search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search committees'**
  String get commSearch;

  /// Committee: the filter bar, for a screen reader
  ///
  /// In en, this message translates to:
  /// **'Filter committees'**
  String get commFilterLabel;

  /// Committee filter: still collecting
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get commFilterRunning;

  /// Committee filter: something is owed past its day
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get commFilterLate;

  /// Committee filter: every cycle paid out
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get commFilterCompleted;

  /// Committee filter: stopped by the reader
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get commFilterCancelled;

  /// Committee sort: by the next cycle's day
  ///
  /// In en, this message translates to:
  /// **'Next cycle'**
  String get commSortNext;

  /// Committee sort
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commSortName;

  /// Committee sort: what one share pays a cycle
  ///
  /// In en, this message translates to:
  /// **'Contribution'**
  String get commSortAmount;

  /// Committee sort
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get commSortRecent;

  /// Committee: no committee matches the filter and search
  ///
  /// In en, this message translates to:
  /// **'Nothing matches'**
  String get commNoMatch;

  /// Committee: no match, what to do
  ///
  /// In en, this message translates to:
  /// **'No committee matches this filter and search.'**
  String get commNoMatchText;

  /// Committee: clear the filter and the search
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get commShowAll;

  /// Committee: a link to a committee that is not there
  ///
  /// In en, this message translates to:
  /// **'That committee is not here'**
  String get commNotFound;

  /// Committee summary kicker: what the committees hold
  ///
  /// In en, this message translates to:
  /// **'Collected, not paid out'**
  String get commInThePot;

  /// Committee summary stat: every contribution recorded
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get commCollected;

  /// Committee summary stat: every payout recorded
  ///
  /// In en, this message translates to:
  /// **'Paid out'**
  String get commPaidOut;

  /// Committee summary stat: owed and unpaid to the day
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get commOutstanding;

  /// Committee summary caption: each committee counted once
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No running committees} =1{1 running committee} other{{n} running committees}}'**
  String commRunning(int n);

  /// Committee: a summary's currency, when there is more than one
  ///
  /// In en, this message translates to:
  /// **'In {code}'**
  String commSummaryCurrency(String code);

  /// Committee summary kicker: the contribution times the shares
  ///
  /// In en, this message translates to:
  /// **'Pool each cycle'**
  String get commPoolEachCycle;

  /// Committee: which cycle the committee is in
  ///
  /// In en, this message translates to:
  /// **'Cycle {n} of {total}'**
  String commCycleOf(String n, String total);

  /// Committee: it has not reached its first cycle
  ///
  /// In en, this message translates to:
  /// **'Starts {date}'**
  String commBeforeStart(String date);

  /// Committee stat: what the reader pays each cycle, for all their shares
  ///
  /// In en, this message translates to:
  /// **'Your contribution'**
  String get commYourContribution;

  /// Committee stat: distinct members, however many shares they hold
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get commPeople;

  /// Committee stat: positions in the payout order
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get commShares;

  /// Committee stat label: the cycle the reader receives
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get commYourTurn;

  /// Committee: a cycle by its number
  ///
  /// In en, this message translates to:
  /// **'Cycle {n}'**
  String commTurnCycle(String n);

  /// Committee stat: the reader's payout is already recorded
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get commTurnDone;

  /// Committee stat: the reader holds no share
  ///
  /// In en, this message translates to:
  /// **'No turn'**
  String get commTurnNone;

  /// Committee section: who has paid into the current cycle
  ///
  /// In en, this message translates to:
  /// **'This cycle'**
  String get commThisCycle;

  /// Committee section: which cycle each share receives, settled when it was created
  ///
  /// In en, this message translates to:
  /// **'Payout order'**
  String get commPayoutOrder;

  /// Committee: the payout order is fixed, unlike the order things are recorded
  ///
  /// In en, this message translates to:
  /// **'Settled when the committee was created. The order records are entered in does not change it.'**
  String get commPayoutOrderCap;

  /// Committee chart title
  ///
  /// In en, this message translates to:
  /// **'Collected each cycle'**
  String get commCollectedEachCycle;

  /// Committee chart caption
  ///
  /// In en, this message translates to:
  /// **'What each cycle has collected of its pool, in {code}.'**
  String commCollectedCap(String code);

  /// Committee chart: it shows one currency
  ///
  /// In en, this message translates to:
  /// **'Committees in other currencies are counted on their own.'**
  String get commOtherCurrencies;

  /// Committee chart bar, for a screen reader
  ///
  /// In en, this message translates to:
  /// **'{cycle}: {amount}'**
  String commChartEntry(String cycle, String amount);

  /// Committee section: the people in it
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get commMembersSection;

  /// Committee row: the cycle this share is paid
  ///
  /// In en, this message translates to:
  /// **'Receives cycle {n}'**
  String commReceivesCycle(String n);

  /// Committee row: a member holding several shares
  ///
  /// In en, this message translates to:
  /// **'Receives cycles {list}'**
  String commReceivesCycles(String list);

  /// Committee row: how many shares a member holds
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 share} other{{n} shares}}'**
  String commShareCount(int n);

  /// Committee: the member who is the reader
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get commYouLabel;

  /// Committee: the day a contribution was handed over
  ///
  /// In en, this message translates to:
  /// **'Paid {date}'**
  String commPaidOn(String date);

  /// Committee: the day a cycle falls due
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String commDueOn(String date);

  /// Committee: a cycle's collection against its pool
  ///
  /// In en, this message translates to:
  /// **'{collected} of {pool}'**
  String commCollectedOf(String collected, String pool);

  /// Committee: what a cycle still needs before a payout
  ///
  /// In en, this message translates to:
  /// **'Short {amount}'**
  String commShortBy(String amount);

  /// Committee progress bar, for a screen reader
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} cycles paid out'**
  String commCyclesPaidOut(String done, String total);

  /// Committee: the history list is empty
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded yet'**
  String get commNoHistory;

  /// Committee fact
  ///
  /// In en, this message translates to:
  /// **'Contribution a cycle'**
  String get commFactContribution;

  /// Committee fact: how many cycles, which is how many shares
  ///
  /// In en, this message translates to:
  /// **'Cycles'**
  String get commFactCycles;

  /// Committee fact
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get commFactFrequency;

  /// Committee: the only frequency this build keeps
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get commMonthly;

  /// Committee fact: the anchor every cycle is worked out from
  ///
  /// In en, this message translates to:
  /// **'First cycle due'**
  String get commFactFirstDue;

  /// Committee fact: contribution times shares
  ///
  /// In en, this message translates to:
  /// **'Pool a cycle'**
  String get commFactPool;

  /// Committee fact: contribution times shares times cycles
  ///
  /// In en, this message translates to:
  /// **'Over the committee'**
  String get commFactExpected;

  /// Committee fact: what the reader is in this committee
  ///
  /// In en, this message translates to:
  /// **'Your part'**
  String get commFactRole;

  /// Committee fact: the day it stopped
  ///
  /// In en, this message translates to:
  /// **'Cancelled on'**
  String get commFactCancelledOn;

  /// Committee fact: what was owed when it stopped, and does not grow
  ///
  /// In en, this message translates to:
  /// **'Unpaid at cancellation'**
  String get commUnpaidAtCancelTotal;

  /// Committee role: the reader pays and receives
  ///
  /// In en, this message translates to:
  /// **'A member'**
  String get commRoleMember;

  /// Committee role: the reader runs it and holds no share
  ///
  /// In en, this message translates to:
  /// **'The organiser'**
  String get commRoleOrganiser;

  /// Committee role: both
  ///
  /// In en, this message translates to:
  /// **'Organiser and member'**
  String get commRoleBoth;

  /// Committee: what the tool does and does not do
  ///
  /// In en, this message translates to:
  /// **'Lume keeps your own record of this committee. It holds no money and moves none.'**
  String get commRoleHelp;

  /// Committee: a share's contribution for a cycle is recorded
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get commPaid;

  /// Committee: the cycle falls due on the reader's day
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get commDueToday;

  /// Committee: the cycle fell due before the reader's day
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get commLate;

  /// Committee: the cycle falls due later
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get commUpcoming;

  /// Committee: owed when the committee stopped, and not growing
  ///
  /// In en, this message translates to:
  /// **'Unpaid at cancellation'**
  String get commUnpaidAtCancel;

  /// Committee: the cycle fell after the committee was cancelled
  ///
  /// In en, this message translates to:
  /// **'Not due'**
  String get commNotDue;

  /// Committee: without the reader's day no state is claimed
  ///
  /// In en, this message translates to:
  /// **'Not known'**
  String get commDayUnknown;

  /// Committee: the reader's zone could not be resolved
  ///
  /// In en, this message translates to:
  /// **'Lume cannot work out your day, so it does not say what is late or due. The dates themselves are shown as they are.'**
  String get commDayUnknownText;

  /// Committee: the reader recorded that this cycle's pool was handed over
  ///
  /// In en, this message translates to:
  /// **'Payout recorded'**
  String get commPayoutRecorded;

  /// Committee: fully collected, so a payout can be recorded
  ///
  /// In en, this message translates to:
  /// **'Ready to pay out'**
  String get commPayoutReady;

  /// Committee: part collected, so nothing may be paid out yet
  ///
  /// In en, this message translates to:
  /// **'Waiting on contributions'**
  String get commPayoutWaiting;

  /// Committee action
  ///
  /// In en, this message translates to:
  /// **'Record contribution'**
  String get commRecordContribution;

  /// Committee action: the reader's note that the pool was handed over outside Lume
  ///
  /// In en, this message translates to:
  /// **'Record payout'**
  String get commRecordPayout;

  /// Committee action
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commEdit;

  /// Committee action
  ///
  /// In en, this message translates to:
  /// **'Cancel committee'**
  String get commCancelCommittee;

  /// Committee: the way out of cancelling
  ///
  /// In en, this message translates to:
  /// **'Keep it running'**
  String get commKeepCommittee;

  /// Committee action: undo a cancellation
  ///
  /// In en, this message translates to:
  /// **'Reinstate'**
  String get commReinstate;

  /// Committee action
  ///
  /// In en, this message translates to:
  /// **'Delete committee'**
  String get commDeleteCommittee;

  /// Committee sheet title
  ///
  /// In en, this message translates to:
  /// **'Record contribution'**
  String get commPayTitle;

  /// Committee sheet: what is about to be recorded
  ///
  /// In en, this message translates to:
  /// **'{name} pays {amount} for cycle {n}, due {due}.'**
  String commPayText(String name, String amount, String n, String due);

  /// Committee sheet: a member holding several shares pays for each
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{One share} other{{n} shares, recorded together}}'**
  String commPayShares(int n);

  /// Committee sheet: the date field
  ///
  /// In en, this message translates to:
  /// **'Day it was paid'**
  String get commPaidOnLabel;

  /// Committee sheet: confirm
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get commPayGo;

  /// Committee sheet title
  ///
  /// In en, this message translates to:
  /// **'Record payout'**
  String get commPayoutTitle;

  /// Committee sheet: what a payout record means
  ///
  /// In en, this message translates to:
  /// **'{name} receives {amount} for cycle {n}. Lume records it; it moves no money.'**
  String commPayoutText(String name, String amount, String n);

  /// Committee toast
  ///
  /// In en, this message translates to:
  /// **'Contribution recorded'**
  String get commPaidToast;

  /// Committee toast: what the reader recorded, not what Lume did
  ///
  /// In en, this message translates to:
  /// **'Payout recorded'**
  String get commPayoutToast;

  /// Committee: take a contribution out of the figures
  ///
  /// In en, this message translates to:
  /// **'Void this contribution'**
  String get commVoidContribution;

  /// Committee: put it back
  ///
  /// In en, this message translates to:
  /// **'Restore this contribution'**
  String get commRestoreContribution;

  /// Committee: take a payout out of the figures
  ///
  /// In en, this message translates to:
  /// **'Void this payout'**
  String get commVoidPayout;

  /// Committee: put it back
  ///
  /// In en, this message translates to:
  /// **'Restore this payout'**
  String get commRestorePayout;

  /// Committee: a record kept but out of the figures
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get commVoided;

  /// Committee toast
  ///
  /// In en, this message translates to:
  /// **'Taken out of the figures'**
  String get commVoidedToast;

  /// Committee toast
  ///
  /// In en, this message translates to:
  /// **'Put back'**
  String get commRestoredToast;

  /// Committee: cancel confirmation title
  ///
  /// In en, this message translates to:
  /// **'Cancel this committee?'**
  String get commCancelTitle;

  /// Committee: what cancelling does and does not do
  ///
  /// In en, this message translates to:
  /// **'Every record is kept. Cycles after today raise nothing; what was already owed stays as unpaid at cancellation. No refund is worked out, and nothing is paid back.'**
  String get commCancelText;

  /// Committee toast
  ///
  /// In en, this message translates to:
  /// **'Committee cancelled'**
  String get commCancelledToast;

  /// Committee toast
  ///
  /// In en, this message translates to:
  /// **'Committee reinstated'**
  String get commReinstatedToast;

  /// Committee: delete confirmation title
  ///
  /// In en, this message translates to:
  /// **'Delete this committee?'**
  String get commDeleteTitle;

  /// Committee: exactly what deleting removes
  ///
  /// In en, this message translates to:
  /// **'This removes the committee, {members}, {shares}, {cycles}, {contributions} and {payouts}.'**
  String commDeleteText(
    String members,
    String shares,
    String cycles,
    String contributions,
    String payouts,
  );

  /// Committee toast
  ///
  /// In en, this message translates to:
  /// **'Committee deleted'**
  String get commDeletedToast;

  /// Committee toast after Undo
  ///
  /// In en, this message translates to:
  /// **'Committee restored'**
  String get commRestoredCommitteeToast;

  /// Committee: a record cannot be read
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get commNeedsAttention;

  /// Committee: stored records that cannot be decoded
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 record can\'t be read. It is kept as it is, and its committee is left out of the totals.} other{{n} records can\'t be read. They are kept as they are, and their committees are left out of the totals.}}'**
  String commDefects(int n);

  /// Committee: a damaged committee
  ///
  /// In en, this message translates to:
  /// **'Some of this committee\'s records do not hold together, so its figures are left out. You can look at it and delete it; nothing else will write over it.'**
  String get commDamagedText;

  /// Committee form title
  ///
  /// In en, this message translates to:
  /// **'New committee'**
  String get commNewCommittee;

  /// Committee form title
  ///
  /// In en, this message translates to:
  /// **'Edit committee'**
  String get commEditCommittee;

  /// Committee form field: the reader's own label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commFieldName;

  /// Committee form field
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get commFieldNote;

  /// Committee form field
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get commFieldCurrency;

  /// Committee form field: what one share pays each cycle
  ///
  /// In en, this message translates to:
  /// **'Contribution a cycle'**
  String get commFieldContribution;

  /// Committee form field: the anchor every cycle is worked out from
  ///
  /// In en, this message translates to:
  /// **'First cycle due'**
  String get commFieldFirstDue;

  /// Committee form field
  ///
  /// In en, this message translates to:
  /// **'Your part'**
  String get commFieldRole;

  /// Committee form section: the people and the order they are paid in
  ///
  /// In en, this message translates to:
  /// **'Members and turns'**
  String get commFieldMembers;

  /// Committee form: how the order and shares work
  ///
  /// In en, this message translates to:
  /// **'They are paid in this order: the first receives cycle 1. A member with two shares pays twice a cycle and is paid twice.'**
  String get commMembersHelp;

  /// Committee form: a member row's label
  ///
  /// In en, this message translates to:
  /// **'Member {n}'**
  String commMemberName(String n);

  /// Committee form action
  ///
  /// In en, this message translates to:
  /// **'Add a member'**
  String get commAddMember;

  /// Committee form action
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commRemoveMember;

  /// Committee form: earlier in the payout order
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get commMoveUp;

  /// Committee form: later in the payout order
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get commMoveDown;

  /// Committee form field: how many turns this member holds
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get commFieldShares;

  /// Committee form: mark the member who is the reader
  ///
  /// In en, this message translates to:
  /// **'This is you'**
  String get commThisIsYou;

  /// Committee form: once a contribution or payout exists
  ///
  /// In en, this message translates to:
  /// **'The terms are fixed'**
  String get commLockedTitle;

  /// Committee form: what is locked, and what is not
  ///
  /// In en, this message translates to:
  /// **'A contribution or a payout has been recorded, so the amount, the currency, the shares, the first day and the order stay as they are. The names and the note can still be changed.'**
  String get commLockedText;

  /// Committee toast
  ///
  /// In en, this message translates to:
  /// **'Committee saved'**
  String get commSaved;

  /// Committee form error
  ///
  /// In en, this message translates to:
  /// **'Give the committee a name'**
  String get commErrName;

  /// Committee form error
  ///
  /// In en, this message translates to:
  /// **'Give every member a name'**
  String get commErrMemberName;

  /// Committee form error
  ///
  /// In en, this message translates to:
  /// **'That is too long'**
  String get commErrLong;

  /// Committee form error
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get commErrDate;

  /// Committee form error
  ///
  /// In en, this message translates to:
  /// **'A committee needs at least two shares'**
  String get commErrMembers;

  /// Committee form error
  ///
  /// In en, this message translates to:
  /// **'Shares must be a whole number of at least one'**
  String get commErrShares;

  /// Committee form error: the role and the reader must agree
  ///
  /// In en, this message translates to:
  /// **'Mark exactly one member as you, or say you are the organiser only'**
  String get commErrReader;

  /// Committee form error: organiser only
  ///
  /// In en, this message translates to:
  /// **'An organiser who holds no share has no member to mark'**
  String get commErrReaderNone;

  /// Committee form error
  ///
  /// In en, this message translates to:
  /// **'That is outside what this can hold'**
  String get commErrRange;

  /// Committee error
  ///
  /// In en, this message translates to:
  /// **'That figure is too large to work with'**
  String get commErrTooLarge;

  /// Committee form error
  ///
  /// In en, this message translates to:
  /// **'{code} is no longer in use for a new committee'**
  String commErrWithdrawn(String code);

  /// Committee form error
  ///
  /// In en, this message translates to:
  /// **'A payment cannot be dated after today'**
  String get commErrFuture;

  /// Committee error
  ///
  /// In en, this message translates to:
  /// **'That is already recorded'**
  String get commErrDuplicate;

  /// Committee error: a payout before the cycle is collected
  ///
  /// In en, this message translates to:
  /// **'Cycle {n} is still short {amount}. A payout is recorded once it is fully collected.'**
  String commErrIncomplete(String n, String amount);

  /// Committee error
  ///
  /// In en, this message translates to:
  /// **'Void this cycle\'s payout first'**
  String get commErrPaidOut;

  /// Committee error
  ///
  /// In en, this message translates to:
  /// **'This committee is cancelled'**
  String get commErrCancelled;

  /// Committee error
  ///
  /// In en, this message translates to:
  /// **'It changed while you were working. Open it again.'**
  String get commErrConflict;

  /// Committee error
  ///
  /// In en, this message translates to:
  /// **'This committee\'s records do not hold together'**
  String get commErrDamaged;

  /// Committee error
  ///
  /// In en, this message translates to:
  /// **'That could not be saved. Nothing was changed.'**
  String get commErrFailed;

  /// Committee export sheet title
  ///
  /// In en, this message translates to:
  /// **'Export committees'**
  String get commExportTitle;

  /// Committee export: the lossless format
  ///
  /// In en, this message translates to:
  /// **'Backup file (JSON)'**
  String get commExportJson;

  /// Committee export: what JSON is for
  ///
  /// In en, this message translates to:
  /// **'Everything, and it can be imported again.'**
  String get commExportJsonHelp;

  /// Committee export: the view format
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet (CSV)'**
  String get commExportCsv;

  /// Committee export: what CSV is and is not
  ///
  /// In en, this message translates to:
  /// **'One row per share per cycle. It cannot be imported.'**
  String get commExportCsvHelp;

  /// Committee export: the privacy switch
  ///
  /// In en, this message translates to:
  /// **'Include names'**
  String get commExportNames;

  /// Committee export: what including names means
  ///
  /// In en, this message translates to:
  /// **'Off, the file says Committee 1 and Member 2, and leaves notes out. On, it carries the names of everyone in your committees.'**
  String get commExportNamesHelp;

  /// Committee export: confirm
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get commExportGo;

  /// Committee import: open the sheet
  ///
  /// In en, this message translates to:
  /// **'Import a backup'**
  String get commImport;

  /// Committee import: the field's label
  ///
  /// In en, this message translates to:
  /// **'Paste a Lume committee backup file'**
  String get commImportText;

  /// Committee import: check without writing
  ///
  /// In en, this message translates to:
  /// **'Check it'**
  String get commImportCheck;

  /// Committee import: what a good file would do
  ///
  /// In en, this message translates to:
  /// **'Ready: {c} to add, {u} to update, {s} already here. Nothing is written until you import.'**
  String commImportReady(String c, String u, String s);

  /// Committee import: the file is refused whole
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 problem. Nothing will be imported.} other{{n} problems. Nothing will be imported.}}'**
  String commImportIssues(int n);

  /// Committee import: a redacted file
  ///
  /// In en, this message translates to:
  /// **'No names in this backup: members will be called Member 1, Member 2…'**
  String get commImportNoNames;

  /// Committee import: confirm
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get commImportAction;

  /// Committee import toast
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{Imported 1 record} other{Imported {n} records}}'**
  String commImported(int n);

  /// Committee member: what this member has contributed over the committee
  ///
  /// In en, this message translates to:
  /// **'Paid in'**
  String get commMemberPaidLabel;

  /// Committee member: contribution times cycles times their shares
  ///
  /// In en, this message translates to:
  /// **'Owed over the committee'**
  String get commMemberExpected;

  /// Committee member section: every cycle, and whether this member paid it
  ///
  /// In en, this message translates to:
  /// **'Their cycles'**
  String get commTheirCycles;

  /// Committee delete confirmation: how many members would go
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 member} other{{n} members}}'**
  String commCountMembers(int n);

  /// Committee delete confirmation: how many shares would go
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 share} other{{n} shares}}'**
  String commCountShares(int n);

  /// Committee delete confirmation: how many cycles would go
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 cycle} other{{n} cycles}}'**
  String commCountCycles(int n);

  /// Committee delete confirmation: how many contributions would go
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{no contributions} =1{1 contribution} other{{n} contributions}}'**
  String commCountContributions(int n);

  /// Committee delete confirmation: how many payouts would go
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{no payouts} =1{1 payout} other{{n} payouts}}'**
  String commCountPayouts(int n);

  /// Baby Budget: the list of the reader’s own budgets
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get babyBudgets;

  /// Baby Budget: start a budget
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get babyAdd;

  /// Baby Budget: the empty state title
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get babyEmptyTitle;

  /// Baby Budget: the empty state body
  ///
  /// In en, this message translates to:
  /// **'Start a budget to see what a month costs, where it goes and what is coming up. Everything stays on this device.'**
  String get babyEmptyText;

  /// Baby Budget: the search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search budgets and categories'**
  String get babySearch;

  /// Baby Budget: no budget matched the filter or search
  ///
  /// In en, this message translates to:
  /// **'Nothing matches'**
  String get babyNoMatch;

  /// Baby Budget: what to do when nothing matched
  ///
  /// In en, this message translates to:
  /// **'Try another word, or show every budget.'**
  String get babyNoMatchText;

  /// Baby Budget: clear the filter and the search
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get babyShowAll;

  /// Baby Budget: the filter bar’s accessible name
  ///
  /// In en, this message translates to:
  /// **'Filter budgets'**
  String get babyFilterLabel;

  /// Baby Budget: budgets that are running
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get babyFilterInUse;

  /// Baby Budget: budgets whose start date has not arrived
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get babyFilterNotStarted;

  /// Baby Budget: budgets put away
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get babyFilterArchived;

  /// Baby Budget: sort by name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get babySortName;

  /// Baby Budget: sort by what the month has cost
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get babySortSpend;

  /// Baby Budget: sort by last activity
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get babySortRecent;

  /// Baby Budget: a record could not be read
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get babyNeedsAttention;

  /// Baby Budget: how many stored records failed to decode
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 record could not be read. Nothing was changed.} other{{n} records could not be read. Nothing was changed.}}'**
  String babyDefects(int n);

  /// Baby Budget: the damaged-budget notice
  ///
  /// In en, this message translates to:
  /// **'Part of this budget could not be read, so its figures are left out. You can still delete it.'**
  String get babyDamagedText;

  /// Baby Budget: a deep link pointed at a budget that has gone
  ///
  /// In en, this message translates to:
  /// **'That budget is no longer here.'**
  String get babyNotFound;

  /// Baby Budget: which currency a summary card covers
  ///
  /// In en, this message translates to:
  /// **'In {code}'**
  String babySummaryCurrency(String code);

  /// Baby Budget: what the current month has cost
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get babyThisMonth;

  /// Baby Budget: everything recorded since the budget started
  ///
  /// In en, this message translates to:
  /// **'Spent to date'**
  String get babySpentToDate;

  /// Baby Budget: what the planned purchases add up to
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get babyPlannedTotal;

  /// Baby Budget: how many budgets a summary covers
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 budget} other{{n} budgets}}'**
  String babyBudgetCount(int n);

  /// Baby Budget: the progress ring’s label
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get babyPlanLabel;

  /// Baby Budget: how much of the monthly plan the month has used
  ///
  /// In en, this message translates to:
  /// **'{percent} of plan'**
  String babyOfPlan(String percent);

  /// Baby Budget: the month has passed the plan
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String babyOverBy(String amount);

  /// Baby Budget: the budget has no monthly plan, so there is no ratio
  ///
  /// In en, this message translates to:
  /// **'No plan set'**
  String get babyNoPlan;

  /// Baby Budget: the budget starts on a day that has not arrived
  ///
  /// In en, this message translates to:
  /// **'Not started yet'**
  String get babyNotStartedTitle;

  /// Baby Budget: when the budget begins
  ///
  /// In en, this message translates to:
  /// **'This budget starts on {date}. Nothing is counted before then.'**
  String babyNotStartedText(String date);

  /// Baby Budget: the day the reader put the budget away
  ///
  /// In en, this message translates to:
  /// **'Archived on {date}'**
  String babyArchivedOn(String date);

  /// Baby Budget: the first day the budget covers
  ///
  /// In en, this message translates to:
  /// **'Started on {date}'**
  String babyStartedOn(String date);

  /// Baby Budget: the part of the plan no category holds
  ///
  /// In en, this message translates to:
  /// **'{amount} unallocated'**
  String babyUnallocated(String amount);

  /// Baby Budget: the donut of categories
  ///
  /// In en, this message translates to:
  /// **'Where it goes'**
  String get babyWhereItGoes;

  /// Baby Budget: the word under the figure in the donut
  ///
  /// In en, this message translates to:
  /// **'a month'**
  String get babyAMonth;

  /// Baby Budget: the donut’s accessible name
  ///
  /// In en, this message translates to:
  /// **'Where this month’s spending goes'**
  String get babyDonutLabel;

  /// Baby Budget: the bar chart of recent months
  ///
  /// In en, this message translates to:
  /// **'Six months'**
  String get babySixMonths;

  /// Baby Budget: what the bars count
  ///
  /// In en, this message translates to:
  /// **'Monthly spending in {code}, without planned purchases'**
  String babySixMonthsCap(String code);

  /// Baby Budget: one bar, for a screen reader
  ///
  /// In en, this message translates to:
  /// **'{month}: {amount}'**
  String babyChartEntry(String month, String amount);

  /// Baby Budget: planned purchases with an expected day
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get babyComingUp;

  /// Baby Budget: planned purchases with no day
  ///
  /// In en, this message translates to:
  /// **'One-off purchases'**
  String get babyOneOff;

  /// Baby Budget: no planned purchases
  ///
  /// In en, this message translates to:
  /// **'Nothing planned.'**
  String get babyNothingPlanned;

  /// Baby Budget: the month has no spends
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded this month.'**
  String get babyNothingThisMonth;

  /// Baby Budget: spends with no category of their own
  ///
  /// In en, this message translates to:
  /// **'Uncategorised'**
  String get babyUncategorised;

  /// Baby Budget: the reader’s own categories
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get babyCategories;

  /// Baby Budget: the budget has no categories
  ///
  /// In en, this message translates to:
  /// **'No categories yet. Spends without one are counted together.'**
  String get babyNoCategories;

  /// Baby Budget: the list of a month’s spends
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get babyMonthSpending;

  /// Baby Budget: the month picker option that drops the filter
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get babyEveryMonth;

  /// Baby Budget: the month picker’s label
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get babyMonthLabel;

  /// Baby Budget: one category’s own spends
  ///
  /// In en, this message translates to:
  /// **'In this category'**
  String get babyCategorySpending;

  /// Baby Budget: how much of the month a category holds
  ///
  /// In en, this message translates to:
  /// **'{percent} of this month'**
  String babyShareOfMonth(String percent);

  /// Baby Budget: what a category means to spend a month
  ///
  /// In en, this message translates to:
  /// **'Category plan'**
  String get babyCategoryPlan;

  /// Baby Budget: how many spends a category holds
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{nothing recorded} =1{1 spend} other{{n} spends}}'**
  String babySpendCount(int n);

  /// Baby Budget: a planned purchase whose expected day has passed
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get babyOverdue;

  /// Baby Budget: a planned purchase still to come
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get babyExpected;

  /// Baby Budget: a planned purchase with no expected day
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get babyUndated;

  /// Baby Budget: this is an intention, not a spend
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get babyPlannedBadge;

  /// Baby Budget: a spend the reader took out of the figures
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get babyVoidedBadge;

  /// Baby Budget: the reader’s calendar day could not be worked out
  ///
  /// In en, this message translates to:
  /// **'Day unknown'**
  String get babyDayUnknown;

  /// Baby Budget: what is missing without the reader’s day
  ///
  /// In en, this message translates to:
  /// **'Your time zone could not be worked out, so nothing is called overdue and no month is shown.'**
  String get babyDayUnknownText;

  /// Baby Budget: when a planned purchase is expected
  ///
  /// In en, this message translates to:
  /// **'Expected {date}'**
  String babyExpectedOn(String date);

  /// Baby Budget: the day money went
  ///
  /// In en, this message translates to:
  /// **'Spent {date}'**
  String babySpentOn(String date);

  /// Baby Budget: add money that went
  ///
  /// In en, this message translates to:
  /// **'Record a spend'**
  String get babyRecordSpend;

  /// Baby Budget: add something the reader means to buy
  ///
  /// In en, this message translates to:
  /// **'Plan a purchase'**
  String get babyPlanPurchase;

  /// Baby Budget: turn a planned purchase into a spend
  ///
  /// In en, this message translates to:
  /// **'Mark as bought'**
  String get babyMarkBought;

  /// Baby Budget: turn a spend back into an intention
  ///
  /// In en, this message translates to:
  /// **'Move back to planned'**
  String get babyMarkPlanned;

  /// Baby Budget: change the budget’s name, plan or start
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get babyEditBudget;

  /// Baby Budget: change one spend
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get babyEditSpend;

  /// Baby Budget: put a budget away, keeping everything
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get babyArchive;

  /// Baby Budget: take a budget out of the archive
  ///
  /// In en, this message translates to:
  /// **'Bring back'**
  String get babyUnarchive;

  /// Baby Budget: remove a budget and everything it holds
  ///
  /// In en, this message translates to:
  /// **'Delete budget'**
  String get babyDeleteBudget;

  /// Baby Budget: name a new category
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get babyAddCategory;

  /// Baby Budget: the category form’s title
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get babyEditCategoryTitle;

  /// Baby Budget: remove a category
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get babyDeleteCategory;

  /// Baby Budget: take a spend out of the figures without deleting it
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get babyVoidSpend;

  /// Baby Budget: put a voided spend back
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get babyRestoreSpend;

  /// Baby Budget: see one category’s own spends
  ///
  /// In en, this message translates to:
  /// **'Open category'**
  String get babyOpenCategory;

  /// Baby Budget: the create form’s title
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get babyNewBudget;

  /// Baby Budget: the edit form’s title
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get babyEditBudgetTitle;

  /// Baby Budget: what the reader calls this budget
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get babyFieldName;

  /// Baby Budget: how to fill the name
  ///
  /// In en, this message translates to:
  /// **'Whatever you call it. Nothing here has to name a child.'**
  String get babyNameHint;

  /// Baby Budget: the one currency this budget uses
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get babyFieldCurrency;

  /// Baby Budget: what the reader means to spend a month
  ///
  /// In en, this message translates to:
  /// **'Monthly plan'**
  String get babyFieldPlan;

  /// Baby Budget: the monthly plan is optional
  ///
  /// In en, this message translates to:
  /// **'Leave it empty for no plan. Without one there is no percentage.'**
  String get babyPlanHint;

  /// Baby Budget: the first day the budget covers
  ///
  /// In en, this message translates to:
  /// **'Started on'**
  String get babyFieldStartedOn;

  /// Baby Budget: what the start date does
  ///
  /// In en, this message translates to:
  /// **'Nothing may be recorded before this day.'**
  String get babyStartHint;

  /// Baby Budget: a free note on the budget
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get babyFieldNote;

  /// Baby Budget: the categories form section
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get babyFieldCategories;

  /// Baby Budget: how categories are used
  ///
  /// In en, this message translates to:
  /// **'Name the things you spend on. Anything without a category is counted on its own.'**
  String get babyCategoriesHint;

  /// Baby Budget: one category name field
  ///
  /// In en, this message translates to:
  /// **'Category {n}'**
  String babyCategoryName(String n);

  /// Baby Budget: take a category out of the form
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get babyRemoveCategory;

  /// Baby Budget: move a category earlier
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get babyMoveUp;

  /// Baby Budget: move a category later
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get babyMoveDown;

  /// Baby Budget: which tone a category’s slice takes
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get babyFieldColour;

  /// Baby Budget: one of the category tones
  ///
  /// In en, this message translates to:
  /// **'Colour {n}'**
  String babyColourName(String n);

  /// Baby Budget: how much a spend was
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get babyFieldAmount;

  /// Baby Budget: which category a spend belongs to
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get babyFieldCategory;

  /// Baby Budget: a spend’s own label
  ///
  /// In en, this message translates to:
  /// **'What it is'**
  String get babyFieldLabel;

  /// Baby Budget: the day money went
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get babyFieldDay;

  /// Baby Budget: the day a planned purchase is expected
  ///
  /// In en, this message translates to:
  /// **'Expected on'**
  String get babyFieldExpected;

  /// Baby Budget: a planned purchase without an expected day
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get babyNoDate;

  /// Baby Budget: drop the expected day
  ///
  /// In en, this message translates to:
  /// **'Clear the date'**
  String get babyClearDate;

  /// Baby Budget: the currency cannot change once a spend exists
  ///
  /// In en, this message translates to:
  /// **'The currency is fixed'**
  String get babyLockedTitle;

  /// Baby Budget: why the currency is locked
  ///
  /// In en, this message translates to:
  /// **'This budget already has records in {code}. To use another currency, archive it and start a new one.'**
  String babyLockedText(String code);

  /// Baby Budget: the spend form’s title
  ///
  /// In en, this message translates to:
  /// **'Record a spend'**
  String get babySpendTitle;

  /// Baby Budget: the planned purchase form’s title
  ///
  /// In en, this message translates to:
  /// **'Plan a purchase'**
  String get babyPlanTitle;

  /// Baby Budget: the edit form’s title for a spend
  ///
  /// In en, this message translates to:
  /// **'Edit spend'**
  String get babyEditSpendTitle;

  /// Baby Budget: the edit form’s title for a plan
  ///
  /// In en, this message translates to:
  /// **'Edit planned purchase'**
  String get babyEditPlanTitle;

  /// Baby Budget: the real amount, replacing the estimate
  ///
  /// In en, this message translates to:
  /// **'What it actually cost'**
  String get babyActualAmount;

  /// Baby Budget: the sheet that turns a plan into a spend
  ///
  /// In en, this message translates to:
  /// **'Mark as bought'**
  String get babyBoughtTitle;

  /// Baby Budget: what marking bought does
  ///
  /// In en, this message translates to:
  /// **'{label} was planned at {amount}. Record it as spent, and change the amount if it cost something else.'**
  String babyBoughtText(String label, String amount);

  /// Baby Budget: confirm marking a purchase bought
  ///
  /// In en, this message translates to:
  /// **'Record it'**
  String get babyBoughtGo;

  /// Baby Budget: the sheet that turns a spend back into a plan
  ///
  /// In en, this message translates to:
  /// **'Move back to planned'**
  String get babyPlannedAgainTitle;

  /// Baby Budget: what moving back to planned does
  ///
  /// In en, this message translates to:
  /// **'This takes {amount} out of the month’s figures and puts it back on the planned list. The record itself is kept.'**
  String babyPlannedAgainText(String amount);

  /// Baby Budget: confirm moving a spend back to planned
  ///
  /// In en, this message translates to:
  /// **'Move it back'**
  String get babyPlannedAgainGo;

  /// Baby Budget: the archive confirmation’s title
  ///
  /// In en, this message translates to:
  /// **'Archive this budget?'**
  String get babyArchiveTitle;

  /// Baby Budget: what archiving does
  ///
  /// In en, this message translates to:
  /// **'Every record is kept and every figure stays. Nothing new can be added until you bring it back.'**
  String get babyArchiveText;

  /// Baby Budget: confirm archiving
  ///
  /// In en, this message translates to:
  /// **'Archive it'**
  String get babyArchiveGo;

  /// Baby Budget: do not archive
  ///
  /// In en, this message translates to:
  /// **'Keep it open'**
  String get babyKeepBudget;

  /// Baby Budget: the delete confirmation’s title
  ///
  /// In en, this message translates to:
  /// **'Delete this budget?'**
  String get babyDeleteTitle;

  /// Baby Budget: exactly what deleting removes
  ///
  /// In en, this message translates to:
  /// **'This removes the budget, {categories}, {spends} and {planned}.'**
  String babyDeleteText(String categories, String spends, String planned);

  /// Baby Budget delete confirmation: how many categories would go
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{no categories} =1{1 category} other{{n} categories}}'**
  String babyCountCategories(int n);

  /// Baby Budget delete confirmation: how many spends would go
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{no spends} =1{1 spend} other{{n} spends}}'**
  String babyCountSpends(int n);

  /// Baby Budget delete confirmation: how many planned purchases would go
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{no planned purchases} =1{1 planned purchase} other{{n} planned purchases}}'**
  String babyCountPlanned(int n);

  /// Baby Budget: the category delete confirmation’s title
  ///
  /// In en, this message translates to:
  /// **'Delete this category?'**
  String get babyDeleteCategoryTitle;

  /// Baby Budget: what happens to a deleted category’s spends
  ///
  /// In en, this message translates to:
  /// **'Its {spends} are kept. Choose where they should go.'**
  String babyDeleteCategoryText(String spends);

  /// Baby Budget: do not move a deleted category’s spends
  ///
  /// In en, this message translates to:
  /// **'Leave them uncategorised'**
  String get babyMoveToNone;

  /// Baby Budget: move a deleted category’s spends into another
  ///
  /// In en, this message translates to:
  /// **'Move them to {name}'**
  String babyMoveTo(String name);

  /// Baby Budget: the budget was written
  ///
  /// In en, this message translates to:
  /// **'Budget saved.'**
  String get babySaved;

  /// Baby Budget: a spend was written
  ///
  /// In en, this message translates to:
  /// **'Spend recorded.'**
  String get babySpendSaved;

  /// Baby Budget: a planned purchase was written
  ///
  /// In en, this message translates to:
  /// **'Purchase planned.'**
  String get babyPlanSaved;

  /// Baby Budget: a plan became a spend
  ///
  /// In en, this message translates to:
  /// **'Recorded as bought.'**
  String get babyBoughtToast;

  /// Baby Budget: a spend became a plan again
  ///
  /// In en, this message translates to:
  /// **'Moved back to planned.'**
  String get babyPlannedAgainToast;

  /// Baby Budget: a spend was taken out of the figures
  ///
  /// In en, this message translates to:
  /// **'Spend voided.'**
  String get babyVoidedToast;

  /// Baby Budget: a voided spend was put back
  ///
  /// In en, this message translates to:
  /// **'Spend restored.'**
  String get babyRestoredToast;

  /// Baby Budget: a category was written
  ///
  /// In en, this message translates to:
  /// **'Category saved.'**
  String get babyCategorySaved;

  /// Baby Budget: a category was removed
  ///
  /// In en, this message translates to:
  /// **'Category deleted.'**
  String get babyCategoryDeletedToast;

  /// Baby Budget: the budget was put away
  ///
  /// In en, this message translates to:
  /// **'Budget archived.'**
  String get babyArchivedToast;

  /// Baby Budget: the budget is in use again
  ///
  /// In en, this message translates to:
  /// **'Budget brought back.'**
  String get babyUnarchivedToast;

  /// Baby Budget: the budget and its records were removed
  ///
  /// In en, this message translates to:
  /// **'Budget deleted.'**
  String get babyDeletedToast;

  /// Baby Budget: an undone delete brought the budget back
  ///
  /// In en, this message translates to:
  /// **'Budget restored.'**
  String get babyRestoredBudgetToast;

  /// Baby Budget: the name is missing
  ///
  /// In en, this message translates to:
  /// **'Give the budget a name.'**
  String get babyErrName;

  /// Baby Budget: a category name is missing
  ///
  /// In en, this message translates to:
  /// **'Give every category a name.'**
  String get babyErrCategoryName;

  /// Baby Budget: a field is over its limit
  ///
  /// In en, this message translates to:
  /// **'That is too long.'**
  String get babyErrLong;

  /// Baby Budget: the amount is missing or zero
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above zero.'**
  String get babyErrAmount;

  /// Baby Budget: a date is missing
  ///
  /// In en, this message translates to:
  /// **'Choose a date.'**
  String get babyErrDate;

  /// Baby Budget: the spend date is in the future
  ///
  /// In en, this message translates to:
  /// **'A spend cannot be dated after today.'**
  String get babyErrFuture;

  /// Baby Budget: the archive date is in the future
  ///
  /// In en, this message translates to:
  /// **'A budget cannot be archived on a day that has not arrived.'**
  String get babyErrArchivedFuture;

  /// Baby Budget: the date precedes the start
  ///
  /// In en, this message translates to:
  /// **'This budget starts on {date}. Nothing can be recorded before then.'**
  String babyErrBeforeStart(String date);

  /// Baby Budget: the new start would orphan a record
  ///
  /// In en, this message translates to:
  /// **'{label} is dated {date}. Move or remove it before changing the start.'**
  String babyErrStartAfter(String label, String date);

  /// Baby Budget: the plan is zero
  ///
  /// In en, this message translates to:
  /// **'A plan has to be above zero. Leave it empty for no plan.'**
  String get babyErrZeroPlan;

  /// Baby Budget: a category plan needs a budget plan
  ///
  /// In en, this message translates to:
  /// **'Set a monthly plan for the budget before giving a category one.'**
  String get babyErrNoBudgetPlan;

  /// Baby Budget: the category plans exceed the budget
  ///
  /// In en, this message translates to:
  /// **'The category plans add up to more than the budget’s plan.'**
  String get babyErrOverPlan;

  /// Baby Budget: the new plan is under the sum of its categories
  ///
  /// In en, this message translates to:
  /// **'That is less than the categories already hold. Lower them first.'**
  String get babyErrBelowCategories;

  /// Baby Budget: too many categories
  ///
  /// In en, this message translates to:
  /// **'A budget can hold {n} categories.'**
  String babyErrCategoryLimit(String n);

  /// Baby Budget: two categories share a name
  ///
  /// In en, this message translates to:
  /// **'There is already a category with that name.'**
  String get babyErrDuplicate;

  /// Baby Budget: an archived budget takes no writes
  ///
  /// In en, this message translates to:
  /// **'This budget is archived. Bring it back to change anything.'**
  String get babyErrArchived;

  /// Baby Budget: the stored version moved on
  ///
  /// In en, this message translates to:
  /// **'This changed somewhere else. Open it again.'**
  String get babyErrConflict;

  /// Baby Budget: a damaged budget takes no writes
  ///
  /// In en, this message translates to:
  /// **'Part of this budget could not be read, so nothing was changed.'**
  String get babyErrDamaged;

  /// Baby Budget: an amount would overflow
  ///
  /// In en, this message translates to:
  /// **'That number is too large to store.'**
  String get babyErrTooLarge;

  /// Baby Budget: the write failed
  ///
  /// In en, this message translates to:
  /// **'That could not be saved.'**
  String get babyErrFailed;

  /// Baby Budget: the export sheet’s title
  ///
  /// In en, this message translates to:
  /// **'Export this budget'**
  String get babyExportTitle;

  /// Baby Budget: what export writes
  ///
  /// In en, this message translates to:
  /// **'A file saved to this device. Names and notes are left out unless you keep them.'**
  String get babyExportText;

  /// Baby Budget: the lossless export
  ///
  /// In en, this message translates to:
  /// **'Full backup (JSON)'**
  String get babyExportJson;

  /// Baby Budget: what the JSON holds
  ///
  /// In en, this message translates to:
  /// **'Everything, so it can be brought back into Lume.'**
  String get babyExportJsonText;

  /// Baby Budget: the readable export
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet (CSV)'**
  String get babyExportCsv;

  /// Baby Budget: what the CSV holds
  ///
  /// In en, this message translates to:
  /// **'One row per spend. It cannot be brought back in.'**
  String get babyExportCsvText;

  /// Baby Budget: do not redact the export
  ///
  /// In en, this message translates to:
  /// **'Keep names and notes'**
  String get babyKeepNames;

  /// Baby Budget: what redaction does
  ///
  /// In en, this message translates to:
  /// **'Off, the budget is called Budget 1 and categories Category 1, Category 2 and so on.'**
  String get babyKeepNamesText;

  /// Baby Budget: read a JSON file back in
  ///
  /// In en, this message translates to:
  /// **'Import a backup'**
  String get babyImport;

  /// Baby Budget: what import does
  ///
  /// In en, this message translates to:
  /// **'Choose a Lume budget file. Nothing already here is touched, and nothing is written unless the whole file reads cleanly.'**
  String get babyImportText;

  /// Baby Budget: the file was exported redacted
  ///
  /// In en, this message translates to:
  /// **'This backup has no names: budgets will be called Budget 1, Budget 2 and so on.'**
  String get babyImportNoNames;

  /// Baby Budget: confirm the import
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get babyImportAction;

  /// Baby Budget: how many records came in
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 record imported} other{{n} records imported}}'**
  String babyImported(int n);

  /// Baby Budget: write the file
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get babyExportGo;

  /// Baby Budget: read the file without writing anything
  ///
  /// In en, this message translates to:
  /// **'Check it'**
  String get babyImportCheck;

  /// Baby Budget: what a checked file would do
  ///
  /// In en, this message translates to:
  /// **'Ready: {c} to add, {u} to update, {s} already here. Nothing is written until you import.'**
  String babyImportReady(String c, String u, String s);

  /// Baby Budget: the file was refused whole
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 problem. Nothing will be imported.} other{{n} problems. Nothing will be imported.}}'**
  String babyImportIssues(int n);

  /// World Clock: the reader’s own clock
  ///
  /// In en, this message translates to:
  /// **'Your time'**
  String get clockYourTime;

  /// World Clock: the label under it
  ///
  /// In en, this message translates to:
  /// **'Your time zone'**
  String get clockYourZone;

  /// World Clock: the list of places
  ///
  /// In en, this message translates to:
  /// **'Clocks'**
  String get clockCities;

  /// World Clock: add a zone to the list
  ///
  /// In en, this message translates to:
  /// **'Add a place'**
  String get clockAdd;

  /// World Clock: the picker’s title
  ///
  /// In en, this message translates to:
  /// **'Add a place'**
  String get clockAddTitle;

  /// World Clock: the search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search cities and time zones'**
  String get clockSearch;

  /// World Clock: no zone matched
  ///
  /// In en, this message translates to:
  /// **'Nothing matches'**
  String get clockNoMatch;

  /// World Clock: what to do when nothing matched
  ///
  /// In en, this message translates to:
  /// **'Try a city, a country or a time zone name.'**
  String get clockNoMatchText;

  /// World Clock: clear the search
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get clockShowAll;

  /// World Clock: the empty list
  ///
  /// In en, this message translates to:
  /// **'No places yet'**
  String get clockEmptyTitle;

  /// World Clock: the empty state body
  ///
  /// In en, this message translates to:
  /// **'Add a city to see its time beside yours. Your own time is always here.'**
  String get clockEmptyText;

  /// World Clock: how many places the list holds
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 place} other{{n} places}}'**
  String clockCount(int n);

  /// World Clock: the place keeps the reader’s own time
  ///
  /// In en, this message translates to:
  /// **'Same time'**
  String get clockSameTime;

  /// World Clock: the place is ahead of the reader
  ///
  /// In en, this message translates to:
  /// **'{offset} ahead'**
  String clockAhead(String offset);

  /// World Clock: the place is behind the reader
  ///
  /// In en, this message translates to:
  /// **'{offset} behind'**
  String clockBehind(String offset);

  /// World Clock: the place is on the day before the reader’s
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get clockYesterday;

  /// World Clock: the place is on the reader’s own day
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get clockToday;

  /// World Clock: the place is on the day after the reader’s
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get clockTomorrow;

  /// World Clock: the place is currently on daylight saving time
  ///
  /// In en, this message translates to:
  /// **'Summer time'**
  String get clockSummerTime;

  /// World Clock: what a screen reader hears for one row
  ///
  /// In en, this message translates to:
  /// **'{place}, {time}, {day}, {offset}'**
  String clockRowSemantics(
    String place,
    String time,
    String day,
    String offset,
  );

  /// World Clock: the converter section
  ///
  /// In en, this message translates to:
  /// **'Convert a time'**
  String get clockConvert;

  /// World Clock: the zone converted from
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get clockConvertFrom;

  /// World Clock: the zone converted to
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get clockConvertTo;

  /// World Clock: the time being converted
  ///
  /// In en, this message translates to:
  /// **'At'**
  String get clockConvertAt;

  /// World Clock: the converted time and its day
  ///
  /// In en, this message translates to:
  /// **'{time} on {day}'**
  String clockConvertResult(String time, String day);

  /// World Clock: both sides of the converter are the same zone
  ///
  /// In en, this message translates to:
  /// **'Pick two different places'**
  String get clockConvertSame;

  /// World Clock: take a place off the list
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get clockRemove;

  /// World Clock: move a place earlier
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get clockMoveUp;

  /// World Clock: move a place later
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get clockMoveDown;

  /// World Clock: a place joined the list
  ///
  /// In en, this message translates to:
  /// **'{place} added'**
  String clockAdded(String place);

  /// World Clock: a place left the list
  ///
  /// In en, this message translates to:
  /// **'{place} removed'**
  String clockRemovedToast(String place);

  /// World Clock: the same zone twice is refused
  ///
  /// In en, this message translates to:
  /// **'{place} is already on the list'**
  String clockAlready(String place);

  /// World Clock: a stored identifier the database does not hold
  ///
  /// In en, this message translates to:
  /// **'That time zone is not known'**
  String get clockZoneUnknownTitle;

  /// World Clock: the unknown-zone body
  ///
  /// In en, this message translates to:
  /// **'Lume could not find “{id}” in the time-zone database it carries. Nothing has been guessed in its place.'**
  String clockZoneUnknownText(String id);

  /// World Clock: the database did not load
  ///
  /// In en, this message translates to:
  /// **'The time-zone database is unavailable'**
  String get clockDatabaseTitle;

  /// World Clock: the database-unavailable body
  ///
  /// In en, this message translates to:
  /// **'Without it no time anywhere can be worked out, and none is shown.'**
  String get clockDatabaseText;

  /// World Clock: the device zone is unknown
  ///
  /// In en, this message translates to:
  /// **'This device has not said where it is'**
  String get clockDeviceTitle;

  /// World Clock: the missing-device-zone body
  ///
  /// In en, this message translates to:
  /// **'Choose your time zone in Settings, and your own clock will appear here.'**
  String get clockDeviceText;

  /// World Clock: the country needs a city or an explicit zone
  ///
  /// In en, this message translates to:
  /// **'Your country has more than one time zone'**
  String get clockChooseTitle;

  /// World Clock: the selection-required body
  ///
  /// In en, this message translates to:
  /// **'Choose the one you are in, and your own clock will appear here.'**
  String get clockChooseText;

  /// World Clock: a stored identifier that the database has renamed
  ///
  /// In en, this message translates to:
  /// **'{stored} is now called {canonical}'**
  String clockAliasNote(String stored, String canonical);

  /// World Clock: which database the times come from
  ///
  /// In en, this message translates to:
  /// **'IANA time-zone database {version}'**
  String clockDatabaseVersion(String version);

  /// Calculator: the keypad’s name
  ///
  /// In en, this message translates to:
  /// **'Calculator keypad'**
  String get calcKeypad;

  /// Calculator: the readout’s name
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get calcDisplay;

  /// Calculator: the running sum’s name
  ///
  /// In en, this message translates to:
  /// **'Expression'**
  String get calcExpression;

  /// Calculator: the list of finished sums
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get calcHistory;

  /// Calculator: the history is empty
  ///
  /// In en, this message translates to:
  /// **'Nothing worked out yet.'**
  String get calcNoHistory;

  /// Calculator: clear everything
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get calcClear;

  /// Calculator: clear the number being typed
  ///
  /// In en, this message translates to:
  /// **'Clear entry'**
  String get calcClearEntry;

  /// Calculator: delete the last digit
  ///
  /// In en, this message translates to:
  /// **'Backspace'**
  String get calcBackspace;

  /// Calculator: work it out
  ///
  /// In en, this message translates to:
  /// **'Equals'**
  String get calcEquals;

  /// Calculator: add
  ///
  /// In en, this message translates to:
  /// **'Plus'**
  String get calcPlus;

  /// Calculator: subtract
  ///
  /// In en, this message translates to:
  /// **'Minus'**
  String get calcMinus;

  /// Calculator: multiply
  ///
  /// In en, this message translates to:
  /// **'Times'**
  String get calcTimes;

  /// Calculator: divide
  ///
  /// In en, this message translates to:
  /// **'Divided by'**
  String get calcDivide;

  /// Calculator: divide by a hundred
  ///
  /// In en, this message translates to:
  /// **'Per cent'**
  String get calcPercent;

  /// Calculator: the decimal separator key
  ///
  /// In en, this message translates to:
  /// **'Decimal point'**
  String get calcDecimal;

  /// Calculator: make it negative or positive
  ///
  /// In en, this message translates to:
  /// **'Change sign'**
  String get calcSign;

  /// Calculator: one of the ten digit keys
  ///
  /// In en, this message translates to:
  /// **'Digit {n}'**
  String calcDigit(String n);

  /// Calculator: the reader asked to divide by zero
  ///
  /// In en, this message translates to:
  /// **'Nothing can be divided by zero'**
  String get calcErrDivZero;

  /// Calculator: the entry reached its length limit
  ///
  /// In en, this message translates to:
  /// **'That is as many digits as this can hold'**
  String get calcErrTooLong;

  /// Calculator: the result left the range the calculator keeps exactly
  ///
  /// In en, this message translates to:
  /// **'That number is too large to work with'**
  String get calcErrOverflow;

  /// Calculator: a recurring decimal cut at the kept precision
  ///
  /// In en, this message translates to:
  /// **'That division does not end'**
  String get calcErrPrecision;

  /// Calculator: one finished sum
  ///
  /// In en, this message translates to:
  /// **'{expression} = {result}'**
  String calcHistoryRow(String expression, String result);

  /// Calculator: everything was cleared
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get calcCleared;

  /// Calculator: how the arithmetic is done
  ///
  /// In en, this message translates to:
  /// **'Worked out exactly, to {places} decimal places.'**
  String calcPrecisionNote(String places);

  /// Focus Timer: the working stretch
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusFocus;

  /// Focus Timer: the resting stretch
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get focusBreak;

  /// Focus Timer: begin
  ///
  /// In en, this message translates to:
  /// **'Start focus'**
  String get focusStart;

  /// Focus Timer: hold it where it is
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get focusPause;

  /// Focus Timer: carry on
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get focusResume;

  /// Focus Timer: back to the full time
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get focusReset;

  /// Focus Timer: go to the next stretch
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get focusSkip;

  /// Focus Timer: the working stretch ended
  ///
  /// In en, this message translates to:
  /// **'Focus finished'**
  String get focusDone;

  /// Focus Timer: the resting stretch ended
  ///
  /// In en, this message translates to:
  /// **'Break over'**
  String get focusBreakOver;

  /// Focus Timer: where the reader is in the round
  ///
  /// In en, this message translates to:
  /// **'Session {n} of {of}'**
  String focusSession(String n, String of);

  /// Focus Timer: the clock is going
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get focusRunning;

  /// Focus Timer: the clock is held
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get focusPaused;

  /// Focus Timer: the clock has not started
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get focusReady;

  /// Focus Timer: how long a stretch runs
  ///
  /// In en, this message translates to:
  /// **'Focus length'**
  String get focusLength;

  /// Focus Timer: how long a break runs
  ///
  /// In en, this message translates to:
  /// **'Break length'**
  String get focusBreakLength;

  /// Focus Timer: how long the reader has focused today
  ///
  /// In en, this message translates to:
  /// **'Minutes today'**
  String get focusToday;

  /// Focus Timer: consecutive days with a session
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get focusStreakLabel;

  /// Focus Timer: how many sessions were finished
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get focusSessionsLabel;

  /// Focus Timer: the seven-day chart
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get focusThisWeek;

  /// Focus Timer: one bar, for a screen reader
  ///
  /// In en, this message translates to:
  /// **'{day}: {minutes}'**
  String focusChartEntry(String day, String minutes);

  /// Focus Timer: what the reader has done since opening the tool
  ///
  /// In en, this message translates to:
  /// **'This session'**
  String get focusThisSession;

  /// Focus Timer: no session has finished in this run of the app
  ///
  /// In en, this message translates to:
  /// **'Nothing yet — start a session and it will count here.'**
  String get focusNothingYet;

  /// Focus Timer: what "this session" means, said plainly
  ///
  /// In en, this message translates to:
  /// **'Counted since you opened Lume. Nothing here survives closing it.'**
  String get focusKeptSession;

  /// Tasbih: the number the reader is on
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get tasbihCounter;

  /// Tasbih: what the big control does
  ///
  /// In en, this message translates to:
  /// **'Tap to count'**
  String get tasbihTap;

  /// Tasbih: how far through a round the reader is
  ///
  /// In en, this message translates to:
  /// **'{count} of {target}'**
  String tasbihOf(String count, String target);

  /// Tasbih: how many full rounds have been counted
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No rounds} =1{1 round} other{{n} rounds}}'**
  String tasbihSets(int n);

  /// Tasbih: back to zero
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get tasbihReset;

  /// Tasbih: the reset confirmation
  ///
  /// In en, this message translates to:
  /// **'Reset the counter?'**
  String get tasbihResetAsk;

  /// Tasbih: what resetting does
  ///
  /// In en, this message translates to:
  /// **'The count and the rounds go back to zero. Nothing is kept.'**
  String get tasbihResetText;

  /// Tasbih: confirm the reset
  ///
  /// In en, this message translates to:
  /// **'Reset it'**
  String get tasbihResetGo;

  /// Tasbih: do not reset
  ///
  /// In en, this message translates to:
  /// **'Keep counting'**
  String get tasbihKeepCount;

  /// Tasbih: the target was reached
  ///
  /// In en, this message translates to:
  /// **'Round complete'**
  String get tasbihComplete;

  /// Tasbih: which words are being counted
  ///
  /// In en, this message translates to:
  /// **'Phrase'**
  String get tasbihPhrase;

  /// Tasbih: the phrase picker
  ///
  /// In en, this message translates to:
  /// **'Choose a phrase'**
  String get tasbihPickTitle;

  /// Tasbih: switching phrases mid-count
  ///
  /// In en, this message translates to:
  /// **'Change the phrase?'**
  String get tasbihSwitchAsk;

  /// Tasbih: what switching does
  ///
  /// In en, this message translates to:
  /// **'The count goes back to zero. The rounds you have finished are kept.'**
  String get tasbihSwitchText;

  /// Tasbih: confirm the switch
  ///
  /// In en, this message translates to:
  /// **'Change it'**
  String get tasbihSwitchGo;

  /// Tasbih: the count reached its ceiling
  ///
  /// In en, this message translates to:
  /// **'That is as high as the counter goes'**
  String get tasbihMax;

  /// Tasbih: an honest statement of what is not stored
  ///
  /// In en, this message translates to:
  /// **'The count is here while Lume is open. Nothing is written down.'**
  String get tasbihNotKept;

  /// Tasbih: the conventional count for this phrase
  ///
  /// In en, this message translates to:
  /// **'Round of {n}'**
  String tasbihTargetLabel(String n);

  /// Tasbih: the label above the phrase’s plain meaning, in the reader’s own language
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get tasbihMeaning;

  /// Play: the grid of games
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get playGames;

  /// Play: what sort of game it is
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get playKind;

  /// Play: a puzzle game
  ///
  /// In en, this message translates to:
  /// **'Puzzle'**
  String get playKindPuzzle;

  /// Play: a word game
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get playKindWord;

  /// Play: a memory game
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get playKindMemory;

  /// Play: an arithmetic game
  ///
  /// In en, this message translates to:
  /// **'Arithmetic'**
  String get playKindArithmetic;

  /// Play: a game’s name
  ///
  /// In en, this message translates to:
  /// **'Number Grid'**
  String get playGameNumberGrid;

  /// Play: a game’s name
  ///
  /// In en, this message translates to:
  /// **'Word Chain'**
  String get playGameWordChain;

  /// Play: a game’s name
  ///
  /// In en, this message translates to:
  /// **'Memory Match'**
  String get playGameMemoryMatch;

  /// Play: a game’s name
  ///
  /// In en, this message translates to:
  /// **'Quick Maths'**
  String get playGameQuickMaths;

  /// Play: the reference draws the tile and nothing opens
  ///
  /// In en, this message translates to:
  /// **'Not playable yet'**
  String get playNotYet;

  /// Play: why nothing opens, said plainly
  ///
  /// In en, this message translates to:
  /// **'None of these can be played yet, and nothing here is a score of yours.'**
  String get playNotYetText;

  /// Play: how many games the grid holds
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 game} other{{n} games}}'**
  String playCount(int n);

  /// Reference key uc.length
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get ucLength;

  /// Reference key uc.mass - the reference word is Weight, not Mass
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get ucMass;

  /// Reference key uc.volume
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get ucVolume;

  /// Reference key uc.area
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get ucArea;

  /// Reference key uc.speed
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get ucSpeed;

  /// Reference key uc.data
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get ucData;

  /// Reference key uc.metre
  ///
  /// In en, this message translates to:
  /// **'Metre'**
  String get ucMetre;

  /// Reference key uc.kilometre
  ///
  /// In en, this message translates to:
  /// **'Kilometre'**
  String get ucKilometre;

  /// Reference key uc.centimetre
  ///
  /// In en, this message translates to:
  /// **'Centimetre'**
  String get ucCentimetre;

  /// Reference key uc.mile
  ///
  /// In en, this message translates to:
  /// **'Mile'**
  String get ucMile;

  /// Reference key uc.foot
  ///
  /// In en, this message translates to:
  /// **'Foot'**
  String get ucFoot;

  /// Reference key uc.inch
  ///
  /// In en, this message translates to:
  /// **'Inch'**
  String get ucInch;

  /// Reference key uc.kilogram
  ///
  /// In en, this message translates to:
  /// **'Kilogram'**
  String get ucKilogram;

  /// Reference key uc.gram
  ///
  /// In en, this message translates to:
  /// **'Gram'**
  String get ucGram;

  /// Reference key uc.pound
  ///
  /// In en, this message translates to:
  /// **'Pound'**
  String get ucPound;

  /// Reference key uc.ounce
  ///
  /// In en, this message translates to:
  /// **'Ounce'**
  String get ucOunce;

  /// Reference key uc.tola
  ///
  /// In en, this message translates to:
  /// **'Tola'**
  String get ucTola;

  /// Reference key uc.litre
  ///
  /// In en, this message translates to:
  /// **'Litre'**
  String get ucLitre;

  /// Reference key uc.millilitre
  ///
  /// In en, this message translates to:
  /// **'Millilitre'**
  String get ucMillilitre;

  /// Reference key uc.gallon. The reference names this one US in English and still shows a bare gal beside it; C100 separates the two gallons
  ///
  /// In en, this message translates to:
  /// **'Gallon (US)'**
  String get ucGallonUs;

  /// No reference key - the imperial gallon the reference has no unit for (C100)
  ///
  /// In en, this message translates to:
  /// **'Gallon (imperial)'**
  String get ucGallonImp;

  /// Reference key uc.cup, named for the US legal cup of 240 ml that its 0.24 factor actually is (C100)
  ///
  /// In en, this message translates to:
  /// **'Cup (US)'**
  String get ucCupUs;

  /// Reference key uc.sqmetre
  ///
  /// In en, this message translates to:
  /// **'Square metre'**
  String get ucSqmetre;

  /// Reference key uc.sqfoot
  ///
  /// In en, this message translates to:
  /// **'Square foot'**
  String get ucSqfoot;

  /// Reference key uc.acre
  ///
  /// In en, this message translates to:
  /// **'Acre'**
  String get ucAcre;

  /// Reference key uc.marla
  ///
  /// In en, this message translates to:
  /// **'Marla'**
  String get ucMarla;

  /// Reference key uc.kmh
  ///
  /// In en, this message translates to:
  /// **'Kilometres per hour'**
  String get ucKmh;

  /// Reference key uc.mph
  ///
  /// In en, this message translates to:
  /// **'Miles per hour'**
  String get ucMph;

  /// Reference key uc.ms
  ///
  /// In en, this message translates to:
  /// **'Metres per second'**
  String get ucMs;

  /// No reference key - the base the two data families hang off (C100)
  ///
  /// In en, this message translates to:
  /// **'Byte'**
  String get ucByte;

  /// No reference key - 1,000 bytes (C100)
  ///
  /// In en, this message translates to:
  /// **'Kilobyte'**
  String get ucKilobyte;

  /// Reference key uc.megabyte
  ///
  /// In en, this message translates to:
  /// **'Megabyte'**
  String get ucMegabyte;

  /// Reference key uc.gigabyte
  ///
  /// In en, this message translates to:
  /// **'Gigabyte'**
  String get ucGigabyte;

  /// Reference key uc.terabyte
  ///
  /// In en, this message translates to:
  /// **'Terabyte'**
  String get ucTerabyte;

  /// No reference key - the IEC binary unit, 1,024 bytes (C100)
  ///
  /// In en, this message translates to:
  /// **'Kibibyte'**
  String get ucKibibyte;

  /// No reference key - the IEC binary unit, 1,024 KiB (C100)
  ///
  /// In en, this message translates to:
  /// **'Mebibyte'**
  String get ucMebibyte;

  /// No reference key - the IEC binary unit, 1,024 MiB (C100)
  ///
  /// In en, this message translates to:
  /// **'Gibibyte'**
  String get ucGibibyte;

  /// No reference key - the IEC binary unit, 1,024 GiB (C100)
  ///
  /// In en, this message translates to:
  /// **'Tebibyte'**
  String get ucTebibyte;

  /// Reference key convert.swap
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get convertSwap;

  /// Reference key convert.allUnits
  ///
  /// In en, this message translates to:
  /// **'All units'**
  String get convertAllUnits;

  /// No reference key - the amount field carries no label in the reference, and an unlabelled field is a field a screen reader cannot name
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get convertAmount;

  /// No reference key - which unit is being converted from
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get convertFrom;

  /// No reference key - which unit is being converted to
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get convertTo;

  /// No reference key - the unit picker the reference does not have (C100)
  ///
  /// In en, this message translates to:
  /// **'Choose a unit'**
  String get convertChooseUnit;

  /// No reference key - the category strip has no accessible name in the reference
  ///
  /// In en, this message translates to:
  /// **'What to convert'**
  String get convertCategory;

  /// No reference key - what a screen reader hears for the result, which is otherwise two numbers with no stated relation between them
  ///
  /// In en, this message translates to:
  /// **'{from} is {to}'**
  String convertEquals(String from, String to);

  /// No reference key - the reference puts binary factors under decimal names; the names are separated here and the difference is stated where the reader chooses (C100)
  ///
  /// In en, this message translates to:
  /// **'kB, MB, GB and TB are powers of 1,000. KiB, MiB, GiB and TiB are powers of 1,024.'**
  String get convertDataNote;

  /// Reference key birthdays.next
  ///
  /// In en, this message translates to:
  /// **'Next up'**
  String get birthdaysNext;

  /// Reference key birthdays.tracked
  ///
  /// In en, this message translates to:
  /// **'Tracked'**
  String get birthdaysTracked;

  /// Reference key birthdays.thisMonth
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get birthdaysThisMonth;

  /// Reference key birthdays.turning
  ///
  /// In en, this message translates to:
  /// **'Turning'**
  String get birthdaysTurning;

  /// Reference key birthdays.turns
  ///
  /// In en, this message translates to:
  /// **'turns {n}'**
  String birthdaysTurns(int n);

  /// No reference key - an anniversary counts years; it does not turn an age
  ///
  /// In en, this message translates to:
  /// **'{n} years'**
  String birthdaysYears(int n);

  /// Reference key birthdays.upcoming
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get birthdaysUpcoming;

  /// Reference key birthdays.birthday
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthdaysBirthday;

  /// Reference key birthdays.anniversary
  ///
  /// In en, this message translates to:
  /// **'Anniversary'**
  String get birthdaysAnniversary;

  /// Reference key birthdays.add
  ///
  /// In en, this message translates to:
  /// **'Add a date'**
  String get birthdaysAdd;

  /// No reference key - the reference has four fixture dates and so can never be empty (C100)
  ///
  /// In en, this message translates to:
  /// **'Nothing coming up'**
  String get birthdaysNothingTitle;

  /// No reference key - see birthdaysNothingTitle
  ///
  /// In en, this message translates to:
  /// **'Dates you add appear here, soonest first.'**
  String get birthdaysNothingText;

  /// Reference key rec.birthdays.noun
  ///
  /// In en, this message translates to:
  /// **'date'**
  String get recBirthdaysNoun;

  /// Reference key rec.birthdays.nounPlural
  ///
  /// In en, this message translates to:
  /// **'birthdays & anniversaries'**
  String get recBirthdaysNounPlural;

  /// Reference key rec.birthdays.emptyTitle
  ///
  /// In en, this message translates to:
  /// **'No dates saved'**
  String get recBirthdaysEmptyTitle;

  /// Reference key rec.birthdays.emptyText. The reference promises a reminder - "Lume will remind you in good time" - and nothing in this build schedules or delivers one, so it says what it does do (C100)
  ///
  /// In en, this message translates to:
  /// **'Add a birthday and it is counted down here.'**
  String get recBirthdaysEmptyText;

  /// Reference key rec.birthdays.ph
  ///
  /// In en, this message translates to:
  /// **'Whose day is it?'**
  String get recBirthdaysPh;

  /// Reference key rec.f.occasion
  ///
  /// In en, this message translates to:
  /// **'Occasion'**
  String get recFieldOccasion;

  /// Reference key rec.nextOne
  ///
  /// In en, this message translates to:
  /// **'Next one'**
  String get recNextOne;

  /// Reference key rec.turning
  ///
  /// In en, this message translates to:
  /// **'Turning'**
  String get recTurning;

  /// Reference key rec.seed.ourAnniversary
  ///
  /// In en, this message translates to:
  /// **'Our anniversary'**
  String get recSeedOurAnniversary;

  /// Reference key water.today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get waterToday;

  /// Reference key water.ofTarget. "target" there, "goal" here, because this figure is a goal the reader sets and not a recommendation (C100)
  ///
  /// In en, this message translates to:
  /// **'of a {target} goal'**
  String waterOfTarget(String target);

  /// No reference key - said while the goal is still the one the tool opened with, so a figure the reader never chose is never presented as theirs (C100)
  ///
  /// In en, this message translates to:
  /// **'of the default {target} goal'**
  String waterOfDefault(String target);

  /// Reference key water.progress
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get waterProgress;

  /// Reference key water.remaining
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get waterRemaining;

  /// Reference key water.glasses
  ///
  /// In en, this message translates to:
  /// **'Glasses'**
  String get waterGlasses;

  /// No reference key - how many drinks were logged today, in the slot the reference fills with a Day streak of 6 that nothing counted (C100)
  ///
  /// In en, this message translates to:
  /// **'Logged'**
  String get waterLogged;

  /// Reference key water.timeline
  ///
  /// In en, this message translates to:
  /// **'Today’s intake'**
  String get waterTimeline;

  /// Reference key water.kindWater
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get waterKindWater;

  /// Reference key water.kindTea
  ///
  /// In en, this message translates to:
  /// **'Tea'**
  String get waterKindTea;

  /// Reference key water.added
  ///
  /// In en, this message translates to:
  /// **'{amount} logged'**
  String waterAdded(String amount);

  /// No reference key - the reference fixes 2000 ml for every reader with no way to change it (C100)
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get waterGoal;

  /// No reference key - marks a goal the reader has not set, so it is never read as advice (C100)
  ///
  /// In en, this message translates to:
  /// **'Default goal'**
  String get waterGoalDefault;

  /// No reference key - see waterGoal
  ///
  /// In en, this message translates to:
  /// **'Change goal'**
  String get waterSetGoal;

  /// No reference key - the one sentence that keeps a number on a hydration screen from reading as medical guidance (C100)
  ///
  /// In en, this message translates to:
  /// **'A goal to fill, not a health recommendation.'**
  String get waterGoalHint;

  /// No reference key - see waterGoal
  ///
  /// In en, this message translates to:
  /// **'Goal in ml'**
  String get waterGoalMl;

  /// Reference key rec.water.emptyTitle, over the tool own summary rather than the list
  ///
  /// In en, this message translates to:
  /// **'Nothing logged today'**
  String get waterNothingTitle;

  /// Reference key rec.water.emptyText
  ///
  /// In en, this message translates to:
  /// **'Log a glass and today’s total starts filling.'**
  String get waterNothingText;

  /// No reference key - the two buttons are labelled with the amount alone in the reference, which a screen reader hears as a bare number
  ///
  /// In en, this message translates to:
  /// **'Add {amount}'**
  String waterAddSmall(String amount);

  /// Reference key rec.water.noun
  ///
  /// In en, this message translates to:
  /// **'drink'**
  String get recWaterNoun;

  /// Reference key rec.water.nounPlural. The reference says "today’s drinks" over a list that holds every day it has; this list is not filtered to today, so it does not claim to be (C100)
  ///
  /// In en, this message translates to:
  /// **'drinks'**
  String get recWaterNounPlural;

  /// Reference key rec.water.emptyTitle
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet'**
  String get recWaterEmptyTitle;

  /// Reference key rec.water.emptyText
  ///
  /// In en, this message translates to:
  /// **'Log a glass and your daily total starts filling.'**
  String get recWaterEmptyText;

  /// Reference key rec.f.amountMl
  ///
  /// In en, this message translates to:
  /// **'Amount in ml'**
  String get recFieldAmountMl;

  /// Reference key rec.f.drink
  ///
  /// In en, this message translates to:
  /// **'Drink'**
  String get recFieldDrink;

  /// Reference key rec.f.repeat
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get recFieldRepeat;

  /// Wave 7 (ROLLOUT_WAVE_7.md) — Reminders' label field, the schema's own copy (rec.f.remindMe)
  ///
  /// In en, this message translates to:
  /// **'Remind me to'**
  String get remFieldLabel;

  /// reminders.once
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get remRepeatOnce;

  /// reminders.daily
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get remRepeatDaily;

  /// reminders.weekly
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get remRepeatWeekly;

  /// Validation: the label field was left empty
  ///
  /// In en, this message translates to:
  /// **'Say what to be reminded about'**
  String get remErrLabel;

  /// A save or delete found a newer version than the one on screen
  ///
  /// In en, this message translates to:
  /// **'This reminder changed elsewhere'**
  String get remErrConflict;

  /// A write failed for a reason other than a conflict
  ///
  /// In en, this message translates to:
  /// **'That didn\'t save. Try again.'**
  String get remErrFailed;

  /// Toast: the record saved, but the reader's timezone could not be resolved, so nothing was scheduled with the platform (REMINDERS_PROPOSAL.md §2 — never guessed)
  ///
  /// In en, this message translates to:
  /// **'Saved — set your location in Account so this can fire on time'**
  String get remSavedNoZone;

  /// Toast: the record saved, but the platform refused or failed to schedule the notification
  ///
  /// In en, this message translates to:
  /// **'Saved, but the reminder couldn\'t be scheduled'**
  String get remSavedNoSchedule;

  /// Button, and the add sheet's title
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get remAddReminder;

  /// The edit sheet's title
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get remEditReminder;

  /// Toast after deleting a reminder, with Undo
  ///
  /// In en, this message translates to:
  /// **'Reminder deleted'**
  String get remDeletedToast;

  /// Banner shown when the platform's notification permission is not granted (REMINDERS_PROPOSAL.md §4)
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications'**
  String get remPermissionTitle;

  /// Banner body, explaining why the permission matters
  ///
  /// In en, this message translates to:
  /// **'Lume needs permission to remind you at the right time, even when the app is closed.'**
  String get remPermissionText;

  /// Button: the permission can only be changed from the platform's own Settings screen
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get remOpenSettings;

  /// Button: the platform will still show its own request dialog
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get remEnableNotifications;

  /// Android 12+ banner: exact-alarm scheduling is not available
  ///
  /// In en, this message translates to:
  /// **'Allow exact timing'**
  String get remExactAlarmTitle;

  /// Android 12+ banner body
  ///
  /// In en, this message translates to:
  /// **'Without this, Android may deliver a reminder a few minutes late.'**
  String get remExactAlarmText;

  /// Summary card kicker
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remSummaryKicker;

  /// Summary card caption, read after the count of enabled reminders
  ///
  /// In en, this message translates to:
  /// **'turned on'**
  String get remSummaryCaption;

  /// rec.reminders.emptyTitle
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get remEmptyTitle;

  /// rec.reminders.emptyText
  ///
  /// In en, this message translates to:
  /// **'Set one and Lume will nudge you at the right time.'**
  String get remEmptyText;

  /// The height field's label on the BMI calculator.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get bmiFieldHeight;

  /// The weight field's label on the BMI calculator.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get bmiFieldWeight;

  /// The summary card's kicker, and the progress gauge's accessible name.
  ///
  /// In en, this message translates to:
  /// **'Your BMI'**
  String get bmiYourBmi;

  /// The band label for a BMI under 18.5.
  ///
  /// In en, this message translates to:
  /// **'Underweight'**
  String get bmiBandUnderweight;

  /// The band label for a BMI from 18.5 up to 25.
  ///
  /// In en, this message translates to:
  /// **'Healthy weight'**
  String get bmiBandHealthy;

  /// The band label for a BMI from 25 up to 30.
  ///
  /// In en, this message translates to:
  /// **'Overweight'**
  String get bmiBandOverweight;

  /// The band label for a BMI of 30 and over.
  ///
  /// In en, this message translates to:
  /// **'Obese'**
  String get bmiBandObese;

  /// The section title over the four bands.
  ///
  /// In en, this message translates to:
  /// **'BMI scale'**
  String get bmiScale;

  /// The section title over the healthy range and ideal weight rows.
  ///
  /// In en, this message translates to:
  /// **'Healthy weight for you'**
  String get bmiHealthyTitle;

  /// The row label for the healthy-weight range at the reader's height.
  ///
  /// In en, this message translates to:
  /// **'Healthy range'**
  String get bmiHealthyRange;

  /// The row label for the midpoint of the healthy range.
  ///
  /// In en, this message translates to:
  /// **'Ideal weight'**
  String get bmiIdealWeight;

  /// A closed band's boundaries on the scale, both already formatted.
  ///
  /// In en, this message translates to:
  /// **'{low} to {high}'**
  String bmiRange(String low, String high);

  /// An open-ended band's ceiling on the scale (underweight).
  ///
  /// In en, this message translates to:
  /// **'Under {value}'**
  String bmiUnder(String value);

  /// An open-ended band's floor on the scale (obese).
  ///
  /// In en, this message translates to:
  /// **'Over {value}'**
  String bmiOver(String value);

  /// The marker on the scale row matching the reader's own reading.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get bmiCurrent;

  /// Toast when today's check-in changed elsewhere before this write landed.
  ///
  /// In en, this message translates to:
  /// **'This changed somewhere else. Open it again.'**
  String get streakErrConflict;

  /// Toast when a check-in write failed to save.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t save. Try again.'**
  String get streakErrFailed;

  /// Toast after marking today done on the streak.
  ///
  /// In en, this message translates to:
  /// **'Checked in for today'**
  String get streakCheckedInToast;

  /// Toast after clearing today's check-in on the streak.
  ///
  /// In en, this message translates to:
  /// **'Check-in removed'**
  String get streakUncheckedToast;

  /// Streak summary card kicker.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get streakSummaryKicker;

  /// Streak summary caption — the reader's longest streak ever recorded.
  ///
  /// In en, this message translates to:
  /// **'Best: {n} days'**
  String streakBestCaption(int n);

  /// Streak summary stat label — this month's check-ins as a share of days elapsed.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get streakRateLabel;

  /// Streak summary stat label — the next streak-length milestone still ahead.
  ///
  /// In en, this message translates to:
  /// **'Next milestone'**
  String get streakNextLabel;

  /// Checkbox state announced for today's row on the streak toggle.
  ///
  /// In en, this message translates to:
  /// **'Checked in today'**
  String get streakCheckInLabel;

  /// Section title over the streak's 35-day check-in grid.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get streakCalendarTitle;

  /// Section title over the streak's milestone list.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get streakMilestonesTitle;

  /// Label for one streak-length milestone.
  ///
  /// In en, this message translates to:
  /// **'{n}-day streak'**
  String streakMilestoneDays(int n);

  /// Screen-reader summary for the streak's 35-day check-in grid.
  ///
  /// In en, this message translates to:
  /// **'{checked} of the last {total} days checked in'**
  String streakCalendarA11y(int checked, int total);

  /// Label for the cadence field in the habit form.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get habitsFieldFrequency;

  /// Habit cadence: every day.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get habitsFreqDaily;

  /// Habit cadence: Monday to Friday only.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get habitsFreqWeekdays;

  /// Habit cadence: once a week.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get habitsFreqWeekly;

  /// Empty state title for the Habits list.
  ///
  /// In en, this message translates to:
  /// **'No habits yet'**
  String get habitsEmptyTitle;

  /// Empty state text for the Habits list.
  ///
  /// In en, this message translates to:
  /// **'Add a habit to start tracking your streak.'**
  String get habitsEmptyText;

  /// Button that opens the new-habit form.
  ///
  /// In en, this message translates to:
  /// **'Add habit'**
  String get habitsAddHabit;

  /// Form title when adding a habit.
  ///
  /// In en, this message translates to:
  /// **'New habit'**
  String get habitsNewHabit;

  /// Form title when editing a habit.
  ///
  /// In en, this message translates to:
  /// **'Edit habit'**
  String get habitsEditHabit;

  /// Kicker on the Habits summary card.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get habitsSummaryKicker;

  /// Summary stat label: how many habits are tracked.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habitsStatTotal;

  /// Summary stat label: habits with a current streak.
  ///
  /// In en, this message translates to:
  /// **'Active streaks'**
  String get habitsStatActiveStreaks;

  /// What a habit row's checkbox marks, read together with the habit's own name.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get habitsCheckLabel;

  /// A habit's current streak in days, shown on its row.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No streak yet} =1{1 day streak} other{{n} day streak}}'**
  String habitsStreakDays(int n);

  /// A habit's current streak in weeks, shown on its row.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No streak yet} =1{1 week streak} other{{n} week streak}}'**
  String habitsStreakWeeks(int n);

  /// The bare unit word for a daily-cadence streak figure.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{day} other{days}}'**
  String habitsUnitDays(int n);

  /// The bare unit word for a weekly-cadence streak figure.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{week} other{weeks}}'**
  String habitsUnitWeeks(int n);

  /// Caption under the habit detail's headline figure.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get habitsCurrentStreakCaption;

  /// Habit detail stat label: the longest streak on record.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get habitsStatBest;

  /// Habit detail stat label: share of required days/weeks kept.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get habitsStatCompletion;

  /// Detail action that logs today's check-in.
  ///
  /// In en, this message translates to:
  /// **'Mark done today'**
  String get habitsMarkDone;

  /// Detail action that removes today's check-in.
  ///
  /// In en, this message translates to:
  /// **'Undo today\'s check-in'**
  String get habitsUnmarkDone;

  /// Delete-confirmation title for a habit.
  ///
  /// In en, this message translates to:
  /// **'Delete this habit?'**
  String get habitsDeleteAsk;

  /// Delete-confirmation body.
  ///
  /// In en, this message translates to:
  /// **'{name} and its check-in history will be removed. You can undo this straight away.'**
  String habitsDeleteText(String name);

  /// Toast after deleting a habit.
  ///
  /// In en, this message translates to:
  /// **'Habit deleted'**
  String get habitsDeletedToast;

  /// Error toast: conflict/notFound on a write.
  ///
  /// In en, this message translates to:
  /// **'Someone already changed this habit'**
  String get habitsErrConflict;

  /// Error toast: generic write failure.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save this habit'**
  String get habitsErrFailed;

  /// Validation error: empty name.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get habitsErrName;

  /// Validation error: name or notes over the limit.
  ///
  /// In en, this message translates to:
  /// **'That\'s too long'**
  String get habitsErrLong;

  /// Badge on a habit whose check-in records are inconsistent; its figures are hidden.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get habitsDamagedBadge;

  /// Medication schedule option. Reference key rec.sched.daily.
  ///
  /// In en, this message translates to:
  /// **'Once a day'**
  String get medsScheduleDaily;

  /// Medication schedule option. Reference key rec.sched.twice.
  ///
  /// In en, this message translates to:
  /// **'Twice a day'**
  String get medsScheduleTwice;

  /// Medication schedule option. Reference key rec.sched.weekly.
  ///
  /// In en, this message translates to:
  /// **'Once a week'**
  String get medsScheduleWeekly;

  /// Medication schedule option. Reference key rec.sched.needed.
  ///
  /// In en, this message translates to:
  /// **'As needed'**
  String get medsScheduleNeeded;

  /// Form field label for the medication's schedule. Reference key rec.f.schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get medsFieldSchedule;

  /// Form field label for the medicine's name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get medsFieldName;

  /// Placeholder text for the name field. Reference key rec.meds.ph.
  ///
  /// In en, this message translates to:
  /// **'Name of the medicine'**
  String get medsFieldNamePh;

  /// Form field label for the dose. Reference key rec.f.dose.
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get medsFieldDose;

  /// Placeholder text for the dose field. Reference key rec.meds.dosePh.
  ///
  /// In en, this message translates to:
  /// **'500 mg'**
  String get medsFieldDosePh;

  /// Form field label for the optional first-dose time of day; stored as plain data, not a scheduled alert. Reference key rec.f.firstDose.
  ///
  /// In en, this message translates to:
  /// **'First dose'**
  String get medsFieldFirstDose;

  /// Form field label for the optional count of doses remaining. Reference key rec.f.dosesLeft.
  ///
  /// In en, this message translates to:
  /// **'Doses left'**
  String get medsFieldDosesLeft;

  /// Form field label for the optional free-text note. Reference key rec.f.notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get medsFieldNotes;

  /// Title shown when the reader has not added any medication yet. Reference key rec.meds.emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No medication tracked'**
  String get medsEmptyTitle;

  /// Supporting text under the empty-state title; adapted from the reference to drop the "next dose" claim this build cannot compute.
  ///
  /// In en, this message translates to:
  /// **'Add one to keep track of the dose, the schedule, and how much is left.'**
  String get medsEmptyText;

  /// Label on the button that opens the add-medication form.
  ///
  /// In en, this message translates to:
  /// **'Add medication'**
  String get medsAddMedication;

  /// Screen title while adding a new medication.
  ///
  /// In en, this message translates to:
  /// **'New medication'**
  String get medsNewMedication;

  /// Screen title while editing an existing medication.
  ///
  /// In en, this message translates to:
  /// **'Edit medication'**
  String get medsEditMedication;

  /// Small label above the medication count on the list's summary card.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get medsSummaryKicker;

  /// Summary-card caption, shown only when at least one medication is running low; ICU plural on the count.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{} =1{1 running low} other{{n} running low}}'**
  String medsSummaryCaption(int n);

  /// Badge shown on a medication whose doses-left count is at or below 3. Reference key rec.meds.low.
  ///
  /// In en, this message translates to:
  /// **'Running low'**
  String get medsLowBadge;

  /// Small unit word shown beside the doses-left count on the medication's detail summary.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get medsDosesLeftUnit;

  /// Detail-screen caption stating the stored first-dose time of day (not an alert).
  ///
  /// In en, this message translates to:
  /// **'First dose at {time}'**
  String medsFirstDoseAt(String time);

  /// Title of the safety notice on a medication's detail screen; replaces the reference's "Kept on this device" title, which would misstate this build's session-only storage.
  ///
  /// In en, this message translates to:
  /// **'Not medical advice'**
  String get medsSafetyTitle;

  /// Body of the safety notice. Reference key rec.meds.safety.
  ///
  /// In en, this message translates to:
  /// **'Lume reminds you; it does not advise. Follow what your doctor or pharmacist told you.'**
  String get medsSafetyText;

  /// Validation message when the name field is left empty.
  ///
  /// In en, this message translates to:
  /// **'Name this medication'**
  String get medsErrName;

  /// Validation message when the dose field is left empty.
  ///
  /// In en, this message translates to:
  /// **'Enter the dose'**
  String get medsErrDose;

  /// Validation message when a text field exceeds its length limit.
  ///
  /// In en, this message translates to:
  /// **'That is too long'**
  String get medsErrLong;

  /// Validation message when the doses-left field isn't a valid non-negative integer.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number, 0 or more'**
  String get medsErrDosesLeft;

  /// Toast shown when a write is refused because the record changed since it was read.
  ///
  /// In en, this message translates to:
  /// **'This medication changed elsewhere'**
  String get medsErrConflict;

  /// Toast shown when a record fails its strict codec.
  ///
  /// In en, this message translates to:
  /// **'This medication\'s record doesn\'t add up and can\'t be shown safely'**
  String get medsErrDamaged;

  /// Generic toast for an unspecified write failure.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t save. Try again.'**
  String get medsErrFailed;

  /// Title of the delete-confirmation sheet.
  ///
  /// In en, this message translates to:
  /// **'Delete this medication?'**
  String get medsDeleteAsk;

  /// Body of the delete-confirmation sheet; names the medication and states Undo is available.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed. You can undo this straight away.'**
  String medsDeleteText(String name);

  /// Toast shown after a successful delete (paired with Undo).
  ///
  /// In en, this message translates to:
  /// **'Medication deleted'**
  String get medsDeletedToast;

  /// The noun used inside the generic recDelete/recDeleteAsk/recDeletedFinal sentence templates for this family's irreversible delete
  ///
  /// In en, this message translates to:
  /// **'vaccination record'**
  String get vaccinesNoun;

  /// Empty-state title on the Vaccinations list
  ///
  /// In en, this message translates to:
  /// **'No vaccinations yet'**
  String get vaccinesEmptyTitle;

  /// Empty-state supporting text
  ///
  /// In en, this message translates to:
  /// **'Keep a record of vaccinations for yourself or your family.'**
  String get vaccinesEmptyText;

  /// Button label, empty state and list
  ///
  /// In en, this message translates to:
  /// **'Add vaccination'**
  String get vaccinesAddVaccination;

  /// Form screen title when adding
  ///
  /// In en, this message translates to:
  /// **'New vaccination'**
  String get vaccinesNewVaccination;

  /// Form screen title when editing
  ///
  /// In en, this message translates to:
  /// **'Edit vaccination'**
  String get vaccinesEditVaccination;

  /// Summary card caption; n is the real due count, never a fixture literal
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{All up to date} =1{1 still due} other{{n} still due}}'**
  String vaccinesDueCaption(int n);

  /// Form field label for the vaccine's name
  ///
  /// In en, this message translates to:
  /// **'Vaccine'**
  String get vaccinesFieldName;

  /// Form field / detail label for who received it (free text, never a picker)
  ///
  /// In en, this message translates to:
  /// **'For'**
  String get vaccinesFieldFor;

  /// Form field label, e.g. "2nd dose"
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get vaccinesFieldDose;

  /// Form field / detail label for the clinic, doctor or pharmacy
  ///
  /// In en, this message translates to:
  /// **'Given by'**
  String get vaccinesFieldGivenBy;

  /// Validation message when an optional text field exceeds its length limit
  ///
  /// In en, this message translates to:
  /// **'That is too long'**
  String get vaccinesErrLong;

  /// Toast when a write hits a version conflict or the record is gone
  ///
  /// In en, this message translates to:
  /// **'This record changed elsewhere'**
  String get vaccinesErrConflict;

  /// Generic write-failure toast
  ///
  /// In en, this message translates to:
  /// **'That didn\'t save. Try again.'**
  String get vaccinesErrFailed;

  /// Title shown when the reader has not added any health record
  ///
  /// In en, this message translates to:
  /// **'No health records yet'**
  String get healthEmptyTitle;

  /// Supporting text under the empty-state title
  ///
  /// In en, this message translates to:
  /// **'Add a visit, a result or anything else worth keeping track of.'**
  String get healthEmptyText;

  /// Button label to add a new health record
  ///
  /// In en, this message translates to:
  /// **'Add a record'**
  String get healthAddRecord;

  /// Header title while adding a record
  ///
  /// In en, this message translates to:
  /// **'New record'**
  String get healthNewRecord;

  /// Header title while editing a record
  ///
  /// In en, this message translates to:
  /// **'Edit record'**
  String get healthEditRecord;

  /// Placeholder text in the records search field
  ///
  /// In en, this message translates to:
  /// **'Search records'**
  String get healthSearch;

  /// Section title above the full record list
  ///
  /// In en, this message translates to:
  /// **'All records'**
  String get healthAll;

  /// Small label above the summary card's total count
  ///
  /// In en, this message translates to:
  /// **'Health records'**
  String get healthSummaryKicker;

  /// Summary card caption naming how many records are dated today or later
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 upcoming} other{{n} upcoming}}'**
  String healthSummaryUpcoming(int n);

  /// Summary card caption when no record is dated today or later
  ///
  /// In en, this message translates to:
  /// **'Nothing upcoming'**
  String get healthSummaryNoneUpcoming;

  /// Summary card stat label: total record count
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get healthStatTotal;

  /// Summary card stat label: count of upcoming records
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get healthStatUpcoming;

  /// Summary card stat label: number of distinct record kinds used
  ///
  /// In en, this message translates to:
  /// **'Types'**
  String get healthStatTypes;

  /// Form field / fact label for the record's kind (appointment, report, etc.)
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get healthFieldType;

  /// Form field / fact label for who the record is from (doctor, clinic, lab)
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get healthFieldSource;

  /// Placeholder text in the record title field
  ///
  /// In en, this message translates to:
  /// **'Annual check-up, blood test…'**
  String get healthTitlePlaceholder;

  /// Placeholder text in the source field
  ///
  /// In en, this message translates to:
  /// **'Doctor, clinic or lab'**
  String get healthSourcePlaceholder;

  /// Record kind option/label
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get healthKindAppointment;

  /// Record kind option/label
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get healthKindReport;

  /// Record kind option/label
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get healthKindPrescription;

  /// Record kind option/label
  ///
  /// In en, this message translates to:
  /// **'Vaccination'**
  String get healthKindVaccination;

  /// Record kind option/label
  ///
  /// In en, this message translates to:
  /// **'Measurement'**
  String get healthKindMeasurement;

  /// Validation message when a field exceeds its length limit
  ///
  /// In en, this message translates to:
  /// **'That is too long'**
  String get healthErrTooLong;

  /// Error toast when a stored record fails strict decoding
  ///
  /// In en, this message translates to:
  /// **'This record\'s details don\'t add up and can\'t be shown safely'**
  String get healthErrDamaged;

  /// Delete confirmation sheet title
  ///
  /// In en, this message translates to:
  /// **'Delete this record?'**
  String get healthDeleteAsk;

  /// Delete confirmation sheet body — states plainly it's irreversible
  ///
  /// In en, this message translates to:
  /// **'This removes the record permanently. It cannot be undone.'**
  String get healthDeleteText;

  /// Toast shown after a successful, final delete
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get healthDeletedToast;

  /// Cycle Tracker summary card kicker: the reader's current day within their logged cycle
  ///
  /// In en, this message translates to:
  /// **'Cycle day'**
  String get cycleDayKicker;

  /// Cycle phase name, from the reader's own logged average length
  ///
  /// In en, this message translates to:
  /// **'Menstrual'**
  String get cyclePhaseMenstrual;

  /// Cycle phase name
  ///
  /// In en, this message translates to:
  /// **'Follicular'**
  String get cyclePhaseFollicular;

  /// Cycle phase name
  ///
  /// In en, this message translates to:
  /// **'Ovulation'**
  String get cyclePhaseOvulation;

  /// Cycle phase name
  ///
  /// In en, this message translates to:
  /// **'Luteal'**
  String get cyclePhaseLuteal;

  /// Summary card caption shown before there is enough history for an average
  ///
  /// In en, this message translates to:
  /// **'Log a couple more periods to see predictions'**
  String get cycleTrackingCaption;

  /// Empty state title: nothing logged at all
  ///
  /// In en, this message translates to:
  /// **'No periods logged yet'**
  String get cycleEmptyTitle;

  /// Empty state body: what logging unlocks, honestly framed as an estimate from the reader's own data
  ///
  /// In en, this message translates to:
  /// **'Log when your period starts and Lume will work out your average cycle length and estimate your next one from your own history.'**
  String get cycleEmptyText;

  /// Empty state's primary call to action
  ///
  /// In en, this message translates to:
  /// **'Log your first period'**
  String get cycleLogFirst;

  /// Sheet title / primary button for logging a new period
  ///
  /// In en, this message translates to:
  /// **'Log period'**
  String get cycleLogPeriod;

  /// Sheet title when correcting an already-logged period
  ///
  /// In en, this message translates to:
  /// **'Edit period'**
  String get cycleEditPeriod;

  /// Field label: when the period started
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get cycleStartDateLabel;

  /// Field label: when the period ended
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get cycleEndDateLabel;

  /// Checkbox: the period is still ongoing, so there's no end date
  ///
  /// In en, this message translates to:
  /// **'Hasn\'t ended yet'**
  String get cycleStillOngoing;

  /// Shown as the current period's value when it has no end date logged
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get cycleOngoingBadge;

  /// Label for the current/most recent logged period's row
  ///
  /// In en, this message translates to:
  /// **'Started {date}'**
  String cycleStartedOn(String date);

  /// A past period's start and end date, formatted, for its history row
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String cycleDateRange(String start, String end);

  /// Section title for the predicted next start date
  ///
  /// In en, this message translates to:
  /// **'Estimated next period'**
  String get cycleNextEstimateKicker;

  /// Caption under the estimate, keeping it honest about certainty
  ///
  /// In en, this message translates to:
  /// **'An estimate from your own average — not a diagnosis or a guarantee'**
  String get cycleNextEstimateCaption;

  /// Section title for past completed cycles
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get cycleHistoryTitle;

  /// Summary card stat label for the average logged cycle length
  ///
  /// In en, this message translates to:
  /// **'Average cycle'**
  String get cycleAverageLabel;

  /// Summary card stat label for how many periods the reader has logged
  ///
  /// In en, this message translates to:
  /// **'Periods logged'**
  String get cycleLoggedCountLabel;

  /// Verb label for removing a logged period (button and delete-confirmation action)
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get cycleDeleteEntry;

  /// Delete confirmation title
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get cycleDeleteTitle;

  /// Delete confirmation consequence — recoverable, matching the Undo that follows
  ///
  /// In en, this message translates to:
  /// **'This removes this logged period from your history. This can be undone right after.'**
  String get cycleDeleteText;

  /// Toast after a successful delete, paired with Undo
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get cycleDeletedToast;

  /// Toast after logging or correcting a period
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get cycleSavedToast;

  /// Generic write-failure toast
  ///
  /// In en, this message translates to:
  /// **'That didn\'t save. Try again.'**
  String get cycleErrFailed;

  /// Toast for a conflicting/missing record on write
  ///
  /// In en, this message translates to:
  /// **'This entry changed elsewhere'**
  String get cycleErrConflict;

  /// Pregnancy: the one field label, for the date picker
  ///
  /// In en, this message translates to:
  /// **'First day of your last period'**
  String get pregnancyLmpLabel;

  /// Pregnancy: hint under the date field, keeping the estimate honest
  ///
  /// In en, this message translates to:
  /// **'Used to estimate your due date. Not medical advice.'**
  String get pregnancyLmpHint;

  /// Pregnancy: the date field's value before anything is entered
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get pregnancyNotSet;

  /// Pregnancy: empty-state title, before a date is entered
  ///
  /// In en, this message translates to:
  /// **'See your estimated due date'**
  String get pregnancyEmptyTitle;

  /// Pregnancy: empty-state body text
  ///
  /// In en, this message translates to:
  /// **'Add the first day of your last period and Lume will estimate your week, trimester and due date.'**
  String get pregnancyEmptyText;

  /// Pregnancy: the unit beside the week number ("/ 40"); weeks is pre-formatted
  ///
  /// In en, this message translates to:
  /// **'/ {weeks}'**
  String pregnancyOfWeeks(String weeks);

  /// Pregnancy: the trimester label in the summary caption; n is pre-formatted
  ///
  /// In en, this message translates to:
  /// **'Trimester {n}'**
  String pregnancyTrimester(String n);

  /// Pregnancy: summary stat label
  ///
  /// In en, this message translates to:
  /// **'Days pregnant'**
  String get pregnancyDaysPregnant;

  /// Pregnancy: summary stat label, before the due date
  ///
  /// In en, this message translates to:
  /// **'Days to go'**
  String get pregnancyDaysToGo;

  /// Pregnancy: summary stat label, once the due date has passed
  ///
  /// In en, this message translates to:
  /// **'Days overdue'**
  String get pregnancyDaysOverdue;

  /// Pregnancy: summary stat label for the calendar date itself
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get pregnancyDueDateLabel;

  /// Pregnancy: accessible label on the summary card's progress ring
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get pregnancyProgressLabel;

  /// Pregnancy: section title over the four gestational-age markers
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get pregnancyMilestonesTitle;

  /// Pregnancy: milestone label, week 12
  ///
  /// In en, this message translates to:
  /// **'First trimester complete'**
  String get pregnancyMilestone12;

  /// Pregnancy: milestone label, week 20 (usual timing, not a booked appointment)
  ///
  /// In en, this message translates to:
  /// **'Anatomy scan window'**
  String get pregnancyMilestone20;

  /// Pregnancy: milestone label, week 28
  ///
  /// In en, this message translates to:
  /// **'Third trimester begins'**
  String get pregnancyMilestone28;

  /// Pregnancy: milestone label, week 37
  ///
  /// In en, this message translates to:
  /// **'Full term'**
  String get pregnancyMilestone37;

  /// Pregnancy: toast after clearing the stored date
  ///
  /// In en, this message translates to:
  /// **'Date cleared'**
  String get pregnancyClearedToast;

  /// Pregnancy: generic save-failure toast
  ///
  /// In en, this message translates to:
  /// **'That didn\'t save. Try again.'**
  String get pregnancyErrFailed;

  /// Pregnancy: conflict/not-found save-failure toast
  ///
  /// In en, this message translates to:
  /// **'This changed elsewhere. Try again.'**
  String get pregnancyErrConflict;

  /// Reference key qibla.direction — the qibla metric's own label, over the bearing figure
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get qiblaDirection;

  /// Reference key qibla.distance — the label over the great-circle distance to the Kaaba
  ///
  /// In en, this message translates to:
  /// **'To the Kaaba'**
  String get qiblaToKaaba;

  /// Reference key qibla.reference — the section title over the Kaaba's and the reader's own coordinates
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get qiblaReference;

  /// Reference key qibla.kaaba — the row naming the Kaaba's own coordinates
  ///
  /// In en, this message translates to:
  /// **'Kaaba'**
  String get qiblaKaaba;

  /// Reference key qibla.yourpos — the row naming the reader's own coordinates, worked out from their city
  ///
  /// In en, this message translates to:
  /// **'Your position'**
  String get qiblaYourPosition;

  /// Reference key qibla.magnetic — the row naming what the bearing is measured against
  ///
  /// In en, this message translates to:
  /// **'Bearing basis'**
  String get qiblaBasis;

  /// Reference key qibla.trueNorth — this build has no device compass to correct for magnetic declination, so the bearing is given against true north
  ///
  /// In en, this message translates to:
  /// **'True north'**
  String get qiblaTrueNorth;

  /// The note under the qibla dial, explaining the needle is worked out from coordinates rather than read from the phone's own sensor
  ///
  /// In en, this message translates to:
  /// **'A calculated direction, not a live compass'**
  String get qiblaNoteTitle;

  /// The note's explanatory text
  ///
  /// In en, this message translates to:
  /// **'This shows the great-circle direction to the Kaaba, worked out from your city\'s coordinates. It doesn\'t read your phone\'s sensors, so hold a compass or a map beside it to line yourself up.'**
  String get qiblaNoteText;

  /// Shown when Lume has no coordinates for the reader's chosen city, mirroring sun.noCity's own pattern
  ///
  /// In en, this message translates to:
  /// **'No position for {city}'**
  String qiblaNoCityTitle(String city);

  /// The explanatory text under qiblaNoCityTitle
  ///
  /// In en, this message translates to:
  /// **'The qibla direction is worked out from a city\'s coordinates, and Lume has none for this one. Choose another city in Profile to see it.'**
  String get qiblaNoCityText;

  /// Reference key zakat.assets — the asset-entry section's title
  ///
  /// In en, this message translates to:
  /// **'Your assets'**
  String get zakatAssets;

  /// Reference key zakat.cash — one of the six asset fields
  ///
  /// In en, this message translates to:
  /// **'Cash & bank'**
  String get zakatCash;

  /// Reference key zakat.gold — gold held, entered in grams
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get zakatGold;

  /// Reference key zakat.silver — silver held, entered in grams
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get zakatSilver;

  /// Reference key zakat.investments
  ///
  /// In en, this message translates to:
  /// **'Investments'**
  String get zakatInvestments;

  /// Reference key zakat.business
  ///
  /// In en, this message translates to:
  /// **'Business assets'**
  String get zakatBusiness;

  /// Reference key zakat.liabilities — subtracted from assets before the nisab test
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get zakatLiabilities;

  /// Reference key zakat.payable — the headline figure (2.5% of net assets, once above nisab)
  ///
  /// In en, this message translates to:
  /// **'Zakat payable'**
  String get zakatPayable;

  /// Reference key zakat.aboveNisab — the summary caption when eligible
  ///
  /// In en, this message translates to:
  /// **'Your net assets are above nisab'**
  String get zakatAboveNisab;

  /// Reference key zakat.belowNisab — the summary caption when not eligible
  ///
  /// In en, this message translates to:
  /// **'Below nisab — no zakat is due'**
  String get zakatBelowNisab;

  /// Reference key zakat.netAssets — assets less liabilities, may be negative
  ///
  /// In en, this message translates to:
  /// **'Net assets'**
  String get zakatNetAssets;

  /// Reference key zakat.nisab — the lower of the gold/silver thresholds actually applied
  ///
  /// In en, this message translates to:
  /// **'Nisab'**
  String get zakatNisab;

  /// Reference key zakat.rate — the fixed 2.5% zakat rate
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get zakatRateLabel;

  /// Reference key zakat.breakdown — the eight-row detail table's title
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get zakatBreakdown;

  /// Reference key zakat.item — the breakdown table's first column header
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get zakatItem;

  /// Search field placeholder, Al-Qur’an browse (quran_tool.dart)
  ///
  /// In en, this message translates to:
  /// **'Search surahs'**
  String get quranSearchPlaceholder;

  /// Section title, surah list
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get quranSurahsTitle;

  /// Empty-state title
  ///
  /// In en, this message translates to:
  /// **'No surahs found'**
  String get quranNoMatch;

  /// Empty-state body
  ///
  /// In en, this message translates to:
  /// **'Try a different search.'**
  String get quranNoMatchText;

  /// n: int — a surah's ayah count, shown in the surah list's meta line
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 ayah} other{{n} ayahs}}'**
  String quranAyahCount(int n);

  /// Where a surah was revealed
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get quranMeccan;

  /// Where a surah was revealed
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get quranMedinan;

  /// surah: String, s: int, a: int — an ayah reference line (surah name, surah number, ayah number)
  ///
  /// In en, this message translates to:
  /// **'{surah} · {s}:{a}'**
  String quranVerseReference(String surah, int s, int a);

  /// number: int
  ///
  /// In en, this message translates to:
  /// **'Ayah {number}'**
  String quranAyahNumber(int number);

  /// Search field placeholder, Search the Qur’an
  ///
  /// In en, this message translates to:
  /// **'Search the Qur’an'**
  String get quransearchPlaceholder;

  /// n: int — number of ayah hits
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 result} other{{n} results}}'**
  String quransearchResultsTitle(int n);

  /// Empty-state title
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get quransearchEmptyTitle;

  /// Empty-state body
  ///
  /// In en, this message translates to:
  /// **'Try a different word or a shorter search.'**
  String get quransearchEmptyText;

  /// Honesty disclosure under the search field, stating the pool's real size
  ///
  /// In en, this message translates to:
  /// **'Searching 3 ayahs and 12 surahs — a starting set, not the full Qur’an.'**
  String get quransearchScopeNote;

  /// Suggested-search chips title
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get quransearchSuggestedTitle;

  /// Section title, other ayat in the pool
  ///
  /// In en, this message translates to:
  /// **'More verses'**
  String get ayahMoreVerses;

  /// Toast shown after Save
  ///
  /// In en, this message translates to:
  /// **'Saved to your reading'**
  String get ayahSaved;

  /// Toast shown after Save is toggled off
  ///
  /// In en, this message translates to:
  /// **'Removed from your reading'**
  String get ayahUnsaved;

  /// Currency name
  ///
  /// In en, this message translates to:
  /// **'Pakistani Rupee'**
  String get ccyPkr;

  /// Currency name
  ///
  /// In en, this message translates to:
  /// **'Indian Rupee'**
  String get ccyInr;

  /// Currency name
  ///
  /// In en, this message translates to:
  /// **'Turkish Lira'**
  String get ccyTry;

  /// Currency picker sheet title
  ///
  /// In en, this message translates to:
  /// **'Choose a currency'**
  String get currencyChooseCurrency;

  /// from: String, value: String, to: String — the headline conversion line
  ///
  /// In en, this message translates to:
  /// **'1 {from} = {value} {to}'**
  String currencyRateLine(String from, String value, String to);

  /// pair: String — the rate chart's caption, matching ratesHistory's own '{name}, 30 days' pattern
  ///
  /// In en, this message translates to:
  /// **'{pair}, 30 days'**
  String currencyChart(String pair);

  /// Fuel grade name
  ///
  /// In en, this message translates to:
  /// **'Hi-Octane'**
  String get fuelHiOctane;

  /// Fuel grade name
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get fuelDiesel;

  /// Fuel grade name
  ///
  /// In en, this message translates to:
  /// **'Light Diesel'**
  String get fuelLightDiesel;

  /// Fuel grade name
  ///
  /// In en, this message translates to:
  /// **'Unleaded'**
  String get fuelUnleaded;

  /// Fuel grade name
  ///
  /// In en, this message translates to:
  /// **'Super Unleaded'**
  String get fuelSuperUnleaded;

  /// Fuel grade name
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get fuelRegular;

  /// Fuel grade name
  ///
  /// In en, this message translates to:
  /// **'Midgrade'**
  String get fuelMidgrade;

  /// Fuel grade name
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get fuelPremium;

  /// Fuel grade name
  ///
  /// In en, this message translates to:
  /// **'Special 95'**
  String get fuelSpecial95;

  /// Fuel grade name
  ///
  /// In en, this message translates to:
  /// **'Super 98'**
  String get fuelSuper98;

  /// Fuel grade name
  ///
  /// In en, this message translates to:
  /// **'E-Plus 91'**
  String get fuelEPlus91;

  /// Fuel grade name
  ///
  /// In en, this message translates to:
  /// **'Petrol 91'**
  String get fuelPetrol91;

  /// Fuel grade name
  ///
  /// In en, this message translates to:
  /// **'Petrol 95'**
  String get fuelPetrol95;

  /// Fuel grade name
  ///
  /// In en, this message translates to:
  /// **'CNG'**
  String get fuelCng;

  /// date: String — the price list's effective date
  ///
  /// In en, this message translates to:
  /// **'Effective {date}'**
  String fuelEffective(String date);

  /// Trailing caption on the delta since the previous revision
  ///
  /// In en, this message translates to:
  /// **'since last update'**
  String get fuelSinceLast;

  /// Filter chip — every fuel grade
  ///
  /// In en, this message translates to:
  /// **'All Grades'**
  String get fuelAllGrades;

  /// Column/field label — the fuel grade
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get fuelGrade;

  /// Column label, the prior price
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get fuelPrevious;

  /// Column label, the current price
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get fuelCurrent;

  /// Chart section title
  ///
  /// In en, this message translates to:
  /// **'Price trend'**
  String get fuelTrend;

  /// Chart caption
  ///
  /// In en, this message translates to:
  /// **'Fuel price, last 24 months'**
  String get fuelTrendCap;

  /// Data-source label
  ///
  /// In en, this message translates to:
  /// **'Retail price'**
  String get fuelSourceRetail;

  /// Data-source label
  ///
  /// In en, this message translates to:
  /// **'State average'**
  String get fuelSourceState;

  /// Data-source label
  ///
  /// In en, this message translates to:
  /// **'Oil marketing companies'**
  String get fuelSourceOmc;

  /// Data-source label
  ///
  /// In en, this message translates to:
  /// **'Regional average'**
  String get fuelSourceRegional;

  /// Unit name
  ///
  /// In en, this message translates to:
  /// **'litre'**
  String get unitLitre;

  /// Unit name
  ///
  /// In en, this message translates to:
  /// **'gallon'**
  String get unitGallon;

  /// Generic label used by Fuel Prices' effective-date chip (fuel_text.dart); no shared commonThisWeek-equivalent existed — several tools duplicate their own 'This week' string under feature-specific keys instead
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get commonThisWeek;

  /// Unit abbreviation, miles per gallon
  ///
  /// In en, this message translates to:
  /// **'mpg'**
  String get unitMpg;

  /// Unit abbreviation, kilometres per litre
  ///
  /// In en, this message translates to:
  /// **'km/L'**
  String get unitKmpl;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get fuelcostDistance;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Fuel economy'**
  String get fuelcostEconomy;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Fuel price'**
  String get fuelcostPrice;

  /// Hint under the fuel-price field
  ///
  /// In en, this message translates to:
  /// **'From today’s fuel price — edit to use your own'**
  String get fuelcostPriceHint;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get fuelcostPeople;

  /// Result label
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get fuelcostTotal;

  /// d: String — the trip's distance, formatted
  ///
  /// In en, this message translates to:
  /// **'For a {d} trip'**
  String fuelcostForTrip(String d);

  /// Result label
  ///
  /// In en, this message translates to:
  /// **'Fuel used'**
  String get fuelcostUsed;

  /// Result label
  ///
  /// In en, this message translates to:
  /// **'Per person'**
  String get fuelcostPerPerson;

  /// unit: String — the distance unit in use
  ///
  /// In en, this message translates to:
  /// **'Per {unit}'**
  String fuelcostPerUnit(String unit);

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get fuelcostCompare;

  /// Table column header
  ///
  /// In en, this message translates to:
  /// **'Scenario'**
  String get fuelcostScenario;

  /// Table column header
  ///
  /// In en, this message translates to:
  /// **'Consumption'**
  String get fuelcostConsumption;

  /// Table column header
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get fuelcostCost;

  /// Comparison scenario name
  ///
  /// In en, this message translates to:
  /// **'Solo trip'**
  String get fuelcostScSolo;

  /// n: String — the number of people sharing the trip
  ///
  /// In en, this message translates to:
  /// **'Shared with {n}'**
  String fuelcostScShared(String n);

  /// Comparison scenario name
  ///
  /// In en, this message translates to:
  /// **'Round trip'**
  String get fuelcostScReturn;

  /// Scheme name
  ///
  /// In en, this message translates to:
  /// **'National Savings'**
  String get savingsScheme;

  /// Summary label
  ///
  /// In en, this message translates to:
  /// **'Best rate'**
  String get savingsBestRate;

  /// Field/column label
  ///
  /// In en, this message translates to:
  /// **'Term'**
  String get savingsTerm;

  /// Field/column label
  ///
  /// In en, this message translates to:
  /// **'Payout'**
  String get savingsPayout;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get savingsMinimum;

  /// Compact form of Minimum, tight spaces
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get savingsMin;

  /// Field/column label
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get savingsRate;

  /// Search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get savingsSearch;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get savingsProducts;

  /// Trailing unit on a rate
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get savingsPerYear;

  /// Section title, the return calculator
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get savingsEstimate;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get savingsAmount;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get savingsProduct;

  /// Result label
  ///
  /// In en, this message translates to:
  /// **'Monthly profit'**
  String get savingsMonthlyProfit;

  /// Result label
  ///
  /// In en, this message translates to:
  /// **'Yearly profit'**
  String get savingsYearlyProfit;

  /// Empty state, non-Pakistan reader
  ///
  /// In en, this message translates to:
  /// **'Not available in your country'**
  String get savingsUnavailableTitle;

  /// Empty state body, non-Pakistan reader
  ///
  /// In en, this message translates to:
  /// **'National Savings certificates are specific to Pakistan.'**
  String get savingsUnavailableText;

  /// Empty state, country without operator tariffs
  ///
  /// In en, this message translates to:
  /// **'Mobile packages are not in your setup'**
  String get packagesUnavailableTitle;

  /// Search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search packages'**
  String get packagesSearch;

  /// Field/column label
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get packagesPrice;

  /// Field/column label
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get packagesData;

  /// Field/column label
  ///
  /// In en, this message translates to:
  /// **'Validity'**
  String get packagesValidity;

  /// Empty-state title
  ///
  /// In en, this message translates to:
  /// **'No packages match'**
  String get packagesNoMatch;

  /// Empty-state body
  ///
  /// In en, this message translates to:
  /// **'Try a different search or filter.'**
  String get packagesNoMatchText;

  /// Action label
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get packagesCompare;

  /// Field/column label
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get packagesPackage;

  /// Field/column label
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get packagesMins;

  /// Field/column label
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get packagesSms;

  /// Detail sheet title
  ///
  /// In en, this message translates to:
  /// **'Package details'**
  String get packagesDetail;

  /// Summary kicker
  ///
  /// In en, this message translates to:
  /// **'Next holiday'**
  String get holidaysNext;

  /// Small status label
  ///
  /// In en, this message translates to:
  /// **'Listed here'**
  String get holidaysListed;

  /// Search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search holidays'**
  String get holidaysSearch;

  /// Filter label
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get holidaysKind;

  /// Empty-state title
  ///
  /// In en, this message translates to:
  /// **'No holidays found'**
  String get holidaysNoMatch;

  /// Empty-state body
  ///
  /// In en, this message translates to:
  /// **'Try a different search or type'**
  String get holidaysNoMatchText;

  /// Section title, the full list
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get holidaysListTitle;

  /// Honesty note title — curly apostrophe, asserted literally by holidays_tool_test.dart
  ///
  /// In en, this message translates to:
  /// **'Reference dates, not this year’s calendar'**
  String get holidaysNoteTitle;

  /// Honesty note body — curly apostrophe
  ///
  /// In en, this message translates to:
  /// **'These are illustrative dates, not drawn from a live calendar, and movable dates like Eid shift every year. Check an official source for this year’s actual holidays.'**
  String get holidaysNoteText;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Tracking number'**
  String get parcelTrackingLabel;

  /// Field placeholder, an example tracking number
  ///
  /// In en, this message translates to:
  /// **'e.g. TCS-8842910'**
  String get parcelPlaceholder;

  /// Action button
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get parcelTrack;

  /// Fixed toast, never varies
  ///
  /// In en, this message translates to:
  /// **'Looking up the shipment'**
  String get parcelLookingUp;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get parcelActive;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Carrier'**
  String get parcelCarrier;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get parcelLastSeen;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get parcelExpected;

  /// Section title, the tracking timeline
  ///
  /// In en, this message translates to:
  /// **'Journey'**
  String get parcelJourney;

  /// Row label
  ///
  /// In en, this message translates to:
  /// **'Notify on updates'**
  String get parcelNotify;

  /// Confirmation toast
  ///
  /// In en, this message translates to:
  /// **'You’ll be notified on every update'**
  String get parcelNotifying;

  /// Timeline status
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get parcelStBooked;

  /// Timeline status — distinct key from parcelActive despite the same English
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get parcelStInTransit;

  /// Timeline status
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get parcelStArrived;

  /// Timeline status
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get parcelStDelivered;

  /// Timeline status
  ///
  /// In en, this message translates to:
  /// **'Arriving'**
  String get parcelStArriving;

  /// item: String, status: String — the shared summary line
  ///
  /// In en, this message translates to:
  /// **'{item} · {status}'**
  String parcelShareText(String item, String status);

  /// Search action/title
  ///
  /// In en, this message translates to:
  /// **'Find trains'**
  String get trainsFind;

  /// Loading state
  ///
  /// In en, this message translates to:
  /// **'Searching services'**
  String get trainsSearching;

  /// Status filter chip
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get trainsRunning;

  /// Status filter chip
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get trainsDelayed;

  /// Empty-state title
  ///
  /// In en, this message translates to:
  /// **'No services match'**
  String get trainsNoMatch;

  /// Empty-state body
  ///
  /// In en, this message translates to:
  /// **'Clear the status filter to see every departure.'**
  String get trainsNoMatchText;

  /// Compact column header, platform number
  ///
  /// In en, this message translates to:
  /// **'Plat.'**
  String get trainsPlatform;

  /// Small caption before a starting fare
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get trainsFareCaption;

  /// name: String — the chosen train's name
  ///
  /// In en, this message translates to:
  /// **'{name}'**
  String trainsSelected(String name);

  /// Metric label
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get trainsSpeed;

  /// Metric label
  ///
  /// In en, this message translates to:
  /// **'Next stop'**
  String get trainsNextStop;

  /// Metric label
  ///
  /// In en, this message translates to:
  /// **'Delay'**
  String get trainsDelay;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get trainsMap;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Station timeline'**
  String get trainsStops;

  /// time: String — the real, as-run time beside a scheduled one
  ///
  /// In en, this message translates to:
  /// **'actual {time}'**
  String trainsActual(String time);

  /// Label, the timetabled time
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get trainsScheduled;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Fares & availability'**
  String get trainsFares;

  /// Column header
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get trainsClass;

  /// Column header
  ///
  /// In en, this message translates to:
  /// **'Fare'**
  String get trainsFare;

  /// Column header
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get trainsSeats;

  /// Action button
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get trainsRemind;

  /// name: String — confirmation toast after Remind me
  ///
  /// In en, this message translates to:
  /// **'Tracking {name}'**
  String trainsReminded(String name);

  /// name: String, from: String, to: String, arrival: String — the shared summary line
  ///
  /// In en, this message translates to:
  /// **'{name} · {from} → {to} · {arrival}'**
  String trainsShareText(String name, String from, String to, String arrival);

  /// Progress ring's accessible label
  ///
  /// In en, this message translates to:
  /// **'Air quality index'**
  String get aqiIndex;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'What this means'**
  String get aqiAdvice;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Pollutants'**
  String get aqiPollutants;

  /// Chart label
  ///
  /// In en, this message translates to:
  /// **'Last 24 hours'**
  String get aqiTrend;

  /// Badge on an estimated (not measured) reading
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get aqiEstimated;

  /// n: int — a trend chart's axis label
  ///
  /// In en, this message translates to:
  /// **'{n}h'**
  String aqiHoursAgo(int n);

  /// city: String — honesty note under an estimated reading
  ///
  /// In en, this message translates to:
  /// **'Estimated for {city} — not measured by a monitoring station.'**
  String aqiEstimatedNote(String city);

  /// Source-bar caption
  ///
  /// In en, this message translates to:
  /// **'Estimated, not measured'**
  String get aqiEstimatedSource;

  /// city: String, value: String, band: String — the shared summary line
  ///
  /// In en, this message translates to:
  /// **'Air quality in {city}: {value} AQI · {band}'**
  String aqiShareText(String city, String value, String band);

  /// Reference key DUA_CATEGORIES[].label ('morning') — exact text asserted by duas_tool_test.dart's category-count assertions
  ///
  /// In en, this message translates to:
  /// **'Morning & evening'**
  String get duaCategoryMorning;

  /// Reference key DUA_CATEGORIES[].label ('daily') — exact text asserted literally by duas_tool_test.dart (tap target and count-map key)
  ///
  /// In en, this message translates to:
  /// **'Daily life'**
  String get duaCategoryDaily;

  /// Reference key DUA_CATEGORIES[].label ('travel') — exact text asserted literally by duas_tool_test.dart (tap target)
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get duaCategoryTravel;

  /// Reference key DUA_CATEGORIES[].label ('distress') — exact text asserted by duas_tool_test.dart's category-count assertions
  ///
  /// In en, this message translates to:
  /// **'Distress & worry'**
  String get duaCategoryDistress;

  /// Reference key DUA_CATEGORIES[].label ('food') — exact text asserted by duas_tool_test.dart's category-count assertions
  ///
  /// In en, this message translates to:
  /// **'Food & drink'**
  String get duaCategoryFood;

  /// Reference key DUA_CATEGORIES[].label ('sleep') — exact text asserted by duas_tool_test.dart's category-count assertions
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get duaCategorySleep;

  /// Reference DUAS[].title, the 'distress' dua (Sahih al-Bukhari 6369)
  ///
  /// In en, this message translates to:
  /// **'Relief from anxiety'**
  String get duaTitleAnxiety;

  /// Reference DUAS[].title, the 'food' dua (Sunan Abi Dawud 3767) — exact text asserted literally by duas_tool_test.dart (tap target)
  ///
  /// In en, this message translates to:
  /// **'Before eating'**
  String get duaTitleBeforeEating;

  /// Reference DUAS[].title, the 'sleep' dua (Sahih al-Bukhari 6324)
  ///
  /// In en, this message translates to:
  /// **'Before sleeping'**
  String get duaTitleBeforeSleeping;

  /// Reference DUAS[].title, the 'morning' dua (Sahih Muslim 2723)
  ///
  /// In en, this message translates to:
  /// **'Morning remembrance'**
  String get duaTitleMorningRemembrance;

  /// Reference DUAS[].title, the 'travel' dua (Az-Zukhruf 13)
  ///
  /// In en, this message translates to:
  /// **'Dua for travel'**
  String get duaTitleTravel;

  /// Reference key duas.all — the browse-list title with no category filter
  ///
  /// In en, this message translates to:
  /// **'All duas'**
  String get duasAll;

  /// Filter-bar section title
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get duasCategories;

  /// name: String — reference key duas.inCategory, the browse-list title once a category is chosen (the reference passes the category's own label as {name})
  ///
  /// In en, this message translates to:
  /// **'{name}'**
  String duasInCategory(String name);

  /// Reference key duas.noMatch — empty-state title
  ///
  /// In en, this message translates to:
  /// **'No duas here yet'**
  String get duasNoMatch;

  /// Reference key duas.noMatchText — empty-state body
  ///
  /// In en, this message translates to:
  /// **'Try another category or clear the search.'**
  String get duasNoMatchText;

  /// Reference key duas.search — search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search duas'**
  String get duasSearch;

  /// Reference key duas.today — the featured reader card's reference line
  ///
  /// In en, this message translates to:
  /// **'Dua of the day'**
  String get duasToday;

  /// Generic, reusable reader-card control (not dua-prefixed) — reference key reader.listen; kept deliberately generic since other reader cards may reuse it
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get readerListen;

  /// Generic, reusable reader-card toast (not dua-prefixed) — reference key reader.playing, kept as the plain 'Playing' rather than the reference's dua-specific 'Playing recitation' so the string stays reusable by any future audio reader card
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get readerPlaying;

  /// Section title above the name grid
  ///
  /// In en, this message translates to:
  /// **'All names'**
  String get names99AllTitle;

  /// n: String (formatted count) — honesty disclosure on the summary card: twelve of ninety-nine names are held, and this says so rather than looking like a full but truncated list
  ///
  /// In en, this message translates to:
  /// **'The remaining {n} need a verified source.'**
  String names99Caption(String n);

  /// Summary card's kicker, above the held-count figure
  ///
  /// In en, this message translates to:
  /// **'Names of Allah'**
  String get names99Kicker;

  /// Empty-state title
  ///
  /// In en, this message translates to:
  /// **'No name matches'**
  String get names99NoMatch;

  /// Empty-state body
  ///
  /// In en, this message translates to:
  /// **'Try the transliteration or the meaning.'**
  String get names99NoMatchText;

  /// name: String, meaning: String — the toast a tap on a name card says, composed exactly as names99.tool.js does (n.tl + ' — ' + n.meaning); em dash asserted literally by names99_tool_test.dart ('Al-Quddus — The Most Holy')
  ///
  /// In en, this message translates to:
  /// **'{name} — {meaning}'**
  String names99Opened(String name, String meaning);

  /// The progress ring's own accessible label, alongside its centre percentage
  ///
  /// In en, this message translates to:
  /// **'Names known'**
  String get names99Progress;

  /// held: String, total: String — the ring's accessible value and the summary's reading ('12 of 99')
  ///
  /// In en, this message translates to:
  /// **'{held} of {total}'**
  String names99Reading(String held, String total);

  /// Search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search names'**
  String get names99Search;

  /// name: String — the reference line a shared name card carries
  ///
  /// In en, this message translates to:
  /// **'{name} — Asma ul Husna'**
  String names99ShareSource(String name);

  /// total: String — the small suffix beside the lead figure ('/ 99')
  ///
  /// In en, this message translates to:
  /// **'/ {total}'**
  String names99Total(String total);

  /// Reference key markets.cap — an asset row's meta line ('Vol {vol}', 'Cap {cap}')
  ///
  /// In en, this message translates to:
  /// **'Cap'**
  String get marketsCap;

  /// Reference key markets.tab.global — the world indices section/context-bar label
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get marketsGlobal;

  /// Section title, the crypto board — beyond the reference's own three-section world board (see markets_tool.dart's library note), so not a reference-supplied string
  ///
  /// In en, this message translates to:
  /// **'Top crypto'**
  String get marketsTopCrypto;

  /// Section title, the ETF board — see marketsTopCrypto's note
  ///
  /// In en, this message translates to:
  /// **'Top ETFs'**
  String get marketsTopEtfs;

  /// Reference key markets.vol — an asset row's meta line ('Vol {vol}', 'Cap {cap}')
  ///
  /// In en, this message translates to:
  /// **'Vol'**
  String get marketsVol;

  /// name: String — reference key bills.opening, the toast on tapping a bill row
  ///
  /// In en, this message translates to:
  /// **'Opening {name}'**
  String billsOpening(String name);

  /// Reference key bills.trend — the trend chart's own label/section title
  ///
  /// In en, this message translates to:
  /// **'Six months'**
  String get billsTrend;

  /// money: String — reference key bills.trendCap — the trend chart's caption
  ///
  /// In en, this message translates to:
  /// **'Total billed each month: {money}'**
  String billsTrendCap(String money);

  /// n: int — the summary card's caption when bills are overdue (bills_tool.dart). Not in wave9_arb_keys.md's alphabetical 262-key list (that list's own header count is actually off by 9 — 271 keys, not 262 — see final report), but the list's own instructions explicitly call out this key's ICU-plural shape and bills_tool.dart / bills_tool_test.dart both reference it, so it is added here too
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 overdue} other{{n} overdue}}'**
  String billsOverdueCount(int n);

  /// date: String — a paid bill's row meta, when it was paid
  ///
  /// In en, this message translates to:
  /// **'Paid {date}'**
  String billsPaidOn(String date);

  /// Summary card's caption when nothing is overdue
  ///
  /// In en, this message translates to:
  /// **'Everything is on track'**
  String get billsAllOnTrack;

  /// Summary card's stat label for bills not yet due
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get billsUpcoming;

  /// Summary card's stat label for the amount already paid
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get billsPaidAmount;

  /// Body text under the overdue-attention notice
  ///
  /// In en, this message translates to:
  /// **'These bills are overdue and may carry a late fee.'**
  String get billsNeedAttentionText;

  /// Section title above the full bills list
  ///
  /// In en, this message translates to:
  /// **'All bills'**
  String get billsAll;

  /// Empty-state title when a filter matches nothing
  ///
  /// In en, this message translates to:
  /// **'No bills match'**
  String get billsNoMatch;

  /// Empty-state body text
  ///
  /// In en, this message translates to:
  /// **'Try a different filter.'**
  String get billsNoMatchText;

  /// Row meta prefix before a bill's reference number
  ///
  /// In en, this message translates to:
  /// **'Ref'**
  String get billsRef;

  /// name: String — the toast on tapping an already-paid bill row
  ///
  /// In en, this message translates to:
  /// **'{name} is already paid'**
  String billsRowPaid(String name);

  /// Reference key cricket.balls — batting table column header
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get cricketBalls;

  /// Reference key cricket.batter — batting table column header
  ///
  /// In en, this message translates to:
  /// **'Batter'**
  String get cricketBatter;

  /// Reference key cricket.batting — section title
  ///
  /// In en, this message translates to:
  /// **'Batting'**
  String get cricketBatting;

  /// Reference key cricket.bowler — bowling table column header
  ///
  /// In en, this message translates to:
  /// **'Bowler'**
  String get cricketBowler;

  /// Reference key cricket.bowling — section title
  ///
  /// In en, this message translates to:
  /// **'Bowling'**
  String get cricketBowling;

  /// team: String — reference key cricket.choseToBat, the score card's status line
  ///
  /// In en, this message translates to:
  /// **'{team} chose to bat'**
  String cricketChoseToBat(String team);

  /// Reference key cricket.economy — bowling table column header
  ///
  /// In en, this message translates to:
  /// **'Econ'**
  String get cricketEconomy;

  /// Reference key cricket.fixtures — tab label, asserted literally by cricket_test.dart
  ///
  /// In en, this message translates to:
  /// **'Fixtures'**
  String get cricketFixtures;

  /// Reference key cricket.format — score card metric label
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get cricketFormat;

  /// Reference key cricket.fours — batting table column header
  ///
  /// In en, this message translates to:
  /// **'4s'**
  String get cricketFours;

  /// Reference key cricket.live — tab label
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get cricketLive;

  /// Reference key cricket.lost — standings table column header
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get cricketLost;

  /// Reference key cricket.maidens — bowling table column header
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get cricketMaidens;

  /// Reference key cricket.notOut — suffix beside a batter's name who has not been dismissed
  ///
  /// In en, this message translates to:
  /// **'not out'**
  String get cricketNotOut;

  /// Reference key cricket.nrr — standings table column header, kept as the universal stat abbreviation
  ///
  /// In en, this message translates to:
  /// **'NRR'**
  String get cricketNrr;

  /// Reference key cricket.overs — suffix after an overs count on the score card (e.g. '18.2 overs')
  ///
  /// In en, this message translates to:
  /// **'overs'**
  String get cricketOvers;

  /// Reference key cricket.overs2 — bowling table's own overs-bowled column header (distinct from cricketOvers' score-card suffix, same underlying word)
  ///
  /// In en, this message translates to:
  /// **'O'**
  String get cricketOvers2;

  /// Reference key cricket.played — standings table column header
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get cricketPlayed;

  /// Reference key cricket.points — standings table column header
  ///
  /// In en, this message translates to:
  /// **'Pts'**
  String get cricketPoints;

  /// Reference key cricket.runRate — score card metric label
  ///
  /// In en, this message translates to:
  /// **'Run rate'**
  String get cricketRunRate;

  /// Reference key cricket.runs — batting/bowling table column header
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get cricketRuns;

  /// Reference key cricket.sixes — batting table column header
  ///
  /// In en, this message translates to:
  /// **'6s'**
  String get cricketSixes;

  /// Reference key cricket.standings — the tab label that opens the table; asserted literally by cricket_test.dart (see cricketTable's own note for the reference's own inverted naming)
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get cricketStandings;

  /// Reference key cricket.strikeRate — batting table column header
  ///
  /// In en, this message translates to:
  /// **'SR'**
  String get cricketStrikeRate;

  /// Reference key cricket.table — the section title the Table tab opens, asserted literally by cricket_test.dart. The reference's own naming is inverted: the tab is labelled cricket.standings ('Table') and the section it opens is titled cricket.table ('Standings')
  ///
  /// In en, this message translates to:
  /// **'Standings'**
  String get cricketTable;

  /// Reference key cricket.team — standings table column header
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get cricketTeam;

  /// Reference key cricket.upcoming — fixtures section title
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get cricketUpcoming;

  /// Reference key cricket.venue — score card metric label
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get cricketVenue;

  /// Reference key cricket.wickets — bowling table column header
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get cricketWickets;

  /// Reference key cricket.won — standings table column header
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get cricketWon;

  /// Reference key loadshed.billHint — the nudge-to-Bills row's value
  ///
  /// In en, this message translates to:
  /// **'Check your last bill'**
  String get loadshedBillHint;

  /// Reference key loadshed.currentlyOff — summary card kicker, mid-outage
  ///
  /// In en, this message translates to:
  /// **'Power is off'**
  String get loadshedCurrentlyOff;

  /// Reference key loadshed.currentlyOn — summary card kicker, power currently on
  ///
  /// In en, this message translates to:
  /// **'Next outage'**
  String get loadshedCurrentlyOn;

  /// from: String, to: String — reference key loadshed.nextOutage
  ///
  /// In en, this message translates to:
  /// **'{from} to {to}'**
  String loadshedNextOutage(String from, String to);

  /// Reference key loadshed.notify — the reminders row's label
  ///
  /// In en, this message translates to:
  /// **'Notify me before an outage'**
  String get loadshedNotify;

  /// Reference key loadshed.notifyOn — confirmation toast
  ///
  /// In en, this message translates to:
  /// **'Outage reminders are on'**
  String get loadshedNotifyOn;

  /// The reminders row's static trailing value — matches the reference's own reused common.on ('On')
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get loadshedNotifyValue;

  /// Reference key loadshed.outage — each schedule row's own title
  ///
  /// In en, this message translates to:
  /// **'Outage'**
  String get loadshedOutage;

  /// time: String — reference key loadshed.powerBack, summary caption mid-outage
  ///
  /// In en, this message translates to:
  /// **'Back on at {time}'**
  String loadshedPowerBack(String time);

  /// Reference key loadshed.provider — context-bar label
  ///
  /// In en, this message translates to:
  /// **'Distribution company'**
  String get loadshedProvider;

  /// Reference key loadshed.reliability — summary card stat label
  ///
  /// In en, this message translates to:
  /// **'Kept to schedule'**
  String get loadshedReliability;

  /// Reference key loadshed.schedule — section title
  ///
  /// In en, this message translates to:
  /// **'Today’s schedule'**
  String get loadshedSchedule;

  /// hours: String — a slot's own length, scoped to Loadshedding rather than a second shared duration key (loadshed_text.dart's own note)
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String loadshedSlotDuration(String hours);

  /// Reference key loadshed.slots — summary card stat label
  ///
  /// In en, this message translates to:
  /// **'Slots'**
  String get loadshedSlots;

  /// Reference key loadshed.today — summary card stat label
  ///
  /// In en, this message translates to:
  /// **'Off today'**
  String get loadshedToday;

  /// Reference key loadshed.week — the week chart's own label/section title
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get loadshedWeek;

  /// Reference key loadshed.weekCap — week chart caption
  ///
  /// In en, this message translates to:
  /// **'Hours without power each day'**
  String get loadshedWeekCap;

  /// Reference key bonds.bond — e.g. '750 bond'
  ///
  /// In en, this message translates to:
  /// **'bond'**
  String get prizebondsBond;

  /// Reference key bonds.check — action button
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get prizebondsCheck;

  /// Reference key bonds.checkLead — lead text above the check form
  ///
  /// In en, this message translates to:
  /// **'Check a bond number against the latest draw.'**
  String get prizebondsCheckLead;

  /// Reference key bonds.denomination — the denomination picker's accessible label
  ///
  /// In en, this message translates to:
  /// **'Denomination'**
  String get prizebondsDenomination;

  /// Reference key bonds.denominations — summary card stat label
  ///
  /// In en, this message translates to:
  /// **'Denominations'**
  String get prizebondsDenominations;

  /// Reference key bonds.draws — section title
  ///
  /// In en, this message translates to:
  /// **'Upcoming draws'**
  String get prizebondsDraws;

  /// Reference key bonds.first — prize-tiers table column header
  ///
  /// In en, this message translates to:
  /// **'First'**
  String get prizebondsFirst;

  /// Reference key bonds.firstPrize — a draw row's value caption
  ///
  /// In en, this message translates to:
  /// **'First prize'**
  String get prizebondsFirstPrize;

  /// Reference key bonds.nextDraw — summary card kicker
  ///
  /// In en, this message translates to:
  /// **'Next draw'**
  String get prizebondsNextDraw;

  /// denom: String, draw: String — reference key bonds.nextDrawSub, summary card caption
  ///
  /// In en, this message translates to:
  /// **'{denom} bond · {draw}'**
  String prizebondsNextDrawSub(String denom, String draw);

  /// Reference key bonds.noWin — toast on Check, always (the reference never wires up a real match)
  ///
  /// In en, this message translates to:
  /// **'No prize on this number in the latest draw'**
  String get prizebondsNoWin;

  /// Empty-state title, 'Your numbers'. Deliberately reworded from the reference's own bonds.noneSaved ('No saved numbers') to read as an honest empty state — see prizebondsNoneSavedText's note
  ///
  /// In en, this message translates to:
  /// **'You haven’t saved a number yet'**
  String get prizebondsNoneSaved;

  /// Deliberately reworded from the reference's own bonds.noneSavedText ('Check a number above and save it to be told when it wins.'), which implies a working save action; the reference never writes to its own saved-numbers state (see prizebonds_tool.dart's library note), so this describes the permanently-empty state honestly instead of promising a save flow that does not exist
  ///
  /// In en, this message translates to:
  /// **'There’s nothing here to check against a draw yet.'**
  String get prizebondsNoneSavedText;

  /// Reference key bonds.number — field label
  ///
  /// In en, this message translates to:
  /// **'Bond number'**
  String get prizebondsNumber;

  /// Reference key bonds.prizePool — summary card stat label
  ///
  /// In en, this message translates to:
  /// **'Total prizes'**
  String get prizebondsPrizePool;

  /// Reference key bonds.prizeShape — chart section title
  ///
  /// In en, this message translates to:
  /// **'First prize by denomination'**
  String get prizebondsPrizeShape;

  /// Reference key bonds.prizeShapeCap — chart caption
  ///
  /// In en, this message translates to:
  /// **'A larger bond buys a larger top prize, not better odds.'**
  String get prizebondsPrizeShapeCap;

  /// Reference key bonds.prizeTiers — table section title
  ///
  /// In en, this message translates to:
  /// **'Prize tiers'**
  String get prizebondsPrizeTiers;

  /// Reference key bonds.scheme — context-bar label
  ///
  /// In en, this message translates to:
  /// **'National prize bonds'**
  String get prizebondsScheme;

  /// Reference key bonds.second — prize-tiers table column header
  ///
  /// In en, this message translates to:
  /// **'Second'**
  String get prizebondsSecond;

  /// Reference key bonds.third — prize-tiers table column header
  ///
  /// In en, this message translates to:
  /// **'Third'**
  String get prizebondsThird;

  /// Reference key bonds.totalWinners — summary card stat label
  ///
  /// In en, this message translates to:
  /// **'Winners'**
  String get prizebondsTotalWinners;

  /// Empty state body, non-Pakistan reader — reworded to match savingsUnavailableText's own 'specific to Pakistan' phrasing (the sibling Money & Rates tool) rather than the reference's own more generic bonds.unavailable.text ('a country-specific savings product')
  ///
  /// In en, this message translates to:
  /// **'Prize bonds are specific to Pakistan.'**
  String get prizebondsUnavailableText;

  /// Reference key bonds.unavailable.title — empty state title, non-Pakistan reader
  ///
  /// In en, this message translates to:
  /// **'Not available in your country'**
  String get prizebondsUnavailableTitle;

  /// n: String — reference key bonds.winners, a draw row's meta line
  ///
  /// In en, this message translates to:
  /// **'{n} winners'**
  String prizebondsWinners(String n);

  /// Reference key bonds.yourNumbers — section title
  ///
  /// In en, this message translates to:
  /// **'Your numbers'**
  String get prizebondsYourNumbers;

  /// Label for the next upcoming alarm.
  ///
  /// In en, this message translates to:
  /// **'Next alarm'**
  String get alarmsNext;

  /// Empty state: no alarms have been created.
  ///
  /// In en, this message translates to:
  /// **'No alarms set'**
  String get alarmsNone;

  /// Screen/section title for the alarms list.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarmsAll;

  /// Button that opens the new-alarm form.
  ///
  /// In en, this message translates to:
  /// **'Add an alarm'**
  String get alarmsAdd;

  /// Form title when adding an alarm.
  ///
  /// In en, this message translates to:
  /// **'New alarm'**
  String get alarmsAdding;

  /// Alarm repeat option: every day of the week.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get alarmsDaily;

  /// Alarm repeat option: Monday to Friday only.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get alarmsWeekdays;

  /// Alarm repeat option: Saturday and Sunday only.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get alarmsWeekend;

  /// Suggested alarm label/preset.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get alarmsA1;

  /// Suggested alarm label/preset for a later, relaxed wake-up.
  ///
  /// In en, this message translates to:
  /// **'Lie-in'**
  String get alarmsA2;

  /// Suggested alarm label/preset for an evening wind-down reminder.
  ///
  /// In en, this message translates to:
  /// **'Wind down'**
  String get alarmsA3;

  /// Relative time until the next alarm fires.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{in about 1 hour} other{in about {n} hours}}'**
  String alarmsInHours(int n);

  /// Button that captures the current page photo.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get docscanCapture;

  /// On-screen hint shown on the capture page.
  ///
  /// In en, this message translates to:
  /// **'Lay the page flat and capture'**
  String get docscanHint;

  /// Said when the camera permission is refused and the platform will ask again the next time Capture is pressed.
  ///
  /// In en, this message translates to:
  /// **'Lume can\'t use the camera. Press Capture to be asked again.'**
  String get docscanCaptureDenied;

  /// Said when the camera was refused and Android does not say whether it will ask again.
  ///
  /// In en, this message translates to:
  /// **'Lume can\'t use the camera. Press Capture to be asked again, or turn it on in Settings if Android doesn\'t ask.'**
  String get docscanCaptureUndetermined;

  /// Section title over the captured pages list.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get docscanPagesTitle;

  /// Label for one captured page, by its position.
  ///
  /// In en, this message translates to:
  /// **'Page {n}'**
  String docscanPageN(int n);

  /// Page-source option: capture with the camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get docscanSourceCamera;

  /// Page-source option: import from the gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get docscanSourceGallery;

  /// Toast after clearing all captured pages.
  ///
  /// In en, this message translates to:
  /// **'Pages cleared'**
  String get docscanCleared;

  /// Toast when sharing the scanned pages fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share. Try again.'**
  String get docscanShareFailed;

  /// Section title over the how-it-works steps.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get docscanStepsTitle;

  /// First how-it-works step.
  ///
  /// In en, this message translates to:
  /// **'Capture each page'**
  String get docscanStepCapture;

  /// Second how-it-works step.
  ///
  /// In en, this message translates to:
  /// **'Review and remove pages'**
  String get docscanStepReview;

  /// Third how-it-works step.
  ///
  /// In en, this message translates to:
  /// **'Share when you\'re ready'**
  String get docscanStepShare;

  /// Title of the honesty note above the Faraid calculator.
  ///
  /// In en, this message translates to:
  /// **'A guide, not a ruling'**
  String get faraidNoteTitle;

  /// Body of the honesty note above the Faraid calculator.
  ///
  /// In en, this message translates to:
  /// **'This calculator only covers a wife or wives, sons and daughters — not every relative Islamic inheritance law recognizes. It\'s a starting point, not a fatwa.'**
  String get faraidNoteText;

  /// Section title for the estate-entry fields.
  ///
  /// In en, this message translates to:
  /// **'The estate'**
  String get faraidEstate;

  /// Field label: the estate's value before debts and bequest.
  ///
  /// In en, this message translates to:
  /// **'Gross estate'**
  String get faraidGross;

  /// Field label: amounts deducted before distribution.
  ///
  /// In en, this message translates to:
  /// **'Debts & funeral costs'**
  String get faraidDebts;

  /// Field label: the optional bequest amount.
  ///
  /// In en, this message translates to:
  /// **'Bequest (wasiyyah)'**
  String get faraidBequest;

  /// Hint under the bequest field.
  ///
  /// In en, this message translates to:
  /// **'Capped at one third of the net estate.'**
  String get faraidBequestHint;

  /// Section title for the heirs list.
  ///
  /// In en, this message translates to:
  /// **'Heirs'**
  String get faraidHeirs;

  /// Heir type: wife/wives.
  ///
  /// In en, this message translates to:
  /// **'Wife'**
  String get faraidWife;

  /// Heir type: sons.
  ///
  /// In en, this message translates to:
  /// **'Sons'**
  String get faraidSons;

  /// Heir type: daughters.
  ///
  /// In en, this message translates to:
  /// **'Daughters'**
  String get faraidDaughters;

  /// Explainer line for the wife's fixed share.
  ///
  /// In en, this message translates to:
  /// **'A wife\'s fixed share is 1/8 with children, 1/4 without.'**
  String get faraidRuleWife;

  /// Explainer line for how sons share the residue.
  ///
  /// In en, this message translates to:
  /// **'A son shares the residue as 2 parts to a daughter\'s 1.'**
  String get faraidRuleSons;

  /// Explainer line for how daughters' shares work.
  ///
  /// In en, this message translates to:
  /// **'A daughter alone or with sisters takes a fixed share; with a brother she shares the residue 1:2.'**
  String get faraidRuleDaughters;

  /// Label: estate value after debts and bequest.
  ///
  /// In en, this message translates to:
  /// **'Net estate'**
  String get faraidNet;

  /// Caption shown when the entered bequest exceeded the one-third cap.
  ///
  /// In en, this message translates to:
  /// **'The bequest was capped at one third of the net estate'**
  String get faraidCaptionCapped;

  /// Caption shown once the net estate is ready to distribute.
  ///
  /// In en, this message translates to:
  /// **'Distributed among the heirs below'**
  String get faraidCaptionReady;

  /// Section title over the calculated shares.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get faraidDistribution;

  /// Section title for the per-heir explanation list.
  ///
  /// In en, this message translates to:
  /// **'Why these shares'**
  String get faraidExplain;

  /// Share-type tag: a residuary (non-fixed) heir.
  ///
  /// In en, this message translates to:
  /// **'Residuary'**
  String get faraidResiduary;

  /// Reason tag for the wife's share.
  ///
  /// In en, this message translates to:
  /// **'Fixed share'**
  String get faraidReasonWife;

  /// Reason tag for the sons' share.
  ///
  /// In en, this message translates to:
  /// **'Residue, 2 parts to a daughter\'s 1'**
  String get faraidReasonSons;

  /// Reason tag for the daughters' share.
  ///
  /// In en, this message translates to:
  /// **'Fixed share, or residue with a brother'**
  String get faraidReasonDaughters;

  /// Label for the portion this calculator doesn't assign to a modelled heir.
  ///
  /// In en, this message translates to:
  /// **'Unallocated'**
  String get faraidUnallocated;

  /// Explainer for the unallocated portion.
  ///
  /// In en, this message translates to:
  /// **'This calculator doesn\'t model every relative — a father, mother, husband, siblings or grandchildren would normally receive this share.'**
  String get faraidReasonUnallocated;

  /// Button that opens the new-fast form.
  ///
  /// In en, this message translates to:
  /// **'Log a fast'**
  String get fastingLogFast;

  /// Form title when editing a logged fast.
  ///
  /// In en, this message translates to:
  /// **'Edit fast'**
  String get fastingEditFast;

  /// Field label for the fast's date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fastingDateLabel;

  /// Field label for the fast's type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fastingKindLabel;

  /// Fast type: a voluntary Sunnah fast.
  ///
  /// In en, this message translates to:
  /// **'Sunnah'**
  String get fastingKindSunnah;

  /// Fast type: making up a missed obligatory fast.
  ///
  /// In en, this message translates to:
  /// **'Qada'**
  String get fastingKindQada;

  /// Toggle label confirming the fast was kept.
  ///
  /// In en, this message translates to:
  /// **'I kept this fast'**
  String get fastingKeptToggleLabel;

  /// Button that deletes a logged fast.
  ///
  /// In en, this message translates to:
  /// **'Delete fast'**
  String get fastingDeleteEntry;

  /// Confirmation dialog title for deleting a fast.
  ///
  /// In en, this message translates to:
  /// **'Delete this fast?'**
  String get fastingDeleteTitle;

  /// Confirmation dialog body for deleting a fast.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone from here.'**
  String get fastingDeleteText;

  /// Toast for a conflicting/missing record on write (mirrors cycleErrConflict).
  ///
  /// In en, this message translates to:
  /// **'This entry changed elsewhere'**
  String get fastingErrConflict;

  /// Generic write-failure toast (mirrors cycleErrFailed).
  ///
  /// In en, this message translates to:
  /// **'That didn\'t save. Try again.'**
  String get fastingErrFailed;

  /// Toast after saving a fast.
  ///
  /// In en, this message translates to:
  /// **'Fast saved'**
  String get fastingSavedToast;

  /// Toast after deleting a fast.
  ///
  /// In en, this message translates to:
  /// **'Fast deleted'**
  String get fastingDeletedToast;

  /// Empty state title for the fasting log.
  ///
  /// In en, this message translates to:
  /// **'No fasts logged yet'**
  String get fastingEmptyTitle;

  /// Empty state text for the fasting log.
  ///
  /// In en, this message translates to:
  /// **'Log a fast to start tracking your streak.'**
  String get fastingEmptyText;

  /// Empty state CTA button.
  ///
  /// In en, this message translates to:
  /// **'Log your first fast'**
  String get fastingLogFirst;

  /// Caption for the current fasting streak count.
  ///
  /// In en, this message translates to:
  /// **'{n} in a row'**
  String fastingStreakCaption(int n);

  /// Stat label: fasts kept.
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get fastingProgressLabel;

  /// Stat label: voluntary (non-obligatory) fasts.
  ///
  /// In en, this message translates to:
  /// **'Voluntary'**
  String get fastingVoluntaryLabel;

  /// Stat label: obligatory fasts.
  ///
  /// In en, this message translates to:
  /// **'Obligatory'**
  String get fastingObligatoryLabel;

  /// Stat label: fasts missed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get fastingMissedLabel;

  /// Section title over the fasting calendar grid.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get fastingCalendarTitle;

  /// Section title over the recent-days list.
  ///
  /// In en, this message translates to:
  /// **'Recent days'**
  String get fastingRecentTitle;

  /// Calendar-day badge: this day's fast was kept.
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get fastingKeptBadge;

  /// Calendar-day badge: this day's fast was not kept.
  ///
  /// In en, this message translates to:
  /// **'Not kept'**
  String get fastingNotKeptBadge;

  /// Screen-reader summary for the fasting calendar grid.
  ///
  /// In en, this message translates to:
  /// **'{kept} of {total} days fasted'**
  String fastingCalendarA11y(int kept, int total);

  /// Subtitle noting the calendar is calculated, not observed.
  ///
  /// In en, this message translates to:
  /// **'Calculated · tabular Islamic calendar'**
  String get hijriCalculatedSubtitle;

  /// Hijri year with its era marker. year: String — pre-formatted via LumeFormatting.integer for locale-aware digits.
  ///
  /// In en, this message translates to:
  /// **'{year} AH'**
  String hijriYearAh(String year);

  /// Title of the honesty note above the Hijri calendar.
  ///
  /// In en, this message translates to:
  /// **'A calculated calendar, not an official sighting'**
  String get hijriNoteTitle;

  /// Body of the honesty note above the Hijri calendar.
  ///
  /// In en, this message translates to:
  /// **'This calendar is worked out from a fixed 30-year arithmetic cycle, not the officially adopted Umm al-Qura calendar or your local moon-sighting authority. Dates here can fall a day either side of what is actually announced.'**
  String get hijriNoteText;

  /// Section title over the upcoming Islamic dates list.
  ///
  /// In en, this message translates to:
  /// **'Upcoming dates'**
  String get hijriEventsTitle;

  /// Islamic calendar event: the 10th of Muharram.
  ///
  /// In en, this message translates to:
  /// **'Ashura'**
  String get hijriEventAshura;

  /// Islamic calendar event: the first of Ramadan.
  ///
  /// In en, this message translates to:
  /// **'Ramadan begins'**
  String get hijriEventRamadanBegins;

  /// Islamic calendar event: the 9th of Dhul-Hijjah.
  ///
  /// In en, this message translates to:
  /// **'Day of Arafah'**
  String get hijriEventDayOfArafah;

  /// Section title over the date converter.
  ///
  /// In en, this message translates to:
  /// **'Convert a date'**
  String get hijriConvertTitle;

  /// Field label for the Gregorian side of the converter.
  ///
  /// In en, this message translates to:
  /// **'Gregorian date'**
  String get hijriGregorian;

  /// Field label for the Hijri side of the converter.
  ///
  /// In en, this message translates to:
  /// **'Hijri date'**
  String get hijriHijriDate;

  /// Section title over the list of Hijri month names.
  ///
  /// In en, this message translates to:
  /// **'The Hijri months'**
  String get hijriMonthsTitle;

  /// Placeholder text for the link field.
  ///
  /// In en, this message translates to:
  /// **'https://…'**
  String get mediasaverLinkPlaceholder;

  /// Empty state title for the saved-media library.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get mediasaverEmptyTitle;

  /// Field label: destination country for the photo spec.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get passportCountry;

  /// Field label: the target photo size.
  ///
  /// In en, this message translates to:
  /// **'Photo size'**
  String get passportSize;

  /// Field label: background treatment.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get passportBackground;

  /// Background option: plain white.
  ///
  /// In en, this message translates to:
  /// **'Plain white'**
  String get passportWhite;

  /// Field label: required head height in the frame.
  ///
  /// In en, this message translates to:
  /// **'Head height'**
  String get passportHeadHeight;

  /// Button that opens the camera.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get passportCapture;

  /// Status text while the camera opens.
  ///
  /// In en, this message translates to:
  /// **'Opening the camera'**
  String get passportCapturing;

  /// Button that imports a photo from the gallery.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get passportImport;

  /// Status text while the gallery picker is open.
  ///
  /// In en, this message translates to:
  /// **'Choosing a photo'**
  String get passportImporting;

  /// Section title over the photo requirements list.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get passportRequirements;

  /// Requirement: background.
  ///
  /// In en, this message translates to:
  /// **'Plain, evenly lit background'**
  String get passportReqBackground;

  /// Requirement: facial expression.
  ///
  /// In en, this message translates to:
  /// **'Neutral expression, mouth closed'**
  String get passportReqExpression;

  /// Requirement: glasses/glare.
  ///
  /// In en, this message translates to:
  /// **'No glare or heavy frames over the eyes'**
  String get passportReqGlasses;

  /// Requirement: photo recency.
  ///
  /// In en, this message translates to:
  /// **'Taken within the last six months'**
  String get passportReqRecent;

  /// Section title over the common photo-size presets.
  ///
  /// In en, this message translates to:
  /// **'Common sizes'**
  String get passportSizes;

  /// Field label: target document type.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get passportDocument;

  /// Field label: print resolution in dots per inch.
  ///
  /// In en, this message translates to:
  /// **'DPI'**
  String get passportDpi;

  /// Document type: passport photo.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get passportPassport;

  /// Document type: US visa photo.
  ///
  /// In en, this message translates to:
  /// **'US visa'**
  String get passportVisaUS;

  /// Document type: national ID photo.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get passportIdCard;

  /// Button that saves the cropped photo.
  ///
  /// In en, this message translates to:
  /// **'Save photo'**
  String get passportSavePhoto;

  /// Status text while the photo saves.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get passportSaving;

  /// Toast after saving the photo.
  ///
  /// In en, this message translates to:
  /// **'Saved to your photos'**
  String get passportSaved;

  /// Button that discards and retakes the photo.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get passportRetake;

  /// Button that returns to the gallery picker.
  ///
  /// In en, this message translates to:
  /// **'Choose a different photo'**
  String get passportChooseDifferent;

  /// Accessibility label for the cropped preview image.
  ///
  /// In en, this message translates to:
  /// **'Your cropped passport photo'**
  String get passportPreviewAlt;

  /// On-screen framing guide hint.
  ///
  /// In en, this message translates to:
  /// **'Centre your face in the frame, looking straight ahead'**
  String get passportGuideHint;

  /// Said when the chosen photo can't be processed.
  ///
  /// In en, this message translates to:
  /// **'Lume couldn\'t use that photo. Try a different one.'**
  String get passportProcessFailed;

  /// Said when the camera permission is refused and the platform will ask again.
  ///
  /// In en, this message translates to:
  /// **'Lume can\'t use the camera. Press Take a photo to be asked again.'**
  String get passportCameraDenied;

  /// Said when the camera permission is off for good.
  ///
  /// In en, this message translates to:
  /// **'Camera access for Lume is off. Turn it on in Settings to take a photo.'**
  String get passportCameraBlocked;

  /// Said when the camera was refused and Android does not say whether it will ask again.
  ///
  /// In en, this message translates to:
  /// **'Lume can\'t use the camera. Press Take a photo to be asked again, or turn it on in Settings if Android doesn\'t ask.'**
  String get passportCameraUndetermined;

  /// Said when a device policy has turned the camera off.
  ///
  /// In en, this message translates to:
  /// **'The camera is turned off on this device by a restriction or its administrator.'**
  String get passportCameraRestricted;

  /// Said when this build/device has no camera capture.
  ///
  /// In en, this message translates to:
  /// **'Taking a photo isn\'t available on this device'**
  String get passportCameraUnavailable;

  /// Toast when opening the camera fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the camera. Try again.'**
  String get passportCameraFailed;

  /// Said when the photo-library permission is refused.
  ///
  /// In en, this message translates to:
  /// **'Lume can\'t open your photos. You can allow it in Settings.'**
  String get passportGalleryDenied;

  /// Said when this build/device has no gallery picker.
  ///
  /// In en, this message translates to:
  /// **'Choosing a photo isn\'t available on this device'**
  String get passportGalleryUnavailable;

  /// Toast when opening the gallery fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your photos. Try again.'**
  String get passportGalleryFailed;

  /// Said when the chosen photo exceeds a usable size.
  ///
  /// In en, this message translates to:
  /// **'That photo is too large to use'**
  String get passportTooLarge;

  /// Action that opens the device's Settings page for Lume.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get passportOpenSettings;

  /// Said when the system would not open Lume's page in Settings.
  ///
  /// In en, this message translates to:
  /// **'Settings didn\'t open. You\'ll find Lume under Apps in your phone\'s Settings.'**
  String get passportSettingsFailed;

  /// Said when the photo-library write permission is refused.
  ///
  /// In en, this message translates to:
  /// **'Lume can\'t save to your photos. You can allow it in Settings.'**
  String get passportSaveDenied;

  /// Said when the photo library reports no space.
  ///
  /// In en, this message translates to:
  /// **'There\'s no space to save the photo'**
  String get passportSaveNoSpace;

  /// Said when this build/device can't save to the photo library.
  ///
  /// In en, this message translates to:
  /// **'Saving to photos isn\'t available on this device'**
  String get passportSaveUnavailable;

  /// Toast when saving the photo fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the photo. Try again.'**
  String get passportSaveFailed;

  /// Label for the next upcoming prayer.
  ///
  /// In en, this message translates to:
  /// **'Next prayer'**
  String get prayerNext;

  /// Countdown to the next prayer.
  ///
  /// In en, this message translates to:
  /// **'{time} to go'**
  String prayerCountdown(String time);

  /// Label for the day's prayer progress indicator.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get prayerProgress;

  /// Section title for today's prayer times.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get prayerToday;

  /// Label for the next prayer in the day's list.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get prayerUpNext;

  /// Status tag: this prayer's time has already passed today.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get prayerPassed;

  /// Section title for sunrise/sunset times.
  ///
  /// In en, this message translates to:
  /// **'Sunrise & sunset'**
  String get prayerSunTitle;

  /// Section title for the multi-day prayer schedule.
  ///
  /// In en, this message translates to:
  /// **'Upcoming days'**
  String get prayerUpcoming;

  /// Field label: the prayer-time calculation method.
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get prayerMethod;

  /// Calculation method option.
  ///
  /// In en, this message translates to:
  /// **'Muslim World League'**
  String get prayerMethodMwl;

  /// Field label: the Asr-specific calculation setting.
  ///
  /// In en, this message translates to:
  /// **'Asr calculation'**
  String get prayerAsrMethodLabel;

  /// Asr calculation option.
  ///
  /// In en, this message translates to:
  /// **'Standard (Shafi\'i, Maliki, Hanbali)'**
  String get prayerAsrStandard;

  /// Field label: the city used to calculate prayer times.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get prayerLocation;

  /// Field label: the time zone used to display prayer times.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get prayerTimezone;

  /// Section title for prayer settings.
  ///
  /// In en, this message translates to:
  /// **'Method & location'**
  String get prayerSettings;

  /// Empty state title when the selected city has no coordinates.
  ///
  /// In en, this message translates to:
  /// **'No position for {city}'**
  String prayerNoCityTitle(String city);

  /// Empty state body when the selected city has no coordinates.
  ///
  /// In en, this message translates to:
  /// **'Prayer times are worked out from a city\'s coordinates, and Lume has none for this one. Choose another city in Profile to see them.'**
  String get prayerNoCityText;

  /// Empty state title when the time zone can't be resolved.
  ///
  /// In en, this message translates to:
  /// **'No clock for {zone}'**
  String prayerNoZoneTitle(String zone);

  /// Empty state body when the time zone can't be resolved.
  ///
  /// In en, this message translates to:
  /// **'Prayer times are worked out on your clock, so they need your time zone. Choose one in Profile › Time.'**
  String get prayerNoZoneText;

  /// Prompt to choose a time zone, shown inline before times are available.
  ///
  /// In en, this message translates to:
  /// **'Prayer times need your time zone to be worked out. Choose one in Profile › Time.'**
  String get prayerZoneChooseText;

  /// Title of the honesty note above prayer times.
  ///
  /// In en, this message translates to:
  /// **'A calculated schedule, not a mosque announcement'**
  String get prayerNoteTitle;

  /// Body of the honesty note above prayer times.
  ///
  /// In en, this message translates to:
  /// **'These times are worked out from your city\'s coordinates using the Muslim World League method. Cross-check them against your local mosque or authority before relying on them.'**
  String get prayerNoteText;

  /// Source line on the prayer-times share card.
  ///
  /// In en, this message translates to:
  /// **'{city} · {date}'**
  String prayerShareSource(String city, String date);

  /// Toast for a conflicting record on write.
  ///
  /// In en, this message translates to:
  /// **'This changed somewhere else. Open it again.'**
  String get praytrackErrConflict;

  /// Generic write-failure toast.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t save. Try again.'**
  String get praytrackErrFailed;

  /// Section title over today's prayer checklist.
  ///
  /// In en, this message translates to:
  /// **'Mark today\'s prayers'**
  String get praytrackMarkTitle;

  /// Status tag: a prayer not yet marked.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get praytrackPending;

  /// Caption for the current all-five-prayers streak.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{No streak yet} =1{1 day streak} other{{n} day streak}}'**
  String praytrackStreakCaption(int n);

  /// Stat label for the streak count.
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get praytrackStreakLabel;

  /// Stat label: prayers still to make up.
  ///
  /// In en, this message translates to:
  /// **'To make up'**
  String get praytrackQadaStatLabel;

  /// Checkbox label: this prayer was prayed.
  ///
  /// In en, this message translates to:
  /// **'Prayed'**
  String get praytrackCheckLabel;

  /// Section title over the 35-day heatmap.
  ///
  /// In en, this message translates to:
  /// **'Last 35 days'**
  String get praytrackHeatTitle;

  /// Section title over the per-prayer breakdown.
  ///
  /// In en, this message translates to:
  /// **'By prayer'**
  String get praytrackByPrayerTitle;

  /// Caption under the per-prayer breakdown.
  ///
  /// In en, this message translates to:
  /// **'How often each prayer was marked prayed in the last 35 days.'**
  String get praytrackByPrayerCaption;

  /// Section title for the qada (make-up) summary.
  ///
  /// In en, this message translates to:
  /// **'Qada'**
  String get praytrackQadaTitle;

  /// Value line for the qada summary.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Nothing outstanding} =1{1 prayer to make up} other{{n} prayers to make up}}'**
  String praytrackQadaValue(int n);

  /// Footnote clarifying how the qada count is derived.
  ///
  /// In en, this message translates to:
  /// **'Counts a past day\'s prayer only once it went unmarked — never a starting balance.'**
  String get praytrackQadaFootnote;

  /// Kicker label on the Ramadan countdown card.
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get ramadanCountdown;

  /// Estimated start date before Ramadan begins.
  ///
  /// In en, this message translates to:
  /// **'Begins around {date}'**
  String ramadanStarts(String date);

  /// Label for the Hijri year.
  ///
  /// In en, this message translates to:
  /// **'Hijri year'**
  String get ramadanYear;

  /// Label for today's sunset time.
  ///
  /// In en, this message translates to:
  /// **'Sunset today'**
  String get ramadanSunsetToday;

  /// Section title over the pre-Ramadan preparation cards.
  ///
  /// In en, this message translates to:
  /// **'Prepare'**
  String get ramadanPrepare;

  /// Preparation card: making up missed fasts.
  ///
  /// In en, this message translates to:
  /// **'Make up missed fasts'**
  String get ramadanPrepQada;

  /// Subtitle for the qada preparation card.
  ///
  /// In en, this message translates to:
  /// **'Before Ramadan begins'**
  String get ramadanPrepQadaSub;

  /// Preparation card: planning a Qur'an reading pace.
  ///
  /// In en, this message translates to:
  /// **'Set a reading pace'**
  String get ramadanPrepQuran;

  /// Subtitle for the Qur'an-pace preparation card.
  ///
  /// In en, this message translates to:
  /// **'One juz a day finishes in 30'**
  String get ramadanPrepQuranSub;

  /// Preparation card: planning zakat.
  ///
  /// In en, this message translates to:
  /// **'Plan your zakat'**
  String get ramadanPrepZakat;

  /// Subtitle for the zakat preparation card.
  ///
  /// In en, this message translates to:
  /// **'Many give during Ramadan'**
  String get ramadanPrepZakatSub;

  /// Label for the current day of Ramadan. n: String — pre-formatted via LumeFormatting.integer for locale-aware digits.
  ///
  /// In en, this message translates to:
  /// **'Ramadan, day {n}'**
  String ramadanDay(String n);

  /// Countdown to iftar.
  ///
  /// In en, this message translates to:
  /// **'Iftar in {time}'**
  String ramadanIftarIn(String time);

  /// Stat label: when suhoor ends.
  ///
  /// In en, this message translates to:
  /// **'Suhoor ends'**
  String get ramadanSuhoor;

  /// Timeline title: when suhoor ends (distinct key from ramadanSuhoor).
  ///
  /// In en, this message translates to:
  /// **'Suhoor ends'**
  String get ramadanSuhoorEnds;

  /// Subtitle under the suhoor timeline entry.
  ///
  /// In en, this message translates to:
  /// **'Stop eating at Fajr'**
  String get ramadanSuhoorSub;

  /// Label for iftar.
  ///
  /// In en, this message translates to:
  /// **'Iftar'**
  String get ramadanIftar;

  /// Subtitle under the iftar timeline entry.
  ///
  /// In en, this message translates to:
  /// **'Break the fast at Maghrib'**
  String get ramadanIftarSub;

  /// Stat label: days remaining in Ramadan.
  ///
  /// In en, this message translates to:
  /// **'Days left'**
  String get ramadanRemaining;

  /// Label for today's entry on the Ramadan timeline.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get ramadanDayTimeline;

  /// Title of the honesty note above Ramadan dates.
  ///
  /// In en, this message translates to:
  /// **'A calculated estimate'**
  String get ramadanNoteTitle;

  /// Body of the honesty note above Ramadan dates.
  ///
  /// In en, this message translates to:
  /// **'Based on the Hijri calendar and today\'s Fajr and Maghrib — not a moon sighting. The actual date may differ by a day.'**
  String get ramadanNoteText;

  /// Empty state title when the selected city has no coordinates.
  ///
  /// In en, this message translates to:
  /// **'No position for {city}'**
  String ramadanNoCityTitle(String city);

  /// Empty state body when the selected city has no coordinates.
  ///
  /// In en, this message translates to:
  /// **'Ramadan times are worked out from a city\'s coordinates, and Lume has none for this one. Choose another city in Profile to see them.'**
  String get ramadanNoCityText;

  /// Empty state title when the time zone can't be resolved.
  ///
  /// In en, this message translates to:
  /// **'No clock for {zone}'**
  String ramadanNoZoneTitle(String zone);

  /// Empty state body when the time zone can't be resolved.
  ///
  /// In en, this message translates to:
  /// **'Ramadan times are worked out on your clock, so they need your time zone. Choose one in Profile › Time.'**
  String get ramadanNoZoneText;

  /// Prompt to choose a time zone, shown inline before times are available.
  ///
  /// In en, this message translates to:
  /// **'Ramadan times need your time zone to be worked out. Choose one in Profile › Time.'**
  String get ramadanZoneChooseText;

  /// Source line on the Ramadan share card.
  ///
  /// In en, this message translates to:
  /// **'{city} · {date}'**
  String ramadanShareSource(String city, String date);

  /// Toast for a conflicting record on write (mirrors praytrackErrConflict).
  ///
  /// In en, this message translates to:
  /// **'This changed somewhere else. Open it again.'**
  String get taraweehErrConflict;

  /// Generic write-failure toast (mirrors praytrackErrFailed).
  ///
  /// In en, this message translates to:
  /// **'That didn\'t save. Try again.'**
  String get taraweehErrFailed;

  /// Toast after marking tonight's Taraweeh as prayed.
  ///
  /// In en, this message translates to:
  /// **'Logged for tonight'**
  String get taraweehPrayedToast;

  /// Toast after clearing tonight's entry.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s entry removed'**
  String get taraweehClearedToast;

  /// Kicker label on the Taraweeh summary card.
  ///
  /// In en, this message translates to:
  /// **'Taraweeh streak'**
  String get taraweehSummaryKicker;

  /// Unit word for a count of nights.
  ///
  /// In en, this message translates to:
  /// **'nights'**
  String get taraweehNightsUnit;

  /// Caption showing the best-ever streak.
  ///
  /// In en, this message translates to:
  /// **'Best: {n} nights'**
  String taraweehBestCaption(int n);

  /// Stat label: total nights logged.
  ///
  /// In en, this message translates to:
  /// **'Nights logged'**
  String get taraweehStatTotal;

  /// Stat label: Juz of the Qur'an completed.
  ///
  /// In en, this message translates to:
  /// **'Juz completed'**
  String get taraweehStatJuz;

  /// Stat label: the next Juz to read.
  ///
  /// In en, this message translates to:
  /// **'Next Juz'**
  String get taraweehStatNextJuz;

  /// Label for tonight's entry.
  ///
  /// In en, this message translates to:
  /// **'Tonight'**
  String get taraweehTonight;

  /// Toggle/status label: Taraweeh prayed tonight.
  ///
  /// In en, this message translates to:
  /// **'Prayed tonight'**
  String get taraweehPrayedLabel;

  /// Field label: number of rakaat prayed.
  ///
  /// In en, this message translates to:
  /// **'Rakaat prayed'**
  String get taraweehRakaatTitle;

  /// Option label for a rakaat-count choice.
  ///
  /// In en, this message translates to:
  /// **'{n} rakaat'**
  String taraweehRakaatOption(int n);

  /// Field label: the Juz reached tonight.
  ///
  /// In en, this message translates to:
  /// **'Juz reached'**
  String get taraweehJuzTitle;

  /// Value shown when no Juz has been noted yet.
  ///
  /// In en, this message translates to:
  /// **'Not noted'**
  String get taraweehJuzValueNone;

  /// The Juz stepper's decrease action (mirrors tipFewer).
  ///
  /// In en, this message translates to:
  /// **'Fewer'**
  String get taraweehJuzDecrementLabel;

  /// The Juz stepper's increase action (mirrors tipMore).
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get taraweehJuzIncrementLabel;

  /// Section title over the Qur'an-completion progress.
  ///
  /// In en, this message translates to:
  /// **'Qur\'an progress'**
  String get taraweehProgressTitle;

  /// Progress label: Juz completed so far.
  ///
  /// In en, this message translates to:
  /// **'Juz completed'**
  String get taraweehProgressLabel;

  /// Progress value: Juz done out of total.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String taraweehProgressValue(int done, int total);

  /// Message shown once the Khatm (full Qur'an) is complete.
  ///
  /// In en, this message translates to:
  /// **'The whole Qur\'an has been completed this Ramadan'**
  String get taraweehKhatmComplete;

  /// Section title over the Taraweeh calendar grid.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get taraweehCalendarTitle;

  /// Screen-reader summary for the Taraweeh calendar grid.
  ///
  /// In en, this message translates to:
  /// **'{prayed} of the last {total} nights prayed'**
  String taraweehCalendarA11y(int prayed, int total);

  /// Section title over the user's saved vehicles.
  ///
  /// In en, this message translates to:
  /// **'Your vehicles'**
  String get vehicleFleet;

  /// Count of open fines on a vehicle.
  ///
  /// In en, this message translates to:
  /// **'{n} open fine'**
  String vehicleOpenFines(int n);

  /// Said when a vehicle has no outstanding fines.
  ///
  /// In en, this message translates to:
  /// **'No outstanding fines'**
  String get vehicleNoFines;

  /// Stat label: outstanding amount due.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get vehicleOutstanding;

  /// Stat label: next token-tax due date.
  ///
  /// In en, this message translates to:
  /// **'Next token due'**
  String get vehicleNextToken;

  /// Field label: the vehicle's odometer reading.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get vehicleOdometer;

  /// Search field placeholder for the saved vehicles list.
  ///
  /// In en, this message translates to:
  /// **'Search your vehicles'**
  String get vehicleSearch;

  /// Tag: a vehicle registered to the user.
  ///
  /// In en, this message translates to:
  /// **'Registered to you'**
  String get vehicleYours;

  /// Label: vehicle token (registration) tax.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get vehicleToken;

  /// Label: vehicle insurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get vehicleInsurance;

  /// Count of fines on a vehicle.
  ///
  /// In en, this message translates to:
  /// **'{n} fine'**
  String vehicleFines(int n);

  /// Status tag: no fines on record.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get vehicleClear;

  /// Section title/prompt for the registration lookup.
  ///
  /// In en, this message translates to:
  /// **'Check any registration'**
  String get vehicleCheck;

  /// Field label: vehicle registration number.
  ///
  /// In en, this message translates to:
  /// **'Registration number'**
  String get vehicleRegistration;

  /// Button that looks up a registration number.
  ///
  /// In en, this message translates to:
  /// **'Look up'**
  String get vehicleLookup;

  /// Status text while a lookup is in progress.
  ///
  /// In en, this message translates to:
  /// **'Checking the register'**
  String get vehicleLookingUp;

  /// Section title over upcoming vehicle reminders.
  ///
  /// In en, this message translates to:
  /// **'What\'s coming up'**
  String get vehicleReminders;

  /// Reminder type: token tax due.
  ///
  /// In en, this message translates to:
  /// **'Token tax due'**
  String get vehicleTokenTax;

  /// Reminder type: insurance renewal due.
  ///
  /// In en, this message translates to:
  /// **'Insurance renewal'**
  String get vehicleInsuranceRenewal;
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

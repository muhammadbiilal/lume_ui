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

  /// About, reference build only: the data is fixtures, and the claims elsewhere reproduce the reference
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

  /// Reference key calendar.adding — the toast the floating action speaks
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get calendarAdding;

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

  /// What a screen reader says for the "Sample data" mark at the head of a tool's source line, in development and reference builds (F6B closure)
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

  /// Reference key fresh.annual
  ///
  /// In en, this message translates to:
  /// **'Current tax year'**
  String get freshAnnual;

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

  /// A release build’s word for data held only for the session; replaces "Stored on this device" without a durable store
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

  /// Reference key subs.renews
  ///
  /// In en, this message translates to:
  /// **'renews {date}'**
  String subsRenews(String date);

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

  /// Reference key tool.related — the related-tools section head
  ///
  /// In en, this message translates to:
  /// **'Related tools'**
  String get toolRelated;

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
  /// **'{code} is no longer issued. Choose a current currency.'**
  String ledgerErrWithdrawn(String code);

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

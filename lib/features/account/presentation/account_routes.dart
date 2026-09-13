/// The twenty-one account routes.
///
/// `ui/account-ui.js`'s `ROUTES`, one function each, in its declaration order.
/// Every one of them returns a [LumeAccountView] rather than a screen: the
/// host owns the header, the back stack and the unsaved-changes guard, and a
/// route decides only what is in it.
///
/// ### What is not here
///
/// No route reaches a repository. Everything a route needs is on
/// [LumeAccountRouteContext], which the host fills in — which is what lets a
/// test render any of the twenty-one in any state without a store, and what
/// keeps the gate in one place.
///
/// ### The gate
///
/// Seven of them need an account: `account`, `email`, `phone`, `security`,
/// `password`, `sessions` and `delete`. The host asks before it builds, and
/// [signedOutView] is what a guest who reaches one anyway is shown — the same
/// refusal whether they arrived by row, by link or by an expiry while the
/// screen was open.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icon.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_settings.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/password_policy.dart';
import '../../auth/presentation/auth_parts.dart';
import '../../onboarding/domain/onboarding_state.dart';
import '../application/account_form.dart';
import '../domain/account_model.dart';
import '../domain/notification_prefs.dart';
import 'account_parts.dart';

/// Everything the twenty-one routes read, and everything they can ask for.
@immutable
class LumeAccountRouteContext {
  const LumeAccountRouteContext({
    required this.l,
    required this.f,
    required this.form,
    required this.profile,
    required this.state,
    required this.notify,
    required this.themeMode,
    required this.language,
    required this.countryName,
    required this.regionValue,
    required this.homeCurrency,
    required this.homeZone,
    required this.zones,
    required this.version,
    required this.favourites,
    required this.recents,
    required this.sessions,
    required this.stored,
    required this.actions,
    this.identity,
  });

  final AppLocalizations l;
  final LumeFormatting f;
  final LumeAccountForm form;

  final LumeProfileRecord profile;
  final LumeAccountState state;
  final LumeAccountIdentity? identity;
  final LumeNotificationPrefs notify;
  final ThemeMode themeMode;

  /// The reading language's own name.
  final String language;

  /// The reader's country, named in the reading language.
  final String countryName;

  /// `regionValue()` — country, city and currency.
  final String regionValue;

  /// The currency the reader's market uses, for the "follow my region" row.
  final String homeCurrency;

  /// The zone the reader's region implies, and the zones near it.
  final String homeZone;
  final List<String> zones;

  final String version;

  /// Saved tools and recently opened ones, already named.
  final List<LumeLibraryEntry> favourites;
  final List<LumeLibraryEntry> recents;

  final List<LumeDeviceSession> sessions;
  final LumeStoredData stored;

  final LumeAccountActions actions;

  bool get isAuthed => state == LumeAccountState.authed;
}

/// One saved or recent tool, as the library route draws it.
@immutable
class LumeLibraryEntry {
  const LumeLibraryEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
  });

  final String id;
  final String name;
  final String category;
  final String icon;
}

/// What a route can ask the host to do.
@immutable
class LumeAccountActions {
  const LumeAccountActions({
    required this.open,
    required this.openTool,
    required this.setLanguage,
    required this.setCurrency,
    required this.setUnits,
    required this.setClock,
    required this.setZone,
    required this.setTheme,
    required this.toggleCategory,
    required this.togglePreview,
    required this.toggleSensitivePreview,
    required this.toggleRecommendations,
    required this.editLocation,
    required this.submit,
    required this.signIn,
    required this.startTour,
    required this.sendFeedback,
    required this.pickPhoto,
    required this.clearPhoto,
    required this.clearPhone,
    required this.cancelEmailChange,
    required this.revoke,
    required this.signOutOthers,
    required this.leaveField,
  });

  final void Function(LumeAccountRoute route) open;
  final void Function(String featureId) openTool;

  final void Function(String code) setLanguage;
  final void Function(String code) setCurrency;
  final void Function(LumeUnitsPreference units) setUnits;
  final void Function(String clock) setClock;
  final void Function(String? zone) setZone;
  final void Function(ThemeMode mode) setTheme;

  final void Function(String categoryId, bool on) toggleCategory;
  final void Function(bool on) togglePreview;
  final void Function(bool on) toggleSensitivePreview;
  final void Function(bool on) toggleRecommendations;

  /// The location picker — country, then city.
  final VoidCallback editLocation;

  /// Send a form. The host knows which one from the route it is on.
  final VoidCallback submit;

  final VoidCallback signIn;
  final VoidCallback startTour;
  final VoidCallback sendFeedback;

  final VoidCallback pickPhoto;
  final VoidCallback clearPhoto;
  final VoidCallback clearPhone;
  final VoidCallback cancelEmailChange;

  final void Function(String sessionId) revoke;
  final VoidCallback signOutOthers;

  /// Blur on a field, so the route's own check can run.
  final void Function(String name) leaveField;
}

/// Build one route.
///
/// A `switch` over the enum rather than a map, so adding a value without a
/// body is a compile error rather than a blank screen.
LumeAccountView buildAccountRoute(
  LumeAccountRoute route,
  LumeAccountRouteContext c,
) => switch (route) {
  LumeAccountRoute.prefs => _prefs(c),
  LumeAccountRoute.language => _language(c),
  LumeAccountRoute.region => _region(c),
  LumeAccountRoute.currency => _currency(c),
  LumeAccountRoute.units => _units(c),
  LumeAccountRoute.time => _time(c),
  LumeAccountRoute.appearance => _appearance(c),
  LumeAccountRoute.notifications => _notifications(c),
  LumeAccountRoute.library => _library(c),
  LumeAccountRoute.account => _account(c),
  LumeAccountRoute.edit => _edit(c),
  LumeAccountRoute.email => _email(c),
  LumeAccountRoute.phone => _phone(c),
  LumeAccountRoute.security => _security(c),
  LumeAccountRoute.password => _password(c),
  LumeAccountRoute.sessions => _sessions(c),
  LumeAccountRoute.privacy => _privacy(c),
  LumeAccountRoute.sync => _sync(c),
  LumeAccountRoute.help => _help(c),
  LumeAccountRoute.about => _about(c),
  LumeAccountRoute.delete => _delete(c),
};

/// What a protected route shows to somebody without an account.
///
/// The same refusal however they arrived — a row, a link, or a session that
/// ran out while the screen was open — with a way forward rather than a dead
/// end.
LumeAccountView signedOutView(LumeAccountRouteContext c, String title) =>
    LumeAccountView(
      title: title,
      body: (BuildContext context) => <Widget>[
        LumeAccountSection(
          child: LumeToolState(
            icon: LumeIcons.lock,
            title: c.l.authErrSignedOut,
            text: c.l.authNeedAccountText,
            action: LumeButton.accent(
              label: c.l.authSignIn,
              icon: LumeIcons.login,
              onPressed: c.actions.signIn,
            ),
          ),
        ),
      ],
    );

// ------------------------------------------------------------- preferences

LumeAccountView _prefs(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  return LumeAccountView(
    title: l.acctPrefsTitle,
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: LumeAccountList(
          rows: <Widget>[
            LumeSettingsRow(
              icon: LumeIcons.globe,
              title: l.acctLanguageTitle,
              value: c.language,
              onTap: () => c.actions.open(LumeAccountRoute.language),
            ),
            LumeSettingsRow(
              icon: LumeIcons.pin,
              title: l.acctRegionTitle,
              value: c.regionValue,
              onTap: () => c.actions.open(LumeAccountRoute.region),
            ),
            LumeSettingsRow(
              icon: LumeIcons.currency,
              title: l.acctCurrencyTitle,
              value: c.profile.currency == LumePreference.auto
                  ? l.persCurrencyAuto(c.f.currency)
                  : c.profile.currency,
              onTap: () => c.actions.open(LumeAccountRoute.currency),
            ),
            LumeSettingsRow(
              icon: LumeIcons.ruler,
              title: l.acctUnitsTitle,
              value: _unitsLabel(l, c.profile.units),
              onTap: () => c.actions.open(LumeAccountRoute.units),
            ),
            LumeSettingsRow(
              icon: LumeIcons.clock,
              title: l.acctTimezoneTitle,
              value: _clockLabel(l, c.profile.clock),
              onTap: () => c.actions.open(LumeAccountRoute.time),
            ),
            LumeSettingsRow(
              icon: c.themeMode == ThemeMode.dark
                  ? LumeIcons.moon
                  : LumeIcons.sun,
              title: l.acctAppearanceTitle,
              value: _themeLabel(l, c.themeMode),
              onTap: () => c.actions.open(LumeAccountRoute.appearance),
            ),
            LumeSettingsRow(
              icon: LumeIcons.bellRing,
              title: l.navNotifications,
              value: _notifValue(c),
              onTap: () => c.actions.open(LumeAccountRoute.notifications),
              isLast: true,
            ),
          ],
        ),
      ),
    ],
  );
}

String _unitsLabel(AppLocalizations l, LumeUnitsPreference units) =>
    switch (units) {
      LumeUnitsPreference.auto => l.persUnitsAuto,
      LumeUnitsPreference.metric => l.persUnitsMetric,
      LumeUnitsPreference.imperial => l.persUnitsImperial,
    };

String _clockLabel(AppLocalizations l, String clock) => switch (clock) {
  '12' => l.persTime12,
  '24' => l.persTime24,
  _ => l.persUnitsAuto,
};

String _themeLabel(AppLocalizations l, ThemeMode mode) => switch (mode) {
  ThemeMode.light => l.acctAppearanceLight,
  ThemeMode.dark => l.acctAppearanceDark,
  ThemeMode.system => l.acctAppearanceSystem,
};

String _notifValue(LumeAccountRouteContext c) {
  final bool islamic = c.profile.islamic ?? false;
  final int total = LumeNotificationPrefs.visible(islamic: islamic).length;
  return c.l.acctCatsOn(total, c.notify.onCount(islamic: islamic));
}

LumeAccountView _language(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  return LumeAccountView(
    title: l.acctLanguageTitle,
    subtitle: l.acctLanguageNote,
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: LumeOptionList(
          label: l.acctLanguageTitle,
          children: <LumeOptionRow>[
            for (final LumeLanguageChoice choice in kLanguageChoices)
              LumeOptionRow(
                title: choice.native,
                subtitle: choice.code == 'en' ? choice.english : null,
                selected: choice.code == c.languageCode,
                onTap: () => c.actions.setLanguage(choice.code),
              ),
          ],
        ),
      ),
      LumeAccountSection(
        tight: true,
        child: LumeNoteCard(
          icon: LumeIcons.info,
          title: l.acctLanguageTitle,
          text: l.acctLanguageNote,
        ),
      ),
    ],
  );
}

LumeAccountView _region(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  return LumeAccountView(
    title: l.acctRegionTitle,
    subtitle: c.regionValue,
    body: (BuildContext context) => <Widget>[
      // Say what changing this changes, at the point of change.
      LumeAccountSection(
        child: LumeNoteCard(
          icon: LumeIcons.alert,
          tone: LumeNoteTone.warn,
          title: l.acctRegionTitle,
          text: l.acctRegionWarn,
        ),
      ),
      LumeAccountSection(
        tight: true,
        child: LumeAccountList(
          rows: <Widget>[
            LumeSettingsRow(
              icon: LumeIcons.globe,
              title: l.persCountry,
              value: c.countryName,
              onTap: c.actions.editLocation,
            ),
            LumeSettingsRow(
              icon: LumeIcons.pin,
              title: l.persCity,
              value: c.profile.city,
              notSetLabel: l.actionNotSet,
              onTap: c.actions.editLocation,
            ),
            LumeSettingsRow(
              icon: LumeIcons.currency,
              title: l.acctCurrencyTitle,
              value: c.f.currency,
              onTap: () => c.actions.open(LumeAccountRoute.currency),
              isLast: true,
            ),
          ],
        ),
      ),
      LumeAccountSection(
        tight: true,
        child: LumeButton.accent(
          label: l.acctRegionChange,
          icon: LumeIcons.globe,
          block: true,
          onPressed: c.actions.editLocation,
        ),
      ),
    ],
  );
}

LumeAccountView _currency(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  // The reader's own market first, then the currencies the product quotes.
  final List<String> codes = <String>[
    LumePreference.auto,
    if (c.homeCurrency.isNotEmpty) c.homeCurrency,
    'USD',
    'EUR',
    'GBP',
    'AED',
    'SAR',
    'INR',
    'JPY',
  ].toSet().toList(growable: false);

  return LumeAccountView(
    title: l.acctCurrencyTitle,
    subtitle: l.acctCurrencyNote,
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: LumeOptionList(
          label: l.acctCurrencyTitle,
          children: <LumeOptionRow>[
            for (final String code in codes)
              LumeOptionRow(
                title: code == LumePreference.auto ? l.acctCurrencyAuto : code,
                subtitle: code == LumePreference.auto
                    ? l.persCurrencyAuto(
                        c.homeCurrency.isEmpty ? c.f.currency : c.homeCurrency,
                      )
                    : null,
                selected: c.profile.currency == code,
                onTap: () => c.actions.setCurrency(code),
              ),
          ],
        ),
      ),
    ],
  );
}

LumeAccountView _units(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  return LumeAccountView(
    title: l.acctUnitsTitle,
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: LumeOptionList(
          label: l.acctUnitsTitle,
          children: <LumeOptionRow>[
            LumeOptionRow(
              title: l.acctUnitsAuto,
              subtitle: l.persUnitsAuto,
              selected: c.profile.units == LumeUnitsPreference.auto,
              onTap: () => c.actions.setUnits(LumeUnitsPreference.auto),
            ),
            LumeOptionRow(
              title: l.acctUnitsMetric,
              subtitle: 'km · °C · kg',
              selected: c.profile.units == LumeUnitsPreference.metric,
              onTap: () => c.actions.setUnits(LumeUnitsPreference.metric),
            ),
            LumeOptionRow(
              title: l.acctUnitsImperial,
              subtitle: 'mi · °F · lb',
              selected: c.profile.units == LumeUnitsPreference.imperial,
              onTap: () => c.actions.setUnits(LumeUnitsPreference.imperial),
            ),
          ],
        ),
      ),
    ],
  );
}

LumeAccountView _time(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  return LumeAccountView(
    title: l.acctTimeTitle,
    subtitle: c.profile.timeZone ?? c.homeZone,
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        title: l.acctClockFormat,
        child: LumeOptionList(
          label: l.acctClockFormat,
          children: <LumeOptionRow>[
            LumeOptionRow(
              title: l.acctTimezoneAuto,
              selected: c.profile.clock == LumePreference.auto,
              onTap: () => c.actions.setClock(LumePreference.auto),
            ),
            LumeOptionRow(
              title: l.acctClock12,
              selected: c.profile.clock == '12',
              onTap: () => c.actions.setClock('12'),
            ),
            LumeOptionRow(
              title: l.acctClock24,
              selected: c.profile.clock == '24',
              onTap: () => c.actions.setClock('24'),
            ),
          ],
        ),
      ),
      LumeAccountSection(
        title: l.acctTimezoneTitle,
        child: LumeOptionList(
          label: l.acctTimezoneTitle,
          children: <LumeOptionRow>[
            LumeOptionRow(
              title: l.acctTimezoneFollowRegion,
              subtitle: c.homeZone,
              selected: c.profile.timeZone == null,
              onTap: () => c.actions.setZone(null),
            ),
            for (final String zone in c.zones)
              LumeOptionRow(
                title: zone.split('/').skip(1).join(' · ').replaceAll('_', ' '),
                subtitle: zone,
                selected: c.profile.timeZone == zone,
                onTap: () => c.actions.setZone(zone),
              ),
          ],
        ),
      ),
      LumeAccountSection(
        tight: true,
        child: LumeNoteCard(
          icon: LumeIcons.info,
          title: l.acctTimezoneTitle,
          text: l.acctTimezoneNote,
        ),
      ),
    ],
  );
}

LumeAccountView _appearance(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  return LumeAccountView(
    title: l.acctAppearanceTitle,
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: LumeOptionList(
          label: l.acctAppearanceTitle,
          children: <LumeOptionRow>[
            LumeOptionRow(
              title: l.acctAppearanceSystem,
              selected: c.themeMode == ThemeMode.system,
              onTap: () => c.actions.setTheme(ThemeMode.system),
            ),
            LumeOptionRow(
              title: l.acctAppearanceLight,
              selected: c.themeMode == ThemeMode.light,
              onTap: () => c.actions.setTheme(ThemeMode.light),
            ),
            LumeOptionRow(
              title: l.acctAppearanceDark,
              selected: c.themeMode == ThemeMode.dark,
              onTap: () => c.actions.setTheme(ThemeMode.dark),
            ),
          ],
        ),
      ),
    ],
  );
}

/// One preference store, two doors.
///
/// The switches are the notification centre's own; this is the other door
/// onto them. There is no engine behind them in this build, and the note says
/// so rather than letting the screen imply one.
LumeAccountView _notifications(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  final bool islamic = c.profile.islamic ?? false;
  final List<LumeNotificationCategory> cats = LumeNotificationPrefs.visible(
    islamic: islamic,
  );

  return LumeAccountView(
    title: l.navNotifications,
    subtitle: c.notify.push ? l.acctPushOn : l.acctPushOff,
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: LumeAccountList(
          rows: <Widget>[
            for (int i = 0; i < cats.length; i++)
              LumeSettingsRow(
                icon: cats[i].icon,
                title: _categoryLabel(l, cats[i].id),
                toggle: c.notify.isOn(cats[i].id),
                onTap: () => c.actions.toggleCategory(
                  cats[i].id,
                  !c.notify.isOn(cats[i].id),
                ),
                isLast: i == cats.length - 1,
              ),
          ],
        ),
      ),
      LumeAccountSection(
        tight: true,
        child: LumeAccountList(
          rows: <Widget>[
            LumeSettingsRow(
              icon: LumeIcons.eye,
              title: l.acctPrivacyPreview,
              subtitle: l.acctPrivacyPreviewSub,
              toggle: c.notify.preview,
              onTap: () => c.actions.togglePreview(!c.notify.preview),
            ),
            LumeSettingsRow(
              icon: LumeIcons.lock,
              title: l.acctPrivacySensitive,
              subtitle: l.acctPrivacySensitiveSub,
              // Inverted on purpose: the switch asks whether sensitive
              // content stays *hidden*, which is the promise being made.
              toggle: !c.notify.sensitivePreview,
              onTap: () =>
                  c.actions.toggleSensitivePreview(c.notify.sensitivePreview),
              isLast: true,
            ),
          ],
        ),
      ),
      if (!c.isAuthed)
        LumeAccountSection(
          tight: true,
          child: LumeNoteCard(
            icon: LumeIcons.info,
            title: l.acctGuestNotifTitle,
            text: l.acctGuestNotifText,
          ),
        ),
    ],
  );
}

String _categoryLabel(AppLocalizations l, String id) => switch (id) {
  'faith' => l.ncatFaith,
  'finance' => l.ncatFinance,
  'markets' => l.ncatMarkets,
  'travel' => l.ncatTravel,
  'weather' => l.ncatWeather,
  'news' => l.ncatNews,
  'personal' => l.ncatPersonal,
  'reminders' => l.ncatReminders,
  'documents' => l.ncatDocuments,
  'health' => l.ncatHealth,
  _ => l.ncatSystem,
};

LumeAccountView _library(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  return LumeAccountView(
    title: l.acctRowLibrary,
    subtitle: l.acctRowLibrarySub,
    body: (BuildContext context) => <Widget>[
      if (c.favourites.isEmpty)
        LumeAccountSection(
          child: LumeToolState(
            icon: LumeIcons.bookmark,
            title: l.acctNoFavourites,
            text: l.acctNoFavouritesText,
          ),
        )
      else
        LumeAccountSection(
          child: LumeAccountList(
            rows: <Widget>[
              for (int i = 0; i < c.favourites.length; i++)
                LumeSettingsRow(
                  icon: c.favourites[i].icon,
                  title: c.favourites[i].name,
                  subtitle: c.favourites[i].category,
                  onTap: () => c.actions.openTool(c.favourites[i].id),
                  isLast: i == c.favourites.length - 1,
                ),
            ],
          ),
        ),
      if (c.recents.isNotEmpty)
        LumeAccountSection(
          child: LumeAccountList(
            rows: <Widget>[
              for (int i = 0; i < c.recents.length; i++)
                LumeSettingsRow(
                  icon: c.recents[i].icon,
                  title: c.recents[i].name,
                  onTap: () => c.actions.openTool(c.recents[i].id),
                  isLast: i == c.recents.length - 1,
                ),
            ],
          ),
        ),
    ],
  );
}

/// The languages the picker offers.
@immutable
class LumeLanguageChoice {
  const LumeLanguageChoice(this.code, this.native, this.english);

  final String code;
  final String native;
  final String english;
}

const List<LumeLanguageChoice> kLanguageChoices = <LumeLanguageChoice>[
  LumeLanguageChoice('en', 'English', 'English'),
  LumeLanguageChoice('ur', 'اردو', 'Urdu'),
  LumeLanguageChoice('ar', 'العربية', 'Arabic'),
];

extension on LumeAccountRouteContext {
  /// The reading language's code, recovered from its own name.
  String get languageCode => kLanguageChoices
      .firstWhere(
        (LumeLanguageChoice x) => x.native == language,
        orElse: () => kLanguageChoices.first,
      )
      .code;
}

// ------------------------------------------------------------------ account

LumeAccountView _account(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  final LumeAccountIdentity? u = c.isAuthed ? c.identity : null;
  if (u == null) return signedOutView(c, l.acctPersonalTitle);

  return LumeAccountView(
    title: l.acctPersonalTitle,
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: LumeAccountList(
          rows: <Widget>[
            LumeSettingsRow(
              icon: LumeIcons.user,
              title: l.acctFieldDisplayName,
              value: u.displayName,
              notSetLabel: l.actionNotSet,
              onTap: () => c.actions.open(LumeAccountRoute.edit),
            ),
            LumeSettingsRow(
              icon: LumeIcons.mail,
              title: l.acctEmailTitle,
              value: u.email,
              onTap: () => c.actions.open(LumeAccountRoute.email),
            ),
            LumeSettingsRow(
              icon: LumeIcons.phone,
              title: l.acctPhoneTitle,
              value: u.phone,
              notSetLabel: l.actionNotSet,
              onTap: () => c.actions.open(LumeAccountRoute.phone),
            ),
            LumeSettingsRow(
              icon: LumeIcons.pin,
              title: l.acctRegionTitle,
              value: c.regionValue,
              onTap: () => c.actions.open(LumeAccountRoute.region),
            ),
            // Two rows that lead nowhere on purpose: a status and a date are
            // facts, not settings, and a chevron would promise a screen.
            LumeSettingsRow(
              icon: LumeIcons.checkCircle,
              title: l.acctStatus,
              value: u.status == LumeAccountStatus.locked
                  ? l.acctStatusLocked
                  : l.acctStatusActive,
              chevron: false,
            ),
            LumeSettingsRow(
              icon: LumeIcons.calendar,
              title: l.acctSince,
              value: c.f.dateLongYear(u.createdAt),
              chevron: false,
              isLast: true,
            ),
          ],
        ),
      ),
      if (u.pendingEmail != null && u.pendingEmail!.isNotEmpty)
        LumeAccountSection(
          tight: true,
          child: LumeNoteCard(
            icon: LumeIcons.mail,
            tone: LumeNoteTone.warn,
            title: l.acctEmailPending,
            text: l.acctEmailPendingText(u.pendingEmail!),
          ),
        ),
      // Its own block, its own tone, never adjacent to a routine row.
      LumeAccountSection(
        child: LumeDangerZone(
          label: l.acctDangerZone,
          text: l.acctDeleteRowSub,
          child: LumeButton.dangerGhost(
            label: l.acctDeleteRow,
            icon: LumeIcons.trash,
            block: true,
            onPressed: () => c.actions.open(LumeAccountRoute.delete),
          ),
        ),
      ),
    ],
  );
}

/// The one form a guest may open.
///
/// §124.4 promised the onboarding name could be changed later, and the only
/// screen that changes it required an account — so a guest who gave a name
/// could never edit or remove it. The form is the same; a guest simply has
/// fewer fields, because a guest has fewer things.
LumeAccountView _edit(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  final LumeAccountIdentity? u = c.isAuthed ? c.identity : null;
  final bool guest = u == null;
  final String photo = u?.photo ?? c.profile.photo;

  return LumeAccountView(
    title: l.acctEditTitle,
    initialValues: guest
        ? <String, String>{'displayName': c.profile.displayName}
        : <String, String>{
            'displayName': u.displayName,
            'firstName': u.firstName,
            'lastName': u.lastName,
            'phone': u.phone,
          },
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: LumeCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              LumeProfileAvatar(
                photo: photo,
                initials: u?.initials ?? '',
                small: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l.acctPhoto,
                      style: LumeInputField.labelStyle(context),
                    ),
                    Text(
                      l.acctPhotoNote,
                      style: LumeInputField.captionStyle(context),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        LumeButton(
                          label: photo.isEmpty
                              ? l.acctPhotoAdd
                              : l.acctPhotoReplace,
                          icon: LumeIcons.camera,
                          small: true,
                          onPressed: c.actions.pickPhoto,
                        ),
                        if (photo.isNotEmpty)
                          LumeButton(
                            label: l.acctPhotoRemove,
                            icon: LumeIcons.trash,
                            small: true,
                            onPressed: c.actions.clearPhoto,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      LumeAccountSection(
        tight: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LumeAccountFields(
              children: <Widget>[
                LumeAccountField(
                  form: c.form,
                  name: 'displayName',
                  label: l.acctFieldDisplayName,
                  hint: l.acctNameNote,
                  maxLength: 40,
                  error: (LumeFormIssue i) => accountMessage(l, i),
                  onLeave: c.actions.leaveField,
                ),
                if (!guest) ...<Widget>[
                  LumeAccountField(
                    form: c.form,
                    name: 'firstName',
                    label: l.acctFieldFirst,
                    optionalLabel: l.commonOptional,
                    error: (LumeFormIssue i) => accountMessage(l, i),
                    onLeave: c.actions.leaveField,
                  ),
                  LumeAccountField(
                    form: c.form,
                    name: 'lastName',
                    label: l.acctFieldLast,
                    optionalLabel: l.commonOptional,
                    error: (LumeFormIssue i) => accountMessage(l, i),
                    onLeave: c.actions.leaveField,
                  ),
                  LumeAccountField(
                    form: c.form,
                    name: 'phone',
                    label: l.acctFieldPhone,
                    optionalLabel: l.commonOptional,
                    hint: l.acctPhoneNote,
                    keyboardType: TextInputType.phone,
                    error: (LumeFormIssue i) => accountMessage(l, i),
                    onLeave: c.actions.leaveField,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            LumeButton.accent(
              label: l.acctSaveChanges,
              block: true,
              busy: c.form.busy,
              onPressed: c.form.dirty && !c.form.busy ? c.actions.submit : null,
            ),
            const SizedBox(height: 8),
            if (!c.form.dirty)
              Text(
                l.acctNothingChanged,
                textAlign: TextAlign.center,
                style: LumeInputField.captionStyle(context),
              ),
          ],
        ),
      ),
      LumeAccountSection(
        tight: true,
        child: LumeAccountList(
          rows: <Widget>[
            if (!guest)
              LumeSettingsRow(
                icon: LumeIcons.mail,
                title: l.acctEmailTitle,
                value: u.email,
                onTap: () => c.actions.open(LumeAccountRoute.email),
              ),
            // Country and region belong on this screen, but they are chosen
            // in the location picker rather than typed, so the row leads
            // there instead of duplicating it.
            LumeSettingsRow(
              icon: LumeIcons.globe,
              title: l.persCountry,
              value: c.countryName,
              onTap: () => c.actions.open(LumeAccountRoute.region),
            ),
            LumeSettingsRow(
              icon: LumeIcons.pin,
              title: c.profile.region.isNotEmpty ? l.persRegion : l.persCity,
              value: c.profile.region.isNotEmpty
                  ? c.profile.region
                  : c.profile.city,
              notSetLabel: l.actionNotSet,
              onTap: () => c.actions.open(LumeAccountRoute.region),
              isLast: true,
            ),
          ],
        ),
      ),
      if (guest)
        LumeAccountSection(
          tight: true,
          child: LumeNoteCard(
            icon: LumeIcons.info,
            title: l.acctGuestBadge,
            text: l.acctGuestEditNote,
          ),
        ),
    ],
  );
}

LumeAccountView _email(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  final LumeAccountIdentity? u = c.isAuthed ? c.identity : null;
  if (u == null) return signedOutView(c, l.acctEmailTitle);
  final String pending = u.pendingEmail ?? '';

  return LumeAccountView(
    title: l.acctEmailTitle,
    subtitle: u.email,
    initialValues: const <String, String>{'email': ''},
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: LumeAccountList(
          rows: <Widget>[
            LumeSettingsRow(
              icon: LumeIcons.mail,
              title: l.acctEmailTitle,
              value: u.email,
              chevron: false,
              isLast: true,
            ),
          ],
        ),
      ),
      if (pending.isNotEmpty)
        LumeAccountSection(
          tight: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LumeNoteCard(
                icon: LumeIcons.mail,
                tone: LumeNoteTone.warn,
                title: l.acctEmailPending,
                text: l.acctEmailPendingText(pending),
              ),
              const SizedBox(height: 12),
              LumeButton(
                label: l.actionCancel,
                block: true,
                onPressed: c.actions.cancelEmailChange,
              ),
            ],
          ),
        )
      else
        LumeAccountSection(
          tight: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LumeAccountField(
                form: c.form,
                name: 'email',
                label: l.acctFieldNewEmail,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                error: (LumeFormIssue i) => accountMessage(l, i),
                onLeave: c.actions.leaveField,
                onSubmitted: c.actions.submit,
              ),
              const SizedBox(height: 16),
              LumeButton.accent(
                label: l.actionChange,
                block: true,
                busy: c.form.busy,
                onPressed: c.form.busy ? null : c.actions.submit,
              ),
            ],
          ),
        ),
    ],
  );
}

LumeAccountView _phone(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  final LumeAccountIdentity? u = c.isAuthed ? c.identity : null;
  if (u == null) return signedOutView(c, l.acctPhoneTitle);

  return LumeAccountView(
    title: l.acctPhoneTitle,
    initialValues: <String, String>{'phone': u.phone},
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LumeAccountField(
              form: c.form,
              name: 'phone',
              label: l.acctFieldPhone,
              hint: l.acctPhoneNote,
              keyboardType: TextInputType.phone,
              autofillHints: const <String>[AutofillHints.telephoneNumber],
              error: (LumeFormIssue i) => accountMessage(l, i),
              onLeave: c.actions.leaveField,
              onSubmitted: c.actions.submit,
            ),
            const SizedBox(height: 14),
            // What it is for, said plainly: Lume has no phone sign-in and no
            // phone recovery, so the number does nothing else.
            LumeNoteCard(
              icon: LumeIcons.info,
              title: l.acctPhoneScope,
              text: l.acctPhoneScopeText,
            ),
            const SizedBox(height: 16),
            LumeButton.accent(
              label: l.actionSave,
              block: true,
              busy: c.form.busy,
              onPressed: c.form.busy ? null : c.actions.submit,
            ),
            if (u.phone.isNotEmpty) ...<Widget>[
              const SizedBox(height: 9),
              LumeButton(
                label: l.actionRemove,
                block: true,
                onPressed: c.form.busy ? null : c.actions.clearPhone,
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

// ----------------------------------------------------------------- security

/// What is here is what exists.
///
/// There is no two-factor switch, no biometric unlock and no sign-in alerting
/// in this build, so there are no rows for them: a row reading "Off" for
/// something that was never built still advertises it.
LumeAccountView _security(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  if (!c.isAuthed) return signedOutView(c, l.acctSecurityTitle);

  return LumeAccountView(
    title: l.acctSecurityTitle,
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: LumeAccountList(
          rows: <Widget>[
            LumeSettingsRow(
              icon: LumeIcons.key,
              accent: true,
              title: l.acctChangePassword,
              subtitle: l.acctChangePasswordSub,
              onTap: () => c.actions.open(LumeAccountRoute.password),
            ),
            LumeSettingsRow(
              icon: LumeIcons.device,
              title: l.acctSessionsTitle,
              subtitle: l.acctSessionsSub(c.sessions.length),
              onTap: () => c.actions.open(LumeAccountRoute.sessions),
              isLast: true,
            ),
          ],
        ),
      ),
      LumeAccountSection(
        tight: true,
        child: LumeNoteCard(
          icon: LumeIcons.shield,
          title: l.acctSecurityScope,
          text: l.acctSecurityScopeText,
        ),
      ),
      LumeAccountSection(
        tight: true,
        child: LumeButton(
          label: l.acctSignOutOthers,
          icon: LumeIcons.logout,
          block: true,
          onPressed: c.actions.signOutOthers,
        ),
      ),
    ],
  );
}

LumeAccountView _password(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  if (!c.isAuthed) return signedOutView(c, l.acctChangePassword);

  return LumeAccountView(
    title: l.acctChangePassword,
    initialValues: const <String, String>{
      'current': '',
      'password': '',
      'confirm': '',
    },
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LumeAccountField(
              form: c.form,
              name: 'current',
              label: l.acctFieldCurrent,
              obscure: true,
              revealShowLabel: l.authShowPassword,
              revealHideLabel: l.authHidePassword,
              autofillHints: const <String>[AutofillHints.password],
              error: (LumeFormIssue i) => accountMessage(l, i),
              onLeave: c.actions.leaveField,
            ),
            const SizedBox(height: 14),
            LumeAccountField(
              form: c.form,
              name: 'password',
              label: l.authFieldNewPassword,
              obscure: true,
              revealShowLabel: l.authShowPassword,
              revealHideLabel: l.authHidePassword,
              autofillHints: const <String>[AutofillHints.newPassword],
              error: (LumeFormIssue i) => accountMessage(l, i),
              onLeave: c.actions.leaveField,
            ),
            const SizedBox(height: 10),
            LumePasswordMeter(
              strength: LumePasswordPolicy.strength(c.form.read('password')),
              label: _strengthWord(
                l,
                LumePasswordPolicy.strength(c.form.read('password')),
              ),
            ),
            const SizedBox(height: 10),
            LumePasswordRules(
              title: l.authPasswordRulesTitle,
              checks: LumePasswordPolicy.checks(c.form.read('password')),
              labelFor: (LumePasswordRule rule) => _ruleLabel(l, rule),
            ),
            const SizedBox(height: 14),
            LumeAccountField(
              form: c.form,
              name: 'confirm',
              label: l.acctFieldConfirmNew,
              obscure: true,
              revealShowLabel: l.authShowPassword,
              revealHideLabel: l.authHidePassword,
              autofillHints: const <String>[AutofillHints.newPassword],
              error: (LumeFormIssue i) => accountMessage(l, i),
              onLeave: c.actions.leaveField,
              onSubmitted: c.actions.submit,
            ),
            const SizedBox(height: 18),
            LumeButton.accent(
              label: l.authResetCta,
              block: true,
              busy: c.form.busy,
              onPressed: c.form.busy ? null : c.actions.submit,
            ),
          ],
        ),
      ),
    ],
  );
}

LumeAccountView _sessions(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  if (!c.isAuthed) return signedOutView(c, l.acctSessionsTitle);

  return LumeAccountView(
    title: l.acctSessionsTitle,
    subtitle: l.acctSessionsSub(c.sessions.length),
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: LumeAccountList(
          rows: <Widget>[
            for (int i = 0; i < c.sessions.length; i++)
              LumeSessionRow(
                label: c.sessions[i].label,
                // Composed here so the date and the time are the reader's.
                detail: _sessionDetail(c, c.sessions[i]),
                semanticLabel: <String>[
                  c.sessions[i].label,
                  if (c.sessions[i].isCurrent) l.acctThisDevice,
                  _sessionDetail(c, c.sessions[i]),
                ].join(', '),
                thisDeviceLabel: c.sessions[i].isCurrent
                    ? l.acctThisDevice
                    : null,
                signOutLabel: l.acctSignOutDevice,
                onSignOut: c.sessions[i].isCurrent
                    ? null
                    : () => c.actions.revoke(c.sessions[i].id),
                isLast: i == c.sessions.length - 1,
              ),
          ],
        ),
      ),
      if (c.sessions.length > 1)
        LumeAccountSection(
          tight: true,
          child: LumeButton(
            label: l.acctSignOutOthers,
            icon: LumeIcons.logout,
            block: true,
            onPressed: c.actions.signOutOthers,
          ),
        )
      else
        LumeAccountSection(
          tight: true,
          child: LumeNoteCard(
            icon: LumeIcons.info,
            title: l.acctSessionsTitle,
            text: l.acctNoOtherDevices,
          ),
        ),
    ],
  );
}

// ------------------------------------------------- privacy, data, help, about

LumeAccountView _privacy(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  return LumeAccountView(
    title: l.acctPrivacyTitle,
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: LumeAccountList(
          rows: <Widget>[
            LumeSettingsRow(
              icon: LumeIcons.eye,
              title: l.acctPrivacyPreview,
              subtitle: l.acctPrivacyPreviewSub,
              toggle: c.notify.preview,
              onTap: () => c.actions.togglePreview(!c.notify.preview),
            ),
            LumeSettingsRow(
              icon: LumeIcons.lock,
              title: l.acctPrivacySensitive,
              subtitle: l.acctPrivacySensitiveSub,
              toggle: !c.notify.sensitivePreview,
              onTap: () =>
                  c.actions.toggleSensitivePreview(c.notify.sensitivePreview),
            ),
            LumeSettingsRow(
              icon: LumeIcons.sparkles,
              title: l.acctPrivacyPersonal,
              subtitle: l.acctPrivacyPersonalSub,
              toggle: c.profile.prefs.recommendations,
              onTap: () => c.actions.toggleRecommendations(
                !c.profile.prefs.recommendations,
              ),
              isLast: true,
            ),
          ],
        ),
      ),
      // Nothing to switch off, said plainly rather than by omission.
      LumeAccountSection(
        tight: true,
        child: LumeNoteCard(
          icon: LumeIcons.shield,
          title: l.acctPrivacyAnalytics,
          text: l.acctPrivacyAnalyticsSub,
        ),
      ),
      LumeAccountSection(
        tight: true,
        child: LumeAccountList(
          rows: <Widget>[
            LumeSettingsRow(
              icon: LumeIcons.cloud,
              title: l.acctSyncTitle,
              subtitle: l.acctRowSyncSub,
              onTap: () => c.actions.open(LumeAccountRoute.sync),
              isLast: true,
            ),
          ],
        ),
      ),
    ],
  );
}

LumeAccountView _sync(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  return LumeAccountView(
    title: l.acctSyncTitle,
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: LumeStoreGroup(
          icon: LumeIcons.device,
          label: l.acctSyncDevice,
          child: LumeAccountList(
            rows: <Widget>[
              for (int i = 0; i < c.stored.onDevice.length; i++)
                LumeSettingsRow(
                  icon: LumeIcons.check,
                  title: _storedLabel(l, c.stored.onDevice[i]),
                  chevron: false,
                  isLast: i == c.stored.onDevice.length - 1,
                ),
            ],
          ),
        ),
      ),
      LumeAccountSection(
        tight: true,
        child: LumeStoreGroup(
          icon: LumeIcons.cloud,
          label: l.acctSyncSynced,
          child: c.stored.synced.isEmpty
              // Nothing syncs, and the screen says why rather than showing an
              // empty card that looks like a loading one.
              ? LumeToolState(
                  icon: LumeIcons.cloud,
                  title: l.acctSyncSynced,
                  text: l.acctSyncNone,
                )
              : LumeAccountList(
                  rows: <Widget>[
                    for (int i = 0; i < c.stored.synced.length; i++)
                      LumeSettingsRow(
                        icon: LumeIcons.cloud,
                        title: _storedLabel(l, c.stored.synced[i]),
                        chevron: false,
                        isLast: i == c.stored.synced.length - 1,
                      ),
                  ],
                ),
        ),
      ),
    ],
  );
}

String _storedLabel(AppLocalizations l, String key) => switch (key) {
  'prefs' => l.acctDataPrefs,
  'notes' => l.acctDataNotes,
  'tools' => l.acctDataTools,
  'notify' => l.acctDataNotify,
  _ => l.acctDataAccount,
};

LumeAccountView _help(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  return LumeAccountView(
    title: l.acctHelpTitle,
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: LumeNoteCard(
          icon: LumeIcons.help,
          title: l.acctHelpTitle,
          text: l.acctHelpText,
        ),
      ),
      LumeAccountSection(
        tight: true,
        child: LumeAccountList(
          rows: <Widget>[
            LumeSettingsRow(
              icon: LumeIcons.sparkles,
              title: l.acctHelpTour,
              subtitle: l.acctRowTourSub,
              onTap: c.actions.startTour,
            ),
            LumeSettingsRow(
              icon: LumeIcons.shield,
              title: l.acctPrivacyTitle,
              subtitle: l.acctRowPrivacySub,
              onTap: () => c.actions.open(LumeAccountRoute.privacy),
            ),
            LumeSettingsRow(
              icon: LumeIcons.cloud,
              title: l.acctSyncTitle,
              subtitle: l.acctRowSyncSub,
              onTap: () => c.actions.open(LumeAccountRoute.sync),
              isLast: true,
            ),
          ],
        ),
      ),
      LumeAccountSection(
        tight: true,
        child: LumeButton(
          label: l.acctHelpContact,
          icon: LumeIcons.mail,
          block: true,
          onPressed: c.actions.sendFeedback,
        ),
      ),
    ],
  );
}

LumeAccountView _about(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  return LumeAccountView(
    title: l.acctAboutTitle,
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: LumeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Center(
                child: LumeIcon(
                  LumeIcons.lume,
                  size: 34,
                  color: context.lume.accent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Lume',
                textAlign: TextAlign.center,
                style: LumeType.tracked(
                  LumeType.natural(context, context.lumeType.title, size: 17),
                  -0.03,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                l.acctAboutText,
                textAlign: TextAlign.center,
                style: LumeInputField.captionStyle(context),
              ),
            ],
          ),
        ),
      ),
      LumeAccountSection(
        tight: true,
        child: LumeAccountList(
          rows: <Widget>[
            LumeSettingsRow(
              icon: LumeIcons.info,
              title: l.acctVersion,
              // This build's version, not the prototype's. See D40.
              value: c.version,
              chevron: false,
            ),
            LumeSettingsRow(
              icon: LumeIcons.globe,
              title: l.acctLanguageTitle,
              value: c.language,
              chevron: false,
            ),
            LumeSettingsRow(
              icon: LumeIcons.pin,
              title: l.acctRegionTitle,
              value: c.regionValue,
              chevron: false,
              isLast: true,
            ),
          ],
        ),
      ),
    ],
  );
}

// ----------------------------------------------------------------- deletion

/// Deletion is not an edit.
///
/// It says what it takes away *and* what it leaves, asks for the password, and
/// then asks once more — because an account that can be ended by one mistaken
/// tap is an account nobody can trust.
LumeAccountView _delete(LumeAccountRouteContext c) {
  final AppLocalizations l = c.l;
  if (!c.isAuthed) return signedOutView(c, l.acctDeleteTitle);

  return LumeAccountView(
    title: l.acctDeleteTitle,
    initialValues: const <String, String>{'current': ''},
    body: (BuildContext context) => <Widget>[
      LumeAccountSection(
        child: LumeStoreGroup(
          icon: LumeIcons.alert,
          label: l.acctDeleteWhat,
          child: LumeConsequenceList(
            items: <String>[l.acctDeleteW1, l.acctDeleteW2, l.acctDeleteW3],
            keeps: false,
          ),
        ),
      ),
      LumeAccountSection(
        tight: true,
        child: LumeStoreGroup(
          icon: LumeIcons.check,
          label: l.acctDeleteKeeps,
          child: LumeConsequenceList(
            items: <String>[l.acctDeleteK1],
            keeps: true,
          ),
        ),
      ),
      LumeAccountSection(
        tight: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l.acctDeleteConfirmTitle,
              style: LumeInputField.labelStyle(context),
            ),
            const SizedBox(height: 4),
            Text(
              l.acctDeleteConfirmText,
              style: LumeInputField.captionStyle(context),
            ),
            const SizedBox(height: 10),
            LumeAccountField(
              form: c.form,
              name: 'current',
              label: l.authFieldPassword,
              obscure: true,
              revealShowLabel: l.authShowPassword,
              revealHideLabel: l.authHidePassword,
              autofillHints: const <String>[AutofillHints.password],
              error: (LumeFormIssue i) => accountMessage(l, i),
              onLeave: c.actions.leaveField,
            ),
            const SizedBox(height: 18),
            LumeButton.danger(
              label: l.acctDeleteCta,
              icon: LumeIcons.trash,
              block: true,
              busy: c.form.busy,
              onPressed: c.form.busy ? null : c.actions.submit,
            ),
          ],
        ),
      ),
    ],
  );
}

// ------------------------------------------------------------------ messages

/// Turn a form's message key into the sentence it stands for.
///
/// The controller holds keys rather than sentences so that nothing in the
/// state is in one language; this is the single place they are resolved.
String accountMessage(AppLocalizations l, LumeFormIssue issue) =>
    switch (issue.key) {
      'currentRequired' => l.acctErrCurrentRequired,
      'currentWrong' => l.acctErrCurrentWrong,
      'passwordRequired' => l.authErrPasswordRequired,
      'passwordWeak' => l.authErrPasswordWeak,
      'passwordSame' => l.acctErrPasswordSame,
      'confirmRequired' => l.authErrConfirmRequired,
      'confirmMismatch' => l.authErrConfirmMismatch,
      'emailRequired' => l.authErrEmailRequired,
      'emailInvalid' => l.authErrEmailInvalid,
      'emailTaken' => l.authErrEmailTaken,
      'emailSame' => l.authErrEmailSame,
      'phoneInvalid' => l.acctErrPhoneInvalid,
      'nameRequired' => l.authFieldName,
      'locked' => l.authErrLocked,
      'signedOut' => l.authErrSignedOut,
      'storage' => l.acctErrStorage,
      _ => l.authErrNetwork,
    };

String _strengthWord(AppLocalizations l, LumePasswordStrength s) => switch (s) {
  LumePasswordStrength.none => l.authStrength0,
  LumePasswordStrength.weak => l.authStrength1,
  LumePasswordStrength.fair => l.authStrength2,
  LumePasswordStrength.good => l.authStrength3,
  LumePasswordStrength.strong => l.authStrength4,
};

String _ruleLabel(AppLocalizations l, LumePasswordRule rule) => switch (rule) {
  LumePasswordRule.length => l.authPasswordRuleLength,
  LumePasswordRule.upper => l.authPasswordRuleUpper,
  LumePasswordRule.lower => l.authPasswordRuleLower,
  LumePasswordRule.digit => l.authPasswordRuleDigit,
};

/// "Islamabad, Pakistan · Last seen 6 Sept, 9:14 pm" — composed where the
/// reader's own date and clock preferences are known.
String _sessionDetail(LumeAccountRouteContext c, LumeDeviceSession s) =>
    <String>[
      if (s.place.isNotEmpty) s.place,
      c.l.acctLastSeen(
        '${c.f.dateShort(s.lastSeen)} · ${c.f.time(s.lastSeen)}',
      ),
    ].join(' · ');

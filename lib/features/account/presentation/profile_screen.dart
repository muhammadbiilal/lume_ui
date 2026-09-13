/// Profile — identity, preferences, privacy and support.
///
/// Its composition stays the same whether the reader is a guest, signed in, or
/// holding a session that has run out. What changes is which rows exist and
/// what they say:
///
/// 1. the page head — Profile, and a Preferences control
/// 2. `.phead` — the identity card
/// 3. **Your Lume** — the settings every reader has
/// 4. **Account** — what the account state makes available
/// 5. **Support** — help, about, the tour
/// 6. the sign-out row, for a reader who has somewhere to sign out of
/// 7. the version line
///
/// The screen renders from state rather than being edited in place, so it
/// cannot drift into claiming an account that is not there. *Nothing here
/// invents a name, an email or a statistic to fill a gap* — an account with no
/// name shows the address, and a guest is a guest.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_destination.dart';
import '../../../core/widgets/lume/lume_destination_cards.dart';
import '../../../core/widgets/lume/lume_settings.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/account_model.dart';
import '../domain/profile_view.dart';
import 'profile_art.dart';

/// What Profile can ask the shell to do.
///
/// One callback per destination rather than one router call, so the screen
/// names what it wants and the host decides how to get there — and a test can
/// record the intent without a router.
@immutable
class LumeProfileActions {
  const LumeProfileActions({
    required this.open,
    required this.openInterests,
    required this.signIn,
    required this.signUp,
    required this.signOut,
    required this.startTour,
  });

  /// Any of the twenty-one account routes.
  final void Function(LumeAccountRoute route) open;

  /// `sheet:personalise` — the personalisation sheet, which is not an account
  /// route: it belongs to onboarding's own picker.
  final VoidCallback openInterests;

  final VoidCallback signIn;
  final VoidCallback signUp;
  final VoidCallback signOut;

  /// `acctdo:tour`.
  final VoidCallback startTour;
}

/// The screen.
class LumeProfileScreen extends StatelessWidget {
  const LumeProfileScreen({
    super.key,
    required this.view,
    required this.actions,
  });

  final LumeProfileView view;
  final LumeProfileActions actions;

  /// Keys the tests and the bounds comparison address elements by.
  static const String headKey = 'profile.head';
  static const String identityKey = 'profile.identity';
  static const String lumeKey = 'profile.lume';
  static const String accountKey = 'profile.account';
  static const String supportKey = 'profile.support';
  static const String sessionKey = 'profile.session';
  static const String versionKey = 'profile.version';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);

    return LumeDestinationPage(
      storageId: 'profile',
      semanticLabel: l.navProfile,
      slivers: <Widget>[
        SliverToBoxAdapter(child: _head(context, l)),
        SliverToBoxAdapter(child: _identity(context, l)),
        SliverToBoxAdapter(child: _lume(context, l)),
        SliverToBoxAdapter(child: _account(context, l)),
        SliverToBoxAdapter(child: _support(context, l)),
        if (view.isAuthed) SliverToBoxAdapter(child: _session(context, l)),
        SliverToBoxAdapter(child: _version(context, l)),
      ],
    );
  }

  // -- 1. the head ---------------------------------------------------------

  Widget _head(BuildContext context, AppLocalizations l) => KeyedSubtree(
    key: const ValueKey<String>(headKey),
    child: LumePageHead(
      title: l.navProfile,
      subtitle: l.profileSub,
      action: LumeHeaderButton(
        icon: LumeIcons.settings,
        semanticLabel: l.acctPrefsTitle,
        onTap: () => actions.open(LumeAccountRoute.prefs),
      ),
    ),
  );

  // -- 2. the identity card ------------------------------------------------

  /// The identity states, as contents of one composition.
  ///
  /// The expired case is the one the reference got wrong in its own history
  /// and calls out in its source: a returning holder's own name sitting above
  /// "you are using Lume as a guest". Here the expired card says what happened
  /// and whose account it is, and nothing reads them as signed in — not the
  /// avatar, not the member-since tag, not a row.
  Widget _identity(BuildContext context, AppLocalizations l) {
    final LumeAccountIdentity? user = view.user;
    final LumeAccountIdentity? pending = view.pending;
    final LumeFormatting f = LumeFormatting.of(context);

    final String name;
    final String? secondary;
    if (user != null) {
      final String full = user.fullName;
      // With no name the address *is* the identity — there is nothing to
      // invent and nothing to apologise for.
      name = full.isNotEmpty ? full : user.email;
      secondary = full.isNotEmpty ? user.email : null;
    } else if (pending != null) {
      name = l.authExpiredTitle;
      secondary = l.acctSignedInAs(pending.email);
    } else {
      name = view.values.deviceName.isNotEmpty
          ? view.values.deviceName
          : l.acctGuestTitle;
      secondary = l.acctGuestText;
    }

    final List<Widget> meta = <Widget>[
      if (user != null) ...<Widget>[
        LumeTag(
          label: l.acctMemberSince(f.dateLongYear(user.createdAt)),
          icon: LumeIcons.star,
        ),
        if (user.status == LumeAccountStatus.locked)
          LumeBadge(label: l.acctStatusLocked, tone: LumeBadgeTone.late_),
      ] else if (pending != null)
        LumeBadge(label: l.authExpiredTitle, tone: LumeBadgeTone.warn)
      else
        LumeTag(label: l.acctGuestBadge),
    ];

    final List<Widget> acts = <Widget>[
      if (user != null)
        LumeButton(
          label: l.acctEditProfile,
          icon: LumeIcons.user,
          block: true,
          onPressed: () => actions.open(LumeAccountRoute.edit),
        )
      else if (pending != null)
        LumeButton.accent(
          label: l.authExpiredCta,
          icon: LumeIcons.login,
          block: true,
          onPressed: actions.signIn,
        )
      else ...<Widget>[
        LumeButton.accent(
          label: l.authCreateAccount,
          icon: LumeIcons.user,
          block: true,
          onPressed: actions.signUp,
        ),
        LumeButton(
          label: l.authSignIn,
          icon: LumeIcons.login,
          block: true,
          onPressed: actions.signIn,
        ),
      ],
    ];

    // An incomplete profile is *invited* to complete itself, never forced to.
    final bool incomplete = user != null && user.fullName.isEmpty;

    return KeyedSubtree(
      key: const ValueKey<String>(identityKey),
      child: LumePageSection(
        child: LumeMeasure(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LumeIdentityCard(
                art: const LumeProfileHeadArt(),
                avatar: LumeProfileAvatar(
                  photo: user?.photo ?? '',
                  initials: user?.initials ?? '',
                ),
                name: name,
                secondary: secondary,
                meta: meta,
                why: view.isGuest
                    ? LumeGuestWhy(
                        title: l.acctGuestWhy,
                        reasons: <String>[
                          l.acctGuestWhy1,
                          l.acctGuestWhy2,
                          l.acctGuestWhy3,
                        ],
                      )
                    : null,
                actions: acts,
              ),
              if (incomplete) ...<Widget>[
                const SizedBox(height: LumeSpace.gapCard),
                LumeNoteCard(
                  icon: LumeIcons.sparkles,
                  tone: LumeNoteTone.info,
                  title: l.acctCompleteTitle,
                  text: l.acctCompleteText,
                ),
                const SizedBox(height: 10),
                LumeButton(
                  label: l.acctCompleteCta,
                  icon: LumeIcons.user,
                  block: true,
                  onPressed: () => actions.open(LumeAccountRoute.edit),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // -- 3. Your Lume --------------------------------------------------------

  Widget _lume(BuildContext context, AppLocalizations l) {
    final LumeProfileValues v = view.values;
    final LumeFormatting f = LumeFormatting.of(context);
    return _group(
      groupKey: lumeKey,
      label: l.acctYourLume,
      rows: <Widget>[
        LumeSettingsRow(
          icon: LumeIcons.sliders,
          accent: true,
          title: l.acctRowPreferences,
          subtitle: l.acctRowPreferencesSub,
          onTap: () => actions.open(LumeAccountRoute.prefs),
        ),
        LumeSettingsRow(
          icon: LumeIcons.bellRing,
          title: l.navNotifications,
          subtitle: l.acctRowNotificationsSub,
          value: v.notifications,
          onTap: () => actions.open(LumeAccountRoute.notifications),
        ),
        LumeSettingsRow(
          icon: Theme.of(context).brightness == Brightness.dark
              ? LumeIcons.moon
              : LumeIcons.sun,
          title: l.acctRowAppearance,
          subtitle: l.acctRowAppearanceSub,
          value: v.appearance,
          onTap: () => actions.open(LumeAccountRoute.appearance),
        ),
        LumeSettingsRow(
          icon: LumeIcons.globe,
          title: l.acctRowLanguage,
          subtitle: l.acctLanguageNote,
          value: v.language,
          onTap: () => actions.open(LumeAccountRoute.language),
        ),
        LumeSettingsRow(
          icon: LumeIcons.pin,
          title: l.acctRowRegion,
          subtitle: l.acctRowRegionSub,
          value: v.region,
          onTap: () => actions.open(LumeAccountRoute.region),
        ),
        LumeSettingsRow(
          icon: LumeIcons.sparkles,
          title: l.acctRowInterests,
          subtitle: l.acctRowInterestsSub,
          value: f.number(v.interests),
          onTap: actions.openInterests,
        ),
        // A guest has a name too, and it was promised it could be changed.
        // A signed-in reader changes theirs on the account form instead.
        if (!view.isAuthed)
          LumeSettingsRow(
            icon: LumeIcons.user,
            title: l.acctFieldDisplayName,
            subtitle: l.acctNameNote,
            // Empty is a real value here: a guest who never gave this device
            // a name has one Lume holds and knows to be blank.
            value: v.deviceName,
            notSetLabel: l.actionNotSet,
            onTap: () => actions.open(LumeAccountRoute.edit),
          ),
        LumeSettingsRow(
          icon: LumeIcons.bookmark,
          title: l.acctRowLibrary,
          subtitle: l.acctRowLibrarySub,
          value: f.number(v.favourites),
          onTap: () => actions.open(LumeAccountRoute.library),
          isLast: true,
        ),
      ],
    );
  }

  // -- 4. Account ----------------------------------------------------------

  Widget _account(BuildContext context, AppLocalizations l) {
    final List<Widget> rows = view.isAuthed
        ? <Widget>[
            LumeSettingsRow(
              icon: LumeIcons.user,
              accent: true,
              title: l.acctRowPersonal,
              subtitle: l.acctRowPersonalSub,
              onTap: () => actions.open(LumeAccountRoute.account),
            ),
            LumeSettingsRow(
              icon: LumeIcons.shield,
              title: l.acctRowSecurity,
              subtitle: l.acctRowSecuritySub,
              onTap: () => actions.open(LumeAccountRoute.security),
            ),
          ]
        : <Widget>[
            // The state decides which invitation leads. An expired session is
            // offered its way back first; a guest is offered the account they
            // do not have.
            if (view.isExpired) ...<Widget>[
              LumeSettingsRow(
                icon: LumeIcons.login,
                accent: true,
                title: l.authExpiredCta,
                subtitle: l.authExpiredText,
                onTap: actions.signIn,
              ),
              LumeSettingsRow(
                icon: LumeIcons.user,
                title: l.authCreateAccount,
                subtitle: l.acctGuestWhy1,
                onTap: actions.signUp,
              ),
            ] else ...<Widget>[
              LumeSettingsRow(
                icon: LumeIcons.user,
                accent: true,
                title: l.authCreateAccount,
                subtitle: l.acctGuestWhy1,
                onTap: actions.signUp,
              ),
              LumeSettingsRow(
                icon: LumeIcons.login,
                title: l.authSignIn,
                subtitle: l.authSignInText,
                onTap: actions.signIn,
              ),
            ],
          ];

    return _group(
      groupKey: accountKey,
      label: l.navAccount,
      rows: <Widget>[
        ...rows,
        // Privacy and Data & sync are on every version of this group: they
        // describe what is on *this device*, which is exactly as true for a
        // guest, and a row a guest can see must lead somewhere.
        LumeSettingsRow(
          icon: LumeIcons.lock,
          title: l.acctRowPrivacy,
          subtitle: l.acctRowPrivacySub,
          onTap: () => actions.open(LumeAccountRoute.privacy),
        ),
        LumeSettingsRow(
          icon: LumeIcons.cloud,
          title: l.acctRowSync,
          subtitle: l.acctRowSyncSub,
          onTap: () => actions.open(LumeAccountRoute.sync),
          isLast: true,
        ),
      ],
    );
  }

  // -- 5. Support ----------------------------------------------------------

  Widget _support(BuildContext context, AppLocalizations l) => _group(
    groupKey: supportKey,
    label: l.acctSupport,
    rows: <Widget>[
      LumeSettingsRow(
        icon: LumeIcons.help,
        title: l.acctRowHelp,
        subtitle: l.acctRowHelpSub,
        onTap: () => actions.open(LumeAccountRoute.help),
      ),
      LumeSettingsRow(
        icon: LumeIcons.info,
        title: l.acctRowAbout,
        subtitle: l.acctRowAboutSub,
        onTap: () => actions.open(LumeAccountRoute.about),
      ),
      LumeSettingsRow(
        icon: LumeIcons.sparkles,
        title: l.acctRowTour,
        subtitle: l.acctRowTourSub,
        onTap: actions.startTour,
        isLast: true,
      ),
    ],
  );

  // -- 6. the way out ------------------------------------------------------

  Widget _session(BuildContext context, AppLocalizations l) => KeyedSubtree(
    key: const ValueKey<String>(sessionKey),
    child: LumePageSection(
      child: LumeMeasure(
        child: LumeCard(
          padded: false,
          child: LumeSettingsRow(
            icon: LumeIcons.logout,
            title: l.acctSignOut,
            subtitle: l.acctSignedInAs(view.identity?.email ?? ''),
            chevron: false,
            onTap: actions.signOut,
            isLast: true,
          ),
        ),
      ),
    ),
  );

  // -- 7. the version ------------------------------------------------------

  /// The version line, carrying **this** build's version. See D40.
  Widget _version(BuildContext context, AppLocalizations l) => KeyedSubtree(
    key: const ValueKey<String>(versionKey),
    child: Padding(
      padding: const EdgeInsets.only(top: 22),
      child: LumeMeasure(
        child: Text(
          'Lume · ${l.acctVersion} ${view.values.version}',
          textAlign: TextAlign.center,
          style: LumeType.natural(
            context,
            context.lumeType.meta,
            size: 12,
          ).copyWith(color: context.lume.text3),
        ),
      ),
    ),
  );

  // -- the group shape -----------------------------------------------------

  Widget _group({
    required String groupKey,
    required String label,
    required List<Widget> rows,
  }) => KeyedSubtree(
    key: ValueKey<String>(groupKey),
    child: LumePageSection(
      child: LumeMeasure(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LumeSettingsGroupLabel(label),
            const SizedBox(height: LumeSettingsMetrics.groupLabelGap),
            LumeCard(
              padded: false,
              child: Column(mainAxisSize: MainAxisSize.min, children: rows),
            ),
          ],
        ),
      ),
    ),
  );
}

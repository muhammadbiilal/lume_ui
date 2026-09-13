/// Profile, wired to the launch.
///
/// Profile reads more stores than any other destination — the account, the
/// personalisation record, the theme, the notification preferences, the
/// favourites and the build — and turns them into one [LumeProfileView]. That
/// composition is the whole of this file's job: the screen renders a value and
/// decides nothing, which is what lets a test put it in any identity state
/// without a repository.
///
/// Every row leads to a real destination. *A functional row must not point
/// indefinitely at a generic placeholder* — so the twenty-one account routes
/// are routes, `sheet:personalise` opens the picker onboarding already owns,
/// and the two authentication actions open the flow F4 built.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/personalisation.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/lume_build.dart';
import '../../../core/routing/lume_routes.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../../../app/providers/shell_provider.dart';
import '../../../app/providers/theme_provider.dart';
import '../../../core/localization/lume_locales.dart';
import '../../auth/application/auth_flow_controller.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../onboarding/data/country_fixture.dart';
import '../../onboarding/domain/onboarding_state.dart';
import '../../startup/application/startup_controller.dart';
import '../domain/account_model.dart';
import '../domain/account_repository.dart';
import '../domain/notification_prefs.dart';
import '../domain/profile_view.dart';
import 'personalise_sheet.dart';
import 'profile_screen.dart';

/// Profile on a branch.
class LumeProfileHost extends ConsumerStatefulWidget {
  const LumeProfileHost({super.key, required this.branch});

  /// The branch root Profile sits on, so an account route opened from here
  /// returns here.
  final String branch;

  @override
  ConsumerState<LumeProfileHost> createState() => _LumeProfileHostState();
}

class _LumeProfileHostState extends ConsumerState<LumeProfileHost> {
  /// Shown over the page. There is no global presenter, so a screen that
  /// toasts holds its own.
  LumeToastData? _toast;

  void _say(String message) {
    if (!mounted) return;
    setState(() => _toast = LumeToastData(message: message));
  }

  /// What the appearance row says, from the mode actually in force.
  String _appearance(AppLocalizations l, ThemeMode mode) => switch (mode) {
    ThemeMode.light => l.acctAppearanceLight,
    ThemeMode.dark => l.acctAppearanceDark,
    ThemeMode.system => l.acctAppearanceSystem,
  };

  /// `regionValue()` — country, city and currency, joined the way the
  /// reference joins them.
  ///
  /// The country's *name* comes from the table the launch read. Where the
  /// table is missing the row falls back to the ISO code, which is true; it
  /// never falls back to a blank or to a guess.
  String _region(
    LumeFormatting f,
    LumeProfileRecord p,
    LumeCountryFixture? countries,
    String language,
  ) => <String>[
    countries?.nameOf(p.country, language) ?? p.country,
    if (p.city.isNotEmpty) p.city,
    f.currency,
  ].join(' · ');

  @override
  Widget build(BuildContext context) => LumeProfileScope(
    builder: (BuildContext context, LumeUserContext user) {
      final AppLocalizations l = AppLocalizations.of(context);
      final String language = Localizations.localeOf(context).languageCode;
      final LumeStartupController gate = ref.watch(startupControllerProvider);
      final LumeProfileRecord p = gate.state.profile;
      final LumeFormatting f = LumeFormatting.of(
        context,
        countryCode: user.country,
      );
      final LumeAccountRepository account = ref.watch(
        accountRepositoryProvider,
      );
      final LumeNotificationPrefs notify = ref
          .watch(notificationPrefsProvider)
          .prefs;
      final ThemeMode mode = ref.watch(themeModeProvider);

      final List<LumeNotificationCategory> cats = LumeNotificationPrefs.visible(
        islamic: user.islamic,
      );

      final LumeProfileView view = LumeProfileView(
        state: account.state,
        identity: account.identity,
        values: LumeProfileValues(
          // A language is named in itself: somebody looking for Urdu is
          // looking for "اردو", not for "Urdu".
          language: LumeLocales.forCode(language).native,
          region: _region(f, p, gate.state.countries, language),
          appearance: _appearance(l, mode),
          // The count and the list are the same question asked once: the
          // faith gate is applied to both, so a reader cannot be told about
          // a category their own Notifications screen does not show. The
          // reference counts all eleven regardless — see C34.
          notifications: l.acctCatsOn(
            cats.length,
            notify.onCount(islamic: user.islamic),
          ),
          interests: p.interests.length,
          favourites: p.favourites.length,
          version: kLumeVersion,
          deviceName: p.displayName,
        ),
      );

      final Widget screen = LumeProfileScreen(
        view: view,
        actions: LumeProfileActions(
          open: (LumeAccountRoute route) =>
              context.go(LumeRoutes.accountRoute(widget.branch, route.segment)),
          // The personalisation picker belongs to onboarding, not to the
          // account: it is the same sheet the "What are you here for?" step
          // uses, and a second copy would be a second answer.
          openInterests: () => unawaited(showLumePersonalise(context)),
          signIn: () =>
              context.go(LumeRoutes.authRoute(LumeAuthRoute.signIn.segment)),
          signUp: () =>
              context.go(LumeRoutes.authRoute(LumeAuthRoute.signUp.segment)),
          signOut: () => _say(l.acctLoggedOut),
          startTour: () => _say(l.acctHelpTour),
        ),
      );

      if (_toast == null) return screen;
      return Stack(
        children: <Widget>[
          screen,
          Positioned(
            left: 0,
            right: 0,
            bottom: 92 + MediaQuery.paddingOf(context).bottom,
            child: Align(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LumeToast(data: _toast!),
              ),
            ),
          ),
        ],
      );
    },
  );
}

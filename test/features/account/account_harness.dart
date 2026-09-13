/// What an account test needs, once.
///
/// Two ways in, because the account section has two gates and they guard
/// different things. [pumpAccountRouter] goes through the real router, which
/// is where the path parameter, the redirect and the back stack live.
/// [pumpAccountHost] puts the host on screen directly, which is the only way
/// to see its *own* refusal — the one a session that expires while the screen
/// is open runs into, after the router has already let the reader through.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/account/data/fake_account_repository.dart';
import 'package:lume/features/account/data/notification_prefs_store.dart';
import 'package:lume/features/account/domain/account_model.dart';
import 'package:lume/features/account/presentation/account_host.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/features/auth/domain/auth_repository.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';

import '../../helpers/lume_harness.dart';

/// A signed-in session whose month has run out.
LumeAuthRepository expiredAuth() => LumeFakeAuthRepository.withAccount()
  ..seedSession(kFixtureEmail)
  ..expireSession();

/// A launch that has finished, with the country table in it.
///
/// Three of the routes name a country and one lists timezones, and both come
/// from the bundled table the launch reads. Without it they fall back to the
/// ISO code — which is honest, and is not what the reference draws, so a
/// capture taken that way would score against a screen the product never
/// shows.
Future<LumeStartupController> bootedGate({
  LumeProfileRecord? profile,
  LumeAuthRepository? auth,
}) async {
  final LumeMemoryProfileRepository profiles = LumeMemoryProfileRepository();
  if (profile != null) await profiles.writeProfile(profile);
  final LumeStartupController gate = LumeStartupController(
    authRepository: auth ?? LumeFakeAuthRepository.withAccount(),
    profileRepository: profiles,
  );
  await gate.boot();
  return gate;
}

/// The overrides an account test almost always wants: a real account behind
/// the section, and a preferences store of its own so one test's switches
/// cannot reach the next.
List<Override> accountOverrides({
  LumeFakeAccountRepository? account,
  LumeMemoryNotificationPrefs? notify,
  LumeStartupController? gate,
}) => <Override>[
  accountStoreProvider.overrideWithValue(
    account ?? LumeFakeAccountRepository(),
  ),
  notificationPrefsProvider.overrideWithValue(
    notify ?? LumeMemoryNotificationPrefs(),
  ),
  if (gate != null) startupControllerProvider.overrideWithValue(gate),
];

/// One account route, through the real router, on Profile's branch.
Future<GoRouter> pumpAccountRouter(
  WidgetTester tester, {
  required LumeAccountRoute route,
  LumeFakeAccountRepository? account,
  LumeMemoryNotificationPrefs? notify,
  Size surface = LumeViewport.phone,
  ThemeMode theme = ThemeMode.light,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
}) => pumpLumeRouter(
  tester,
  initialLocation: LumeRoutes.accountRoute(LumeRoutes.profile, route.segment),
  // The router's gate reads the *session*, the host's reads the account, and
  // both have to say the same thing or the test is measuring the seam.
  signedIn:
      (account ?? LumeFakeAccountRepository()).state == LumeAccountState.authed,
  overrides: accountOverrides(account: account, notify: notify),
  surface: surface,
  theme: theme,
  locale: locale,
  textScale: textScale,
);

/// The host on its own, past the router's gate.
Future<void> pumpAccountHost(
  WidgetTester tester, {
  required LumeAccountRoute route,
  LumeFakeAccountRepository? account,
  LumeMemoryNotificationPrefs? notify,
  Size surface = LumeViewport.phone,
  ThemeMode theme = ThemeMode.light,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
  LumeStartupController? gate,
}) => pumpLume(
  tester,
  LumeAccountHost(branch: LumeRoutes.profile, route: route),
  overrides: accountOverrides(account: account, notify: notify, gate: gate),
  surface: surface,
  theme: theme,
  locale: locale,
  textScale: textScale,
);

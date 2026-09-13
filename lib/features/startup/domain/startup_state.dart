/// What the application knows about itself at launch, and the one place that
/// turns it into a destination.
///
/// **One decision system.** Every redirect in the product is decided by
/// [LumeRouteGate.redirect]. No screen performs its own: a screen that
/// redirected would be racing this one, and two systems that both navigate
/// produce loops that nobody can read.
///
/// The rules the gate exists to guarantee:
///
/// * Home never flashes before the session is known.
/// * Sign In never flashes in front of somebody who is signed in.
/// * A deep link is never lost to authentication or onboarding — it is held
///   and resumed.
/// * Session restoration runs once.
/// * Authentication never marks onboarding complete.
/// * Guest is not a lesser authenticated state; it is its own state, and most
///   of the product is open to it.
library;

import 'package:flutter/foundation.dart';

import '../../../core/routing/lume_routes.dart';
import '../../auth/domain/auth_model.dart';
import '../../onboarding/data/country_fixture.dart';
import '../../onboarding/domain/onboarding_state.dart';

/// How far the launch has got.
enum LumeStartupPhase {
  /// Repositories have not answered. The splash is showing, and it is the
  /// only correct thing to show: anything else would be a guess.
  booting,

  /// Everything the gate needs is known.
  ready,
}

/// Everything the gate reads. A value, so a test can state a launch in one
/// expression and assert the destination.
@immutable
class LumeStartupState {
  const LumeStartupState({
    this.phase = LumeStartupPhase.booting,
    this.auth = const LumeAuthStatus.guest(),
    this.profile = const LumeProfileRecord(),
    this.profileIsDurable = false,
    this.held,
    this.countries,
  });

  final LumeStartupPhase phase;
  final LumeAuthStatus auth;
  final LumeProfileRecord profile;

  /// Whether the profile survives a restart.
  ///
  /// **The first-run gate depends on this.** With a store that forgets, a
  /// completed onboarding is forgotten too, and sending every launch to
  /// `/onboarding` would put the flow in front of someone who has already
  /// finished it — every single time. So while this is `false` the gate does
  /// not force onboarding, and says so rather than pretending the gate works.
  final bool profileIsDurable;

  /// A location the user asked for that could not be honoured yet, held until
  /// it can be. Survives onboarding and authentication both.
  final String? held;

  /// The country table, read once at launch.
  ///
  /// Three surfaces need a country's *name* — onboarding's picker, Profile's
  /// region row and the account's region route — and a name is a translated
  /// string from a bundled table, not something a screen can derive from
  /// `PK`. Reading it here means every one of them reads the same table, and
  /// none of them has to render an empty box while an asset decodes.
  ///
  /// `null` means the read failed. That is a real state: the screens fall
  /// back to the ISO code, which is true, rather than to a blank.
  final LumeCountryFixture? countries;

  bool get isReady => phase == LumeStartupPhase.ready;

  LumeStartupState copyWith({
    LumeStartupPhase? phase,
    LumeAuthStatus? auth,
    LumeProfileRecord? profile,
    bool? profileIsDurable,
    String? held,
    bool clearHeld = false,
    LumeCountryFixture? countries,
  }) => LumeStartupState(
    phase: phase ?? this.phase,
    auth: auth ?? this.auth,
    profile: profile ?? this.profile,
    profileIsDurable: profileIsDurable ?? this.profileIsDurable,
    held: clearHeld ? null : (held ?? this.held),
    countries: countries ?? this.countries,
  );

  @override
  bool operator ==(Object other) =>
      other is LumeStartupState &&
      other.phase == phase &&
      other.auth == auth &&
      // The whole record, not only `onboarded`. The gate is the one place the
      // profile lives, and every destination reads it through the same
      // listener — so a change of country, of the faith preference or of the
      // recents list has to reach them, and comparing one field would swallow
      // all three.
      other.profile == profile &&
      other.profileIsDurable == profileIsDurable &&
      other.held == held &&
      identical(other.countries, countries);

  @override
  int get hashCode =>
      Object.hash(phase, auth, profile, profileIsDurable, held, countries);
}

/// The single routing decision.
abstract final class LumeRouteGate {
  /// Where the splash lives while the launch is still deciding.
  static const String splash = '/splash';

  /// The account routes that need an account.
  ///
  /// **Only seven of the twenty-one.** Everything else in the section works
  /// for a guest, and a row a guest can see must lead somewhere: "Data &
  /// sync" and "Privacy" describe what is on *this device*, which is exactly
  /// as true without an account, and the edit form is the only screen that
  /// changes a guest's own device name.
  ///
  /// The segments rather than the enum, because routing is core and the
  /// account is a feature. `account_routes_test.dart` asserts this set is
  /// exactly `LumeAccountRepository.requiresAccount`'s, so the two cannot
  /// drift.
  static const Set<String> protectedAccountRoutes = <String>{
    'account',
    'email',
    'phone',
    'security',
    'password',
    'sessions',
    'delete',
  };

  /// Whether a location needs an account.
  ///
  /// The *route* decides, not the section: `/profile/account/help` is open and
  /// `/profile/account/password` is not, and treating the whole section as
  /// protected would send a guest to sign in to read the help.
  static bool isProtected(String location) {
    final int at = location.indexOf('/${LumeRoutes.accountSegment}/');
    if (at < 0) return false;
    final String rest = location.substring(
      at + LumeRoutes.accountSegment.length + 2,
    );
    final String segment = rest.split('/').first.split('?').first;
    return protectedAccountRoutes.contains(segment);
  }

  /// Whether a location belongs to the authentication flow.
  static bool isAuth(String location) =>
      location == LumeRoutes.auth || location.startsWith('${LumeRoutes.auth}/');

  /// Whether a location is one of the two flows that cover the shell.
  static bool isFlow(String location) =>
      isAuth(location) ||
      location == LumeRoutes.onboarding ||
      location == splash;

  /// Where [location] should actually go, or `null` to let it stand.
  ///
  /// ### Priority
  ///
  /// The conditions are not independent, so the order matters and is stated
  /// rather than left to fall out of the code:
  ///
  /// 1. **Nothing is known yet** → the splash. Every other rule needs an
  ///    answer this one is still waiting for.
  /// 2. **Onboarding is required** → `/onboarding`. It comes before the
  ///    session because it is the product's first question, and because a
  ///    brand-new install has no session to have an opinion about.
  /// 3. **The session has expired** → `/auth/expired`. A dead session is a
  ///    thing to be told about, not a quiet downgrade to guest.
  /// 4. **A protected location without an account** → `/auth/signin`, with
  ///    the location held.
  /// 5. **Sitting on the splash, or on a flow that is finished** → the held
  ///    destination, else the start route.
  ///
  /// Guest is never redirected anywhere by rule 4 except away from the
  /// account's own surfaces. Being a guest is not a problem to be solved.
  static String? redirect({
    required LumeStartupState state,
    required String location,
  }) {
    // 1 — nothing is known yet.
    if (!state.isReady) {
      return location == splash ? null : splash;
    }

    final bool onboardingNeeded =
        state.profileIsDurable && LumeOnboardingState.shouldShow(state.profile);

    // 2 — the first question, before anything about a session.
    if (onboardingNeeded) {
      return location == LumeRoutes.onboarding ? null : LumeRoutes.onboarding;
    }
    if (location == LumeRoutes.onboarding) {
      // Onboarding is finished but the flow is still on screen; the flow
      // itself reports its outcome and the host leaves. Nothing to force.
      return null;
    }

    // 3 — an expired session interrupts, once, wherever the user was going.
    if (state.auth.isExpired) {
      final String expired = LumeRoutes.authRoute('expired');
      return location == expired ? null : expired;
    }

    // 4 — a protected location needs an account.
    if (isProtected(location) && !state.auth.isAuthenticated) {
      return LumeRoutes.authRoute('signin');
    }

    // 5 — the splash has nothing left to wait for.
    if (location == splash) {
      return state.held ?? LumeRoutes.start;
    }

    return null;
  }
}

/// The one routing decision, stated as a table.
///
/// Every redirect the product performs comes out of
/// [LumeRouteGate.redirect], so this is the whole of it: a pure function of a
/// launch state and a location. Testing it here rather than only through a
/// navigator means the priority order is asserted directly, and a rule that
/// would loop is visible as a loop rather than as a hang.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/auth/domain/auth_model.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/startup/domain/startup_state.dart';

import '../auth/auth_harness.dart';

void main() {
  const String signIn = '/auth/signin';
  const String expired = '/auth/expired';
  const String splash = LumeRouteGate.splash;
  const String account = '/profile/account';

  LumeStartupState ready({
    LumeAuthStatus auth = const LumeAuthStatus.guest(),
    bool onboarded = true,
    bool durable = true,
    String? held,
  }) => LumeStartupState(
    phase: LumeStartupPhase.ready,
    auth: auth,
    profile: LumeProfileRecord(onboarded: onboarded),
    profileIsDurable: durable,
    held: held,
  );

  LumeAuthStatus signedIn() => LumeAuthStatus(
    state: LumeSessionState.authenticated,
    account: const LumeAccount(id: 'usr-1', email: kTestEmail),
    session: LumeSession(
      email: kTestEmail,
      deviceId: 'dev',
      issued: DateTime(2026, 9, 12),
      expires: DateTime(2026, 10, 12),
    ),
  );

  LumeAuthStatus expiredSession() => LumeAuthStatus(
    state: LumeSessionState.expired,
    account: const LumeAccount(id: 'usr-1', email: kTestEmail),
    session: LumeSession(
      email: kTestEmail,
      deviceId: 'dev',
      issued: DateTime(2026, 8, 12),
      expires: DateTime(2026, 9, 11),
    ),
  );

  String? go(LumeStartupState state, String location) =>
      LumeRouteGate.redirect(state: state, location: location);

  group('while the launch is still deciding', () {
    test('everything goes to the splash', () {
      const LumeStartupState booting = LumeStartupState();
      for (final String location in <String>[
        LumeRoutes.home,
        account,
        signIn,
        LumeRoutes.onboarding,
        '/tools/tool/calculator',
      ]) {
        expect(go(booting, location), splash, reason: location);
      }
    });

    test('the splash itself is left alone, so there is no loop', () {
      expect(go(const LumeStartupState(), splash), isNull);
    });

    test('neither Home nor Sign In is ever shown before the answer', () {
      // The two flashes the whole arrangement exists to prevent.
      const LumeStartupState booting = LumeStartupState();
      expect(go(booting, LumeRoutes.home), isNot(LumeRoutes.home));
      expect(go(booting, signIn), isNot(signIn));
    });
  });

  group('once it knows', () {
    test('a guest is left where they were going', () {
      expect(go(ready(), LumeRoutes.home), isNull);
      expect(go(ready(), '/tools/tool/calculator'), isNull);
      expect(
        go(ready(), LumeRoutes.explore),
        isNull,
        reason: 'being a guest is not a problem to be solved',
      );
    });

    test('the splash hands over to the start route', () {
      expect(go(ready(), splash), LumeRoutes.start);
    });

    test('the splash hands over to a held destination instead', () {
      expect(
        go(ready(held: '/today/notifications'), splash),
        '/today/notifications',
      );
    });

    test('somebody signed in is left alone everywhere', () {
      final LumeStartupState state = ready(auth: signedIn());
      for (final String location in <String>[
        LumeRoutes.home,
        account,
        '/tools/tool/calculator',
      ]) {
        expect(go(state, location), isNull, reason: location);
      }
    });
  });

  group('the account surfaces', () {
    test('need an account, and hold what was asked for', () {
      expect(go(ready(), account), signIn);
      expect(go(ready(), '/home/account'), signIn);
    });

    test('open for somebody signed in', () {
      expect(go(ready(auth: signedIn()), account), isNull);
    });

    test('an expired session is told rather than quietly refused', () {
      expect(go(ready(auth: expiredSession()), account), expired);
    });

    test('nothing else in the product is gated', () {
      // The list is the account's own surfaces and nothing more: a row a guest
      // can see has to lead somewhere.
      for (final String location in <String>[
        LumeRoutes.home,
        LumeRoutes.tools,
        LumeRoutes.today,
        LumeRoutes.explore,
        LumeRoutes.profile,
        '/home/notifications',
        '/home/search',
        '/tools/tool/calculator',
        '/home/tool/records/records/7',
      ]) {
        expect(LumeRouteGate.isProtected(location), isFalse, reason: location);
        expect(go(ready(), location), isNull, reason: location);
      }
    });
  });

  group('an expired session', () {
    test('interrupts wherever the user was going', () {
      final LumeStartupState state = ready(auth: expiredSession());
      for (final String location in <String>[
        LumeRoutes.home,
        '/tools/tool/calculator',
        signIn,
      ]) {
        expect(go(state, location), expired, reason: location);
      }
    });

    test('leaves its own screen alone, so there is no loop', () {
      expect(go(ready(auth: expiredSession()), expired), isNull);
    });

    test('is gone once the session is', () {
      expect(go(ready(), LumeRoutes.home), isNull);
    });
  });

  group('onboarding comes first', () {
    test('a durable store with an unfinished flow sends everything there', () {
      final LumeStartupState fresh = ready(onboarded: false);
      for (final String location in <String>[
        LumeRoutes.home,
        account,
        signIn,
      ]) {
        expect(go(fresh, location), LumeRoutes.onboarding, reason: location);
      }
    });

    test('it outranks an expired session', () {
      // A brand-new install has no session worth having an opinion about, and
      // the first question is still the first question.
      final LumeStartupState both = ready(
        onboarded: false,
        auth: expiredSession(),
      );
      expect(go(both, LumeRoutes.home), LumeRoutes.onboarding);
    });

    test('the flow is left alone once it is showing', () {
      expect(go(ready(onboarded: false), LumeRoutes.onboarding), isNull);
    });

    test('and the flow is left alone while it finishes', () {
      // The flow reports its own outcome and the host leaves; the gate does
      // not yank it away mid-frame.
      expect(go(ready(), LumeRoutes.onboarding), isNull);
    });

    test('a store that forgets does not force it', () {
      // With no durable store a completed onboarding is forgotten too, so
      // forcing the flow would put it in front of the same person every
      // launch. The gate says so rather than pretending it works.
      expect(
        go(ready(onboarded: false, durable: false), LumeRoutes.home),
        isNull,
      );
    });
  });

  group('no rule can loop', () {
    test('every destination the gate names is a fixed point', () {
      final List<LumeStartupState> states = <LumeStartupState>[
        const LumeStartupState(),
        ready(),
        ready(auth: signedIn()),
        ready(auth: expiredSession()),
        ready(onboarded: false),
        ready(held: '/today/notifications'),
      ];
      final List<String> locations = <String>[
        splash,
        signIn,
        expired,
        account,
        LumeRoutes.home,
        LumeRoutes.onboarding,
        '/tools/tool/calculator',
      ];

      for (final LumeStartupState state in states) {
        for (final String from in locations) {
          final String? once = go(state, from);
          if (once == null) continue;
          // Wherever a redirect lands, redirecting again must stop. A rule
          // that moved twice would move for ever.
          final String? twice = go(state, once);
          expect(
            twice,
            anyOf(isNull, once),
            reason: '$from → $once → $twice under $state',
          );
        }
      }
    });
  });

  group('the launch itself', () {
    test('restores the session exactly once', () async {
      final LumeFakeAuthRepository auth = fakeAuth()..seedSession(kTestEmail);
      final LumeStartupController gate = LumeStartupController(
        authRepository: auth,
        profileRepository: LumeMemoryProfileRepository(),
      );

      await Future.wait<void>(<Future<void>>[
        gate.boot(),
        gate.boot(),
        gate.boot(),
      ]);
      expect(auth.restores, 1);
      expect(gate.state.auth.isAuthenticated, isTrue);
      gate.dispose();
    });

    test(
      'runs the profile migration before anything reads a preference',
      () async {
        final LumeMemoryProfileRepository profiles =
            LumeMemoryProfileRepository(
              initial: const LumeProfileRecord(onboarded: true),
              installation: const LumeInstallationInfo.legacy(),
            );
        final LumeStartupController gate = LumeStartupController(
          authRepository: fakeAuth(),
          profileRepository: profiles,
        );
        await gate.boot();
        expect(
          gate.state.profile.islamic,
          isTrue,
          reason: 'the grandfathered answer, decided before the first read',
        );
        gate.dispose();
      },
    );

    test(
      'a launch that cannot read anything is a guest, and still starts',
      () async {
        final LumeFakeAuthRepository auth = fakeAuth()..seedSession(kTestEmail);
        auth.script.fail(LumeAuthFailure.storage);
        final LumeStartupController gate = LumeStartupController(
          authRepository: auth,
          profileRepository: LumeMemoryProfileRepository(),
        );
        await gate.boot();
        expect(gate.state.isReady, isTrue);
        expect(gate.state.auth.isGuest, isTrue);
        gate.dispose();
      },
    );

    test('holds a real destination and refuses to hold a flow', () async {
      final LumeStartupController gate = LumeStartupController(
        authRepository: fakeAuth(),
        profileRepository: LumeMemoryProfileRepository(),
      );
      gate.hold('/profile/account');
      expect(gate.state.held, '/profile/account');

      for (final String flow in <String>[
        splash,
        signIn,
        LumeRoutes.onboarding,
      ]) {
        gate.hold(flow);
        expect(
          gate.state.held,
          '/profile/account',
          reason: 'sending somebody back into a flow is not resuming anything',
        );
      }

      expect(gate.takeHeld(), '/profile/account');
      expect(gate.takeHeld(), isNull, reason: 'handed over exactly once');
      gate.dispose();
    });

    test('signing in never marks onboarding complete', () async {
      final LumeMemoryProfileRepository profiles = LumeMemoryProfileRepository(
        initial: const LumeProfileRecord(),
        installation: const LumeInstallationInfo.existing(),
      );
      final LumeStartupController gate = LumeStartupController(
        authRepository: fakeAuth(),
        profileRepository: profiles,
      );
      await gate.boot();
      expect(gate.state.profile.onboarded, isFalse);

      gate.signedIn(signedIn());
      expect(
        gate.state.profile.onboarded,
        isFalse,
        reason: 'having an account is not having answered the first questions',
      );
      gate.dispose();
    });

    test('signing out drops the session and the held destination', () async {
      final LumeFakeAuthRepository auth = fakeAuth()..seedSession(kTestEmail);
      final LumeStartupController gate = LumeStartupController(
        authRepository: auth,
        profileRepository: LumeMemoryProfileRepository(),
      );
      await gate.boot();
      gate.hold('/profile/account');
      await gate.signOut();

      expect(gate.state.auth.isGuest, isTrue);
      expect(
        gate.state.held,
        isNull,
        reason:
            'what somebody wanted before signing out is not owed to the '
            'next person holding the phone',
      );
      gate.dispose();
    });

    test('continuing as a guest only applies to an expired session', () async {
      final LumeFakeAuthRepository auth = fakeAuth()..seedSession(kTestEmail);
      final LumeStartupController gate = LumeStartupController(
        authRepository: auth,
        profileRepository: LumeMemoryProfileRepository(),
      );
      await gate.boot();
      await gate.continueAsGuest();
      expect(
        gate.state.auth.isAuthenticated,
        isTrue,
        reason: 'there was nothing expired to leave behind',
      );

      auth.expireSession();
      await auth.restore();
      gate.signedIn(auth.status);
      await gate.continueAsGuest();
      expect(gate.state.auth.isGuest, isTrue);
      gate.dispose();
    });

    test('notifies only when something it publishes has moved', () async {
      final LumeStartupController gate = LumeStartupController(
        authRepository: fakeAuth(),
        profileRepository: LumeMemoryProfileRepository(),
      );
      int notifications = 0;
      gate.addListener(() => notifications++);
      await gate.boot();
      final int afterBoot = notifications;

      gate.hold('/profile/account');
      gate.hold('/profile/account');
      expect(
        notifications,
        afterBoot + 1,
        reason: 'the router re-evaluates on every notification',
      );
      gate.dispose();
    });
  });
}

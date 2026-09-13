/// The launch and the authentication flow, driven through the real router.
///
/// The gate's own tests prove the decision; these prove the wiring — that the
/// decision reaches the navigator, that a deep link survives the detour, and
/// that the screens people actually see appear in the order the state machine
/// says they should.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/auth/application/auth_flow_controller.dart';
import 'package:lume/features/auth/domain/auth_model.dart';
import 'package:lume/features/auth/presentation/auth_flow.dart';
import 'package:lume/features/auth/presentation/auth_parts.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/domain/startup_state.dart';
import 'package:lume/features/startup/presentation/splash_screen.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../auth/auth_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  AppLocalizations strings(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(LumeAuthFlow)));

  Future<void> signIn(WidgetTester tester) async {
    final LumeAuthFlowState state = tester.state<LumeAuthFlowState>(
      find.byType(LumeAuthFlow),
    );
    state.controller
      ..edit(LumeAuthField.email, kTestEmail)
      ..edit(LumeAuthField.password, kTestPassword);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(LumeAuthSubmit).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(LumeAuthSubmit).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  group('the authentication routes', () {
    for (final (LumeAuthRoute route, String label, int _) in kAuthStates) {
      testWidgets('/auth/${route.segment} opens $label', (
        WidgetTester tester,
      ) async {
        final GoRouter router = await pumpLumeRouter(
          tester,
          initialLocation: LumeRoutes.authRoute(route.segment),
        );
        expect(locationOf(router), LumeRoutes.authRoute(route.segment));
        expect(find.byType(LumeAuthFlow), findsOneWidget);
        expect(tester.takeException(), isNull);
        expectNoOverflow(tester);
      });
    }

    testWidgets('a segment nobody defined falls back to sign in', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(tester, initialLocation: '/auth/nonsense');
      final AppLocalizations l = strings(tester);
      expect(find.text(l.authSignInTitle), findsOneWidget);
    });

    testWidgets('the location follows the flow, without rebuilding it', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.authRoute('signin'),
      );
      final LumeAuthFlowState before = tester.state<LumeAuthFlowState>(
        find.byType(LumeAuthFlow),
      );

      before.controller.go(LumeAuthRoute.forgot);
      await tester.pumpAndSettle();

      expect(locationOf(router), '/auth/forgot');
      expect(
        tester.state<LumeAuthFlowState>(find.byType(LumeAuthFlow)),
        same(before),
        reason: 'one controller holds the token, the step and the held route',
      );
    });

    testWidgets('a link straight to a screen moves the flow to it', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRoutes.authRoute('signin'),
      );
      router.go(LumeRoutes.authRoute('signup'));
      await tester.pumpAndSettle();

      final AppLocalizations l = strings(tester);
      expect(find.text(l.authSignUpTitle), findsOneWidget);
    });
  });

  group('the launch', () {
    testWidgets('shows the splash and nothing else while it decides', (
      WidgetTester tester,
    ) async {
      final LumeFakeAuthRepository auth = fakeAuth()
        ..seedSession(kTestEmail)
        ..script.latency = const Duration(milliseconds: 200);

      await pumpLumeRouter(tester, auth: auth, settle: false);
      await tester.pump();
      expect(find.byKey(LumeSplashScreen.surface), findsOneWidget);
      expect(
        find.byType(LumeAuthFlow),
        findsNothing,
        reason: 'Sign In must not flash in front of somebody signed in',
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.byKey(LumeSplashScreen.surface), findsNothing);
    });

    testWidgets('lands on the start route once it knows', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: LumeRouteGate.splash,
      );
      expect(locationOf(router), LumeRoutes.start);
    });
  });

  group('a protected destination', () {
    testWidgets('sends a guest to sign in and says why', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: '/profile/account/security',
      );
      expect(locationOf(router), '/auth/signin');

      final AppLocalizations l = strings(tester);
      expect(
        find.text(l.authNeedAccountText),
        findsOneWidget,
        reason: 'a flow that interrupted something says what it interrupted',
      );
    });

    testWidgets('is resumed after signing in, not swapped for Home', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: '/profile/account/security',
      );
      expect(locationOf(router), '/auth/signin');

      await signIn(tester);
      expect(
        locationOf(router),
        '/profile/account/security',
        reason: 'the deep link survived the detour',
      );
    });

    testWidgets('offers a way to stay a guest, which goes back to the app', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: '/home/account/password',
      );
      expect(find.byType(LumeAuthSecondary), findsOneWidget);
      await tester.ensureVisible(find.byType(LumeAuthSecondary));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LumeAuthSecondary));
      await tester.pumpAndSettle();

      expect(locationOf(router), isNot(startsWith(LumeRoutes.auth)));
      expect(find.byType(LumeAuthFlow), findsNothing);
    });
  });

  group('an expired session', () {
    testWidgets('interrupts the launch with its own screen', (
      WidgetTester tester,
    ) async {
      final LumeFakeAuthRepository auth = fakeAuth()
        ..seedSession(kTestEmail)
        ..expireSession();

      final GoRouter router = await pumpLumeRouter(
        tester,
        auth: auth,
        initialLocation: LumeRoutes.home,
      );
      expect(locationOf(router), '/auth/expired');

      final AppLocalizations l = strings(tester);
      expect(find.text(l.authExpiredTitle), findsOneWidget);
    });

    testWidgets('continuing as a guest ends it, and does not come back', (
      WidgetTester tester,
    ) async {
      final LumeFakeAuthRepository auth = fakeAuth()
        ..seedSession(kTestEmail)
        ..expireSession();

      final GoRouter router = await pumpLumeRouter(
        tester,
        auth: auth,
        initialLocation: LumeRoutes.home,
      );
      final AppLocalizations l = strings(tester);
      await tester.ensureVisible(find.text(l.authContinueAsGuest));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.authContinueAsGuest));
      await tester.pumpAndSettle();

      expect(locationOf(router), LumeRoutes.home);

      // And it stays gone: the next navigation is not interrupted again.
      router.go(LumeRoutes.tools);
      await tester.pumpAndSettle();
      expect(locationOf(router), LumeRoutes.tools);
    });

    testWidgets('signing in again returns to where the user was going', (
      WidgetTester tester,
    ) async {
      final LumeFakeAuthRepository auth = fakeAuth()
        ..seedSession(kTestEmail)
        ..expireSession();

      final GoRouter router = await pumpLumeRouter(
        tester,
        auth: auth,
        initialLocation: '/today/notifications',
      );
      expect(locationOf(router), '/auth/expired');

      final AppLocalizations l = strings(tester);
      await tester.tap(find.text(l.authExpiredCta));
      await tester.pumpAndSettle();
      await signIn(tester);

      expect(locationOf(router), '/today/notifications');
    });
  });

  group('onboarding and authentication do not touch', () {
    testWidgets('the first run is sent to onboarding, not to sign in', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        profile: _DurableProfiles(const LumeProfileRecord()),
        initialLocation: LumeRoutes.home,
      );
      expect(locationOf(router), LumeRoutes.onboarding);
    });

    testWidgets('a completed one is not reopened by a restart', (
      WidgetTester tester,
    ) async {
      final _DurableProfiles profiles = _DurableProfiles(
        const LumeProfileRecord(onboarded: true),
      );
      final GoRouter router = await pumpLumeRouter(
        tester,
        profile: profiles,
        initialLocation: LumeRoutes.home,
      );
      expect(locationOf(router), LumeRoutes.home);
    });

    testWidgets('signing in does not mark the first run finished', (
      WidgetTester tester,
    ) async {
      final _DurableProfiles profiles = _DurableProfiles(
        const LumeProfileRecord(onboarded: true),
      );
      await pumpLumeRouter(
        tester,
        profile: profiles,
        initialLocation: '/auth/signin',
      );
      // The launch itself writes once, to record the one-shot migration. What
      // matters is that nothing after it does.
      final int afterBoot = profiles.writes;
      await signIn(tester);

      expect(
        profiles.writes,
        afterBoot,
        reason: 'authentication writes nothing to the profile',
      );
    });
  });

  group('signing up', () {
    testWidgets('ends on the arrival screen and then in the app', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: '/auth/signup',
      );
      final LumeAuthFlowState state = tester.state<LumeAuthFlowState>(
        find.byType(LumeAuthFlow),
      );
      final AppLocalizations l = strings(tester);

      state.controller
        ..edit(LumeAuthField.name, 'Someone New')
        ..edit(LumeAuthField.email, 'new@example.com');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LumeAuthSubmit).first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      state.controller
        ..edit(LumeAuthField.password, 'Passw0rdy')
        ..edit(LumeAuthField.confirm, 'Passw0rdy');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(LumeAuthSubmit).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LumeAuthSubmit).first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(locationOf(router), '/auth/created');
      expect(find.text(l.authCreatedTitle), findsOneWidget);

      await tester.tap(find.text(l.authEnterCta));
      await tester.pumpAndSettle();
      expect(locationOf(router), LumeRoutes.start);
    });
  });

  group('back', () {
    testWidgets('steps through the flow before leaving it', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: '/auth/signin',
      );
      final LumeAuthFlowState state = tester.state<LumeAuthFlowState>(
        find.byType(LumeAuthFlow),
      );
      state.controller.go(LumeAuthRoute.forgot);
      await tester.pumpAndSettle();
      expect(locationOf(router), '/auth/forgot');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(locationOf(router), '/auth/signin');
    });
  });
}

/// A profile repository that reports itself durable, so the first-run gate is
/// live in the test even though no implementation in the product is.
class _DurableProfiles implements LumeProfileRepository {
  _DurableProfiles(this._record);

  LumeProfileRecord _record;
  int writes = 0;

  @override
  bool get isDurable => true;

  @override
  Future<LumeInstallationInfo> readInstallation() async =>
      const LumeInstallationInfo.existing();

  @override
  Future<LumeProfileRecord> readProfile() async => _record;

  @override
  Future<void> writeProfile(LumeProfileRecord record) async {
    writes++;
    _record = record;
  }
}

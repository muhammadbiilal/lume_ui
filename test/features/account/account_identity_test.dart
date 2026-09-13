/// Personal information and Security.
///
/// The two index routes: neither writes anything itself, and both are read
/// almost entirely for what they *say*. Personal information is the only
/// place the whole identity is on one screen, so it is the place a leak
/// would show. Security is the only place that describes what Lume protects,
/// so it is the place an overclaim would.
///
/// Both are protected, which is asserted where protection lives —
/// `account_reachability_test.dart`. What is asserted here is the screen a
/// reader who is allowed through actually gets.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_settings.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/features/account/data/fake_account_repository.dart';
import 'package:lume/features/account/domain/account_model.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import 'account_harness.dart';

const Size kTall = Size(390, 2400);

/// The seeded account, so a test can say what it expects to see.
final LumeAccountIdentity kAmina = LumeAccountIdentity(
  email: 'amina@example.com',
  createdAt: DateTime(2024, 3, 18),
  displayName: 'Amina Rahman',
  firstName: 'Amina',
  lastName: 'Rahman',
);

void main() {
  setUpAll(loadLumeFonts);

  Finder rowTitled(String title) => find.byWidgetPredicate(
    (Widget w) => w is LumeSettingsRow && w.title == title,
    description: 'settings row "$title"',
  );

  String? valueOf(WidgetTester tester, String title) =>
      tester.widget<LumeSettingsRow>(rowTitled(title)).value;

  // ------------------------------------------------- personal information

  group('personal information', () {
    testWidgets('six rows, in the order the reference puts them', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.account,
        gate: await bootedGate(),
        surface: kTall,
      );
      const List<String> order = <String>[
        'Display name',
        'Email address',
        'Phone number',
        'Region & currency',
        'Account status',
        'Member since',
      ];
      expect(find.byType(LumeSettingsRow), findsNWidgets(order.length));
      double last = -1;
      for (final String title in order) {
        expect(rowTitled(title), findsOneWidget, reason: title);
        final double y = tester.getTopLeft(rowTitled(title)).dy;
        expect(y, greaterThan(last), reason: title);
        last = y;
      }
    });

    testWidgets('and each says what this account actually holds', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.account,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(valueOf(tester, 'Display name'), kAmina.displayName);
      expect(valueOf(tester, 'Email address'), kAmina.email);
      expect(valueOf(tester, 'Account status'), 'Active');
      // With its year, because a membership date without one reads like
      // today.
      expect(valueOf(tester, 'Member since'), '18 March 2024');
    });

    testWidgets('a value it holds and knows to be empty says so', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.account,
        gate: await bootedGate(),
        surface: kTall,
      );
      // The seeded account has no phone. That is a fact about the account,
      // not a gap in the screen, so the row says "Not set" rather than
      // trailing off into white space.
      expect(valueOf(tester, 'Phone number'), isEmpty);
      expect(find.text('Not set'), findsOneWidget);
    });

    testWidgets('a locked account is not described as active', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.account,
        account: LumeFakeAccountRepository(
          identity: LumeAccountIdentity(
            email: kAmina.email,
            createdAt: kAmina.createdAt,
            status: LumeAccountStatus.locked,
          ),
        ),
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(valueOf(tester, 'Account status'), 'Locked');
      expect(find.text('Active'), findsNothing);
    });

    testWidgets('four rows lead somewhere; the two facts do not', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.account,
        gate: await bootedGate(),
        surface: kTall,
      );
      for (final String title in <String>[
        'Display name',
        'Email address',
        'Phone number',
        'Region & currency',
      ]) {
        final LumeSettingsRow row = tester.widget<LumeSettingsRow>(
          rowTitled(title),
        );
        expect(row.onTap, isNotNull, reason: title);
        expect(row.chevron, isTrue, reason: title);
      }
      // A status and a date are facts. A chevron would promise a screen.
      for (final String title in <String>['Account status', 'Member since']) {
        final LumeSettingsRow row = tester.widget<LumeSettingsRow>(
          rowTitled(title),
        );
        expect(row.onTap, isNull, reason: title);
        expect(row.chevron, isFalse, reason: title);
      }
    });

    testWidgets('and each of the four goes where its title says', (
      WidgetTester tester,
    ) async {
      const Map<String, String> destinations = <String, String>{
        'Display name': '/edit',
        'Email address': '/email',
        'Phone number': '/phone',
        'Region & currency': '/region',
      };
      for (final MapEntry<String, String> go in destinations.entries) {
        final GoRouter router = await pumpAccountRouter(
          tester,
          route: LumeAccountRoute.account,
          surface: kTall,
        );
        await tester.tap(rowTitled(go.key));
        await tester.pumpAndSettle();
        expect(locationOf(router), endsWith(go.value), reason: go.key);
      }
    });

    testWidgets('an address waiting to be verified is not yet the address', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.account,
        account: LumeFakeAccountRepository(
          identity: LumeAccountIdentity(
            email: kAmina.email,
            createdAt: kAmina.createdAt,
            pendingEmail: 'amina@newplace.example',
          ),
        ),
        gate: await bootedGate(),
        surface: kTall,
      );
      // The row still shows the address that works; the note says what is
      // waiting, and what has to happen before it counts.
      expect(valueOf(tester, 'Email address'), kAmina.email);
      expect(find.text('Pending verification'), findsOneWidget);
      expect(
        find.text(
          'amina@newplace.example becomes your address once you verify it.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('and with nothing pending there is no note at all', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.account,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.byType(LumeNoteCard), findsNothing);
      expect(find.text('Pending verification'), findsNothing);
    });

    testWidgets('deletion sits in its own block, below everything routine', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.account,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.byType(LumeDangerZone), findsOneWidget);
      // An overline: the kicker is drawn in caps, which is styling rather
      // than a different string.
      expect(find.text('DANGER ZONE'), findsOneWidget);
      expect(find.text('Permanently remove your Lume account'), findsOneWidget);
      // Never adjacent to a routine row: it is the last thing on the screen.
      expect(
        tester.getTopLeft(rowTitled('Member since')).dy,
        lessThan(tester.getTopLeft(find.byType(LumeDangerZone)).dy),
      );
    });

    testWidgets('and its button opens the screen that asks, not the deed', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpAccountRouter(
        tester,
        route: LumeAccountRoute.account,
        surface: kTall,
      );
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      expect(locationOf(router), endsWith('/delete'));
      // Nothing has happened yet. The delete route asks for a password and
      // then asks again; see `account_destructive_test.dart`.
      expect(find.text('Delete account'), findsWidgets);
    });

    testWidgets('a reader without an account is told, not shown', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.account,
        account: LumeFakeAccountRepository.guest(),
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.byType(LumeToolState), findsOneWidget);
      expect(
        find.text('This part of Lume belongs to your account.'),
        findsOneWidget,
      );
      expect(find.text('Sign in'), findsOneWidget);
      // No rows, no identity, and no danger zone for an account that is not
      // there to delete.
      expect(find.byType(LumeSettingsRow), findsNothing);
      expect(find.byType(LumeDangerZone), findsNothing);
    });

    testWidgets('a session that has run out gets the same refusal', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.account,
        account: LumeFakeAccountRepository.expired(),
        gate: await bootedGate(),
        surface: kTall,
      );
      // The device still remembers the account; the session does not. The
      // details are not drawn from a remembered identity.
      expect(find.byType(LumeSettingsRow), findsNothing);
      expect(find.textContaining('amina@example.com'), findsNothing);
      expect(find.textContaining('Amina'), findsNothing);
    });

    testWidgets('nothing on the screen is a password or a token', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.account,
        gate: await bootedGate(),
        surface: kTall,
      );
      await tester.pumpAndSettle();
      final List<String> said = semanticStrings(tester);
      handle.dispose();

      expect(said, isNotEmpty);
      for (final String text in said) {
        expect(text.contains('correct horse'), isFalse, reason: text);
        expect(text.toLowerCase().contains('token'), isFalse, reason: text);
      }
    });
  });

  // -------------------------------------------------------------- security

  group('security', () {
    testWidgets('two doors and a note, and nothing that was never built', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.security,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.byType(LumeSettingsRow), findsNWidgets(2));
      expect(rowTitled('Change password'), findsOneWidget);
      expect(rowTitled('Active sessions'), findsOneWidget);
      // A row reading "Off" for something that does not exist still
      // advertises it (§124.13).
      for (final String never in <String>[
        'Two-factor',
        'Biometric',
        'Face ID',
        'Sign-in alerts',
        'Recovery codes',
      ]) {
        expect(find.textContaining(never), findsNothing, reason: never);
      }
    });

    testWidgets('the note says what is protected and what is not', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.security,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.byType(LumeNoteCard), findsOneWidget);
      expect(find.text('What Lume protects'), findsOneWidget);
      expect(
        find.textContaining('no two-factor or biometric unlock in this build'),
        findsOneWidget,
      );
    });

    testWidgets('the password row promises nothing it cannot know', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.security,
        gate: await bootedGate(),
        surface: kTall,
      );
      // "Last changed" would be a date this build does not have. It says so.
      expect(
        find.text('Last changed is not recorded on this device'),
        findsOneWidget,
      );
    });

    testWidgets('the sessions row counts the devices, and counts them once', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.security,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.text('3 signed in'), findsOneWidget);
    });

    testWidgets('and says "1 signed in" rather than "1 signed ins"', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.security,
        account: LumeFakeAccountRepository.aloneOnThisDevice(),
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.text('1 signed in'), findsOneWidget);
    });

    testWidgets('both rows go where their titles say', (
      WidgetTester tester,
    ) async {
      const Map<String, String> destinations = <String, String>{
        'Change password': '/password',
        'Active sessions': '/sessions',
      };
      for (final MapEntry<String, String> go in destinations.entries) {
        final GoRouter router = await pumpAccountRouter(
          tester,
          route: LumeAccountRoute.security,
          surface: kTall,
        );
        await tester.tap(rowTitled(go.key));
        await tester.pumpAndSettle();
        expect(locationOf(router), endsWith(go.value), reason: go.key);
      }
    });

    testWidgets('signing the others out says how many, and leaves this one', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository account = LumeFakeAccountRepository();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.security,
        account: account,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.text('3 signed in'), findsOneWidget);

      await tester.tap(find.text('Sign out all other devices'));
      await tester.pumpAndSettle();
      // It asks first. Signing a reader out of their other devices is not
      // undoable from here, so the button opens a question rather than doing
      // it — and the question's own confirm is what acts.
      expect(find.byType(LumeDeleteConfirmation), findsOneWidget);
      await tester.tap(find.text('Sign out all other devices').last);
      await tester.pumpAndSettle();

      // Two went; this device stays, because the reader is using it.
      expect(find.text('Signed out 2 other devices'), findsOneWidget);
      expect(find.text('1 signed in'), findsOneWidget);
      final List<LumeDeviceSession> left = await account.sessions();
      expect(left, hasLength(1));
      expect(left.single.isCurrent, isTrue);
    });

    testWidgets('and doing it twice does not claim a second time', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.security,
        account: LumeFakeAccountRepository.aloneOnThisDevice(),
        gate: await bootedGate(),
        surface: kTall,
      );
      await tester.tap(find.text('Sign out all other devices'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out all other devices').last);
      await tester.pumpAndSettle();

      // Nothing to sign out, and the count it reports is the count it acted
      // on. The reference offers the control here whether or not there is
      // anything to revoke — the Sessions route is the one that hides it —
      // so "0" is the honest answer rather than a missing one.
      expect(find.text('Signed out 0 other devices'), findsOneWidget);
      expect(find.text('1 signed in'), findsOneWidget);
    });

    testWidgets('a reader without an account is told, not shown', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.security,
        account: LumeFakeAccountRepository.guest(),
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.byType(LumeToolState), findsOneWidget);
      expect(find.byType(LumeSettingsRow), findsNothing);
      expect(find.text('Sign out all other devices'), findsNothing);
      expect(find.byType(LumeNoteCard), findsNothing);
    });

    testWidgets('no device is identified by anything but its own name', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.security,
        gate: await bootedGate(),
        surface: kTall,
      );
      await tester.pumpAndSettle();
      final List<String> said = semanticStrings(tester);
      handle.dispose();

      expect(said, isNotEmpty);
      for (final String text in said) {
        expect(text.contains('dev-'), isFalse, reason: text);
      }
    });
  });
}

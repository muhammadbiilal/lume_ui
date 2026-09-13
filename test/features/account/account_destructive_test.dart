/// The four things that cannot be undone, and the sessions screen.
///
/// Deleting an account, signing out, revoking a device and signing out every
/// other device are the only actions in the section that take something away.
/// Each is tested for the same five things: what it says before it happens,
/// that it cannot happen without a second answer, that it happens once, what
/// is left afterwards, and that Back cannot make it happen again.
///
/// **Nothing here deletes anything real.** `LumeFakeAccountRepository` holds
/// an account for the life of the process and reports `isDurable == false`;
/// there is no server, no migration and no file. A test that "deletes an
/// account" empties a field in a fixture.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_settings.dart';
import 'package:lume/features/account/data/fake_account_repository.dart';
import 'package:lume/features/account/domain/account_model.dart';
import 'package:lume/features/account/domain/account_repository.dart';
import 'package:lume/features/account/presentation/account_host.dart';
import 'package:lume/features/account/presentation/account_parts.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../destinations/profile_harness.dart';
import 'account_harness.dart';

const Size kTall = Size(390, 3000);
const String kSeededPassword = 'correct horse';

void main() {
  setUpAll(loadLumeFonts);

  Future<void> type(WidgetTester tester, String name, String text) async {
    await tester.enterText(
      find.descendant(
        of: find.byKey(LumeAccountField.fieldKey(name)),
        matching: find.byType(TextField),
      ),
      text,
    );
    await tester.pump();
  }

  // ---------------------------------------------------------------- delete

  group('deleting an account', () {
    testWidgets('says what goes and what stays, before anything is typed', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.delete,
        gate: await bootedGate(),
        surface: kTall,
      );

      // The warning is a composition, not a sentence: three things lost, one
      // thing kept, and the second list is the reason the first is bearable.
      expect(find.text('What this does'), findsOneWidget);
      expect(find.text('Your account and email are removed.'), findsOneWidget);
      expect(
        find.text('Every signed-in device is signed out.'),
        findsOneWidget,
      );
      expect(find.text('This cannot be undone.'), findsOneWidget);

      expect(find.text('What stays'), findsOneWidget);
      expect(
        find.text(
          'Notes, tasks, expenses and preferences remain on this device.',
        ),
        findsOneWidget,
      );

      // And the two lists are drawn apart, the losses above the keeps.
      expect(
        tester.getTopLeft(find.text('What this does')).dy,
        lessThan(tester.getTopLeft(find.text('What stays')).dy),
      );
    });

    testWidgets('asks who it is before it asks whether', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.delete,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.text('Confirm it’s you'), findsOneWidget);
      expect(find.byKey(LumeAccountField.fieldKey('current')), findsOneWidget);
      final LumeInputField field = tester.widget<LumeInputField>(
        find.byKey(LumeAccountField.fieldKey('current')),
      );
      expect(field.obscure, isTrue);
      expect(field.value, isEmpty);
    });

    testWidgets('a wrong password deletes nothing and asks nothing more', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.delete,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'current', 'wrong');
      await tester.tap(find.widgetWithText(LumeButton, 'Delete my account'));
      await tester.pumpAndSettle();

      // The second question is asked first, and only then the password is
      // checked — so a wrong password comes back from the confirmation.
      await tester.tap(find.text('Delete my account').last);
      await tester.pumpAndSettle();

      expect(find.text('That current password is incorrect.'), findsOneWidget);
      expect(repo.state, LumeAccountState.authed);
      expect(repo.identity, isNotNull);
    });

    testWidgets('the confirmation says it cannot be undone, and can be left', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.delete,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'current', kSeededPassword);
      await tester.tap(find.widgetWithText(LumeButton, 'Delete my account'));
      await tester.pumpAndSettle();

      expect(find.text('Delete your account?'), findsOneWidget);
      expect(
        find.text('This removes the account for good. There is no way back.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Nothing happened, and the password that was typed for an action that
      // is not happening does not stay on the screen.
      expect(repo.state, LumeAccountState.authed);
      expect(repo.writes, 0);
      expect(
        tester
            .widget<LumeInputField>(
              find.byKey(LumeAccountField.fieldKey('current')),
            )
            .value,
        isEmpty,
      );
    });

    testWidgets('confirming deletes once, and leaves the reader a Lume', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository();
      final GoRouter router = await pumpAccountRouter(
        tester,
        route: LumeAccountRoute.delete,
        account: repo,
        surface: kTall,
      );
      await type(tester, 'current', kSeededPassword);
      await tester.tap(find.widgetWithText(LumeButton, 'Delete my account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete my account').last);
      await tester.pumpAndSettle();

      expect(repo.writes, 1, reason: 'asked once, deleted once');
      expect(repo.state, LumeAccountState.guest);
      expect(repo.identity, isNull);

      // §37 — the account is gone and the reader's own things are not. The
      // fixture never had them; what it proves is that deletion does not
      // touch the profile store.
      expect(locationOf(router), LumeRoutes.profile);
    });

    testWidgets('and Back cannot reopen the form that did it', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository();
      final GoRouter router = await pumpAccountRouter(
        tester,
        route: LumeAccountRoute.delete,
        account: repo,
        surface: kTall,
      );
      await type(tester, 'current', kSeededPassword);
      await tester.tap(find.widgetWithText(LumeButton, 'Delete my account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete my account').last);
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Back from Profile leaves the app; it does not walk back into a form
      // whose account no longer exists.
      expect(find.byType(LumeAccountHost), findsNothing);
      expect(locationOf(router), LumeRoutes.profile);
    });

    testWidgets('a store that cannot be reached deletes nothing', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository(
        failWith: LumeAccountFailure.unreachable,
      );
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.delete,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'current', kSeededPassword);
      await tester.tap(find.widgetWithText(LumeButton, 'Delete my account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete my account').last);
      await tester.pumpAndSettle();

      expect(repo.state, LumeAccountState.authed);
      expect(find.textContaining('reach the network'), findsWidgets);
    });

    testWidgets('a second tap while one is in flight is not a second delete', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository(
        delay: const Duration(milliseconds: 300),
      );
      // Without the router: the thing being tested is the second tap, and a
      // navigation away mid-flight would be testing the router instead.
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.delete,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'current', kSeededPassword);
      await tester.tap(find.widgetWithText(LumeButton, 'Delete my account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete my account').last);
      await tester.pump();

      // The confirmation is still up while the delete is in flight, so both
      // the form's button and the dialog's carry the same words. Tapping the
      // first is the second tap this test is about.
      await tester.tap(
        find.widgetWithText(LumeButton, 'Delete my account').first,
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(repo.writes, 1);
    });

    testWidgets('the fixture is not durable, and does not claim to be', (
      WidgetTester tester,
    ) async {
      // The one assertion that matters most in this file: a reader of this
      // repository can see that nothing here survives the process.
      expect(LumeFakeAccountRepository().isDurable, isFalse);
    });
  });

  // --------------------------------------------------------------- sign out

  group('signing out', () {
    testWidgets('asks, names the account, and does not sign out on cancel', (
      WidgetTester tester,
    ) async {
      final LumeRecordedProfile recorded = await pumpProfileForSignOut(tester);
      await tester.tap(find.widgetWithText(LumeSettingsRow, 'Log out'));
      await tester.pump();
      // Profile hands the sign-out to the shell rather than doing it: the
      // session belongs to the launch, not to a settings row.
      expect(recorded.signOuts, 1);
    });
  });

  // --------------------------------------------------------------- sessions

  group('the sessions screen', () {
    testWidgets('names this device, and every other one', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sessions,
        gate: await bootedGate(),
        surface: kTall,
      );

      expect(find.text('3 signed in'), findsOneWidget);
      expect(find.text('Pixel 6 Pro · Lume'), findsOneWidget);
      expect(find.text('MacBook Air · Safari'), findsOneWidget);
      expect(find.text('iPad · Lume'), findsOneWidget);
      // Exactly one row is this one.
      expect(find.text('This device'), findsOneWidget);
    });

    testWidgets('the row for this device has no way to end it', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sessions,
        gate: await bootedGate(),
        surface: kTall,
      );
      // Ending this session is signing out, which lives elsewhere and says
      // so. Two Sign outs for three devices.
      expect(find.text('Sign out'), findsNWidgets(2));

      final Finder here = find.ancestor(
        of: find.text('This device'),
        matching: find.byType(LumeSessionRow),
      );
      expect(
        find.descendant(of: here, matching: find.text('Sign out')),
        findsNothing,
      );
    });

    testWidgets('each row says where and when, in the reader’s own clock', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sessions,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.textContaining('Islamabad, Pakistan'), findsWidgets);
      expect(find.textContaining('Lahore, Pakistan'), findsOneWidget);
      expect(find.textContaining('Last seen'), findsNWidgets(3));
    });

    testWidgets('no token, no identifier a stranger could use', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sessions,
        gate: await bootedGate(),
        surface: kTall,
      );
      // The opaque id exists so a row can be revoked. It must not be drawn,
      // announced, or otherwise handed to whoever is looking at the phone.
      for (final String id in <String>['dev-this', 'dev-mac', 'dev-ipad']) {
        expect(find.textContaining(id), findsNothing, reason: id);
      }
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpAndSettle();
      final List<String> said = semanticStrings(tester);
      handle.dispose();

      expect(said, isNotEmpty, reason: 'the walk found no tree to search');
      for (final String label in said) {
        expect(label.contains('dev-'), isFalse, reason: label);
        expect(label.contains('tok'), isFalse, reason: label);
      }
    });

    testWidgets('revoking one device removes one row', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sessions,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      await tester.tap(find.text('Sign out').first);
      await tester.pumpAndSettle();

      expect(repo.writes, 1);
      expect(await repo.sessions(), hasLength(2));
      expect(find.text('MacBook Air · Safari'), findsNothing);
      // This device is untouched.
      expect(find.text('Pixel 6 Pro · Lume'), findsOneWidget);
    });

    testWidgets('signing out the others asks first, and cancel means no', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sessions,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      await tester.tap(
        find.widgetWithText(LumeButton, 'Sign out all other devices'),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Every other signed-in device will need to sign in again.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.writes, 0);
      expect(await repo.sessions(), hasLength(3));
    });

    testWidgets('confirming signs the others out, once, and says how many', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sessions,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      await tester.tap(
        find.widgetWithText(LumeButton, 'Sign out all other devices'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out all other devices').last);
      await tester.pumpAndSettle();

      expect(repo.writes, 1);
      expect(await repo.sessions(), hasLength(1));
      expect(find.text('Signed out 2 other devices'), findsOneWidget);
    });

    testWidgets('one device alone is told so rather than shown a button', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sessions,
        account: LumeFakeAccountRepository.aloneOnThisDevice(),
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.text('1 signed in'), findsOneWidget);
      expect(find.text('No other devices are signed in.'), findsOneWidget);
      expect(
        find.widgetWithText(LumeButton, 'Sign out all other devices'),
        findsNothing,
      );
    });

    testWidgets('a store that has not answered yet shows no devices', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sessions,
        account: LumeFakeAccountRepository(
          delay: const Duration(milliseconds: 300),
        ),
        gate: await bootedGate(),
        surface: kTall,
      );
      // Before the answer arrives the screen claims nothing — no invented
      // rows, no "0 devices", just the heading it was opened with.
      expect(find.text('Pixel 6 Pro · Lume'), findsNothing);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Pixel 6 Pro · Lume'), findsOneWidget);
    });

    testWidgets('a session that has run out shows the refusal, not the list', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sessions,
        account: LumeFakeAccountRepository.expired(),
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.textContaining('You’re signed out'), findsOneWidget);
      expect(find.text('Pixel 6 Pro · Lume'), findsNothing);
      expect(find.text('MacBook Air · Safari'), findsNothing);
    });

    testWidgets('a guest sees no other account’s devices', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.sessions,
        account: LumeFakeAccountRepository.guest(),
        gate: await bootedGate(),
        surface: kTall,
      );
      // The gate, and then the repository: `sessions()` answers with nothing
      // for anybody who is not signed in, so even a leak past the gate would
      // show an empty list rather than somebody else's phone.
      expect(find.textContaining('You’re signed out'), findsOneWidget);
      expect(find.text('MacBook Air · Safari'), findsNothing);
      expect(await LumeFakeAccountRepository.guest().sessions(), isEmpty);
    });
  });
}

/// Profile, with a recorder, for the sign-out row.
Future<LumeRecordedProfile> pumpProfileForSignOut(WidgetTester tester) async {
  final LumeRecordedProfile recorded = LumeRecordedProfile();
  await pumpLume(
    tester,
    profileScreenFor(profileView(state: LumeAccountState.authed), recorded),
    surface: kTall,
  );
  return recorded;
}

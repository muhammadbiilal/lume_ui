/// The account's four forms, and the guard over all of them.
///
/// Edit, email, phone and password are the only routes that *hold* something
/// before it is written, which makes them the only routes where the reader can
/// lose work, submit twice, or leave a password in memory. Everything here is
/// about those three risks.
///
/// **Nothing connects.** Every repository is `LumeFakeAccountRepository`, and
/// it says so: `isDurable` is `false`, no write survives the process, and a
/// password is compared against a seeded string that never leaves the fixture.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/features/account/application/account_form.dart';
import 'package:lume/features/account/data/fake_account_repository.dart';
import 'package:lume/features/account/domain/account_model.dart';
import 'package:lume/features/account/domain/account_repository.dart';
import 'package:lume/features/account/presentation/account_host.dart';
import 'package:lume/features/account/presentation/account_parts.dart';

import '../../helpers/load_fonts.dart';
import 'account_harness.dart';

/// Tall, so a form's own foot is laid out and a button below the fold can be
/// tapped without scrolling the test.
const Size kTall = Size(390, 3000);

/// The password the fixture was seeded with. It exists here and nowhere in
/// the product: no screen, no log and no semantics ever sees it.
const String kSeededPassword = 'correct horse';

void main() {
  setUpAll(loadLumeFonts);

  /// One field, by the name its value is stored under. Addressing it by the
  /// words above it would be addressing it by the language.
  Finder fieldNamed(String name) => find.byKey(LumeAccountField.fieldKey(name));

  /// The text a field is showing, read from its controller rather than from
  /// the rendered glyphs — an obscured field draws dots.
  String valueOf(WidgetTester tester, String name) =>
      tester.widget<LumeInputField>(fieldNamed(name)).value;

  Future<void> type(
    WidgetTester tester,
    String name,
    String text, {
    bool blur = true,
  }) async {
    final Finder field = find.descendant(
      of: fieldNamed(name),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, text);
    await tester.pump();
    if (blur) {
      // Blur is where the checks a field can be judged on alone happen.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
    }
  }

  // ------------------------------------------------------------------ edit

  group('the edit form', () {
    testWidgets('opens on the account it is editing', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.edit,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(valueOf(tester, 'displayName'), 'Amina Rahman');
      expect(valueOf(tester, 'firstName'), 'Amina');
      expect(valueOf(tester, 'lastName'), 'Rahman');
      // An empty phone is a value the account holds and knows to be empty.
      expect(valueOf(tester, 'phone'), '');
      // Nothing to save yet, so the button is off and says so.
      expect(find.text('Nothing to save yet'), findsOneWidget);
      final LumeButton save = tester.widget<LumeButton>(
        find.widgetWithText(LumeButton, 'Save changes'),
      );
      expect(save.onPressed, isNull);
    });

    testWidgets('a guest edits the one thing a guest has', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.edit,
        account: LumeFakeAccountRepository.guest(),
        gate: await bootedGate(),
        surface: kTall,
      );
      // §124.4 — the name onboarding took can be changed. Everything else on
      // this form belongs to an account.
      expect(find.text('DISPLAY NAME'), findsOneWidget);
      expect(find.text('FIRST NAME · Optional'), findsNothing);
      expect(find.text('PHONE · Optional'), findsNothing);
      expect(find.text('Guest'), findsOneWidget);
    });

    testWidgets('typing turns the button on, and undoing turns it off', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.edit,
        gate: await bootedGate(),
        surface: kTall,
      );

      await type(tester, 'displayName', 'Amina R');
      expect(find.text('Nothing to save yet'), findsNothing);
      expect(
        tester
            .widget<LumeButton>(find.widgetWithText(LumeButton, 'Save changes'))
            .onPressed,
        isNotNull,
      );

      // Back to what it was: the form is clean again, because dirty is a
      // comparison rather than a flag somebody set.
      await type(tester, 'displayName', 'Amina Rahman');
      expect(find.text('Nothing to save yet'), findsOneWidget);
      expect(
        tester
            .widget<LumeButton>(find.widgetWithText(LumeButton, 'Save changes'))
            .onPressed,
        isNull,
      );
    });

    testWidgets('a name of nothing but spaces becomes no name at all', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.edit,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'displayName', '   ');
      await tester.tap(find.widgetWithText(LumeButton, 'Save changes'));
      await tester.pumpAndSettle();

      // Not refused: `updateUser` in `account.js` trims a blank name and
      // stores it, and the identity card is built for exactly that — with no
      // name the address is the identity. Refusing it here would make the
      // nameless state unreachable through the form that creates it.
      expect(repo.writes, 1, reason: 'the form was sent');
      expect(repo.identity!.displayName, isEmpty);
      // And the account is not nameless: `fullName` falls back to the first
      // and last names, which this form did not touch.
      expect(repo.identity!.fullName, 'Amina Rahman');
    });

    testWidgets('surrounding space is trimmed on the way in', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.edit,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'displayName', '  Amina Rahim  ');
      await tester.tap(find.widgetWithText(LumeButton, 'Save changes'));
      await tester.pumpAndSettle();
      expect(repo.identity!.displayName, 'Amina Rahim');
    });

    testWidgets('a number Lume cannot read is refused, and the draft stays', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.edit,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'phone', 'not a number');
      await tester.tap(find.widgetWithText(LumeButton, 'Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a phone number Lume can read.'), findsOneWidget);
      // A failed save keeps what was typed. Losing it would be the second
      // injury.
      expect(valueOf(tester, 'phone'), 'not a number');
      expect(repo.identity!.phone, '');
    });

    testWidgets('the name is capped where the reference caps it', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.edit,
        gate: await bootedGate(),
        surface: kTall,
      );
      final LumeInputField field = tester.widget<LumeInputField>(
        fieldNamed('displayName'),
      );
      expect(field.maxLength, 40);
    });

    testWidgets('a successful save writes once and leaves', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.edit,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'displayName', 'Amina Rahim');
      await tester.tap(find.widgetWithText(LumeButton, 'Save changes'));
      await tester.pumpAndSettle();

      expect(repo.writes, 1);
      expect(repo.identity!.displayName, 'Amina Rahim');
      expect(find.text('Profile updated'), findsOneWidget);
    });

    testWidgets('a second tap while one is in flight is not a second write', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository(
        delay: const Duration(milliseconds: 300),
      );
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.edit,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'displayName', 'Amina Rahim');

      await tester.tap(find.widgetWithText(LumeButton, 'Save changes'));
      await tester.pump();
      // Busy: the button is inert and the fields are too.
      final LumeButton busy = tester.widget<LumeButton>(
        find.widgetWithText(LumeButton, 'Save changes'),
      );
      expect(busy.busy, isTrue);
      expect(busy.onPressed, isNull);

      await tester.tap(
        find.widgetWithText(LumeButton, 'Save changes'),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(repo.writes, 1, reason: 'one tap, one write');
    });

    testWidgets('nothing reachable can be reached while a save is in flight', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.edit,
        account: LumeFakeAccountRepository(
          delay: const Duration(milliseconds: 300),
        ),
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'displayName', 'Amina Rahim');
      await tester.tap(find.widgetWithText(LumeButton, 'Save changes'));
      await tester.pump();

      for (final LumeInputField field in tester.widgetList<LumeInputField>(
        find.byType(LumeInputField),
      )) {
        expect(field.enabled, isFalse);
      }
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    });

    testWidgets('a store that cannot be reached says so over the form', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository(
        failWith: LumeAccountFailure.unreachable,
      );
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.edit,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'displayName', 'Amina Rahim');
      await tester.tap(find.widgetWithText(LumeButton, 'Save changes'));
      await tester.pumpAndSettle();

      expect(find.textContaining('reach the network'), findsWidgets);
      // And the draft is still there to try again with.
      expect(valueOf(tester, 'displayName'), 'Amina Rahim');
    });

    testWidgets('a store that refuses to write says which store', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.edit,
        account: LumeFakeAccountRepository(
          failWith: LumeAccountFailure.storage,
        ),
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'displayName', 'Amina Rahim');
      await tester.tap(find.widgetWithText(LumeButton, 'Save changes'));
      await tester.pumpAndSettle();
      expect(find.textContaining('save to this device'), findsWidgets);
    });
  });

  // ----------------------------------------------------------------- email

  group('the address form', () {
    testWidgets('opens empty, beside the address it would replace', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.email,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(valueOf(tester, 'email'), '');
      expect(find.text('amina@example.com'), findsWidgets);
    });

    testWidgets('an address that is not one is refused', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.email,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'email', 'amina@');
      await tester.tap(find.widgetWithText(LumeButton, 'Change'));
      await tester.pumpAndSettle();

      expect(find.textContaining('email address'), findsWidgets);
      expect(repo.identity!.pendingEmail, isNull);
    });

    testWidgets('the address it already is, is refused', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.email,
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'email', 'amina@example.com');
      await tester.tap(find.widgetWithText(LumeButton, 'Change'));
      await tester.pumpAndSettle();
      expect(find.textContaining('already'), findsWidgets);
    });

    testWidgets('a change is pending until it is verified', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.email,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'email', 'amina@lume.test');
      await tester.tap(find.widgetWithText(LumeButton, 'Change'));
      await tester.pumpAndSettle();

      // The identity has *not* moved. That is the whole point of pending.
      expect(repo.identity!.email, 'amina@example.com');
      expect(repo.identity!.pendingEmail, 'amina@lume.test');
      expect(find.text('Pending verification'), findsWidgets);
    });

    testWidgets('the address carries an autofill hint and an email keyboard', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.email,
        gate: await bootedGate(),
        surface: kTall,
      );
      final LumeInputField field = tester.widget<LumeInputField>(
        find.byType(LumeInputField),
      );
      expect(field.autofillHints, contains(AutofillHints.email));
      expect(field.keyboardType, TextInputType.emailAddress);
      expect(field.textInputAction, TextInputAction.done);
    });
  });

  // ----------------------------------------------------------------- phone

  group('the phone form', () {
    testWidgets('opens on the number the account holds', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.phone,
        account: LumeFakeAccountRepository(
          identity: LumeAccountIdentity(
            email: 'amina@example.com',
            createdAt: DateTime(2024, 3, 18),
            displayName: 'Amina Rahman',
            phone: '+92 300 1234567',
          ),
        ),
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(valueOf(tester, 'phone'), '+92 300 1234567');
      // A number that is there can be removed.
      expect(find.widgetWithText(LumeButton, 'Remove'), findsOneWidget);
    });

    testWidgets('with no number there is nothing to remove', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.phone,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.widgetWithText(LumeButton, 'Remove'), findsNothing);
    });

    testWidgets('says what the number is for, and what it is not for', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.phone,
        gate: await bootedGate(),
        surface: kTall,
      );
      // There is no phone sign-in and no phone recovery in this build, and
      // the screen says so rather than letting the field imply one.
      expect(find.text('What this is for'), findsOneWidget);
      expect(find.textContaining('no phone sign-in'), findsOneWidget);
    });

    testWidgets('a saved number is written once', (WidgetTester tester) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.phone,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'phone', '+92 300 1234567');
      await tester.tap(find.widgetWithText(LumeButton, 'Save'));
      await tester.pumpAndSettle();

      expect(repo.writes, 1);
      expect(repo.identity!.phone, '+92 300 1234567');
      expect(find.text('Phone number saved'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------- password

  group('the password form', () {
    testWidgets('opens empty, three times over', (WidgetTester tester) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.password,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(valueOf(tester, 'current'), '');
      expect(valueOf(tester, 'password'), '');
      expect(valueOf(tester, 'confirm'), '');
    });

    testWidgets('every field is obscured, with a way to look', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.password,
        gate: await bootedGate(),
        surface: kTall,
      );
      final List<LumeInputField> fields = tester
          .widgetList<LumeInputField>(find.byType(LumeInputField))
          .toList();
      expect(fields, hasLength(3));
      for (final LumeInputField f in fields) {
        expect(f.obscure, isTrue);
        expect(f.revealed, isFalse);
        expect(f.onToggleReveal, isNotNull);
        expect(f.revealShowLabel, isNotNull);
      }
    });

    testWidgets('looking at one does not reveal the others', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.password,
        gate: await bootedGate(),
        surface: kTall,
      );
      await tester.tap(find.bySemanticsLabel('Show password').first);
      await tester.pumpAndSettle();

      final List<LumeInputField> fields = tester
          .widgetList<LumeInputField>(find.byType(LumeInputField))
          .toList();
      expect(fields[0].revealed, isTrue);
      expect(fields[1].revealed, isFalse);
      expect(fields[2].revealed, isFalse);
    });

    testWidgets('the rules on screen are the rules the engine enforces', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.password,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(find.text('PASSWORD MUST CONTAIN'), findsOneWidget);
      expect(find.text('at least 8 characters'), findsOneWidget);
      expect(find.text('an uppercase letter'), findsOneWidget);
      expect(find.text('a lowercase letter'), findsOneWidget);
      expect(find.text('a number'), findsOneWidget);
    });

    testWidgets('a wrong current password is refused first', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.password,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'current', 'wrong');
      await type(tester, 'password', 'short');
      await type(tester, 'confirm', 'different');
      await tester.tap(find.widgetWithText(LumeButton, 'Update password'));
      await tester.pumpAndSettle();

      // The reference's order: a reader who mistypes the current one is not
      // also told their new one is weak.
      expect(find.text('That current password is incorrect.'), findsOneWidget);
      expect(find.textContaining('requirements'), findsNothing);
    });

    testWidgets('a weak new password is refused, then a mismatch', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.password,
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'current', kSeededPassword);
      await type(tester, 'password', 'short');
      await type(tester, 'confirm', 'short');
      await tester.tap(find.widgetWithText(LumeButton, 'Update password'));
      await tester.pumpAndSettle();
      expect(find.textContaining('requirements'), findsWidgets);

      await type(tester, 'password', 'Str0ngEnough');
      await type(tester, 'confirm', 'Str0ngEnoughX');
      await tester.tap(find.widgetWithText(LumeButton, 'Update password'));
      await tester.pumpAndSettle();
      expect(find.textContaining('don’t match'), findsWidgets);
    });

    testWidgets('a change signs every other device out', (
      WidgetTester tester,
    ) async {
      final LumeFakeAccountRepository repo = LumeFakeAccountRepository();
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.password,
        account: repo,
        gate: await bootedGate(),
        surface: kTall,
      );
      expect(await repo.sessions(), hasLength(3));

      await type(tester, 'current', kSeededPassword);
      await type(tester, 'password', 'Str0ngEnough');
      await type(tester, 'confirm', 'Str0ngEnough');
      await tester.tap(find.widgetWithText(LumeButton, 'Update password'));
      await tester.pumpAndSettle();

      expect(repo.writes, 1);
      // A password change that left the old sessions alive would not be one.
      expect(await repo.sessions(), hasLength(1));
    });

    testWidgets('and the three passwords do not stay in memory', (
      WidgetTester tester,
    ) async {
      final LumeAccountForm form = LumeAccountForm()
        ..reset(<String, String>{
          'current': kSeededPassword,
          'password': 'Str0ngEnough',
          'confirm': 'Str0ngEnough',
        });
      expect(form.read('current'), isNotEmpty);

      form.wipe();
      expect(form.read('current'), isEmpty);
      expect(form.read('password'), isEmpty);
      expect(form.read('confirm'), isEmpty);
      expect(form.dirty, isFalse);
      expect(form.isRevealed('current'), isFalse);

      // And disposing does it too, for the screen that is simply closed.
      final LumeAccountForm disposed = LumeAccountForm()
        ..reset(<String, String>{'current': kSeededPassword})
        ..dispose();
      expect(disposed.read('current'), isEmpty);
    });

    testWidgets('nothing typed here reaches a semantic label', (
      WidgetTester tester,
    ) async {
      await pumpAccountHost(
        tester,
        route: LumeAccountRoute.password,
        gate: await bootedGate(),
        surface: kTall,
      );
      await type(tester, 'current', kSeededPassword);

      // A screen reader is told there is a password field, never what is in
      // it. The controller necessarily holds the characters while they are
      // being typed; what must not happen is those characters reaching a
      // *label*, a *value* or a *hint* — which is everything assistive
      // technology, and anything reading the semantics tree, can see.
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpAndSettle();
      final List<String> exposed = semanticStrings(tester);
      handle.dispose();

      expect(exposed, isNotEmpty, reason: 'the walk found no tree to search');
      for (final String text in exposed) {
        expect(
          text.contains(kSeededPassword),
          isFalse,
          reason: 'a password reached the semantics tree',
        );
      }
    });
  });

  // ------------------------------------------------------------ the guard

  group('the unsaved-changes guard', () {
    // Through the real router, because leaving is the thing being tested and
    // only the router can be left.
    Future<void> openEdit(
      WidgetTester tester, {
      LumeFakeAccountRepository? account,
    }) async {
      await pumpAccountRouter(
        tester,
        route: LumeAccountRoute.edit,
        account: account,
        surface: kTall,
      );
    }

    testWidgets('a clean form leaves without asking', (
      WidgetTester tester,
    ) async {
      await openEdit(tester);
      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();
      expect(find.byType(LumeDeleteConfirmation), findsNothing);
    });

    testWidgets('a changed form asks before it leaves', (
      WidgetTester tester,
    ) async {
      await openEdit(tester);
      await type(tester, 'displayName', 'Amina R');
      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();

      expect(find.text('Discard your changes?'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('undoing the change silences the guard again', (
      WidgetTester tester,
    ) async {
      await openEdit(tester);
      await type(tester, 'displayName', 'Amina R');
      await type(tester, 'displayName', 'Amina Rahman');
      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();
      expect(find.byType(LumeDeleteConfirmation), findsNothing);
    });

    testWidgets('cancelling keeps the reader on the form, with the draft', (
      WidgetTester tester,
    ) async {
      await openEdit(tester);
      await type(tester, 'displayName', 'Amina R');
      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(LumeAccountHost), findsOneWidget);
      expect(valueOf(tester, 'displayName'), 'Amina R');
    });

    testWidgets('a failed save keeps the draft and the guard', (
      WidgetTester tester,
    ) async {
      await openEdit(
        tester,
        account: LumeFakeAccountRepository(
          failWith: LumeAccountFailure.storage,
        ),
      );
      await type(tester, 'displayName', 'Amina R');
      await tester.tap(find.widgetWithText(LumeButton, 'Save changes'));
      await tester.pumpAndSettle();

      expect(valueOf(tester, 'displayName'), 'Amina R');
      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsOneWidget);
    });

    testWidgets('the system back runs the same guard', (
      WidgetTester tester,
    ) async {
      await openEdit(tester);
      await type(tester, 'displayName', 'Amina R');

      // What the OS gesture and the hardware key both do.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsOneWidget);
    });

    testWidgets('asking twice does not stack two dialogs', (
      WidgetTester tester,
    ) async {
      await openEdit(tester);
      await type(tester, 'displayName', 'Amina R');
      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();
      expect(find.byType(LumeDeleteConfirmation), findsOneWidget);

      // The control is behind the dialog's own barrier now. Asking again
      // cannot reach it — the tap lands on the barrier and dismisses the
      // question instead — so a second dialog can never stack on the first,
      // and the reader is back on the form with the draft they were asked
      // about.
      await tester.tap(find.byType(LumeBackButton), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(LumeDeleteConfirmation), findsNothing);
      expect(find.byType(LumeAccountHost), findsOneWidget);
      expect(valueOf(tester, 'displayName'), 'Amina R');

      // And asking once more still asks once.
      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();
      expect(find.byType(LumeDeleteConfirmation), findsOneWidget);
    });

    testWidgets('the dialog names the destructive action as an action', (
      WidgetTester tester,
    ) async {
      await openEdit(tester);
      await type(tester, 'displayName', 'Amina R');
      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();

      // A verb, not "OK". And both answers are buttons a screen reader can
      // tell apart.
      final SemanticsNode discard = tester.getSemantics(
        find.text('Discard').first,
      );
      expect(discard.getSemanticsData().flagsCollection.isButton, isTrue);
      final SemanticsNode cancel = tester.getSemantics(
        find.text('Cancel').first,
      );
      expect(cancel.getSemanticsData().flagsCollection.isButton, isTrue);
    });

    testWidgets('a rebuild for a new locale does not look like an edit', (
      WidgetTester tester,
    ) async {
      await openEdit(tester);
      // Same route, same values, different language.
      await pumpAccountRouter(
        tester,
        route: LumeAccountRoute.edit,
        locale: const Locale('ur'),
        surface: kTall,
      );
      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();
      expect(find.byType(LumeDeleteConfirmation), findsNothing);
    });

    testWidgets('a rebuild for a new theme does not either', (
      WidgetTester tester,
    ) async {
      await openEdit(tester);
      await pumpAccountRouter(
        tester,
        route: LumeAccountRoute.edit,
        theme: ThemeMode.dark,
        surface: kTall,
      );
      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();
      expect(find.byType(LumeDeleteConfirmation), findsNothing);
    });

    testWidgets('every form route is guarded, and no other route is', (
      WidgetTester tester,
    ) async {
      // One guard, in the host, asked by every departure — which is why it is
      // there and not inside whichever form happens to be dirty.
      for (final LumeAccountRoute route in <LumeAccountRoute>[
        LumeAccountRoute.edit,
        LumeAccountRoute.email,
        LumeAccountRoute.phone,
        LumeAccountRoute.password,
        LumeAccountRoute.delete,
      ]) {
        await pumpAccountRouter(tester, route: route, surface: kTall);
        final LumeAccountHost host = tester.widget<LumeAccountHost>(
          find.byType(LumeAccountHost),
        );
        expect(host.route, route);
        // The form opens with values, which is what makes a change
        // detectable at all.
        expect(find.byType(LumeInputField), findsWidgets, reason: '$route');
      }

      // A chooser holds nothing, so there is nothing to lose.
      await pumpAccountRouter(
        tester,
        route: LumeAccountRoute.appearance,
        surface: kTall,
      );
      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();
      expect(find.byType(LumeDeleteConfirmation), findsNothing);
    });
  });
}

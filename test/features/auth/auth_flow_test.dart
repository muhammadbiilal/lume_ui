/// What the authentication screens do when they are used.
///
/// Every route, every validation rule, every loading and error state, and the
/// three properties the phase names as security behaviour: a submission
/// happens once, a password is never re-masked or carried out of the screen,
/// and a completed recovery cannot be reached again by going back.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_pressable.dart';
import 'package:lume/features/auth/application/auth_flow_controller.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/auth/domain/auth_model.dart';
import 'package:lume/features/auth/presentation/auth_chrome.dart';
import 'package:lume/features/auth/presentation/auth_flow.dart';
import 'package:lume/features/auth/presentation/auth_parts.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import 'auth_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  Future<void> pump(
    WidgetTester tester,
    LumeAuthRoute route, {
    int step = 1,
    bool modal = false,
    LumeFakeAuthRepository? repository,
    void Function(
      LumeAuthOutcome outcome,
      LumeAuthStatus? status,
      String? pending,
    )?
    onOutcome,
    ValueChanged<LumeAuthRoute>? onRouteChanged,
    Size surface = LumeViewport.phone,
    ThemeMode theme = ThemeMode.light,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
  }) => pumpLume(
    tester,
    authAt(
      route,
      step: step,
      modal: modal,
      repository: repository,
      onOutcome: onOutcome,
      onRouteChanged: onRouteChanged,
    ),
    surface: surface,
    theme: theme,
    locale: locale,
    textScale: textScale,
  );

  group('every route renders itself', () {
    for (final (LumeAuthRoute route, String label, int step) in kAuthStates) {
      testWidgets(label, (WidgetTester tester) async {
        await pump(tester, route, step: step);
        final AppLocalizations l = AppLocalizations.of(
          tester.element(find.byType(LumeAuthFlow)),
        );
        expect(
          find.byKey(LumeAuthKeys.title),
          findsOneWidget,
          reason: 'every screen has exactly one heading',
        );
        expect(find.text(l.authSignInTitle).evaluate().length, lessThan(2));
        expect(tester.takeException(), isNull);
        expectNoOverflow(tester);
      });
    }
  });

  group('validation', () {
    testWidgets('nothing is judged before the field is left', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signIn);
      await type(tester, LumeAuthField.email, 'not-an-address');
      expect(
        controllerOf(tester).form.errors,
        isEmpty,
        reason: 'typing is not finishing',
      );

      await typeAndLeave(tester, LumeAuthField.email, 'not-an-address');
      expect(
        controllerOf(tester).form.errors[LumeAuthField.email],
        LumeAuthIssue.emailInvalid,
      );
    });

    testWidgets('leaving a field empty says nothing at all', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signIn);
      await typeAndLeave(tester, LumeAuthField.email, '');
      expect(
        controllerOf(tester).form.errors,
        isEmpty,
        reason: 'an untouched field is not a wrong one',
      );
    });

    testWidgets('an address that passes gets a mark as well as a border', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signIn);
      await typeAndLeave(tester, LumeAuthField.email, kTestEmail);
      expect(controllerOf(tester).form.valid, contains(LumeAuthField.email));
    });

    testWidgets('editing a field drops the verdict on it', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signIn);
      await typeAndLeave(tester, LumeAuthField.email, 'not-an-address');
      expect(controllerOf(tester).form.errors, isNotEmpty);
      await type(tester, LumeAuthField.email, 'not-an-address-yet');
      expect(
        controllerOf(tester).form.errors,
        isEmpty,
        reason: 'a complaint about what was typed cannot outlive it',
      );
    });

    testWidgets('a confirmation is checked against the password on blur', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signUp, step: 2);
      await type(tester, LumeAuthField.password, 'Passw0rdy');
      await typeAndLeave(tester, LumeAuthField.confirm, 'Passw0rdyy');
      expect(
        controllerOf(tester).form.errors[LumeAuthField.confirm],
        LumeAuthIssue.confirmMismatch,
      );
    });

    testWidgets('the whole form is checked on submission', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signIn);
      await submit(tester);
      final LumeAuthFormState form = controllerOf(tester).form;
      expect(form.errors[LumeAuthField.email], LumeAuthIssue.emailRequired);
      expect(
        form.errors[LumeAuthField.password],
        LumeAuthIssue.passwordRequired,
      );
    });

    testWidgets('the password rules are drawn from the password', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signUp, step: 2);
      expect(find.byType(LumePasswordRules), findsOneWidget);
      await type(tester, LumeAuthField.password, 'Passw0rdy');
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeAuthFlow)),
      );
      expect(find.text(l.authStrength3), findsOneWidget);
    });
  });

  group('submission', () {
    testWidgets('happens exactly once however hard the button is pressed', (
      WidgetTester tester,
    ) async {
      final LumeFakeAuthRepository repo = fakeAuth();
      int outcomes = 0;
      await pump(
        tester,
        LumeAuthRoute.signIn,
        repository: repo,
        onOutcome: (LumeAuthOutcome _, LumeAuthStatus? _, String? _) =>
            outcomes++,
      );
      await type(tester, LumeAuthField.email, kTestEmail);
      await type(tester, LumeAuthField.password, kTestPassword);

      await tester.tap(find.byType(LumeAuthSubmit));
      await tester.pump();
      // Three more presses while it is working.
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byType(LumeAuthSubmit), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 40));
      }
      await tester.pump(LumeAuthFlowController.kAuthMinimumWork);
      await tester.pumpAndSettle();

      expect(outcomes, 1);
    });

    testWidgets('the button says it is working and keeps its size', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signIn);
      final Size before = tester.getSize(find.byType(LumeAuthSubmit));

      await startSubmit(tester, email: kTestEmail, password: kTestPassword);
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeAuthFlow)),
      );
      expect(controllerOf(tester).form.busy, isTrue);
      expect(find.text(l.authSigningIn), findsOneWidget);
      expect(tester.getSize(find.byType(LumeAuthSubmit)), before);

      await tester.pump(LumeAuthFlowController.kAuthMinimumWork);
      await tester.pumpAndSettle();
    });

    testWidgets('every other control is inert while it works', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signIn);
      await startSubmit(tester, email: kTestEmail, password: kTestPassword);

      final LumeAuthFlowController c = controllerOf(tester);
      expect(c.form.busy, isTrue);
      // The recovery link and the sign-up link both stand down, so a second
      // destination cannot be chosen while the first is in flight.
      final LumePressable inline = tester.widget<LumePressable>(
        find.byKey(LumeAuthKeys.inline),
      );
      expect(inline.onTap, isNull);

      await tester.pump(LumeAuthFlowController.kAuthMinimumWork);
      await tester.pumpAndSettle();
    });

    testWidgets('a wrong password is a message, not a field complaint', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signIn);
      await type(tester, LumeAuthField.email, kTestEmail);
      await type(tester, LumeAuthField.password, 'NotTheOne1');
      await submit(tester);

      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeAuthFlow)),
      );
      expect(find.byKey(LumeAuthKeys.formError), findsOneWidget);
      expect(find.text(l.authErrCredentials), findsOneWidget);
      expect(controllerOf(tester).form.errors, isEmpty);
    });

    testWidgets('every domain failure has a sentence', (
      WidgetTester tester,
    ) async {
      for (final LumeAuthFailure failure in LumeAuthFailure.values) {
        await pump(tester, LumeAuthRoute.signIn);
        await refuse(tester, failure);
        // Two of them leave for a screen of their own rather than a line
        // above the form, which is the point of the split.
        if (failure == LumeAuthFailure.linkInvalid ||
            failure == LumeAuthFailure.linkExpired) {
          expect(
            controllerOf(tester).form.failure,
            failure,
            reason: '$failure',
          );
          continue;
        }
        expect(
          find.byKey(LumeAuthKeys.formError),
          findsOneWidget,
          reason: '$failure has no message',
        );
      }
    });

    testWidgets('offline says nothing was lost', (WidgetTester tester) async {
      await pump(tester, LumeAuthRoute.signIn);
      await refuse(tester, LumeAuthFailure.network);
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeAuthFlow)),
      );
      expect(find.text(l.authErrNetwork), findsOneWidget);
      // What was typed is still there to submit again.
      expect(controllerOf(tester).form.read(LumeAuthField.email), kTestEmail);
    });

    testWidgets('a repository that throws is still a designed failure', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signIn, repository: _ThrowingAuth());
      await type(tester, LumeAuthField.email, kTestEmail);
      await type(tester, LumeAuthField.password, kTestPassword);
      await submit(tester);
      expect(controllerOf(tester).form.failure, LumeAuthFailure.network);
      expect(tester.takeException(), isNull);
    });
  });

  group('the password reveal', () {
    testWidgets('shows and hides, and says which it is doing', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signIn);
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeAuthFlow)),
      );

      expect(find.bySemanticsLabel(l.authShowPassword), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(l.authShowPassword));
      await tester.pumpAndSettle();
      expect(
        controllerOf(tester).form.isRevealed(LumeAuthField.password),
        isTrue,
      );
      expect(find.bySemanticsLabel(l.authHidePassword), findsOneWidget);
    });

    testWidgets('a failed submission does not re-mask what was revealed', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signIn);
      controllerOf(tester).toggleReveal(LumeAuthField.password);
      await tester.pumpAndSettle();

      await type(tester, LumeAuthField.email, kTestEmail);
      await type(tester, LumeAuthField.password, 'NotTheOne1');
      await submit(tester);

      expect(
        controllerOf(tester).form.isRevealed(LumeAuthField.password),
        isTrue,
        reason: 'exactly when the user most wants to read what they typed',
      );
    });

    testWidgets('a revealed field is still secure entry when hidden', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signIn);
      final Finder field = find.byType(TextField).at(1);
      expect(tester.widget<TextField>(field).obscureText, isTrue);
      // And never offers the keyboard's dictionary or suggestion strip.
      expect(tester.widget<TextField>(field).enableSuggestions, isFalse);
      expect(tester.widget<TextField>(field).autocorrect, isFalse);
    });
  });

  group('autofill and the keyboard', () {
    testWidgets('sign in offers the right hints and actions', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signIn);
      final List<TextField> fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields[0].autofillHints, contains(AutofillHints.username));
      expect(fields[0].keyboardType, TextInputType.emailAddress);
      expect(fields[0].textInputAction, TextInputAction.next);
      expect(fields[1].autofillHints, contains(AutofillHints.password));
      expect(
        fields[1].textInputAction,
        TextInputAction.done,
        reason: 'the last field submits',
      );
    });

    testWidgets('sign up asks for a new password, not the current one', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signUp, step: 2);
      for (final TextField f in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(f.autofillHints, contains(AutofillHints.newPassword));
      }
    });

    testWidgets('the code field is numeric and takes a one-time code', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.verify);
      final TextField f = tester.widget<TextField>(find.byType(TextField));
      expect(f.keyboardType, TextInputType.number);
      expect(f.autofillHints, contains(AutofillHints.oneTimeCode));
      expect(f.maxLength, 6);
    });

    testWidgets('the last field submits from the keyboard', (
      WidgetTester tester,
    ) async {
      int outcomes = 0;
      await pump(
        tester,
        LumeAuthRoute.signIn,
        onOutcome: (LumeAuthOutcome _, LumeAuthStatus? _, String? _) =>
            outcomes++,
      );
      await type(tester, LumeAuthField.email, kTestEmail);
      await type(tester, LumeAuthField.password, kTestPassword);

      await tester.tap(find.byType(TextField).at(1));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(LumeAuthFlowController.kAuthMinimumWork);
      await tester.pumpAndSettle();
      expect(outcomes, 1);
    });

    testWidgets('the panel keeps its bottom above the keyboard', (
      WidgetTester tester,
    ) async {
      const double keyboard = 320;
      await pumpLume(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewInsets: const EdgeInsets.only(bottom: keyboard)),
            child: authAt(LumeAuthRoute.signIn),
          ),
        ),
      );

      // The panel reserves the keyboard's height inside its own bottom, so
      // scrolling to the end of the screen puts the last control *above* the
      // keyboard rather than behind it. Without that reservation the button
      // would be unreachable however far the user scrolled.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      final double top = LumeViewport.phone.height - keyboard;
      expect(
        tester.getRect(find.byType(LumeAuthSubmit)).bottom,
        lessThanOrEqualTo(top),
        reason: 'the submit button is unreachable behind the keyboard',
      );
      expectNoOverflow(tester);
    });
  });

  group('moving through the flow', () {
    testWidgets('sign in and sign up are siblings, not levels', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signIn);
      final LumeAuthFlowController c = controllerOf(tester);

      c.go(LumeAuthRoute.signUp);
      await tester.pumpAndSettle();
      c.go(LumeAuthRoute.signIn);
      await tester.pumpAndSettle();
      c.go(LumeAuthRoute.signUp);
      await tester.pumpAndSettle();

      // One press escapes, not one per hop.
      expect(c.back(), isTrue);
      await tester.pumpAndSettle();
      expect(c.route, LumeAuthRoute.signIn);
      expect(c.back(), isFalse, reason: 'nothing left inside the flow');
    });

    testWidgets('back from step two keeps step one', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signUp);
      await type(tester, LumeAuthField.email, 'new@example.com');
      await submit(tester);
      expect(controllerOf(tester).step, 2);

      expect(controllerOf(tester).back(), isTrue);
      await tester.pumpAndSettle();
      expect(controllerOf(tester).step, 1);
      expect(
        controllerOf(tester).route,
        LumeAuthRoute.signUp,
        reason: 'leaving from step two would throw step one away',
      );
    });

    testWidgets('an outcome is not a step: nothing goes back into it', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signUp);
      await type(tester, LumeAuthField.name, 'Someone New');
      await type(tester, LumeAuthField.email, 'new@example.com');
      await submit(tester);
      await type(tester, LumeAuthField.password, 'Passw0rdy');
      await type(tester, LumeAuthField.confirm, 'Passw0rdy');
      await submit(tester);

      expect(controllerOf(tester).route, LumeAuthRoute.created);
      expect(
        controllerOf(tester).canGoBack,
        isFalse,
        reason: 'the account already exists; there is nothing to return to',
      );
      expect(find.byKey(LumeAuthKeys.back), findsNothing);
    });

    testWidgets('a completed reset cannot be reached again by going back', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.forgot);
      await type(tester, LumeAuthField.email, kTestEmail);
      await submit(tester);
      expect(controllerOf(tester).route, LumeAuthRoute.sent);

      controllerOf(tester).openResetLink();
      await tester.pumpAndSettle();
      await type(tester, LumeAuthField.password, 'Passw0rdy2');
      await type(tester, LumeAuthField.confirm, 'Passw0rdy2');
      await submit(tester);

      expect(controllerOf(tester).route, LumeAuthRoute.updated);
      expect(
        controllerOf(tester).canGoBack,
        isFalse,
        reason: 'a spent recovery code must not be sitting one press away',
      );
    });

    testWidgets('a dead link leaves for a screen with a way out', (
      WidgetTester tester,
    ) async {
      final LumeFakeAuthRepository repo = fakeAuth();
      await pump(tester, LumeAuthRoute.reset, repository: repo);
      repo.script.fail(LumeAuthFailure.linkExpired);
      await type(tester, LumeAuthField.password, 'Passw0rdy2');
      await type(tester, LumeAuthField.confirm, 'Passw0rdy2');
      await submit(tester);

      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeAuthFlow)),
      );
      expect(controllerOf(tester).route, LumeAuthRoute.trouble);
      expect(find.text(l.authTroubleExpired), findsOneWidget);
      expect(find.byKey(LumeAuthKeys.formError), findsNothing);
    });

    testWidgets('the location follows the flow', (WidgetTester tester) async {
      final List<LumeAuthRoute> seen = <LumeAuthRoute>[];
      await pump(tester, LumeAuthRoute.signIn, onRouteChanged: seen.add);
      controllerOf(tester).go(LumeAuthRoute.forgot);
      await tester.pumpAndSettle();
      expect(seen, <LumeAuthRoute>[LumeAuthRoute.forgot]);
    });
  });

  group('the resend window', () {
    testWidgets('counts down, then offers the action', (
      WidgetTester tester,
    ) async {
      DateTime now = DateTime(2026, 9, 12, 9);
      await pumpLume(
        tester,
        authAt(LumeAuthRoute.verify, clock: () => now),
        animate: true,
      );
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeAuthFlow)),
      );

      expect(find.text(l.authResendIn(45)), findsOneWidget);
      expect(find.text(l.authResend), findsNothing);

      now = now.add(const Duration(seconds: 46));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(l.authResend), findsOneWidget);
      // No `pumpAndSettle`: this is the one test that lets motion run, and
      // the ambient drift is an 18-second loop that never settles.
    });

    testWidgets('a refusal that names a wait is the wait', (
      WidgetTester tester,
    ) async {
      final LumeFakeAuthRepository repo = fakeAuth();
      await pumpLume(
        tester,
        authAt(LumeAuthRoute.verify, repository: repo, resendOpen: true),
      );
      final LumeAuthFlowController c = controllerOf(tester);
      expect(c.resendSeconds, 0);

      repo.script.fail(
        LumeAuthFailure.rateLimited,
        retryAfter: const Duration(seconds: 20),
      );
      await c.resend();
      await tester.pumpAndSettle();

      expect(c.resendSeconds, 20, reason: 'the screen never invents a number');
      expect(
        c.form.failure,
        isNull,
        reason: 'a wait is not an error worth a red box',
      );
    });

    testWidgets('the countdown is announced as it changes', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.verify);
      final Finder quiet = find.byType(LumeAuthQuietLine);
      expect(
        tester
            .widgetList<LumeAuthQuietLine>(quiet)
            .any((LumeAuthQuietLine q) => q.live),
        isTrue,
      );
    });
  });

  group('sensitive state', () {
    testWidgets('is gone the moment the flow is finished with', (
      WidgetTester tester,
    ) async {
      late LumeAuthFlowController c;
      await pump(tester, LumeAuthRoute.signIn);
      c = controllerOf(tester);
      await type(tester, LumeAuthField.email, kTestEmail);
      await type(tester, LumeAuthField.password, kTestPassword);
      expect(c.form.values, isNotEmpty);

      await submit(tester);
      expect(
        c.form.values,
        isEmpty,
        reason: 'a password must not outlive the submission that spent it',
      );
    });

    testWidgets('is gone when the flow is dismissed', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signIn, modal: true);
      final LumeAuthFlowController c = controllerOf(tester);
      await type(tester, LumeAuthField.password, kTestPassword);
      c.dismiss();
      await tester.pumpAndSettle();
      expect(c.form.values, isEmpty);
    });

    testWidgets('is gone when the screen is disposed', (
      WidgetTester tester,
    ) async {
      final LumeAuthFlowController c = LumeAuthFlowController(
        repository: fakeAuth(),
      );
      await pumpLume(tester, authAt(LumeAuthRoute.signIn, controller: c));
      c.edit(LumeAuthField.password, kTestPassword);
      await tester.pumpAndSettle();

      await pumpLume(tester, const SizedBox.shrink());
      c.dispose();
      expect(c.form.values, isEmpty);
    });

    testWidgets('a new route starts from an empty form', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signIn);
      final LumeAuthFlowController c = controllerOf(tester);
      await type(tester, LumeAuthField.email, kTestEmail);
      c.go(LumeAuthRoute.signUp);
      await tester.pumpAndSettle();
      expect(
        c.form.values,
        isEmpty,
        reason: 'a half-typed sign-in cannot leak into a sign-up',
      );
    });
  });

  group('guest and dismissal', () {
    testWidgets('a flow that interrupted something offers both ways out', (
      WidgetTester tester,
    ) async {
      LumeAuthOutcome? got;
      await pump(
        tester,
        LumeAuthRoute.signIn,
        modal: true,
        onOutcome: (LumeAuthOutcome o, LumeAuthStatus? _, String? _) => got = o,
      );
      expect(find.byKey(LumeAuthKeys.close), findsOneWidget);
      expect(find.byType(LumeAuthSecondary), findsOneWidget);

      await tester.tap(find.byType(LumeAuthSecondary));
      await tester.pumpAndSettle();
      expect(got, LumeAuthOutcome.dismissed);
    });

    testWidgets('a flow nobody interrupted offers neither', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.signIn);
      expect(find.byKey(LumeAuthKeys.close), findsNothing);
      expect(find.byType(LumeAuthSecondary), findsNothing);
    });

    testWidgets('leaving the expiry screen ends the dead session', (
      WidgetTester tester,
    ) async {
      LumeAuthOutcome? got;
      await pump(
        tester,
        LumeAuthRoute.expired,
        onOutcome: (LumeAuthOutcome o, LumeAuthStatus? _, String? _) => got = o,
      );
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeAuthFlow)),
      );
      await tester.ensureVisible(find.text(l.authContinueAsGuest));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.authContinueAsGuest));
      await tester.pumpAndSettle();
      expect(got, LumeAuthOutcome.signedOutGuest);
    });

    testWidgets('an outcome screen cannot be dismissed', (
      WidgetTester tester,
    ) async {
      for (final LumeAuthRoute route in <LumeAuthRoute>[
        LumeAuthRoute.created,
        LumeAuthRoute.expired,
      ]) {
        LumeAuthOutcome? got;
        await pump(
          tester,
          route,
          modal: true,
          onOutcome: (LumeAuthOutcome o, LumeAuthStatus? _, String? _) =>
              got = o,
        );
        expect(find.byKey(LumeAuthKeys.close), findsNothing, reason: '$route');
        expect(find.byKey(LumeAuthKeys.back), findsNothing, reason: '$route');
        controllerOf(tester).dismiss();
        await tester.pumpAndSettle();
        expect(got, isNull, reason: '$route is a thing to be dealt with');
      }
    });

    testWidgets('the held destination comes back with the outcome', (
      WidgetTester tester,
    ) async {
      String? pending;
      await pump(
        tester,
        LumeAuthRoute.signIn,
        modal: true,
        onOutcome: (LumeAuthOutcome _, LumeAuthStatus? _, String? p) =>
            pending = p,
      );
      await type(tester, LumeAuthField.email, kTestEmail);
      await type(tester, LumeAuthField.password, kTestPassword);
      await submit(tester);
      expect(pending, '/profile/account');
    });
  });

  group('everywhere it has to work', () {
    const List<(String, Size)> surfaces = <(String, Size)>[
      ('the narrowest phone', Size(359, 844)),
      ('a phone', LumeViewport.phone),
      ('a tablet', Size(700, 900)),
      ('a wide tablet', Size(1100, 900)),
      ('a desktop', Size(1400, 900)),
      ('a phone held sideways', Size(852, 393)),
    ];
    for (final (String name, Size surface) in surfaces) {
      testWidgets('every screen lays out on $name', (
        WidgetTester tester,
      ) async {
        for (final (LumeAuthRoute route, String label, int step)
            in kAuthStates) {
          await pump(tester, route, step: step, surface: surface);
          expect(tester.takeException(), isNull, reason: '$label on $name');
          expectNoOverflow(tester);
        }
      });
    }

    testWidgets('in dark, in Urdu and in Arabic', (WidgetTester tester) async {
      const List<(ThemeMode, Locale)> cells = <(ThemeMode, Locale)>[
        (ThemeMode.dark, Locale('en')),
        (ThemeMode.light, Locale('ur')),
        (ThemeMode.light, Locale('ar')),
        (ThemeMode.dark, Locale('ar')),
      ];
      for (final (ThemeMode theme, Locale locale) in cells) {
        for (final (LumeAuthRoute route, String label, int step)
            in kAuthStates) {
          await pump(tester, route, step: step, theme: theme, locale: locale);
          expect(
            tester.takeException(),
            isNull,
            reason: '$label in ${locale.languageCode}/${theme.name}',
          );
          expectNoOverflow(tester);
        }
      }
    });

    testWidgets('at 200 per cent text', (WidgetTester tester) async {
      for (final (LumeAuthRoute route, String label, int step) in kAuthStates) {
        await pump(tester, route, step: step, textScale: 2.0);
        expect(tester.takeException(), isNull, reason: label);
        expectNoOverflow(tester);
      }
    });

    testWidgets('the back chevron mirrors and the dismissal does not', (
      WidgetTester tester,
    ) async {
      await pump(tester, LumeAuthRoute.forgot, locale: const Locale('ar'));
      // The chevron means "back", which is a direction; a cross means
      // "close", which is not.
      final Rect back = tester.getRect(find.byKey(LumeAuthKeys.back));
      expect(
        back.center.dx,
        greaterThan(tester.getSize(find.byType(LumeAuthFlow)).width / 2),
        reason: 'in Arabic, back is on the right',
      );
    });
  });

  group('what a screen reader is told', () {
    testWidgets('each screen announces its own title', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      for (final (LumeAuthRoute route, String label, int step) in kAuthStates) {
        await pump(tester, route, step: step);
        final AppLocalizations l = AppLocalizations.of(
          tester.element(find.byType(LumeAuthFlow)),
        );
        expect(
          find.bySemanticsLabel(l.authSignInTitle).evaluate().isNotEmpty ||
              find.byKey(LumeAuthKeys.title).evaluate().isNotEmpty,
          isTrue,
          reason: label,
        );
      }
      handle.dispose();
    });

    testWidgets('an error is announced rather than only drawn', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, LumeAuthRoute.signIn);
      await refuse(tester, LumeAuthFailure.credentials);

      // A message nobody is told about is a message only some people get.
      expect(
        tester
            .getSemantics(find.byKey(LumeAuthKeys.formError))
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('every control clears the touch floor', (
      WidgetTester tester,
    ) async {
      for (final (LumeAuthRoute route, String label, int step) in kAuthStates) {
        await pump(tester, route, step: step);
        for (final Element e in find.byType(LumePressable).evaluate()) {
          final Size size = tester.getSize(
            find.byElementPredicate((Element it) => it == e),
          );
          expect(
            size.height,
            greaterThanOrEqualTo(43.9),
            reason: '$label has a control ${size.height} tall',
          );
        }
      }
    });

    testWidgets('the step indicator is decoration, and the count is not', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester, LumeAuthRoute.signUp, step: 2);
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeAuthFlow)),
      );
      // The bar says nothing; the sentence beside it says everything.
      expect(find.text(l.authStepOf(2, 2)), findsOneWidget);
      handle.dispose();
    });
  });
}

/// A repository that throws rather than returning a refusal.
class _ThrowingAuth extends LumeFakeAuthRepository {
  @override
  Future<LumeAuthResult> signIn({
    required String email,
    required String password,
  }) async => throw StateError('the backend fell over');
}

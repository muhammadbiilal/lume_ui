/// The shared way to put the authentication flow into a named state.
///
/// Every state F4C asks about is reachable from one expression here, which is
/// what stops a golden and a behaviour test from disagreeing about what
/// "the sign-in screen with a refused submission" means.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/auth/application/auth_flow_controller.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/auth/domain/auth_model.dart';
import 'package:lume/features/auth/presentation/auth_flow.dart';
import 'package:lume/features/auth/presentation/auth_parts.dart';

/// The account every test signs in as.
const String kTestEmail = 'amina@example.com';
const String kTestPassword = 'Passw0rdy';
const String kTestName = 'Amina Tariq';

/// The eleven compositions, by the name their goldens carry.
///
/// `signup` is two of them, which is why the step is part of the tuple.
const List<(LumeAuthRoute, String, int)> kAuthStates =
    <(LumeAuthRoute, String, int)>[
      (LumeAuthRoute.signIn, 'signin', 1),
      (LumeAuthRoute.signUp, 'signup', 1),
      (LumeAuthRoute.signUp, 'signup2', 2),
      (LumeAuthRoute.forgot, 'forgot', 1),
      (LumeAuthRoute.sent, 'sent', 1),
      (LumeAuthRoute.reset, 'reset', 1),
      (LumeAuthRoute.updated, 'updated', 1),
      (LumeAuthRoute.created, 'created', 1),
      (LumeAuthRoute.expired, 'expired', 1),
      (LumeAuthRoute.trouble, 'trouble', 1),
      (LumeAuthRoute.verify, 'verify', 1),
    ];

/// A repository with one account in it.
LumeFakeAuthRepository fakeAuth({
  bool locked = false,
  DateTime Function()? clock,
}) => LumeFakeAuthRepository.withAccount(
  email: kTestEmail,
  password: kTestPassword,
  displayName: kTestName,
  locked: locked,
  clock: clock,
);

/// The controller currently mounted.
LumeAuthFlowController controllerOf(WidgetTester tester) =>
    tester.state<LumeAuthFlowState>(find.byType(LumeAuthFlow)).controller;

/// The flow, opened on [route] and put into whatever state the name implies.
///
/// Everything that varies between the eleven screens is a named argument
/// rather than a separate builder, so a golden reads as one line and the list
/// of states is the list of arguments.
Widget authAt(
  LumeAuthRoute route, {
  int step = 1,
  bool modal = false,
  bool named = true,
  bool resendOpen = false,
  LumeTroubleReason trouble = LumeTroubleReason.linkInvalid,
  LumeFakeAuthRepository? repository,
  LumeAuthFlowController? controller,
  void Function(
    LumeAuthOutcome outcome,
    LumeAuthStatus? status,
    String? pending,
  )?
  onOutcome,
  ValueChanged<LumeAuthRoute>? onRouteChanged,
  DateTime Function()? clock,
}) {
  final LumeFakeAuthRepository repo = repository ?? fakeAuth(clock: clock);
  // The verify screen's code is delivered by a repository with no mail server
  // behind it; a real one returns nothing and the line is not drawn.
  final LumeAuthFlowController c =
      controller ??
      LumeAuthFlowController(
        repository: repo,
        initialRoute: route,
        modal: modal,
        pendingDestination: modal ? '/profile/account' : null,
        clock: clock,
      );
  // Only the one made here. The verify screen runs a one-second ticker, and a
  // controller left alive keeps a pending timer past the end of the test —
  // but a caller who brought their own is the one who ends it.
  if (controller == null) addTearDown(c.dispose);

  // `sent` and `reset` only exist once a recovery has been asked for, so they
  // are given the token such a request would have produced rather than being
  // left holding one they could not have got.
  if (route == LumeAuthRoute.sent || route == LumeAuthRoute.reset) {
    c.restoreState(recoveryToken: 'rst-test');
  }
  if (route == LumeAuthRoute.signUp && step == 2) c.restoreState(step: 2);
  if (route == LumeAuthRoute.trouble) c.restoreState(trouble: trouble);
  if (route == LumeAuthRoute.verify) {
    // The code is delivered only because this repository has no mail server
    // behind it, and the screen only draws that line because of it.
    c.restoreState(deliveredCode: '384512', openResendWindow: resendOpen);
  }

  return LumeAuthFlow(
    repository: repo,
    initialRoute: route,
    modal: modal,
    status: named
        ? LumeAuthStatus(
            state: route == LumeAuthRoute.expired
                ? LumeSessionState.expired
                : LumeSessionState.authenticated,
            account: LumeAccount(
              id: 'usr-1',
              email: kTestEmail,
              displayName: kTestName,
              pendingEmail: route == LumeAuthRoute.verify
                  ? 'moved@example.com'
                  : null,
            ),
          )
        : const LumeAuthStatus.guest(),
    controller: c,
    onOutcome: onOutcome,
    onRouteChanged: onRouteChanged,
  );
}

/// Type into a field and leave it, which is when a blur check runs.
Future<void> typeAndLeave(
  WidgetTester tester,
  LumeAuthField field,
  String value,
) async {
  await type(tester, field, value);
  controllerOf(tester).leave(field);
  await tester.pumpAndSettle();
}

/// Type into a field without leaving it.
Future<void> type(
  WidgetTester tester,
  LumeAuthField field,
  String value,
) async {
  controllerOf(tester).edit(field, value);
  await tester.pumpAndSettle();
}

/// Submit, and let the minimum-work floor elapse.
///
/// The button is scrolled to first: two of these screens are taller than a
/// phone, and a tap that lands on nothing is not a test of anything.
Future<void> submit(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(LumeAuthSubmit).first);
  await tester.pumpAndSettle();
  await tester.tap(find.byType(LumeAuthSubmit).first);
  await tester.pump();
  await tester.pump(LumeAuthFlowController.kAuthMinimumWork);
  await tester.pumpAndSettle();
}

/// Fill in sign-in and press the button, stopping while it is still working.
Future<void> startSubmit(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await type(tester, LumeAuthField.email, email);
  await type(tester, LumeAuthField.password, password);
  await tester.ensureVisible(find.byType(LumeAuthSubmit).first);
  await tester.pumpAndSettle();
  await tester.tap(find.byType(LumeAuthSubmit).first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

/// Make the next attempt fail with [failure], then make it.
Future<void> refuse(WidgetTester tester, LumeAuthFailure failure) async {
  final LumeAuthFlowController c = controllerOf(tester);
  (c.repository as LumeFakeAuthRepository).script.fail(failure);
  await type(tester, LumeAuthField.email, kTestEmail);
  await type(tester, LumeAuthField.password, kTestPassword);
  await submit(tester);
}

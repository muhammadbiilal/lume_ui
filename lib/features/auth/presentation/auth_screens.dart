/// The eleven authentication compositions.
///
/// Each one names its slots and nothing else: the frame is
/// [LumeAuthScaffold]'s, the rules are the domain's, and what a submission
/// does is the controller's. A screen here has no navigation, no repository
/// and no validation of its own.
///
/// They are all built from one [LumeAuthScreen], which reads the controller
/// and switches. That is deliberate — eleven separate widgets that each
/// assembled their own header would drift apart, and the header is the first
/// thing that drifts.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../application/auth_flow_controller.dart';
import '../domain/auth_model.dart';
import '../domain/password_policy.dart';
import 'auth_chrome.dart';
import 'auth_parts.dart';
import 'auth_strings.dart';

/// `U+2068 FIRST STRONG ISOLATE` and `U+2069 POP DIRECTIONAL ISOLATE`.
///
/// An address or a code is direction-neutral, and dropping one into an Arabic
/// or Urdu sentence lets the bidi algorithm reorder it — a domain ends up at
/// the wrong end of the line, and a six-digit code reads backwards. Wrapping
/// it says "this run has its own direction, decide it from the run itself".
/// Written as escapes because the characters are invisible in source.
const String _isolate = '\u2068';
const String _isolateEnd = '\u2069';

/// Whatever the controller is currently on.
class LumeAuthScreen extends StatelessWidget {
  const LumeAuthScreen({
    super.key,
    required this.controller,
    this.accountEmail,
    this.pendingEmail,
    this.displayName,
    this.onOpenLegal,
  });

  final LumeAuthFlowController controller;

  /// The address behind an expired session, shown back masked.
  final String? accountEmail;

  /// The address waiting on a verification code.
  final String? pendingEmail;

  /// Who the arrival screen greets.
  final String? displayName;

  /// Opens the data sheet. A sheet rather than a screen: leaving would take
  /// the password the user has just typed with it.
  final VoidCallback? onOpenLegal;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeAuthRoute route = controller.route;

    // One host, eleven screens: the label follows the rendered title.
    return Semantics(
      container: true,
      label: route.title(l, step: controller.step),
      explicitChildNodes: true,
      child: switch (route) {
        LumeAuthRoute.signIn => _SignIn(controller: controller),
        LumeAuthRoute.signUp => _SignUp(
          controller: controller,
          onOpenLegal: onOpenLegal,
        ),
        LumeAuthRoute.forgot => _Forgot(controller: controller),
        LumeAuthRoute.sent => _Sent(controller: controller),
        LumeAuthRoute.reset => _Reset(controller: controller),
        LumeAuthRoute.updated => _Updated(controller: controller),
        LumeAuthRoute.created => _Created(
          controller: controller,
          displayName: displayName,
        ),
        LumeAuthRoute.expired => _Expired(
          controller: controller,
          email: accountEmail,
        ),
        LumeAuthRoute.trouble => _Trouble(controller: controller),
        LumeAuthRoute.verify => _Verify(
          controller: controller,
          pendingEmail: pendingEmail,
        ),
      },
    );
  }
}

/// The header every screen gets, assembled from what the route allows.
LumeAuthTop _top(
  BuildContext context,
  LumeAuthFlowController c, {
  bool back = true,
  String? stepOf,
}) {
  final AppLocalizations l = AppLocalizations.of(context);
  // A screen with a step behind it keeps its Back even when the whole flow
  // can also be dismissed — otherwise step two of a sign-up reached from a
  // link has no way home to step one.
  final bool showBack = back && (!c.modal || c.canGoBack);
  final bool showClose = c.modal && c.route.dismissible;
  return LumeAuthTop(
    onBack: showBack ? c.back : null,
    onClose: showClose ? c.dismiss : null,
    stepOf: stepOf,
    backLabel: l.a11yBack,
    closeLabel: l.actionClose,
  );
}

/// The form-level message, when the last attempt had one.
Widget? _failure(BuildContext context, LumeAuthFlowController c) {
  final LumeAuthFailure? f = c.form.failure;
  if (f == null) return null;
  return LumeAuthMessage.error(f.message(AppLocalizations.of(context)));
}

/// One field, wired to the controller.
LumeAuthInput _input(
  BuildContext context,
  LumeAuthFlowController c, {
  required LumeAuthField field,
  required String label,
  String? placeholder,
  String? hint,
  String? optionalLabel,
  bool obscure = false,
  List<String>? autofill,
  TextInputType? keyboard,
  int? maxLength,
  TextInputAction action = TextInputAction.next,
  bool submitOnDone = false,
}) {
  final AppLocalizations l = AppLocalizations.of(context);
  final LumeAuthIssue? issue = c.form.errors[field];
  return LumeAuthInput(
    field: field,
    label: label,
    value: c.form.read(field),
    onChanged: (String v) => c.edit(field, v),
    onEditingComplete: () => c.leave(field),
    onSubmitted: submitOnDone ? c.submit : null,
    error: issue?.message(l),
    hint: hint,
    placeholder: placeholder,
    optionalLabel: optionalLabel,
    valid: c.form.valid.contains(field),
    obscure: obscure,
    revealed: c.form.isRevealed(field),
    onToggleReveal: obscure ? () => c.toggleReveal(field) : null,
    revealShowLabel: l.authShowPassword,
    revealHideLabel: l.authHidePassword,
    keyboardType: keyboard,
    autofillHints: autofill,
    maxLength: maxLength,
    textInputAction: action,
    enabled: !c.form.busy,
  );
}

/// The vertical stack a form slot holds: 12 between every child, except where
/// a row says otherwise.
Widget _form(List<Widget> children) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: <Widget>[
    for (int i = 0; i < children.length; i++) ...<Widget>[
      if (i > 0)
        SizedBox(height: LumeAuthMetrics.formGap + _gapAdjust(children[i])),
      children[i],
    ],
  ],
);

double _gapAdjust(Widget row) {
  final Object widget = row;
  return widget is LumeAuthFormRow ? widget.gapAdjust : 0;
}

/// The masked address, on its own bold line under the supporting copy.
InlineSpan _withMaskedEmail(BuildContext context, String text, String? email) {
  final LumeColors lume = context.lume;
  if (email == null || email.isEmpty) return TextSpan(text: text);
  return TextSpan(
    children: <InlineSpan>[
      TextSpan(text: '$text\n'),
      TextSpan(
        // An address is direction-neutral content inside a sentence that may
        // be right-to-left. The isolate keeps it reading left to right and
        // stops the domain jumping to the other end of the line.
        text: '$_isolate${LumeEmailPolicy.mask(email)}$_isolateEnd',
        style: TextStyle(fontWeight: FontWeight.w700, color: lume.text),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------

class _SignIn extends StatelessWidget {
  const _SignIn({required this.controller});

  final LumeAuthFlowController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeAuthFlowController c = controller;

    return LumeAuthScaffold(
      top: _top(context, c),
      title: l.authSignInTitle,
      text: l.authSignInText,
      // A flow that interrupted something says what it interrupted.
      notice: c.pendingDestination == null
          ? null
          : LumeAuthMessage.notice(l.authNeedAccountText),
      form: _form(<Widget>[
        ?_failure(context, c),
        _input(
          context,
          c,
          field: LumeAuthField.email,
          label: l.authFieldEmail,
          placeholder: l.authEmailPlaceholder,
          keyboard: TextInputType.emailAddress,
          autofill: const <String>[AutofillHints.username, AutofillHints.email],
        ),
        _input(
          context,
          c,
          field: LumeAuthField.password,
          label: l.authFieldPassword,
          obscure: true,
          autofill: const <String>[AutofillHints.password],
          action: TextInputAction.done,
          submitOnDone: true,
        ),
        LumeAuthInlineLink(
          label: l.authForgotAction,
          onPressed: c.form.busy ? null : () => c.go(LumeAuthRoute.forgot),
        ),
      ]),
      actions: LumeAuthSubmit(
        label: l.authSignIn,
        busyLabel: l.authSigningIn,
        busy: c.form.busy,
        onPressed: c.submit,
      ),
      foot: <Widget>[
        if (c.modal)
          LumeAuthSecondary(
            label: l.authContinueAsGuest,
            onPressed: c.form.busy ? null : c.dismiss,
          ),
        LumeAuthLink(
          text: l.authNoAccount,
          strong: l.authCreateOne,
          onPressed: c.form.busy ? null : () => c.go(LumeAuthRoute.signUp),
        ),
      ],
      asideTitle: l.authAsideTitle,
      asideText: l.authAsideText,
    );
  }
}

class _SignUp extends StatelessWidget {
  const _SignUp({required this.controller, this.onOpenLegal});

  final LumeAuthFlowController controller;
  final VoidCallback? onOpenLegal;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeAuthFlowController c = controller;
    final int step = c.step;
    final String stepOf = l.authStepOf(step, 2);

    if (step == 1) {
      return LumeAuthScaffold(
        top: _top(context, c, stepOf: stepOf),
        title: l.authSignUpTitle,
        text: l.authSignUpText,
        steps: const LumeAuthSteps(step: 1, total: 2),
        form: _form(<Widget>[
          ?_failure(context, c),
          _input(
            context,
            c,
            field: LumeAuthField.name,
            label: l.authFieldName,
            optionalLabel: l.commonOptional,
            hint: l.authNameHint,
            maxLength: 40,
            autofill: const <String>[AutofillHints.name],
          ),
          _input(
            context,
            c,
            field: LumeAuthField.email,
            label: l.authFieldEmail,
            placeholder: l.authEmailPlaceholder,
            keyboard: TextInputType.emailAddress,
            autofill: const <String>[AutofillHints.email],
            action: TextInputAction.done,
            submitOnDone: true,
          ),
        ]),
        actions: LumeAuthSubmit(
          label: l.authContinue,
          busy: c.form.busy,
          onPressed: c.submit,
        ),
        foot: <Widget>[
          LumeAuthLink(
            text: l.authHaveAccount,
            strong: l.authSignIn,
            onPressed: c.form.busy ? null : () => c.go(LumeAuthRoute.signIn),
          ),
        ],
        asideTitle: l.authAsideTitle,
        asideText: l.authAsideText,
      );
    }

    final String password = c.form.read(LumeAuthField.password);
    return LumeAuthScaffold(
      top: _top(context, c, stepOf: stepOf),
      title: l.authSignUpPasswordTitle,
      text: l.authSignUpPasswordText,
      steps: const LumeAuthSteps(step: 2, total: 2),
      form: _form(<Widget>[
        ?_failure(context, c),
        _input(
          context,
          c,
          field: LumeAuthField.password,
          label: l.authFieldPassword,
          obscure: true,
          autofill: const <String>[AutofillHints.newPassword],
        ),
        LumePasswordMeter(
          strength: LumePasswordPolicy.strength(password),
          label: LumePasswordPolicy.strength(password).label(l),
        ),
        LumePasswordRules(
          checks: LumePasswordPolicy.checks(password),
          title: l.authPasswordRulesTitle,
          labelFor: (LumePasswordRule r) => r.label(l),
        ),
        _input(
          context,
          c,
          field: LumeAuthField.confirm,
          label: l.authFieldConfirm,
          obscure: true,
          autofill: const <String>[AutofillHints.newPassword],
          action: TextInputAction.done,
          submitOnDone: true,
        ),
      ]),
      actions: LumeAuthSubmit(
        label: l.authCreateAccount,
        busyLabel: l.authCreatingAccount,
        busy: c.form.busy,
        onPressed: c.submit,
      ),
      legal: LumeAuthLegal(
        text: l.authLegal,
        linkLabel: l.authLegalLink,
        onPressed: onOpenLegal,
      ),
      asideTitle: l.authAsideTitle,
      asideText: l.authAsideText,
    );
  }
}

class _Forgot extends StatelessWidget {
  const _Forgot({required this.controller});

  final LumeAuthFlowController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeAuthFlowController c = controller;

    return LumeAuthScaffold(
      top: _top(context, c),
      visual: const LumeAuthSeal(icon: LumeIcons.key, tone: LumeSealTone.calm),
      title: l.authForgotTitle,
      text: l.authForgotText,
      form: _form(<Widget>[
        ?_failure(context, c),
        _input(
          context,
          c,
          field: LumeAuthField.email,
          label: l.authFieldEmail,
          placeholder: l.authEmailPlaceholder,
          keyboard: TextInputType.emailAddress,
          autofill: const <String>[AutofillHints.email],
          action: TextInputAction.done,
          submitOnDone: true,
        ),
      ]),
      actions: LumeAuthSubmit(
        label: l.authForgotCta,
        busy: c.form.busy,
        onPressed: c.submit,
      ),
      foot: <Widget>[
        LumeAuthLink(
          text: l.authRememberPassword,
          strong: l.authSignIn,
          onPressed: c.form.busy ? null : () => c.go(LumeAuthRoute.signIn),
        ),
      ],
      asideTitle: l.authAsideTitle,
      asideText: l.authAsideText,
    );
  }
}

/// The neutral confirmation.
///
/// **Identical whether or not the address exists.** The address the user just
/// typed is deliberately not echoed here: it would add a string that varies
/// with the input, and this screen has to be the same either way.
class _Sent extends StatelessWidget {
  const _Sent({required this.controller});

  final LumeAuthFlowController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeAuthFlowController c = controller;

    return LumeAuthScaffold(
      top: _top(context, c),
      brand: false,
      status: true,
      visual: const LumeAuthSeal(icon: LumeIcons.mail, tone: LumeSealTone.calm),
      title: l.authSentTitle,
      text: l.authSentText,
      note: l.authSentNote,
      grow: true,
      actions: c.canOpenResetLink
          ? LumeAuthSubmit(label: l.authOpenLink, onPressed: c.openResetLink)
          : null,
      foot: <Widget>[
        LumeAuthLink(
          text: l.authBackToSignIn,
          onPressed: () => c.go(LumeAuthRoute.signIn),
        ),
        LumeAuthQuietLine(l.authSentLocal),
      ],
      asideTitle: l.authAsideTitle,
      asideText: l.authAsideText,
    );
  }
}

class _Reset extends StatelessWidget {
  const _Reset({required this.controller});

  final LumeAuthFlowController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeAuthFlowController c = controller;
    final String password = c.form.read(LumeAuthField.password);

    return LumeAuthScaffold(
      top: _top(context, c),
      visual: const LumeAuthSeal(
        icon: LumeIcons.shield,
        tone: LumeSealTone.calm,
      ),
      title: l.authResetTitle,
      text: l.authResetText,
      form: _form(<Widget>[
        ?_failure(context, c),
        _input(
          context,
          c,
          field: LumeAuthField.password,
          label: l.authFieldNewPassword,
          obscure: true,
          autofill: const <String>[AutofillHints.newPassword],
        ),
        LumePasswordMeter(
          strength: LumePasswordPolicy.strength(password),
          label: LumePasswordPolicy.strength(password).label(l),
        ),
        LumePasswordRules(
          checks: LumePasswordPolicy.checks(password),
          title: l.authPasswordRulesTitle,
          labelFor: (LumePasswordRule r) => r.label(l),
        ),
        _input(
          context,
          c,
          field: LumeAuthField.confirm,
          label: l.authFieldConfirm,
          obscure: true,
          autofill: const <String>[AutofillHints.newPassword],
          action: TextInputAction.done,
          submitOnDone: true,
        ),
      ]),
      actions: LumeAuthSubmit(
        label: l.authResetCta,
        busy: c.form.busy,
        onPressed: c.submit,
      ),
      asideTitle: l.authAsideTitle,
      asideText: l.authAsideText,
    );
  }
}

class _Updated extends StatelessWidget {
  const _Updated({required this.controller});

  final LumeAuthFlowController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return LumeAuthScaffold(
      top: _top(context, controller, back: false),
      brand: false,
      status: true,
      visual: const LumeAuthSeal(icon: LumeIcons.check),
      title: l.authUpdatedTitle,
      text: l.authUpdatedText,
      grow: true,
      actions: LumeAuthSubmit(
        label: l.authSignIn,
        onPressed: () => controller.go(LumeAuthRoute.signIn, fresh: true),
      ),
      asideTitle: l.authAsideTitle,
      asideText: l.authAsideText,
    );
  }
}

/// The arrival. The account already exists by the time this renders, so it is
/// a designed destination rather than a step that could fail — and there is
/// deliberately no route back into the flow behind it.
class _Created extends StatelessWidget {
  const _Created({required this.controller, this.displayName});

  final LumeAuthFlowController controller;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String? who = displayName?.trim();
    return LumeAuthScaffold(
      top: _top(context, controller, back: false),
      brand: false,
      status: true,
      visual: const LumeAuthSeal(icon: LumeIcons.check),
      title: l.authCreatedTitle,
      text: who == null || who.isEmpty
          ? l.authCreatedText
          : l.authCreatedTextNamed(who),
      grow: true,
      actions: LumeAuthSubmit(
        label: l.authEnterCta,
        onPressed: controller.complete,
      ),
      asideTitle: l.authAsideTitle,
      asideText: l.authAsideText,
    );
  }
}

class _Expired extends StatelessWidget {
  const _Expired({required this.controller, this.email});

  final LumeAuthFlowController controller;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return LumeAuthScaffold(
      top: _top(context, controller, back: false),
      brand: false,
      status: true,
      visual: const LumeAuthSeal(
        icon: LumeIcons.clock,
        tone: LumeSealTone.warn,
      ),
      title: l.authExpiredTitle,
      textSpan: _withMaskedEmail(context, l.authExpiredText, email),
      grow: true,
      actions: LumeAuthSubmit(
        label: l.authExpiredCta,
        onPressed: () => controller.go(LumeAuthRoute.signIn, fresh: true),
      ),
      foot: <Widget>[
        // Choosing to stay a guest ends the dead session rather than leaving
        // it to interrupt again on the next launch.
        LumeAuthLink(
          text: l.authContinueAsGuest,
          onPressed: controller.continueAsGuest,
        ),
      ],
      asideTitle: l.authAsideTitle,
      asideText: l.authAsideText,
    );
  }
}

class _Trouble extends StatelessWidget {
  const _Trouble({required this.controller});

  final LumeAuthFlowController controller;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return LumeAuthScaffold(
      top: _top(context, controller),
      brand: false,
      status: true,
      visual: const LumeAuthSeal(
        icon: LumeIcons.alert,
        tone: LumeSealTone.warn,
      ),
      title: l.authTroubleTitle,
      text: controller.troubleReason.message(l),
      grow: true,
      actions: LumeAuthSubmit(
        label: l.authTroubleCta,
        onPressed: () => controller.go(LumeAuthRoute.forgot, fresh: true),
      ),
      foot: <Widget>[
        LumeAuthLink(
          text: l.authBackToSignIn,
          onPressed: () => controller.go(LumeAuthRoute.signIn, fresh: true),
        ),
      ],
      asideTitle: l.authAsideTitle,
      asideText: l.authAsideText,
    );
  }
}

class _Verify extends StatelessWidget {
  const _Verify({required this.controller, this.pendingEmail});

  final LumeAuthFlowController controller;
  final String? pendingEmail;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeAuthFlowController c = controller;
    final int left = c.resendSeconds;
    final String? code = c.deliveredCode;

    return LumeAuthScaffold(
      top: _top(context, c),
      brand: false,
      status: true,
      visual: const LumeAuthSeal(icon: LumeIcons.mail, tone: LumeSealTone.calm),
      title: l.authVerifyTitle,
      textSpan: _withMaskedEmail(context, l.authVerifyText, pendingEmail),
      form: _form(<Widget>[
        ?_failure(context, c),
        _input(
          context,
          c,
          field: LumeAuthField.code,
          label: l.authFieldCode,
          keyboard: TextInputType.number,
          autofill: const <String>[AutofillHints.oneTimeCode],
          maxLength: 6,
          action: TextInputAction.done,
          submitOnDone: true,
        ),
        // Only a repository with no mail server behind it delivers a code
        // here; with a real one this line does not exist.
        if (code != null) _LocalCode(code: code),
      ]),
      actions: LumeAuthSubmit(
        label: l.authVerifyCta,
        busy: c.form.busy,
        onPressed: c.submit,
      ),
      foot: <Widget>[
        LumeAuthQuietLine(l.authResendNone),
        if (left > 0)
          LumeAuthQuietLine(l.authResendIn(left), live: true)
        else
          LumeAuthLink(
            text: '',
            strong: l.authResend,
            onPressed: c.form.busy ? null : c.resend,
          ),
        LumeAuthLink(text: l.actionCancel, onPressed: c.dismiss),
      ],
      asideTitle: l.authAsideTitle,
      asideText: l.authAsideText,
    );
  }
}

class _LocalCode extends StatelessWidget implements LumeAuthFormRow {
  const _LocalCode({required this.code});

  final String code;

  /// `.auth__note { margin-top: 12 }`, on top of the form's own gap.
  @override
  double get gapAdjust => LumeAuthMetrics.noteTop;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Text(
      // The code is direction-neutral and sits inside a sentence that may be
      // right-to-left, so it is isolated rather than left to the bidi
      // algorithm.
      l.authLocalCode('$_isolate$code$_isolateEnd'),
      key: LumeAuthKeys.note,
      style: LumeAuthType.caption(context),
      textAlign: TextAlign.center,
    );
  }
}

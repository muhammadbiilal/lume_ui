/// The authentication flow: which screen, what has been typed, and what a
/// submission does with the answer.
///
/// One controller for the whole flow rather than one per screen, because the
/// flow has state that outlives any of its screens — a recovery token, a held
/// destination, which step of a sign-up, when a resend becomes available. The
/// reference keeps the same things in `authCtx` for the same reason.
///
/// **What it is not.** It is not a router. It reports the route it wants and
/// something above it navigates; the decision about whether that route is
/// *allowed* belongs to the startup gate, which is the only place redirects
/// are decided.
///
/// **Sensitive state.** [values] holds what has been typed, passwords
/// included. It is wiped on success, on leaving the flow, and in [dispose] —
/// and nothing ever puts it in a log, a route, an exception or a semantics
/// label. [toString] is deliberately not overridden to print it.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/auth_model.dart';
import '../domain/auth_repository.dart';
import '../domain/password_policy.dart';

/// The eleven compositions, as ten routes plus a step.
enum LumeAuthRoute {
  signIn,
  signUp,
  forgot,
  sent,
  reset,
  updated,
  created,
  expired,
  trouble,
  verify;

  /// The path segment under `/auth`.
  String get segment => switch (this) {
    signIn => 'signin',
    signUp => 'signup',
    forgot => 'forgot',
    sent => 'sent',
    reset => 'reset',
    updated => 'updated',
    created => 'created',
    expired => 'expired',
    trouble => 'trouble',
    verify => 'verify',
  };

  static LumeAuthRoute? fromSegment(String segment) {
    for (final LumeAuthRoute r in values) {
      if (r.segment == segment) return r;
    }
    return null;
  }

  /// A screen that reports rather than asks. Centred hero, no ranged form.
  bool get isStatus => switch (this) {
    sent || updated || created || expired || trouble || verify => true,
    _ => false,
  };

  /// Whether the flow may be dismissed from here at all. `created` and
  /// `expired` are outcomes that have to be dealt with.
  bool get dismissible => this != created && this != expired;
}

/// Why `trouble` is showing.
enum LumeTroubleReason { linkInvalid, linkExpired }

/// Which way the panel came in. Forward and backward are different
/// transitions, so the screen is told which one it is.
enum LumeAuthNav { forward, back }

/// What a submission is for.
enum LumeAuthSubmission { signIn, signUpStep, signUp, forgot, reset, verify }

/// Everything a form screen needs to draw itself.
@immutable
class LumeAuthFormState {
  const LumeAuthFormState({
    this.values = const <LumeAuthField, String>{},
    this.errors = const <LumeAuthField, LumeAuthIssue>{},
    this.valid = const <LumeAuthField>{},
    this.touched = const <LumeAuthField>{},
    this.revealed = const <LumeAuthField>{},
    this.failure,
    this.retryAfter,
    this.busy = false,
  });

  final Map<LumeAuthField, String> values;

  /// Per-field complaints.
  final Map<LumeAuthField, LumeAuthIssue> errors;

  /// Fields that have passed a check they could be judged on in isolation.
  final Set<LumeAuthField> valid;

  /// Fields the user has finished with. Nothing is judged before this.
  final Set<LumeAuthField> touched;

  /// Password fields the user has asked to see. Kept here rather than in the
  /// widget, so a failed submission — which rebuilds the form — does not
  /// re-mask what the user asked to read, exactly when they most want it.
  final Set<LumeAuthField> revealed;

  /// The form-level failure, if the last attempt had one.
  final LumeAuthFailure? failure;

  final Duration? retryAfter;

  /// A submission is in flight. Every action is inert while this is true, so
  /// nothing can be submitted twice.
  final bool busy;

  String read(LumeAuthField f) => values[f] ?? '';

  bool isRevealed(LumeAuthField f) => revealed.contains(f);

  LumeAuthFormState copyWith({
    Map<LumeAuthField, String>? values,
    Map<LumeAuthField, LumeAuthIssue>? errors,
    Set<LumeAuthField>? valid,
    Set<LumeAuthField>? touched,
    Set<LumeAuthField>? revealed,
    LumeAuthFailure? failure,
    Duration? retryAfter,
    bool clearFailure = false,
    bool? busy,
  }) => LumeAuthFormState(
    values: values ?? this.values,
    errors: errors ?? this.errors,
    valid: valid ?? this.valid,
    touched: touched ?? this.touched,
    revealed: revealed ?? this.revealed,
    failure: clearFailure ? null : (failure ?? this.failure),
    retryAfter: clearFailure ? null : (retryAfter ?? this.retryAfter),
    busy: busy ?? this.busy,
  );
}

/// The fields each route starts from.
///
/// A route always begins from a fresh copy, so a half-typed sign-up cannot
/// leak into a sign-in.
const Map<LumeAuthRoute, List<LumeAuthField>> kAuthFields =
    <LumeAuthRoute, List<LumeAuthField>>{
      LumeAuthRoute.signIn: <LumeAuthField>[
        LumeAuthField.email,
        LumeAuthField.password,
      ],
      LumeAuthRoute.signUp: <LumeAuthField>[
        LumeAuthField.name,
        LumeAuthField.email,
        LumeAuthField.password,
        LumeAuthField.confirm,
      ],
      LumeAuthRoute.forgot: <LumeAuthField>[LumeAuthField.email],
      LumeAuthRoute.reset: <LumeAuthField>[
        LumeAuthField.password,
        LumeAuthField.confirm,
      ],
      LumeAuthRoute.verify: <LumeAuthField>[LumeAuthField.code],
    };

class LumeAuthFlowController extends ChangeNotifier {
  LumeAuthFlowController({
    required this.repository,
    LumeAuthRoute initialRoute = LumeAuthRoute.signIn,
    this.modal = false,
    this.pendingDestination,
    DateTime Function()? clock,
    Duration? minimumWork,
  }) : _route = initialRoute,
       _now = clock ?? DateTime.now,
       minimumWork = minimumWork ?? kAuthMinimumWork {
    _resetForm();
    // The window opens when the screen does, however the screen was reached —
    // by the flow moving, or by a link arriving straight on it.
    if (initialRoute == LumeAuthRoute.verify) _openResendWindow();
  }

  /// How long a submission takes *at least*.
  ///
  /// The reference waits a flat 420 ms before answering, so a submission is
  /// always a designed loading state rather than a flicker. With a real
  /// repository the work is real, so this is a floor rather than a delay: a
  /// slow answer takes as long as it takes, and a fast one still reads.
  static const Duration kAuthMinimumWork = Duration(milliseconds: 420);

  /// How long the resend window is. Matched to the repository's, so the
  /// countdown and the refusal agree.
  static const Duration resendWindow = Duration(seconds: 45);

  final LumeAuthRepository repository;
  final Duration minimumWork;
  final DateTime Function() _now;

  /// Whether the flow was put in front of something the user was already
  /// doing. A cross dismisses a modal flow; a back chevron steps through any
  /// flow. They are different controls and are never the same button.
  final bool modal;

  /// A destination held across authentication and resumed afterwards, rather
  /// than swapped for Home.
  final String? pendingDestination;

  LumeAuthRoute _route;
  final List<LumeAuthRoute> _stack = <LumeAuthRoute>[];
  int _step = 1;
  LumeAuthNav _nav = LumeAuthNav.forward;
  LumeAuthFormState _form = const LumeAuthFormState();
  String? _recoveryToken;
  String? _deliveredCode;
  LumeTroubleReason _trouble = LumeTroubleReason.linkInvalid;
  DateTime? _resendAt;
  Timer? _ticker;
  bool _disposed = false;

  /// Set when the flow has finished and the host should leave.
  LumeAuthOutcome? _outcome;

  /// The status the finished flow produced.
  ///
  /// Handed upward rather than fetched again: asking the repository to restore
  /// a second time is a second session restoration, which is exactly what the
  /// startup contract forbids.
  LumeAuthStatus? _finalStatus;

  LumeAuthRoute get route => _route;
  int get step => _route == LumeAuthRoute.signUp ? _step : 1;
  LumeAuthNav get nav => _nav;
  LumeAuthFormState get form => _form;
  LumeTroubleReason get troubleReason => _trouble;
  LumeAuthOutcome? get outcome => _outcome;
  LumeAuthStatus? get finalStatus => _finalStatus;

  /// The code the double handed back, shown only because this build has no
  /// mail server. A repository with one returns `null` and the line vanishes.
  String? get deliveredCode => _deliveredCode;

  /// Whether anything is behind this screen inside the flow.
  bool get canGoBack =>
      _stack.isNotEmpty || (_route == LumeAuthRoute.signUp && _step == 2);

  /// Seconds left on the resend window, or zero when it is open.
  int get resendSeconds {
    final DateTime? at = _resendAt;
    if (at == null) return 0;
    final int left = at.difference(_now()).inMilliseconds;
    return left <= 0 ? 0 : (left / 1000).ceil();
  }

  // ---- routing inside the flow -------------------------------------------

  /// Move to [next].
  ///
  /// Sign-in and sign-up are **siblings, not levels**: hopping between them
  /// unwinds the stack to the earlier visit rather than deepening it, so
  /// escaping does not take one press per hop.
  void go(LumeAuthRoute next, {bool fresh = false, bool back = false}) {
    if (next == _route && !fresh) return;
    final int at = _stack.indexOf(next);
    if (at != -1) {
      _stack.removeRange(at, _stack.length);
    } else if (!back) {
      _stack.add(_route);
    }

    // An outcome is not a step. Nothing behind "your account is ready" is
    // worth returning to.
    if (fresh) _stack.clear();

    _route = next;
    _nav = back ? LumeAuthNav.back : LumeAuthNav.forward;
    if (next == LumeAuthRoute.signUp) _step = 1;
    if (next == LumeAuthRoute.verify) _openResendWindow();
    _resetForm();
    notifyListeners();
  }

  /// The back chevron, the system gesture and Escape.
  ///
  /// Returns `false` when there is nothing left inside the flow, which is the
  /// host's cue to leave it.
  bool back() {
    if (_route == LumeAuthRoute.signUp && _step == 2) {
      // Leaving from step two would throw step one away.
      _step = 1;
      _nav = LumeAuthNav.back;
      _clearErrors();
      notifyListeners();
      return true;
    }
    if (_stack.isEmpty) return false;
    final LumeAuthRoute previous = _stack.removeLast();
    _route = previous;
    _nav = LumeAuthNav.back;
    if (previous == LumeAuthRoute.signUp) _step = 1;
    _resetForm();
    notifyListeners();
    return true;
  }

  /// The cross on a modal flow.
  ///
  /// Dismisses the whole flow rather than stepping through it, and does
  /// nothing at all on a screen that is an outcome to be dealt with.
  void dismiss() {
    if (!_route.dismissible) return;
    _finish(LumeAuthOutcome.dismissed);
  }

  /// "Continue as a guest" on the expiry screen.
  ///
  /// Not a dismissal: the screen has no cross and nothing else leaves it.
  /// Choosing to stay a guest **ends** the dead session rather than leaving it
  /// to interrupt again on the next launch.
  void continueAsGuest() => _finish(LumeAuthOutcome.signedOutGuest);

  /// "Enter Lume" on the arrival screen.
  ///
  /// The account was created when the form was submitted, so the status this
  /// carries is the one that submission produced.
  void complete() => _finish(LumeAuthOutcome.authenticated, status: _created);

  /// Held between creating the account and entering the application.
  LumeAuthStatus? _created;

  void _finish(LumeAuthOutcome how, {LumeAuthStatus? status}) {
    _wipe();
    _stopTicker();
    _outcome = how;
    _finalStatus = status;
    notifyListeners();
  }

  // ---- the form ----------------------------------------------------------

  void edit(LumeAuthField field, String value) {
    final Map<LumeAuthField, String> values = Map<LumeAuthField, String>.of(
      _form.values,
    )..[field] = value;
    // Editing a field drops the verdict on it: a tick that survived the edit
    // that invalidated it would be a lie.
    _form = _form.copyWith(
      values: values,
      errors: Map<LumeAuthField, LumeAuthIssue>.of(_form.errors)..remove(field),
      valid: Set<LumeAuthField>.of(_form.valid)..remove(field),
    );
    notifyListeners();
  }

  /// Called when a field is left.
  ///
  /// Nothing is judged on first render. Only the two checks that can be made
  /// in isolation happen here — whether an address is an address, and whether
  /// a confirmation matches. Everything else waits for the submission, which
  /// is the first moment the form is a whole.
  void leave(LumeAuthField field) {
    final String value = _form.read(field);
    final Set<LumeAuthField> touched = Set<LumeAuthField>.of(_form.touched)
      ..add(field);

    LumeAuthIssue? issue;
    bool? passed;
    if (field == LumeAuthField.email && value.isNotEmpty) {
      passed = LumeEmailPolicy.isValid(value);
      if (!passed) issue = LumeAuthIssue.emailInvalid;
    } else if (field == LumeAuthField.confirm && value.isNotEmpty) {
      passed = value == _form.read(LumeAuthField.password);
      if (!passed) issue = LumeAuthIssue.confirmMismatch;
    }

    if (passed == null) {
      _form = _form.copyWith(touched: touched);
      notifyListeners();
      return;
    }

    _form = _form.copyWith(
      touched: touched,
      valid: Set<LumeAuthField>.of(_form.valid)
        ..removeWhere((LumeAuthField f) => f == field)
        ..addAll(passed ? <LumeAuthField>{field} : const <LumeAuthField>{}),
      errors: Map<LumeAuthField, LumeAuthIssue>.of(_form.errors)
        ..remove(field)
        ..addAll(
          issue == null
              ? const <LumeAuthField, LumeAuthIssue>{}
              : <LumeAuthField, LumeAuthIssue>{field: issue},
        ),
    );
    notifyListeners();
  }

  void toggleReveal(LumeAuthField field) {
    final Set<LumeAuthField> next = Set<LumeAuthField>.of(_form.revealed);
    if (!next.remove(field)) next.add(field);
    _form = _form.copyWith(revealed: next);
    notifyListeners();
  }

  void _resetForm() {
    _form = const LumeAuthFormState();
  }

  void _clearErrors() {
    _form = _form.copyWith(
      errors: const <LumeAuthField, LumeAuthIssue>{},
      clearFailure: true,
    );
  }

  /// Drop everything typed. Called on success, on leaving, and on dispose.
  void _wipe() {
    _form = const LumeAuthFormState();
    _recoveryToken = null;
    _deliveredCode = null;
  }

  // ---- submission --------------------------------------------------------

  /// What the primary action on the current screen does.
  LumeAuthSubmission? get submission => switch (_route) {
    LumeAuthRoute.signIn => LumeAuthSubmission.signIn,
    LumeAuthRoute.signUp =>
      _step == 1 ? LumeAuthSubmission.signUpStep : LumeAuthSubmission.signUp,
    LumeAuthRoute.forgot => LumeAuthSubmission.forgot,
    LumeAuthRoute.reset => LumeAuthSubmission.reset,
    LumeAuthRoute.verify => LumeAuthSubmission.verify,
    _ => null,
  };

  /// Run the primary action.
  ///
  /// Inert while a submission is in flight, which is the whole of the
  /// duplicate-submission guard: there is no second path to here.
  Future<void> submit() async {
    final LumeAuthSubmission? kind = submission;
    if (kind == null || _form.busy) return;

    _form = _form.copyWith(
      busy: true,
      errors: const <LumeAuthField, LumeAuthIssue>{},
      clearFailure: true,
    );
    notifyListeners();

    final Stopwatch watch = Stopwatch()..start();
    LumeAuthResult result;
    try {
      result = await _run(kind);
    } on Object {
      // Whatever a repository throws, the user gets a designed failure rather
      // than a crash. The object itself is not rendered: it could name an
      // address, an endpoint or worse.
      result = const LumeAuthRefused.failed(LumeAuthFailure.network);
    }
    final Duration left = minimumWork - watch.elapsed;
    if (left > Duration.zero) await Future<void>.delayed(left);
    if (_disposed) return;

    _form = _form.copyWith(busy: false);
    _apply(kind, result);
  }

  Future<LumeAuthResult> _run(LumeAuthSubmission kind) => switch (kind) {
    LumeAuthSubmission.signIn => repository.signIn(
      email: _form.read(LumeAuthField.email),
      password: _form.read(LumeAuthField.password),
    ),
    LumeAuthSubmission.signUpStep => repository.checkIdentity(
      name: _form.read(LumeAuthField.name),
      email: _form.read(LumeAuthField.email),
    ),
    LumeAuthSubmission.signUp => repository.signUp(
      name: _form.read(LumeAuthField.name),
      email: _form.read(LumeAuthField.email),
      password: _form.read(LumeAuthField.password),
      confirm: _form.read(LumeAuthField.confirm),
    ),
    LumeAuthSubmission.forgot => repository.requestPasswordReset(
      _form.read(LumeAuthField.email),
    ),
    LumeAuthSubmission.reset => repository.resetPassword(
      token: _recoveryToken ?? '',
      password: _form.read(LumeAuthField.password),
      confirm: _form.read(LumeAuthField.confirm),
    ),
    LumeAuthSubmission.verify => repository.verifyEmail(
      _form.read(LumeAuthField.code),
    ),
  };

  void _apply(LumeAuthSubmission kind, LumeAuthResult result) {
    if (result is LumeAuthRefused) {
      // A recovery link that cannot be redeemed is not something the user can
      // fix by retyping, so it leaves for a screen with a way out rather than
      // putting a red line above a form that will refuse them again.
      if (kind == LumeAuthSubmission.reset &&
          (result.failure == LumeAuthFailure.linkInvalid ||
              result.failure == LumeAuthFailure.linkExpired)) {
        _recoveryToken = null;
        _trouble = result.failure == LumeAuthFailure.linkExpired
            ? LumeTroubleReason.linkExpired
            : LumeTroubleReason.linkInvalid;
        go(LumeAuthRoute.trouble, fresh: true);
        return;
      }
      _form = _form.copyWith(
        errors: result.issues,
        failure: result.failure,
        retryAfter: result.retryAfter,
      );
      notifyListeners();
      return;
    }

    final LumeAuthAccepted ok = result as LumeAuthAccepted;
    switch (kind) {
      case LumeAuthSubmission.signIn:
        _finish(LumeAuthOutcome.authenticated, status: ok.status);
      case LumeAuthSubmission.signUpStep:
        _step = 2;
        _nav = LumeAuthNav.forward;
        _clearErrors();
        notifyListeners();
      case LumeAuthSubmission.signUp:
        // The account exists from here, not from the moment the arrival
        // screen is dismissed.
        _created = ok.status;
        go(LumeAuthRoute.created, fresh: true);
      case LumeAuthSubmission.forgot:
        _recoveryToken = ok.recoveryToken;
        go(LumeAuthRoute.sent);
      case LumeAuthSubmission.reset:
        _recoveryToken = null;
        go(LumeAuthRoute.updated, fresh: true);
      case LumeAuthSubmission.verify:
        _finish(LumeAuthOutcome.verified, status: ok.status);
    }
  }

  /// "Open the reset link" on the neutral confirmation.
  ///
  /// Present only while a token is held. A build with a mail server would
  /// arrive here from the link instead.
  bool get canOpenResetLink => _recoveryToken != null;

  void openResetLink() {
    if (_recoveryToken == null) return;
    go(LumeAuthRoute.reset);
  }

  /// Start an email verification, with the address and code the account
  /// surfaces produced.
  void beginVerification({String? deliveredCode}) {
    go(LumeAuthRoute.verify);
    _deliveredCode = deliveredCode;
    notifyListeners();
  }

  // ---- the resend window -------------------------------------------------

  void _openResendWindow() {
    _resendAt = _now().add(resendWindow);
    _startTicker();
  }

  void _startTicker() {
    _stopTicker();
    // A number that counts down is only honest if it moves.
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (_disposed || _route != LumeAuthRoute.verify) {
        _stopTicker();
        return;
      }
      notifyListeners();
      if (resendSeconds == 0) _stopTicker();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// "Send it again". Only offered once the window is open.
  Future<void> resend() async {
    if (_form.busy || resendSeconds > 0) return;
    _form = _form.copyWith(busy: true, clearFailure: true);
    notifyListeners();

    LumeAuthResult result;
    try {
      result = await repository.resendVerification();
    } on Object {
      result = const LumeAuthRefused.failed(LumeAuthFailure.network);
    }
    if (_disposed) return;

    if (result is LumeAuthRefused) {
      // A refusal that names a wait is the wait: the screen never invents one.
      if (result.failure == LumeAuthFailure.rateLimited &&
          result.retryAfter != null) {
        _resendAt = _now().add(result.retryAfter!);
        _startTicker();
        _form = _form.copyWith(busy: false, clearFailure: true);
      } else {
        _form = _form.copyWith(
          busy: false,
          failure: result.failure,
          errors: result.issues,
        );
      }
      notifyListeners();
      return;
    }

    _deliveredCode = (result as LumeAuthAccepted).deliveredCode;
    _form = _form.copyWith(busy: false);
    _openResendWindow();
    notifyListeners();
  }

  /// Put the flow into a state that would normally take several steps to
  /// reach, so a golden or a test can name it in one line.
  ///
  /// Marked rather than hidden: it exists for tests, and a production caller
  /// that reached for it would be skipping the checks that produce these
  /// states in the first place.
  @visibleForTesting
  void restoreState({
    LumeAuthRoute? route,
    int? step,
    String? recoveryToken,
    String? deliveredCode,
    LumeTroubleReason? trouble,
    bool openResendWindow = false,
  }) {
    if (recoveryToken != null) _recoveryToken = recoveryToken;
    if (deliveredCode != null) _deliveredCode = deliveredCode;
    if (trouble != null) _trouble = trouble;
    if (route != null) {
      _route = route;
      _resetForm();
    }
    if (step != null) _step = step;
    if (openResendWindow) {
      _resendAt = _now().subtract(const Duration(seconds: 1));
      _stopTicker();
    }
    notifyListeners();
  }

  /// The screen holding this controller has gone, but something else owns it.
  ///
  /// Stops the countdown and empties the form without ending the controller's
  /// life — what was typed does not outlive the screen that collected it.
  void leaveFlow() {
    _stopTicker();
    _wipe();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTicker();
    _wipe();
    super.dispose();
  }
}

/// How the flow ended.
enum LumeAuthOutcome {
  /// Signed in or signed up. The held destination, if any, is resumed.
  authenticated,

  /// An email verification completed.
  verified,

  /// Dismissed. Whoever was a guest is still a guest.
  dismissed,

  /// Dismissed from the expiry screen, which ends the dead session.
  signedOutGuest,
}

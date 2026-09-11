/// A deterministic [LumeAuthRepository] with no backend behind it.
///
/// This is the only implementation in the repository, and it exists so that
/// every state a screen can be in is reachable on demand: a refusal, a lock, a
/// dead link, an expired code, a rate limit, a network drop, a restored
/// session, an expired one. A test asks for the state it wants and gets
/// exactly that, every time.
///
/// **Not persistence and not security.** Accounts live in a map for the life
/// of the process, passwords are held as the strings they are because there is
/// nothing to protect them from here, and nothing is written to disk. A build
/// that shipped this would have no accounts after a restart, which is the
/// honest shape of a reference application with no backend.
///
/// [LumeAuthScript] is how a test asks for a failure. Setting
/// `nextFailure` makes the *next* call refuse with it, whatever the
/// credentials say — so "what does the screen do when the network is gone" is
/// one line rather than a mock framework.
library;

import 'dart:async';

import '../domain/auth_model.dart';
import '../domain/auth_repository.dart';
import '../domain/password_policy.dart';

/// One account, as the double keeps it.
class LumeFakeAccount {
  LumeFakeAccount({
    required this.id,
    required this.email,
    required this.password,
    this.displayName = '',
    this.locked = false,
    this.emailVerified = false,
  });

  final String id;
  String email;
  String password;
  String displayName;
  bool locked;
  bool emailVerified;

  String? pendingEmail;
  String? pendingCode;
  DateTime? codeExpires;

  String? resetToken;
  DateTime? resetExpires;

  /// Bumped by a password change, which is what makes live sessions stale.
  int generation = 0;
}

/// What the next call should do instead of working.
class LumeAuthScript {
  LumeAuthScript();

  /// Applied to the next call, then cleared.
  LumeAuthFailure? nextFailure;

  /// Paired with [LumeAuthFailure.rateLimited].
  Duration? retryAfter;

  /// How long a call takes. Zero in tests that do not care; the product's
  /// 420 ms deliberate pause is the flow controller's, not this.
  Duration latency = Duration.zero;

  void fail(LumeAuthFailure failure, {Duration? retryAfter}) {
    nextFailure = failure;
    this.retryAfter = retryAfter;
  }

  LumeAuthRefused? take() {
    final LumeAuthFailure? f = nextFailure;
    if (f == null) return null;
    final Duration? after = retryAfter;
    nextFailure = null;
    retryAfter = null;
    return LumeAuthRefused.failed(f, retryAfter: after);
  }
}

class LumeFakeAuthRepository implements LumeAuthRepository {
  LumeFakeAuthRepository({
    List<LumeFakeAccount>? accounts,
    LumeAuthStatus? restored,
    DateTime Function()? clock,
    LumeAuthScript? script,
  }) : script = script ?? LumeAuthScript(),
       _now = clock ?? DateTime.now,
       _restored = restored {
    for (final LumeFakeAccount a in accounts ?? const <LumeFakeAccount>[]) {
      _accounts[LumeEmailPolicy.normalise(a.email)] = a;
    }
  }

  /// A repository holding one account, which is what most tests want.
  factory LumeFakeAuthRepository.withAccount({
    String email = 'amina@example.com',
    String password = 'Passw0rdy',
    String displayName = 'Amina Tariq',
    bool locked = false,
    LumeAuthStatus? restored,
    DateTime Function()? clock,
  }) => LumeFakeAuthRepository(
    accounts: <LumeFakeAccount>[
      LumeFakeAccount(
        id: 'usr-1',
        email: email,
        password: password,
        displayName: displayName,
        locked: locked,
      ),
    ],
    restored: restored,
    clock: clock,
  );

  final LumeAuthScript script;
  final DateTime Function() _now;
  final Map<String, LumeFakeAccount> _accounts = <String, LumeFakeAccount>{};

  LumeAuthStatus? _restored;
  LumeAuthStatus _status = const LumeAuthStatus.guest();

  /// How many times [restore] has been called. Running session restoration
  /// twice is a defect the startup tests assert against, so it is countable.
  int restores = 0;

  /// The window a resend has to wait out. The reference's is 45 seconds.
  static const Duration resendWindow = Duration(seconds: 45);

  /// How long a verification code lives.
  static const Duration codeWindow = Duration(minutes: 10);

  /// How long a recovery link lives.
  static const Duration linkWindow = Duration(hours: 1);

  DateTime? _lastResend;

  Future<void> _wait() => script.latency == Duration.zero
      ? Future<void>.value()
      : Future<void>.delayed(script.latency);

  LumeAccount _public(LumeFakeAccount a) => LumeAccount(
    id: a.id,
    email: a.email,
    displayName: a.displayName,
    emailVerified: a.emailVerified,
    pendingEmail: a.pendingEmail,
  );

  LumeAuthStatus _signedIn(LumeFakeAccount a) {
    final DateTime now = _now();
    return LumeAuthStatus(
      state: LumeSessionState.authenticated,
      account: _public(a),
      session: LumeSession(
        email: a.email,
        deviceId: 'dev-fake',
        issued: now,
        expires: now.add(const Duration(days: 30)),
      ),
    );
  }

  /// The current status, for a controller that wants it without a round trip.
  LumeAuthStatus get status => _status;

  @override
  Future<LumeAuthStatus> restore() async {
    restores++;
    await _wait();
    final LumeAuthRefused? scripted = script.take();
    if (scripted != null) {
      // A restore that cannot be completed is a guest, not a crash. Nothing
      // about a failed read says the user is signed in.
      _status = const LumeAuthStatus.guest();
      return _status;
    }

    final LumeAuthStatus? given = _restored;
    if (given == null) {
      _status = const LumeAuthStatus.guest();
      return _status;
    }

    // Expiry fails closed, and is decided here rather than trusted.
    final LumeSession? s = given.session;
    if (given.state == LumeSessionState.authenticated &&
        s != null &&
        s.isExpiredAt(_now())) {
      _status = LumeAuthStatus(
        state: LumeSessionState.expired,
        account: given.account,
        session: s,
      );
      return _status;
    }
    _status = given;
    return _status;
  }

  @override
  Future<LumeAuthResult> signIn({
    required String email,
    required String password,
  }) async {
    await _wait();
    final LumeAuthRefused? scripted = script.take();
    if (scripted != null) return scripted;

    final Map<LumeAuthField, LumeAuthIssue> issues =
        <LumeAuthField, LumeAuthIssue>{};
    final String mail = LumeEmailPolicy.normalise(email);
    if (mail.isEmpty) {
      issues[LumeAuthField.email] = LumeAuthIssue.emailRequired;
    } else if (!LumeEmailPolicy.isValid(mail)) {
      issues[LumeAuthField.email] = LumeAuthIssue.emailInvalid;
    }
    if (password.isEmpty) {
      issues[LumeAuthField.password] = LumeAuthIssue.passwordRequired;
    }
    if (issues.isNotEmpty) return LumeAuthRefused.fields(issues);

    final LumeFakeAccount? found = _accounts[mail];
    // One answer for "no such account" and "wrong password".
    if (found == null || found.password != password) {
      return const LumeAuthRefused.failed(LumeAuthFailure.credentials);
    }
    if (found.locked) {
      return const LumeAuthRefused.failed(LumeAuthFailure.locked);
    }

    _status = _signedIn(found);
    return LumeAuthAccepted(status: _status);
  }

  Map<LumeAuthField, LumeAuthIssue> _identityIssues(String email) {
    final Map<LumeAuthField, LumeAuthIssue> issues =
        <LumeAuthField, LumeAuthIssue>{};
    final String mail = LumeEmailPolicy.normalise(email);
    if (mail.isEmpty) {
      issues[LumeAuthField.email] = LumeAuthIssue.emailRequired;
    } else if (!LumeEmailPolicy.isValid(mail)) {
      issues[LumeAuthField.email] = LumeAuthIssue.emailInvalid;
    } else if (_accounts.containsKey(mail)) {
      issues[LumeAuthField.email] = LumeAuthIssue.emailTaken;
    }
    return issues;
  }

  @override
  Future<LumeAuthResult> checkIdentity({
    required String name,
    required String email,
  }) async {
    await _wait();
    final LumeAuthRefused? scripted = script.take();
    if (scripted != null) return scripted;

    final Map<LumeAuthField, LumeAuthIssue> issues = _identityIssues(email);
    return issues.isEmpty
        ? const LumeAuthAccepted()
        : LumeAuthRefused.fields(issues);
  }

  @override
  Future<LumeAuthResult> signUp({
    required String name,
    required String email,
    required String password,
    required String confirm,
  }) async {
    await _wait();
    final LumeAuthRefused? scripted = script.take();
    if (scripted != null) return scripted;

    final Map<LumeAuthField, LumeAuthIssue> issues = _identityIssues(email);
    if (password.isEmpty) {
      issues[LumeAuthField.password] = LumeAuthIssue.passwordRequired;
    } else if (!LumePasswordPolicy.isAcceptable(password)) {
      issues[LumeAuthField.password] = LumeAuthIssue.passwordWeak;
    }
    if (confirm.isEmpty) {
      issues[LumeAuthField.confirm] = LumeAuthIssue.confirmRequired;
    } else if (confirm != password) {
      issues[LumeAuthField.confirm] = LumeAuthIssue.confirmMismatch;
    }
    if (issues.isNotEmpty) return LumeAuthRefused.fields(issues);

    final String mail = LumeEmailPolicy.normalise(email);
    final LumeFakeAccount created = LumeFakeAccount(
      id: 'usr-${_accounts.length + 1}',
      email: mail,
      password: password,
      displayName: name.trim(),
    );
    _accounts[mail] = created;
    _status = _signedIn(created);
    return LumeAuthAccepted(status: _status);
  }

  @override
  Future<LumeAuthResult> requestPasswordReset(String email) async {
    await _wait();
    final LumeAuthRefused? scripted = script.take();
    if (scripted != null) return scripted;

    final String mail = LumeEmailPolicy.normalise(email);
    if (mail.isEmpty) {
      return const LumeAuthRefused.fields(<LumeAuthField, LumeAuthIssue>{
        LumeAuthField.email: LumeAuthIssue.emailRequired,
      });
    }
    if (!LumeEmailPolicy.isValid(mail)) {
      return const LumeAuthRefused.fields(<LumeAuthField, LumeAuthIssue>{
        LumeAuthField.email: LumeAuthIssue.emailInvalid,
      });
    }

    // Neutral: a token of the same shape either way. An address with no
    // account gets one that simply resolves to nothing when it is redeemed,
    // so nothing downstream can render the difference.
    // Fixed width, so the token's *length* cannot differ between an address
    // that has an account and one that does not. Neutrality that leaks through
    // a string length is not neutrality.
    final String token =
        'rst-${mail.hashCode.toUnsigned(32).toRadixString(16).padLeft(8, '0')}';
    final LumeFakeAccount? found = _accounts[mail];
    if (found != null) {
      found.resetToken = token;
      found.resetExpires = _now().add(linkWindow);
    }
    return LumeAuthAccepted(recoveryToken: token);
  }

  @override
  Future<LumeAuthResult> resetPassword({
    required String token,
    required String password,
    required String confirm,
  }) async {
    await _wait();
    final LumeAuthRefused? scripted = script.take();
    if (scripted != null) return scripted;

    final Map<LumeAuthField, LumeAuthIssue> issues =
        <LumeAuthField, LumeAuthIssue>{};
    if (password.isEmpty) {
      issues[LumeAuthField.password] = LumeAuthIssue.passwordRequired;
    } else if (!LumePasswordPolicy.isAcceptable(password)) {
      issues[LumeAuthField.password] = LumeAuthIssue.passwordWeak;
    }
    if (confirm != password) {
      issues[LumeAuthField.confirm] = LumeAuthIssue.confirmMismatch;
    }
    // The field rules are answered before the link is, so somebody with a dead
    // link and a weak password is told about the password they can still fix.
    if (issues.isNotEmpty) return LumeAuthRefused.fields(issues);

    LumeFakeAccount? holder;
    for (final LumeFakeAccount a in _accounts.values) {
      if (a.resetToken != null && a.resetToken == token) holder = a;
    }
    if (holder == null) {
      return const LumeAuthRefused.failed(LumeAuthFailure.linkInvalid);
    }
    final DateTime? expires = holder.resetExpires;
    if (expires == null || !_now().isBefore(expires)) {
      return const LumeAuthRefused.failed(LumeAuthFailure.linkExpired);
    }

    holder.password = password;
    holder.resetToken = null;
    holder.resetExpires = null;
    holder.generation++;
    // A password change invalidates every session, including this device's.
    if (_status.account?.email == holder.email) {
      _status = const LumeAuthStatus.guest();
    }
    return const LumeAuthAccepted();
  }

  /// Start an email change, which is what puts the verify screen in reach.
  ///
  /// Not part of [LumeAuthRepository]: changing an address belongs to the
  /// account surfaces, and F4C only needs the state it produces.
  LumeAuthResult requestEmailChange(String next) {
    final LumeFakeAccount? me = _current();
    if (me == null) {
      return const LumeAuthRefused.failed(LumeAuthFailure.signedOut);
    }
    final String mail = LumeEmailPolicy.normalise(next);
    if (!LumeEmailPolicy.isValid(mail)) {
      return const LumeAuthRefused.fields(<LumeAuthField, LumeAuthIssue>{
        LumeAuthField.email: LumeAuthIssue.emailInvalid,
      });
    }
    if (mail == me.email) {
      return const LumeAuthRefused.fields(<LumeAuthField, LumeAuthIssue>{
        LumeAuthField.email: LumeAuthIssue.emailSame,
      });
    }
    if (_accounts.containsKey(mail)) {
      return const LumeAuthRefused.fields(<LumeAuthField, LumeAuthIssue>{
        LumeAuthField.email: LumeAuthIssue.emailTaken,
      });
    }
    me.pendingEmail = mail;
    me.pendingCode = '384512';
    me.codeExpires = _now().add(codeWindow);
    _lastResend = _now();
    _status = LumeAuthStatus(
      state: _status.state,
      account: _public(me),
      session: _status.session,
    );
    return LumeAuthAccepted(deliveredCode: me.pendingCode);
  }

  LumeFakeAccount? _current() {
    final String? mail = _status.signedInAccount?.email;
    return mail == null ? null : _accounts[mail];
  }

  @override
  Future<LumeAuthResult> resendVerification() async {
    await _wait();
    final LumeAuthRefused? scripted = script.take();
    if (scripted != null) return scripted;

    final LumeFakeAccount? me = _current();
    if (me == null || me.pendingEmail == null) {
      return const LumeAuthRefused.failed(LumeAuthFailure.nothingPending);
    }

    // Rate limited by the repository, so the screen draws a countdown it did
    // not invent and cannot disagree with.
    final DateTime? last = _lastResend;
    if (last != null) {
      final Duration since = _now().difference(last);
      if (since < resendWindow) {
        return LumeAuthRefused.failed(
          LumeAuthFailure.rateLimited,
          retryAfter: resendWindow - since,
        );
      }
    }

    _lastResend = _now();
    me.codeExpires = _now().add(codeWindow);
    return LumeAuthAccepted(deliveredCode: me.pendingCode);
  }

  @override
  Future<LumeAuthResult> verifyEmail(String code) async {
    await _wait();
    final LumeAuthRefused? scripted = script.take();
    if (scripted != null) return scripted;

    final LumeFakeAccount? me = _current();
    final String? pending = me?.pendingEmail;
    if (me == null || pending == null) {
      return const LumeAuthRefused.failed(LumeAuthFailure.nothingPending);
    }
    if (code.trim().isEmpty) {
      return const LumeAuthRefused.fields(<LumeAuthField, LumeAuthIssue>{
        LumeAuthField.code: LumeAuthIssue.codeRequired,
      });
    }
    final DateTime? expires = me.codeExpires;
    if (expires == null || !_now().isBefore(expires)) {
      return const LumeAuthRefused.failed(LumeAuthFailure.codeExpired);
    }
    if (code.trim() != me.pendingCode) {
      return const LumeAuthRefused.fields(<LumeAuthField, LumeAuthIssue>{
        LumeAuthField.code: LumeAuthIssue.codeIncorrect,
      });
    }
    // The address was free when the change was asked for. It may not be now.
    if (_accounts.containsKey(pending)) {
      me.pendingEmail = null;
      me.pendingCode = null;
      return const LumeAuthRefused.fields(<LumeAuthField, LumeAuthIssue>{
        LumeAuthField.code: LumeAuthIssue.emailTaken,
      });
    }

    _accounts.remove(me.email);
    me.email = pending;
    me.emailVerified = true;
    me.pendingEmail = null;
    me.pendingCode = null;
    me.codeExpires = null;
    _accounts[me.email] = me;
    _status = _signedIn(me);
    return LumeAuthAccepted(status: _status);
  }

  @override
  Future<void> signOut() async {
    await _wait();
    _restored = null;
    _status = const LumeAuthStatus.guest();
  }

  /// Force the stored session past its expiry, so the expired state can be
  /// reached without waiting a month.
  void expireSession() {
    final LumeAuthStatus current = _restored ?? _status;
    final LumeSession? s = current.session;
    if (s == null) return;
    final LumeSession dead = LumeSession(
      email: s.email,
      deviceId: s.deviceId,
      issued: s.issued,
      expires: _now().subtract(const Duration(seconds: 1)),
    );
    _restored = LumeAuthStatus(
      state: LumeSessionState.expired,
      account: current.account,
      session: dead,
    );
    _status = _restored!;
  }

  /// A restored session for [email], as a launch would find it.
  void seedSession(String email, {Duration life = const Duration(days: 30)}) {
    final LumeFakeAccount? a = _accounts[LumeEmailPolicy.normalise(email)];
    if (a == null) return;
    final DateTime now = _now();
    _restored = LumeAuthStatus(
      state: LumeSessionState.authenticated,
      account: _public(a),
      session: LumeSession(
        email: a.email,
        deviceId: 'dev-fake',
        issued: now,
        expires: now.add(life),
      ),
    );
  }
}

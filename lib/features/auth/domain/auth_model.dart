/// What authentication is made of: an account, a session, and the two kinds of
/// answer an attempt can come back with.
///
/// Nothing here knows what a backend is. A repository that talks to Supabase,
/// Firebase or Dayroz's own service maps whatever it receives onto
/// [LumeAuthFailure] and [LumeAuthIssue] before it returns — so a widget never
/// sees a provider's error code, and swapping the provider cannot change what
/// a screen says.
///
/// The split between the two failure kinds is the reference's, and it is a
/// design rule rather than a convenience: an [LumeAuthIssue] belongs to a
/// field and is fixed by retyping it, and a [LumeAuthFailure] belongs to the
/// attempt and is not. The second kind is why `trouble` exists as a screen —
/// "a failure the user cannot fix by retyping gets a screen and a way out, not
/// a red line above a form that will refuse them again".
library;

import 'package:flutter/foundation.dart';

/// The three states the application can be in with respect to an account.
///
/// `expired` is a real state, not a flavour of signed out: the account is
/// known, the address can be shown back masked, and the way out is to sign in
/// again rather than to start from nothing.
enum LumeSessionState {
  /// Nobody is signed in, and nobody was. The application works.
  guest,

  /// A live session.
  authenticated,

  /// A session that has run out, or whose device row was revoked from
  /// elsewhere. Not authenticated, and not a guest either.
  expired,
}

/// A person's account, as far as the client is allowed to know.
///
/// No password, no digest, no token. There is nothing in this class that would
/// be a problem in a log, which is the point.
@immutable
class LumeAccount {
  const LumeAccount({
    required this.id,
    required this.email,
    this.displayName = '',
    this.emailVerified = false,
    this.pendingEmail,
  });

  final String id;
  final String email;
  final String displayName;
  final bool emailVerified;

  /// An address waiting on a verification code. The account's identity never
  /// moves until the code is accepted.
  final String? pendingEmail;

  LumeAccount copyWith({
    String? email,
    String? displayName,
    bool? emailVerified,
    String? pendingEmail,
    bool clearPending = false,
  }) => LumeAccount(
    id: id,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    emailVerified: emailVerified ?? this.emailVerified,
    pendingEmail: clearPending ? null : (pendingEmail ?? this.pendingEmail),
  );

  @override
  bool operator ==(Object other) =>
      other is LumeAccount &&
      other.id == id &&
      other.email == email &&
      other.displayName == displayName &&
      other.emailVerified == emailVerified &&
      other.pendingEmail == pendingEmail;

  @override
  int get hashCode =>
      Object.hash(id, email, displayName, emailVerified, pendingEmail);
}

/// A session, as the client holds it.
///
/// The token is opaque and is never rendered, never logged and never put in a
/// route. It is here because a repository needs somewhere to keep it; nothing
/// in the presentation layer reads it.
@immutable
class LumeSession {
  const LumeSession({
    required this.email,
    required this.deviceId,
    required this.issued,
    required this.expires,
    this.revoked = false,
  });

  final String email;
  final String deviceId;
  final DateTime issued;
  final DateTime expires;

  /// Signed out from another device, or invalidated by a password change.
  final bool revoked;

  /// Expiry fails **closed**: anything that is not provably in the future is
  /// expired. A corrupt timestamp that compares false used to read as valid
  /// for ever.
  bool isExpiredAt(DateTime now) => revoked || !now.isBefore(expires);

  @override
  bool operator ==(Object other) =>
      other is LumeSession &&
      other.email == email &&
      other.deviceId == deviceId &&
      other.issued == issued &&
      other.expires == expires &&
      other.revoked == revoked;

  @override
  int get hashCode => Object.hash(email, deviceId, issued, expires, revoked);
}

/// Where the application stands. The one thing the router reads.
@immutable
class LumeAuthStatus {
  const LumeAuthStatus({required this.state, this.account, this.session});

  /// Nobody signed in.
  const LumeAuthStatus.guest()
    : state = LumeSessionState.guest,
      account = null,
      session = null;

  final LumeSessionState state;

  /// The account. Present when authenticated, and **also** present when
  /// expired — that is what lets the expiry screen greet a returning holder by
  /// their masked address. Nothing else may read it as an identity.
  final LumeAccount? account;

  final LumeSession? session;

  bool get isAuthenticated => state == LumeSessionState.authenticated;
  bool get isGuest => state == LumeSessionState.guest;
  bool get isExpired => state == LumeSessionState.expired;

  /// The account only when it is a live identity. The expiry case answers
  /// `null` here on purpose.
  LumeAccount? get signedInAccount => isAuthenticated ? account : null;

  @override
  bool operator ==(Object other) =>
      other is LumeAuthStatus &&
      other.state == state &&
      other.account == account &&
      other.session == session;

  @override
  int get hashCode => Object.hash(state, account, session);
}

/// A field an attempt can complain about.
enum LumeAuthField { name, email, password, confirm, code }

/// A complaint about one field. Fixed by retyping it.
enum LumeAuthIssue {
  emailRequired,
  emailInvalid,
  emailTaken,
  emailSame,
  passwordRequired,
  passwordWeak,
  confirmRequired,
  confirmMismatch,
  codeRequired,
  codeIncorrect,
}

/// A failure of the attempt itself. Not fixed by retyping.
enum LumeAuthFailure {
  /// Unknown account **or** wrong password. One message for both: the
  /// difference between them is exactly what an attacker is asking for.
  credentials,

  /// The account is locked and needs a reset to open again.
  locked,

  /// A recovery link that was already used, or was issued for another
  /// address.
  linkInvalid,

  /// A recovery link past its hour.
  linkExpired,

  /// A verification code past its window. Distinct from a wrong one, because
  /// the way out is different: ask for another rather than look harder.
  codeExpired,

  /// There is no email change waiting to be verified.
  nothingPending,

  /// Too many attempts, too quickly. Carries [LumeAuthRefused.retryAfter].
  rateLimited,

  /// The device could not reach the network. Nothing was lost.
  network,

  /// The device could not save. A designed failure, not a silent one.
  storage,

  /// The action needs an account and there is none.
  signedOut,
}

/// What an attempt comes back as.
@immutable
sealed class LumeAuthResult {
  const LumeAuthResult();

  bool get ok => this is LumeAuthAccepted;
}

/// It worked. Carries only what the next screen needs.
@immutable
final class LumeAuthAccepted extends LumeAuthResult {
  const LumeAuthAccepted({this.status, this.recoveryToken, this.deliveredCode});

  /// The status after the attempt, when the attempt changed it.
  final LumeAuthStatus? status;

  /// A recovery token, held for the length of the flow and dropped the moment
  /// it is spent. Opaque, and never rendered.
  final String? recoveryToken;

  /// **Test doubles only.** The reference has no mail server and prints the
  /// code on the screen so the flow can be walked; a real repository returns
  /// `null` here and the code arrives by mail. Nothing logs it.
  final String? deliveredCode;
}

/// It did not. Either a set of field complaints, or one failure, never both.
@immutable
final class LumeAuthRefused extends LumeAuthResult {
  const LumeAuthRefused.fields(this.issues) : failure = null, retryAfter = null;

  const LumeAuthRefused.failed(LumeAuthFailure this.failure, {this.retryAfter})
    : issues = const <LumeAuthField, LumeAuthIssue>{};

  final Map<LumeAuthField, LumeAuthIssue> issues;
  final LumeAuthFailure? failure;

  /// How long until the action is worth trying again. Only ever set with
  /// [LumeAuthFailure.rateLimited].
  final Duration? retryAfter;
}

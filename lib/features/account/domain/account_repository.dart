/// What the account section reads and writes.
///
/// **Five contracts, not one.** `services/account.js` is a single engine
/// because the prototype has one file; a real build has an identity service, a
/// preference store, a session service, a sync service and a local library,
/// and they fail independently. Splitting them here is what lets the Dayroz
/// adapters arrive one at a time.
///
/// Nothing in any of them takes or returns a secret. A password goes *in* to
/// be checked and never comes back out; what crosses the boundary is a
/// [LumeAccountResult].
library;

import 'package:flutter/foundation.dart';

import 'account_model.dart';

/// Why an account operation refused.
///
/// A repository never hands a widget an exception, a status code or a driver
/// message. It hands it one of these, and the screen decides what to say — so
/// the copy is localised in one place and the same refusal cannot read two
/// ways on two screens.
enum LumeAccountFailure {
  /// The password given does not match.
  wrongPassword,

  /// The new password is not acceptable. The policy says why.
  weakPassword,

  /// The two entries differ.
  mismatch,

  /// Not a valid address.
  invalidEmail,

  /// Somebody already has it.
  emailTaken,

  /// Not a usable number.
  invalidPhone,

  /// A name is required and was blank.
  nameRequired,

  /// The account is locked.
  locked,

  /// No account on this device. Every protected route checks first, so this
  /// is a race rather than a normal path.
  signedOut,

  /// Local storage refused the write.
  storage,

  /// Nothing could be reached.
  unreachable,
}

/// Thrown by a repository, caught by a controller, never seen by a widget.
class LumeAccountException implements Exception {
  const LumeAccountException(this.failure, {this.field});

  final LumeAccountFailure failure;

  /// Which form field the refusal belongs to, when it belongs to one:
  /// `current`, `password`, `confirm`, `email`, `phone`, `displayName`.
  /// `null` means the form as a whole.
  final String? field;

  @override
  String toString() =>
      'LumeAccountException(${failure.name}${field == null ? '' : ', $field'})';
}

/// What a write came back with.
@immutable
class LumeAccountResult {
  const LumeAccountResult.ok({this.identity}) : failure = null, field = null;

  const LumeAccountResult.refused(this.failure, {this.field}) : identity = null;

  /// The account after the write, when there is one.
  final LumeAccountIdentity? identity;

  final LumeAccountFailure? failure;
  final String? field;

  bool get isOk => failure == null;
}

/// Identity: who the account belongs to, and the parts of it that can change.
abstract interface class LumeAccountRepository {
  /// Guest, signed in, or a session that has run out.
  LumeAccountState get state;

  /// `null` for a guest. For an expired session this is still the account the
  /// device remembers — which is what lets the screen say whose it is.
  LumeAccountIdentity? get identity;

  /// Which routes need an account.
  ///
  /// *"Only the account's own surfaces. Nothing in the catalogue is gated
  /// behind sign-in, because nothing in it needs to be."* Data & sync is not
  /// one of them: it describes what is on this device, which is exactly as
  /// true for a guest, and a row a guest can see must lead somewhere.
  bool requiresAccount(LumeAccountRoute route);

  /// Name, phone and photo. A guest may change their display name too — §124.4
  /// promised the onboarding name could be changed later, and the only screen
  /// that changes it must not require an account.
  Future<LumeAccountResult> updateIdentity({
    String? displayName,
    String? firstName,
    String? lastName,
    String? phone,
    String? photo,
  });

  /// Start a change of address. The identity does not move until the code is
  /// accepted; until then it is [LumeAccountIdentity.pendingEmail].
  Future<LumeAccountResult> requestEmailChange(String email);

  /// Abandon a pending change.
  Future<LumeAccountResult> cancelEmailChange();

  /// Replace the password.
  ///
  /// Every other session is invalidated: a password change that left old
  /// sessions alive would not be a password change.
  Future<LumeAccountResult> changePassword({
    required String current,
    required String password,
    required String confirm,
  });
}

/// Sessions: which devices are holding one, and how to end them.
abstract interface class LumeSessionRepository {
  /// Most recently seen first, with this device flagged.
  Future<List<LumeDeviceSession>> sessions();

  /// End one.
  ///
  /// Revoking *this* device is a sign-out, and the caller has to know that so
  /// it can re-render the whole shell rather than one settings screen — so the
  /// result says whether it was.
  Future<LumeRevokeResult> revoke(String id);

  /// End every session but this one.
  Future<LumeRevokeResult> signOutOthers();
}

/// What a revocation did.
@immutable
class LumeRevokeResult {
  const LumeRevokeResult({required this.revoked, this.signedOutSelf = false});

  final int revoked;

  /// The reader ended their own session. The shell has to be told.
  final bool signedOutSelf;
}

/// What is stored, and where.
abstract interface class LumeSyncRepository {
  Future<LumeStoredData> stored();
}

/// Ending the account.
///
/// Its own contract, because deletion is not an edit: it needs a confirmed
/// password, it cannot be undone, and it must be impossible to reach by
/// accident from a screen that merely changes a name.
abstract interface class LumeAccountDeletion {
  /// Checks the password and deletes. The session ends and the local
  /// preferences survive — §37: changing an account must not delete the
  /// reader's notes, tasks or favourites.
  Future<LumeAccountResult> deleteAccount({required String password});
}

/// Whether a write survives the process.
///
/// Reported rather than assumed. A fixture answers `false`, and a test asserts
/// that nothing upstream calls it storage.
abstract interface class LumeDurability {
  bool get isDurable;
}

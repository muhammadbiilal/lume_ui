/// The authentication contract Dayroz will implement.
///
/// Everything below returns a [LumeAuthResult]. An implementation that talks
/// to a real service maps its own errors onto [LumeAuthFailure] and
/// [LumeAuthIssue] **inside the repository** — a widget must never see a
/// provider's error code, and swapping the provider must not be able to change
/// what a screen says.
///
/// Obligations beyond the signatures:
///
/// 1. **Passwords and codes are arguments, never state.** Nothing here stores
///    a password, returns one, or puts one anywhere it could be logged.
///    [LumeAuthAccepted.deliveredCode] exists only for doubles, and the doc on
///    it says so.
/// 2. **Unknown account and wrong password are one answer.**
///    [LumeAuthFailure.credentials] is returned for both. The difference
///    between them is what an attacker is asking for.
/// 3. **A reset request is neutral.** [requestPasswordReset] succeeds whether
///    or not the address has an account, and returns a token of the same shape
///    either way, so nothing downstream can render the difference.
/// 4. **Expiry fails closed.** [restore] answers
///    [LumeSessionState.expired] for anything it cannot prove is live.
library;

import 'auth_model.dart';

abstract interface class LumeAuthRepository {
  /// What the stored session amounts to, read once at startup.
  ///
  /// The startup gate waits for this rather than guessing, which is what stops
  /// Sign In flashing in front of a user who is signed in.
  Future<LumeAuthStatus> restore();

  /// Email and password.
  ///
  /// Refuses with [LumeAuthFailure.credentials] for an unknown account and for
  /// a wrong password alike.
  Future<LumeAuthResult> signIn({
    required String email,
    required String password,
  });

  /// The identity half of a sign-up, checked on its own.
  ///
  /// Runs the same rules the full submission will run, so a progressive form
  /// can never accept a first step that the second step would reject.
  Future<LumeAuthResult> checkIdentity({
    required String name,
    required String email,
  });

  /// The whole sign-up. Starts a session on success.
  Future<LumeAuthResult> signUp({
    required String name,
    required String email,
    required String password,
    required String confirm,
  });

  /// Ask for a recovery link. Neutral — see obligation 3.
  Future<LumeAuthResult> requestPasswordReset(String email);

  /// Spend a recovery token.
  ///
  /// Invalidates every session for that account, because a password change
  /// that left old sessions alive would not be a password change.
  Future<LumeAuthResult> resetPassword({
    required String token,
    required String password,
    required String confirm,
  });

  /// Ask for a code to be sent to the address waiting on verification.
  ///
  /// Rate-limited by the repository, not by the screen: refusing with
  /// [LumeAuthFailure.rateLimited] and a `retryAfter` is what lets the screen
  /// draw a countdown it did not invent.
  Future<LumeAuthResult> resendVerification();

  /// Redeem a verification code.
  Future<LumeAuthResult> verifyEmail(String code);

  /// Drop the session. Never a wipe: the device keeps what the device made.
  Future<void> signOut();
}

/// The account section, as a deterministic fixture.
///
/// It behaves like the engine in `services/account.js` — the same rules, the
/// same refusals, the same order of checks — and it stores nothing beyond the
/// life of the process. **It is never described as durable, live or
/// server-verified**, and `isDurable` says so to anyone who asks.
///
/// A password is compared here and never kept: the fixture holds a *seeded*
/// password for the account it was constructed with, and nothing in the
/// domain, the widgets or the semantics ever sees it.
library;

import 'dart:async';

import '../../auth/domain/auth_model.dart';
import '../../auth/domain/password_policy.dart';
import '../domain/account_model.dart';
import '../domain/account_repository.dart';

/// `EMAIL_RE` in `account.js`, which is stricter than the field's `type`.
final RegExp _email = RegExp(
  r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+"
  r"(\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*"
  r'@([A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?\.)+[A-Za-z]{2,24}$',
);

/// A number Lume will accept: digits, spaces, dashes and one leading plus.
final RegExp _phone = RegExp(r'^\+?[0-9][0-9 \-()]{5,19}$');

/// The account, the devices and the rules, for as long as the process lives.
class LumeFakeAccountRepository
    implements
        LumeAccountRepository,
        LumeSessionRepository,
        LumeSyncRepository,
        LumeAccountDeletion,
        LumeDurability {
  LumeFakeAccountRepository({
    LumeAccountIdentity? identity,
    this.state = LumeAccountState.authed,
    String password = 'correct horse',
    List<LumeDeviceSession>? sessions,
    this.delay = Duration.zero,
    this.failWith,
  }) : _identity = identity ?? _seedIdentity,
       _password = password,
       _sessions = List<LumeDeviceSession>.of(sessions ?? _seedSessions);

  /// A guest: no account on this device.
  factory LumeFakeAccountRepository.guest() => LumeFakeAccountRepository(
    identity: null,
    state: LumeAccountState.guest,
    sessions: const <LumeDeviceSession>[],
  );

  /// An account this device remembers, whose session has run out.
  factory LumeFakeAccountRepository.expired() =>
      LumeFakeAccountRepository(state: LumeAccountState.expired);

  /// One device, so the "no other devices" state has something to draw.
  factory LumeFakeAccountRepository.aloneOnThisDevice() =>
      LumeFakeAccountRepository(
        sessions: <LumeDeviceSession>[_seedSessions.first],
      );

  static final LumeAccountIdentity _seedIdentity = LumeAccountIdentity(
    email: 'amina@example.com',
    createdAt: DateTime(2024, 3, 18),
    // The same figures `measure_destinations.mjs` writes into
    // `lume-accounts`, so a capture and a golden describe the same person and
    // the comparison is about the layout rather than about the name.
    displayName: 'Amina Rahman',
    firstName: 'Amina',
    lastName: 'Rahman',
  );

  /// Measured from the reference's own session list: this device first, the
  /// others by when they were last seen.
  static final List<LumeDeviceSession> _seedSessions = <LumeDeviceSession>[
    LumeDeviceSession(
      id: 'dev-this',
      label: 'Pixel 6 Pro · Lume',
      place: 'Islamabad, Pakistan',
      lastSeen: DateTime(2026, 9, 7, 16, 30),
      isCurrent: true,
    ),
    LumeDeviceSession(
      id: 'dev-mac',
      label: 'MacBook Air · Safari',
      place: 'Islamabad, Pakistan',
      lastSeen: DateTime(2026, 9, 6, 21, 14),
    ),
    LumeDeviceSession(
      id: 'dev-ipad',
      label: 'iPad · Lume',
      place: 'Lahore, Pakistan',
      lastSeen: DateTime(2026, 8, 29, 9, 2),
    ),
  ];

  @override
  LumeAccountState state;

  LumeAccountIdentity? _identity;
  String _password;
  List<LumeDeviceSession> _sessions;

  final Duration delay;

  /// Makes every write refuse, for the failure states.
  final LumeAccountFailure? failWith;

  /// How many writes were attempted. A duplicate submission shows up here.
  int writes = 0;

  @override
  bool get isDurable => false;

  @override
  LumeAccountIdentity? get identity => _identity;

  /// Keeps this store's "who is signed in" in step with the launch gate's.
  ///
  /// The gate owns the session — the auth screens sign in and out through
  /// it — and the account screens read this store. Without this the two
  /// disagreed: signing in left Profile showing a guest, and signing out
  /// left it showing the account. A signed-in account the store already
  /// holds keeps its identity (so an edited name survives); a new one is
  /// built from what the session knows, dated by the session's own issue
  /// time rather than a clock read. Signing out leaves a guest with no
  /// identity and no sessions; an expired session keeps the identity, as
  /// `LumeFakeAccountRepository.expired` does.
  ///
  /// **Dayroz obligation:** the real account service answers "who is this"
  /// from the same session the auth service issued, so there is one answer
  /// rather than two kept in step.
  void follow(LumeAuthStatus auth) {
    final LumeAccount? a = auth.signedInAccount;
    if (a != null) {
      if (state == LumeAccountState.authed && _identity?.email == a.email) {
        return;
      }
      final String name = a.displayName.trim();
      final List<String> words = name.isEmpty
          ? const <String>[]
          : name.split(RegExp(r'\s+'));
      _identity = LumeAccountIdentity(
        email: a.email,
        createdAt: auth.session?.issued ?? DateTime(2024),
        displayName: name,
        firstName: words.isEmpty ? '' : words.first,
        lastName: words.length > 1 ? words.sublist(1).join(' ') : '',
        pendingEmail: a.pendingEmail,
      );
      if (_sessions.isEmpty) {
        _sessions = List<LumeDeviceSession>.of(_seedSessions.take(1));
      }
      state = LumeAccountState.authed;
      return;
    }
    if (auth.isExpired) {
      state = LumeAccountState.expired;
      return;
    }
    state = LumeAccountState.guest;
    _identity = null;
    _sessions = <LumeDeviceSession>[];
  }

  /// `PROTECTED` in `account.js`, exactly.
  static const Set<LumeAccountRoute> _protected = <LumeAccountRoute>{
    LumeAccountRoute.account,
    LumeAccountRoute.email,
    LumeAccountRoute.phone,
    LumeAccountRoute.security,
    LumeAccountRoute.password,
    LumeAccountRoute.sessions,
    LumeAccountRoute.delete,
  };

  @override
  bool requiresAccount(LumeAccountRoute route) => _protected.contains(route);

  Future<void> _settle() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  LumeAccountResult? _guard() {
    if (failWith != null) return LumeAccountResult.refused(failWith!);
    if (state != LumeAccountState.authed || _identity == null) {
      return const LumeAccountResult.refused(LumeAccountFailure.signedOut);
    }
    return null;
  }

  // ---- identity ----------------------------------------------------------

  @override
  Future<LumeAccountResult> updateIdentity({
    String? displayName,
    String? firstName,
    String? lastName,
    String? phone,
    String? photo,
  }) async {
    writes++;
    await _settle();
    if (failWith != null) return LumeAccountResult.refused(failWith!);

    // A guest has a display name too, and may change it. Everything else on
    // the form belongs to an account.
    final bool guest = state != LumeAccountState.authed || _identity == null;
    // A blank name is **not** refused. `updateUser` in `account.js` trims it
    // and stores it, and the identity card is built for exactly that: with no
    // name the address is the identity. Refusing it here would have made the
    // nameless state unreachable through the form that creates it.
    if (phone != null && phone.isNotEmpty && !_phone.hasMatch(phone.trim())) {
      return const LumeAccountResult.refused(
        LumeAccountFailure.invalidPhone,
        field: 'phone',
      );
    }
    if (guest) return const LumeAccountResult.ok();

    _identity = _identity!.copyWith(
      displayName: displayName?.trim(),
      firstName: firstName?.trim(),
      lastName: lastName?.trim(),
      phone: phone?.trim(),
      photo: photo,
    );
    return LumeAccountResult.ok(identity: _identity);
  }

  @override
  Future<LumeAccountResult> requestEmailChange(String email) async {
    writes++;
    await _settle();
    final LumeAccountResult? refused = _guard();
    if (refused != null) return refused;

    final String next = email.trim().toLowerCase();
    if (!_email.hasMatch(next)) {
      return const LumeAccountResult.refused(
        LumeAccountFailure.invalidEmail,
        field: 'email',
      );
    }
    if (next == _identity!.email) {
      return const LumeAccountResult.refused(
        LumeAccountFailure.emailTaken,
        field: 'email',
      );
    }
    _identity = _identity!.copyWith(pendingEmail: next);
    return LumeAccountResult.ok(identity: _identity);
  }

  @override
  Future<LumeAccountResult> cancelEmailChange() async {
    writes++;
    await _settle();
    final LumeAccountResult? refused = _guard();
    if (refused != null) return refused;
    _identity = _identity!.copyWith(clearPending: true);
    return LumeAccountResult.ok(identity: _identity);
  }

  @override
  Future<LumeAccountResult> changePassword({
    required String current,
    required String password,
    required String confirm,
  }) async {
    writes++;
    await _settle();
    final LumeAccountResult? refused = _guard();
    if (refused != null) return refused;

    // The reference's order: the current one first, so a reader who mistypes
    // it is not also told their new one is weak.
    if (current != _password) {
      return const LumeAccountResult.refused(
        LumeAccountFailure.wrongPassword,
        field: 'current',
      );
    }
    if (!LumePasswordPolicy.isAcceptable(password)) {
      return const LumeAccountResult.refused(
        LumeAccountFailure.weakPassword,
        field: 'password',
      );
    }
    if (password != confirm) {
      return const LumeAccountResult.refused(
        LumeAccountFailure.mismatch,
        field: 'confirm',
      );
    }

    _password = password;
    // Every other session goes: a password change that left them alive would
    // not be a password change.
    _sessions = <LumeDeviceSession>[
      for (final LumeDeviceSession s in _sessions)
        if (s.isCurrent) s,
    ];
    return LumeAccountResult.ok(identity: _identity);
  }

  // ---- sessions ----------------------------------------------------------

  @override
  Future<List<LumeDeviceSession>> sessions() async {
    await _settle();
    if (state != LumeAccountState.authed) return const <LumeDeviceSession>[];
    final List<LumeDeviceSession> out = List<LumeDeviceSession>.of(_sessions)
      ..sort(
        (LumeDeviceSession a, LumeDeviceSession b) =>
            b.lastSeen.compareTo(a.lastSeen),
      );
    return List<LumeDeviceSession>.unmodifiable(out);
  }

  @override
  Future<LumeRevokeResult> revoke(String id) async {
    writes++;
    await _settle();
    final LumeDeviceSession? target = _sessions
        .where((LumeDeviceSession s) => s.id == id)
        .firstOrNull;
    if (target == null) return const LumeRevokeResult(revoked: 0);
    _sessions = <LumeDeviceSession>[
      for (final LumeDeviceSession s in _sessions)
        if (s.id != id) s,
    ];
    if (target.isCurrent) {
      state = LumeAccountState.guest;
      return const LumeRevokeResult(revoked: 1, signedOutSelf: true);
    }
    return const LumeRevokeResult(revoked: 1);
  }

  @override
  Future<LumeRevokeResult> signOutOthers() async {
    writes++;
    await _settle();
    final int before = _sessions.length;
    _sessions = <LumeDeviceSession>[
      for (final LumeDeviceSession s in _sessions)
        if (s.isCurrent) s,
    ];
    return LumeRevokeResult(revoked: before - _sessions.length);
  }

  // ---- storage -----------------------------------------------------------

  @override
  Future<LumeStoredData> stored() async {
    await _settle();
    // `storage()` in `account.js`: five kinds on the device, nothing synced,
    // because no backend exists in this build.
    return const LumeStoredData(
      onDevice: <String>['prefs', 'tools', 'notes', 'notify', 'account'],
      synced: <String>[],
    );
  }

  // ---- deletion ----------------------------------------------------------

  @override
  Future<LumeAccountResult> deleteAccount({required String password}) async {
    writes++;
    await _settle();
    final LumeAccountResult? refused = _guard();
    if (refused != null) return refused;

    if (password.isEmpty || password != _password) {
      return const LumeAccountResult.refused(
        LumeAccountFailure.wrongPassword,
        field: 'current',
      );
    }
    _identity = null;
    _sessions = const <LumeDeviceSession>[];
    state = LumeAccountState.guest;
    return const LumeAccountResult.ok();
  }
}

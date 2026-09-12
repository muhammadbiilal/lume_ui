/// What the account section is made of.
///
/// Read from `services/account.js` and `ui/account-ui.js`: the engine answers
/// what Lume knows, and the UI turns those answers into screens — *including
/// the answer "nothing", which has a designed shape rather than a plausible
/// stand-in.*
///
/// **Nothing here is a secret.** There is no password, no digest, no token and
/// no refresh token in any of these types. The engine checks a password and
/// returns a verdict; what crosses this boundary is the verdict.
library;

import 'package:flutter/foundation.dart';

/// Where the reader stands with Lume.
///
/// `account.js` calls it `state()`, and it is four values rather than a
/// boolean: a holder whose session has lapsed is not a guest, and telling them
/// apart is what stops a returning user's own name sitting over "you're using
/// Lume as a guest".
enum LumeAccountState {
  /// No account on this device.
  guest,

  /// Signed in, session good.
  authed,

  /// An account this device knows, whose session has run out.
  expired,
}

/// Whether an account can be used.
enum LumeAccountStatus { active, locked }

/// The person, as Lume knows them.
@immutable
class LumeAccountIdentity {
  const LumeAccountIdentity({
    required this.email,
    required this.createdAt,
    this.displayName = '',
    this.firstName = '',
    this.lastName = '',
    this.phone = '',
    this.photo = '',
    this.status = LumeAccountStatus.active,
    this.pendingEmail,
  });

  final String email;

  /// When the account was made. Shown with its year, because a membership
  /// date without one reads like today.
  final DateTime createdAt;

  final String displayName;
  final String firstName;
  final String lastName;

  /// Empty means "not set", which the row says out loud rather than leaving
  /// blank. A value the product holds and knows to be empty is not the same
  /// as one it does not have.
  final String phone;

  final String photo;
  final LumeAccountStatus status;

  /// An address waiting on verification. The identity never moves until the
  /// code is accepted.
  final String? pendingEmail;

  /// First and last together, or empty. Never assembled from the address.
  String get fullName =>
      <String>[firstName, lastName].where((String s) => s.isNotEmpty).join(' ');

  /// Up to two letters from a *real* name — never invented from an address.
  ///
  /// `account.js`'s own rule: a display name, then first and last, then
  /// nothing. An email is not a name, and two letters taken from one is a
  /// guess presented as a fact.
  String get initials {
    final List<String> words = <String>[
      if (displayName.isNotEmpty) ...displayName.split(RegExp(r'\s+')),
      if (displayName.isEmpty) ...<String>[firstName, lastName],
    ].where((String w) => w.trim().isNotEmpty).toList();
    if (words.isEmpty) return '';
    final String first = _glyph(words.first);
    final String last = words.length > 1 ? _glyph(words.last) : '';
    return (first + last).toUpperCase();
  }

  /// The first *glyph*, not the first code unit.
  ///
  /// `account.js`'s own `firstGlyph`: a name beginning with a surrogate pair —
  /// an emoji, or a character outside the basic plane — must not be cut in
  /// half, which is what `word[0]` would do.
  static String _glyph(String word) {
    final String w = word.trim();
    if (w.isEmpty) return '';
    final int first = w.runes.first;
    return String.fromCharCode(first);
  }

  LumeAccountIdentity copyWith({
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    String? phone,
    String? photo,
    LumeAccountStatus? status,
    String? pendingEmail,
    bool clearPending = false,
  }) => LumeAccountIdentity(
    email: email ?? this.email,
    createdAt: createdAt,
    displayName: displayName ?? this.displayName,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    phone: phone ?? this.phone,
    photo: photo ?? this.photo,
    status: status ?? this.status,
    pendingEmail: clearPending ? null : (pendingEmail ?? this.pendingEmail),
  );

  @override
  bool operator ==(Object other) =>
      other is LumeAccountIdentity &&
      other.email == email &&
      other.createdAt == createdAt &&
      other.displayName == displayName &&
      other.firstName == firstName &&
      other.lastName == lastName &&
      other.phone == phone &&
      other.photo == photo &&
      other.status == status &&
      other.pendingEmail == pendingEmail;

  @override
  int get hashCode => Object.hash(
    email,
    createdAt,
    displayName,
    firstName,
    lastName,
    phone,
    photo,
    status,
    pendingEmail,
  );
}

/// One device holding a session.
///
/// **No token, no identifier a stranger could use.** A label, roughly where it
/// was, when it was last seen, and whether it is this one. `id` is opaque and
/// exists so the row can be revoked.
@immutable
class LumeDeviceSession {
  const LumeDeviceSession({
    required this.id,
    required this.label,
    required this.place,
    required this.lastSeen,
    this.isCurrent = false,
  });

  final String id;

  /// "iPhone 15 · Safari". What the reader would recognise.
  final String label;

  /// "Islamabad, Pakistan". Coarse on purpose.
  final String place;

  final DateTime lastSeen;

  /// The device the reader is holding. It has no Sign out control of its own:
  /// revoking it is signing out, which is a different action in a different
  /// place.
  final bool isCurrent;
}

/// Where a kind of data actually lives.
///
/// `account.js`'s `storage()` answers `synced: []` and lists five kinds on the
/// device, because no backend exists in this build. *"Saying so is a designed
/// screen; implying otherwise would be the §125 failure in a different
/// costume."*
@immutable
class LumeStoredData {
  const LumeStoredData({required this.onDevice, required this.synced});

  /// Translation keys, not sentences.
  final List<String> onDevice;
  final List<String> synced;
}

/// Every screen the account host can show.
///
/// The list is `ui/account-ui.js`'s `ROUTES`, in its declaration order. It is
/// not a menu: `LumeAccountRepository.requiresAccount` decides which of them a
/// guest may open, and the host asks before it draws.
enum LumeAccountRoute {
  prefs,
  language,
  region,
  currency,
  units,
  time,
  appearance,
  notifications,
  library,
  account,
  edit,
  email,
  phone,
  security,
  password,
  sessions,
  privacy,
  sync,
  help,
  about,
  delete;

  /// The route's own path segment — `/profile/account/language`.
  String get segment => name;

  static LumeAccountRoute? parse(String? segment) {
    for (final LumeAccountRoute r in LumeAccountRoute.values) {
      if (r.segment == segment) return r;
    }
    return null;
  }
}

/// What Profile shows, separated from where it came from.
///
/// Profile reads six different stores — the account, the personalisation
/// record, the theme, the notification preferences, the favourites and the
/// build — and none of that belongs on a screen. This is the one shape it
/// takes them in, so the screen renders a value rather than deciding one, and
/// a test can put it in any state directly.
///
/// **Nothing here is a secret.** A name, an address the reader already sees,
/// counts, and the labels of settings. No token, no digest, no session id.
library;

import 'package:flutter/foundation.dart';

import 'account_model.dart';

/// The reader's own settings, as the rows say them.
///
/// Every field is a *rendered* value rather than a raw preference: the row
/// shows "Follow my region (PKR)", not `auto`, and deciding which is which is
/// the host's job because it needs the locale to do it.
@immutable
class LumeProfileValues {
  const LumeProfileValues({
    required this.language,
    required this.region,
    required this.appearance,
    required this.notifications,
    required this.interests,
    required this.favourites,
    required this.version,
    this.deviceName = '',
  });

  /// `L.languageName(L.lang())` — the language in its own name.
  final String language;

  /// `regionValue()` — country, city and currency, joined by ` · `.
  final String region;

  /// Which of the three appearance choices is in force.
  final String appearance;

  /// `acct.catsOn` — how many notification categories are on, of how many.
  final String notifications;

  /// How many interests the reader picked, and how many tools they saved.
  final int interests;
  final int favourites;

  /// The build's own version. Not the prototype's — see D40.
  final String version;

  /// The name a guest gave this device in onboarding. Empty is a value the
  /// product holds and knows to be empty, and the row says "Not set".
  final String deviceName;
}

/// Everything Profile draws, in one value.
@immutable
class LumeProfileView {
  const LumeProfileView({
    required this.state,
    required this.values,
    this.identity,
  });

  final LumeAccountState state;

  /// `null` for a guest. For an expired session this is still the account the
  /// device remembers, which is what lets the screen say whose it is — and
  /// what stops the returning holder's own name sitting over "you're using
  /// Lume as a guest".
  final LumeAccountIdentity? identity;

  final LumeProfileValues values;

  bool get isAuthed => state == LumeAccountState.authed;
  bool get isExpired => state == LumeAccountState.expired;
  bool get isGuest => state == LumeAccountState.guest;

  /// The account as a *signed-in* identity, which an expired session is not.
  ///
  /// `account.js` splits `user()` from `pendingUser()` for this reason: the
  /// expired screen may greet the holder by address, and nothing else may read
  /// them as signed in — not the avatar, not the member-since tag, not a row.
  LumeAccountIdentity? get user => isAuthed ? identity : null;

  /// The account behind an expired session. Never the signed-in one.
  LumeAccountIdentity? get pending => isExpired ? identity : null;
}

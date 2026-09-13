/// Notification preferences — **one preference store, two doors.**
///
/// The notification *centre* is not part of this phase, and none of this
/// pretends otherwise: there is no engine, no scheduler and no delivery. What
/// is here is the thing Profile and the account section actually need — the
/// categories a reader can switch, the two privacy switches that decide how
/// much of a notification is shown on a locked screen, and quiet hours.
///
/// It is one store because the same preferences are reached from two places:
/// the account's Notifications route and the notification centre's own
/// settings. A second copy would be a second answer to the same question, and
/// the two would disagree the moment one of them failed to save.
library;

import 'package:flutter/foundation.dart';

import '../../../core/icons/lume_icons.dart';

/// One switchable kind of notification.
///
/// `notify-engine.js`'s `CATEGORIES`, in its order. `faith` is the one that is
/// gated: a reader who has not switched the Islamic experience on never sees
/// the row, which is §64's rule that hiding the entry point is not enough.
@immutable
class LumeNotificationCategory {
  const LumeNotificationCategory({
    required this.id,
    required this.icon,
    this.faith = false,
    this.sensitive = false,
  });

  final String id;
  final String icon;

  /// Shown only where the Islamic experience is on.
  final bool faith;

  /// Health and the like. A preview of one is off by default, and stays off
  /// until the reader asks for it.
  final bool sensitive;
}

/// The eleven categories, in the engine's own order.
const List<LumeNotificationCategory> kNotificationCategories =
    <LumeNotificationCategory>[
      LumeNotificationCategory(
        id: 'faith',
        icon: LumeIcons.prayer,
        faith: true,
      ),
      LumeNotificationCategory(id: 'finance', icon: LumeIcons.wallet),
      LumeNotificationCategory(id: 'markets', icon: LumeIcons.trending),
      LumeNotificationCategory(id: 'travel', icon: LumeIcons.plane),
      LumeNotificationCategory(id: 'weather', icon: LumeIcons.cloudSun),
      LumeNotificationCategory(id: 'news', icon: LumeIcons.news),
      LumeNotificationCategory(id: 'personal', icon: LumeIcons.user),
      LumeNotificationCategory(id: 'reminders', icon: LumeIcons.bell),
      LumeNotificationCategory(id: 'documents', icon: LumeIcons.folder),
      LumeNotificationCategory(
        id: 'health',
        icon: LumeIcons.pulse,
        sensitive: true,
      ),
      LumeNotificationCategory(id: 'system', icon: LumeIcons.settings),
    ];

/// What the reader has asked for.
@immutable
class LumeNotificationPrefs {
  const LumeNotificationPrefs({
    this.push = false,
    this.inApp = true,
    this.sound = true,
    this.haptics = true,
    this.badge = true,
    this.quiet = false,
    this.quietFrom = 22,
    this.quietTo = 7,
    this.preview = true,
    this.sensitivePreview = false,
    this.off = const <String>{},
  });

  /// System push. `false` until the OS has actually granted it, and this build
  /// never asks — so a screen must not report it as on.
  final bool push;

  final bool inApp;
  final bool sound;
  final bool haptics;
  final bool badge;

  final bool quiet;

  /// Hours of the day, 0–23.
  final int quietFrom;
  final int quietTo;

  /// Whether a notification's text is shown before the device is unlocked.
  final bool preview;

  /// Whether a *sensitive* one's is. Off by default, and separately.
  final bool sensitivePreview;

  /// Categories the reader has switched **off**.
  ///
  /// Stored as the exceptions rather than as the whole set, so a category
  /// added later is on by default — which is what the engine does, and what
  /// stops a new kind of notification arriving silently switched off.
  final Set<String> off;

  bool isOn(String id) => !off.contains(id);

  /// The categories a given reader can see at all.
  ///
  /// The faith gate is asked here rather than at the row, so the count and the
  /// list cannot disagree — which is exactly what they do in the reference.
  /// See C34.
  static List<LumeNotificationCategory> visible({required bool islamic}) =>
      kNotificationCategories
          .where((LumeNotificationCategory c) => islamic || !c.faith)
          .toList(growable: false);

  int onCount({required bool islamic}) => visible(
    islamic: islamic,
  ).where((LumeNotificationCategory c) => isOn(c.id)).length;

  LumeNotificationPrefs copyWith({
    bool? push,
    bool? inApp,
    bool? sound,
    bool? haptics,
    bool? badge,
    bool? quiet,
    int? quietFrom,
    int? quietTo,
    bool? preview,
    bool? sensitivePreview,
    Set<String>? off,
  }) => LumeNotificationPrefs(
    push: push ?? this.push,
    inApp: inApp ?? this.inApp,
    sound: sound ?? this.sound,
    haptics: haptics ?? this.haptics,
    badge: badge ?? this.badge,
    quiet: quiet ?? this.quiet,
    quietFrom: quietFrom ?? this.quietFrom,
    quietTo: quietTo ?? this.quietTo,
    preview: preview ?? this.preview,
    sensitivePreview: sensitivePreview ?? this.sensitivePreview,
    off: off ?? this.off,
  );

  /// The same value with one category switched.
  LumeNotificationPrefs toggled(String id, {required bool on}) {
    final Set<String> next = Set<String>.of(off);
    if (on) {
      next.remove(id);
    } else {
      next.add(id);
    }
    return copyWith(off: next);
  }

  @override
  bool operator ==(Object other) =>
      other is LumeNotificationPrefs &&
      other.push == push &&
      other.inApp == inApp &&
      other.sound == sound &&
      other.haptics == haptics &&
      other.badge == badge &&
      other.quiet == quiet &&
      other.quietFrom == quietFrom &&
      other.quietTo == quietTo &&
      other.preview == preview &&
      other.sensitivePreview == sensitivePreview &&
      setEquals(other.off, off);

  @override
  int get hashCode => Object.hash(
    push,
    inApp,
    sound,
    haptics,
    badge,
    quiet,
    quietFrom,
    quietTo,
    preview,
    sensitivePreview,
    Object.hashAllUnordered(off),
  );
}

/// Where the preferences live.
///
/// An interface, so the fixture that holds them in memory and the durable one
/// Dayroz supplies are the same thing to every caller. [isDurable] is reported
/// rather than assumed: a screen must not say "saved" over a store that will
/// forget.
abstract interface class LumeNotificationPrefsStore {
  LumeNotificationPrefs get prefs;

  Future<void> write(LumeNotificationPrefs next);

  bool get isDurable;
}

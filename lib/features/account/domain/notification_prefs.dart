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

/// One thing that can send a notification.
///
/// `notify-engine.js`'s `SOURCES`, carried as a table rather than as an
/// engine: what the preferences screen needs from it is which *tool* feeds
/// which *category*, and that is a fact about the product rather than about a
/// running scheduler.
///
/// **It does not send anything.** There is no build function here, no
/// schedule and no delivery — the fifteen rows exist so the category list can
/// be filtered the way the reference filters it, and so the per-tool section
/// has something true to group by.
@immutable
class LumeNotificationSource {
  const LumeNotificationSource({
    required this.id,
    required this.tool,
    required this.category,
    required this.type,
    this.sensitive = false,
  });

  final String id;

  /// The feature id in the catalogue, so eligibility can be asked about it.
  final String tool;

  final String category;

  /// The kind of notification, which the per-tool section switches.
  final String type;

  /// A *source* property, not a category one: `src.sensitive` in the
  /// reference's engine. Bills, due bills, documents, subscriptions and
  /// medication withhold their detail while sensitive previews are off,
  /// though only one of them is in the Health category. Keying this off the
  /// category would have shown a bill's amount by default.
  final bool sensitive;
}

/// The fifteen, in the engine's own order.
const List<LumeNotificationSource> kNotificationSources =
    <LumeNotificationSource>[
      LumeNotificationSource(
        id: 'prayer.next',
        tool: 'prayer',
        category: 'faith',
        type: 'prayerReminder',
      ),
      LumeNotificationSource(
        id: 'bills.overdue',
        tool: 'bills',
        category: 'finance',
        type: 'billOverdue',
        sensitive: true,
      ),
      LumeNotificationSource(
        id: 'bills.due',
        tool: 'bills',
        category: 'finance',
        type: 'billDue',
        sensitive: true,
      ),
      LumeNotificationSource(
        id: 'markets.move',
        tool: 'markets',
        category: 'markets',
        type: 'marketMove',
      ),
      LumeNotificationSource(
        id: 'parcel.transit',
        tool: 'parcel',
        category: 'travel',
        type: 'parcelUpdate',
      ),
      LumeNotificationSource(
        id: 'flights.delay',
        tool: 'flights',
        category: 'travel',
        type: 'flightChange',
      ),
      LumeNotificationSource(
        id: 'trains.delay',
        tool: 'trains',
        category: 'travel',
        type: 'trainDelay',
      ),
      LumeNotificationSource(
        id: 'weather.alert',
        tool: 'weather',
        category: 'weather',
        type: 'severeWeather',
      ),
      LumeNotificationSource(
        id: 'weather.tomorrow',
        tool: 'weather',
        category: 'weather',
        type: 'forecast',
      ),
      LumeNotificationSource(
        id: 'loadshed.next',
        tool: 'loadshed',
        category: 'system',
        type: 'outage',
      ),
      LumeNotificationSource(
        id: 'documents.expiring',
        tool: 'documents',
        category: 'documents',
        type: 'docExpiry',
        sensitive: true,
      ),
      LumeNotificationSource(
        id: 'subs.renewal',
        tool: 'subs',
        category: 'finance',
        type: 'subRenewal',
        sensitive: true,
      ),
      LumeNotificationSource(
        id: 'todos.today',
        tool: 'todos',
        category: 'reminders',
        type: 'taskReminder',
      ),
      LumeNotificationSource(
        id: 'meds.dose',
        tool: 'meds',
        category: 'health',
        type: 'medication',
        sensitive: true,
      ),
      LumeNotificationSource(
        id: 'habits.streak',
        tool: 'habits',
        category: 'personal',
        type: 'habitReminder',
      ),
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
    this.typesOff = const <String>{},
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

  /// Source ids the reader has switched **off**, for the per-tool section.
  /// Exceptions again, so a source added later arrives switched on.
  final Set<String> typesOff;

  bool isOn(String id) => !off.contains(id);

  bool isTypeOn(String sourceId) => !typesOff.contains(sourceId);

  /// The categories a given reader can see at all.
  ///
  /// **Two filters, the reference's own.** A category is offered when the
  /// reader's faith preference allows it *and* some visible feature feeds it
  /// — `NOTIFY.SOURCES.some(src => src.cat === c.id && visible(src.tool))`.
  /// Asked once, here, so the count on Profile and the list on this screen
  /// cannot disagree; in the reference they do, and C34 records it.
  ///
  /// `isToolVisible` is the catalogue's own answer, so a country-gated tool
  /// takes its category with it. `null` means "do not ask the second
  /// question" — a caller with no catalogue to hand.
  static List<LumeNotificationCategory> visible({
    required bool islamic,
    bool Function(String toolId)? isToolVisible,
  }) => kNotificationCategories
      .where((LumeNotificationCategory c) {
        if (c.faith && !islamic) return false;
        if (isToolVisible == null) return true;
        return kNotificationSources.any(
          (LumeNotificationSource s) =>
              s.category == c.id && isToolVisible(s.tool),
        );
      })
      .toList(growable: false);

  /// The sources behind one category, for the per-tool section.
  static List<LumeNotificationSource> sourcesFor(
    String categoryId, {
    bool Function(String toolId)? isToolVisible,
  }) => kNotificationSources
      .where(
        (LumeNotificationSource s) =>
            s.category == categoryId &&
            (isToolVisible == null || isToolVisible(s.tool)),
      )
      .toList(growable: false);

  int onCount({
    required bool islamic,
    bool Function(String toolId)? isToolVisible,
  }) => visible(
    islamic: islamic,
    isToolVisible: isToolVisible,
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
    Set<String>? typesOff,
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
    typesOff: typesOff ?? this.typesOff,
  );

  /// The same value with one source switched.
  LumeNotificationPrefs typeToggled(String sourceId, {required bool on}) {
    final Set<String> next = Set<String>.of(typesOff);
    if (on) {
      next.remove(sourceId);
    } else {
      next.add(sourceId);
    }
    return copyWith(typesOff: next);
  }

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
      setEquals(other.off, off) &&
      setEquals(other.typesOff, typesOff);

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
    Object.hashAllUnordered(typesOff),
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

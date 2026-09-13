/// The notification centre's own model.
///
/// The engine decides what is true; the centre decides how it looks. That
/// split is why none of this computes anything: a notification arrives
/// already resolved, with its title, its body, its age and its priority, and
/// the screen's whole job is to draw it.
///
/// Three rules travel with the data rather than with the screen, because all
/// three are about what must never reach it:
///
/// * a notification for a feature this reader cannot see is not built at all,
///   whether it is hidden by faith or by country (§64);
/// * a sensitive tool's detail is withheld when previews are off — the row
///   says something happened, not what;
/// * priority outranks recency, so an important item does not fall off the
///   bottom because three ordinary ones arrived.
///
/// The category and source registries are **not** redefined here. They are
/// `kNotificationCategories` and `kNotificationSources` in
/// `account/domain/notification_prefs.dart`, which the preferences route
/// already reads — one registry, two surfaces.
library;

import 'package:flutter/foundation.dart';

/// How loudly an event asks to be noticed. `rank` is what the "Important"
/// filter compares, and what outranks recency when the list is ordered.
enum LumeNotificationPriority {
  low(0),
  normal(1),
  high(2),
  critical(3);

  const LumeNotificationPriority(this.rank);

  final int rank;
}

/// What a row's own button does, when it has one.
@immutable
class LumeNotificationAction {
  const LumeNotificationAction({required this.labelKey, required this.tool});

  /// Which localised verb the button reads — the `n.act.*` suffix.
  final String labelKey;

  /// The tool it opens.
  final String tool;
}

/// One resolved notification.
@immutable
class LumeNotification {
  const LumeNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.icon,
    required this.tool,
    required this.agoMinutes,
    this.priority = LumeNotificationPriority.normal,
    this.read = false,
    this.actioned = false,
    this.expired = false,
    this.grouped = false,
    this.groupId = '',
    this.action,
    this.members = 0,
  });

  final String id;
  final String title;

  /// Already resolved against the preview preferences: when previews are off
  /// this is the "something happened" line, and when a sensitive tool's
  /// preview is off it is that tool's own discreet wording. The screen never
  /// sees what was withheld.
  final String body;

  /// A `kNotificationCategories` id.
  final String category;

  final String icon;

  /// The catalogue feature this belongs to, so opening it goes somewhere and
  /// eligibility can be asked about it.
  final String tool;

  /// How long ago, in whole minutes, against the injected clock. The screen
  /// turns it into words; it is never a wall-clock read.
  final int agoMinutes;

  final LumeNotificationPriority priority;
  final bool read;

  /// Acted on already — it stays in history and stops asking.
  final bool actioned;

  /// Past the moment it was about. Still history, no longer something to do.
  final bool expired;

  /// A folded row standing for several updates of one event.
  final bool grouped;

  /// Which event this belongs to. Three or more of one event fold together.
  final String groupId;

  final LumeNotificationAction? action;

  /// How many rows a folded row stands for. Zero unless [grouped].
  final int members;
}

/// Which of the four shapes a filter is.
enum LumeNotificationSlice { all, unread, important, category }

/// Which slice of the list the centre is showing.
///
/// The three tabs, plus any category id. The reference keeps this as
/// presentation state on the screen rather than in the engine, and so does
/// this: it is a question about what is being looked at, not about what is
/// true.
@immutable
class LumeNotificationFilter {
  const LumeNotificationFilter.all()
    : category = null,
      kind = LumeNotificationSlice.all;
  const LumeNotificationFilter.unread()
    : category = null,
      kind = LumeNotificationSlice.unread;
  const LumeNotificationFilter.important()
    : category = null,
      kind = LumeNotificationSlice.important;
  const LumeNotificationFilter.category(String this.category)
    : kind = LumeNotificationSlice.category;

  final LumeNotificationSlice kind;
  final String? category;

  bool get isAll => kind == LumeNotificationSlice.all;
  bool get isUnread => kind == LumeNotificationSlice.unread;
  bool get isImportant => kind == LumeNotificationSlice.important;

  /// The three tabs share the "All" chip in the category bar, because none of
  /// them is a category.
  bool get isTab => kind != LumeNotificationSlice.category;

  /// Does [n] belong in this slice?
  ///
  /// Unread and Important both drop expired rows: an expired item is history,
  /// and neither filter is asking about history.
  bool admits(LumeNotification n) => switch (kind) {
    LumeNotificationSlice.all => true,
    LumeNotificationSlice.unread => !n.read && !n.expired,
    LumeNotificationSlice.important => n.priority.rank >= 2 && !n.expired,
    LumeNotificationSlice.category => n.category == category,
  };

  @override
  bool operator ==(Object other) =>
      other is LumeNotificationFilter &&
      other.kind == kind &&
      other.category == category;

  @override
  int get hashCode => Object.hash(kind, category);
}

/// Everything the centre draws in one read.
@immutable
class LumeNotificationFeed {
  const LumeNotificationFeed({
    required this.all,
    required this.quietHours,
    required this.pushEnabled,
  });

  /// Every notification this reader may see, ordered — expired last, then
  /// priority descending, then age ascending. Filtering and folding happen on
  /// the way to the screen.
  final List<LumeNotification> all;

  /// Whether the clock is inside the reader's quiet window right now.
  final bool quietHours;

  /// Whether push has been allowed on this device. The centre reports it; it
  /// never asks for it.
  final bool pushEnabled;

  int get unread =>
      all.where((LumeNotification n) => !n.read && !n.expired).length;

  int get important => all
      .where((LumeNotification n) => n.priority.rank >= 2 && !n.expired)
      .length;

  /// How many of each category there is something to show for. The category
  /// bar offers only these — a chip for an empty category is a dead end.
  Map<String, int> get liveCategories {
    final Map<String, int> out = <String, int>{};
    for (final LumeNotification n in all) {
      out[n.category] = (out[n.category] ?? 0) + 1;
    }
    return out;
  }
}

/// Why the centre could not be drawn.
///
/// **Unreachable from the shipped fixture**, which cannot fail. It exists
/// because the reference draws an error state — `NOTIFY.list` throwing leaves
/// the reader somewhere — and Dayroz will read this over a network.
enum LumeNotificationFailure { unreachable }

/// Thrown by a feed that cannot answer.
class LumeNotificationException implements Exception {
  const LumeNotificationException(this.failure);

  final LumeNotificationFailure failure;

  @override
  String toString() => 'LumeNotificationException(${failure.name})';
}

/// What the notification centre asks of whatever is behind it.
///
/// Reads and writes are separate on purpose: [feed] is what is true, and the
/// three writes are the only things the centre may change about it.
abstract interface class LumeNotificationRepository {
  /// Everything, resolved for this reader against this clock.
  Future<LumeNotificationFeed> feed({required DateTime now});

  /// One row, read.
  Future<void> markRead(String id);

  /// Every row, read.
  Future<void> markAllRead();

  /// One row, gone from the list.
  Future<void> dismiss(String id);
}

/// Whether what is behind the feed survives a restart. `false` for every
/// fixture in this conversion, and the surfaces say so.
abstract interface class LumeNotificationDurability {
  bool get isDurable;
}

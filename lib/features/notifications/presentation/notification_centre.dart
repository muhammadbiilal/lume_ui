/// The notification centre — a screen, on whichever branch opened it.
///
/// Distinct from the account's Notifications *route*, which is where the
/// preferences live. This is the history: what happened, in what order, and
/// what can still be done about it. They share one preference record and one
/// category registry and nothing else.
///
/// Composition, in the order `screens/notifications.screen.js` emits it:
///
/// 1. the toolbar — title, unread count or "all caught up", back, and up to
///    two actions (Mark all read only while something is unread, and
///    Settings);
/// 2. the three tabs — All / Unread / Important, each with its count;
/// 3. the category bar, carrying **only categories that have something in
///    them**, because a chip for an empty category is a dead end;
/// 4. the quiet-hours note, when the clock is inside the window;
/// 5. the list, or an empty state whose wording depends on which tab asked;
/// 6. a trailing row to the preferences, showing whether push is on.
library;

import 'package:flutter/material.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/domain/notification_prefs.dart';
import '../data/notification_fixtures.dart' show foldNotifications;
import '../domain/notification_model.dart';
import 'notification_row.dart';

/// What the centre can ask the host to do.
@immutable
class LumeNotificationActions {
  const LumeNotificationActions({
    required this.setFilter,
    required this.open,
    required this.act,
    required this.dismiss,
    required this.markAllRead,
    required this.openSettings,
    required this.retry,
  });

  final ValueChanged<LumeNotificationFilter> setFilter;

  /// Open the row — mark it read and go to its tool.
  final ValueChanged<LumeNotification> open;

  /// The row's own verb.
  final ValueChanged<LumeNotification> act;

  final ValueChanged<LumeNotification> dismiss;
  final VoidCallback markAllRead;
  final VoidCallback openSettings;
  final VoidCallback retry;
}

/// The body of the centre. The toolbar is the host's, because the host owns
/// leaving.
class LumeNotificationCentre extends StatelessWidget {
  const LumeNotificationCentre({
    super.key,
    required this.feed,
    required this.filter,
    required this.actions,
    this.failure,
  });

  final LumeNotificationFeed feed;
  final LumeNotificationFilter filter;
  final LumeNotificationActions actions;

  /// Set when the feed could not be read. **Unreachable from the shipped
  /// fixture**; the reference draws it when its engine throws.
  final LumeNotificationFailure? failure;

  static const Key tabsKey = ValueKey<String>('notif.tabs');
  static const Key listKey = ValueKey<String>('notif.list');
  static const Key emptyKey = ValueKey<String>('notif.empty');

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);

    if (failure != null) {
      return LumeToolState(
        icon: LumeIcons.alert,
        title: l.nErrorTitle,
        text: l.nErrorText,
        action: LumeButton.accent(
          label: l.actionTryAgain,
          icon: LumeIcons.refresh,
          onPressed: actions.retry,
        ),
      );
    }

    final List<LumeNotification> shown = foldNotifications(
      feed.all.where(filter.admits).toList(growable: false),
      l,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _tabs(context, l),
        ..._categories(context, l),
        if (feed.quietHours)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: LumeNoteCard(
              icon: LumeIcons.moon,
              title: l.nQuietTitle,
              text: l.nQuietText,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: shown.isEmpty ? _empty(l) : _list(context, l, shown),
        ),
        // Nothing here was delivered, and the screen says so rather than
        // letting a list of sample alerts imply that it was (§125).
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: LumeNoteCard(
            icon: LumeIcons.info,
            title: l.navNotifications,
            text: l.nFixtureNote,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: LumeRows(
            children: <Widget>[
              LumeCompactRow(
                icon: LumeIcons.settings,
                label: l.nSettings,
                value: feed.pushEnabled ? l.nPushOn : l.nPushOff,
                onTap: actions.openSettings,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabs(BuildContext context, AppLocalizations l) => LumeTabs(
    key: tabsKey,
    semanticLabel: l.navNotifications,
    value: filter.isUnread
        ? 'unread'
        : filter.isImportant
        ? 'important'
        : 'all',
    items: <LumeChoice>[
      LumeChoice(value: 'all', label: l.commonAll, count: feed.all.length),
      LumeChoice(value: 'unread', label: l.nTabUnread, count: feed.unread),
      LumeChoice(
        value: 'important',
        label: l.nTabImportant,
        count: feed.important,
      ),
    ],
    onChanged: (String v) => actions.setFilter(switch (v) {
      'unread' => const LumeNotificationFilter.unread(),
      'important' => const LumeNotificationFilter.important(),
      _ => const LumeNotificationFilter.all(),
    }),
  );

  /// Only the categories that have something in them.
  List<Widget> _categories(BuildContext context, AppLocalizations l) {
    final Map<String, int> live = feed.liveCategories;
    if (live.isEmpty) return const <Widget>[];

    final List<LumeNotificationCategory> present = kNotificationCategories
        .where((LumeNotificationCategory c) => live.containsKey(c.id))
        .toList(growable: false);
    if (present.isEmpty) return const <Widget>[];

    return <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 14),
        child: LumeFilterBar(
          gutters: false,
          children: <Widget>[
            LumeFilterChip(
              label: l.commonAll,
              selected: filter.isTab,
              onTap: () =>
                  actions.setFilter(const LumeNotificationFilter.all()),
            ),
            for (final LumeNotificationCategory c in present)
              LumeFilterChip(
                label: lumeNotificationCategoryLabel(l, c.id),
                icon: c.icon,
                count: live[c.id],
                selected: filter.category == c.id,
                onTap: () =>
                    actions.setFilter(LumeNotificationFilter.category(c.id)),
              ),
          ],
        ),
      ),
    ];
  }

  Widget _empty(AppLocalizations l) => LumeToolState(
    key: emptyKey,
    icon: filter.isUnread ? LumeIcons.checkCircle : LumeIcons.bell,
    title: filter.isUnread ? l.nEmptyCaughtUp : l.nEmptyTitle,
    text: l.nEmptyText,
  );

  Widget _list(
    BuildContext context,
    AppLocalizations l,
    List<LumeNotification> shown,
  ) => LumeCard(
    key: listKey,
    padded: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < shown.length; i++)
          LumeNotificationRow(
            notification: shown[i],
            categoryLabel: lumeNotificationCategoryLabel(l, shown[i].category),
            actionLabel: shown[i].action == null
                ? null
                : lumeNotificationActionLabel(l, shown[i].action!.labelKey),
            onOpen: () => actions.open(shown[i]),
            onAct: shown[i].action == null ? null : () => actions.act(shown[i]),
            onDismiss: () => actions.dismiss(shown[i]),
            isLast: i == shown.length - 1,
          ),
      ],
    ),
  );
}

/// A category's own name. The same eleven the preferences route names, from
/// the same registry.
String lumeNotificationCategoryLabel(AppLocalizations l, String id) =>
    switch (id) {
      'faith' => l.ncatFaith,
      'finance' => l.ncatFinance,
      'markets' => l.ncatMarkets,
      'travel' => l.ncatTravel,
      'weather' => l.ncatWeather,
      'news' => l.ncatNews,
      'personal' => l.ncatPersonal,
      'reminders' => l.ncatReminders,
      'documents' => l.ncatDocuments,
      'health' => l.ncatHealth,
      _ => l.ncatSystem,
    };

/// The verb on a row's own button.
String lumeNotificationActionLabel(AppLocalizations l, String key) =>
    switch (key) {
      'viewPrayer' => l.nActViewPrayer,
      'pay' => l.nActPay,
      'viewMarket' => l.nActViewMarket,
      'track' => l.nActTrack,
      'viewFlight' => l.nActViewFlight,
      'viewTrain' => l.nActViewTrain,
      'viewWeather' => l.nActViewWeather,
      'viewDoc' => l.nActViewDoc,
      _ => l.nActComplete,
    };

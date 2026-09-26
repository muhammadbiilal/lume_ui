/// The notification centre, wired to the launch.
///
/// The host owns three things the centre does not: the toolbar and leaving,
/// the filter (which is presentation state, so it lives with the screen that
/// presents it rather than in the feed), and the writes.
///
/// It also owns the **skeleton**, and owns it carefully. The reference paints
/// one on the first visit only: the shell renders every screen at boot, and a
/// skeleton spent while the screen was hidden is one the reader never sees —
/// leaving them a blank centre the first time they actually arrive.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/notification_feed.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/widgets/lume/lume_destination.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/notification_model.dart';
import 'notification_centre.dart';
import 'notification_open.dart';
import 'notification_sheets.dart';

/// The centre on a branch.
class LumeNotificationHost extends ConsumerStatefulWidget {
  const LumeNotificationHost({super.key, required this.branch});

  /// Which branch it sits on, so Back returns there and a tool opened from a
  /// row opens on the same branch.
  final String branch;

  /// How long the first visit shows the shape of what is coming.
  static const Duration settle = Duration(milliseconds: 90);

  static const Key headerKey = ValueKey<String>('notif.header');
  static const Key skeletonKey = ValueKey<String>('notif.skeleton');

  @override
  ConsumerState<LumeNotificationHost> createState() =>
      _LumeNotificationHostState();
}

class _LumeNotificationHostState extends ConsumerState<LumeNotificationHost> {
  LumeNotificationFilter _filter = const LumeNotificationFilter.all();
  LumeNotificationFeed? _feed;
  LumeNotificationFailure? _failure;

  /// Whether the skeleton is still up.
  bool _settling = true;
  Timer? _settleTimer;

  /// Which read the screen is showing. A late answer to a superseded question
  /// is dropped.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _settleTimer = Timer(LumeNotificationHost.settle, () {
      if (mounted) setState(() => _settling = false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_read()));
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    super.dispose();
  }

  Future<void> _read() async {
    final int request = ++_request;
    try {
      final LumeNotificationFeed feed = await ref
          .read(notificationFeedProvider)
          .feed(now: LumeClockScope.of(context).now());
      if (!mounted || request != _request) return;
      setState(() {
        _feed = feed;
        _failure = null;
      });
    } on LumeNotificationException catch (e) {
      if (!mounted || request != _request) return;
      setState(() => _failure = e.failure);
    } on Object {
      if (!mounted || request != _request) return;
      setState(() => _failure = LumeNotificationFailure.unreachable);
    }
  }

  // A row goes to its tool on *this* branch, so Back comes back here.
  Future<void> _open(LumeNotification n) async {
    final bool left = await openLumeNotification(
      ref: ref,
      context: context,
      branch: widget.branch,
      n: n,
    );
    if (!left && mounted) await _read();
  }

  /// `action.act` after marking the item actioned, as the reference's
  /// `actItem` does: the row stays in history and stops asking.
  Future<void> _act(LumeNotification n) async {
    await ref.read(notificationFeedProvider).markActioned(n.id);
    if (!mounted) return;
    await _open(n);
  }

  Future<void> _dismiss(LumeNotification n) async {
    await ref.read(notificationFeedProvider).dismiss(n.id);
    if (mounted) await _read();
  }

  Future<void> _markAllRead() async {
    await ref.read(notificationFeedProvider).markAllRead();
    if (mounted) await _read();
  }

  void _leave() => context.go(widget.branch);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeNotificationFeed? feed = _feed;
    final bool waiting = _settling || (feed == null && _failure == null);

    return LumeDestinationPage(
      storageId: '${widget.branch}/notifications',
      semanticLabel: l.navNotifications,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: KeyedSubtree(
            key: LumeNotificationHost.headerKey,
            child: LumeToolbar(
              title: l.navNotifications,
              subtitle: waiting
                  ? null
                  : (feed?.unread ?? 0) > 0
                  ? l.nUnreadCount(feed!.unread)
                  : l.nAllRead,
              backLabel: l.actionBack,
              onBack: _leave,
              actions: <Widget>[
                if (!waiting && (feed?.unread ?? 0) > 0)
                  LumeHeaderButton(
                    icon: LumeIcons.check,
                    semanticLabel: l.nMarkAllRead,
                    onTap: () => unawaited(_markAllRead()),
                  ),
                LumeHeaderButton(
                  icon: LumeIcons.settings,
                  semanticLabel: l.nSettings,
                  onTap: _openSettings,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          // Every block below is a `.sect` and carries its own inset and its
          // own 24 above. The tabs run edge to edge, so the page cannot pad
          // them in.
          padding: const EdgeInsets.only(bottom: 24),
          sliver: SliverToBoxAdapter(
            child: waiting
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: LumeSkeleton(
                      key: LumeNotificationHost.skeletonKey,
                      kind: LumeSkeletonKind.row,
                      count: 4,
                    ),
                  )
                : LumeNotificationCentre(
                    feed:
                        feed ??
                        const LumeNotificationFeed(
                          all: <LumeNotification>[],
                          quietHours: false,
                          pushEnabled: false,
                        ),
                    filter: _filter,
                    failure: _failure,
                    actions: LumeNotificationActions(
                      setFilter: (LumeNotificationFilter f) =>
                          setState(() => _filter = f),
                      open: (LumeNotification n) => unawaited(_open(n)),
                      act: (LumeNotification n) => unawaited(_act(n)),
                      dismiss: (LumeNotification n) => unawaited(_dismiss(n)),
                      markAllRead: () => unawaited(_markAllRead()),
                      openSettings: _openSettings,
                      retry: () => unawaited(_read()),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// The preferences, as a sheet over the centre.
  ///
  /// `#sheet-notifprefs`, which is what the reference raises from here — not
  /// a walk out to the account section, which would lose the reader's place
  /// and their filter. The same store either way, so a switch flipped here is
  /// flipped there.
  void _openSettings() {
    unawaited(
      showLumeNotificationPrefsSheet(context).then((_) {
        if (mounted) unawaited(_read());
      }),
    );
  }
}

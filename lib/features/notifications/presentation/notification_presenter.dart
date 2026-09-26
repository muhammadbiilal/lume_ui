/// When a banner is up, and which one.
///
/// `notifyTick` in the reference: two and a half seconds after launch, and
/// every forty-five seconds after that, the shell asks the engine for the next
/// thing nobody has been told about and lets the engine say which surface it
/// goes to. This is that tick, and the policy stays where the reference keeps
/// it — in the repository (`nextToPresent`, `markPresented`) and in
/// [lumeMayInterrupt] — so this widget only schedules and draws.
///
/// What it reproduces:
///
/// * **one surface per event.** Whatever the tick takes is marked presented,
///   banner or not, so it is never offered twice;
/// * **nothing while in-app and push are both off** — the tick returns before
///   anything is marked;
/// * **no banner on the centre**, where the reader is already looking at the
///   list. The event is still marked: the centre was its surface;
/// * **no banner while the app is away.** The reference would push instead;
///   there is no push in this build, so the event waits, unpresented, for the
///   reader to come back.
///
/// And one thing the reference leaves to chance: no banner over a sheet or a
/// dialog, where it could be tapped instead of the question.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/notification_feed.dart';
import '../../../app/providers/personalisation.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/routing/lume_routes.dart';
import '../../account/domain/notification_prefs.dart';
import 'notification_open.dart';
import '../domain/notification_model.dart';
import 'notification_banner.dart';

/// Ticks, and holds the banner above [child].
class LumeNotificationPresenter extends ConsumerStatefulWidget {
  const LumeNotificationPresenter({
    super.key,
    required this.location,
    required this.child,
  });

  /// Where the router is: the banner stays off the centre, and a tapped
  /// banner opens its tool on the branch the reader is on.
  final String location;

  final Widget child;

  /// `setTimeout(notifyTick, 2500)` — the default [LumeNotificationSchedule].
  static final Duration firstTick = const LumeNotificationSchedule().firstTick;

  /// `setInterval(notifyTick, 45000)` — the default [LumeNotificationSchedule].
  static final Duration interval = const LumeNotificationSchedule().interval;

  @override
  ConsumerState<LumeNotificationPresenter> createState() =>
      _LumeNotificationPresenterState();
}

class _LumeNotificationPresenterState
    extends ConsumerState<LumeNotificationPresenter> {
  Timer? _first;
  Timer? _every;
  LumeNotification? _banner;

  /// A tick that is still reading is not overlapped by the next one.
  bool _ticking = false;

  @override
  void initState() {
    super.initState();
    final LumeNotificationSchedule schedule = ref.read(
      notificationScheduleProvider,
    );
    if (!schedule.enabled) return;
    _first = Timer(schedule.firstTick, () => unawaited(_tick()));
    _every = Timer.periodic(schedule.interval, (_) => unawaited(_tick()));
  }

  @override
  void dispose() {
    _first?.cancel();
    _every?.cancel();
    super.dispose();
  }

  /// The branch the location is on — its first segment.
  String get _branch {
    final List<String> parts = widget.location.split('/');
    return parts.length > 1 && parts[1].isNotEmpty
        ? '/${parts[1]}'
        : LumeRoutes.home;
  }

  /// `router.current() === 'notifications'`.
  bool get _onCentre =>
      widget.location.endsWith('/${LumeRoutes.notificationsSegment}');

  Future<void> _tick() async {
    if (_ticking || !mounted) return;
    final AppLifecycleState? life = WidgetsBinding.instance.lifecycleState;
    if (life != null && life != AppLifecycleState.resumed) return;

    _ticking = true;
    try {
      final LumeNotificationRepository feed = ref.read(
        notificationFeedProvider,
      );
      final LumeNotificationPrefs prefs = ref
          .read(notificationPrefsProvider)
          .prefs;
      final DateTime now = LumeClockScope.of(context).now();

      final LumeNotificationFeed state = await feed.feed(now: now);
      if (!prefs.inApp && !state.pushEnabled) return;

      final LumeNotification? next = await feed.nextToPresent(now: now);
      if (next == null) return;
      await feed.markPresented(next.id);
      if (!mounted) return;

      final bool interrupt = lumeMayInterrupt(
        next,
        inApp: prefs.inApp,
        quietHours: state.quietHours,
      );
      if (interrupt && !_onCentre) setState(() => _banner = next);
    } on LumeNotificationException {
      // A feed that cannot be read presents nothing. The centre is where
      // that is said, not a banner.
    } finally {
      _ticking = false;
    }
  }

  Future<void> _open(LumeNotification n) =>
      openLumeNotification(ref: ref, context: context, branch: _branch, n: n);

  @override
  Widget build(BuildContext context) {
    // A route above the shell — a sheet, a dialog — is a question the reader
    // is being asked, and a banner over it could be tapped instead.
    final bool covered = !(ModalRoute.of(context)?.isCurrent ?? true);

    return LumeNotificationBannerHost(
      notification: _banner,
      suppressed: _onCentre || covered,
      onOpen: (LumeNotification n) => unawaited(_open(n)),
      onDismissed: () {
        if (mounted) setState(() => _banner = null);
      },
      child: widget.child,
    );
  }
}

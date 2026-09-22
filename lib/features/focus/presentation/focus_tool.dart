/// Focus Timer — the clock-instrument archetype, with two compositions.
///
/// `tools/everyday/focus.tool.js` draws three things: the clock face, a row of
/// three figures — "75 Minutes today", "5 Day streak", "3 Sessions" — and a
/// seven-bar week chart. Every one of those numbers is a constant in
/// `context.js` (`todayMins: 75, streak: 5, sessions: 3, week: [50, 75, 25,
/// 100, 50, 75, 75]`). They are somebody else's afternoon. So this tool has
/// **two compositions, and which one is drawn depends on the build**:
///
/// | build | below the clock face |
/// |---|---|
/// | [LumeBuildProfile.parity] | **the sample path** — the reference's three figures and its week chart, exactly where the reference put them, so the capture can be compared point for point. The source bar leads with "Sample data" in the reader's own language, because `focus` is [LumeDataCapability.isSample]; a parity build never ships. |
/// | development, release | **the honest path** — the focus and break lengths, and what has actually happened *since Lume was opened*: minutes counted and stretches finished, or "Nothing yet". No minutes-today, no day streak, no week chart, because none of those exist. |
///
/// The split is one `reproducesReference` read in [build] and nothing else;
/// `focus_sample_test.dart` asserts that no `75`, no streak, no session count
/// and no seven-bar chart can be found anywhere in the development or release
/// tree.
///
/// What the honest path says of itself is `focusKeptSession` — "Counted since
/// you opened Lume. Nothing here survives closing it." — which is the literal
/// truth: [LumeToolSession] is in memory and is not written anywhere.
///
/// **Notifications.** The catalogue declares `notifications` for this feature.
/// Nothing implements them, exactly as nothing implements Timer's. A stretch
/// that runs out while Lume is in the background is noticed when Lume is
/// looked at again ([LumeFocusController.back]) and is never announced before
/// then, and no copy anywhere on this screen says otherwise.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/lume_build_profile.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/time/lume_boot_clock.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chart.dart';
import '../../../core/widgets/lume/lume_clock_face.dart';
import '../../../core/widgets/lume/lume_destination.dart';
import '../../../core/widgets/lume/lume_destination_cards.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../timer/application/timer_controller.dart' show LumePeriodicTimer;
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/focus_clock.dart';
import '../application/focus_controller.dart';

class LumeFocusTool extends ConsumerStatefulWidget {
  const LumeFocusTool({
    super.key,
    required this.request,
    this.periodic,
    this.elapsed,
  });

  final LumeToolRequest request;

  /// The repaint interval and the elapsed-time source, for a test that steps
  /// time itself. A screen test that cannot reach the constructor overrides
  /// [focusClockProvider] instead.
  final LumePeriodicTimer? periodic;
  final LumeElapsed? elapsed;

  static Widget open(LumeToolRequest request) =>
      LumeFocusTool(request: request);

  static const String id = 'focus';

  static const Key timeKey = ValueKey<String>('focus.time');
  static const Key startKey = ValueKey<String>('focus.start');
  static const Key resetKey = ValueKey<String>('focus.reset');
  static const Key skipKey = ValueKey<String>('focus.skip');
  static const Key phaseKey = ValueKey<String>('focus.phase');
  static const Key focusLengthKey = ValueKey<String>('focus.length');
  static const Key breakLengthKey = ValueKey<String>('focus.breakLength');
  static const Key thisSessionKey = ValueKey<String>('focus.thisSession');
  static const Key countedKey = ValueKey<String>('focus.counted');
  static const Key emptyKey = ValueKey<String>('focus.empty');
  static const Key sampleMetricsKey = ValueKey<String>('focus.sampleMetrics');
  static const Key sampleWeekKey = ValueKey<String>('focus.sampleWeek');
  static const Key sampleFiguresKey = ValueKey<String>('focus.sampleFigures');
  static const Key sampleWeekSectionKey = ValueKey<String>('focus.sampleSect');

  /// `context.js` `focus()` — the constants the reference prints, kept here
  /// as the sample data they are and drawn only where [LumeBuildProfile
  /// .reproducesReference] is true.
  static const int sampleMinutesToday = 75;
  static const int sampleStreak = 5;
  static const int sampleSessions = 3;
  static const List<double> sampleWeek = <double>[50, 75, 25, 100, 50, 75, 75];

  @override
  ConsumerState<LumeFocusTool> createState() => _LumeFocusToolState();
}

class _LumeFocusToolState extends ConsumerState<LumeFocusTool>
    with WidgetsBindingObserver {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeFocusController _clock = LumeFocusController(
    session: ref.read(toolSessionProvider),
    periodic: widget.periodic,
    elapsed: widget.elapsed ?? ref.read(focusClockProvider),
    onFinished: _finished,
  )..addListener(_changed);

  void _changed() => setState(() {});

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _clock.back();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _clock.away();
      case AppLifecycleState.inactive:
        break;
    }
  }

  /// `toast(t('focus.done'))` and `navigator.vibrate([30, 60, 30])`, as
  /// `timer_tool.dart` does both.
  void _finished(LumeFocusPhase done) {
    final AppLocalizations l = AppLocalizations.of(context);
    _host.currentState?.say(
      done == LumeFocusPhase.focus ? l.focusDone : l.focusBreakOver,
    );
    HapticFeedback.vibrate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    // The one place the build decides anything. See the library comment.
    final bool sample = ref.watch(buildProfileProvider).reproducesReference;

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _face(l, f),
          if (sample) ...<Widget>[
            _sampleFigures(l, f),
            _sampleWeek(l, f),
          ] else ...<Widget>[_controls(l), _lengths(l, f), _counted(l, f)],
        ],
      ),
    );
  }

  // ---- the face, in every build ------------------------------------------

  Widget _face(AppLocalizations l, LumeFormatting f) {
    final LumeFocusStatus status = _clock.status;
    final String primary = switch (status) {
      LumeFocusStatus.running => l.focusPause,
      LumeFocusStatus.paused => l.focusResume,
      LumeFocusStatus.ready =>
        _clock.phase == LumeFocusPhase.focus ? l.focusStart : l.commonStart,
    };

    return LumeClockFace(
      timeKey: LumeFocusTool.timeKey,
      display: _clock.display,
      hint: l.focusSession(
        f.integer(_clock.session),
        f.integer(LumeFocusController.sessionsPerCycle),
      ),
      // Flexible, because "Start focus" is a longer word than Timer's
      // "Start": at twice the text size the pair is 9.5 points wider than the
      // gutters allow, and the face's row neither wraps nor scrolls. Loose,
      // so at ordinary sizes each button is exactly as wide as the reference
      // drew it.
      primary: Flexible(
        child: LumeButton.accent(
          key: LumeFocusTool.startKey,
          label: primary,
          icon: status == LumeFocusStatus.running ? null : LumeIcons.play,
          onPressed: _clock.toggle,
        ),
      ),
      reset: Flexible(
        child: LumeButton(
          key: LumeFocusTool.resetKey,
          label: l.focusReset,
          icon: LumeIcons.refresh,
          onPressed: _clock.reset,
        ),
      ),
    );
  }

  // ---- the honest path ---------------------------------------------------

  String _phaseName(AppLocalizations l) =>
      _clock.phase == LumeFocusPhase.focus ? l.focusFocus : l.focusBreak;

  /// Which phase is on the clock, what it is doing, and the way out of it.
  Widget _controls(AppLocalizations l) => LumeToolSection(
    key: LumeFocusTool.phaseKey,
    tight: true,
    title: _phaseName(l),
    subtitle: switch (_clock.status) {
      LumeFocusStatus.running => l.focusRunning,
      LumeFocusStatus.paused => l.focusPaused,
      LumeFocusStatus.ready => l.focusReady,
    },
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        LumeButton(
          key: LumeFocusTool.skipKey,
          label: l.focusSkip,
          icon: LumeIcons.arrowR,
          small: true,
          semanticLabel: '${l.focusSkip}, ${_phaseName(l)}',
          onPressed: _clock.skip,
        ),
      ],
    ),
  );

  Widget _lengths(AppLocalizations l, LumeFormatting f) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _lengthStrip(
        key: LumeFocusTool.focusLengthKey,
        title: l.focusLength,
        f: f,
        l: l,
        choices: LumeFocusController.focusChoices,
        chosen: _clock.focusLength,
        onPick: _clock.setFocusLength,
      ),
      _lengthStrip(
        key: LumeFocusTool.breakLengthKey,
        title: l.focusBreakLength,
        f: f,
        l: l,
        choices: LumeFocusController.breakChoices,
        chosen: _clock.breakLength,
        onPick: _clock.setBreakLength,
      ),
    ],
  );

  Widget _lengthStrip({
    required Key key,
    required String title,
    required AppLocalizations l,
    required LumeFormatting f,
    required List<Duration> choices,
    required Duration chosen,
    required ValueChanged<Duration> onPick,
  }) => LumeToolSection(
    title: title,
    child: LumeHorizontalStrip.chips(
      key: key,
      semanticLabel: title,
      children: <Widget>[
        for (final Duration d in choices)
          LumeChoiceChip(
            label: l.unitMinutesCount(f.integer(d.inMinutes)),
            selected: d == chosen,
            onTap: () => onPick(d),
          ),
      ],
    ),
  );

  /// What has really happened, which is only ever this run of the app.
  Widget _counted(AppLocalizations l, LumeFormatting f) => LumeToolSection(
    key: LumeFocusTool.thisSessionKey,
    title: l.focusThisSession,
    subtitle: l.focusKeptSession,
    child: _clock.hasCounted
        ? LumeMetrics(
            key: LumeFocusTool.countedKey,
            children: <Widget>[
              LumeMetric(
                icon: LumeIcons.timer,
                value: l.unitMinutesCount(f.integer(_clock.focused.inMinutes)),
                label: l.focusFocus,
              ),
              LumeMetric(
                icon: LumeIcons.check,
                value: f.integer(_clock.completedSessions),
                label: l.focusSessionsLabel,
              ),
            ],
          )
        : LumeToolState(
            key: LumeFocusTool.emptyKey,
            icon: LumeIcons.timer,
            title: l.focusNothingYet,
          ),
  );

  // ---- the sample path, parity only --------------------------------------

  Widget _sampleFigures(AppLocalizations l, LumeFormatting f) =>
      LumeToolSection(
        key: LumeFocusTool.sampleFiguresKey,
        child: LumeMetrics(
          key: LumeFocusTool.sampleMetricsKey,
          columns: 3,
          children: <Widget>[
            LumeMetric(
              icon: LumeIcons.timer,
              value: f.integer(LumeFocusTool.sampleMinutesToday),
              label: l.focusToday,
            ),
            LumeMetric(
              icon: LumeIcons.flame,
              value: f.integer(LumeFocusTool.sampleStreak),
              label: l.focusStreakLabel,
            ),
            LumeMetric(
              icon: LumeIcons.check,
              value: f.integer(LumeFocusTool.sampleSessions),
              label: l.focusSessionsLabel,
            ),
          ],
        ),
      );

  Widget _sampleWeek(AppLocalizations l, LumeFormatting f) {
    final List<String> days = f.weekdayNarrowFromMonday();
    return LumeToolSection(
      key: LumeFocusTool.sampleWeekSectionKey,
      title: l.focusThisWeek,
      child: LumeCard(
        child: LumeBarChart(
          key: LumeFocusTool.sampleWeekKey,
          label: l.focusThisWeek,
          values: LumeFocusTool.sampleWeek,
          labels: days,
          highlight: LumeFocusTool.sampleWeek.length - 1,
          valueLabels: <String>[
            for (int i = 0; i < LumeFocusTool.sampleWeek.length; i++)
              l.focusChartEntry(
                days[i],
                l.unitMinutesCount(f.integer(LumeFocusTool.sampleWeek[i])),
              ),
          ],
        ),
      ),
    );
  }
}

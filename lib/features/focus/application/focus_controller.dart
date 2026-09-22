/// Focus Timer — a focus stretch, then a break, counted from a clock.
///
/// `tools/everyday/focus.tool.js` draws `shared/clock.js` `clockScreen` over
/// `runClock('focus')`, which is the timer's engine with 1500 seconds in place
/// of 300 and a different toast. Three things are wrong with it, and this
/// fixes all three:
///
/// * **it adds a second per interval tick.** `st.secs += -1` every 1000 ms is
///   a count of *fires*, not of time: a busy frame, a throttled background
///   tab or a slow paint each lose a second for good. Here the remaining time
///   is `length − (clock() − startedAt)`, computed fresh every read, so the
///   ticker only decides how often the face repaints and can fire early,
///   late, or not at all without moving the answer by a millisecond;
/// * **`s.session` is never written.** The reference prints "Session 1 of 4"
///   from a literal `session: s.session || 1`, and nothing anywhere increments
///   it — a focus stretch can run to zero a hundred times and it still says 1.
///   Here a finished stretch advances it, and a finished break advances the
///   session within the cycle of [sessionsPerCycle];
/// * **there is no break at all.** `focus` is one countdown. A focus tool
///   without a break is a timer with a different default, so this alternates:
///   [LumeFocusPhase.focus] for [focusLength], then
///   [LumeFocusPhase.breakTime] for [breakLength].
///
/// **Policy**, the stopwatch's (`stopwatch_controller.dart`, C83) applied
/// here:
///
/// * time comes only from [LumeElapsed] — by default the boot-time clock,
///   which keeps counting while the phone sleeps — never the wall clock, so
///   changing the phone's time or zone moves nothing;
/// * in the background a running phase keeps its start and keeps elapsing;
///   only the repaint ticker stops ([away]) and starts again ([back]). A
///   phase that ran out while Lume was away is settled on [back], because
///   **nothing is delivered in the background**: the catalogue declares
///   `notifications` for this feature and, exactly as Timer does, nothing
///   implements them. Declared, inert, and said so here rather than implied
///   anywhere on screen;
/// * leaving the tool pauses the phase and keeps what has elapsed;
/// * **nothing survives the app being closed.** [LumeToolSession] is in
///   memory. A new process starts at a full focus stretch, session 1, with no
///   counted minutes and no finished sessions — which is also why
///   [completedSessions] and [focused] are described on screen as "this
///   session" and never as a day, a streak or a history;
/// * a clock that seems to run backwards counts as no time, a length is held
///   between [minLength] and [maxLength], and what has been counted is held
///   below [maxCounted], so no figure is ever negative and none overflows.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/time/lume_boot_clock.dart';
import '../../timer/application/timer_controller.dart' show LumePeriodicTimer;
import '../../tools/application/tool_session.dart';

/// Which half of the cycle is on the clock.
enum LumeFocusPhase {
  /// The focus stretch.
  focus,

  /// The break after it. `break` is a Dart keyword.
  breakTime,
}

/// What the clock is doing, for the words beside it.
enum LumeFocusStatus { ready, running, paused }

class LumeFocusController extends ChangeNotifier {
  LumeFocusController({
    required LumeToolSession session,
    this.onFinished,
    LumePeriodicTimer? periodic,
    LumeElapsed? elapsed,
  }) : _session = session,
       _periodic = periodic ?? Timer.periodic,
       _elapsed = elapsed ?? LumeBootClock.platform();

  static const String tool = 'focus';

  /// `runClock`: `kind === 'focus' ? 1500 : 300` — twenty-five minutes.
  static const Duration defaultFocus = Duration(minutes: 25);

  /// The reference has no break, so this is a choice rather than a
  /// reproduction: five minutes, the shorter of the two rests the technique
  /// the reference is imitating alternates, and the one the reader is most
  /// likely to want after twenty-five. Changeable from [breakChoices].
  static const Duration defaultBreak = Duration(minutes: 5);

  /// A stretch is at least a minute and at most four hours. The ceiling is
  /// what the face can draw without wrapping minutes into hours (`240:00`)
  /// and far longer than anyone sits down for.
  static const Duration minLength = Duration(minutes: 1);
  static const Duration maxLength = Duration(hours: 4);

  /// The most this tool will claim to have counted in one run of the app.
  static const Duration maxCounted = Duration(days: 999);

  /// `of: 4` — the reference's cycle length, made real.
  static const int sessionsPerCycle = 4;

  /// How often the face repaints while running. Nothing is *measured* from
  /// the ticker; see the library comment.
  static const Duration frame = Duration(milliseconds: 250);

  static const List<Duration> focusChoices = <Duration>[
    Duration(minutes: 15),
    defaultFocus,
    Duration(minutes: 45),
    Duration(minutes: 60),
  ];

  static const List<Duration> breakChoices = <Duration>[
    defaultBreak,
    Duration(minutes: 10),
    Duration(minutes: 15),
  ];

  final LumeToolSession _session;
  final LumePeriodicTimer _periodic;
  final LumeElapsed _elapsed;

  /// Told which phase ran out, once, when it does.
  final void Function(LumeFocusPhase finished)? onFinished;

  Timer? _ticker;
  Duration? _startedAt;

  // ---- what is held -------------------------------------------------------

  int _read(String key, int fallback) =>
      int.tryParse(_session.read(tool, key) ?? '') ?? fallback;

  static int _clampLength(int ms) =>
      ms.clamp(minLength.inMilliseconds, maxLength.inMilliseconds);

  Duration get focusLength => Duration(
    milliseconds: _clampLength(_read('focusMs', defaultFocus.inMilliseconds)),
  );

  Duration get breakLength => Duration(
    milliseconds: _clampLength(_read('breakMs', defaultBreak.inMilliseconds)),
  );

  LumeFocusPhase get phase => _session.read(tool, 'phase') == 'break'
      ? LumeFocusPhase.breakTime
      : LumeFocusPhase.focus;

  /// The length of the phase on the clock.
  Duration get length =>
      phase == LumeFocusPhase.focus ? focusLength : breakLength;

  /// Where in the cycle this is — 1 through [sessionsPerCycle].
  int get session => _read('session', 1).clamp(1, sessionsPerCycle);

  /// Focus stretches finished since Lume was opened. Not a day, not a
  /// streak: this process, and nothing before it.
  int get completedSessions => _read('done', 0).clamp(0, 1 << 30);

  /// Time actually spent in the focus phase since Lume was opened.
  Duration get focused => Duration(
    milliseconds: _read('countedMs', 0).clamp(0, maxCounted.inMilliseconds),
  );

  /// Whether anything at all has happened this run.
  bool get hasCounted => completedSessions > 0 || focused > Duration.zero;

  // ---- what the clock says ------------------------------------------------

  /// Started and not paused — whether or not the face is repainting.
  bool get running => _startedAt != null;

  int get _heldMs => _read('heldMs', 0).clamp(0, length.inMilliseconds);

  /// How much of this phase has passed, the run in progress included.
  Duration get elapsed {
    final Duration? since = _startedAt;
    final int run = since == null ? 0 : (_elapsed() - since).inMilliseconds;
    return Duration(
      milliseconds: (_heldMs + (run < 0 ? 0 : run)).clamp(
        0,
        length.inMilliseconds,
      ),
    );
  }

  /// How much of this phase is left.
  Duration get remaining => length - elapsed;

  LumeFocusStatus get status => running
      ? LumeFocusStatus.running
      : (elapsed > Duration.zero
            ? LumeFocusStatus.paused
            : LumeFocusStatus.ready);

  /// `fmtClock('focus', secs)` — minutes and seconds, minutes unbounded.
  String get display => format(remaining);

  /// A part-second still standing is a second on the face, so a fresh
  /// twenty-five minutes reads `25:00` and only reaches `00:00` when it is
  /// actually over.
  static String format(Duration left) {
    final int ms = left.isNegative ? 0 : left.inMilliseconds;
    final int secs = (ms + 999) ~/ 1000;
    String two(int v) => v < 10 ? '0$v' : '$v';
    return '${two(secs ~/ 60)}:${two(secs % 60)}';
  }

  // ---- commands -----------------------------------------------------------

  /// Start, or pause when running — the reference's one control (C66).
  void toggle() {
    if (running) {
      _pause();
      notifyListeners();
      return;
    }
    if (remaining <= Duration.zero) _hold(0);
    _startedAt = _elapsed();
    _repaint();
    notifyListeners();
  }

  /// Back to the start of this phase. What has already been counted stays
  /// counted: the minutes were spent whether or not the stretch is begun
  /// again.
  void reset() {
    _abandon();
    notifyListeners();
  }

  /// Straight to the next phase, without pretending the stretch finished: a
  /// skipped focus banks only the minutes that really passed, and does not
  /// advance [completedSessions].
  void skip() {
    final LumeFocusPhase leaving = phase;
    final Duration done = elapsed;
    _stop();
    if (leaving == LumeFocusPhase.focus) {
      _count(done);
      _enter(LumeFocusPhase.breakTime, session);
    } else {
      _enter(LumeFocusPhase.focus, session % sessionsPerCycle + 1);
    }
    notifyListeners();
  }

  void setFocusLength(Duration d) {
    if (phase == LumeFocusPhase.focus) _abandon();
    _session.write(tool, 'focusMs', '${_clampLength(d.inMilliseconds)}');
    notifyListeners();
  }

  void setBreakLength(Duration d) {
    if (phase == LumeFocusPhase.breakTime) {
      _stop();
      _hold(0);
    }
    _session.write(tool, 'breakMs', '${_clampLength(d.inMilliseconds)}');
    notifyListeners();
  }

  /// Lume is out of sight: stop repainting, keep elapsing.
  void away() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Lume is seen again. A phase that ran out while it was away is settled
  /// now — it was not announced then, and this does not pretend it was.
  void back() {
    if (running && remaining <= Duration.zero) {
      _finish();
      return;
    }
    if (running) _repaint();
    notifyListeners();
  }

  // ---- the works ----------------------------------------------------------

  void _repaint() => _ticker ??= _periodic(frame, (_) => _settle());

  void _settle() {
    if (running && remaining <= Duration.zero) {
      _finish();
      return;
    }
    notifyListeners();
  }

  /// This phase ran out: count it, move on, and say so once.
  void _finish() {
    final LumeFocusPhase done = phase;
    _stop();
    if (done == LumeFocusPhase.focus) {
      _count(length);
      _session.write(tool, 'done', '${completedSessions + 1}');
      _enter(LumeFocusPhase.breakTime, session);
    } else {
      _enter(LumeFocusPhase.focus, session % sessionsPerCycle + 1);
    }
    notifyListeners();
    onFinished?.call(done);
  }

  /// Give up the stretch in progress, keeping the minutes it really took.
  void _abandon() {
    if (phase == LumeFocusPhase.focus) _count(elapsed);
    _stop();
    _hold(0);
  }

  void _enter(LumeFocusPhase next, int nth) {
    _session
      ..write(tool, 'phase', next == LumeFocusPhase.focus ? 'focus' : 'break')
      ..write(tool, 'session', '$nth')
      ..write(tool, 'heldMs', '0');
  }

  void _count(Duration d) {
    if (d <= Duration.zero) return;
    final int total = (focused + d).inMilliseconds;
    _session.write(
      tool,
      'countedMs',
      '${total.clamp(0, maxCounted.inMilliseconds)}',
    );
  }

  void _hold(int ms) => _session.write(tool, 'heldMs', '$ms');

  void _pause() {
    _hold(elapsed.inMilliseconds);
    _stop();
  }

  void _stop() {
    _startedAt = null;
    _ticker?.cancel();
    _ticker = null;
  }

  /// Leaving the tool pauses the clock and keeps the time.
  @override
  void dispose() {
    if (running) _pause();
    super.dispose();
  }
}

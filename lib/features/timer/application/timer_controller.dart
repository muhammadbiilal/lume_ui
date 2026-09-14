/// The countdown, as `tool.screen.js` `runClock` runs it.
///
/// One state object, one interval, three commands:
///
/// * **set** a preset — stop, and hold that many seconds;
/// * **start** — with nothing held, hold the last preset or five minutes; count
///   down once a second; **start again while running pauses** (the same
///   control, the same label — C66);
/// * **reset** — stop, and hold the last preset or five minutes again.
///
/// Reaching zero stops the clock, holds zero, and reports [onFinished] once.
/// Leaving the tool stops it (`stopClocks`) without forgetting what it held,
/// which is why the held seconds live in the tool session rather than in the
/// widget.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../tools/application/tool_session.dart';

/// Starts the one-second interval. A parameter so a test can hold time still
/// or step it — no test waits on a wall clock.
typedef LumePeriodicTimer =
    Timer Function(Duration period, void Function(Timer timer) tick);

class LumeTimerController extends ChangeNotifier {
  LumeTimerController({
    required LumeToolSession session,
    this.onFinished,
    LumePeriodicTimer? periodic,
  }) : _session = session,
       _periodic = periodic ?? Timer.periodic;

  static const String tool = 'timer';

  /// `st.total || 300` — five minutes when no preset was chosen.
  static const int defaultSeconds = 300;

  final LumeToolSession _session;
  final LumePeriodicTimer _periodic;
  final VoidCallback? onFinished;
  Timer? _ticker;

  /// The seconds held, or `null` before anything was set or started — the
  /// face then reads the reference's opening `00:00`.
  int? get seconds => int.tryParse(_session.read(tool, 'secs') ?? '');

  /// The last preset, if one was chosen.
  int? get total => int.tryParse(_session.read(tool, 'total') ?? '');

  bool get running => _ticker != null;

  /// `fmtClock('timer', secs)` — minutes and seconds, minutes unbounded.
  String get display => format(seconds ?? 0);

  static String format(int secs) {
    String two(int v) => v < 10 ? '0$v' : '$v';
    final int s = secs < 0 ? 0 : secs;
    return '${two(s ~/ 60)}:${two(s % 60)}';
  }

  void _hold(int secs) => _session.write(tool, 'secs', '$secs');

  void set(int secs) {
    _stop();
    _session.write(tool, 'total', '$secs');
    _hold(secs);
    notifyListeners();
  }

  void reset() {
    _stop();
    _hold(total ?? defaultSeconds);
    notifyListeners();
  }

  /// Start, or pause if already running.
  void toggle() {
    if (running) {
      _stop();
      notifyListeners();
      return;
    }
    if ((seconds ?? 0) <= 0) _hold(total ?? defaultSeconds);
    _ticker = _periodic(const Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  void _tick() {
    final int next = (seconds ?? 0) - 1;
    if (next <= 0) {
      _stop();
      _hold(0);
      notifyListeners();
      onFinished?.call();
      return;
    }
    _hold(next);
    notifyListeners();
  }

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Leaving the tool stops the clock and keeps the seconds.
  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}

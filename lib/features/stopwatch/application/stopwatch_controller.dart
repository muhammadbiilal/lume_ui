/// The stopwatch, counting what the reference only pretends to.
///
/// `runClock('stopwatch')` adds a whole second each second and prints `.00`
/// after it, and its laps list is never written. This counts elapsed time
/// from a monotonic source, so hundredths move, and records laps (C83):
///
/// * **toggle** — start, or pause when running;
/// * **lap** — while running, mark the time;
/// * **reset** — while paused, back to zero with no laps.
///
/// What it has counted lives in the tool session, so leaving the tool and
/// coming back finds the same time — stopped, as `stopClocks` stops it.
///
/// **Policy** (F6B closure, C83):
///
/// * time comes only from [LumeElapsed] — by default the boot-time clock
///   (`lume_boot_clock.dart`: `CLOCK_BOOTTIME` on Android,
///   `mach_continuous_time` on iOS), meant to keep counting in deep sleep —
///   never the wall clock, so changing the phone's time or zone moves nothing;
/// * in the background a running stopwatch keeps its start and counts on;
///   only the repaint ticker stops ([away]) and starts again ([back]);
/// * leaving the tool pauses it and keeps the time;
/// * nothing survives the app being closed: the session is in memory, so a
///   new one starts at zero, stopped, with no laps. A reboot restarts the
///   boot-time clock too, which is why no start time is ever kept past the
///   process: a durable stopwatch would need the boot's identity stored with
///   it, and this one does not pretend to be durable;
/// * a clock that seems to run backwards counts as no time, and a run longer
///   than [maxRun] stops there, so the figure is never negative and never
///   overflows.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/time/lume_boot_clock.dart';
import '../../timer/application/timer_controller.dart';
import '../../tools/application/tool_session.dart';

class LumeStopwatchController extends ChangeNotifier {
  LumeStopwatchController({
    required LumeToolSession session,
    LumePeriodicTimer? periodic,
    LumeElapsed? elapsed,
  }) : _session = session,
       _periodic = periodic ?? Timer.periodic,
       _elapsed = elapsed ?? LumeBootClock.platform();

  static const String tool = 'stopwatch';

  /// How often the face repaints while running.
  static const Duration frame = Duration(milliseconds: 30);

  /// Longer than anyone times anything; the most a stopwatch will show.
  static const Duration maxRun = Duration(days: 999);

  final LumeToolSession _session;
  final LumePeriodicTimer _periodic;
  final LumeElapsed _elapsed;
  Timer? _ticker;
  Duration? _startedAt;

  /// Started and not paused — whether or not the face is being repainted.
  bool get running => _startedAt != null;

  int get _held => (int.tryParse(_session.read(tool, 'ms') ?? '') ?? 0).clamp(
    0,
    maxRun.inMilliseconds,
  );

  /// Milliseconds counted, including the run in progress.
  int get milliseconds {
    final Duration? since = _startedAt;
    final int run = since == null
        ? 0
        : (_elapsed() - since).inMilliseconds.clamp(0, maxRun.inMilliseconds);
    return (_held + run).clamp(0, maxRun.inMilliseconds);
  }

  /// Each lap's mark — the total at the moment Lap was pressed.
  List<int> get marks => <int>[
    for (final String s in (_session.read(tool, 'laps') ?? '').split(','))
      if (int.tryParse(s) != null) int.parse(s),
  ];

  /// Each lap's own length.
  List<int> get laps {
    final List<int> m = marks;
    return <int>[
      for (int i = 0; i < m.length; i++) m[i] - (i == 0 ? 0 : m[i - 1]),
    ];
  }

  String get display => format(milliseconds);

  /// `mm:ss.cc` — minutes unbounded, hundredths cut, not rounded.
  static String format(int ms) {
    String two(int v) => v < 10 ? '0$v' : '$v';
    final int t = ms < 0 ? 0 : ms;
    return '${two(t ~/ 60000)}:${two(t ~/ 1000 % 60)}.${two(t ~/ 10 % 100)}';
  }

  void toggle() {
    if (running) {
      _pause();
    } else {
      _startedAt = _elapsed();
      _tick();
    }
    notifyListeners();
  }

  void _tick() => _ticker ??= _periodic(frame, (_) => notifyListeners());

  /// Lume is out of sight: stop repainting, keep counting.
  void away() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Lume is seen again: repaint, from the same start.
  void back() {
    if (running) _tick();
    notifyListeners();
  }

  void lap() {
    if (!running) return;
    _session.write(tool, 'laps', <int>[...marks, milliseconds].join(','));
    notifyListeners();
  }

  void reset() {
    if (running) return;
    _session
      ..write(tool, 'ms', '0')
      ..write(tool, 'laps', '');
    notifyListeners();
  }

  void _pause() {
    _session.write(tool, 'ms', '$milliseconds');
    _startedAt = null;
    _ticker?.cancel();
    _ticker = null;
  }

  /// Leaving the tool stops the clock and keeps the time.
  @override
  void dispose() {
    if (running) _pause();
    super.dispose();
  }
}

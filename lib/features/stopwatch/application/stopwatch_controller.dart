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
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../timer/application/timer_controller.dart';
import '../../tools/application/tool_session.dart';

/// Monotonic elapsed time. A parameter so a test steps it.
typedef LumeElapsed = Duration Function();

class LumeStopwatchController extends ChangeNotifier {
  LumeStopwatchController({
    required LumeToolSession session,
    LumePeriodicTimer? periodic,
    LumeElapsed? elapsed,
  }) : _session = session,
       _periodic = periodic ?? Timer.periodic,
       _elapsed = elapsed ?? _monotonic;

  static const String tool = 'stopwatch';

  /// How often the face repaints while running.
  static const Duration frame = Duration(milliseconds: 30);

  static final Stopwatch _clock = Stopwatch()..start();
  static Duration _monotonic() => _clock.elapsed;

  final LumeToolSession _session;
  final LumePeriodicTimer _periodic;
  final LumeElapsed _elapsed;
  Timer? _ticker;
  Duration? _startedAt;

  bool get running => _ticker != null;

  int get _held => int.tryParse(_session.read(tool, 'ms') ?? '') ?? 0;

  /// Milliseconds counted, including the run in progress.
  int get milliseconds {
    final Duration? since = _startedAt;
    return _held + (since == null ? 0 : (_elapsed() - since).inMilliseconds);
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
      _ticker = _periodic(frame, (_) => notifyListeners());
    }
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

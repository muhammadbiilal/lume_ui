/// Speed Test's figures — `context.js` `speedTest()` and `tool.screen.js`
/// `runSpeedTest()`, typed.
///
/// The reference measures nothing: it opens on 48.2 Mbps, derives upload as
/// `down × 0.42`, fixes ping at 18 ms, and "Start test" eases towards a random
/// `30 + random × 70` Mbps over 1.8 seconds. This is that instrument, as
/// sample data — the source line says so. The run's random source is
/// injected (`speedtestRandomProvider`) so a test reads the same figure
/// every time.
///
/// **Dayroz obligation:** a real test needs a measurement server (download
/// and upload of a known payload, round-trip time for ping) and the
/// platform's connection type and carrier, none of which this build has.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

@immutable
class LumeSpeedHistory {
  const LumeSpeedHistory({
    required this.today,
    required this.wifi,
    required this.down,
    required this.ping,
    required this.series,
  });

  /// "Today", or "Yesterday".
  final bool today;

  /// Wi-Fi, or mobile data.
  final bool wifi;
  final double down;
  final int ping;
  final List<double> series;
}

abstract final class LumeSpeedtestFixtures {
  /// `s.down || 48.2`.
  static const double defaultDown = 48.2;

  /// `up: down * 0.42`.
  static double upFor(double down) => down * 0.42;

  /// `ping: 18`.
  static const int ping = 18;

  /// The gauge's full scale — `pct: Math.min(1, down / 200)`.
  static const double fullScale = 200;
  static double fraction(double down) => math.min(1, down / fullScale);

  /// How long the needle takes — 1800 ms, eased out (cubic).
  static const Duration run = Duration(milliseconds: 1800);

  /// `30 + Math.random() * 70`, kept to one decimal as `st.down` is.
  static double nextReading(math.Random random) =>
      ((30 + random.nextDouble() * 70) * 10).round() / 10;

  static const List<LumeSpeedHistory> history = <LumeSpeedHistory>[
    LumeSpeedHistory(
      today: true,
      wifi: true,
      down: 48.2,
      ping: 18,
      series: <double>[40, 44, 47, 48, 48.2],
    ),
    LumeSpeedHistory(
      today: false,
      wifi: false,
      down: 22.4,
      ping: 42,
      series: <double>[18, 20, 21, 22, 22.4],
    ),
  ];
}

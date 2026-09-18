/// The stopwatch's approved corrections, held to their policy (C83, F6B
/// closure): hundredths that move, laps that are recorded, Pause, and a clock
/// that is monotonic, injectable and never the wall clock.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/time/lume_boot_clock.dart';
import 'package:lume/features/stopwatch/application/stopwatch_controller.dart';
import 'package:lume/features/stopwatch/presentation/stopwatch_tool.dart';
import 'package:lume/features/tools/application/tool_session.dart';

import '../wave1/wave1_tools_test.dart' show pumpTool;

class _Ticker implements Timer {
  _Ticker(this.onTick);
  final void Function(Timer) onTick;
  bool active = true;
  int ticks = 0;

  void fire() {
    if (!active) return;
    ticks++;
    onTick(this);
  }

  @override
  void cancel() => active = false;
  @override
  bool get isActive => active;
  @override
  int get tick => ticks;
}

void main() {
  late Duration now;
  late List<_Ticker> tickers;
  late LumeToolSession session;

  LumeStopwatchController watch() => LumeStopwatchController(
    session: session,
    elapsed: () => now,
    periodic: (Duration d, void Function(Timer) tick) {
      final _Ticker t = _Ticker(tick);
      tickers.add(t);
      return t;
    },
  );

  setUp(() {
    now = const Duration(hours: 5);
    tickers = <_Ticker>[];
    session = LumeToolSession();
  });

  test('start, pause and resume add up only the running time', () {
    final LumeStopwatchController w = watch()..toggle();
    expect(w.running, isTrue);
    now += const Duration(milliseconds: 1234);
    w.toggle();
    expect(w.running, isFalse);
    now += const Duration(minutes: 3);
    expect(w.display, '00:01.23');
    w.toggle();
    now += const Duration(milliseconds: 1000);
    expect(w.milliseconds, 2234);
    expect(w.display, '00:02.23');
    w.dispose();
  });

  test('hundredths roll over into seconds, and seconds into minutes', () {
    String at(int ms) => LumeStopwatchController.format(ms);
    expect(at(9), '00:00.00', reason: 'cut, not rounded');
    expect(at(10), '00:00.01');
    expect(at(999), '00:00.99');
    expect(at(1000), '00:01.00');
    expect(at(1239), '00:01.23');
    expect(at(59999), '00:59.99');
    expect(at(60000), '01:00.00');
    expect(at(3599999), '59:59.99');
    expect(at(3600000), '60:00.00', reason: 'minutes run past an hour');
  });

  test('laps are kept in the order they were taken, each its own length', () {
    final LumeStopwatchController w = watch()..toggle();
    for (final int ms in <int>[1500, 700, 2300]) {
      now += Duration(milliseconds: ms);
      w.lap();
    }
    expect(w.marks, <int>[1500, 2200, 4500]);
    expect(w.laps, <int>[1500, 700, 2300]);
    w.toggle();
    w.lap();
    expect(w.laps, hasLength(3), reason: 'no lap while paused');
    w.dispose();
  });

  test('in the background it counts on, and only the repainting stops', () {
    final LumeStopwatchController w = watch()..toggle();
    now += const Duration(seconds: 2);
    w.away();
    expect(w.running, isTrue);
    expect(tickers.single.active, isFalse, reason: 'no repaint while away');
    now += const Duration(seconds: 30);
    w.back();
    expect(tickers, hasLength(2));
    expect(tickers.last.active, isTrue);
    expect(w.milliseconds, 32000);
    w.dispose();
  });

  test('a paused stopwatch stays paused across the background', () {
    final LumeStopwatchController w = watch()..toggle();
    now += const Duration(seconds: 4);
    w
      ..toggle()
      ..away();
    now += const Duration(minutes: 1);
    w.back();
    expect(w.running, isFalse);
    expect(tickers.where((_Ticker t) => t.active), isEmpty);
    expect(w.milliseconds, 4000);
    w.dispose();
  });

  test('restoration: leaving the tool keeps the time, stopped; a new app '
      'session starts at zero', () {
    final LumeStopwatchController w = watch()..toggle();
    now += const Duration(milliseconds: 2500);
    w.lap();
    w.dispose();
    now += const Duration(minutes: 5);
    final LumeStopwatchController again = watch();
    expect(again.running, isFalse);
    expect(again.display, '00:02.50');
    expect(again.laps, <int>[2500]);
    again.dispose();

    session = LumeToolSession();
    final LumeStopwatchController fresh = watch();
    expect(fresh.display, '00:00.00');
    expect(fresh.laps, isEmpty);
    expect(fresh.running, isFalse);
    fresh.dispose();
  });

  test(
    'deep sleep: the boot-time clock counts it, and so the stopwatch does',
    () {
      // The fake is the boot-time clock: it advances while the phone sleeps.
      // Dart's own monotonic clock would not have — the case this closes.
      final LumeStopwatchController w = watch()..toggle();
      now += const Duration(seconds: 5);
      w.away();
      now += const Duration(hours: 2); // screen off, the CPU suspended
      w.back();
      expect(
        w.milliseconds,
        const Duration(hours: 2, seconds: 5).inMilliseconds,
      );
      expect(w.display, '120:05.00');
      w.dispose();
    },
  );

  test('a clock that seems to go back counts as no time; a run past the '
      'most is held there', () {
    final LumeStopwatchController w = watch()..toggle();
    now -= const Duration(seconds: 30);
    expect(w.milliseconds, 0, reason: 'never negative');
    now += const Duration(days: 5000);
    expect(
      w.milliseconds,
      LumeStopwatchController.maxRun.inMilliseconds,
      reason: 'never past the most, never overflowing',
    );
    w.toggle();
    session.write('stopwatch', 'ms', '-500');
    expect(w.milliseconds, 0, reason: 'a held value is clamped too');
    w.dispose();
  });

  test('the clock each platform reads', () {
    expect(
      LumeBootClock.sourceFor(TargetPlatform.android),
      LumeBootClockSource.androidBootTime,
    );
    expect(
      LumeBootClock.sourceFor(TargetPlatform.iOS),
      LumeBootClockSource.darwinContinuous,
    );
    for (final TargetPlatform p in <TargetPlatform>[
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
      TargetPlatform.fuchsia,
    ]) {
      expect(LumeBootClock.sourceFor(p), LumeBootClockSource.dartMonotonic);
    }
    expect(
      LumeBootClock.sourceFor(TargetPlatform.android, web: true),
      LumeBootClockSource.dartMonotonic,
    );
    // The id Android passes, from <linux/time.h>.
    expect(LumeBootClock.linuxBootTime, 7);
  });

  test('iOS reads Apple continuous time — the source contract', () {
    expect(LumeBootClock.darwinTicks, 'mach_continuous_time');
    expect(LumeBootClock.darwinTimebase, 'mach_timebase_info');
    final String source = File(
      'lib/core/time/lume_boot_clock.dart',
    ).readAsStringSync();
    // Code only: the doc comment may name what is not used.
    final String code = source
        .split('\n')
        .where((String l) => !l.trimLeft().startsWith('//'))
        .join('\n');
    expect(code, contains("'clock_gettime'"), reason: 'Android unchanged');
    expect(code, contains('lookupFunction<Uint64 Function(), int Function()>'));
    expect(code, contains('(darwinTicks)'));
    expect(code, contains('(darwinTimebase)'));
    expect(code, contains('Int32 Function(Pointer<_MachTimebase>)'));
    for (final String excluded in <String>[
      'clock_gettime_nsec_np',
      'mach_absolute_time',
      'CLOCK_MONOTONIC',
      'CLOCK_UPTIME',
      'DateTime',
    ]) {
      expect(code, isNot(contains(excluded)), reason: excluded);
    }
    // mach_continuous_time is in libSystem from iOS 10; the target is newer,
    // so there is no fallback for the iOS clock.
    final String project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final Iterable<double> targets = RegExp(
      r'IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);',
    ).allMatches(project).map((Match m) => double.parse(m[1]!));
    expect(targets, isNotEmpty);
    expect(targets.every((double t) => t >= 10), isTrue);
  });

  group('iOS ticks to time', () {
    // arm64 Apple devices tick at 24 MHz: 125/3 ns a tick. Intel Macs, 1/1.
    final LumeTimebase arm = LumeTimebase(125, 3);
    final LumeTimebase unit = LumeTimebase(1, 1);

    test('the timebase converts exactly', () {
      expect(
        LumeBootClock.ticksToDuration(24000000, arm),
        const Duration(seconds: 1),
      );
      expect(
        LumeBootClock.ticksToDuration(24000000 * 3600, arm),
        const Duration(hours: 1),
      );
      expect(
        LumeBootClock.ticksToDuration(1500000000, unit),
        const Duration(milliseconds: 1500),
      );
      expect(LumeBootClock.ticksToDuration(0, arm), Duration.zero);
    });

    test('a product past 64 bits does not overflow; a tick count past 2⁶³ '
        'reads as the ceiling', () {
      const int huge = 0x7FFFFFFFFFFFFFFF;
      expect(LumeBootClock.ticksToDuration(huge, arm), LumeBootClock.ceiling);
      expect(
        LumeBootClock.ticksToDuration(huge, LumeTimebase(0xFFFFFFFF, 1)),
        LumeBootClock.ceiling,
      );
      expect(LumeBootClock.ticksToDuration(-1, arm), LumeBootClock.ceiling);
      // Ninety-nine days of arm ticks times 125 fits well within int; the
      // result is exact.
      const int days99 = 24000000 * 86400 * 99;
      expect(
        LumeBootClock.ticksToDuration(days99, arm),
        const Duration(days: 99),
      );
    });

    test('a zero or out-of-range timebase is refused, never divided by', () {
      for (final (int n, int d) in <(int, int)>[
        (0, 1),
        (1, 0),
        (-1, 1),
        (1, 0x100000000),
      ]) {
        expect(
          () => LumeTimebase(n, d),
          throwsA(isA<LumeBootClockUnavailable>()),
          reason: '$n/$d',
        );
      }
    });

    test('readings only go forward, and are held at the ceiling', () {
      int ticks = 24000000 * 10;
      final LumeElapsed clock = LumeBootClock.darwin(
        ticks: () => ticks,
        timebase: arm,
      );
      expect(clock(), const Duration(seconds: 10));
      ticks = 24000000 * 4; // a reading that seems to go back
      expect(clock(), const Duration(seconds: 10));
      ticks = 24000000 * 12;
      expect(clock(), const Duration(seconds: 12));
      ticks = -1;
      expect(clock(), LumeBootClock.ceiling);
      ticks = 0;
      expect(clock(), LumeBootClock.ceiling);
    });

    test('a native read that fails is not swallowed', () {
      final LumeElapsed clock = LumeBootClock.darwin(
        ticks: () => throw const LumeBootClockUnavailable('test'),
        timebase: arm,
      );
      expect(clock, throwsA(isA<LumeBootClockUnavailable>()));
    });

    test('a stopwatch on the continuous clock counts a simulated sleep '
        '(host test, not an iOS device test)', () {
      int ticks = 0;
      final LumeStopwatchController w = LumeStopwatchController(
        session: LumeToolSession(),
        periodic: (Duration d, void Function(Timer) f) => _Ticker(f),
        elapsed: LumeBootClock.darwin(ticks: () => ticks, timebase: arm),
      )..toggle();
      ticks += 24000000 * 5;
      w.away();
      ticks += 24000000 * 3600; // the device asleep: continuous time counts
      w.back();
      expect(
        w.milliseconds,
        const Duration(hours: 1, seconds: 5).inMilliseconds,
      );
      w.dispose();
    });
  });

  test('where no device clock exists, time still only goes forward', () {
    final LumeElapsed clock = LumeBootClock.platform();
    final Duration a = clock();
    final Duration b = clock();
    expect(b >= a, isTrue);
  });

  testWidgets('no wall clock: time passing changes nothing the source does '
      'not say', (WidgetTester tester) async {
    final LumeStopwatchController w = LumeStopwatchController(
      session: LumeToolSession(),
      elapsed: () => const Duration(seconds: 10),
    )..toggle();
    await tester.pump(const Duration(minutes: 10));
    expect(w.milliseconds, 0);
    w.dispose();
    final String source = File(
      'lib/features/stopwatch/application/stopwatch_controller.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('DateTime.now')));
    expect(source, isNot(contains('DateTime(')));
  });

  testWidgets('the tool stops repainting in the background and counts on', (
    WidgetTester tester,
  ) async {
    await pumpTool(tester, 'stopwatch', surface: const Size(390, 1200));
    await tester.tap(find.byKey(LumeStopwatchTool.startKey));
    await tester.pump();
    for (final AppLifecycleState s in <AppLifecycleState>[
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    for (final AppLifecycleState s in <AppLifecycleState>[
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester
          .widget<Text>(
            find
                .descendant(
                  of: find.byKey(LumeStopwatchTool.timeKey),
                  matching: find.byType(Text),
                )
                .first,
          )
          .data,
      isNot('00:00.00'),
    );
    await tester.tap(find.byKey(LumeStopwatchTool.startKey));
    await tester.pump();
  });
}

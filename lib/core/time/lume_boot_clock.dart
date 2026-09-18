/// Elapsed time that keeps counting while the phone sleeps (F6B closure, C83).
///
/// Dart's own `Stopwatch` reads `CLOCK_MONOTONIC` on Android, which stops in
/// deep sleep, and a comparable uptime clock on iOS — so a stopwatch left
/// running with the screen off would count short. This reads a clock that does
/// not stop, synchronously, through dart:ffi:
///
/// * **Android** — libc `clock_gettime(CLOCK_BOOTTIME)`, the clock behind
///   `SystemClock.elapsedRealtime`;
/// * **iOS** — `clock_gettime_nsec_np(CLOCK_MONOTONIC)`, which on Darwin
///   continues while the system sleeps (as `mach_continuous_time` does);
/// * **anywhere else** (the host that runs the tests, a desktop build) —
///   Dart's monotonic `Stopwatch`, said as such by [LumeBootClock.sourceFor].
///
/// Never the wall clock: a changed time or zone moves nothing. Both device
/// clocks start again at boot, so an elapsed time never outlives a reboot —
/// and nothing that uses one is stored across process death (see
/// `stopwatch_controller.dart`).
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

/// Elapsed time since some fixed moment. A parameter, so a test steps it.
typedef LumeElapsed = Duration Function();

/// Which clock [LumeBootClock.platform] reads.
enum LumeBootClockSource {
  /// Android `CLOCK_BOOTTIME`.
  androidBootTime,

  /// Darwin `CLOCK_MONOTONIC`, which counts sleep.
  darwinContinuous,

  /// Dart's `Stopwatch`: monotonic, but not across deep sleep. Only where no
  /// device clock is reachable.
  dartMonotonic,
}

abstract final class LumeBootClock {
  /// `CLOCK_BOOTTIME` in `<linux/time.h>`.
  static const int linuxBootTime = 7;

  /// `CLOCK_MONOTONIC` in Darwin's `<time.h>`.
  static const int darwinMonotonic = 6;

  static LumeBootClockSource sourceFor(
    TargetPlatform platform, {
    bool web = false,
  }) => web
      ? LumeBootClockSource.dartMonotonic
      : switch (platform) {
          TargetPlatform.android => LumeBootClockSource.androidBootTime,
          TargetPlatform.iOS => LumeBootClockSource.darwinContinuous,
          _ => LumeBootClockSource.dartMonotonic,
        };

  /// The clock this platform reads. On Android and iOS a clock that cannot
  /// be reached throws, rather than falling back to one that misses sleep.
  static LumeElapsed platform() => switch (sourceFor(
    defaultTargetPlatform,
    web: kIsWeb,
  )) {
    LumeBootClockSource.androidBootTime when Platform.isAndroid => _android(),
    LumeBootClockSource.darwinContinuous when Platform.isIOS => _darwin(),
    _ => _dart,
  };

  static final Stopwatch _stopwatch = Stopwatch()..start();
  static Duration _dart() => _stopwatch.elapsed;

  static LumeElapsed _android() {
    final int Function(int, Pointer<_Timespec>) get =
        DynamicLibrary.open('libc.so').lookupFunction<
          Int Function(Int, Pointer<_Timespec>),
          int Function(int, Pointer<_Timespec>)
        >('clock_gettime');
    // One buffer for the life of the process.
    final Pointer<_Timespec> t = calloc<_Timespec>();
    return () {
      if (get(linuxBootTime, t) != 0) {
        throw StateError('clock_gettime(CLOCK_BOOTTIME) failed');
      }
      return Duration(microseconds: t.ref.sec * 1000000 + t.ref.nsec ~/ 1000);
    };
  }

  static LumeElapsed _darwin() {
    final int Function(int) get = DynamicLibrary.process()
        .lookupFunction<Uint64 Function(Uint32), int Function(int)>(
          'clock_gettime_nsec_np',
        );
    return () => Duration(microseconds: get(darwinMonotonic) ~/ 1000);
  }
}

/// `struct timespec`: `time_t` and `long`, both the platform's `long`.
final class _Timespec extends Struct {
  @Long()
  external int sec;

  @Long()
  external int nsec;
}

/// Elapsed time that keeps counting while the phone sleeps (F6B closure, C83).
///
/// Dart's own `Stopwatch` reads `CLOCK_MONOTONIC` on Android, which stops in
/// deep sleep, and an uptime clock on iOS — so a stopwatch left running with
/// the screen off would count short. This reads a clock intended not to stop,
/// synchronously, through dart:ffi:
///
/// * **Android** — libc `clock_gettime(CLOCK_BOOTTIME)`, the clock behind
///   `SystemClock.elapsedRealtime`;
/// * **iOS** — `mach_continuous_time()`, Apple's continuous tick count, which
///   Apple documents as advancing while the system sleeps (unlike
///   `mach_absolute_time`), converted to nanoseconds by
///   `mach_timebase_info`, read once and cached. Both symbols are in
///   libSystem from iOS 10; Lume's deployment target is 13.0, so there is
///   **no fallback**: if either cannot be reached, [LumeBootClock.platform]
///   throws [LumeBootClockUnavailable] rather than quietly counting on a
///   clock that stops in sleep;
/// * **anywhere else** (the host that runs the tests, a desktop build) —
///   Dart's monotonic `Stopwatch`, said as such by [LumeBootClock.sourceFor].
///
/// Never the wall clock: a changed time or zone moves nothing. Both device
/// clocks start again at boot, so an elapsed time never outlives a reboot —
/// and nothing that uses one is stored across process death (see
/// `stopwatch_controller.dart`). Every device reading passes [LumeBootClock
/// .forward], so a reading that seems to go back repeats the last one.
///
/// The iOS path is checked as source on Windows; it has not been built or
/// run on an Apple device, and real deep sleep has not been observed there.
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

  /// Apple `mach_continuous_time`, which counts sleep.
  darwinContinuous,

  /// Dart's `Stopwatch`: monotonic, but not across deep sleep. Only where no
  /// device clock is reachable.
  dartMonotonic,
}

/// A device's sleep-counting clock could not be reached. Thrown instead of
/// falling back to a clock that stops while the phone sleeps.
final class LumeBootClockUnavailable implements Exception {
  const LumeBootClockUnavailable(this.reason);

  final String reason;

  @override
  String toString() => 'LumeBootClockUnavailable: $reason';
}

/// `mach_timebase_info_data_t`: ticks × [numer] / [denom] = nanoseconds.
@immutable
final class LumeTimebase {
  /// Throws [LumeBootClockUnavailable] for a zero or out-of-range term, which
  /// would divide by zero or scale every reading wrongly.
  LumeTimebase(this.numer, this.denom) {
    if (numer <= 0 || denom <= 0 || numer > _uint32 || denom > _uint32) {
      throw LumeBootClockUnavailable('mach timebase $numer/$denom');
    }
  }

  static const int _uint32 = 0xFFFFFFFF;

  final int numer;
  final int denom;
}

abstract final class LumeBootClock {
  /// `CLOCK_BOOTTIME` in `<linux/time.h>`.
  static const int linuxBootTime = 7;

  /// The Apple symbols the iOS clock reads, in `<mach/mach_time.h>`.
  static const String darwinTicks = 'mach_continuous_time';
  static const String darwinTimebase = 'mach_timebase_info';

  /// The longest reading a device clock returns; far past any stopwatch's
  /// own limit, and small enough that nothing downstream overflows.
  static const Duration ceiling = Duration(days: 365 * 1000);

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

  /// The clock this platform reads, made once per process. On Android and
  /// iOS a clock that cannot be reached throws [LumeBootClockUnavailable].
  static LumeElapsed platform() =>
      _platform ??= switch (sourceFor(defaultTargetPlatform, web: kIsWeb)) {
        LumeBootClockSource.androidBootTime when Platform.isAndroid => forward(
          _android(),
        ),
        LumeBootClockSource.darwinContinuous when Platform.isIOS => darwin(
          ticks: _darwinTicks(),
          timebase: _darwinTimebase(),
        ),
        _ => _dart,
      };

  static LumeElapsed? _platform;

  static final Stopwatch _stopwatch = Stopwatch()..start();
  static Duration _dart() => _stopwatch.elapsed;

  /// Nanoseconds for [ticks] at [base], without overflowing: a tick count
  /// read as negative (a `uint64` past 2⁶³) or a product past [ceiling]
  /// gives [ceiling].
  static Duration ticksToDuration(int ticks, LumeTimebase base) {
    if (ticks < 0) return ceiling;
    final BigInt ns =
        BigInt.from(ticks) * BigInt.from(base.numer) ~/ BigInt.from(base.denom);
    final BigInt us = ns ~/ BigInt.from(1000);
    return us > BigInt.from(ceiling.inMicroseconds)
        ? ceiling
        : Duration(microseconds: us.toInt());
  }

  /// The iOS clock from its two native reads, which a test replaces.
  static LumeElapsed darwin({
    required int Function() ticks,
    required LumeTimebase timebase,
  }) => forward(() => ticksToDuration(ticks(), timebase));

  /// [read], never going back: a reading below the last repeats the last,
  /// and one past [ceiling] is held there.
  static LumeElapsed forward(LumeElapsed read) {
    Duration last = Duration.zero;
    return () {
      final Duration now = read();
      final Duration held = now > ceiling ? ceiling : now;
      if (held > last) last = held;
      return last;
    };
  }

  static LumeElapsed _android() {
    final int Function(int, Pointer<_Timespec>) get;
    try {
      get = DynamicLibrary.open('libc.so')
          .lookupFunction<
            Int Function(Int, Pointer<_Timespec>),
            int Function(int, Pointer<_Timespec>)
          >('clock_gettime');
    } on Object catch (e) {
      throw LumeBootClockUnavailable('clock_gettime: $e');
    }
    // One buffer for the life of the process.
    final Pointer<_Timespec> t = calloc<_Timespec>();
    return () {
      if (get(linuxBootTime, t) != 0) {
        throw const LumeBootClockUnavailable('clock_gettime(CLOCK_BOOTTIME)');
      }
      final int sec = t.ref.sec;
      if (sec < 0 || sec > ceiling.inSeconds) return ceiling;
      return Duration(microseconds: sec * 1000000 + t.ref.nsec ~/ 1000);
    };
  }

  static int Function() _darwinTicks() {
    try {
      return DynamicLibrary.process()
          .lookupFunction<Uint64 Function(), int Function()>(darwinTicks);
    } on Object catch (e) {
      throw LumeBootClockUnavailable('$darwinTicks: $e');
    }
  }

  /// Read once; the timebase is fixed for the life of the process.
  static LumeTimebase _darwinTimebase() {
    final int Function(Pointer<_MachTimebase>) info;
    try {
      info = DynamicLibrary.process()
          .lookupFunction<
            Int32 Function(Pointer<_MachTimebase>),
            int Function(Pointer<_MachTimebase>)
          >(darwinTimebase);
    } on Object catch (e) {
      throw LumeBootClockUnavailable('$darwinTimebase: $e');
    }
    final Pointer<_MachTimebase> b = calloc<_MachTimebase>();
    try {
      final int kern = info(b);
      if (kern != 0) {
        throw LumeBootClockUnavailable('$darwinTimebase returned $kern');
      }
      return LumeTimebase(b.ref.numer, b.ref.denom);
    } finally {
      calloc.free(b);
    }
  }
}

/// `struct timespec`: `time_t` and `long`, both the platform's `long`.
final class _Timespec extends Struct {
  @Long()
  external int sec;

  @Long()
  external int nsec;
}

/// `struct mach_timebase_info`: two `uint32_t`.
final class _MachTimebase extends Struct {
  @Uint32()
  external int numer;

  @Uint32()
  external int denom;
}

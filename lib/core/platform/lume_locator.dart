/// One approximate position, asked for only when the reader taps
/// "Use my current location" (claude.md §9).
///
/// * The fix is taken once, at low accuracy — a city needs no more — and is
///   never tracked, stored or sent anywhere: the caller turns it into a
///   country and a city and drops it.
/// * A [LumeLocator] reports what happened as a [LumeLocateOutcome], so the
///   screen can say plainly why there is no position and leave the reader to
///   choose by hand, which is always possible.
/// * [LumeRecordingLocator] answers without touching the platform — tests use
///   it, and it never reaches the operating system.
///
/// The platform adapter lives in `lume_locator_platform.dart`, the only file
/// that knows which plugin reads the position.
library;

import 'package:flutter/foundation.dart';

/// What became of one request for the reader's position.
enum LumeLocateOutcome {
  /// A position was read.
  located,

  /// The reader said no this time. Asking again later is allowed.
  denied,

  /// The reader said no for good, or the device forbids it; only the
  /// system's own settings can change that.
  blocked,

  /// Location is switched off on the device.
  serviceOff,

  /// Nothing on this device can locate, or the platform failed or timed out.
  failed,
}

/// The answer to one request.
@immutable
class LumeLocateResult {
  const LumeLocateResult.located(double this.latitude, double this.longitude)
    : outcome = LumeLocateOutcome.located;

  const LumeLocateResult.refused(this.outcome)
    : assert(outcome != LumeLocateOutcome.located),
      latitude = null,
      longitude = null;

  final LumeLocateOutcome outcome;

  /// Set only when [outcome] is [LumeLocateOutcome.located].
  final double? latitude;
  final double? longitude;
}

/// Reads the reader's approximate position, once.
abstract interface class LumeLocator {
  Future<LumeLocateResult> locate();
}

/// Answers every request with [result]. Never touches the platform.
class LumeRecordingLocator implements LumeLocator {
  LumeRecordingLocator({
    this.result = const LumeLocateResult.refused(LumeLocateOutcome.failed),
  });

  /// What the next request answers.
  LumeLocateResult result;

  /// How many times a position was asked for.
  int requests = 0;

  @override
  Future<LumeLocateResult> locate() async {
    requests++;
    return result;
  }
}

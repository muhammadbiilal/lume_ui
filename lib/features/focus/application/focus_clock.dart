/// Where Focus gets its elapsed time from.
///
/// The controller takes a [LumeElapsed] so a test can step time itself
/// (`stopwatch_controller.dart`). The tool is built by the router, which
/// cannot pass one in, so the source is a provider: the boot-time clock in
/// the app, and whatever a screen test overrides it with in a test.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/lume_boot_clock.dart';

final Provider<LumeElapsed> focusClockProvider = Provider<LumeElapsed>(
  (Ref ref) => LumeBootClock.platform(),
);

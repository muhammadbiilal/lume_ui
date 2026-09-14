/// The device services a tool reaches through a contract, never directly.
///
/// Each is overridden in tests and in the fixture build with a recording fake,
/// so no test opens a dialer, a share sheet or a save dialog.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/lume_dialer.dart';
import '../../core/platform/lume_dialer_platform.dart';

/// D6 — opens the phone app with a number filled in.
final Provider<LumeDialer> dialerProvider = Provider<LumeDialer>(
  (Ref ref) => const LumePlatformDialer(),
);

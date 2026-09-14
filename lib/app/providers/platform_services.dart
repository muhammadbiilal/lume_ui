/// The device services a tool reaches through a contract, never directly.
///
/// Each is overridden in tests and in the fixture build with a recording fake,
/// so no test opens a dialer, a share sheet or a save dialog.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/lume_dialer.dart';
import '../../core/platform/lume_dialer_platform.dart';
import '../../core/platform/lume_export.dart';
import '../../core/platform/lume_scanner.dart';
import '../../core/platform/lume_share.dart';
import '../../core/platform/lume_share_platform.dart';

/// D6 — opens the phone app with a number filled in.
final Provider<LumeDialer> dialerProvider = Provider<LumeDialer>(
  (Ref ref) => const LumePlatformDialer(),
);

/// D7 — hands a rendered share card to the platform's share sheet.
final Provider<LumeSharer> sharerProvider = Provider<LumeSharer>(
  (Ref ref) => const LumePlatformSharer(),
);

/// D7 — puts a rendered share card in the photo library. Unavailable until
/// the photo-library permission is decided ([LumeUnavailableImageSaver]).
final Provider<LumeImageSaver> imageSaverProvider = Provider<LumeImageSaver>(
  (Ref ref) => const LumeUnavailableImageSaver(),
);

/// C78 — reads a code with the camera or from an image. Unavailable until a
/// camera package and its permission wording are decided
/// ([LumeUnavailableScanner]): nothing reaches the device.
final Provider<LumeScanner> scannerProvider = Provider<LumeScanner>(
  (Ref ref) => const LumeUnavailableScanner(),
);

/// D7 — writes a tool's export where the reader chooses.
final Provider<LumeExporter> exporterProvider = Provider<LumeExporter>(
  (Ref ref) => const LumePlatformExporter(),
);

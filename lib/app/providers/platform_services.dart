/// The device services a tool reaches through a contract, never directly.
///
/// Each is overridden in tests and in the fixture build with a recording fake,
/// so no test opens a dialer, a share sheet or a save dialog.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/lume_dialer.dart';
import '../../core/platform/lume_dialer_platform.dart';
import '../../core/platform/lume_export.dart';
import '../../core/platform/lume_image_saver_platform.dart';
import '../../core/platform/lume_link_opener.dart';
import '../../core/platform/lume_link_opener_platform.dart';
import '../../core/platform/lume_scanner.dart';
import '../../core/platform/lume_scanner_platform.dart';
import '../../core/platform/lume_share.dart';
import '../../core/platform/lume_share_platform.dart';
import '../../core/routing/app_router.dart';

/// D6 — opens the phone app with a number filled in.
final Provider<LumeDialer> dialerProvider = Provider<LumeDialer>(
  (Ref ref) => const LumePlatformDialer(),
);

/// D7 — hands a rendered share card to the platform's share sheet.
final Provider<LumeSharer> sharerProvider = Provider<LumeSharer>(
  (Ref ref) => const LumePlatformSharer(),
);

/// D7, F6B — puts a rendered share card in the photo library, asking for
/// add-only access and nothing more.
final Provider<LumeImageSaver> imageSaverProvider = Provider<LumeImageSaver>(
  (Ref ref) => const LumePlatformImageSaver(),
);

/// C80 — reads a QR code with the camera or from one chosen image, on the
/// device. The capture page is pushed on the root navigator, over the shell.
final Provider<LumeScanner> scannerProvider = Provider<LumeScanner>(
  (Ref ref) => LumePlatformScanner(
    navigator: () =>
        ref.read(routerProvider).routerDelegate.navigatorKey.currentState,
  ),
);

/// C80 — opens a checked web, email or message address in another app, on a
/// press.
final Provider<LumeLinkOpener> linkOpenerProvider = Provider<LumeLinkOpener>(
  (Ref ref) => const LumePlatformLinkOpener(),
);

/// D7 — writes a tool's export where the reader chooses.
final Provider<LumeExporter> exporterProvider = Provider<LumeExporter>(
  (Ref ref) => const LumePlatformExporter(),
);

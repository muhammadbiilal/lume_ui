/// The device services a tool reaches through a contract, never directly.
///
/// Each is overridden in tests and in the fixture build with a recording fake,
/// so no test opens a dialer, a share sheet or a save dialog.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/lume_app_settings.dart';
import '../../core/platform/lume_camera_gate.dart';
import '../../core/platform/lume_dialer.dart';
import '../../core/platform/lume_dialer_platform.dart';
import '../../core/platform/lume_export.dart';
import '../../core/platform/lume_image_saver_platform.dart';
import '../../core/platform/lume_link_opener.dart';
import '../../core/platform/lume_media_store_saver.dart';
import '../../core/platform/lume_link_opener_platform.dart';
import '../../core/platform/lume_notification_gate.dart';
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

/// A message the reader has previewed, handed to the share sheet as text
/// (a Ledger reminder). Never a delivery.
final Provider<LumeTextSharer> textSharerProvider = Provider<LumeTextSharer>(
  (Ref ref) => const LumePlatformTextSharer(),
);

/// D7, F6B — puts a rendered share card in the photo library, asking for
/// add-only access and nothing more.
final Provider<LumeImageSaver> imageSaverProvider = Provider<LumeImageSaver>(
  (Ref ref) => kIsWeb
      ? const LumeUnavailableImageSaver()
      : switch (defaultTargetPlatform) {
          // Lume's own MediaStore channel: a `.png` typed `image/png` (C81).
          TargetPlatform.android => const LumeMediaStoreImageSaver(),
          TargetPlatform.iOS => const LumeGalImageSaver(),
          _ => const LumeUnavailableImageSaver(),
        },
);

/// C80 — reads a QR code with the camera or from one chosen image, on the
/// device. The capture page is pushed on the root navigator, over the shell.
/// On Android the camera is asked for through Lume's own channel first, so a
/// refusal is told from one for good.
final Provider<LumeScanner> scannerProvider = Provider<LumeScanner>(
  (Ref ref) => LumePlatformScanner(
    navigator: () =>
        ref.read(routerProvider).routerDelegate.navigatorKey.currentState,
    gate: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? const LumeAndroidCameraGate()
        : null,
    settings:
        !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS)
        ? const LumeChannelAppSettings()
        : null,
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

/// Wave 7 (`REMINDERS_PROPOSAL.md` §4) — one gate, one channel per platform,
/// not one channel branching inside itself, matching the camera gate's own
/// Android-only-rather-than-pretending-cross-platform choice.
final Provider<LumeNotificationGate> notificationGateProvider =
    Provider<LumeNotificationGate>((Ref ref) {
      if (kIsWeb) return const LumeUnavailableNotificationGate();
      return switch (defaultTargetPlatform) {
        TargetPlatform.android => const LumeAndroidNotificationGate(),
        TargetPlatform.iOS => const LumeIosNotificationGate(),
        _ => const LumeUnavailableNotificationGate(),
      };
    });

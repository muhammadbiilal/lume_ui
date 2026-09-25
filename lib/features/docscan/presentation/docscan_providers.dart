/// The device services Document Scanner reaches through a contract, never
/// directly — scoped to this feature alone, the way `platform_services.dart`
/// scopes the app-wide ones (F6B, C80).
///
/// Neither provider is declared in `platform_services.dart`: nothing else in
/// Lume takes a document photo or shares more than one file at once, so
/// there is nothing app-wide to add there.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/lume_app_settings.dart';
import '../../../core/platform/lume_camera_gate.dart';
import '../data/document_capture.dart';
import '../data/document_capture_platform.dart';
import '../data/document_sharer.dart';

/// Captures a document photo with the camera, or chooses one from the
/// gallery — on the device. Gated the same way [scannerProvider] gates the QR
/// scanner's own camera press (`platform_services.dart`).
final Provider<LumeDocumentCamera> documentCameraProvider =
    Provider<LumeDocumentCamera>(
      (Ref ref) => kIsWeb
          ? const LumeUnavailableDocumentCamera()
          : switch (defaultTargetPlatform) {
              TargetPlatform.android => const LumePlatformDocumentCamera(
                gate: LumeAndroidCameraGate(),
                settings: LumeChannelAppSettings(),
              ),
              TargetPlatform.iOS => const LumePlatformDocumentCamera(
                settings: LumeChannelAppSettings(),
              ),
              _ => const LumeUnavailableDocumentCamera(),
            },
    );

/// Hands the pages a session captured to the platform's share sheet, each
/// named and typed as it actually is.
final Provider<LumeDocumentSharer> documentSharerProvider =
    Provider<LumeDocumentSharer>(
      (Ref ref) => const LumePlatformDocumentSharer(),
    );

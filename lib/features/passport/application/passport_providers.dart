/// Passport Photos' own device services.
///
/// The same shape `app/providers/platform_services.dart` gives every other
/// tool's camera and photo access, kept here instead: this build is confined
/// to `lib/features/passport/`, so the shared platform-services file — every
/// other converted tool's own dependency — is left untouched, and this one
/// tool's provider lives beside the contract it serves.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/lume_app_settings.dart';
import '../../../core/platform/lume_camera_gate.dart';
import '../data/passport_photo_platform.dart';
import '../domain/passport_photo_source.dart';

/// C80-shaped: the camera is asked for through Lume's own Android channel
/// first, so a refusal is told from one for good; iOS has no such channel, so
/// the picker's own `PlatformException` codes are all it can go on. Web and
/// any other platform get the unavailable source, never a device reach.
final Provider<LumePassportPhotoSource> passportPhotoSourceProvider =
    Provider<LumePassportPhotoSource>((Ref ref) {
      if (kIsWeb) return const LumeUnavailablePassportPhotoSource();
      return switch (defaultTargetPlatform) {
        TargetPlatform.android => const LumePlatformPassportPhotoSource(
          gate: LumeAndroidCameraGate(),
          settings: LumeChannelAppSettings(),
        ),
        TargetPlatform.iOS => const LumePlatformPassportPhotoSource(
          settings: LumeChannelAppSettings(),
        ),
        _ => const LumeUnavailablePassportPhotoSource(),
      };
    });

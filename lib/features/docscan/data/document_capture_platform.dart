/// The one file that knows which package captures a document photo — mirrors
/// `lume_scanner_platform.dart`'s own rule for QR (C80).
///
/// `image_picker`'s camera source opens the system camera app — the phone's
/// own hardware and UI, not an embedded preview Lume draws, because there is
/// nothing here to decode from a live frame the way `flutter_zxing` decodes a
/// QR code — and hands back one photo's bytes; its gallery source is the same
/// system picker the QR scanner's own "From gallery" already uses, granting
/// the one file chosen with no library permission. Neither is a new
/// dependency: `image_picker` is already pinned in `pubspec.yaml` for the QR
/// scanner's gallery pick.
///
/// The camera permission is asked only after Capture is pressed: on Android
/// by [LumeCameraGate], exactly as the QR scanner gates its own camera press,
/// so a refusal is known from one for good; on iOS `image_picker` asks the
/// system prompt itself, and its own denial code is mapped directly (C80) —
/// narrower than the camera plugin's, since `image_picker` does not
/// distinguish "denied" from "restricted" the way `flutter_zxing`'s camera
/// plugin does.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart' as picker;

import '../../../core/platform/lume_app_settings.dart';
import '../../../core/platform/lume_camera_gate.dart';
import 'document_capture.dart';

/// Opens the camera or the gallery and hands back the chosen file, or `null`
/// if the reader chose nothing.
typedef LumeImageCapture = Future<picker.XFile?> Function(picker.ImageSource);

Future<picker.XFile?> _pick(picker.ImageSource source) =>
    picker.ImagePicker().pickImage(
      source: source,
      // A phone photo of a page does not need its full sensor resolution to
      // be legible once shared; this keeps a capture a reasonable size
      // without any processing of Lume's own.
      imageQuality: 85,
      requestFullMetadata: false,
    );

class LumePlatformDocumentCamera implements LumeDocumentCamera {
  const LumePlatformDocumentCamera({
    LumeCameraGate? gate,
    LumeAppSettings? settings,
    LumeImageCapture pick = _pick,
  }) : _gate = gate,
       _settings = settings,
       _pickImage = pick;

  /// Asked before the camera opens, on Android only — `null` elsewhere leaves
  /// it to `image_picker` itself, which cannot tell a refusal from one for
  /// good on iOS.
  final LumeCameraGate? _gate;

  /// Opens Lume's page in Settings, where the platform has one to open.
  final LumeAppSettings? _settings;
  final LumeImageCapture _pickImage;

  @override
  Future<LumeCaptureResult> capture() async {
    final LumeCameraGate? gate = _gate;
    if (gate != null) {
      final LumeCaptureOutcome? refused = refusal(await gate.request());
      if (refused != null) return LumeCaptureResult(refused);
    }
    return _take(picker.ImageSource.camera, isCamera: true);
  }

  @override
  Future<LumeCaptureResult> pickImage() =>
      _take(picker.ImageSource.gallery, isCamera: false);

  Future<LumeCaptureResult> _take(
    picker.ImageSource source, {
    required bool isCamera,
  }) async {
    final picker.XFile? file;
    try {
      file = await _pickImage(source);
    } on MissingPluginException {
      return const LumeCaptureResult.unavailable();
    } on PlatformException catch (e) {
      return LumeCaptureResult(trouble(e.code, isCamera: isCamera));
    }
    if (file == null) {
      return const LumeCaptureResult(LumeCaptureOutcome.cancelled);
    }
    try {
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return const LumeCaptureResult(LumeCaptureOutcome.failed);
      }
      return LumeCaptureResult(
        LumeCaptureOutcome.captured,
        bytes: bytes,
        mimeType: file.mimeType ?? mimeOf(file.name),
      );
    } on Object {
      return const LumeCaptureResult(LumeCaptureOutcome.failed);
    }
  }

  /// What a camera [access] means for the capture: `null` to open the camera.
  /// The same mapping `LumePlatformScanner.refusal` uses for QR — one gate,
  /// one meaning, used by both instruments.
  @visibleForTesting
  static LumeCaptureOutcome? refusal(LumeCameraAccess access) =>
      switch (access) {
        LumeCameraAccess.granted => null,
        LumeCameraAccess.denied => LumeCaptureOutcome.denied,
        LumeCameraAccess.blocked => LumeCaptureOutcome.blocked,
        LumeCameraAccess.restricted => LumeCaptureOutcome.restricted,
        LumeCameraAccess.undetermined => LumeCaptureOutcome.undetermined,
        LumeCameraAccess.interrupted => LumeCaptureOutcome.cancelled,
        LumeCameraAccess.unavailable => LumeCaptureOutcome.unavailable,
        // A request never answers "first request"; if it did, the adapter
        // failed.
        LumeCameraAccess.firstRequest ||
        LumeCameraAccess.failed => LumeCaptureOutcome.failed,
      };

  /// `image_picker`'s own denial codes for a source it would not open:
  /// `camera_access_denied` from the camera, `photo_access_denied` from the
  /// gallery. Neither says whether it is refused for good, so both are
  /// [LumeCaptureOutcome.denied] rather than a guess at
  /// [LumeCaptureOutcome.blocked] (C80) — true on Android too, where the
  /// gate above already turned a granular refusal into its own outcome
  /// before this is ever reached for the camera source.
  @visibleForTesting
  static LumeCaptureOutcome trouble(String code, {required bool isCamera}) {
    final String denied = isCamera ? 'camera_access_denied' : 'photo_access_denied';
    return code == denied ? LumeCaptureOutcome.denied : LumeCaptureOutcome.failed;
  }

  /// A best guess from the file's own name, for a gallery file `image_picker`
  /// reports no MIME type for. Defaults to JPEG, what a camera capture always
  /// is.
  @visibleForTesting
  static String mimeOf(String name) {
    final String lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  /// Where Lume's own Settings page can change the camera: refused for good,
  /// or refused with the platform not saying (Android only) — the same set
  /// `LumePlatformScanner.settingsHelp` declares for QR.
  static const Set<LumeCaptureOutcome> settingsHelp = <LumeCaptureOutcome>{
    LumeCaptureOutcome.blocked,
    LumeCaptureOutcome.undetermined,
  };

  @override
  bool offersSettings(LumeCaptureOutcome outcome) =>
      _settings != null && settingsHelp.contains(outcome);

  @override
  Future<bool> openSettings() async => await _settings?.open() ?? false;
}

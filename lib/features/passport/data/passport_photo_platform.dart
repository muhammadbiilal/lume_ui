/// The one file that knows which package takes and picks a photo for
/// Passport Photos — `image_picker`, already pinned in `pubspec.yaml` for
/// QR's own "From gallery" (`lume_scanner_platform.dart`). Reused here for
/// both sides: `ImageSource.camera` opens the platform's own native camera
/// (Android's camera app, iOS's `UIImagePickerController`), which is the
/// honest choice for *taking a photograph* — `flutter_zxing`'s
/// `ReaderWidget`, QR's own camera view, is a barcode viewfinder with no
/// still-capture of its own to reuse, only continuous frame decoding.
///
/// The Android camera permission is asked for through [LumeCameraGate]
/// before the picker opens, exactly as `LumePlatformScanner.scan` does, so a
/// refusal is told from one for good; elsewhere `image_picker` itself asks
/// (and iOS answers only through its own `PlatformException` codes).
/// `requestFullMetadata: false` matches the scanner's own choice: no EXIF, no
/// broader photo-library grant than the one image chosen.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart' as picker;

import '../../../core/platform/lume_app_settings.dart';
import '../../../core/platform/lume_camera_gate.dart';
import '../domain/passport_photo_source.dart';

/// Opens the system camera or picker; the chosen file, or `null` if none.
typedef LumePassportImagePick =
    Future<picker.XFile?> Function(picker.ImageSource source);

class LumePlatformPassportPhotoSource implements LumePassportPhotoSource {
  const LumePlatformPassportPhotoSource({
    this.gate,
    this.settings,
    LumePassportImagePick pick = _defaultPick,
  }) : _pick = pick;

  /// Asks for the camera before the picker opens. `null` leaves it to the
  /// picker itself, which cannot tell a refusal from one for good.
  final LumeCameraGate? gate;

  /// Opens Lume's own page in Settings, where the platform has one to open.
  final LumeAppSettings? settings;

  final LumePassportImagePick _pick;

  /// A phone photo is a few megabytes; a file past this would stall the
  /// device to decode and crop — the same ceiling QR's own gallery pick uses
  /// (`LumePlatformScanner.maxImageBytes`).
  static const int maxImageBytes = 25 * 1024 * 1024;

  @override
  Future<LumePassportPhotoResult> capture() async {
    final LumeCameraGate? g = gate;
    if (g != null) {
      final LumePassportPhotoOutcome? refused = refusal(await g.request());
      if (refused != null) return LumePassportPhotoResult(refused);
    }
    return _run(picker.ImageSource.camera, camera: true);
  }

  @override
  Future<LumePassportPhotoResult> pickImage() =>
      _run(picker.ImageSource.gallery, camera: false);

  Future<LumePassportPhotoResult> _run(
    picker.ImageSource source, {
    required bool camera,
  }) async {
    final picker.XFile? file;
    try {
      file = await _pick(source);
    } on MissingPluginException {
      return const LumePassportPhotoResult.unavailable();
    } on PlatformException catch (e) {
      return LumePassportPhotoResult(_trouble(e.code, camera: camera));
    }
    if (file == null) {
      return const LumePassportPhotoResult(LumePassportPhotoOutcome.cancelled);
    }
    try {
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return const LumePassportPhotoResult(LumePassportPhotoOutcome.failed);
      }
      if (bytes.lengthInBytes > maxImageBytes) {
        return const LumePassportPhotoResult(LumePassportPhotoOutcome.tooLarge);
      }
      return LumePassportPhotoResult(LumePassportPhotoOutcome.captured, bytes);
    } on Object {
      return const LumePassportPhotoResult(LumePassportPhotoOutcome.failed);
    }
  }

  /// `image_picker`'s own denial codes: `camera_access_denied` on both
  /// platforms answers the one prompt a reader gets (Android's gate has
  /// already classified a repeatable refusal before this is ever reached;
  /// reaching it at all past the gate, or on iOS where there is no gate,
  /// means the one ask is spent), and `photo_access_denied` is the picker's
  /// own gallery refusal.
  static LumePassportPhotoOutcome _trouble(String code, {required bool camera}) {
    if (camera) {
      return switch (code) {
        'camera_access_denied' => LumePassportPhotoOutcome.blocked,
        _ => LumePassportPhotoOutcome.failed,
      };
    }
    return switch (code) {
      'photo_access_denied' => LumePassportPhotoOutcome.denied,
      _ => LumePassportPhotoOutcome.failed,
    };
  }

  /// What a camera [access] means for capture: `null` to open the camera.
  /// The same mapping `LumePlatformScanner.refusal` uses for Scan.
  @visibleForTesting
  static LumePassportPhotoOutcome? refusal(LumeCameraAccess access) =>
      switch (access) {
        LumeCameraAccess.granted => null,
        LumeCameraAccess.denied => LumePassportPhotoOutcome.denied,
        LumeCameraAccess.blocked => LumePassportPhotoOutcome.blocked,
        LumeCameraAccess.restricted => LumePassportPhotoOutcome.restricted,
        LumeCameraAccess.undetermined => LumePassportPhotoOutcome.undetermined,
        LumeCameraAccess.interrupted => LumePassportPhotoOutcome.cancelled,
        LumeCameraAccess.unavailable => LumePassportPhotoOutcome.unavailable,
        LumeCameraAccess.firstRequest ||
        LumeCameraAccess.failed => LumePassportPhotoOutcome.failed,
      };

  /// Where Lume's own Settings page can change the camera: refused for good,
  /// or refused with the platform not saying (Android only).
  static const Set<LumePassportPhotoOutcome> settingsHelp =
      <LumePassportPhotoOutcome>{
        LumePassportPhotoOutcome.blocked,
        LumePassportPhotoOutcome.undetermined,
      };

  @override
  bool offersSettings(LumePassportPhotoOutcome outcome) =>
      settings != null && settingsHelp.contains(outcome);

  @override
  Future<bool> openSettings() async => await settings?.open() ?? false;
}

Future<picker.XFile?> _defaultPick(picker.ImageSource source) =>
    picker.ImagePicker().pickImage(source: source, requestFullMetadata: false);

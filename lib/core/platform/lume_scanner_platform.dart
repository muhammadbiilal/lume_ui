/// The one file that knows which packages scan (C80).
///
/// * **Camera** — `flutter_zxing`'s `ReaderWidget`, inside [LumeCapturePage]:
///   zxing-cpp decodes each frame on the device through FFI. No network, no
///   analytics, no microphone (`enableAudio: false`), no frame kept. The
///   camera permission is asked only after Scan is pressed: on Android by
///   [LumeCameraGate] before the page opens, so Lume knows a refusal from one
///   for good; elsewhere by the camera plugin when the page opens.
/// * **From gallery** — `image_picker`'s system picker (the Android Photo
///   Picker, iOS PHPicker) with `requestFullMetadata: false`, so the one image
///   chosen is granted and no photo-library permission is asked. The picker
///   hands back a private copy; it is decoded in a background isolate and
///   deleted whatever the outcome.
///
/// Everything a platform does is a parameter, so what this adapter decides —
/// which outcome a picked image is, which a camera error is — is tested
/// without a device.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_zxing/flutter_zxing.dart' as zxing;
import 'package:image_picker/image_picker.dart' as picker;

import 'lume_app_settings.dart';
import 'lume_camera_gate.dart';
import 'lume_capture_page.dart';
import 'lume_scanner.dart';

/// One code found in an image, in terms that name no package.
@immutable
class LumeDecodedCode {
  const LumeDecodedCode({
    required this.text,
    required this.isQr,
    required this.isValid,
  });

  final String? text;
  final bool isQr;

  /// False when the symbol was located but its content is damaged.
  final bool isValid;
}

/// What decoding an image produced: codes, or why there are none.
@immutable
class LumeDecodedImage {
  const LumeDecodedImage({this.codes = const <LumeDecodedCode>[], this.error});

  final List<LumeDecodedCode> codes;

  /// The image itself could not be read.
  final String? error;
}

/// Finds the navigator the capture page is pushed on.
typedef LumeNavigatorLookup = NavigatorState? Function();

/// Opens the system picker; the chosen copy's path, or `null` if none.
typedef LumeImagePick = Future<String?> Function();

typedef LumeImageDecode = Future<LumeDecodedImage> Function(String path);
typedef LumeFileSize = Future<int> Function(String path);
typedef LumeFileRemove = Future<void> Function(String path);

class LumePlatformScanner implements LumeScanner {
  const LumePlatformScanner({
    required LumeNavigatorLookup navigator,
    LumeCameraGate? gate,
    LumeAppSettings? settings,
    LumeCameraView camera = lumeZxingCamera,
    LumeImagePick pick = _pick,
    LumeImageDecode decode = _decode,
    LumeFileSize sizeOf = _sizeOf,
    LumeFileRemove remove = _remove,
  }) : _navigator = navigator,
       _gate = gate,
       _settings = settings,
       _camera = camera,
       _pickImage = pick,
       _decodeImage = decode,
       _size = sizeOf,
       _delete = remove;

  final LumeNavigatorLookup _navigator;

  /// Asks for the camera before the page opens. `null` leaves it to the
  /// camera plugin, which cannot tell a refusal from one for good.
  final LumeCameraGate? _gate;

  /// Opens Lume's page in Settings, where the platform has one to open.
  final LumeAppSettings? _settings;
  final LumeCameraView _camera;
  final LumeImagePick _pickImage;
  final LumeImageDecode _decodeImage;
  final LumeFileSize _size;
  final LumeFileRemove _delete;

  /// A phone photo is a few megabytes; a file past this is not a photo of a
  /// code, and decoding it would stall the device.
  static const int maxImageBytes = 25 * 1024 * 1024;

  @override
  Future<LumeScanResult> scan() async {
    final NavigatorState? navigator = _navigator();
    if (navigator == null) return const LumeScanResult.unavailable();
    final LumeCameraGate? gate = _gate;
    if (gate != null) {
      final LumeScanOutcome? refused = refusal(await gate.request());
      if (refused != null) return LumeScanResult(refused);
    }
    try {
      return await showLumeCapture(navigator, camera: _camera);
    } on MissingPluginException {
      return const LumeScanResult.unavailable();
    } on Exception {
      return const LumeScanResult(LumeScanOutcome.failed);
    }
  }

  @override
  Future<LumeScanResult> pickImage() async {
    final String? path;
    try {
      path = await _pickImage();
    } on MissingPluginException {
      return const LumeScanResult.unavailable();
    } on PlatformException catch (e) {
      return LumeScanResult(
        e.code == 'photo_access_denied'
            ? LumeScanOutcome.denied
            : LumeScanOutcome.failed,
      );
    }
    if (path == null) return const LumeScanResult(LumeScanOutcome.cancelled);
    try {
      final int bytes = await _size(path);
      if (bytes <= 0) return const LumeScanResult(LumeScanOutcome.unreadable);
      if (bytes > maxImageBytes) {
        return const LumeScanResult(LumeScanOutcome.tooLarge);
      }
      return interpret(await _decodeImage(path));
    } on Object {
      return const LumeScanResult(LumeScanOutcome.failed);
    } finally {
      try {
        await _delete(path);
      } on Object {
        // A copy the system cleans with the cache; nothing to tell the reader.
      }
    }
  }

  /// What a camera [access] means for the scan: `null` to open the camera.
  @visibleForTesting
  static LumeScanOutcome? refusal(LumeCameraAccess access) => switch (access) {
    LumeCameraAccess.granted => null,
    LumeCameraAccess.denied => LumeScanOutcome.denied,
    LumeCameraAccess.blocked => LumeScanOutcome.blocked,
    LumeCameraAccess.restricted => LumeScanOutcome.restricted,
    LumeCameraAccess.undetermined => LumeScanOutcome.undetermined,
    LumeCameraAccess.interrupted => LumeScanOutcome.cancelled,
    LumeCameraAccess.unavailable => LumeScanOutcome.unavailable,
    // A request never answers "first request"; if it did, the adapter failed.
    LumeCameraAccess.firstRequest ||
    LumeCameraAccess.failed => LumeScanOutcome.failed,
  };

  /// Where Lume's own Settings page can change the camera: refused for good,
  /// or refused with the platform not saying (Android only). Not a policy or
  /// Screen Time restriction, which the page cannot lift; not a cancel, an
  /// interruption, a missing camera or a failure, which it cannot help.
  static const Set<LumeScanOutcome> settingsHelp = <LumeScanOutcome>{
    LumeScanOutcome.blocked,
    LumeScanOutcome.undetermined,
  };

  @override
  bool offersSettings(LumeScanOutcome outcome) =>
      _settings != null && settingsHelp.contains(outcome);

  @override
  Future<bool> openSettings() async => await _settings?.open() ?? false;

  /// What a decoded image means for the reader.
  @visibleForTesting
  static LumeScanResult interpret(LumeDecodedImage image) {
    if (image.error != null) {
      return const LumeScanResult(LumeScanOutcome.unreadable);
    }
    if (image.codes.isEmpty) {
      return const LumeScanResult(LumeScanOutcome.nothing);
    }
    final Iterable<LumeDecodedCode> qr = image.codes.where(
      (LumeDecodedCode c) => c.isQr,
    );
    if (qr.isEmpty) {
      return LumeScanResult(
        image.codes.any((LumeDecodedCode c) => c.isValid)
            ? LumeScanOutcome.unsupported
            : LumeScanOutcome.unreadable,
      );
    }
    // The same code found twice is one code.
    final Set<String> texts = <String>{
      for (final LumeDecodedCode c in qr)
        if (c.isValid && (c.text ?? '').isNotEmpty) c.text!,
    };
    if (texts.length > 1) {
      return const LumeScanResult(LumeScanOutcome.multiple);
    }
    if (texts.isEmpty) {
      return const LumeScanResult(LumeScanOutcome.unreadable);
    }
    return LumeScanResult(LumeScanOutcome.read, texts.single);
  }
}

bool _isQr(int? format) =>
    ((format ?? 0) &
        (zxing.Format.qrCode |
            zxing.Format.microQRCode |
            zxing.Format.rmqrCode)) !=
    0;

/// What a camera error means for the reader, in the camera plugin's own
/// codes. iOS asks once: its `CameraAccessDenied` answers the one prompt it
/// will ever show, so it is blocked, as `…WithoutPrompt` is; `…Restricted` is
/// Screen Time or a profile, which the reader's own Settings page cannot
/// change. On Android the gate has already asked; a `CameraAccessDenied` here is
/// a permission taken away while the page was opening, which Scan asks again.
@visibleForTesting
LumeScanOutcome lumeCameraTrouble(Object error, {required bool promptsOnce}) {
  if (error is MissingPluginException) return LumeScanOutcome.unavailable;
  final String? code = RegExp(
    r'CameraException\((\w+)',
  ).firstMatch(error.toString())?.group(1);
  return switch (code) {
    'CameraAccessDenied' =>
      promptsOnce ? LumeScanOutcome.blocked : LumeScanOutcome.denied,
    'CameraAccessDeniedWithoutPrompt' => LumeScanOutcome.blocked,
    'CameraAccessRestricted' => LumeScanOutcome.restricted,
    'cameraNotFound' => LumeScanOutcome.unavailable,
    _ => LumeScanOutcome.failed,
  };
}

/// The camera view: `ReaderWidget` with every control of its own hidden, so
/// only Lume's page is drawn around the picture.
Widget lumeZxingCamera(
  BuildContext context,
  LumeCameraEvents events,
  double scanSide,
) {
  final double shorter = MediaQuery.sizeOf(context).shortestSide;
  return zxing.ReaderWidget(
    onScan: (zxing.Code code) {
      final String? text = code.text;
      if (code.isValid && text != null) {
        events.onCode(text, isQr: _isQr(code.format));
      }
    },
    onControllerCreated: (_, Exception? error) {
      if (error == null) {
        events.onLive();
      } else {
        events.onTrouble(
          lumeCameraTrouble(
            error,
            promptsOnce: defaultTargetPlatform == TargetPlatform.iOS,
          ),
        );
      }
    },
    tryInverted: true,
    showScannerOverlay: false,
    showFlashlight: false,
    showToggleCamera: false,
    showGallery: false,
    allowPinchZoom: false,
    // The square decoded is the window drawn, with a margin for a hand.
    cropPercent: shorter <= 0
        ? 0.7
        : ((scanSide * 1.15) / shorter).clamp(0.4, 1.0),
    loading: const SizedBox.expand(),
  );
}

Future<String?> _pick() async => (await picker.ImagePicker().pickImage(
  source: picker.ImageSource.gallery,
  requestFullMetadata: false,
))?.path;

Future<LumeDecodedImage> _decode(String path) =>
    Isolate.run<LumeDecodedImage>(() async {
      final zxing.Codes found = await zxing.zx.readBarcodesImagePathString(
        path,
        zxing.DecodeParams(
          tryHarder: true,
          tryInverted: true,
          maxSize: 1280,
          maxNumberOfSymbols: 8,
        ),
      );
      return LumeDecodedImage(
        error: found.error,
        codes: <LumeDecodedCode>[
          for (final zxing.Code c in found.codes)
            LumeDecodedCode(
              text: c.text,
              isQr: _isQr(c.format),
              isValid: c.isValid,
            ),
        ],
      );
    });

Future<int> _sizeOf(String path) => File(path).length();

Future<void> _remove(String path) async {
  final File file = File(path);
  if (file.existsSync()) await file.delete();
}

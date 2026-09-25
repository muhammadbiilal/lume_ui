/// Capturing a photo of a document, or choosing one already taken — through a
/// contract, the same shape `LumeScanner` (`lume_scanner.dart`) uses for a QR
/// code, and for the same reason (F6B, C80): the camera is asked for only by
/// a press, never at launch, and a refusal is explained rather than asked
/// again.
///
/// A code scan and a document scan point the same camera at different
/// things. `LumeScanner` decodes a barcode on the device and the decoded
/// *text* is the whole result — the frame itself never leaves the phone. A
/// document scanner's result *is* the frame: there is nothing to decode, so
/// this contract hands back the bytes Lume was given rather than something
/// read out of them. That is also why it is a contract of its own rather
/// than `LumeScanner` wearing a new name — `LumeScanResult.value` is decoded
/// text, and a document photo is not text.
///
/// * `LumePlatformDocumentCamera` (`document_capture_platform.dart`) is the
///   device adapter.
/// * [LumeUnavailableDocumentCamera] never touches a device.
/// * [LumeRecordingDocumentCamera] records instead, for tests.
library;

import 'package:flutter/foundation.dart';

/// What became of one request for a document photo.
enum LumeCaptureOutcome {
  /// A photo was captured or chosen; [LumeCaptureResult.bytes] holds it.
  captured,

  /// The reader closed the camera, or chose no image. Not a failure, and
  /// nothing is said about it.
  cancelled,

  /// The reader refused the camera or the photos, and the platform will ask
  /// again the next time.
  denied,

  /// The permission is off and the platform will not ask again: refused for
  /// good. Only Settings can change it.
  blocked,

  /// A device policy has turned the camera off. Settings cannot change it.
  restricted,

  /// The camera was refused, and the platform does not say whether it will
  /// ask again: Capture may ask, and Settings certainly can.
  undetermined,

  /// Nothing on this device can capture this way: no camera, or no picker on
  /// this platform.
  unavailable,

  /// The camera or the picker would not open, or the platform threw.
  failed,
}

@immutable
class LumeCaptureResult {
  const LumeCaptureResult(this.outcome, {this.bytes, this.mimeType});

  const LumeCaptureResult.unavailable()
    : outcome = LumeCaptureOutcome.unavailable,
      bytes = null,
      mimeType = null;

  final LumeCaptureOutcome outcome;

  /// The photo, when [outcome] is [LumeCaptureOutcome.captured].
  final Uint8List? bytes;

  /// What [bytes] actually is — `image/jpeg` from a camera capture, or
  /// whatever the chosen gallery file already was. Never assumed to be PNG.
  final String? mimeType;

  @override
  bool operator ==(Object other) =>
      other is LumeCaptureResult &&
      other.outcome == outcome &&
      other.bytes == bytes &&
      other.mimeType == mimeType;

  @override
  int get hashCode => Object.hash(outcome, bytes, mimeType);

  @override
  String toString() => 'LumeCaptureResult(${outcome.name}, $mimeType)';
}

/// Captures or chooses a document photo. Asks for the camera or the photos
/// only when called.
abstract interface class LumeDocumentCamera {
  /// Opens the camera and hands back the photo taken.
  Future<LumeCaptureResult> capture();

  /// Lets the reader choose one image from the gallery.
  Future<LumeCaptureResult> pickImage();

  /// Whether Settings can change a camera [outcome], and this camera can open
  /// Lume's page there.
  bool offersSettings(LumeCaptureOutcome outcome);

  /// Opens Lume's own page in Settings; false if it did not open.
  Future<bool> openSettings();
}

/// A camera for a platform with no capture adapter. It never reaches the
/// platform.
class LumeUnavailableDocumentCamera implements LumeDocumentCamera {
  const LumeUnavailableDocumentCamera();

  @override
  Future<LumeCaptureResult> capture() async =>
      const LumeCaptureResult.unavailable();

  @override
  Future<LumeCaptureResult> pickImage() async =>
      const LumeCaptureResult.unavailable();

  @override
  bool offersSettings(LumeCaptureOutcome outcome) => false;

  @override
  Future<bool> openSettings() async => false;
}

/// Records every request and answers with [result]. Never touches the
/// platform.
class LumeRecordingDocumentCamera implements LumeDocumentCamera {
  LumeRecordingDocumentCamera({
    this.result = const LumeCaptureResult.unavailable(),
    this.settings = const <LumeCaptureOutcome>{},
    this.settingsOpen = true,
  });

  /// What the next request answers.
  LumeCaptureResult result;

  /// The outcomes it offers Settings for.
  Set<LumeCaptureOutcome> settings;

  /// What opening Settings answers.
  bool settingsOpen;

  /// `capture`, `pickImage` and `openSettings`, in the order they were asked
  /// for.
  final List<String> requested = <String>[];

  @override
  Future<LumeCaptureResult> capture() async {
    requested.add('capture');
    return result;
  }

  @override
  Future<LumeCaptureResult> pickImage() async {
    requested.add('pickImage');
    return result;
  }

  @override
  bool offersSettings(LumeCaptureOutcome outcome) => settings.contains(outcome);

  @override
  Future<bool> openSettings() async {
    requested.add('openSettings');
    return settingsOpen;
  }
}

/// Reading a code with the camera, or from an image — through a contract.
///
/// The reference's Scan says "Scanning" and From gallery says "Choosing an
/// image", and neither does anything more. Lume reaches the camera and the
/// photo picker only through this contract, and says what actually happened
/// (C78, C80):
///
/// * a [LumeScanner] reports a [LumeScanResult]; the screen says it;
/// * the camera is asked for only by a press, never at launch, and a refusal
///   is explained rather than asked again;
/// * a read code is only ever *text*: what it is and where it would go is
///   decided by `LumeQrPayload`, and nothing is opened without a second press;
/// * `LumePlatformScanner` (`lume_scanner_platform.dart`) is the device
///   adapter, the one file that knows which packages scan;
/// * [LumeUnavailableScanner] never touches a device, and
///   [LumeRecordingScanner] records instead, for tests.
library;

import 'package:flutter/foundation.dart';

/// What became of one request to read a code.
enum LumeScanOutcome {
  /// A QR code was read; [LumeScanResult.value] holds its text.
  read,

  /// The image was opened and no code was in it.
  nothing,

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
  /// ask again (C80): Scan may ask, and Settings certainly can.
  undetermined,

  /// Nothing on this device can scan: no camera, or no scanner on this
  /// platform.
  unavailable,

  /// The camera would not start, or the platform threw.
  failed,

  /// The image holds more than one QR code, and Lume will not guess which
  /// the reader meant.
  multiple,

  /// A code was found, and it is not a QR code.
  unsupported,

  /// The image could not be decoded, or the code in it is damaged.
  unreadable,

  /// The image is larger than Lume will decode on the device.
  tooLarge,
}

@immutable
class LumeScanResult {
  const LumeScanResult(this.outcome, [this.value]);

  const LumeScanResult.unavailable()
    : outcome = LumeScanOutcome.unavailable,
      value = null;

  final LumeScanOutcome outcome;

  /// The code's text, when [outcome] is [LumeScanOutcome.read].
  final String? value;

  @override
  bool operator ==(Object other) =>
      other is LumeScanResult &&
      other.outcome == outcome &&
      other.value == value;

  @override
  int get hashCode => Object.hash(outcome, value);

  @override
  String toString() => 'LumeScanResult(${outcome.name}, $value)';
}

/// Reads a code. Asks for the camera or the photos only when called.
abstract interface class LumeScanner {
  /// Opens the camera and reads the first QR code it sees.
  Future<LumeScanResult> scan();

  /// Lets the reader choose one image and reads the QR code in it.
  Future<LumeScanResult> pickImage();

  /// Whether Settings can change a camera [outcome], and this scanner can
  /// open Lume's page there.
  bool offersSettings(LumeScanOutcome outcome);

  /// Opens Lume's own page in Settings; false if it did not open.
  Future<bool> openSettings();
}

/// A scanner for a platform with no camera adapter. It never reaches the
/// platform.
class LumeUnavailableScanner implements LumeScanner {
  const LumeUnavailableScanner();

  @override
  Future<LumeScanResult> scan() async => const LumeScanResult.unavailable();

  @override
  Future<LumeScanResult> pickImage() async =>
      const LumeScanResult.unavailable();

  @override
  bool offersSettings(LumeScanOutcome outcome) => false;

  @override
  Future<bool> openSettings() async => false;
}

/// Records every request and answers with [result]. Never touches the
/// platform.
class LumeRecordingScanner implements LumeScanner {
  LumeRecordingScanner({
    this.result = const LumeScanResult.unavailable(),
    this.settings = const <LumeScanOutcome>{},
    this.settingsOpen = true,
  });

  /// What the next request answers.
  LumeScanResult result;

  /// The outcomes it offers Settings for.
  Set<LumeScanOutcome> settings;

  /// What opening Settings answers.
  bool settingsOpen;

  /// `scan`, `pickImage` and `openSettings`, in the order they were asked for.
  final List<String> requested = <String>[];

  @override
  Future<LumeScanResult> scan() async {
    requested.add('scan');
    return result;
  }

  @override
  Future<LumeScanResult> pickImage() async {
    requested.add('pickImage');
    return result;
  }

  @override
  bool offersSettings(LumeScanOutcome outcome) => settings.contains(outcome);

  @override
  Future<bool> openSettings() async {
    requested.add('openSettings');
    return settingsOpen;
  }
}

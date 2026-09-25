/// Reading a raw photo for Passport Photos, through a contract — the same
/// shape `LumeScanner` (`core/platform/lume_scanner.dart`) already gives QR's
/// camera and gallery access (C80), but handing back the untouched image
/// bytes a QR scanner decodes and discards rather than a decoded code.
///
/// Kept inside this feature rather than added to `app/providers/
/// platform_services.dart`: this build is confined to `lib/features/passport/`
/// alone, so [LumePassportPhotoSource] is its own small contract, wired by
/// its own provider (`passport_providers.dart`), not a change to the shared
/// platform-services file every other tool also depends on.
///
/// * a [LumePassportPhotoSource] reports a [LumePassportPhotoResult]; the
///   tool says what actually happened, exactly as QR does;
/// * the camera and the photo library are asked for only by a press, never
///   at launch;
/// * `LumePlatformPassportPhotoSource` (`data/passport_photo_platform.dart`)
///   is the device adapter;
/// * [LumeUnavailablePassportPhotoSource] never touches a device, and
///   [LumeRecordingPassportPhotoSource] records instead, for tests.
library;

import 'package:flutter/foundation.dart';

/// What became of one request for a photo.
enum LumePassportPhotoOutcome {
  /// A photo was captured or chosen; [LumePassportPhotoResult.bytes] holds
  /// its untouched bytes.
  captured,

  /// The reader closed the camera, or chose no image. Not a failure.
  cancelled,

  /// The reader refused the camera or the photos, and the platform will ask
  /// again next time.
  denied,

  /// Refused for good ("don't ask again", or a second refusal): only
  /// Settings can change it.
  blocked,

  /// A device policy has turned the camera off. Settings cannot change it.
  restricted,

  /// Refused, and the platform does not say whether it will ask again.
  undetermined,

  /// Nothing on this device can do this — no camera, or no picker.
  unavailable,

  /// The camera or the picker would not open, or threw.
  failed,

  /// The chosen file is larger than Lume will decode on the device.
  tooLarge,
}

@immutable
class LumePassportPhotoResult {
  const LumePassportPhotoResult(this.outcome, [this.bytes]);

  const LumePassportPhotoResult.unavailable()
    : outcome = LumePassportPhotoOutcome.unavailable,
      bytes = null;

  final LumePassportPhotoOutcome outcome;

  /// The photo's own bytes, exactly as the camera or the picker handed them
  /// over, when [outcome] is [LumePassportPhotoOutcome.captured].
  final Uint8List? bytes;

  @override
  bool operator ==(Object other) =>
      other is LumePassportPhotoResult &&
      other.outcome == outcome &&
      listEquals(other.bytes, bytes);

  @override
  int get hashCode =>
      Object.hash(outcome, bytes == null ? null : Object.hashAll(bytes!));

  @override
  String toString() =>
      'LumePassportPhotoResult(${outcome.name}, '
      '${bytes == null ? 'no bytes' : '${bytes!.length} bytes'})';
}

/// Reads a photo. Asks for the camera or the photos only when called.
abstract interface class LumePassportPhotoSource {
  /// Opens the camera and hands back what was taken.
  Future<LumePassportPhotoResult> capture();

  /// Lets the reader choose one image from their photos.
  Future<LumePassportPhotoResult> pickImage();

  /// Whether Settings can change a camera [outcome], and this source can
  /// open Lume's page there.
  bool offersSettings(LumePassportPhotoOutcome outcome);

  /// Opens Lume's own page in Settings; false if it did not open.
  Future<bool> openSettings();
}

/// A source for a platform with no camera or picker adapter. It never
/// reaches the platform.
class LumeUnavailablePassportPhotoSource implements LumePassportPhotoSource {
  const LumeUnavailablePassportPhotoSource();

  @override
  Future<LumePassportPhotoResult> capture() async =>
      const LumePassportPhotoResult.unavailable();

  @override
  Future<LumePassportPhotoResult> pickImage() async =>
      const LumePassportPhotoResult.unavailable();

  @override
  bool offersSettings(LumePassportPhotoOutcome outcome) => false;

  @override
  Future<bool> openSettings() async => false;
}

/// Records every request and answers with [result]. Never touches the
/// platform.
class LumeRecordingPassportPhotoSource implements LumePassportPhotoSource {
  LumeRecordingPassportPhotoSource({
    this.result = const LumePassportPhotoResult.unavailable(),
    this.settings = const <LumePassportPhotoOutcome>{},
    this.settingsOpen = true,
  });

  /// What the next request answers.
  LumePassportPhotoResult result;

  /// The outcomes it offers Settings for.
  Set<LumePassportPhotoOutcome> settings;

  /// What opening Settings answers.
  bool settingsOpen;

  /// `capture`, `pickImage` and `openSettings`, in the order they were asked
  /// for.
  final List<String> requested = <String>[];

  @override
  Future<LumePassportPhotoResult> capture() async {
    requested.add('capture');
    return result;
  }

  @override
  Future<LumePassportPhotoResult> pickImage() async {
    requested.add('pickImage');
    return result;
  }

  @override
  bool offersSettings(LumePassportPhotoOutcome outcome) =>
      settings.contains(outcome);

  @override
  Future<bool> openSettings() async {
    requested.add('openSettings');
    return settingsOpen;
  }
}

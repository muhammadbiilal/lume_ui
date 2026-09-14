/// Reading a code with the camera, or from an image — through a contract.
///
/// The reference's Scan says "Scanning" and From gallery says "Choosing an
/// image", and neither does anything more. Lume reaches the camera only
/// through this contract, and says what actually happened (C78):
///
/// * a [LumeScanner] reports a [LumeScanResult]; the screen says it —
///   read, nothing found, permission refused, unavailable, failed;
/// * the camera is asked for only by a press, never at launch, and a refusal
///   is explained rather than asked again;
/// * [LumeUnavailableScanner] is this build's scanner: no camera package is
///   chosen yet, so it answers "unavailable" and never touches the device;
/// * [LumeRecordingScanner] records instead, for tests.
library;

import 'package:flutter/foundation.dart';

/// What became of one request to read a code.
enum LumeScanOutcome {
  /// A code was read; [LumeScanResult.value] holds its text.
  read,

  /// The camera looked, or the image was opened, and no code was in it.
  nothing,

  /// The reader refused the camera or the photo library.
  denied,

  /// Nothing on this device, or in this build, can scan.
  unavailable,

  /// The platform was asked and threw.
  failed,
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
}

/// Reads a code. Asks for the camera or the photo library only when called.
abstract interface class LumeScanner {
  /// Opens the camera and reads the first code it sees.
  Future<LumeScanResult> scan();

  /// Lets the reader choose an image and reads a code in it.
  Future<LumeScanResult> pickImage();
}

/// This build's scanner: unavailable until a camera package and its
/// permission wording are decided. It never reaches the platform.
class LumeUnavailableScanner implements LumeScanner {
  const LumeUnavailableScanner();

  @override
  Future<LumeScanResult> scan() async => const LumeScanResult.unavailable();

  @override
  Future<LumeScanResult> pickImage() async =>
      const LumeScanResult.unavailable();
}

/// Records every request and answers with [result]. Never touches the
/// platform.
class LumeRecordingScanner implements LumeScanner {
  LumeRecordingScanner({this.result = const LumeScanResult.unavailable()});

  /// What the next request answers.
  LumeScanResult result;

  /// `scan` and `pickImage`, in the order they were asked for.
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
}

/// How a card reaches Pictures on Android: Lume's own MediaStore channel (C81).
///
/// `LumeImageSaver.kt` writes the PNG bytes as they are — `DISPLAY_NAME`
/// ending `.png`, `MIME_TYPE` `image/png`, `RELATIVE_PATH` Pictures,
/// `IS_PENDING` while writing, a taken name renamed by MediaStore, an
/// unfinished row deleted — on Android 10 and later with no permission. On
/// Android 7–9 it asks for `WRITE_EXTERNAL_STORAGE` (declared only up to
/// API 28), writes a new file and waits for the media scanner.
///
/// Saved is said only when the channel reports a published row whose name
/// ends `.png` and whose type is `image/png` — anything else is a failure, so
/// a row the platform re-typed is never called saved.
library;

import 'package:flutter/services.dart';

import 'lume_image_saver_platform.dart';
import 'lume_share.dart';

/// `--dart-define=LUME_SIMULATE_SAVE_FAILURE=true` fails the write after the
/// row is made, so cleanup can be seen on a device. The native side honours it
/// only in a debuggable build; a release never compiles it in.
const bool kLumeSimulateSaveFailure = bool.fromEnvironment(
  'LUME_SIMULATE_SAVE_FAILURE',
);

class LumeMediaStoreImageSaver implements LumeImageSaver {
  const LumeMediaStoreImageSaver({
    MethodChannel channel = const MethodChannel('lume/image_saver'),
    DateTime Function() now = DateTime.now,
    bool simulateFailure = kLumeSimulateSaveFailure,
  }) : _channel = channel,
       _now = now,
       _simulateFailure = simulateFailure;

  final MethodChannel _channel;
  final DateTime Function() _now;
  final bool _simulateFailure;

  static const String mime = 'image/png';

  @override
  Future<LumeSaveOutcome> saveImage(
    Uint8List png, {
    required String fileName,
  }) async {
    if (!LumePngFile.isPng(png)) return LumeSaveOutcome.failed;
    final Map<Object?, Object?>? r;
    try {
      r = await _channel
          .invokeMapMethod<Object?, Object?>('savePng', <String, Object?>{
            'bytes': png,
            'name': LumePngFile.nameFor(fileName, _now()),
            'simulateFailure': _simulateFailure,
          });
    } on MissingPluginException {
      return LumeSaveOutcome.unavailable;
    } on PlatformException {
      return LumeSaveOutcome.failed;
    }
    return switch (r?['outcome']) {
      'saved'
          when r?['mime'] == mime &&
              (r?['name'] as String? ?? '').endsWith('.png') &&
              r?['uri'] != null =>
        LumeSaveOutcome.saved,
      'denied' => LumeSaveOutcome.denied,
      'noSpace' => LumeSaveOutcome.noSpace,
      _ => LumeSaveOutcome.failed,
    };
  }
}

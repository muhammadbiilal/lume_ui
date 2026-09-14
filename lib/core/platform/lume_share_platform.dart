/// The one file that knows how a card or a file leaves the device.
///
/// `share_plus` opens the platform's share sheet with an in-memory file — no
/// temporary file of Lume's, no storage permission — and reports what the
/// sheet reported. The dependency is justified in `pubspec.yaml` and reaches
/// nothing else in the app (D7).
library;

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'lume_export.dart';
import 'lume_share.dart';

/// Opens the share sheet. A parameter so the adapter's mapping can be tested
/// without a platform.
typedef LumeShareSheet = Future<ShareResultStatus> Function(ShareParams params);

Future<ShareResultStatus> _sheet(ShareParams params) async =>
    (await SharePlus.instance.share(params)).status;

class LumePlatformSharer implements LumeSharer {
  const LumePlatformSharer({LumeShareSheet sheet = _sheet}) : _open = sheet;

  final LumeShareSheet _open;

  @override
  Future<LumeShareOutcome> shareImage(
    Uint8List png, {
    required String fileName,
    required String caption,
  }) async {
    try {
      // "The image is the primary artifact, with text only as a caption."
      final ShareResultStatus status = await _open(
        ShareParams(
          files: <XFile>[
            XFile.fromData(png, mimeType: 'image/png', name: fileName),
          ],
          fileNameOverrides: <String>[fileName],
          text: caption,
        ),
      );
      return switch (status) {
        ShareResultStatus.success => LumeShareOutcome.shared,
        ShareResultStatus.dismissed => LumeShareOutcome.dismissed,
        ShareResultStatus.unavailable => LumeShareOutcome.unavailable,
      };
    } on MissingPluginException {
      return LumeShareOutcome.unavailable;
    } on PlatformException {
      return LumeShareOutcome.failed;
    }
  }
}

/// Export through the same sheet: on a phone, "Save to Files", Drive and mail
/// are destinations of the share sheet, and a download folder is not a place a
/// reader can find again. [LumeExportOutcome.saved] only when the reader chose
/// one.
class LumePlatformExporter implements LumeExporter {
  const LumePlatformExporter({LumeShareSheet sheet = _sheet}) : _open = sheet;

  final LumeShareSheet _open;

  @override
  Future<LumeExportOutcome> export(LumeExportFile file) async {
    try {
      final ShareResultStatus status = await _open(
        ShareParams(
          files: <XFile>[
            XFile.fromData(
              file.bytes,
              mimeType: file.mimeType,
              name: file.fileName,
            ),
          ],
          fileNameOverrides: <String>[file.fileName],
        ),
      );
      return switch (status) {
        ShareResultStatus.success => LumeExportOutcome.saved,
        ShareResultStatus.dismissed => LumeExportOutcome.cancelled,
        ShareResultStatus.unavailable => LumeExportOutcome.unavailable,
      };
    } on MissingPluginException {
      return LumeExportOutcome.unavailable;
    } on PlatformException {
      return LumeExportOutcome.failed;
    }
  }
}

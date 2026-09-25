/// Sharing captured pages as what they actually are — a variant of D7's own
/// rule, adapted for a file [LumeSharer] cannot honestly carry.
///
/// [LumeSharer] (`lume_share.dart`) hands the platform's share sheet exactly
/// one PNG, typed `image/png` unconditionally — right for a rendered share
/// card, which is always a PNG Lume drew. A document capture is never that:
/// the camera hands back a JPEG (`image_picker`'s own format), and a chosen
/// gallery file is whatever it already was. Sharing either through
/// [LumeSharer] would either misname a JPEG "image/png" or force a re-encode
/// this codebase has no package for — `pubspec.yaml` carries no
/// image-processing dependency, and none is added here.
///
/// This opens the same `share_plus` door (`lume_share_platform.dart` does,
/// for the same package already pinned there) directly instead: honest about
/// each page's own MIME type, and able to carry more than one file in the one
/// sheet, which [LumeSharer]'s single-image contract cannot.
library;

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'document_page.dart';

/// What became of sharing one or more pages.
enum LumeDocShareOutcome {
  /// The reader chose a destination.
  shared,

  /// The reader closed the sheet.
  dismissed,

  /// This platform cannot share, or cannot say what happened.
  unavailable,

  /// The platform threw.
  failed,
}

abstract interface class LumeDocumentSharer {
  /// Hands [pages] to the platform's share sheet as a set of files, each
  /// named and typed as it actually is. Never called with an empty list.
  Future<LumeDocShareOutcome> share(List<LumeDocumentPage> pages);
}

class LumePlatformDocumentSharer implements LumeDocumentSharer {
  const LumePlatformDocumentSharer();

  @override
  Future<LumeDocShareOutcome> share(List<LumeDocumentPage> pages) async {
    if (pages.isEmpty) return LumeDocShareOutcome.failed;
    try {
      final ShareResultStatus status = (await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[
            for (final LumeDocumentPage p in pages)
              XFile.fromData(p.bytes, mimeType: p.mimeType, name: p.fileName),
          ],
          fileNameOverrides: <String>[
            for (final LumeDocumentPage p in pages) p.fileName,
          ],
        ),
      )).status;
      return switch (status) {
        ShareResultStatus.success => LumeDocShareOutcome.shared,
        ShareResultStatus.dismissed => LumeDocShareOutcome.dismissed,
        ShareResultStatus.unavailable => LumeDocShareOutcome.unavailable,
      };
    } on MissingPluginException {
      return LumeDocShareOutcome.unavailable;
    } on PlatformException {
      return LumeDocShareOutcome.failed;
    }
  }
}

/// Records each request and never touches the platform.
class LumeRecordingDocumentSharer implements LumeDocumentSharer {
  LumeRecordingDocumentSharer({this.outcome = LumeDocShareOutcome.shared});

  LumeDocShareOutcome outcome;
  final List<List<LumeDocumentPage>> shared = <List<LumeDocumentPage>>[];

  @override
  Future<LumeDocShareOutcome> share(List<LumeDocumentPage> pages) async {
    shared.add(pages);
    return outcome;
  }
}

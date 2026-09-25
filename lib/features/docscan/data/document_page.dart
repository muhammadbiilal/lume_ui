/// One captured page — session-only.
///
/// Nothing here survives the tool closing, and nothing here is a fixture:
/// every field is exactly what the reader's own capture or gallery choice
/// produced (§29; see the wave report's `LumeDataCapability.inputOnly`
/// reasoning for docscan). There is no persisted "history" across sessions —
/// only this run's own pages, which is what makes them honest to show at
/// all.
library;

import 'package:flutter/foundation.dart';

@immutable
class LumeDocumentPage {
  const LumeDocumentPage({
    required this.id,
    required this.bytes,
    required this.mimeType,
    required this.capturedAt,
    required this.fromGallery,
  });

  /// Unique within one session. The clock a test runs on is pinned and does
  /// not advance between two captures, so this is a counter the caller owns
  /// — never the instant, which several pages can honestly share.
  final String id;

  final Uint8List bytes;

  /// What [bytes] actually is — `image/jpeg` from the camera, or whatever the
  /// chosen gallery file already was. Never assumed to be PNG: that is what a
  /// shared file has to be honest about (D7, `document_sharer.dart`).
  final String mimeType;

  final DateTime capturedAt;

  /// Whether this page came from "From gallery" rather than a fresh capture
  /// — the row's own meta line says which.
  final bool fromGallery;

  String get _extension => switch (mimeType) {
    'image/png' => 'png',
    'image/heic' => 'heic',
    'image/webp' => 'webp',
    _ => 'jpg',
  };

  /// `lume-docscan-<yyyyMMdd-HHmmss>-<id>.<ext>` — named the way a saved
  /// share card is (`LumePngFile.nameFor`), with the id kept so two pages
  /// captured in the same second (the pinned fixture clock never advances at
  /// all) still leave the share sheet with two distinct file names.
  String get fileName {
    String two(int n) => n.toString().padLeft(2, '0');
    final DateTime t = capturedAt;
    return 'lume-docscan-${t.year}${two(t.month)}${two(t.day)}-'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}-$id.$_extension';
  }
}

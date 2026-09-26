/// Media Saver's library — `context.js` `savedMedia()`, typed, with the
/// reference's own figures beside it (`182 MB` used, last saved today).
///
/// All of it is sample data, and the source line says so. The reference
/// fetches nothing either: "Fetch" is `toast:` "Fetching media".
///
/// **Dayroz obligation:** a real saver needs a network client to fetch the
/// linked media, a store for what was saved (with its real size and date),
/// and the platform's gallery or files to hand it to.
library;

import 'package:flutter/foundation.dart';

import '../../../core/widgets/lume/lume_art.dart';

enum LumeSavedMediaKind { video, photo, audio }

@immutable
class LumeSavedMedia {
  const LumeSavedMedia({
    required this.kind,
    required this.tone,
    required this.glyph,
    required this.megabytes,
  });

  final LumeSavedMediaKind kind;
  final LumeArtTone tone;
  final String glyph;
  final double megabytes;
}

abstract final class LumeMediaSaverFixtures {
  static const List<LumeSavedMedia> library = <LumeSavedMedia>[
    LumeSavedMedia(
      kind: LumeSavedMediaKind.video,
      tone: LumeArtTone.violet,
      glyph: '🎬',
      megabytes: 18,
    ),
    LumeSavedMedia(
      kind: LumeSavedMediaKind.photo,
      tone: LumeArtTone.accent,
      glyph: '📷',
      megabytes: 3.2,
    ),
    LumeSavedMedia(
      kind: LumeSavedMediaKind.audio,
      tone: LumeArtTone.amber,
      glyph: '🎵',
      megabytes: 6.8,
    ),
  ];

  /// `'182 ' + c.t('unit.mb')` — the reference's own storage figure.
  static const int storageMegabytes = 182;
}

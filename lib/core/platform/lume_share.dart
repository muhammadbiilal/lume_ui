/// What leaves Lume as a picture, and the one door it leaves by (D7).
///
/// `share-cards.js` draws a 1080 × 1350 card — the words, their source, the
/// Lume footer — and offers **Share** and **Save image**. The reference toasts
/// "Shared" and "Image saved" whether or not anything happened; Lume says them
/// only when the platform reports it.
///
/// * [LumeShareCard] is the typed content: a kind (which picks the colourway),
///   the words, an optional Arabic line, and the source that makes a shared
///   figure honest — a number never leaves without its place and moment.
/// * [LumeSharer] hands a rendered PNG to the platform's share sheet;
///   [LumeImageSaver] puts it in the photo library.
/// * [LumeRecordingSharer] and [LumeRecordingImageSaver] record and never touch
///   the platform — every test, and the fixture build, use them.
///
/// **Privacy rule.** A card is refused for a sensitive tool ([forFeature]):
/// health, documents, cycle and the rest never become an image that can be
/// forwarded, whatever a tool asks for.
library;

import 'package:flutter/foundation.dart';

/// `THEMES` — which colourway a card is drawn in.
enum LumeShareKind { quran, hadith, dua, quote, reminder }

@immutable
class LumeShareCard {
  const LumeShareCard._({
    required this.kind,
    required this.text,
    required this.source,
    this.arabic,
  });

  /// `null` when the content cannot honestly be a card: empty words, no
  /// source, or more than [maxText] characters (the card would overflow its
  /// 1350-point height rather than wrap).
  static LumeShareCard? tryCreate({
    required LumeShareKind kind,
    required String text,
    required String source,
    String? arabic,
  }) {
    final String t = text.trim();
    final String s = source.trim();
    final String? a = arabic?.trim();
    if (t.isEmpty || s.isEmpty) return null;
    if (t.length > maxText || s.length > maxSource) return null;
    if (a != null && (a.isEmpty || a.length > maxText)) return null;
    return LumeShareCard._(kind: kind, text: t, source: s, arabic: a);
  }

  /// A card for [sensitive] content is never made.
  static LumeShareCard? forFeature({
    required bool sensitive,
    required LumeShareKind kind,
    required String text,
    required String source,
    String? arabic,
  }) => sensitive
      ? null
      : tryCreate(kind: kind, text: text, source: source, arabic: arabic);

  static const int maxText = 280;
  static const int maxSource = 120;

  final LumeShareKind kind;
  final String text;
  final String source;
  final String? arabic;

  /// `lume-<kind>.png` — `a.download` in the reference.
  String get fileName => 'lume-${kind.name}.png';

  /// The caption that travels with the image — `text + ' — ' + source`.
  String get caption => '$text — $source';

  @override
  bool operator ==(Object other) =>
      other is LumeShareCard &&
      other.kind == kind &&
      other.text == text &&
      other.source == source &&
      other.arabic == arabic;

  @override
  int get hashCode => Object.hash(kind, text, source, arabic);
}

/// What became of a share.
enum LumeShareOutcome {
  /// The reader chose a destination.
  shared,

  /// The reader closed the sheet.
  dismissed,

  /// This platform cannot share, or cannot say what happened.
  unavailable,

  /// The platform threw.
  failed,
}

/// What became of a save.
enum LumeSaveOutcome {
  saved,

  /// The reader refused the photo library.
  denied,

  /// Nothing on this build can save an image (see [LumeUnavailableImageSaver]).
  unavailable,
  failed,
}

/// Hands a rendered card to the platform's share sheet.
abstract interface class LumeSharer {
  Future<LumeShareOutcome> shareImage(
    Uint8List png, {
    required String fileName,
    required String caption,
  });
}

/// Puts a rendered card in the photo library.
abstract interface class LumeImageSaver {
  Future<LumeSaveOutcome> saveImage(Uint8List png, {required String fileName});
}

/// One recorded request.
@immutable
class LumeSharedImage {
  const LumeSharedImage(this.png, this.fileName, this.caption);

  final Uint8List png;
  final String fileName;
  final String? caption;
}

class LumeRecordingSharer implements LumeSharer {
  LumeRecordingSharer({this.outcome = LumeShareOutcome.shared});

  LumeShareOutcome outcome;
  final List<LumeSharedImage> shared = <LumeSharedImage>[];

  @override
  Future<LumeShareOutcome> shareImage(
    Uint8List png, {
    required String fileName,
    required String caption,
  }) async {
    shared.add(LumeSharedImage(png, fileName, caption));
    return outcome;
  }
}

class LumeRecordingImageSaver implements LumeImageSaver {
  LumeRecordingImageSaver({this.outcome = LumeSaveOutcome.saved});

  LumeSaveOutcome outcome;
  final List<LumeSharedImage> saved = <LumeSharedImage>[];

  @override
  Future<LumeSaveOutcome> saveImage(
    Uint8List png, {
    required String fileName,
  }) async {
    saved.add(LumeSharedImage(png, fileName, null));
    return outcome;
  }
}

/// The production saver until the photo-library permission is decided.
///
/// Saving to the gallery needs Android's `WRITE_EXTERNAL_STORAGE` below
/// API 30 and iOS's photo-library usage strings — a permission and user-data
/// decision this phase does not take. Until it is taken, Save image says it
/// cannot save rather than pretending it did (D7); Share still offers the
/// platform's own "Save image" destination.
class LumeUnavailableImageSaver implements LumeImageSaver {
  const LumeUnavailableImageSaver();

  @override
  Future<LumeSaveOutcome> saveImage(
    Uint8List png, {
    required String fileName,
  }) async => LumeSaveOutcome.unavailable;
}

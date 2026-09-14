/// Religious text, carried as a source gives it — never as this app wrote it.
///
/// F6B decision: a hadith, its narrator, its collection, its numbering and any
/// commentary are not machine-translated, reverse-translated or invented. A
/// passage is shown in a language only when a verified translation into that
/// language exists; otherwise its verified fallback is shown and labelled as
/// such, so English content is never presented as Urdu or Arabic.
///
/// The standalone reference holds only the reference's English
/// (`LumeHadithFixtures`), with no original and no translation. **Dayroz
/// obligation:** a licensed, verified hadith source — authenticated Arabic
/// originals, verified Urdu and English translations, collection numbering
/// and grading preserved, licences and attribution recorded, and one record
/// identity across languages.
library;

import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';

/// A language a religious text is held in, by BCP-47 code.
@immutable
class LumeContentLanguage {
  const LumeContentLanguage(this.code);

  static const LumeContentLanguage arabic = LumeContentLanguage('ar');
  static const LumeContentLanguage english = LumeContentLanguage('en');
  static const LumeContentLanguage urdu = LumeContentLanguage('ur');

  final String code;

  static const Set<String> _rtl = <String>{'ar', 'ur', 'fa', 'he', 'ps', 'sd'};

  /// The text's own direction — which, for a fallback, is not the
  /// interface's.
  bool get isRightToLeft => _rtl.contains(code);

  Locale get locale => Locale(code);

  @override
  bool operator ==(Object other) =>
      other is LumeContentLanguage && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}

/// A translation, and who verified it.
@immutable
class LumeVerifiedTranslation {
  const LumeVerifiedTranslation({
    required this.language,
    required this.text,
    required this.translator,
  });

  final LumeContentLanguage language;
  final String text;

  /// The translator or edition, as the source credits it.
  final String translator;
}

/// Who publishes the text, under what licence, at which version.
@immutable
class LumeContentAttribution {
  const LumeContentAttribution({
    required this.publisher,
    required this.sourceVersion,
    this.licence,
  });

  /// "Sunnah.com", a printed edition — as the source names itself.
  final String publisher;

  /// The source's own version or edition identifier, so a record can be
  /// traced to exactly what was imported.
  final String sourceVersion;

  /// `null` where no licence has been recorded — which the standalone
  /// reference's fixtures are, and which a release must not ship.
  final String? licence;
}

/// One hadith, as a source holds it.
@immutable
class LumeHadithRecord {
  const LumeHadithRecord({
    required this.id,
    required this.collection,
    required this.number,
    required this.narrator,
    required this.attribution,
    this.book,
    this.chapter,
    this.grading,
    this.originalLanguage,
    this.originalText,
    this.translations = const <LumeVerifiedTranslation>[],
    this.fallback,
  });

  /// One identity across every language this hadith is held in.
  final String id;

  /// The collection, as cited: "Sahih Muslim".
  final String collection;

  /// The number within the collection, as the source numbers it — a string,
  /// because numbering schemes differ between editions.
  final String number;

  final String? book;
  final String? chapter;
  final String narrator;

  /// The grading, only where the source states one.
  final String? grading;

  /// The original, only where the source holds it. Never produced here.
  final LumeContentLanguage? originalLanguage;
  final String? originalText;

  final List<LumeVerifiedTranslation> translations;

  /// The verified text shown when no translation into the reader's language
  /// exists — the reference's English in this build.
  final LumeVerifiedTranslation? fallback;

  final LumeContentAttribution attribution;

  /// What to show a reader of [language], and whether it is in that language.
  LumeResolvedPassage? resolve(LumeContentLanguage language) {
    if (originalLanguage == language && originalText != null) {
      return LumeResolvedPassage(
        text: originalText!,
        language: language,
        isFallback: false,
      );
    }
    for (final LumeVerifiedTranslation t in translations) {
      if (t.language == language) {
        return LumeResolvedPassage(
          text: t.text,
          language: t.language,
          isFallback: false,
        );
      }
    }
    final LumeVerifiedTranslation? f = fallback;
    if (f == null) return null;
    return LumeResolvedPassage(
      text: f.text,
      language: f.language,
      // The fallback *is* the reader's language when they read English.
      isFallback: f.language != language,
    );
  }
}

/// A passage chosen for a reader, with the language it is actually in.
@immutable
class LumeResolvedPassage {
  const LumeResolvedPassage({
    required this.text,
    required this.language,
    required this.isFallback,
  });

  final String text;

  /// The language the text *is* in — which, for a fallback, is not the
  /// reader's. A screen sets direction and labels from this, never from the
  /// interface locale.
  final LumeContentLanguage language;

  /// True when no verified translation into the reader's language exists.
  final bool isFallback;
}

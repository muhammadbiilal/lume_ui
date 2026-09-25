/// One of the 99 Names of Allah, as the reference holds it.
///
/// `assets/js/data/tool-data.js:663-676` — `NAMES99`. Each entry carries four
/// things and only those four: its place in the traditional list of 99, the
/// Arabic script, a transliteration, and a plain English gloss of what the
/// name means.
///
/// The gloss is modelled through the same [LumeVerifiedTranslation] contract
/// `religious_content.dart` gives Hadith (C82): a translation is credited to
/// whoever the source credits it to, and nothing is asserted in a language no
/// verified text has reached. The reference holds only its own English, so
/// [meaning] is that English, credited to the fixture edition — not a
/// verified translation into any language, and not presented as one.
library;

import 'package:flutter/foundation.dart';

import '../../hadith/domain/religious_content.dart';

/// One name — `{ n, ar, tl, meaning }` in the source.
@immutable
class LumeName {
  const LumeName({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.meaning,
  });

  /// `n` — this name's place in the traditional list of 99. Not this
  /// fixture's index: the source numbers Ar-Rahman 1 through Al-Bari 12, and
  /// that numbering is kept exactly, with no renumbering to fill the gap left
  /// by the 87 the source does not hold.
  final int number;

  /// `ar` — Arabic script, as the source holds it. Data, not a string to be
  /// translated: it reads right to left in every interface language.
  final String arabic;

  /// `tl` — how the name is written in Latin script.
  final String transliteration;

  /// `meaning` — the reference's own English gloss, modelled as a translation
  /// of the name so it resolves through the shared contract. No other
  /// language is recorded, so [resolve] never claims a verified Arabic,
  /// Urdu or any other rendering that does not exist in this build.
  final LumeVerifiedTranslation meaning;

  /// What to show a reader of [language]: the meaning verbatim when they read
  /// English, or the same English again, labelled as a fallback — the same
  /// shape [LumeHadithRecord.resolve] gives Hadith, with no original-language
  /// branch because a name's Arabic is shown on its own, not as a resolved
  /// passage.
  LumeResolvedPassage resolve(LumeContentLanguage language) =>
      LumeResolvedPassage(
        text: meaning.text,
        language: meaning.language,
        isFallback: meaning.language != language,
      );
}

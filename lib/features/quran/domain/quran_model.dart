/// The Qur'an the reader opens on — `tool-data.js` `SURAHS` and `AYAT`, and
/// the day's ayah `context.js` `dayIndex` chooses.
///
/// The Qur'an is not this app's to write. Its Arabic is kept exactly as the
/// reference gives it, in every language: not altered, abridged or reworded.
/// A translation of it has to come from a verified, licensed edition, so the
/// reference's own English is carried here credited as what it is — the web
/// reference's unverified rendering, never a licensed translation — the same
/// honesty C82 gives Hadith, extended to scripture (D12, C77, C82). A
/// transliteration is not scripture and needs no such licence; it is kept as
/// its own field, shown as the reference gives it, in every language.
///
/// The standalone reference holds only twelve of the mushaf's 114 surahs and
/// three of its 6,236 ayat — exactly what `tool-data.js` holds, no more.
/// **Dayroz obligation:** a licensed, verified mushaf source — the complete
/// 114 surahs, the complete text, verified translations into every
/// supported language with their translators recorded, and licences and
/// attribution kept — before this build can call itself a Qur'an reader
/// rather than a fixture of one.
library;

import '../../hadith/domain/religious_content.dart';

/// Where a surah was revealed, as the reference labels it.
enum LumeSurahPlace { meccan, medinan }

/// One surah's catalogue entry — `SURAHS`. Twelve of the mushaf's 114:
/// exactly the reference's own subset, ported rather than completed.
class LumeSurah {
  const LumeSurah({
    required this.number,
    required this.name,
    required this.arabicName,
    required this.meaning,
    required this.ayahCount,
    required this.place,
  });

  /// The surah's position in the mushaf — not its position in this list,
  /// which holds only twelve of the 114.
  final int number;

  /// The transliterated name the reference gives in every language:
  /// "Al-Fatihah". A proper name, not a translation, so [resolveName] never
  /// marks it a fallback — the same treatment Hadith gives a collection's
  /// name (C77).
  final String name;

  /// The surah's own name, in Arabic script, exactly as the reference holds
  /// it.
  final String arabicName;

  /// The reference's own English gloss: "The Opening". Plain metadata, shown
  /// in every language exactly as the reference shows it — not a
  /// translation of scripture, so it carries no licence obligation.
  final String meaning;

  /// The surah's true length in the mushaf — not the number of its ayat this
  /// build holds, which may be none.
  final int ayahCount;

  final LumeSurahPlace place;

  /// The surah's own name in [language]: the Arabic to an Arabic reader,
  /// the transliteration otherwise. Never a fallback — a transliterated
  /// name is what the reference always shows, in every language, not a
  /// translation attempt with nothing verified behind it.
  LumeResolvedPassage resolveName(LumeContentLanguage language) =>
      language == LumeContentLanguage.arabic
      ? LumeResolvedPassage(
          text: arabicName,
          language: LumeContentLanguage.arabic,
          isFallback: false,
        )
      : LumeResolvedPassage(
          text: name,
          language: LumeContentLanguage.english,
          isFallback: false,
        );
}

/// One ayah — `AYAT`. Three of the mushaf's 6,236: exactly the reference's
/// own subset.
class LumeAyah {
  const LumeAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.arabic,
    required this.translation,
    required this.transliteration,
  });

  final int surahNumber;
  final int ayahNumber;

  /// The surah's transliterated name, as `AYAT` cites it. Not necessarily
  /// one of the twelve [LumeSurah] entries — Ash-Sharh (94) is not — because
  /// the reference's two lists were never made to agree with each other.
  final String surahName;

  /// The ayah's own words, exactly as the reference holds them. Never
  /// altered, abridged or reworded.
  final String arabic;

  /// The reference's own English rendering. Not a licensed, verified
  /// translation — [resolve] credits it as such, and marks it a fallback for
  /// a reader who asked for anything else.
  final String translation;

  /// A Latin transliteration of the Arabic. Not a translation and not
  /// scripture, so it needs no licence of its own; kept as the reference
  /// gives it, in every language.
  final String transliteration;

  /// "13:28" — this build's one identity for the ayah, independent of any
  /// interface language.
  String get id => '$surahNumber:$ayahNumber';

  /// What to show a reader of [language]: the Arabic — the original, never a
  /// fallback — to an Arabic reader; the reference's English, credited and
  /// marked as a fallback for anyone else, exactly as [LumeHadithRecord]
  /// resolves a passage with an original and one verified-in-nothing-else
  /// fallback (C82's pattern, reused directly).
  LumeResolvedPassage resolve(LumeContentLanguage language) {
    if (language == LumeContentLanguage.arabic) {
      return LumeResolvedPassage(
        text: arabic,
        language: LumeContentLanguage.arabic,
        isFallback: false,
      );
    }
    return LumeResolvedPassage(
      text: translation,
      language: LumeContentLanguage.english,
      isFallback: language != LumeContentLanguage.english,
    );
  }
}

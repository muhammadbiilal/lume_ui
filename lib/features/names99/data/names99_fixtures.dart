/// The Names the reader opens on — `tool-data.js` `NAMES99`.
///
/// A name is religious text: its Arabic, its transliteration and its number
/// in the traditional list of 99 are kept exactly as the reference gives
/// them. Its meaning is the reference's own English gloss, carried as data
/// rather than run through the ARBs — like `LumeHadithFixtures` and
/// `LumeTasbihPhrases`, content is carried as a source gives it, and the
/// interface around it is translated (C77).
///
/// **Dayroz obligation.** The source (`tool-data.js:663-676`) holds twelve of
/// the ninety-nine names — Ar-Rahman through Al-Bari — and no more. This is
/// not a display slice of a larger list held elsewhere: it is the whole of
/// what the reference has. [LumeNames99Fixtures.all] reproduces exactly those
/// twelve, numbered 1 through 12 as the source numbers them, and invents none
/// of the remaining eighty-seven — no name, no Arabic, no meaning. A licensed,
/// verified rendering of all ninety-nine — authenticated Arabic, verified
/// translations, and attribution and licence recorded for each — is the real
/// gap, and completing it needs a licensed source this repository does not
/// hold. Until then the screen says twelve of ninety-nine where the reference
/// only implies it, so that a reader is never left to discover the gap by
/// scrolling to the end of a list that stops short of its own name.
library;

import '../../hadith/domain/religious_content.dart';
import '../domain/names99_model.dart';

abstract final class LumeNames99Fixtures {
  /// Who the English is credited to: the web reference, not a verified
  /// translation.
  static const String edition = 'Lume web reference English (unverified)';

  /// Where every fixture came from. No licence: a release must not ship it.
  static const LumeContentAttribution attribution = LumeContentAttribution(
    publisher: 'Lume web reference fixture',
    sourceVersion: 'tool-data.js NAMES99',
  );

  /// The traditional count this tool is named for. [all] does not reach it —
  /// that gap is the point of the "Dayroz obligation" note above, not a bug
  /// to round away.
  static const int total = 99;

  /// `NAMES99`, in the reference's order and numbering. Twelve entries; see
  /// the library note for why there are no more.
  static const List<LumeName> all = <LumeName>[
    LumeName(
      number: 1,
      arabic: 'الرَّحْمَٰن',
      transliteration: 'Ar-Rahman',
      meaning: LumeVerifiedTranslation(
        language: LumeContentLanguage.english,
        text: 'The Most Compassionate',
        translator: edition,
      ),
    ),
    LumeName(
      number: 2,
      arabic: 'الرَّحِيم',
      transliteration: 'Ar-Rahim',
      meaning: LumeVerifiedTranslation(
        language: LumeContentLanguage.english,
        text: 'The Most Merciful',
        translator: edition,
      ),
    ),
    LumeName(
      number: 3,
      arabic: 'الْمَلِك',
      transliteration: 'Al-Malik',
      meaning: LumeVerifiedTranslation(
        language: LumeContentLanguage.english,
        text: 'The Sovereign',
        translator: edition,
      ),
    ),
    LumeName(
      number: 4,
      arabic: 'الْقُدُّوس',
      transliteration: 'Al-Quddus',
      meaning: LumeVerifiedTranslation(
        language: LumeContentLanguage.english,
        text: 'The Most Holy',
        translator: edition,
      ),
    ),
    LumeName(
      number: 5,
      arabic: 'السَّلَام',
      transliteration: 'As-Salam',
      meaning: LumeVerifiedTranslation(
        language: LumeContentLanguage.english,
        text: 'The Source of Peace',
        translator: edition,
      ),
    ),
    LumeName(
      number: 6,
      arabic: 'الْمُؤْمِن',
      transliteration: 'Al-Mu’min',
      meaning: LumeVerifiedTranslation(
        language: LumeContentLanguage.english,
        text: 'The Giver of Faith',
        translator: edition,
      ),
    ),
    LumeName(
      number: 7,
      arabic: 'الْمُهَيْمِن',
      transliteration: 'Al-Muhaymin',
      meaning: LumeVerifiedTranslation(
        language: LumeContentLanguage.english,
        text: 'The Guardian',
        translator: edition,
      ),
    ),
    LumeName(
      number: 8,
      arabic: 'الْعَزِيز',
      transliteration: 'Al-Aziz',
      meaning: LumeVerifiedTranslation(
        language: LumeContentLanguage.english,
        text: 'The Almighty',
        translator: edition,
      ),
    ),
    LumeName(
      number: 9,
      arabic: 'الْجَبَّار',
      transliteration: 'Al-Jabbar',
      meaning: LumeVerifiedTranslation(
        language: LumeContentLanguage.english,
        text: 'The Compeller',
        translator: edition,
      ),
    ),
    LumeName(
      number: 10,
      arabic: 'الْمُتَكَبِّر',
      transliteration: 'Al-Mutakabbir',
      meaning: LumeVerifiedTranslation(
        language: LumeContentLanguage.english,
        text: 'The Supreme',
        translator: edition,
      ),
    ),
    LumeName(
      number: 11,
      arabic: 'الْخَالِق',
      transliteration: 'Al-Khaliq',
      meaning: LumeVerifiedTranslation(
        language: LumeContentLanguage.english,
        text: 'The Creator',
        translator: edition,
      ),
    ),
    LumeName(
      number: 12,
      arabic: 'الْبَارِئ',
      transliteration: 'Al-Bari',
      meaning: LumeVerifiedTranslation(
        language: LumeContentLanguage.english,
        text: 'The Originator',
        translator: edition,
      ),
    ),
  ];

  /// How many of [total] this build actually holds — [all]'s own length, so
  /// the count on screen can never drift from the list behind it.
  static int get held => all.length;

  /// `names.filter(...)` — a search through the transliteration and the
  /// meaning, exactly as the reference matches (`n.tl + ' ' + n.meaning`).
  static List<LumeName> shown({String query = ''}) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return <LumeName>[
      for (final LumeName n in all)
        if ('${n.transliteration} ${n.meaning.text}'.toLowerCase().contains(
          q,
        ))
          n,
    ];
  }
}

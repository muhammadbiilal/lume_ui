/// `SURAHS` and `AYAT` — `tool-data.js`, and the day's ayah `context.js`
/// `dayIndex` picks. Backs all three tools this build converts from them:
/// Al-Qur'an (browse), Search the Qur'an, and Ayah of the Day.
///
/// Every surah and every ayah here is the reference's own, ported verbatim —
/// number, Arabic, English gloss or rendering, and transliteration exactly as
/// `tool-data.js` holds them. Nothing is invented to fill the mushaf's
/// remaining 102 surahs or 6,233 ayat; see the domain file's doc comment for
/// the Dayroz obligation that closes that gap.
library;

import '../domain/quran_model.dart';
import '../../hadith/domain/religious_content.dart';

abstract final class LumeQuranFixtures {
  /// Who the English is credited to: the web reference, not a verified
  /// translation.
  static const String edition = 'Lume web reference English (unverified)';

  /// Where every fixture came from. No licence: a release must not ship it.
  static const LumeContentAttribution attribution = LumeContentAttribution(
    publisher: 'Lume web reference fixture',
    sourceVersion: 'tool-data.js SURAHS, AYAT',
  );

  /// `SURAHS`, in the reference's order — twelve of the mushaf's 114.
  static const List<LumeSurah> surahs = <LumeSurah>[
    LumeSurah(
      number: 1,
      name: 'Al-Fatihah',
      arabicName: 'الفاتحة',
      meaning: 'The Opening',
      ayahCount: 7,
      place: LumeSurahPlace.meccan,
    ),
    LumeSurah(
      number: 2,
      name: 'Al-Baqarah',
      arabicName: 'البقرة',
      meaning: 'The Cow',
      ayahCount: 286,
      place: LumeSurahPlace.medinan,
    ),
    LumeSurah(
      number: 3,
      name: 'Ali ‘Imran',
      arabicName: 'آل عمران',
      meaning: 'Family of Imran',
      ayahCount: 200,
      place: LumeSurahPlace.medinan,
    ),
    LumeSurah(
      number: 4,
      name: 'An-Nisa',
      arabicName: 'النساء',
      meaning: 'The Women',
      ayahCount: 176,
      place: LumeSurahPlace.medinan,
    ),
    LumeSurah(
      number: 13,
      name: 'Ar-Ra‘d',
      arabicName: 'الرعد',
      meaning: 'The Thunder',
      ayahCount: 43,
      place: LumeSurahPlace.medinan,
    ),
    LumeSurah(
      number: 18,
      name: 'Al-Kahf',
      arabicName: 'الكهف',
      meaning: 'The Cave',
      ayahCount: 110,
      place: LumeSurahPlace.meccan,
    ),
    LumeSurah(
      number: 36,
      name: 'Ya-Sin',
      arabicName: 'يس',
      meaning: 'Ya Sin',
      ayahCount: 83,
      place: LumeSurahPlace.meccan,
    ),
    LumeSurah(
      number: 55,
      name: 'Ar-Rahman',
      arabicName: 'الرحمن',
      meaning: 'The Most Merciful',
      ayahCount: 78,
      place: LumeSurahPlace.medinan,
    ),
    LumeSurah(
      number: 56,
      name: 'Al-Waqi‘ah',
      arabicName: 'الواقعة',
      meaning: 'The Inevitable',
      ayahCount: 96,
      place: LumeSurahPlace.meccan,
    ),
    LumeSurah(
      number: 67,
      name: 'Al-Mulk',
      arabicName: 'الملك',
      meaning: 'The Sovereignty',
      ayahCount: 30,
      place: LumeSurahPlace.meccan,
    ),
    LumeSurah(
      number: 112,
      name: 'Al-Ikhlas',
      arabicName: 'الإخلاص',
      meaning: 'The Sincerity',
      ayahCount: 4,
      place: LumeSurahPlace.meccan,
    ),
    LumeSurah(
      number: 114,
      name: 'An-Nas',
      arabicName: 'الناس',
      meaning: 'Mankind',
      ayahCount: 6,
      place: LumeSurahPlace.meccan,
    ),
  ];

  /// `AYAT`, in the reference's order — three of the mushaf's 6,236. Ash-Sharh
  /// (94) is not among the twelve [surahs] above; the reference's two lists
  /// were never made to agree with each other, and this keeps that honestly.
  static const List<LumeAyah> ayat = <LumeAyah>[
    LumeAyah(
      surahNumber: 13,
      ayahNumber: 28,
      surahName: 'Ar-Ra‘d',
      arabic:
          'الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُم بِذِكْرِ اللَّهِ ۗ '
          'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
      translation:
          'Those who believe, and whose hearts find rest in the remembrance '
          'of God — surely in the remembrance of God do hearts find rest.',
      transliteration: 'Alladhīna āmanū wa taṭma’innu qulūbuhum bi-dhikri-llāh',
    ),
    LumeAyah(
      surahNumber: 94,
      ayahNumber: 6,
      surahName: 'Ash-Sharh',
      arabic: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
      translation: 'Indeed, with hardship comes ease.',
      transliteration: 'Inna ma‘a al-‘usri yusrā',
    ),
    LumeAyah(
      surahNumber: 2,
      ayahNumber: 286,
      surahName: 'Al-Baqarah',
      arabic: 'لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا',
      translation: 'God does not burden a soul beyond what it can bear.',
      transliteration: 'Lā yukallifu-llāhu nafsan illā wus‘ahā',
    ),
  ];

  /// `['rahman', 'sabr', 'light', 'mercy', 'ar-rahman', 'yaseen']` —
  /// `quransearch.tool.js`'s own suggested queries. Search terms, not prose:
  /// the reference never runs them through its translation function either,
  /// so they are kept as data here rather than as localised strings.
  static const List<String> suggestedSearches = <String>[
    'rahman',
    'sabr',
    'light',
    'mercy',
    'ar-rahman',
    'yaseen',
  ];

  /// `dayIndex(n)` — the same formula Hadith's fixture carries: `(year × 372
  /// + month × 31 + date) % n`, the month counted from zero as JavaScript
  /// counts it.
  static int dayIndex(DateTime day, int n) =>
      (day.year * 372 + (day.month - 1) * 31 + day.day) % n;

  /// The ayah of [day] — `ayahOfDay()`.
  static LumeAyah ayahOfDay(DateTime day) => ayat[dayIndex(day, ayat.length)];

  /// The surah with [number], where one of the twelve holds it.
  static LumeSurah? surahByNumber(int number) {
    for (final LumeSurah s in surahs) {
      if (s.number == number) return s;
    }
    return null;
  }

  /// The one ayah this fixture holds for [surahNumber], where it holds one.
  /// Ar-Ra‘d (13) and Al-Baqarah (2) are the only two of [surahs] this
  /// resolves; the other ten have none, exactly as the reference's tiny
  /// `AYAT` table leaves them.
  static LumeAyah? ayahForSurah(int surahNumber) {
    for (final LumeAyah a in ayat) {
      if (a.surahNumber == surahNumber) return a;
    }
    return null;
  }

  /// `D.SURAHS.filter(...)` — `quran.tool.js`'s own query: the name, the
  /// meaning and the number, lower-cased.
  static List<LumeSurah> surahsMatching(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return surahs;
    return <LumeSurah>[
      for (final LumeSurah s in surahs)
        if ('${s.name} ${s.meaning} ${s.number}'.toLowerCase().contains(q)) s,
    ];
  }

  /// `quranSearch(q)` (`context.js`) — with nothing typed, the three ayat,
  /// exactly as the reference returns them and searches no further. With a
  /// query, every ayah whose translation or surah name matches, then every
  /// surah whose name or meaning matches — in that order, exactly as the
  /// reference builds `hits`. A search over three ayat and twelve surahs is a
  /// search over three ayat and twelve surahs, not a claim of searching the
  /// Qur'an; nothing here pretends otherwise.
  static List<LumeQuranSearchHit> search(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return <LumeQuranSearchHit>[
        for (final LumeAyah a in ayat)
          LumeQuranSearchHit(
            kind: LumeQuranSearchKind.ayah,
            surahNumber: a.surahNumber,
            ayahNumber: a.ayahNumber,
            surahName: a.surahName,
            text: a.translation,
          ),
      ];
    }
    final List<LumeQuranSearchHit> hits = <LumeQuranSearchHit>[];
    for (final LumeAyah a in ayat) {
      if ('${a.translation} ${a.surahName}'.toLowerCase().contains(q)) {
        hits.add(
          LumeQuranSearchHit(
            kind: LumeQuranSearchKind.ayah,
            surahNumber: a.surahNumber,
            ayahNumber: a.ayahNumber,
            surahName: a.surahName,
            text: a.translation,
          ),
        );
      }
    }
    for (final LumeSurah s in surahs) {
      if ('${s.name} ${s.meaning}'.toLowerCase().contains(q)) {
        hits.add(
          LumeQuranSearchHit(
            kind: LumeQuranSearchKind.surah,
            surahNumber: s.number,
            ayahNumber: 1,
            surahName: s.name,
            text: s.meaning,
            place: s.place,
          ),
        );
      }
    }
    return hits;
  }
}

/// Which fixture a search hit came from — an ayah or a surah. `quranSearch`
/// returns both in one undifferentiated list; this keeps them tellable apart
/// without losing that the reference itself never bothers to.
enum LumeQuranSearchKind { ayah, surah }

/// One row `quranSearch` returns.
class LumeQuranSearchHit {
  const LumeQuranSearchHit({
    required this.kind,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.text,
    this.place,
  });

  final LumeQuranSearchKind kind;
  final int surahNumber;

  /// `1` for a surah hit — the reference's own placeholder ayah number
  /// (`a: 1`), not a claim that ayah 1 matched.
  final int ayahNumber;
  final String surahName;

  /// An ayah's translation, or a surah's meaning.
  final String text;

  /// Only a surah hit carries one — an ayah hit's `place` is the reference's
  /// own empty string, kept here as `null`.
  final LumeSurahPlace? place;
}

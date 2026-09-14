/// The hadith the reader opens on — `tool-data.js` `HADITH`, and the day's
/// choice `context.js` `dayIndex` makes.
///
/// A hadith is religious text: its words, its narrator and its collection are
/// kept exactly as the reference gives them, in every language. A translation
/// of a hadith has to come from a verified source, so none is made here
/// (C77, C82); the interface around it is translated.
library;

import '../domain/religious_content.dart';

/// A hadith's grade — how the scholars of hadith judge its chain.
enum LumeHadithGrade { sahih, hasan }

/// The collection a hadith is filed under, as the filter names it.
enum LumeHadithCollection {
  bukhari('Bukhari', 7563),
  muslim('Muslim', 5362),
  tabarani('Tabarani', 3956);

  const LumeHadithCollection(this.label, this.count);

  /// The collection's own name, written the same in every language.
  final String label;

  /// The filter chip's count — the collection's size in the reference.
  final int count;
}

class LumeHadith {
  const LumeHadith({
    required this.text,
    required this.source,
    required this.number,
    required this.grade,
    required this.narrator,
    required this.collection,
  });

  /// The hadith in the reference's English.
  final String text;

  /// The book, as the collection is cited: "Sahih Muslim".
  final String source;

  /// Its number in that book.
  final String number;

  final LumeHadithGrade grade;
  final String narrator;
  final LumeHadithCollection collection;

  /// `x.text.length > 58 ? x.text.slice(0, 58) + '…' : x.text` — a browse
  /// row's title. Cut by UTF-16 unit, as `slice` cuts.
  String get shortText => text.length > 58 ? '${text.substring(0, 58)}…' : text;

  /// This hadith in the religious-content contract (C82): one identity, its
  /// collection and number as cited, its narrator and the grade the
  /// reference states, and the reference's English as the only text — a
  /// fallback, with no original and no translation, because none has been
  /// verified. The attribution records that it is a fixture with no licence.
  LumeHadithRecord get record => LumeHadithRecord(
    id: '${collection.name}-$number',
    collection: source,
    number: number,
    narrator: narrator,
    grading: grade.name,
    fallback: LumeVerifiedTranslation(
      language: LumeContentLanguage.english,
      text: text,
      translator: LumeHadithFixtures.edition,
    ),
    attribution: LumeHadithFixtures.attribution,
  );
}

abstract final class LumeHadithFixtures {
  /// Who the English is credited to: the web reference, not a verified
  /// translation.
  static const String edition = 'Lume web reference English (unverified)';

  /// Where every fixture came from. No licence: a release must not ship it.
  static const LumeContentAttribution attribution = LumeContentAttribution(
    publisher: 'Lume web reference fixture',
    sourceVersion: 'tool-data.js HADITH',
  );

  /// `HADITH`, in the reference's order.
  static const List<LumeHadith> all = <LumeHadith>[
    LumeHadith(
      text: 'The best of people are those who are most beneficial to people.',
      source: 'Al-Mu‘jam al-Awsat',
      number: '5787',
      grade: LumeHadithGrade.hasan,
      narrator: 'Jabir ibn Abdullah',
      collection: LumeHadithCollection.tabarani,
    ),
    LumeHadith(
      text:
          'None of you truly believes until he loves for his brother what he '
          'loves for himself.',
      source: 'Sahih al-Bukhari',
      number: '13',
      grade: LumeHadithGrade.sahih,
      narrator: 'Anas ibn Malik',
      collection: LumeHadithCollection.bukhari,
    ),
    LumeHadith(
      text:
          'Make things easy and do not make them difficult; give glad tidings '
          'and do not repel people.',
      source: 'Sahih al-Bukhari',
      number: '69',
      grade: LumeHadithGrade.sahih,
      narrator: 'Anas ibn Malik',
      collection: LumeHadithCollection.bukhari,
    ),
    LumeHadith(
      text:
          'The strong is not the one who overcomes people by his strength, but '
          'the one who controls himself while in anger.',
      source: 'Sahih Muslim',
      number: '2609',
      grade: LumeHadithGrade.sahih,
      narrator: 'Abu Hurairah',
      collection: LumeHadithCollection.muslim,
    ),
  ];

  /// `dayIndex(n)` — `(year × 372 + month × 31 + date) % n`, with the month
  /// counted from zero as JavaScript counts it.
  static int dayIndex(DateTime day, int n) =>
      (day.year * 372 + (day.month - 1) * 31 + day.day) % n;

  /// The hadith of [day].
  static LumeHadith of(DateTime day) => all[dayIndex(day, all.length)];

  /// `shown` — a collection, then a search through the words, the narrator
  /// and the source.
  static List<LumeHadith> shown({
    LumeHadithCollection? collection,
    String query = '',
  }) {
    final String q = query.trim().toLowerCase();
    return <LumeHadith>[
      for (final LumeHadith h in all)
        if ((collection == null || h.collection == collection) &&
            (q.isEmpty ||
                '${h.text} ${h.narrator} ${h.source}'.toLowerCase().contains(
                  q,
                )))
          h,
    ];
  }
}

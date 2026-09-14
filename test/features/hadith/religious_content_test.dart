/// Religious text is carried as a source gives it: a passage is shown in a
/// language only when a verified text in that language exists, and a
/// fallback is always known to be one (F6B decision 3, C82).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/hadith/data/hadith_fixtures.dart';
import 'package:lume/features/hadith/domain/religious_content.dart';

const LumeContentAttribution source = LumeContentAttribution(
  publisher: 'A licensed publisher',
  sourceVersion: 'v1',
  licence: 'Licensed',
);

void main() {
  group('resolving a passage for a reader', () {
    const LumeHadithRecord englishOnly = LumeHadithRecord(
      id: 'muslim-2609',
      collection: 'Sahih Muslim',
      number: '2609',
      narrator: 'Abu Hurairah',
      attribution: source,
      fallback: LumeVerifiedTranslation(
        language: LumeContentLanguage.english,
        text: 'The strong is not the one who overcomes people by his strength.',
        translator: 'Edition A',
      ),
    );

    test('an English reader reads the English, and it is not a fallback', () {
      final LumeResolvedPassage p = englishOnly.resolve(
        LumeContentLanguage.english,
      )!;
      expect(p.language, LumeContentLanguage.english);
      expect(p.isFallback, isFalse);
    });

    test('an Urdu reader is shown the English, and told it is English', () {
      final LumeResolvedPassage p = englishOnly.resolve(
        LumeContentLanguage.urdu,
      )!;
      expect(p.text, englishOnly.fallback!.text);
      expect(p.language, LumeContentLanguage.english);
      expect(p.language.isRightToLeft, isFalse);
      expect(p.isFallback, isTrue);
    });

    test('a verified translation is used when it exists', () {
      const LumeHadithRecord withUrdu = LumeHadithRecord(
        id: 'x-1',
        collection: 'C',
        number: '1',
        narrator: 'N',
        attribution: source,
        translations: <LumeVerifiedTranslation>[
          LumeVerifiedTranslation(
            language: LumeContentLanguage.urdu,
            text: 'اردو متن',
            translator: 'Edition B',
          ),
        ],
      );
      final LumeResolvedPassage p = withUrdu.resolve(LumeContentLanguage.urdu)!;
      expect(p.text, 'اردو متن');
      expect(p.isFallback, isFalse);
      expect(p.language.isRightToLeft, isTrue);
    });

    test('the original is shown to a reader of its language', () {
      const LumeHadithRecord withArabic = LumeHadithRecord(
        id: 'x-2',
        collection: 'C',
        number: '2',
        narrator: 'N',
        attribution: source,
        originalLanguage: LumeContentLanguage.arabic,
        originalText: 'نص',
      );
      final LumeResolvedPassage p = withArabic.resolve(
        LumeContentLanguage.arabic,
      )!;
      expect(p.text, 'نص');
      expect(p.isFallback, isFalse);
    });

    test('with nothing verified to show, nothing is shown', () {
      const LumeHadithRecord empty = LumeHadithRecord(
        id: 'x-3',
        collection: 'C',
        number: '3',
        narrator: 'N',
        attribution: source,
      );
      expect(empty.resolve(LumeContentLanguage.english), isNull);
    });
  });

  group("this build's hadith", () {
    final List<LumeHadithRecord> records = <LumeHadithRecord>[
      for (final LumeHadith h in LumeHadithFixtures.all) h.record,
    ];

    test('each keeps its words, collection, number and narrator exactly', () {
      for (int i = 0; i < records.length; i++) {
        final LumeHadith h = LumeHadithFixtures.all[i];
        final LumeHadithRecord r = records[i];
        expect(r.fallback!.text, h.text);
        expect(r.collection, h.source);
        expect(r.number, h.number);
        expect(r.narrator, h.narrator);
        expect(r.grading, h.grade.name);
      }
    });

    test('one identity each', () {
      expect(
        records.map((LumeHadithRecord r) => r.id).toSet(),
        hasLength(records.length),
      );
    });

    test('no original and no translation is invented', () {
      for (final LumeHadithRecord r in records) {
        expect(r.originalText, isNull);
        expect(r.originalLanguage, isNull);
        expect(r.translations, isEmpty);
        expect(r.fallback!.language, LumeContentLanguage.english);
      }
    });

    test('Urdu and Arabic readers are always told it is English', () {
      for (final LumeHadithRecord r in records) {
        for (final LumeContentLanguage lang in <LumeContentLanguage>[
          LumeContentLanguage.urdu,
          LumeContentLanguage.arabic,
        ]) {
          final LumeResolvedPassage p = r.resolve(lang)!;
          expect(p.isFallback, isTrue);
          expect(p.language, LumeContentLanguage.english);
        }
      }
    });

    test('the fixture says it is a fixture, with no licence', () {
      for (final LumeHadithRecord r in records) {
        expect(r.attribution.licence, isNull);
        expect(r.fallback!.translator, contains('unverified'));
      }
    });
  });
}

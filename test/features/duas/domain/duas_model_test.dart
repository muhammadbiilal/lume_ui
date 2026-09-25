/// Duas resolve the same way Hadith's records do (`religious_content_test.dart`):
/// a passage is shown in a language only when a verified text in that
/// language exists, and a fallback is always known to be one (C82) — except a
/// dua actually has a real original, so its own language resolves to it
/// rather than to a labelled fallback.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/duas/data/duas_fixtures.dart';
import 'package:lume/features/duas/domain/duas_model.dart';
import 'package:lume/features/hadith/domain/religious_content.dart';

const LumeContentAttribution _source = LumeContentAttribution(
  publisher: 'A licensed publisher',
  sourceVersion: 'v1',
  licence: 'Licensed',
);

void main() {
  group('resolving a dua for a reader', () {
    const LumeDuaRecord withArabic = LumeDuaRecord(
      id: 'x-1',
      citation: 'Sahih Muslim 1',
      attribution: _source,
      originalLanguage: LumeContentLanguage.arabic,
      originalText: 'نص الدعاء',
      fallback: LumeVerifiedTranslation(
        language: LumeContentLanguage.english,
        text: 'The supplication, in English.',
        translator: 'Edition A',
      ),
    );

    test('an Arabic reader is shown the real Arabic, not a fallback', () {
      final LumeResolvedPassage p = withArabic.resolve(
        LumeContentLanguage.arabic,
      )!;
      expect(p.text, 'نص الدعاء');
      expect(p.language, LumeContentLanguage.arabic);
      expect(p.language.isRightToLeft, isTrue);
      expect(p.isFallback, isFalse);
    });

    test('an English reader reads the English, and it is not a fallback', () {
      final LumeResolvedPassage p = withArabic.resolve(
        LumeContentLanguage.english,
      )!;
      expect(p.text, 'The supplication, in English.');
      expect(p.language, LumeContentLanguage.english);
      expect(p.isFallback, isFalse);
    });

    test('an Urdu reader is shown the English, and told it is English', () {
      final LumeResolvedPassage p = withArabic.resolve(
        LumeContentLanguage.urdu,
      )!;
      expect(p.text, 'The supplication, in English.');
      expect(p.language, LumeContentLanguage.english);
      expect(p.isFallback, isTrue);
    });

    test('a verified translation is used ahead of the fallback', () {
      const LumeDuaRecord withUrdu = LumeDuaRecord(
        id: 'x-2',
        citation: 'C 2',
        attribution: _source,
        originalLanguage: LumeContentLanguage.arabic,
        originalText: 'نص',
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

    test('with nothing verified to show, nothing is shown', () {
      const LumeDuaRecord empty = LumeDuaRecord(
        id: 'x-3',
        citation: 'C 3',
        attribution: _source,
      );
      expect(empty.resolve(LumeContentLanguage.english), isNull);
    });
  });

  group("this build's duas", () {
    test('there are exactly five — the reference has no more', () {
      expect(LumeDuaFixtures.all, hasLength(5));
    });

    final List<LumeDuaRecord> records = <LumeDuaRecord>[
      for (final LumeDua d in LumeDuaFixtures.all) d.record,
    ];

    test('each keeps its Arabic, its citation and its English exactly', () {
      for (int i = 0; i < records.length; i++) {
        final LumeDua d = LumeDuaFixtures.all[i];
        final LumeDuaRecord r = records[i];
        expect(r.originalText, d.arabic);
        expect(r.originalLanguage, LumeContentLanguage.arabic);
        expect(r.citation, d.citation);
        expect(r.fallback!.text, d.translation);
      }
    });

    test('one identity each', () {
      expect(records.map((LumeDuaRecord r) => r.id).toSet(), hasLength(5));
    });

    test('the fixture says it is a fixture, with no licence', () {
      for (final LumeDuaRecord r in records) {
        expect(r.attribution.licence, isNull);
        expect(r.fallback!.translator, contains('unverified'));
      }
    });

    test('each category counts only the duas actually filed under it — never '
        'the reference\'s own inflated DUA_CATEGORIES[].n', () {
      // The reference's own DUA_CATEGORIES: morning 12, daily 18, travel 6,
      // distress 9, food 5, sleep 7 — none of which this build ports.
      const Map<LumeDuaCategory, int> inflated = <LumeDuaCategory, int>{
        LumeDuaCategory.morning: 12,
        LumeDuaCategory.daily: 18,
        LumeDuaCategory.travel: 6,
        LumeDuaCategory.distress: 9,
        LumeDuaCategory.food: 5,
        LumeDuaCategory.sleep: 7,
      };
      // The real count: one dua in each category except `daily`, which the
      // DUAS array never actually uses at all.
      const Map<LumeDuaCategory, int> real = <LumeDuaCategory, int>{
        LumeDuaCategory.morning: 1,
        LumeDuaCategory.daily: 0,
        LumeDuaCategory.travel: 1,
        LumeDuaCategory.distress: 1,
        LumeDuaCategory.food: 1,
        LumeDuaCategory.sleep: 1,
      };
      for (final LumeDuaCategory c in LumeDuaCategory.values) {
        expect(LumeDuaFixtures.countOf(c), real[c]);
        expect(LumeDuaFixtures.countOf(c), isNot(inflated[c]));
      }
      expect(
        real.values.fold<int>(0, (int a, int b) => a + b),
        LumeDuaFixtures.all.length,
      );
    });
  });

  group('browsing', () {
    test('a category narrows the list to the real count', () {
      expect(LumeDuaFixtures.shown(category: LumeDuaCategory.daily), isEmpty);
      expect(
        LumeDuaFixtures.shown(category: LumeDuaCategory.travel),
        hasLength(1),
      );
    });

    test('a query matches the Arabic, the English or the citation', () {
      expect(LumeDuaFixtures.shown(query: 'anxiety'), hasLength(1));
      expect(LumeDuaFixtures.shown(query: 'Bukhari'), hasLength(2));
      expect(LumeDuaFixtures.shown(query: 'أَصْبَحْنَا'), hasLength(1));
      expect(LumeDuaFixtures.shown(query: 'zzz'), isEmpty);
    });

    test("the day's dua is always one of the five", () {
      final LumeDua d = LumeDuaFixtures.of(DateTime(2026, 9, 25));
      expect(LumeDuaFixtures.all, contains(d));
    });
  });
}

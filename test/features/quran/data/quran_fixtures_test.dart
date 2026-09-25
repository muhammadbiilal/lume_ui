/// `LumeQuranFixtures` against the reference's own `SURAHS`, `AYAT` and
/// `quranSearch` — ported verbatim, and honest about how little of the
/// mushaf they actually cover.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/quran/data/quran_fixtures.dart';
import 'package:lume/features/quran/domain/quran_model.dart';

void main() {
  group('the fixtures', () {
    test('hold exactly the reference\'s twelve surahs and three ayat', () {
      expect(LumeQuranFixtures.surahs, hasLength(12));
      expect(LumeQuranFixtures.ayat, hasLength(3));
    });

    test('no licence is claimed for a fixture with none recorded', () {
      expect(LumeQuranFixtures.attribution.licence, isNull);
      expect(LumeQuranFixtures.edition, contains('unverified'));
    });

    test('Ash-Sharh (94) has an ayah but no matching surah in the twelve', () {
      expect(LumeQuranFixtures.ayahForSurah(94), isNotNull);
      expect(LumeQuranFixtures.surahByNumber(94), isNull);
    });

    test('Ar-Ra‘d (13) and Al-Baqarah (2) resolve to a real ayah', () {
      expect(LumeQuranFixtures.ayahForSurah(13)!.surahName, 'Ar-Ra‘d');
      expect(LumeQuranFixtures.ayahForSurah(2)!.surahName, 'Al-Baqarah');
    });

    test('a surah this build holds no ayah for resolves to nothing', () {
      expect(LumeQuranFixtures.ayahForSurah(1), isNull);
    });
  });

  group('surahsMatching — quran.tool.js\'s own query', () {
    test('an empty query is every surah', () {
      expect(LumeQuranFixtures.surahsMatching(''), LumeQuranFixtures.surahs);
    });

    test('matches the name, the meaning or the number, case-insensitively', () {
      expect(
        LumeQuranFixtures.surahsMatching('cave').single.name,
        'Al-Kahf',
      );
      expect(
        LumeQuranFixtures.surahsMatching('AR-RAHMAN').single.name,
        'Ar-Rahman',
      );
      expect(LumeQuranFixtures.surahsMatching('112').single.number, 112);
    });

    test('a query matching nothing is an empty list', () {
      expect(LumeQuranFixtures.surahsMatching('zzz not a surah'), isEmpty);
    });
  });

  group('dayIndex — the same formula as Hadith\'s, applied to three ayat', () {
    test('is deterministic for a fixed day', () {
      final DateTime day = DateTime(2026, 9, 7);
      final int first = LumeQuranFixtures.dayIndex(day, 3);
      final int second = LumeQuranFixtures.dayIndex(day, 3);
      expect(first, second);
      expect(first, inInclusiveRange(0, 2));
    });

    test('7 September 2026 opens on Ar-Ra‘d 13:28', () {
      final LumeAyah a = LumeQuranFixtures.ayahOfDay(DateTime(2026, 9, 7));
      expect(a.surahNumber, 13);
      expect(a.ayahNumber, 28);
    });

    test('a different day can pick a different ayah', () {
      final LumeAyah day1 = LumeQuranFixtures.ayahOfDay(DateTime(2026, 9, 8));
      final LumeAyah day2 = LumeQuranFixtures.ayahOfDay(DateTime(2026, 9, 9));
      expect(day1.id == day2.id, isFalse);
    });
  });

  group('search — quranSearch(q), including the no-match case', () {
    test('an empty query is the three ayat, in the reference\'s order', () {
      final List<LumeQuranSearchHit> hits = LumeQuranFixtures.search('');
      expect(hits, hasLength(3));
      expect(hits.every((LumeQuranSearchHit h) => h.kind == LumeQuranSearchKind.ayah), isTrue);
      expect(hits.first.surahNumber, 13);
    });

    test('matches an ayah by its translation or its surah name', () {
      final List<LumeQuranSearchHit> hits = LumeQuranFixtures.search('hardship');
      expect(hits, hasLength(1));
      expect(hits.single.kind, LumeQuranSearchKind.ayah);
      expect(hits.single.surahNumber, 94);
    });

    test('matches a surah by its name or its meaning, after the ayat', () {
      // "Cow" is the Cow's own meaning and appears in no ayah translation.
      final List<LumeQuranSearchHit> hits = LumeQuranFixtures.search('cow');
      expect(hits, hasLength(1));
      expect(hits.single.kind, LumeQuranSearchKind.surah);
      expect(hits.single.surahName, 'Al-Baqarah');
      expect(hits.single.place, LumeSurahPlace.medinan);
    });

    test('ayah hits precede surah hits when both match', () {
      // "believe" is only in the Ar-Ra'd ayah's translation; adding a surah
      // hit alongside it exercises the ordering without relying on one.
      final List<LumeQuranSearchHit> hits = LumeQuranFixtures.search('the');
      final int firstSurah = hits.indexWhere(
        (LumeQuranSearchHit h) => h.kind == LumeQuranSearchKind.surah,
      );
      final int lastAyah = hits.lastIndexWhere(
        (LumeQuranSearchHit h) => h.kind == LumeQuranSearchKind.ayah,
      );
      if (firstSurah != -1 && lastAyah != -1) {
        expect(lastAyah, lessThan(firstSurah));
      }
    });

    test('a query matching nothing is an empty list', () {
      expect(LumeQuranFixtures.search('zzz-not-in-the-mushaf'), isEmpty);
    });
  });
}

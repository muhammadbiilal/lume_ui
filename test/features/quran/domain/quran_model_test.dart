/// The religious-content contract, reused directly for the Qur'an: an ayah's
/// Arabic is never a fallback, its translation is credited and marked one
/// exactly when the reader's language is neither Arabic nor English, and a
/// surah's own name is never mislabelled as a translation attempt.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/hadith/domain/religious_content.dart';
import 'package:lume/features/quran/domain/quran_model.dart';

const LumeAyah kAyah = LumeAyah(
  surahNumber: 13,
  ayahNumber: 28,
  surahName: 'Ar-Ra‘d',
  arabic: 'الَّذِينَ آمَنُوا',
  translation: 'Those who believe.',
  transliteration: 'Alladhīna āmanū',
);

const LumeSurah kSurah = LumeSurah(
  number: 1,
  name: 'Al-Fatihah',
  arabicName: 'الفاتحة',
  meaning: 'The Opening',
  ayahCount: 7,
  place: LumeSurahPlace.meccan,
);

void main() {
  group('LumeAyah.resolve', () {
    test(
      'an Arabic reader is given the Arabic, and it is never a fallback',
      () {
        final LumeResolvedPassage p = kAyah.resolve(LumeContentLanguage.arabic);
        expect(p.text, kAyah.arabic);
        expect(p.language, LumeContentLanguage.arabic);
        expect(p.language.isRightToLeft, isTrue);
        expect(p.isFallback, isFalse);
      },
    );

    test(
      'an English reader is given the English, and it is not a fallback',
      () {
        final LumeResolvedPassage p = kAyah.resolve(
          LumeContentLanguage.english,
        );
        expect(p.text, kAyah.translation);
        expect(p.language, LumeContentLanguage.english);
        expect(p.isFallback, isFalse);
      },
    );

    test('an Urdu reader is given the English, and told it is English', () {
      final LumeResolvedPassage p = kAyah.resolve(LumeContentLanguage.urdu);
      expect(p.text, kAyah.translation);
      expect(p.language, LumeContentLanguage.english);
      expect(p.language.isRightToLeft, isFalse);
      expect(p.isFallback, isTrue);
    });

    test('any other language is the same fallback, marked the same way', () {
      final LumeResolvedPassage p = kAyah.resolve(
        const LumeContentLanguage('fr'),
      );
      expect(p.text, kAyah.translation);
      expect(p.isFallback, isTrue);
    });
  });

  group('LumeSurah.resolveName', () {
    test('an Arabic reader is given the Arabic name, never a fallback', () {
      final LumeResolvedPassage p = kSurah.resolveName(
        LumeContentLanguage.arabic,
      );
      expect(p.text, kSurah.arabicName);
      expect(p.language, LumeContentLanguage.arabic);
      expect(p.isFallback, isFalse);
    });

    test('every other reader is given the transliterated name — a proper noun, '
        'never marked as a translation with nothing verified behind it', () {
      for (final LumeContentLanguage lang in <LumeContentLanguage>[
        LumeContentLanguage.english,
        LumeContentLanguage.urdu,
        const LumeContentLanguage('fr'),
      ]) {
        final LumeResolvedPassage p = kSurah.resolveName(lang);
        expect(p.text, kSurah.name);
        expect(p.isFallback, isFalse);
      }
    });
  });

  test("an ayah's own id is surah:ayah, independent of language", () {
    expect(kAyah.id, '13:28');
  });
}

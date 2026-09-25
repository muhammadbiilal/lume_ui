/// The twelve names the fixture actually holds, and the honesty of what it
/// does not.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/hadith/domain/religious_content.dart';
import 'package:lume/features/names99/data/names99_fixtures.dart';
import 'package:lume/features/names99/domain/names99_model.dart';

void main() {
  group('the fixture', () {
    test('holds exactly twelve names, numbered 1 through 12', () {
      expect(LumeNames99Fixtures.all, hasLength(12));
      expect(LumeNames99Fixtures.held, 12);
      expect(
        LumeNames99Fixtures.all.map((LumeName n) => n.number),
        List<int>.generate(12, (int i) => i + 1),
      );
    });

    test('is named for 99 but never claims to hold them', () {
      expect(LumeNames99Fixtures.total, 99);
      expect(LumeNames99Fixtures.held, isNot(LumeNames99Fixtures.total));
      // Nothing here numbers a name past the twelfth — the missing 87 are
      // not renumbered or invented to look complete.
      for (final LumeName n in LumeNames99Fixtures.all) {
        expect(n.number, inInclusiveRange(1, 12));
      }
    });

    test('every name carries real Arabic, a transliteration and a meaning', () {
      for (final LumeName n in LumeNames99Fixtures.all) {
        expect(n.arabic, isNotEmpty);
        expect(n.transliteration, isNotEmpty);
        expect(n.meaning.text, isNotEmpty);
        expect(n.meaning.language, LumeContentLanguage.english);
      }
    });

    test('Ar-Rahman through Al-Bari, in the reference\'s own order', () {
      expect(
        LumeNames99Fixtures.all.map((LumeName n) => n.transliteration),
        <String>[
          'Ar-Rahman',
          'Ar-Rahim',
          'Al-Malik',
          'Al-Quddus',
          'As-Salam',
          'Al-Mu’min',
          'Al-Muhaymin',
          'Al-Aziz',
          'Al-Jabbar',
          'Al-Mutakabbir',
          'Al-Khaliq',
          'Al-Bari',
        ],
      );
    });

    test('has no licence recorded — a release must not ship it as-is', () {
      expect(LumeNames99Fixtures.attribution.licence, isNull);
    });
  });

  group('resolve', () {
    test('reading English is not a fallback', () {
      final LumeResolvedPassage p = LumeNames99Fixtures.all.first.resolve(
        LumeContentLanguage.english,
      );
      expect(p.isFallback, isFalse);
      expect(p.text, 'The Most Compassionate');
      expect(p.language, LumeContentLanguage.english);
    });

    test('reading any other language falls back to the same English — never '
        'an invented Urdu or Arabic rendering', () {
      for (final LumeContentLanguage lang in <LumeContentLanguage>[
        LumeContentLanguage.urdu,
        LumeContentLanguage.arabic,
        const LumeContentLanguage('fr'),
      ]) {
        final LumeResolvedPassage p = LumeNames99Fixtures.all.first.resolve(
          lang,
        );
        expect(p.isFallback, isTrue);
        expect(p.text, 'The Most Compassionate');
        expect(p.language, LumeContentLanguage.english);
      }
    });
  });

  group('shown', () {
    test('with no query, every name', () {
      expect(LumeNames99Fixtures.shown(), LumeNames99Fixtures.all);
    });

    test('a transliteration finds its own name', () {
      final List<LumeName> found = LumeNames99Fixtures.shown(query: 'bari');
      expect(found, hasLength(1));
      expect(found.single.transliteration, 'Al-Bari');
    });

    test('a word from the meaning finds its name too', () {
      final List<LumeName> found = LumeNames99Fixtures.shown(
        query: 'sovereign',
      );
      expect(found, hasLength(1));
      expect(found.single.transliteration, 'Al-Malik');
    });

    test('nothing matches a name outside the twelve', () {
      expect(LumeNames99Fixtures.shown(query: 'wadud'), isEmpty);
    });
  });
}

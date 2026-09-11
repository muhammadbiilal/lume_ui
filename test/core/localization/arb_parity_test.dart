/// Localisation: three languages, full key parity, and the right direction.
///
/// Parity is not aspirational here. `gen_l10n` falls back to English for any
/// key a locale is missing, so a partial ARB ships silently — the user simply
/// sees English in the middle of an Urdu screen. These tests fail instead.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/localization/lume_locales.dart';
import 'package:lume/core/theme/lume/lume_type.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/lume_harness.dart';

const String _dir = 'lib/l10n';

Map<String, String> _arb(String code) {
  final Map<String, dynamic> raw =
      jsonDecode(File('$_dir/app_$code.arb').readAsStringSync())
          as Map<String, dynamic>;
  return <String, String>{
    for (final MapEntry<String, dynamic> e in raw.entries)
      if (!e.key.startsWith('@')) e.key: e.value as String,
  };
}

void main() {
  final Map<String, String> en = _arb('en');
  final Map<String, String> ur = _arb('ur');
  final Map<String, String> ar = _arb('ar');

  group('key parity', () {
    test('English has keys at all', () {
      expect(en, isNotEmpty);
    });

    test('Urdu has every English key, and no extras', () {
      expect(ur.keys.toSet(), en.keys.toSet());
    });

    test('Arabic has every English key, and no extras', () {
      expect(ar.keys.toSet(), en.keys.toSet());
    });

    test('no value is empty in any language', () {
      for (final MapEntry<String, Map<String, String>> lang
          in <String, Map<String, String>>{
            'en': en,
            'ur': ur,
            'ar': ar,
          }.entries) {
        lang.value.forEach((String k, String v) {
          expect(
            v.trim(),
            isNotEmpty,
            reason:
                '${lang.key}.$k is blank — an empty string is not a '
                'translation, it is a hole',
          );
        });
      }
    });

    test('no translation was left as the English string', () {
      // A handful legitimately match — a proper noun, an abbreviation — so this
      // guards against a wholesale copy rather than a single coincidence.
      int identical = 0;
      en.forEach((String k, String v) {
        if (ur[k] == v) identical++;
      });
      expect(
        identical / en.length,
        lessThan(0.1),
        reason:
            'most Urdu values are byte-identical to English, which means '
            'the file was copied rather than translated',
      );
    });

    test('the generator reports nothing untranslated', () {
      // `l10n.yaml` writes this on every `flutter gen-l10n`. An empty object is
      // the contract; anything else is a key some language is missing.
      final File backlog = File('l10n_untranslated.json');
      if (!backlog.existsSync()) return;
      final Map<String, dynamic> j =
          jsonDecode(backlog.readAsStringSync()) as Map<String, dynamic>;
      expect(j, isEmpty, reason: 'untranslated keys: ${j.keys.join(', ')}');
    });
  });

  group('the shipped set', () {
    test('is exactly English, Urdu and Arabic', () {
      expect(LumeLocales.all.map((LumeLanguage l) => l.code).toList(), <String>[
        'en',
        'ur',
        'ar',
      ]);
    });

    test('there is an ARB for every shipped language, and no others', () {
      final Set<String> files = Directory(_dir)
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.arb'))
          .map(
            (File f) => f.uri.pathSegments.last
                .replaceAll('app_', '')
                .replaceAll('.arb', ''),
          )
          .toSet();
      expect(
        files,
        LumeLocales.all.map((LumeLanguage l) => l.code).toSet(),
        reason:
            'an empty ARB would put a row in the language picker that '
            'does nothing when chosen',
      );
    });

    test('each language declares its own locale in its ARB', () {
      for (final String code in <String>['en', 'ur', 'ar']) {
        final Map<String, dynamic> raw =
            jsonDecode(File('$_dir/app_$code.arb').readAsStringSync())
                as Map<String, dynamic>;
        expect(raw['@@locale'], code);
      }
    });

    test('AppLocalizations supports the same three', () {
      expect(
        AppLocalizations.supportedLocales
            .map((Locale l) => l.languageCode)
            .toSet(),
        <String>{'en', 'ur', 'ar'},
      );
    });
  });

  group('direction', () {
    test('English reads left to right; Urdu and Arabic read right to left', () {
      expect(LumeLocales.english.direction, TextDirection.ltr);
      expect(LumeLocales.urdu.direction, TextDirection.rtl);
      expect(LumeLocales.arabic.direction, TextDirection.rtl);
    });

    testWidgets('the tree takes its direction from the locale', (
      WidgetTester tester,
    ) async {
      for (final MapEntry<String, TextDirection> e in <String, TextDirection>{
        'en': TextDirection.ltr,
        'ur': TextDirection.rtl,
        'ar': TextDirection.rtl,
      }.entries) {
        late TextDirection got;
        await pumpLume(
          tester,
          LumeProbe(onBuild: (BuildContext c) => got = Directionality.of(c)),
          locale: Locale(e.key),
        );
        expect(got, e.value, reason: e.key);
      }
    });
  });

  group('resolution', () {
    test('a device asking for a regional variant gets the language', () {
      expect(
        LumeLocales.resolve(<Locale>[
          const Locale('ur', 'PK'),
        ], LumeLocales.supported),
        const Locale('ur'),
      );
      expect(
        LumeLocales.resolve(<Locale>[
          const Locale('ar', 'SA'),
        ], LumeLocales.supported),
        const Locale('ar'),
      );
    });

    test('a language we do not ship falls back to English', () {
      expect(
        LumeLocales.resolve(<Locale>[
          const Locale('ja'),
        ], LumeLocales.supported),
        const Locale('en'),
      );
    });

    test('the first supported preference wins', () {
      expect(
        LumeLocales.resolve(<Locale>[
          const Locale('ja'),
          const Locale('ar'),
        ], LumeLocales.supported),
        const Locale('ar'),
      );
    });

    test('language is never inferred from country', () {
      // A device in Pakistan set to English gets English. This is the
      // invariant the whole personalisation model rests on, and it is worth a
      // test that fails loudly if anyone ever "helpfully" adds a mapping.
      expect(
        LumeLocales.resolve(<Locale>[
          const Locale('en', 'PK'),
        ], LumeLocales.supported),
        const Locale('en'),
      );
    });
  });

  group('script-aware type', () {
    test('Urdu and Arabic need a looser line than the Latin scale', () {
      expect(LumeType.needsTallLineHeight(const Locale('ur')), isTrue);
      expect(LumeType.needsTallLineHeight(const Locale('ar')), isTrue);
      expect(LumeType.needsTallLineHeight(const Locale('en')), isFalse);
    });

    testWidgets('fit() raises the line height for a tall script', (
      WidgetTester tester,
    ) async {
      late TextStyle english;
      late TextStyle urdu;

      await pumpLume(
        tester,
        LumeProbe(
          onBuild: (BuildContext c) =>
              english = LumeType.fit(c, LumeType.standard.display),
        ),
        locale: const Locale('en'),
      );
      await pumpLume(
        tester,
        LumeProbe(
          onBuild: (BuildContext c) =>
              urdu = LumeType.fit(c, LumeType.standard.display),
        ),
        locale: const Locale('ur'),
      );

      // Display is 28/32, so 1.143 — tight enough to clip Nastaliq descenders.
      expect(english.height, closeTo(32 / 28, 0.001));
      expect(urdu.height, greaterThanOrEqualTo(LumeType.tallScriptMinHeight));
    });

    testWidgets('fit() drops negative tracking for joined scripts', (
      WidgetTester tester,
    ) async {
      late TextStyle urdu;
      await pumpLume(
        tester,
        LumeProbe(
          onBuild: (BuildContext c) => urdu = LumeType.fit(
            c,
            LumeType.tracked(LumeType.standard.display, -0.04),
          ),
        ),
        locale: const Locale('ur'),
      );
      expect(
        urdu.letterSpacing,
        0,
        reason: 'tightening a joined script pulls its letterforms together',
      );
    });

    testWidgets(
      'overline() uppercases Latin and leaves caseless scripts alone',
      (WidgetTester tester) async {
        late String latin;
        late String arabic;
        await pumpLume(
          tester,
          LumeProbe(
            onBuild: (BuildContext c) =>
                latin = LumeType.overline(c, 'Make it local'),
          ),
          locale: const Locale('en'),
        );
        await pumpLume(
          tester,
          LumeProbe(
            onBuild: (BuildContext c) =>
                arabic = LumeType.overline(c, 'اجعله محليًا'),
          ),
          locale: const Locale('ar'),
        );
        expect(latin, 'MAKE IT LOCAL');
        expect(
          arabic,
          'اجعله محليًا',
          reason:
              'uppercasing a caseless script changes nothing and costs an '
              'allocation',
        );
      },
    );
  });

  group('strings reach the tree', () {
    testWidgets('the same key resolves differently in each language', (
      WidgetTester tester,
    ) async {
      final Map<String, String> got = <String, String>{};
      for (final String code in <String>['en', 'ur', 'ar']) {
        await pumpLume(
          tester,
          LumeProbe(
            onBuild: (BuildContext c) =>
                got[code] = AppLocalizations.of(c).actionContinue,
          ),
          locale: Locale(code),
        );
      }
      expect(got['en'], 'Continue');
      expect(got['ur'], isNot(got['en']));
      expect(got['ar'], isNot(got['en']));
      expect(got['ar'], isNot(got['ur']));
    });
  });
}

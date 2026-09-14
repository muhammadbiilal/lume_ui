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

/// The whole file, metadata included. The English one declares the
/// placeholder contract, and only `@key` entries carry it.
Map<String, dynamic> _raw(String code) =>
    jsonDecode(File('$_dir/app_$code.arb').readAsStringSync())
        as Map<String, dynamic>;

/// The placeholder names `key` declares, from `@key.placeholders`.
Set<String> _declared(Map<String, dynamic> raw, String key) {
  final Object? meta = raw['@$key'];
  if (meta is! Map<String, dynamic>) return const <String>{};
  final Object? ph = meta['placeholders'];
  if (ph is! Map<String, dynamic>) return const <String>{};
  return ph.keys.toSet();
}

/// Does this message actually reference `name`?
///
/// `{name}` or `{name, plural, …}` — and nothing else, because the first word
/// of a plural branch also sits behind a brace and is not a placeholder.
bool _uses(String message, String name) =>
    RegExp(r'\{\s*' + RegExp.escape(name) + r'\s*[},]').hasMatch(message);

/// The branch keys of a plural message: `=0`, `=1`, `one`, `few`, `other`.
Set<String> _branches(String message) => <String>{
  for (final RegExpMatch m in RegExp(
    r'(?:^|[{\s])(zero|one|two|few|many|other|=\d+)\s*\{',
  ).allMatches(message))
    m.group(1)!,
};

bool _isPlural(String message) =>
    RegExp(r'\{\s*\w+\s*,\s*plural\s*,').hasMatch(message);

bool _isSelect(String message) =>
    RegExp(r'\{\s*\w+\s*,\s*select\s*,').hasMatch(message);

/// A branch that means exactly one.
bool _hasSingular(String message) =>
    _branches(message).contains('=1') || _branches(message).contains('one');

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

    test('every string that has words in it is really translated', () {
      // The ratio above catches a file that was copied. This catches the
      // single key that was missed — which is the way it actually happens,
      // and which used to ship "3 signed in" to an Urdu reader.
      //
      // Two kinds of value are legitimately identical, and both are decided
      // by what the value *is* rather than by a list that would rot:
      //
      //  * a composition of placeholders and punctuation, which has no words
      //    to translate — `{high} / {low}`;
      //  * the named exceptions below, each a token rather than a phrase.
      const Set<String> allowed = <String>{
        // A sample address is a technical token.
        'authEmailPlaceholder',
        // An organisation's acronym. ISNA is ISNA in every language.
        'methodIsna',
        // Pakistan's Employees' Old-Age Benefits Institution, by its acronym —
        // the levy is named on payslips as EOBI in Arabic text too.
        'levyEobi',
        // The United Kingdom's non-emergency medical line, by the name printed
        // on it: NHS 111 is dialled and signed as NHS 111 in any language.
        'emergNameNhs111',
        // Currency & Gold: a price per unit and the share card's line are
        // only their placeholders and punctuation; the words arrive filled.
        'ratesPerUnit',
        'ratesShareText',
        // Flights: altitude and speed side by side, each already worded.
        'flightsCruiseSub',
        // Sample data in a tool's status line: a score, a dialling code, a
        // window of hours, an index, two operators, a tax year, a tally.
        // Fixture values, not sentences.
        'toolStatusCricket',
        'toolStatusEmergency',
        'toolStatusLoadshed',
        'toolStatusMarkets',
        'toolStatusPackages',
        'toolStatusTax',
        'toolStatusWater',
      };

      /// Anything left once the placeholders and the punctuation are gone.
      bool hasWords(String v) => v
          .replaceAll(RegExp(r'\{[^{}]*\}'), ' ')
          .replaceAll(RegExp(r'[^A-Za-z]'), ' ')
          .trim()
          .isNotEmpty;

      final List<String> missed = <String>[];
      for (final MapEntry<String, Map<String, String>> lang
          in <String, Map<String, String>>{'ur': ur, 'ar': ar}.entries) {
        for (final String key in en.keys) {
          if (allowed.contains(key)) continue;
          if (!hasWords(en[key]!)) continue;
          if (lang.value[key] == en[key]) missed.add('${lang.key}/$key');
        }
      }
      expect(missed, isEmpty, reason: 'still English: ${missed.join(', ')}');
    });

    test('and an exception is only an exception while it is one', () {
      // A key on the list that has since been translated, or has grown words
      // it did not have, should come off it rather than sit there excusing
      // nothing.
      for (final String key in <String>['authEmailPlaceholder', 'methodIsna']) {
        expect(en, contains(key), reason: '$key no longer exists');
        expect(
          ur[key],
          en[key],
          reason: '$key is translated now and can leave the list',
        );
      }
    });

    test('nothing tells a reader about their browser', () {
      // C49. The reference is a web page and says so — "check your browser's
      // storage settings", "allowed by your browser". A Flutter build has no
      // browser, and a sentence pointing a phone user at one is an
      // instruction they cannot follow.
      const Set<String> namesAPlatform = <String>{
        // One of five platform labels a session can carry, beside Android,
        // iPhone, Mac and Windows. It names a platform, never the reader's
        // own device.
        'acctDeviceBrowser',
      };
      for (final String key in en.keys) {
        if (namesAPlatform.contains(key)) continue;
        expect(
          en[key]!.toLowerCase(),
          isNot(contains('browser')),
          reason: '$key talks about a browser',
        );
      }
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

  group('placeholders', () {
    // A translation that drops a placeholder does not fail to build and does
    // not fall back: it renders a sentence with the number missing from it.
    final Map<String, dynamic> rawEn = _raw('en');

    test('every declared placeholder is used by the English string', () {
      for (final String key in en.keys) {
        for (final String name in _declared(rawEn, key)) {
          expect(
            _uses(en[key]!, name),
            isTrue,
            reason: '$key declares {$name} and never uses it',
          );
        }
      }
    });

    test('and by every translation of it', () {
      for (final MapEntry<String, Map<String, String>> lang
          in <String, Map<String, String>>{'ur': ur, 'ar': ar}.entries) {
        for (final String key in en.keys) {
          for (final String name in _declared(rawEn, key)) {
            expect(
              _uses(lang.value[key]!, name),
              isTrue,
              reason: '${lang.key}/$key drops {$name}',
            );
          }
        }
      }
    });

    test('and no translation invents a placeholder of its own', () {
      // Anything `gen_l10n` would treat as a placeholder but English never
      // declared. It would render as the literal brace text.
      final RegExp simple = RegExp(r'\{\s*(\w+)\s*\}');
      for (final MapEntry<String, Map<String, String>> lang
          in <String, Map<String, String>>{'ur': ur, 'ar': ar}.entries) {
        for (final String key in en.keys) {
          final Set<String> allowed = _declared(rawEn, key);
          for (final RegExpMatch m in simple.allMatches(lang.value[key]!)) {
            final String name = m.group(1)!;
            // A branch body of exactly one word looks the same to this
            // regular expression, so only names English also uses count.
            if (!simple.hasMatch(en[key]!) && !_uses(en[key]!, name)) continue;
            if (allowed.isEmpty) continue;
            expect(
              allowed.contains(name) || !_uses(en[key]!, name),
              isTrue,
              reason: '${lang.key}/$key uses an undeclared {$name}',
            );
          }
        }
      }
    });
  });

  group('plurals', () {
    test('a plural in English is a plural in every language', () {
      for (final MapEntry<String, Map<String, String>> lang
          in <String, Map<String, String>>{'ur': ur, 'ar': ar}.entries) {
        for (final String key in en.keys) {
          expect(
            _isPlural(lang.value[key]!),
            _isPlural(en[key]!),
            reason: '${lang.key}/$key disagrees about being a plural',
          );
          expect(
            _isSelect(lang.value[key]!),
            _isSelect(en[key]!),
            reason: '${lang.key}/$key disagrees about being a select',
          );
        }
      }
    });

    test('every plural has an "other", in every language', () {
      // ICU falls back to `other`, so a message without one has no fallback
      // at all for a count nobody enumerated.
      for (final MapEntry<String, Map<String, String>> lang
          in <String, Map<String, String>>{
            'en': en,
            'ur': ur,
            'ar': ar,
          }.entries) {
        for (final String key in lang.value.keys) {
          final String message = lang.value[key]!;
          if (!_isPlural(message)) continue;
          expect(
            _branches(message),
            contains('other'),
            reason: '${lang.key}/$key has no other branch',
          );
        }
      }
    });

    test('a language that counts one separately says so everywhere', () {
      // English and Urdu both have a singular. Where English distinguishes
      // one, Urdu must too, or an Urdu reader is told "1 trains" — which is
      // exactly what three Trains strings used to say.
      for (final String key in en.keys) {
        if (!_isPlural(en[key]!) || !_hasSingular(en[key]!)) continue;
        expect(
          _hasSingular(ur[key]!),
          isTrue,
          reason: 'ur/$key collapses the singular into the plural',
        );
      }
    });

    test('and Arabic is allowed to count further than English does', () {
      // Arabic has a dual and a paucal. Matching English branch-for-branch
      // would be the wrong kind of parity: what matters is that it covers at
      // least as much, never less.
      for (final String key in en.keys) {
        if (!_isPlural(en[key]!)) continue;
        final Set<String> enB = _branches(en[key]!);
        final Set<String> arB = _branches(ar[key]!);
        expect(
          arB.length,
          greaterThanOrEqualTo(enB.length),
          reason: 'ar/$key has fewer branches than English',
        );
      }
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

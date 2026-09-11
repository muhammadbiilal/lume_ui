/// The bundled fonts, verified from the binaries rather than from their names.
///
/// Three things are checked, and each catches a different failure:
///
/// * **Declaration** — every weight `pubspec.yaml` declares points at a file
///   whose `OS/2.usWeightClass` is that number. A Medium file declared at 600
///   would render, and render wrong.
/// * **Coverage** — every weight `LumeType` asks for has a real file. A missing
///   one makes Flutter synthesise, and a faux-bold Plus Jakarta is visibly not
///   Plus Jakarta.
/// * **Identity** — SHA-256, so a face swapped underneath the project fails a
///   test rather than silently redesigning the product.
library;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/theme/lume/lume_type.dart';

import '../../helpers/truetype.dart';

/// Recorded when the binaries were copied. Provenance is in
/// `assets/fonts/PROVENANCE.md`.
const Map<String, String> _checksums = <String, String>{
  'PlusJakartaSans-Regular.ttf':
      '076831b98043f50f829b6c91db3be4a844641f1c95bccff5c886ed87c661a852',
  'PlusJakartaSans-Medium.ttf':
      'b4fc14ec283d54236fd302cdb92546f98ae0ff061ca5ee23453a02bdf4628791',
  'PlusJakartaSans-SemiBold.ttf':
      '50357df108c5d297ec4ece76aeddf49561f3794f67af077cfc2c711b7a75b439',
  'PlusJakartaSans-Bold.ttf':
      '32971ad7976930539a11c79ce91ce84092df7f25c5be716b594601842f10a7ae',
  'PlusJakartaSans-ExtraBold.ttf':
      'd9e0ddb4a15a0054ad84b4ded3b4b9f354a0b7df426e21a1363d6933728da9d5',
  'NotoNaskhArabic-Regular.ttf':
      '67b5a525a661b607971fbd3f96a81b89d3a768e74534fca84f18ac97e6fab72f',
  'PlusJakartaSans-OFL.txt':
      '995c7199cab65954f545996326755daee7b63cc6b42b06c13da1f9502ab08a99',
  'NotoNaskhArabic-OFL.txt':
      'a7a5a25eb188bf1cd96982030d53e23c33485c69b1044a562254226857ee13af',
};

/// The weight each Plus Jakarta file must carry, per `pubspec.yaml`.
const Map<String, int> _declaredWeights = <String, int>{
  'PlusJakartaSans-Regular.ttf': 400,
  'PlusJakartaSans-Medium.ttf': 500,
  'PlusJakartaSans-SemiBold.ttf': 600,
  'PlusJakartaSans-Bold.ttf': 700,
  'PlusJakartaSans-ExtraBold.ttf': 800,
};

const String _dir = 'assets/fonts';

void main() {
  group('the files are present and unchanged', () {
    _checksums.forEach((String name, String want) {
      test('$name exists and matches its recorded SHA-256', () {
        final File f = File('$_dir/$name');
        expect(f.existsSync(), isTrue, reason: '$_dir/$name is missing');
        expect(
          sha256.convert(f.readAsBytesSync()).toString(),
          want,
          reason: '$name is not the binary this project was verified against',
        );
      });
    });
  });

  group('pubspec declares each weight against the right binary', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();

    _declaredWeights.forEach((String file, int weight) {
      test('$file is declared at $weight and is $weight', () {
        // The declaration, read from the manifest rather than assumed.
        final RegExp decl = RegExp(
          r'asset:\s*assets/fonts/' +
              RegExp.escape(file) +
              r'\s*\n\s*weight:\s*(\d+)',
        );
        final RegExpMatch? m = decl.firstMatch(pubspec);
        expect(m, isNotNull, reason: '$file is not declared in pubspec.yaml');
        expect(
          int.parse(m!.group(1)!),
          weight,
          reason: 'pubspec declares the wrong weight for $file',
        );

        // The fact, read from the binary.
        final FontFacts facts = FontFacts.read('$_dir/$file');
        expect(
          facts.weightClass,
          weight,
          reason:
              '$file carries usWeightClass ${facts.weightClass}, but is '
              'declared at $weight — Flutter would render the wrong cut',
        );
      });
    });

    test('every declared Plus Jakarta file is the Plus Jakarta family', () {
      for (final String file in _declaredWeights.keys) {
        final FontFacts facts = FontFacts.read('$_dir/$file');
        expect(
          facts.effectiveFamily,
          'Plus Jakarta Sans',
          reason: '$file reports ${facts.effectiveFamily}',
        );
      }
    });

    test('none of them is italic', () {
      for (final String file in _declaredWeights.keys) {
        expect(FontFacts.read('$_dir/$file').isItalic, isFalse, reason: file);
      }
    });

    test('all five share one units-per-em, so the scale is one scale', () {
      final Set<int> upem = _declaredWeights.keys
          .map((String f) => FontFacts.read('$_dir/$f').unitsPerEm)
          .toSet();
      expect(upem, hasLength(1));
    });
  });

  group('Flutter never has to synthesise a weight', () {
    test('every weight the type scale uses has a real file', () {
      final Set<int> declared = _declaredWeights.values.toSet();
      final Set<int> used = LumeType.standard.all.values
          .map((TextStyle s) => s.fontWeight!.value)
          .toSet();
      expect(
        used.difference(declared),
        isEmpty,
        reason:
            'the type scale asks for a weight with no bundled file; '
            'Flutter would synthesise it',
      );
    });

    test('all five weights 400-800 are covered', () {
      expect(_declaredWeights.values.toSet(), <int>{400, 500, 600, 700, 800});
    });
  });

  group('the Arabic face', () {
    late FontFacts noto;

    setUpAll(() {
      noto = FontFacts.read('$_dir/NotoNaskhArabic-Regular.ttf');
    });

    test('is Noto Naskh Arabic', () {
      expect(noto.effectiveFamily, 'Noto Naskh Arabic');
    });

    test('is variable, with a wght axis', () {
      expect(noto.isVariable, isTrue);
      expect(noto.weightAxis, isNotNull);
    });

    test('covers 400-700, which is what the reference loads', () {
      // The reference's font URL asks for 400;600;700. One binary covers all
      // three, so the heavier cuts are axis positions rather than synthesised.
      expect(noto.weightAxis!.min, lessThanOrEqualTo(400));
      expect(noto.weightAxis!.max, greaterThanOrEqualTo(700));
    });

    test('the reading style stays inside the axis range', () {
      for (final FontWeight w in <FontWeight>[
        FontWeight.w400,
        FontWeight.w600,
        FontWeight.w700,
      ]) {
        final TextStyle s = LumeType.arabic(weight: w);
        final FontVariation v = s.fontVariations!.firstWhere(
          (FontVariation f) => f.axis == 'wght',
        );
        expect(
          v.value,
          inInclusiveRange(noto.weightAxis!.min, noto.weightAxis!.max),
        );
      }
    });
  });

  group('licensing', () {
    test('both families carry an OFL file', () {
      expect(File('$_dir/PlusJakartaSans-OFL.txt').existsSync(), isTrue);
      expect(File('$_dir/NotoNaskhArabic-OFL.txt').existsSync(), isTrue);
    });

    test('each licence names the copyright its binary declares', () {
      final Map<String, String> pairs = <String, String>{
        'PlusJakartaSans-Regular.ttf': 'PlusJakartaSans-OFL.txt',
        'NotoNaskhArabic-Regular.ttf': 'NotoNaskhArabic-OFL.txt',
      };
      pairs.forEach((String font, String licence) {
        final String declared = FontFacts.read('$_dir/$font').copyright.trim();
        final String text = File('$_dir/$licence').readAsStringSync();
        expect(
          text,
          contains(declared),
          reason: '$licence does not carry the copyright line in $font',
        );
      });
    });

    test('both licences are the SIL Open Font License 1.1', () {
      for (final String f in <String>[
        'PlusJakartaSans-OFL.txt',
        'NotoNaskhArabic-OFL.txt',
      ]) {
        expect(
          File('$_dir/$f').readAsStringSync(),
          contains('SIL OPEN FONT LICENSE Version 1.1'),
          reason: f,
        );
      }
    });

    test('provenance is recorded', () {
      final File p = File('$_dir/PROVENANCE.md');
      expect(p.existsSync(), isTrue);
      final String text = p.readAsStringSync();
      for (final String name in _checksums.keys) {
        expect(text, contains(name), reason: '$name is not in PROVENANCE.md');
      }
    });
  });

  group('nothing unused is bundled', () {
    test('the fonts directory holds only what the product uses', () {
      final Set<String> present = Directory(_dir)
          .listSync()
          .whereType<File>()
          .map((File f) => f.uri.pathSegments.last)
          .toSet();
      final Set<String> expected = <String>{
        ..._checksums.keys,
        'PROVENANCE.md',
      };
      expect(
        present.difference(expected),
        isEmpty,
        reason: 'an unused font is dead weight in every build',
      );
    });
  });
}

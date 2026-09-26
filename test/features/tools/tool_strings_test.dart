/// Every tool's source line reads in the reader's language (§11): each
/// catalogue `fallbackSource` has a key, and Urdu and Arabic do not fall
/// back to the English.
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/tools/presentation/tool_strings.dart';
import 'package:lume/l10n/app_localizations.dart';

void main() {
  final Set<String> sources = <String>{
    for (final LumeFeature f in kLumeFeatures) f.fallbackSource,
  };

  test('every source the catalogue declares has a key', () {
    final AppLocalizations en = lookupAppLocalizations(const Locale('en'));
    final List<String> missing = <String>[
      for (final String s in sources)
        if (LumeToolStrings.sourceName(en, s) == null) s,
    ];
    expect(missing, isEmpty);
  });

  test('in English each key says what the catalogue says', () {
    final AppLocalizations en = lookupAppLocalizations(const Locale('en'));
    for (final String s in sources) {
      expect(LumeToolStrings.sourceName(en, s), s);
    }
  });

  for (final String lang in <String>['ur', 'ar']) {
    test('$lang: no source is left in English', () {
      final AppLocalizations l = lookupAppLocalizations(Locale(lang));
      final List<String> untranslated = <String>[
        for (final String s in sources)
          if (LumeToolStrings.sourceName(l, s) == s) s,
      ];
      expect(untranslated, isEmpty);
    });
  }
}

/// "Follow my region" on screen: a country with several zones and no city
/// to decide asks for one, in every language; the zone a region resolves
/// to does not move with the language.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/features/events/presentation/events_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/todos/presentation/todos_tool.dart';
import 'package:lume/l10n/app_localizations.dart';
import 'package:lume/l10n/app_localizations_ar.dart';
import 'package:lume/l10n/app_localizations_en.dart';
import 'package:lume/l10n/app_localizations_ur.dart';

import '../../helpers/load_fonts.dart';
import '../tax/tax_harness.dart';
import 'wave2_harness.dart';

LumeProfileRepository reader(String country, String region, String city) =>
    LumeMemoryProfileRepository(
      initial: taxReader(country: country, region: region, city: city),
    );

void main() {
  setUpAll(loadLumeFonts);

  for (final (Locale locale, AppLocalizations l)
      in <(Locale, AppLocalizations)>[
        (const Locale('en'), AppLocalizationsEn()),
        (const Locale('ur'), AppLocalizationsUr()),
        (const Locale('ar'), AppLocalizationsAr()),
      ]) {
    testWidgets('To-dos in the United States with no city: a zone to '
        'choose, not a day guessed (${locale.languageCode})', (
      WidgetTester t,
    ) async {
      await pumpWave2(
        t,
        'todos',
        locale: locale,
        profile: reader('US', 'New York', ''),
      );
      final Finder state = find.byKey(LumeTodosTool.dayUnknownKey);
      expect(state, findsOneWidget);
      final LumeToolState s = t.widget(
        find.descendant(of: state, matching: find.byType(LumeToolState)),
      );
      expect(s.title, l.recZoneUnknownTitle);
      expect(s.text, l.recZoneChooseText);
    });
  }

  testWidgets('New York\'s zone is one zone in English, Urdu and Arabic, '
      'each naming it in CLDR\'s words', (WidgetTester t) async {
    for (final (Locale locale, String name) in <(Locale, String)>[
      (const Locale('en'), 'New York Time'),
      (const Locale('ur'), 'نیو یارک وقت'),
      (const Locale('ar'), 'توقيت نيويورك'),
    ]) {
      await pumpWave2(
        t,
        'events',
        locale: locale,
        profile: reader('US', 'New York', 'New York'),
      );
      expect(find.byKey(LumeEventsTool.dayUnknownKey), findsNothing);
      await tapVisible(t, find.byType(LumeRecordRow).first);
      expect(
        find.textContaining('\u2068$name\u2069'),
        findsWidgets,
        reason: locale.languageCode,
      );
    }
  });
}

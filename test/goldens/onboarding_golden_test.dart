/// Golden and capture coverage for the two F4A steps.
///
/// Two jobs in one file, because both need the same six cells set up the same
/// way:
///
/// * **Goldens** freeze what the parity tests agreed, and are committed.
/// * **Captures** write `.flutter.png` next to the `.web.png` the web tool
///   produces, so `compare.mjs` can put them side by side. Those are working
///   artefacts and are gitignored (Q7).
///
/// The six cells are the ones F4A asks for: 390×844 in English light, dark and
/// Urdu; then 700×900, 1100×900 and 852×393.
///
/// Both screens are given the **same fixture state** as the web capture: the
/// country step opens on Pakistan with no recent countries, and the interests
/// step opens with nothing selected and the faith switch off — which is what a
/// first run is, and what `capture_web.mjs --step` reaches by pressing the
/// flow's own Continue.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/onboarding/data/country_fixture.dart';
import 'package:lume/features/onboarding/data/interests_fixture.dart';
import 'package:lume/features/onboarding/presentation/onboarding_steps.dart';

import '../helpers/capture.dart';
import '../helpers/load_fonts.dart';
import '../helpers/lume_harness.dart';

/// One comparison cell.
typedef Cell = ({String name, Size surface, ThemeMode theme, Locale locale});

const List<Cell> kOnboardingCells = <Cell>[
  (
    name: '390 light en',
    surface: Size(390, 844),
    theme: ThemeMode.light,
    locale: Locale('en'),
  ),
  (
    name: '390 dark en',
    surface: Size(390, 844),
    theme: ThemeMode.dark,
    locale: Locale('en'),
  ),
  (
    name: '390 light ur',
    surface: Size(390, 844),
    theme: ThemeMode.light,
    locale: Locale('ur'),
  ),
  (
    name: '700 light en',
    surface: Size(700, 900),
    theme: ThemeMode.light,
    locale: Locale('en'),
  ),
  (
    name: '1100 light en',
    surface: Size(1100, 900),
    theme: ThemeMode.light,
    locale: Locale('en'),
  ),
  (
    name: '852 light en',
    surface: Size(852, 393),
    theme: ThemeMode.light,
    locale: Locale('en'),
  ),
];

void main() {
  setUpAll(loadLumeFonts);

  final LumeCountryFixture countries = LumeCountryFixture.parse(
    File('assets/data/countries.json').readAsStringSync(),
  );
  final LumeInterestsFixture interests = LumeInterestsFixture.parse(
    File('assets/data/interests.json').readAsStringSync(),
  );

  Widget country() => CountryStep(
    countries: countries,
    onBack: () {},
    onSkip: () {},
    onContinue: (_) {},
  );

  Widget interestsStep() => InterestsStep(
    catalogue: interests,
    onBack: () {},
    onSkip: () {},
    onContinue: (Set<String> s, bool i) {},
  );

  String slug(Cell c) =>
      '${c.surface.width.round()}_${c.theme == ThemeMode.dark ? 'dark' : 'light'}'
      '_${c.locale.languageCode}';

  group('country goldens', () {
    for (final Cell cell in kOnboardingCells) {
      testWidgets(cell.name, (WidgetTester tester) async {
        await pumpLume(
          tester,
          country(),
          surface: cell.surface,
          theme: cell.theme,
          locale: cell.locale,
        );
        await expectLater(
          find.byType(CountryStep),
          matchesGoldenFile('images/onb_country_${slug(cell)}.png'),
        );
      });
    }
  });

  group('interests goldens', () {
    for (final Cell cell in kOnboardingCells) {
      testWidgets(cell.name, (WidgetTester tester) async {
        await pumpLume(
          tester,
          interestsStep(),
          surface: cell.surface,
          theme: cell.theme,
          locale: cell.locale,
        );
        await expectLater(
          find.byType(InterestsStep),
          matchesGoldenFile('images/onb_interests_${slug(cell)}.png'),
        );
      });
    }
  });

  group('the states the phase asks for', () {
    testWidgets('country · searching', (WidgetTester tester) async {
      await pumpLume(tester, country(), surface: const Size(390, 844));
      await tester.enterText(find.byType(TextField).first, 'united');
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CountryStep),
        matchesGoldenFile('images/onb_country_search.png'),
      );
    });

    testWidgets('country · no results', (WidgetTester tester) async {
      await pumpLume(tester, country(), surface: const Size(390, 844));
      await tester.enterText(find.byType(TextField).first, 'qqqqq');
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CountryStep),
        matchesGoldenFile('images/onb_country_no_results.png'),
      );
    });

    testWidgets('country · with recent countries', (WidgetTester tester) async {
      await pumpLume(
        tester,
        CountryStep(
          countries: countries,
          recent: LumeCountryFixtureState.someRecent,
          onBack: () {},
          onSkip: () {},
        ),
        surface: const Size(390, 844),
      );
      await expectLater(
        find.byType(CountryStep),
        matchesGoldenFile('images/onb_country_recent.png'),
      );
    });

    testWidgets('interests · minimum reached', (WidgetTester tester) async {
      await pumpLume(
        tester,
        InterestsStep(
          catalogue: interests,
          initialSelection: const <String>{
            'weather',
            'calendar',
            'tasks',
            'notes',
            'maths',
          },
          onBack: () {},
          onSkip: () {},
        ),
        surface: const Size(390, 844),
      );
      await expectLater(
        find.byType(InterestsStep),
        matchesGoldenFile('images/onb_interests_minimum.png'),
      );
    });

    testWidgets('interests · at the cap', (WidgetTester tester) async {
      await pumpLume(
        tester,
        InterestsStep(
          catalogue: interests,
          initialSelection: interests.allIds
              .where((String id) => !interests.faithInterests.contains(id))
              .take(10)
              .toSet(),
          initialFaithOpen: false,
          onBack: () {},
          onSkip: () {},
        ),
        surface: const Size(390, 844),
      );
      await expectLater(
        find.byType(InterestsStep),
        matchesGoldenFile('images/onb_interests_at_cap.png'),
      );
    });

    testWidgets('interests · the faith switch on', (WidgetTester tester) async {
      await pumpLume(
        tester,
        InterestsStep(
          catalogue: interests,
          initialSelection: const <String>{'prayer', 'quran', 'duas'},
          initialFaithOpen: true,
          onBack: () {},
          onSkip: () {},
        ),
        surface: const Size(390, 1400),
      );
      await expectLater(
        find.byType(InterestsStep),
        matchesGoldenFile('images/onb_interests_faith_open.png'),
      );
    });

    testWidgets('interests · 200 per cent text', (WidgetTester tester) async {
      await pumpLume(
        tester,
        interestsStep(),
        surface: const Size(390, 844),
        textScale: 2.0,
      );
      await expectLater(
        find.byType(InterestsStep),
        matchesGoldenFile('images/onb_interests_text200.png'),
      );
    });
  });

  // The captures the comparison pairs with the web ones. Not committed; see
  // `.gitignore` and Q7.
  group('captures for the comparison', () {
    for (final Cell cell in kOnboardingCells) {
      testWidgets('country · ${cell.name}', (WidgetTester tester) async {
        await captureLume(
          tester,
          country(),
          name: 'onb_country',
          surface: cell.surface,
          theme: cell.theme,
          locale: cell.locale,
          suffix: '_step3',
          outDir: 'docs/conversion_archive/shots/onboarding',
        );
      });

      testWidgets('interests · ${cell.name}', (WidgetTester tester) async {
        await captureLume(
          tester,
          interestsStep(),
          name: 'onb_interests',
          surface: cell.surface,
          theme: cell.theme,
          locale: cell.locale,
          suffix: '_step5',
          outDir: 'docs/conversion_archive/shots/onboarding',
        );
      });
    }
  });
}

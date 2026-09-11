/// Every step of the onboarding flow, rendered and frozen.
///
/// The F4A file covers the two screens it built as components. This one covers
/// the **flow**: all nine steps, each pumped through `LumeOnboardingFlow` so
/// what is frozen is the composition the app actually shows — chrome, step,
/// footer and all — rather than a step widget mounted on its own.
///
/// Two jobs, as in F4A:
///
/// * **Goldens** are committed, and are the visual evidence for the phase.
/// * **Captures** write `.flutter.png` beside the `.web.png` that
///   `capture_web.mjs --step N` produces, so `compare.mjs` can pair them.
///   Working artefacts, gitignored.
///
/// The cells are the ones F4B asks for: 390×844 in English light, dark, Urdu
/// and Arabic; 359×844 for the narrowest supported phone; 700×900 and
/// 1100×900 for the two larger classes; and 852×393 for a phone held sideways,
/// which is the compact-height override. 200 per cent text and an open
/// keyboard have their own goldens at the end, on the steps where they bite.
///
/// **State.** Steps 0–5 open as a first run does. Steps 6–8 open with the
/// Islamic experience on, because that is the composition with something in
/// it — the method block exists, and the permission subtitles and the
/// completion copy all change with it. The web captures for those three steps
/// are taken with `--faith 1` for the same reason, and the off variants are
/// held as their own state goldens.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/onboarding/data/country_fixture.dart';
import 'package:lume/features/onboarding/data/interests_fixture.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/presentation/onboarding_flow.dart';

import '../helpers/capture.dart';
import '../helpers/load_fonts.dart';
import '../helpers/lume_harness.dart';
import 'onboarding_golden_test.dart' show Cell;

/// The eight cells the phase asks to see.
const List<Cell> kFlowCells = <Cell>[
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
    name: '390 light ar',
    surface: Size(390, 844),
    theme: ThemeMode.light,
    locale: Locale('ar'),
  ),
  (
    name: '359 light en',
    surface: Size(359, 844),
    theme: ThemeMode.light,
    locale: Locale('en'),
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

/// The nine steps, by the name the golden files carry.
const List<(int, String)> kSteps = <(int, String)>[
  (LumeOnboardingStep.welcome, 'welcome'),
  (LumeOnboardingStep.plan, 'plan'),
  (LumeOnboardingStep.tools, 'tools'),
  (LumeOnboardingStep.country, 'country'),
  (LumeOnboardingStep.city, 'city'),
  (LumeOnboardingStep.interests, 'interests'),
  (LumeOnboardingStep.setUp, 'setup'),
  (LumeOnboardingStep.name, 'name'),
  (LumeOnboardingStep.done, 'done'),
];

void main() {
  setUpAll(loadLumeFonts);

  final LumeCountryFixture countries = LumeCountryFixture.parse(
    File('assets/data/countries.json').readAsStringSync(),
  );
  final LumeInterestsFixture catalogue = LumeInterestsFixture.parse(
    File('assets/data/interests.json').readAsStringSync(),
  );

  /// The last three steps are worth seeing with the experience on.
  bool faithFor(int step) => step >= LumeOnboardingStep.setUp;

  Widget flow(int step, {bool? islamic, String name = ''}) =>
      LumeOnboardingFlow(
        countries: countries,
        catalogue: catalogue,
        store: LumeMemoryOnboardingStore(
          LumeProfileRecord(
            islamic: islamic ?? faithFor(step),
            displayName: name,
          ),
        ),
        initialStep: step,
        // Named so the completion step says a prayer rather than falling back
        // to the neutral sentence, which is its other state and has its own
        // golden.
        nextPrayerName: 'Asr',
      );

  String slug(Cell c) =>
      '${c.surface.width.round()}_${c.theme == ThemeMode.dark ? 'dark' : 'light'}'
      '_${c.locale.languageCode}';

  group('every step, everywhere', () {
    for (final (int step, String label) in kSteps) {
      for (final Cell cell in kFlowCells) {
        testWidgets('$label · ${cell.name}', (WidgetTester tester) async {
          await pumpLume(
            tester,
            flow(step),
            surface: cell.surface,
            theme: cell.theme,
            locale: cell.locale,
          );
          await expectLater(
            find.byType(LumeOnboardingFlow),
            matchesGoldenFile('images/onb_${label}_${slug(cell)}.png'),
          );
        });
      }
    }
  });

  group('the states the phase asks for', () {
    testWidgets('set up · without the experience', (WidgetTester t) async {
      await pumpLume(t, flow(LumeOnboardingStep.setUp, islamic: false));
      await expectLater(
        find.byType(LumeOnboardingFlow),
        matchesGoldenFile('images/onb_setup_no_faith.png'),
      );
    });

    testWidgets('done · without the experience', (WidgetTester t) async {
      await pumpLume(t, flow(LumeOnboardingStep.done, islamic: false));
      await expectLater(
        find.byType(LumeOnboardingFlow),
        matchesGoldenFile('images/onb_done_no_faith.png'),
      );
    });

    testWidgets('name · prefilled', (WidgetTester tester) async {
      await pumpLume(tester, flow(LumeOnboardingStep.name, name: 'Bilal'));
      await expectLater(
        find.byType(LumeOnboardingFlow),
        matchesGoldenFile('images/onb_name_prefilled.png'),
      );
    });

    testWidgets('name · with the keyboard up', (WidgetTester tester) async {
      await pumpLume(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewInsets: const EdgeInsets.only(bottom: 320)),
            child: flow(LumeOnboardingStep.name),
          ),
        ),
      );
      await expectLater(
        find.byType(LumeOnboardingFlow),
        matchesGoldenFile('images/onb_name_keyboard.png'),
      );
    });

    for (final (int step, String label) in <(int, String)>[
      (LumeOnboardingStep.welcome, 'welcome'),
      (LumeOnboardingStep.city, 'city'),
      (LumeOnboardingStep.setUp, 'setup'),
      (LumeOnboardingStep.done, 'done'),
    ]) {
      testWidgets('$label · 200 per cent text', (WidgetTester tester) async {
        await pumpLume(tester, flow(step), textScale: 2.0);
        await expectLater(
          find.byType(LumeOnboardingFlow),
          matchesGoldenFile('images/onb_${label}_text200.png'),
        );
      });
    }
  });

  // Paired with the web captures by `compare.mjs`. Gitignored — see Q7.
  group('captures for the comparison', () {
    for (final (int step, String label) in kSteps) {
      for (final Cell cell in kFlowCells) {
        testWidgets('$label · ${cell.name}', (WidgetTester tester) async {
          await captureLume(
            tester,
            flow(step),
            name: 'onb_$label',
            surface: cell.surface,
            theme: cell.theme,
            locale: cell.locale,
            suffix: '_step$step',
            outDir: 'docs/conversion_archive/shots/onboarding',
          );
        });
      }
    }
  });
}

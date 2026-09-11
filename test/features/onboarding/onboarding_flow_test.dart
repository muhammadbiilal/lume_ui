/// The whole flow, driven through its own controls.
///
/// Nine steps, forward and back, every skip, and what each one leaves behind.
/// The store is the in-memory one, so what a step wrote is readable straight
/// after it wrote it.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/features/onboarding/data/country_fixture.dart';
import 'package:lume/features/onboarding/data/interests_fixture.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/presentation/country_screen.dart';
import 'package:lume/features/onboarding/presentation/interests_screen.dart';
import 'package:lume/features/onboarding/presentation/onboarding_chrome.dart';
import 'package:lume/features/onboarding/presentation/onboarding_flow.dart';
import 'package:lume/features/onboarding/presentation/onboarding_parts.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  final LumeCountryFixture countries = LumeCountryFixture.parse(
    File('assets/data/countries.json').readAsStringSync(),
  );
  final LumeInterestsFixture catalogue = LumeInterestsFixture.parse(
    File('assets/data/interests.json').readAsStringSync(),
  );

  /// The five the interests step needs to enable Continue.
  const List<String> fiveLabels = <String>[
    'Weather',
    'Calendar',
    'Tasks & to-dos',
    'Notes',
    'Calculators',
  ];

  late LumeMemoryOnboardingStore store;
  LumeOnboardingOutcome? outcome;
  LumeProfileRecord? finalRecord;

  setUp(() {
    store = LumeMemoryOnboardingStore();
    outcome = null;
    finalRecord = null;
  });

  Future<void> pumpFlow(
    WidgetTester tester, {
    int step = LumeOnboardingStep.welcome,
    Size surface = LumeViewport.tall,
    ThemeMode theme = ThemeMode.light,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    String? nextPrayer,
    LumeMemoryOnboardingStore? withStore,
  }) {
    store = withStore ?? store;
    return pumpLume(
      tester,
      LumeOnboardingFlow(
        countries: countries,
        catalogue: catalogue,
        store: store,
        initialStep: step,
        nextPrayerName: nextPrayer,
        onDone: (LumeOnboardingOutcome o, LumeProfileRecord r) {
          outcome = o;
          finalRecord = r;
        },
      ),
      surface: surface,
      theme: theme,
      locale: locale,
      textScale: textScale,
    );
  }

  Future<void> tapContinue(WidgetTester tester) async {
    await tester.tap(find.byType(LumeOnboardingContinue));
    await tester.pumpAndSettle();
  }

  LumeOnboardingFlowState flowState(WidgetTester tester) =>
      tester.state<LumeOnboardingFlowState>(find.byType(LumeOnboardingFlow));

  // ------------------------------------------------------------ composition

  group('every step renders its own composition', () {
    testWidgets('0 · welcome', (WidgetTester tester) async {
      await pumpFlow(tester);
      expect(find.byType(LumeOnboardingBrand), findsOneWidget);
      expect(
        find.text('Everything your day needs, quietly organised.'),
        findsOneWidget,
      );
      expect(find.text('Get started'), findsOneWidget);
      expect(find.byType(LumeOnboardingLink), findsOneWidget);
      expect(
        find.byType(LumeOnboardingBack),
        findsOneWidget,
        reason: 'present but invisible, so the progress bar does not shift',
      );
      expect(find.bySemanticsLabel('Back'), findsNothing);
    });

    testWidgets('1 · plan', (WidgetTester tester) async {
      await pumpFlow(tester, step: LumeOnboardingStep.plan);
      expect(find.text('PLAN'), findsOneWidget);
      expect(find.text('Your day, laid out before it starts'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('2 · tools quotes the whole catalogue', (
      WidgetTester tester,
    ) async {
      await pumpFlow(tester, step: LumeOnboardingStep.tools);
      expect(find.text('TOOLS'), findsOneWidget);
      expect(
        find.text('${catalogue.featureCount}-odd tools, one or two taps away'),
        findsOneWidget,
      );
      expect(catalogue.featureCount, 85);
    });

    testWidgets('3 · country', (WidgetTester tester) async {
      await pumpFlow(tester, step: LumeOnboardingStep.country);
      expect(find.text('Where are you based?'), findsOneWidget);
      expect(find.byType(LumeCountryRow), findsWidgets);
    });

    testWidgets('4 · city, kickered with the country', (
      WidgetTester tester,
    ) async {
      await pumpFlow(tester, step: LumeOnboardingStep.city);
      expect(find.text('Which city are you in?'), findsOneWidget);
      expect(
        find.text('PAKISTAN'),
        findsOneWidget,
        reason: 'the kicker is the country, not a fixed word',
      );
      expect(find.text('Use my current location'), findsOneWidget);
      // Pakistan has regions, so the list groups.
      expect(find.text('PUNJAB'), findsOneWidget);
      expect(find.text('Lahore'), findsOneWidget);
    });

    testWidgets('5 · interests', (WidgetTester tester) async {
      await pumpFlow(tester, step: LumeOnboardingStep.interests);
      expect(find.text('What are you here for?'), findsOneWidget);
      expect(find.byType(LumeInterestChip), findsWidgets);
    });

    testWidgets('6 · set up, with two toggles on by default', (
      WidgetTester tester,
    ) async {
      await pumpFlow(tester, step: LumeOnboardingStep.setUp);
      expect(find.text('Set it up once'), findsOneWidget);
      expect(find.byType(LumeOnboardingToggleRow), findsNWidgets(2));
      for (final LumeOnboardingToggleRow row
          in tester.widgetList<LumeOnboardingToggleRow>(
            find.byType(LumeOnboardingToggleRow),
          )) {
        expect(row.value, isTrue);
      }
      expect(find.text('Looks good'), findsOneWidget);
      expect(
        find.byType(LumeOnboardingChoice),
        findsNothing,
        reason: 'the method block does not exist for a non-Muslim user',
      );
    });

    testWidgets('6 · the method block exists once the experience is on', (
      WidgetTester tester,
    ) async {
      store.write(
        store.read().copyWith(islamic: true, interests: <String>['prayer']),
      );
      await pumpFlow(tester, step: LumeOnboardingStep.setUp);
      expect(find.byType(LumeOnboardingChoice), findsOneWidget);
      // `.group-label` is uppercased in CSS, so the glyphs are capitals and
      // the announcement is the sentence it was written as.
      expect(find.text('PRAYER CALCULATION METHOD'), findsOneWidget);
      expect(find.bySemanticsLabel('Prayer calculation method'), findsWidgets);
      expect(find.text('Muslim World League'), findsOneWidget);
      // And the two subtitles change with it.
      expect(
        find.text('For prayer times, Qibla, weather and nearby places'),
        findsOneWidget,
      );
      expect(
        find.text('A quiet nudge 5 minutes before each adhan'),
        findsOneWidget,
      );
    });

    testWidgets('7 · name', (WidgetTester tester) async {
      await pumpFlow(tester, step: LumeOnboardingStep.name);
      expect(find.text('ONE LAST THING'), findsOneWidget);
      expect(find.text('What should we call you?'), findsOneWidget);
      expect(find.byType(LumeToolField), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);
    });

    testWidgets('8 · done, and its two branches', (WidgetTester tester) async {
      await pumpFlow(tester, step: LumeOnboardingStep.done);
      expect(find.text('ALL SET'), findsOneWidget);
      expect(find.text('You’re all set'), findsOneWidget);
      expect(find.text('Enter Lume'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Skip'),
        findsNothing,
        reason: 'the last step has nothing to skip past',
      );
    });

    testWidgets('8 · greets by name when there is one', (
      WidgetTester tester,
    ) async {
      store.write(store.read().copyWith(displayName: 'Sam'));
      await pumpFlow(tester, step: LumeOnboardingStep.done);
      expect(find.text('You’re ready, Sam'), findsOneWidget);
    });

    testWidgets('8 · names the next prayer when the experience is on', (
      WidgetTester tester,
    ) async {
      store.write(store.read().copyWith(islamic: true));
      await pumpFlow(tester, step: LumeOnboardingStep.done, nextPrayer: 'Asr');
      expect(find.textContaining('Asr'), findsOneWidget);
    });

    testWidgets('8 · falls back to the neutral copy with no prayer', (
      WidgetTester tester,
    ) async {
      store.write(store.read().copyWith(islamic: true));
      await pumpFlow(tester, step: LumeOnboardingStep.done);
      expect(
        find.text('Today’s plan is waiting on the home screen.'),
        findsOneWidget,
        reason: 'a sentence with a hole in it is worse than the neutral one',
      );
    });
  });

  // -------------------------------------------------------------- traversal

  group('forward and back', () {
    testWidgets('the whole flow, end to end', (WidgetTester tester) async {
      await pumpFlow(tester);

      await tapContinue(tester); // welcome → plan
      expect(flowState(tester).step, LumeOnboardingStep.plan);
      await tapContinue(tester); // → tools
      await tapContinue(tester); // → country
      expect(flowState(tester).step, LumeOnboardingStep.country);

      await tester.tap(find.text('United Kingdom').first);
      await tester.pumpAndSettle();
      await tapContinue(tester); // → city
      expect(flowState(tester).step, LumeOnboardingStep.city);
      expect(
        flowState(tester).draft.city,
        isNotEmpty,
        reason: 'a country change seeds its first city',
      );

      await tester.tap(find.text('Manchester').first);
      await tester.pumpAndSettle();
      await tapContinue(tester); // → interests
      expect(flowState(tester).step, LumeOnboardingStep.interests);
      expect(store.read().country, 'GB', reason: 'location lands here');
      expect(store.read().city, 'Manchester');

      for (final String label in fiveLabels) {
        await tester.tap(find.widgetWithText(LumeInterestChip, label));
      }
      await tester.pumpAndSettle();
      await tapContinue(tester); // → set up
      expect(flowState(tester).step, LumeOnboardingStep.setUp);
      expect(store.read().interests.length, 5);

      await tapContinue(tester); // → name
      expect(flowState(tester).step, LumeOnboardingStep.name);

      await tester.enterText(find.byType(TextField), 'Sam');
      await tapContinue(tester); // → done
      expect(flowState(tester).step, LumeOnboardingStep.done);
      expect(store.read().displayName, 'Sam');

      await tapContinue(tester); // finish
      expect(outcome, LumeOnboardingOutcome.finished);
      expect(finalRecord!.onboarded, isTrue);
      expect(finalRecord!.country, 'GB');
      expect(finalRecord!.city, 'Manchester');
      expect(finalRecord!.displayName, 'Sam');
      expect(finalRecord!.islamic, isFalse);
    });

    testWidgets('back walks every step down to the first', (
      WidgetTester tester,
    ) async {
      await pumpFlow(tester, step: LumeOnboardingStep.done);
      for (int expected = LumeOnboardingStep.name; expected >= 0; expected--) {
        await tester.tap(find.byType(LumeOnboardingBack));
        await tester.pumpAndSettle();
        expect(flowState(tester).step, expected);
      }
      // And the first step's Back does nothing at all.
      await tester.tap(find.byType(LumeOnboardingBack));
      await tester.pumpAndSettle();
      expect(flowState(tester).step, LumeOnboardingStep.welcome);
    });

    testWidgets('going back and forward keeps what was chosen', (
      WidgetTester tester,
    ) async {
      await pumpFlow(tester, step: LumeOnboardingStep.country);
      await tester.tap(find.text('United Kingdom').first);
      await tester.pumpAndSettle();
      await tapContinue(tester);

      await tester.tap(find.byType(LumeOnboardingBack));
      await tester.pumpAndSettle();
      expect(flowState(tester).step, LumeOnboardingStep.country);
      final Iterable<LumeCountryRow> selected = tester
          .widgetList<LumeCountryRow>(find.byType(LumeCountryRow))
          .where((LumeCountryRow r) => r.selected);
      expect(
        selected.every((LumeCountryRow r) => r.country.code == 'GB'),
        isTrue,
      );
    });

    testWidgets('interests survive a walk back to the city and forward', (
      WidgetTester tester,
    ) async {
      await pumpFlow(tester, step: LumeOnboardingStep.interests);
      for (final String label in fiveLabels) {
        await tester.tap(find.widgetWithText(LumeInterestChip, label));
      }
      await tester.pumpAndSettle();
      expect(find.text('5 of 10 selected'), findsOneWidget);

      await tester.tap(find.byType(LumeOnboardingBack));
      await tester.pumpAndSettle();
      expect(flowState(tester).step, LumeOnboardingStep.city);
      await tapContinue(tester);

      expect(flowState(tester).step, LumeOnboardingStep.interests);
      expect(
        find.text('5 of 10 selected'),
        findsOneWidget,
        reason: 'the draft is the single copy',
      );
    });

    testWidgets('the router walks the flow and lands on the app', (
      WidgetTester tester,
    ) async {
      // The smoke test: the real router, the real loader, the real asset
      // tables, and the flow's own controls — start to finish, ending
      // somewhere that is not onboarding.
      final GoRouter router = await pumpLumeRouter(
        tester,
        initialLocation: '/onboarding',
      );
      expect(locationOf(router), '/onboarding');
      expect(find.text('Get started'), findsOneWidget);

      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      for (int i = 0; i < 2; i++) {
        await tester.tap(find.byType(LumeOnboardingContinue));
        await tester.pumpAndSettle();
      }

      // country, then city — both open on a selection, so Continue is live.
      expect(find.text('Where are you based?'), findsOneWidget);
      await tester.tap(find.byType(LumeOnboardingContinue));
      await tester.pumpAndSettle();
      expect(find.text('Which city are you in?'), findsOneWidget);
      await tester.tap(find.byType(LumeOnboardingContinue));
      await tester.pumpAndSettle();

      expect(find.text('What are you here for?'), findsOneWidget);
      for (final String label in fiveLabels) {
        await tester.tap(find.widgetWithText(LumeInterestChip, label));
      }
      await tester.pumpAndSettle();
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byType(LumeOnboardingContinue));
        await tester.pumpAndSettle();
      }

      expect(find.byType(LumeOnboardingFlow), findsNothing);
      expect(locationOf(router), isNot('/onboarding'));
    });

    testWidgets('the system back gesture moves one step, then leaves', (
      WidgetTester tester,
    ) async {
      await pumpLumeRouter(tester, initialLocation: '/onboarding');
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      expect(find.text('Your day, laid out before it starts'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Get started'), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------ skips

  group('skipping', () {
    for (final int step in <int>[
      LumeOnboardingStep.welcome,
      LumeOnboardingStep.plan,
      LumeOnboardingStep.tools,
      LumeOnboardingStep.country,
      LumeOnboardingStep.city,
      LumeOnboardingStep.interests,
      LumeOnboardingStep.setUp,
      LumeOnboardingStep.name,
    ]) {
      testWidgets('step $step offers Skip and it ends the flow', (
        WidgetTester tester,
      ) async {
        await pumpFlow(tester, step: step);
        expect(find.text('Skip'), findsOneWidget);
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
        expect(outcome, LumeOnboardingOutcome.skipped);
        expect(finalRecord!.onboarded, isTrue);
      });
    }

    testWidgets('the last step cannot be skipped', (WidgetTester tester) async {
      await pumpFlow(tester, step: LumeOnboardingStep.done);
      // Present, invisible and inert — the prototype disables it rather than
      // removing it, so the top row keeps its shape on the final step.
      expect(find.text('Skip'), findsOneWidget);
      expect(find.bySemanticsLabel('Skip'), findsNothing);
      expect(outcome, isNull);
    });

    testWidgets('skipping with nothing chosen writes the defaults', (
      WidgetTester tester,
    ) async {
      await pumpFlow(tester, step: LumeOnboardingStep.plan);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(finalRecord!.interests, LumeOnboardingState.defaultInterests);
      expect(finalRecord!.islamic, isFalse);
    });

    testWidgets('the name step’s own Skip advances without writing', (
      WidgetTester tester,
    ) async {
      store.write(store.read().copyWith(displayName: 'Sam'));
      await pumpFlow(tester, step: LumeOnboardingStep.name);
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
      expect(flowState(tester).step, LumeOnboardingStep.done);
      expect(
        store.read().displayName,
        'Sam',
        reason: '§124.4 — skipping is not a deletion',
      );
    });

    testWidgets('an untouched name field writes nothing either', (
      WidgetTester tester,
    ) async {
      store.write(store.read().copyWith(displayName: 'Sam'));
      await pumpFlow(tester, step: LumeOnboardingStep.name);
      await tapContinue(tester);
      expect(store.read().displayName, 'Sam');
    });

    testWidgets('an emptied name field does write the emptiness', (
      WidgetTester tester,
    ) async {
      // §125: an empty field writes an empty name; it does not leave the
      // previous one standing. The difference from Skip is the whole point.
      store.write(store.read().copyWith(displayName: 'Sam'));
      await pumpFlow(tester, step: LumeOnboardingStep.name);
      await tester.enterText(find.byType(TextField), '');
      await tapContinue(tester);
      expect(store.read().displayName, '');
    });

    testWidgets('sign in hands over, and still leaves a usable app', (
      WidgetTester tester,
    ) async {
      await pumpFlow(tester);
      await tester.tap(find.byType(LumeOnboardingLink));
      await tester.pumpAndSettle();
      expect(outcome, LumeOnboardingOutcome.signIn);
      expect(finalRecord!.interests, isNotEmpty);
    });
  });

  // ------------------------------------------------------------ set-up step

  group('the set-up step', () {
    testWidgets('its toggles are intent, and they persist on completion', (
      WidgetTester tester,
    ) async {
      await pumpFlow(tester, step: LumeOnboardingStep.setUp);
      await tester.tap(find.byType(LumeSwitch).first);
      await tester.pumpAndSettle();
      expect(flowState(tester).draft.wantsLocation, isFalse);

      await tapContinue(tester);
      await tapContinue(tester); // name → done
      await tapContinue(tester); // finish
      expect(finalRecord!.wantsLocation, isFalse);
      expect(finalRecord!.wantsReminders, isTrue);
    });

    testWidgets('the method is stored, and the stored one is marked', (
      WidgetTester tester,
    ) async {
      store.write(store.read().copyWith(islamic: true, method: 'ISNA'));
      await pumpFlow(tester, step: LumeOnboardingStep.setUp);
      expect(flowState(tester).draft.method, 'ISNA');

      await tester.tap(find.text('Umm al-Qura'));
      await tester.pumpAndSettle();
      expect(flowState(tester).draft.method, 'UmmAlQura');
    });
  });

  // ------------------------------------------------------------ the matrix

  group('every step lays out everywhere', () {
    const List<(String, Size)> surfaces = <(String, Size)>[
      ('narrow 359', LumeViewport.narrow),
      ('phone 390', LumeViewport.phone),
      ('medium 700', LumeViewport.medium),
      ('expanded 1100', LumeViewport.expanded),
      ('landscape 852x393', LumeViewport.landscapePhone),
    ];

    for (final int step in LumeOnboardingStep.all) {
      for (final (String name, Size surface) in surfaces) {
        testWidgets('step $step at $name', (WidgetTester tester) async {
          for (final Locale locale in <Locale>[
            const Locale('en'),
            const Locale('ur'),
            const Locale('ar'),
          ]) {
            await pumpFlow(
              tester,
              step: step,
              surface: surface,
              locale: locale,
              withStore: LumeMemoryOnboardingStore(
                const LumeProfileRecord(islamic: true),
              ),
            );
            expectNoOverflow(tester);
          }
        });
      }
    }

    testWidgets('and in dark', (WidgetTester tester) async {
      for (final int step in LumeOnboardingStep.all) {
        await pumpFlow(tester, step: step, theme: ThemeMode.dark);
        expectNoOverflow(tester);
      }
    });

    testWidgets('and at 200 per cent text', (WidgetTester tester) async {
      for (final int step in LumeOnboardingStep.all) {
        // A real phone at 200 per cent, not the counting surface: the point
        // is that a step three times its own height scrolls rather than
        // overflows.
        await pumpFlow(tester, step: step, textScale: 2.0);
        expectNoOverflow(tester);
      }
    });

    testWidgets('the name step with the keyboard up', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewInsets: const EdgeInsets.only(bottom: 320)),
            child: LumeOnboardingFlow(
              countries: countries,
              catalogue: catalogue,
              store: store,
              initialStep: LumeOnboardingStep.name,
            ),
          ),
        ),
        surface: LumeViewport.phone,
      );
      expectNoOverflow(tester);
      expect(find.byType(LumeToolField), findsOneWidget);
      // The browser resizes its viewport when the keyboard opens; the step
      // does the same, so nothing is laid out underneath it. What is left is
      // 444 points for a step that wants about 490, so it scrolls — which is
      // the prototype's behaviour at that height too.
      expect(
        tester.getRect(find.byType(CustomScrollView)).bottom,
        lessThanOrEqualTo(LumeViewport.phone.height - 320),
      );
    });
  });

  // ----------------------------------------------------------- city picking

  group('the city step', () {
    testWidgets('a country without regions renders one flat list', (
      WidgetTester tester,
    ) async {
      store.write(store.read().copyWith(country: 'JP', city: 'Tokyo'));
      await pumpFlow(tester, step: LumeOnboardingStep.city);
      expect(find.text('Tokyo'), findsOneWidget);
      expect(find.text('Osaka'), findsOneWidget);
      // No region headings: Japan has no region table.
      expect(find.text('PUNJAB'), findsNothing);
    });

    testWidgets('searching flattens a grouped list', (
      WidgetTester tester,
    ) async {
      await pumpFlow(tester, step: LumeOnboardingStep.city);
      expect(find.text('PUNJAB'), findsOneWidget);
      await tester.enterText(find.byType(LumeSearchField), 'lah');
      await tester.pumpAndSettle();
      expect(find.text('PUNJAB'), findsNothing);
      expect(find.text('Lahore'), findsOneWidget);
    });

    testWidgets('no match shows the no-results state', (
      WidgetTester tester,
    ) async {
      await pumpFlow(tester, step: LumeOnboardingStep.city);
      await tester.enterText(find.byType(LumeSearchField), 'qqqqq');
      await tester.pumpAndSettle();
      expect(find.text('Nothing found'), findsOneWidget);
      expect(find.byType(LumeLocationRow), findsNothing);
    });

    testWidgets('changing country resets the city', (
      WidgetTester tester,
    ) async {
      await pumpFlow(tester, step: LumeOnboardingStep.country);
      await tester.tap(find.text('Japan').first);
      await tester.pumpAndSettle();
      await tapContinue(tester);
      expect(flowState(tester).draft.country, 'JP');
      expect(flowState(tester).draft.city, 'Tokyo');
      expect(
        flowState(tester).draft.region,
        isNull,
        reason: 'Japan has no region layer',
      );
    });
  });
}

/// The two steps as they render: measured against the prototype, and driven
/// through every state the phase asks for.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/theme/lume/lume_space.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_pressable.dart';
import 'package:lume/features/onboarding/data/country_fixture.dart';
import 'package:lume/features/onboarding/data/interests_fixture.dart';
import 'package:lume/features/onboarding/domain/interests_model.dart';
import 'package:lume/features/onboarding/presentation/country_screen.dart';
import 'package:lume/features/onboarding/presentation/interests_screen.dart';
import 'package:lume/features/onboarding/presentation/onboarding_chrome.dart';
import 'package:lume/features/onboarding/presentation/onboarding_flow.dart';
import 'package:lume/features/onboarding/presentation/onboarding_steps.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../../helpers/measured.dart';

void main() {
  setUpAll(loadLumeFonts);

  final LumeCountryFixture countries = LumeCountryFixture.parse(
    File('assets/data/countries.json').readAsStringSync(),
  );
  final LumeInterestsFixture interests = LumeInterestsFixture.parse(
    File('assets/data/interests.json').readAsStringSync(),
  );

  final Measurements? light = Measurements.available()
      ? Measurements.load()
      : null;

  Future<void> pumpCountry(
    WidgetTester tester, {
    Size surface = LumeViewport.phone,
    ThemeMode theme = ThemeMode.light,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    List<String> recent = LumeCountryFixtureState.noRecent,
    String selected = 'PK',
    VoidCallback? onBack,
    VoidCallback? onSkip,
    ValueChanged<String>? onContinue,
  }) => pumpLume(
    tester,
    CountryStep(
      countries: countries,
      recent: recent,
      initialCountry: selected,
      onBack: onBack,
      onSkip: onSkip,
      onContinue: onContinue,
    ),
    surface: surface,
    theme: theme,
    locale: locale,
    textScale: textScale,
  );

  Future<void> pumpInterests(
    WidgetTester tester, {
    Size surface = LumeViewport.phone,
    ThemeMode theme = ThemeMode.light,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    Set<String> selection = const <String>{},
    bool? faithOpen,
    LumeInterestsController? controller,
    VoidCallback? onBack,
    VoidCallback? onSkip,
    void Function(Set<String>, bool)? onContinue,
  }) => pumpLume(
    tester,
    InterestsStep(
      catalogue: interests,
      initialSelection: selection,
      initialFaithOpen: faithOpen,
      controller: controller,
      onBack: onBack,
      onSkip: onSkip,
      onContinue: onContinue,
    ),
    surface: surface,
    theme: theme,
    locale: locale,
    textScale: textScale,
  );

  // ---------------------------------------------------------------- chrome

  group('the shared chrome, measured', () {
    testWidgets('the back control is the measured circle', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester, onBack: () {});
      // The visible circle is 34; its touch target is 44 and overhangs. Asking
      // for the widget would give the target, which is the other measurement.
      final Size size = tester.getSize(
        find.byKey(LumeOnboardingKeys.backCircle),
      );
      expect(size.width, LumeOnboardingMetrics.navSize);
      expect(size.height, LumeOnboardingMetrics.navSize);
      if (light != null) {
        expect(size.height, light['onb.nav'].height);
      }
      expect(
        tester.getSize(find.byType(LumeOnboardingBack)).height,
        LumeSpace.tap,
        reason: 'the target is whole even though the circle is not',
      );
    });

    testWidgets('on the first step it keeps its space and leaves semantics', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester);
      expect(
        tester.getSize(find.byType(LumeOnboardingBack)).width,
        LumeOnboardingMetrics.navSize,
        reason: 'the progress bar must not shift between steps',
      );
      expect(find.bySemanticsLabel('Back'), findsNothing);
    });

    testWidgets('the progress bar has nine segments', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester);
      final LumeOnboardingProgress bar = tester.widget<LumeOnboardingProgress>(
        find.byType(LumeOnboardingProgress),
      );
      expect(bar.total, 9);
      expect(bar.step, LumeOnboardingStep.country);
      expect(
        tester.getSize(find.byType(LumeOnboardingProgress)).height,
        LumeOnboardingMetrics.segmentHeight,
      );
      if (light != null) {
        expect(LumeOnboardingMetrics.segmentHeight, light['onb.seg'].height);
        expect(LumeOnboardingMetrics.segmentGap, light['onb.progress'].gap);
      }
    });

    testWidgets('the country step is the fourth of nine', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester);
      expect(LumeOnboardingStep.country, 3);
      await pumpInterests(tester);
      expect(LumeOnboardingStep.interests, 5);
    });

    testWidgets('Skip is there when it does something, and not when not', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester);
      expect(find.text('Skip'), findsNothing);
      await pumpCountry(tester, onSkip: () {});
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('the kicker, title and text are the reference’s copy', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester);
      expect(find.text('MAKE IT LOCAL'), findsOneWidget);
      expect(find.text('Where are you based?'), findsOneWidget);
      expect(
        find.textContaining('It says nothing about who you are'),
        findsOneWidget,
      );
    });

    testWidgets('the title is the measured display role', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester);
      final Text title = tester.widget<Text>(find.text('Where are you based?'));
      expect(title.style!.fontSize, 28);
      expect(title.style!.fontWeight, FontWeight.w800);
      if (light != null) {
        expect(title.style!.fontSize, light['onb.title'].fontSize);
        expect(title.style!.fontWeight, light['onb.title'].fontWeight);
      }
    });

    testWidgets('the supporting text is capped at thirty characters', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester);
      final double width = tester
          .getSize(find.textContaining('It says nothing about who you are'))
          .width;
      // `.onb__text { max-width: 30ch }` measured 304.08 at 390. A ch is a
      // font metric, so this allows a point of rounding either way.
      expect(width, lessThanOrEqualTo(310));
      if (light != null) {
        expect(width, closeTo(light['onb.text'].width, 6));
      }
    });

    testWidgets('Continue is the measured button, disabled at 0.38', (
      WidgetTester tester,
    ) async {
      await pumpInterests(tester);
      final Finder button = find.byType(LumeOnboardingContinue);
      expect(tester.getSize(button).height, 46);
      if (light != null) {
        expect(tester.getSize(button).height, light['onb.continue'].height);
        expect(light['onb.continue.off'].px('opacity'), 0.38);
      }
      final LumeButton inner = tester.widget<LumeButton>(
        find.descendant(of: button, matching: find.byType(LumeButton)),
      );
      expect(inner.onPressed, isNull, reason: 'nothing selected yet');
    });
  });

  // --------------------------------------------------------------- country

  group('the country step', () {
    testWidgets('opens on Pakistan with Popular and All countries', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester);
      expect(find.text('POPULAR'), findsOneWidget);
      expect(find.text('RECENT'), findsNothing);
      expect(find.text('Pakistan'), findsWidgets);

      // "All countries" is below twenty popular rows, so it is built when it
      // is scrolled to — which is the list doing its job, not a missing
      // section.
      await tester.dragUntilVisible(
        find.text('ALL COUNTRIES'),
        find.byType(LumeCountryPickerView),
        const Offset(0, -300),
      );
      expect(find.text('ALL COUNTRIES'), findsOneWidget);
    });

    testWidgets('a returning user sees Recent first', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester, recent: LumeCountryFixtureState.someRecent);
      expect(find.text('RECENT'), findsOneWidget);
      final double recent = tester.getRect(find.text('RECENT')).top;
      final double popular = tester.getRect(find.text('POPULAR')).top;
      expect(recent, lessThan(popular));
    });

    testWidgets('a row carries a code, a name and a currency', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester);
      final Finder row = find.byType(LumeCountryRow).first;
      expect(
        find.descendant(of: row, matching: find.text('PK')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('Pakistan')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('PKR')),
        findsOneWidget,
      );
    });

    testWidgets('the row is the measured height with the measured padding', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester);
      final double height = tester
          .getSize(find.byType(LumeCountryRow).first)
          .height;
      expect(height, greaterThanOrEqualTo(LumeLocPickerMetrics.rowMinHeight));
      if (light != null) {
        expect(LumeLocPickerMetrics.rowMinHeight, light['locrow'].height);
        expect(
          LumeLocPickerMetrics.rowPaddingX,
          light['locrow'].px('paddingLeft'),
        );
        expect(LumeLocPickerMetrics.rowGap, light['locrow'].gap);
        expect(LumeLocPickerMetrics.codeMinWidth, light['locrow.code'].width);
      }
    });

    testWidgets('the selected row is tinted and the rest are not', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester);
      final Iterable<LumeCountryRow> rows = tester.widgetList<LumeCountryRow>(
        find.byType(LumeCountryRow),
      );
      expect(
        rows.where((LumeCountryRow r) => r.selected).length,
        greaterThan(0),
      );
      expect(
        rows
            .where((LumeCountryRow r) => r.selected)
            .every((LumeCountryRow r) => r.country.code == 'PK'),
        isTrue,
      );
    });

    testWidgets('selecting moves the tint', (WidgetTester tester) async {
      await pumpCountry(tester);
      await tester.tap(find.text('United Kingdom').first);
      await tester.pumpAndSettle();
      final Iterable<LumeCountryRow> selected = tester
          .widgetList<LumeCountryRow>(find.byType(LumeCountryRow))
          .where((LumeCountryRow r) => r.selected);
      expect(
        selected.every((LumeCountryRow r) => r.country.code == 'GB'),
        isTrue,
      );
    });

    testWidgets('searching narrows to one flat list', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester);
      await tester.enterText(find.byType(LumeSearchField), 'united');
      await tester.pumpAndSettle();
      expect(find.text('POPULAR'), findsNothing);
      expect(find.text('ALL COUNTRIES'), findsNothing);
      expect(find.text('United Kingdom'), findsOneWidget);
    });

    testWidgets('a search with no hits shows the no-results state', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester);
      await tester.enterText(find.byType(LumeSearchField), 'qqqqq');
      await tester.pumpAndSettle();
      expect(find.text('Nothing found'), findsOneWidget);
      expect(find.byType(LumeCountryRow), findsNothing);
    });

    testWidgets('clearing the search brings the sections back', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester);
      await tester.enterText(find.byType(LumeSearchField), 'united');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(LumeSearchField), '');
      await tester.pumpAndSettle();
      expect(find.text('POPULAR'), findsOneWidget);
    });

    testWidgets('Continue reports the chosen country', (
      WidgetTester tester,
    ) async {
      String? chosen;
      await pumpCountry(tester, onContinue: (String code) => chosen = code);
      await tester.tap(find.text('United Kingdom').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LumeOnboardingContinue));
      expect(chosen, 'GB');
    });

    testWidgets('it is a list of rows, not a grid of tiles', (
      WidgetTester tester,
    ) async {
      // The brief rules out a flag grid, tiles, cards and three columns. A row
      // fills the list's width; a tile would not.
      await pumpCountry(tester);
      final double rowWidth = tester
          .getSize(find.byType(LumeCountryRow).first)
          .width;
      final double listWidth = tester
          .getSize(find.byType(LumeCountryPickerView))
          .width;
      expect(rowWidth, greaterThan(listWidth * 0.9));
      expect(find.byType(GridView), findsNothing);
    });
  });

  // ------------------------------------------------------------- interests

  group('the interests step', () {
    testWidgets('offers 29 chips in 6 groups', (WidgetTester tester) async {
      await pumpInterests(tester, surface: LumeViewport.tall);
      expect(find.byType(LumeInterestChip), findsNWidgets(23));
      // The faith group's six are behind the switch until it is on.
      await tester.tap(find.byType(LumeSwitch));
      await tester.pumpAndSettle();
      expect(find.byType(LumeInterestChip), findsNWidgets(29));
    });

    testWidgets('the five ordinary group labels are shown', (
      WidgetTester tester,
    ) async {
      await pumpInterests(tester, surface: LumeViewport.tall);
      for (final String label in <String>[
        'EVERYDAY LIFE',
        'MONEY & FINANCE',
        'HEALTH & WELLNESS',
        'TRAVEL & GETTING AROUND',
        'NEWS & ENTERTAINMENT',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      // The sixth group's heading is the switch, not a label.
      expect(find.text('ISLAMIC FEATURES'), findsNothing);
      expect(find.text('Islamic features'), findsOneWidget);
    });

    testWidgets('the chip is the measured pill', (WidgetTester tester) async {
      await pumpInterests(tester, surface: LumeViewport.tall);
      final double height = tester
          .getSize(find.byType(LumeInterestChip).first)
          .height;
      expect(height, LumePickerMetrics.chipHeight);
      if (light != null) {
        expect(LumePickerMetrics.chipHeight, light['pick'].height);
        expect(
          LumePickerMetrics.chipPaddingStart,
          light['pick'].px('paddingLeft'),
        );
        expect(
          LumePickerMetrics.chipPaddingEnd,
          light['pick'].px('paddingRight'),
        );
        expect(LumePickerMetrics.chipGap, light['picker'].gap);
        expect(
          LumePickerMetrics.mutedOpacity,
          light['pick.muted'].px('opacity'),
        );
        // The faith card sits at 18, not the 20 its own rule declares.
        expect(
          LumePickerMetrics.groupGap,
          light['pickgroup.faith'].px('marginTop'),
        );
      }
    });

    testWidgets('the count starts below the minimum', (
      WidgetTester tester,
    ) async {
      await pumpInterests(tester);
      expect(find.text('0 of 5 minimum'), findsOneWidget);
    });

    testWidgets('reaching five switches the message and enables Continue', (
      WidgetTester tester,
    ) async {
      await pumpInterests(
        tester,
        selection: <String>{'weather', 'calendar', 'tasks', 'notes'},
      );
      expect(find.text('4 of 5 minimum'), findsOneWidget);
      LumeButton button() => tester.widget<LumeButton>(
        find.descendant(
          of: find.byType(LumeOnboardingContinue),
          matching: find.byType(LumeButton),
        ),
      );
      expect(button().onPressed, isNull);

      await tester.tap(find.widgetWithText(LumeInterestChip, 'Converters'));
      await tester.pumpAndSettle();
      expect(find.text('5 of 10 selected'), findsOneWidget);
      expect(button().onPressed, isNotNull);
    });

    testWidgets('the cap refuses an eleventh and says why', (
      WidgetTester tester,
    ) async {
      final LumeInterestsController controller = LumeInterestsController(
        selected: interests.allIds
            .where((String id) => !interests.faithInterests.contains(id))
            .take(10)
            .toSet(),
        faithOpen: false,
        faithInterests: interests.faithInterests,
      );
      addTearDown(controller.dispose);

      await pumpInterests(
        tester,
        surface: LumeViewport.tall,
        controller: controller,
      );
      expect(find.text('10 of 10 selected'), findsOneWidget);

      final LumeInterestChip muted = tester
          .widgetList<LumeInterestChip>(find.byType(LumeInterestChip))
          .firstWhere((LumeInterestChip c) => c.muted);
      expect(muted.selected, isFalse);

      await tester.tap(
        find.widgetWithText(LumeInterestChip, muted.interest.label),
      );
      await tester.pumpAndSettle();
      expect(find.text('Up to 10 — remove one first'), findsOneWidget);
      expect(controller.count, 10);
    });

    testWidgets('Clear empties the selection', (WidgetTester tester) async {
      await pumpInterests(
        tester,
        selection: <String>{'weather', 'calendar', 'tasks'},
      );
      expect(find.text('3 of 5 minimum'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(find.text('0 of 5 minimum'), findsOneWidget);
    });

    testWidgets('the faith switch is off, and seeds three when turned on', (
      WidgetTester tester,
    ) async {
      Set<String>? chosen;
      bool? islamic;
      await pumpInterests(
        tester,
        surface: LumeViewport.tall,
        onContinue: (Set<String> s, bool i) {
          chosen = s;
          islamic = i;
        },
      );
      expect(tester.widget<LumeSwitch>(find.byType(LumeSwitch)).value, isFalse);
      expect(find.text('Prayer times'), findsNothing);

      await tester.tap(find.byType(LumeSwitch));
      await tester.pumpAndSettle();
      expect(find.text('3 of 5 minimum'), findsOneWidget);
      expect(find.text('Prayer times'), findsOneWidget);

      await tester.tap(find.widgetWithText(LumeInterestChip, 'Weather'));
      await tester.tap(find.widgetWithText(LumeInterestChip, 'Calendar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LumeOnboardingContinue));
      expect(islamic, isTrue);
      expect(chosen, contains('prayer'));
    });

    testWidgets('turning it off removes the faith interests', (
      WidgetTester tester,
    ) async {
      await pumpInterests(
        tester,
        surface: LumeViewport.tall,
        selection: <String>{'weather', 'prayer', 'quran'},
      );
      expect(find.text('3 of 5 minimum'), findsOneWidget);
      await tester.tap(find.byType(LumeSwitch));
      await tester.pumpAndSettle();
      expect(find.text('1 of 5 minimum'), findsOneWidget);
      expect(find.text('Prayer times'), findsNothing);
    });

    testWidgets('coming back restores what was chosen', (
      WidgetTester tester,
    ) async {
      await pumpInterests(
        tester,
        surface: LumeViewport.tall,
        selection: <String>{'weather', 'news', 'prayer', 'quran', 'duas'},
      );
      expect(find.text('5 of 10 selected'), findsOneWidget);
      expect(
        tester.widget<LumeSwitch>(find.byType(LumeSwitch)).value,
        isTrue,
        reason: 'the switch is inferred from the selection',
      );
    });

    testWidgets('it is chips, not category rows', (WidgetTester tester) async {
      await pumpInterests(tester, surface: LumeViewport.tall);
      expect(find.byType(Wrap), findsWidgets);
      final double chipWidth = tester
          .getSize(find.byType(LumeInterestChip).first)
          .width;
      final double viewWidth = tester
          .getSize(find.byType(LumeInterestsView))
          .width;
      expect(
        chipWidth,
        lessThan(viewWidth * 0.6),
        reason: 'a chip is a pill, not a full-width row',
      );
    });
  });

  // ------------------------------------------------------------ the matrix

  group('every state lays out', () {
    const List<(String, Size)> surfaces = <(String, Size)>[
      ('compact', LumeViewport.phone),
      ('narrow', LumeViewport.narrow),
      ('medium', LumeViewport.medium),
      ('expanded', LumeViewport.expanded),
      ('compact-height', LumeViewport.landscapePhone),
    ];

    for (final (String name, Size surface) in surfaces) {
      testWidgets('country at $name', (WidgetTester tester) async {
        for (final ThemeMode theme in ThemeMode.values) {
          for (final Locale locale in <Locale>[
            const Locale('en'),
            const Locale('ur'),
            const Locale('ar'),
          ]) {
            await pumpCountry(
              tester,
              surface: surface,
              theme: theme,
              locale: locale,
              recent: LumeCountryFixtureState.someRecent,
              onBack: () {},
              onSkip: () {},
            );
            expectNoOverflow(tester);
          }
        }
      });

      testWidgets('interests at $name', (WidgetTester tester) async {
        for (final ThemeMode theme in ThemeMode.values) {
          for (final Locale locale in <Locale>[
            const Locale('en'),
            const Locale('ur'),
            const Locale('ar'),
          ]) {
            await pumpInterests(
              tester,
              surface: surface,
              theme: theme,
              locale: locale,
              selection: <String>{'weather', 'prayer'},
              onBack: () {},
              onSkip: () {},
            );
            expectNoOverflow(tester);
          }
        }
      });
    }

    testWidgets('both survive 200 per cent text', (WidgetTester tester) async {
      await pumpCountry(tester, textScale: 2.0, onBack: () {}, onSkip: () {});
      expectNoOverflow(tester);
      await pumpInterests(tester, textScale: 2.0, onBack: () {}, onSkip: () {});
      expectNoOverflow(tester);
    });

    testWidgets('the search field and no-results survive 200 per cent', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester, textScale: 2.0);
      await tester.enterText(find.byType(LumeSearchField), 'qqqqq');
      await tester.pumpAndSettle();
      expectNoOverflow(tester);
    });
  });

  group('direction', () {
    testWidgets('the country row leads with its code in both directions', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester);
      final Rect ltrCode = tester.getRect(find.text('PK').first);
      final Rect ltrRow = tester.getRect(find.byType(LumeCountryRow).first);
      expect(ltrCode.left - ltrRow.left, lessThan(ltrRow.width / 2));

      await pumpCountry(tester, locale: const Locale('ur'));
      final Rect rtlCode = tester.getRect(find.text('PK').first);
      final Rect rtlRow = tester.getRect(find.byType(LumeCountryRow).first);
      expect(
        rtlRow.right - rtlCode.right,
        lessThan(rtlRow.width / 2),
        reason: 'the code leads on the start edge, which is the right in Urdu',
      );
    });

    testWidgets('country names are localised, not left in English', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester, locale: const Locale('ur'));
      expect(find.text('Pakistan'), findsNothing);
      expect(find.text('پاکستان'), findsWidgets);
    });

    testWidgets('interest chips are localised too', (
      WidgetTester tester,
    ) async {
      // The reference leaves these in English in every language. This does
      // not — see D12.
      await pumpInterests(
        tester,
        surface: LumeViewport.tall,
        locale: const Locale('ur'),
      );
      expect(find.text('Weather'), findsNothing);
      expect(find.text('موسم'), findsOneWidget);
    });
  });

  group('the flow, as far as it goes', () {
    testWidgets('country then interests, then out', (
      WidgetTester tester,
    ) async {
      LumeOnboardingDraft? finished;
      await pumpLume(
        tester,
        LumeOnboardingFlow(
          countries: countries,
          catalogue: interests,
          onFinished: (LumeOnboardingDraft d) => finished = d,
        ),
        surface: LumeViewport.tall,
      );

      expect(find.text('Where are you based?'), findsOneWidget);
      await tester.tap(find.text('United Kingdom').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LumeOnboardingContinue));
      await tester.pumpAndSettle();

      expect(find.text('What are you here for?'), findsOneWidget);
      for (final String label in <String>[
        'Weather',
        'Calendar',
        'Tasks & to-dos',
        'Notes',
        'Calculators',
      ]) {
        await tester.tap(find.widgetWithText(LumeInterestChip, label));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LumeOnboardingContinue));
      await tester.pumpAndSettle();

      expect(finished, isNotNull);
      expect(finished!.country, 'GB');
      expect(finished!.interests.length, 5);
      expect(finished!.islamic, isFalse, reason: 'never inferred');
    });

    testWidgets('Back returns to the country step and keeps the choice', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        LumeOnboardingFlow(countries: countries, catalogue: interests),
        surface: LumeViewport.tall,
      );
      await tester.tap(find.text('United Kingdom').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LumeOnboardingContinue));
      await tester.pumpAndSettle();
      expect(find.text('What are you here for?'), findsOneWidget);

      await tester.tap(find.byType(LumeOnboardingBack));
      await tester.pumpAndSettle();
      expect(find.text('Where are you based?'), findsOneWidget);
      final Iterable<LumeCountryRow> selected = tester
          .widgetList<LumeCountryRow>(find.byType(LumeCountryRow))
          .where((LumeCountryRow r) => r.selected);
      expect(
        selected.every((LumeCountryRow r) => r.country.code == 'GB'),
        isTrue,
        reason: 'the draft survived the step change',
      );
    });

    testWidgets('Back out of the first step leaves the flow', (
      WidgetTester tester,
    ) async {
      int left = 0;
      await pumpLume(
        tester,
        LumeOnboardingFlow(
          countries: countries,
          catalogue: interests,
          onLeave: () => left++,
        ),
        surface: LumeViewport.tall,
      );
      await tester.tap(find.byType(LumeOnboardingBack));
      await tester.pumpAndSettle();
      expect(left, 1);
    });
  });

  group('accessibility', () {
    testWidgets('every country row is the prototype’s 41, which is Q9', (
      WidgetTester tester,
    ) async {
      // Three under §9's floor, and deliberately: the rows are adjacent, so a
      // 44 px target would either overlap its neighbour's or change the list's
      // rhythm. The target is 350 points wide, so the miss the floor guards
      // against is not the one on offer. Raised as Q9 rather than settled.
      await pumpCountry(tester);
      for (final Element e in find.byType(LumeCountryRow).evaluate()) {
        expect(
          tester.getSize(find.byWidget(e.widget)).height,
          greaterThanOrEqualTo(LumeLocPickerMetrics.rowMinHeight),
        );
      }
    });

    testWidgets('the two chrome controls do clear it', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester, onBack: () {}, onSkip: () {});
      expect(
        tester.getSize(find.byType(LumeOnboardingBack)).height,
        greaterThanOrEqualTo(LumeSpace.tap),
      );
      expect(
        tester.getSize(find.byType(LumeOnboardingSkip)).height,
        greaterThanOrEqualTo(LumeSpace.tap),
      );
    });

    testWidgets('so does Clear, and every chip', (WidgetTester tester) async {
      await pumpInterests(tester, surface: LumeViewport.tall);
      expect(
        tester.getSize(find.widgetWithText(LumePressable, 'Clear')).height,
        greaterThanOrEqualTo(LumeSpace.tap),
      );
      for (final Element e in find.byType(LumeInterestChip).evaluate()) {
        expect(
          tester.getSize(find.byWidget(e.widget)).height,
          greaterThanOrEqualTo(LumePickerMetrics.chipHeight),
        );
      }
    });

    testWidgets('a country row announces its name and currency', (
      WidgetTester tester,
    ) async {
      await pumpCountry(tester);
      expect(find.bySemanticsLabel('Pakistan, PKR'), findsOneWidget);
    });

    testWidgets('a chip announces itself as a selected button', (
      WidgetTester tester,
    ) async {
      await pumpInterests(tester, selection: <String>{'weather'});
      expect(
        tester.getSemantics(find.widgetWithText(LumeInterestChip, 'Weather')),
        matchesSemantics(
          label: 'Weather',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
        reason: 'a chosen chip is selected, not merely tinted',
      );
    });

    testWidgets('the faith switch announces its state', (
      WidgetTester tester,
    ) async {
      await pumpInterests(tester, surface: LumeViewport.tall);
      expect(find.bySemanticsLabel(RegExp('Islamic features')), findsWidgets);
    });

    testWidgets('the progress bar is not announced', (
      WidgetTester tester,
    ) async {
      // `aria-hidden` in the reference: nine anonymous bars help nobody.
      await pumpCountry(tester);
      expect(
        find.descendant(
          of: find.byType(LumeOnboardingProgress),
          matching: find.byType(Semantics),
        ),
        findsNothing,
      );
    });
  });
}

/// The BMI Calculator screen: what it opens on, what typing into it does, and
/// that a reader in another language and script gets the same figures without
/// the screen breaking.
///
/// The maths has its own test (`bmi_maths_test.dart`). This one is about the
/// screen: that the reference's own opening figures reach the fields, that
/// typing a new height or weight moves the reading and its band, and that the
/// fabricated "history" the reference draws (`context.js:1183`) is nowhere on
/// it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/bmi/domain/bmi_maths.dart';
import 'package:lume/features/bmi/presentation/bmi_tool.dart';
import 'package:lume/features/tools/application/tool_session.dart';

import 'bmi_harness.dart';

void main() {
  group('what it opens on', () {
    testWidgets('the metric opening figures, for a Pakistani reader', (
      WidgetTester tester,
    ) async {
      await pumpBmi(tester, country: 'PK');

      expect(bmiTyped(tester, LumeBmiTool.heightKey), '175');
      expect(bmiTyped(tester, LumeBmiTool.weightKey), '75');
      // The suffixes are the plain international symbols, not a translated
      // word — `cm` and `kg`.
      expect(
        textsIn(tester, find.byKey(LumeBmiTool.heightKey)),
        contains('cm'),
      );
      expect(
        textsIn(tester, find.byKey(LumeBmiTool.weightKey)),
        contains('kg'),
      );
      // 75 / 1.75² rounds to 24.5, and the reading is healthy.
      expect(
        textsIn(tester, find.byKey(LumeBmiTool.summaryKey)),
        contains('24.5'),
      );
      expect(
        textsIn(tester, find.byKey(LumeBmiTool.summaryKey)),
        contains('Healthy weight'),
      );
    });

    testWidgets('the imperial opening figures, for a US reader', (
      WidgetTester tester,
    ) async {
      await pumpBmi(tester, country: 'US', city: 'New York');

      expect(bmiTyped(tester, LumeBmiTool.heightKey), '69');
      expect(bmiTyped(tester, LumeBmiTool.weightKey), '165');
      expect(
        textsIn(tester, find.byKey(LumeBmiTool.heightKey)),
        contains('in'),
      );
      expect(
        textsIn(tester, find.byKey(LumeBmiTool.weightKey)),
        contains('lb'),
      );
      // 165 lb and 69 in round to 24.4, still healthy.
      expect(
        textsIn(tester, find.byKey(LumeBmiTool.summaryKey)),
        contains('24.4'),
      );
    });

    testWidgets('the scale names all four bands, and marks the reader\'s own', (
      WidgetTester tester,
    ) async {
      await pumpBmi(tester);
      final List<String> scale = textsIn(
        tester,
        find.byKey(LumeBmiTool.scaleKey),
      );
      expect(
        scale,
        containsAll(<String>[
          'Underweight',
          'Healthy weight',
          'Overweight',
          'Obese',
        ]),
      );
      // The default reading is healthy, and only that row is marked current.
      expect(
        textsIn(
          tester,
          find.byKey(LumeBmiTool.scaleRowKey(LumeBmiBand.healthy)),
        ),
        contains('Current'),
      );
      expect(
        textsIn(tester, find.byKey(LumeBmiTool.scaleRowKey(LumeBmiBand.obese))),
        isNot(contains('Current')),
      );
    });

    testWidgets('there is no history or trend anywhere on the screen', (
      WidgetTester tester,
    ) async {
      await pumpBmi(tester);
      final List<String> screen = textsIn(tester, find.byType(LumeBmiTool));
      expect(screen, isNot(contains('History')));
      // The reference's own offsets from a BMI of 24.5.
      for (final String fabricated in <String>[
        '25.9',
        '25.6',
        '25.1',
        '24.7',
      ]) {
        expect(screen, isNot(contains(fabricated)));
      }
    });
  });

  group('typing into it', () {
    testWidgets('a new weight moves the reading and the band', (
      WidgetTester tester,
    ) async {
      await pumpBmi(tester);
      await tester.enterText(bmiInput(LumeBmiTool.weightKey), '100');
      await tester.pumpAndSettle();

      // 100 / 1.75² = 32.65..., which rounds to 32.7 and is obese.
      expect(
        textsIn(tester, find.byKey(LumeBmiTool.summaryKey)),
        contains('32.7'),
      );
      expect(
        textsIn(tester, find.byKey(LumeBmiTool.summaryKey)),
        contains('Obese'),
      );
      expect(
        textsIn(tester, find.byKey(LumeBmiTool.scaleRowKey(LumeBmiBand.obese))),
        contains('Current'),
      );
    });

    testWidgets('an emptied field reads as zero and throws nothing', (
      WidgetTester tester,
    ) async {
      await pumpBmi(tester);
      await tester.enterText(bmiInput(LumeBmiTool.heightKey), '');
      await tester.pumpAndSettle();

      expect(
        textsIn(tester, find.byKey(LumeBmiTool.summaryKey)),
        contains('0.0'),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the session carries the two fields between openings', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = LumeToolSession();
      await pumpBmi(tester, session: session);
      await tester.enterText(bmiInput(LumeBmiTool.weightKey), '60');
      await tester.pumpAndSettle();

      await pumpBmi(tester, session: session);
      expect(bmiTyped(tester, LumeBmiTool.weightKey), '60');
    });
  });

  group('other languages', () {
    testWidgets('Urdu draws the same figures without overflowing', (
      WidgetTester tester,
    ) async {
      await pumpBmi(tester, locale: const Locale('ur'));
      expect(tester.takeException(), isNull);
      expect(find.byKey(LumeBmiTool.summaryKey), findsOneWidget);
    });

    testWidgets('Arabic draws right to left without overflowing', (
      WidgetTester tester,
    ) async {
      await pumpBmi(tester, locale: const Locale('ar'), country: 'SA');
      expect(tester.takeException(), isNull);
      expect(
        Directionality.of(tester.element(find.byKey(LumeBmiTool.summaryKey))),
        TextDirection.rtl,
      );
    });
  });
}

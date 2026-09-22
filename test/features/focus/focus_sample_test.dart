/// Sample data against what the reader actually did.
///
/// `context.js` hands Focus `todayMins: 75, streak: 5, sessions: 3,
/// week: [50, 75, 25, 100, 50, 75, 75]`. None of it happened. The parity
/// build reproduces it — that is what a parity build is for, and it never
/// ships — and the development and release builds must not, which is what
/// most of this file asserts: **the absence**. A test that only checked the
/// parity build drew the right figures would let the fabrication through to a
/// real build without a word.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_chart.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/focus/presentation/focus_tool.dart';

import '../../helpers/load_fonts.dart';
import 'focus_harness.dart';

/// Every string anywhere in the tree.
List<String> _allText(WidgetTester tester) => <String>[
  for (final Text t in tester.widgetList<Text>(find.byType(Text)))
    if (t.data != null) t.data!.trim(),
];

void main() {
  setUpAll(loadLumeFonts);

  /// The two builds a reader can actually be running.
  const List<LumeBuildProfile> shipping = <LumeBuildProfile>[
    LumeBuildProfile.development,
    LumeBuildProfile.release,
  ];

  group('the honest path — no fixture history reaches a reader', () {
    for (final LumeBuildProfile build in shipping) {
      testWidgets('${build.name}: none of the reference\'s figures is drawn', (
        WidgetTester tester,
      ) async {
        await pumpFocus(
          tester,
          FocusWorld(),
          profile: build,
          surface: const Size(390, 5000),
        );

        // The three fabricated figures, by the value and by the label.
        final List<String> text = _allText(tester);
        expect(text, isNot(contains('75')), reason: 'no minutes-today');
        expect(text, isNot(contains('Minutes today')));
        expect(text, isNot(contains('Day streak')), reason: 'no streak');
        expect(text, isNot(contains('5 Day streak')));
        expect(find.text('This week'), findsNothing);

        // The seven-bar week, which is seven more constants.
        expect(find.byType(LumeBarChart), findsNothing);

        // And the widgets that would carry them, whatever they said.
        expect(find.byKey(LumeFocusTool.sampleMetricsKey), findsNothing);
        expect(find.byKey(LumeFocusTool.sampleWeekKey), findsNothing);
        expect(find.byKey(LumeFocusTool.sampleFiguresKey), findsNothing);
        expect(find.byKey(LumeFocusTool.sampleWeekSectionKey), findsNothing);
      });

      testWidgets('${build.name}: it shows what it really knows, and says '
          'how long it knows it for', (WidgetTester tester) async {
        await pumpFocus(
          tester,
          FocusWorld(),
          profile: build,
          surface: const Size(390, 5000),
        );
        expect(find.text('This session'), findsOneWidget);
        expect(
          find.text(
            'Counted since you opened Lume. Nothing here survives closing it.',
          ),
          findsOneWidget,
        );
        expect(find.byKey(LumeFocusTool.emptyKey), findsOneWidget);
        expect(
          find.text('Nothing yet — start a session and it will count here.'),
          findsOneWidget,
        );
        expect(
          find.byKey(LumeFocusTool.countedKey),
          findsNothing,
          reason: 'nothing has happened, so there are no figures at all',
        );
      });
    }

    testWidgets('a figure appears only once the reader has earned it', (
      WidgetTester tester,
    ) async {
      final FocusWorld world = FocusWorld();
      await pumpFocus(
        tester,
        world,
        profile: LumeBuildProfile.release,
        surface: const Size(390, 5000),
      );
      expect(find.byKey(LumeFocusTool.emptyKey), findsOneWidget);

      // One whole twenty-five minute stretch, on the injected clock.
      await tester.tap(find.byKey(LumeFocusTool.startKey));
      await tester.pump();
      world.advance(const Duration(minutes: 25));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 3));

      expect(find.byKey(LumeFocusTool.emptyKey), findsNothing);
      final List<String> counted = <String>[
        for (final LumeMetric m in tester.widgetList<LumeMetric>(
          find.descendant(
            of: find.byKey(LumeFocusTool.countedKey),
            matching: find.byType(LumeMetric),
          ),
        )) ...<String>[m.value, m.label],
      ];
      expect(counted, <String>['25 min', 'Focus', '1', 'Sessions']);
      // Still nothing fabricated beside it.
      expect(_allText(tester), isNot(contains('75')));
      expect(find.byType(LumeBarChart), findsNothing);
    });
  });

  group('the sample path — parity, and labelled', () {
    testWidgets('the reference\'s figures, and the mark that says what they '
        'are', (WidgetTester tester) async {
      await pumpFocus(
        tester,
        FocusWorld(),
        profile: LumeBuildProfile.parity,
        surface: const Size(390, 5000),
      );
      expect(find.byKey(LumeFocusTool.sampleMetricsKey), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
      expect(find.text('Minutes today'), findsOneWidget);
      expect(find.text('Day streak'), findsOneWidget);
      expect(find.byType(LumeBarChart), findsOneWidget);
      expect(
        tester
            .widget<LumeBarChart>(find.byKey(LumeFocusTool.sampleWeekKey))
            .values,
        LumeFocusTool.sampleWeek,
      );

      // The label, in the reader's own language, where the figures are.
      expect(find.byKey(LumeSourceLine.sampleKey), findsOneWidget);
      expect(find.text('Sample data'), findsOneWidget);

      // And none of the honest path, which would be claiming both at once.
      expect(find.text('This session'), findsNothing);
      expect(find.byKey(LumeFocusTool.countedKey), findsNothing);
    });

    testWidgets('the mark is translated, not an English label bolted on', (
      WidgetTester tester,
    ) async {
      await pumpFocus(
        tester,
        FocusWorld(),
        profile: LumeBuildProfile.parity,
        locale: const Locale('ar'),
        surface: const Size(390, 5000),
      );
      final String mark = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(LumeSourceLine.sampleKey),
              matching: find.byType(Text),
            ),
          )
          .first
          .data!;
      expect(mark, isNot('Sample data'));
      expect(mark.trim(), isNotEmpty);
    });

    testWidgets('a parity build is never shippable', (
      WidgetTester tester,
    ) async {
      expect(LumeBuildProfile.parity.shippable, isFalse);
      expect(
        () => lumeRefuseUnshippable(
          profile: LumeBuildProfile.parity,
          releaseMode: true,
        ),
        throwsA(isA<LumeUnshippableBuild>()),
      );
    });
  });
}

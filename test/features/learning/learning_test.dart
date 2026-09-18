/// Learning & Growth, against the running reference, and used.
///
/// The bar chart is compared against the reference with its bars at the
/// heights the stylesheet is written for (`--fixbars`, C64); the as-rendered
/// capture, where `animateBars` leaves every bar at 3, is committed beside it
/// as the evidence of the defect.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_chart.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/features/learning/data/learning_fixtures.dart';
import 'package:lume/features/learning/presentation/learning_tool.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../tax/tax_harness.dart';
import '../tools/tool_parity.dart';

final String kLearning = LumeRoutes.tool(LumeRoutes.tools, 'learning');

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('learning');
  tearDownAll(parity.write);

  Finder barOf(int i) => find
      .descendant(
        of: find.byKey(LumeLearningTool.weekKey),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).borderRadius ==
                  const BorderRadius.vertical(
                    top: Radius.circular(6),
                    bottom: Radius.circular(3),
                  ),
        ),
      )
      .at(i);

  Map<String, Finder> elements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    'toolbar.action1': find
        .descendant(
          of: find.byType(LumeIconButton).first,
          matching: find.byType(Container),
        )
        .first,
    'summary': find.byKey(LumeLearningTool.summaryKey),
    'summary.value': find.text('185'),
    'summary.small': find.text('min'),
    'pring': find.byType(LumeProgressRing),
    'pring.mid': find.text('74%'),
    'sect.title': find.text('In progress'),
    'kard': find
        .descendant(
          of: find.byKey(LumeLearningTool.coursesKey),
          matching: find.byType(LumeCard),
        )
        .first,
    'course.name': find.text('Arabic — Level 2'),
    'course.meta': find.text('Self-paced · 25 min'),
    'course.pct': find.text('62%'),
    'pbar': find
        .descendant(
          of: find.byKey(LumeLearningTool.coursesKey),
          matching: find.byType(LumeProgressBar),
        )
        .first,
    'bars': find.byKey(LumeLearningTool.weekKey),
    'bars.bar1': barOf(0),
    'bars.bar2': barOf(1),
    'bars.bar3': barOf(2),
    'bars.bar7': barOf(6),
    'heat': find.byKey(LumeLearningTool.consistencyKey),
    'rows': find.byKey(LumeLearningTool.insightsKey),
    'rrow.title': find.text('Short sessions stick'),
    'srcbar': find.byType(LumeSourceBar),
    'related': find.byType(LumeRelatedTools),
  };

  const Set<String> textBlocks = <String>{
    'summary.value',
    'summary.small',
    'pring.mid',
    'sect.title',
    'course.name',
    'course.meta',
    'course.pct',
    'rrow.title',
  };
  const Set<String> below = <String>{
    'bars',
    'bars.bar1',
    'bars.bar2',
    'bars.bar3',
    'bars.bar7',
    'heat',
    'rows',
    'rrow.title',
    'srcbar',
    'related',
  };

  group('where everything is', () {
    for (final (String cell, Size size) in <(String, Size)>[
      (
        'tool_learning_default_pk_fixbars_390x844_light_en',
        const Size(390, 5000),
      ),
      (
        'tool_learning_default_pk_fixbars_700x900_light_en',
        const Size(650, 5000),
      ),
      (
        'tool_learning_default_pk_fixbars_1100x900_light_en',
        const Size(1050, 5000),
      ),
    ]) {
      testWidgets(cell, (WidgetTester tester) async {
        await pumpTax(tester, location: kLearning, surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          elements(),
          noWidth: textBlocks,
          drifting: below,
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }
  });

  group('what it says', () {
    testWidgets('every part, as the reference writes it', (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic> k =
          webToolCell(
                'tool_learning_default_pk_fixbars_390x844_light_en',
              )!['composition']
              as Map<String, dynamic>;
      await pumpTax(
        tester,
        location: kLearning,
        surface: const Size(390, 5000),
      );

      final Map<String, dynamic> header = k['header'] as Map<String, dynamic>;
      expect(find.text(header['title'] as String), findsOneWidget);
      expect(find.text(header['sub'] as String), findsOneWidget);
      expect(
        tester
            .widgetList<LumeIconButton>(find.byType(LumeIconButton))
            .map((LumeIconButton b) => b.label),
        (header['actions'] as List<dynamic>).map(
          (dynamic a) => (a as Map<String, dynamic>)['label'],
        ),
      );

      final Map<String, dynamic> s = k['summary'] as Map<String, dynamic>;
      expect(
        textsUnder(tester, find.byKey(LumeLearningTool.summaryKey)),
        <String>[
          (s['kicker'] as String).toUpperCase(),
          ...(s['value'] as String).split(' '),
          s['caption'] as String,
          (k['ring'] as Map<String, dynamic>)['text'] as String,
          for (final dynamic st in s['stats'] as List<dynamic>) ...<String>[
            (st as Map<String, dynamic>)['value'] as String,
            st['label'] as String,
          ],
        ],
      );

      expect(
        textsUnder(tester, find.byKey(LumeLearningTool.coursesKey)),
        <String>[
          for (final dynamic c in k['courses'] as List<dynamic>) ...<String>[
            (c as Map<String, dynamic>)['name'] as String,
            c['meta'] as String,
            c['pct'] as String,
          ],
        ],
      );

      final List<dynamic> bars = k['bars'] as List<dynamic>;
      expect(
        textsUnder(tester, find.byKey(LumeLearningTool.weekKey)),
        bars.map((dynamic b) => (b as Map<String, dynamic>)['label']),
      );
      final LumeBarChart chart = tester.widget(
        find.byKey(LumeLearningTool.weekKey),
      );
      for (int i = 0; i < bars.length; i++) {
        final Map<String, dynamic> b = bars[i] as Map<String, dynamic>;
        expect(chart.fillOf(i), int.parse(b['fill'] as String), reason: '$i');
        expect(chart.highlight == i, b['on'], reason: '$i');
        expect(
          tester.getSize(barOf(i)).height,
          closeTo((b['height'] as num).toDouble(), 1),
          reason: 'bar $i',
        );
      }

      final Map<String, dynamic> heat = k['heat'] as Map<String, dynamic>;
      final LumeHeatmap map = tester.widget(
        find.byKey(LumeLearningTool.consistencyKey),
      );
      expect(map.levels, heat['levels']);
      expect(map.summary, heat['summary']);
      expect(<String>[map.less, map.more], heat['key']);

      expect(
        textsUnder(tester, find.byKey(LumeLearningTool.insightsKey)),
        <String>[
          for (final dynamic r in k['rows'] as List<dynamic>) ...<String>[
            (r as Map<String, dynamic>)['title'] as String,
            r['sub'] as String,
          ],
        ],
      );

      final Map<String, dynamic> src = k['source'] as Map<String, dynamic>;
      expect(find.text(src['fresh'] as String), findsOneWidget);
      expect(referenceSourceLine(tester), src['line']);
      expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
    });

    test('the grid is the reference generator’s, not typed in', () {
      expect(kReferenceLearningWeek.consistency, <int>[
        0, 3, 0, 3, 3, 3, 0, 3, 2, 1, 3, 2, 2, 3, 2, 2, 3, 3, //
        1, 3, 2, 3, 1, 0, 3, 0, 1, 3, 3, 1, 0, 3, 2, 3, 3,
      ]);
      expect(kReferenceLearningWeek.activeDays, 29);
    });
  });

  group('the header', () {
    testWidgets('favourite writes the reader’s saved list, and says so', (
      WidgetTester tester,
    ) async {
      await pumpTax(tester, location: kLearning);
      final LumeStartupController gate = ProviderScope.containerOf(
        tester.element(find.byType(LumeLearningTool)),
      ).read(startupControllerProvider);
      expect(gate.state.profile.favourites, isNot(contains('learning')));

      await tester.tap(find.bySemanticsLabel('Save to favourites'));
      await tester.pump();
      expect(gate.state.profile.favourites, contains('learning'));
      expect(
        find.text('Added Learning & Growth to favourites'),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 2200));
      expect(find.byType(LumeToast), findsNothing);

      await tester.tap(find.bySemanticsLabel('Save to favourites'));
      await tester.pump();
      expect(gate.state.profile.favourites, isNot(contains('learning')));
      expect(
        find.text('Removed Learning & Growth from favourites'),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 2200));
    });

    testWidgets('search has no field to focus here, and does nothing — as in '
        'the reference', (WidgetTester tester) async {
      await pumpTax(tester, location: kLearning);
      await tester.tap(find.bySemanticsLabel('Search this tool'));
      await tester.pumpAndSettle();
      expect(find.byType(LumeToast), findsNothing);
      expect(find.byType(LumeLearningTool), findsOneWidget);
    });
  });

  group('it holds up', () {
    testWidgets('right to left, the week reads from the right', (
      WidgetTester tester,
    ) async {
      await pumpTax(
        tester,
        location: kLearning,
        surface: const Size(390, 5000),
        locale: const Locale('ur'),
      );
      expect(
        Directionality.of(tester.element(find.byType(LumeToolFrame))),
        TextDirection.rtl,
      );
      expect(
        tester.getRect(barOf(0)).left,
        greaterThan(tester.getRect(barOf(6)).left),
      );
      // The highlighted day stays the last one, at the left edge.
      final Rect chart = tester.getRect(find.byKey(LumeLearningTool.weekKey));
      expect(tester.getRect(barOf(6)).left, lessThan(chart.center.dx));
    });

    testWidgets('at 200 %', (WidgetTester tester) async {
      await pumpTax(tester, location: kLearning, textScale: 2);
      expectNoOverflow(tester);
    });

    testWidgets('the charts say what they show', (WidgetTester tester) async {
      await pumpTax(
        tester,
        location: kLearning,
        surface: const Size(390, 5000),
      );
      final SemanticsHandle h = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(RegExp(r'^Consistency, 29 / 35')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('M: 20'), findsOneWidget);
      expect(find.bySemanticsLabel('Weekly goal'), findsOneWidget);
      h.dispose();
    });
  });

  group('the bar chart, on its own', () {
    test('a zero value is the minimum, and every zero is not a division by '
        'zero', () {
      const LumeBarChart zeros = LumeBarChart(
        values: <double>[0, 0, 0],
        labels: <String>['a', 'b', 'c'],
        label: 'x',
      );
      expect(zeros.fillOf(0), 0);
      const LumeBarChart ceiling = LumeBarChart(
        values: <double>[10, 20],
        labels: <String>['a', 'b'],
        label: 'x',
        max: 40,
      );
      expect(ceiling.fillOf(1), 50, reason: 'o.max raises the ceiling');
    });
  });
}

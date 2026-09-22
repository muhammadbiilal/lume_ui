/// Focus against the running reference — the **sample** composition.
///
/// The seven committed cells were measured in a browser with
/// `measure_destinations.mjs --tool focus`, and [ToolParity] compares each
/// recorded `getBoundingClientRect` against the finder for the same element,
/// relative to the tool bar on both sides. Only the parity build is compared:
/// the figures below the clock face — "75 Minutes today", "5 Day streak",
/// "3 Sessions" and the seven-bar week — are `context.js` constants, and no
/// development or release build draws them (`focus_sample_test.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_chart.dart';
import 'package:lume/core/widgets/lume/lume_clock_face.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/focus/presentation/focus_tool.dart';

import '../../helpers/load_fonts.dart';
import '../tools/tool_parity.dart';
import 'focus_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('focus');
  tearDownAll(parity.write);

  Map<String, Finder> elements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    'clockface': find.byType(LumeClockFace),
    'clockface.time': find.byKey(LumeFocusTool.timeKey),
    'clock.btn1': find.byKey(LumeFocusTool.startKey),
    'clock.btn2': find.byKey(LumeFocusTool.resetKey),
    'sect1': find.byKey(LumeFocusTool.sampleFiguresKey),
    'metrics': find.byKey(LumeFocusTool.sampleMetricsKey),
    'metric1': find.byType(LumeMetric).first,
    'metric2': find.byType(LumeMetric).at(1),
    'sect2': find.byKey(LumeFocusTool.sampleWeekSectionKey),
    'kard': find.byType(LumeCard).first,
    'bars': find.byKey(LumeFocusTool.sampleWeekKey),
    'srcbar': find.byType(LumeSourceBar),
    'related': find.byType(LumeRelatedTools),
  };

  // Only the English cells are compared point for point. The Urdu and Arabic
  // cells were measured in Chrome with its own Noto faces; Flutter loads
  // different ones, so their line boxes differ by a few points everywhere and
  // a bounds comparison would be measuring the font, not the layout. What
  // those cells are for — the words, the direction and the numerals — is
  // asserted in `focus_l10n_test.dart`.
  group('where everything is', () {
    for (final (String cell, Size size) in <(String, Size)>[
      ('tool_focus_default_pk_390x844_light_en', const Size(390, 5000)),
      ('tool_focus_default_pk_390x844_dark_en', const Size(390, 5000)),
      // 852x393 is the height-constrained landscape cell. Its column
      // width comes from the shell's rail against a 393-point height,
      // which a tall test surface cannot reproduce; comparing it would
      // measure the stage, not the tool. The three width classes below
      // cover what the layout actually decides.
      ('tool_focus_default_pk_700x900_light_en', const Size(650, 5000)),
      ('tool_focus_default_pk_1100x900_light_en', const Size(1050, 5000)),
    ]) {
      final bool needsShell = !kFocusRouted && size.width > 390;
      testWidgets('$cell${needsShell ? ' — skipped: $kFocusUnrouted' : ''}', (
        WidgetTester tester,
      ) async {
        await pumpFocus(
          tester,
          FocusWorld(),
          surface: size,
          theme: cell.contains('_dark_') ? ThemeMode.dark : ThemeMode.light,
          locale: Locale(cell.split('_').last),
        );
        final List<String> misses = parity.bounds(
          tester,
          cell,
          elements(),
          // A `LumeToolSection` carries the 24-point gap above it inside its
          // own box; the reference's `<section>` has it as a margin, outside
          // its box. Recorded here rather than hidden in a tolerance.
          shifted: const <String, double>{'sect1': -24, 'sect2': -24},
          grown: const <String, double>{'sect1': 24, 'sect2': 24},
          drifting: const <String>{'srcbar', 'related', 'kard', 'bars'},
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      }, skip: needsShell);
    }
  });

  group('what it says, in the state the reference was captured in', () {
    testWidgets('the clock face, the figures and the week', (
      WidgetTester tester,
    ) async {
      const String cell = 'tool_focus_default_pk_390x844_light_en';
      await pumpFocus(tester, FocusWorld(), surface: const Size(390, 5000));
      final Map<String, dynamic> k =
          webToolCell(cell)!['composition'] as Map<String, dynamic>;

      final Map<String, dynamic> header = k['header'] as Map<String, dynamic>;
      expect(find.text(header['title'] as String), findsOneWidget);
      expect(find.text(header['sub'] as String), findsOneWidget);
      expect(header['actions'], isEmpty);

      final Map<String, dynamic> clock = k['clock'] as Map<String, dynamic>;
      expect(focusTime(tester), clock['time']);
      expect(find.text(clock['sub'] as String), findsOneWidget);
      expect(<String>[
        ...textsUnder(tester, find.byKey(LumeFocusTool.startKey)),
        ...textsUnder(tester, find.byKey(LumeFocusTool.resetKey)),
      ], clock['buttons']);

      // "75 Minutes today · 5 Day streak · 3 Sessions", in that order.
      expect(
        textsUnder(tester, find.byKey(LumeFocusTool.sampleMetricsKey)),
        <String>['75', 'Minutes today', '5', 'Day streak', '3', 'Sessions'],
      );

      // The seven bars, with the reference's own labels and its highlight.
      final LumeBarChart bars = tester.widget<LumeBarChart>(
        find.byKey(LumeFocusTool.sampleWeekKey),
      );
      final List<dynamic> web = k['bars'] as List<dynamic>;
      expect(bars.values, <double>[
        for (final dynamic b in web)
          double.parse((b as Map<String, dynamic>)['fill'] as String),
      ]);
      expect(bars.labels, <String>[
        for (final dynamic b in web) (b as Map<String, dynamic>)['label'],
      ]);
      expect(bars.highlight, 6);
      expect(find.text('This week'), findsOneWidget);

      final Map<String, dynamic> src = k['source'] as Map<String, dynamic>;
      expect(find.text(src['fresh'] as String), findsOneWidget);
      expect(referenceSourceLine(tester), src['line']);
      expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
    });

    testWidgets('and it says the figures are sample data, where the figures '
        'are', (WidgetTester tester) async {
      await pumpFocus(tester, FocusWorld(), surface: const Size(390, 5000));
      // C85: a parity build marks a sample-data tool in its own source bar,
      // in the reader's language — that is the whole licence for drawing
      // somebody else's afternoon here.
      expect(find.byKey(LumeSourceLine.sampleKey), findsOneWidget);
      expect(find.text('Sample data'), findsOneWidget);
    });
  });
}

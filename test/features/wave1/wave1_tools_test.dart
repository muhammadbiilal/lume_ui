/// Rollout wave 1, against the running reference, and used (F6B decision 7).
///
/// Six tools on two approved archetypes: Age, Date Calculator, Tip & Split,
/// Loan / EMI and Compound Interest on Tax's form calculator, Stopwatch on
/// Timer's clock instrument. Each is measured against its web cells, read
/// back against what the reference drew, driven through what it does, and
/// laid out right to left and at 200 %.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/platform/lume_export.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_chart.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_clock_face.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_pressable.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_share_card.dart';
import 'package:lume/core/widgets/lume/lume_spark.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/age/presentation/age_tool.dart';
import 'package:lume/features/compound/presentation/compound_tool.dart';
import 'package:lume/features/datecalc/presentation/datecalc_tool.dart';
import 'package:lume/features/loan/presentation/loan_tool.dart';
import 'package:lume/features/stopwatch/presentation/stopwatch_tool.dart';
import 'package:lume/features/tipsplit/presentation/tipsplit_tool.dart';
import 'package:lume/features/shell/presentation/fixture_tool_screen.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';
import '../tools/tool_parity.dart';

Future<void> pumpTool(
  WidgetTester tester,
  String id, {
  String state = 'default_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  List<Override> overrides = const <Override>[],
}) async {
  await pumpLumeRouter(
    tester,
    initialLocation: LumeRoutes.tool(LumeRoutes.tools, id),
    profile: taxProfile(state),
    surface: surface,
    locale: locale,
    textScale: textScale,
    overrides: overrides,
  );
  await tester.pumpAndSettle();
  // Reminders' durable store (`ROLLOUT_WAVE_7.md`) hydrates over a real
  // SQLite read — genuine async I/O `pumpAndSettle`'s fake-async clock does
  // not fast-forward, unlike every other tool's synchronous or Timer-based
  // store. Generic, not Reminders-specific: waits only while the frame's own
  // loading skeleton is still showing, for whichever tool that turns out to
  // be true of.
  if (find.byType(LumeSkeleton).evaluate().isNotEmpty) {
    await tester.runAsync(() async {
      for (
        int i = 0;
        i < 200 && find.byType(LumeSkeleton).evaluate().isNotEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
  }
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

Finder toolbarAction(String label) => find.descendant(
  of: find.byType(LumeToolbar),
  matching: find.byWidgetPredicate(
    (Widget w) => w is LumeIconButton && w.label == label,
  ),
);

Map<String, dynamic> composition(String cell) =>
    webToolCell(cell)!['composition'] as Map<String, dynamic>;

List<String> compactValues(WidgetTester tester, Key rows) => <String>[
  for (final LumeCompactRow r in tester.widgetList<LumeCompactRow>(
    inKey(rows, find.byType(LumeCompactRow)),
  ))
    r.value ?? '',
];

List<String> compactLabels(WidgetTester tester, Key rows) => <String>[
  for (final LumeCompactRow r in tester.widgetList<LumeCompactRow>(
    inKey(rows, find.byType(LumeCompactRow)),
  ))
    r.label,
];

void expectSummary(WidgetTester tester, Key key, Map<String, dynamic> web) {
  final LumeSummaryCard s = tester.widget<LumeSummaryCard>(find.byKey(key));
  expect(s.kicker, web['kicker']);
  expect('${s.value}${s.unit ?? ''}', web['value']);
  expect(s.caption, web['caption']);
  expect(
    <List<String>>[
      for (final LumeStat st in s.stats) <String>[st.value, st.label],
    ],
    <List<String>>[
      for (final dynamic w in web['stats'] as List<dynamic>)
        <String>[
          (w as Map<String, dynamic>)['value'] as String,
          w['label'] as String,
        ],
    ],
  );
}

/// Labels, and the typed value and its unit where the field is typed; a
/// date field shows its day in the reader's locale rather than the ISO the
/// reference's input holds (C83).
void expectFields(
  WidgetTester tester,
  List<dynamic> web, {
  Set<int> dates = const <int>{},
}) {
  final List<LumeToolField> fields = tester
      .widgetList<LumeToolField>(find.byType(LumeToolField))
      .toList();
  expect(fields.map((LumeToolField f) => f.label).toList(), <String>[
    for (final dynamic w in web) (w as Map<String, dynamic>)['label'] as String,
  ]);
  for (int i = 0; i < fields.length; i++) {
    final Map<String, dynamic> w = web[i] as Map<String, dynamic>;
    if (dates.contains(i)) {
      expect(fields[i].onTap, isNotNull, reason: '${w['label']} is picked');
      continue;
    }
    expect(fields[i].controller?.text ?? fields[i].value, w['value']);
    expect(fields[i].prefix ?? fields[i].suffix, w['affix']);
  }
}

List<String> sectionTitles(WidgetTester tester) => <String>[
  for (final LumeToolSection s in tester.widgetList<LumeToolSection>(
    find.byType(LumeToolSection),
  ))
    if (s.title != null) s.title!,
];

List<String> webTitles(Map<String, dynamic> k) => <String>[
  for (final dynamic s in k['sections'] as List<dynamic>)
    if ((s as Map<String, dynamic>)['title'] != null) s['title'] as String,
];

typedef BoundsCase = (String cell, Size surface);

List<BoundsCase> boundsCells(String tool) => <BoundsCase>[
  ('tool_${tool}_default_pk_390x844_light_en', const Size(390, 5000)),
  ('tool_${tool}_default_pk_700x900_light_en', const Size(650, 5000)),
  ('tool_${tool}_default_pk_1100x900_light_en', const Size(1050, 5000)),
];

void main() {
  setUpAll(loadLumeFonts);

  Finder firstCard() => find.byType(LumeCard).first;
  Finder cardAround(Key key) =>
      find.ancestor(of: find.byKey(key), matching: find.byType(LumeCard));

  // ------------------------------------------------------------------ Age

  group('Age', () {
    final ToolParity parity = ToolParity('age');
    tearDownAll(parity.write);

    for (final (String cell, Size size) in boundsCells('age')) {
      testWidgets('where everything is · $cell', (WidgetTester tester) async {
        await pumpTool(tester, 'age', surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          <String, Finder>{
            'toolbar': find.byType(LumeToolbar),
            'kard': firstCard(),
            'field1': find.byKey(LumeAgeTool.dobKey),
            'summary': find.byKey(LumeAgeTool.summaryKey),
            'kard2': cardAround(LumeAgeTool.nextKey),
            'meter1': find.byKey(LumeAgeTool.nextKey),
            'rows': find.byKey(LumeAgeTool.milestonesKey),
            'crow1': inKey(
              LumeAgeTool.milestonesKey,
              find.byType(LumeCompactRow),
            ).first,
            'srcbar': find.byType(LumeSourceBar),
            'related': find.byType(LumeRelatedTools),
          },
          drifting: const <String>{
            'kard2',
            'meter1',
            'rows',
            'crow1',
            'srcbar',
            'related',
          },
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }

    for (final String state in <String>['default_pk', 'default_us']) {
      testWidgets('what it says · $state', (WidgetTester tester) async {
        await pumpTool(tester, 'age', state: state);
        final Map<String, dynamic> k = composition(
          'tool_age_${state}_390x844_light_en',
        );
        expectSummary(
          tester,
          LumeAgeTool.summaryKey,
          k['summary'] as Map<String, dynamic>,
        );
        expectFields(
          tester,
          k['fields'] as List<dynamic>,
          dates: const <int>{0},
        );
        expect(sectionTitles(tester), webTitles(k));
        expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
        final LumeMeterRow meter = tester.widget<LumeMeterRow>(
          find.byKey(LumeAgeTool.nextKey),
        );
        expect(meter.value, 'in 223 days');
        expect(compactLabels(tester, LumeAgeTool.milestonesKey), <String>[
          '10000 days old',
          '15000 days old',
          '20000 days old',
        ]);
      });
    }

    testWidgets('the date of birth is picked, not typed', (
      WidgetTester tester,
    ) async {
      await pumpTool(tester, 'age', surface: const Size(390, 900));
      await tester.tap(find.byKey(LumeAgeTool.dobKey));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
    });

    testWidgets('Share hands over the age on screen (C83)', (
      WidgetTester tester,
    ) async {
      await pumpTool(tester, 'age', surface: const Size(390, 900));
      await tester.tap(toolbarAction('Share'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LumeShareCardArt>(find.byType(LumeShareCardArt))
            .card
            .text,
        'You are 33 years · 4 months and 20 days',
      );
    });
  });

  // ------------------------------------------------------ Date Calculator

  group('Date Calculator', () {
    final ToolParity parity = ToolParity('datecalc');
    tearDownAll(parity.write);

    for (final (String cell, Size size) in boundsCells('datecalc')) {
      testWidgets('where everything is · $cell', (WidgetTester tester) async {
        await pumpTool(tester, 'datecalc', surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          <String, Finder>{
            'toolbar': find.byType(LumeToolbar),
            'segmented': find.byKey(LumeDatecalcTool.modeKey),
            'kard': firstCard(),
            'field1': find.byKey(LumeDatecalcTool.fromKey),
            'field2': find.byKey(LumeDatecalcTool.toKey),
            'summary': find.byKey(LumeDatecalcTool.summaryKey),
            'rows': find.byKey(LumeDatecalcTool.businessKey),
            'crow1': inKey(
              LumeDatecalcTool.businessKey,
              find.byType(LumeCompactRow),
            ).first,
            'srcbar': find.byType(LumeSourceBar),
            'related': find.byType(LumeRelatedTools),
          },
          drifting: const <String>{'rows', 'crow1', 'srcbar', 'related'},
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }

    for (final String state in <String>['default_pk', 'default_us']) {
      testWidgets('what it says · $state', (WidgetTester tester) async {
        await pumpTool(tester, 'datecalc', state: state);
        final Map<String, dynamic> k = composition(
          'tool_datecalc_${state}_390x844_light_en',
        );
        expectSummary(
          tester,
          LumeDatecalcTool.summaryKey,
          k['summary'] as Map<String, dynamic>,
        );
        expectFields(
          tester,
          k['fields'] as List<dynamic>,
          dates: const <int>{0, 1},
        );
        expect(
          tester
              .widget<LumeSegmented>(find.byKey(LumeDatecalcTool.modeKey))
              .items
              .map((LumeChoice c) => c.label)
              .toList(),
          <String>[
            for (final dynamic s in k['segments'] as List<dynamic>)
              (s as Map<String, dynamic>)['label'] as String,
          ],
        );
        expect(sectionTitles(tester), webTitles(k));
        expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
        expect(compactValues(tester, LumeDatecalcTool.businessKey), <String>[
          '0',
          '0',
          '6',
        ]);
      });
    }

    testWidgets('adding days: the date, and one day is a day', (
      WidgetTester tester,
    ) async {
      await pumpTool(tester, 'datecalc', surface: const Size(390, 1200));
      await tester.tap(inKey(LumeDatecalcTool.modeKey, find.text('Add days')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LumeToolField>(find.byKey(LumeDatecalcTool.fromKey))
            .label,
        'Start date',
      );
      await tester.enterText(
        inKey(LumeDatecalcTool.daysKey, find.byType(EditableText)),
        '10',
      );
      await tester.pumpAndSettle();
      final LumeSummaryCard s = tester.widget<LumeSummaryCard>(
        find.byKey(LumeDatecalcTool.summaryKey),
      );
      expect(s.kicker, 'Result date');
      expect(s.value, '17 September 2026');
      expect(s.caption, '10 days from the start date');
      expect(compactValues(tester, LumeDatecalcTool.businessKey), <String>[
        '8',
        '2',
        '6',
      ]);
      await tester.enterText(
        inKey(LumeDatecalcTool.daysKey, find.byType(EditableText)),
        '1',
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LumeSummaryCard>(find.byKey(LumeDatecalcTool.summaryKey))
            .caption,
        '1 day from the start date',
      );
    });
  });

  // --------------------------------------------------------- Tip & Split

  group('Tip & Split', () {
    final ToolParity parity = ToolParity('tipsplit');
    tearDownAll(parity.write);

    // The people row is 44 tall for its stepper targets (D6): the card is six
    // taller, and everything under it six lower (C83).
    const Map<String, double> lower = <String, double>{
      'summary': 6,
      'rows': 6,
      'crow1': 6,
      'srcbar': 6,
      'related': 6,
    };

    for (final (String cell, Size size) in boundsCells('tipsplit')) {
      testWidgets('where everything is · $cell', (WidgetTester tester) async {
        await pumpTool(tester, 'tipsplit', surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          <String, Finder>{
            'toolbar': find.byType(LumeToolbar),
            'kard': firstCard(),
            'field1': find.byKey(LumeTipsplitTool.billKey),
            'chips': find.byKey(LumeTipsplitTool.tipsKey),
            'chip1': find.byType(LumeChoiceChip).first,
            'summary': find.byKey(LumeTipsplitTool.summaryKey),
            'rows': find.byKey(LumeTipsplitTool.splitKey),
            'crow1': inKey(
              LumeTipsplitTool.splitKey,
              find.byType(LumeCompactRow),
            ).first,
            'srcbar': find.byType(LumeSourceBar),
            'related': find.byType(LumeRelatedTools),
          },
          shifted: lower,
          grown: const <String, double>{'kard': 6},
          drifting: const <String>{'rows', 'crow1', 'srcbar', 'related'},
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }

    for (final String state in <String>['default_pk', 'default_us']) {
      testWidgets('what it says · $state', (WidgetTester tester) async {
        await pumpTool(tester, 'tipsplit', state: state);
        final Map<String, dynamic> k = composition(
          'tool_tipsplit_${state}_390x844_light_en',
        );
        expectSummary(
          tester,
          LumeTipsplitTool.summaryKey,
          k['summary'] as Map<String, dynamic>,
        );
        expectFields(tester, k['fields'] as List<dynamic>);
        expect(sectionTitles(tester), webTitles(k));
        expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
        expect(
          tester
              .widgetList<LumeChoiceChip>(find.byType(LumeChoiceChip))
              .map((LumeChoiceChip c) => '${c.label}${c.selected ? '*' : ''}')
              .toList(),
          <String>['0%', '5%', '10%*', '15%', '20%'],
        );
        expect(compactLabels(tester, LumeTipsplitTool.splitKey), <String>[
          'Person 1',
          'Person 2',
        ]);
      });
    }

    testWidgets('a tip and a head count change the split; one person is the '
        'fewest', (WidgetTester tester) async {
      await pumpTool(tester, 'tipsplit', surface: const Size(390, 1200));
      await tester.tap(find.widgetWithText(LumeChoiceChip, '15%'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LumeSummaryCard>(find.byKey(LumeTipsplitTool.summaryKey))
            .value,
        'Rs 6,509',
      );
      final Finder steps = inKey(
        LumeTipsplitTool.peopleKey,
        find.byType(LumePressable),
      );
      await tester.tap(steps.last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LumeSummaryCard>(find.byKey(LumeTipsplitTool.summaryKey))
            .value,
        'Rs 4,339.33',
      );
      expect(compactLabels(tester, LumeTipsplitTool.splitKey), hasLength(3));
      await tester.tap(steps.first);
      await tester.pumpAndSettle();
      await tester.tap(steps.first);
      await tester.pumpAndSettle();
      final LumeStepper stepper = tester.widget<LumeStepper>(
        find.byKey(LumeTipsplitTool.peopleKey),
      );
      expect(stepper.value, '1');
      expect(stepper.onDecrement, isNull);
    });
  });

  // ----------------------------------------------------------- Loan / EMI

  group('Loan / EMI', () {
    final ToolParity parity = ToolParity('loan');
    tearDownAll(parity.write);

    for (final (String cell, Size size) in boundsCells('loan')) {
      testWidgets('where everything is · $cell', (WidgetTester tester) async {
        await pumpTool(tester, 'loan', surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          <String, Finder>{
            'toolbar': find.byType(LumeToolbar),
            'kard': firstCard(),
            'field1': find.byKey(LumeLoanTool.principalKey),
            'field2': find.byKey(LumeLoanTool.rateKey),
            'summary': find.byKey(LumeLoanTool.summaryKey),
            'donutwrap': find.byKey(LumeLoanTool.splitKey),
            'table': find.byKey(LumeLoanTool.scheduleKey),
            'rows': find.byKey(LumeLoanTool.compareKey),
            'crow1': inKey(
              LumeLoanTool.compareKey,
              find.byType(LumeCompactRow),
            ).first,
            'srcbar': find.byType(LumeSourceBar),
            'related': find.byType(LumeRelatedTools),
          },
          drifting: const <String>{
            'donutwrap',
            'table',
            'rows',
            'crow1',
            'srcbar',
            'related',
          },
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }

    for (final String state in <String>['default_pk', 'default_us']) {
      testWidgets('what it says · $state', (WidgetTester tester) async {
        await pumpTool(tester, 'loan', state: state);
        final Map<String, dynamic> k = composition(
          'tool_loan_${state}_390x844_light_en',
        );
        expectSummary(
          tester,
          LumeLoanTool.summaryKey,
          k['summary'] as Map<String, dynamic>,
        );
        expectFields(tester, k['fields'] as List<dynamic>);
        expect(sectionTitles(tester), webTitles(k));
        expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
        final Map<String, dynamic> table = k['table'] as Map<String, dynamic>;
        final LumeTable t = tester.widget<LumeTable>(
          find.byKey(LumeLoanTool.scheduleKey),
        );
        expect(
          t.columns.map((LumeColumn c) => c.label).toList(),
          table['head'],
        );
        expect(t.rows, table['rows']);
        final Map<String, dynamic> donut = k['donut'] as Map<String, dynamic>;
        final LumeDonut d = tester.widget<LumeDonut>(
          find.byKey(LumeLoanTool.splitKey),
        );
        expect(
          <String?>[d.centre, d.centreSub],
          <String?>[donut['mid'] as String?, donut['sub'] as String?],
        );
        expect(d.slices.map((LumeDonutSlice s) => s.label).toList(), <String>[
          for (final dynamic key in donut['keys'] as List<dynamic>)
            (key as Map<String, dynamic>)['label'] as String,
        ]);
        expect(compactLabels(tester, LumeLoanTool.compareKey), <String>[
          'At 10.0%',
          'At 12.0%',
          'At 14.0%',
        ]);
      });
    }

    testWidgets('the comparison is worked on the loan amount (C83)', (
      WidgetTester tester,
    ) async {
      await pumpTool(tester, 'loan');
      expect(compactValues(tester, LumeLoanTool.compareKey), <String>[
        'Rs 120,258',
        'Rs 125,904',
        'Rs 131,698',
      ]);
    });

    testWidgets('no tenure has no payment and no schedule', (
      WidgetTester tester,
    ) async {
      await pumpTool(tester, 'loan', surface: const Size(390, 1600));
      await tester.enterText(
        inKey(LumeLoanTool.yearsKey, find.byType(EditableText)),
        '0',
      );
      await tester.pumpAndSettle();
      final LumeSummaryCard s = tester.widget<LumeSummaryCard>(
        find.byKey(LumeLoanTool.summaryKey),
      );
      expect(s.value, 'Rs 0');
      expect(s.caption, 'over 0 payments');
      expect(
        tester.widget<LumeTable>(find.byKey(LumeLoanTool.scheduleKey)).rows,
        isEmpty,
      );
    });

    testWidgets('Export writes the schedule the reference exports', (
      WidgetTester tester,
    ) async {
      final LumeRecordingExporter exporter = LumeRecordingExporter();
      await pumpTool(
        tester,
        'loan',
        surface: const Size(390, 900),
        overrides: <Override>[exporterProvider.overrideWithValue(exporter)],
      );
      await tester.tap(toolbarAction('Export'));
      await tester.pumpAndSettle();
      final LumeExportFile file = exporter.exported.single;
      expect(file.fileName, 'lume-loan-2026-09-07.csv');
      final List<String> lines = utf8
          .decode(file.bytes)
          .replaceFirst('﻿', '')
          .split('\r\n');
      expect(lines.first, 'Year,Principal,Interest,Balance');
      expect(lines[1], '1,878943,631900,4781057');
      expect(lines, hasLength(6));
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Share hands over the payment and its term (C83)', (
      WidgetTester tester,
    ) async {
      await pumpTool(tester, 'loan', surface: const Size(390, 900));
      await tester.tap(toolbarAction('Share'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LumeShareCardArt>(find.byType(LumeShareCardArt))
            .card
            .text,
        'Monthly payment: Rs 125,904 · over 60 payments',
      );
    });
  });

  // ---------------------------------------------------- Compound Interest

  group('Compound Interest', () {
    final ToolParity parity = ToolParity('compound');
    tearDownAll(parity.write);

    for (final (String cell, Size size) in boundsCells('compound')) {
      testWidgets('where everything is · $cell', (WidgetTester tester) async {
        await pumpTool(tester, 'compound', surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          <String, Finder>{
            'toolbar': find.byType(LumeToolbar),
            'kard': firstCard(),
            'field1': find.byKey(LumeCompoundTool.initialKey),
            'field2': find.byKey(LumeCompoundTool.monthlyKey),
            'summary': find.byKey(LumeCompoundTool.summaryKey),
            'chart': find.byKey(LumeCompoundTool.chartKey),
            'table': find.byKey(LumeCompoundTool.tableKey),
            'srcbar': find.byType(LumeSourceBar),
            'related': find.byType(LumeRelatedTools),
          },
          drifting: const <String>{'chart', 'table', 'srcbar', 'related'},
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }

    for (final String state in <String>['default_pk', 'default_us']) {
      testWidgets('what it says · $state', (WidgetTester tester) async {
        await pumpTool(tester, 'compound', state: state);
        final Map<String, dynamic> k = composition(
          'tool_compound_${state}_390x844_light_en',
        );
        expectSummary(
          tester,
          LumeCompoundTool.summaryKey,
          k['summary'] as Map<String, dynamic>,
        );
        expectFields(tester, k['fields'] as List<dynamic>);
        expect(sectionTitles(tester), webTitles(k));
        expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
        final Map<String, dynamic> table = k['table'] as Map<String, dynamic>;
        final LumeTable t = tester.widget<LumeTable>(
          find.byKey(LumeCompoundTool.tableKey),
        );
        expect(
          t.columns.map((LumeColumn c) => c.label).toList(),
          table['head'],
        );
        expect(t.rows, table['rows']);
        expect(
          tester
              .widget<LumeLineChart>(find.byKey(LumeCompoundTool.chartKey))
              .labels,
          <String>['0', '5y', '10y'],
        );
      });
    }

    testWidgets('a single year is drawn from where it started', (
      WidgetTester tester,
    ) async {
      await pumpTool(tester, 'compound', surface: const Size(390, 1600));
      await tester.enterText(
        inKey(LumeCompoundTool.yearsKey, find.byType(EditableText)),
        '1',
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LumeLineChart>(find.byKey(LumeCompoundTool.chartKey))
            .values,
        hasLength(2),
      );
      expect(
        tester
            .widget<LumeSummaryCard>(find.byKey(LumeCompoundTool.summaryKey))
            .caption,
        'after 1 year',
      );
    });
  });

  // ------------------------------------------------------------ Stopwatch

  group('Stopwatch', () {
    final ToolParity parity = ToolParity('stopwatch');
    tearDownAll(parity.write);

    for (final (String cell, Size size) in boundsCells('stopwatch')) {
      testWidgets('where everything is · $cell', (WidgetTester tester) async {
        await pumpTool(tester, 'stopwatch', surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          <String, Finder>{
            'toolbar': find.byType(LumeToolbar),
            'clockface': find.byType(LumeClockFace),
            'clockface.time': find.byKey(LumeStopwatchTool.timeKey),
            'clock.btn1': find.byKey(LumeStopwatchTool.startKey),
            'clock.btn2': find.byKey(LumeStopwatchTool.resetKey),
            'state': find.byKey(LumeStopwatchTool.emptyKey),
            'srcbar': find.byType(LumeSourceBar),
            'related': find.byType(LumeRelatedTools),
          },
          drifting: const <String>{'state', 'srcbar', 'related'},
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }

    for (final String state in <String>['default_pk', 'default_us']) {
      testWidgets('what it says · $state', (WidgetTester tester) async {
        await pumpTool(tester, 'stopwatch', state: state);
        final Map<String, dynamic> k = composition(
          'tool_stopwatch_${state}_390x844_light_en',
        );
        final Map<String, dynamic> clock = k['clock'] as Map<String, dynamic>;
        final LumeClockFace face = tester.widget<LumeClockFace>(
          find.byType(LumeClockFace),
        );
        expect(face.display, clock['time']);
        expect(<String>[
          (face.primary as LumeButton).label,
          (face.reset as LumeButton).label,
        ], clock['buttons']);
        expect(
          tester
              .widget<LumeToolState>(find.byKey(LumeStopwatchTool.emptyKey))
              .title,
          (k['state'] as Map<String, dynamic>)['title'],
        );
        expect(sectionTitles(tester), webTitles(k));
        expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
      });
    }

    testWidgets('Start runs it; Lap records; Pause stops; Reset clears (C83)', (
      WidgetTester tester,
    ) async {
      await pumpTool(tester, 'stopwatch', surface: const Size(390, 1200));
      await tester.tap(find.byKey(LumeStopwatchTool.startKey));
      await tester.pump();
      expect(
        tester.widget<LumeButton>(find.byKey(LumeStopwatchTool.startKey)).label,
        'Pause',
      );
      expect(find.byKey(LumeStopwatchTool.resetKey), findsNothing);
      await tester.pump(const Duration(milliseconds: 120));
      await tester.tap(find.byKey(LumeStopwatchTool.lapKey));
      await tester.pump();
      expect(compactLabels(tester, LumeStopwatchTool.lapsKey), <String>[
        'Lap 1',
      ]);
      await tester.tap(find.byKey(LumeStopwatchTool.startKey));
      await tester.pump();
      expect(find.byKey(LumeStopwatchTool.lapKey), findsNothing);
      await tester.tap(find.byKey(LumeStopwatchTool.resetKey));
      await tester.pump();
      expect(find.byKey(LumeStopwatchTool.emptyKey), findsOneWidget);
      expect(
        tester.widget<LumeClockFace>(find.byType(LumeClockFace)).display,
        '00:00.00',
      );
    });
  });

  // ------------------------------------------------------ every language

  group('right to left, and at 200 %', () {
    for (final String id in <String>[
      'age',
      'datecalc',
      'tipsplit',
      'loan',
      'compound',
      'stopwatch',
    ]) {
      testWidgets('$id in Urdu', (WidgetTester tester) async {
        await pumpTool(tester, id, locale: const Locale('ur'));
        expect(
          Directionality.of(tester.element(find.byType(LumeToolFrame))),
          TextDirection.rtl,
        );
        expect(find.byType(FixtureToolScreen), findsNothing);
        expectNoOverflow(tester);
      });

      testWidgets('$id in Arabic', (WidgetTester tester) async {
        await pumpTool(tester, id, locale: const Locale('ar'));
        expectNoOverflow(tester);
      });

      testWidgets('$id at 200 %', (WidgetTester tester) async {
        await pumpTool(tester, id, textScale: 2);
        expectNoOverflow(tester);
      });
    }
  });
}

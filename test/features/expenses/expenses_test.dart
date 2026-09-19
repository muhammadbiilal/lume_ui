/// Expenses, against the running reference, and used — the first tool on the
/// record layer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/platform/lume_export.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_chart.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/expenses/presentation/expenses_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';
import '../tools/tool_parity.dart';

final String kExpenses = LumeRoutes.tool(LumeRoutes.tools, 'expenses');

Future<GoRouter> pumpExpenses(
  WidgetTester tester, {
  String state = 'default_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  List<Override> overrides = const <Override>[],
}) async {
  final GoRouter router = await pumpLumeRouter(
    tester,
    initialLocation: kExpenses,
    profile: taxProfile(state),
    surface: surface,
    locale: locale,
    textScale: textScale,
    overrides: overrides,
  );
  await tester.pumpAndSettle();
  return router;
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

/// The box a chip or option draws, inside its larger target.
Finder drawn(Type parent, double height) => find.descendant(
  of: find.byType(parent),
  matching: find.byWidgetPredicate(
    (Widget w) => w is Container && w.constraints?.minHeight == height,
  ),
);

Finder toolbarAction(String label) => find.descendant(
  of: find.byType(LumeToolbar),
  matching: find.byWidgetPredicate(
    (Widget w) =>
        (w is LumeIconButton && w.label == label) ||
        (w is LumeTextButton && w.label == label),
  ),
);

List<String> recordTitles(WidgetTester tester) => tester
    .widgetList<LumeRecordRow>(find.byType(LumeRecordRow))
    .map((LumeRecordRow r) => r.title)
    .toList();

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> openFirstRecord(WidgetTester tester) =>
    tapVisible(tester, find.byType(LumeRecordRow).first);

Future<void> openForm(WidgetTester tester) =>
    tapVisible(tester, find.byKey(LumeExpensesTool.addKey));

/// Lets the form's confirmation delay run out and the toast go.
Future<void> settleSave(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

Future<void> dismissToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('expenses');
  tearDownAll(parity.write);

  Map<String, Finder> listElements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    'toolbar.textbtn': find.byKey(LumeExpensesTool.addKey),
    'search': find.byKey(LumeExpensesTool.searchKey),
    // A chip, an option: the drawing, not the 44-point target around it.
    'cchip1': drawn(LumeRecordChip, LumeRecordChip.height).first,
    'cchip2': drawn(LumeRecordChip, LumeRecordChip.height).at(1),
    'recs': find.byKey(LumeExpensesTool.recordsKey),
    'rrec1': find.byType(LumeRecordRow).first,
    'rrec2': find.byType(LumeRecordRow).at(1),
    'segmented': find.byKey(LumeExpensesTool.rangeKey),
    'summary': find.byKey(LumeExpensesTool.summaryKey),
    'pring': find.byType(LumeProgressRing).first,
    'bars': find.byKey(LumeExpensesTool.weekKey),
    'donutwrap': find.byKey(LumeExpensesTool.categoriesKey),
    'fchip1': drawn(LumeFilterChip, LumeFilterChip.height).first,
    'fchip2': drawn(LumeFilterChip, LumeFilterChip.height).at(1),
    'sortopt1': drawn(LumeSortBar, LumeSortBar.optionHeight).first,
    'sortopt2': drawn(LumeSortBar, LumeSortBar.optionHeight).at(1),
    'rows': find.byKey(LumeExpensesTool.transactionsKey),
    'rrow1': inKey(
      LumeExpensesTool.transactionsKey,
      find.byType(LumeRichRow),
    ).first,
    'rrow2': inKey(
      LumeExpensesTool.transactionsKey,
      find.byType(LumeRichRow),
    ).at(1),
    'meter1': find.byType(LumeMeterRow).first,
    'meter2': find.byType(LumeMeterRow).at(1),
    'crow1': inKey(
      LumeExpensesTool.recurringKey,
      find.byType(LumeCompactRow),
    ).first,
    'btnrow': find.byKey(LumeExpensesTool.actionsKey),
    'btn1': inKey(LumeExpensesTool.actionsKey, find.byType(LumeButton)).first,
    'btn2': inKey(LumeExpensesTool.actionsKey, find.byType(LumeButton)).last,
    'srcbar': find.byType(LumeSourceBar),
    'privacy': find.byType(LumePrivateState),
    'related': find.byType(LumeRelatedTools),
  };

  // Below the records the page is one long column: a pixel of text drift in
  // any one row moves everything after it.
  const Set<String> below = <String>{
    'bars',
    'donutwrap',
    'fchip1',
    'fchip2',
    'sortopt1',
    'sortopt2',
    'rows',
    'rrow1',
    'rrow2',
    'meter1',
    'meter2',
    'crow1',
    'btnrow',
    'btn1',
    'btn2',
    'srcbar',
    'privacy',
    'related',
  };

  group('where everything is', () {
    for (final (String cell, Size size) in <(String, Size)>[
      ('tool_expenses_default_pk_390x844_light_en', const Size(390, 5000)),
      ('tool_expenses_default_pk_700x900_light_en', const Size(650, 5000)),
      ('tool_expenses_default_pk_1100x900_light_en', const Size(1050, 5000)),
    ]) {
      testWidgets(cell, (WidgetTester tester) async {
        await pumpExpenses(tester, surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          <String, Finder>{...listElements()}..removeWhere(
            // The note is text: at 650 and 1050 against 700 and 1100 it wraps
            // once more, and what follows it moves by that line.
            (String k, _) => size.width > 390 && k == 'related',
          ),
          // `.bars` stops above its caption; the chart here holds both.
          noHeight: <String>{'bars', if (size.width > 390) 'privacy'},
          drifting: below,
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }

    testWidgets('tool_expenses_default_pk_detail_390x844_light_en', (
      WidgetTester tester,
    ) async {
      await pumpExpenses(tester);
      await openFirstRecord(tester);
      await tester.pumpAndSettle();
      final List<String> misses = parity.bounds(
        tester,
        'tool_expenses_default_pk_detail_390x844_light_en',
        <String, Finder>{
          'toolbar': find.byType(LumeToolbar),
          'chero': find.byKey(LumeExpensesTool.heroKey),
          'cfacts': find.byKey(LumeExpensesTool.factsKey),
          'cacts': find.byKey(LumeExpensesTool.detailActionsKey),
          'crud.id': find.byKey(LumeExpensesTool.recordIdKey),
        },
        noWidth: const <String>{'crud.id'},
      );
      expect(misses, isEmpty, reason: misses.join('\n'));
    });

    testWidgets('tool_expenses_default_pk_new_390x844_light_en', (
      WidgetTester tester,
    ) async {
      await pumpExpenses(tester);
      // Title has the focus, as it has there; leaving it would show its error.
      await openForm(tester);
      final List<String> misses = parity.bounds(
        tester,
        'tool_expenses_default_pk_new_390x844_light_en',
        <String, Finder>{
          'toolbar': find.byType(LumeToolbar),
          'cform': find.byKey(LumeExpensesTool.formKey),
          'cfield1': find.byKey(LumeExpensesTool.fieldKey('title')),
          'cfield2': find.byKey(LumeExpensesTool.fieldKey('amount')),
          // `.cattach` is the dashed tile, under its label.
          'cattach': find.descendant(
            of: find.byKey(LumeExpensesTool.fieldKey('receipt')),
            matching: find.byWidgetPredicate(
              (Widget w) =>
                  w is CustomPaint &&
                  w.foregroundPainter.runtimeType.toString() == '_DashedBox',
            ),
          ),
          'csubmit': find.byKey(LumeExpensesTool.submitKey),
        },
        // `.cform` ends above `.csubmit`; here the one column holds both.
        noHeight: const <String>{'cform'},
        drifting: const <String>{'cattach', 'csubmit'},
      );
      expect(misses, isEmpty, reason: misses.join('\n'));
    });
  });

  group('what it says, in each state the reference was captured in', () {
    Map<String, dynamic> composition(String cell) =>
        webToolCell(cell)!['composition'] as Map<String, dynamic>;

    List<String> strings(Object? v) => (v as List<dynamic>).cast<String>();

    // The reference writes a transaction's date as "1 Sep" for every reader;
    // it is the reader's own short date here (C74). Either way it names the
    // same day.
    List<String> sameDay(List<String> meta) => <String>[
      for (final String m in meta)
        m.replaceAllMapped(
          RegExp(r'^(?:(\d+) Sept?|Sept? (\d+))$'),
          (Match d) => 'Sep ${d[1] ?? d[2]}',
        ),
    ];

    void expectHeader(WidgetTester tester, Map<String, dynamic> k) {
      final Map<String, dynamic> h = k['header'] as Map<String, dynamic>;
      final LumeToolbar bar = tester.widget<LumeToolbar>(
        find.byType(LumeToolbar),
      );
      expect(
        <String?>[bar.title, bar.subtitle],
        <String?>[h['title'] as String?, h['sub'] as String?],
      );
      for (final dynamic a in h['actions'] as List<dynamic>) {
        final Map<String, dynamic> m = a as Map<String, dynamic>;
        final String label = (m['text'] ?? m['label']) as String;
        expect(toolbarAction(label), findsOneWidget, reason: label);
      }
    }

    Future<void> expectList(WidgetTester tester, String cell) async {
      final Map<String, dynamic> k = composition(cell);
      final Map<String, dynamic> r = k['records'] as Map<String, dynamic>;
      final Map<String, dynamic> x = k['finance'] as Map<String, dynamic>;
      expectHeader(tester, k);

      expect(
        tester
            .widget<LumeSearchField>(find.byKey(LumeExpensesTool.searchKey))
            .placeholder,
        r['placeholder'],
      );
      expect(
        <List<Object?>>[
          for (final LumeRecordChip c in tester.widgetList<LumeRecordChip>(
            find.byType(LumeRecordChip),
          ))
            <Object?>[c.label, '${c.count}', c.selected],
        ],
        <List<Object?>>[
          for (final dynamic c in r['chips'] as List<dynamic>)
            (c as List<dynamic>).cast<Object?>(),
        ],
      );
      final List<dynamic> states = r['states'] as List<dynamic>;
      if (states.isEmpty) {
        expect(
          <List<String?>>[
            for (final LumeRecordRow row in tester.widgetList<LumeRecordRow>(
              find.byType(LumeRecordRow),
            ))
              <String?>[row.initial, row.title, row.subtitle, row.value],
          ],
          <List<String?>>[
            for (final dynamic w in r['rows'] as List<dynamic>)
              <String>[
                (w as Map<String, dynamic>)['initial'] as String,
                w['title'] as String,
                w['sub'] as String,
                w['value'] as String,
              ],
          ],
        );
      } else {
        final Map<String, dynamic> s = states.single as Map<String, dynamic>;
        final LumeCollectionState st = tester.widget<LumeCollectionState>(
          find.byKey(LumeExpensesTool.recordStateKey),
        );
        expect(
          <Object?>[st.title, st.text, (st.primaryAction! as LumeButton).label],
          <Object?>[s['title'], s['text'], strings(s['ctas']).single],
        );
      }

      final LumeSegmented seg = tester.widget<LumeSegmented>(
        find.byKey(LumeExpensesTool.rangeKey),
      );
      expect(
        <Object?>[
          seg.items.map((LumeChoice c) => c.label).toList(),
          seg.items.firstWhere((LumeChoice c) => c.value == seg.value).label,
        ],
        <Object?>[
          <String>[
            for (final dynamic s in k['segments'] as List<dynamic>)
              (s as Map<String, dynamic>)['label'] as String,
          ],
          (k['segments'] as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .firstWhere((Map<String, dynamic> s) => s['on'] == true)['label'],
        ],
      );

      final Map<String, dynamic> sm = k['summary'] as Map<String, dynamic>;
      final LumeSummaryCard card = tester.widget<LumeSummaryCard>(
        find.byKey(LumeExpensesTool.summaryKey),
      );
      expect(
        <Object?>[
          card.kicker,
          card.value,
          card.caption,
          <List<String>>[
            for (final LumeStat s in card.stats) <String>[s.value, s.label],
          ],
          (card.aside! as LumeProgressRing).centreValue,
        ],
        <Object?>[
          sm['kicker'],
          sm['value'],
          sm['caption'],
          <List<String>>[
            for (final dynamic s in sm['stats'] as List<dynamic>)
              <String>[
                (s as Map<String, dynamic>)['value'] as String,
                s['label'] as String,
              ],
          ],
          (x['ring'] as Map<String, dynamic>)['mid'],
        ],
      );

      final LumeBarChart bars = tester.widget<LumeBarChart>(
        find.byKey(LumeExpensesTool.weekKey),
      );
      expect(bars.labels, <String>[
        for (final dynamic b in x['bars'] as List<dynamic>)
          (b as List<dynamic>)[0] as String,
      ]);
      expect(find.text(x['barsCaption'] as String), findsOneWidget);

      final Map<String, dynamic> dn = k['donut'] as Map<String, dynamic>;
      final LumeDonut donut = tester.widget<LumeDonut>(
        find.byKey(LumeExpensesTool.categoriesKey),
      );
      expect(
        <Object?>[
          donut.centre,
          donut.centreSub,
          <List<String?>>[
            for (final LumeDonutSlice s in donut.slices)
              <String?>[s.label, s.display],
          ],
        ],
        <Object?>[
          dn['mid'],
          dn['sub'],
          <List<String?>>[
            for (final dynamic s in dn['keys'] as List<dynamic>)
              <String?>[
                (s as Map<String, dynamic>)['label'] as String?,
                s['value'] as String?,
              ],
          ],
        ],
      );

      expect(
        <List<Object?>>[
          for (final LumeFilterChip c in tester.widgetList<LumeFilterChip>(
            find.byType(LumeFilterChip),
          ))
            <Object?>[c.label, c.selected, c.icon != null],
        ],
        <List<Object?>>[
          for (final dynamic c in x['filters'] as List<dynamic>)
            (c as List<dynamic>).cast<Object?>(),
        ],
      );
      final LumeSortBar sort = tester.widget<LumeSortBar>(
        find.byKey(LumeExpensesTool.sortKey),
      );
      expect(
        <Object?>[
          sort.label,
          <List<Object?>>[
            for (final LumeChoice c in sort.items)
              <Object?>[c.label, c.value == sort.value],
          ],
        ],
        <Object?>[
          x['sortLabel'],
          <List<Object?>>[
            for (final dynamic s in x['sorts'] as List<dynamic>)
              <Object?>[(s as List<dynamic>)[0], s[1]],
          ],
        ],
      );

      // The reference's `.rrow` list holds the transactions and then the
      // insights; they are two sections here as there.
      final List<Map<String, dynamic>> tx = (x['transactions'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((Map<String, dynamic> t) => t['value'] != null)
          .toList();
      final Map<String, dynamic>? empty = k['state'] as Map<String, dynamic>?;
      if (empty == null) {
        expect(
          <List<Object?>>[
            for (final LumeRichRow row in tester.widgetList<LumeRichRow>(
              inKey(LumeExpensesTool.transactionsKey, find.byType(LumeRichRow)),
            ))
              <Object?>[
                row.title,
                row.subtitle,
                sameDay(row.meta ?? const <String>[]),
                row.value,
                row.valueColor != null,
              ],
          ],
          <List<Object?>>[
            for (final Map<String, dynamic> t in tx)
              <Object?>[
                t['title'],
                t['sub'],
                sameDay(strings(t['meta'])),
                t['value'],
                t['income'],
              ],
          ],
        );
      } else {
        expect(tx, isEmpty);
        final LumeToolState st = tester.widget<LumeToolState>(
          find.descendant(
            of: find.byType(LumeToolFrame),
            matching: find.byType(LumeToolState),
          ),
        );
        expect(
          <Object?>[st.title, st.text, (st.action! as LumeButton).label],
          <Object?>[empty['title'], empty['text'], empty['action']],
        );
      }

      expect(
        <List<String>>[
          for (final LumeMeterRow m in tester.widgetList<LumeMeterRow>(
            find.byType(LumeMeterRow),
          ))
            <String>[m.label, m.value, '${(m.progress * 100).round()}'],
        ],
        <List<String>>[
          for (final dynamic m in x['meters'] as List<dynamic>)
            <String>[
              (m as List<dynamic>)[0] as String,
              m[1] as String,
              m[2] as String,
            ],
        ],
      );
      expect(
        <List<String?>>[
          for (final LumeCompactRow c in tester.widgetList<LumeCompactRow>(
            inKey(LumeExpensesTool.recurringKey, find.byType(LumeCompactRow)),
          ))
            <String?>[c.label, c.subtitle, c.value],
        ],
        <List<String?>>[
          for (final dynamic c in x['recurring'] as List<dynamic>)
            (c as List<dynamic>).cast<String?>(),
        ],
      );
      expect(
        <List<String?>>[
          for (final LumeRichRow row in tester.widgetList<LumeRichRow>(
            inKey(LumeExpensesTool.insightsKey, find.byType(LumeRichRow)),
          ))
            <String?>[row.title, row.subtitle],
        ],
        <List<String?>>[
          for (final Map<String, dynamic> t
              in (x['transactions'] as List<dynamic>)
                  .cast<Map<String, dynamic>>()
                  .where((Map<String, dynamic> t) => t['value'] == null))
            <String?>[t['title'] as String?, t['sub'] as String?],
        ],
      );
      expect(
        tester
            .widgetList<LumeButton>(
              inKey(LumeExpensesTool.actionsKey, find.byType(LumeButton)),
            )
            .map((LumeButton b) => b.label)
            .toList(),
        strings(k['buttons']),
      );
      expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
    }

    for (final String state in <String>[
      'default_pk',
      'default_us',
      'muslim_gb',
    ]) {
      testWidgets(state, (WidgetTester tester) async {
        await pumpExpenses(tester, state: state);
        await expectList(tester, 'tool_expenses_${state}_390x844_light_en');
      });
    }

    testWidgets('a search that finds nothing', (WidgetTester tester) async {
      await pumpExpenses(tester);
      await tester.enterText(find.byKey(LumeExpensesTool.searchKey), 'zzz');
      await tester.pumpAndSettle();
      await expectList(
        tester,
        'tool_expenses_default_pk_q-zzz_390x844_light_en',
      );
    });

    testWidgets('the Transport chip', (WidgetTester tester) async {
      await pumpExpenses(tester);
      await tapVisible(
        tester,
        inKey(LumeExpensesTool.chipsKey, find.text('Transport')),
      );
      await expectList(
        tester,
        'tool_expenses_default_pk_cfil-transport_390x844_light_en',
      );
    });

    testWidgets('the Transport category', (WidgetTester tester) async {
      await pumpExpenses(tester);
      await tapVisible(
        tester,
        inKey(LumeExpensesTool.filterKey, find.text('Transport')),
      );
      await expectList(
        tester,
        'tool_expenses_default_pk_cat-transport_390x844_light_en',
      );
    });

    void expectDetail(WidgetTester tester, String cell) {
      final Map<String, dynamic> k = composition(cell);
      final Map<String, dynamic> r = k['records'] as Map<String, dynamic>;
      if (!cell.contains('1100')) expectHeader(tester, k);
      final Map<String, dynamic> h = r['hero'] as Map<String, dynamic>;
      final LumeRecordHero hero = tester.widget<LumeRecordHero>(
        find.byKey(LumeExpensesTool.heroKey),
      );
      expect(
        <String?>[hero.kicker, hero.value, hero.title, hero.caption],
        <String?>[
          h['kicker'] as String?,
          h['value'] as String?,
          h['title'] as String?,
          h['caption'] as String?,
        ],
      );
      expect(
        <List<String>>[
          for (final LumeFact f
              in tester
                  .widget<LumeFactCard>(
                    inKey(LumeExpensesTool.factsKey, find.byType(LumeFactCard)),
                  )
                  .facts)
            <String>[f.label, f.value],
        ],
        <List<String>>[
          for (final dynamic f in r['facts'] as List<dynamic>)
            <String>[(f as List<dynamic>)[0] as String, f[1] as String],
        ],
      );
      final LumeDetailActions acts = tester.widget<LumeDetailActions>(
        find.byKey(LumeExpensesTool.detailActionsKey),
      );
      expect(<String?>[
        acts.editLabel,
        acts.deleteLabel,
      ], strings(r['actions']));
      // The reference's ids are random; these are counted (C74).
      expect(
        tester
            .widget<LumeRecordIdLabel>(find.byKey(LumeExpensesTool.recordIdKey))
            .label,
        startsWith('Record ID EXP-'),
      );
      expect(find.text('Details'), findsOneWidget);
    }

    testWidgets('a record opened', (WidgetTester tester) async {
      await pumpExpenses(tester);
      await openFirstRecord(tester);
      expectDetail(tester, 'tool_expenses_default_pk_detail_390x844_light_en');
      expect(find.byType(LumeSourceBar), findsNothing);
      expect(find.byType(LumeRelatedTools), findsNothing);
    });

    testWidgets('a record opened beside the list', (WidgetTester tester) async {
      await pumpExpenses(tester, surface: const Size(1050, 5000));
      expect(find.text('Nothing selected'), findsOneWidget);
      expect(
        find.text('Choose one from the list to see it here.'),
        findsOneWidget,
      );
      await openFirstRecord(tester);
      expectDetail(tester, 'tool_expenses_default_pk_detail_1100x900_light_en');
      expect(
        tester.widget<LumeRecordRow>(find.byType(LumeRecordRow).first).selected,
        isTrue,
      );
      expect(find.byType(LumeRecordRow), findsNWidgets(5));
    });

    void expectForm(WidgetTester tester, String cell) {
      final Map<String, dynamic> k = composition(cell);
      final Map<String, dynamic> r = k['records'] as Map<String, dynamic>;
      if (!cell.contains('1100')) expectHeader(tester, k);
      final List<Map<String, dynamic>> fields = (r['fields'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      const List<String> names = <String>[
        'title',
        'amount',
        'cat',
        'date',
        'method',
        'notes',
        'receipt',
      ];
      expect(
        fields.map((Map<String, dynamic> f) => f['label']).toList(),
        <String>[
          'Title',
          'Amount',
          'Category',
          'Date',
          'Payment',
          'Notes',
          'Receipt',
        ],
      );
      for (int i = 0; i < names.length; i++) {
        final Map<String, dynamic> want = fields[i];
        final Finder at = find.byKey(LumeExpensesTool.fieldKey(names[i]));
        final Widget w = tester.widget(at);
        switch (w) {
          case LumeFormField():
            expect(
              <Object?>[
                w.label,
                w.optionalLabel,
                w.placeholder,
                w.controller!.text,
                w.error == null ? null : '!${w.error}',
              ],
              <Object?>[
                want['label'],
                want['optional'],
                want['placeholder'],
                want['value'],
                want['error'],
              ],
              reason: names[i],
            );
          case LumeFormPicker():
            final Map<String, String> shown = <String, String>{
              'groceries': 'Groceries',
              'cash': 'Cash',
              'card': 'Card',
              '2026-09-07': 'Mon, 7 Sept',
            };
            expect(
              <Object?>[w.label, w.value],
              <Object?>[want['label'], shown[want['value']]],
              reason: names[i],
            );
          case LumeAttachTile():
            expect(
              <Object?>[w.fieldLabel, w.optionalLabel, w.label],
              <Object?>[want['label'], want['optional'], want['attach']],
            );
          default:
            fail('${names[i]} is a ${w.runtimeType}');
        }
      }
      final List<String> submit = strings(r['submit']);
      expect(find.text(submit.first), findsOneWidget);
      if (r['submitNote'] != null) {
        expect(find.text(r['submitNote'] as String), findsOneWidget);
      }
      if (submit.length > 1) {
        expect(
          inKey(LumeExpensesTool.submitKey, find.text(submit[1])),
          findsOneWidget,
        );
      }
    }

    testWidgets('a new expense', (WidgetTester tester) async {
      await pumpExpenses(tester);
      await openForm(tester);
      expectForm(tester, 'tool_expenses_default_pk_new_390x844_light_en');
    });

    testWidgets('a new expense at expanded width', (WidgetTester tester) async {
      await pumpExpenses(tester, surface: const Size(1050, 5000));
      await openForm(tester);
      expectForm(tester, 'tool_expenses_default_pk_new_1100x900_light_en');
      expect(find.text('Expense information'), findsOneWidget);
      // Side by side, not the reference's Save over its Cancel (C74).
      final Rect save = tester.getRect(
        inKey(LumeExpensesTool.submitKey, find.byType(LumeButton)).first,
      );
      final Rect cancel = tester.getRect(
        inKey(LumeExpensesTool.submitKey, find.byType(LumeButton)).last,
      );
      expect(cancel.top, save.top);
      expect(cancel.left, greaterThanOrEqualTo(save.right));
    });

    testWidgets('saved with nothing in it', (WidgetTester tester) async {
      await pumpExpenses(tester);
      await openForm(tester);
      await tester.tap(toolbarAction('Save'));
      await tester.pumpAndSettle();
      expectForm(tester, 'tool_expenses_default_pk_invalid_390x844_light_en');
      await dismissToast(tester);
    });

    testWidgets('a record being edited', (WidgetTester tester) async {
      await pumpExpenses(tester);
      await openFirstRecord(tester);
      await tester.tap(toolbarAction('Edit expense'));
      await tester.pumpAndSettle();
      expectForm(tester, 'tool_expenses_default_pk_edit_390x844_light_en');
    });

    testWidgets('a record saved', (WidgetTester tester) async {
      await pumpExpenses(tester);
      await openForm(tester);
      await tester.enterText(
        find.byKey(LumeExpensesTool.fieldKey('title')),
        'Tea',
      );
      await tester.enterText(
        find.byKey(LumeExpensesTool.fieldKey('amount')),
        '4',
      );
      await tester.tap(toolbarAction('Save'));
      await settleSave(tester);
      expectDetail(tester, 'tool_expenses_default_pk_saved_390x844_light_en');
      await dismissToast(tester);
    });
  });

  group('used', () {
    testWidgets('a save can be undone, and the list says how many', (
      WidgetTester tester,
    ) async {
      await pumpExpenses(tester, surface: const Size(390, 900));
      await openForm(tester);
      await tester.enterText(
        find.byKey(LumeExpensesTool.fieldKey('title')),
        'Tea',
      );
      await tester.enterText(
        find.byKey(LumeExpensesTool.fieldKey('amount')),
        '4',
      );
      await tester.tap(toolbarAction('Save'));
      await settleSave(tester);
      expect(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text('Expense added'),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text('Undo'),
        ),
      );
      await tester.pumpAndSettle();
      expect(recordTitles(tester), isNot(contains('Tea')));
      expect(
        tester.widget<LumeToolbar>(find.byType(LumeToolbar)).subtitle,
        '5 records',
      );
      await dismissToast(tester);
    });

    testWidgets('a delete asks first, and can be undone', (
      WidgetTester tester,
    ) async {
      await pumpExpenses(tester, surface: const Size(390, 900));
      await openFirstRecord(tester);
      await tapVisible(
        tester,
        inKey(LumeExpensesTool.detailActionsKey, find.text('Delete expense')),
      );
      final LumeDeleteConfirmation sheet = tester.widget(
        find.byType(LumeDeleteConfirmation),
      );
      expect(
        <Object?>[
          sheet.title,
          sheet.consequence,
          sheet.confirmLabel,
          sheet.cancelLabel,
          sheet.warn,
        ],
        <Object?>[
          'Delete this expense?',
          'Groceries will be removed. You can undo this straight away.',
          'Delete expense',
          'Cancel',
          false,
        ],
      );
      await tester.tap(
        find.descendant(
          of: find.byType(LumeDeleteConfirmation),
          matching: find.text('Delete expense'),
        ),
      );
      await tester.pumpAndSettle();
      expect(recordTitles(tester), isNot(contains('Groceries')));
      expect(
        tester.widget<LumeToolbar>(find.byType(LumeToolbar)).subtitle,
        '4 records',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text('Undo'),
        ),
      );
      await tester.pumpAndSettle();
      expect(recordTitles(tester).first, 'Groceries');
      await dismissToast(tester);
    });

    testWidgets('Cancel on the sheet deletes nothing', (
      WidgetTester tester,
    ) async {
      await pumpExpenses(tester, surface: const Size(390, 900));
      await openFirstRecord(tester);
      await tapVisible(
        tester,
        inKey(LumeExpensesTool.detailActionsKey, find.text('Delete expense')),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(LumeDeleteConfirmation),
          matching: find.text('Cancel'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(LumeExpensesTool.heroKey), findsOneWidget);
    });

    testWidgets('leaving a changed form asks, in amber', (
      WidgetTester tester,
    ) async {
      await pumpExpenses(tester, surface: const Size(390, 900));
      await openForm(tester);
      await tester.enterText(
        find.byKey(LumeExpensesTool.fieldKey('title')),
        'Tea',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();
      final LumeDeleteConfirmation sheet = tester.widget(
        find.byType(LumeDeleteConfirmation),
      );
      expect(sheet.warn, isTrue);
      expect(sheet.title, 'Discard your changes?');
      await tester.tap(
        find.descendant(
          of: find.byType(LumeDeleteConfirmation),
          matching: find.text(sheet.cancelLabel),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(LumeExpensesTool.formKey), findsOneWidget);
      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(LumeDeleteConfirmation),
          matching: find.text(sheet.confirmLabel),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(LumeExpensesTool.recordsKey), findsOneWidget);
      expect(recordTitles(tester), isNot(contains('Tea')));
    });

    testWidgets('an unchanged form leaves without asking', (
      WidgetTester tester,
    ) async {
      await pumpExpenses(tester, surface: const Size(390, 900));
      await openForm(tester);
      await tester.tap(find.byType(LumeBackButton));
      await tester.pumpAndSettle();
      expect(find.byType(LumeDeleteConfirmation), findsNothing);
      expect(find.byKey(LumeExpensesTool.recordsKey), findsOneWidget);
    });

    testWidgets('the body’s Add expense opens the form (C74)', (
      WidgetTester tester,
    ) async {
      await pumpExpenses(tester);
      await tapVisible(
        tester,
        inKey(LumeExpensesTool.actionsKey, find.text('Add expense')),
      );
      expect(find.byKey(LumeExpensesTool.formKey), findsOneWidget);
    });

    testWidgets('a choice is made on a sheet', (WidgetTester tester) async {
      await pumpExpenses(tester, surface: const Size(390, 900));
      await openForm(tester);
      await tester.tap(find.byKey(LumeExpensesTool.fieldKey('method')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(LumeSheet),
          matching: find.text('Wallet'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LumeFormPicker>(
              find.byKey(LumeExpensesTool.fieldKey('method')),
            )
            .value,
        'Wallet',
      );
    });

    testWidgets('a receipt is not attached yet, and says so', (
      WidgetTester tester,
    ) async {
      await pumpExpenses(tester, surface: const Size(390, 900));
      await openForm(tester);
      await tapVisible(
        tester,
        find.byKey(LumeExpensesTool.fieldKey('receipt')),
      );
      expect(find.byType(LumeToast), findsOneWidget);
      await dismissToast(tester);
    });

    testWidgets('sorting by amount puts the salary first', (
      WidgetTester tester,
    ) async {
      await pumpExpenses(tester);
      await tapVisible(
        tester,
        inKey(LumeExpensesTool.sortKey, find.text('Amount')),
      );
      expect(
        tester
            .widget<LumeRichRow>(
              inKey(
                LumeExpensesTool.transactionsKey,
                find.byType(LumeRichRow),
              ).first,
            )
            .title,
        'Salary',
      );
    });

    testWidgets('Export writes the transactions, and Share is not offered', (
      WidgetTester tester,
    ) async {
      final LumeRecordingExporter exporter = LumeRecordingExporter();
      await pumpExpenses(
        tester,
        surface: const Size(390, 900),
        overrides: <Override>[exporterProvider.overrideWithValue(exporter)],
      );
      await tester.tap(toolbarAction('Export'));
      await tester.pump();
      final LumeExportFile file = exporter.exported.single;
      expect(file.fileName, 'lume-expenses-2026-09-07.csv');
      final List<String> lines = file.text.trim().split(RegExp(r'\r?\n'));
      expect(lines, hasLength(9));
      expect(lines.first, 'Date,Title,Category,Amount,PKR');
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('leaving keeps the search and the chip', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpExpenses(tester);
      await tapVisible(
        tester,
        inKey(LumeExpensesTool.chipsKey, find.text('Bills')),
      );
      router.go(LumeRoutes.tools);
      await tester.pumpAndSettle();
      router.go(kExpenses);
      await tester.pumpAndSettle();
      expect(recordTitles(tester), <String>['Internet bill']);
    });

    testWidgets('in Urdu the records read right to left', (
      WidgetTester tester,
    ) async {
      await pumpExpenses(tester, locale: const Locale('ur'));
      expect(
        Directionality.of(tester.element(find.byType(LumeToolFrame))),
        TextDirection.rtl,
      );
      expectNoOverflow(tester);
    });

    testWidgets('in Arabic, the form', (WidgetTester tester) async {
      await pumpExpenses(tester, locale: const Locale('ar'));
      await openForm(tester);
      expectNoOverflow(tester);
    });

    for (final String where in <String>['list', 'detail', 'form']) {
      testWidgets('at 200 %, the $where', (WidgetTester tester) async {
        await pumpExpenses(tester, textScale: 2);
        if (where == 'detail') await openFirstRecord(tester);
        if (where == 'form') await openForm(tester);
        expectNoOverflow(tester);
      });
    }
  });
}

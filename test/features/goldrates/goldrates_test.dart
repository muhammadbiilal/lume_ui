/// Currency & Gold, against the running reference, and used.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/localization/lume_numerals.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_share_card.dart';
import 'package:lume/core/widgets/lume/lume_spark.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/goldrates/data/goldrates_fixtures.dart';
import 'package:lume/features/goldrates/presentation/goldrates_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';
import '../tools/tool_parity.dart';

final String kGoldrates = LumeRoutes.tool(LumeRoutes.tools, 'goldrates');

Future<GoRouter> pumpGoldrates(
  WidgetTester tester, {
  String state = 'default_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  List<Override> overrides = const <Override>[],
}) async {
  final GoRouter router = await pumpLumeRouter(
    tester,
    initialLocation: kGoldrates,
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

Finder numerals(String text) =>
    find.byWidgetPredicate((Widget w) => w is LumeNumerals && w.text == text);

Finder toolbarAction(String label) => find.descendant(
  of: find.byType(LumeToolbar),
  matching: find.byWidgetPredicate(
    (Widget w) => w is LumeIconButton && w.label == label,
  ),
);

List<String> rowTitles(WidgetTester tester) => tester
    .widgetList<LumeRichRow>(find.byType(LumeRichRow))
    .map((LumeRichRow r) => r.title)
    .toList();

String glyph(LumeDelta d) => '${LumeDelta.glyphFor(d.direction)}${d.text}';

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('goldrates');
  tearDownAll(parity.write);

  const Key summary = LumeGoldratesTool.summaryKey;
  const Key table = LumeGoldratesTool.metalsKey;
  const Key list = LumeGoldratesTool.listKey;
  const Key weight = LumeGoldratesTool.weightKey;

  Finder head(String label) => find
      .ancestor(
        of: inKey(table, numerals(label)),
        matching: find.byType(Container),
      )
      .first;

  Map<String, Finder> elements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    'ctxbar': find.byType(LumeContextBar),
    'summary': find.byKey(summary),
    'summary.kicker': inKey(summary, find.text('GOLD 24K')),
    'summary.value': inKey(summary, numerals('Rs 290,480')),
    'summary.unit': inKey(summary, find.text('/ tola')),
    'summary.caption': find
        .ancestor(
          of: inKey(summary, find.byType(LumeDelta)),
          matching: find.byType(ConstrainedBox),
        )
        .first,
    'summary.delta': inKey(summary, find.byType(LumeDelta)),
    'summary.stat1': find
        .ancestor(
          of: inKey(summary, find.text('g')),
          matching: find.byType(Column),
        )
        .first,
    'summary.statv': inKey(summary, numerals('Rs 24,904')),
    'summary.statl': inKey(summary, find.text('g')),
    'table': find.byKey(table),
    'table.th1': head('METAL'),
    'table.th2': head('G'),
    'table.th3': head('TOLA'),
    'table.th4': head('CHANGE'),
    'table.td1': find
        .ancestor(
          of: inKey(table, numerals('Gold 24k')),
          matching: find.byType(Container),
        )
        .first,
    'table.delta': inKey(table, find.byType(LumeDelta)),
    'search': find.byKey(LumeGoldratesTool.searchKey),
    'rows': find.byKey(list),
    'rrow1': inKey(list, find.byType(LumeRichRow)).first,
    'rrow.logo': inKey(
      list,
      find.byWidgetPredicate(
        (Widget w) =>
            w is Container &&
            w.constraints ==
                const BoxConstraints.tightFor(width: 38, height: 38),
      ),
    ).first,
    'rrow.title': inKey(list, find.text('USD')),
    'rrow.sub': inKey(list, find.text('US Dollar')),
    'rrow.meta': inKey(list, find.byType(Wrap)).first,
    'rrow.spark': inKey(list, find.byType(LumeSparkline)).first,
    'rrow.end': find
        .ancestor(
          of: inKey(list, find.byType(LumeDelta)).first,
          matching: find.byType(Column),
        )
        .first,
    'rrow.value': inKey(list, numerals('283')),
    'rrow.delta': inKey(list, find.byType(LumeDelta)).first,
    'kard': find.ancestor(
      of: find.byKey(LumeGoldratesTool.chartKey),
      matching: find.byType(LumeCard),
    ),
    'chart.svg': inKey(
      LumeGoldratesTool.chartKey,
      find.byWidgetPredicate((Widget w) => w is SizedBox && w.height == 132),
    ),
    'chart.cap': inKey(
      LumeGoldratesTool.chartKey,
      find.text('Open market close, last 30 days'),
    ),
    'fgrid': find
        .ancestor(of: find.byKey(weight), matching: find.byType(Row))
        .first,
    'field1': find.byKey(weight),
    'field2': find.byKey(LumeGoldratesTool.worthKey),
    'field.box': inKey(weight, find.byType(AnimatedContainer)).first,
    'field.affix': inKey(weight, find.text('g')),
    'srcbar': find.byType(LumeSourceBar),
    'related': find.byType(LumeRelatedTools),
  };

  const Set<String> textBlocks = <String>{
    // `<p>` and `<span>`s the width of their box; Flutter's text is its own
    // width, so only position and height compare.
    'summary.kicker',
    'summary.value',
    'summary.caption',
    'summary.statv',
    'summary.statl',
    'rrow.sub',
    'rrow.meta',
    'chart.cap',
  };

  group('where everything is', () {
    for (final (String cell, Size size) in <(String, Size)>[
      ('tool_goldrates_default_pk_390x844_light_en', const Size(390, 5000)),
      ('tool_goldrates_default_pk_700x900_light_en', const Size(650, 5000)),
      ('tool_goldrates_default_pk_1100x900_light_en', const Size(1050, 5000)),
    ]) {
      testWidgets(cell, (WidgetTester tester) async {
        await pumpGoldrates(tester, surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          elements(),
          noWidth: textBlocks,
          // The pressable context item's widened target (C62), and what lies
          // far enough down for Chrome's fractional lines to add up (D20).
          drifting: <String>{
            'ctxbar',
            'kard',
            'chart.svg',
            'chart.cap',
            'fgrid',
            'field1',
            'field2',
            'field.box',
            'field.affix',
            'srcbar',
            'related',
          },
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }
  });

  group('what it says, in each state the reference was captured in', () {
    Future<void> expectWords(WidgetTester tester, String cell) async {
      final Map<String, dynamic> k =
          webToolCell(cell)!['composition'] as Map<String, dynamic>;
      final Map<String, dynamic> x = k['explorer'] as Map<String, dynamic>;

      expect(
        textsUnder(tester, find.byType(LumeContextBar)),
        (x['context'] as List<dynamic>).cast<String>(),
      );

      final Map<String, dynamic> s = x['summary'] as Map<String, dynamic>;
      final LumeSummaryCard card = tester.widget<LumeSummaryCard>(
        find.byKey(summary),
      );
      expect(
        <Object?>[
          card.kicker,
          card.value,
          card.unit,
          glyph(card.captionDelta!),
          <List<String>>[
            for (final LumeStat st in card.stats) <String>[st.value, st.label],
          ],
        ],
        <Object?>[
          s['kicker'],
          s['value'],
          s['unit'],
          s['caption'],
          <List<String>>[
            for (final dynamic st in s['stats'] as List<dynamic>)
              (st as List<dynamic>).cast<String>(),
          ],
        ],
      );

      final Map<String, dynamic> t = x['table'] as Map<String, dynamic>;
      final LumeTable metals = tester.widget<LumeTable>(find.byKey(table));
      expect(
        metals.columns.map((LumeColumn c) => c.label).toList(),
        (t['head'] as List<dynamic>).cast<String>(),
      );
      expect(metals.rows, <List<String>>[
        for (final dynamic r in t['rows'] as List<dynamic>)
          (r as List<dynamic>).cast<String>(),
      ]);

      expect(
        tester
            .widget<LumeSearchField>(find.byType(LumeSearchField))
            .placeholder,
        x['placeholder'],
      );

      expect(
        <List<Object?>>[
          for (final LumeRichRow r in tester.widgetList<LumeRichRow>(
            find.byType(LumeRichRow),
          ))
            <Object?>[
              r.logo,
              r.title,
              r.subtitle,
              r.meta,
              r.value,
              glyph(r.delta!),
              'spark spark--${(r.trailing! as LumeSparkline).trend!.name}',
            ],
        ],
        <List<Object?>>[
          for (final dynamic r in x['rows'] as List<dynamic>)
            <Object?>[
              (r as Map<String, dynamic>)['logo'],
              r['code'],
              r['name'],
              (r['meta'] as List<dynamic>).cast<String>(),
              r['value'],
              r['delta'],
              r['tone'],
            ],
        ],
      );

      final Map<String, dynamic>? empty = x['empty'] as Map<String, dynamic>?;
      if (empty == null) {
        expect(find.byKey(LumeGoldratesTool.emptyKey), findsNothing);
      } else {
        final LumeToolState st = tester.widget<LumeToolState>(
          find.byKey(LumeGoldratesTool.emptyKey),
        );
        expect(
          <String?>[st.title, st.text],
          <String?>[empty['title'] as String?, empty['text'] as String?],
        );
      }

      final Map<String, dynamic> c = x['chart'] as Map<String, dynamic>;
      final LumeLineChart chart = tester.widget<LumeLineChart>(
        find.byKey(LumeGoldratesTool.chartKey),
      );
      expect(
        <Object?>[chart.label, chart.labels, chart.caption],
        <Object?>[
          c['label'],
          (c['xlabels'] as List<dynamic>).cast<String>(),
          c['caption'],
        ],
      );

      final LumeToolField w = tester.widget<LumeToolField>(find.byKey(weight));
      final LumeToolField v = tester.widget<LumeToolField>(
        find.byKey(LumeGoldratesTool.worthKey),
      );
      expect(
        <List<String?>>[
          <String?>[w.label, w.controller!.text],
          <String?>[v.label, v.value],
        ],
        <List<String>>[
          for (final dynamic fld in x['fields'] as List<dynamic>)
            (fld as List<dynamic>).cast<String>(),
        ],
      );

      expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
      expect(
        find.text(((k['header'] as Map<String, dynamic>)['sub']) as String),
        findsOneWidget,
      );
    }

    for (final String state in <String>[
      'default_pk',
      'default_us',
      'muslim_gb',
      'default_ae',
      'default_jp',
    ]) {
      testWidgets(state, (WidgetTester tester) async {
        await pumpGoldrates(tester, state: state);
        await expectWords(tester, 'tool_goldrates_${state}_390x844_light_en');
      });
    }

    for (final String q in <String>['eur', 'zzz']) {
      testWidgets('searching "$q"', (WidgetTester tester) async {
        await pumpGoldrates(tester);
        await tester.enterText(
          inKey(LumeGoldratesTool.searchKey, find.byType(EditableText)),
          q,
        );
        await tester.pumpAndSettle();
        await expectWords(
          tester,
          'tool_goldrates_default_pk_q-${q}_390x844_light_en',
        );
      });
    }
  });

  group('used', () {
    testWidgets('the converter converts, and says nothing of a non-number '
        '(C72)', (WidgetTester tester) async {
      await pumpGoldrates(tester);
      final LumeMetals pk = LumeMetals.forCurrency('PKR');
      String worth() => tester
          .widget<LumeToolField>(find.byKey(LumeGoldratesTool.worthKey))
          .value!;
      expect(worth(), 'Rs 249,040');
      final Finder input = inKey(weight, find.byType(EditableText));
      await tester.ensureVisible(input);
      await tester.enterText(input, '11.664');
      await tester.pumpAndSettle();
      // A tola's weight of gold is worth what a tola costs.
      expect(pk.goldPerTola.round(), 290480);
      expect(worth(), 'Rs 290,480');
      await tester.enterText(input, '');
      await tester.pumpAndSettle();
      expect(worth(), '—');
    });

    testWidgets('a currency is found by its name, in Urdu or English', (
      WidgetTester tester,
    ) async {
      await pumpGoldrates(tester, locale: const Locale('ur'));
      final Finder field = inKey(
        LumeGoldratesTool.searchKey,
        find.byType(EditableText),
      );
      await tester.enterText(field, 'pound');
      await tester.pumpAndSettle();
      expect(rowTitles(tester), <String>['GBP']);
      await tester.enterText(field, 'یورو');
      await tester.pumpAndSettle();
      expect(rowTitles(tester), <String>['EUR']);
      expect(
        Directionality.of(tester.element(find.byType(LumeToolFrame))),
        TextDirection.rtl,
      );
    });

    testWidgets('the country opens Personalise', (WidgetTester tester) async {
      await pumpGoldrates(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(LumeContextBar),
          matching: find.text('Pakistan'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(LumeSheet), findsOneWidget);
    });

    testWidgets('the tool bar’s Search puts the cursor in the field', (
      WidgetTester tester,
    ) async {
      await pumpGoldrates(tester);
      await tester.tap(toolbarAction('Search this tool'));
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(
              inKey(LumeGoldratesTool.searchKey, find.byType(EditableText)),
            )
            .focusNode
            .hasFocus,
        isTrue,
      );
    });

    testWidgets('leaving keeps the query and the weight', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpGoldrates(tester);
      await tester.enterText(
        inKey(LumeGoldratesTool.searchKey, find.byType(EditableText)),
        'sar',
      );
      final Finder input = inKey(weight, find.byType(EditableText));
      await tester.ensureVisible(input);
      await tester.enterText(input, '5');
      await tester.pumpAndSettle();
      router.go(LumeRoutes.tools);
      await tester.pumpAndSettle();
      router.go(kGoldrates);
      await tester.pumpAndSettle();
      expect(rowTitles(tester), <String>['SAR']);
      expect(
        tester.widget<LumeToolField>(find.byKey(weight)).controller!.text,
        '5',
      );
    });

    testWidgets('the share card is the price the screen leads with', (
      WidgetTester tester,
    ) async {
      await pumpGoldrates(tester, surface: const Size(390, 900));
      await tester.tap(toolbarAction('Share'));
      await tester.pumpAndSettle();
      final LumeShareCard card = tester
          .widget<LumeShareCardArt>(find.byType(LumeShareCardArt))
          .card;
      expect(card.kind, LumeShareKind.quote);
      expect(card.text, 'Gold 24k: Rs 290,480 / tola');
      expect(card.source, startsWith('Open market · '));
    });

    testWidgets('the chart tells a screen reader where gold began and ended', (
      WidgetTester tester,
    ) async {
      await pumpGoldrates(tester);
      final List<double> h = LumeMetals.forCurrency('PKR').history;
      expect(h, hasLength(30));
      expect(
        tester
            .widget<LumeLineChart>(find.byKey(LumeGoldratesTool.chartKey))
            .summary,
        startsWith('From Rs '),
      );
    });

    testWidgets('at 200 %', (WidgetTester tester) async {
      await pumpGoldrates(tester, textScale: 2);
      expectNoOverflow(tester);
    });

    testWidgets('in Arabic, right to left, without overflow', (
      WidgetTester tester,
    ) async {
      await pumpGoldrates(tester, locale: const Locale('ar'));
      expectNoOverflow(tester);
      expect(
        Directionality.of(tester.element(find.byType(LumeToolFrame))),
        TextDirection.rtl,
      );
    });
  });
}

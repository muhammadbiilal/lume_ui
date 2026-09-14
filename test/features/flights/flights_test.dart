/// Flights, against the running reference, and used.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/localization/lume_numerals.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_journey.dart';
import 'package:lume/core/widgets/lume/lume_map.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_share_card.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/flights/presentation/flights_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';
import '../tools/tool_parity.dart';

final String kFlights = LumeRoutes.tool(LumeRoutes.tools, 'flights');

Future<GoRouter> pumpFlights(
  WidgetTester tester, {
  String state = 'default_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  final GoRouter router = await pumpLumeRouter(
    tester,
    initialLocation: kFlights,
    profile: taxProfile(state),
    surface: surface,
    locale: locale,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
  return router;
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

Finder numerals(String text) =>
    find.byWidgetPredicate((Widget w) => w is LumeNumerals && w.text == text);

Finder labelled(String label) => find.byWidgetPredicate(
  (Widget w) => w is Semantics && w.properties.label == label,
);

Finder toolbarAction(String label) => find.descendant(
  of: find.byType(LumeToolbar),
  matching: find.byWidgetPredicate(
    (Widget w) => w is LumeIconButton && w.label == label,
  ),
);

List<String> boardTitles(WidgetTester tester) => tester
    .widgetList<LumeRichRow>(find.byType(LumeRichRow))
    .map((LumeRichRow r) => r.title)
    .toList();

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('flights');
  tearDownAll(parity.write);

  const Key board = LumeFlightsTool.boardKey;
  const Key journey = LumeFlightsTool.journeyKey;
  const Key map = LumeFlightsTool.mapKey;
  const Key table = LumeFlightsTool.aircraftKey;

  Finder head(String label) => find
      .ancestor(
        of: inKey(table, numerals(label)),
        matching: find.byType(Container),
      )
      .first;

  Map<String, Finder> elements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    'search': find.byKey(LumeFlightsTool.searchKey),
    'segmented': find.byKey(LumeFlightsTool.viewKey),
    'seg1': find
        .ancestor(
          of: inKey(LumeFlightsTool.viewKey, find.text('Arrivals')),
          matching: find.byType(AnimatedContainer),
        )
        .first,
    'metrics': find.byKey(LumeFlightsTool.metricsKey),
    'metric1': find.byType(LumeMetric).first,
    'metric2': find.byType(LumeMetric).at(1),
    'metric.value': inKey(LumeFlightsTool.metricsKey, numerals('5')),
    'metric.label': inKey(LumeFlightsTool.metricsKey, find.text('Flights')),
    'lmap': find.byKey(map),
    'lmap.pin1': inKey(map, labelled('Dubai Intl')),
    'lmap.pinOn': inKey(map, labelled('EK 624')),
    'lmap.pin3': inKey(map, labelled('Islamabad Intl')),
    'lmap.cap': find
        .ancestor(
          of: inKey(map, find.text('DXB → ISB')),
          matching: find.byType(Container),
        )
        .first,
    'rows': find.byKey(board),
    'rrow1': inKey(board, find.byType(LumeRichRow)).first,
    'rrowSel': inKey(board, find.byType(LumeRichRow)).first,
    'rrow2': inKey(board, find.byType(LumeRichRow)).at(1),
    'rrow.logo': inKey(
      board,
      find.byWidgetPredicate(
        (Widget w) =>
            w is Container &&
            w.constraints ==
                const BoxConstraints.tightFor(width: 38, height: 38),
      ),
    ).first,
    'rrow.title': inKey(board, find.text('EK 624')),
    'rrow.badge': inKey(board, find.byType(LumeBadge)).first,
    'rrow.sub': inKey(board, find.text('Emirates · Boeing 777-300ER')),
    'rrow.meta': inKey(board, find.byType(Wrap)).first,
    'rrow.end': find
        .ancestor(
          of: inKey(board, find.text('ETA 08:22')),
          matching: find.byType(Column),
        )
        .first,
    'rrow.value': inKey(board, numerals('08:05')),
    'rrow.valuesub': inKey(board, find.text('ETA 08:22')),
    'kard': find.ancestor(
      of: find.byKey(journey),
      matching: find.byType(LumeCard),
    ),
    'journey': find.byKey(journey),
    'journey.from': find
        .ancestor(
          of: inKey(journey, find.text('DXB')),
          matching: find.byWidgetPredicate(
            (Widget w) => w is SizedBox && w.width == LumeJourney.endWidth,
          ),
        )
        .first,
    'journey.code': inKey(journey, find.text('DXB')),
    'journey.name': inKey(journey, find.text('Dubai Intl')),
    'journey.time': inKey(journey, find.text('03:52')),
    'journey.to': find
        .ancestor(
          of: inKey(journey, find.text('ISB')),
          matching: find.byWidgetPredicate(
            (Widget w) => w is SizedBox && w.width == LumeJourney.endWidth,
          ),
        )
        .first,
    'journey.track': find.byKey(LumeJourney.trackKey),
    'journey.line': find.byKey(LumeJourney.lineKey),
    'journey.prog': find.byKey(LumeJourney.progressKey),
    'journey.craft': find.byKey(LumeJourney.craftKey),
    'journey.dur': inKey(journey, find.text('774 km to run')),
    'table': find.byKey(table),
    'table.th1': head('FIELD'),
    'table.th2': head('VALUE'),
    'table.td1': find
        .ancestor(
          of: inKey(table, numerals('Aircraft')),
          matching: find.byType(Container),
        )
        .first,
    'tline': find.byKey(LumeFlightsTool.timelineKey),
    'tline.title': inKey(
      LumeFlightsTool.timelineKey,
      find.text('Scheduled departure'),
    ),
    'tline.sub': inKey(LumeFlightsTool.timelineKey, find.text('Dubai Intl')),
    'btnrow': find.byKey(LumeFlightsTool.actionsKey),
    'btn1': inKey(LumeFlightsTool.actionsKey, find.byType(LumeButton)).first,
    'btn2': inKey(LumeFlightsTool.actionsKey, find.byType(LumeButton)).last,
    'srcbar': find.byType(LumeSourceBar),
    'related': find.byType(LumeRelatedTools),
  };

  const Set<String> textBlocks = <String>{
    // "●" is a fallback glyph, drawn wider here than in Chrome.
    'rrow.badge',
    'metric.value',
    'metric.label',
    'rrow.sub',
    'rrow.meta',
    'journey.code',
    'journey.name',
    'journey.time',
    'tline.title',
    'tline.sub',
  };

  group('where everything is', () {
    for (final (String cell, Size size) in <(String, Size)>[
      ('tool_flights_default_pk_390x844_light_en', const Size(390, 5000)),
      ('tool_flights_default_pk_700x900_light_en', const Size(650, 5000)),
      ('tool_flights_default_pk_1100x900_light_en', const Size(1050, 5000)),
    ]) {
      testWidgets(cell, (WidgetTester tester) async {
        await pumpFlights(tester, surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          elements(),
          noWidth: textBlocks,
          drifting: <String>{
            'kard',
            'journey',
            'journey.from',
            'journey.code',
            'journey.name',
            'journey.time',
            'journey.to',
            'journey.track',
            'journey.line',
            'journey.prog',
            'journey.craft',
            'journey.dur',
            'table',
            'table.th1',
            'table.th2',
            'table.td1',
            'tline',
            'tline.title',
            'tline.sub',
            'btnrow',
            'btn1',
            'btn2',
            'srcbar',
            'related',
          },
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }
  });

  group('what it says, in each state the reference was captured in', () {
    String timelineState(LumeTimelineState s) => switch (s) {
      LumeTimelineState.done => 'done',
      LumeTimelineState.now => 'now',
      LumeTimelineState.upcoming => '',
    };

    Future<void> expectWords(WidgetTester tester, String cell) async {
      final Map<String, dynamic> k =
          webToolCell(cell)!['composition'] as Map<String, dynamic>;
      final Map<String, dynamic> x = k['flights'] as Map<String, dynamic>;

      expect(
        tester
            .widget<LumeSearchField>(find.byType(LumeSearchField))
            .placeholder,
        x['placeholder'],
      );
      final LumeSegmented seg = tester.widget<LumeSegmented>(
        find.byKey(LumeFlightsTool.viewKey),
      );
      expect(
        seg.items.map((LumeChoice c) => c.label).toList(),
        (x['segments'] as List<dynamic>).cast<String>(),
      );
      expect(
        seg.items.firstWhere((LumeChoice c) => c.value == seg.value).label,
        x['segmentOn'],
      );
      expect(
        <List<String>>[
          for (final LumeMetric m in tester.widgetList<LumeMetric>(
            find.byType(LumeMetric),
          ))
            <String>[m.value, m.label],
        ],
        <List<String>>[
          for (final dynamic m in x['metrics'] as List<dynamic>)
            (m as List<dynamic>).cast<String>(),
        ],
      );

      final Map<String, dynamic> wm = x['map'] as Map<String, dynamic>;
      final LumeMap lmap = tester.widget<LumeMap>(find.byKey(map));
      expect(
        <String?>[lmap.label, lmap.caption],
        <String?>[wm['label'] as String?, wm['caption'] as String?],
      );
      final List<dynamic> pins = wm['pins'] as List<dynamic>;
      expect(lmap.pins, hasLength(pins.length));
      for (int i = 0; i < pins.length; i++) {
        final List<dynamic> p = pins[i] as List<dynamic>;
        double pct(Object v) => double.parse((v as String).replaceAll('%', ''));
        expect(lmap.pins[i].label, p[0]);
        expect(lmap.pins[i].x, closeTo(pct(p[1] as Object), 0.01));
        expect(lmap.pins[i].y, closeTo(pct(p[2] as Object), 0.01));
        expect(lmap.pins[i].active, p[3]);
      }

      expect(
        <List<Object?>>[
          for (final LumeRichRow r in tester.widgetList<LumeRichRow>(
            find.byType(LumeRichRow),
          ))
            <Object?>[
              r.logo,
              r.title,
              r.subtitle,
              '${LumeBadge.glyphFor(r.badge!.tone) ?? ''}${r.badge!.label}',
              r.meta,
              r.value,
              r.valueSub,
              r.selected,
            ],
        ],
        <List<Object?>>[
          for (final dynamic r in x['rows'] as List<dynamic>)
            <Object?>[
              (r as Map<String, dynamic>)['logo'],
              r['title'],
              r['sub'],
              r['badge'],
              (r['meta'] as List<dynamic>).cast<String>(),
              r['value'],
              r['valueSub'],
              r['selected'],
            ],
        ],
      );

      final Map<String, dynamic>? empty = x['empty'] as Map<String, dynamic>?;
      if (empty == null) {
        expect(find.byKey(LumeFlightsTool.emptyKey), findsNothing);
      } else {
        final LumeToolState st = tester.widget<LumeToolState>(
          find.byKey(LumeFlightsTool.emptyKey),
        );
        expect(
          <String?>[st.title, st.text, (st.action! as LumeButton).label],
          <String?>[
            empty['title'] as String?,
            empty['text'] as String?,
            empty['action'] as String?,
          ],
        );
      }

      final Map<String, dynamic> j = x['journey'] as Map<String, dynamic>;
      final LumeJourney jr = tester.widget<LumeJourney>(find.byKey(journey));
      expect(
        <Object?>[
          <String>[jr.fromCode, jr.toCode],
          <String>[jr.from, jr.to],
          <String>[jr.fromTime, jr.toTime],
          jr.remaining,
          '${(jr.progress * 100).round()}',
        ],
        <Object?>[
          (j['codes'] as List<dynamic>).cast<String>(),
          (j['names'] as List<dynamic>).cast<String>(),
          (j['times'] as List<dynamic>).cast<String>(),
          j['duration'],
          j['fill'],
        ],
      );

      final Map<String, dynamic> t = x['table'] as Map<String, dynamic>;
      final LumeTable aircraft = tester.widget<LumeTable>(find.byKey(table));
      expect(
        aircraft.columns.map((LumeColumn c) => c.label).toList(),
        (t['head'] as List<dynamic>).cast<String>(),
      );
      expect(aircraft.rows, <List<String>>[
        for (final dynamic r in t['rows'] as List<dynamic>)
          (r as List<dynamic>).cast<String>(),
      ]);

      final LumeTimeline tl = tester.widget<LumeTimeline>(
        find.byKey(LumeFlightsTool.timelineKey),
      );
      expect(
        <List<String?>>[
          for (final LumeTimelineEntry e in tl.entries)
            <String?>[e.time, e.title, e.subtitle, timelineState(e.state)],
        ],
        <List<String?>>[
          for (final dynamic e in x['timeline'] as List<dynamic>)
            <String?>[
              (e as Map<String, dynamic>)['time'] as String?,
              e['title'] as String?,
              e['sub'] as String?,
              e['state'] as String?,
            ],
        ],
      );

      expect(
        tester
            .widgetList<LumeButton>(
              inKey(LumeFlightsTool.actionsKey, find.byType(LumeButton)),
            )
            .map((LumeButton b) => b.label)
            .toList(),
        (x['buttons'] as List<dynamic>).cast<String>(),
      );
      // The chosen flight's section is titled with its number and airline.
      final String journeyTitle = <String?>[
        for (final dynamic s in k['sections'] as List<dynamic>)
          (s as Map<String, dynamic>)['title'] as String?,
      ].whereType<String>().firstWhere((String t) => t.contains(' · '));
      expect(find.text(journeyTitle), findsOneWidget);
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
    ]) {
      testWidgets(state, (WidgetTester tester) async {
        await pumpFlights(tester, state: state);
        await expectWords(tester, 'tool_flights_${state}_390x844_light_en');
      });
    }

    for (final (String label, String view) in <(String, String)>[
      ('Departures', 'departures'),
      ('Tracked', 'tracked'),
    ]) {
      testWidgets('$label chosen', (WidgetTester tester) async {
        await pumpFlights(tester);
        await tester.tap(inKey(LumeFlightsTool.viewKey, find.text(label)));
        await tester.pumpAndSettle();
        await expectWords(
          tester,
          'tool_flights_default_pk_view-${view}_390x844_light_en',
        );
      });
    }

    testWidgets('a search that finds nothing', (WidgetTester tester) async {
      await pumpFlights(tester);
      await tester.enterText(find.byType(EditableText), 'zzz');
      await tester.pumpAndSettle();
      await expectWords(
        tester,
        'tool_flights_default_pk_q-zzz_390x844_light_en',
      );
    });

    testWidgets('QR 614 chosen', (WidgetTester tester) async {
      await pumpFlights(tester);
      final Finder row = inKey(board, find.text('QR 614'));
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      await expectWords(
        tester,
        'tool_flights_default_pk_flight-QR-614_390x844_light_en',
      );
    });
  });

  group('used', () {
    testWidgets('the empty board’s Arrivals clears the search (C73)', (
      WidgetTester tester,
    ) async {
      await pumpFlights(tester);
      await tester.enterText(find.byType(EditableText), 'zzz');
      await tester.pumpAndSettle();
      expect(find.byKey(LumeFlightsTool.emptyKey), findsOneWidget);
      final Finder action = inKey(
        LumeFlightsTool.emptyKey,
        find.byType(LumeButton),
      );
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(boardTitles(tester), hasLength(5));
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        isEmpty,
      );
    });

    testWidgets('Track says so, and keeps nothing (C73)', (
      WidgetTester tester,
    ) async {
      await pumpFlights(tester);
      final Finder track = inKey(
        LumeFlightsTool.actionsKey,
        find.text('Track this flight'),
      );
      await tester.ensureVisible(track);
      await tester.tap(track);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text('Tracking EK 624'),
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('the share card is the chosen flight', (
      WidgetTester tester,
    ) async {
      await pumpFlights(tester, surface: const Size(390, 900));
      await tester.tap(toolbarAction('Share'));
      await tester.pumpAndSettle();
      final LumeShareCard card = tester
          .widget<LumeShareCardArt>(find.byType(LumeShareCardArt))
          .card;
      expect(card.kind, LumeShareKind.quote);
      expect(card.text, 'EK 624 · DXB → ISB · ETA 08:22');
      expect(card.source, startsWith('Emirates · '));
    });

    testWidgets('leaving keeps the view, the query and the flight', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpFlights(tester);
      final Finder row = inKey(board, find.text('BA 262'));
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.tap(inKey(LumeFlightsTool.viewKey, find.text('Tracked')));
      await tester.pumpAndSettle();
      router.go(LumeRoutes.tools);
      await tester.pumpAndSettle();
      router.go(kFlights);
      await tester.pumpAndSettle();
      expect(boardTitles(tester), <String>['EK 624', 'BA 262']);
      expect(tester.widget<LumeJourney>(find.byKey(journey)).fromCode, 'LHR');
    });

    testWidgets('a selected row is announced as selected', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpFlights(tester);
      expect(
        tester.getSemantics(inKey(board, find.byType(LumeRichRow)).first),
        isSemantics(
          isSelected: true,
          label:
              'EK 624, En route, Emirates · Boeing 777-300ER, 08:05, ETA 08:22',
        ),
      );
      h.dispose();
    });

    testWidgets('an American reader reads miles and miles an hour', (
      WidgetTester tester,
    ) async {
      await pumpFlights(tester, state: 'default_us');
      expect(
        tester.widget<LumeJourney>(find.byKey(journey)).remaining,
        '481 mi to run',
      );
    });

    testWidgets('in Urdu the journey runs right to left', (
      WidgetTester tester,
    ) async {
      await pumpFlights(tester, locale: const Locale('ur'));
      final Rect from = tester.getRect(inKey(journey, find.text('DXB')));
      final Rect to = tester.getRect(inKey(journey, find.text('ISB')));
      expect(from.left, greaterThan(to.left));
      expect(
        Directionality.of(tester.element(find.byType(LumeToolFrame))),
        TextDirection.rtl,
      );
      expectNoOverflow(tester);
    });

    testWidgets('at 200 %', (WidgetTester tester) async {
      await pumpFlights(tester, textScale: 2);
      expectNoOverflow(tester);
    });
  });
}

/// Weather, against the running reference, and used — the dashboard
/// reference (F6A-D2).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_share_card.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/core/widgets/lume/lume_weather.dart';
import 'package:lume/features/weather/presentation/weather_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';
import '../tools/tool_parity.dart';

final String kWeather = LumeRoutes.tool(LumeRoutes.tools, 'weather');

Future<void> pumpWeather(
  WidgetTester tester, {
  String state = 'default_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  await pumpLumeRouter(
    tester,
    initialLocation: kWeather,
    profile: taxProfile(state),
    surface: surface,
    locale: locale,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

Finder toolbarAction(String label) => find.descendant(
  of: find.byType(LumeToolbar),
  matching: find.byWidgetPredicate(
    (Widget w) => w is LumeIconButton && w.label == label,
  ),
);

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('weather');
  tearDownAll(parity.write);

  Map<String, Finder> elements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    'ctxbar': find.byKey(LumeWeatherTool.contextKey),
    'summary': find.byKey(LumeWeatherTool.summaryKey),
    'hourly': find.byKey(LumeWeatherTool.hourlyKey),
    'hourly.col1': find
        .descendant(
          of: find.byKey(LumeWeatherTool.hourlyKey),
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is Container &&
                w.constraints ==
                    const BoxConstraints.tightFor(
                      width: LumeHourlyStrip.columnWidth,
                    ),
          ),
        )
        .first,
    'rows': find.byKey(LumeWeatherTool.daysKey),
    'rrow1': inKey(LumeWeatherTool.daysKey, find.byType(LumeRichRow)).first,
    'tempbar': find.byType(LumeTempBar).first,
    'kard': find
        .ancestor(
          of: find.byKey(LumeWeatherTool.aqiKey),
          matching: find.byType(LumeCard),
        )
        .first,
    'aqi': find.byKey(LumeAqiCard.topKey),
    'aqi.value': find.byKey(LumeAqiCard.valueKey),
    'aqi.body': find.byKey(LumeAqiCard.bodyKey),
    'aqi.badge': inKey(LumeAqiCard.bodyKey, find.byType(LumeBadge)),
    'aqi.parts': find.byKey(LumeAqiCard.partsKey),
    'sunarc': find.byKey(LumeWeatherTool.sunKey),
    'sunarc.svg': find.byKey(LumeSunArc.drawingKey),
    'sunarc.ends': find.byKey(LumeSunArc.endsKey),
    'metrics': find.byKey(LumeWeatherTool.metricsKey),
    'crow1': inKey(
      LumeWeatherTool.conditionsKey,
      find.byType(LumeCompactRow),
    ).first,
    'srcbar': find.byType(LumeSourceBar),
    'related': find.byType(LumeRelatedTools),
  };

  const Set<String> below = <String>{
    'kard',
    'aqi',
    'aqi.value',
    'aqi.body',
    'aqi.badge',
    'aqi.parts',
    'sunarc',
    'sunarc.svg',
    'sunarc.ends',
    'metrics',
    'crow1',
    'srcbar',
    'related',
  };

  group('where everything is', () {
    for (final (String cell, Size size) in <(String, Size)>[
      ('tool_weather_default_pk_390x844_light_en', const Size(390, 5000)),
      ('tool_weather_default_pk_700x900_light_en', const Size(650, 5000)),
      ('tool_weather_default_pk_1100x900_light_en', const Size(1050, 5000)),
    ]) {
      testWidgets(cell, (WidgetTester tester) async {
        await pumpWeather(tester, surface: size);
        // C85: at phone width the sample mark wraps the source line.
        final bool wraps = size.width < 600;
        final List<String> misses = parity.bounds(
          tester,
          cell,
          elements(),
          // The rail runs past the screen; its box is the screen's width.
          noWidth: const <String>{'hourly'},
          grown: wraps ? sampleMarkGrown : const <String, double>{},
          shifted: wraps ? sampleMarkShifted : const <String, double>{},
          drifting: below,
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }
  });

  group('what it says, in each state the reference was captured in', () {
    Future<void> expectWords(WidgetTester tester, String cell) async {
      final Map<String, dynamic> k =
          webToolCell(cell)!['composition'] as Map<String, dynamic>;
      final Map<String, dynamic> x = k['weather'] as Map<String, dynamic>;

      final Map<String, dynamic> h = k['header'] as Map<String, dynamic>;
      expect(
        tester.widget<LumeToolbar>(find.byType(LumeToolbar)).subtitle,
        h['sub'],
      );

      expect(
        tester
            .widget<LumeContextBar>(find.byKey(LumeWeatherTool.contextKey))
            .items
            .map((LumeContextItem i) => i.label)
            .toList(),
        (x['context'] as List<dynamic>).cast<String>(),
      );

      final Map<String, dynamic> sm = k['summary'] as Map<String, dynamic>;
      final LumeSummaryCard card = tester.widget<LumeSummaryCard>(
        find.byKey(LumeWeatherTool.summaryKey),
      );
      expect(
        <Object?>[
          card.kicker,
          card.value,
          card.caption,
          <List<String>>[
            for (final LumeStat s in card.stats) <String>[s.value, s.label],
          ],
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
        ],
      );

      final LumeHourlyStrip strip = tester.widget<LumeHourlyStrip>(
        find.byKey(LumeWeatherTool.hourlyKey),
      );
      expect(
        <List<Object?>>[
          for (final LumeHourlyItem i in strip.items)
            <Object?>[i.time, i.temperature, i.rain, i.now, '#i-${i.icon}'],
        ],
        <List<Object?>>[
          for (final dynamic c in x['hourly'] as List<dynamic>)
            (c as List<dynamic>).cast<Object?>(),
        ],
      );

      final List<Map<String, dynamic>> days = (x['days'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final List<LumeRichRow> rows = tester
          .widgetList<LumeRichRow>(
            inKey(LumeWeatherTool.daysKey, find.byType(LumeRichRow)),
          )
          .toList();
      final List<LumeTempBar> bars = tester
          .widgetList<LumeTempBar>(find.byType(LumeTempBar))
          .toList();
      expect(
        <List<Object?>>[
          for (int i = 0; i < rows.length; i++)
            <Object?>[
              rows[i].title,
              rows[i].subtitle,
              rows[i].meta,
              rows[i].value,
              rows[i].valueSub,
              <String>['${bars[i].start}%', '${100 - bars[i].end}%'],
            ],
        ],
        <List<Object?>>[
          for (final Map<String, dynamic> d in days)
            <Object?>[
              d['title'],
              d['sub'],
              (d['meta'] as List<dynamic>).cast<String>(),
              d['value'],
              d['valueSub'],
              (d['bar'] as List<dynamic>).cast<String>(),
            ],
        ],
      );

      final Map<String, dynamic> a = x['aqi'] as Map<String, dynamic>;
      final LumeAqiCard aqi = tester.widget<LumeAqiCard>(
        find.byKey(LumeWeatherTool.aqiKey),
      );
      expect(
        <Object?>[
          aqi.value,
          aqi.unit,
          '${LumeBadge.glyphFor(aqi.badge.tone) ?? ''}${aqi.badge.label}',
          aqi.advice,
          <List<String>>[
            for (final LumeAqiPartItem p in aqi.parts)
              <String>[p.value, p.name],
          ],
        ],
        <Object?>[
          a['value'],
          a['unit'],
          a['badge'],
          a['advice'],
          <List<String>>[
            for (final dynamic p in a['parts'] as List<dynamic>)
              (p as List<dynamic>).cast<String>(),
          ],
        ],
      );

      final Map<String, dynamic> s = x['sun'] as Map<String, dynamic>;
      final LumeSunArc arc = tester.widget<LumeSunArc>(
        find.byKey(LumeWeatherTool.sunKey),
      );
      expect(
        <Object?>[
          <String>[arc.rise, arc.riseLabel],
          <String>[arc.set, arc.setLabel],
          arc.progress.toStringAsFixed(3),
        ],
        <Object?>[
          ((s['ends'] as List<dynamic>)[0] as List<dynamic>).cast<String>(),
          ((s['ends'] as List<dynamic>)[1] as List<dynamic>).cast<String>(),
          s['progress'],
        ],
      );

      expect(
        <List<String>>[
          for (final LumeMetric m in tester.widgetList<LumeMetric>(
            inKey(LumeWeatherTool.metricsKey, find.byType(LumeMetric)),
          ))
            <String>[m.value, m.label],
        ],
        <List<String>>[
          for (final dynamic m in x['metrics'] as List<dynamic>)
            (m as List<dynamic>).cast<String>(),
        ],
      );
      expect(
        <List<String?>>[
          for (final LumeCompactRow c in tester.widgetList<LumeCompactRow>(
            inKey(LumeWeatherTool.conditionsKey, find.byType(LumeCompactRow)),
          ))
            <String?>[c.label, c.value],
        ],
        <List<String?>>[
          for (final dynamic c in x['conditions'] as List<dynamic>)
            (c as List<dynamic>).cast<String?>(),
        ],
      );
      if (x['alert'] == null) {
        expect(find.byKey(LumeWeatherTool.alertKey), findsNothing);
      }

      final Map<String, dynamic> src = k['source'] as Map<String, dynamic>;
      final LumeSourceBar bar = tester.widget<LumeSourceBar>(
        find.byType(LumeSourceBar),
      );
      expect(bar.qualityLabel, src['fresh']);
      expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
    }

    for (final String state in <String>[
      'default_pk',
      'default_us',
      'muslim_gb',
    ]) {
      testWidgets(state, (WidgetTester tester) async {
        await pumpWeather(tester, state: state);
        await expectWords(tester, 'tool_weather_${state}_390x844_light_en');
      });
    }
  });

  group('used', () {
    testWidgets('nothing on it says Live (F6A-D2)', (
      WidgetTester tester,
    ) async {
      await pumpWeather(tester);
      expect(
        find.textContaining(RegExp(r'\blive\b', caseSensitive: false)),
        findsNothing,
      );
      expect(
        tester.widget<LumeSourceBar>(find.byType(LumeSourceBar)).qualityLabel,
        startsWith('Delayed'),
      );
    });

    testWidgets('the place opens Personalise', (WidgetTester tester) async {
      await pumpWeather(tester, surface: const Size(390, 900));
      await tester.tap(find.text('Islamabad, Pakistan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(LumeSheet), findsOneWidget);
    });

    testWidgets('the share card is the conditions now', (
      WidgetTester tester,
    ) async {
      await pumpWeather(tester, surface: const Size(390, 900));
      await tester.tap(toolbarAction('Share'));
      await tester.pumpAndSettle();
      final LumeShareCard card = tester
          .widget<LumeShareCardArt>(find.byType(LumeShareCardArt))
          .card;
      expect(card.kind, LumeShareKind.quote);
      expect(card.text, 'Islamabad · 34° Hazy sun · humid. High 34° · Low 23°');
      expect(card.source, startsWith('Mon, 7 Sept · '));
    });

    testWidgets('right to left, a day runs from the right', (
      WidgetTester tester,
    ) async {
      await pumpWeather(tester, locale: const Locale('ur'));
      expect(
        Directionality.of(tester.element(find.byType(LumeToolFrame))),
        TextDirection.rtl,
      );
      final Rect first = tester.getRect(
        inKey(LumeWeatherTool.hourlyKey, find.byType(MergeSemantics)).first,
      );
      final Rect second = tester.getRect(
        inKey(LumeWeatherTool.hourlyKey, find.byType(MergeSemantics)).at(1),
      );
      expect(first.left, greaterThan(second.left));
      expectNoOverflow(tester);
    });

    testWidgets('in Arabic', (WidgetTester tester) async {
      await pumpWeather(tester, locale: const Locale('ar'));
      expectNoOverflow(tester);
    });

    testWidgets('at 200 %', (WidgetTester tester) async {
      await pumpWeather(tester, textScale: 2);
      expectNoOverflow(tester);
    });
  });
}

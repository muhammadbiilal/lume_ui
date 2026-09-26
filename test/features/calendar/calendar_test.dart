/// Calendar, against the running reference, and used.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lume/core/time/lume_zone_labels.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/platform/lume_export.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/time/lume_hijri.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_month_grid.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/core/time/lume_solar.dart';
import 'package:lume/features/records/presentation/record_tool.dart';
import 'package:lume/features/calendar/presentation/calendar_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';
import '../tools/tool_parity.dart';

final String kCalendar = LumeRoutes.tool(LumeRoutes.tools, 'calendar');

Future<void> pumpCalendar(
  WidgetTester tester, {
  String state = 'default_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  List<Override> overrides = const <Override>[],
}) async {
  await pumpLumeRouter(
    tester,
    initialLocation: kCalendar,
    profile: taxProfile(state),
    surface: surface,
    locale: locale,
    textScale: textScale,
    overrides: overrides,
  );
  await tester.pumpAndSettle();
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

List<LumeTimelineEntry> agendaOf(WidgetTester tester) =>
    tester.widget<LumeTimeline>(find.byKey(LumeCalendarTool.agendaKey)).entries;

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('calendar');
  tearDownAll(parity.write);

  Map<String, Finder> elements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    'ctxbar': find.byType(LumeContextBar),
    'segmented': find.byKey(LumeCalendarTool.viewKey),
    'mgrid': find.byKey(LumeCalendarTool.gridKey),
    'mgrid.title': inKey(LumeCalendarTool.gridKey, find.text('September 2026')),
    // `.mgrid__head { padding-bottom: 4px }` -- the head with its padding.
    'mgrid.head1': find
        .ancestor(
          of: inKey(LumeCalendarTool.gridKey, find.text('M')),
          matching: find.byType(Padding),
        )
        .first,
    'mgrid.today': find.byKey(LumeMonthGrid.todayKey),
    // `.tline__time { width: 52px; text-align: end }` -- the gutter.
    'tline.time': find.ancestor(
      of: inKey(LumeCalendarTool.agendaKey, find.text('9:00 am')),
      matching: find.byWidgetPredicate(
        (Widget w) => w is SizedBox && w.width == 52,
      ),
    ),
    'tline.title': inKey(
      LumeCalendarTool.agendaKey,
      find.text('Morning standup'),
    ),
    'tline.sub': inKey(LumeCalendarTool.agendaKey, find.text('Team call')),
    'rows': find.byKey(LumeCalendarTool.holidaysKey),
    'crow1': inKey(
      LumeCalendarTool.holidaysKey,
      find.byType(LumeCompactRow),
    ).first,
    // `.crow__label` holds the kind in its `<i>` -- the label and the kind.
    'crow.label': find
        .ancestor(
          of: inKey(LumeCalendarTool.holidaysKey, find.text('Iqbal Day')),
          matching: find.byType(Column),
        )
        .first,
    'crow.value': inKey(LumeCalendarTool.holidaysKey, find.text('9 Nov')),
    'srcbar': find.byType(LumeSourceBar),
    'related': find.byType(LumeRelatedTools),
  };

  const Set<String> textBlocks = <String>{
    'mgrid.title',
    'mgrid.head1',
    'tline.time',
    'tline.title',
    'tline.sub',
    'crow.label',
    'crow.value',
  };

  group('where everything is', () {
    for (final (String cell, Size size) in <(String, Size)>[
      ('tool_calendar_default_pk_390x844_light_en', const Size(390, 5000)),
      ('tool_calendar_default_pk_700x900_light_en', const Size(650, 5000)),
      ('tool_calendar_default_pk_1100x900_light_en', const Size(1050, 5000)),
    ]) {
      testWidgets(cell, (WidgetTester tester) async {
        await pumpCalendar(tester, surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          elements(),
          noWidth: textBlocks,
          // `.tline__time` is content-height in a row aligned to the top; the
          // Flutter gutter stretches with the row so the rail beside it can
          // run its line down. Its x and width compare; the title and sub
          // beside it hold the vertical rhythm.
          noHeight: <String>{'tline.time'},
          // A 1.5-point rounding of the grid's fractional cells accumulates
          // down the rows; everything below the grid may carry it.
          drifting: <String>{
            'mgrid',
            'tline.time',
            'tline.title',
            'tline.sub',
            'rows',
            'crow1',
            'crow.label',
            'crow.value',
            'srcbar',
            'related',
          },
        );
        expect(misses, isEmpty, reason: misses.join('\n'));

        // `.fab { inset-inline-end: 22px }` — 51 by 50 over the page.
        final Rect fab = tester.getRect(find.byKey(LumeCalendarTool.addKey));
        expect(fab.size, const Size(51, 50));
        expect(
          tester.getRect(find.byType(LumeToolFrame)).right - fab.right,
          22,
        );
      });
    }
  });

  group('what it says, in each state the reference was captured in', () {
    Future<void> expectWords(
      WidgetTester tester,
      String cell, {
      bool chronological = false,
      bool holidaysAsWritten = true,
    }) async {
      final Map<String, dynamic> k =
          webToolCell(cell)!['composition'] as Map<String, dynamic>;
      final Map<String, dynamic> c = k['calendar'] as Map<String, dynamic>;

      // The zone is bidi-isolated; the isolates are invisible format
      // characters, and what is compared is the words the reader sees. The
      // reference writes the zone's identifier; Lume writes CLDR's name for
      // it (C89), so the reference's identifier is read through the same
      // label layer — a departure named, not a comparison loosened.
      expect(
        <String>[
          for (final String t in textsUnder(
            tester,
            find.byType(LumeContextBar),
          ))
            t.replaceAll(RegExp('[\u2068\u2069]'), ''),
        ],
        <String>[
          for (final String w in (c['context'] as List<dynamic>).cast<String>())
            w.contains('/') ? LumeZoneLabels.of(w, language: 'en').display : w,
        ],
      );
      final LumeSegmented seg = tester.widget<LumeSegmented>(
        find.byKey(LumeCalendarTool.viewKey),
      );
      expect(
        seg.items.map((LumeChoice x) => x.label),
        (c['segments'] as List<dynamic>).cast<String>(),
      );
      expect(
        seg.items.firstWhere((LumeChoice x) => x.value == seg.value).label,
        c['segmentOn'],
      );

      final LumeMonthGrid grid = tester.widget<LumeMonthGrid>(
        find.byKey(LumeCalendarTool.gridKey),
      );
      expect(grid.title + (grid.subtitle ?? ''), c['title']);
      expect(grid.heads, (c['heads'] as List<dynamic>).cast<String>());
      expect(grid.leading, c['empties']);
      final List<dynamic> days = c['days'] as List<dynamic>;
      expect(grid.days, hasLength(days.length));
      for (int i = 0; i < days.length; i++) {
        final List<dynamic> web = days[i] as List<dynamic>;
        final bool islamic = web.length == 3;
        expect(grid.days[i].label, web[0], reason: 'day ${i + 1}');
        expect(grid.days[i].today, web.last, reason: 'day ${i + 1}');
        if (!islamic) {
          expect(grid.days[i].sub, isNull);
        } else if (i < 7) {
          // Up to today the reference's subtraction is the true date.
          expect(grid.days[i].sub, web[1], reason: 'day ${i + 1}');
        }
      }

      final List<LumeTimelineEntry> agenda = agendaOf(tester);
      final List<List<String?>> webAgenda = <List<String?>>[
        for (final dynamic a in c['agenda'] as List<dynamic>)
          <String?>[
            (a as Map<String, dynamic>)['time'] as String?,
            a['title'] as String?,
            a['sub'] as String?,
          ],
      ];
      final List<List<String?>> ours = <List<String?>>[
        for (final LumeTimelineEntry e in agenda)
          <String?>[e.time, e.title, e.subtitle],
      ];
      if (chronological) {
        // The same entries, in time order rather than text order (C71).
        expect(ours.toSet(), webAgenda.toSet());
      } else {
        expect(ours, webAgenda);
      }

      final List<LumeCompactRow> holidays = tester
          .widgetList<LumeCompactRow>(
            inKey(LumeCalendarTool.holidaysKey, find.byType(LumeCompactRow)),
          )
          .toList();
      final List<dynamic> webHolidays = c['holidays'] as List<dynamic>;
      expect(holidays, hasLength(webHolidays.length));
      for (int i = 0; i < holidays.length; i++) {
        final Map<String, dynamic> w = webHolidays[i] as Map<String, dynamic>;
        expect(holidays[i].label, w['label']);
        expect(holidays[i].subtitle, w['sub']);
        if (holidaysAsWritten) expect(holidays[i].value, w['value']);
      }

      expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
    }

    testWidgets('Pakistan', (WidgetTester tester) async {
      await pumpCalendar(tester);
      await expectWords(tester, 'tool_calendar_default_pk_390x844_light_en');
    });

    testWidgets('the United States — its holidays in its own date order', (
      WidgetTester tester,
    ) async {
      await pumpCalendar(tester, state: 'default_us');
      await expectWords(
        tester,
        'tool_calendar_default_us_390x844_light_en',
        holidaysAsWritten: false,
      );
      // `tool-data.js` writes "28 Nov" in every language; Lume writes the
      // reader's month-and-day (C71).
      expect(
        tester
            .widgetList<LumeCompactRow>(find.byType(LumeCompactRow))
            .first
            .value,
        intl.DateFormat.MMMd('en').format(DateTime(2026, 11, 28)),
      );
    });

    testWidgets('a Muslim reader in Pakistan — Hijri days and Maghrib', (
      WidgetTester tester,
    ) async {
      await pumpCalendar(tester, state: 'muslim_pk');
      await expectWords(
        tester,
        'tool_calendar_muslim_pk_390x844_light_en',
        chronological: true,
      );
    });

    // The reference compares its machine's own clock (16:41 in Karachi when
    // it was captured) with London's prayer times, and so shows Maghrib to a
    // reader for whom it is 11:41. The next prayer is read on London's own
    // clock here (C88): at 11:41 it is Dhuhr, at 16:41 — the moment the
    // reference meant — Maghrib at 7:35 pm, as it shows.
    test('a Muslim reader in London — the next prayer on London\'s clock', () {
      String next(DateTime instant) {
        final LumeSolarTime t = LumeCalendarTool.nextPrayer(
          now: instant,
          country: 'GB',
          city: 'London',
          zone: LumeTimeZoneService.shared.zoneFor('Europe/London'),
        )!;
        return '${t.key} ${t.hour}:${t.minute.toString().padLeft(2, '0')}';
      }

      expect(next(DateTime.utc(2026, 9, 7, 10, 41)), startsWith('dhuhr 13:'));
      expect(next(DateTime.utc(2026, 9, 7, 15, 41)), 'maghrib 19:35');
      // A renamed identifier reads the same clock as its canonical zone.
      expect(
        LumeCalendarTool.nextPrayer(
          now: DateTime.utc(2026, 9, 7, 15, 41),
          country: 'GB',
          city: 'London',
          zone: LumeTimeZoneService.shared.zoneFor('Europe/Belfast'),
        )?.key,
        'maghrib',
      );
    });

    testWidgets('Week chosen — and the month stays', (
      WidgetTester tester,
    ) async {
      await pumpCalendar(tester);
      await tester.tap(inKey(LumeCalendarTool.viewKey, find.text('Week')));
      await tester.pumpAndSettle();
      await expectWords(
        tester,
        'tool_calendar_default_pk_view-week_390x844_light_en',
      );
    });
  });

  group('used', () {
    testWidgets('the agenda is in time order, prayer included (C71)', (
      WidgetTester tester,
    ) async {
      await pumpCalendar(tester, state: 'muslim_pk');
      expect(agendaOf(tester).map((LumeTimelineEntry e) => e.title), <String>[
        'Morning standup',
        'Design review',
        'Maghrib',
        'Groceries',
      ]);
    });

    testWidgets('each day carries its own Hijri date, turning over (C71)', (
      WidgetTester tester,
    ) async {
      await pumpCalendar(tester, state: 'muslim_pk');
      final LumeMonthGrid grid = tester.widget<LumeMonthGrid>(
        find.byKey(LumeCalendarTool.gridKey),
      );
      for (int d = 1; d <= grid.days.length; d++) {
        expect(
          grid.days[d - 1].sub,
          '${LumeHijriDate.of(DateTime(2026, 9, d)).day}',
        );
      }
      expect(
        grid.days.map((LumeMonthDay x) => int.parse(x.sub!)).contains(1),
        isTrue,
      );
    });

    testWidgets('a reader without the Islamic experience sees no Hijri', (
      WidgetTester tester,
    ) async {
      await pumpCalendar(tester);
      expect(find.textContaining('Rabi'), findsNothing);
      expect(
        agendaOf(tester).map((LumeTimelineEntry e) => e.title),
        isNot(contains('Maghrib')),
      );
    });

    testWidgets('Add is named, and opens a new event in Events — the '
        'reference only said "New event"', (WidgetTester tester) async {
      await pumpCalendar(tester, surface: const Size(390, 900));
      final SemanticsHandle h = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Add an event'), findsOneWidget);
      h.dispose();
      await tester.tap(find.byKey(LumeCalendarTool.addKey));
      await tester.pumpAndSettle();

      const LumeRecordKeys events = LumeRecordKeys('events');
      expect(find.byType(LumeCalendarTool), findsNothing);
      expect(find.byKey(events.form), findsOneWidget);
      expect(find.byKey(events.submit), findsOneWidget);
      expect(find.text('New event'), findsNothing);
    });

    testWidgets('today is announced as the chosen day', (
      WidgetTester tester,
    ) async {
      await pumpCalendar(tester);
      final SemanticsHandle h = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byKey(LumeMonthGrid.todayKey)),
        isSemantics(label: 'Monday, 7 September', isSelected: true),
      );
      h.dispose();
    });

    testWidgets('Export writes the reference’s record', (
      WidgetTester tester,
    ) async {
      final LumeRecordingExporter exporter = LumeRecordingExporter();
      await pumpCalendar(
        tester,
        surface: const Size(390, 900),
        overrides: <Override>[exporterProvider.overrideWithValue(exporter)],
      );
      await tester.tap(
        find.descendant(
          of: find.byType(LumeToolbar),
          matching: find.byWidgetPredicate(
            (Widget w) => w is LumeIconButton && w.label == 'Export',
          ),
        ),
      );
      await tester.pump();
      final LumeExportFile file = exporter.exported.single;
      expect(file.fileName, 'lume-calendar-2026-09-07.json');
      expect(jsonDecode(file.text), containsPair('tool', 'calendar'));
      expect(jsonDecode(file.text), containsPair('currency', 'PKR'));
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('right to left, the week reads from the right', (
      WidgetTester tester,
    ) async {
      await pumpCalendar(tester, locale: const Locale('ur'));
      expect(
        Directionality.of(tester.element(find.byType(LumeToolFrame))),
        TextDirection.rtl,
      );
      final Finder cells = inKey(
        LumeCalendarTool.gridKey,
        find.byType(AspectRatio),
      );
      expect(
        tester.getCenter(cells.at(0)).dx,
        greaterThan(tester.getCenter(cells.at(1)).dx),
      );
    });

    testWidgets('at 200 %', (WidgetTester tester) async {
      await pumpCalendar(tester, textScale: 2);
      expectNoOverflow(tester);
    });
  });
}

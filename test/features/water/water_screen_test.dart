/// Water on screen: the parity day's figures, logging a glass, today's
/// intake, the two states the reference cannot reach, and the two things
/// that are not drawn at all.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/water/presentation/water_tool.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import 'water_harness.dart';

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

void main() {
  setUpAll(loadLumeFonts);

  group('the parity day, from the four seeded drinks', () {
    testWidgets('1.3 L of a 2.0 L goal, 0.8 L left, 5 glasses, 4 logged', (
      WidgetTester t,
    ) async {
      await pumpWater(t);

      final LumeSummaryCard card = t.widget<LumeSummaryCard>(
        find.byKey(LumeWaterTool.summaryKey),
      );
      expect(card.kicker, 'Today');
      expect(card.value, '1.3 L');
      // Nothing has been chosen, so the caption says the goal is the default.
      expect(card.caption, 'of the default 2.0 L goal');
      expect(
        card.stats.map((LumeStat s) => '${s.value} ${s.label}').toList(),
        <String>['0.8 L Remaining', '5 Glasses', '4 Logged'],
      );
    });

    testWidgets('the ring is 63 %, half up, and says so in words', (
      WidgetTester t,
    ) async {
      await pumpWater(t);

      final LumeProgressRing ring = t.widget<LumeProgressRing>(
        find.byKey(LumeWaterTool.ringKey),
      );
      expect(ring.value, closeTo(0.625, 1e-12));
      // 62.5 rounded half up. Half to even would print 62.
      expect(ring.centreValue, '63%');
      expect(ring.valueText, '63%');
      expect(ring.label, 'Progress');
    });

    testWidgets('the ring is never the only indicator', (WidgetTester t) async {
      await pumpWater(t);
      // Everything the arc says is also a figure with a word beside it.
      final List<String> texts = waterTexts(
        t,
        find.byKey(LumeWaterTool.summaryKey),
      );
      expect(texts, containsAll(<String>['1.3 L', '0.8 L', 'Remaining', '5']));
    });

    testWidgets("today's intake lists the four, earliest first", (
      WidgetTester t,
    ) async {
      await pumpWater(t);

      expect(find.text('Today’s intake'), findsOneWidget);
      final List<String> texts = waterTexts(
        t,
        find.byKey(LumeWaterTool.timelineKey),
      );
      // time, amount, kind — in that order, four times over.
      expect(texts, <String>[
        '8:10 am',
        '250 ml',
        'Water',
        '10:30 am',
        '500 ml',
        'Water',
        '1:05 pm',
        '250 ml',
        'Tea',
        '3:40 pm',
        '250 ml',
        'Water',
      ]);
    });

    testWidgets('the two buttons carry the reference\'s two amounts', (
      WidgetTester t,
    ) async {
      await pumpWater(t);

      final LumeButton small = t.widget<LumeButton>(
        find.byKey(LumeWaterTool.addSmallKey),
      );
      final LumeButton large = t.widget<LumeButton>(
        find.byKey(LumeWaterTool.addLargeKey),
      );
      expect(small.label, '+ 250 ml');
      expect(large.label, '+ 500 ml');
      // What a screen reader hears is a sentence, not a loose number.
      expect(small.semanticLabel, 'Add 250 ml');
      expect(large.semanticLabel, 'Add 500 ml');
      expect(small.tone, LumeButtonTone.accent);
    });
  });

  group('logging a glass moves every figure', () {
    testWidgets('+ 250 ml writes a record and the summary follows', (
      WidgetTester t,
    ) async {
      final LumeMemoryRecordRepository store = waterStore();
      await pumpWater(t, store: store);

      await tapWater(t, find.byKey(LumeWaterTool.addSmallKey));

      expect(store.view('water').items.length, 5);
      final LumeSummaryCard card = t.widget<LumeSummaryCard>(
        find.byKey(LumeWaterTool.summaryKey),
      );
      expect(card.value, '1.5 L');
      expect(card.stats.map((LumeStat s) => s.value).toList(), <String>[
        '0.5 L',
        '6',
        '5',
      ]);
      final LumeProgressRing ring = t.widget<LumeProgressRing>(
        find.byKey(LumeWaterTool.ringKey),
      );
      expect(ring.centreValue, '75%');
      expect(find.text('250 ml logged'), findsOneWidget);
    });

    testWidgets('+ 500 ml, and the drink joins the timeline at the hour now', (
      WidgetTester t,
    ) async {
      final LumeMemoryRecordRepository store = waterStore();
      await pumpWater(t, store: store);

      await tapWater(t, find.byKey(LumeWaterTool.addLargeKey));

      expect(
        t.widget<LumeSummaryCard>(find.byKey(LumeWaterTool.summaryKey)).value,
        '1.8 L',
      );
      // The fixture instant is 16:41, after all four seeds.
      final List<String> texts = waterTexts(
        t,
        find.byKey(LumeWaterTool.timelineKey),
      );
      expect(texts.length, 15);
      expect(texts.sublist(12), <String>['4:41 pm', '500 ml', 'Water']);
      expect(find.text('500 ml logged'), findsOneWidget);
    });

    testWidgets('what is written is a whole record, day and all', (
      WidgetTester t,
    ) async {
      final LumeMemoryRecordRepository store = waterStore(seeded: false);
      await pumpWater(t, store: store);

      await tapWater(t, find.byKey(LumeWaterTool.addSmallKey));

      final Map<String, Object?> f = store.view('water').items.single.fields;
      expect(f['ml'], 250);
      expect(f['kind'], 'water');
      expect(f['at'], '16:41');
      expect(f['date'], '2026-09-07');
    });
  });

  group('a day with nothing on it', () {
    testWidgets('says so, and draws no ring over zeros', (
      WidgetTester t,
    ) async {
      await pumpWater(t, store: waterStore(seeded: false));

      expect(find.byKey(LumeWaterTool.nothingKey), findsOneWidget);
      expect(find.text('Nothing logged today'), findsOneWidget);
      expect(find.byKey(LumeWaterTool.summaryKey), findsNothing);
      expect(find.byKey(LumeWaterTool.ringKey), findsNothing);
      expect(find.byKey(LumeWaterTool.timelineKey), findsNothing);
    });

    testWidgets('the goal row and the two buttons are still there', (
      WidgetTester t,
    ) async {
      await pumpWater(t, store: waterStore(seeded: false));

      expect(find.byKey(LumeWaterTool.goalKey), findsOneWidget);
      expect(find.byKey(LumeWaterTool.goalEditKey), findsOneWidget);
      expect(find.byKey(LumeWaterTool.addSmallKey), findsOneWidget);
      expect(find.text('Default goal'), findsOneWidget);
    });

    testWidgets('logging from empty fills the first figure', (
      WidgetTester t,
    ) async {
      await pumpWater(t, store: waterStore(seeded: false));
      await tapWater(t, find.byKey(LumeWaterTool.addSmallKey));

      expect(find.byKey(LumeWaterTool.nothingKey), findsNothing);
      expect(
        t.widget<LumeSummaryCard>(find.byKey(LumeWaterTool.summaryKey)).value,
        '0.3 L',
      );
    });

    testWidgets('yesterday\'s drinks are not today\'s', (WidgetTester t) async {
      final LumeMemoryRecordRepository store = waterStore(seeded: false);
      store.create('water', <String, Object?>{
        'ml': 900,
        'kind': 'water',
        'at': '09:00',
        'date': '2026-09-06',
      });
      await pumpWater(t, store: store);

      expect(find.byKey(LumeWaterTool.nothingKey), findsOneWidget);
      // The record is still listed — it happened — it is just not today.
      expect(find.byKey(LumeWaterTool.summaryKey), findsNothing);
    });
  });

  group('a reader whose day cannot be worked out', () {
    testWidgets('the counted sections give way to the zone state', (
      WidgetTester t,
    ) async {
      await pumpWater(t, profile: waterReader(zone: 'Mars/Olympus_Mons'));

      expect(find.byKey(LumeWaterTool.dayUnknownKey), findsOneWidget);
      expect(find.byKey(LumeWaterTool.summaryKey), findsNothing);
      expect(find.byKey(LumeWaterTool.ringKey), findsNothing);
      expect(find.byKey(LumeWaterTool.timelineKey), findsNothing);
      expect(find.byKey(LumeWaterTool.nothingKey), findsNothing);
      expect(find.byKey(LumeWaterTool.addSmallKey), findsNothing);
      expect(find.byKey(LumeWaterTool.goalKey), findsNothing);
    });

    testWidgets('a zone that resolves draws the figures again', (
      WidgetTester t,
    ) async {
      await pumpWater(t, profile: waterReader(zone: 'Asia/Karachi'));
      expect(find.byKey(LumeWaterTool.dayUnknownKey), findsNothing);
      expect(find.byKey(LumeWaterTool.summaryKey), findsOneWidget);
    });
  });

  group('what is not drawn', () {
    testWidgets('no streak, and no seven-bar week', (WidgetTester t) async {
      await pumpWater(t);

      final List<String> texts = allTexts(t);
      // `streak: 6` — the literal, and the label it sat under.
      expect(texts, isNot(contains('6')));
      expect(texts.where((String s) => s.contains('streak')), isEmpty);
      expect(texts.where((String s) => s.contains('Streak')), isEmpty);
      // `week: [1800, 2100, 1650, 2000, 1900, 2200, 1250]`.
      for (final String bar in <String>[
        '1800',
        '2100',
        '1650',
        '1900',
        '2200',
        '1,800',
        '2,100',
      ]) {
        expect(texts, isNot(contains(bar)), reason: bar);
      }
      expect(find.text('This week'), findsNothing);
      // No chart of any kind is in the tree.
      expect(find.byType(CustomPaint), findsWidgets);
      expect(
        t
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .where(
              (CustomPaint p) =>
                  '${p.painter.runtimeType}'.toLowerCase().contains('bar'),
            ),
        isEmpty,
      );
    });

    testWidgets('nothing on the screen makes a claim about health', (
      WidgetTester t,
    ) async {
      await pumpWater(t);

      // Everything but the host's related rail, which names the catalogue's
      // own neighbouring tools — one of them is called Health Records, and
      // that is a tool's name, not a claim this screen makes.
      final List<String> related = waterTexts(t, find.byType(LumeRelatedTools));
      final String page = allTexts(
        t,
      ).where((String s) => !related.contains(s)).join(' | ').toLowerCase();
      for (final String claim in <String>[
        'dehydrat',
        'hydrated',
        'hydration',
        'healthy',
        'health',
        'should drink',
        'recommend',
        'doctor',
        'medical',
        'daily requirement',
        'you need',
        'too little',
        'not enough',
        'well done',
        'keep it up',
      ]) {
        expect(page.contains(claim), isFalse, reason: claim);
      }
    });
  });

  group('the goal row', () {
    testWidgets('marks the default until somebody chooses', (
      WidgetTester t,
    ) async {
      await pumpWater(t);

      final LumeRichRow row = t.widget<LumeRichRow>(
        inKey(LumeWaterTool.goalKey, find.byType(LumeRichRow)),
      );
      expect(row.title, 'Daily goal');
      expect(row.subtitle, 'Default goal');
      expect(row.value, '2.0 L');
    });
  });

  group("a drink's own record", () {
    testWidgets('the row says which day as well as the time', (
      WidgetTester t,
    ) async {
      await pumpWater(t);
      final List<LumeRecordRow> rows = t
          .widgetList<LumeRecordRow>(find.byType(LumeRecordRow))
          .toList();
      expect(rows.length, 4);
      expect(rows.first.title, 'Water');
      // The reference shows the bare stored `08:10`; with a day on the record
      // the row can say which day, and the clock is the reader's.
      expect(rows.first.subtitle, 'Today · 8:10 am');
      expect(rows.first.value, '250 ml');
      expect(rows.first.initial, 'W');
    });

    testWidgets('the detail states the amount and the day, which the '
        'reference does not', (WidgetTester t) async {
      await pumpWater(t);
      await tapWater(t, find.byType(LumeRecordRow).first);

      final LumeFactCard facts = t.widget<LumeFactCard>(
        find.descendant(
          of: find.byKey(LumeWaterTool.keys.facts),
          matching: find.byType(LumeFactCard),
        ),
      );
      expect(
        facts.facts.map((LumeFact f) => '${f.label}: ${f.value}').toList(),
        <String>[
          'Drink: Water',
          'Amount in ml: 250',
          // The reference prints `08:10` here and `8:10 am` on the timeline.
          'Time: 8:10 am',
          'Date: Mon, 7 Sept',
        ],
      );
    });
  });

  group('an imperial reader', () {
    testWidgets('sees fluid ounces, from the exact factor', (
      WidgetTester t,
    ) async {
      await pumpWater(t, state: 'default_us');

      final LumeSummaryCard card = t.widget<LumeSummaryCard>(
        find.byKey(LumeWaterTool.summaryKey),
      );
      // 1250 / 29.5735295625 = 42.27; 750 / … = 25.36.
      expect(card.value, '42 fl oz');
      expect(card.caption, 'of the default 68 fl oz goal');
      expect(card.stats.first.value, '25 fl oz');
      // The buttons still log 250 and 500 ml; only the label changes.
      expect(
        t.widget<LumeButton>(find.byKey(LumeWaterTool.addSmallKey)).label,
        '+ 8 fl oz',
      );
      expect(
        t.widget<LumeButton>(find.byKey(LumeWaterTool.addLargeKey)).label,
        '+ 17 fl oz',
      );
    });

    testWidgets('and what is stored is still millilitres', (
      WidgetTester t,
    ) async {
      final LumeMemoryRecordRepository store = waterStore(seeded: false);
      await pumpWater(t, state: 'default_us', store: store);
      await tapWater(t, find.byKey(LumeWaterTool.addSmallKey));

      expect(store.view('water').items.single['ml'], 250);
      // The reference's toast says "250 ml" to an imperial reader who pressed
      // a button labelled "+ 8 fl oz". This one agrees with the button.
      expect(find.text('8 fl oz logged'), findsOneWidget);
    });
  });

  group('every control is reachable', () {
    testWidgets('the add buttons and the goal editor carry their own labels', (
      WidgetTester t,
    ) async {
      final SemanticsHandle handle = t.ensureSemantics();
      await pumpWater(t);

      expect(find.bySemanticsLabel('Add 250 ml'), findsOneWidget);
      expect(find.bySemanticsLabel('Add 500 ml'), findsOneWidget);
      expect(find.bySemanticsLabel('Change goal'), findsOneWidget);
      // The ring announces what it is and what it reads.
      expect(find.bySemanticsLabel('Progress'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the goal field is a labelled text field', (
      WidgetTester t,
    ) async {
      final SemanticsHandle handle = t.ensureSemantics();
      await pumpWater(t);
      await tapWater(t, find.byKey(LumeWaterTool.goalEditKey));

      // The field's own node carries the label, and the sheet's heading
      // repeats it, so the match is on the pattern rather than on one node.
      expect(find.bySemanticsLabel(RegExp('Goal in ml')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('^Save\$')), findsOneWidget);
      handle.dispose();
    });
  });

  group('the wider layouts', () {
    testWidgets('landscape phone', (WidgetTester t) async {
      await pumpWater(t, surface: LumeViewport.landscapePhone);
      expect(find.byKey(LumeWaterTool.summaryKey), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('expanded, where the host shows a detail pane', (
      WidgetTester t,
    ) async {
      await pumpWater(t, surface: LumeViewport.expanded);
      expect(find.byKey(LumeWaterTool.summaryKey), findsOneWidget);
      expect(find.byKey(LumeWaterTool.timelineKey), findsOneWidget);
      expect(find.byKey(LumeWaterTool.goalKey), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('dark mode draws from the theme', (WidgetTester t) async {
      await pumpWater(t, theme: ThemeMode.dark);
      expect(find.byKey(LumeWaterTool.summaryKey), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('200 % text scale does not overflow', (WidgetTester t) async {
      await pumpWater(t, textScale: 2, surface: const Size(390, 9000));
      expect(find.byKey(LumeWaterTool.summaryKey), findsOneWidget);
      expect(find.byKey(LumeWaterTool.goalEditKey), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });
}

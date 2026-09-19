/// Events and Shopping — the composition reads the records; a time is on the
/// reader's clock; a list's clear is confirmed and not undoable; Share makes
/// a card of what is still to get.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/widgets/lume/lume_agenda.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/events/domain/event_family.dart';
import 'package:lume/features/events/presentation/events_tool.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/data/record_seeds.dart';
import 'package:lume/features/records/domain/record_model.dart';
import 'package:lume/features/records/presentation/record_family.dart';
import 'package:lume/features/shopping/domain/shopping_family.dart';
import 'package:lume/features/share/presentation/share_sheet.dart';
import 'package:lume/features/shopping/presentation/shopping_tool.dart';
import 'package:lume/l10n/app_localizations_en.dart';

import '../../helpers/load_fonts.dart';
import 'wave2_harness.dart';

LumeRecordContext ctx({String zone = 'Asia/Karachi'}) => LumeRecordContext(
  l: AppLocalizationsEn(),
  f: const LumeFormatting(locale: Locale('en'), countryCode: 'PK'),
  now: kFixtureInstant,
  zone: LumeTimeZoneService.shared.resolveId(zone),
  currency: 'PKR',
);

/// Money is written with a no-break space after the symbol.
String plain(String? s) => (s ?? '').replaceAll(' ', ' ');

List<String> richTitles(WidgetTester tester, Key key) => <String>[
  for (final LumeRichRow r in tester.widgetList<LumeRichRow>(
    inKey(key, find.byType(LumeRichRow)),
  ))
    r.title,
];

void main() {
  setUpAll(loadLumeFonts);
  final DateTime now = kFixtureInstant;

  group('Events', () {
    const keys = LumeEventsTool.keys;

    testWidgets('upcoming is the records from today on, soonest first, on '
        'the reader\'s clock', (WidgetTester tester) async {
      final LumeMemoryRecordRepository store = wave2Store()..open('events');
      store.create('events', <String, Object?>{
        'title': 'Standup',
        'date': lumeIsoDay(now, 0),
        'at': '09:30',
      });
      store.create('events', <String, Object?>{
        'title': 'Last week',
        'date': lumeIsoDay(now, -7),
        'at': '10:00',
      });
      await pumpWave2(tester, 'events', store: store);
      expect(richTitles(tester, LumeEventsTool.upcomingKey), <String>[
        'Standup',
        'Team lunch',
        'Dentist',
      ]);
      final LumeRichRow lunch = tester
          .widgetList<LumeRichRow>(
            inKey(LumeEventsTool.upcomingKey, find.byType(LumeRichRow)),
          )
          .elementAt(1);
      expect(lunch.meta, <String>['7:00 pm · in 2 days', '12 going']);
      // Past events stay in the records.
      expect(
        tester
            .widgetList<LumeRecordRow>(find.byType(LumeRecordRow))
            .map((LumeRecordRow r) => r.title),
        contains('Last week'),
      );
    });

    testWidgets('a time is said in the reader\'s zone, never a fixed offset', (
      WidgetTester tester,
    ) async {
      await pumpWave2(tester, 'events', state: 'muslim_gb');
      await tapVisible(tester, find.byType(LumeRecordRow).first);
      final LumeFactCard facts = tester.widget(
        find.descendant(
          of: find.byKey(keys.facts),
          matching: find.byType(LumeFactCard),
        ),
      );
      expect(
        facts.facts.map((f) => '${f.label}: ${f.value}'),
        containsAllInOrder(<String>[
          'Time: 7:00 pm',
          'Timezone: \u2068Europe/London\u2069',
        ]),
      );
    });

    testWidgets('title and date are required; an emptied time reads as none', (
      WidgetTester tester,
    ) async {
      final LumeMemoryRecordRepository store = wave2Store();
      await pumpWave2(tester, 'events', store: store);
      await tapVisible(tester, find.byKey(keys.add));
      await tapVisible(tester, find.text('Save event'));
      expect(find.text('Title is required'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byKey(keys.field('title')),
          matching: find.byType(EditableText),
        ),
        'Parents evening',
      );
      await tapVisible(tester, find.byKey(keys.clearField('at')));
      await tapVisible(tester, find.text('Save event'));
      await settleSave(tester);
      final LumeRecord r = store.view('events').items.first;
      expect(r['date'], lumeIsoDay(now, 0));
      expect(r['at'], '');
      expect(find.text('No time set'), findsOneWidget);
    });

    test('an event holds no reminder, repeat or alert; nothing schedules', () {
      expect(LumeEventFamily.kSchema.fields.map((f) => f.name), <String>[
        'title',
        'date',
        'at',
        'where',
        'people',
        'notes',
      ]);
      for (final String path in <String>[
        'lib/features/events/domain/event_family.dart',
        'lib/features/events/presentation/events_tool.dart',
      ]) {
        final String code = File(path)
            .readAsLinesSync()
            .where((String l) => !l.trimLeft().startsWith('//'))
            .join('\n');
        for (final String banned in <String>[
          'Notification',
          'notification',
          'schedule(',
          'reminder',
          'DateTime.now',
          'Duration(hours:',
        ]) {
          expect(code, isNot(contains(banned)), reason: '$path: $banned');
        }
      }
    });

    test('people is a whole number above zero, or none', () {
      const LumeEventFamily family = LumeEventFamily();
      final LumeMemoryRecordRepository store = wave2Store()..open('events');
      for (final (Object? v, int? want) in <(Object?, int?)>[
        (12, 12),
        ('3', 3),
        (0, null),
        (-2, null),
        (2.5, null),
        ('', null),
      ]) {
        final LumeRecord r = store.create('events', <String, Object?>{
          'title': 'x',
          'date': lumeIsoDay(now, 1),
          'people': v,
        }).record!;
        expect(family.read(r, ctx()).people, want, reason: '$v');
      }
    });
  });

  group('Shopping', () {
    const keys = LumeShoppingTool.keys;

    testWidgets('the summary is the records\' — still to get, the estimate '
        'of everything, and the ticked share', (WidgetTester tester) async {
      await pumpWave2(tester, 'shopping');
      final LumeSummaryCard s = tester.widget(
        find.byKey(LumeShoppingTool.summaryKey),
      );
      expect(s.value, '4');
      expect(s.valueSmall, '/ 5');
      expect(plain(s.caption), 'about Rs 23');
      final LumeProgressRing ring = s.aside! as LumeProgressRing;
      expect(ring.value, closeTo(0.2, 1e-9));
      expect(ring.centreValue, '1/5');
      // Aisles in order, with the reader's items; quantities as written.
      final List<LumeCheckRow> produce = tester
          .widgetList<LumeCheckRow>(
            inKey(
              LumeShoppingTool.groupKey(LumeShopAisle.produce),
              find.byType(LumeCheckRow),
            ),
          )
          .toList();
      expect(
        produce.map(
          (LumeCheckRow r) => plain('${r.label} ${r.meta} ${r.value}'),
        ),
        <String>['Tomatoes 2 kg Rs 4', 'Lemons 1 Rs 3'],
      );
    });

    testWidgets('a tick moves the ring and the chips; Clear checked asks, '
        'says it cannot be undone, and offers no Undo', (
      WidgetTester tester,
    ) async {
      final LumeMemoryRecordRepository store = wave2Store();
      await pumpWave2(tester, 'shopping', store: store);
      final String milk = store
          .view('shopping')
          .items
          .firstWhere((LumeRecord r) => r['label'] == '@shopSeedI2')
          .id;
      await tapVisible(tester, find.byKey(LumeShoppingTool.itemKey(milk)));
      final LumeSummaryCard s = tester.widget(
        find.byKey(LumeShoppingTool.summaryKey),
      );
      expect(s.value, '3');
      expect(find.text('Clear 2 in the basket'), findsOneWidget);

      await tapVisible(tester, find.byKey(LumeShoppingTool.clearKey));
      expect(
        find.text(
          '2 items will be removed from the list. This cannot be undone.',
        ),
        findsOneWidget,
      );
      await tapVisible(tester, find.text('Clear 2 in the basket').last);
      expect(store.view('shopping').items, hasLength(3));
      expect(store.canUndo, isFalse);
      expect(find.text('2 removed'), findsOneWidget);
      expect(find.text('Undo'), findsNothing);
      // Nothing left ticked: nothing to clear.
      expect(
        tester
            .widget<LumeButton>(find.byKey(LumeShoppingTool.clearKey))
            .onPressed,
        isNull,
      );
      expect(find.byKey(keys.bulk), findsNothing);
    });

    testWidgets('Share the list offers a card of what is still to get', (
      WidgetTester tester,
    ) async {
      await pumpWave2(tester, 'shopping');
      await tapVisible(tester, find.byKey(LumeShoppingTool.shareKey));
      final LumeShareCard card = tester
          .widget<LumeShareSheet>(find.byType(LumeShareSheet))
          .card;
      expect(card.kind, LumeShareKind.reminder);
      expect(
        card.text,
        'Tomatoes (2 kg) · Milk (1 L) · Lemons (1) · Washing powder (2)',
      );
      expect(card.source, 'Shopping list · Mon, 7 Sept');
    });

    testWidgets('with everything in the basket there is nothing to share', (
      WidgetTester tester,
    ) async {
      final LumeMemoryRecordRepository store = wave2Store()..open('shopping');
      for (final LumeRecord r in store.view('shopping').items) {
        store.update('shopping', r.id, <String, Object?>{'done': true});
      }
      await pumpWave2(tester, 'shopping', store: store);
      expect(
        tester
            .widget<LumeButton>(find.byKey(LumeShoppingTool.shareKey))
            .onPressed,
        isNull,
      );
    });

    test('an empty list is an empty ring, not a division by zero', () {
      expect(LumeShoppingBoard(const <LumeShopItem>[]).share, 0);
      expect(LumeShoppingBoard(const <LumeShopItem>[]).estimate, 0);
    });

    test('a price that is not a number is no price; zero shows none', () {
      const LumeShoppingFamily family = LumeShoppingFamily();
      final LumeMemoryRecordRepository store = wave2Store()..open('shopping');
      for (final (Object? v, String? want) in <(Object?, String?)>[
        (4, 'Rs 4'),
        ('2.5', 'Rs 3'),
        ('', null),
        ('abc', null),
        (0, null),
      ]) {
        final LumeRecord r = store.create('shopping', <String, Object?>{
          'label': 'x',
          'price': v,
        }).record!;
        expect(
          family.price(family.read(r, ctx()), ctx())?.replaceAll(' ', ' '),
          want,
          reason: '$v',
        );
      }
    });
  });
}

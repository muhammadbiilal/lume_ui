/// The approved Wave 2 contracts (C86): record-backed compositions, To-dos'
/// rolling seven-date Week, and the Clear under an optional date or time.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/events/presentation/events_tool.dart';
import 'package:lume/features/notes/presentation/notes_tool.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/data/record_seeds.dart';
import 'package:lume/features/records/domain/record_model.dart';
import 'package:lume/features/records/presentation/record_family.dart';
import 'package:lume/features/records/presentation/record_tool.dart';
import 'package:lume/features/shopping/presentation/shopping_tool.dart';
import 'package:lume/features/todos/domain/todo_family.dart';
import 'package:lume/features/todos/presentation/todos_tool.dart';
import 'package:lume/l10n/app_localizations_en.dart';

import '../../helpers/load_fonts.dart';
import 'wave2_harness.dart';

List<String> metrics(WidgetTester t) => <String>[
  for (final LumeMetric m in t.widgetList<LumeMetric>(
    inKey(LumeNotesTool.metricsKey, find.byType(LumeMetric)),
  ))
    m.value,
];

/// A summary card's value, its small part, caption and stats, flat.
List<String> summary(WidgetTester t, Key key) {
  final LumeSummaryCard s = t.widget(find.byKey(key));
  return <String>[
    s.value,
    s.valueSmall ?? '',
    s.caption?.replaceAll(' ', ' ') ?? '',
    for (final LumeStat x in s.stats) x.value,
  ];
}

String idOf(
  LumeMemoryRecordRepository s,
  String coll,
  String field,
  Object v,
) => s.view(coll).items.firstWhere((LumeRecord r) => r[field] == v).id;

LumeRecordContext ctxAt(DateTime instant, String zone) => LumeRecordContext(
  l: AppLocalizationsEn(),
  f: const LumeFormatting(locale: Locale('en'), countryCode: 'US'),
  now: instant,
  zoneId: zone,
  currency: 'USD',
);

/// A task whose store record carries only what the Week contract reads.
LumeTodo task(
  LumeMemoryRecordRepository s,
  DateTime? due, {
  bool done = false,
}) {
  final LumeRecord r = s.create('todos', <String, Object?>{
    'label': 'x',
    'due': due == null ? '' : lumeIsoDay(due, 0),
    'done': done,
  }).record!;
  return const LumeTodoFamily().read(r, ctxAt(kFixtureInstant, 'Asia/Karachi'));
}

void main() {
  setUpAll(loadLumeFonts);

  group('record-backed compositions', () {
    testWidgets('Notes: create, edit, delete and Undo move every figure; a '
        'search does not', (WidgetTester t) async {
      final LumeMemoryRecordRepository s = wave2Store();
      await pumpWave2(t, 'notes', store: s);
      expect(metrics(t), <String>['4', '2', '3']);

      final String id = s
          .create('notes', <String, Object?>{'title': 'A', 'folder': 'ideas'})
          .record!
          .id;
      await t.pumpAndSettle();
      expect(metrics(t), <String>['5', '2', '3'], reason: 'create');

      s.update('notes', id, <String, Object?>{'pinned': true});
      await t.pumpAndSettle();
      expect(metrics(t), <String>['5', '3', '3'], reason: 'edit');

      s.remove('notes', id);
      await t.pumpAndSettle();
      expect(metrics(t), <String>['4', '2', '3'], reason: 'delete');

      s.undo();
      await t.pumpAndSettle();
      expect(metrics(t), <String>['5', '3', '3'], reason: 'Undo');

      await t.enterText(find.byKey(LumeNotesTool.keys.search), 'zzz');
      await t.pumpAndSettle();
      expect(metrics(t), <String>['5', '3', '3'], reason: 'search');
    });

    testWidgets('To-dos: the summary follows every write; When, Priority and '
        'the search narrow only the list', (WidgetTester t) async {
      final LumeMemoryRecordRepository s = wave2Store();
      await pumpWave2(t, 'todos', store: s);
      const Key k = LumeTodosTool.summaryKey;
      expect(summary(t, k), <String>[
        '1',
        '/ 3',
        'Nothing overdue',
        '0',
        '1',
        '1',
      ]);

      final String id = s
          .create('todos', <String, Object?>{
            'label': 'Late',
            'due': lumeIsoDay(kFixtureInstant, -2),
          })
          .record!
          .id;
      await t.pumpAndSettle();
      expect(summary(t, k), <String>['1', '/ 4', '1 overdue', '1', '1', '1']);

      s.update('todos', id, <String, Object?>{'done': true});
      await t.pumpAndSettle();
      // Done and past due: off Today, not overdue, done this week.
      expect(summary(t, k), <String>[
        '1',
        '/ 3',
        'Nothing overdue',
        '0',
        '1',
        '2',
      ]);

      s.remove('todos', id);
      await t.pumpAndSettle();
      expect(summary(t, k), <String>[
        '1',
        '/ 3',
        'Nothing overdue',
        '0',
        '1',
        '1',
      ]);

      s.undo();
      await t.pumpAndSettle();
      expect(summary(t, k), <String>[
        '1',
        '/ 3',
        'Nothing overdue',
        '0',
        '1',
        '2',
      ]);

      final List<String> before = summary(t, k);
      await tapVisible(t, find.byKey(LumeTodosTool.whenChip(LumeTodoWhen.all)));
      await tapVisible(t, find.byKey(LumeTodosTool.priorityChip('high')));
      await t.enterText(find.byKey(LumeTodosTool.keys.search), 'send');
      await t.pumpAndSettle();
      expect(summary(t, k), before);
    });

    testWidgets('Events: upcoming follows create, a date moved into the past, '
        'delete and Undo', (WidgetTester t) async {
      final LumeMemoryRecordRepository s = wave2Store();
      await pumpWave2(t, 'events', store: s);
      int rows() => t
          .widgetList(
            inKey(LumeEventsTool.upcomingKey, find.byType(LumeRichRow)),
          )
          .length;
      expect(rows(), 2);
      final String id = s
          .create('events', <String, Object?>{
            'title': 'Standup',
            'date': lumeIsoDay(kFixtureInstant, 1),
          })
          .record!
          .id;
      await t.pumpAndSettle();
      expect(rows(), 3, reason: 'create');
      s.update('events', id, <String, Object?>{
        'date': lumeIsoDay(kFixtureInstant, -1),
      });
      await t.pumpAndSettle();
      expect(rows(), 2, reason: 'edit into the past');
      s.remove('events', id);
      s.undo();
      await t.pumpAndSettle();
      expect(rows(), 2, reason: 'delete then Undo: back, still past');
    });

    testWidgets('Shopping: the summary follows every write and the bulk '
        'clear; a search does not', (WidgetTester t) async {
      final LumeMemoryRecordRepository s = wave2Store();
      await pumpWave2(t, 'shopping', store: s);
      const Key k = LumeShoppingTool.summaryKey;
      expect(summary(t, k), <String>['4', '/ 5', 'about Rs 23']);

      final String id = s
          .create('shopping', <String, Object?>{'label': 'Rice', 'price': 10})
          .record!
          .id;
      await t.pumpAndSettle();
      expect(summary(t, k), <String>['5', '/ 6', 'about Rs 33']);

      s.update('shopping', id, <String, Object?>{'price': 12, 'done': true});
      await t.pumpAndSettle();
      expect(summary(t, k), <String>['4', '/ 6', 'about Rs 35']);

      s.remove('shopping', id);
      await t.pumpAndSettle();
      expect(summary(t, k), <String>['4', '/ 5', 'about Rs 23']);
      s.undo();
      await t.pumpAndSettle();
      expect(summary(t, k), <String>['4', '/ 6', 'about Rs 35']);

      await t.enterText(find.byKey(LumeShoppingTool.keys.search), 'zzz');
      await t.pumpAndSettle();
      expect(summary(t, k), <String>['4', '/ 6', 'about Rs 35']);
      await t.enterText(find.byKey(LumeShoppingTool.keys.search), '');
      await t.pumpAndSettle();

      await tapVisible(t, find.byKey(LumeShoppingTool.clearKey));
      await tapVisible(t, find.text('Clear 2 in the basket').last);
      expect(summary(t, k), <String>['4', '/ 4', 'about Rs 17']);
      final LumeProgressRing ring =
          t.widget<LumeSummaryCard>(find.byKey(k)).aside! as LumeProgressRing;
      expect(ring.value, 0);
    });

    testWidgets('with no records, no figure remains: nothing a fixture could '
        'have put there', (WidgetTester t) async {
      final LumeMemoryRecordRepository s = wave2Store();
      for (final String c in <String>['notes', 'todos', 'shopping', 'events']) {
        s.open(c);
        for (final LumeRecord r in s.view(c).items) {
          s.remove(c, r.id);
        }
      }
      await pumpWave2(t, 'notes', store: s);
      // Three folders is the family's list of folders, not a count of notes.
      expect(metrics(t), <String>['0', '0', '3']);
      await pumpWave2(t, 'todos', store: s);
      expect(summary(t, LumeTodosTool.summaryKey), <String>[
        '0',
        '/ 0',
        'Nothing overdue',
        '0',
        '0',
        '0',
      ]);
      await pumpWave2(t, 'shopping', store: s);
      expect(summary(t, LumeShoppingTool.summaryKey), <String>[
        '0',
        '/ 0',
        'about Rs 0',
      ]);
      await pumpWave2(t, 'events', store: s);
      expect(find.byKey(LumeEventsTool.emptyKey), findsOneWidget);
    });

    test('the four tools read no fixture module', () {
      for (final String f in <String>[
        'lib/features/notes/presentation/notes_tool.dart',
        'lib/features/todos/presentation/todos_tool.dart',
        'lib/features/events/presentation/events_tool.dart',
        'lib/features/shopping/presentation/shopping_tool.dart',
        'lib/features/notes/domain/note_family.dart',
        'lib/features/todos/domain/todo_family.dart',
        'lib/features/events/domain/event_family.dart',
        'lib/features/shopping/domain/shopping_family.dart',
      ]) {
        final String src = File(f).readAsStringSync();
        expect(src, isNot(contains('_fixtures.dart')), reason: f);
        expect(src, isNot(contains('core/fixtures/lume_reference')), reason: f);
      }
    });
  });

  group('To-dos Week: today and the six calendar dates after it', () {
    final LumeMemoryRecordRepository s = wave2Store()..open('todos');
    final DateTime today = DateTime(2026, 9, 7);
    DateTime at(int d) => DateTime(today.year, today.month, today.day + d);

    test('which tasks each segment holds', () {
      final Map<String, LumeTodo> x = <String, LumeTodo>{
        'due today': task(s, at(0)),
        'due today, done': task(s, at(0), done: true),
        'sixth date after': task(s, at(6)),
        'sixth date after, done': task(s, at(6), done: true),
        'seventh date after': task(s, at(7)),
        'overdue': task(s, at(-3)),
        'past due, done': task(s, at(-3), done: true),
        'undated': task(s, null),
        'undated, done': task(s, null, done: true),
      };
      Set<String> inside(LumeTodoWhen w) => <String>{
        for (final MapEntry<String, LumeTodo> e in x.entries)
          if (w.holds(e.value, today)) e.key,
      };
      expect(inside(LumeTodoWhen.today), <String>{
        'due today',
        'due today, done',
        'overdue',
        'undated',
        'undated, done',
      });
      expect(inside(LumeTodoWhen.week), <String>{
        ...inside(LumeTodoWhen.today),
        'sixth date after',
        'sixth date after, done',
      });
      expect(inside(LumeTodoWhen.all), x.keys.toSet());
      expect(LumeTodoWhen.weekSpan, 6);
    });

    test('"today" is the reader\'s date, from the injected instant on their '
        'zone — a zone change moves it', () {
      // 20:30 UTC: still the 7th in New York, already the 8th in Karachi.
      final DateTime instant = DateTime.utc(2026, 9, 7, 20, 30);
      final LumeRecordContext ny = ctxAt(instant, 'America/New_York');
      final LumeRecordContext khi = ctxAt(instant, 'Asia/Karachi');
      expect(ny.today, DateTime(2026, 9, 7));
      expect(khi.today, DateTime(2026, 9, 8));
      expect(ny.zoneKnown && khi.zoneKnown, isTrue);
      final LumeTodo due14 = task(s, DateTime(2026, 9, 14));
      expect(LumeTodoWhen.week.holds(due14, ny.today), isFalse);
      expect(LumeTodoWhen.week.holds(due14, khi.today), isTrue);
    });

    test('calendar dates, not 168 hours, across a daylight-saving change', () {
      // New York springs forward on 8 March 2026. At 23:30 on the 7th the
      // window is the 7th to the 13th: the 14th is out, although 168 hours
      // from now falls on it.
      final DateTime instant = DateTime.utc(2026, 3, 8, 4, 30);
      final LumeRecordContext ny = ctxAt(instant, 'America/New_York');
      expect(ny.today, DateTime(2026, 3, 7));
      expect(
        ny.local.add(const Duration(hours: 168)).day,
        14,
        reason: 'what an hours window would have reached',
      );
      expect(
        LumeTodoWhen.week.holds(task(s, DateTime(2026, 3, 13)), ny.today),
        isTrue,
      );
      expect(
        LumeTodoWhen.week.holds(task(s, DateTime(2026, 3, 14)), ny.today),
        isFalse,
      );
      // And falling back on 1 November: the 7th after is still out.
      final LumeRecordContext fall = ctxAt(
        DateTime.utc(2026, 10, 31, 12),
        'America/New_York',
      );
      expect(fall.today, DateTime(2026, 10, 31));
      expect(
        LumeTodoWhen.week.holds(task(s, DateTime(2026, 11, 6)), fall.today),
        isTrue,
      );
      expect(
        LumeTodoWhen.week.holds(task(s, DateTime(2026, 11, 7)), fall.today),
        isFalse,
      );
    });

    test('a zone the database cannot read falls back to the device\'s date, '
        'and says so', () {
      final LumeRecordContext c = ctxAt(kFixtureInstant, 'Asia/Tokyo');
      expect(c.zoneKnown, isFalse);
      expect(c.today, DateTime(2026, 9, 7));
    });

    for (final (Locale locale, String spoken, TextDirection dir)
        in <(Locale, String, TextDirection)>[
          (const Locale('en'), 'Next seven days', TextDirection.ltr),
          (const Locale('ur'), 'اگلے سات دن', TextDirection.rtl),
          (const Locale('ar'), 'الأيام السبعة القادمة', TextDirection.rtl),
        ]) {
      testWidgets(
        'the Week chip is spoken as "$spoken" (${locale.languageCode})',
        (WidgetTester t) async {
          final SemanticsHandle h = t.ensureSemantics();
          await pumpWave2(t, 'todos', locale: locale);
          final Finder chip = find.byKey(
            LumeTodosTool.whenChip(LumeTodoWhen.week),
          );
          expect(
            t.getSemantics(chip),
            isSemantics(label: spoken, isButton: true),
          );
          expect(Directionality.of(t.element(chip)), dir);
          await tapVisible(t, chip);
          expect(t.widget<LumeFilterChip>(chip).selected, isTrue);
          h.dispose();
        },
      );
    }
  });

  group('Clear under an optional date or time', () {
    const LumeRecordKeys todo = LumeTodosTool.keys;
    const LumeRecordKeys event = LumeEventsTool.keys;

    testWidgets('shown only with a value; named for what it clears; at least '
        '44 × 44', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      final LumeMemoryRecordRepository s = wave2Store();
      await pumpWave2(t, 'todos', store: s);
      await tapVisible(t, find.byKey(todo.add));
      final Finder clear = find.byKey(todo.clearField('due'));
      expect(clear, findsOneWidget);
      expect(
        t.getSemantics(clear),
        isSemantics(label: 'Clear due date', isButton: true),
      );
      final Size size = t.getSize(clear);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
      await tapVisible(t, clear);
      expect(clear, findsNothing, reason: 'nothing left to clear');
      h.dispose();
    });

    testWidgets('an undated task offers no Clear', (WidgetTester t) async {
      final LumeMemoryRecordRepository s = wave2Store();
      await pumpWave2(t, 'todos', store: s);
      await tapVisible(
        t,
        find.byKey(todo.row(idOf(s, 'todos', 'label', '@todosSeedItem4'))),
      );
      await tapVisible(t, find.text('Edit task').last);
      expect(find.byKey(todo.form), findsOneWidget);
      expect(find.byKey(todo.clearField('due')), findsNothing);
    });

    testWidgets('clearing an event\'s time leaves its date; the form is then '
        'changed, and leaving it asks first', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      final LumeMemoryRecordRepository s = wave2Store();
      await pumpWave2(t, 'events', store: s);
      await tapVisible(t, find.byType(LumeRecordRow).first);
      await tapVisible(t, find.text('Edit event').last);
      final Finder clear = find.byKey(event.clearField('at'));
      expect(
        t.getSemantics(clear),
        isSemantics(label: 'Clear event time', isButton: true),
      );
      // The date is required and has no Clear of its own.
      expect(find.byKey(event.clearField('date')), findsNothing);
      await tapVisible(t, clear);
      expect(find.byKey(event.clearField('at')), findsNothing);
      expect(
        find.text('Wed, 9 Sept'),
        findsOneWidget,
        reason: 'the date stays',
      );
      await tapVisible(t, find.byType(LumeBackButton));
      expect(find.byType(LumeDeleteConfirmation), findsOneWidget);
      expect(find.text('Discard your changes?'), findsOneWidget);
      h.dispose();
    });

    testWidgets('reached and pressed from the keyboard', (
      WidgetTester t,
    ) async {
      await pumpWave2(t, 'todos');
      await tapVisible(t, find.byKey(todo.add));
      final Finder clear = find.byKey(todo.clearField('due'));
      bool focused() {
        final FocusNode? f = FocusManager.instance.primaryFocus;
        if (f?.context == null) return false;
        return find
            .descendant(
              of: clear,
              matching: find.byElementPredicate(
                (Element e) => identical(e, f!.context),
              ),
            )
            .evaluate()
            .isNotEmpty;
      }

      for (int i = 0; i < 40 && !focused(); i++) {
        await t.sendKeyEvent(LogicalKeyboardKey.tab);
        await t.pump();
      }
      expect(focused(), isTrue, reason: 'Tab reaches Clear');
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(clear, findsNothing);
    });

    testWidgets('pressed through the accessibility action, as switch access '
        'does', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await pumpWave2(t, 'todos');
      await tapVisible(t, find.byKey(todo.add));
      t.semantics.tap(find.semantics.byLabel('Clear due date'));
      await t.pumpAndSettle();
      expect(find.byKey(todo.clearField('due')), findsNothing);
      h.dispose();
    });

    for (final (String what, Size size, double scale, Locale locale)
        in <(String, Size, double, Locale)>[
          ('at 200 %', const Size(390, 844), 2, const Locale('en')),
          ('in narrow landscape', const Size(852, 393), 1, const Locale('en')),
          ('right to left', const Size(390, 844), 1, const Locale('ur')),
        ]) {
      testWidgets(what, (WidgetTester t) async {
        final SemanticsHandle h = t.ensureSemantics();
        await pumpWave2(
          t,
          'todos',
          surface: size,
          textScale: scale,
          locale: locale,
        );
        await tapVisible(t, find.byKey(todo.add));
        final Finder clear = find.byKey(todo.clearField('due'));
        await t.ensureVisible(clear);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        final Rect r = t.getRect(clear);
        expect(r.width >= 44 && r.height >= 44, isTrue, reason: '$r');
        if (locale.languageCode == 'ur') {
          expect(
            t.getSemantics(clear),
            isSemantics(label: 'مقررہ تاریخ ہٹائیں', isButton: true),
          );
          // At the field's end, which in Urdu is the left.
          final Rect field = t.getRect(find.byKey(todo.field('due')));
          expect(r.left, lessThan(field.center.dx));
        }
        await t.tap(clear);
        await t.pumpAndSettle();
        expect(clear, findsNothing);
        h.dispose();
      });
    }
  });
}

/// To-dos — a tick is one write wherever it is made, the summary is worked
/// out from the tasks, and a due day is a date, never a notification.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/core/widgets/lume/lume_agenda.dart';
import 'package:lume/core/widgets/lume/lume_chip.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/data/record_seeds.dart';
import 'package:lume/features/records/domain/record_model.dart';
import 'package:lume/features/records/presentation/record_family.dart';
import 'package:lume/features/todos/domain/todo_family.dart';
import 'package:lume/features/todos/presentation/todos_tool.dart';
import 'package:lume/l10n/app_localizations_en.dart';

import '../../helpers/load_fonts.dart';
import 'wave2_harness.dart';

const String kTodos = 'todos';

LumeRecordContext ctx(DateTime now) => LumeRecordContext(
  l: AppLocalizationsEn(),
  f: const LumeFormatting(locale: Locale('en'), countryCode: 'PK'),
  now: now,
  zone: LumeTimeZoneService.shared.resolveId('Asia/Karachi'),
  currency: 'PKR',
);

List<LumeTodo> read(LumeMemoryRecordRepository store, DateTime now) {
  const LumeTodoFamily family = LumeTodoFamily();
  return <LumeTodo>[
    for (final LumeRecord r in store.view('todos').items)
      family.read(r, ctx(now)),
  ];
}

List<String> visibleLabels(WidgetTester tester) => <String>[
  for (final LumeCheckRow r in tester.widgetList<LumeCheckRow>(
    inKey(LumeTodosTool.visibleKey, find.byType(LumeCheckRow)),
  ))
    r.label,
];

void main() {
  setUpAll(loadLumeFonts);

  const keys = LumeTodosTool.keys;
  final DateTime now = kFixtureInstant;

  testWidgets('the tasks lead with Open and Done chips; the summary is '
      'today\'s, worked out from them', (WidgetTester tester) async {
    await pumpWave2(tester, kTodos);
    final List<LumeRecordChip> chips = tester
        .widgetList<LumeRecordChip>(find.byType(LumeRecordChip))
        .toList();
    expect(
      <String>[for (final LumeRecordChip c in chips) '${c.label} ${c.count}'],
      <String>['All 4', 'Open 3', 'Done 1'],
    );
    final LumeSummaryCard s = tester.widget(
      find.byKey(LumeTodosTool.summaryKey),
    );
    // Due today: two; undated: the done one. Tomorrow's is coming up.
    expect(s.value, '1');
    expect(s.valueSmall, '/ 3');
    expect(s.caption, 'Nothing overdue');
    expect(
      <String>[for (final LumeStat x in s.stats) x.value],
      <String>['0', '1', '1'],
    );
  });

  testWidgets('a tick in the composition is the record\'s tick — and a sample '
      'task keeps speaking the reader\'s language', (
    WidgetTester tester,
  ) async {
    final LumeMemoryRecordRepository store = wave2Store();
    await pumpWave2(tester, kTodos, store: store, locale: const Locale('ur'));
    final Finder first = find.byKey(
      LumeTodosTool.taskKey(store.view('todos').items.first.id),
    );
    await tapVisible(tester, first);
    final LumeRecord r = store.view('todos').items.first;
    expect(r['done'], isTrue);
    // A tick writes no words: the record is still a sample, so its '@key'
    // is still read in Urdu rather than shown raw (`records.js` keeps
    // `_seed` on a toggle).
    expect(r.seeded, isTrue);
    expect(find.text('سہ ماہی خلاصہ بھیجیں'), findsWidgets);
    expect(find.textContaining('@todosSeed'), findsNothing);
    final LumeRecordRow row = tester.widget<LumeRecordRow>(
      find.byKey(keys.row(r.id)),
    );
    expect(row.done, isTrue);
  });

  testWidgets('the record row\'s own check says what it is, in the reader\'s '
      'words, and which row it is on', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpWave2(tester, kTodos);
    expect(
      find.bySemanticsLabel('Completed, Send the quarterly summary'),
      findsOneWidget,
    );
    handle.dispose();
  });

  test('overdue, coming up and done this week are worked out, not fixed', () {
    final LumeMemoryRecordRepository store = wave2Store()..open('todos');
    store.create('todos', <String, Object?>{
      'label': 'Renew the licence',
      'list': 'personal',
      'due': lumeIsoDay(now, -3),
      'priority': 'high',
    });
    store.create('todos', <String, Object?>{
      'label': 'Plan the trip',
      'list': 'home',
      'due': lumeIsoDay(now, 12),
    });
    final LumeTodoBoard board = LumeTodoBoard(read(store, now), now);
    expect(board.overdue, 1);
    expect(
      board.onToday.map((LumeTodo x) => x.label),
      contains('Renew the licence'),
    );
    expect(board.upcoming.map((LumeTodo x) => x.label), <String>[
      'Review the design feedback',
      'Plan the trip',
    ]);
    expect(board.done7(now), 1);
    expect(board.openIn(LumeTodoList.work), 2);
    // A done task last changed eight days ago is not this week's.
    expect(board.done7(now.add(const Duration(days: 8))), 0);
  });

  testWidgets('When: Today, the week ahead, or everything; Priority narrows '
      'it (the reference\'s Week and All were the same list — C86)', (
    WidgetTester tester,
  ) async {
    final LumeMemoryRecordRepository store = wave2Store()..open('todos');
    store.create('todos', <String, Object?>{
      'label': 'Plan the trip',
      'list': 'home',
      'due': lumeIsoDay(now, 12),
    });
    await pumpWave2(tester, kTodos, store: store);
    expect(visibleLabels(tester), <String>[
      'Send the quarterly summary',
      'Pick up the prescription',
      'Book the car service',
    ]);
    await tapVisible(
      tester,
      find.byKey(LumeTodosTool.whenChip(LumeTodoWhen.week)),
    );
    expect(visibleLabels(tester), contains('Review the design feedback'));
    expect(visibleLabels(tester), isNot(contains('Plan the trip')));
    await tapVisible(
      tester,
      find.byKey(LumeTodosTool.whenChip(LumeTodoWhen.all)),
    );
    expect(visibleLabels(tester), contains('Plan the trip'));
    await tapVisible(tester, find.byKey(LumeTodosTool.priorityChip('high')));
    expect(visibleLabels(tester), <String>['Send the quarterly summary']);
    await tester.enterText(find.byKey(keys.search), 'zzz');
    await tester.pumpAndSettle();
    expect(find.byKey(LumeTodosTool.emptyKey), findsOneWidget);
  });

  testWidgets('Add a task opens the form with today due and normal priority', (
    WidgetTester tester,
  ) async {
    await pumpWave2(tester, kTodos);
    await tapVisible(tester, find.byKey(LumeTodosTool.fabKey));
    expect(find.byKey(keys.form), findsOneWidget);
    expect(find.text('Mon, 7 Sept'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    // The due day is optional, and can be emptied.
    await tapVisible(tester, find.byKey(keys.clearField('due')));
    expect(find.byKey(keys.clearField('due')), findsNothing);
  });

  test('a task holds no reminder: nothing in the family or the tool '
      'schedules or delivers anything', () {
    expect(LumeTodoFamily.kSchema.fields.map((f) => f.name), <String>[
      'label',
      'list',
      'due',
      'priority',
      'done',
      'notes',
    ]);
    for (final String path in <String>[
      'lib/features/todos/domain/todo_family.dart',
      'lib/features/todos/presentation/todos_tool.dart',
    ]) {
      final String src = File(path).readAsStringSync();
      for (final String banned in <String>[
        'notification',
        'Notification',
        'schedule(',
        'alarm',
        'DateTime.now',
      ]) {
        final String code = src
            .split('\n')
            .where((String l) => !l.trimLeft().startsWith('//'))
            .join('\n');
        expect(code, isNot(contains(banned)), reason: '$path: $banned');
      }
    }
  });
}

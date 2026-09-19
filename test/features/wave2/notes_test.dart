/// Notes — the record host's lifecycle, and a composition that reads the
/// records rather than a fixture beside them (C86).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/notes/domain/note_family.dart';
import 'package:lume/features/notes/presentation/notes_tool.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_model.dart';

import '../../helpers/load_fonts.dart';
import 'wave2_harness.dart';

const String kNotes = 'notes';

List<String> recordTitles(WidgetTester tester) => <String>[
  for (final LumeRecordRow r in tester.widgetList<LumeRecordRow>(
    find.byType(LumeRecordRow),
  ))
    r.title,
];

List<String> metricValues(WidgetTester tester) => <String>[
  for (final LumeMetric m in tester.widgetList<LumeMetric>(
    inKey(LumeNotesTool.metricsKey, find.byType(LumeMetric)),
  ))
    m.value,
];

List<String?> folderCounts(WidgetTester tester) => <String?>[
  for (final LumeCompactRow r in tester.widgetList<LumeCompactRow>(
    inKey(LumeNotesTool.foldersKey, find.byType(LumeCompactRow)),
  ))
    r.value,
];

void main() {
  setUpAll(loadLumeFonts);

  const keys = LumeNotesTool.keys;

  testWidgets('the records lead, in the reader\'s language, pinned first '
      'in the reference\'s order', (WidgetTester tester) async {
    await pumpWave2(tester, kNotes);
    expect(recordTitles(tester), <String>[
      'Sprint retro points',
      'Reading list',
      'App idea',
      'Meeting notes',
    ]);
    final LumeRecordRow first = tester.widget<LumeRecordRow>(
      find.byType(LumeRecordRow).first,
    );
    expect(first.badge?.label, 'Pinned');
    expect(first.meta, <String>['Work', 'Today']);
    // The body cut at 62 characters, as `row(r).sub` cuts it.
    expect(
      first.subtitle,
      'Ship the onboarding fix first, then revisit the empty states…',
    );
  });

  testWidgets('in Urdu the sample notes speak Urdu', (
    WidgetTester tester,
  ) async {
    await pumpWave2(tester, kNotes, locale: const Locale('ur'));
    expect(recordTitles(tester).first, 'اسپرنٹ جائزے کے نکات');
    expect(
      Directionality.of(tester.element(find.byType(LumeRecordRow).first)),
      TextDirection.rtl,
    );
  });

  testWidgets('the composition reads the records: metrics, folders, pinned '
      'cards and recent all move with them (C86)', (WidgetTester tester) async {
    final LumeMemoryRecordRepository store = wave2Store();
    await pumpWave2(tester, kNotes, store: store);
    expect(metricValues(tester), <String>['4', '2', '3']);
    // The reference writes 5, 4 and 3 beside four notes.
    expect(folderCounts(tester), <String?>['2', '1', '1']);
    expect(
      find.descendant(
        of: find.byKey(LumeNotesTool.pinnedKey),
        matching: find.byType(LumeNoteTile),
      ),
      findsNWidgets(2),
    );

    store.create('notes', <String, Object?>{
      'title': 'Groceries plan',
      'body': 'Rice, lentils',
      'folder': 'ideas',
      'pinned': true,
    });
    await tester.pumpAndSettle();
    expect(metricValues(tester), <String>['5', '3', '3']);
    expect(folderCounts(tester), <String?>['2', '1', '2']);
    expect(
      find.descendant(
        of: find.byKey(LumeNotesTool.pinnedKey),
        matching: find.byType(LumeNoteTile),
      ),
      findsNWidgets(3),
    );
  });

  testWidgets('one query searches the records and the recent notes', (
    WidgetTester tester,
  ) async {
    await pumpWave2(tester, kNotes);
    await tester.enterText(find.byKey(keys.search), 'reading');
    await tester.pumpAndSettle();
    expect(recordTitles(tester), <String>['Reading list']);
    expect(
      find.descendant(
        of: find.byKey(LumeNotesTool.recentKey),
        matching: find.byType(LumeRichRow),
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(keys.search), 'zzz');
    await tester.pumpAndSettle();
    expect(find.byKey(keys.recordState), findsOneWidget);
    expect(find.byKey(LumeNotesTool.emptyKey), findsOneWidget);
    await tapVisible(tester, find.text('Clear'));
    expect(recordTitles(tester), hasLength(4));
  });

  testWidgets('a pinned card and a recent row open their note', (
    WidgetTester tester,
  ) async {
    await pumpWave2(tester, kNotes);
    await tapVisible(tester, find.byType(LumeNoteTile).at(1));
    expect(find.byKey(keys.hero), findsOneWidget);
    final LumeRecordHero hero = tester.widget(find.byKey(keys.hero));
    expect(hero.kicker, 'Personal');
    expect(hero.value, 'Reading list');
    expect(hero.caption, 'Edited Today');
  });

  testWidgets('New note opens the form, which judges only what was left or '
      'submitted, and focuses the first error', (WidgetTester tester) async {
    await pumpWave2(tester, kNotes);
    await tapVisible(tester, find.byKey(LumeNotesTool.fabKey));
    expect(find.byKey(keys.form), findsOneWidget);
    expect(find.text('Title is required'), findsNothing);

    await tapVisible(tester, find.text('Save note'));
    expect(find.text('Title is required'), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(keys.field('title')),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );

    await tester.enterText(
      find.descendant(
        of: find.byKey(keys.field('title')),
        matching: find.byType(EditableText),
      ),
      'Packing list',
    );
    await tapVisible(tester, find.byKey(keys.field('pinned')));
    await tapVisible(tester, find.text('Save note'));
    await settleSave(tester);
    final LumeRecordHero hero = tester.widget(find.byKey(keys.hero));
    expect(hero.value, 'Packing list');
    expect(find.text('Note added'), findsOneWidget);
    await tapVisible(tester, find.text('Undo'));
    await tapVisible(tester, find.byType(LumeBackButton));
    expect(recordTitles(tester), isNot(contains('Packing list')));
  });

  testWidgets('leaving a changed form asks first; keeping stays', (
    WidgetTester tester,
  ) async {
    await pumpWave2(tester, kNotes);
    await tapVisible(tester, find.byKey(keys.add));
    await tester.enterText(
      find.descendant(
        of: find.byKey(keys.field('title')),
        matching: find.byType(EditableText),
      ),
      'Half',
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byType(LumeBackButton));
    expect(find.byType(LumeDeleteConfirmation), findsOneWidget);
    await tapVisible(tester, find.text('Keep editing'));
    expect(find.byKey(keys.form), findsOneWidget);
    await tapVisible(tester, find.byType(LumeBackButton));
    await tapVisible(tester, find.text('Discard'));
    expect(find.byKey(keys.form), findsNothing);
    expect(recordTitles(tester), hasLength(4));
  });

  testWidgets('editing a sample note keeps its words and makes it the '
      'reader\'s', (WidgetTester tester) async {
    final LumeMemoryRecordRepository store = wave2Store();
    await pumpWave2(tester, kNotes, store: store);
    await tapVisible(tester, find.byType(LumeRecordRow).first);
    await tapVisible(tester, find.text('Edit note').last);
    final TextField title = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(keys.field('title')),
        matching: find.byType(TextField),
      ),
    );
    expect(title.controller!.text, 'Sprint retro points');
    await tapVisible(tester, find.text('Save changes'));
    await settleSave(tester);
    final LumeRecord r = store.view('notes').items.first;
    expect(r.seeded, isFalse);
    expect(r['title'], 'Sprint retro points');
  });

  testWidgets('a delete can be undone, as the family is recoverable', (
    WidgetTester tester,
  ) async {
    await pumpWave2(tester, kNotes);
    await tapVisible(tester, find.byType(LumeRecordRow).at(2));
    await tapVisible(tester, find.text('Delete note'));
    expect(
      find.text('App idea will be removed. You can undo this straight away.'),
      findsOneWidget,
    );
    await tapVisible(tester, find.text('Delete note').last);
    expect(recordTitles(tester), isNot(contains('App idea')));
    await tapVisible(tester, find.text('Undo'));
    expect(recordTitles(tester), contains('App idea'));
  });

  testWidgets('at expanded width a note opens beside the list', (
    WidgetTester tester,
  ) async {
    await pumpWave2(tester, kNotes, surface: const Size(1100, 2400));
    expect(find.text('Nothing selected'), findsOneWidget);
    await tapVisible(tester, find.byType(LumeRecordRow).first);
    expect(find.byType(LumeMasterDetail), findsOneWidget);
    expect(find.byKey(keys.hero), findsOneWidget);
    expect(find.byType(LumeRecordRow), findsNWidgets(4));
    final LumeRecordRow selected = tester.widget<LumeRecordRow>(
      find.byType(LumeRecordRow).first,
    );
    expect(selected.selected, isTrue);
  });

  testWidgets('a collection that cannot be read says so and retries', (
    WidgetTester tester,
  ) async {
    final LumeMemoryRecordRepository store = wave2Store()
      ..unreadable.add('notes');
    await pumpWave2(tester, kNotes, store: store);
    final LumeCollectionState s = tester.widget(find.byKey(keys.recordState));
    expect(s.kind, LumeCollectionStateKind.error);
    expect(s.title, 'We could not load notes');
    store.unreadable.clear();
    await tapVisible(tester, find.text('Try again'));
    expect(recordTitles(tester), hasLength(4));
  });

  testWidgets('an empty collection offers the first note, and promises no '
      'storage it does not have (C86)', (WidgetTester tester) async {
    final LumeMemoryRecordRepository store = wave2Store();
    await pumpWave2(tester, kNotes, store: store);
    for (final LumeRecord r in store.view('notes').items) {
      store.remove('notes', r.id);
    }
    await tester.pumpAndSettle();
    final LumeCollectionState s = tester.widget(find.byKey(keys.recordState));
    expect(s.kind, LumeCollectionStateKind.empty);
    expect(s.text, 'Notes are searchable the moment you save them.');
    expect(s.text, isNot(contains('device')));
    expect(metricValues(tester), <String>['0', '0', '3']);
  });

  test('the family reads the reference\'s own folder keys too', () {
    expect(LumeNoteFolder.byId('@notes.fIdeas'), LumeNoteFolder.ideas);
    expect(LumeNoteFolder.byId('ideas'), LumeNoteFolder.ideas);
    expect(LumeNoteFolder.byId('elsewhere'), isNull);
  });

  testWidgets('a field\'s value survives a failed save', (
    WidgetTester tester,
  ) async {
    final LumeMemoryRecordRepository store = wave2Store()..refuseWrites = true;
    await pumpWave2(tester, kNotes, store: store);
    await tapVisible(tester, find.byKey(keys.add));
    await tester.enterText(
      find.descendant(
        of: find.byKey(keys.field('title')),
        matching: find.byType(EditableText),
      ),
      'Kept',
    );
    await tapVisible(tester, find.text('Save note'));
    await settleSave(tester);
    expect(find.text('Nothing you typed was lost. Try again.'), findsOneWidget);
    expect(
      tester
          .widget<LumeFormField>(find.byKey(keys.field('title')))
          .controller!
          .text,
      'Kept',
    );
  });
}

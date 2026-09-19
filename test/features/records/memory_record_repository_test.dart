/// The record store, held to what `records.js` does.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_model.dart';

final DateTime kNow = DateTime(2026, 9, 7, 16, 41, 32);

LumeMemoryRecordRepository store({Duration? delay}) =>
    LumeMemoryRecordRepository(
      now: () => kNow,
      hydrateDelay: delay,
      seeds: (String c, DateTime now) => c == 'expenses'
          ? <Map<String, Object?>>[
              <String, Object?>{'title': '@groceries', 'amount': 34},
              <String, Object?>{'title': '@taxi', 'amount': 9},
            ]
          : null,
    );

void main() {
  // A widget test's clock is a fake one, so the 220 ms read is timed exactly.
  testWidgets('the first open is a loading state, and the records arrive', (
    WidgetTester tester,
  ) async {
    final LumeMemoryRecordRepository r = store(
      delay: const Duration(milliseconds: 220),
    );
    addTearDown(r.dispose);
    int heard = 0;
    r.addListener(() => heard++);
    expect(r.open('expenses').status, LumeCollectionStatus.loading);
    await tester.pump(const Duration(milliseconds: 219));
    expect(r.view('expenses').status, LumeCollectionStatus.loading);
    await tester.pump(const Duration(milliseconds: 1));
    final LumeCollectionView v = r.view('expenses');
    expect(v.status, LumeCollectionStatus.ready);
    expect(v.items.map((LumeRecord x) => x['title']), <String>[
      '@groceries',
      '@taxi',
    ]);
    expect(v.items.every((LumeRecord x) => x.seeded && x.version == 1), isTrue);
    expect(heard, 1);
  });

  test(
    'a collection with no seeds opens empty; ids are counted, not random',
    () {
      final LumeMemoryRecordRepository r = store();
      expect(r.open('notes').items, isEmpty);
      expect(
        r.create('notes', <String, Object?>{'title': 'a'}).record!.id,
        'not-1',
      );
      expect(
        r.create('notes', <String, Object?>{'title': 'b'}).record!.id,
        'not-2',
      );
      expect(r.view('notes').items.first['title'], 'b');
      expect(r.durable, isFalse);
    },
  );

  test('an update raises the version; a stale version is a conflict', () {
    final LumeMemoryRecordRepository r = store();
    final LumeRecord first = r.open('expenses').items.first;
    final LumeWriteResult ok = r.update('expenses', first.id, <String, Object?>{
      'amount': 40,
    }, expectVersion: 1);
    expect(ok.ok, isTrue);
    expect(ok.record!.version, 2);
    expect(ok.record!['title'], '@groceries');
    expect(ok.record!.seeded, isFalse);

    final LumeWriteResult stale = r.update(
      'expenses',
      first.id,
      <String, Object?>{'amount': 50},
      expectVersion: 1,
    );
    expect(stale.failure, LumeWriteFailure.conflict);
    expect(stale.current!.version, 2);
    expect(r.get('expenses', first.id)!['amount'], 40);
  });

  test('undo reverses the last write and only that one', () {
    final LumeMemoryRecordRepository r = store();
    final List<LumeRecord> before = r.open('expenses').items;
    final LumeWriteResult gone = r.remove('expenses', before.first.id);
    expect(r.view('expenses').items, hasLength(1));
    final LumeUndone? back = r.undo();
    expect(back!.kind, LumeUndoKind.delete);
    expect(r.view('expenses').items.first.id, before.first.id);
    expect(gone.record!.id, before.first.id);
    expect(r.undo(), isNull, reason: 'one step, not a stack');

    r.create('expenses', <String, Object?>{'title': 'Tea'});
    r.forgetUndo();
    expect(r.canUndo, isFalse);
    expect(r.undo(), isNull);
  });

  test('offline writes are queued; a refused write changes nothing', () {
    final LumeMemoryRecordRepository r = store()..offline = true;
    expect(r.open('expenses').status, LumeCollectionStatus.offline);
    expect(
      r.create('expenses', <String, Object?>{'title': 'x'}).record!.queued,
      isTrue,
    );
    r.refuseWrites = true;
    final int n = r.view('expenses').items.length;
    expect(
      r.create('expenses', <String, Object?>{'title': 'y'}).failure,
      LumeWriteFailure.storage,
    );
    expect(r.view('expenses').items, hasLength(n));
  });

  test('an unreadable collection is an error until retried', () {
    final LumeMemoryRecordRepository r = store()..unreadable.add('expenses');
    expect(r.open('expenses').status, LumeCollectionStatus.error);
    r.unreadable.clear();
    expect(r.retry('expenses').status, LumeCollectionStatus.ready);
  });

  test('a tick keeps a sample record a sample; a saved form claims it', () {
    // `records.js` keeps `_seed` unless the form's save clears it, so a sample
    // record ticked from its row is still read in the reader's language.
    final LumeMemoryRecordRepository r = store();
    final LumeRecord seeded = r.open('expenses').items.first;
    expect(seeded.seeded, isTrue);
    final LumeRecord ticked = r.update('expenses', seeded.id, <String, Object?>{
      'done': true,
    }, claim: false).record!;
    expect(ticked.seeded, isTrue);
    expect(ticked.version, 2);
    final LumeRecord saved = r.update('expenses', seeded.id, <String, Object?>{
      'title': 'Milk',
    }).record!;
    expect(saved.seeded, isFalse);
  });
}

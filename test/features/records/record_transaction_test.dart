/// The record layer's multi-record transaction: one snapshot, several
/// collections, all or nothing, one notification, safe retries.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_model.dart';
import 'package:lume/features/records/domain/record_transaction.dart';

void main() {
  late LumeMemoryRecordRepository store;
  late int notified;
  DateTime clock = DateTime.utc(2026, 9, 7, 10);

  setUp(() {
    clock = DateTime.utc(2026, 9, 7, 10);
    store = LumeMemoryRecordRepository(hydrateDelay: null, now: () => clock)
      ..open('parties')
      ..open('entries')
      ..open('allocations');
    notified = 0;
    store.addListener(() => notified++);
  });

  tearDown(() => store.dispose());

  /// A small committed world: one party, one entry.
  LumeTxReceipt seed() => store.run<void>((LumeRecordTx tx) {
    tx.create('parties', 'p1', <String, Object?>{'name': 'Ahmed'});
    tx.create('entries', 'e1', <String, Object?>{'party': 'p1', 'minor': 100});
  }).receipt!;

  LumeTxFailureKind? kind(LumeTxResult<Object?> r) => r.failure?.kind;

  test('a successful commit across three collections, notified once', () {
    final LumeTxResult<String> r = store.run<String>((LumeRecordTx tx) {
      tx.create('parties', 'p1', <String, Object?>{'name': 'Ahmed'});
      tx.create('entries', 'e1', <String, Object?>{'party': 'p1'});
      tx.create('allocations', 'a1', <String, Object?>{'entry': 'e1'});
      return 'done';
    });
    expect(r.ok, isTrue);
    expect(r.value, 'done');
    expect(r.receipt!.changes.map((LumeTxChange c) => c.id), <String>[
      'p1',
      'e1',
      'a1',
    ]);
    expect(store.get('parties', 'p1')!.version, 1);
    expect(store.get('allocations', 'a1'), isNotNull);
    expect(notified, 1);
  });

  test('the transaction reads its own writes, in one snapshot', () {
    seed();
    store.run<void>((LumeRecordTx tx) {
      tx.update('parties', 'p1', <String, Object?>{
        'name': 'Ahmed K',
      }, expectVersion: 1);
      expect(tx.get('parties', 'p1')!['name'], 'Ahmed K');
      // Outside the transaction, nothing yet.
      expect(store.get('parties', 'p1')!['name'], 'Ahmed');
      tx.create('parties', 'p2', <String, Object?>{'name': 'Sara'});
      expect(tx.all('parties').map((LumeRecord r) => r.id), <String>[
        'p2',
        'p1',
      ]);
    });
    expect(store.get('parties', 'p1')!['name'], 'Ahmed K');
  });

  group('commit none', () {
    test('a family rule refused: nothing written, nobody told', () {
      seed();
      final String before = store.debugDump();
      notified = 0;
      final LumeTxResult<void> r = store.run<void>((LumeRecordTx tx) {
        tx.create('allocations', 'a1', <String, Object?>{});
        tx.reject('overpayment');
      });
      expect(kind(r), LumeTxFailureKind.rejected);
      expect(r.failure!.detail, 'overpayment');
      expect(store.debugDump(), before);
      expect(notified, 0);
    });

    test('a stale version on one of several records', () {
      seed();
      final String before = store.debugDump();
      notified = 0;
      final LumeTxResult<void> r = store.run<void>((LumeRecordTx tx) {
        tx.create('allocations', 'a1', <String, Object?>{});
        tx.update('parties', 'p1', <String, Object?>{
          'name': 'x',
        }, expectVersion: 1);
        tx.update('entries', 'e1', <String, Object?>{}, expectVersion: 7);
      });
      expect(kind(r), LumeTxFailureKind.conflict);
      expect(r.failure!.id, 'e1');
      expect(r.failure!.current!.version, 1);
      expect(store.debugDump(), before);
      expect(notified, 0);
    });

    test('a missing record', () {
      final LumeTxResult<void> r = store.run<void>(
        (LumeRecordTx tx) => tx.delete('entries', 'nope', expectVersion: 1),
      );
      expect(kind(r), LumeTxFailureKind.missing);
    });

    test('a collection not yet read is unavailable, not empty', () {
      final LumeTxResult<void> r = store.run<void>(
        (LumeRecordTx tx) => tx.all('unopened'),
      );
      expect(kind(r), LumeTxFailureKind.unavailable);
      expect(r.failure!.collection, 'unopened');
    });

    for (final (String what, int failAt) in <(String, int)>[
      ('after staged creates', 2),
      ('after staged updates', 4),
      ('after staged deletes', 5),
    ]) {
      test('storage failing $what: byte-equivalent prior state', () {
        seed();
        store.run<void>((LumeRecordTx tx) {
          tx.create('allocations', 'a0', <String, Object?>{'n': 0});
        });
        final String before = store.debugDump();
        notified = 0;
        store.publishFault = (LumeTxChange c, int i) {
          if (i == failAt) throw StateError('disk full');
        };
        final LumeTxResult<void> r = store.run<void>((LumeRecordTx tx) {
          tx.create('allocations', 'a1', <String, Object?>{});
          tx.create('allocations', 'a2', <String, Object?>{});
          tx.update('parties', 'p1', <String, Object?>{
            'name': 'x',
          }, expectVersion: 1);
          tx.update('entries', 'e1', <String, Object?>{}, expectVersion: 1);
          tx.delete('allocations', 'a0', expectVersion: 1);
          tx.create('allocations', 'a3', <String, Object?>{});
        });
        expect(kind(r), LumeTxFailureKind.storage);
        expect(store.debugDump(), before);
        expect(notified, 0);
        expect(store.get('allocations', 'a1'), isNull);
        expect(store.get('allocations', 'a0'), isNotNull);
      });
    }

    test('the store refusing writes', () {
      store.refuseWrites = true;
      final LumeTxResult<void> r = store.run<void>((LumeRecordTx tx) {
        tx.create('parties', 'p1', <String, Object?>{});
      });
      expect(kind(r), LumeTxFailureKind.storage);
      expect(store.view('parties').items, isEmpty);
    });
  });

  test('observers see before or after, never between', () {
    seed();
    final List<String> seen = <String>[];
    store.addListener(() {
      seen.add(
        '${store.get('parties', 'p1')!['name']}/'
        '${store.get('entries', 'e1')!['minor']}',
      );
    });
    store.run<void>((LumeRecordTx tx) {
      tx.update('parties', 'p1', <String, Object?>{
        'name': 'B',
      }, expectVersion: 1);
      expect(seen, isEmpty);
      tx.update('entries', 'e1', <String, Object?>{
        'party': 'p1',
        'minor': 200,
      }, expectVersion: 1);
      expect(seen, isEmpty);
    });
    expect(seen, <String>['B/200']);
  });

  group('concurrency', () {
    test('two transactions write one record: the second conflicts', () {
      seed();
      final LumeRecordTx a = store.begin();
      final LumeRecordTx b = store.begin();
      a.update('parties', 'p1', <String, Object?>{'n': 'a'}, expectVersion: 1);
      b.update('parties', 'p1', <String, Object?>{'n': 'b'}, expectVersion: 1);
      expect(store.commit<void>(a, null).ok, isTrue);
      final LumeTxResult<void> second = store.commit<void>(b, null);
      expect(kind(second), LumeTxFailureKind.conflict);
      expect(store.get('parties', 'p1')!['n'], 'a');
    });

    test('a collection listed then changed by another: conflict', () {
      seed();
      final LumeRecordTx a = store.begin();
      final int count = a.all('entries').length;
      store.run<void>((LumeRecordTx tx) {
        tx.create('entries', 'e2', <String, Object?>{});
      });
      a.create('allocations', 'a1', <String, Object?>{'over': count});
      expect(kind(store.commit<void>(a, null)), LumeTxFailureKind.conflict);
      expect(store.get('allocations', 'a1'), isNull);
    });

    test('a single-record write outside a transaction also conflicts', () {
      seed();
      final LumeRecordTx a = store.begin();
      a.all('parties');
      store.create('parties', <String, Object?>{'name': 'legacy'});
      a.create('parties', 'p9', <String, Object?>{});
      expect(kind(store.commit<void>(a, null)), LumeTxFailureKind.conflict);
    });
  });

  group('ids', () {
    test('a create names its id; an id held or ever held is refused', () {
      seed();
      expect(
        kind(
          store.run<void>((LumeRecordTx tx) {
            tx.create('parties', 'p1', <String, Object?>{});
          }),
        ),
        LumeTxFailureKind.duplicateId,
      );
      store.run<void>(
        (LumeRecordTx tx) => tx.delete('entries', 'e1', expectVersion: 1),
      );
      expect(
        kind(
          store.run<void>((LumeRecordTx tx) {
            tx.create('entries', 'e1', <String, Object?>{});
          }),
        ),
        LumeTxFailureKind.duplicateId,
      );
    });
  });

  test('insert carries a record in with its own id, version and times; '
      'a held or once-held id is refused', () {
    final LumeRecord carried = LumeRecord(
      id: 'x1',
      fields: const <String, Object?>{'n': 1},
      version: 4,
      createdAt: DateTime.utc(2020),
      updatedAt: DateTime.utc(2021),
    );
    expect(
      store.run<void>((LumeRecordTx tx) => tx.insert('entries', carried)).ok,
      isTrue,
    );
    final LumeRecord got = store.get('entries', 'x1')!;
    expect(got.version, 4);
    expect(got.createdAt, DateTime.utc(2020));
    expect(
      kind(store.run<void>((LumeRecordTx tx) => tx.insert('entries', carried))),
      LumeTxFailureKind.duplicateId,
    );
  });

  group('undo', () {
    test('reverting a delete restores the same ids, exactly', () {
      final LumeTxReceipt made = seed();
      final LumeRecord e1 = store.get('entries', 'e1')!;
      final LumeTxReceipt removed = store.run<void>((LumeRecordTx tx) {
        tx.delete('entries', 'e1', expectVersion: 1);
        tx.update('parties', 'p1', <String, Object?>{
          'name': 'Ahmed',
          'count': 0,
        }, expectVersion: 1);
      }).receipt!;
      expect(store.get('entries', 'e1'), isNull);
      notified = 0;
      expect(store.revert(removed).ok, isTrue);
      expect(notified, 1);
      final LumeRecord back = store.get('entries', 'e1')!;
      expect(back.id, e1.id);
      expect(back.version, e1.version);
      expect(back.fields, e1.fields);
      expect(store.get('parties', 'p1')!.fields, <String, Object?>{
        'name': 'Ahmed',
      });
      expect(made.changes, hasLength(2));
    });

    test('reverting a create removes it; the id is never made again', () {
      final LumeTxReceipt made = seed();
      expect(store.revert(made).ok, isTrue);
      expect(store.get('parties', 'p1'), isNull);
      expect(
        kind(
          store.run<void>((LumeRecordTx tx) {
            tx.create('parties', 'p1', <String, Object?>{});
          }),
        ),
        LumeTxFailureKind.duplicateId,
      );
    });

    test('an undo over a changed record is a conflict, and changes '
        'nothing', () {
      final LumeTxReceipt made = seed();
      store.run<void>((LumeRecordTx tx) {
        tx.update('parties', 'p1', <String, Object?>{
          'name': 'later',
        }, expectVersion: 1);
      });
      final String before = store.debugDump();
      expect(kind(store.revert(made)), LumeTxFailureKind.conflict);
      expect(store.debugDump(), before);
    });
  });

  group('idempotency', () {
    LumeTxResult<int> add(String key, String payload) => store.run<int>(
      (LumeRecordTx tx) {
        tx.create('entries', 'e-$payload', <String, Object?>{'p': payload});
        return tx.all('entries').length;
      },
      idempotencyKey: key,
      fingerprint: payload,
    );

    test('a retried command is applied once and answered again', () {
      final LumeTxResult<int> first = add('k1', 'x');
      expect(first.ok, isTrue);
      notified = 0;
      final LumeTxResult<int> again = add('k1', 'x');
      expect(again.ok, isTrue);
      expect(again.value, first.value);
      expect(again.receipt!.replayed, isTrue);
      expect(store.view('entries').items, hasLength(1));
      expect(notified, 0);
    });

    test('the same key with a different payload is refused', () {
      add('k1', 'x');
      final LumeTxResult<int> other = add('k1', 'y');
      expect(kind(other), LumeTxFailureKind.idempotencyMismatch);
      expect(store.get('entries', 'e-y'), isNull);
    });

    test('a failed command leaves its key free to try again', () {
      store.refuseWrites = true;
      expect(add('k2', 'x').ok, isFalse);
      store.refuseWrites = false;
      expect(add('k2', 'x').ok, isTrue);
    });
  });

  test('deterministic: the same commands give the same store', () {
    String play() {
      final LumeMemoryRecordRepository s = LumeMemoryRecordRepository(
        hydrateDelay: null,
        now: () => DateTime.utc(2026, 9, 7),
      )..open('entries');
      for (int i = 0; i < 5; i++) {
        s.run<void>((LumeRecordTx tx) {
          tx.create('entries', 'e$i', <String, Object?>{'i': i});
          if (i > 0) tx.delete('entries', 'e${i - 1}', expectVersion: 1);
        });
      }
      final String out = s.debugDump();
      s.dispose();
      return out;
    }

    expect(play(), play());
  });

  test('a finished transaction cannot be used or committed again', () {
    final LumeRecordTx tx = store.begin();
    store.commit<void>(tx, null);
    expect(() => store.commit<void>(tx, null), throwsStateError);
    expect(() => tx.all('parties'), throwsStateError);
  });
}

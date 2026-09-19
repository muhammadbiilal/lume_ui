/// The record store for this build: in memory, and honest about it.
///
/// A port of `records.js` in everything but the disk. Collections are read
/// lazily, seeded once, versioned on every update, and undoable one step.
/// The guide's states are reachable for real rather than mocked: the first
/// open is a loading state, [offline] marks writes as queued, [refuseWrites]
/// makes the store fail a write, and [unreadable] makes a collection fail to
/// load.
///
/// [durable] is `false`: nothing here outlives the process (C74).
///
/// Transactions ([LumeRecordTransactions]) stage their writes over a
/// snapshot and publish copy-on-write: the collections they touch are
/// copied, the staged changes applied to the copies, and the copies swapped
/// in only once every change has been applied — so a failure part-way leaves
/// the live state exactly as it was. [publishFault] injects that failure in
/// tests.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/record_model.dart';
import '../domain/record_repository.dart';
import '../domain/record_transaction.dart';

/// The demonstration records a collection opens with the first time, as field
/// maps, or `null` for a collection that starts empty.
typedef LumeRecordSeeds =
    List<Map<String, Object?>>? Function(String collection, DateTime now);

class LumeMemoryRecordRepository extends ChangeNotifier
    implements LumeRecordRepository {
  LumeMemoryRecordRepository({
    LumeRecordSeeds? seeds,
    DateTime Function()? now,
    this.hydrateDelay = const Duration(milliseconds: 220),
  }) : _seeds = seeds ?? _noSeeds,
       _now = now ?? DateTime.now;

  static List<Map<String, Object?>>? _noSeeds(String c, DateTime n) => null;

  final LumeRecordSeeds _seeds;
  final DateTime Function() _now;

  /// How long the first read of a collection takes. `records.js` waits 220 ms
  /// so the skeleton is a frame rather than a flicker. `null` reads at once,
  /// which is what a widget test that is not about loading wants.
  final Duration? hydrateDelay;

  /// `navigator.onLine === false`. Writes made while this is set are queued.
  bool offline = false;

  /// The store refuses writes, as browser storage does with site data blocked.
  bool refuseWrites = false;

  /// Collections whose stored form cannot be read.
  final Set<String> unreadable = <String>{};

  final Map<String, List<LumeRecord>> _cache = <String, List<LumeRecord>>{};
  final Set<String> _loading = <String>{};
  final Set<String> _failed = <String>{};
  final Map<String, int> _counters = <String, int>{};
  _UndoEntry? _undo;
  final List<Timer> _timers = <Timer>[];

  /// Rises with every published change, per collection and in all.
  final Map<String, int> _collectionRevision = <String, int>{};
  int _revision = 0;

  /// Every id each collection has ever held — a deleted id is never made
  /// again.
  final Map<String, Set<String>> _used = <String, Set<String>>{};

  /// Committed commands by idempotency key.
  final Map<String, _Idempotent> _idempotent = <String, _Idempotent>{};

  /// Called as each staged change is applied to the copy a commit will
  /// publish; throwing fails the commit with nothing written. Tests only.
  @visibleForTesting
  void Function(LumeTxChange change, int index)? publishFault;

  void _touch(String collection) {
    _collectionRevision[collection] =
        (_collectionRevision[collection] ?? 0) + 1;
    _revision++;
  }

  @override
  bool get durable => false;

  @override
  bool get isOffline => offline;

  /// `newId(prefix)` — the collection's first three letters and a count.
  /// Counted rather than random, so an id a test or a screenshot shows is the
  /// same every time; unique within a collection for the life of the store.
  String _newId(String collection) {
    final int n = (_counters[collection] ?? 0) + 1;
    _counters[collection] = n;
    final String prefix = collection.length >= 3
        ? collection.substring(0, 3)
        : collection;
    return '$prefix-$n';
  }

  LumeRecord _stamp(
    String collection,
    Map<String, Object?> fields, {
    int index = 0,
    bool seeded = false,
  }) {
    final DateTime at = _now().subtract(Duration(seconds: index));
    final String id = _newId(collection);
    (_used[collection] ??= <String>{}).add(id);
    return LumeRecord(
      id: id,
      fields: Map<String, Object?>.unmodifiable(fields),
      version: 1,
      createdAt: at,
      updatedAt: at,
      seeded: seeded,
      queued: !seeded && offline,
    );
  }

  void _hydrate(String collection) {
    if (_loading.contains(collection)) return;
    _loading.add(collection);

    void finish() {
      _loading.remove(collection);
      if (unreadable.contains(collection)) {
        _failed.add(collection);
      } else {
        final DateTime now = _now();
        final List<Map<String, Object?>> seeds =
            _seeds(collection, now) ?? const <Map<String, Object?>>[];
        _cache[collection] = <LumeRecord>[
          for (int i = 0; i < seeds.length; i++)
            _stamp(collection, seeds[i], index: i, seeded: true),
        ];
      }
      notifyListeners();
    }

    if (hydrateDelay == null) {
      _loading.remove(collection);
      if (unreadable.contains(collection)) {
        _failed.add(collection);
      } else {
        final List<Map<String, Object?>> seeds =
            _seeds(collection, _now()) ?? const <Map<String, Object?>>[];
        _cache[collection] = <LumeRecord>[
          for (int i = 0; i < seeds.length; i++)
            _stamp(collection, seeds[i], index: i, seeded: true),
        ];
      }
      return;
    }
    _timers.add(Timer(hydrateDelay!, finish));
  }

  @override
  LumeCollectionView open(String collection) {
    if (!_cache.containsKey(collection) && !_failed.contains(collection)) {
      _hydrate(collection);
    }
    return view(collection);
  }

  @override
  LumeCollectionView view(String collection) {
    if (_failed.contains(collection)) {
      return const LumeCollectionView(LumeCollectionStatus.error);
    }
    final List<LumeRecord>? items = _cache[collection];
    if (items == null) {
      return const LumeCollectionView(LumeCollectionStatus.loading);
    }
    return LumeCollectionView(
      offline ? LumeCollectionStatus.offline : LumeCollectionStatus.ready,
      List<LumeRecord>.unmodifiable(items),
    );
  }

  @override
  LumeRecord? get(String collection, String id) {
    for (final LumeRecord r in _cache[collection] ?? const <LumeRecord>[]) {
      if (r.id == id) return r;
    }
    return null;
  }

  int _indexOf(String collection, String id) =>
      (_cache[collection] ?? const <LumeRecord>[]).indexWhere(
        (LumeRecord r) => r.id == id,
      );

  @override
  LumeWriteResult create(String collection, Map<String, Object?> fields) {
    if (refuseWrites) {
      return const LumeWriteResult.failed(LumeWriteFailure.storage);
    }
    final LumeRecord record = _stamp(collection, fields);
    (_cache[collection] ??= <LumeRecord>[]).insert(0, record);
    _touch(collection);
    _undo = _UndoEntry.create(collection, record.id);
    notifyListeners();
    return LumeWriteResult.ok(record);
  }

  @override
  LumeWriteResult update(
    String collection,
    String id,
    Map<String, Object?> fields, {
    int? expectVersion,
    bool claim = true,
  }) {
    final int at = _indexOf(collection, id);
    if (at == -1) return const LumeWriteResult.failed(LumeWriteFailure.missing);
    final LumeRecord before = _cache[collection]![at];
    if (expectVersion != null && before.version != expectVersion) {
      return LumeWriteResult.failed(LumeWriteFailure.conflict, current: before);
    }
    if (refuseWrites) {
      return const LumeWriteResult.failed(LumeWriteFailure.storage);
    }
    final LumeRecord after = before.copyWith(
      fields: Map<String, Object?>.unmodifiable(<String, Object?>{
        ...before.fields,
        ...fields,
      }),
      version: before.version + 1,
      updatedAt: _now(),
      queued: offline,
      // A record the reader has saved is theirs from here on (`_seed = 0`);
      // a tick writes no words and leaves it as it was.
      seeded: fields.isEmpty || !claim ? before.seeded : false,
    );
    _cache[collection]![at] = after;
    _touch(collection);
    _undo = _UndoEntry.update(collection, id, before);
    notifyListeners();
    return LumeWriteResult.ok(after);
  }

  @override
  LumeWriteResult remove(String collection, String id) {
    final int at = _indexOf(collection, id);
    if (at == -1) return const LumeWriteResult.failed(LumeWriteFailure.missing);
    if (refuseWrites) {
      return const LumeWriteResult.failed(LumeWriteFailure.storage);
    }
    final LumeRecord record = _cache[collection]!.removeAt(at);
    _touch(collection);
    _undo = _UndoEntry.delete(collection, record, at);
    notifyListeners();
    return LumeWriteResult.ok(record);
  }

  @override
  LumeUndone? undo() {
    final _UndoEntry? entry = _undo;
    _undo = null;
    if (entry == null) return null;
    final List<LumeRecord> items = _cache[entry.collection] ??= <LumeRecord>[];
    _touch(entry.collection);
    switch (entry.kind) {
      case LumeUndoKind.create:
        final int at = _indexOf(entry.collection, entry.id!);
        if (at == -1) return null;
        items.removeAt(at);
        notifyListeners();
        return LumeUndone(LumeUndoKind.create, entry.collection);
      case LumeUndoKind.update:
        final int at = _indexOf(entry.collection, entry.id!);
        if (at == -1) return null;
        items[at] = entry.record!;
        notifyListeners();
        return LumeUndone(LumeUndoKind.update, entry.collection, entry.record);
      case LumeUndoKind.delete:
        items.insert(
          entry.index!.clamp(0, items.length).toInt(),
          entry.record!,
        );
        notifyListeners();
        return LumeUndone(LumeUndoKind.delete, entry.collection, entry.record);
    }
  }

  @override
  bool get canUndo => _undo != null;

  @override
  void forgetUndo() => _undo = null;

  @override
  LumeCollectionView retry(String collection) {
    _failed.remove(collection);
    _cache.remove(collection);
    return open(collection);
  }

  // ---- transactions -----------------------------------------------------

  @override
  LumeRecordTx begin() => _MemoryTx(this, <String, List<LumeRecord>>{
    for (final MapEntry<String, List<LumeRecord>> e in _cache.entries)
      e.key: List<LumeRecord>.unmodifiable(e.value),
  }, Map<String, int>.of(_collectionRevision));

  @override
  LumeTxResult<T> run<T>(
    T Function(LumeRecordTx tx) body, {
    String? idempotencyKey,
    String? fingerprint,
  }) {
    final _Idempotent? prior = idempotencyKey == null
        ? null
        : _idempotent[idempotencyKey];
    if (prior != null) return prior.replay<T>(fingerprint);
    final _MemoryTx tx = begin() as _MemoryTx;
    final T value;
    try {
      value = body(tx);
    } on LumeTxFailure catch (f) {
      tx._closed = true;
      return LumeTxResult<T>.failed(f);
    }
    return commit<T>(
      tx,
      value,
      idempotencyKey: idempotencyKey,
      fingerprint: fingerprint,
    );
  }

  @override
  LumeTxResult<T> commit<T>(
    LumeRecordTx tx,
    T value, {
    String? idempotencyKey,
    String? fingerprint,
  }) {
    final _MemoryTx t = tx as _MemoryTx;
    if (t._closed) throw StateError('transaction already finished');
    t._closed = true;
    final _Idempotent? prior = idempotencyKey == null
        ? null
        : _idempotent[idempotencyKey];
    if (prior != null) return prior.replay<T>(fingerprint);

    // Everything read must still be as it was read.
    for (final MapEntry<String, int> scan in t._scans.entries) {
      if ((_collectionRevision[scan.key] ?? 0) != scan.value) {
        return LumeTxResult<T>.failed(
          LumeTxFailure(LumeTxFailureKind.conflict, collection: scan.key),
        );
      }
    }
    for (final MapEntry<(String, String), int?> read in t._reads.entries) {
      final LumeRecord? live = get(read.key.$1, read.key.$2);
      if (live?.version != read.value) {
        return LumeTxResult<T>.failed(
          LumeTxFailure(
            LumeTxFailureKind.conflict,
            collection: read.key.$1,
            id: read.key.$2,
            current: live,
          ),
        );
      }
    }
    if (refuseWrites) {
      return LumeTxResult<T>.failed(
        const LumeTxFailure(LumeTxFailureKind.storage),
      );
    }

    // Apply to copies; publish only once all of it applied.
    final Map<String, List<LumeRecord>> next = <String, List<LumeRecord>>{};
    final List<LumeTxChange> changes = <LumeTxChange>[];
    try {
      for (final (String c, String id) in t._order) {
        final List<LumeRecord> list = next[c] ??= List<LumeRecord>.of(
          _cache[c]!,
        );
        final int at = list.indexWhere((LumeRecord r) => r.id == id);
        final LumeRecord? before = at == -1 ? null : list[at];
        final LumeRecord? after = t._writes[(c, id)];
        if (before == null && after == null) continue;
        final LumeTxChange change = LumeTxChange(c, id, before, after);
        publishFault?.call(change, changes.length);
        if (after == null) {
          list.removeAt(at);
        } else if (before == null) {
          final int? was = t._restoredAt[(c, id)];
          list.insert(
            was == null || was < 0 ? (was == null ? 0 : list.length) : was,
            after,
          );
        } else {
          list[at] = after;
        }
        changes.add(change);
      }
    } on Object catch (e) {
      return LumeTxResult<T>.failed(
        LumeTxFailure(LumeTxFailureKind.storage, detail: e),
      );
    }

    for (final MapEntry<String, List<LumeRecord>> e in next.entries) {
      _cache[e.key] = e.value;
      _touch(e.key);
    }
    for (final LumeTxChange c in changes) {
      if (c.after != null) (_used[c.collection] ??= <String>{}).add(c.id);
    }
    final LumeTxReceipt receipt = LumeTxReceipt(
      _revision,
      List<LumeTxChange>.unmodifiable(changes),
    );
    if (idempotencyKey != null) {
      _idempotent[idempotencyKey] = _Idempotent(fingerprint, value, receipt);
    }
    if (changes.isNotEmpty) {
      // A one-step Undo of an earlier single write would now undo past this.
      _undo = null;
      notifyListeners();
    }
    return LumeTxResult<T>.ok(value, receipt);
  }

  @override
  LumeTxResult<void> revert(LumeTxReceipt receipt) =>
      run<void>((LumeRecordTx tx) {
        final _MemoryTx t = tx as _MemoryTx;
        for (final LumeTxChange c in receipt.changes.reversed) {
          final LumeRecord? live = t.get(c.collection, c.id);
          final LumeTxFailure conflict = LumeTxFailure(
            LumeTxFailureKind.conflict,
            collection: c.collection,
            id: c.id,
            current: live,
          );
          if (c.after == null) {
            if (live != null) throw conflict;
            t._restore(c.collection, c.before!);
          } else if (live == null || live.version != c.after!.version) {
            throw conflict;
          } else if (c.before == null) {
            t.delete(c.collection, c.id, expectVersion: live.version);
          } else {
            t.update(
              c.collection,
              c.id,
              c.before!.fields,
              expectVersion: live.version,
            );
          }
        }
      });

  /// Every collection's records, in a canonical text — for a test to say
  /// that a failed commit left the store exactly as it was.
  @visibleForTesting
  String debugDump() {
    final StringBuffer out = StringBuffer();
    for (final String c in (_cache.keys.toList()..sort())) {
      out.writeln('[$c] r${_collectionRevision[c] ?? 0}');
      for (final LumeRecord r in _cache[c]!) {
        final List<String> keys = r.fields.keys.toList()..sort();
        out.writeln(
          '${r.id} v${r.version} ${r.createdAt.toIso8601String()} '
          '${r.updatedAt.toIso8601String()} ${r.seeded} ${r.queued} '
          '{${keys.map((String k) => '$k=${r.fields[k]}').join(', ')}}',
        );
      }
    }
    return out.toString();
  }

  @override
  void dispose() {
    for (final Timer t in _timers) {
      t.cancel();
    }
    super.dispose();
  }
}

/// A committed command, kept to answer its retry.
@immutable
class _Idempotent {
  const _Idempotent(this.fingerprint, this.value, this.receipt);

  final String? fingerprint;
  final Object? value;
  final LumeTxReceipt receipt;

  LumeTxResult<T> replay<T>(String? asked) => asked == fingerprint
      ? LumeTxResult<T>.ok(
          value as T,
          LumeTxReceipt(receipt.revision, receipt.changes, replayed: true),
        )
      : LumeTxResult<T>.failed(
          const LumeTxFailure(LumeTxFailureKind.idempotencyMismatch),
        );
}

/// A transaction over a snapshot, with its own write set.
class _MemoryTx implements LumeRecordTx {
  _MemoryTx(this._store, this._snapshot, this._revisions);

  final LumeMemoryRecordRepository _store;
  final Map<String, List<LumeRecord>> _snapshot;
  final Map<String, int> _revisions;

  /// Collections listed, with the revision seen.
  final Map<String, int> _scans = <String, int>{};

  /// Records read, with the version seen (`null`: seen absent).
  final Map<(String, String), int?> _reads = <(String, String), int?>{};

  /// Staged writes (`null`: deleted), and the order they were first made.
  final Map<(String, String), LumeRecord?> _writes =
      <(String, String), LumeRecord?>{};
  final List<(String, String)> _order = <(String, String)>[];

  /// Where a restored record stood before it was removed.
  final Map<(String, String), int> _restoredAt = <(String, String), int>{};

  bool _closed = false;

  List<LumeRecord> _base(String collection) {
    if (_closed) throw StateError('transaction already finished');
    final List<LumeRecord>? list = _snapshot[collection];
    if (list == null) {
      throw LumeTxFailure(
        LumeTxFailureKind.unavailable,
        collection: collection,
      );
    }
    return list;
  }

  void _stage(String collection, String id, LumeRecord? record) {
    final (String, String) key = (collection, id);
    if (!_writes.containsKey(key)) _order.add(key);
    _writes[key] = record;
  }

  @override
  LumeRecord? get(String collection, String id) {
    final List<LumeRecord> base = _base(collection);
    final (String, String) key = (collection, id);
    if (_writes.containsKey(key)) return _writes[key];
    LumeRecord? found;
    for (final LumeRecord r in base) {
      if (r.id == id) found = r;
    }
    _reads.putIfAbsent(key, () => found?.version);
    return found;
  }

  @override
  List<LumeRecord> all(String collection) {
    final List<LumeRecord> base = _base(collection);
    _scans.putIfAbsent(collection, () => _revisions[collection] ?? 0);
    final Set<String> inBase = <String>{for (final LumeRecord r in base) r.id};
    return <LumeRecord>[
      // Created here, newest first.
      for (final (String c, String id) in _order.reversed)
        if (c == collection && !inBase.contains(id) && _writes[(c, id)] != null)
          _writes[(c, id)]!,
      for (final LumeRecord r in base)
        if (!_writes.containsKey((collection, r.id)))
          r
        else if (_writes[(collection, r.id)] != null)
          _writes[(collection, r.id)]!,
    ];
  }

  @override
  LumeRecord create(String collection, String id, Map<String, Object?> fields) {
    if (get(collection, id) != null ||
        (_store._used[collection]?.contains(id) ?? false)) {
      throw LumeTxFailure(
        LumeTxFailureKind.duplicateId,
        collection: collection,
        id: id,
      );
    }
    final DateTime now = _store._now();
    final LumeRecord record = LumeRecord(
      id: id,
      fields: Map<String, Object?>.unmodifiable(fields),
      version: 1,
      createdAt: now,
      updatedAt: now,
      queued: _store.offline,
    );
    _stage(collection, id, record);
    return record;
  }

  LumeRecord _current(String collection, String id, int expectVersion) {
    final LumeRecord? current = get(collection, id);
    if (current == null) {
      throw LumeTxFailure(
        LumeTxFailureKind.missing,
        collection: collection,
        id: id,
      );
    }
    if (current.version != expectVersion) {
      throw LumeTxFailure(
        LumeTxFailureKind.conflict,
        collection: collection,
        id: id,
        current: current,
      );
    }
    return current;
  }

  @override
  LumeRecord update(
    String collection,
    String id,
    Map<String, Object?> fields, {
    required int expectVersion,
  }) {
    final LumeRecord before = _current(collection, id, expectVersion);
    final LumeRecord after = before.copyWith(
      fields: Map<String, Object?>.unmodifiable(fields),
      version: before.version + 1,
      updatedAt: _store._now(),
      seeded: false,
      queued: _store.offline,
    );
    _stage(collection, id, after);
    return after;
  }

  @override
  void delete(String collection, String id, {required int expectVersion}) {
    _current(collection, id, expectVersion);
    _stage(collection, id, null);
  }

  /// Put back a removed record exactly as it was — its id, its version —
  /// where it stood among the others (newest first).
  void _restore(String collection, LumeRecord record) {
    final List<LumeRecord> base = _base(collection);
    _restoredAt[(collection, record.id)] = base.indexWhere(
      (LumeRecord r) => r.createdAt.isBefore(record.createdAt),
    );
    _stage(collection, record.id, record);
  }

  @override
  Never reject(Object detail) =>
      throw LumeTxFailure(LumeTxFailureKind.rejected, detail: detail);
}

@immutable
class _UndoEntry {
  const _UndoEntry.create(this.collection, String this.id)
    : kind = LumeUndoKind.create,
      record = null,
      index = null;

  const _UndoEntry.update(
    this.collection,
    String this.id,
    LumeRecord this.record,
  ) : kind = LumeUndoKind.update,
      index = null;

  const _UndoEntry.delete(
    this.collection,
    LumeRecord this.record,
    int this.index,
  ) : kind = LumeUndoKind.delete,
      id = null;

  final LumeUndoKind kind;
  final String collection;
  final String? id;
  final LumeRecord? record;
  final int? index;
}

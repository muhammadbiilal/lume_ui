/// Reminders' durable store — the one collection this build persists past
/// the app closing (`REMINDERS_PROPOSAL.md` §2). Every other family still
/// uses [LumeMemoryRecordRepository]; this is not a project-wide migration,
/// and nothing outside `lib/features/reminders/` is wired to it.
///
/// The interface is synchronous (the reference is synchronous
/// `localStorage`); SQLite is not. This keeps an in-memory cache as the
/// live, synchronous source of truth — reads and writes answer from it
/// immediately, exactly like the memory store — and persists underneath as
/// a write-behind: each mutation issues its SQL right away, chained on an
/// internal queue that keeps writes in program order, but the caller never
/// waits on it. **Named plainly**: a hard kill of the process between a
/// cache update and that statement reaching disk could in theory lose the
/// very last write. sqflite issues statements in order on its own single
/// worker, so the exposure is a narrow race, not a routine one — a real,
/// different failure mode from Option B's "everything is lost by design",
/// not a claim that this store can never lose anything (`REMINDERS_PROPOSAL.md`
/// §2).
///
/// The transaction engine below is deliberately the same shape as
/// [LumeMemoryRecordRepository]'s own — copied, not reinvented, because that
/// logic is exactly as tested as it needs to be and a second, divergent
/// implementation of optimistic-concurrency conflict detection is a
/// correctness risk this store does not need to take on.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/values/lume_record_id.dart';
import '../domain/record_model.dart';
import '../domain/record_repository.dart';
import '../domain/record_transaction.dart';

class LumeSqliteRecordRepository extends ChangeNotifier
    implements LumeRecordRepository {
  LumeSqliteRecordRepository({
    required String path,
    DateTime Function()? now,
    Random? random,
    Future<Database> Function(String path)? open,
  }) : _path = path,
       _now = now ?? DateTime.now,
       _random = random ?? Random.secure(),
       _open = open ?? _defaultOpen;

  static const String _table = 'records';

  /// [path] is a bare filename, resolved against the platform's own
  /// databases directory (`getDatabasesPath()` — sqflite's own, needing no
  /// separate path-lookup package). A caller passing its own `open`
  /// (tests, `sqflite_common_ffi`) may give `path` any meaning it wants —
  /// `:memory:` included.
  static Future<Database> _defaultOpen(String path) async {
    final String dir = await getDatabasesPath();
    return openDatabase(
      '$dir/$path',
      version: 1,
      onCreate: (Database db, int version) => db.execute(
        'CREATE TABLE $_table ('
        'collection TEXT NOT NULL, '
        'id TEXT NOT NULL, '
        'fields TEXT NOT NULL, '
        'version INTEGER NOT NULL, '
        'created_at TEXT NOT NULL, '
        'updated_at TEXT NOT NULL, '
        'PRIMARY KEY (collection, id))',
      ),
    );
  }

  final String _path;
  final DateTime Function() _now;
  final Random _random;
  final Future<Database> Function(String path) _open;

  Future<Database>? _db;
  Future<Database> get _database => _db ??= _open(_path);

  /// A disk-full or permissions test double; the store refuses the write
  /// and the cache is left exactly as it was.
  bool refuseWrites = false;

  final Map<String, List<LumeRecord>> _cache = <String, List<LumeRecord>>{};
  final Set<String> _loading = <String>{};
  final Set<String> _failed = <String>{};
  _UndoEntry? _undo;

  final Map<String, int> _collectionRevision = <String, int>{};
  int _revision = 0;
  final Map<String, Set<String>> _used = <String, Set<String>>{};
  final Map<String, _Idempotent> _idempotent = <String, _Idempotent>{};

  /// Keeps persistence in program order without the synchronous API ever
  /// waiting on it.
  Future<void> _writeChain = Future<void>.value();

  void _persist(Future<void> Function(Database db) op) {
    _writeChain = _writeChain
        .then((_) async {
          final Database db = await _database;
          await op(db);
        })
        .catchError((Object _, StackTrace _) {
          // A write-behind failure has nowhere to surface to once the
          // synchronous call has already returned success. The cache stays the
          // live truth; the next successful write for this row corrects disk.
        });
  }

  void _upsertRow(String collection, LumeRecord r) => _persist(
    (Database db) => db.insert(_table, <String, Object?>{
      'collection': collection,
      'id': r.id,
      'fields': jsonEncode(r.fields),
      'version': r.version,
      'created_at': r.createdAt.toIso8601String(),
      'updated_at': r.updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace),
  );

  void _deleteRow(String collection, String id) => _persist(
    (Database db) => db.delete(
      _table,
      where: 'collection = ? AND id = ?',
      whereArgs: <Object?>[collection, id],
    ),
  );

  void _touch(String collection) {
    _collectionRevision[collection] =
        (_collectionRevision[collection] ?? 0) + 1;
    _revision++;
  }

  @override
  bool get durable => true;

  /// A local database is never "queued" the way a synced backend is.
  @override
  bool get isOffline => false;

  String _newId() => LumeRecordId.generate(_random).value;

  LumeRecord _stamp(Map<String, Object?> fields) {
    final DateTime at = _now();
    return LumeRecord(
      id: _newId(),
      fields: Map<String, Object?>.unmodifiable(fields),
      version: 1,
      createdAt: at,
      updatedAt: at,
    );
  }

  Future<void> _hydrate(String collection) async {
    if (_loading.contains(collection)) return;
    _loading.add(collection);
    try {
      final Database db = await _database;
      final List<Map<String, Object?>> rows = await db.query(
        _table,
        where: 'collection = ?',
        whereArgs: <Object?>[collection],
      );
      final List<LumeRecord> items =
          <LumeRecord>[
            for (final Map<String, Object?> row in rows)
              LumeRecord(
                id: row['id']! as String,
                fields: Map<String, Object?>.unmodifiable(
                  Map<String, Object?>.from(
                    jsonDecode(row['fields']! as String)
                        as Map<Object?, Object?>,
                  ),
                ),
                version: row['version']! as int,
                createdAt: DateTime.parse(row['created_at']! as String),
                updatedAt: DateTime.parse(row['updated_at']! as String),
              ),
          ]..sort(
            (LumeRecord a, LumeRecord b) => b.createdAt.compareTo(a.createdAt),
          );
      (_used[collection] ??= <String>{}).addAll(
        items.map((LumeRecord r) => r.id),
      );
      _cache[collection] = items;
    } on Object {
      _failed.add(collection);
    } finally {
      _loading.remove(collection);
      notifyListeners();
    }
  }

  @override
  LumeCollectionView open(String collection) {
    if (!_cache.containsKey(collection) &&
        !_failed.contains(collection) &&
        !_loading.contains(collection)) {
      unawaited(_hydrate(collection));
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
      LumeCollectionStatus.ready,
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
    final LumeRecord record = _stamp(fields);
    (_used[collection] ??= <String>{}).add(record.id);
    (_cache[collection] ??= <LumeRecord>[]).insert(0, record);
    _touch(collection);
    _undo = _UndoEntry.create(collection, record.id);
    _upsertRow(collection, record);
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
    );
    _cache[collection]![at] = after;
    _touch(collection);
    _undo = _UndoEntry.update(collection, id, before);
    _upsertRow(collection, after);
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
    _deleteRow(collection, id);
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
        _deleteRow(entry.collection, entry.id!);
        notifyListeners();
        return LumeUndone(LumeUndoKind.create, entry.collection);
      case LumeUndoKind.update:
        final int at = _indexOf(entry.collection, entry.id!);
        if (at == -1) return null;
        items[at] = entry.record!;
        _upsertRow(entry.collection, entry.record!);
        notifyListeners();
        return LumeUndone(LumeUndoKind.update, entry.collection, entry.record);
      case LumeUndoKind.delete:
        items.insert(
          entry.index!.clamp(0, items.length).toInt(),
          entry.record!,
        );
        _upsertRow(entry.collection, entry.record!);
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
  LumeRecordTx begin() => _SqliteTx(this, <String, List<LumeRecord>>{
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
    final _SqliteTx tx = begin() as _SqliteTx;
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
    final _SqliteTx t = tx as _SqliteTx;
    if (t._closed) throw StateError('transaction already finished');
    t._closed = true;
    final _Idempotent? prior = idempotencyKey == null
        ? null
        : _idempotent[idempotencyKey];
    if (prior != null) return prior.replay<T>(fingerprint);

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

    final Map<String, List<LumeRecord>> next = <String, List<LumeRecord>>{};
    final List<LumeTxChange> changes = <LumeTxChange>[];
    for (final (String c, String id) in t._order) {
      final List<LumeRecord> list = next[c] ??= List<LumeRecord>.of(
        _cache[c] ?? <LumeRecord>[],
      );
      final int at = list.indexWhere((LumeRecord r) => r.id == id);
      final LumeRecord? before = at == -1 ? null : list[at];
      final LumeRecord? after = t._writes[(c, id)];
      if (before == null && after == null) continue;
      changes.add(LumeTxChange(c, id, before, after));
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
    }

    for (final MapEntry<String, List<LumeRecord>> e in next.entries) {
      _cache[e.key] = e.value;
      _touch(e.key);
    }
    for (final LumeTxChange c in changes) {
      if (c.after != null) {
        (_used[c.collection] ??= <String>{}).add(c.id);
        _upsertRow(c.collection, c.after!);
      } else {
        _deleteRow(c.collection, c.id);
      }
    }
    final LumeTxReceipt receipt = LumeTxReceipt(
      _revision,
      List<LumeTxChange>.unmodifiable(changes),
    );
    if (idempotencyKey != null) {
      _idempotent[idempotencyKey] = _Idempotent(fingerprint, value, receipt);
    }
    if (changes.isNotEmpty) {
      _undo = null;
      notifyListeners();
    }
    return LumeTxResult<T>.ok(value, receipt);
  }

  @override
  LumeTxResult<void> revert(LumeTxReceipt receipt) =>
      run<void>((LumeRecordTx tx) {
        final _SqliteTx t = tx as _SqliteTx;
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

  /// Waits for every persistence write issued so far to reach disk — tests
  /// only, so an assertion against the database itself is not a race
  /// against the write-behind queue.
  @visibleForTesting
  Future<void> flush() => _writeChain;

  @override
  Future<void> dispose() async {
    await _writeChain;
    if (_db != null) await (await _db!).close();
    super.dispose();
  }
}

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

class _SqliteTx implements LumeRecordTx {
  _SqliteTx(this._store, this._snapshot, this._revisions);

  final LumeSqliteRecordRepository _store;
  final Map<String, List<LumeRecord>> _snapshot;
  final Map<String, int> _revisions;

  final Map<String, int> _scans = <String, int>{};
  final Map<(String, String), int?> _reads = <(String, String), int?>{};
  final Map<(String, String), LumeRecord?> _writes =
      <(String, String), LumeRecord?>{};
  final List<(String, String)> _order = <(String, String)>[];
  final Map<(String, String), int> _restoredAt = <(String, String), int>{};

  bool _closed = false;

  List<LumeRecord> _base(String collection) {
    if (_closed) throw StateError('transaction already finished');
    return _snapshot[collection] ?? const <LumeRecord>[];
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
    );
    _stage(collection, id, record);
    return record;
  }

  @override
  LumeRecord insert(String collection, LumeRecord record) {
    if (get(collection, record.id) != null ||
        (_store._used[collection]?.contains(record.id) ?? false)) {
      throw LumeTxFailure(
        LumeTxFailureKind.duplicateId,
        collection: collection,
        id: record.id,
      );
    }
    final LumeRecord copy = record.copyWith(
      fields: Map<String, Object?>.unmodifiable(record.fields),
    );
    _stage(collection, record.id, copy);
    return copy;
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
    );
    _stage(collection, id, after);
    return after;
  }

  @override
  void delete(String collection, String id, {required int expectVersion}) {
    _current(collection, id, expectVersion);
    _stage(collection, id, null);
  }

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

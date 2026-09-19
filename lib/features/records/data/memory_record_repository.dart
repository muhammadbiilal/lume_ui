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
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/record_model.dart';
import '../domain/record_repository.dart';

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
    return LumeRecord(
      id: _newId(collection),
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

  @override
  void dispose() {
    for (final Timer t in _timers) {
      t.cancel();
    }
    super.dispose();
  }
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

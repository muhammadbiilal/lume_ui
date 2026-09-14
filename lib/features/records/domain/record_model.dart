/// A record, a collection's condition, and what a write did — `records.js`.
///
/// Twelve reference families differ in their fields and not in what create,
/// read, update and delete mean, so one model serves all of them: a record is
/// an id, its fields by name, and the bookkeeping the store keeps beside
/// them — a version for conflicts, when it was made and last changed, whether
/// it is demonstration content, and whether it was written while offline.
library;

import 'package:flutter/foundation.dart';

/// One record — `stamp()`'s fields plus the record's own.
@immutable
class LumeRecord {
  const LumeRecord({
    required this.id,
    required this.fields,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.seeded = false,
    this.queued = false,
  });

  final String id;

  /// What the record holds, by field name. A seeded record's strings are
  /// translation keys; a record the reader wrote holds their own words.
  final Map<String, Object?> fields;

  /// `_v` — starts at 1 and rises with every update. A form remembers the
  /// version it was opened against, so a save that finds another has a
  /// conflict rather than a right to overwrite.
  final int version;

  /// `_at`.
  final DateTime createdAt;

  /// `_up`.
  final DateTime updatedAt;

  /// `_seed` — demonstration content, whose text is resolved in the reader's
  /// language each time it is shown. A record the reader has saved is theirs
  /// and is never re-translated under them.
  final bool seeded;

  /// `_queued` — written while offline, and shown as queued rather than
  /// passed off as current (§10).
  final bool queued;

  Object? operator [](String name) => fields[name];

  LumeRecord copyWith({
    Map<String, Object?>? fields,
    int? version,
    DateTime? updatedAt,
    bool? seeded,
    bool? queued,
  }) => LumeRecord(
    id: id,
    fields: fields ?? this.fields,
    version: version ?? this.version,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    seeded: seeded ?? this.seeded,
    queued: queued ?? this.queued,
  );
}

/// Which of the guide's states a collection is in — `view(coll).state`.
enum LumeCollectionStatus {
  /// Opened for the first time and not yet read: the skeleton is a frame
  /// that actually happens.
  loading,
  ready,

  /// Readable, from what this device holds, while the network is away.
  offline,

  /// The collection could not be read.
  error,
}

/// What to draw for a collection right now — one answer, never assembled
/// from separate reads.
@immutable
class LumeCollectionView {
  const LumeCollectionView(this.status, [this.items = const <LumeRecord>[]]);

  final LumeCollectionStatus status;

  /// Newest first, as the store keeps them.
  final List<LumeRecord> items;

  bool get isOffline => status == LumeCollectionStatus.offline;
}

/// Why a write did not happen.
enum LumeWriteFailure {
  /// The store refused the write. Nothing the reader typed is lost.
  storage,

  /// The record is no longer there.
  missing,

  /// A newer version exists than the one the form was opened against.
  conflict,
}

/// What a create, update or delete did.
@immutable
class LumeWriteResult {
  const LumeWriteResult.ok(LumeRecord this.record)
    : failure = null,
      current = null;

  const LumeWriteResult.failed(LumeWriteFailure this.failure, {this.current})
    : record = null;

  /// The record as written, or as it was just before it was removed.
  final LumeRecord? record;

  final LumeWriteFailure? failure;

  /// On a conflict, the newer version that is in the store.
  final LumeRecord? current;

  bool get ok => failure == null;
}

/// Which write an undo reversed.
enum LumeUndoKind { create, update, delete }

/// What `undo()` did — enough for the caller to say so and to select the
/// record it brought back.
@immutable
class LumeUndone {
  const LumeUndone(this.kind, this.collection, [this.record]);

  final LumeUndoKind kind;
  final String collection;
  final LumeRecord? record;
}

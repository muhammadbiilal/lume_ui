/// Health Records' records, read and written through the record layer's
/// transactions.
///
/// One collection, no children. Nothing is seeded: a reader's Health Records
/// starts empty (Option B), and is kept in memory, not durable — the same
/// undertaking every sensitive family here makes (`durable` reads `false`).
///
/// A record is not recoverable: deleting one is final, so the tool that
/// draws this must ask plainly and never arm an Undo it cannot honour
/// (`lume_crud.dart`'s [LumeDeleteKind.irreversible] — Documents and Health
/// Records are the two families that mean it literally). [undo] still exists
/// here, because the underlying store can revert any write and a test needs
/// to prove that generic mechanism actually works on this collection; the
/// screen simply never wires a delete's toast to it.
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import 'health_book.dart';
import 'health_failure.dart';
import 'health_model.dart';

/// What the reader filled in for a record.
@immutable
class HealthDraft {
  const HealthDraft({
    required this.title,
    required this.kind,
    required this.date,
    this.source,
    this.value,
    this.notes,
  });

  final String title;
  final HealthRecordKind kind;
  final LumeDate date;
  final String? source;
  final String? value;
  final String? notes;

  String get fingerprint => jsonEncode(<String, Object?>{
    't': title,
    'k': kind.name,
    'd': date.toIso(),
    's': source,
    'v': value,
    'n': notes,
  });
}

@immutable
class HealthWrite {
  const HealthWrite(this.receipt, {this.record});
  final LumeTxReceipt receipt;
  final HealthRecord? record;
}

@immutable
class HealthSnapshot {
  const HealthSnapshot({
    required this.status,
    this.records = const <HealthRecord>[],
    this.defects = const <HealthDefect>[],
  });

  final LumeCollectionStatus status;
  final List<HealthRecord> records;
  final List<HealthDefect> defects;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;

  HealthBook book(LumeDate? today) =>
      HealthBook.from(records: records, defects: defects, today: today);
}

class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(HealthCollections.records)) {
      try {
        records.add(HealthRecord.decode(r));
      } on HealthDefectException catch (e) {
        defects.add(e.defect);
      }
    }
  }

  final LumeRecordTx tx;
  final List<HealthRecord> records = <HealthRecord>[];
  final List<HealthDefect> defects = <HealthDefect>[];

  HealthRecord sound(LumeRecordId id) {
    for (final HealthRecord r in records) {
      if (r.id == id) return r;
    }
    throw HealthFailure(HealthFailureKind.notFound, ids: <LumeRecordId>[id]);
  }
}

class HealthRepository {
  HealthRepository(this._store, {Random? random, DateTime Function()? now})
    : _random = random ?? Random.secure(),
      _now = now ?? DateTime.now;

  final LumeRecordRepository _store;
  final Random _random;
  final DateTime Function() _now;

  Listenable get changes => _store;

  /// Option B: always `false` today; a screen that would claim durability
  /// reads this first.
  bool get durable => _store.durable;

  LumeRecordId _newId() => LumeRecordId.generate(_random);

  void open() {
    for (final String c in HealthCollections.all) {
      _store.open(c);
    }
  }

  void retry() {
    for (final String c in HealthCollections.all) {
      if (_store.view(c).status == LumeCollectionStatus.error) {
        _store.retry(c);
      }
    }
  }

  HealthSnapshot view() {
    final LumeCollectionView v = _store.view(HealthCollections.records);
    if (v.status == LumeCollectionStatus.error) {
      return const HealthSnapshot(status: LumeCollectionStatus.error);
    }
    if (v.status == LumeCollectionStatus.loading) {
      return const HealthSnapshot(status: LumeCollectionStatus.loading);
    }
    final List<HealthDefect> defects = <HealthDefect>[];
    final List<HealthRecord> out = <HealthRecord>[];
    for (final LumeRecord r in v.items) {
      try {
        out.add(HealthRecord.decode(r));
      } on HealthDefectException catch (e) {
        defects.add(e.defect);
      }
    }
    return HealthSnapshot(status: v.status, records: out, defects: defects);
  }

  HealthResult<HealthWrite> add(HealthDraft draft, {String? idempotencyKey}) =>
      _write<HealthRecord>(
        (_Data d) {
          _validate(draft);
          final HealthRecord r0 = _record(_newId(), draft, _now());
          final LumeRecord r = d.tx.create(
            HealthCollections.records,
            r0.id.value,
            r0.toFields(),
          );
          final HealthRecord stored = HealthRecord.decode(r);
          d.records.add(stored);
          return stored;
        },
        idempotencyKey: idempotencyKey,
        fingerprint: idempotencyKey == null ? null : draft.fingerprint,
      );

  /// Edit a record — every field, at any time.
  HealthResult<HealthWrite> edit(
    LumeRecordId id,
    HealthDraft draft, {
    required int version,
  }) => _write<HealthRecord>((_Data d) {
    final HealthRecord was = d.sound(id);
    _validate(draft);
    final HealthRecord now = _record(was.id, draft, was.createdAt);
    final LumeRecord r = d.tx.update(
      HealthCollections.records,
      id.value,
      now.toFields(),
      expectVersion: version,
    );
    final HealthRecord stored = HealthRecord.decode(r);
    d.records[d.records.indexWhere((HealthRecord x) => x.id == id)] = stored;
    return stored;
  });

  /// A record is deleted for good — never recoverable (`record-schemas.js`'s
  /// `recoverable: false`). The screen that calls this must have already
  /// asked, in words that say so, and must never offer an Undo afterwards.
  HealthResult<HealthWrite> delete(LumeRecordId id, {required int version}) =>
      _write<HealthRecord>((_Data d) {
        final HealthRecord was = d.sound(id);
        d.tx.delete(
          HealthCollections.records,
          id.value,
          expectVersion: version,
        );
        d.records.removeWhere((HealthRecord x) => x.id == id);
        d.defects.removeWhere((HealthDefect x) => x.recordId == id.value);
        return was;
      });

  /// The store's generic revert, proven at this layer for the underlying
  /// transaction mechanism — not a capability the screen exposes for a
  /// delete (see the class doc).
  HealthResult<void> undo(HealthWrite write) {
    final LumeTxResult<void> r = _store.revert(write.receipt);
    return r.ok
        ? const HealthResult<void>.ok(null)
        : HealthResult<void>.failed(_map(r.failure!));
  }

  // ---- internals ----------------------------------------------------------

  HealthRecord _record(
    LumeRecordId id,
    HealthDraft draft,
    DateTime createdAt,
  ) => HealthRecord(
    id: id,
    title: draft.title.trim(),
    kind: draft.kind,
    date: draft.date,
    source: _optional(draft.source),
    value: _optional(draft.value),
    notes: _optional(draft.notes),
    createdAt: createdAt,
  );

  static void _validate(HealthDraft draft) {
    final String title = draft.title.trim();
    if (title.isEmpty) {
      throw const HealthFailure.validation('title', 'required');
    }
    if (title.length > kHealthTitleMax) {
      throw const HealthFailure.validation('title', 'long');
    }
    if ((draft.source?.trim().length ?? 0) > kHealthSourceMax) {
      throw const HealthFailure.validation('source', 'long');
    }
    if ((draft.value?.trim().length ?? 0) > kHealthValueMax) {
      throw const HealthFailure.validation('value', 'long');
    }
    if ((draft.notes?.trim().length ?? 0) > kHealthNotesMax) {
      throw const HealthFailure.validation('notes', 'long');
    }
  }

  static String? _optional(String? s) =>
      s == null || s.trim().isEmpty ? null : s.trim();

  HealthResult<HealthWrite> _write<T>(
    T Function(_Data d) body, {
    String? idempotencyKey,
    String? fingerprint,
  }) {
    final LumeTxResult<T> r = _store.run<T>(
      (LumeRecordTx tx) {
        try {
          final _Data d = _Data(tx);
          return body(d);
        } on HealthFailure catch (f) {
          tx.reject(f);
        }
      },
      idempotencyKey: idempotencyKey,
      fingerprint: fingerprint,
    );
    if (!r.ok) return HealthResult<HealthWrite>.failed(_map(r.failure!));
    final T v = r.value as T;
    return HealthResult<HealthWrite>.ok(
      HealthWrite(r.receipt!, record: v is HealthRecord ? v : null),
    );
  }

  static HealthFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected => f.detail! as HealthFailure,
    LumeTxFailureKind.conflict ||
    LumeTxFailureKind.duplicateId => HealthFailure(
      HealthFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => HealthFailure(
      HealthFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => HealthFailure(
      HealthFailureKind.storage,
      cause: f.kind,
    ),
  };
}

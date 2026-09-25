/// Vaccinations' records, read and written through the record layer's
/// transactions.
///
/// One flat collection, no children, no aggregate — a vaccination is a
/// single row, edited in place (matching Subscriptions rather than Meal
/// Plan's fixed-slot upsert). Nothing is seeded: a reader's Vaccinations
/// starts empty (Option B, `durable` is always `false` today).
///
/// **Delete is irreversible, on purpose.** This is a health record
/// (`lume_crud.dart`'s [LumeDeleteKind.irreversible] names "Documents and
/// health records" as the two families where a delete's confirmation says
/// so and no Undo is armed afterwards, because arming one would be a lie
/// about a sensitive record the reader chose to remove). [delete] still
/// returns a receipt, exactly like every other family's, so the store's own
/// conflict handling and the domain layer's [undo] stay uniform and
/// testable; the presentation layer is the one that chooses never to offer
/// Undo after a vaccination is deleted.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import 'vaccines_book.dart';
import 'vaccines_failure.dart';
import 'vaccines_model.dart';

/// What the reader filled in for a vaccination.
@immutable
class VaccineDraft {
  const VaccineDraft({
    required this.name,
    this.forWhom,
    this.dose,
    required this.date,
    this.status = VaccineStatus.given,
    this.provider,
    this.notes,
  });

  final String name;
  final String? forWhom;
  final String? dose;
  final LumeDate date;
  final VaccineStatus status;
  final String? provider;
  final String? notes;
}

@immutable
class VaccinesWrite {
  const VaccinesWrite(this.receipt, {this.record});
  final LumeTxReceipt receipt;
  final VaccineRecord? record;
}

@immutable
class VaccinesSnapshot {
  const VaccinesSnapshot({
    required this.status,
    this.records = const <VaccineRecord>[],
    this.defects = const <VaccinesDefect>[],
  });

  final LumeCollectionStatus status;
  final List<VaccineRecord> records;
  final List<VaccinesDefect> defects;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;

  VaccinesBook book(LumeDate? today) =>
      VaccinesBook.from(records: records, defects: defects, today: today);
}

class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(VaccinesCollections.records)) {
      try {
        records.add(VaccineRecord.decode(r));
      } on VaccinesDefectException catch (e) {
        defects.add(e.defect);
      }
    }
  }

  final LumeRecordTx tx;
  final List<VaccineRecord> records = <VaccineRecord>[];
  final List<VaccinesDefect> defects = <VaccinesDefect>[];

  VaccineRecord sound(LumeRecordId id) {
    for (final VaccineRecord v in records) {
      if (v.id == id) return v;
    }
    throw VaccinesFailure(
      VaccinesFailureKind.notFound,
      ids: <LumeRecordId>[id],
    );
  }
}

class VaccinesRepository {
  VaccinesRepository(this._store, {Random? random, DateTime Function()? now})
    : _random = random ?? Random.secure(),
      _now = now ?? DateTime.now;

  final LumeRecordRepository _store;
  final Random _random;
  final DateTime Function() _now;

  Listenable get changes => _store;

  /// Option B: always `false` today.
  bool get durable => _store.durable;

  LumeRecordId _newId() => LumeRecordId.generate(_random);

  void open() {
    for (final String c in VaccinesCollections.all) {
      _store.open(c);
    }
  }

  void retry() {
    for (final String c in VaccinesCollections.all) {
      if (_store.view(c).status == LumeCollectionStatus.error) {
        _store.retry(c);
      }
    }
  }

  VaccinesSnapshot view() {
    final LumeCollectionView v = _store.view(VaccinesCollections.records);
    if (v.status == LumeCollectionStatus.error) {
      return const VaccinesSnapshot(status: LumeCollectionStatus.error);
    }
    if (v.status == LumeCollectionStatus.loading) {
      return const VaccinesSnapshot(status: LumeCollectionStatus.loading);
    }
    final List<VaccinesDefect> defects = <VaccinesDefect>[];
    final List<VaccineRecord> out = <VaccineRecord>[];
    for (final LumeRecord r in v.items) {
      try {
        out.add(VaccineRecord.decode(r));
      } on VaccinesDefectException catch (e) {
        defects.add(e.defect);
      }
    }
    return VaccinesSnapshot(status: v.status, records: out, defects: defects);
  }

  VaccinesResult<VaccinesWrite> add(
    VaccineDraft draft, {
    String? idempotencyKey,
  }) => _write<VaccineRecord>((_Data d) {
    _validate(draft);
    final VaccineRecord r = _record(_newId(), draft, _now());
    final LumeRecord stored = d.tx.create(
      VaccinesCollections.records,
      r.id.value,
      r.toFields(),
    );
    final VaccineRecord decoded = VaccineRecord.decode(stored);
    d.records.add(decoded);
    return decoded;
  }, idempotencyKey: idempotencyKey);

  VaccinesResult<VaccinesWrite> edit(
    LumeRecordId id,
    VaccineDraft draft, {
    required int version,
  }) => _write<VaccineRecord>((_Data d) {
    final VaccineRecord was = d.sound(id);
    _validate(draft);
    final VaccineRecord now = _record(was.id, draft, was.createdAt);
    final LumeRecord stored = d.tx.update(
      VaccinesCollections.records,
      id.value,
      now.toFields(),
      expectVersion: version,
    );
    final VaccineRecord decoded = VaccineRecord.decode(stored);
    d.records[d.records.indexWhere((VaccineRecord x) => x.id == id)] = decoded;
    return decoded;
  });

  /// Irreversible in the UI (see the library doc); still a uniform,
  /// conflict-checked write here.
  VaccinesResult<VaccinesWrite> delete(
    LumeRecordId id, {
    required int version,
  }) => _write<VaccineRecord>((_Data d) {
    final VaccineRecord was = d.sound(id);
    d.tx.delete(VaccinesCollections.records, id.value, expectVersion: version);
    d.records.removeWhere((VaccineRecord x) => x.id == id);
    d.defects.removeWhere((VaccinesDefect x) => x.recordId == id.value);
    return was;
  });

  VaccinesResult<void> undo(VaccinesWrite write) {
    if (write.receipt.revision == 0) return const VaccinesResult<void>.ok(null);
    final LumeTxResult<void> r = _store.revert(write.receipt);
    return r.ok
        ? const VaccinesResult<void>.ok(null)
        : VaccinesResult<void>.failed(_map(r.failure!));
  }

  // ---- internals ----------------------------------------------------------

  VaccineRecord _record(
    LumeRecordId id,
    VaccineDraft draft,
    DateTime createdAt,
  ) => VaccineRecord(
    id: id,
    name: draft.name.trim(),
    forWhom: _optional(draft.forWhom),
    dose: _optional(draft.dose),
    date: draft.date,
    status: draft.status,
    provider: _optional(draft.provider),
    notes: _optional(draft.notes),
    createdAt: createdAt,
  );

  static void _validate(VaccineDraft draft) {
    final String name = draft.name.trim();
    if (name.isEmpty) {
      throw const VaccinesFailure.validation('name', 'required');
    }
    if (name.length > kVaccinesNameMax) {
      throw const VaccinesFailure.validation('name', 'long');
    }
    if ((draft.forWhom?.trim().length ?? 0) > kVaccinesForWhomMax) {
      throw const VaccinesFailure.validation('forWhom', 'long');
    }
    if ((draft.dose?.trim().length ?? 0) > kVaccinesDoseMax) {
      throw const VaccinesFailure.validation('dose', 'long');
    }
    if ((draft.provider?.trim().length ?? 0) > kVaccinesProviderMax) {
      throw const VaccinesFailure.validation('provider', 'long');
    }
    if ((draft.notes?.trim().length ?? 0) > kVaccinesNotesMax) {
      throw const VaccinesFailure.validation('notes', 'long');
    }
  }

  static String? _optional(String? s) =>
      s == null || s.trim().isEmpty ? null : s.trim();

  VaccinesResult<VaccinesWrite> _write<T>(
    T Function(_Data d) body, {
    String? idempotencyKey,
    String? fingerprint,
  }) {
    final LumeTxResult<T> r = _store.run<T>(
      (LumeRecordTx tx) {
        try {
          final _Data d = _Data(tx);
          return body(d);
        } on VaccinesFailure catch (f) {
          tx.reject(f);
        }
      },
      idempotencyKey: idempotencyKey,
      fingerprint: fingerprint,
    );
    if (!r.ok) return VaccinesResult<VaccinesWrite>.failed(_map(r.failure!));
    final T v = r.value as T;
    return VaccinesResult<VaccinesWrite>.ok(
      VaccinesWrite(r.receipt!, record: v is VaccineRecord ? v : null),
    );
  }

  static VaccinesFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected => f.detail! as VaccinesFailure,
    LumeTxFailureKind.conflict ||
    LumeTxFailureKind.duplicateId => VaccinesFailure(
      VaccinesFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => VaccinesFailure(
      VaccinesFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => VaccinesFailure(
      VaccinesFailureKind.storage,
      cause: f.kind,
    ),
  };
}

/// Medication's records, read and written through the record layer's
/// transactions.
///
/// One collection, no children: a medication is a single row, edited in
/// place — its dose or count left genuinely can change without becoming a
/// different medication. Nothing is seeded: a reader's Medication starts
/// empty (Option B).
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import 'meds_book.dart';
import 'meds_failure.dart';
import 'meds_model.dart';

/// What the reader filled in for a medication.
@immutable
class MedsDraft {
  const MedsDraft({
    required this.name,
    required this.dose,
    required this.schedule,
    this.firstDoseAt,
    this.dosesLeft,
    this.notes,
  });

  final String name;
  final String dose;
  final MedsSchedule schedule;
  final String? firstDoseAt;
  final int? dosesLeft;
  final String? notes;

  String get fingerprint => jsonEncode(<String, Object?>{
    'n': name,
    'd': dose,
    's': schedule.name,
    'a': firstDoseAt,
    'l': dosesLeft,
    'note': notes,
  });
}

@immutable
class MedsWrite {
  const MedsWrite(this.receipt, {this.medication});
  final LumeTxReceipt receipt;
  final MedsEntry? medication;
}

@immutable
class MedsSnapshot {
  const MedsSnapshot({
    required this.status,
    this.medications = const <MedsEntry>[],
    this.defects = const <MedsDefect>[],
  });

  final LumeCollectionStatus status;
  final List<MedsEntry> medications;
  final List<MedsDefect> defects;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;

  MedsBook book() => MedsBook.from(medications: medications, defects: defects);
}

class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(MedsCollections.medications)) {
      try {
        medications.add(MedsEntry.decode(r));
      } on MedsDefectException catch (e) {
        defects.add(e.defect);
      }
    }
  }

  final LumeRecordTx tx;
  final List<MedsEntry> medications = <MedsEntry>[];
  final List<MedsDefect> defects = <MedsDefect>[];

  MedsEntry sound(LumeRecordId id) {
    for (final MedsEntry m in medications) {
      if (m.id == id) return m;
    }
    throw MedsFailure(MedsFailureKind.notFound, ids: <LumeRecordId>[id]);
  }
}

class MedsRepository {
  MedsRepository(this._store, {Random? random, DateTime Function()? now})
    : _random = random ?? Random.secure(),
      _now = now ?? DateTime.now;

  final LumeRecordRepository _store;
  final Random _random;
  final DateTime Function() _now;

  Listenable get changes => _store;

  /// Option B: always `false` today — session-only, matching every other
  /// record family here except Reminders.
  bool get durable => _store.durable;

  LumeRecordId _newId() => LumeRecordId.generate(_random);

  void open() {
    for (final String c in MedsCollections.all) {
      _store.open(c);
    }
  }

  void retry() {
    for (final String c in MedsCollections.all) {
      if (_store.view(c).status == LumeCollectionStatus.error) {
        _store.retry(c);
      }
    }
  }

  MedsSnapshot view() {
    final LumeCollectionView v = _store.view(MedsCollections.medications);
    if (v.status == LumeCollectionStatus.error) {
      return const MedsSnapshot(status: LumeCollectionStatus.error);
    }
    if (v.status == LumeCollectionStatus.loading) {
      return const MedsSnapshot(status: LumeCollectionStatus.loading);
    }
    final List<MedsDefect> defects = <MedsDefect>[];
    final List<MedsEntry> out = <MedsEntry>[];
    for (final LumeRecord r in v.items) {
      try {
        out.add(MedsEntry.decode(r));
      } on MedsDefectException catch (e) {
        defects.add(e.defect);
      }
    }
    return MedsSnapshot(status: v.status, medications: out, defects: defects);
  }

  MedsResult<MedsWrite> add(MedsDraft draft, {String? idempotencyKey}) =>
      _write<MedsEntry>(
        (_Data d) {
          _validate(draft);
          final MedsEntry m = _entry(_newId(), draft, _now());
          final LumeRecord r = d.tx.create(
            MedsCollections.medications,
            m.id.value,
            m.toFields(),
          );
          final MedsEntry stored = MedsEntry.decode(r);
          d.medications.add(stored);
          return stored;
        },
        idempotencyKey: idempotencyKey,
        fingerprint: idempotencyKey == null ? null : draft.fingerprint,
      );

  /// Edit a medication — every field, at any time.
  MedsResult<MedsWrite> edit(
    LumeRecordId id,
    MedsDraft draft, {
    required int version,
  }) => _write<MedsEntry>((_Data d) {
    final MedsEntry was = d.sound(id);
    _validate(draft);
    final MedsEntry now = _entry(was.id, draft, was.createdAt);
    final LumeRecord r = d.tx.update(
      MedsCollections.medications,
      id.value,
      now.toFields(),
      expectVersion: version,
    );
    final MedsEntry stored = MedsEntry.decode(r);
    d.medications[d.medications.indexWhere((MedsEntry x) => x.id == id)] =
        stored;
    return stored;
  });

  MedsResult<MedsWrite> delete(LumeRecordId id, {required int version}) =>
      _write<MedsEntry>((_Data d) {
        final MedsEntry was = d.sound(id);
        d.tx.delete(
          MedsCollections.medications,
          id.value,
          expectVersion: version,
        );
        d.medications.removeWhere((MedsEntry x) => x.id == id);
        d.defects.removeWhere((MedsDefect x) => x.recordId == id.value);
        return was;
      });

  MedsResult<void> undo(MedsWrite write) {
    final LumeTxResult<void> r = _store.revert(write.receipt);
    return r.ok
        ? const MedsResult<void>.ok(null)
        : MedsResult<void>.failed(_map(r.failure!));
  }

  // ---- internals ------------------------------------------------------

  MedsEntry _entry(LumeRecordId id, MedsDraft draft, DateTime createdAt) =>
      MedsEntry(
        id: id,
        name: draft.name.trim(),
        dose: draft.dose.trim(),
        schedule: draft.schedule,
        firstDoseAt: draft.firstDoseAt,
        dosesLeft: draft.dosesLeft,
        notes: _optional(draft.notes),
        createdAt: createdAt,
      );

  static void _validate(MedsDraft draft) {
    final String name = draft.name.trim();
    if (name.isEmpty) {
      throw const MedsFailure.validation('name', 'required');
    }
    if (name.length > kMedsNameMax) {
      throw const MedsFailure.validation('name', 'long');
    }
    final String dose = draft.dose.trim();
    if (dose.isEmpty) {
      throw const MedsFailure.validation('dose', 'required');
    }
    if (dose.length > kMedsDoseMax) {
      throw const MedsFailure.validation('dose', 'long');
    }
    if ((draft.notes?.trim().length ?? 0) > kMedsNoteMax) {
      throw const MedsFailure.validation('notes', 'long');
    }
    final int? left = draft.dosesLeft;
    if (left != null && (left < 0 || left > kMedsDosesLeftMax)) {
      throw const MedsFailure.validation('dosesLeft', 'range');
    }
    final String? at = draft.firstDoseAt;
    if (at != null && !RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').hasMatch(at)) {
      throw const MedsFailure.validation('firstDoseAt', 'clock');
    }
  }

  static String? _optional(String? s) =>
      s == null || s.trim().isEmpty ? null : s.trim();

  MedsResult<MedsWrite> _write<T>(
    T Function(_Data d) body, {
    String? idempotencyKey,
    String? fingerprint,
  }) {
    final LumeTxResult<T> r = _store.run<T>(
      (LumeRecordTx tx) {
        try {
          final _Data d = _Data(tx);
          return body(d);
        } on MedsFailure catch (f) {
          tx.reject(f);
        }
      },
      idempotencyKey: idempotencyKey,
      fingerprint: fingerprint,
    );
    if (!r.ok) return MedsResult<MedsWrite>.failed(_map(r.failure!));
    final T v = r.value as T;
    return MedsResult<MedsWrite>.ok(
      MedsWrite(r.receipt!, medication: v is MedsEntry ? v : null),
    );
  }

  static MedsFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected => f.detail! as MedsFailure,
    LumeTxFailureKind.conflict || LumeTxFailureKind.duplicateId => MedsFailure(
      MedsFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => MedsFailure(
      MedsFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => MedsFailure(
      MedsFailureKind.storage,
      cause: f.kind,
    ),
  };
}

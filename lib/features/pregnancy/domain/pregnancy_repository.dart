/// Pregnancy's record, read and written through the record layer's
/// transactions, the way every other record family is (`mealplan_repository.dart`).
///
/// **One record, not a list.** Where Meal Plan keeps up to 21 entries,
/// Pregnancy keeps at most one: the reader's current last-period date.
/// Setting a new date replaces the one on file; there is no history of
/// past estimates to keep consistent, so this is simpler than every
/// wave-5/6 family. Nothing is seeded: a reader's Pregnancy starts empty
/// (Option B), matching this build's session-only record store
/// (`records_provider.dart`, `durable: false`).
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import 'pregnancy_failure.dart';
import 'pregnancy_maths.dart';
import 'pregnancy_model.dart';

@immutable
class PregnancyWrite {
  const PregnancyWrite(this.receipt, {this.profile});
  final LumeTxReceipt receipt;
  final PregnancyProfile? profile;
}

@immutable
class PregnancySnapshot {
  const PregnancySnapshot({required this.status, this.profile, this.defect});

  final LumeCollectionStatus status;
  final PregnancyProfile? profile;

  /// A record this build could not decode — reported, never a crash.
  final PregnancyDefect? defect;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;
}

class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(PregnancyCollections.profile)) {
      try {
        profile = PregnancyProfile.decode(r);
      } on PregnancyDefectException {
        // Left unset — a defect surfaces through view(), not a write's own
        // read of the collection, so a corrupt record never blocks a new
        // one from being written over it (the create/update branches below
        // key off `profile`, not off what is actually stored).
      }
      break; // at most one record ever exists in this collection.
    }
  }

  final LumeRecordTx tx;
  PregnancyProfile? profile;
}

class PregnancyRepository {
  PregnancyRepository(this._store, {Random? random, DateTime Function()? now})
    : _random = random ?? Random.secure(),
      _now = now ?? DateTime.now;

  final LumeRecordRepository _store;
  final Random _random;
  final DateTime Function() _now;

  Listenable get changes => _store;

  /// Option B: always `false` today.
  bool get durable => _store.durable;

  LumeRecordId _newId() => LumeRecordId.generate(_random);

  void open() => _store.open(PregnancyCollections.profile);

  void retry() {
    if (_store.view(PregnancyCollections.profile).status ==
        LumeCollectionStatus.error) {
      _store.retry(PregnancyCollections.profile);
    }
  }

  PregnancySnapshot view() {
    final LumeCollectionView v = _store.view(PregnancyCollections.profile);
    if (v.status == LumeCollectionStatus.error) {
      return const PregnancySnapshot(status: LumeCollectionStatus.error);
    }
    if (v.status == LumeCollectionStatus.loading) {
      return const PregnancySnapshot(status: LumeCollectionStatus.loading);
    }
    if (v.items.isEmpty) return PregnancySnapshot(status: v.status);
    try {
      return PregnancySnapshot(
        status: v.status,
        profile: PregnancyProfile.decode(v.items.first),
      );
    } on PregnancyDefectException catch (e) {
      return PregnancySnapshot(status: v.status, defect: e.defect);
    }
  }

  /// Set (or replace) the reader's last-period date. [today] is the
  /// reader's resolved calendar date; a date that fails
  /// [LumePregnancyValidity.check] against it is refused rather than
  /// stored (defence in depth — the date picker's own bounds are the
  /// first line, not the only one).
  PregnancyResult<PregnancyWrite> setLmp(LumeDate lmp, LumeDate today) =>
      _write<PregnancyProfile>((_Data d) {
        switch (LumePregnancyValidity.check(lmp, today)) {
          case LumePregnancyInvalid.future:
            throw const PregnancyFailure.validation('lmp', 'future');
          case LumePregnancyInvalid.tooOld:
            throw const PregnancyFailure.validation('lmp', 'tooOld');
          case null:
            break;
        }
        final PregnancyProfile? existing = d.profile;
        if (existing != null) {
          final LumeRecord r = d.tx.update(
            PregnancyCollections.profile,
            existing.id.value,
            existing.copyWith(lmp: lmp).toFields(),
            expectVersion: existing.version,
          );
          return PregnancyProfile.decode(r);
        }
        final PregnancyProfile p = PregnancyProfile(
          id: _newId(),
          lmp: lmp,
          createdAt: _now(),
        );
        return PregnancyProfile.decode(
          d.tx.create(PregnancyCollections.profile, p.id.value, p.toFields()),
        );
      });

  /// Clear the reader's date entirely — a delete, with Undo, matching every
  /// other family's delete pattern. A no-op result (not a failure) when
  /// there was nothing on file.
  PregnancyResult<PregnancyWrite> clear() {
    final PregnancySnapshot s = view();
    final PregnancyProfile? existing = s.profile;
    if (existing == null) {
      return const PregnancyResult<PregnancyWrite>.ok(
        PregnancyWrite(LumeTxReceipt(0, <LumeTxChange>[])),
      );
    }
    return _write<PregnancyProfile>((_Data d) {
      final PregnancyProfile? p = d.profile;
      if (p == null) {
        throw PregnancyFailure(
          PregnancyFailureKind.notFound,
          ids: <LumeRecordId>[existing.id],
        );
      }
      d.tx.delete(PregnancyCollections.profile, p.id.value, expectVersion: p.version);
      return p;
    });
  }

  PregnancyResult<void> undo(PregnancyWrite write) {
    if (write.receipt.revision == 0) return const PregnancyResult<void>.ok(null);
    final LumeTxResult<void> r = _store.revert(write.receipt);
    return r.ok
        ? const PregnancyResult<void>.ok(null)
        : PregnancyResult<void>.failed(_map(r.failure!));
  }

  PregnancyResult<PregnancyWrite> _write<T>(T Function(_Data d) body) {
    final LumeTxResult<T> r = _store.run<T>((LumeRecordTx tx) {
      try {
        final _Data d = _Data(tx);
        return body(d);
      } on PregnancyFailure catch (f) {
        tx.reject(f);
      }
    });
    if (!r.ok) return PregnancyResult<PregnancyWrite>.failed(_map(r.failure!));
    final T v = r.value as T;
    return PregnancyResult<PregnancyWrite>.ok(
      PregnancyWrite(r.receipt!, profile: v is PregnancyProfile ? v : null),
    );
  }

  static PregnancyFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected => f.detail! as PregnancyFailure,
    LumeTxFailureKind.conflict ||
    LumeTxFailureKind.duplicateId => PregnancyFailure(
      PregnancyFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => PregnancyFailure(
      PregnancyFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => PregnancyFailure(
      PregnancyFailureKind.storage,
      cause: f.kind,
    ),
  };
}

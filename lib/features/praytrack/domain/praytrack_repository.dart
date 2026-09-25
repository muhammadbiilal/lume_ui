/// Prayer Tracker's records, read and written through the record layer's
/// transactions.
///
/// One flat collection, one check-in per (day, prayer). [toggle] is the only
/// write: it creates a check-in where there was none, or removes the one
/// that was there — no confirmation, matching Habits' own toggle. Nothing is
/// seeded: a reader's Prayer Tracker starts empty (Option B — session-only,
/// `durable` says so).
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import 'praytrack_book.dart';
import 'praytrack_failure.dart';
import 'praytrack_model.dart';

@immutable
class PrayTrackWrite {
  const PrayTrackWrite(this.receipt, {this.checkin});

  final LumeTxReceipt receipt;

  /// Set on a toggle that added a check-in; `null` when the toggle removed
  /// one.
  final PrayerCheckin? checkin;
}

/// Prayer Tracker's records as they stand, or why they cannot be shown.
@immutable
class PrayTrackSnapshot {
  const PrayTrackSnapshot({
    required this.status,
    this.checkins = const <PrayerCheckin>[],
    this.defects = const <PrayTrackDefect>[],
  });

  final LumeCollectionStatus status;
  final List<PrayerCheckin> checkins;
  final List<PrayTrackDefect> defects;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;

  Map<LumeDate, Set<PrayerKey>> get byDate {
    final Map<LumeDate, Set<PrayerKey>> out = <LumeDate, Set<PrayerKey>>{};
    for (final PrayerCheckin c in checkins) {
      (out[c.date] ??= <PrayerKey>{}).add(c.prayer);
    }
    return out;
  }

  PrayTrackStats stats(LumeDate today) =>
      PrayTrackStats.compute(byDate: byDate, today: today);
}

class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(PrayTrackCollections.checkins)) {
      try {
        checkins.add(PrayerCheckin.decode(r));
      } on PrayTrackDefectException catch (e) {
        defects.add(e.defect);
      }
    }
  }

  final LumeRecordTx tx;
  final List<PrayerCheckin> checkins = <PrayerCheckin>[];
  final List<PrayTrackDefect> defects = <PrayTrackDefect>[];

  PrayerCheckin? at(LumeDate date, PrayerKey prayer) {
    for (final PrayerCheckin c in checkins) {
      if (c.date == date && c.prayer == prayer) return c;
    }
    return null;
  }
}

class PrayTrackRepository {
  PrayTrackRepository(this._store, {Random? random, DateTime Function()? now})
    : _random = random ?? Random.secure(),
      _now = now ?? DateTime.now;

  final LumeRecordRepository _store;
  final Random _random;
  final DateTime Function() _now;

  /// Told once per committed write.
  Listenable get changes => _store;

  /// Whether a write survives the app being closed. Option B: always
  /// `false` today.
  bool get durable => _store.durable;

  LumeRecordId _newId() => LumeRecordId.generate(_random);

  void open() {
    for (final String c in PrayTrackCollections.all) {
      _store.open(c);
    }
  }

  void retry() {
    for (final String c in PrayTrackCollections.all) {
      if (_store.view(c).status == LumeCollectionStatus.error) {
        _store.retry(c);
      }
    }
  }

  /// The records now, decoded; one that cannot be read is a defect, listed,
  /// never dropped from view but silently excluded from every figure.
  PrayTrackSnapshot view() {
    final LumeCollectionView v = _store.view(PrayTrackCollections.checkins);
    if (v.status == LumeCollectionStatus.error) {
      return const PrayTrackSnapshot(status: LumeCollectionStatus.error);
    }
    if (v.status == LumeCollectionStatus.loading) {
      return const PrayTrackSnapshot(status: LumeCollectionStatus.loading);
    }
    final List<PrayTrackDefect> defects = <PrayTrackDefect>[];
    final List<PrayerCheckin> out = <PrayerCheckin>[];
    for (final LumeRecord r in v.items) {
      try {
        out.add(PrayerCheckin.decode(r));
      } on PrayTrackDefectException catch (e) {
        defects.add(e.defect);
      }
    }
    return PrayTrackSnapshot(status: v.status, checkins: out, defects: defects);
  }

  /// Toggle whether [prayer] was marked prayed on [date]: creates a
  /// check-in where there was none, or removes the one that was there.
  PrayTrackResult<PrayTrackWrite> toggle(PrayerKey prayer, LumeDate date) =>
      _write<PrayerCheckin?>((_Data d) {
        final PrayerCheckin? existing = d.at(date, prayer);
        if (existing != null) {
          d.tx.delete(
            PrayTrackCollections.checkins,
            existing.id.value,
            expectVersion: existing.version,
          );
          d.checkins.removeWhere((PrayerCheckin x) => x.id == existing.id);
          return null;
        }
        final PrayerCheckin c = PrayerCheckin(
          id: _newId(),
          date: date,
          prayer: prayer,
          createdAt: _now(),
        );
        final PrayerCheckin stored = PrayerCheckin.decode(
          d.tx.create(PrayTrackCollections.checkins, c.id.value, c.toFields()),
        );
        d.checkins.add(stored);
        return stored;
      });

  /// Reverse a committed toggle, restoring the same id and version.
  PrayTrackResult<void> undo(PrayTrackWrite write) {
    final LumeTxResult<void> r = _store.revert(write.receipt);
    return r.ok
        ? const PrayTrackResult<void>.ok(null)
        : PrayTrackResult<void>.failed(_map(r.failure!));
  }

  PrayTrackResult<PrayTrackWrite> _write<T>(T Function(_Data d) body) {
    final LumeTxResult<T> r = _store.run<T>((LumeRecordTx tx) {
      final _Data d = _Data(tx);
      return body(d);
    });
    if (!r.ok) return PrayTrackResult<PrayTrackWrite>.failed(_map(r.failure!));
    final T v = r.value as T;
    return PrayTrackResult<PrayTrackWrite>.ok(
      PrayTrackWrite(r.receipt!, checkin: v is PrayerCheckin ? v : null),
    );
  }

  static PrayTrackFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected => f.detail is PrayTrackFailure
        ? f.detail! as PrayTrackFailure
        : PrayTrackFailure(PrayTrackFailureKind.storage, cause: f.kind),
    LumeTxFailureKind.conflict ||
    LumeTxFailureKind.duplicateId => PrayTrackFailure(
      PrayTrackFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => PrayTrackFailure(
      PrayTrackFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => PrayTrackFailure(
      PrayTrackFailureKind.storage,
      cause: f.kind,
    ),
  };
}

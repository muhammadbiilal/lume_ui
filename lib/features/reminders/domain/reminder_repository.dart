/// Reminders' records, read and written through the record layer's
/// transactions, and kept in step with a real scheduled notification
/// (`REMINDERS_PROPOSAL.md`).
///
/// One flat collection, like Meal Plan's — no aggregate parent, no money.
/// **Unlike every other family's repository, this one's writes are
/// `Future`s.** Every other repository here answers synchronously because
/// the record store itself does; this one also has to wait on
/// [LumeReminderScheduler], a real platform call that a synchronous method
/// cannot represent honestly. The record write inside it still happens
/// synchronously, first — a scheduling failure never loses what the reader
/// typed, it only means the record now needs the reader to grant a
/// permission or open the app again before it can fire (`scheduleOutcome`).
library;

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import '../data/reminder_scheduler.dart';
import 'reminder_book.dart';
import 'reminder_failure.dart';
import 'reminder_model.dart';

@immutable
class ReminderWrite {
  const ReminderWrite(this.receipt, {this.entry, this.scheduleOutcome});
  final LumeTxReceipt receipt;
  final ReminderEntry? entry;
  final ReminderScheduleOutcome? scheduleOutcome;
}

@immutable
class ReminderSnapshot {
  const ReminderSnapshot({
    required this.status,
    this.entries = const <ReminderEntry>[],
    this.defects = const <ReminderDefect>[],
  });

  final LumeCollectionStatus status;
  final List<ReminderEntry> entries;
  final List<ReminderDefect> defects;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;

  ReminderBook get book => ReminderBook(entries);
}

class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(ReminderCollections.entries)) {
      try {
        entries.add(ReminderEntry.decode(r));
      } on ReminderDefectException catch (e) {
        defects.add(e.defect);
      }
    }
  }

  final LumeRecordTx tx;
  final List<ReminderEntry> entries = <ReminderEntry>[];
  final List<ReminderDefect> defects = <ReminderDefect>[];
}

class ReminderRepository {
  ReminderRepository(
    this._store,
    this._scheduler, {
    Random? random,
    DateTime Function()? now,
  }) : _random = random ?? Random.secure(),
       _now = now ?? DateTime.now;

  final LumeRecordRepository _store;
  final LumeReminderScheduler _scheduler;
  final Random _random;
  final DateTime Function() _now;

  Listenable get changes => _store;

  bool get durable => _store.durable;

  LumeRecordId _newId() => LumeRecordId.generate(_random);

  void open() => _store.open(ReminderCollections.entries);

  void retry() {
    if (_store.view(ReminderCollections.entries).status == LumeCollectionStatus.error) {
      _store.retry(ReminderCollections.entries);
    }
  }

  ReminderSnapshot view() {
    final LumeCollectionView v = _store.view(ReminderCollections.entries);
    if (v.status == LumeCollectionStatus.error) {
      return const ReminderSnapshot(status: LumeCollectionStatus.error);
    }
    if (v.status == LumeCollectionStatus.loading) {
      return const ReminderSnapshot(status: LumeCollectionStatus.loading);
    }
    final List<ReminderDefect> defects = <ReminderDefect>[];
    final List<ReminderEntry> out = <ReminderEntry>[];
    for (final LumeRecord r in v.items) {
      try {
        out.add(ReminderEntry.decode(r));
      } on ReminderDefectException catch (e) {
        defects.add(e.defect);
      }
    }
    return ReminderSnapshot(status: v.status, entries: out, defects: defects);
  }

  Future<ReminderResult<ReminderWrite>> add({
    required String label,
    required int atHour,
    required int atMinute,
    ReminderRepeat repeat = ReminderRepeat.once,
    String? notes,
    required String? zoneId,
  }) async {
    final String trimmed = label.trim();
    if (trimmed.isEmpty) {
      return const ReminderResult<ReminderWrite>.failed(
        ReminderFailure.validation('label', 'required'),
      );
    }
    if (trimmed.length > kReminderLabelMax) {
      return const ReminderResult<ReminderWrite>.failed(
        ReminderFailure.validation('label', 'long'),
      );
    }
    final ReminderEntry entry = ReminderEntry(
      id: _newId(),
      label: trimmed,
      atHour: atHour,
      atMinute: atMinute,
      repeat: repeat,
      notes: notes?.trim().isEmpty ?? true ? null : notes!.trim(),
      createdAt: _now(),
    );
    final LumeTxResult<ReminderEntry> r = _store.run<ReminderEntry>((LumeRecordTx tx) {
      final _Data d = _Data(tx);
      final LumeRecord stored = d.tx.create(
        ReminderCollections.entries,
        entry.id.value,
        entry.toFields(),
      );
      return ReminderEntry.decode(stored);
    });
    if (!r.ok) return ReminderResult<ReminderWrite>.failed(_map(r.failure!));
    final ReminderScheduleOutcome outcome = await _scheduler.schedule(r.value!, zoneId: zoneId);
    return ReminderResult<ReminderWrite>.ok(
      ReminderWrite(r.receipt!, entry: r.value, scheduleOutcome: outcome),
    );
  }

  Future<ReminderResult<ReminderWrite>> edit(
    LumeRecordId id, {
    String? label,
    int? atHour,
    int? atMinute,
    ReminderRepeat? repeat,
    Object? notes = _sentinel,
    bool? enabled,
    required String? zoneId,
  }) async {
    final ReminderSnapshot s = view();
    ReminderEntry? existing;
    for (final ReminderEntry e in s.entries) {
      if (e.id == id) existing = e;
    }
    if (existing == null) {
      return ReminderResult<ReminderWrite>.failed(
        ReminderFailure(ReminderFailureKind.notFound, ids: <LumeRecordId>[id]),
      );
    }
    if (label != null) {
      final String trimmed = label.trim();
      if (trimmed.isEmpty) {
        return const ReminderResult<ReminderWrite>.failed(
          ReminderFailure.validation('label', 'required'),
        );
      }
      if (trimmed.length > kReminderLabelMax) {
        return const ReminderResult<ReminderWrite>.failed(
          ReminderFailure.validation('label', 'long'),
        );
      }
    }
    final ReminderEntry next = existing.copyWith(
      label: label,
      atHour: atHour,
      atMinute: atMinute,
      repeat: repeat,
      notes: identical(notes, _sentinel) ? _sentinel : notes,
      enabled: enabled,
    );
    final LumeTxResult<ReminderEntry> r = _store.run<ReminderEntry>((LumeRecordTx tx) {
      final LumeRecord stored = tx.update(
        ReminderCollections.entries,
        id.value,
        next.toFields(),
        expectVersion: existing!.version,
      );
      return ReminderEntry.decode(stored);
    });
    if (!r.ok) return ReminderResult<ReminderWrite>.failed(_map(r.failure!));
    final ReminderScheduleOutcome outcome = await _scheduler.schedule(r.value!, zoneId: zoneId);
    return ReminderResult<ReminderWrite>.ok(
      ReminderWrite(r.receipt!, entry: r.value, scheduleOutcome: outcome),
    );
  }

  Future<ReminderResult<ReminderWrite>> setEnabled(
    LumeRecordId id,
    bool enabled, {
    required String? zoneId,
  }) => edit(id, enabled: enabled, zoneId: zoneId);

  Future<ReminderResult<ReminderWrite>> remove(LumeRecordId id) async {
    final ReminderSnapshot s = view();
    ReminderEntry? existing;
    for (final ReminderEntry e in s.entries) {
      if (e.id == id) existing = e;
    }
    if (existing == null) {
      return ReminderResult<ReminderWrite>.failed(
        ReminderFailure(ReminderFailureKind.notFound, ids: <LumeRecordId>[id]),
      );
    }
    final LumeTxResult<ReminderEntry> r = _store.run<ReminderEntry>((LumeRecordTx tx) {
      tx.delete(ReminderCollections.entries, id.value, expectVersion: existing!.version);
      return existing;
    });
    if (!r.ok) return ReminderResult<ReminderWrite>.failed(_map(r.failure!));
    await _scheduler.cancel(id);
    return ReminderResult<ReminderWrite>.ok(ReminderWrite(r.receipt!, entry: r.value));
  }

  Future<ReminderResult<void>> undo(ReminderWrite write, {required String? zoneId}) async {
    if (write.receipt.revision == 0) return const ReminderResult<void>.ok(null);
    final LumeTxResult<void> r = _store.revert(write.receipt);
    if (!r.ok) return ReminderResult<void>.failed(_map(r.failure!));
    // The record is back; put its notification back with it.
    final ReminderEntry? entry = write.entry;
    if (entry != null) {
      final ReminderEntry? restored = view().entries
          .cast<ReminderEntry?>()
          .firstWhere((ReminderEntry? e) => e?.id == entry.id, orElse: () => null);
      if (restored != null) {
        await _scheduler.schedule(restored, zoneId: zoneId);
      } else {
        await _scheduler.cancel(entry.id);
      }
    }
    return const ReminderResult<void>.ok(null);
  }

  static ReminderFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected => f.detail! as ReminderFailure,
    LumeTxFailureKind.conflict ||
    LumeTxFailureKind.duplicateId => ReminderFailure(
      ReminderFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => ReminderFailure(
      ReminderFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => ReminderFailure(
      ReminderFailureKind.storage,
      cause: f.kind,
    ),
  };
}

const Object _sentinel = Object();

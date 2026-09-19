/// Several records, in several collections, written as one — or not at all.
///
/// A family whose records depend on each other (a repayment and the
/// allocations that apply it) cannot be kept consistent one write at a time:
/// between the second and third write an observer would see a repayment
/// applied to nothing. A transaction reads one consistent snapshot, stages
/// its creates, updates and deletes in a write set of its own, and publishes
/// them in one step when it commits — every change, or none.
///
/// **Optimistic.** [LumeRecordTransactions.begin] takes a snapshot; nothing
/// is locked. Every record a transaction reads, and every collection it
/// lists, is remembered with the version it saw; [LumeRecordTransactions.commit]
/// refuses with [LumeTxFailureKind.conflict] if any of them has changed
/// since, so two transactions begun together cannot both write what the
/// other read.
///
/// **Observers see before or after, never between.** Staged changes are
/// invisible outside the transaction; a successful commit notifies once; a
/// failed one changes nothing and notifies no one.
///
/// **Retries are safe.** A command may carry an idempotency key and a
/// fingerprint of its payload: committing the same key and fingerprint again
/// returns the first result without writing twice; the same key with another
/// payload is refused.
library;

import 'package:flutter/foundation.dart';

import 'record_model.dart';

/// Why a transaction did not commit.
enum LumeTxFailureKind {
  /// A record or collection it read changed before it committed, or an
  /// expected version did not match.
  conflict,

  /// A create named an id the collection holds, or has ever held.
  duplicateId,

  /// An update or delete named a record that is not there.
  missing,

  /// A collection it touched has not been read yet, or cannot be.
  unavailable,

  /// The caller refused its own write set (the family's rules failed).
  rejected,

  /// The store could not publish it. Nothing was written.
  storage,

  /// An idempotency key already used for a different payload.
  idempotencyMismatch,
}

/// A transaction refused, and where. [detail] is the caller's typed reason
/// for a [LumeTxFailureKind.rejected] write set.
@immutable
class LumeTxFailure implements Exception {
  const LumeTxFailure(
    this.kind, {
    this.collection,
    this.id,
    this.current,
    this.detail,
  });

  final LumeTxFailureKind kind;
  final String? collection;
  final String? id;

  /// On a conflict, the record as it now is.
  final LumeRecord? current;

  /// The caller's own reason, carried through untouched.
  final Object? detail;

  @override
  String toString() =>
      'LumeTxFailure(${kind.name}'
      '${collection == null ? '' : ', $collection'}'
      '${id == null ? '' : '/$id'}'
      '${detail == null ? '' : ', $detail'})';
}

/// One record changed by a committed transaction: what it was and what it
/// became (`null` for "absent").
@immutable
class LumeTxChange {
  const LumeTxChange(this.collection, this.id, this.before, this.after);

  final String collection;
  final String id;
  final LumeRecord? before;
  final LumeRecord? after;
}

/// What a committed transaction did — enough to reverse it
/// ([LumeRecordTransactions.revert]) with the same ids.
@immutable
class LumeTxReceipt {
  const LumeTxReceipt(this.revision, this.changes, {this.replayed = false});

  /// The store's revision this commit produced.
  final int revision;

  /// In the order they were staged.
  final List<LumeTxChange> changes;

  /// A retried command: the first commit's receipt, returned without
  /// writing again.
  final bool replayed;
}

/// A transaction's outcome: its value and receipt, or why nothing happened.
@immutable
class LumeTxResult<T> {
  const LumeTxResult.ok(T this.value, LumeTxReceipt this.receipt)
    : failure = null;

  const LumeTxResult.failed(LumeTxFailure this.failure)
    : value = null,
      receipt = null;

  final T? value;
  final LumeTxReceipt? receipt;
  final LumeTxFailure? failure;

  bool get ok => failure == null;
}

/// An open transaction: reads through its snapshot and its own writes.
///
/// Every method throws [LumeTxFailure] on a refusal; [LumeRecordTransactions.run]
/// turns that into a failed result with nothing written.
abstract interface class LumeRecordTx {
  /// One record as this transaction sees it, or `null`.
  LumeRecord? get(String collection, String id);

  /// Every record of [collection] as this transaction sees it, newest first.
  List<LumeRecord> all(String collection);

  /// A new record with the caller's [id] — made once, never reused.
  LumeRecord create(String collection, String id, Map<String, Object?> fields);

  /// Replace a record's fields; [expectVersion] must be the version this
  /// transaction sees.
  LumeRecord update(
    String collection,
    String id,
    Map<String, Object?> fields, {
    required int expectVersion,
  });

  /// Remove a record; [expectVersion] as for [update].
  void delete(String collection, String id, {required int expectVersion});

  /// Refuse the whole write set with the caller's own [detail].
  Never reject(Object detail);
}

/// Stores that can commit several records at once.
abstract interface class LumeRecordTransactions implements Listenable {
  /// A transaction over a snapshot of the store as it is now.
  LumeRecordTx begin();

  /// Publish [tx]'s write set, all of it or none, and return [value] with a
  /// receipt. [idempotencyKey] and [fingerprint] make a retried command
  /// safe (see the library doc).
  LumeTxResult<T> commit<T>(
    LumeRecordTx tx,
    T value, {
    String? idempotencyKey,
    String? fingerprint,
  });

  /// [begin], [body], [commit] — a failure thrown by [body] is returned, and
  /// nothing is written.
  LumeTxResult<T> run<T>(
    T Function(LumeRecordTx tx) body, {
    String? idempotencyKey,
    String? fingerprint,
  });

  /// Reverse a committed transaction as one more transaction: created
  /// records removed, updated ones given their fields back, removed ones
  /// restored with their ids. Refused as a conflict if any of them has
  /// changed since.
  LumeTxResult<void> revert(LumeTxReceipt receipt);
}

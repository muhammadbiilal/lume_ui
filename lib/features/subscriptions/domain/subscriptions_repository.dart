/// Subscriptions' records, read and written through the record layer's
/// transactions (`SUBSCRIPTIONS_PROPOSAL.md`).
///
/// One collection, no children: a subscription is a single row, edited in
/// place (unlike Installments/Goals, nothing about a subscription is
/// locked once it exists — a plan's price or cycle genuinely can change).
/// Nothing is seeded: a reader's Subscriptions starts empty (Option B).
library;

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_currency_policy.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import 'subscriptions_book.dart';
import 'subscriptions_failure.dart';
import 'subscriptions_model.dart';

/// What the reader filled in for a subscription.
@immutable
class SubscriptionDraft {
  const SubscriptionDraft({
    required this.name,
    this.category,
    required this.amount,
    required this.cycle,
    this.customDays,
    required this.startedOn,
    this.tone = SubscriptionTone.sky,
  });

  final String name;
  final String? category;
  final LumeMoney amount;
  final SubscriptionCycle cycle;
  final int? customDays;
  final LumeDate startedOn;
  final SubscriptionTone tone;

  LumeCurrency get currency => amount.currency;

  String get fingerprint => jsonEncode(<String, Object?>{
    'n': name,
    'cat': category,
    'a': amount.minor,
    'c': amount.currency.code,
    'cy': cycle.name,
    'cd': customDays,
    's': startedOn.toIso(),
  });
}

@immutable
class SubscriptionsWrite {
  const SubscriptionsWrite(this.receipt, {this.subscription});
  final LumeTxReceipt receipt;
  final Subscription? subscription;
}

@immutable
class SubscriptionsSnapshot {
  const SubscriptionsSnapshot({
    required this.status,
    this.subscriptions = const <Subscription>[],
    this.defects = const <SubscriptionsDefect>[],
  });

  final LumeCollectionStatus status;
  final List<Subscription> subscriptions;
  final List<SubscriptionsDefect> defects;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;

  SubscriptionsBook book(LumeDate? today) =>
      SubscriptionsBook.from(subscriptions: subscriptions, defects: defects, today: today);
}

class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(SubscriptionsCollections.subscriptions)) {
      try {
        subscriptions.add(Subscription.decode(r));
      } on SubscriptionsDefectException catch (e) {
        defects.add(e.defect);
      }
    }
  }

  final LumeRecordTx tx;
  final List<Subscription> subscriptions = <Subscription>[];
  final List<SubscriptionsDefect> defects = <SubscriptionsDefect>[];

  Subscription sound(LumeRecordId id) {
    for (final Subscription s in subscriptions) {
      if (s.id == id) return s;
    }
    throw SubscriptionsFailure(
      SubscriptionsFailureKind.notFound,
      ids: <LumeRecordId>[id],
    );
  }
}

class SubscriptionsRepository {
  SubscriptionsRepository(this._store, {Random? random, DateTime Function()? now})
    : _random = random ?? Random.secure(),
      _now = now ?? DateTime.now;

  final LumeRecordRepository _store;
  final Random _random;
  final DateTime Function() _now;

  Listenable get changes => _store;

  /// Option B: always `false` today; a screen that would claim durability
  /// reads this first (matches every other financial record family here).
  bool get durable => _store.durable;

  LumeRecordId _newId() => LumeRecordId.generate(_random);

  void open() {
    for (final String c in SubscriptionsCollections.all) {
      _store.open(c);
    }
  }

  void retry() {
    for (final String c in SubscriptionsCollections.all) {
      if (_store.view(c).status == LumeCollectionStatus.error) {
        _store.retry(c);
      }
    }
  }

  SubscriptionsSnapshot view() {
    final LumeCollectionView v = _store.view(SubscriptionsCollections.subscriptions);
    if (v.status == LumeCollectionStatus.error) {
      return const SubscriptionsSnapshot(status: LumeCollectionStatus.error);
    }
    if (v.status == LumeCollectionStatus.loading) {
      return const SubscriptionsSnapshot(status: LumeCollectionStatus.loading);
    }
    final List<SubscriptionsDefect> defects = <SubscriptionsDefect>[];
    final List<Subscription> out = <Subscription>[];
    for (final LumeRecord r in v.items) {
      try {
        out.add(Subscription.decode(r));
      } on SubscriptionsDefectException catch (e) {
        defects.add(e.defect);
      }
    }
    return SubscriptionsSnapshot(status: v.status, subscriptions: out, defects: defects);
  }

  SubscriptionsResult<SubscriptionsWrite> add(
    SubscriptionDraft draft, {
    String? idempotencyKey,
  }) => _write<Subscription>(
    (_Data d) {
      _validate(draft);
      if (!LumeCurrencyPolicy.of(draft.currency).usable) {
        throw const SubscriptionsFailure.validation('currency', 'withdrawn');
      }
      final Subscription s = _subscription(_newId(), draft, _now());
      final LumeRecord r = d.tx.create(
        SubscriptionsCollections.subscriptions,
        s.id.value,
        s.toFields(),
      );
      final Subscription stored = Subscription.decode(r);
      d.subscriptions.add(stored);
      return stored;
    },
    idempotencyKey: idempotencyKey,
    fingerprint: idempotencyKey == null ? null : draft.fingerprint,
  );

  /// Edit a subscription — every field, at any time. A plan's price or
  /// cycle genuinely can change; nothing here is locked by history the way
  /// an instalment plan's terms are.
  SubscriptionsResult<SubscriptionsWrite> edit(
    LumeRecordId id,
    SubscriptionDraft draft, {
    required int version,
  }) => _write<Subscription>((_Data d) {
    final Subscription was = d.sound(id);
    _validate(draft);
    if (!LumeCurrencyPolicy.of(
      draft.currency,
      existing: <LumeCurrency>[was.currency],
    ).usable) {
      throw const SubscriptionsFailure.validation('currency', 'withdrawn');
    }
    final Subscription now = _subscription(
      was.id,
      draft,
      was.createdAt,
      state: was.state,
      cancelledAt: was.cancelledAt,
    );
    final LumeRecord r = d.tx.update(
      SubscriptionsCollections.subscriptions,
      id.value,
      now.toFields(),
      expectVersion: version,
    );
    final Subscription stored = Subscription.decode(r);
    d.subscriptions[d.subscriptions.indexWhere((Subscription x) => x.id == id)] = stored;
    return stored;
  });

  /// Cancel, or reactivate. Kept whole either way — never a delete.
  SubscriptionsResult<SubscriptionsWrite> setCancelled(
    LumeRecordId id,
    bool cancelled, {
    required int version,
  }) => _write<Subscription>((_Data d) {
    final Subscription was = d.sound(id);
    final LumeRecord r = d.tx.update(
      SubscriptionsCollections.subscriptions,
      id.value,
      was
          .copyWith(
            state: cancelled ? SubscriptionState.cancelled : SubscriptionState.active,
            cancelledAt: cancelled ? _now() : null,
            clearCancelledAt: !cancelled,
          )
          .toFields(),
      expectVersion: version,
    );
    final Subscription stored = Subscription.decode(r);
    d.subscriptions[d.subscriptions.indexWhere((Subscription x) => x.id == id)] = stored;
    return stored;
  });

  SubscriptionsResult<SubscriptionsWrite> delete(
    LumeRecordId id, {
    required int version,
  }) => _write<Subscription>((_Data d) {
    final Subscription was = d.sound(id);
    d.tx.delete(SubscriptionsCollections.subscriptions, id.value, expectVersion: version);
    d.subscriptions.removeWhere((Subscription x) => x.id == id);
    d.defects.removeWhere((SubscriptionsDefect x) => x.recordId == id.value);
    return was;
  });

  SubscriptionsResult<void> undo(SubscriptionsWrite write) {
    final LumeTxResult<void> r = _store.revert(write.receipt);
    return r.ok
        ? const SubscriptionsResult<void>.ok(null)
        : SubscriptionsResult<void>.failed(_map(r.failure!));
  }

  // ---- internals ----------------------------------------------------------

  Subscription _subscription(
    LumeRecordId id,
    SubscriptionDraft draft,
    DateTime createdAt, {
    SubscriptionState state = SubscriptionState.active,
    DateTime? cancelledAt,
  }) => Subscription(
    id: id,
    name: draft.name.trim(),
    category: _optional(draft.category),
    amount: draft.amount,
    cycle: draft.cycle,
    customDays: draft.cycle == SubscriptionCycle.custom ? draft.customDays : null,
    startedOn: draft.startedOn,
    tone: draft.tone,
    state: state,
    createdAt: createdAt,
    cancelledAt: cancelledAt,
  );

  static void _validate(SubscriptionDraft draft) {
    final String name = draft.name.trim();
    if (name.isEmpty) {
      throw const SubscriptionsFailure.validation('name', 'required');
    }
    if (name.length > kSubscriptionsNameMax) {
      throw const SubscriptionsFailure.validation('name', 'long');
    }
    if ((draft.category?.trim().length ?? 0) > kSubscriptionsCategoryMax) {
      throw const SubscriptionsFailure.validation('category', 'long');
    }
    if (draft.amount.isZero) {
      throw const SubscriptionsFailure.validation('amount', 'zero');
    }
    if (draft.cycle == SubscriptionCycle.custom) {
      final int? d = draft.customDays;
      if (d == null || d < 1 || d > 3660) {
        throw const SubscriptionsFailure.validation('customDays', 'range');
      }
    }
    // amount.minor / customDays * 30 must not overflow — divide first
    // (subscriptions_book.dart), so the only remaining bound is the entry
    // amount itself, already enforced by LumeMoney.entry.
  }

  static String? _optional(String? s) =>
      s == null || s.trim().isEmpty ? null : s.trim();

  SubscriptionsResult<SubscriptionsWrite> _write<T>(
    T Function(_Data d) body, {
    String? idempotencyKey,
    String? fingerprint,
  }) {
    final LumeTxResult<T> r = _store.run<T>((LumeRecordTx tx) {
      try {
        final _Data d = _Data(tx);
        return body(d);
      } on SubscriptionsFailure catch (f) {
        tx.reject(f);
      } on LumeMoneyException catch (e) {
        tx.reject(SubscriptionsFailure(SubscriptionsFailureKind.overflow, cause: e));
      }
    }, idempotencyKey: idempotencyKey, fingerprint: fingerprint);
    if (!r.ok) return SubscriptionsResult<SubscriptionsWrite>.failed(_map(r.failure!));
    final T v = r.value as T;
    return SubscriptionsResult<SubscriptionsWrite>.ok(
      SubscriptionsWrite(r.receipt!, subscription: v is Subscription ? v : null),
    );
  }

  static SubscriptionsFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected => f.detail! as SubscriptionsFailure,
    LumeTxFailureKind.conflict ||
    LumeTxFailureKind.duplicateId => SubscriptionsFailure(
      SubscriptionsFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => SubscriptionsFailure(
      SubscriptionsFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => SubscriptionsFailure(
      SubscriptionsFailureKind.storage,
      cause: f.kind,
    ),
  };

  /// The currency a new subscription defaults to: the reader's, where it
  /// is one a new subscription may use.
  static LumeCurrency? defaultCurrency(String code) {
    final LumeCurrency? c = LumeCurrency.tryOf(code);
    return c != null && LumeCurrencyPolicy.of(c).usable ? c : null;
  }
}

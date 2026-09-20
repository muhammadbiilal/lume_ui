/// Installments' records, read and written through the record layer's
/// transactions (`INSTALLMENTS_PROPOSAL.md` §40).
///
/// Every write is one transaction: a plan with its whole schedule, a
/// payment, a void, a cancellation, a deletion with every record that names
/// the plan. The staged state proves itself before it is published — every
/// invariant holds and no plan is newly damaged — or the whole transaction
/// rolls back, and no observer sees anything in between. Nothing is seeded:
/// a reader's Installments starts empty.
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
import 'installments_book.dart';
import 'installments_failure.dart';
import 'installments_model.dart';
import '../../../core/values/lume_month_anchor.dart';

/// What the reader filled in for a plan.
@immutable
class InstallmentPlanDraft {
  const InstallmentPlanDraft({
    required this.item,
    this.merchant,
    this.note,
    required this.amount,
    required this.count,
    required this.firstDue,
    this.deposit,
    this.depositOn,
    this.cashPrice,
  });

  final String item;
  final String? merchant;
  final String? note;
  final LumeMoney amount;
  final int count;
  final LumeDate firstDue;
  final LumeMoney? deposit;
  final LumeDate? depositOn;
  final LumeMoney? cashPrice;

  LumeCurrency get currency => amount.currency;

  String get fingerprint => jsonEncode(<String, Object?>{
    'i': item,
    'm': merchant,
    'n': note,
    'a': amount.minor,
    'c': amount.currency.code,
    'k': count,
    'f': firstDue.toIso(),
    'd': deposit?.minor,
    'do': depositOn?.toIso(),
    'p': cashPrice?.minor,
  });
}

/// A committed write — enough to show it and to undo it.
@immutable
class InstallmentsWrite {
  const InstallmentsWrite(this.receipt, {this.plan, this.payment});

  final LumeTxReceipt receipt;
  final InstallmentPlan? plan;
  final InstallmentPayment? payment;
}

/// Installments' records as they stand, or why they cannot be shown.
@immutable
class InstallmentsSnapshot {
  const InstallmentsSnapshot({
    required this.status,
    this.plans = const <InstallmentPlan>[],
    this.schedule = const <ScheduledInstallment>[],
    this.payments = const <InstallmentPayment>[],
    this.defects = const <InstallmentsDefect>[],
  });

  final LumeCollectionStatus status;
  final List<InstallmentPlan> plans;
  final List<ScheduledInstallment> schedule;
  final List<InstallmentPayment> payments;
  final List<InstallmentsDefect> defects;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;

  InstallmentsBook book(LumeDate? today) => InstallmentsBook.from(
    plans: plans,
    schedule: schedule,
    payments: payments,
    defects: defects,
    today: today,
  );
}

/// Records decoded inside one transaction.
class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(InstallmentsCollections.plans)) {
      _read(r, InstallmentPlan.decode, plans);
    }
    for (final LumeRecord r in tx.all(InstallmentsCollections.schedule)) {
      _read(r, ScheduledInstallment.decode, schedule);
    }
    for (final LumeRecord r in tx.all(InstallmentsCollections.payments)) {
      _read(r, InstallmentPayment.decode, payments);
    }
    damagedBefore = <String>{
      for (final InstallmentsDamage d in book().damage) d.plan,
    };
  }

  final LumeRecordTx tx;
  final List<InstallmentPlan> plans = <InstallmentPlan>[];
  final List<ScheduledInstallment> schedule = <ScheduledInstallment>[];
  final List<InstallmentPayment> payments = <InstallmentPayment>[];
  final List<InstallmentsDefect> defects = <InstallmentsDefect>[];
  late final Set<String> damagedBefore;

  void _read<T>(LumeRecord r, T Function(LumeRecord) decode, List<T> into) {
    try {
      into.add(decode(r));
    } on InstallmentsDefectException catch (e) {
      defects.add(e.defect);
    }
  }

  InstallmentsBook book() => InstallmentsBook.from(
    plans: plans,
    schedule: schedule,
    payments: payments,
    defects: defects,
    today: null,
  );

  InstallmentPlanView view(LumeRecordId id) {
    final InstallmentPlanView? v = book().plan(id);
    if (v == null) {
      throw InstallmentsFailure(
        InstallmentsFailureKind.notFound,
        ids: <LumeRecordId>[id],
      );
    }
    return v;
  }

  /// A plan a write may touch: there, and not damaged before this write.
  InstallmentPlanView sound(LumeRecordId id) {
    final InstallmentPlanView v = view(id);
    if (damagedBefore.contains(id.value)) {
      throw InstallmentsFailure(
        InstallmentsFailureKind.damaged,
        ids: <LumeRecordId>[id],
      );
    }
    return v;
  }
}

class InstallmentsRepository {
  InstallmentsRepository(
    this._store, {
    Random? random,
    DateTime Function()? now,
  }) : _random = random ?? Random.secure(),
       _now = now ?? DateTime.now;

  final LumeRecordRepository _store;
  final Random _random;
  final DateTime Function() _now;

  /// Told once per committed write.
  Listenable get changes => _store;

  /// Whether a write survives the app closing — the store's answer (C74).
  bool get durable => _store.durable;

  LumeRecordId _newId() => LumeRecordId.generate(_random);

  void open() {
    for (final String c in InstallmentsCollections.all) {
      _store.open(c);
    }
  }

  void retry() {
    for (final String c in InstallmentsCollections.all) {
      if (_store.view(c).status == LumeCollectionStatus.error) {
        _store.retry(c);
      }
    }
  }

  /// The records now, decoded; one that cannot be read is a defect, listed,
  /// never dropped.
  InstallmentsSnapshot view() {
    final List<LumeCollectionView> views = <LumeCollectionView>[
      for (final String c in InstallmentsCollections.all) _store.view(c),
    ];
    if (views.any(
      (LumeCollectionView v) => v.status == LumeCollectionStatus.error,
    )) {
      return const InstallmentsSnapshot(status: LumeCollectionStatus.error);
    }
    if (views.any(
      (LumeCollectionView v) => v.status == LumeCollectionStatus.loading,
    )) {
      return const InstallmentsSnapshot(status: LumeCollectionStatus.loading);
    }
    final List<InstallmentsDefect> defects = <InstallmentsDefect>[];
    List<T> read<T>(LumeCollectionView v, T Function(LumeRecord) decode) => <T>[
      for (final LumeRecord r in v.items)
        ...() {
          try {
            return <T>[decode(r)];
          } on InstallmentsDefectException catch (e) {
            defects.add(e.defect);
            return <T>[];
          }
        }(),
    ];
    return InstallmentsSnapshot(
      status: views.first.status,
      plans: read(views[0], InstallmentPlan.decode),
      schedule: read(views[1], ScheduledInstallment.decode),
      payments: read(views[2], InstallmentPayment.decode),
      defects: defects,
    );
  }

  // ---- plans --------------------------------------------------------------

  /// Add a plan and its whole schedule, generated once and stored.
  InstallmentsResult<InstallmentsWrite> addPlan(
    InstallmentPlanDraft draft, {
    String? idempotencyKey,
  }) => _write<InstallmentPlan>(
    (_Data d) {
      _validate(draft);
      // A new plan is a new obligation: a withdrawn currency is not for it.
      if (!LumeCurrencyPolicy.of(draft.currency).usable) {
        throw const InstallmentsFailure.validation('currency', 'withdrawn');
      }
      final InstallmentPlan p = _plan(_newId(), draft, _now());
      d.tx.create(InstallmentsCollections.plans, p.id.value, p.toFields());
      d.plans.add(p);
      _schedule(d, p);
      return InstallmentPlan.decode(
        d.tx.get(InstallmentsCollections.plans, p.id.value)!,
      );
    },
    idempotencyKey: idempotencyKey,
    fingerprint: idempotencyKey == null ? null : draft.fingerprint,
  );

  /// Edit a plan. Item, merchant and note always; the terms — amount,
  /// count, currency, first due date, deposit — only while no payment
  /// exists, and then the schedule is replaced, with new ids, in the same
  /// transaction. With any payment, a changed term is a typed `locked`
  /// failure naming the field, and nothing is written.
  InstallmentsResult<InstallmentsWrite> editPlan(
    LumeRecordId id,
    InstallmentPlanDraft draft, {
    required int version,
  }) => _write<InstallmentPlan>((_Data d) {
    final InstallmentPlanView v = d.sound(id);
    final InstallmentPlan was = v.plan;
    // A locked term is refused as locked, before anything else is asked of
    // it.
    final String? changed = _changedTerm(was, draft);
    if (changed != null && v.hasPayments) {
      throw InstallmentsFailure(
        InstallmentsFailureKind.locked,
        field: changed,
        ids: <LumeRecordId>[id],
      );
    }
    _validate(draft);
    if (!LumeCurrencyPolicy.of(
      draft.currency,
      existing: <LumeCurrency>[was.currency],
    ).usable) {
      throw const InstallmentsFailure.validation('currency', 'withdrawn');
    }
    final InstallmentPlan now = _plan(
      was.id,
      draft,
      was.createdAt,
      state: was.state,
    );
    final LumeRecord r = d.tx.update(
      InstallmentsCollections.plans,
      id.value,
      now.toFields(),
      expectVersion: version,
    );
    d.plans[d.plans.indexWhere((InstallmentPlan x) => x.id == id)] =
        InstallmentPlan.decode(r);
    if (changed != null) {
      for (final InstallmentRow row in v.rows) {
        d.tx.delete(
          InstallmentsCollections.schedule,
          row.row.id.value,
          expectVersion: row.row.version,
        );
        d.schedule.removeWhere((ScheduledInstallment x) => x.id == row.row.id);
      }
      _schedule(d, now);
    }
    return InstallmentPlan.decode(r);
  });

  /// Cancel a plan — kept whole, with its schedule and payments — or
  /// reinstate one. A completed plan has nothing to cancel.
  InstallmentsResult<InstallmentsWrite> setCancelled(
    LumeRecordId id,
    bool cancelled, {
    required int version,
  }) => _write<InstallmentPlan>((_Data d) {
    final InstallmentPlanView v = d.sound(id);
    if (cancelled && v.status == InstallmentPlanStatus.completed) {
      throw InstallmentsFailure(
        InstallmentsFailureKind.completed,
        ids: <LumeRecordId>[id],
      );
    }
    final LumeRecord r = d.tx.update(
      InstallmentsCollections.plans,
      id.value,
      v.plan
          .copyWith(
            state: cancelled
                ? InstallmentPlanState.cancelled
                : InstallmentPlanState.active,
          )
          .toFields(),
      expectVersion: version,
    );
    d.plans[d.plans.indexWhere((InstallmentPlan x) => x.id == id)] =
        InstallmentPlan.decode(r);
    return InstallmentPlan.decode(r);
  });

  /// Delete a plan made by mistake: the plan, every scheduled instalment and
  /// every payment that names it — records that cannot be read included —
  /// in one transaction, so nothing is left behind. [undo] brings back the
  /// same ids and versions.
  InstallmentsResult<InstallmentsWrite> deletePlan(
    LumeRecordId id, {
    required int version,
  }) => _write<InstallmentPlan>((_Data d) {
    final InstallmentPlanView v = d.view(id);
    for (final String c in <String>[
      InstallmentsCollections.payments,
      InstallmentsCollections.schedule,
    ]) {
      for (final LumeRecord r in d.tx.all(c)) {
        if (r['plan'] == id.value) {
          d.tx.delete(c, r.id, expectVersion: r.version);
        }
      }
    }
    d.tx.delete(
      InstallmentsCollections.plans,
      id.value,
      expectVersion: version,
    );
    d.plans.removeWhere((InstallmentPlan x) => x.id == id);
    d.schedule.removeWhere((ScheduledInstallment x) => x.planId == id);
    d.payments.removeWhere((InstallmentPayment x) => x.planId == id);
    d.defects.removeWhere((InstallmentsDefect x) => x.planId == id.value);
    d.damagedBefore.remove(id.value);
    return v.plan;
  });

  // ---- payments -----------------------------------------------------------

  /// Pay one scheduled instalment, in full, at its amount — the earliest
  /// unpaid one; any other is `outOfOrder`, naming the one to pay first.
  InstallmentsResult<InstallmentsWrite> recordPayment(
    LumeRecordId planId,
    LumeRecordId installmentId,
    LumeDate paidOn, {
    String? idempotencyKey,
  }) => _write<InstallmentPayment>(
    (_Data d) {
      final InstallmentPlanView v = d.sound(planId);
      if (v.plan.cancelled) {
        throw InstallmentsFailure(
          InstallmentsFailureKind.cancelled,
          ids: <LumeRecordId>[planId],
        );
      }
      final InstallmentRow? row = v.rows
          .where((InstallmentRow r) => r.row.id == installmentId)
          .firstOrNull;
      if (row == null) {
        throw InstallmentsFailure(
          InstallmentsFailureKind.notFound,
          ids: <LumeRecordId>[installmentId],
        );
      }
      if (row.paid) {
        throw InstallmentsFailure(
          InstallmentsFailureKind.alreadyPaid,
          ids: <LumeRecordId>[installmentId],
        );
      }
      final InstallmentRow next = v.next!;
      if (next.row.id != installmentId) {
        throw InstallmentsFailure(
          InstallmentsFailureKind.outOfOrder,
          ids: <LumeRecordId>[next.row.id],
        );
      }
      final InstallmentPayment p = InstallmentPayment(
        id: _newId(),
        planId: planId,
        installmentId: installmentId,
        amount: row.row.amount,
        paidOn: paidOn,
        createdAt: _now(),
      );
      final InstallmentPayment stored = InstallmentPayment.decode(
        d.tx.create(InstallmentsCollections.payments, p.id.value, p.toFields()),
      );
      d.payments.add(stored);
      return stored;
    },
    idempotencyKey: idempotencyKey,
    fingerprint: idempotencyKey == null
        ? null
        : '${planId.value}|${installmentId.value}|${paidOn.toIso()}',
  );

  /// Void a payment (the instalment is unpaid again; the record is kept),
  /// or restore it — refused when the instalment has been paid again since.
  InstallmentsResult<InstallmentsWrite> setPaymentVoided(
    LumeRecordId paymentId,
    bool voided, {
    required int version,
  }) => _write<InstallmentPayment>((_Data d) {
    final InstallmentPayment? p = d.payments
        .where((InstallmentPayment x) => x.id == paymentId)
        .firstOrNull;
    if (p == null) {
      throw InstallmentsFailure(
        InstallmentsFailureKind.notFound,
        ids: <LumeRecordId>[paymentId],
      );
    }
    final InstallmentPlanView v = d.sound(p.planId);
    if (v.plan.cancelled) {
      throw InstallmentsFailure(
        InstallmentsFailureKind.cancelled,
        ids: <LumeRecordId>[p.planId],
      );
    }
    if (!voided &&
        d.payments.any(
          (InstallmentPayment x) =>
              x.active && x.installmentId == p.installmentId && x.id != p.id,
        )) {
      throw InstallmentsFailure(
        InstallmentsFailureKind.alreadyPaid,
        ids: <LumeRecordId>[p.installmentId],
      );
    }
    final LumeRecord r = d.tx.update(
      InstallmentsCollections.payments,
      p.id.value,
      p
          .withState(
            voided
                ? InstallmentPaymentState.voided
                : InstallmentPaymentState.active,
          )
          .toFields(),
      expectVersion: version,
    );
    final InstallmentPayment stored = InstallmentPayment.decode(r);
    d.payments[d.payments.indexWhere((InstallmentPayment x) => x.id == p.id)] =
        stored;
    return stored;
  });

  /// Reverse a committed write — a delete's or a cancellation's Undo —
  /// restoring the same ids and versions.
  InstallmentsResult<void> undo(InstallmentsWrite write) {
    final LumeTxResult<void> r = _store.revert(write.receipt);
    return r.ok
        ? const InstallmentsResult<void>.ok(null)
        : InstallmentsResult<void>.failed(_map(r.failure!));
  }

  // ---- internals ----------------------------------------------------------

  InstallmentPlan _plan(
    LumeRecordId id,
    InstallmentPlanDraft draft,
    DateTime createdAt, {
    InstallmentPlanState state = InstallmentPlanState.active,
  }) => InstallmentPlan(
    id: id,
    item: draft.item.trim(),
    merchant: _optional(draft.merchant),
    note: _optional(draft.note),
    amount: draft.amount,
    count: draft.count,
    firstDue: draft.firstDue,
    deposit: draft.deposit,
    depositOn: draft.depositOn,
    cashPrice: draft.cashPrice,
    state: state,
    createdAt: createdAt,
  );

  /// The whole schedule of [p], once: one stored row per instalment.
  void _schedule(_Data d, InstallmentPlan p) {
    final List<LumeDate> dues = lumeMonthlyDues(p.firstDue, p.count)!;
    final DateTime at = _now();
    for (int n = 1; n <= p.count; n++) {
      final ScheduledInstallment row = ScheduledInstallment(
        id: _newId(),
        planId: p.id,
        seq: n,
        due: dues[n - 1],
        amount: p.amount,
        createdAt: at,
      );
      d.schedule.add(
        ScheduledInstallment.decode(
          d.tx.create(
            InstallmentsCollections.schedule,
            row.id.value,
            row.toFields(),
          ),
        ),
      );
    }
  }

  /// The first term [draft] changes on [was], by field name, or `null`.
  static String? _changedTerm(InstallmentPlan was, InstallmentPlanDraft draft) {
    if (draft.currency != was.currency) return 'currency';
    if (draft.amount != was.amount) return 'amount';
    if (draft.count != was.count) return 'count';
    if (draft.firstDue != was.firstDue) return 'firstDue';
    if (draft.deposit != was.deposit) return 'deposit';
    if (draft.depositOn != was.depositOn) return 'depositOn';
    return null;
  }

  static void _validate(InstallmentPlanDraft draft) {
    final String item = draft.item.trim();
    if (item.isEmpty) {
      throw const InstallmentsFailure.validation('item', 'required');
    }
    if (item.length > kInstallmentsNameMax) {
      throw const InstallmentsFailure.validation('item', 'long');
    }
    if ((draft.merchant?.trim().length ?? 0) > kInstallmentsNameMax) {
      throw const InstallmentsFailure.validation('merchant', 'long');
    }
    if ((draft.note?.length ?? 0) > kInstallmentsNoteMax) {
      throw const InstallmentsFailure.validation('note', 'long');
    }
    if (draft.amount.isZero) {
      throw const InstallmentsFailure.validation('amount', 'zero');
    }
    if (draft.count < 1 || draft.count > kInstallmentsCountMax) {
      throw const InstallmentsFailure.validation('count', 'range');
    }
    if (draft.amount.minor > LumeMoney.maxSumMinor ~/ draft.count) {
      throw const InstallmentsFailure(
        InstallmentsFailureKind.overflow,
        field: 'amount',
      );
    }
    if (lumeMonthlyDues(draft.firstDue, draft.count) == null) {
      throw const InstallmentsFailure.validation('firstDue', 'range');
    }
    final LumeMoney scheduled = LumeMoney.sum(
      draft.amount.minor * draft.count,
      draft.currency,
    );
    final LumeMoney? deposit = draft.deposit;
    if ((deposit == null) != (draft.depositOn == null)) {
      throw InstallmentsFailure.validation(
        deposit == null ? 'deposit' : 'depositOn',
        'required',
      );
    }
    if (deposit != null) {
      if (deposit.currency != draft.currency) {
        throw const InstallmentsFailure.validation('deposit', 'currency');
      }
      if (deposit.isZero) {
        throw const InstallmentsFailure.validation('deposit', 'zero');
      }
      if (deposit.minor > LumeMoney.maxSumMinor - scheduled.minor) {
        throw const InstallmentsFailure(
          InstallmentsFailureKind.overflow,
          field: 'deposit',
        );
      }
      if (deposit.compareTo(scheduled + deposit) > 0) {
        throw const InstallmentsFailure.validation('deposit', 'exceedsTotal');
      }
    }
    final LumeMoney? cash = draft.cashPrice;
    if (cash != null) {
      if (cash.currency != draft.currency) {
        throw const InstallmentsFailure.validation('cashPrice', 'currency');
      }
      if (cash.isZero) {
        throw const InstallmentsFailure.validation('cashPrice', 'zero');
      }
    }
  }

  static String? _optional(String? s) =>
      s == null || s.trim().isEmpty ? null : s.trim();

  InstallmentsResult<InstallmentsWrite> _write<T>(
    T Function(_Data d) body, {
    String? idempotencyKey,
    String? fingerprint,
  }) {
    final LumeTxResult<T> r = _store.run<T>(
      (LumeRecordTx tx) {
        try {
          final _Data d = _Data(tx);
          final T v = body(d);
          _verify(d);
          return v;
        } on InstallmentsFailure catch (f) {
          tx.reject(f);
        } on LumeMoneyException catch (e) {
          tx.reject(
            InstallmentsFailure(InstallmentsFailureKind.overflow, cause: e),
          );
        }
      },
      idempotencyKey: idempotencyKey,
      fingerprint: fingerprint,
    );
    if (!r.ok) {
      return InstallmentsResult<InstallmentsWrite>.failed(_map(r.failure!));
    }
    final T v = r.value as T;
    return InstallmentsResult<InstallmentsWrite>.ok(
      InstallmentsWrite(
        r.receipt!,
        plan: v is InstallmentPlan ? v : null,
        payment: v is InstallmentPayment ? v : null,
      ),
    );
  }

  /// Every invariant holds on the staged state and no plan the write
  /// reached is newly damaged; otherwise the whole transaction rolls back.
  static void _verify(_Data d) {
    final InstallmentsBook book = d.book();
    final List<String> broken = book.invariants();
    final List<InstallmentsDamage> fresh = <InstallmentsDamage>[
      for (final InstallmentsDamage x in book.damage)
        if (!d.damagedBefore.contains(x.plan)) x,
    ];
    if (broken.isNotEmpty || fresh.isNotEmpty) {
      throw InstallmentsFailure(
        InstallmentsFailureKind.damaged,
        ids: <LumeRecordId>[
          for (final InstallmentsDamage x in fresh)
            ?LumeRecordId.tryParse(x.plan),
        ],
        cause: <Object>[
          ...broken,
          for (final InstallmentsDamage x in fresh) x.reason,
        ],
      );
    }
    // Every sum the screen will draw fits its bound.
    for (final LumeCurrency c in book.currencies) {
      book.summary(c);
    }
  }

  static InstallmentsFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected => f.detail! as InstallmentsFailure,
    LumeTxFailureKind.conflict ||
    LumeTxFailureKind.duplicateId => InstallmentsFailure(
      InstallmentsFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => InstallmentsFailure(
      InstallmentsFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => InstallmentsFailure(
      InstallmentsFailureKind.storage,
      cause: f.kind,
    ),
  };
}

/// The currency a new plan defaults to: the reader's, where it is one a new
/// plan may use.
LumeCurrency? installmentsDefaultCurrency(String code) {
  final LumeCurrency? c = LumeCurrency.tryOf(code);
  return c != null && LumeCurrencyPolicy.of(c).usable ? c : null;
}

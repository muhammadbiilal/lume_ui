/// Goals' records, read and written through the record layer's
/// transactions (`GOALS_PROPOSAL.md`).
///
/// Every write is one transaction: a goal, a contribution, a void, a
/// state change, a deletion with every contribution that names the goal.
/// The staged state proves itself before it is published — every
/// invariant holds and no goal is newly damaged — or the whole
/// transaction rolls back. Nothing is seeded: a reader's Goals starts
/// empty (Option B — session-only, `durable` says so, never claimed
/// otherwise).
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
import 'goals_book.dart';
import 'goals_failure.dart';
import 'goals_model.dart';

/// What the reader filled in for a goal.
@immutable
class GoalDraft {
  const GoalDraft({
    required this.name,
    this.note,
    required this.target,
    this.targetDate,
    this.icon = GoalIcon.target,
  });

  final String name;
  final String? note;
  final LumeMoney target;
  final LumeDate? targetDate;
  final GoalIcon icon;

  LumeCurrency get currency => target.currency;

  String get fingerprint => jsonEncode(<String, Object?>{
    'n': name,
    'note': note,
    'a': target.minor,
    'c': target.currency.code,
    'd': targetDate?.toIso(),
    'i': icon.name,
  });
}

/// A committed write — enough to show it and to undo it.
@immutable
class GoalsWrite {
  const GoalsWrite(this.receipt, {this.goal, this.contribution});

  final LumeTxReceipt receipt;
  final Goal? goal;
  final GoalContribution? contribution;
}

/// Goals' records as they stand, or why they cannot be shown.
@immutable
class GoalsSnapshot {
  const GoalsSnapshot({
    required this.status,
    this.goals = const <Goal>[],
    this.contributions = const <GoalContribution>[],
    this.defects = const <GoalsDefect>[],
  });

  final LumeCollectionStatus status;
  final List<Goal> goals;
  final List<GoalContribution> contributions;
  final List<GoalsDefect> defects;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;

  GoalsBook book(LumeDate? today) => GoalsBook.from(
    goals: goals,
    contributions: contributions,
    defects: defects,
    today: today,
  );
}

/// Records decoded inside one transaction.
class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(GoalsCollections.goals)) {
      _read(r, Goal.decode, goals);
    }
    for (final LumeRecord r in tx.all(GoalsCollections.contributions)) {
      _read(r, GoalContribution.decode, contributions);
    }
    damagedBefore = <String>{for (final GoalsDamage d in book().damage) d.goal};
  }

  final LumeRecordTx tx;
  final List<Goal> goals = <Goal>[];
  final List<GoalContribution> contributions = <GoalContribution>[];
  final List<GoalsDefect> defects = <GoalsDefect>[];
  late final Set<String> damagedBefore;

  void _read<T>(LumeRecord r, T Function(LumeRecord) decode, List<T> into) {
    try {
      into.add(decode(r));
    } on GoalsDefectException catch (e) {
      defects.add(e.defect);
    }
  }

  GoalsBook book() => GoalsBook.from(
    goals: goals,
    contributions: contributions,
    defects: defects,
    today: null,
  );

  GoalView view(LumeRecordId id) {
    final GoalView? v = book().goal(id);
    if (v == null) {
      throw GoalsFailure(GoalsFailureKind.notFound, ids: <LumeRecordId>[id]);
    }
    return v;
  }

  /// A goal a write may touch: there, and not damaged before this write.
  GoalView sound(LumeRecordId id) {
    final GoalView v = view(id);
    if (damagedBefore.contains(id.value)) {
      throw GoalsFailure(GoalsFailureKind.damaged, ids: <LumeRecordId>[id]);
    }
    return v;
  }
}

class GoalsRepository {
  GoalsRepository(this._store, {Random? random, DateTime Function()? now})
    : _random = random ?? Random.secure(),
      _now = now ?? DateTime.now;

  final LumeRecordRepository _store;
  final Random _random;
  final DateTime Function() _now;

  /// Told once per committed write.
  Listenable get changes => _store;

  /// Whether a write survives the app closing — the store's answer.
  /// Option B: always `false` today; the on-screen disclosure reads this,
  /// not a hand-written string, so the day a durable store exists behind
  /// the same interface, the disclosure disappears on its own.
  bool get durable => _store.durable;

  LumeRecordId _newId() => LumeRecordId.generate(_random);

  void open() {
    for (final String c in GoalsCollections.all) {
      _store.open(c);
    }
  }

  void retry() {
    for (final String c in GoalsCollections.all) {
      if (_store.view(c).status == LumeCollectionStatus.error) {
        _store.retry(c);
      }
    }
  }

  /// The records now, decoded; one that cannot be read is a defect,
  /// listed, never dropped.
  GoalsSnapshot view() {
    final List<LumeCollectionView> views = <LumeCollectionView>[
      for (final String c in GoalsCollections.all) _store.view(c),
    ];
    if (views.any(
      (LumeCollectionView v) => v.status == LumeCollectionStatus.error,
    )) {
      return const GoalsSnapshot(status: LumeCollectionStatus.error);
    }
    if (views.any(
      (LumeCollectionView v) => v.status == LumeCollectionStatus.loading,
    )) {
      return const GoalsSnapshot(status: LumeCollectionStatus.loading);
    }
    final List<GoalsDefect> defects = <GoalsDefect>[];
    List<T> read<T>(LumeCollectionView v, T Function(LumeRecord) decode) => <T>[
      for (final LumeRecord r in v.items)
        ...() {
          try {
            return <T>[decode(r)];
          } on GoalsDefectException catch (e) {
            defects.add(e.defect);
            return <T>[];
          }
        }(),
    ];
    return GoalsSnapshot(
      status: views.first.status,
      goals: read(views[0], Goal.decode),
      contributions: read(views[1], GoalContribution.decode),
      defects: defects,
    );
  }

  // ---- goals ---------------------------------------------------------------

  GoalsResult<GoalsWrite> addGoal(GoalDraft draft, {String? idempotencyKey}) =>
      _write<Goal>(
        (_Data d) {
          _validate(draft);
          if (!LumeCurrencyPolicy.of(draft.currency).usable) {
            throw const GoalsFailure.validation('currency', 'withdrawn');
          }
          final Goal g = _goal(_newId(), draft, _now());
          final LumeRecord r = d.tx.create(
            GoalsCollections.goals,
            g.id.value,
            g.toFields(),
          );
          final Goal stored = Goal.decode(r);
          d.goals.add(stored);
          return stored;
        },
        idempotencyKey: idempotencyKey,
        fingerprint: idempotencyKey == null ? null : draft.fingerprint,
      );

  /// Edit a goal — every field, at any time. Unlike a fixed instalment
  /// plan, nothing about a goal is locked by having contributions.
  GoalsResult<GoalsWrite> editGoal(
    LumeRecordId id,
    GoalDraft draft, {
    required int version,
  }) => _write<Goal>((_Data d) {
    final GoalView v = d.sound(id);
    _validate(draft);
    if (!LumeCurrencyPolicy.of(
      draft.currency,
      existing: <LumeCurrency>[v.currency],
    ).usable) {
      throw const GoalsFailure.validation('currency', 'withdrawn');
    }
    if (draft.currency != v.currency && v.contributions.isNotEmpty) {
      // A currency change would make every existing contribution
      // unreadable against the new target: refused, named, not silently
      // dropped or converted.
      throw const GoalsFailure.validation('currency', 'hasContributions');
    }
    final Goal now = _goal(
      v.goal.id,
      draft,
      v.goal.createdAt,
      state: v.goal.state,
    );
    final LumeRecord r = d.tx.update(
      GoalsCollections.goals,
      id.value,
      now.toFields(),
      expectVersion: version,
    );
    final Goal stored = Goal.decode(r);
    d.goals[d.goals.indexWhere((Goal x) => x.id == id)] = stored;
    return stored;
  });

  /// Mark a goal completed or abandoned, or reactivate one back to active.
  GoalsResult<GoalsWrite> setState(
    LumeRecordId id,
    GoalState state, {
    required int version,
  }) => _write<Goal>((_Data d) {
    final GoalView v = d.sound(id);
    final LumeRecord r = d.tx.update(
      GoalsCollections.goals,
      id.value,
      v.goal.copyWith(state: state).toFields(),
      expectVersion: version,
    );
    final Goal stored = Goal.decode(r);
    d.goals[d.goals.indexWhere((Goal x) => x.id == id)] = stored;
    return stored;
  });

  /// Delete a goal made by mistake: the goal and every contribution that
  /// names it, in one transaction. [undo] brings back the same ids and
  /// versions.
  GoalsResult<GoalsWrite> deleteGoal(LumeRecordId id, {required int version}) =>
      _write<Goal>((_Data d) {
        final GoalView v = d.view(id);
        for (final LumeRecord r in d.tx.all(GoalsCollections.contributions)) {
          if (r['goal'] == id.value) {
            d.tx.delete(
              GoalsCollections.contributions,
              r.id,
              expectVersion: r.version,
            );
          }
        }
        d.tx.delete(GoalsCollections.goals, id.value, expectVersion: version);
        d.goals.removeWhere((Goal x) => x.id == id);
        d.contributions.removeWhere((GoalContribution x) => x.goalId == id);
        d.defects.removeWhere((GoalsDefect x) => x.goalId == id.value);
        d.damagedBefore.remove(id.value);
        return v.goal;
      });

  // ---- contributions ---------------------------------------------------------

  GoalsResult<GoalsWrite> addContribution(
    LumeRecordId goalId,
    LumeMoney amount,
    LumeDate on, {
    String? idempotencyKey,
  }) => _write<GoalContribution>(
    (_Data d) {
      final GoalView v = d.sound(goalId);
      if (v.goal.state != GoalState.active) {
        throw GoalsFailure(
          GoalsFailureKind.closed,
          ids: <LumeRecordId>[goalId],
        );
      }
      if (amount.isZero) {
        throw const GoalsFailure.validation('amount', 'zero');
      }
      if (amount.currency != v.currency) {
        throw const GoalsFailure.validation('amount', 'currency');
      }
      if (amount.minor > LumeMoney.maxSumMinor - v.saved.minor) {
        throw const GoalsFailure(GoalsFailureKind.overflow, field: 'amount');
      }
      final GoalContribution c = GoalContribution(
        id: _newId(),
        goalId: goalId,
        amount: amount,
        on: on,
        createdAt: _now(),
      );
      final GoalContribution stored = GoalContribution.decode(
        d.tx.create(GoalsCollections.contributions, c.id.value, c.toFields()),
      );
      d.contributions.add(stored);
      return stored;
    },
    idempotencyKey: idempotencyKey,
    fingerprint: idempotencyKey == null
        ? null
        : '${goalId.value}|${amount.minor}|${on.toIso()}',
  );

  /// Void a contribution (kept, excluded from every sum), or restore one.
  GoalsResult<GoalsWrite> setContributionVoided(
    LumeRecordId contributionId,
    bool voided, {
    required int version,
  }) => _write<GoalContribution>((_Data d) {
    final GoalContribution? c = d.contributions
        .where((GoalContribution x) => x.id == contributionId)
        .firstOrNull;
    if (c == null) {
      throw GoalsFailure(
        GoalsFailureKind.notFound,
        ids: <LumeRecordId>[contributionId],
      );
    }
    d.sound(c.goalId);
    final LumeRecord r = d.tx.update(
      GoalsCollections.contributions,
      c.id.value,
      c
          .withState(
            voided
                ? GoalContributionState.voided
                : GoalContributionState.active,
          )
          .toFields(),
      expectVersion: version,
    );
    final GoalContribution stored = GoalContribution.decode(r);
    d.contributions[d.contributions.indexWhere(
          (GoalContribution x) => x.id == c.id,
        )] =
        stored;
    return stored;
  });

  /// Reverse a committed write — a delete's or a state change's Undo —
  /// restoring the same ids and versions.
  GoalsResult<void> undo(GoalsWrite write) {
    final LumeTxResult<void> r = _store.revert(write.receipt);
    return r.ok
        ? const GoalsResult<void>.ok(null)
        : GoalsResult<void>.failed(_map(r.failure!));
  }

  // ---- internals ----------------------------------------------------------

  Goal _goal(
    LumeRecordId id,
    GoalDraft draft,
    DateTime createdAt, {
    GoalState state = GoalState.active,
  }) => Goal(
    id: id,
    name: draft.name.trim(),
    note: _optional(draft.note),
    target: draft.target,
    targetDate: draft.targetDate,
    icon: draft.icon,
    state: state,
    createdAt: createdAt,
  );

  static void _validate(GoalDraft draft) {
    final String name = draft.name.trim();
    if (name.isEmpty) throw const GoalsFailure.validation('name', 'required');
    if (name.length > kGoalsNameMax) {
      throw const GoalsFailure.validation('name', 'long');
    }
    if ((draft.note?.length ?? 0) > kGoalsNoteMax) {
      throw const GoalsFailure.validation('note', 'long');
    }
    if (draft.target.isZero) {
      throw const GoalsFailure.validation('target', 'zero');
    }
  }

  static String? _optional(String? s) =>
      s == null || s.trim().isEmpty ? null : s.trim();

  GoalsResult<GoalsWrite> _write<T>(
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
        } on GoalsFailure catch (f) {
          tx.reject(f);
        } on LumeMoneyException catch (e) {
          tx.reject(GoalsFailure(GoalsFailureKind.overflow, cause: e));
        }
      },
      idempotencyKey: idempotencyKey,
      fingerprint: fingerprint,
    );
    if (!r.ok) return GoalsResult<GoalsWrite>.failed(_map(r.failure!));
    final T v = r.value as T;
    return GoalsResult<GoalsWrite>.ok(
      GoalsWrite(
        r.receipt!,
        goal: v is Goal ? v : null,
        contribution: v is GoalContribution ? v : null,
      ),
    );
  }

  /// Every invariant holds on the staged state and no goal the write
  /// reached is newly damaged; otherwise the whole transaction rolls back.
  static void _verify(_Data d) {
    final GoalsBook book = d.book();
    final List<GoalsDamage> fresh = <GoalsDamage>[
      for (final GoalsDamage x in book.damage)
        if (!d.damagedBefore.contains(x.goal)) x,
    ];
    if (fresh.isNotEmpty) {
      throw GoalsFailure(
        GoalsFailureKind.damaged,
        ids: <LumeRecordId>[
          for (final GoalsDamage x in fresh) ?LumeRecordId.tryParse(x.goal),
        ],
        cause: <String>[for (final GoalsDamage x in fresh) x.reason],
      );
    }
    // Every sum the screen will draw fits its bound.
    for (final LumeCurrency c in book.currencies) {
      book.summary(c);
    }
  }

  /// The currency a new goal defaults to: the reader's, where it is one a
  /// new goal may use.
  static LumeCurrency? defaultCurrency(String code) {
    final LumeCurrency? c = LumeCurrency.tryOf(code);
    return c != null && LumeCurrencyPolicy.of(c).usable ? c : null;
  }

  static GoalsFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected => f.detail! as GoalsFailure,
    LumeTxFailureKind.conflict || LumeTxFailureKind.duplicateId => GoalsFailure(
      GoalsFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => GoalsFailure(
      GoalsFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => GoalsFailure(
      GoalsFailureKind.storage,
      cause: f.kind,
    ),
  };
}

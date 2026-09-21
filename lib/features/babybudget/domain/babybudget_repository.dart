/// Baby Budget's writes (`BABY_BUDGET_PROPOSAL.md` §5, §7, §9).
///
/// Every write is one transaction over the record store, checked against
/// the whole budget before it is published. The rules that cost the most
/// to get wrong are here, in one place:
///
/// * a spend is spent or planned, never between, and marking one bought
///   moves every field of it in a single write (correction 1);
/// * a plan is greater than zero, a category plan needs one, and removing
///   the budget's plan takes its shares with it (correction 2);
/// * nothing predates the budget's first day, and moving that day is
///   refused with a conflict naming the earliest record (correction 3);
/// * an archived budget is never archived tomorrow, and takes no
///   ordinary write (correction 4).
///
/// Nothing here reads a clock except the injected [DateTime Function()],
/// which stamps the moment a record was made. Every day a rule depends on
/// is passed in by the caller, from the reader's own zone.
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
import 'babybudget_book.dart';
import 'babybudget_failure.dart';
import 'babybudget_model.dart';

/// A category as the reader entered it, before anything is written.
@immutable
class BabyCategoryDraft {
  const BabyCategoryDraft({
    required this.name,
    this.monthlyPlan,
    this.colour = 0,
  });

  final String name;
  final LumeMoney? monthlyPlan;
  final int colour;
}

/// A budget as the reader entered it.
@immutable
class BabyBudgetDraft {
  const BabyBudgetDraft({
    required this.name,
    this.note,
    required this.currency,
    this.monthlyPlan,
    required this.startedOn,
    this.categories = const <BabyCategoryDraft>[],
  });

  final String name;
  final String? note;
  final LumeCurrency currency;
  final LumeMoney? monthlyPlan;
  final LumeDate startedOn;
  final List<BabyCategoryDraft> categories;

  String get fingerprint => jsonEncode(<String, Object?>{
    'n': name,
    'o': note,
    'u': currency.code,
    'p': monthlyPlan?.minor,
    's': startedOn.toIso(),
    'c': <Object?>[
      for (final BabyCategoryDraft c in categories)
        <Object?>[c.name, c.monthlyPlan?.minor, c.colour],
    ],
  });
}

/// What a committed write did, and what it made.
@immutable
/// One category as an edit describes it: an existing one, carrying its
/// id and the version the reader had, or a new one with neither.
@immutable
class BabyCategoryEdit {
  const BabyCategoryEdit({
    this.id,
    this.version,
    required this.name,
    this.monthlyPlan,
    this.colour = 0,
  });

  final LumeRecordId? id;
  final int? version;
  final String name;
  final LumeMoney? monthlyPlan;
  final int colour;

  BabyCategoryDraft get draft =>
      BabyCategoryDraft(name: name, monthlyPlan: monthlyPlan, colour: colour);
}

class BabyBudgetWrite {
  const BabyBudgetWrite(this.receipt, {this.budget, this.spend});

  final LumeTxReceipt receipt;
  final BabyBudget? budget;
  final BabySpend? spend;
}

/// The records as they stand, or why they cannot be read.
@immutable
class BabyBudgetSnapshot {
  const BabyBudgetSnapshot({
    required this.status,
    this.budgets = const <BabyBudget>[],
    this.categories = const <BabyCategory>[],
    this.spends = const <BabySpend>[],
    this.defects = const <BabyBudgetDefect>[],
  });

  final LumeCollectionStatus status;
  final List<BabyBudget> budgets;
  final List<BabyCategory> categories;
  final List<BabySpend> spends;
  final List<BabyBudgetDefect> defects;

  bool get loading => status == LumeCollectionStatus.loading;
  bool get failed => status == LumeCollectionStatus.error;

  BabyBudgetBook book(LumeDate? today) => BabyBudgetBook.from(
    budgets: budgets,
    categories: categories,
    spends: spends,
    defects: defects,
    today: today,
  );
}

/// Everything one transaction can see and change, decoded once.
class _Data {
  _Data(this.tx) {
    for (final LumeRecord r in tx.all(BabyBudgetCollections.budgets)) {
      _read<BabyBudget>(r, BabyBudget.decode, budgets);
    }
    // A category's money needs its budget's currency, so budgets first.
    final Map<String, LumeCurrency> currencies = <String, LumeCurrency>{
      for (final BabyBudget b in budgets) b.id.value: b.currency,
    };
    for (final LumeRecord r in tx.all(BabyBudgetCollections.categories)) {
      final Object? owner = r['budget'];
      final LumeCurrency? cur = owner is String ? currencies[owner] : null;
      if (cur == null) {
        // Its budget is gone or unreadable: the book reports the orphan.
        _read<BabyCategory>(
          r,
          (LumeRecord x) => BabyCategory.decode(x, currency: _anyCurrency),
          categories,
        );
        continue;
      }
      _read<BabyCategory>(
        r,
        (LumeRecord x) => BabyCategory.decode(x, currency: cur),
        categories,
      );
    }
    for (final LumeRecord r in tx.all(BabyBudgetCollections.spends)) {
      _read<BabySpend>(r, BabySpend.decode, spends);
    }
    damagedBefore = <String>{
      for (final BabyBudgetDamage d in book().damage) d.budget,
    };
  }

  /// Only ever used to decode an orphan's amount so it can be reported
  /// rather than dropped; the book refuses to count it either way.
  static final LumeCurrency _anyCurrency = LumeCurrency.of('USD');

  final LumeRecordTx tx;
  final List<BabyBudget> budgets = <BabyBudget>[];
  final List<BabyCategory> categories = <BabyCategory>[];
  final List<BabySpend> spends = <BabySpend>[];
  final List<BabyBudgetDefect> defects = <BabyBudgetDefect>[];

  late final Set<String> damagedBefore;

  void _read<T>(LumeRecord r, T Function(LumeRecord) decode, List<T> into) {
    try {
      into.add(decode(r));
    } on BabyBudgetDefectException catch (e) {
      defects.add(e.defect);
    }
  }

  /// The day is never read inside a write.
  BabyBudgetBook book() => BabyBudgetBook.from(
    budgets: budgets,
    categories: categories,
    spends: spends,
    defects: defects,
    today: null,
  );

  BabyBudget budgetRecord(LumeRecordId id) {
    for (final BabyBudget b in budgets) {
      if (b.id == id) return b;
    }
    throw BabyBudgetFailure(
      BabyBudgetFailureKind.notFound,
      ids: <LumeRecordId>[id],
    );
  }

  BabyBudgetView view(LumeRecordId id) {
    final BabyBudgetView? v = book().budget(id);
    if (v == null) {
      throw BabyBudgetFailure(
        BabyBudgetFailureKind.notFound,
        ids: <LumeRecordId>[id],
      );
    }
    return v;
  }

  /// A budget a write may touch: readable, and not put away
  /// (correction 4).
  BabyBudgetView live(LumeRecordId id) {
    final BabyBudgetView v = view(id);
    if (damagedBefore.contains(id.value)) {
      throw BabyBudgetFailure(
        BabyBudgetFailureKind.damaged,
        ids: <LumeRecordId>[id],
      );
    }
    if (v.budget.archived) {
      throw BabyBudgetFailure(
        BabyBudgetFailureKind.archived,
        ids: <LumeRecordId>[id],
      );
    }
    return v;
  }

  /// Readable, archived or not — for archiving, un-archiving, deleting.
  BabyBudgetView sound(LumeRecordId id) {
    final BabyBudgetView v = view(id);
    if (damagedBefore.contains(id.value)) {
      throw BabyBudgetFailure(
        BabyBudgetFailureKind.damaged,
        ids: <LumeRecordId>[id],
      );
    }
    return v;
  }

  BabySpend spend(LumeRecordId id) {
    for (final BabySpend s in spends) {
      if (s.id == id) return s;
    }
    throw BabyBudgetFailure(
      BabyBudgetFailureKind.notFound,
      ids: <LumeRecordId>[id],
    );
  }

  BabyCategory category(LumeRecordId id) {
    for (final BabyCategory c in categories) {
      if (c.id == id) return c;
    }
    throw BabyBudgetFailure(
      BabyBudgetFailureKind.notFound,
      ids: <LumeRecordId>[id],
    );
  }

  // Staging: the decoded lists are kept in step with the transaction, so
  // the checks before publication see exactly what would be written.

  BabyBudget putBudget(BabyBudget b, {required bool isNew}) {
    final LumeRecord r = isNew
        ? tx.create(BabyBudgetCollections.budgets, b.id.value, b.toFields())
        : tx.update(
            BabyBudgetCollections.budgets,
            b.id.value,
            b.toFields(),
            expectVersion: b.version,
          );
    final BabyBudget decoded = BabyBudget.decode(r);
    final int at = budgets.indexWhere((BabyBudget x) => x.id == b.id);
    if (at < 0) {
      budgets.add(decoded);
    } else {
      budgets[at] = decoded;
    }
    return decoded;
  }

  BabyCategory putCategory(
    BabyCategory c, {
    required bool isNew,
    required LumeCurrency currency,
  }) {
    final LumeRecord r = isNew
        ? tx.create(BabyBudgetCollections.categories, c.id.value, c.toFields())
        : tx.update(
            BabyBudgetCollections.categories,
            c.id.value,
            c.toFields(),
            expectVersion: c.version,
          );
    final BabyCategory decoded = BabyCategory.decode(r, currency: currency);
    final int at = categories.indexWhere((BabyCategory x) => x.id == c.id);
    if (at < 0) {
      categories.add(decoded);
    } else {
      categories[at] = decoded;
    }
    return decoded;
  }

  BabySpend putSpend(BabySpend s, {required bool isNew}) {
    final LumeRecord r = isNew
        ? tx.create(BabyBudgetCollections.spends, s.id.value, s.toFields())
        : tx.update(
            BabyBudgetCollections.spends,
            s.id.value,
            s.toFields(),
            expectVersion: s.version,
          );
    final BabySpend decoded = BabySpend.decode(r);
    final int at = spends.indexWhere((BabySpend x) => x.id == s.id);
    if (at < 0) {
      spends.add(decoded);
    } else {
      spends[at] = decoded;
    }
    return decoded;
  }

  void removeCategory(BabyCategory c) {
    tx.delete(
      BabyBudgetCollections.categories,
      c.id.value,
      expectVersion: c.version,
    );
    categories.removeWhere((BabyCategory x) => x.id == c.id);
  }

  /// Remove a budget and everything belonging to it, damaged records
  /// included, in this one transaction.
  void removeBudget(LumeRecordId id, int version) {
    final String key = id.value;
    void sweep(String collection) {
      for (final LumeRecord r in tx.all(collection)) {
        if (r['budget'] == key) {
          tx.delete(collection, r.id, expectVersion: r.version);
        }
      }
    }

    sweep(BabyBudgetCollections.spends);
    sweep(BabyBudgetCollections.categories);
    tx.delete(BabyBudgetCollections.budgets, key, expectVersion: version);

    budgets.removeWhere((BabyBudget x) => x.id == id);
    categories.removeWhere((BabyCategory x) => x.budgetId == id);
    spends.removeWhere((BabySpend x) => x.budgetId == id);
    defects.removeWhere((BabyBudgetDefect d) => d.budgetId == key);
    damagedBefore.remove(key);
  }
}

/// Baby Budget's records, written in transactions.
class BabyBudgetRepository {
  BabyBudgetRepository(this._store, {Random? random, DateTime Function()? now})
    : _random = random ?? Random.secure(),
      _now = now ?? DateTime.now;

  final LumeRecordRepository _store;
  final Random _random;
  final DateTime Function() _now;

  /// Told once per committed write.
  Listenable get changes => _store;

  bool get durable => _store.durable;

  void open() {
    for (final String c in BabyBudgetCollections.all) {
      _store.open(c);
    }
  }

  void retry() {
    for (final String c in BabyBudgetCollections.all) {
      if (_store.view(c).status == LumeCollectionStatus.error) {
        _store.retry(c);
      }
    }
  }

  BabyBudgetSnapshot view() {
    final List<LumeCollectionView> views = <LumeCollectionView>[
      for (final String c in BabyBudgetCollections.all) _store.view(c),
    ];
    for (final LumeCollectionView v in views) {
      if (v.status == LumeCollectionStatus.error) {
        return const BabyBudgetSnapshot(status: LumeCollectionStatus.error);
      }
    }
    for (final LumeCollectionView v in views) {
      if (v.status == LumeCollectionStatus.loading) {
        return const BabyBudgetSnapshot(status: LumeCollectionStatus.loading);
      }
    }
    final List<BabyBudgetDefect> defects = <BabyBudgetDefect>[];
    List<T> read<T>(LumeCollectionView v, T Function(LumeRecord) decode) => <T>[
      for (final LumeRecord r in v.items)
        ...() {
          try {
            return <T>[decode(r)];
          } on BabyBudgetDefectException catch (e) {
            defects.add(e.defect);
            return <T>[];
          }
        }(),
    ];
    final List<BabyBudget> budgets = read<BabyBudget>(
      views[0],
      BabyBudget.decode,
    );
    final Map<String, LumeCurrency> currencies = <String, LumeCurrency>{
      for (final BabyBudget b in budgets) b.id.value: b.currency,
    };
    return BabyBudgetSnapshot(
      status: LumeCollectionStatus.ready,
      budgets: budgets,
      categories: read<BabyCategory>(
        views[1],
        (LumeRecord r) => BabyCategory.decode(
          r,
          currency: currencies[r['budget']] ?? LumeCurrency.of('USD'),
        ),
      ),
      spends: read<BabySpend>(views[2], BabySpend.decode),
      defects: defects,
    );
  }

  /// Create a budget and its categories in one transaction.
  BabyBudgetResult<BabyBudgetWrite> addBudget(
    BabyBudgetDraft draft, {
    String? idempotencyKey,
  }) => _write<BabyBudget>(
    (_Data d) {
      _validateDraft(draft);
      if (!LumeCurrencyPolicy.of(draft.currency).usable) {
        throw const BabyBudgetFailure.validation('currency', 'withdrawn');
      }
      final DateTime at = _now();
      final BabyBudget b = BabyBudget(
        id: _newId(),
        name: draft.name.trim(),
        note: _optional(draft.note),
        currency: draft.currency,
        monthlyPlan: draft.monthlyPlan,
        startedOn: draft.startedOn,
        createdAt: at,
      );
      d.putBudget(b, isNew: true);
      for (final (int i, BabyCategoryDraft c) in draft.categories.indexed) {
        d.putCategory(
          BabyCategory(
            id: _newId(),
            budgetId: b.id,
            name: c.name.trim(),
            monthlyPlan: c.monthlyPlan,
            order: i,
            colour: c.colour,
            createdAt: at,
          ),
          isNew: true,
          currency: b.currency,
        );
      }
      return b;
    },
    idempotencyKey: idempotencyKey,
    fingerprint: draft.fingerprint,
  );

  /// Rename a budget, or change its note.
  BabyBudgetResult<BabyBudgetWrite> editBudget(
    LumeRecordId id, {
    required String name,
    String? note,
    required int version,
  }) => _write<BabyBudget>((_Data d) {
    final BabyBudget was = d.budgetRecord(id);
    d.live(id);
    _expect(was.version, version, id);
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const BabyBudgetFailure.validation('name', 'required');
    }
    if (trimmed.length > kBabyNameMax) {
      throw const BabyBudgetFailure.validation('name', 'long');
    }
    return d.putBudget(
      was.copyWith(
        name: trimmed,
        note: _optional(note),
        clearNote: note == null,
      ),
      isNew: false,
    );
  });

  /// Everything a budget's form can change, in **one** transaction: its
  /// name, note, plan and start, and the whole list of its categories.
  ///
  /// This exists because the pieces cannot be applied one at a time
  /// without passing through states none of them allows — lowering the
  /// plan before lowering the categories under it, say — and because a
  /// refusal must leave the budget exactly as the reader found it, not
  /// half-edited. Categories the list leaves out are removed and their
  /// spends kept, uncategorised; the rest are renamed, re-planned and
  /// re-ordered in the order given.
  BabyBudgetResult<BabyBudgetWrite> reviseBudget(
    LumeRecordId id, {
    required String name,
    String? note,
    LumeMoney? monthlyPlan,
    required LumeDate startedOn,
    required List<BabyCategoryEdit> categories,
    required int version,
  }) => _write<BabyBudget>((_Data d) {
    final BabyBudget was = d.budgetRecord(id);
    final BabyBudgetView v = d.live(id);
    _expect(was.version, version, id);

    _validateDraft(
      BabyBudgetDraft(
        name: name,
        note: note,
        currency: was.currency,
        monthlyPlan: monthlyPlan,
        startedOn: startedOn,
        categories: <BabyCategoryDraft>[
          for (final BabyCategoryEdit c in categories) c.draft,
        ],
      ),
    );
    // Nothing the budget holds may predate its new first day
    // (correction 3), and the refusal names the record that stops it.
    for (final BabySpend s in v.spends) {
      final LumeDate? day = s.day;
      if (day != null && day.isBefore(startedOn)) {
        throw BabyBudgetFailure(
          BabyBudgetFailureKind.beforeStart,
          field: 'startedOn',
          reason: 'recordEarlier',
          ids: <LumeRecordId>[s.id],
          day: day,
          label: s.label,
        );
      }
    }

    // Categories the list no longer holds. Their spends stay, and become
    // uncategorised — a category is removed, never its money.
    final Set<String> kept = <String>{
      for (final BabyCategoryEdit c in categories)
        if (c.id != null) c.id!.value,
    };
    for (final BabyCategory c in v.categories) {
      if (kept.contains(c.id.value)) continue;
      for (final BabySpend s in v.spends) {
        if (s.categoryId != c.id) continue;
        d.putSpend(s.copyWith(clearCategory: true), isNew: false);
      }
      d.removeCategory(c);
    }

    // The rest, in the order the reader put them in.
    for (final (int order, BabyCategoryEdit c) in categories.indexed) {
      final LumeRecordId? existing = c.id;
      if (existing == null) {
        d.putCategory(
          BabyCategory(
            id: _newId(),
            budgetId: id,
            name: c.name.trim(),
            monthlyPlan: c.monthlyPlan,
            order: order,
            colour: c.colour,
            createdAt: _now(),
          ),
          isNew: true,
          currency: was.currency,
        );
        continue;
      }
      final BabyCategory before = d.category(existing);
      if (before.budgetId != id) {
        throw BabyBudgetFailure(
          BabyBudgetFailureKind.notFound,
          ids: <LumeRecordId>[existing],
        );
      }
      if (c.version != null) _expect(before.version, c.version!, existing);
      d.putCategory(
        BabyCategory(
          id: before.id,
          budgetId: id,
          name: c.name.trim(),
          monthlyPlan: c.monthlyPlan,
          order: order,
          colour: c.colour,
          createdAt: before.createdAt,
          version: before.version,
        ),
        isNew: false,
        currency: was.currency,
      );
    }

    return d.putBudget(
      BabyBudget(
        id: was.id,
        name: name.trim(),
        note: _optional(note),
        currency: was.currency,
        monthlyPlan: monthlyPlan,
        startedOn: startedOn,
        archivedOn: was.archivedOn,
        createdAt: was.createdAt,
        version: was.version,
      ),
      isNew: false,
    );
  });

  /// Set or clear the monthly plan.
  ///
  /// Clearing it clears every category plan **in the same transaction**
  /// (correction 2): a share of nothing is not a plan. The caller has
  /// already told the reader how many go.
  BabyBudgetResult<BabyBudgetWrite> setPlan(
    LumeRecordId id,
    LumeMoney? plan, {
    required int version,
  }) => _write<BabyBudget>((_Data d) {
    final BabyBudget was = d.budgetRecord(id);
    final BabyBudgetView v = d.live(id);
    _expect(was.version, version, id);
    if (plan != null) {
      if (!plan.isPositive) {
        throw const BabyBudgetFailure.validation('plan', 'zero');
      }
      if (plan.currency != was.currency) {
        throw const BabyBudgetFailure.validation('plan', 'currency');
      }
      final LumeMoney given = LumeMoney.total(<LumeMoney>[
        for (final BabyCategory c in v.categories) ?c.monthlyPlan,
      ], was.currency);
      if (given.compareTo(plan) > 0) {
        throw BabyBudgetFailure(
          BabyBudgetFailureKind.planShape,
          field: 'plan',
          reason: 'belowCategories',
          cause: given.minor,
        );
      }
    } else {
      for (final BabyCategory c in v.categories) {
        if (c.monthlyPlan != null) {
          d.putCategory(
            c.copyWith(clearPlan: true),
            isNew: false,
            currency: was.currency,
          );
        }
      }
    }
    return d.putBudget(
      plan == null
          ? was.copyWith(clearPlan: true)
          : was.copyWith(monthlyPlan: plan),
      isNew: false,
    );
  });

  /// Move the day the budget starts (correction 3).
  ///
  /// Allowed only while every record stays valid. Moving it past the
  /// earliest record is refused with a conflict that names that record.
  BabyBudgetResult<BabyBudgetWrite> setStartedOn(
    LumeRecordId id,
    LumeDate on, {
    required int version,
  }) => _write<BabyBudget>((_Data d) {
    final BabyBudget was = d.budgetRecord(id);
    final BabyBudgetView v = d.live(id);
    _expect(was.version, version, id);
    for (final BabySpend s in v.spends) {
      final LumeDate? day = s.day;
      if (day != null && day.isBefore(on)) {
        throw BabyBudgetFailure(
          BabyBudgetFailureKind.beforeStart,
          field: 'startedOn',
          reason: 'recordEarlier',
          ids: <LumeRecordId>[s.id],
          day: day,
          label: s.label,
        );
      }
    }
    return d.putBudget(was.copyWith(startedOn: on), isNew: false);
  });

  /// Add a category to the end of the reader's order.
  BabyBudgetResult<BabyBudgetWrite> addCategory(
    LumeRecordId budgetId,
    BabyCategoryDraft draft, {
    String? idempotencyKey,
  }) => _write<BabyBudget>((_Data d) {
    final BabyBudget b = d.budgetRecord(budgetId);
    final BabyBudgetView v = d.live(budgetId);
    if (v.categories.length >= kBabyCategoryMax) {
      throw const BabyBudgetFailure.validation('categories', 'many');
    }
    _validateCategory(draft, b.monthlyPlan);
    final int order = v.categories.isEmpty
        ? 0
        : v.categories.map((BabyCategory c) => c.order).reduce(max) + 1;
    d.putCategory(
      BabyCategory(
        id: _newId(),
        budgetId: budgetId,
        name: draft.name.trim(),
        monthlyPlan: draft.monthlyPlan,
        order: order >= kBabyCategoryMax ? v.categories.length : order,
        colour: draft.colour,
        createdAt: _now(),
      ),
      isNew: true,
      currency: b.currency,
    );
    return b;
  }, idempotencyKey: idempotencyKey);

  /// Rename a category, or change its plan or tone.
  BabyBudgetResult<BabyBudgetWrite> editCategory(
    LumeRecordId id, {
    required String name,
    LumeMoney? monthlyPlan,
    bool clearPlan = false,
    int? colour,
    required int version,
  }) => _write<BabyBudget>((_Data d) {
    final BabyCategory was = d.category(id);
    final BabyBudget b = d.budgetRecord(was.budgetId);
    d.live(was.budgetId);
    _expect(was.version, version, id);
    _validateCategory(
      BabyCategoryDraft(
        name: name,
        monthlyPlan: clearPlan ? null : monthlyPlan,
        colour: colour ?? was.colour,
      ),
      b.monthlyPlan,
    );
    d.putCategory(
      was.copyWith(
        name: name.trim(),
        monthlyPlan: monthlyPlan,
        clearPlan: clearPlan,
        colour: colour,
      ),
      isNew: false,
      currency: b.currency,
    );
    return b;
  });

  /// Remove a category. Its spends are moved to [moveTo], or left
  /// uncategorised — never deleted, and never left pointing at nothing.
  BabyBudgetResult<BabyBudgetWrite> deleteCategory(
    LumeRecordId id, {
    LumeRecordId? moveTo,
    required int version,
  }) => _write<BabyBudget>((_Data d) {
    final BabyCategory was = d.category(id);
    final BabyBudget b = d.budgetRecord(was.budgetId);
    final BabyBudgetView v = d.live(was.budgetId);
    _expect(was.version, version, id);
    if (moveTo != null && v.categoryOf(moveTo) == null) {
      throw BabyBudgetFailure(
        BabyBudgetFailureKind.notFound,
        ids: <LumeRecordId>[moveTo],
      );
    }
    for (final BabySpend s in v.spends) {
      if (s.categoryId != id) continue;
      d.putSpend(
        moveTo == null
            ? s.copyWith(clearCategory: true)
            : s.copyWith(categoryId: moveTo),
        isNew: false,
      );
    }
    d.removeCategory(was);
    return b;
  });

  /// Record money that went (correction 1: it always has a day).
  BabyBudgetResult<BabyBudgetWrite> recordSpend(
    LumeRecordId budgetId, {
    required LumeMoney amount,
    required LumeDate spentOn,
    LumeRecordId? categoryId,
    String? label,
    LumeDate? today,
    String? idempotencyKey,
  }) => _write<BabySpend>(
    (_Data d) {
      final BabyBudget b = d.budgetRecord(budgetId);
      final BabyBudgetView v = d.live(budgetId);
      _checkAmount(amount, b.currency);
      _checkCategory(v, categoryId);
      _checkNotFuture(spentOn, today);
      _checkNotBeforeStart(b, spentOn);
      return d.putSpend(
        BabySpend(
          id: _newId(),
          budgetId: budgetId,
          categoryId: categoryId,
          label: _optional(label),
          amount: amount,
          planned: false,
          spentOn: spentOn,
          createdAt: _now(),
        ),
        isNew: true,
      );
    },
    idempotencyKey: idempotencyKey,
    fingerprint: <String>[
      budgetId.value,
      '${amount.minor}',
      spentOn.toIso(),
      categoryId?.value ?? '',
      label ?? '',
    ].join('|'),
  );

  /// Record something the reader means to buy. It has no spent day at
  /// all (correction 1), and may be expected in the future.
  BabyBudgetResult<BabyBudgetWrite> recordPlanned(
    LumeRecordId budgetId, {
    required LumeMoney amount,
    LumeDate? expectedOn,
    LumeRecordId? categoryId,
    String? label,
    String? idempotencyKey,
  }) => _write<BabySpend>((_Data d) {
    final BabyBudget b = d.budgetRecord(budgetId);
    final BabyBudgetView v = d.live(budgetId);
    _checkAmount(amount, b.currency);
    _checkCategory(v, categoryId);
    if (expectedOn != null) _checkNotBeforeStart(b, expectedOn);
    return d.putSpend(
      BabySpend(
        id: _newId(),
        budgetId: budgetId,
        categoryId: categoryId,
        label: _optional(label),
        amount: amount,
        planned: true,
        expectedOn: expectedOn,
        createdAt: _now(),
      ),
      isNew: true,
    );
  }, idempotencyKey: idempotencyKey);

  /// Mark a planned purchase bought: one write that clears the plan,
  /// takes the day the money went, drops the day it was expected, and
  /// takes what was actually paid where that is given (correction 1).
  BabyBudgetResult<BabyBudgetWrite> markBought(
    LumeRecordId id, {
    required LumeDate on,
    LumeMoney? actually,
    LumeDate? today,
    required int version,
  }) => _write<BabySpend>((_Data d) {
    final BabySpend was = d.spend(id);
    final BabyBudget b = d.budgetRecord(was.budgetId);
    d.live(was.budgetId);
    _expect(was.version, version, id);
    if (!was.planned) {
      throw const BabyBudgetFailure.validation('planned', 'alreadySpent');
    }
    if (actually != null) _checkAmount(actually, b.currency);
    _checkNotFuture(on, today);
    _checkNotBeforeStart(b, on);
    return d.putSpend(was.bought(on, actually: actually), isNew: false);
  });

  /// Turn a spend back into a plan — the deliberate way back (D-B18).
  BabyBudgetResult<BabyBudgetWrite> markPlanned(
    LumeRecordId id, {
    LumeDate? expectedOn,
    required int version,
  }) => _write<BabySpend>((_Data d) {
    final BabySpend was = d.spend(id);
    final BabyBudget b = d.budgetRecord(was.budgetId);
    d.live(was.budgetId);
    _expect(was.version, version, id);
    if (was.planned) {
      throw const BabyBudgetFailure.validation('planned', 'alreadyPlanned');
    }
    if (expectedOn != null) _checkNotBeforeStart(b, expectedOn);
    return d.putSpend(was.replanned(expected: expectedOn), isNew: false);
  });

  /// Correct a record without changing what kind of record it is.
  BabyBudgetResult<BabyBudgetWrite> editSpend(
    LumeRecordId id, {
    LumeMoney? amount,
    LumeDate? day,
    LumeRecordId? categoryId,
    bool clearCategory = false,
    String? label,
    bool clearLabel = false,
    bool clearExpected = false,
    LumeDate? today,
    required int version,
  }) => _write<BabySpend>((_Data d) {
    final BabySpend was = d.spend(id);
    final BabyBudget b = d.budgetRecord(was.budgetId);
    final BabyBudgetView v = d.live(was.budgetId);
    _expect(was.version, version, id);
    if (amount != null) _checkAmount(amount, b.currency);
    if (!clearCategory && categoryId != null) _checkCategory(v, categoryId);
    if (day != null) {
      if (!was.planned) _checkNotFuture(day, today);
      _checkNotBeforeStart(b, day);
    }
    return d.putSpend(
      was.copyWith(
        amount: amount,
        spentOn: was.planned ? null : day,
        expectedOn: was.planned ? day : null,
        clearExpected: clearExpected,
        categoryId: categoryId,
        clearCategory: clearCategory,
        label: label,
        clearLabel: clearLabel,
      ),
      isNew: false,
    );
  });

  /// Void a record, or bring one back.
  BabyBudgetResult<BabyBudgetWrite> setVoided(
    LumeRecordId id,
    bool voided, {
    required int version,
  }) => _write<BabySpend>((_Data d) {
    final BabySpend was = d.spend(id);
    d.live(was.budgetId);
    _expect(was.version, version, id);
    if (was.voided == voided) return was;
    return d.putSpend(
      was.withState(voided ? BabySpendState.voided : BabySpendState.active),
      isNew: false,
    );
  });

  /// Put a budget away on [on], or bring it back (correction 4).
  BabyBudgetResult<BabyBudgetWrite> setArchived(
    LumeRecordId id,
    bool archived, {
    LumeDate? on,
    LumeDate? today,
    required int version,
  }) => _write<BabyBudget>((_Data d) {
    final BabyBudget was = d.budgetRecord(id);
    d.sound(id);
    _expect(was.version, version, id);
    if (!archived) {
      return d.putBudget(was.copyWith(clearArchived: true), isNew: false);
    }
    if (on == null) {
      throw const BabyBudgetFailure.validation('archivedOn', 'required');
    }
    // A budget cannot have been put away tomorrow.
    _checkNotFuture(on, today, field: 'archivedOn');
    return d.putBudget(was.copyWith(archivedOn: on), isNew: false);
  });

  /// Remove a budget and everything it owns, in one transaction.
  BabyBudgetResult<BabyBudgetWrite> deleteBudget(
    LumeRecordId id, {
    required int version,
  }) => _write<BabyBudget>((_Data d) {
    final BabyBudget was = d.budgetRecord(id);
    _expect(was.version, version, id);
    d.removeBudget(id, version);
    return was;
  });

  /// Take a committed write back.
  BabyBudgetResult<void> undo(BabyBudgetWrite write) {
    final LumeTxResult<void> r = _store.revert(write.receipt);
    return r.ok
        ? const BabyBudgetResult<void>.ok(null)
        : BabyBudgetResult<void>.failed(_map(r.failure!));
  }

  /// How many records a budget holds, for the delete confirmation.
  BabyBudgetCounts counts(LumeRecordId id) {
    final BabyBudgetSnapshot s = view();
    final String key = id.value;
    return BabyBudgetCounts(
      categories: s.categories
          .where((BabyCategory x) => x.budgetId.value == key)
          .length,
      spends: s.spends
          .where((BabySpend x) => x.budgetId.value == key && !x.planned)
          .length,
      planned: s.spends
          .where((BabySpend x) => x.budgetId.value == key && x.planned)
          .length,
    );
  }

  LumeRecordId _newId() => LumeRecordId.generate(_random);

  static void _expect(int was, int given, LumeRecordId id) {
    if (was != given) {
      throw BabyBudgetFailure(
        BabyBudgetFailureKind.conflict,
        ids: <LumeRecordId>[id],
      );
    }
  }

  static void _checkAmount(LumeMoney amount, LumeCurrency currency) {
    if (!amount.isPositive) {
      throw const BabyBudgetFailure.validation('amount', 'zero');
    }
    if (amount.currency != currency) {
      throw const BabyBudgetFailure.validation('amount', 'currency');
    }
  }

  static void _checkCategory(BabyBudgetView v, LumeRecordId? categoryId) {
    if (categoryId != null && v.categoryOf(categoryId) == null) {
      throw BabyBudgetFailure(
        BabyBudgetFailureKind.notFound,
        ids: <LumeRecordId>[categoryId],
      );
    }
  }

  /// Money never went on a day that has not arrived (D-B5). Without the
  /// reader's day nothing is classified, and the entered day stands.
  static void _checkNotFuture(
    LumeDate day,
    LumeDate? today, {
    String field = 'spentOn',
  }) {
    if (today != null && day.isAfter(today)) {
      throw BabyBudgetFailure.validation(field, 'future');
    }
  }

  /// Nothing predates the budget's first day (correction 3).
  static void _checkNotBeforeStart(BabyBudget b, LumeDate day) {
    if (day.isBefore(b.startedOn)) {
      throw BabyBudgetFailure(
        BabyBudgetFailureKind.beforeStart,
        field: 'day',
        reason: 'beforeStart',
        day: b.startedOn,
      );
    }
  }

  static void _validateDraft(BabyBudgetDraft draft) {
    if (draft.name.trim().isEmpty) {
      throw const BabyBudgetFailure.validation('name', 'required');
    }
    if (draft.name.trim().length > kBabyNameMax) {
      throw const BabyBudgetFailure.validation('name', 'long');
    }
    if ((draft.note ?? '').length > kBabyNoteMax) {
      throw const BabyBudgetFailure.validation('note', 'long');
    }
    final LumeMoney? plan = draft.monthlyPlan;
    if (plan != null) {
      // A plan of nothing is no plan (correction 2).
      if (!plan.isPositive) {
        throw const BabyBudgetFailure.validation('plan', 'zero');
      }
      if (plan.currency != draft.currency) {
        throw const BabyBudgetFailure.validation('plan', 'currency');
      }
      // Twelve months of it must still be a figure that can be added up.
      if (plan.minor > LumeMoney.maxSumMinor ~/ 12) {
        throw const BabyBudgetFailure.validation('plan', 'overflow');
      }
    }
    if (draft.categories.length > kBabyCategoryMax) {
      throw const BabyBudgetFailure.validation('categories', 'many');
    }
    LumeMoney given = LumeMoney.zero(draft.currency);
    for (final BabyCategoryDraft c in draft.categories) {
      _validateCategory(c, plan);
      if (c.monthlyPlan != null) given += c.monthlyPlan!;
    }
    if (plan != null && given.compareTo(plan) > 0) {
      throw const BabyBudgetFailure(
        BabyBudgetFailureKind.planShape,
        field: 'categories',
        reason: 'overPlan',
      );
    }
  }

  static void _validateCategory(BabyCategoryDraft c, LumeMoney? budgetPlan) {
    if (c.name.trim().isEmpty) {
      throw const BabyBudgetFailure.validation('category', 'required');
    }
    if (c.name.trim().length > kBabyNameMax) {
      throw const BabyBudgetFailure.validation('category', 'long');
    }
    if (c.colour < 0 || c.colour >= kBabyColourCount) {
      throw const BabyBudgetFailure.validation('category', 'colour');
    }
    final LumeMoney? plan = c.monthlyPlan;
    if (plan == null) return;
    if (!plan.isPositive) {
      throw const BabyBudgetFailure.validation('categoryPlan', 'zero');
    }
    // A share of nothing is not a plan (correction 2).
    if (budgetPlan == null) {
      throw const BabyBudgetFailure(
        BabyBudgetFailureKind.planShape,
        field: 'categoryPlan',
        reason: 'noBudgetPlan',
      );
    }
    if (plan.compareTo(budgetPlan) > 0) {
      throw const BabyBudgetFailure(
        BabyBudgetFailureKind.planShape,
        field: 'categoryPlan',
        reason: 'overPlan',
      );
    }
  }

  static String? _optional(String? text) {
    final String t = (text ?? '').trim();
    return t.isEmpty ? null : t;
  }

  BabyBudgetResult<BabyBudgetWrite> _write<T>(
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
        } on BabyBudgetFailure catch (f) {
          tx.reject(f);
        } on BabyBudgetDefectException catch (e) {
          tx.reject(
            BabyBudgetFailure(BabyBudgetFailureKind.damaged, cause: e.defect),
          );
        } on LumeMoneyException catch (e) {
          tx.reject(
            BabyBudgetFailure(BabyBudgetFailureKind.overflow, cause: e),
          );
        }
      },
      idempotencyKey: idempotencyKey,
      fingerprint: idempotencyKey == null ? null : fingerprint,
    );
    if (!r.ok) {
      return BabyBudgetResult<BabyBudgetWrite>.failed(_map(r.failure!));
    }
    final T v = r.value as T;
    return BabyBudgetResult<BabyBudgetWrite>.ok(
      BabyBudgetWrite(
        r.receipt!,
        budget: v is BabyBudget ? v : null,
        spend: v is BabySpend ? v : null,
      ),
    );
  }

  /// Everything §7 asks, against the staged state, before anything is
  /// published.
  static void _verify(_Data d) {
    final BabyBudgetBook book = d.book();
    final List<String> broken = book.invariants();
    final List<BabyBudgetDamage> fresh = <BabyBudgetDamage>[
      for (final BabyBudgetDamage x in book.damage)
        if (!d.damagedBefore.contains(x.budget)) x,
    ];
    if (broken.isNotEmpty || fresh.isNotEmpty) {
      throw BabyBudgetFailure(
        BabyBudgetFailureKind.damaged,
        ids: <LumeRecordId>[
          for (final BabyBudgetDamage x in fresh)
            ?LumeRecordId.tryParse(x.budget),
        ],
        cause: <Object>[
          ...broken,
          for (final BabyBudgetDamage x in fresh) x.reason,
        ],
      );
    }
    // A figure that cannot be shown fails the write, not the screen.
    for (final LumeCurrency c in book.currencies) {
      book.summary(c);
    }
  }

  static BabyBudgetFailure _map(LumeTxFailure f) => switch (f.kind) {
    LumeTxFailureKind.rejected => f.detail! as BabyBudgetFailure,
    LumeTxFailureKind.conflict ||
    LumeTxFailureKind.duplicateId => BabyBudgetFailure(
      BabyBudgetFailureKind.conflict,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.missing => BabyBudgetFailure(
      BabyBudgetFailureKind.notFound,
      ids: <LumeRecordId>[?LumeRecordId.tryParse(f.id ?? '')],
    ),
    LumeTxFailureKind.unavailable ||
    LumeTxFailureKind.storage ||
    LumeTxFailureKind.idempotencyMismatch => BabyBudgetFailure(
      BabyBudgetFailureKind.storage,
      cause: f.kind,
    ),
  };
}

/// How many records a budget holds, named for the confirmation that says
/// what deleting it would remove.
@immutable
class BabyBudgetCounts {
  const BabyBudgetCounts({
    required this.categories,
    required this.spends,
    required this.planned,
  });

  final int categories;
  final int spends;
  final int planned;

  int get total => 1 + categories + spends + planned;
}

/// The currency a new budget defaults to: the reader's, when it is one a
/// new record may use.
LumeCurrency? babyBudgetDefaultCurrency(String code) {
  final LumeCurrency? c = LumeCurrency.tryOf(code);
  return c != null && LumeCurrencyPolicy.of(c).usable ? c : null;
}

/// What a baby budget's records add up to (`BABY_BUDGET_PROPOSAL.md`
/// §6–§8).
///
/// Nothing here is stored. Every figure is worked out from the records
/// each time they are read, in minor units of the budget's own currency,
/// and **in integers**: no `double` appears in a percentage anywhere
/// (correction 5). A rounding that depends on binary floating point is a
/// rounding nobody can predict, test or reproduce.
///
/// ```text
/// spent in a month = Σ active, unplanned spends dated in that month
/// ratio            = (spent × 100 + plan ~/ 2) ~/ plan
/// a share          = largest remainder over integers, ties by order then id
/// planned total    = Σ active, planned spends
/// ```
///
/// The day is an input, never read from a clock here. Without it no month
/// is claimed, nothing is overdue, and there is no trend.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_month_anchor.dart';
import '../../../core/values/lume_record_id.dart';
import 'babybudget_model.dart';

/// How many months the trend covers, ending with the reader's own month.
const int kBabyTrendMonths = 6;

/// Where a planned purchase stands.
enum BabyPlannedStatus {
  /// Expected on or after today.
  expected,

  /// Expected before today, and still not bought.
  overdue,

  /// No day expected at all.
  undated,

  /// The reader's day is not available, so nothing is claimed.
  unknown,
}

/// What a budget is doing.
enum BabyBudgetStatus {
  /// Its first day has not arrived.
  notStarted,

  /// Running.
  inUse,

  /// Put away.
  archived,

  /// The reader's day is not available, so started or not is not claimed.
  unknown,
}

/// One category, and what it took this month.
@immutable
class BabyCategoryView {
  const BabyCategoryView({
    required this.category,
    required this.spent,
    required this.share,
    required this.count,
  });

  final BabyCategory? category;

  /// What this category took in the month being looked at.
  final LumeMoney spent;

  /// Its whole-number share of that month, by largest remainder.
  final int share;

  /// How many spends make it up.
  final int count;

  /// The slice with no category of its own, which is a slice all the
  /// same.
  bool get uncategorised => category == null;

  String get name => category?.name ?? '';
  int get order => category?.order ?? kBabyCategoryMax;
  int get colour => category?.colour ?? kBabyColourCount - 1;
  LumeMoney? get plan => category?.monthlyPlan;
}

/// One month of the trend.
@immutable
class BabyMonth {
  const BabyMonth(this.month, this.spent);

  /// The first day of the month.
  final LumeDate month;
  final LumeMoney spent;
}

/// Why a budget's records cannot be trusted as a whole.
@immutable
class BabyBudgetDamage {
  const BabyBudgetDamage(this.budget, this.reason, [this.id]);

  /// The budget id as the records name it.
  final String budget;

  /// A stable machine word: currency, categoryBudget, orderClash,
  /// tooManyCategories, categoryPlanWithoutBudgetPlan, categoryPlanSum,
  /// beforeStart, archivedFuture, spendCategory, defect, overflow.
  final String reason;

  /// The offending record, when one is.
  final String? id;

  @override
  String toString() => '$budget: $reason${id == null ? '' : ' ($id)'}';
}

/// One budget, read.
@immutable
class BabyBudgetView {
  const BabyBudgetView._({
    required this.budget,
    required this.categories,
    required this.spends,
    required this.damage,
    required this.spentToDate,
    required this.plannedTotal,
    required this.lastActivity,
    required this.today,
  });

  final BabyBudget budget;

  /// The reader's categories, in the order they put them.
  final List<BabyCategory> categories;

  /// Every spend, planned and not, newest first, voided ones included.
  final List<BabySpend> spends;

  final String? damage;

  /// Σ active, unplanned spends, whatever month.
  final LumeMoney spentToDate;

  /// Σ active, planned spends.
  final LumeMoney plannedTotal;

  final DateTime lastActivity;

  /// The reader's day, or `null`.
  final LumeDate? today;

  bool get damaged => damage != null;
  LumeRecordId get id => budget.id;
  String get name => budget.name;
  LumeCurrency get currency => budget.currency;
  LumeMoney? get plan => budget.monthlyPlan;

  BabyBudgetStatus get status {
    if (budget.archived) return BabyBudgetStatus.archived;
    final bool? started = budget.startedBy(today);
    if (started == null) return BabyBudgetStatus.unknown;
    return started ? BabyBudgetStatus.inUse : BabyBudgetStatus.notStarted;
  }

  /// Whether the budget has begun, so figures may be drawn at all
  /// (correction 3).
  bool get running => status == BabyBudgetStatus.inUse;

  /// What was spent in the calendar month [month] is in.
  LumeMoney spentIn(LumeDate month) => LumeMoney.total(<LumeMoney>[
    for (final BabySpend s in spends)
      if (s.counts && s.spentOn != null && lumeSameMonth(s.spentOn!, month))
        s.amount,
  ], currency);

  /// This month's spend, or `null` when there is no day, or the budget
  /// has not started (correction 3): before it begins there is no month,
  /// not a month of nothing.
  LumeMoney? get thisMonth {
    final LumeDate? day = today;
    if (day == null || !running) return null;
    return spentIn(day);
  }

  /// The month's spend against the plan, as a whole percentage, or
  /// `null` when there is no plan or no month to measure (D-B2).
  ///
  /// Worked out in integers, rounded half up (correction 5). It is never
  /// clamped: over the plan it reads over 100.
  int? get ratio {
    final LumeMoney? plan = budget.monthlyPlan;
    final LumeMoney? spent = thisMonth;
    if (plan == null || spent == null || plan.minor <= 0) return null;
    return (spent.minor * 100 + plan.minor ~/ 2) ~/ plan.minor;
  }

  /// What this month went over the plan by, or `null` when it did not.
  LumeMoney? get overBy {
    final LumeMoney? plan = budget.monthlyPlan;
    final LumeMoney? spent = thisMonth;
    if (plan == null || spent == null) return null;
    return spent.compareTo(plan) > 0 ? spent - plan : null;
  }

  /// What the plan does not yet hand out to a category, or `null` when
  /// there is no plan (correction 2).
  LumeMoney? get unallocated {
    final LumeMoney? plan = budget.monthlyPlan;
    if (plan == null) return null;
    final LumeMoney given = LumeMoney.total(<LumeMoney>[
      for (final BabyCategory c in categories) ?c.monthlyPlan,
    ], currency);
    final LumeMoney left = plan - given;
    return left.isNegative ? LumeMoney.zero(currency) : left;
  }

  /// The month's slices, biggest first, each with a whole-number share
  /// that together make exactly 100 (correction 5).
  List<BabyCategoryView> slicesIn(LumeDate month) {
    final Map<String?, List<BabySpend>> by = <String?, List<BabySpend>>{};
    for (final BabySpend s in spends) {
      if (!s.counts || s.spentOn == null) continue;
      if (!lumeSameMonth(s.spentOn!, month)) continue;
      by.putIfAbsent(s.categoryId?.value, () => <BabySpend>[]).add(s);
    }
    if (by.isEmpty) return const <BabyCategoryView>[];

    final Map<String, BabyCategory> known = <String, BabyCategory>{
      for (final BabyCategory c in categories) c.id.value: c,
    };
    // Every slice, in the order that decides a tie: the reader's own
    // order, then the id; uncategorised last of all.
    final List<(BabyCategory?, int, int)> parts =
        <(BabyCategory?, int, int)>[
          for (final MapEntry<String?, List<BabySpend>> e in by.entries)
            (
              e.key == null ? null : known[e.key],
              LumeMoney.total(<LumeMoney>[
                for (final BabySpend s in e.value) s.amount,
              ], currency).minor,
              e.value.length,
            ),
        ]..sort((a, b) {
          final int ao = a.$1?.order ?? kBabyCategoryMax;
          final int bo = b.$1?.order ?? kBabyCategoryMax;
          if (ao != bo) return ao.compareTo(bo);
          final String ai = a.$1?.id.value ?? '￿';
          final String bi = b.$1?.id.value ?? '￿';
          return ai.compareTo(bi);
        });

    final int total = parts.fold<int>(0, (int a, x) => a + x.$2);
    final List<int> shares = _largestRemainder(<int>[
      for (final (BabyCategory?, int, int) p in parts) p.$2,
    ], total);
    final List<BabyCategoryView> out = <BabyCategoryView>[
      for (final (int i, (BabyCategory?, int, int) p) in parts.indexed)
        BabyCategoryView(
          category: p.$1,
          spent: LumeMoney.sum(p.$2, currency),
          share: shares[i],
          count: p.$3,
        ),
    ];
    // Shown biggest first; the tie order above decided the shares, and
    // this only decides where they sit on the screen.
    out.sort((BabyCategoryView a, BabyCategoryView b) {
      final int c = b.spent.compareTo(a.spent);
      if (c != 0) return c;
      if (a.uncategorised != b.uncategorised) return a.uncategorised ? 1 : -1;
      return a.order.compareTo(b.order);
    });
    return out;
  }

  /// This month's slices, or empty when there is no month to look at.
  List<BabyCategoryView> get slices {
    final LumeDate? day = today;
    if (day == null || !running) return const <BabyCategoryView>[];
    return slicesIn(day);
  }

  /// The last [kBabyTrendMonths] months ending with the reader's own,
  /// leaving out any month before the budget began (correction 3).
  ///
  /// `null` without a day, or before the budget starts.
  List<BabyMonth>? get trend {
    final LumeDate? day = today;
    if (day == null || !running) return null;
    final List<BabyMonth> out = <BabyMonth>[];
    for (int i = kBabyTrendMonths - 1; i >= 0; i--) {
      final LumeDate month = lumeMonthStart(day, -i);
      // A month the budget did not cover is not a zero; it is not shown.
      if (month.isBefore(lumeMonthStart(budget.startedOn, 0))) continue;
      out.add(BabyMonth(month, spentIn(month)));
    }
    return out;
  }

  /// Planned purchases that have a day, in the order they need
  /// attention: overdue first, oldest first; then the rest, soonest
  /// first (correction 6).
  List<BabySpend> get comingUp {
    final List<BabySpend> dated = <BabySpend>[
      for (final BabySpend s in spends)
        if (s.active && s.planned && s.expectedOn != null) s,
    ];
    final LumeDate? day = today;
    dated.sort((BabySpend a, BabySpend b) {
      if (day != null) {
        final bool ao = a.expectedOn!.isBefore(day);
        final bool bo = b.expectedOn!.isBefore(day);
        // Overdue above everything else.
        if (ao != bo) return ao ? -1 : 1;
      }
      // Oldest overdue first; soonest to come first. Both are the same
      // comparison: earliest day first.
      final int c = a.expectedOn!.compareTo(b.expectedOn!);
      if (c != 0) return c;
      final int t = a.createdAt.compareTo(b.createdAt);
      return t != 0 ? t : a.id.compareTo(b.id);
    });
    return dated;
  }

  /// Planned purchases with no day, newest first — the reader's own
  /// order, because there is nothing to derive one from.
  List<BabySpend> get oneOff => <BabySpend>[
    for (final BabySpend s in spends)
      if (s.active && s.planned && s.expectedOn == null) s,
  ];

  /// Where one planned purchase stands.
  BabyPlannedStatus statusOf(BabySpend s) {
    if (!s.planned) return BabyPlannedStatus.undated;
    if (s.expectedOn == null) return BabyPlannedStatus.undated;
    final LumeDate? day = today;
    if (day == null) return BabyPlannedStatus.unknown;
    return s.expectedOn!.isBefore(day)
        ? BabyPlannedStatus.overdue
        : BabyPlannedStatus.expected;
  }

  /// Spends that went, newest first — the history list.
  List<BabySpend> get recorded => <BabySpend>[
    for (final BabySpend s in spends)
      if (!s.planned) s,
  ];

  BabyCategory? categoryOf(LumeRecordId? id) {
    if (id == null) return null;
    for (final BabyCategory c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  BabySpend? spendOf(LumeRecordId id) {
    for (final BabySpend s in spends) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// The earliest day any record holds, for the conflict that refuses to
  /// move the start past it (correction 3).
  LumeDate? get earliestRecordDay {
    LumeDate? at;
    for (final BabySpend s in spends) {
      final LumeDate? d = s.day;
      if (d == null) continue;
      if (at == null || d.isBefore(at)) at = d;
    }
    return at;
  }
}

/// Every budget the reader has, read together.
@immutable
class BabyBudgetBook {
  const BabyBudgetBook._({
    required this.budgets,
    required this.defects,
    required this.damage,
    required this.today,
  });

  /// Budgets, most recently active first.
  final List<BabyBudgetView> budgets;

  /// Records that could not be read at all.
  final List<BabyBudgetDefect> defects;

  /// Budgets whose records do not hold together.
  final List<BabyBudgetDamage> damage;

  final LumeDate? today;

  bool get dayKnown => today != null;
  bool get isEmpty => budgets.isEmpty;

  BabyBudgetView? budget(LumeRecordId id) {
    for (final BabyBudgetView v in budgets) {
      if (v.budget.id == id) return v;
    }
    return null;
  }

  List<LumeCurrency> get currencies {
    final List<LumeCurrency> out = <LumeCurrency>[];
    for (final BabyBudgetView v in budgets) {
      if (!out.contains(v.currency)) out.add(v.currency);
    }
    out.sort((LumeCurrency a, LumeCurrency b) => a.code.compareTo(b.code));
    return out;
  }

  /// What a currency's budgets add up to. Damaged ones are left out.
  BabyBudgetSummary summary(LumeCurrency c) {
    final List<BabyBudgetView> mine = <BabyBudgetView>[
      for (final BabyBudgetView v in budgets)
        if (v.currency == c && !v.damaged) v,
    ];
    final bool anyMonthUnknown = mine.any(
      (BabyBudgetView v) => !v.budget.archived && v.thisMonth == null,
    );
    return BabyBudgetSummary(
      currency: c,
      budgets: mine.length,
      thisMonth: anyMonthUnknown
          ? null
          : LumeMoney.total(<LumeMoney>[
              for (final BabyBudgetView v in mine) ?v.thisMonth,
            ], c),
      spentToDate: LumeMoney.total(<LumeMoney>[
        for (final BabyBudgetView v in mine) v.spentToDate,
      ], c),
      plannedTotal: LumeMoney.total(<LumeMoney>[
        for (final BabyBudgetView v in mine) v.plannedTotal,
      ], c),
    );
  }

  List<BabyBudgetSummary> get summaries => <BabyBudgetSummary>[
    for (final LumeCurrency c in currencies) summary(c),
  ];

  /// The rules that do not hold, as stable words. Empty means they do.
  List<String> invariants() {
    final List<String> broken = <String>[];
    for (final BabyBudgetView v in budgets) {
      if (v.damaged) continue;
      final String id = v.budget.id.value;
      // The parts of a month add to the month.
      final LumeDate? day = v.today;
      if (day != null && v.running) {
        final LumeMoney month = v.spentIn(day);
        final List<BabyCategoryView> slices = v.slicesIn(day);
        final int parts = slices.fold<int>(
          0,
          (int a, BabyCategoryView s) => a + s.spent.minor,
        );
        if (parts != month.minor) broken.add('slices $id');
        // The shares make exactly 100 when anything was spent.
        final int shares = slices.fold<int>(
          0,
          (int a, BabyCategoryView s) => a + s.share,
        );
        if (month.minor > 0 && shares != 100) broken.add('shares $id');
        if (month.minor == 0 && slices.isNotEmpty) broken.add('emptyMonth $id');
      }
      // Every month adds to what was spent.
      final int months = <String>{
        for (final BabySpend s in v.spends)
          if (s.counts && s.spentOn != null)
            '${s.spentOn!.year}-${s.spentOn!.month}',
      }.length;
      if (months > 0) {
        final LumeMoney sum = LumeMoney.total(<LumeMoney>[
          for (final BabySpend s in v.spends)
            if (s.counts) s.amount,
        ], v.currency);
        if (sum.minor != v.spentToDate.minor) broken.add('spentToDate $id');
      }
      // A planned purchase is never in what was spent.
      for (final BabySpend s in v.spends) {
        if (s.planned && s.spentOn != null) {
          broken.add('plannedSpentOn $id');
          break;
        }
        if (!s.planned && s.spentOn == null) {
          broken.add('spentWithoutDay $id');
          break;
        }
      }
    }
    return broken;
  }

  /// Read every budget from its records.
  factory BabyBudgetBook.from({
    required List<BabyBudget> budgets,
    required List<BabyCategory> categories,
    required List<BabySpend> spends,
    List<BabyBudgetDefect> defects = const <BabyBudgetDefect>[],
    required LumeDate? today,
  }) {
    final List<BabyBudgetDamage> damage = <BabyBudgetDamage>[];
    final Map<String, BabyBudget> byId = <String, BabyBudget>{
      for (final BabyBudget b in budgets) b.id.value: b,
    };

    void orphans<T>(
      List<T> all,
      String Function(T) owner,
      String Function(T) idOf,
      String reason,
    ) {
      for (final T x in all) {
        if (!byId.containsKey(owner(x))) {
          damage.add(BabyBudgetDamage(owner(x), reason, idOf(x)));
        }
      }
    }

    orphans<BabyCategory>(
      categories,
      (BabyCategory x) => x.budgetId.value,
      (BabyCategory x) => x.id.value,
      'orphanCategory',
    );
    orphans<BabySpend>(
      spends,
      (BabySpend x) => x.budgetId.value,
      (BabySpend x) => x.id.value,
      'orphanSpend',
    );

    final Set<String> defective = <String>{
      for (final BabyBudgetDefect d in defects) ?d.budgetId,
    };

    final List<BabyBudgetView> views = <BabyBudgetView>[];
    for (final BabyBudget b in budgets) {
      final String id = b.id.value;
      final List<BabyCategory> cs =
          <BabyCategory>[
            for (final BabyCategory c in categories)
              if (c.budgetId.value == id) c,
          ]..sort((BabyCategory x, BabyCategory y) {
            final int c = x.order.compareTo(y.order);
            return c != 0 ? c : x.id.compareTo(y.id);
          });
      final List<BabySpend> ss = <BabySpend>[
        for (final BabySpend s in spends)
          if (s.budgetId.value == id) s,
      ]..sort(babySpendOrder);

      String? why = _check(b, cs, ss);
      if (why == null && defective.contains(id)) why = 'defect';
      if (why != null) damage.add(BabyBudgetDamage(id, why));

      DateTime last = b.createdAt;
      for (final BabySpend s in ss) {
        if (s.createdAt.isAfter(last)) last = s.createdAt;
      }
      views.add(
        BabyBudgetView._(
          budget: b,
          categories: cs,
          spends: ss,
          damage: why,
          spentToDate: LumeMoney.total(<LumeMoney>[
            for (final BabySpend s in ss)
              if (s.counts) s.amount,
          ], b.currency),
          plannedTotal: LumeMoney.total(<LumeMoney>[
            for (final BabySpend s in ss)
              if (s.active && s.planned) s.amount,
          ], b.currency),
          lastActivity: last,
          today: today,
        ),
      );
    }

    views.sort(
      (BabyBudgetView a, BabyBudgetView b) =>
          b.lastActivity.compareTo(a.lastActivity),
    );
    return BabyBudgetBook._(
      budgets: views,
      defects: defects,
      damage: damage,
      today: today,
    );
  }

  /// Everything a budget must be for its figures to mean anything.
  static String? _check(
    BabyBudget b,
    List<BabyCategory> categories,
    List<BabySpend> spends,
  ) {
    if (categories.length > kBabyCategoryMax) return 'tooManyCategories';
    final Set<int> orders = <int>{};
    final Set<String> ids = <String>{};
    LumeMoney given = LumeMoney.zero(b.currency);
    for (final BabyCategory c in categories) {
      if (!orders.add(c.order)) return 'orderClash';
      ids.add(c.id.value);
      final LumeMoney? plan = c.monthlyPlan;
      if (plan != null) {
        // A share of nothing is not a plan (correction 2).
        if (b.monthlyPlan == null) return 'categoryPlanWithoutBudgetPlan';
        if (plan.currency != b.currency) return 'currency';
        given += plan;
      }
    }
    if (b.monthlyPlan != null && given.compareTo(b.monthlyPlan!) > 0) {
      return 'categoryPlanSum';
    }
    for (final BabySpend s in spends) {
      if (s.currency != b.currency) return 'currency';
      if (s.categoryId != null && !ids.contains(s.categoryId!.value)) {
        return 'spendCategory';
      }
      // Nothing predates the start (correction 3).
      final LumeDate? day = s.day;
      if (day != null && day.isBefore(b.startedOn)) return 'beforeStart';
    }
    return null;
  }
}

/// A currency's budgets, added up.
@immutable
class BabyBudgetSummary {
  const BabyBudgetSummary({
    required this.currency,
    required this.budgets,
    required this.thisMonth,
    required this.spentToDate,
    required this.plannedTotal,
  });

  final LumeCurrency currency;
  final int budgets;

  /// `null` when a running budget's month cannot be worked out.
  final LumeMoney? thisMonth;
  final LumeMoney spentToDate;
  final LumeMoney plannedTotal;
}

/// Hand out `total`'s hundred points by largest remainder, in integers
/// (correction 5). [values] arrives in the order that breaks a tie:
/// the reader's own order, then the id, uncategorised last.
List<int> _largestRemainder(List<int> values, int total) {
  if (total <= 0) return List<int>.filled(values.length, 0);
  final List<int> floors = <int>[for (final int v in values) v * 100 ~/ total];
  final List<int> remainders = <int>[
    for (final (int i, int v) in values.indexed) v * 100 - floors[i] * total,
  ];
  int left = 100 - floors.fold<int>(0, (int a, int b) => a + b);
  final List<int> order = <int>[for (int i = 0; i < values.length; i++) i]
    ..sort((int a, int b) {
      final int c = remainders[b].compareTo(remainders[a]);
      // A tie goes to whoever came first in the list, which is the
      // reader's order, then the id, with uncategorised last.
      return c != 0 ? c : a.compareTo(b);
    });
  final List<int> out = <int>[...floors];
  for (final int i in order) {
    if (left <= 0) break;
    out[i] += 1;
    left--;
  }
  return out;
}

/// Newest first: the day it is about, then the moment it was recorded,
/// then the id, so the order never wobbles between reads.
int babySpendOrder(BabySpend a, BabySpend b) {
  final LumeDate? ad = a.day;
  final LumeDate? bd = b.day;
  if (ad != null && bd != null) {
    final int d = bd.compareTo(ad);
    if (d != 0) return d;
  } else if (ad != bd) {
    // A record with no day at all sorts after one that has a day.
    return ad == null ? 1 : -1;
  }
  final int t = b.createdAt.compareTo(a.createdAt);
  return t != 0 ? t : a.id.compareTo(b.id);
}

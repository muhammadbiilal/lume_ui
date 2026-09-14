/// Expenses' dashboard figures — `context.js` `expenses()` over `tool-data.js`.
///
/// Everything the dashboard draws except the records, which are the record
/// layer's (`record_seeds.dart`). The budget is the reference's per-market
/// monthly figure in local currency; spent, income and balance are fixed
/// fractions of it; categories share out what was spent; the transactions,
/// recurring payments and week are authored in dollars and converted.
///
/// **Dayroz obligation:** every figure here is fixture data. The dashboard
/// must be computed from the reader's own records and budget.
library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import '../../../core/fixtures/lume_reference_money.dart';
import '../../../core/icons/lume_icons.dart';

/// `EXPENSE_CATEGORIES`, in the reference's order.
enum LumeExpenseCategory {
  groceries(LumeIcons.cart, Color(0xFF10998A), 0.28),
  transport(LumeIcons.car, Color(0xFF6E62E5), 0.19),
  bills(LumeIcons.receipt, Color(0xFFE0913A), 0.22),
  eating(LumeIcons.utensils, Color(0xFFDE6B7A), 0.14),
  health(LumeIcons.pulse, Color(0xFF3E9BD4), 0.09),
  other(LumeIcons.grid, Color(0xFF8B8D95), 0.08);

  const LumeExpenseCategory(this.icon, this.color, this.share);

  final String icon;

  /// The donut slice — a literal in the reference, the same in dark mode.
  final Color color;

  /// Its share of what was spent.
  final double share;

  static LumeExpenseCategory? byId(String? id) {
    for (final LumeExpenseCategory c in values) {
      if (c.name == id) return c;
    }
    return null;
  }
}

/// `TRANSACTIONS[i].method`.
enum LumePaymentMethod { card, autoDebit, transfer, cash, wallet }

/// Which transaction — its words are the reader's language's.
enum LumeTransactionTitle {
  metro,
  fuel,
  electricity,
  salary,
  coffee,
  pharmacy,
  internet,
  airport,
}

@immutable
class LumeTransaction {
  const LumeTransaction({
    required this.title,
    required this.category,
    required this.amountUsd,
    required this.daysAgo,
    required this.method,
    this.time,
    this.income = false,
  });

  final LumeTransactionTitle title;
  final LumeExpenseCategory category;

  /// Signed, in dollars: spending is negative.
  final double amountUsd;

  /// `when` — "Today · 11:20", "Yesterday", "1 Sep", counted back from today.
  final int daysAgo;

  /// The clock time the reference writes after today's, as written.
  final String? time;

  final LumePaymentMethod method;
  final bool income;
}

@immutable
class LumeCategorySpend {
  const LumeCategorySpend(this.category, this.amount);

  final LumeExpenseCategory category;

  /// Local currency, untidied.
  final double amount;
}

@immutable
class LumeBudgetLine {
  const LumeBudgetLine(this.category, this.spent, this.limit);

  final LumeExpenseCategory category;
  final double spent;
  final double limit;

  bool get over => spent > limit;
}

@immutable
class LumeRecurringPayment {
  const LumeRecurringPayment({
    required this.electricity,
    required this.day,
    required this.amountUsd,
  });

  /// `expenses.rec1` Internet, or `expenses.rec2` Electricity.
  final bool electricity;

  /// The day of the month it is taken.
  final int day;

  final double amountUsd;
}

@immutable
class LumeExpensesBoard {
  const LumeExpensesBoard._({
    required this.currency,
    required this.budget,
    required this.dayOfMonth,
  });

  /// `expenses()` for a reader in [country] whose amounts are in [currency],
  /// on [now].
  factory LumeExpensesBoard.forMarket({
    required String country,
    required String currency,
    required DateTime now,
  }) => LumeExpensesBoard._(
    currency: currency,
    budget: (budgets[country] ?? 1200).toDouble(),
    dayOfMonth: now.day,
  );

  final String currency;

  /// `C.BUDGET[country] || 1200`, in local currency.
  final double budget;

  /// `new Date().getDate()` — what the daily average divides by.
  final int dayOfMonth;

  /// `ratio: 0.53`.
  static const double ratio = 0.53;

  double get spent => budget * ratio;
  double get income => budget * 1.24;
  double get balance => budget * 0.71;
  double get dailyAverage => spent / dayOfMonth;

  List<LumeCategorySpend> get categories => <LumeCategorySpend>[
    for (final LumeExpenseCategory c in LumeExpenseCategory.values)
      LumeCategorySpend(c, spent * c.share),
  ];

  /// `byCat.slice(0, 4)` — bills are limited 8 % under what was spent, the
  /// others 35 % over.
  List<LumeBudgetLine> get budgetLines => <LumeBudgetLine>[
    for (final LumeCategorySpend s in categories.take(4))
      LumeBudgetLine(
        s.category,
        s.amount,
        s.amount *
            (1 + (s.category == LumeExpenseCategory.bills ? -0.08 : 0.35)),
      ),
  ];

  /// `money(v)` for a figure already in local currency — tidied.
  static double tidy(double local) => lumeTidy(local);

  /// `money(usd)`.
  double fromUsd(double usd) => lumeFromUsd(usd, currency);

  /// `trend` — the week, Monday first, today last.
  static const List<double> week = <double>[42, 55, 38, 61, 48, 52, 44];

  static const List<LumeRecurringPayment> recurring = <LumeRecurringPayment>[
    LumeRecurringPayment(electricity: false, day: 3, amountUsd: 28),
    LumeRecurringPayment(electricity: true, day: 12, amountUsd: 74),
  ];

  static const List<LumeTransaction> transactions = <LumeTransaction>[
    LumeTransaction(
      title: LumeTransactionTitle.metro,
      category: LumeExpenseCategory.groceries,
      amountUsd: -62,
      daysAgo: 0,
      time: '11:20',
      method: LumePaymentMethod.card,
    ),
    LumeTransaction(
      title: LumeTransactionTitle.fuel,
      category: LumeExpenseCategory.transport,
      amountUsd: -38,
      daysAgo: 0,
      time: '08:05',
      method: LumePaymentMethod.card,
    ),
    LumeTransaction(
      title: LumeTransactionTitle.electricity,
      category: LumeExpenseCategory.bills,
      amountUsd: -74,
      daysAgo: 1,
      method: LumePaymentMethod.autoDebit,
    ),
    LumeTransaction(
      title: LumeTransactionTitle.salary,
      category: LumeExpenseCategory.other,
      amountUsd: 1850,
      daysAgo: 6,
      method: LumePaymentMethod.transfer,
      income: true,
    ),
    LumeTransaction(
      title: LumeTransactionTitle.coffee,
      category: LumeExpenseCategory.eating,
      amountUsd: -6,
      daysAgo: 1,
      method: LumePaymentMethod.cash,
    ),
    LumeTransaction(
      title: LumeTransactionTitle.pharmacy,
      category: LumeExpenseCategory.health,
      amountUsd: -21,
      daysAgo: 3,
      method: LumePaymentMethod.card,
    ),
    LumeTransaction(
      title: LumeTransactionTitle.internet,
      category: LumeExpenseCategory.bills,
      amountUsd: -28,
      daysAgo: 4,
      method: LumePaymentMethod.autoDebit,
    ),
    LumeTransaction(
      title: LumeTransactionTitle.airport,
      category: LumeExpenseCategory.transport,
      amountUsd: -14,
      daysAgo: 5,
      method: LumePaymentMethod.wallet,
    ),
  ];

  /// `catalogue.js` `BUDGET` — a typical monthly household budget in local
  /// currency, for the markets the reference anchors.
  static const Map<String, int> budgets = <String, int>{
    'PK': 80000, 'IN': 45000, 'BD': 30000, 'LK': 90000, 'NP': 40000, //
    'US': 1500, 'CA': 1950, 'GB': 1200, 'IE': 1400, 'AU': 2100, 'NZ': 2200,
    'DE': 1400, 'FR': 1400, 'ES': 1100, 'IT': 1200, 'NL': 1500, 'SE': 15000,
    'NO': 17000, 'AE': 6000, 'SA': 5500, 'QA': 5500, 'KW': 450, 'OM': 550,
    'BH': 550, 'JO': 700, 'TR': 25000, 'EG': 15000, 'MA': 6000, 'NG': 400000,
    'KE': 60000, 'ZA': 15000, 'ID': 6000000, 'MY': 3500, 'PH': 30000,
    'TH': 25000, 'VN': 12000000, 'JP': 180000, 'CN': 6000, 'KR': 1800000,
    'SG': 2200, 'HK': 12000, 'MX': 18000, 'BR': 4000, 'AR': 500000,
    'CL': 700000, 'CO': 3000000,
  };
}

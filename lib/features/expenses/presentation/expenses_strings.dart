/// The words Expenses and its records draw that their data does not carry.
library;

import '../../../l10n/app_localizations.dart';
import '../data/expenses_fixtures.dart';

abstract final class LumeExpensesStrings {
  /// `EXPENSE_CATEGORIES[i].label`.
  static String category(AppLocalizations l, LumeExpenseCategory c) =>
      switch (c) {
        LumeExpenseCategory.groceries => l.expensesCatGroceries,
        LumeExpenseCategory.transport => l.expensesCatTransport,
        LumeExpenseCategory.bills => l.expensesCatBills,
        LumeExpenseCategory.eating => l.expensesCatEating,
        LumeExpenseCategory.health => l.expensesCatHealth,
        LumeExpenseCategory.other => l.expensesCatOther,
      };

  static String transaction(AppLocalizations l, LumeTransactionTitle t) =>
      switch (t) {
        LumeTransactionTitle.metro => l.expensesTxMetro,
        LumeTransactionTitle.fuel => l.expensesTxFuel,
        LumeTransactionTitle.electricity => l.expensesTxElectricity,
        LumeTransactionTitle.salary => l.expensesTxSalary,
        LumeTransactionTitle.coffee => l.expensesTxCoffee,
        LumeTransactionTitle.pharmacy => l.expensesTxPharmacy,
        LumeTransactionTitle.internet => l.expensesTxInternet,
        LumeTransactionTitle.airport => l.expensesTxAirport,
      };

  static String method(AppLocalizations l, LumePaymentMethod m) => switch (m) {
    LumePaymentMethod.card => l.recPayCard,
    LumePaymentMethod.autoDebit => l.expensesMethodAutoDebit,
    LumePaymentMethod.transfer => l.recPayTransfer,
    LumePaymentMethod.cash => l.recPayCash,
    LumePaymentMethod.wallet => l.recPayWallet,
  };

  /// `rec.pay.<key>` — a record's payment field holds the key.
  static String payment(AppLocalizations l, Object? key) => switch (key) {
    'card' => l.recPayCard,
    'transfer' => l.recPayTransfer,
    'wallet' => l.recPayWallet,
    _ => l.recPayCash,
  };

  /// A seeded record's `@key`, in the reader's language; anything else is the
  /// reader's own words and is returned as written.
  static String seeded(AppLocalizations l, Object? v) => switch (v) {
    '@groceries' => l.recSeedGroceries,
    '@groceriesNote' => l.recSeedGroceriesNote,
    '@taxi' => l.recSeedTaxi,
    '@internet' => l.recSeedInternet,
    '@coffee' => l.recSeedCoffee,
    '@pharmacy' => l.recSeedPharmacy,
    null => '',
    _ => '$v',
  };
}

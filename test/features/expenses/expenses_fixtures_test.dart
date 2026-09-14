/// Expenses' figures, held to `context.js` `expenses()` and `locale.js`
/// `tidy()`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_reference_money.dart';
import 'package:lume/features/expenses/data/expenses_fixtures.dart';
import 'package:lume/features/records/data/record_seeds.dart';

void main() {
  test('tidy rounds by magnitude, as the reference does', () {
    expect(lumeTidy(123456), 123000);
    expect(lumeTidy(42400), 42400);
    expect(lumeTidy(12345), 12300);
    expect(lumeTidy(1234.5), 1230);
    expect(lumeTidy(123.5), 124);
    expect(lumeTidy(17.3), 17.5);
    expect(lumeTidy(12.2), 12);
    expect(lumeTidy(9.34), 9.3);
  });

  test('the board is fixed fractions of the market budget', () {
    final LumeExpensesBoard pk = LumeExpensesBoard.forMarket(
      country: 'PK',
      currency: 'PKR',
      now: DateTime(2026, 9, 7),
    );
    expect(pk.budget, 80000);
    expect(LumeExpensesBoard.tidy(pk.spent), 42400);
    expect(LumeExpensesBoard.tidy(pk.income), 99200);
    expect(LumeExpensesBoard.tidy(pk.balance), 56800);
    expect(pk.dailyAverage, closeTo(42400 / 7, 1e-9));
    expect(
      pk.categories.fold<double>(
        0,
        (double a, LumeCategorySpend c) => a + c.amount,
      ),
      closeTo(pk.spent, 1e-6),
    );
    expect(pk.budgetLines, hasLength(4));
    expect(
      pk.budgetLines
          .where((LumeBudgetLine b) => b.over)
          .map((LumeBudgetLine b) => b.category),
      <LumeExpenseCategory>[LumeExpenseCategory.bills],
    );
    // A market the reference does not anchor budgets 1,200 of its own money.
    expect(
      LumeExpensesBoard.forMarket(
        country: 'FI',
        currency: 'EUR',
        now: DateTime(2026, 9, 7),
      ).budget,
      1200,
    );
  });

  test(
    'the seeded expenses are dated back from the day they are first read',
    () {
      final List<Map<String, Object?>> seeds = lumeRecordSeeds(
        'expenses',
        DateTime(2026, 9, 7, 16, 41),
      )!;
      expect(seeds.map((Map<String, Object?> s) => s['date']), <String>[
        '2026-09-07',
        '2026-09-06',
        '2026-09-04',
        '2026-09-03',
        '2026-09-01',
      ]);
      expect(lumeRecordSeeds('notes', DateTime(2026, 9, 7)), isNull);
    },
  );
}

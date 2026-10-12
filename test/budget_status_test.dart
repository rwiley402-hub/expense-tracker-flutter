import 'package:expense_tracker/services/summary_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_data.dart';

void main() {
  group('BudgetStatus', () {
    test('healthy when well under the limit', () {
      const status = BudgetStatus(categoryId: 'dining', limit: 200, spent: 50);
      expect(status.progress, 0.25);
      expect(status.remaining, 150);
      expect(status.isOverBudget, isFalse);
      expect(status.isNearLimit, isFalse);
      expect(status.level, BudgetLevel.healthy);
    });

    test('warning from 80% of the limit', () {
      const status = BudgetStatus(categoryId: 'dining', limit: 200, spent: 160);
      expect(status.isNearLimit, isTrue);
      expect(status.level, BudgetLevel.warning);
    });

    test('exactly at the limit is a warning, not exceeded', () {
      const status = BudgetStatus(categoryId: 'dining', limit: 200, spent: 200);
      expect(status.isOverBudget, isFalse);
      expect(status.level, BudgetLevel.warning);
      expect(status.remaining, 0);
    });

    test('exceeded when spending is above the limit', () {
      const status = BudgetStatus(categoryId: 'dining', limit: 200, spent: 250);
      expect(status.isOverBudget, isTrue);
      expect(status.isNearLimit, isFalse);
      expect(status.progress, 1.25);
      expect(status.remaining, -50);
      expect(status.level, BudgetLevel.exceeded);
    });

    test('unbudgeted when no limit is set', () {
      const spent = BudgetStatus(categoryId: 'other', limit: 0, spent: 30);
      const idle = BudgetStatus(categoryId: 'other', limit: 0, spent: 0);
      expect(spent.level, BudgetLevel.unbudgeted);
      expect(spent.isOverBudget, isFalse);
      expect(spent.progress, 1);
      expect(idle.progress, 0);
    });
  });

  group('SummaryService.budgetStatuses', () {
    final september =
        SummaryService.summarize(sampleTransactions, DateTime(2026, 9));

    test('includes budgeted categories and unbudgeted spending', () {
      final statuses = SummaryService.budgetStatuses(september, {
        'groceries': 250, // 200.75 -> 80.3% warning
        'dining': 50, // 75.10 -> exceeded
        'transport': 100, // 0 spent -> healthy
        'shopping': 0, // removed budget, no spend -> excluded
      });

      final byId = {for (final s in statuses) s.categoryId: s};
      expect(byId.keys,
          unorderedEquals(['groceries', 'dining', 'transport', 'housing']));
      expect(byId['groceries']!.level, BudgetLevel.warning);
      expect(byId['dining']!.level, BudgetLevel.exceeded);
      expect(byId['transport']!.spent, 0);
      expect(byId['transport']!.level, BudgetLevel.healthy);
      expect(byId['housing']!.level, BudgetLevel.unbudgeted);
      expect(byId['housing']!.spent, 1500);
    });

    test('orders problems first: exceeded, warning, healthy, unbudgeted', () {
      final statuses = SummaryService.budgetStatuses(september, {
        'groceries': 250,
        'dining': 50,
        'transport': 100,
      });
      expect(statuses.map((s) => s.categoryId).toList(),
          ['dining', 'groceries', 'transport', 'housing']);
    });

    test('totalBudget ignores zero and negative limits', () {
      expect(
        SummaryService.totalBudget({'a': 100, 'b': 0, 'c': 250.5, 'd': -5}),
        350.5,
      );
    });

    test('budgetedSpending only counts categories with a budget', () {
      final spent = SummaryService.budgetedSpending(september, {
        'groceries': 250,
        'dining': 50,
      });
      expect(spent, 275.85);
    });
  });
}

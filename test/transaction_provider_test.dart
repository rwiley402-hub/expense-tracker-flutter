import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/services/summary_service.dart';
import 'package:expense_tracker/state/transaction_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/in_memory_repository.dart';
import 'helpers/test_data.dart';

void main() {
  late InMemoryTransactionRepository repository;
  late TransactionProvider provider;

  /// Pretend "today" is 12 October 2026: the sample data ends in September.
  DateTime clock() => DateTime(2026, 10, 12);

  setUp(() async {
    repository = InMemoryTransactionRepository(
      initial: sampleTransactions,
      sample: sampleTransactions.take(3).toList(),
      budgets: {'groceries': 250, 'dining': 50},
    );
    provider = TransactionProvider(repository, clock: clock);
    await provider.load();
  });

  test('loads data and selects the latest month that has transactions', () {
    expect(provider.isLoading, isFalse);
    expect(provider.transactions, hasLength(sampleTransactions.length));
    expect(provider.selectedMonth, DateTime(2026, 9));
    expect(provider.summary.totalExpense, 1775.85);
  });

  test('availableMonths includes the current month even without data', () {
    expect(provider.availableMonths,
        [DateTime(2026, 10), DateTime(2026, 9), DateTime(2026, 8)]);
    expect(provider.canGoToNextMonth, isTrue);
    expect(provider.canGoToPreviousMonth, isTrue);

    provider.goToPreviousMonth();
    expect(provider.selectedMonth, DateTime(2026, 8));
    expect(provider.canGoToPreviousMonth, isFalse);
    provider.goToPreviousMonth();
    expect(provider.selectedMonth, DateTime(2026, 8));
  });

  test('category filter narrows visible transactions', () {
    provider.setCategoryFilter('dining');
    expect(provider.visibleTransactions.map((t) => t.id), ['s6', 's5']);
    // The monthly summary still covers all categories.
    expect(provider.summary.totalExpense, 1775.85);
  });

  test('add, update and delete persist through the repository', () async {
    final coffee = tx('new', amount: 4.5, category: 'dining',
        date: DateTime(2026, 9, 30), title: 'Bean There Café');

    await provider.addTransaction(coffee);
    expect(provider.summary.expenseByCategory['dining'], 79.6);
    expect(repository.stored.any((t) => t.id == 'new'), isTrue);

    final updated = await provider.updateTransaction(coffee.copyWith(amount: 6));
    expect(updated, isTrue);
    expect(provider.findById('new')!.amount, 6);

    final removed = await provider.deleteTransaction('new');
    expect(removed?.id, 'new');
    expect(provider.findById('new'), isNull);
    expect(repository.stored.any((t) => t.id == 'new'), isFalse);
    expect(repository.transactionSaves, 3);
  });

  test('restoreTransaction undoes a delete exactly once', () async {
    final removed = await provider.deleteTransaction('s3');
    await provider.restoreTransaction(removed!);
    await provider.restoreTransaction(removed);
    expect(provider.transactions.where((t) => t.id == 's3'), hasLength(1));
  });

  test('budgets drive budget statuses and can be removed', () async {
    final dining = provider.budgetStatuses
        .firstWhere((s) => s.categoryId == 'dining');
    expect(dining.level, BudgetLevel.exceeded);

    await provider.setBudget('dining', 100);
    expect(
      provider.budgetStatuses.firstWhere((s) => s.categoryId == 'dining').level,
      BudgetLevel.healthy,
    );

    await provider.setBudget('dining', 0);
    expect(provider.budgets.containsKey('dining'), isFalse);
    expect(repository.storedBudgets.containsKey('dining'), isFalse);
  });

  test('resetToSampleData replaces transactions and budgets', () async {
    await provider.resetToSampleData();
    expect(provider.transactions, hasLength(3));
    expect(provider.budgets['groceries'], 400); // kDefaultBudgets
    expect(provider.categoryFilter, isNull);
  });

  test('notifies listeners on changes', () async {
    var notifications = 0;
    provider.addListener(() => notifications++);
    provider.selectMonth(DateTime(2026, 8, 15));
    provider.selectMonth(DateTime(2026, 8, 1)); // same month -> no-op
    await provider.addTransaction(tx('x', amount: 1, category: 'other',
        date: DateTime(2026, 8, 2), type: TransactionType.expense));
    expect(notifications, 2);
  });
}

import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/transaction.dart';

/// Aggregated figures for one calendar month.
@immutable
class MonthlySummary {
  const MonthlySummary({
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.transactionCount,
  });

  factory MonthlySummary.empty(DateTime month) => MonthlySummary(
        month: SummaryService.monthOf(month),
        totalIncome: 0,
        totalExpense: 0,
        expenseByCategory: const {},
        incomeByCategory: const {},
        transactionCount: 0,
      );

  /// First day of the summarised month.
  final DateTime month;
  final double totalIncome;
  final double totalExpense;
  final Map<String, double> expenseByCategory;
  final Map<String, double> incomeByCategory;
  final int transactionCount;

  double get net => totalIncome - totalExpense;

  /// Share of income that was not spent. 0 when there was no income.
  double get savingsRate => totalIncome <= 0 ? 0 : net / totalIncome;

  bool get hasExpenses => totalExpense > 0;

  /// Expense categories ordered from largest to smallest spend.
  List<MapEntry<String, double>> get expensesSorted =>
      expenseByCategory.entries.toList()
        ..sort((a, b) {
          final byValue = b.value.compareTo(a.value);
          return byValue != 0 ? byValue : a.key.compareTo(b.key);
        });

  /// Fraction (0..1) of total spending that went to [categoryId].
  double shareOf(String categoryId) => totalExpense <= 0
      ? 0
      : (expenseByCategory[categoryId] ?? 0) / totalExpense;
}

/// Traffic-light level of a category budget.
enum BudgetLevel { exceeded, warning, healthy, unbudgeted }

/// How much of a category's monthly budget has been used.
@immutable
class BudgetStatus {
  const BudgetStatus({
    required this.categoryId,
    required this.limit,
    required this.spent,
  });

  /// Usage ratio at which a budget is flagged as "nearly used up".
  static const double warningThreshold = 0.8;

  final String categoryId;

  /// Monthly limit; 0 means no budget has been set.
  final double limit;
  final double spent;

  bool get hasLimit => limit > 0;

  /// Money left before hitting the limit (negative when over budget).
  double get remaining => limit - spent;

  /// Usage ratio. Can exceed 1 when over budget. Without a limit it is
  /// 1 if anything was spent, otherwise 0.
  double get progress {
    if (!hasLimit) return spent > 0 ? 1.0 : 0.0;
    return spent / limit;
  }

  bool get isOverBudget => hasLimit && spent > limit;

  bool get isNearLimit =>
      hasLimit && !isOverBudget && progress >= warningThreshold;

  BudgetLevel get level {
    if (!hasLimit) return BudgetLevel.unbudgeted;
    if (isOverBudget) return BudgetLevel.exceeded;
    if (isNearLimit) return BudgetLevel.warning;
    return BudgetLevel.healthy;
  }

  @override
  bool operator ==(Object other) =>
      other is BudgetStatus &&
      other.categoryId == categoryId &&
      other.limit == limit &&
      other.spent == spent;

  @override
  int get hashCode => Object.hash(categoryId, limit, spent);

  @override
  String toString() => 'BudgetStatus($categoryId, $spent / $limit)';
}

/// Pure functions that turn a list of transactions into summaries.
///
/// Kept free of Flutter widgets and I/O so it is trivially unit-testable.
abstract final class SummaryService {
  /// Normalises [date] to the first day of its month.
  static DateTime monthOf(DateTime date) => DateTime(date.year, date.month);

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  /// Returns the month [offset] months away from [month].
  static DateTime addMonths(DateTime month, int offset) =>
      DateTime(month.year, month.month + offset);

  /// Transactions matching an optional month and/or category, newest first.
  static List<Transaction> filter(
    Iterable<Transaction> transactions, {
    DateTime? month,
    String? categoryId,
  }) {
    final result = transactions.where((t) {
      if (month != null && !isSameMonth(t.date, month)) return false;
      if (categoryId != null && t.categoryId != categoryId) return false;
      return true;
    }).toList();
    result.sort(compareNewestFirst);
    return result;
  }

  /// Sort order used throughout the app: newest day first, then by title.
  static int compareNewestFirst(Transaction a, Transaction b) {
    final byDay = b.day.compareTo(a.day);
    if (byDay != 0) return byDay;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  /// Totals for every transaction that falls in [month].
  static MonthlySummary summarize(
    Iterable<Transaction> transactions,
    DateTime month,
  ) {
    var income = 0.0;
    var expense = 0.0;
    var count = 0;
    final expenseByCategory = <String, double>{};
    final incomeByCategory = <String, double>{};

    for (final t in transactions) {
      if (!isSameMonth(t.date, month)) continue;
      count++;
      if (t.isExpense) {
        expense += t.amount;
        expenseByCategory.update(
          t.categoryId,
          (value) => value + t.amount,
          ifAbsent: () => t.amount,
        );
      } else {
        income += t.amount;
        incomeByCategory.update(
          t.categoryId,
          (value) => value + t.amount,
          ifAbsent: () => t.amount,
        );
      }
    }

    return MonthlySummary(
      month: monthOf(month),
      totalIncome: _round(income),
      totalExpense: _round(expense),
      expenseByCategory: UnmodifiableMapView(
        expenseByCategory.map((k, v) => MapEntry(k, _round(v))),
      ),
      incomeByCategory: UnmodifiableMapView(
        incomeByCategory.map((k, v) => MapEntry(k, _round(v))),
      ),
      transactionCount: count,
    );
  }

  /// Budget status for every category that either has a positive limit or
  /// has spending this month. Problems are listed first: exceeded, then
  /// warning, then healthy, then unbudgeted; ties broken by usage.
  static List<BudgetStatus> budgetStatuses(
    MonthlySummary summary,
    Map<String, double> budgets,
  ) {
    final ids = <String>{
      ...budgets.entries.where((e) => e.value > 0).map((e) => e.key),
      ...summary.expenseByCategory.keys,
    };

    final statuses = [
      for (final id in ids)
        BudgetStatus(
          categoryId: id,
          limit: budgets[id] != null && budgets[id]! > 0 ? budgets[id]! : 0.0,
          spent: summary.expenseByCategory[id] ?? 0,
        ),
    ];

    statuses.sort((a, b) {
      final byLevel = a.level.index.compareTo(b.level.index);
      if (byLevel != 0) return byLevel;
      final byProgress = b.progress.compareTo(a.progress);
      if (byProgress != 0) return byProgress;
      final bySpent = b.spent.compareTo(a.spent);
      if (bySpent != 0) return bySpent;
      return a.categoryId.compareTo(b.categoryId);
    });
    return statuses;
  }

  /// Sum of all positive budget limits.
  static double totalBudget(Map<String, double> budgets) => _round(
        budgets.values.where((v) => v > 0).fold<double>(0, (a, b) => a + b),
      );

  /// Spending in categories that have a budget (unbudgeted spend excluded).
  static double budgetedSpending(
    MonthlySummary summary,
    Map<String, double> budgets,
  ) {
    var total = 0.0;
    budgets.forEach((id, limit) {
      if (limit > 0) total += summary.expenseByCategory[id] ?? 0;
    });
    return _round(total);
  }

  /// Groups transactions by calendar day, newest day first. Within each day
  /// the order of [compareNewestFirst] is kept.
  static Map<DateTime, List<Transaction>> groupByDay(
    Iterable<Transaction> transactions,
  ) {
    final sorted = transactions.toList()..sort(compareNewestFirst);
    final groups = LinkedHashMap<DateTime, List<Transaction>>();
    for (final t in sorted) {
      groups.putIfAbsent(t.day, () => <Transaction>[]).add(t);
    }
    return groups;
  }

  /// Distinct months that contain at least one transaction, newest first.
  static List<DateTime> monthsWithData(Iterable<Transaction> transactions) {
    final months = transactions.map((t) => monthOf(t.date)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return months;
  }

  /// Relative change from [previous] to [current], e.g. 0.25 for +25%.
  /// Returns null when there is no meaningful baseline.
  static double? percentChange(double previous, double current) {
    if (previous == 0) return null;
    return (current - previous) / previous;
  }

  /// Sum of signed amounts (income positive, expenses negative).
  static double netOf(Iterable<Transaction> transactions) => _round(
        transactions.fold<double>(0, (sum, t) => sum + t.signedAmount),
      );

  /// Rounds to cents to avoid floating point noise like 0.30000000000000004.
  static double _round(double value) => (value * 100).roundToDouble() / 100;
}

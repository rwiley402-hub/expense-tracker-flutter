import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/services/summary_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_data.dart';

void main() {
  final september = DateTime(2026, 9);
  final august = DateTime(2026, 8);

  group('SummaryService.summarize', () {
    test('totals income and expenses for the requested month only', () {
      final summary = SummaryService.summarize(sampleTransactions, september);

      expect(summary.month, DateTime(2026, 9));
      expect(summary.totalIncome, 4500);
      expect(summary.totalExpense, 1775.85);
      expect(summary.net, closeTo(2724.15, 0.001));
      expect(summary.transactionCount, 7);
    });

    test('breaks expenses down by category, rounded to cents', () {
      final summary = SummaryService.summarize(sampleTransactions, september);

      expect(summary.expenseByCategory, {
        'groceries': 200.75,
        'dining': 75.10,
        'housing': 1500.0,
      });
      expect(summary.incomeByCategory, {'salary': 4000.0, 'freelance': 500.0});
    });

    test('sorts categories from largest to smallest spend', () {
      final summary = SummaryService.summarize(sampleTransactions, september);

      expect(
        summary.expensesSorted.map((e) => e.key).toList(),
        ['housing', 'groceries', 'dining'],
      );
    });

    test('computes category share and savings rate', () {
      final summary = SummaryService.summarize(sampleTransactions, august);

      expect(summary.totalExpense, 350);
      expect(summary.shareOf('groceries'), closeTo(300 / 350, 1e-9));
      expect(summary.shareOf('unknown'), 0);
      expect(summary.savingsRate, closeTo(3650 / 4000, 1e-9));
    });

    test('returns an empty summary for a month without data', () {
      final summary =
          SummaryService.summarize(sampleTransactions, DateTime(2026, 1));

      expect(summary.totalIncome, 0);
      expect(summary.totalExpense, 0);
      expect(summary.hasExpenses, isFalse);
      expect(summary.savingsRate, 0);
      expect(summary.expenseByCategory, isEmpty);
    });

    test('ignores the day/time part of the month argument', () {
      final a = SummaryService.summarize(
        sampleTransactions,
        DateTime(2026, 9, 28, 17, 45),
      );
      expect(a.totalExpense, 1775.85);
      expect(a.month, DateTime(2026, 9));
    });

    test('avoids floating point noise', () {
      final txs = [
        tx('1', amount: 0.1, category: 'dining', date: DateTime(2026, 9, 1)),
        tx('2', amount: 0.2, category: 'dining', date: DateTime(2026, 9, 2)),
      ];
      final summary = SummaryService.summarize(txs, september);
      expect(summary.totalExpense, 0.3);
      expect(summary.expenseByCategory['dining'], 0.3);
    });
  });

  group('SummaryService.filter', () {
    test('filters by month and category, newest first', () {
      final result = SummaryService.filter(
        sampleTransactions,
        month: september,
        categoryId: 'groceries',
      );
      expect(result.map((t) => t.id), ['s4', 's3']);
    });

    test('returns everything when no filters are given', () {
      expect(SummaryService.filter(sampleTransactions),
          hasLength(sampleTransactions.length));
    });
  });

  group('SummaryService.groupByDay', () {
    test('groups by calendar day with newest day first', () {
      final groups = SummaryService.groupByDay(
        SummaryService.filter(sampleTransactions, month: september),
      );

      expect(groups.keys.toList(), [
        DateTime(2026, 9, 21),
        DateTime(2026, 9, 18),
        DateTime(2026, 9, 17),
        DateTime(2026, 9, 3),
        DateTime(2026, 9, 1),
      ]);
      expect(groups[DateTime(2026, 9, 3)]!.map((t) => t.id).toSet(),
          {'s3', 's5'});
    });

    test('treats different times on the same day as one group', () {
      final groups = SummaryService.groupByDay([
        tx('1', amount: 1, category: 'dining', date: DateTime(2026, 9, 5, 8)),
        tx('2', amount: 2, category: 'dining', date: DateTime(2026, 9, 5, 20)),
      ]);
      expect(groups, hasLength(1));
      expect(groups.values.single, hasLength(2));
    });
  });

  group('month helpers', () {
    test('monthsWithData returns distinct months newest first', () {
      expect(SummaryService.monthsWithData(sampleTransactions),
          [DateTime(2026, 9), DateTime(2026, 8)]);
    });

    test('addMonths rolls over year boundaries', () {
      expect(SummaryService.addMonths(DateTime(2026, 1), -1),
          DateTime(2025, 12));
      expect(SummaryService.addMonths(DateTime(2026, 12), 1),
          DateTime(2027, 1));
    });

    test('percentChange handles a zero baseline', () {
      expect(SummaryService.percentChange(0, 100), isNull);
      expect(SummaryService.percentChange(200, 150), closeTo(-0.25, 1e-9));
      expect(SummaryService.percentChange(100, 125), closeTo(0.25, 1e-9));
    });

    test('netOf sums signed amounts', () {
      final net = SummaryService.netOf([
        tx('1', amount: 100, category: 'salary', date: DateTime(2026, 9, 1),
            type: TransactionType.income),
        tx('2', amount: 40.5, category: 'dining', date: DateTime(2026, 9, 1)),
      ]);
      expect(net, 59.5);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/default_categories.dart';
import '../services/summary_service.dart';
import '../state/transaction_provider.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/category_avatar.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/empty_state.dart';
import '../widgets/summary_header.dart';

/// Monthly overview: totals, spending pie chart and month-over-month change.
class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final summary = provider.summary;
    final previous = provider.previousMonthSummary;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        SummaryHeader(
          income: summary.totalIncome,
          expense: summary.totalExpense,
          footer: summary.totalIncome > 0
              ? 'Savings rate ${formatPercent(summary.savingsRate)} · '
                  '${summary.transactionCount} transactions'
              : '${summary.transactionCount} transactions',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Spending by category', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                if (!summary.hasExpenses)
                  const EmptyState(
                    icon: Icons.pie_chart_outline,
                    title: 'No spending this month',
                    message: 'Add an expense to see the breakdown.',
                  )
                else ...[
                  CategoryPieChart(summary: summary),
                  const SizedBox(height: 12),
                  for (final entry in summary.expensesSorted)
                    _CategoryRow(
                      categoryId: entry.key,
                      amount: entry.value,
                      share: summary.shareOf(entry.key),
                      budget: provider.budgets[entry.key],
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ComparisonCard(current: summary, previous: previous),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categoryId,
    required this.amount,
    required this.share,
    this.budget,
  });

  final String categoryId;
  final double amount;
  final double share;
  final double? budget;

  @override
  Widget build(BuildContext context) {
    final category = categoryById(categoryId);
    final textTheme = Theme.of(context).textTheme;
    final overBudget = budget != null && budget! > 0 && amount > budget!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CategoryAvatar(category: category, radius: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: textTheme.bodyLarge),
                if (budget != null && budget! > 0)
                  Text(
                    overBudget
                        ? 'Over ${formatCurrency(budget!)} budget'
                        : 'of ${formatCurrency(budget!)} budget',
                    style: textTheme.bodySmall?.copyWith(
                      color: overBudget ? AppColors.expenseFor(context) : null,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(amount),
                style: textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(formatPercent(share), style: textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.current, required this.previous});

  final MonthlySummary current;
  final MonthlySummary previous;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final previousLabel = formatShortMonth(previous.month);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compared with $previousLabel', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            _ChangeRow(
              label: 'Spending',
              previous: previous.totalExpense,
              current: current.totalExpense,
              higherIsBetter: false,
            ),
            _ChangeRow(
              label: 'Income',
              previous: previous.totalIncome,
              current: current.totalIncome,
              higherIsBetter: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.label,
    required this.previous,
    required this.current,
    required this.higherIsBetter,
  });

  final String label;
  final double previous;
  final double current;
  final bool higherIsBetter;

  @override
  Widget build(BuildContext context) {
    final change = SummaryService.percentChange(previous, current);
    final textTheme = Theme.of(context).textTheme;

    Widget trailing;
    if (change == null) {
      trailing = Text('No data', style: textTheme.bodyMedium);
    } else {
      final isUp = change >= 0;
      final isGood = isUp == higherIsBetter || change == 0;
      final color =
          isGood ? AppColors.incomeFor(context) : AppColors.expenseFor(context);
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            '${isUp ? '+' : ''}${formatPercent(change)}',
            style: textTheme.bodyMedium?.copyWith(color: color),
          ),
        ],
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      subtitle: Text(
        '${formatCurrency(previous)} → ${formatCurrency(current)}',
      ),
      trailing: trailing,
    );
  }
}

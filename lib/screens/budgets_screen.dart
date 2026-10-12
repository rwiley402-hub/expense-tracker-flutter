import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/default_categories.dart';
import '../models/transaction.dart';
import '../services/summary_service.dart';
import '../state/transaction_provider.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/budget_dialog.dart';
import '../widgets/budget_progress_tile.dart';
import '../widgets/category_avatar.dart';

/// Per-category monthly budgets with progress for the selected month.
class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final summary = provider.summary;
    final budgets = provider.budgets;
    final statuses = provider.budgetStatuses;
    final textTheme = Theme.of(context).textTheme;

    final trackedIds = statuses.map((s) => s.categoryId).toSet();
    final untracked = categoriesForType(TransactionType.expense)
        .where((c) => !trackedIds.contains(c.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        _OverviewCard(
          totalBudget: SummaryService.totalBudget(budgets),
          spent: SummaryService.budgetedSpending(summary, budgets),
          exceeded: statuses.where((s) => s.isOverBudget).length,
          warning: statuses.where((s) => s.isNearLimit).length,
        ),
        const SizedBox(height: 16),
        if (statuses.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text('Categories', style: textTheme.titleMedium),
          ),
          for (final status in statuses)
            Card(
              child: BudgetProgressTile(
                status: status,
                onTap: () => _editBudget(context, status.categoryId),
              ),
            ),
        ],
        if (untracked.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text('No budget yet', style: textTheme.titleMedium),
          ),
          Card(
            child: Column(
              children: [
                for (final category in untracked)
                  ListTile(
                    leading: CategoryAvatar(category: category, radius: 18),
                    title: Text(category.name),
                    trailing: const Icon(Icons.add),
                    onTap: () => _editBudget(context, category.id),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _editBudget(BuildContext context, String categoryId) async {
    final provider = context.read<TransactionProvider>();
    final result = await showBudgetDialog(
      context,
      category: categoryById(categoryId),
      currentLimit: provider.budgets[categoryId] ?? 0,
    );
    if (result != null) {
      await provider.setBudget(categoryId, result);
    }
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.totalBudget,
    required this.spent,
    required this.exceeded,
    required this.warning,
  });

  final double totalBudget;
  final double spent;
  final int exceeded;
  final int warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final ratio = totalBudget <= 0 ? 0.0 : spent / totalBudget;
    final level = totalBudget <= 0
        ? BudgetLevel.unbudgeted
        : ratio > 1
            ? BudgetLevel.exceeded
            : ratio >= BudgetStatus.warningThreshold
                ? BudgetLevel.warning
                : BudgetLevel.healthy;
    final color = AppColors.budgetLevel(context, level);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly budget', style: textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              totalBudget > 0
                  ? '${formatCurrency(spent)} of ${formatCurrency(totalBudget)}'
                  : 'No budgets set',
              style: textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 12,
                color: color,
                backgroundColor: color.withValues(alpha: 0.18),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (totalBudget > 0)
                  Text(
                    totalBudget - spent >= 0
                        ? '${formatCurrency(totalBudget - spent)} left'
                        : '${formatCurrency(spent - totalBudget)} over',
                    style: textTheme.bodyMedium,
                  ),
                if (exceeded > 0)
                  Text(
                    '· $exceeded over budget',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                if (warning > 0)
                  Text(
                    '· $warning close to limit',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.warning),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

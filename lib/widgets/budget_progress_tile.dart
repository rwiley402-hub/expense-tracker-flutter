import 'package:flutter/material.dart';

import '../data/default_categories.dart';
import '../services/summary_service.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';
import 'category_avatar.dart';

/// Category row with a coloured progress bar showing budget usage.
class BudgetProgressTile extends StatelessWidget {
  const BudgetProgressTile({super.key, required this.status, this.onTap});

  final BudgetStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final category = categoryById(status.categoryId);
    final textTheme = Theme.of(context).textTheme;
    final color = AppColors.budgetLevel(context, status.level);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryAvatar(category: category, radius: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(category.name, style: textTheme.titleSmall),
                ),
                Text(
                  status.hasLimit
                      ? '${formatCurrency(status.spent)} / ${formatCurrency(status.limit)}'
                      : formatCurrency(status.spent),
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: status.progress.clamp(0.0, 1.0),
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: 0.18),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _caption(),
              style: textTheme.bodySmall?.copyWith(
                color: status.level == BudgetLevel.healthy ||
                        status.level == BudgetLevel.unbudgeted
                    ? null
                    : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _caption() {
    switch (status.level) {
      case BudgetLevel.exceeded:
        return 'Over budget by ${formatCurrency(-status.remaining)}';
      case BudgetLevel.warning:
        return '${formatCurrency(status.remaining)} left · '
            '${formatPercent(status.progress)} used';
      case BudgetLevel.healthy:
        return '${formatCurrency(status.remaining)} left · '
            '${formatPercent(status.progress)} used';
      case BudgetLevel.unbudgeted:
        return 'No budget set · tap to add one';
    }
  }
}

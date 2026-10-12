import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/formatters.dart';

/// Card with income, expenses and net figures side by side.
class SummaryHeader extends StatelessWidget {
  const SummaryHeader({
    super.key,
    required this.income,
    required this.expense,
    this.footer,
  });

  final double income;
  final double expense;

  /// Optional extra line shown under the figures (e.g. savings rate).
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final net = income - expense;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Row(
              children: [
                _Stat(
                  label: 'Income',
                  value: formatCurrency(income),
                  color: AppColors.incomeFor(context),
                ),
                _Stat(
                  label: 'Expenses',
                  value: formatCurrency(expense),
                  color: AppColors.expenseFor(context),
                ),
                _Stat(
                  label: 'Net',
                  value: formatSignedCurrency(net),
                  color: net >= 0
                      ? AppColors.incomeFor(context)
                      : AppColors.expenseFor(context),
                ),
              ],
            ),
            if (footer != null) ...[
              const SizedBox(height: 8),
              Text(
                footer!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: textTheme.labelMedium),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

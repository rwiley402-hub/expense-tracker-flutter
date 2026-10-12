import 'package:flutter/material.dart';

import '../data/default_categories.dart';
import '../models/transaction.dart';
import '../utils/app_colors.dart';
import '../utils/formatters.dart';
import 'category_avatar.dart';

/// One row in the transactions list.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, this.onTap});

  final Transaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final category = categoryById(transaction.categoryId);
    final textTheme = Theme.of(context).textTheme;
    final note = transaction.note;
    final subtitle = note != null && note.isNotEmpty
        ? '${category.name} · $note'
        : category.name;
    final amountColor = transaction.isExpense
        ? AppColors.expenseFor(context)
        : AppColors.incomeFor(context);

    return ListTile(
      onTap: onTap,
      leading: CategoryAvatar(category: category),
      title: Text(
        transaction.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        formatSignedCurrency(transaction.signedAmount),
        style: textTheme.titleSmall?.copyWith(
          color: amountColor,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../services/summary_service.dart';
import '../state/transaction_provider.dart';
import '../utils/formatters.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/summary_header.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_form_screen.dart';

/// Transactions for the selected month, grouped by day.
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final visible = provider.visibleTransactions;
    final grouped = SummaryService.groupByDay(visible);

    final income = visible
        .where((t) => t.isIncome)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final expense = visible
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    return Column(
      children: [
        const CategoryFilterBar(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SummaryHeader(income: income, expense: expense),
        ),
        Expanded(
          child: grouped.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No transactions',
                  message: provider.categoryFilter == null
                      ? 'Nothing recorded for ${formatMonth(provider.selectedMonth)} yet.'
                      : 'No transactions in this category for '
                          '${formatMonth(provider.selectedMonth)}.',
                  action: provider.categoryFilter == null
                      ? null
                      : TextButton(
                          onPressed: () => provider.setCategoryFilter(null),
                          child: const Text('Clear filter'),
                        ),
                )
              : ListView(
                  // Leave room so the FAB never covers the last row.
                  padding: const EdgeInsets.only(top: 8, bottom: 96),
                  children: [
                    for (final entry in grouped.entries) ...[
                      _DayHeader(day: entry.key, transactions: entry.value),
                      for (final transaction in entry.value)
                        _DismissibleTransaction(transaction: transaction),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.transactions});

  final DateTime day;
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final net = SummaryService.netOf(transactions);
    final style = theme.textTheme.labelLarge
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(child: Text(formatDayHeader(day), style: style)),
          Text(formatSignedCurrency(net), style: style),
        ],
      ),
    );
  }
}

class _DismissibleTransaction extends StatelessWidget {
  const _DismissibleTransaction({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      onDismissed: (_) => _delete(context),
      child: TransactionTile(
        transaction: transaction,
        onTap: () => openTransactionForm(context, transaction: transaction),
      ),
    );
  }

  void _delete(BuildContext context) {
    final provider = context.read<TransactionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final removed = transaction;
    provider.deleteTransaction(removed.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted "${removed.title}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => provider.restoreTransaction(removed),
          ),
        ),
      );
  }
}

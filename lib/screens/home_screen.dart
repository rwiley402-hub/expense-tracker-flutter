import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/transaction_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/month_selector.dart';
import 'budgets_screen.dart';
import 'summary_screen.dart';
import 'transaction_form_screen.dart';
import 'transactions_screen.dart';

enum _MenuAction { resetSampleData }

/// Root scaffold with bottom navigation between the three main tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _titles = ['Transactions', 'Summary', 'Budgets'];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();

    final Widget body;
    if (provider.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.errorMessage != null && provider.transactions.isEmpty) {
      body = EmptyState(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        message: provider.errorMessage,
        action: FilledButton(
          onPressed: provider.load,
          child: const Text('Retry'),
        ),
      );
    } else {
      body = IndexedStack(
        index: _index,
        children: const [
          TransactionsScreen(),
          SummaryScreen(),
          BudgetsScreen(),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          PopupMenuButton<_MenuAction>(
            onSelected: (action) {
              switch (action) {
                case _MenuAction.resetSampleData:
                  _confirmReset(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _MenuAction.resetSampleData,
                child: ListTile(
                  leading: Icon(Icons.restart_alt),
                  title: Text('Reset sample data'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: MonthSelector(),
        ),
      ),
      body: body,
      floatingActionButton: _index == 0 && !provider.isLoading
          ? FloatingActionButton.extended(
              onPressed: () => openTransactionForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Summary',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Budgets',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final provider = context.read<TransactionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset sample data?'),
        content: const Text(
          'All your transactions and budgets will be replaced with the '
          'bundled demo data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await provider.resetToSampleData();
    messenger.showSnackBar(
      const SnackBar(content: Text('Sample data restored')),
    );
  }
}

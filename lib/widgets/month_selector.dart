import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/transaction_provider.dart';
import '../utils/formatters.dart';

/// "‹ September 2026 ›" control shown under the app bar.
class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();

    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed:
                provider.canGoToPreviousMonth ? provider.goToPreviousMonth : null,
            icon: const Icon(Icons.chevron_left),
          ),
          TextButton.icon(
            onPressed: () => _showMonthPicker(context, provider),
            icon: const Icon(Icons.calendar_month, size: 18),
            label: Text(formatMonth(provider.selectedMonth)),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: provider.canGoToNextMonth ? provider.goToNextMonth : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Future<void> _showMonthPicker(
    BuildContext context,
    TransactionProvider provider,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final months = provider.availableMonths;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final month in months)
                ListTile(
                  title: Text(formatMonth(month)),
                  trailing: month == provider.selectedMonth
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    provider.selectMonth(month);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

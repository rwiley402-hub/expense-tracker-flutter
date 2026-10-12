import 'package:flutter/material.dart';

import '../services/summary_service.dart';

/// Semantic colours that are not part of the Material colour scheme.
abstract final class AppColors {
  static const Color income = Color(0xFF2E7D32);
  static const Color incomeDark = Color(0xFF81C784);
  static const Color healthy = Color(0xFF43A047);
  static const Color warning = Color(0xFFF57C00);

  static Color incomeFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? incomeDark : income;

  static Color expenseFor(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  static Color budgetLevel(BuildContext context, BudgetLevel level) {
    switch (level) {
      case BudgetLevel.exceeded:
        return Theme.of(context).colorScheme.error;
      case BudgetLevel.warning:
        return warning;
      case BudgetLevel.healthy:
        return healthy;
      case BudgetLevel.unbudgeted:
        return Theme.of(context).colorScheme.outline;
    }
  }
}

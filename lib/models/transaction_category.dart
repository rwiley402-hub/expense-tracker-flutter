import 'package:flutter/material.dart';

import 'transaction.dart';

/// A category that transactions are grouped under, with its visual identity.
///
/// Named `TransactionCategory` to avoid clashing with Flutter's own
/// `Category` annotation exported from `foundation.dart`.
@immutable
class TransactionCategory {
  const TransactionCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;

  /// Which kind of transaction this category applies to.
  final TransactionType type;

  bool get isExpense => type == TransactionType.expense;

  @override
  bool operator ==(Object other) =>
      other is TransactionCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

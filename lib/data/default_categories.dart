import 'package:flutter/material.dart';

import '../models/transaction.dart';
import '../models/transaction_category.dart';

/// Id of the catch-all expense category, used when an unknown id is found.
const String kFallbackCategoryId = 'other';

/// Built-in categories. Transactions only store the category id, so the
/// icon and colour can be changed here without migrating stored data.
const List<TransactionCategory> kCategories = [
  // Expenses
  TransactionCategory(
    id: 'groceries',
    name: 'Groceries',
    icon: Icons.local_grocery_store,
    color: Color(0xFF43A047),
    type: TransactionType.expense,
  ),
  TransactionCategory(
    id: 'dining',
    name: 'Dining',
    icon: Icons.restaurant,
    color: Color(0xFFFB8C00),
    type: TransactionType.expense,
  ),
  TransactionCategory(
    id: 'transport',
    name: 'Transport',
    icon: Icons.directions_car,
    color: Color(0xFF1E88E5),
    type: TransactionType.expense,
  ),
  TransactionCategory(
    id: 'housing',
    name: 'Housing',
    icon: Icons.home,
    color: Color(0xFF6D4C41),
    type: TransactionType.expense,
  ),
  TransactionCategory(
    id: 'utilities',
    name: 'Utilities',
    icon: Icons.bolt,
    color: Color(0xFFF9A825),
    type: TransactionType.expense,
  ),
  TransactionCategory(
    id: 'entertainment',
    name: 'Entertainment',
    icon: Icons.movie,
    color: Color(0xFF8E24AA),
    type: TransactionType.expense,
  ),
  TransactionCategory(
    id: 'shopping',
    name: 'Shopping',
    icon: Icons.shopping_bag,
    color: Color(0xFFD81B60),
    type: TransactionType.expense,
  ),
  TransactionCategory(
    id: 'health',
    name: 'Health',
    icon: Icons.favorite,
    color: Color(0xFFE53935),
    type: TransactionType.expense,
  ),
  TransactionCategory(
    id: kFallbackCategoryId,
    name: 'Other',
    icon: Icons.category,
    color: Color(0xFF757575),
    type: TransactionType.expense,
  ),
  // Income
  TransactionCategory(
    id: 'salary',
    name: 'Salary',
    icon: Icons.account_balance_wallet,
    color: Color(0xFF00897B),
    type: TransactionType.income,
  ),
  TransactionCategory(
    id: 'freelance',
    name: 'Freelance',
    icon: Icons.laptop_mac,
    color: Color(0xFF3949AB),
    type: TransactionType.income,
  ),
  TransactionCategory(
    id: 'other_income',
    name: 'Other income',
    icon: Icons.savings,
    color: Color(0xFF7CB342),
    type: TransactionType.income,
  ),
];

final Map<String, TransactionCategory> _categoriesById = {
  for (final category in kCategories) category.id: category,
};

/// Looks up a category, falling back to "Other" for unknown ids.
TransactionCategory categoryById(String id) =>
    _categoriesById[id] ?? _categoriesById[kFallbackCategoryId]!;

/// Whether [id] refers to a known category.
bool isKnownCategory(String id) => _categoriesById.containsKey(id);

/// All categories applicable to the given transaction [type].
List<TransactionCategory> categoriesForType(TransactionType type) =>
    kCategories.where((c) => c.type == type).toList(growable: false);

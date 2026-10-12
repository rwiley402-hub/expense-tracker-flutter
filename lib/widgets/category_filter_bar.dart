import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/default_categories.dart';
import '../state/transaction_provider.dart';

/// Horizontally scrolling chips to filter the list by category.
class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final selected = provider.categoryFilter;

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => provider.setCategoryFilter(null),
            ),
          ),
          for (final category in kCategories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                showCheckmark: false,
                avatar: Icon(category.icon, size: 18, color: category.color),
                label: Text(category.name),
                selected: selected == category.id,
                onSelected: (isSelected) => provider
                    .setCategoryFilter(isSelected ? category.id : null),
              ),
            ),
        ],
      ),
    );
  }
}

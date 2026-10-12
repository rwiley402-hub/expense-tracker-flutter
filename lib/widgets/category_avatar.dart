import 'package:flutter/material.dart';

import '../models/transaction_category.dart';

/// Round tinted badge showing a category's icon in its colour.
class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({super.key, required this.category, this.radius = 20});

  final TransactionCategory category;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: category.name,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: category.color.withValues(alpha: 0.16),
        child: Icon(category.icon, color: category.color, size: radius),
      ),
    );
  }
}

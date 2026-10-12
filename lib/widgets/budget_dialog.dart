import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/transaction_category.dart';
import '../utils/validators.dart';

/// Asks for a monthly budget. Pops with the new limit, `0` to remove the
/// budget, or `null` when cancelled.
Future<double?> showBudgetDialog(
  BuildContext context, {
  required TransactionCategory category,
  double currentLimit = 0,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) =>
        _BudgetDialog(category: category, currentLimit: currentLimit),
  );
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.category, required this.currentLimit});

  final TransactionCategory category;
  final double currentLimit;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentLimit > 0
          ? widget.currentLimit.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(parseAmount(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(widget.category.icon, color: widget.category.color),
      title: Text('${widget.category.name} budget'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Monthly limit',
            prefixText: r'$ ',
            border: OutlineInputBorder(),
          ),
          validator: validateAmount,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        if (widget.currentLimit > 0)
          TextButton(
            onPressed: () => Navigator.of(context).pop(0.0),
            child: const Text('Remove'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

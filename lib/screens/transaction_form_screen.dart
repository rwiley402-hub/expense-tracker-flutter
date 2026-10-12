import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/default_categories.dart';
import '../models/transaction.dart';
import '../services/summary_service.dart';
import '../state/transaction_provider.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';

/// Opens the add/edit form. Pass [transaction] to edit an existing one.
Future<void> openTransactionForm(
  BuildContext context, {
  Transaction? transaction,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => TransactionFormScreen(transaction: transaction),
      fullscreenDialog: transaction == null,
    ),
  );
}

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, this.transaction});

  final Transaction? transaction;

  bool get isEditing => transaction != null;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  static const _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late TransactionType _type;
  late String _categoryId;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.transaction;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _amountController = TextEditingController(
      text: existing == null ? '' : existing.amount.toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _type = existing?.type ?? TransactionType.expense;
    _categoryId = existing?.categoryId ?? categoriesForType(_type).first.id;
    _date = existing?.day ??
        _defaultDateFor(context.read<TransactionProvider>().selectedMonth);
  }

  /// Today when viewing the current month; otherwise a day inside the
  /// viewed month so the new entry shows up where the user is looking.
  static DateTime _defaultDateFor(DateTime selectedMonth) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (SummaryService.isSameMonth(selectedMonth, today)) return today;
    if (selectedMonth.isAfter(today)) return selectedMonth;
    // Last day of a past month.
    return DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(Set<TransactionType> selection) {
    setState(() {
      _type = selection.first;
      if (categoryById(_categoryId).type != _type) {
        _categoryId = categoriesForType(_type).first.id;
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<TransactionProvider>();
    final navigator = Navigator.of(context);
    final note = _noteController.text.trim();
    final transaction = Transaction(
      id: widget.transaction?.id ?? _uuid.v4(),
      title: _titleController.text.trim(),
      amount: parseAmount(_amountController.text)!,
      type: _type,
      categoryId: _categoryId,
      date: DateTime(_date.year, _date.month, _date.day),
      note: note.isEmpty ? null : note,
    );

    if (widget.isEditing) {
      await provider.updateTransaction(transaction);
    } else {
      await provider.addTransaction(transaction);
    }
    // Jump to the month the transaction was saved in.
    provider.selectMonth(transaction.date);
    navigator.pop();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text('"${widget.transaction!.title}" will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final provider = context.read<TransactionProvider>();
    final navigator = Navigator.of(context);
    await provider.deleteTransaction(widget.transaction!.id);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categories = categoriesForType(_type);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit transaction' : 'New transaction'),
        actions: [
          if (widget.isEditing)
            IconButton(
              tooltip: 'Delete',
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: _onTypeChanged,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                autofocus: !widget.isEditing,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: r'$ ',
                  border: OutlineInputBorder(),
                ),
                validator: validateAmount,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Weekly groceries',
                  border: OutlineInputBorder(),
                ),
                validator: validateTitle,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              Text('Category', style: textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in categories)
                    ChoiceChip(
                      showCheckmark: false,
                      avatar: Icon(
                        category.icon,
                        size: 18,
                        color: category.color,
                      ),
                      label: Text(category.name),
                      selected: _categoryId == category.id,
                      onSelected: (_) =>
                          setState(() => _categoryId = category.id),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.event),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(formatFullDate(_date)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                minLines: 1,
                maxLines: 3,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(
                  widget.isEditing ? 'Save changes' : 'Add transaction',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

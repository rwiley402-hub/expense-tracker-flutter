import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/default_budgets.dart';
import '../models/transaction.dart';
import '../services/summary_service.dart';
import '../services/transaction_repository.dart';

/// App-wide state: transactions, budgets and the current month/category
/// filters. Widgets read it through `provider` (`context.watch`/`read`).
///
/// Mutations update memory and notify listeners synchronously (so things
/// like `Dismissible` see the item disappear immediately), then persist.
class TransactionProvider extends ChangeNotifier {
  TransactionProvider(this._repository, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _selectedMonth = SummaryService.monthOf(_clock());
  }

  final TransactionRepository _repository;
  final DateTime Function() _clock;

  List<Transaction> _transactions = const [];
  Map<String, double> _budgets = const {};
  late DateTime _selectedMonth;
  String? _categoryFilter;
  bool _isLoading = true;
  String? _errorMessage;

  // ---------------------------------------------------------------------------
  // Read-only state
  // ---------------------------------------------------------------------------

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UnmodifiableListView<Transaction> get transactions =>
      UnmodifiableListView(_transactions);

  Map<String, double> get budgets => Map.unmodifiable(_budgets);

  /// First day of the month currently being viewed.
  DateTime get selectedMonth => _selectedMonth;

  /// Category id used to filter the transaction list, or null for all.
  String? get categoryFilter => _categoryFilter;

  DateTime get currentMonth => SummaryService.monthOf(_clock());

  /// Transactions for the selected month and category, newest first.
  List<Transaction> get visibleTransactions => SummaryService.filter(
        _transactions,
        month: _selectedMonth,
        categoryId: _categoryFilter,
      );

  /// [visibleTransactions] grouped per day.
  Map<DateTime, List<Transaction>> get groupedTransactions =>
      SummaryService.groupByDay(visibleTransactions);

  /// Summary of the whole selected month (ignores the category filter).
  MonthlySummary get summary =>
      SummaryService.summarize(_transactions, _selectedMonth);

  /// Summary of the month before the selected one, for comparisons.
  MonthlySummary get previousMonthSummary => SummaryService.summarize(
        _transactions,
        SummaryService.addMonths(_selectedMonth, -1),
      );

  List<BudgetStatus> get budgetStatuses =>
      SummaryService.budgetStatuses(summary, _budgets);

  /// Months the user can jump to: every month with data plus the current
  /// month, newest first.
  List<DateTime> get availableMonths {
    final months = {
      ...SummaryService.monthsWithData(_transactions),
      currentMonth,
    }.toList()
      ..sort((a, b) => b.compareTo(a));
    return months;
  }

  bool get canGoToPreviousMonth =>
      _selectedMonth.isAfter(availableMonths.last);

  bool get canGoToNextMonth => _selectedMonth.isBefore(availableMonths.first);

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  /// Loads saved data. Safe to call from a provider's `create` callback:
  /// it only notifies listeners after the first `await`.
  Future<void> load() async {
    try {
      final loaded = await _repository.loadTransactions();
      final budgets = await _repository.loadBudgets();
      _transactions = List.of(loaded);
      _budgets = Map.of(budgets);
      _errorMessage = null;
      _selectInitialMonth();
    } catch (error, stackTrace) {
      debugPrint('Failed to load data: $error\n$stackTrace');
      _errorMessage = 'Could not load your data. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Replaces all data with the bundled demo set and default budgets.
  Future<void> resetToSampleData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _transactions = List.of(await _repository.loadSampleTransactions());
      _budgets = Map.of(kDefaultBudgets);
      _categoryFilter = null;
      _errorMessage = null;
      _selectInitialMonth();
      await _repository.saveTransactions(_transactions);
      await _repository.saveBudgets(_budgets);
    } catch (error) {
      debugPrint('Failed to reset data: $error');
      _errorMessage = 'Could not reset the sample data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Shows the current month if it has data, otherwise the latest month
  /// that does (handy with the historical demo data set).
  void _selectInitialMonth() {
    final now = currentMonth;
    final hasCurrent = _transactions.any(
      (t) => SummaryService.isSameMonth(t.date, now),
    );
    final withData = SummaryService.monthsWithData(_transactions);
    _selectedMonth = hasCurrent || withData.isEmpty ? now : withData.first;
  }

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------

  void selectMonth(DateTime month) {
    final normalized = SummaryService.monthOf(month);
    if (normalized == _selectedMonth) return;
    _selectedMonth = normalized;
    notifyListeners();
  }

  void goToPreviousMonth() {
    if (canGoToPreviousMonth) {
      selectMonth(SummaryService.addMonths(_selectedMonth, -1));
    }
  }

  void goToNextMonth() {
    if (canGoToNextMonth) {
      selectMonth(SummaryService.addMonths(_selectedMonth, 1));
    }
  }

  void setCategoryFilter(String? categoryId) {
    if (categoryId == _categoryFilter) return;
    _categoryFilter = categoryId;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Transactions CRUD
  // ---------------------------------------------------------------------------

  Transaction? findById(String id) {
    for (final t in _transactions) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> addTransaction(Transaction transaction) async {
    _transactions = [..._transactions, transaction];
    notifyListeners();
    await _persistTransactions();
  }

  /// Replaces the transaction with the same id. Returns false if not found.
  Future<bool> updateTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index == -1) return false;
    _transactions = List.of(_transactions)..[index] = transaction;
    notifyListeners();
    await _persistTransactions();
    return true;
  }

  /// Removes a transaction and returns it so the UI can offer "Undo".
  Future<Transaction?> deleteTransaction(String id) async {
    final removed = findById(id);
    if (removed == null) return null;
    _transactions = _transactions.where((t) => t.id != id).toList();
    notifyListeners();
    await _persistTransactions();
    return removed;
  }

  /// Re-adds a previously deleted transaction (no-op if it already exists).
  Future<void> restoreTransaction(Transaction transaction) async {
    if (findById(transaction.id) != null) return;
    await addTransaction(transaction);
  }

  // ---------------------------------------------------------------------------
  // Budgets
  // ---------------------------------------------------------------------------

  /// Sets a monthly budget for [categoryId]. A limit of 0 or less removes it.
  Future<void> setBudget(String categoryId, double limit) async {
    final updated = Map.of(_budgets);
    if (limit <= 0) {
      updated.remove(categoryId);
    } else {
      updated[categoryId] = limit;
    }
    _budgets = updated;
    notifyListeners();
    try {
      await _repository.saveBudgets(_budgets);
    } catch (error) {
      debugPrint('Failed to save budgets: $error');
    }
  }

  Future<void> _persistTransactions() async {
    try {
      await _repository.saveTransactions(_transactions);
    } catch (error) {
      debugPrint('Failed to save transactions: $error');
    }
  }
}

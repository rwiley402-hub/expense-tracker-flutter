import 'package:expense_tracker/data/default_budgets.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/services/transaction_repository.dart';

/// [TransactionRepository] fake that keeps everything in memory and counts
/// writes so tests can assert persistence happened.
class InMemoryTransactionRepository implements TransactionRepository {
  InMemoryTransactionRepository({
    List<Transaction> initial = const [],
    List<Transaction> sample = const [],
    Map<String, double>? budgets,
  })  : _stored = List.of(initial),
        _sample = List.of(sample),
        _budgets = Map.of(budgets ?? kDefaultBudgets);

  List<Transaction> _stored;
  final List<Transaction> _sample;
  Map<String, double> _budgets;

  int transactionSaves = 0;
  int budgetSaves = 0;

  List<Transaction> get stored => List.unmodifiable(_stored);
  Map<String, double> get storedBudgets => Map.unmodifiable(_budgets);

  @override
  Future<List<Transaction>> loadTransactions() async => List.of(_stored);

  @override
  Future<void> saveTransactions(List<Transaction> transactions) async {
    transactionSaves++;
    _stored = List.of(transactions);
  }

  @override
  Future<Map<String, double>> loadBudgets() async => Map.of(_budgets);

  @override
  Future<void> saveBudgets(Map<String, double> budgets) async {
    budgetSaves++;
    _budgets = Map.of(budgets);
  }

  @override
  Future<List<Transaction>> loadSampleTransactions() async => List.of(_sample);
}

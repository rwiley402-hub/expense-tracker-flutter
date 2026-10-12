import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/default_budgets.dart';
import '../models/transaction.dart';

/// Storage abstraction so the state layer can be tested with an in-memory
/// fake and the backing store (shared_preferences today, maybe Hive or a
/// server later) can be swapped without touching the UI.
abstract interface class TransactionRepository {
  /// Returns saved transactions. On first launch this seeds the store with
  /// the bundled sample data.
  Future<List<Transaction>> loadTransactions();

  Future<void> saveTransactions(List<Transaction> transactions);

  /// Returns saved budgets, or [kDefaultBudgets] on first launch.
  Future<Map<String, double>> loadBudgets();

  Future<void> saveBudgets(Map<String, double> budgets);

  /// Reads the bundled demo data set (does not touch the saved data).
  Future<List<Transaction>> loadSampleTransactions();
}

/// Decodes either a bare JSON array of transactions or an object with a
/// `transactions` array (the format used by the bundled asset).
List<Transaction> decodeTransactions(String raw) {
  final Object? decoded = jsonDecode(raw);
  final List<dynamic> items;
  if (decoded is Map<String, dynamic>) {
    items = decoded['transactions'] as List<dynamic>;
  } else if (decoded is List<dynamic>) {
    items = decoded;
  } else {
    throw const FormatException('Unexpected transactions JSON shape');
  }
  return [
    for (final item in items)
      Transaction.fromJson(item as Map<String, dynamic>),
  ];
}

String encodeTransactions(List<Transaction> transactions) =>
    jsonEncode([for (final t in transactions) t.toJson()]);

Map<String, double> decodeBudgets(String raw) {
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  return decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
}

/// [TransactionRepository] backed by `shared_preferences`, which is plenty
/// for a few thousand small records in a personal finance app.
class LocalTransactionRepository implements TransactionRepository {
  LocalTransactionRepository(this._prefs, {AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  static const String transactionsKey = 'expense_tracker.transactions.v1';
  static const String budgetsKey = 'expense_tracker.budgets.v1';
  static const String sampleDataAsset = 'assets/data/transactions.json';

  final SharedPreferences _prefs;
  final AssetBundle _bundle;

  @override
  Future<List<Transaction>> loadTransactions() async {
    final raw = _prefs.getString(transactionsKey);
    if (raw == null) {
      final sample = await loadSampleTransactions();
      await saveTransactions(sample);
      return sample;
    }
    return decodeTransactions(raw);
  }

  @override
  Future<void> saveTransactions(List<Transaction> transactions) async {
    await _prefs.setString(transactionsKey, encodeTransactions(transactions));
  }

  @override
  Future<Map<String, double>> loadBudgets() async {
    final raw = _prefs.getString(budgetsKey);
    if (raw == null) return Map.of(kDefaultBudgets);
    return decodeBudgets(raw);
  }

  @override
  Future<void> saveBudgets(Map<String, double> budgets) async {
    await _prefs.setString(budgetsKey, jsonEncode(budgets));
  }

  @override
  Future<List<Transaction>> loadSampleTransactions() async {
    final raw = await _bundle.loadString(sampleDataAsset);
    return decodeTransactions(raw);
  }
}

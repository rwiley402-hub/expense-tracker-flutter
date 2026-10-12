import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/transaction_repository.dart';
import 'state/transaction_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final repository = LocalTransactionRepository(prefs);

  runApp(
    ChangeNotifierProvider(
      create: (_) => TransactionProvider(repository)..load(),
      child: const ExpenseTrackerApp(),
    ),
  );
}

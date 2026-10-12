import 'package:expense_tracker/models/transaction.dart';

/// Small helper to build transactions tersely in tests.
Transaction tx(
  String id, {
  required double amount,
  required String category,
  required DateTime date,
  TransactionType type = TransactionType.expense,
  String? title,
  String? note,
}) {
  return Transaction(
    id: id,
    title: title ?? 'Transaction $id',
    amount: amount,
    type: type,
    categoryId: category,
    date: date,
    note: note,
  );
}

/// A tiny, hand-checkable data set spanning August and September 2026.
///
/// September 2026:
///   income   salary 4000 + freelance 500          = 4500
///   expenses groceries 120.50 + 80.25 = 200.75
///            dining 45.10 + 30.00     =  75.10
///            housing 1500                          = 1775.85 total
/// August 2026:
///   income   salary 4000
///   expenses groceries 300, dining 50              =  350 total
final List<Transaction> sampleTransactions = [
  tx('s1', amount: 4000, category: 'salary', date: DateTime(2026, 9, 1),
      type: TransactionType.income),
  tx('s2', amount: 500, category: 'freelance', date: DateTime(2026, 9, 18),
      type: TransactionType.income),
  tx('s3', amount: 120.50, category: 'groceries', date: DateTime(2026, 9, 3)),
  tx('s4', amount: 80.25, category: 'groceries', date: DateTime(2026, 9, 17)),
  tx('s5', amount: 45.10, category: 'dining', date: DateTime(2026, 9, 3)),
  tx('s6', amount: 30.00, category: 'dining', date: DateTime(2026, 9, 21)),
  tx('s7', amount: 1500, category: 'housing', date: DateTime(2026, 9, 1)),
  tx('a1', amount: 4000, category: 'salary', date: DateTime(2026, 8, 1),
      type: TransactionType.income),
  tx('a2', amount: 300, category: 'groceries', date: DateTime(2026, 8, 12)),
  tx('a3', amount: 50, category: 'dining', date: DateTime(2026, 8, 30)),
];

import 'dart:convert';
import 'dart:io';

import 'package:expense_tracker/data/default_categories.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/services/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Transaction JSON', () {
    test('round-trips through toJson/fromJson', () {
      final original = Transaction(
        id: 'abc',
        title: 'Luna Ramen House',
        amount: 23.4,
        type: TransactionType.expense,
        categoryId: 'dining',
        date: DateTime(2026, 9, 14),
        note: 'Lunch with Priya',
      );

      final json = original.toJson();
      expect(json['date'], '2026-09-14');
      expect(json['type'], 'expense');

      final decoded = Transaction.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      );
      expect(decoded, original);
    });

    test('omits empty notes and accepts integer amounts', () {
      final t = Transaction.fromJson(const {
        'id': '1',
        'title': 'Salary',
        'amount': 4850,
        'type': 'income',
        'categoryId': 'salary',
        'date': '2026-07-01',
      });
      expect(t.amount, 4850.0);
      expect(t.isIncome, isTrue);
      expect(t.signedAmount, 4850.0);
      expect(t.toJson().containsKey('note'), isFalse);
    });

    test('unknown type falls back to expense', () {
      expect(TransactionType.fromName('refund'), TransactionType.expense);
    });

    test('decodeTransactions accepts wrapped and bare arrays', () {
      const item = {
        'id': '1',
        'title': 'Coffee',
        'amount': 3.5,
        'type': 'expense',
        'categoryId': 'dining',
        'date': '2026-09-01',
      };
      expect(decodeTransactions(jsonEncode([item])), hasLength(1));
      expect(
        decodeTransactions(jsonEncode({
          'transactions': [item, item],
        })),
        hasLength(2),
      );
      expect(() => decodeTransactions('"nope"'), throwsFormatException);
    });
  });

  group('bundled sample data', () {
    late List<Transaction> seed;

    setUpAll(() {
      final raw = File('assets/data/transactions.json').readAsStringSync();
      seed = decodeTransactions(raw);
    });

    test('contains roughly three months of transactions', () {
      expect(seed.length, inInclusiveRange(70, 100));
      final months = seed.map((t) => '${t.date.year}-${t.date.month}').toSet();
      expect(months, hasLength(3));
    });

    test('uses unique ids and known categories that match the type', () {
      expect(seed.map((t) => t.id).toSet(), hasLength(seed.length));
      for (final t in seed) {
        expect(isKnownCategory(t.categoryId), isTrue,
            reason: 'unknown category ${t.categoryId}');
        expect(categoryById(t.categoryId).type, t.type,
            reason: '${t.id} has mismatched type');
        expect(t.amount, greaterThan(0));
      }
    });
  });
}

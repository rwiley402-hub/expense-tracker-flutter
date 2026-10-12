import 'package:flutter/foundation.dart';

/// Whether money left the wallet (expense) or came in (income).
enum TransactionType {
  expense,
  income;

  /// Parses a stored name, falling back to [TransactionType.expense].
  static TransactionType fromName(String value) => TransactionType.values
      .firstWhere((t) => t.name == value, orElse: () => TransactionType.expense);
}

/// A single money movement. [amount] is always positive; the sign is derived
/// from [type] via [signedAmount].
@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.fromName(json['type'] as String),
      categoryId: json['categoryId'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;

  /// Calendar day of the transaction (time component is ignored).
  final DateTime date;
  final String? note;

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  /// Negative for expenses, positive for income.
  double get signedAmount => isExpense ? -amount : amount;

  /// The transaction's date with the time stripped.
  DateTime get day => DateTime(date.year, date.month, date.day);

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    DateTime? date,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'categoryId': categoryId,
        'date': formatDateOnly(date),
        if (note != null && note!.isNotEmpty) 'note': note,
      };

  /// Formats [d] as `yyyy-MM-dd`, the storage format for dates.
  static String formatDateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          other.id == id &&
          other.title == title &&
          other.amount == amount &&
          other.type == type &&
          other.categoryId == categoryId &&
          other.day == day &&
          other.note == note;

  @override
  int get hashCode =>
      Object.hash(id, title, amount, type, categoryId, day, note);

  @override
  String toString() => 'Transaction($id, $title, '
      '${signedAmount.toStringAsFixed(2)}, $categoryId, ${formatDateOnly(date)})';
}

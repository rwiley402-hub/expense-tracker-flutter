import 'package:intl/intl.dart';

const String _locale = 'en_US';

final NumberFormat _currency =
    NumberFormat.currency(locale: _locale, symbol: r'$', decimalDigits: 2);
final NumberFormat _compactCurrency =
    NumberFormat.compactSimpleCurrency(locale: _locale);

/// `1234.5` -> `$1,234.50`
String formatCurrency(double value) => _currency.format(value);

/// `-12.5` -> `-$12.50`, `40` -> `+$40.00`
String formatSignedCurrency(double value) {
  final sign = value < 0 ? '-' : '+';
  return '$sign${_currency.format(value.abs())}';
}

/// `1234.5` -> `$1.2K`
String formatCompactCurrency(double value) => _compactCurrency.format(value);

/// `0.256` -> `26%`
String formatPercent(double ratio) => '${(ratio * 100).round()}%';

/// `DateTime(2026, 9)` -> `September 2026`
String formatMonth(DateTime month) =>
    DateFormat.yMMMM(_locale).format(month);

/// `DateTime(2026, 9)` -> `Sep`
String formatShortMonth(DateTime month) =>
    DateFormat.MMM(_locale).format(month);

/// `Tue, Sep 15, 2026`
String formatFullDate(DateTime date) =>
    DateFormat.yMMMEd(_locale).format(date);

/// Header for a group of transactions: "Today", "Yesterday" or
/// e.g. "Tue, Sep 15".
String formatDayHeader(DateTime day, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final target = DateTime(day.year, day.month, day.day);
  final difference = today.difference(target).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  if (target.year == today.year) {
    return DateFormat.MMMEd(_locale).format(target);
  }
  return DateFormat.yMMMEd(_locale).format(target);
}

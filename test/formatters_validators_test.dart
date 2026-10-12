import 'package:expense_tracker/utils/formatters.dart';
import 'package:expense_tracker/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatters', () {
    test('currency', () {
      expect(formatCurrency(1234.5), r'$1,234.50');
      expect(formatSignedCurrency(-12.5), r'-$12.50');
      expect(formatSignedCurrency(40), r'+$40.00');
    });

    test('percent and month', () {
      expect(formatPercent(0.256), '26%');
      expect(formatMonth(DateTime(2026, 9)), 'September 2026');
    });

    test('day header uses relative labels', () {
      final now = DateTime(2026, 9, 15, 10);
      expect(formatDayHeader(DateTime(2026, 9, 15), now: now), 'Today');
      expect(formatDayHeader(DateTime(2026, 9, 14), now: now), 'Yesterday');
      expect(formatDayHeader(DateTime(2026, 9, 1), now: now), 'Tue, Sep 1');
      expect(formatDayHeader(DateTime(2025, 12, 31), now: now),
          'Wed, Dec 31, 2025');
    });
  });

  group('parseAmount', () {
    test('accepts common formats', () {
      expect(parseAmount('12'), 12);
      expect(parseAmount(' 12.5 '), 12.5);
      expect(parseAmount('12,50'), 12.5);
      expect(parseAmount('1,234.56'), 1234.56);
      expect(parseAmount('3.14159'), 3.14);
    });

    test('rejects junk', () {
      expect(parseAmount(''), isNull);
      expect(parseAmount(null), isNull);
      expect(parseAmount('abc'), isNull);
      expect(parseAmount('1.2.3'), isNull);
    });
  });

  group('validators', () {
    test('validateAmount', () {
      expect(validateAmount(''), isNotNull);
      expect(validateAmount('0'), isNotNull);
      expect(validateAmount('x'), isNotNull);
      expect(validateAmount('2000000'), isNotNull);
      expect(validateAmount('19.99'), isNull);
    });

    test('validateTitle', () {
      expect(validateTitle('   '), isNotNull);
      expect(validateTitle('a' * 61), isNotNull);
      expect(validateTitle('Groceries'), isNull);
    });
  });
}

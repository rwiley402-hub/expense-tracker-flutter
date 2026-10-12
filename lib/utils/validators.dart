/// Parses user-entered money amounts such as `12`, `12.5`, `12,50` or
/// `1,234.56`. Returns null for anything that is not a finite number.
/// The result is rounded to cents.
double? parseAmount(String? input) {
  if (input == null) return null;
  var text = input.trim().replaceAll(' ', '');
  if (text.isEmpty) return null;

  if (text.contains(',') && text.contains('.')) {
    // "1,234.56" - comma is a thousands separator.
    text = text.replaceAll(',', '');
  } else {
    // "12,50" - comma is a decimal separator.
    text = text.replaceAll(',', '.');
  }

  final value = double.tryParse(text);
  if (value == null || value.isNaN || value.isInfinite) return null;
  return (value * 100).roundToDouble() / 100;
}

/// Largest amount accepted for a single transaction or budget.
const double kMaxAmount = 1000000;

/// Form validator for a required, positive amount.
String? validateAmount(String? input) {
  final value = parseAmount(input);
  if (input == null || input.trim().isEmpty) return 'Enter an amount';
  if (value == null) return 'Enter a valid number';
  if (value <= 0) return 'Amount must be greater than zero';
  if (value > kMaxAmount) return 'Amount is too large';
  return null;
}

/// Form validator for a required title.
String? validateTitle(String? input) {
  final text = input?.trim() ?? '';
  if (text.isEmpty) return 'Enter a title';
  if (text.length > 60) return 'Keep the title under 60 characters';
  return null;
}

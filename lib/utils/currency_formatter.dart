// lib/utils/currency_formatter.dart
class CurrencyFormatter {
  // Константний метод форматування, завжди використовує символ гривні
  static String formatSync(double amount) {
    String formattedAmount = amount.toStringAsFixed(2);
    return '$formattedAmount ₴';
  }
}
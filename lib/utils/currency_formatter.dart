// lib/utils/currency_formatter.dart
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyFormatter {
  static Future<String> format(double amount, String currencyCode) async {
    final prefs = await SharedPreferences.getInstance();
    final useSymbol = prefs.getBool('useCurrencySymbol') ?? true;
    
    String formattedAmount = amount.toStringAsFixed(2);
    
    if (useSymbol) {
      // Використовувати символи валют
      switch (currencyCode) {
        case 'UAH':
          return '$formattedAmount ₴';
        case 'USD':
          return '\$${formattedAmount}';
        case 'EUR':
          return '€${formattedAmount}';
        case 'GBP':
          return '£${formattedAmount}';
        default:
          return '$formattedAmount $currencyCode';
      }
    } else {
      // Використовувати текстові коди валют
      return '$formattedAmount $currencyCode';
    }
  }
  
  // Синхронна версія, яка не потребує await, але використовує поточне значення з глобальної змінної
  static String formatSync(double amount, String currencyCode) {
    final useSymbol = _useCurrencySymbol;
    
    String formattedAmount = amount.toStringAsFixed(2);
    
    if (useSymbol) {
      // Використовувати символи валют
      switch (currencyCode) {
        case 'UAH':
          return '$formattedAmount ₴';
        case 'USD':
          return '\$${formattedAmount}';
        case 'EUR':
          return '€${formattedAmount}';
        case 'GBP':
          return '£${formattedAmount}';
        default:
          return '$formattedAmount $currencyCode';
      }
    } else {
      // Використовувати текстові коди валют
      return '$formattedAmount $currencyCode';
    }
  }
  
  // Глобальне кешоване значення
  static bool _useCurrencySymbol = true;
  
  // Ініціалізація глобального значення
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _useCurrencySymbol = prefs.getBool('useCurrencySymbol') ?? true;
  }
  
  // Оновлення глобального значення
  static Future<void> setUseCurrencySymbol(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useCurrencySymbol', value);
    _useCurrencySymbol = value;
  }
}
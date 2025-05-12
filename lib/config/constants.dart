// lib/config/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Фінансовий трекер';
  
  // Дефолтні кольори для категорій
  static final List<Color> categoryColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.indigo,
    Colors.cyan,
    Colors.brown,
    Colors.lime,
  ];
  
  // Іконки для категорій
  static final List<IconData> categoryIcons = [
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.directions_bus,
    Icons.home,
    Icons.medical_services,
    Icons.sports,
    Icons.school,
    Icons.movie,
    Icons.travel_explore,
    Icons.credit_card,
    Icons.attach_money,
    Icons.savings,
    Icons.card_giftcard,
    Icons.sell,
    Icons.work,
    Icons.check_circle,
  ];
  
  // Іконки для рахунків
  static final List<IconData> accountIcons = [
    Icons.credit_card,
    Icons.account_balance,
    Icons.account_balance_wallet,
    Icons.savings,
    Icons.money,
    Icons.currency_exchange,
    Icons.payments,
    Icons.euro,
    Icons.attach_money,
  ];
  
  // Валюти
  static final List<String> currencies = [
    'UAH',
    'USD',
    'EUR',
  ];
  
  // Дні тижня для налаштувань
  static final List<String> daysOfWeek = [
    'Понеділок',
    'Вівторок',
    'Середа',
    'Четвер',
    'П\'ятниця',
    'Субота',
    'Неділя',
  ];
  
  // Формати дати
  static const String dateFormat = 'dd.MM.yyyy';
  static const String monthYearFormat = 'MMMM yyyy';
}
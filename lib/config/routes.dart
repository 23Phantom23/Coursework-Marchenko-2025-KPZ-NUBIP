// lib/config/routes.dart
import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/transactions/add_transaction_screen.dart';
import '../screens/transactions/transactions_screen.dart';
import '../screens/accounts/accounts_screen.dart';
import '../screens/accounts/add_account_screen.dart';
import '../screens/statistics/statistics_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../models/transaction.dart';
import '../models/account.dart';

class AppRoutes {
  static const String home = '/';
  static const String addTransaction = '/add-transaction';
  static const String transactions = '/transactions';
  static const String accounts = '/accounts';
  static const String addAccount = '/add-account';
  static const String statistics = '/statistics';
  static const String settings = '/settings';
  static const String categories = '/categories';
  
  static Map<String, WidgetBuilder> get routes {
    return {
      home: (context) => HomeScreen(),
      transactions: (context) => TransactionsScreen(),
      addTransaction: (context) {
        final transaction = ModalRoute.of(context)?.settings.arguments as Transaction?;
        return AddTransactionScreen(transaction: transaction);
      },
      accounts: (context) => AccountsScreen(),
      addAccount: (context) {
        final account = ModalRoute.of(context)?.settings.arguments as Account?;
        return AddAccountScreen(account: account);
      },
      statistics: (context) => StatisticsScreen(),
      settings: (context) => SettingsScreen(),
      categories: (context) => CategoriesScreen(),
    };
  }
}
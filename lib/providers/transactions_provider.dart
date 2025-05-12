// lib/providers/transactions_provider.dart
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import 'accounts_provider.dart';

class TransactionsProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;

  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  // Завантаження всіх транзакцій
  Future<void> loadTransactions() async {
    try {
      _isLoading = true;
      
      _transactions = await DatabaseService.instance.getTransactions();
    } catch (e) {
      print('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Завантаження транзакцій за період
  Future<void> loadTransactionsByPeriod(DateTime start, DateTime end) async {
    try {
      _isLoading = true;
      
      _transactions = await DatabaseService.instance.getTransactionsByPeriod(start, end);
    } catch (e) {
      print('Error loading transactions by period: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Завантаження транзакцій за рахунком
  Future<void> loadTransactionsByAccount(int accountId) async {
    try {
      _isLoading = true;
      
      _transactions = await DatabaseService.instance.getTransactionsByAccount(accountId);
    } catch (e) {
      print('Error loading transactions by account: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Додавання нової транзакції
  Future<void> addTransaction(Transaction transaction, AccountsProvider accountsProvider) async {
    try {
      final id = await DatabaseService.instance.insertTransaction(transaction);
      final newTransaction = transaction.copyWith(id: id);
      
      _transactions.insert(0, newTransaction);
      
      // Оновлення балансу рахунку
      double amountChange = 0;
      
      if (transaction.type == TransactionType.income) {
        amountChange = transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        amountChange = -transaction.amount;
      } else if (transaction.type == TransactionType.transfer && transaction.toAccountId != null) {
        // Переказ між рахунками
        accountsProvider.transferBetweenAccounts(
          transaction.accountId, 
          transaction.toAccountId!, 
          transaction.amount
        );
        notifyListeners();
        return;
      }
      
      // Оновлюємо баланс рахунку для доходів/витрат
      if (transaction.type != TransactionType.transfer) {
        await accountsProvider.updateAccountBalance(transaction.accountId, amountChange);
      }
      
      notifyListeners();
    } catch (e) {
      print('Error adding transaction: $e');
    }
  }

  // Оновлення транзакції
  Future<void> updateTransaction(Transaction transaction, AccountsProvider accountsProvider) async {
    try {
      // Знаходимо стару транзакцію для розрахунку різниці в балансі
      final oldTransactionIndex = _transactions.indexWhere((t) => t.id == transaction.id);
      if (oldTransactionIndex == -1) return;
      
      final oldTransaction = _transactions[oldTransactionIndex];
      
      await DatabaseService.instance.updateTransaction(transaction);
      
      // Оновити баланс рахунків, скасувавши стару транзакцію і застосувавши нову
      if (oldTransaction.type != TransactionType.transfer && transaction.type != TransactionType.transfer) {
        double oldAmount = oldTransaction.type == TransactionType.income 
            ? oldTransaction.amount 
            : -oldTransaction.amount;
        
        double newAmount = transaction.type == TransactionType.income 
            ? transaction.amount 
            : -transaction.amount;
        
        // Якщо рахунок змінився, оновлюємо обидва рахунки
        if (oldTransaction.accountId != transaction.accountId) {
          await accountsProvider.updateAccountBalance(oldTransaction.accountId, -oldAmount);
          await accountsProvider.updateAccountBalance(transaction.accountId, newAmount);
        } else {
          // Якщо рахунок не змінився, просто оновлюємо різницю
          await accountsProvider.updateAccountBalance(
            transaction.accountId, 
            newAmount - oldAmount
          );
        }
      } else {
        // Тут можна додати складнішу логіку для оновлення переказів між рахунками
        // Скасувати стару транзакцію і застосувати нову
      }
      
      _transactions[oldTransactionIndex] = transaction;
      notifyListeners();
    } catch (e) {
      print('Error updating transaction: $e');
    }
  }

  // Видалення транзакції
  Future<void> deleteTransaction(int id, AccountsProvider accountsProvider) async {
    try {
      final transaction = _transactions.firstWhere((t) => t.id == id);
      
      await DatabaseService.instance.deleteTransaction(id);
      
      // Оновлення балансу рахунку
      if (transaction.type == TransactionType.income) {
        await accountsProvider.updateAccountBalance(transaction.accountId, -transaction.amount);
      } else if (transaction.type == TransactionType.expense) {
        await accountsProvider.updateAccountBalance(transaction.accountId, transaction.amount);
      } else if (transaction.type == TransactionType.transfer && transaction.toAccountId != null) {
        // Скасовуємо переказ
        await accountsProvider.transferBetweenAccounts(
          transaction.toAccountId!, 
          transaction.accountId, 
          transaction.amount
        );
      }
      
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting transaction: $e');
    }
  }

  // Отримання транзакцій за типом
  List<Transaction> getTransactionsByType(TransactionType type) {
    return _transactions.where((t) => t.type == type).toList();
  }

  // Сума витрат за категоріями (для діаграми)
  Map<int, double> getExpensesByCategory() {
    final expenseTransactions = _transactions.where(
      (t) => t.type == TransactionType.expense
    ).toList();
    
    Map<int, double> result = {};
    
    for (var transaction in expenseTransactions) {
      if (result.containsKey(transaction.categoryId)) {
        result[transaction.categoryId] = result[transaction.categoryId]! + transaction.amount;
      } else {
        result[transaction.categoryId] = transaction.amount;
      }
    }
    
    return result;
  }

  // Сума доходів за категоріями (для діаграми)
  Map<int, double> getIncomesByCategory() {
    final incomeTransactions = _transactions.where(
      (t) => t.type == TransactionType.income
    ).toList();
    
    Map<int, double> result = {};
    
    for (var transaction in incomeTransactions) {
      if (result.containsKey(transaction.categoryId)) {
        result[transaction.categoryId] = result[transaction.categoryId]! + transaction.amount;
      } else {
        result[transaction.categoryId] = transaction.amount;
      }
    }
    
    return result;
  }

  // Загальна сума доходів
  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  // Загальна сума витрат
  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);
}
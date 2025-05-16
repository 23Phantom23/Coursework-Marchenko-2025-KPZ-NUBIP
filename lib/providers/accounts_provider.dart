// lib/providers/accounts_provider.dart
import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/database_service.dart';

class AccountsProvider with ChangeNotifier {
  List<Account> _accounts = [];
  bool _isLoading = false;

  List<Account> get accounts => _accounts;
  bool get isLoading => _isLoading;
  
  // Загальний баланс по всіх рахунках
  double get totalBalance => 
      _accounts.fold(0, (sum, account) => sum + account.balance);

  Future<void> loadAccounts() async {
    try {
      _isLoading = true;
      
      _accounts = await DatabaseService.instance.getAccounts();
    } catch (e) {
      print('Error loading accounts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAccount(Account account) async {
    try {
      final id = await DatabaseService.instance.insertAccount(account);
      final newAccount = Account(
        id: id,
        name: account.name,
        balance: account.balance,
        iconName: account.iconName,
        color: account.color,
      );
      
      _accounts.add(newAccount);
      notifyListeners();
    } catch (e) {
      print('Error adding account: $e');
    }
  }

  Future<void> updateAccount(Account account) async {
    try {
      await DatabaseService.instance.updateAccount(account);
      
      final index = _accounts.indexWhere((a) => a.id == account.id);
      if (index != -1) {
        _accounts[index] = account;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating account: $e');
    }
  }

  Future<void> deleteAccount(int id) async {
    try {
      await DatabaseService.instance.deleteAccount(id);
      
      _accounts.removeWhere((account) => account.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting account: $e');
    }
  }

  // Оновлення балансу рахунку після нової транзакції
  Future<void> updateAccountBalance(int accountId, double amount) async {
    final index = _accounts.indexWhere((account) => account.id == accountId);
    if (index != -1) {
      final updatedAccount = _accounts[index].copyWith(
        balance: _accounts[index].balance + amount,
      );
      
      await DatabaseService.instance.updateAccount(updatedAccount);
      _accounts[index] = updatedAccount;
      notifyListeners();
    }
  }

  // Переказ між рахунками
  Future<void> transferBetweenAccounts(
    int fromAccountId, 
    int toAccountId, 
    double amount
  ) async {
    final fromIndex = _accounts.indexWhere((a) => a.id == fromAccountId);
    final toIndex = _accounts.indexWhere((a) => a.id == toAccountId);
    
    if (fromIndex != -1 && toIndex != -1) {
      // Зменшуємо баланс "від" рахунку
      final fromAccount = _accounts[fromIndex].copyWith(
        balance: _accounts[fromIndex].balance - amount,
      );
      
      // Збільшуємо баланс "до" рахунку
      final toAccount = _accounts[toIndex].copyWith(
        balance: _accounts[toIndex].balance + amount,
      );
      
      // Оновлюємо в базі даних
      await DatabaseService.instance.updateAccount(fromAccount);
      await DatabaseService.instance.updateAccount(toAccount);
      
      // Оновлюємо локальний стан
      _accounts[fromIndex] = fromAccount;
      _accounts[toIndex] = toAccount;
      
      notifyListeners();
    }
  }
}
// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  int _startDayOfWeek = 1; // 1 = Понеділок, 7 = Неділя
  int _startDayOfMonth = 1; // День місяця
  
  bool _isLoading = true;

  bool _useCurrencySymbol = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _startDayOfWeek = prefs.getInt('startDayOfWeek') ?? 1;
      _startDayOfMonth = prefs.getInt('startDayOfMonth') ?? 1;
      _useCurrencySymbol = prefs.getBool('useCurrencySymbol') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt('startDayOfWeek', _startDayOfWeek);
      await prefs.setInt('startDayOfMonth', _startDayOfMonth);
      await prefs.setBool('useCurrencySymbol', _useCurrencySymbol);
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Налаштування збережено')),
      );
    }
  }


  Widget _buildCurrencyFormatSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Формат відображення валюти',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: Text('Символ (₴)'),
                value: true,
                groupValue: _useCurrencySymbol,
                onChanged: (value) {
                  setState(() {
                    _useCurrencySymbol = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: Text('Код (UAH)'),
                value: false,
                groupValue: _useCurrencySymbol,
                onChanged: (value) {
                  setState(() {
                    _useCurrencySymbol = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Налаштування'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Загальні налаштування',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            // Сховали налаштування тижня і місяця
                            // _buildStartDayOfWeekSetting(),
                            // SizedBox(height: 16),
                            // _buildStartDayOfMonthSetting(),
                            // SizedBox(height: 16),
                            _buildCurrencyFormatSetting(),
                            SizedBox(height: 16),
                            _buildDarkModeSetting(),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Дані',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildExportDataButton(),
                            SizedBox(height: 16),
                            _buildImportDataButton(),
                            SizedBox(height: 16),
                            _buildClearDataButton(),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Про програму',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Фінансовий трекер - це додаток для моніторингу особистих фінансів. '
                              'Версія: 1.0.0',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Розроблено в рамках курсового проєкту.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                        ),
                        onPressed: _saveSettings,
                        child: Text(
                          'Зберегти налаштування',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDarkModeSetting() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return SwitchListTile(
      title: Text(
        'Темна тема',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text('Використовувати темну тему для додатку'),
      value: themeProvider.isDarkMode,
      onChanged: (bool value) {
        themeProvider.toggleTheme();
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildExportDataButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(Icons.upload_file),
        label: Text('Експорт даних'),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          // Тут буде логіка експорту даних
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Функція експорту даних знаходиться в розробці')),
          );
        },
      ),
    );
  }

  Widget _buildImportDataButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(Icons.download),
        label: Text('Імпорт даних'),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          // Тут буде логіка імпорту даних
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Функція імпорту даних знаходиться в розробці')),
          );
        },
      ),
    );
  }

  Widget _buildClearDataButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(Icons.delete_forever, color: Colors.red),
        label: Text('Очистити всі дані', style: TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          _showClearDataConfirmationDialog();
        },
      ),
    );
  }

  void _showClearDataConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Очистити всі дані?'),
        content: Text(
          'Ви впевнені, що хочете видалити всі дані додатку? '
          'Всі рахунки, категорії та транзакції будуть видалені. '
          'Ця дія незворотна і дані неможливо буде відновити.'
        ),
        actions: [
          TextButton(
            child: Text('Скасувати'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Очистити все'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Очищаємо дані в провайдерах
      final accountsProvider = Provider.of<AccountsProvider>(context, listen: false);
      final categoriesProvider = Provider.of<CategoriesProvider>(context, listen: false);
      final transactionsProvider = Provider.of<TransactionsProvider>(context, listen: false);
      
      // Отримуємо доступ до бази даних і очищаємо таблиці
      final dbHelper = await DatabaseService.instance.database;
      await dbHelper.delete('transactions');
      await dbHelper.delete('categories');
      await dbHelper.delete('accounts');
      
      // Оновлюємо стан провайдерів
      await accountsProvider.loadAccounts();
      await categoriesProvider.loadCategories();
      await transactionsProvider.loadTransactions();
      
      // Додаємо стандартні категорії та рахунки
      await DatabaseService.instance.resetToInitialData();
      
      // Оновлюємо стан провайдерів знову
      await accountsProvider.loadAccounts();
      await categoriesProvider.loadCategories();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Всі дані успішно видалено')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка при видаленні даних: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
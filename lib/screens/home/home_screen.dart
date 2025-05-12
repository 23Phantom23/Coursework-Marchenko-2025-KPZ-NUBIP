// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../widgets/charts/expenses_pie_chart.dart';
import '../../widgets/transaction_list_item.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/account.dart';
import 'package:coursework_kpz/utils/currency_formatter.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  String _defaultCurrency = 'UAH';
  String _timeFilter = 'month'; // 'day', 'week', 'month', 'year'

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadData();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _defaultCurrency = prefs.getString('defaultCurrency') ?? 'UAH';
    });
  }

  Future<void> _loadData() async {
    final accountsProvider = Provider.of<AccountsProvider>(context, listen: false);
    final categoriesProvider = Provider.of<CategoriesProvider>(context, listen: false);
    final transactionsProvider = Provider.of<TransactionsProvider>(context, listen: false);

    await accountsProvider.loadAccounts();
    await categoriesProvider.loadCategories();
    
    // Завантажуємо транзакції за обраний період
    await _loadTransactionsByPeriod(transactionsProvider);
  }

  Future<void> _loadTransactionsByPeriod(TransactionsProvider provider) async {
    DateTime startDate;
    DateTime endDate;
    
    switch (_timeFilter) {
      case 'day':
        startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        endDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
        break;
      case 'week':
        // Знаходимо початок тижня (понеділок)
        startDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        // Кінець тижня (неділя)
        endDate = startDate.add(Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case 'year':
        startDate = DateTime(_selectedDate.year, 1, 1);
        endDate = DateTime(_selectedDate.year, 12, 31, 23, 59, 59);
        break;
      case 'month':
      default:
        startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
        endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
    }
    
    await provider.loadTransactionsByPeriod(startDate, endDate);
  }

  String _formatPeriod() {
    switch (_timeFilter) {
      case 'day':
        return DateFormat('dd MMMM yyyy').format(_selectedDate);
      case 'week':
        final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(Duration(days: 6));
        return '${DateFormat('dd.MM').format(startOfWeek)} - ${DateFormat('dd.MM').format(endOfWeek)}';
      case 'year':
        return _selectedDate.year.toString();
      case 'month':
      default:
        return DateFormat('MMMM yyyy').format(_selectedDate);
    }
  }

  void _changeTimeFilter(String filter) {
    setState(() {
      _timeFilter = filter;
    });
    
    _loadTransactionsByPeriod(
      Provider.of<TransactionsProvider>(context, listen: false)
    );
  }

  void _changePeriod(bool next) {
    setState(() {
      switch (_timeFilter) {
        case 'day':
          _selectedDate = next 
              ? _selectedDate.add(Duration(days: 1))
              : _selectedDate.subtract(Duration(days: 1));
          break;
        case 'week':
          _selectedDate = next 
              ? _selectedDate.add(Duration(days: 7))
              : _selectedDate.subtract(Duration(days: 7));
          break;
        case 'year':
          _selectedDate = DateTime(
            next ? _selectedDate.year + 1 : _selectedDate.year - 1,
            _selectedDate.month,
            _selectedDate.day,
          );
          break;
        case 'month':
        default:
          _selectedDate = DateTime(
            _selectedDate.year,
            next ? _selectedDate.month + 1 : _selectedDate.month - 1,
            _selectedDate.day,
          );
      }
    });
    
    _loadTransactionsByPeriod(
      Provider.of<TransactionsProvider>(context, listen: false)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeFilter(),
                SizedBox(height: 16),
                _buildBalanceCard(),
                SizedBox(height: 16),
                _buildExpensesChart(),
                SizedBox(height: 16),
                _buildRecentTransactions(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addTransaction),
        child: Icon(Icons.add),
        tooltip: 'Додати транзакцію',
      ),
    );
  }

  // Оновлену частину методу _buildDrawer() в lib/screens/home/home_screen.dart
Widget _buildDrawer() {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                AppConstants.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Контроль ваших фінансів',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: Icon(Icons.home),
          title: Text('Головна'),
          selected: true,
          onTap: () => Navigator.pop(context),
        ),
        ListTile(
          leading: Icon(Icons.account_balance_wallet),
          title: Text('Рахунки'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.accounts);
          },
        ),
        ListTile(
          leading: Icon(Icons.category),
          title: Text('Категорії'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.categories);
          },
        ),
        ListTile(
          leading: Icon(Icons.bar_chart),
          title: Text('Статистика'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.statistics);
          },
        ),
        ListTile(
          leading: Icon(Icons.settings),
          title: Text('Налаштування'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.settings);
          },
        ),
      ],
    ),
  );
}

  Widget _buildTimeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left),
              onPressed: () => _changePeriod(false),
            ),
            Text(
              _formatPeriod(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right),
              onPressed: () => _changePeriod(true),
            ),
          ],
        ),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('День', 'day'),
              SizedBox(width: 8),
              _filterChip('Тиждень', 'week'),
              SizedBox(width: 8),
              _filterChip('Місяць', 'month'),
              SizedBox(width: 8),
              _filterChip('Рік', 'year'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    return ActionChip(
      label: Text(label),
      backgroundColor: _timeFilter == value
          ? Theme.of(context).primaryColor.withOpacity(0.2)
          : Colors.grey.withOpacity(0.2),
      labelStyle: TextStyle(
        color: _timeFilter == value
            ? Theme.of(context).primaryColor
            : Colors.grey[700],
        fontWeight: _timeFilter == value ? FontWeight.bold : FontWeight.normal,
      ),
      onPressed: () => _changeTimeFilter(value),
    );
  }

  Widget _buildBalanceCard() {
    final accountsProvider = Provider.of<AccountsProvider>(context);
    
    return Card(
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
              'Загальний баланс',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              CurrencyFormatter.formatSync(accountsProvider.totalBalance, _defaultCurrency),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _balanceInfoItem(
                  Icons.arrow_downward,
                  Colors.green,
                  'Доходи',
                  CurrencyFormatter.formatSync(accountsProvider.totalBalance, _defaultCurrency),
                ),
                _balanceInfoItem(
                  Icons.arrow_upward,
                  Colors.red,
                  'Витрати',
                  CurrencyFormatter.formatSync(accountsProvider.totalBalance, _defaultCurrency),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceInfoItem(
    IconData icon,
    Color color,
    String title,
    String amount,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpensesChart() {
    final transactionsProvider = Provider.of<TransactionsProvider>(context);
    final categoriesProvider = Provider.of<CategoriesProvider>(context);
    final expensesByCategory = transactionsProvider.getExpensesByCategory();
    
    if (expensesByCategory.isEmpty) {
      return Card(
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
                'Витрати за категоріями',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Немає даних про витрати за цей період',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Дозволяє колонці бути мінімальної потрібної висоти
          children: [
            Text(
              'Витрати за категоріями',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Прибираємо фіксовану висоту, даємо контенту визначити розмір
            ExpensesPieChart(
              expensesByCategory: expensesByCategory,
              categories: categoriesProvider.categories,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final transactionsProvider = Provider.of<TransactionsProvider>(context);
    final categoriesProvider = Provider.of<CategoriesProvider>(context);
    final accountsProvider = Provider.of<AccountsProvider>(context);
  
    if (transactionsProvider.transactions.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Останні транзакції',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    child: Text('Всі'),
                    onPressed: () {
                      // Переходимо на екран всіх транзакцій
                      Navigator.pushNamed(context, '/transactions');
                    },
                  ),
                ],
              ),
              SizedBox(height: 16),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Немає транзакцій за цей період',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  
    // Обмежуємо кількість транзакцій до 5
    final transactions = transactionsProvider.transactions.take(5).toList();
  
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Останні транзакції',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  child: Text('Всі'),
                  onPressed: () {
                    // Переходимо на екран всіх транзакцій
                    Navigator.pushNamed(context, '/transactions');
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return TransactionListItem(
                  transaction: transaction,
                  category: categoriesProvider.getCategoryById(transaction.categoryId),
                  account: accountsProvider.accounts.firstWhere(
                    (a) => a.id == transaction.accountId,
                    orElse: () => Account(
                      name: 'Невідомий',
                      balance: 0,
                      currency: 'UAH',
                      iconName: 'help',
                      color: '#9E9E9E',
                    ),
                  ),
                  onTap: () {
                    // Редагування транзакції
                    Navigator.pushNamed(
                      context, 
                      '/add-transaction',
                      arguments: transaction,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
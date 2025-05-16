// lib/screens/transactions/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/accounts_provider.dart';
import '../../widgets/transaction_list_item.dart';
import '../../models/account.dart';
import '../../config/routes.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _timeFilter = 'month'; // 'day', 'week', 'month', 'year'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final transactionsProvider = Provider.of<TransactionsProvider>(context, listen: false);
    final categoriesProvider = Provider.of<CategoriesProvider>(context, listen: false);
    final accountsProvider = Provider.of<AccountsProvider>(context, listen: false);

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
        title: Text('Всі транзакції'),
      ),
      body: Column(
        children: [
          _buildTimeFilter(),
          Expanded(
            child: _buildTransactionsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addTransaction);
        },
        child: Icon(Icons.add),
        tooltip: 'Додати транзакцію',
      ),
    );
  }

  Widget _buildTimeFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
      ),
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

  Widget _buildTransactionsList() {
    return Consumer3<TransactionsProvider, CategoriesProvider, AccountsProvider>(
      builder: (context, transactionsProvider, categoriesProvider, accountsProvider, child) {
        if (transactionsProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (transactionsProvider.transactions.isEmpty) {
          return Center(
            child: Text('Немає транзакцій за цей період'),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: transactionsProvider.transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactionsProvider.transactions[index];
            return Card(
              margin: EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: TransactionListItem(
                transaction: transaction,
                category: categoriesProvider.getCategoryById(transaction.categoryId),
                account: accountsProvider.accounts.firstWhere(
                  (a) => a.id == transaction.accountId,
                  orElse: () => Account(
                    name: 'Невідомий',
                    balance: 0,
                    iconName: 'help',
                    color: '#9E9E9E',
                  ),
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context, 
                    AppRoutes.addTransaction,
                    arguments: transaction,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
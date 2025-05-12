// lib/screens/statistics/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/accounts_provider.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../widgets/charts/expenses_pie_chart.dart';

class StatisticsScreen extends StatefulWidget {
  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  String _timeFilter = 'month'; // 'day', 'week', 'month', 'year'
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: Text('Статистика'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Огляд'),
            Tab(text: 'Витрати'),
            Tab(text: 'Доходи'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildTimeFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildExpensesTab(),
                _buildIncomeTab(),
              ],
            ),
          ),
        ],
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

  Widget _buildOverviewTab() {
    return Consumer3<TransactionsProvider, CategoriesProvider, AccountsProvider>(
      builder: (context, transactionsProvider, categoriesProvider, accountsProvider, child) {
        if (transactionsProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(transactionsProvider),
              SizedBox(height: 16),
              _buildCashflowChart(transactionsProvider),
              SizedBox(height: 16),
              _buildTopCategoriesCard(
                transactionsProvider, 
                categoriesProvider,
                TransactionType.expense,
                'Топ витрат',
              ),
              SizedBox(height: 16),
              _buildTopCategoriesCard(
                transactionsProvider, 
                categoriesProvider,
                TransactionType.income,
                'Топ доходів',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpensesTab() {
    return Consumer2<TransactionsProvider, CategoriesProvider>(
      builder: (context, transactionsProvider, categoriesProvider, child) {
        if (transactionsProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        final expensesByCategory = transactionsProvider.getExpensesByCategory();
        
        if (expensesByCategory.isEmpty) {
          return Center(
            child: Text('Немає даних про витрати за цей період'),
          );
        }
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
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
                        'Розподіл витрат',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      AspectRatio(
                        aspectRatio: 1.3,
                        child: ExpensesPieChart(
                          expensesByCategory: expensesByCategory,
                          categories: categoriesProvider.categories,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              _buildCategoryExpensesList(
                transactionsProvider, 
                categoriesProvider,
              ),
              SizedBox(height: 16),
              _buildExpensesByDayChart(transactionsProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncomeTab() {
    return Consumer2<TransactionsProvider, CategoriesProvider>(
      builder: (context, transactionsProvider, categoriesProvider, child) {
        if (transactionsProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        final incomesByCategory = transactionsProvider.getIncomesByCategory();
        
        if (incomesByCategory.isEmpty) {
          return Center(
            child: Text('Немає даних про доходи за цей період'),
          );
        }
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPieChartCard(
                'Розподіл доходів',
                incomesByCategory,
                categoriesProvider.categories,
                Colors.green,
              ),
              SizedBox(height: 16),
              _buildCategoryIncomesList(
                transactionsProvider, 
                categoriesProvider,
              ),
              SizedBox(height: 16),
              _buildIncomesByDayChart(transactionsProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(TransactionsProvider transactionsProvider) {
    final income = transactionsProvider.totalIncome;
    final expense = transactionsProvider.totalExpense;
    final balance = income - expense;
    
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
              'Підсумок за період',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _summaryItem(
                    'Доходи',
                    income.toStringAsFixed(2),
                    Colors.green,
                    Icons.arrow_downward,
                  ),
                ),
                Expanded(
                  child: _summaryItem(
                    'Витрати',
                    expense.toStringAsFixed(2),
                    Colors.red,
                    Icons.arrow_upward,
                  ),
                ),
                Expanded(
                  child: _summaryItem(
                    'Баланс',
                    balance.toStringAsFixed(2),
                    balance >= 0 ? Colors.blue : Colors.orange,
                    balance >= 0 ? Icons.trending_up : Icons.trending_down,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String title, String amount, Color color, IconData icon) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Text(
          '$amount ₴',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCashflowChart(TransactionsProvider transactionsProvider) {
    final transactions = transactionsProvider.transactions;
    
    if (transactions.isEmpty) {
      return SizedBox();
    }
    
    // Підготовка даних для графіка
    Map<DateTime, double> incomeByDay = {};
    Map<DateTime, double> expenseByDay = {};
    
    for (var transaction in transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      
      if (transaction.type == TransactionType.income) {
        incomeByDay[date] = (incomeByDay[date] ?? 0) + transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        expenseByDay[date] = (expenseByDay[date] ?? 0) + transaction.amount;
      }
    }
    
    // Створюємо список всіх дат у періоді
    List<DateTime> allDates = [];
    
    DateTime startDate;
    DateTime endDate;
    
    switch (_timeFilter) {
      case 'day':
        startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        endDate = startDate;
        break;
      case 'week':
        startDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(Duration(days: 6));
        break;
      case 'year':
        startDate = DateTime(_selectedDate.year, 1, 1);
        endDate = DateTime(_selectedDate.year, 12, 31);
        
        // Для року додаємо по місяцях
        for (int month = 1; month <= 12; month++) {
          allDates.add(DateTime(_selectedDate.year, month, 1));
        }
        break;
      case 'month':
      default:
        startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
        endDate = DateTime(_selectedDate.year, _selectedDate.month, lastDay);
        
        // Додаємо всі дні місяця
        for (int day = 1; day <= lastDay; day++) {
          allDates.add(DateTime(_selectedDate.year, _selectedDate.month, day));
        }
    }
    
    // Якщо не рік і не місяць, то додаємо всі дні між startDate і endDate
    if (_timeFilter != 'year' && _timeFilter != 'month') {
      for (var d = startDate; d.isBefore(endDate.add(Duration(days: 1))); d = d.add(Duration(days: 1))) {
        allDates.add(DateTime(d.year, d.month, d.day));
      }
    }
    
    // Заповнюємо нулями дні, коли не було транзакцій
    for (var date in allDates) {
      incomeByDay.putIfAbsent(date, () => 0);
      expenseByDay.putIfAbsent(date, () => 0);
    }
    
    // Сортуємо дати
    List<DateTime> sortedDates = incomeByDay.keys.toList()..sort();
    
    // Форматування дат для відображення
    String formatChartDate(DateTime date) {
      if (_timeFilter == 'year') {
        return DateFormat('MMM').format(date); // Скорочена назва місяця
      } else {
        return DateFormat('d').format(date); // День
      }
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
          children: [
            Text(
              'Рух коштів',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxValue(incomeByDay, expenseByDay) * 1.2,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(color: Colors.grey[600], fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                            final date = sortedDates[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                formatChartDate(date),
                                style: TextStyle(color: Colors.grey[600], fontSize: 10),
                              ),
                            );
                          }
                          return SizedBox();
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: List.generate(sortedDates.length, (index) {
                    final date = sortedDates[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: incomeByDay[date] ?? 0,
                          color: Colors.green,
                          width: 12,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: expenseByDay[date] ?? 0,
                          color: Colors.red,
                          width: 12,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem('Доходи', Colors.green),
                SizedBox(width: 24),
                _legendItem('Витрати', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxValue(Map<DateTime, double> map1, Map<DateTime, double> map2) {
    double max1 = map1.values.isEmpty ? 0 : map1.values.reduce((a, b) => a > b ? a : b);
    double max2 = map2.values.isEmpty ? 0 : map2.values.reduce((a, b) => a > b ? a : b);
    return max1 > max2 ? max1 : max2;
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTopCategoriesCard(
    TransactionsProvider transactionsProvider,
    CategoriesProvider categoriesProvider,
    TransactionType transactionType,
    String title,
  ) {
    Map<int, double> amountsByCategory;
    
    if (transactionType == TransactionType.expense) {
      amountsByCategory = transactionsProvider.getExpensesByCategory();
    } else {
      amountsByCategory = transactionsProvider.getIncomesByCategory();
    }
    
    if (amountsByCategory.isEmpty) {
      return SizedBox();
    }
    
    // Сортуємо категорії за сумою
    List<MapEntry<int, double>> sortedEntries = amountsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Обмежуємо до 5 найбільших категорій
    if (sortedEntries.length > 5) {
      sortedEntries = sortedEntries.sublist(0, 5);
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
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Column(
              children: sortedEntries.map((entry) {
                final categoryId = entry.key;
                final amount = entry.value;
                
                final category = categoriesProvider.getCategoryById(categoryId);
                
                if (category == null) {
                  return SizedBox();
                }
                
                // Перетворюємо колір з HEX формату в Color
                Color color;
                try {
                  color = Color(int.parse(category.color.replaceAll('#', '0xFF')));
                } catch (e) {
                  color = Colors.grey;
                }
                
                // Обчислюємо відсоток від загальної суми
                final total = amountsByCategory.values.fold(0.0, (sum, val) => sum + val);
                final percentage = (amount / total * 100).toStringAsFixed(1);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withOpacity(0.2),
                        radius: 16,
                        child: Icon(
                          _getIconData(category.iconName),
                          color: color,
                          size: 16,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: amount / total,
                              backgroundColor: Colors.grey.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${amount.toStringAsFixed(2)} ₴',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard(
    String title,
    Map<int, double> amountsByCategory,
    List<Category> categories,
    Color defaultColor,
  ) {
    if (amountsByCategory.isEmpty) {
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
                title,
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
                    'Немає даних для відображення',
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
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.3,
              child: PieChart(
                PieChartData(
                  sections: _createPieSections(amountsByCategory, categories, defaultColor),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  startDegreeOffset: -90,
                ),
              ),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: _createLegendItems(amountsByCategory, categories, defaultColor),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _createPieSections(
    Map<int, double> amountsByCategory,
    List<Category> categories,
    Color defaultColor,
  ) {
    final totalAmount = amountsByCategory.values.fold(0.0, (sum, amount) => sum + amount);
    
    return amountsByCategory.entries.map((entry) {
      final categoryId = entry.key;
      final amount = entry.value;
      final percentage = amount / totalAmount;

      // Знаходимо категорію за її ID
      final category = categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => Category(
          name: 'Невідома',
          type: CategoryType.expense,
          iconName: 'help',
          color: '#9E9E9E',
        ),
      );

      // Перетворюємо колір з HEX формату в Color
      Color color;
      try {
        color = Color(int.parse(category.color.replaceAll('#', '0xFF')));
      } catch (e) {
        color = defaultColor;
      }

      return PieChartSectionData(
        value: amount,
        title: '${(percentage * 100).toStringAsFixed(1)}%',
        radius: 90,
        color: color,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _createLegendItems(
    Map<int, double> amountsByCategory,
    List<Category> categories,
    Color defaultColor,
  ) {
    final totalAmount = amountsByCategory.values.fold(0.0, (sum, amount) => sum + amount);
    
    return amountsByCategory.entries.map((entry) {
      final categoryId = entry.key;
      final amount = entry.value;
      final percentage = (amount / totalAmount * 100).toStringAsFixed(1);

      // Знаходимо категорію за її ID
      final category = categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => Category(
          name: 'Невідома',
          type: CategoryType.expense,
          iconName: 'help',
          color: '#9E9E9E',
        ),
      );

      // Перетворюємо колір з HEX формату в Color
      Color color;
      try {
        color = Color(int.parse(category.color.replaceAll('#', '0xFF')));
      } catch (e) {
        color = defaultColor;
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              '${category.name} (${percentage}%)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildCategoryExpensesList(
    TransactionsProvider transactionsProvider,
    CategoriesProvider categoriesProvider,
  ) {
    final expensesByCategory = transactionsProvider.getExpensesByCategory();
    
    if (expensesByCategory.isEmpty) {
      return SizedBox();
    }
    
    // Сортуємо категорії за сумою
    List<MapEntry<int, double>> sortedEntries = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
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
            Column(
              children: sortedEntries.map((entry) {
                final categoryId = entry.key;
                final amount = entry.value;
                
                final category = categoriesProvider.getCategoryById(categoryId);
                
                if (category == null) {
                  return SizedBox();
                }
                
                // Перетворюємо колір з HEX формату в Color
                Color color;
                try {
                  color = Color(int.parse(category.color.replaceAll('#', '0xFF')));
                } catch (e) {
                  color = Colors.grey;
                }
                
                // Обчислюємо відсоток від загальної суми
                final total = expensesByCategory.values.fold(0.0, (sum, val) => sum + val);
                final percentage = (amount / total * 100).toStringAsFixed(1);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withOpacity(0.2),
                        radius: 16,
                        child: Icon(
                          _getIconData(category.iconName),
                          color: color,
                          size: 16,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: amount / total,
                              backgroundColor: Colors.grey.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${amount.toStringAsFixed(2)} ₴',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIncomesList(
    TransactionsProvider transactionsProvider,
    CategoriesProvider categoriesProvider,
  ) {
    final incomesByCategory = transactionsProvider.getIncomesByCategory();
    
    if (incomesByCategory.isEmpty) {
      return SizedBox();
    }
    
    // Сортуємо категорії за сумою
    List<MapEntry<int, double>> sortedEntries = incomesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
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
              'Доходи за категоріями',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Column(
              children: sortedEntries.map((entry) {
                final categoryId = entry.key;
                final amount = entry.value;
                
                final category = categoriesProvider.getCategoryById(categoryId);
                
                if (category == null) {
                  return SizedBox();
                }
                
                // Перетворюємо колір з HEX формату в Color
                Color color;
                try {
                  color = Color(int.parse(category.color.replaceAll('#', '0xFF')));
                } catch (e) {
                  color = Colors.grey;
                }
                
                // Обчислюємо відсоток від загальної суми
                final total = incomesByCategory.values.fold(0.0, (sum, val) => sum + val);
                final percentage = (amount / total * 100).toStringAsFixed(1);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: color.withOpacity(0.2),
                        radius: 16,
                        child: Icon(
                          _getIconData(category.iconName),
                          color: color,
                          size: 16,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: amount / total,
                              backgroundColor: Colors.grey.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${amount.toStringAsFixed(2)} ₴',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesByDayChart(TransactionsProvider transactionsProvider) {
    final transactions = transactionsProvider.transactions.where(
      (t) => t.type == TransactionType.expense
    ).toList();
    
    if (transactions.isEmpty) {
      return SizedBox();
    }
    
    // Групуємо витрати по днях
    Map<DateTime, double> expensesByDay = {};
    
    for (var transaction in transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      
      expensesByDay[date] = (expensesByDay[date] ?? 0) + transaction.amount;
    }
    
    // Створюємо список всіх дат у періоді
    List<DateTime> allDates = [];
    
    DateTime startDate;
    DateTime endDate;
    
    switch (_timeFilter) {
      case 'day':
        startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        endDate = startDate;
        break;
      case 'week':
        startDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(Duration(days: 6));
        break;
      case 'year':
        startDate = DateTime(_selectedDate.year, 1, 1);
        endDate = DateTime(_selectedDate.year, 12, 31);
        
        // Для року додаємо по місяцях
        for (int month = 1; month <= 12; month++) {
          allDates.add(DateTime(_selectedDate.year, month, 1));
        }
        break;
      case 'month':
      default:
        startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
        endDate = DateTime(_selectedDate.year, _selectedDate.month, lastDay);
        
        // Додаємо всі дні місяця
        for (int day = 1; day <= lastDay; day++) {
          allDates.add(DateTime(_selectedDate.year, _selectedDate.month, day));
        }
    }
    
    // Якщо не рік і не місяць, то додаємо всі дні між startDate і endDate
    if (_timeFilter != 'year' && _timeFilter != 'month' && allDates.isEmpty) {
      for (var d = startDate; d.isBefore(endDate.add(Duration(days: 1))); d = d.add(Duration(days: 1))) {
        allDates.add(DateTime(d.year, d.month, d.day));
      }
    }
    
    // Заповнюємо нулями дні, коли не було витрат
    for (var date in allDates) {
      expensesByDay.putIfAbsent(date, () => 0);
    }
    
    // Сортуємо дати
    List<DateTime> sortedDates = expensesByDay.keys.toList()..sort();
    
    // Форматування дат для відображення
    String formatChartDate(DateTime date) {
      if (_timeFilter == 'year') {
        return DateFormat('MMM').format(date); // Скорочена назва місяця
      } else {
        return DateFormat('d').format(date); // День
      }
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
          children: [
            Text(
              'Витрати по днях',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: expensesByDay.values.isEmpty
                      ? 100
                      : expensesByDay.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(color: Colors.grey[600], fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                            final date = sortedDates[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                formatChartDate(date),
                                style: TextStyle(color: Colors.grey[600], fontSize: 10),
                              ),
                            );
                          }
                          return SizedBox();
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: List.generate(sortedDates.length, (index) {
                    final date = sortedDates[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: expensesByDay[date] ?? 0,
                          color: Colors.red,
                          width: 12,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomesByDayChart(TransactionsProvider transactionsProvider) {
    final transactions = transactionsProvider.transactions.where(
      (t) => t.type == TransactionType.income
    ).toList();
    
    if (transactions.isEmpty) {
      return SizedBox();
    }
    
    // Групуємо доходи по днях
    Map<DateTime, double> incomesByDay = {};
    
    for (var transaction in transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      
      incomesByDay[date] = (incomesByDay[date] ?? 0) + transaction.amount;
    }
    
    // Створюємо список всіх дат у періоді
    List<DateTime> allDates = [];
    
    DateTime startDate;
    DateTime endDate;
    
    switch (_timeFilter) {
      case 'day':
        startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        endDate = startDate;
        break;
      case 'week':
        startDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(Duration(days: 6));
        break;
      case 'year':
        startDate = DateTime(_selectedDate.year, 1, 1);
        endDate = DateTime(_selectedDate.year, 12, 31);
        
        // Для року додаємо по місяцях
        for (int month = 1; month <= 12; month++) {
          allDates.add(DateTime(_selectedDate.year, month, 1));
        }
        break;
      case 'month':
      default:
        startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
        endDate = DateTime(_selectedDate.year, _selectedDate.month, lastDay);
        
        // Додаємо всі дні місяця
        for (int day = 1; day <= lastDay; day++) {
          allDates.add(DateTime(_selectedDate.year, _selectedDate.month, day));
        }
    }
    
    // Якщо не рік і не місяць, то додаємо всі дні між startDate і endDate
    if (_timeFilter != 'year' && _timeFilter != 'month' && allDates.isEmpty) {
      for (var d = startDate; d.isBefore(endDate.add(Duration(days: 1))); d = d.add(Duration(days: 1))) {
        allDates.add(DateTime(d.year, d.month, d.day));
      }
    }
    
    // Заповнюємо нулями дні, коли не було доходів
    for (var date in allDates) {
      incomesByDay.putIfAbsent(date, () => 0);
    }
    
    // Сортуємо дати
    List<DateTime> sortedDates = incomesByDay.keys.toList()..sort();
    
    // Форматування дат для відображення
    String formatChartDate(DateTime date) {
      if (_timeFilter == 'year') {
        return DateFormat('MMM').format(date); // Скорочена назва місяця
      } else {
        return DateFormat('d').format(date); // День
      }
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
          children: [
            Text(
              'Доходи по днях',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: incomesByDay.values.isEmpty
                      ? 100
                      : incomesByDay.values.reduce((a, b) => a > b ? a : b) * 1.2,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(color: Colors.grey[600], fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < sortedDates.length) {
                            final date = sortedDates[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                formatChartDate(date),
                                style: TextStyle(color: Colors.grey[600], fontSize: 10),
                              ),
                            );
                          }
                          return SizedBox();
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: List.generate(sortedDates.length, (index) {
                    final date = sortedDates[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: incomesByDay[date] ?? 0,
                          color: Colors.green,
                          width: 12,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'home':
        return Icons.home;
      case 'medical_services':
        return Icons.medical_services;
      case 'sports':
        return Icons.sports;
      case 'school':
        return Icons.school;
      case 'movie':
        return Icons.movie;
      case 'travel_explore':
        return Icons.travel_explore;
      case 'credit_card':
        return Icons.credit_card;
      case 'account_balance':
        return Icons.account_balance;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'attach_money':
        return Icons.attach_money;
      case 'savings':
        return Icons.savings;
      case 'money':
        return Icons.money;
      case 'currency_exchange':
        return Icons.currency_exchange;
      case 'payments':
        return Icons.payments;
      case 'euro':
        return Icons.euro;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'sell':
        return Icons.sell;
      case 'work':
        return Icons.work;
      case 'check_circle':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }
}
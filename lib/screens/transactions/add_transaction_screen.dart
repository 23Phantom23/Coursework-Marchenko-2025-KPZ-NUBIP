// lib/screens/transactions/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../models/transaction.dart';
import '../../models/category.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction; // Якщо null, створюємо нову транзакцію

  const AddTransactionScreen({Key? key, this.transaction}) : super(key: key);

  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  TransactionType _transactionType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;
  int? _selectedAccountId;
  int? _selectedToAccountId;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Якщо ми редагуємо існуючу транзакцію
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.toString();
      _noteController.text = widget.transaction!.note ?? '';
      _transactionType = widget.transaction!.type;
      _selectedDate = widget.transaction!.date;
      _selectedCategoryId = widget.transaction!.categoryId;
      _selectedAccountId = widget.transaction!.accountId;
      _selectedToAccountId = widget.transaction!.toAccountId;
    }
    
    // Завантажуємо дані для обрання категорій та рахунків
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountsProvider = Provider.of<AccountsProvider>(context, listen: false);
      final categoriesProvider = Provider.of<CategoriesProvider>(context, listen: false);
      
      if (accountsProvider.accounts.isEmpty) {
        accountsProvider.loadAccounts();
      }
      
      if (categoriesProvider.categories.isEmpty) {
        categoriesProvider.loadCategories();
      }
      
      // Встановлюємо початкові значення, якщо не редагування
      if (widget.transaction == null) {
        if (accountsProvider.accounts.isNotEmpty && _selectedAccountId == null) {
          setState(() {
            _selectedAccountId = accountsProvider.accounts.first.id;
          });
        }
        
        // Для переказу встановлюємо другий рахунок, якщо є
        if (_transactionType == TransactionType.transfer && 
            accountsProvider.accounts.length > 1 && 
            _selectedToAccountId == null) {
          setState(() {
            _selectedToAccountId = accountsProvider.accounts[1].id;
          });
        }
        
        // Встановлюємо початкову категорію відповідно до типу транзакції
        if (categoriesProvider.categories.isNotEmpty && _selectedCategoryId == null) {
          final categoryType = _transactionType == TransactionType.income 
              ? CategoryType.income 
              : CategoryType.expense;
          
          final filteredCategories = categoriesProvider.getCategoriesByType(categoryType);
          if (filteredCategories.isNotEmpty) {
            setState(() {
              _selectedCategoryId = filteredCategories.first.id;
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      // Перевіряємо, чи вибрані всі необхідні дані
      if (_selectedAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Будь ласка, виберіть рахунок')),
        );
        return;
      }
      
      if (_transactionType != TransactionType.transfer && _selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Будь ласка, виберіть категорію')),
        );
        return;
      }
      
      if (_transactionType == TransactionType.transfer && _selectedToAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Будь ласка, виберіть рахунок призначення')),
        );
        return;
      }
      
      // Перевіряємо, чи не вибрано однаковий рахунок для переказу
      if (_transactionType == TransactionType.transfer && 
          _selectedAccountId == _selectedToAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не можна переказувати на той самий рахунок')),
        );
        return;
      }
      
      final double amount = double.parse(_amountController.text);
      
      // Створюємо об'єкт транзакції
      final transaction = Transaction(
        id: widget.transaction?.id,
        title: _titleController.text,
        amount: amount,
        date: _selectedDate,
        categoryId: _transactionType == TransactionType.transfer ? 0 : _selectedCategoryId!,
        accountId: _selectedAccountId!,
        toAccountId: _transactionType == TransactionType.transfer ? _selectedToAccountId : null,
        type: _transactionType,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );
      
      final transactionsProvider = Provider.of<TransactionsProvider>(context, listen: false);
      final accountsProvider = Provider.of<AccountsProvider>(context, listen: false);
      
      // Зберігаємо транзакцію
      if (widget.transaction == null) {
        transactionsProvider.addTransaction(transaction, accountsProvider)
          .then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Транзакцію додано')),
            );
            Navigator.pop(context);
          });
      } else {
        transactionsProvider.updateTransaction(transaction, accountsProvider)
          .then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Транзакцію оновлено')),
            );
            Navigator.pop(context);
          });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsProvider = Provider.of<AccountsProvider>(context);
    final categoriesProvider = Provider.of<CategoriesProvider>(context);
    
    final isEditing = widget.transaction != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редагувати транзакцію' : 'Нова транзакція'),
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _showDeleteConfirmationDialog();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTransactionTypeSelector(),
                SizedBox(height: 16),
                if (_transactionType != TransactionType.transfer)
                  _buildCategorySelector(categoriesProvider),
                SizedBox(height: 16),
                _buildAccountSelector(accountsProvider),
                SizedBox(height: 16),
                if (_transactionType == TransactionType.transfer)
                  _buildToAccountSelector(accountsProvider),
                if (_transactionType == TransactionType.transfer)
                  SizedBox(height: 16),
                _buildDatePicker(),
                SizedBox(height: 16),
                _buildAmountField(),
                SizedBox(height: 16),
                _buildTitleField(),
                SizedBox(height: 16),
                _buildNoteField(),
                SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: _saveTransaction,
                    child: Text(
                      isEditing ? 'Оновити' : 'Зберегти',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Тип транзакції',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        SegmentedButton<TransactionType>(
          segments: const <ButtonSegment<TransactionType>>[
            ButtonSegment<TransactionType>(
              value: TransactionType.expense,
              label: Text('Витрата'),
              icon: Icon(Icons.arrow_upward),
            ),
            ButtonSegment<TransactionType>(
              value: TransactionType.income,
              label: Text('Дохід'),
              icon: Icon(Icons.arrow_downward),
            ),
            ButtonSegment<TransactionType>(
              value: TransactionType.transfer,
              label: Text('Переказ'),
              icon: Icon(Icons.swap_horiz),
            ),
          ],
          selected: <TransactionType>{_transactionType},
          onSelectionChanged: (Set<TransactionType> newSelection) {
            setState(() {
              _transactionType = newSelection.first;
              // Скидаємо категорію при зміні типу транзакції
              _selectedCategoryId = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCategorySelector(CategoriesProvider categoriesProvider) {
    // Фільтруємо категорії за типом (дохід/витрата)
    final categoryType = _transactionType == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    
    final categories = categoriesProvider.getCategoriesByType(categoryType);
    
    if (categories.isEmpty) {
      return Center(
        child: Text('Немає доступних категорій'),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Категорія',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedCategoryId,
                isExpanded: true,
                hint: Text('Виберіть категорію'),
                items: categories.map((category) {
                  IconData iconData = _getIconData(category.iconName);
                  Color color;
                  try {
                    color = Color(int.parse(category.color.replaceAll('#', '0xFF')));
                  } catch (e) {
                    color = Colors.grey;
                  }
                  
                  return DropdownMenuItem<int>(
                    value: category.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          radius: 14,
                          child: Icon(iconData, color: color, size: 16),
                        ),
                        SizedBox(width: 12),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (int? value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSelector(AccountsProvider accountsProvider) {
    final accounts = accountsProvider.accounts;
    
    if (accounts.isEmpty) {
      return Center(
        child: Text('Немає доступних рахунків'),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _transactionType == TransactionType.transfer ? 'З рахунку' : 'Рахунок',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedAccountId,
                isExpanded: true,
                hint: Text('Виберіть рахунок'),
                items: accounts.map((account) {
                  IconData iconData = _getIconData(account.iconName);
                  Color color;
                  try {
                    color = Color(int.parse(account.color.replaceAll('#', '0xFF')));
                  } catch (e) {
                    color = Colors.grey;
                  }
                  
                  return DropdownMenuItem<int>(
                    value: account.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          radius: 14,
                          child: Icon(iconData, color: color, size: 16),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(account.name, overflow: TextOverflow.ellipsis),
                        ),
                        Text(
                          '${account.balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (int? value) {
                  setState(() {
                    _selectedAccountId = value;
                    
                    // Якщо вибраний рахунок співпадає з рахунком призначення, то скидаємо рахунок призначення
                    if (_transactionType == TransactionType.transfer && 
                        _selectedAccountId == _selectedToAccountId) {
                      _selectedToAccountId = null;
                    }
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToAccountSelector(AccountsProvider accountsProvider) {
    final accounts = accountsProvider.accounts.where(
      (account) => account.id != _selectedAccountId
    ).toList();
    
    if (accounts.isEmpty) {
      return Center(
        child: Text('Немає доступних рахунків для переказу'),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'На рахунок',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedToAccountId,
                isExpanded: true,
                hint: Text('Виберіть рахунок призначення'),
                items: accounts.map((account) {
                  IconData iconData = _getIconData(account.iconName);
                  Color color;
                  try {
                    color = Color(int.parse(account.color.replaceAll('#', '0xFF')));
                  } catch (e) {
                    color = Colors.grey;
                  }
                  
                  return DropdownMenuItem<int>(
                    value: account.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          radius: 14,
                          child: Icon(iconData, color: color, size: 16),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(account.name, overflow: TextOverflow.ellipsis),
                        ),
                        Text(
                          '${account.balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (int? value) {
                  setState(() {
                    _selectedToAccountId = value;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Дата',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                SizedBox(width: 12),
                Text(
                  DateFormat('dd.MM.yyyy').format(_selectedDate),
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Сума',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.attach_money),
            hintText: '0.00',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Будь ласка, введіть суму';
            }
            
            try {
              final amount = double.parse(value);
              if (amount <= 0) {
                return 'Сума повинна бути більше нуля';
              }
            } catch (e) {
              return 'Неправильний формат числа';
            }
            
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Назва',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.description),
            hintText: _transactionType == TransactionType.expense
                ? 'Наприклад: Продукти в супермаркеті'
                : _transactionType == TransactionType.income
                    ? 'Наприклад: Зарплата'
                    : 'Наприклад: Переказ на картку',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Будь ласка, введіть назву';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Примітка (необов\'язково)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _noteController,
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            hintText: 'Додаткова інформація...',
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Видалити транзакцію?'),
        content: Text('Ви впевнені, що хочете видалити цю транзакцію? Цю дію неможливо скасувати.'),
        actions: [
          TextButton(
            child: Text('Скасувати'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Видалити'),
            onPressed: () {
              Navigator.pop(context);
              
              final transactionsProvider = Provider.of<TransactionsProvider>(context, listen: false);
              final accountsProvider = Provider.of<AccountsProvider>(context, listen: false);
              
              transactionsProvider.deleteTransaction(widget.transaction!.id!, accountsProvider)
                .then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Транзакцію видалено')),
                  );
                  Navigator.pop(context);
                });
            },
          ),
        ],
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
// lib/screens/accounts/add_account_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/accounts_provider.dart';
import '../../models/account.dart';
import '../../config/constants.dart';

class AddAccountScreen extends StatefulWidget {
  final Account? account; // Якщо null, створюємо новий рахунок

  const AddAccountScreen({Key? key, this.account}) : super(key: key);

  @override
  _AddAccountScreenState createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  
  String _selectedCurrency = 'UAH';
  String _selectedIconName = 'credit_card';
  String _selectedColor = '#4CAF50';
  
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    
    // Перевіряємо, чи редагуємо існуючий рахунок
    if (widget.account != null) {
      _isEditing = true;
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.balance.toString();
      _selectedCurrency = widget.account!.currency;
      _selectedIconName = widget.account!.iconName;
      _selectedColor = widget.account!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _saveAccount() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final balance = double.parse(_balanceController.text);
      
      final account = Account(
        id: widget.account?.id,
        name: name,
        balance: balance,
        currency: _selectedCurrency,
        iconName: _selectedIconName,
        color: _selectedColor,
      );
      
      final accountsProvider = Provider.of<AccountsProvider>(context, listen: false);
      
      if (_isEditing) {
        accountsProvider.updateAccount(account).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Рахунок оновлено')),
          );
          Navigator.pop(context);
        });
      } else {
        accountsProvider.addAccount(account).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Рахунок додано')),
          );
          Navigator.pop(context);
        });
      }
    }
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Видалити рахунок?'),
        content: Text(
          'Ви впевнені, що хочете видалити цей рахунок? ' +
          'Усі транзакції, пов\'язані з цим рахунком, також будуть видалені. ' +
          'Цю дію неможливо скасувати.'
        ),
        actions: [
          TextButton(
            child: Text('Скасувати'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Видалити'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              
              final accountsProvider = Provider.of<AccountsProvider>(context, listen: false);
              accountsProvider.deleteAccount(widget.account!.id!).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Рахунок видалено')),
                );
                Navigator.pop(context);
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редагувати рахунок' : 'Новий рахунок'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteAccount,
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
                _buildNameField(),
                SizedBox(height: 16),
                _buildBalanceField(),
                SizedBox(height: 16),
                _buildCurrencySelector(),
                SizedBox(height: 16),
                _buildIconSelector(),
                SizedBox(height: 16),
                _buildColorSelector(),
                SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: _saveAccount,
                    child: Text(
                      _isEditing ? 'Оновити' : 'Створити',
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

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Назва рахунку',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            hintText: 'Наприклад: Основна картка',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Будь ласка, введіть назву рахунку';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBalanceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Поточний баланс',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _balanceController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.account_balance_wallet),
            hintText: '0.00',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Будь ласка, введіть баланс';
            }
            
            try {
              double.parse(value);
            } catch (e) {
              return 'Неправильний формат числа';
            }
            
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCurrencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Валюта',
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
              child: DropdownButton<String>(
                value: _selectedCurrency,
                isExpanded: true,
                items: AppConstants.currencies.map((currency) {
                  return DropdownMenuItem<String>(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedCurrency = value!;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Іконка',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 70,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: AppConstants.accountIcons.map((iconData) {
              final iconName = _getIconName(iconData);
              final isSelected = _selectedIconName == iconName;
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedIconName = iconName;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: 12),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                        : null,
                  ),
                  child: Icon(
                    iconData,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Колір',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: AppConstants.categoryColors.map((color) {
              final colorHex = '#${color.value.toRadixString(16).substring(2)}';
              final isSelected = _selectedColor == colorHex;
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedColor = colorHex;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: 12),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getIconName(IconData iconData) {
    if (iconData == Icons.credit_card) return 'credit_card';
    if (iconData == Icons.account_balance) return 'account_balance';
    if (iconData == Icons.account_balance_wallet) return 'account_balance_wallet';
    if (iconData == Icons.savings) return 'savings';
    if (iconData == Icons.money) return 'money';
    if (iconData == Icons.currency_exchange) return 'currency_exchange';
    if (iconData == Icons.payments) return 'payments';
    if (iconData == Icons.euro) return 'euro';
    if (iconData == Icons.attach_money) return 'attach_money';
    return 'credit_card';
  }
}
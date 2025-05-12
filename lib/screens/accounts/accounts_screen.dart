// lib/screens/accounts/accounts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/accounts_provider.dart';
import '../../config/routes.dart';
import '../../models/account.dart';

class AccountsScreen extends StatefulWidget {
  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountsProvider>(context, listen: false).loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мої рахунки'),
      ),
      body: Consumer<AccountsProvider>(
        builder: (context, accountsProvider, child) {
          if (accountsProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (accountsProvider.accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'У вас ще немає рахунків',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Додати рахунок'),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.addAccount);
                    },
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: accountsProvider.accounts.length,
            itemBuilder: (context, index) {
              final account = accountsProvider.accounts[index];
              return _buildAccountCard(account);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addAccount);
        },
        child: Icon(Icons.add),
        tooltip: 'Додати рахунок',
      ),
    );
  }

  // lib/screens/accounts/accounts_screen.dart
// Змінити _buildAccountCard метод:

  Widget _buildAccountCard(Account account) {
    Color color;
    try {
      color = Color(int.parse(account.color.replaceAll('#', '0xFF')));
    } catch (e) {
      color = Colors.blue;
    }
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Передаємо аргумент account
          Navigator.pushNamed(
            context, 
            AppRoutes.addAccount,
            arguments: account,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(_getIconData(account.iconName), color: color),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Валюта: ${account.currency}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Баланс',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${account.balance.toStringAsFixed(2)} ${account.currency}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: account.balance >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'credit_card':
        return Icons.credit_card;
      case 'account_balance':
        return Icons.account_balance;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
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
      case 'attach_money':
        return Icons.attach_money;
      default:
        return Icons.credit_card;
    }
  }
}
// lib/widgets/transaction_list_item.dart
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/account.dart';
import 'package:intl/intl.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final Category? category;
  final Account account;
  final Account? toAccount;
  final VoidCallback? onTap;

  const TransactionListItem({
    Key? key,
    required this.transaction,
    required this.category,
    required this.account,
    this.toAccount,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      leading: _buildCategoryIcon(),
      title: Text(
        transaction.title,
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _getSubtitle(),
        style: TextStyle(fontSize: 12),
      ),
      trailing: _buildAmountText(),
    );
  }

  Widget _buildCategoryIcon() {
    IconData iconData = Icons.help;
    Color backgroundColor = Colors.grey;
    
    if (category != null) {
      iconData = _getIconData(category!.iconName);
      
      try {
        backgroundColor = Color(int.parse(category!.color.replaceAll('#', '0xFF')));
      } catch (e) {
        backgroundColor = Colors.grey;
      }
    } else if (transaction.type == TransactionType.transfer) {
      iconData = Icons.swap_horiz;
      backgroundColor = Colors.blue;
    }
    
    return CircleAvatar(
      backgroundColor: backgroundColor.withOpacity(0.2),
      child: Icon(
        iconData,
        color: backgroundColor,
        size: 20,
      ),
    );
  }

  String _getSubtitle() {
    final dateFormat = DateFormat('dd.MM.yyyy');
    String date = dateFormat.format(transaction.date);
    
    if (transaction.type == TransactionType.transfer && toAccount != null) {
      return '$date · ${account.name} → ${toAccount!.name}';
    }
    
    return '$date · ${account.name}';
  }

  Widget _buildAmountText() {
    String prefix = '';
    Color color;
    
    switch (transaction.type) {
      case TransactionType.income:
        prefix = '+ ';
        color = Colors.green;
        break;
      case TransactionType.expense:
        prefix = '- ';
        color = Colors.red;
        break;
      case TransactionType.transfer:
        color = Colors.blue;
        break;
    }
    
    return Text(
      '$prefix${transaction.amount.toStringAsFixed(2)}',
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 16,
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
      case 'attach_money':
        return Icons.attach_money;
      case 'savings':
        return Icons.savings;
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
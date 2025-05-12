// lib/widgets/charts/expenses_pie_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/category.dart';

class ExpensesPieChart extends StatelessWidget {
  final Map<int, double> expensesByCategory;
  final List<Category> categories;

  const ExpensesPieChart({
    Key? key,
    required this.expensesByCategory,
    required this.categories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (expensesByCategory.isEmpty) {
      return Center(
        child: Text('Немає даних про витрати'),
      );
    }

    final totalExpenses = expensesByCategory.values.fold(0.0, (sum, amount) => sum + amount);
    
    // Колір тексту, який відповідає поточній темі
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87;
    
    // Використовуємо LayoutBuilder для адаптивного розміру
    return LayoutBuilder(
      builder: (context, constraints) {
        // Визначаємо оптимальний розмір діаграми на основі доступного простору
        final chartSize = constraints.maxWidth * 0.8;
        final chartHeight = chartSize.clamp(150.0, 250.0); // Мінімум 150, максимум 250
        
        return Column(
          mainAxisSize: MainAxisSize.min, // Важливо для правильного розміщення
          children: [
            SizedBox(height: 16),
            SizedBox(
              height: chartHeight,
              child: PieChart(
                PieChartData(
                  sections: _createSections(context),
                  sectionsSpace: 2,
                  centerSpaceRadius: chartHeight / 5, // Адаптивний розмір центрального простору
                  startDegreeOffset: -90,
                ),
              ),
            ),
            SizedBox(height: 16),
            // Використовуємо Wrap для автоматичного переносу легенди на нові рядки
            Wrap(
              spacing: 16, // відступ між елементами по горизонталі
              runSpacing: 8, // відступ між рядками
              alignment: WrapAlignment.center,
              children: _createLegendItems(context, totalExpenses, textColor),
            ),
            SizedBox(height: 8),
          ],
        );
      },
    );
  }

  List<PieChartSectionData> _createSections(BuildContext context) {
    return expensesByCategory.entries.map((entry) {
      final categoryId = entry.key;
      final amount = entry.value;

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
        color = Colors.grey;
      }

      return PieChartSectionData(
        value: amount,
        title: '',
        radius: 80,
        color: color,
        titleStyle: TextStyle(
          fontSize: 0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: _PieChartBadge(
          iconName: category.iconName,
          color: color,
        ),
        badgePositionPercentageOffset: 0.9,
      );
    }).toList();
  }

  List<Widget> _createLegendItems(BuildContext context, double totalExpenses, Color textColor) {
    return expensesByCategory.entries.map((entry) {
      final categoryId = entry.key;
      final amount = entry.value;
      final percentage = (amount / totalExpenses * 100).toStringAsFixed(1);

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
        color = Colors.grey;
      }

      // Використовуємо Container з фіксованою шириною для легенди
      return Container(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        constraints: BoxConstraints(maxWidth: 150), // Обмежуємо ширину для кращого розташування
        child: Row(
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
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _PieChartBadge extends StatelessWidget {
  final String iconName;
  final Color color;

  const _PieChartBadge({
    required this.iconName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Використовуємо cardColor з теми
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          _getIconData(iconName),
          color: color,
          size: 14,
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
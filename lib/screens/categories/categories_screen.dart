// lib/screens/categories/categories_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/categories_provider.dart';
import '../../models/category.dart';
import '../../config/constants.dart';

class CategoriesScreen extends StatefulWidget {
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categoriesProvider = Provider.of<CategoriesProvider>(context, listen: false);
    await categoriesProvider.loadCategories();
  }

  void _showAddCategoryDialog(CategoryType type) {
    // Використовуємо showDialog з barrierDismissible: true
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: AddCategoryDialog(type: type),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Категорії'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Витрати'),
            Tab(text: 'Доходи'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriesList(CategoryType.expense),
          _buildCategoriesList(CategoryType.income),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final type = _tabController.index == 0 ? CategoryType.expense : CategoryType.income;
          _showAddCategoryDialog(type);
        },
        child: Icon(Icons.add),
        tooltip: 'Додати категорію',
      ),
    );
  }

  Widget _buildCategoriesList(CategoryType type) {
    return Consumer<CategoriesProvider>(
      builder: (context, categoriesProvider, child) {
        if (categoriesProvider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        final categories = categoriesProvider.getCategoriesByType(type);
        
        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Немає категорій ${type == CategoryType.expense ? 'витрат' : 'доходів'}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Додати категорію'),
                  onPressed: () => _showAddCategoryDialog(type),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryItem(category);
          },
        );
      },
    );
  }

  Widget _buildCategoryItem(Category category) {
    Color color;
    try {
      color = Color(int.parse(category.color.replaceAll('#', '0xFF')));
    } catch (e) {
      color = Colors.grey;
    }
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(_getIconData(category.iconName), color: color, size: 20),
        ),
        title: Text(
          category.name,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          category.type == CategoryType.expense ? 'Витрата' : 'Дохід',
          style: TextStyle(
            color: category.type == CategoryType.expense ? Colors.red : Colors.green,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                // Використовуємо barrierDismissible: true
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (BuildContext dialogContext) {
                    return Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: EditCategoryDialog(category: category),
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmationDialog(category);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Видалити категорію?'),
        content: Text(
          'Ви впевнені, що хочете видалити категорію "${category.name}"? ' +
          'Усі транзакції, пов\'язані з цією категорією, також будуть видалені. ' +
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
              
              final categoriesProvider = Provider.of<CategoriesProvider>(context, listen: false);
              categoriesProvider.deleteCategory(category.id!).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Категорію видалено')),
                );
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

class AddCategoryDialog extends StatefulWidget {
  final CategoryType type;
  
  const AddCategoryDialog({Key? key, required this.type}) : super(key: key);

  @override
  _AddCategoryDialogState createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String _selectedIconName = 'shopping_cart';
  String _selectedColor = '#F44336';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      try {
        final category = Category(
          name: _nameController.text,
          type: widget.type,
          iconName: _selectedIconName,
          color: _selectedColor,
        );
        
        final categoriesProvider = Provider.of<CategoriesProvider>(context, listen: false);
        
        categoriesProvider.addCategory(category).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Категорію додано')),
          );
          Navigator.pop(context);
        });
      } catch (e) {
        print('Error saving category: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка при збереженні категорії')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Нова категорія ${widget.type == CategoryType.expense ? 'витрат' : 'доходів'}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Назва категорії',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Будь ласка, введіть назву категорії';
                }
                return null;
              },
            ),
          ),
          SizedBox(height: 16),
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
                    margin: EdgeInsets.only(right: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
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
          SizedBox(height: 16),
          Text(
            'Іконка',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 120,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: AppConstants.categoryIcons.length,
              itemBuilder: (context, index) {
                final iconData = AppConstants.categoryIcons[index];
                final iconName = _getIconName(iconData);
                final isSelected = _selectedIconName == iconName;
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIconName = iconName;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
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
              },
            ),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                child: Text('Скасувати'),
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                child: Text('Зберегти'),
                onPressed: _saveCategory,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getIconName(IconData iconData) {
    if (iconData == Icons.shopping_cart) return 'shopping_cart';
    if (iconData == Icons.restaurant) return 'restaurant';
    if (iconData == Icons.directions_bus) return 'directions_bus';
    if (iconData == Icons.home) return 'home';
    if (iconData == Icons.medical_services) return 'medical_services';
    if (iconData == Icons.sports) return 'sports';
    if (iconData == Icons.school) return 'school';
    if (iconData == Icons.movie) return 'movie';
    if (iconData == Icons.travel_explore) return 'travel_explore';
    if (iconData == Icons.credit_card) return 'credit_card';
    if (iconData == Icons.attach_money) return 'attach_money';
    if (iconData == Icons.savings) return 'savings';
    if (iconData == Icons.card_giftcard) return 'card_giftcard';
    if (iconData == Icons.sell) return 'sell';
    if (iconData == Icons.work) return 'work';
    if (iconData == Icons.check_circle) return 'check_circle';
    return 'help';
  }
}

class EditCategoryDialog extends StatefulWidget {
  final Category category;
  
  const EditCategoryDialog({Key? key, required this.category}) : super(key: key);

  @override
  _EditCategoryDialogState createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  
  late String _selectedIconName;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _selectedIconName = widget.category.iconName;
    _selectedColor = widget.category.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateCategory() {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedCategory = Category(
          id: widget.category.id,
          name: _nameController.text,
          type: widget.category.type,
          iconName: _selectedIconName,
          color: _selectedColor,
        );
        
        final categoriesProvider = Provider.of<CategoriesProvider>(context, listen: false);
        
        categoriesProvider.updateCategory(updatedCategory).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Категорію оновлено')),
          );
          Navigator.pop(context);
        });
      } catch (e) {
        print('Error updating category: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка при оновленні категорії')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Редагувати категорію',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Назва категорії',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Будь ласка, введіть назву категорії';
                }
                return null;
              },
            ),
          ),
          SizedBox(height: 16),
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
                    margin: EdgeInsets.only(right: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
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
          SizedBox(height: 16),
          Text(
            'Іконка',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 120,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: AppConstants.categoryIcons.length,
              itemBuilder: (context, index) {
                final iconData = AppConstants.categoryIcons[index];
                final iconName = _getIconName(iconData);
                final isSelected = _selectedIconName == iconName;
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIconName = iconName;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
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
              },
            ),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                child: Text('Скасувати'),
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                child: Text('Оновити'),
                onPressed: _updateCategory,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getIconName(IconData iconData) {
    if (iconData == Icons.shopping_cart) return 'shopping_cart';
    if (iconData == Icons.restaurant) return 'restaurant';
    if (iconData == Icons.directions_bus) return 'directions_bus';
    if (iconData == Icons.home) return 'home';
    if (iconData == Icons.medical_services) return 'medical_services';
    if (iconData == Icons.sports) return 'sports';
    if (iconData == Icons.school) return 'school';
    if (iconData == Icons.movie) return 'movie';
    if (iconData == Icons.travel_explore) return 'travel_explore';
    if (iconData == Icons.credit_card) return 'credit_card';
    if (iconData == Icons.attach_money) return 'attach_money';
    if (iconData == Icons.savings) return 'savings';
    if (iconData == Icons.card_giftcard) return 'card_giftcard';
    if (iconData == Icons.sell) return 'sell';
    if (iconData == Icons.work) return 'work';
    if (iconData == Icons.check_circle) return 'check_circle';
    return 'help';
  }
}
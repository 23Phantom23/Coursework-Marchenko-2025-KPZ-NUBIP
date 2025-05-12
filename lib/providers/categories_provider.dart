// lib/providers/categories_provider.dart
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class CategoriesProvider with ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  
  // Отримання категорій за типом
  List<Category> getCategoriesByType(CategoryType type) {
    return _categories.where((category) => category.type == type).toList();
  }

  Future<void> loadCategories() async {
    try {
      _isLoading = true;
      
      _categories = await DatabaseService.instance.getCategories();
    } catch (e) {
      print('Error loading categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      final id = await DatabaseService.instance.insertCategory(category);
      final newCategory = Category(
        id: id,
        name: category.name,
        type: category.type,
        iconName: category.iconName,
        color: category.color,
      );
      
      _categories.add(newCategory);
      notifyListeners();
    } catch (e) {
      print('Error adding category: $e');
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await DatabaseService.instance.updateCategory(category);
      
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating category: $e');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await DatabaseService.instance.deleteCategory(id);
      
      _categories.removeWhere((category) => category.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting category: $e');
    }
  }

  // Отримання категорії за ID
  Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
}
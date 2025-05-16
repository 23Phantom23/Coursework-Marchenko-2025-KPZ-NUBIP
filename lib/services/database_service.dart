// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'finance_tracker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        balance REAL NOT NULL,
        iconName TEXT NOT NULL,
        color TEXT NOT NULL
      )
    ''');


    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        iconName TEXT NOT NULL,
        color TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        categoryId INTEGER NOT NULL,
        accountId INTEGER NOT NULL,
        toAccountId INTEGER,
        type INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories (id),
        FOREIGN KEY (accountId) REFERENCES accounts (id),
        FOREIGN KEY (toAccountId) REFERENCES accounts (id)
      )
    ''');

    // Додамо деякі початкові дані для тестування
    _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    // Додавання стандартних рахунків
    await db.insert('accounts', {
      'name': 'Monobank Чорна',
      'balance': 1000.0,
      'iconName': 'credit_card',
      'color': '#4CAF50'
    });
    
    await db.insert('accounts', {
      'name': 'Готівка',
      'balance': 500.0,
      'iconName': 'money',
      'color': '#2196F3'
    });

    // Додавання стандартних категорій витрат
    await db.insert('categories', {
      'name': 'Продукти',
      'type': CategoryType.expense.index,
      'iconName': 'shopping_cart',
      'color': '#F44336'
    });
    
    await db.insert('categories', {
      'name': 'Транспорт',
      'type': CategoryType.expense.index,
      'iconName': 'directions_bus',
      'color': '#9C27B0'
    });
    
    await db.insert('categories', {
      'name': 'Кафе',
      'type': CategoryType.expense.index,
      'iconName': 'restaurant',
      'color': '#FF9800'
    });

    // Додавання стандартних категорій доходів
    await db.insert('categories', {
      'name': 'Зарплата',
      'type': CategoryType.income.index,
      'iconName': 'attach_money',
      'color': '#4CAF50'
    });
    
    await db.insert('categories', {
      'name': 'Подарунок',
      'type': CategoryType.income.index,
      'iconName': 'card_giftcard',
      'color': '#E91E63'
    });
  }
  
  // Публічний метод для скидання даних до початкових
  Future<void> resetToInitialData() async {
    final db = await database;
    await _insertInitialData(db);
  }

  // CRUD операції для рахунків
  Future<List<Account>> getAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');
    return List.generate(maps.length, (i) => Account.fromMap(maps[i]));
  }

  Future<Account> getAccount(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = 
        await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    return Account.fromMap(maps.first);
  }

  Future<int> insertAccount(Account account) async {
    final db = await database;
    return await db.insert('accounts', account.toMap());
  }

  Future<int> updateAccount(Account account) async {
    final db = await database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD операції для категорій
  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<List<Category>> getCategoriesByType(CategoryType type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type.index],
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD операції для транзакцій
  Future<List<Transaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  Future<List<Transaction>> getTransactionsByAccount(int accountId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'accountId = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  Future<List<Transaction>> getTransactionsByPeriod(DateTime start, DateTime end) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
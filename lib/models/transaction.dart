// lib/models/transaction.dart
enum TransactionType { income, expense, transfer }

class Transaction {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final int categoryId;
  final int accountId;
  final int? toAccountId; // Для переказів між рахунками
  final TransactionType type;
  final String? note;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.accountId,
    this.toAccountId,
    required this.type,
    this.note,
  });

  Transaction copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
    int? categoryId,
    int? accountId,
    int? toAccountId,
    TransactionType? type,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      type: type ?? this.type,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'categoryId': categoryId,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'type': type.index,
      'note': note,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      categoryId: map['categoryId'],
      accountId: map['accountId'],
      toAccountId: map['toAccountId'],
      type: TransactionType.values[map['type']],
      note: map['note'],
    );
  }
}
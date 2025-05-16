// lib/models/account.dart
class Account {
  final int? id;
  final String name;
  final double balance;
  final String iconName;
  final String color;

  Account({
    this.id,
    required this.name,
    required this.balance,
    required this.iconName,
    required this.color,
  });

  Account copyWith({
    int? id,
    String? name,
    double? balance,
    String? iconName,
    String? color,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'iconName': iconName,
      'color': color,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      balance: map['balance'],
      iconName: map['iconName'],
      color: map['color'],
    );
  }
}
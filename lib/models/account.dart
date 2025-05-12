// lib/models/account.dart
class Account {
  final int? id;
  final String name;
  final double balance;
  final String currency;
  final String iconName;
  final String color;

  Account({
    this.id,
    required this.name,
    required this.balance,
    required this.currency,
    required this.iconName,
    required this.color,
  });

  Account copyWith({
    int? id,
    String? name,
    double? balance,
    String? currency,
    String? iconName,
    String? color,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'currency': currency,
      'iconName': iconName,
      'color': color,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      balance: map['balance'],
      currency: map['currency'],
      iconName: map['iconName'],
      color: map['color'],
    );
  }
}
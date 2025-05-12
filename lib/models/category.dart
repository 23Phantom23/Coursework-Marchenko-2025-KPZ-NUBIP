// lib/models/category.dart
enum CategoryType { income, expense }

class Category {
  final int? id;
  final String name;
  final CategoryType type;
  final String iconName;
  final String color;

  Category({
    this.id,
    required this.name,
    required this.type,
    required this.iconName,
    required this.color,
  });

  Category copyWith({
    int? id,
    String? name,
    CategoryType? type,
    String? iconName,
    String? color,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'iconName': iconName,
      'color': color,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      type: CategoryType.values[map['type']],
      iconName: map['iconName'],
      color: map['color'],
    );
  }
}
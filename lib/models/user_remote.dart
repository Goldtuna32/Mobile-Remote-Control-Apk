class UserRemote {
  final String id;
  final String name;
  final String category;
  final String brand;

  UserRemote({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'category': category, 'brand': brand};
  }

  factory UserRemote.fromMap(Map<String, dynamic> map) {
    return UserRemote(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      brand: map['brand'] ?? '',
    );
  }
}

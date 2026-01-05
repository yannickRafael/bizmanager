class Product {
  final String id;
  final String name;
  final double defaultPrice;

  Product({required this.id, required this.name, required this.defaultPrice});

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      defaultPrice: (map['defaultPrice'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'defaultPrice': defaultPrice};
  }
}

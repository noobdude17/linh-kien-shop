class ProductVariant {
  final String id;
  final String name;
  final double price;
  final double? oldPrice;
  final int stock;

  const ProductVariant({
    required this.id,
    required this.name,
    required this.price,
    this.oldPrice,
    required this.stock,
  });

  bool get isAvailable => stock > 0;

  int? get discountPercent {
    if (oldPrice == null || oldPrice! <= price) return null;
    return (((oldPrice! - price) / oldPrice!) * 100).round();
  }

  factory ProductVariant.fromMap(Map<String, dynamic> m) => ProductVariant(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        price: (m['price'] ?? 0).toDouble(),
        oldPrice: (m['oldPrice'] as num?)?.toDouble(),
        stock: m['stock'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'oldPrice': oldPrice,
        'stock': stock,
      };
}

class CartItemModel {
  final String productId;
  final String name;
  final String variant;
  final String variantId;
  final double price;
  final String imageLabel;
  final String imageUrl;
  int quantity;
  bool selected;

  CartItemModel({
    required this.productId,
    required this.name,
    this.variant = '',
    this.variantId = '',
    required this.price,
    this.imageLabel = '',
    this.imageUrl = '',
    this.quantity = 1,
    this.selected = true,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'name': name,
    'variant': variant,
    'variantId': variantId,
    'price': price,
    'imageLabel': imageLabel,
    'imageUrl': imageUrl,
    'quantity': quantity,
  };

  factory CartItemModel.fromMap(Map<String, dynamic> m) => CartItemModel(
    productId: m['productId'] ?? '',
    name: m['name'] ?? '',
    variant: m['variant'] ?? '',
    variantId: m['variantId'] ?? '',
    price: (m['price'] ?? 0).toDouble(),
    imageLabel: m['imageLabel'] ?? '',
    imageUrl: m['imageUrl'] ?? '',
    quantity: m['quantity'] ?? 1,
  );
}

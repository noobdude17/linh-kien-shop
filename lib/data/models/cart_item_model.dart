class CartItemModel {
  final String productId;
  final String name;
  final String variant;
  final double price;
  final String imageLabel;
  int quantity;
  bool selected;

  CartItemModel({
    required this.productId,
    required this.name,
    this.variant = '',
    required this.price,
    this.imageLabel = '',
    this.quantity = 1,
    this.selected = true,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'variant': variant,
        'price': price,
        'imageLabel': imageLabel,
        'quantity': quantity,
      };

  factory CartItemModel.fromMap(Map<String, dynamic> m) => CartItemModel(
        productId: m['productId'] ?? '',
        name: m['name'] ?? '',
        variant: m['variant'] ?? '',
        price: (m['price'] ?? 0).toDouble(),
        imageLabel: m['imageLabel'] ?? '',
        quantity: m['quantity'] ?? 1,
      );
}

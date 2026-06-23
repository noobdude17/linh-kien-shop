import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String brand;
  final String description;
  final double price;
  final double? oldPrice;
  final double rating;
  final int reviewCount;
  final String imageLabel; // caption cho placeholder ảnh
  final String imageUrl;
  final String categoryId;
  final String categoryName;
  final int stock;
  final bool isActive;
  final Map<String, String> specs;
  final Map<String, dynamic> compatibility;

  const ProductModel({
    required this.id,
    required this.name,
    this.brand = '',
    this.description = '',
    required this.price,
    this.oldPrice,
    this.rating = 0,
    this.reviewCount = 0,
    this.imageLabel = '',
    this.imageUrl = '',
    required this.categoryId,
    this.categoryName = '',
    this.stock = 0,
    this.isActive = true,
    this.specs = const {},
    this.compatibility = const {},
  });

  bool get inStock => isActive;

  /// % giảm giá (làm tròn), null nếu không có oldPrice.
  int? get discountPercent {
    if (oldPrice == null || oldPrice! <= price) return null;
    return (((oldPrice! - price) / oldPrice!) * 100).round();
  }

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      oldPrice: (data['oldPrice'] as num?)?.toDouble(),
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      imageLabel: data['imageLabel'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      stock: data['stock'] ?? 0,
      isActive: data['isActive'] ?? true,
      specs: Map<String, String>.from(data['specs'] ?? {}),
      compatibility: Map<String, dynamic>.from(data['compatibility'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'brand': brand,
    'description': description,
    'price': price,
    'oldPrice': oldPrice,
    'rating': rating,
    'reviewCount': reviewCount,
    'imageLabel': imageLabel,
    'imageUrl': imageUrl,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'stock': stock,
    'isActive': isActive,
    'specs': specs,
    'compatibility': compatibility,
  };
}

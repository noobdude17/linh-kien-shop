import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_variant.dart';

enum StockStatus { inStock, lowStock, outOfStock }

class ProductModel {
  final String id;
  final String name;
  final String brand;
  final String description;
  final double price;
  final double? oldPrice;
  final double rating;
  final int reviewCount;
  final String imageLabel;
  final String imageUrl;
  final List<String> images;
  final String categoryId;
  final String categoryName;
  final int stock;
  final bool isActive;
  final Map<String, String> specs;
  final List<ProductVariant> variants;

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
    this.images = const [],
    required this.categoryId,
    this.categoryName = '',
    this.stock = 0,
    this.isActive = true,
    this.specs = const {},
    this.variants = const [],
  });

  bool get inStock {
    if (variants.isNotEmpty) {
      return variants.any((v) => v.isAvailable);
    }
    return isActive && stock > 0;
  }

  StockStatus get stockStatus {
    if (variants.isNotEmpty) {
      final total = variants.fold<int>(0, (s, v) => s + v.stock);
      if (total == 0) return StockStatus.outOfStock;
      if (total <= 5) return StockStatus.lowStock;
      return StockStatus.inStock;
    }
    if (!isActive || stock == 0) return StockStatus.outOfStock;
    if (stock <= 5) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

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
      images: List<String>.from(data['images'] ?? []),
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      stock: data['stock'] ?? 0,
      isActive: data['isActive'] ?? true,
      specs: Map<String, String>.from(data['specs'] ?? {}),
      variants: (data['variants'] as List<dynamic>? ?? [])
          .map((v) => ProductVariant.fromMap(v as Map<String, dynamic>))
          .toList(),
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
        'images': images,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'stock': stock,
        'isActive': isActive,
        'specs': specs,
        'variants': variants.map((v) => v.toMap()).toList(),
      };
}

import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String categoryId;
  final int stock;
  final bool isActive;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.stock,
    this.isActive = true,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      categoryId: data['categoryId'] ?? '',
      stock: data['stock'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'categoryId': categoryId,
        'stock': stock,
        'isActive': isActive,
      };
}

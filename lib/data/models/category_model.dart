import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String icon; // emoji fallback
  final int colorIndex; // index vào AppColors.categoryBgs
  final String? imageAsset; // asset path, ưu tiên hơn emoji nếu có

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon = '📦',
    this.colorIndex = 0,
    this.imageAsset,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '📦',
      colorIndex: data['colorIndex'] ?? 0,
      imageAsset: data['imageAsset'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'icon': icon,
    'colorIndex': colorIndex,
    if (imageAsset != null) 'imageAsset': imageAsset,
  };
}

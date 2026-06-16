import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String icon; // emoji placeholder (thay icon set sau)
  final int colorIndex; // index vào AppColors.categoryBgs

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon = '📦',
    this.colorIndex = 0,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '📦',
      colorIndex: data['colorIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'icon': icon,
        'colorIndex': colorIndex,
      };
}

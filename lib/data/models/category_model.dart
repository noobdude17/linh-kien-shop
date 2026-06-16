import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String iconUrl;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconUrl,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      iconUrl: data['iconUrl'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'iconUrl': iconUrl,
      };
}

// Danh mục mặc định để seed vào Firestore
const defaultCategories = [
  {'name': 'CPU / Vi xử lý', 'iconUrl': ''},
  {'name': 'RAM', 'iconUrl': ''},
  {'name': 'Card đồ họa (GPU)', 'iconUrl': ''},
  {'name': 'Ổ cứng (SSD/HDD)', 'iconUrl': ''},
  {'name': 'Mainboard', 'iconUrl': ''},
  {'name': 'Nguồn (PSU)', 'iconUrl': ''},
  {'name': 'Tản nhiệt', 'iconUrl': ''},
  {'name': 'Laptop', 'iconUrl': ''},
  {'name': 'Màn hình', 'iconUrl': ''},
  {'name': 'Phụ kiện', 'iconUrl': ''},
];

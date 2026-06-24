import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../mock_data.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

/// Hợp đồng truy xuất sản phẩm. UI/provider phụ thuộc vào abstract này,
/// không phụ thuộc Firestore trực tiếp → dễ test & thay nguồn dữ liệu.
abstract class ProductRepository {
  Future<List<ProductModel>> getFeatured();
  Future<List<ProductModel>> getByCategory(String? categoryId);
  Future<ProductModel?> getById(String id);
  Future<List<CategoryModel>> getCategories();
  Future<List<ProductModel>> search(String query);
}

/// Hiện thực bằng dữ liệu mẫu — dùng cho skeleton & test khi chưa có backend.
class MockProductRepository implements ProductRepository {
  Future<T> _delayed<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 300), () => value);

  @override
  Future<List<ProductModel>> getFeatured() => _delayed(MockData.featured);

  @override
  Future<List<ProductModel>> getByCategory(String? categoryId) {
    final all = [...MockData.featured, ...MockData.gpuList];
    final filtered = categoryId == null
        ? all
        : all.where((p) => p.categoryId == categoryId).toList();
    return _delayed(filtered);
  }

  @override
  Future<ProductModel?> getById(String id) {
    final all = [...MockData.featured, ...MockData.gpuList];
    final found = all.where((p) => p.id == id).toList();
    return _delayed(found.isEmpty ? null : found.first);
  }

  @override
  Future<List<CategoryModel>> getCategories() => _delayed(MockData.categories);

  @override
  Future<List<ProductModel>> search(String query) {
    final q = query.toLowerCase();
    final all = [...MockData.featured, ...MockData.gpuList];
    return _delayed(
      all
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q) ||
              p.categoryName.toLowerCase().contains(q))
          .toList(),
    );
  }
}

/// Hiện thực bằng Firestore — bật khi đã cấu hình Firebase.
class FirestoreProductRepository implements ProductRepository {
  final FirebaseFirestore _db;
  FirestoreProductRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colProducts);

  @override
  Future<List<ProductModel>> getFeatured() async {
    final snap = await _col.where('isActive', isEqualTo: true).limit(10).get();
    return snap.docs.map(ProductModel.fromFirestore).toList();
  }

  @override
  Future<List<ProductModel>> getByCategory(String? categoryId) async {
    Query<Map<String, dynamic>> q = _col.where('isActive', isEqualTo: true);
    if (categoryId != null) q = q.where('categoryId', isEqualTo: categoryId);
    final snap = await q.get();
    return snap.docs.map(ProductModel.fromFirestore).toList();
  }

  @override
  Future<ProductModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? ProductModel.fromFirestore(doc) : null;
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final snap = await _db.collection(AppConstants.colCategories).get();
    return snap.docs.map(CategoryModel.fromFirestore).toList();
  }

  @override
  Future<List<ProductModel>> search(String query) async {
    // Firestore không hỗ trợ full-text search nên fetch toàn bộ active
    // rồi filter client-side (case-insensitive). Ổn với catalog nhỏ.
    // Production nên dùng Algolia / Typesense.
    final q = query.toLowerCase();
    final snap = await _col.where('isActive', isEqualTo: true).get();
    return snap.docs
        .map(ProductModel.fromFirestore)
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q) ||
            p.categoryName.toLowerCase().contains(q))
        .toList();

  }
}

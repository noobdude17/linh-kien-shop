import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

/// Provider nguồn dữ liệu. Đổi 1 dòng này sang FirestoreProductRepository
/// (sau khi cấu hình Firebase) là cả app dùng backend thật.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return MockProductRepository();
  // return FirestoreProductRepository(FirebaseFirestore.instance);
});

/// Sản phẩm nổi bật (Home).
final featuredProductsProvider = FutureProvider<List<ProductModel>>((ref) {
  return ref.watch(productRepositoryProvider).getFeatured();
});

/// Danh mục.
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(productRepositoryProvider).getCategories();
});

/// Sản phẩm theo danh mục (truyền categoryId qua family).
final productsByCategoryProvider =
    FutureProvider.family<List<ProductModel>, String?>((ref, categoryId) {
  return ref.watch(productRepositoryProvider).getByCategory(categoryId);
});

/// Chi tiết 1 sản phẩm theo id.
final productDetailProvider =
    FutureProvider.family<ProductModel?, String>((ref, id) {
  return ref.watch(productRepositoryProvider).getById(id);
});

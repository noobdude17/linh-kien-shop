import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

/// Nguồn dữ liệu sản phẩm. Tự chuyển Mock ↔ Firestore theo [AppConfig.useFirebase].
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  if (AppConfig.firebaseEnabled) {
    return FirestoreProductRepository(FirebaseFirestore.instance);
  }
  return MockProductRepository();
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

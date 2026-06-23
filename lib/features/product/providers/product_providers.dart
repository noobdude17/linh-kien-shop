import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  if (AppConfig.firebaseEnabled) {
    return FirestoreProductRepository(FirebaseFirestore.instance);
  }
  return MockProductRepository();
});

final featuredProductsProvider = FutureProvider<List<ProductModel>>((ref) {
  return ref.watch(productRepositoryProvider).getFeatured();
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(productRepositoryProvider).getCategories();
});

final productsByCategoryProvider =
    FutureProvider.family<List<ProductModel>, String?>((ref, categoryId) {
  return ref.watch(productRepositoryProvider).getByCategory(categoryId);
});

final productDetailProvider =
    FutureProvider.family<ProductModel?, String>((ref, id) {
  return ref.watch(productRepositoryProvider).getById(id);
});

/// Tìm kiếm sản phẩm theo từ khóa.
final searchProvider =
    FutureProvider.autoDispose.family<List<ProductModel>, String>((ref, query) {
  return ref.watch(productRepositoryProvider).search(query.toLowerCase().trim());
});

final relatedProductsProvider =
    FutureProvider.autoDispose.family<List<ProductModel>, String>(
        (ref, productId) async {
  final product = await ref.watch(productDetailProvider(productId).future);
  if (product == null) return [];
  final all =
      await ref.watch(productsByCategoryProvider(product.categoryId).future);
  return all.where((p) => p.id != productId).take(6).toList();
});

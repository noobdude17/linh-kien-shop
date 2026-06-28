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
  Future<ProductPage> getByCategoryPage(
    String? categoryId, {
    required int limit,
    Object? cursor,
  });
  Future<ProductModel?> getById(String id);
  Future<List<CategoryModel>> getCategories();
  Future<List<ProductModel>> search(String query);
  Future<ProductPage> searchPage(
    String query, {
    required int limit,
    Object? cursor,
  });
}

class ProductPage {
  final List<ProductModel> items;
  final Object? cursor;
  final bool hasMore;

  const ProductPage({
    required this.items,
    required this.cursor,
    required this.hasMore,
  });
}

/// Hiện thực bằng dữ liệu mẫu — dùng cho skeleton & test khi chưa có backend.
class MockProductRepository implements ProductRepository {
  static const _featuredCategoryIds = ['gpu', 'cpu', 'ram', 'storage'];

  Future<T> _delayed<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 300), () => value);

  @override
  Future<List<ProductModel>> getFeatured() {
    final products =
        [
            ...MockData.featured,
            ...MockData.gpuList,
          ].where((p) => _featuredCategoryIds.contains(p.categoryId)).toList()
          ..sort((a, b) {
            final price = b.price.compareTo(a.price);
            if (price != 0) return price;
            return b.rating.compareTo(a.rating);
          });
    return _delayed(products.take(12).toList());
  }

  @override
  Future<List<ProductModel>> getByCategory(String? categoryId) {
    final all = [...MockData.featured, ...MockData.gpuList];
    final filtered = categoryId == null
        ? all
        : all.where((p) => p.categoryId == categoryId).toList();
    return _delayed(filtered);
  }

  @override
  Future<ProductPage> getByCategoryPage(
    String? categoryId, {
    required int limit,
    Object? cursor,
  }) async {
    final all = await getByCategory(categoryId);
    final start = cursor is int ? cursor : 0;
    final end = (start + limit).clamp(0, all.length);
    return ProductPage(
      items: all.sublist(start, end),
      cursor: end,
      hasMore: end < all.length,
    );
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
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.brand.toLowerCase().contains(q) ||
                p.categoryName.toLowerCase().contains(q),
          )
          .toList(),
    );
  }

  @override
  Future<ProductPage> searchPage(
    String query, {
    required int limit,
    Object? cursor,
  }) async {
    final all = await search(query);
    final start = cursor is int ? cursor : 0;
    final end = (start + limit).clamp(0, all.length);
    return ProductPage(
      items: all.sublist(start, end),
      cursor: end,
      hasMore: end < all.length,
    );
  }
}

/// Hiện thực bằng Firestore — bật khi đã cấu hình Firebase.
class FirestoreProductRepository implements ProductRepository {
  final FirebaseFirestore _db;
  FirestoreProductRepository(this._db);

  static const _featuredCategoryIds = ['gpu', 'cpu', 'ram', 'storage'];
  static const _featuredCategoryWeight = {
    'gpu': 0,
    'cpu': 1,
    'ram': 2,
    'storage': 3,
  };

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colProducts);

  @override
  Future<List<ProductModel>> getFeatured() async {
    final groups = await Future.wait(
      _featuredCategoryIds.map((categoryId) async {
        final snap = await _col
            .where('isActive', isEqualTo: true)
            .where('categoryId', isEqualTo: categoryId)
            .get(const GetOptions(source: Source.server));
        final products = snap.docs.map(ProductModel.fromFirestore).toList()
          ..sort(_compareFeaturedByPrice);
        return products.take(3);
      }),
    );

    final products = groups.expand((items) => items).toList()
      ..sort(_compareFeatured);
    return products.take(12).toList();
  }

  int _compareFeaturedByPrice(ProductModel a, ProductModel b) {
    final price = b.price.compareTo(a.price);
    if (price != 0) return price;
    final rating = b.rating.compareTo(a.rating);
    if (rating != 0) return rating;
    return a.name.compareTo(b.name);
  }

  int _compareFeatured(ProductModel a, ProductModel b) {
    final category = (_featuredCategoryWeight[a.categoryId] ?? 99).compareTo(
      _featuredCategoryWeight[b.categoryId] ?? 99,
    );
    if (category != 0) return category;
    return _compareFeaturedByPrice(a, b);
  }

  @override
  Future<List<ProductModel>> getByCategory(String? categoryId) async {
    Query<Map<String, dynamic>> q = _col.where('isActive', isEqualTo: true);
    if (categoryId != null) q = q.where('categoryId', isEqualTo: categoryId);
    final snap = await q.get(const GetOptions(source: Source.server));
    return snap.docs.map(ProductModel.fromFirestore).toList();
  }

  @override
  Future<ProductPage> getByCategoryPage(
    String? categoryId, {
    required int limit,
    Object? cursor,
  }) async {
    Query<Map<String, dynamic>> q = _col.where('isActive', isEqualTo: true);
    if (categoryId != null) q = q.where('categoryId', isEqualTo: categoryId);
    q = q.orderBy(FieldPath.documentId).limit(limit);
    if (cursor is DocumentSnapshot<Map<String, dynamic>>) {
      q = q.startAfterDocument(cursor);
    }

    final snap = await q.get(const GetOptions(source: Source.server));
    return ProductPage(
      items: snap.docs.map(ProductModel.fromFirestore).toList(),
      cursor: snap.docs.isEmpty ? cursor : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  }

  @override
  Future<ProductModel?> getById(String id) async {
    final doc = await _col.doc(id).get(const GetOptions(source: Source.server));
    return doc.exists ? ProductModel.fromFirestore(doc) : null;
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final snap = await _db
        .collection(AppConstants.colCategories)
        .get(const GetOptions(source: Source.server));
    return snap.docs.map(CategoryModel.fromFirestore).toList();
  }

  @override
  Future<List<ProductModel>> search(String query) async {
    // Firestore không hỗ trợ full-text search nên fetch toàn bộ active
    // rồi filter client-side (case-insensitive). Ổn với catalog nhỏ.
    // Production nên dùng Algolia / Typesense.
    final q = query.toLowerCase();
    final snap = await _col
        .where('isActive', isEqualTo: true)
        .get(const GetOptions(source: Source.server));
    return snap.docs
        .map(ProductModel.fromFirestore)
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q) ||
              p.categoryName.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<ProductPage> searchPage(
    String query, {
    required int limit,
    Object? cursor,
  }) async {
    final qText = query.toLowerCase().trim();
    if (qText.isEmpty) {
      return const ProductPage(items: [], cursor: null, hasMore: false);
    }

    const scanBatchSize = 80;
    final matches = <ProductModel>[];
    Object? nextCursor = cursor;
    var hasMoreDocs = true;

    while (matches.length < limit && hasMoreDocs) {
      Query<Map<String, dynamic>> q = _col
          .where('isActive', isEqualTo: true)
          .orderBy(FieldPath.documentId)
          .limit(scanBatchSize);
      if (nextCursor is DocumentSnapshot<Map<String, dynamic>>) {
        q = q.startAfterDocument(nextCursor);
      }

      final snap = await q.get(const GetOptions(source: Source.server));
      hasMoreDocs = snap.docs.length == scanBatchSize;
      if (snap.docs.isEmpty) break;
      nextCursor = snap.docs.last;

      for (final doc in snap.docs) {
        final product = ProductModel.fromFirestore(doc);
        if (product.name.toLowerCase().contains(qText) ||
            product.brand.toLowerCase().contains(qText) ||
            product.categoryName.toLowerCase().contains(qText)) {
          matches.add(product);
          if (matches.length == limit) break;
        }
      }
    }

    return ProductPage(
      items: matches,
      cursor: nextCursor,
      hasMore: hasMoreDocs,
    );
  }
}

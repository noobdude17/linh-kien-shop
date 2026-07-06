import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../mock_data.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import 'product_repository.dart';

class AdminDashboardStats {
  final int activeProducts;
  final int totalOrders;
  final int pendingOrders;
  final double deliveredRevenue;
  final List<double> revenue7d;

  const AdminDashboardStats({
    required this.activeProducts,
    required this.totalOrders,
    required this.pendingOrders,
    required this.deliveredRevenue,
    required this.revenue7d,
  });
}

class AdminReviewRecord {
  final ReviewModel review;
  final String productName;

  const AdminReviewRecord({required this.review, required this.productName});
}

class AdminProductQuery {
  final String search;
  final String? categoryId;
  final bool? active;
  final int limit;
  final Object? cursor;

  const AdminProductQuery({
    this.search = '',
    this.categoryId,
    this.active,
    this.limit = 30,
    this.cursor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminProductQuery &&
          search == other.search &&
          categoryId == other.categoryId &&
          active == other.active &&
          limit == other.limit &&
          cursor == other.cursor;

  @override
  int get hashCode => Object.hash(search, categoryId, active, limit, cursor);
}

class AdminOrderQuery {
  final String search;
  final String? status;
  final int limit;
  final Object? cursor;

  const AdminOrderQuery({
    this.search = '',
    this.status,
    this.limit = 30,
    this.cursor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminOrderQuery &&
          search == other.search &&
          status == other.status &&
          limit == other.limit &&
          cursor == other.cursor;

  @override
  int get hashCode => Object.hash(search, status, limit, cursor);
}

class AdminUserQuery {
  final String search;
  final bool? locked;
  final int limit;
  final Object? cursor;

  const AdminUserQuery({
    this.search = '',
    this.locked,
    this.limit = 30,
    this.cursor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminUserQuery &&
          search == other.search &&
          locked == other.locked &&
          limit == other.limit &&
          cursor == other.cursor;

  @override
  int get hashCode => Object.hash(search, locked, limit, cursor);
}

class AdminReviewQuery {
  final String search;
  final bool? hidden;
  final int limit;
  final Object? cursor;

  const AdminReviewQuery({
    this.search = '',
    this.hidden,
    this.limit = 30,
    this.cursor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminReviewQuery &&
          search == other.search &&
          hidden == other.hidden &&
          limit == other.limit &&
          cursor == other.cursor;

  @override
  int get hashCode => Object.hash(search, hidden, limit, cursor);
}

class AdminPage<T> {
  final List<T> items;
  final Object? cursor;
  final bool hasMore;

  const AdminPage({
    required this.items,
    required this.cursor,
    required this.hasMore,
  });
}

abstract class AdminRepository {
  Future<AdminDashboardStats> getDashboardStats();
  Future<AdminPage<ProductModel>> getProducts(AdminProductQuery query);
  Future<ProductModel?> getProduct(String id);
  Future<void> saveProduct(ProductModel product);
  Future<void> softDeleteProduct(String id);
  Future<void> setProductActive(String id, bool active);
  Future<AdminPage<OrderModel>> getOrders(AdminOrderQuery query);
  Future<OrderModel?> getOrder(String id);
  Future<void> updateOrderStatus(String id, String status);
  Future<AdminPage<UserModel>> getUsers(AdminUserQuery query);
  Future<void> setUserLocked(String id, bool locked);
  Future<void> saveUser(UserModel user);
  Future<void> deleteUser(String id);
  Future<AdminPage<AdminReviewRecord>> getReviews(AdminReviewQuery query);
  Future<void> setReviewHidden({
    required String productId,
    required String reviewId,
    required bool hidden,
  });
}

bool canTransitionOrder(String current, String next) {
  if (current == next) return true;
  if (current == AppConstants.statusDelivered ||
      current == AppConstants.statusCancelled) {
    return false;
  }
  if (next == AppConstants.statusCancelled) return true;
  return switch (current) {
    AppConstants.statusPending => next == AppConstants.statusConfirmed,
    AppConstants.statusConfirmed => next == AppConstants.statusShipping,
    AppConstants.statusShipping => next == AppConstants.statusDelivered,
    _ => false,
  };
}

AdminDashboardStats computeDashboardStats(
  List<ProductModel> products,
  List<OrderModel> orders, {
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final buckets = List<double>.filled(7, 0);
  var deliveredRevenue = 0.0;
  for (final order in orders) {
    if (order.status != AppConstants.statusDelivered) continue;
    deliveredRevenue += order.totalAmount;
    final day = DateTime(
      order.createdAt.year,
      order.createdAt.month,
      order.createdAt.day,
    );
    final base = DateTime(today.year, today.month, today.day);
    final diff = base.difference(day).inDays;
    if (diff >= 0 && diff < 7) {
      buckets[6 - diff] += order.totalAmount;
    }
  }
  return AdminDashboardStats(
    activeProducts: products.where((p) => p.isActive).length,
    totalOrders: orders.length,
    pendingOrders: orders
        .where((o) => o.status == AppConstants.statusPending)
        .length,
    deliveredRevenue: deliveredRevenue,
    revenue7d: buckets,
  );
}

class MockAdminRepository implements AdminRepository {
  MockAdminRepository()
    : _products = {
        for (final p in [...MockData.featured, ...MockData.gpuList]) p.id: p,
      },
      _orders = {for (final o in MockData.adminOrders()) o.id: o},
      _reviews = List.of(MockData.reviews),
      _users = {
        'mock-demo': const UserModel(
          id: 'mock-demo',
          name: 'Khách Demo',
          email: 'demo@lks.vn',
          role: AppConstants.roleCustomer,
          phone: '0900000000',
          address: 'Hà Nội',
        ),
        'mock-admin': const UserModel(
          id: 'mock-admin',
          name: 'Quản trị viên',
          email: 'admin@lks.vn',
          role: AppConstants.roleAdmin,
          phone: '0900000000',
          address: 'Hà Nội',
        ),
      };

  final Map<String, ProductModel> _products;
  final Map<String, OrderModel> _orders;
  final Map<String, UserModel> _users;
  final List<ReviewModel> _reviews;

  Future<T> _delayed<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 180), () => value);

  @override
  Future<AdminDashboardStats> getDashboardStats() => _delayed(
    computeDashboardStats(_products.values.toList(), _orders.values.toList()),
  );

  @override
  Future<ProductModel?> getProduct(String id) => _delayed(_products[id]);

  @override
  Future<AdminPage<ProductModel>> getProducts(AdminProductQuery query) {
    var list = _products.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final text = query.search.trim().toLowerCase();
    if (text.isNotEmpty) {
      list = list
          .where((p) => matchesProductSearchQuery(p, text))
          .toList();
    }
    if (query.categoryId != null) {
      list = list.where((p) => p.categoryId == query.categoryId).toList();
    }
    if (query.active != null) {
      list = list.where((p) => p.isActive == query.active).toList();
    }
    return _delayed(_slice(list, query.limit, query.cursor));
  }

  @override
  Future<void> saveProduct(ProductModel product) async {
    _products[product.id] = product;
  }

  @override
  Future<void> softDeleteProduct(String id) async {
    final product = _products[id];
    if (product == null) return;
    _products[id] = _copyProduct(product, isActive: false);
  }

  @override
  Future<void> setProductActive(String id, bool active) async {
    final product = _products[id];
    if (product == null) return;
    _products[id] = _copyProduct(product, isActive: active);
  }

  @override
  Future<OrderModel?> getOrder(String id) => _delayed(_orders[id]);

  @override
  Future<AdminPage<OrderModel>> getOrders(AdminOrderQuery query) {
    var list = _orders.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final text = query.search.trim().toLowerCase();
    if (text.isNotEmpty) {
      list = list
          .where(
            (o) => _matchesAdminSearch(text, [
              o.id,
              o.code,
              o.userId,
              o.customerName,
              o.address,
              o.paymentMethod,
              o.status,
              ...o.items.map((item) => item.productId),
              ...o.items.map((item) => item.name),
              ...o.items.map((item) => item.variant),
            ]),
          )
          .toList();
    }
    if (query.status != null) {
      list = list.where((o) => o.status == query.status).toList();
    }
    return _delayed(_slice(list, query.limit, query.cursor));
  }

  @override
  Future<void> updateOrderStatus(String id, String status) async {
    final order = _orders[id];
    if (order == null) return;
    if (!canTransitionOrder(order.status, status)) {
      throw StateError('Không thể chuyển trạng thái đơn hàng.');
    }
    _orders[id] = order.copyWith(status: status);
  }

  @override
  Future<AdminPage<UserModel>> getUsers(AdminUserQuery query) {
    var list = _users.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    final text = query.search.trim().toLowerCase();
    if (text.isNotEmpty) {
      list = list
          .where(
            (u) => _matchesAdminSearch(text, [
              u.id,
              u.name,
              u.email,
              u.role,
              u.phone,
              u.address,
              u.dob,
              u.defaultAddress?.name,
              u.defaultAddress?.phone,
              u.defaultAddress?.detail,
            ]),
          )
          .toList();
    }
    if (query.locked != null) {
      list = list.where((u) => u.isLocked == query.locked).toList();
    }
    return _delayed(_slice(list, query.limit, query.cursor));
  }

  @override
  Future<void> setUserLocked(String id, bool locked) async {
    final user = _users[id];
    if (user == null || user.isAdmin) return;
    _users[id] = user.copyWith(isLocked: locked);
  }

  @override
  Future<void> saveUser(UserModel user) async {
    _users[user.id] = user;
  }

  @override
  Future<void> deleteUser(String id) async {
    if (_users[id]?.isAdmin ?? false) return;
    _users.remove(id);
  }

  @override
  Future<AdminPage<AdminReviewRecord>> getReviews(AdminReviewQuery query) {
    var list = _reviews.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final text = query.search.trim().toLowerCase();
    if (text.isNotEmpty) {
      list = list
          .where(
            (r) => _matchesAdminSearch(text, [
              r.id,
              r.productId,
              r.userId,
              r.userName,
              r.comment,
              _products[r.productId]?.name,
              _products[r.productId]?.brand,
              _products[r.productId]?.categoryName,
            ]),
          )
          .toList();
    }
    if (query.hidden != null) {
      list = list.where((r) => r.isHidden == query.hidden).toList();
    }
    final records = list
        .map(
          (r) => AdminReviewRecord(
            review: r,
            productName: _products[r.productId]?.name ?? r.productId,
          ),
        )
        .toList();
    return _delayed(_slice(records, query.limit, query.cursor));
  }

  @override
  Future<void> setReviewHidden({
    required String productId,
    required String reviewId,
    required bool hidden,
  }) async {
    final index = _reviews.indexWhere(
      (r) => r.productId == productId && r.id == reviewId,
    );
    if (index < 0) return;
    _reviews[index] = _reviews[index].copyWith(isHidden: hidden);
    _recomputeMockRating(productId);
  }

  void _recomputeMockRating(String productId) {
    final visible = _reviews
        .where((r) => r.productId == productId && !r.isHidden)
        .toList();
    final product = _products[productId];
    if (product == null) return;
    final rating = visible.isEmpty
        ? 0.0
        : visible.fold<double>(0, (acc, r) => acc + r.rating) / visible.length;
    _products[productId] = _copyProduct(
      product,
      rating: (rating * 10).round() / 10,
      reviewCount: visible.length,
    );
  }
}

class FirestoreAdminRepository implements AdminRepository {
  final FirebaseFirestore _db;
  FirestoreAdminRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection(AppConstants.colProducts);
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(AppConstants.colOrders);
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(AppConstants.colUsers);

  @override
  Future<AdminDashboardStats> getDashboardStats() async {
    final productSnap = await _products.get();
    final orderSnap = await _orders.get();
    return computeDashboardStats(
      productSnap.docs.map(ProductModel.fromFirestore).toList(),
      orderSnap.docs.map(OrderModel.fromFirestore).toList(),
    );
  }

  @override
  Future<ProductModel?> getProduct(String id) async {
    final doc = await _products.doc(id).get();
    return doc.exists ? ProductModel.fromFirestore(doc) : null;
  }

  @override
  Future<AdminPage<ProductModel>> getProducts(AdminProductQuery query) async {
    Query<Map<String, dynamic>> q = _products.orderBy(FieldPath.documentId);
    if (query.categoryId != null) {
      q = q.where('categoryId', isEqualTo: query.categoryId);
    }
    if (query.active != null) {
      q = q.where('isActive', isEqualTo: query.active);
    }
    final text = query.search.trim().toLowerCase();
    // Search: Firestore can't full-text, so fetch the whole filtered set and
    // match/paginate in memory (int cursor). Otherwise use real doc-cursor paging.
    if (text.isNotEmpty) {
      final snap = await q.get();
      final items = snap.docs
          .map(ProductModel.fromFirestore)
          .where((p) => matchesProductSearchQuery(p, text))
          .toList();
      return _slice(items, query.limit, query.cursor);
    }
    q = q.limit(query.limit);
    if (query.cursor is DocumentSnapshot<Map<String, dynamic>>) {
      q = q.startAfterDocument(
        query.cursor as DocumentSnapshot<Map<String, dynamic>>,
      );
    }
    final snap = await q.get();
    return AdminPage(
      items: snap.docs.map(ProductModel.fromFirestore).toList(),
      cursor: snap.docs.isEmpty ? query.cursor : snap.docs.last,
      hasMore: snap.docs.length == query.limit,
    );
  }

  @override
  Future<void> saveProduct(ProductModel product) =>
      _products.doc(product.id).set(product.toFirestore());

  @override
  Future<void> softDeleteProduct(String id) =>
      _products.doc(id).set({'isActive': false}, SetOptions(merge: true));

  @override
  Future<void> setProductActive(String id, bool active) =>
      _products.doc(id).set({'isActive': active}, SetOptions(merge: true));

  @override
  Future<OrderModel?> getOrder(String id) async {
    final doc = await _orders.doc(id).get();
    return doc.exists ? OrderModel.fromFirestore(doc) : null;
  }

  @override
  Future<AdminPage<OrderModel>> getOrders(AdminOrderQuery query) async {
    Query<Map<String, dynamic>> q = _orders.orderBy(
      'createdAt',
      descending: true,
    );
    final text = query.search.trim().toLowerCase();
    // status + search filtered in memory: `where(status) + orderBy(createdAt)`
    // would need a composite index (that's why status tabs errored before).
    // ponytail: fetches the whole ordered set; add a composite index + server
    // filter if order volume outgrows a single read.
    if (query.status != null || text.isNotEmpty) {
      final snap = await q.get();
      var items = snap.docs.map(OrderModel.fromFirestore).toList();
      if (query.status != null) {
        items = items.where((o) => o.status == query.status).toList();
      }
      if (text.isNotEmpty) {
        items = items
            .where(
              (o) => _matchesAdminSearch(text, [
                o.id,
                o.code,
                o.userId,
                o.customerName,
                o.address,
                o.paymentMethod,
                o.status,
                ...o.items.map((item) => item.productId),
                ...o.items.map((item) => item.name),
                ...o.items.map((item) => item.variant),
              ]),
            )
            .toList();
      }
      return _slice(items, query.limit, query.cursor);
    }
    q = q.limit(query.limit);
    if (query.cursor is DocumentSnapshot<Map<String, dynamic>>) {
      q = q.startAfterDocument(
        query.cursor as DocumentSnapshot<Map<String, dynamic>>,
      );
    }
    final snap = await q.get();
    return AdminPage(
      items: snap.docs.map(OrderModel.fromFirestore).toList(),
      cursor: snap.docs.isEmpty ? query.cursor : snap.docs.last,
      hasMore: snap.docs.length == query.limit,
    );
  }

  @override
  Future<void> updateOrderStatus(String id, String status) async {
    final doc = await _orders.doc(id).get();
    if (!doc.exists) return;
    final order = OrderModel.fromFirestore(doc);
    if (!canTransitionOrder(order.status, status)) {
      throw StateError('Không thể chuyển trạng thái đơn hàng.');
    }
    await doc.reference.update({'status': status});
  }

  @override
  Future<AdminPage<UserModel>> getUsers(AdminUserQuery query) async {
    final Query<Map<String, dynamic>> q = _users.orderBy(FieldPath.documentId);
    final text = query.search.trim().toLowerCase();
    // locked + search filtered in memory (same composite-index reason as orders).
    if (query.locked != null || text.isNotEmpty) {
      final snap = await q.get();
      var items = snap.docs.map(UserModel.fromFirestore).toList();
      if (query.locked != null) {
        items = items.where((u) => u.isLocked == query.locked).toList();
      }
      if (text.isNotEmpty) {
        items = items
            .where(
              (u) => _matchesAdminSearch(text, [
                u.id,
                u.name,
                u.email,
                u.role,
                u.phone,
                u.address,
                u.dob,
                u.defaultAddress?.name,
                u.defaultAddress?.phone,
                u.defaultAddress?.detail,
              ]),
            )
            .toList();
      }
      return _slice(items, query.limit, query.cursor);
    }
    var paged = q.limit(query.limit);
    if (query.cursor is DocumentSnapshot<Map<String, dynamic>>) {
      paged = paged.startAfterDocument(
        query.cursor as DocumentSnapshot<Map<String, dynamic>>,
      );
    }
    final snap = await paged.get();
    return AdminPage(
      items: snap.docs.map(UserModel.fromFirestore).toList(),
      cursor: snap.docs.isEmpty ? query.cursor : snap.docs.last,
      hasMore: snap.docs.length == query.limit,
    );
  }

  @override
  Future<void> setUserLocked(String id, bool locked) async {
    final doc = await _users.doc(id).get();
    if (!doc.exists) return;
    final user = UserModel.fromFirestore(doc);
    if (user.isAdmin) return;
    await doc.reference.set({'isLocked': locked}, SetOptions(merge: true));
  }

  @override
  Future<void> saveUser(UserModel user) =>
      _users.doc(user.id).set(user.toFirestore(), SetOptions(merge: true));

  @override
  Future<void> deleteUser(String id) async {
    final doc = await _users.doc(id).get();
    if (doc.exists && UserModel.fromFirestore(doc).isAdmin) return;
    await _users.doc(id).delete();
  }

  @override
  Future<AdminPage<AdminReviewRecord>> getReviews(
    AdminReviewQuery query,
  ) async {
    // 1 query collectionGroup thay vì 1 query/sản phẩm (590 sản phẩm = màn
    // hình treo vô hạn → tab "Tất cả" không hiện, toggle ẩn không refresh nổi).
    final reviewSnap = await _db
        .collectionGroup(AppConstants.colReviews)
        .get();
    final productIds = reviewSnap.docs
        .map((doc) => doc.reference.parent.parent?.id)
        .whereType<String>()
        .toSet();
    final names = <String, String>{};
    for (final id in productIds) {
      final doc = await _products.doc(id).get();
      names[id] = (doc.data()?['name'] ?? id) as String;
    }
    final records = <AdminReviewRecord>[
      for (final doc in reviewSnap.docs)
        AdminReviewRecord(
          review: ReviewModel.fromFirestore(doc),
          productName:
              names[doc.reference.parent.parent?.id] ??
              (doc.data()['productId'] ?? '') as String,
        ),
    ];
    var filtered = records
      ..sort((a, b) => b.review.createdAt.compareTo(a.review.createdAt));
    final text = query.search.trim().toLowerCase();
    if (text.isNotEmpty) {
      filtered = filtered
          .where(
            (r) => _matchesAdminSearch(text, [
              r.productName,
              r.review.id,
              r.review.productId,
              r.review.userId,
              r.review.userName,
              r.review.comment,
            ]),
          )
          .toList();
    }
    if (query.hidden != null) {
      filtered = filtered
          .where((r) => r.review.isHidden == query.hidden)
          .toList();
    }
    return _slice(filtered, query.limit, query.cursor);
  }

  @override
  Future<void> setReviewHidden({
    required String productId,
    required String reviewId,
    required bool hidden,
  }) async {
    final productRef = _products.doc(productId);
    final reviewsRef = productRef.collection(AppConstants.colReviews);
    await reviewsRef.doc(reviewId).set({
      'isHidden': hidden,
    }, SetOptions(merge: true));
    final reviewSnap = await reviewsRef.get();
    final visible = reviewSnap.docs
        .map(ReviewModel.fromFirestore)
        .where((review) => !review.isHidden)
        .toList();
    final rating = visible.isEmpty
        ? 0.0
        : visible.fold<double>(0, (acc, r) => acc + r.rating) / visible.length;
    await productRef.set({
      'rating': (rating * 10).round() / 10,
      'reviewCount': visible.length,
    }, SetOptions(merge: true));
  }
}

AdminPage<T> _slice<T>(List<T> list, int limit, Object? cursor) {
  final start = cursor is int ? cursor : 0;
  final end = (start + limit).clamp(0, list.length);
  return AdminPage(
    items: list.sublist(start, end),
    cursor: end,
    hasMore: end < list.length,
  );
}

bool _matchesAdminSearch(String query, Iterable<Object?> values) {
  final normalizedQuery = _normalizeAdminSearch(query);
  if (normalizedQuery.isEmpty) return true;
  final text = values.map(_normalizeAdminSearch).join(' ');
  if (text.contains(normalizedQuery)) return true;

  final tokens = normalizedQuery
      .split(' ')
      .where((token) => token.isNotEmpty)
      .toList();
  return tokens.isNotEmpty && tokens.every(text.contains);
}

String _normalizeAdminSearch(Object? value) {
  final text = switch (value) {
    null => '',
    Iterable() => value.join(' '),
    Map() => [...value.keys, ...value.values].join(' '),
    _ => value.toString(),
  };
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}

ProductModel _copyProduct(
  ProductModel product, {
  bool? isActive,
  double? rating,
  int? reviewCount,
}) {
  return ProductModel(
    id: product.id,
    name: product.name,
    brand: product.brand,
    description: product.description,
    price: product.price,
    oldPrice: product.oldPrice,
    rating: rating ?? product.rating,
    reviewCount: reviewCount ?? product.reviewCount,
    imageLabel: product.imageLabel,
    imageUrl: product.imageUrl,
    images: product.images,
    categoryId: product.categoryId,
    categoryName: product.categoryName,
    stock: product.stock,
    isActive: isActive ?? product.isActive,
    specs: product.specs,
    variants: product.variants,
    compatibility: product.compatibility,
  );
}

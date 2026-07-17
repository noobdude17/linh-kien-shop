import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../product/providers/product_providers.dart';
import '../../product/providers/review_provider.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  if (AppConfig.firebaseEnabled) {
    return FirestoreAdminRepository(FirebaseFirestore.instance);
  }
  return MockAdminRepository();
});

final adminDashboardProvider = FutureProvider<AdminDashboardStats>((ref) {
  return ref.watch(adminRepositoryProvider).getDashboardStats();
});

final adminProductProvider = FutureProvider.family<ProductModel?, String>((
  ref,
  id,
) {
  return ref.watch(adminRepositoryProvider).getProduct(id);
});

final adminProductsProvider =
    FutureProvider.family<AdminPage<ProductModel>, AdminProductQuery>(
      (ref, query) => ref.watch(adminRepositoryProvider).getProducts(query),
    );

final adminOrdersProvider =
    FutureProvider.family<AdminPage<OrderModel>, AdminOrderQuery>(
      (ref, query) => ref.watch(adminRepositoryProvider).getOrders(query),
    );

final adminOrderProvider = FutureProvider.family<OrderModel?, String>((
  ref,
  id,
) {
  return ref.watch(adminRepositoryProvider).getOrder(id);
});

final adminUsersProvider =
    FutureProvider.family<AdminPage<UserModel>, AdminUserQuery>(
      (ref, query) => ref.watch(adminRepositoryProvider).getUsers(query),
    );

final adminReviewsProvider =
    FutureProvider.family<AdminPage<AdminReviewRecord>, AdminReviewQuery>(
      (ref, query) => ref.watch(adminRepositoryProvider).getReviews(query),
    );

void invalidateAdminData(WidgetRef ref) {
  ref
    ..invalidate(adminDashboardProvider)
    ..invalidate(adminProductsProvider)
    ..invalidate(adminOrdersProvider)
    ..invalidate(adminUsersProvider)
    ..invalidate(adminReviewsProvider)
    ..invalidate(featuredProductsProvider)
    ..invalidate(productsByCategoryProvider)
    ..invalidate(productDetailProvider)
    ..invalidate(searchProvider)
    ..invalidate(reviewProvider);
}

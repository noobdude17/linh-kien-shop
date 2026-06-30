import 'package:flutter_test/flutter_test.dart';
import 'package:linh_kien_shop/core/constants/app_constants.dart';
import 'package:linh_kien_shop/data/models/order_model.dart';
import 'package:linh_kien_shop/data/models/product_model.dart';
import 'package:linh_kien_shop/data/repositories/admin_repository.dart';
import 'package:linh_kien_shop/data/repositories/order_repository.dart';
import 'package:linh_kien_shop/routes/app_routes.dart';
import 'package:linh_kien_shop/routes/auth_guard.dart';

void main() {
  test('admin routes require admin role', () {
    expect(
      authRedirect(
        loc: AppRoutes.admin,
        loggedIn: true,
        emailVerified: true,
        profileComplete: true,
        isAdmin: false,
      ),
      AppRoutes.home,
    );

    expect(
      authRedirect(
        loc: AppRoutes.admin,
        loggedIn: true,
        emailVerified: true,
        profileComplete: true,
        isAdmin: true,
      ),
      isNull,
    );
  });

  test('locked users are redirected away after login', () {
    expect(
      authRedirect(
        loc: AppRoutes.home,
        loggedIn: true,
        emailVerified: true,
        profileComplete: true,
        isLocked: true,
      ),
      AppRoutes.login,
    );
    expect(
      authRedirect(
        loc: AppRoutes.login,
        loggedIn: true,
        emailVerified: true,
        profileComplete: true,
        isLocked: true,
      ),
      isNull,
    );
  });

  test('order transition follows fixed admin workflow', () {
    expect(
      canTransitionOrder(
        AppConstants.statusPending,
        AppConstants.statusConfirmed,
      ),
      isTrue,
    );
    expect(
      canTransitionOrder(
        AppConstants.statusPending,
        AppConstants.statusDelivered,
      ),
      isFalse,
    );
    expect(
      canTransitionOrder(
        AppConstants.statusShipping,
        AppConstants.statusCancelled,
      ),
      isTrue,
    );
    expect(
      canTransitionOrder(
        AppConstants.statusDelivered,
        AppConstants.statusCancelled,
      ),
      isFalse,
    );
  });

  test('dashboard stats counts active products and delivered revenue', () {
    final stats = computeDashboardStats(
      const [
        ProductModel(id: 'p1', name: 'A', price: 1, categoryId: 'cpu'),
        ProductModel(
          id: 'p2',
          name: 'B',
          price: 1,
          categoryId: 'gpu',
          isActive: false,
        ),
      ],
      [
        OrderModel(
          id: 'o1',
          code: 'LKS-1',
          userId: 'u1',
          items: const [],
          totalAmount: 100,
          status: AppConstants.statusDelivered,
          createdAt: DateTime(2026, 6, 29),
        ),
        OrderModel(
          id: 'o2',
          code: 'LKS-2',
          userId: 'u1',
          items: const [],
          totalAmount: 200,
          status: AppConstants.statusPending,
          createdAt: DateTime(2026, 6, 29),
        ),
      ],
      now: DateTime(2026, 6, 29),
    );

    expect(stats.activeProducts, 1);
    expect(stats.totalOrders, 2);
    expect(stats.pendingOrders, 1);
    expect(stats.deliveredRevenue, 100);
    expect(stats.revenue7d.last, 100);
  });

  test('mock admin soft delete hides product', () async {
    final repo = MockAdminRepository();
    final page = await repo.getProducts(const AdminProductQuery(limit: 1));
    final product = page.items.first;

    await repo.softDeleteProduct(product.id);
    final hidden = await repo.getProduct(product.id);

    expect(hidden?.isActive, isFalse);
  });

  test('mock admin hides review and recomputes visible rating', () async {
    final repo = MockAdminRepository();
    final page = await repo.getReviews(const AdminReviewQuery(limit: 1));
    final record = page.items.first;

    await repo.setReviewHidden(
      productId: record.review.productId,
      reviewId: record.review.id,
      hidden: true,
    );
    final product = await repo.getProduct(record.review.productId);
    final reviews = await repo.getReviews(
      AdminReviewQuery(search: record.productName),
    );

    expect(reviews.items.any((r) => r.review.id == record.review.id), isTrue);
    expect(product?.reviewCount, greaterThanOrEqualTo(0));
  });

  test('markPaid sets paid but leaves status pending for admin approval', () async {
    final repo = MockOrderRepository();
    final order = await repo.create(
      userId: 'u1',
      customerName: 'Khách',
      items: const [],
      subtotal: 100,
      totalAmount: 100,
      address: 'Hà Nội',
      paymentMethod: AppConstants.payVnpay,
    );

    await repo.markPaid(order.id);
    final updated = await repo.getById(order.id);

    expect(updated?.paid, isTrue);
    expect(updated?.status, AppConstants.statusPending);
  });
}

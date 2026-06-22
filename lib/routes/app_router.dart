import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_back_scope.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/categories_screen.dart';
import '../features/home/screens/search_screen.dart';
import '../features/home/screens/search_results_screen.dart';
import '../features/home/screens/empty_results_screen.dart';
import '../features/product/screens/product_list_screen.dart';
import '../features/product/screens/product_detail_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/order/screens/checkout_screen.dart';
import '../features/order/screens/vnpay_gateway_screen.dart';
import '../features/order/screens/payment_processing_screen.dart';
import '../features/order/screens/order_success_screen.dart';
import '../features/order/screens/order_history_screen.dart';
import '../features/order/screens/order_detail_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/address_list_screen.dart';
import '../features/profile/screens/add_address_screen.dart';
import '../features/profile/screens/wishlist_screen.dart';
import '../features/profile/screens/wishlist_empty_screen.dart';
import '../features/profile/screens/notifications_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/admin_product_list_screen.dart';
import '../features/admin/screens/admin_product_edit_screen.dart';
import '../features/admin/screens/admin_order_management_screen.dart';
import '../features/admin/screens/admin_order_detail_screen.dart';
import 'app_routes.dart';

/// Các route công khai (không cần đăng nhập).
const _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgot,
};

Widget _withBackScope(Widget child) => AppBackScope(child: child);

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges()),
    redirect: (context, state) {
      final loggedIn = authRepo.currentUser != null;
      final loc = state.matchedLocation;

      // Splash & onboarding tự điều hướng, không chặn.
      if (loc == AppRoutes.splash || loc == AppRoutes.onboarding) return null;

      // Chưa đăng nhập mà vào route cần auth → về Login.
      if (!loggedIn && !_publicRoutes.contains(loc)) return AppRoutes.login;

      // Đã đăng nhập mà còn ở Login/Register → về Home.
      if (loggedIn && (loc == AppRoutes.login || loc == AppRoutes.register)) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      // A · Auth
      GoRoute(path: AppRoutes.splash, builder: (_, _) => _withBackScope(const SplashScreen())),
      GoRoute(path: AppRoutes.onboarding, builder: (_, _) => _withBackScope(const OnboardingScreen())),
      GoRoute(path: AppRoutes.login, builder: (_, _) => _withBackScope(const LoginScreen())),
      GoRoute(path: AppRoutes.register, builder: (_, _) => _withBackScope(const RegisterScreen())),
      GoRoute(path: AppRoutes.forgot, builder: (_, _) => _withBackScope(const ForgotPasswordScreen())),

      // B · Home & Browse
      GoRoute(path: AppRoutes.home, builder: (_, _) => _withBackScope(const HomeScreen())),
      GoRoute(path: AppRoutes.categories, builder: (_, _) => _withBackScope(const CategoriesScreen())),
      GoRoute(path: AppRoutes.search, builder: (_, _) => _withBackScope(const SearchScreen())),
      GoRoute(
        path: AppRoutes.list,
        builder: (_, state) => _withBackScope(
          ProductListScreen(categoryId: state.uri.queryParameters['categoryId']),
        ),
      ),
      GoRoute(path: AppRoutes.results, builder: (_, _) => _withBackScope(const SearchResultsScreen())),
      GoRoute(path: AppRoutes.empty, builder: (_, _) => _withBackScope(const EmptyResultsScreen())),

      // C · Product Detail
      GoRoute(
        path: '${AppRoutes.detail}/:id',
        builder: (_, state) => _withBackScope(
          ProductDetailScreen(productId: state.pathParameters['id']!),
        ),
      ),

      // D · Cart & Checkout
      GoRoute(path: AppRoutes.cart, builder: (_, _) => _withBackScope(const CartScreen())),
      GoRoute(path: AppRoutes.checkout, builder: (_, _) => _withBackScope(const CheckoutScreen())),
      GoRoute(path: AppRoutes.vnpay, builder: (_, _) => _withBackScope(const VnpayGatewayScreen())),
      GoRoute(path: AppRoutes.processing, builder: (_, _) => _withBackScope(const PaymentProcessingScreen())),
      GoRoute(path: AppRoutes.success, builder: (_, _) => _withBackScope(const OrderSuccessScreen())),

      // E · Account & Orders
      GoRoute(path: AppRoutes.profile, builder: (_, _) => _withBackScope(const ProfileScreen())),
      GoRoute(path: AppRoutes.editProfile, builder: (_, _) => _withBackScope(const EditProfileScreen())),
      GoRoute(path: AppRoutes.orders, builder: (_, _) => _withBackScope(const OrderHistoryScreen())),
      GoRoute(
        path: '${AppRoutes.orderDetail}/:id',
        builder: (_, state) => _withBackScope(
          OrderDetailScreen(orderId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: AppRoutes.addresses, builder: (_, _) => _withBackScope(const AddressListScreen())),
      GoRoute(path: AppRoutes.addAddress, builder: (_, _) => _withBackScope(const AddAddressScreen())),
      GoRoute(path: AppRoutes.wishlist, builder: (_, _) => _withBackScope(const WishlistScreen())),
      GoRoute(path: AppRoutes.wishlistEmpty, builder: (_, _) => _withBackScope(const WishlistEmptyScreen())),
      GoRoute(path: AppRoutes.notifications, builder: (_, _) => _withBackScope(const NotificationsScreen())),

      // F · Admin
      GoRoute(path: AppRoutes.admin, builder: (_, _) => _withBackScope(const AdminDashboardScreen())),
      GoRoute(path: AppRoutes.adminProducts, builder: (_, _) => _withBackScope(const AdminProductListScreen())),
      GoRoute(path: AppRoutes.adminProductEdit, builder: (_, _) => _withBackScope(const AdminProductEditScreen())),
      GoRoute(path: AppRoutes.adminOrders, builder: (_, _) => _withBackScope(const AdminOrderManagementScreen())),
      GoRoute(path: AppRoutes.adminOrderDetail, builder: (_, _) => _withBackScope(const AdminOrderDetailScreen())),
    ],
  );
});

/// Cầu nối Stream → Listenable để go_router tự đánh giá lại redirect
/// mỗi khi trạng thái đăng nhập thay đổi.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

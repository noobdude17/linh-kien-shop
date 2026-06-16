import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // A · Auth
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: AppRoutes.forgot, builder: (_, _) => const ForgotPasswordScreen()),

      // B · Home & Browse
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(path: AppRoutes.categories, builder: (_, _) => const CategoriesScreen()),
      GoRoute(path: AppRoutes.search, builder: (_, _) => const SearchScreen()),
      GoRoute(
        path: AppRoutes.list,
        builder: (_, state) => ProductListScreen(categoryId: state.uri.queryParameters['categoryId']),
      ),
      GoRoute(path: AppRoutes.results, builder: (_, _) => const SearchResultsScreen()),
      GoRoute(path: AppRoutes.empty, builder: (_, _) => const EmptyResultsScreen()),

      // C · Product Detail
      GoRoute(
        path: '${AppRoutes.detail}/:id',
        builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
      ),

      // D · Cart & Checkout
      GoRoute(path: AppRoutes.cart, builder: (_, _) => const CartScreen()),
      GoRoute(path: AppRoutes.checkout, builder: (_, _) => const CheckoutScreen()),
      GoRoute(path: AppRoutes.vnpay, builder: (_, _) => const VnpayGatewayScreen()),
      GoRoute(path: AppRoutes.processing, builder: (_, _) => const PaymentProcessingScreen()),
      GoRoute(path: AppRoutes.success, builder: (_, _) => const OrderSuccessScreen()),

      // E · Account & Orders
      GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileScreen()),
      GoRoute(path: AppRoutes.editProfile, builder: (_, _) => const EditProfileScreen()),
      GoRoute(path: AppRoutes.orders, builder: (_, _) => const OrderHistoryScreen()),
      GoRoute(
        path: '${AppRoutes.orderDetail}/:id',
        builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(path: AppRoutes.addresses, builder: (_, _) => const AddressListScreen()),
      GoRoute(path: AppRoutes.addAddress, builder: (_, _) => const AddAddressScreen()),
      GoRoute(path: AppRoutes.wishlist, builder: (_, _) => const WishlistScreen()),
      GoRoute(path: AppRoutes.wishlistEmpty, builder: (_, _) => const WishlistEmptyScreen()),
      GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationsScreen()),

      // F · Admin
      GoRoute(path: AppRoutes.admin, builder: (_, _) => const AdminDashboardScreen()),
      GoRoute(path: AppRoutes.adminProducts, builder: (_, _) => const AdminProductListScreen()),
      GoRoute(path: AppRoutes.adminProductEdit, builder: (_, _) => const AdminProductEditScreen()),
      GoRoute(path: AppRoutes.adminOrders, builder: (_, _) => const AdminOrderManagementScreen()),
      GoRoute(path: AppRoutes.adminOrderDetail, builder: (_, _) => const AdminOrderDetailScreen()),
    ],
  );
});

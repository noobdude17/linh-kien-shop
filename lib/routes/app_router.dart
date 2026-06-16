import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/product/screens/product_list_screen.dart';
import '../features/product/screens/product_detail_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/order/screens/checkout_screen.dart';
import '../features/order/screens/order_history_screen.dart';
import '../features/order/screens/order_detail_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/admin_product_screen.dart';
import '../features/admin/screens/admin_order_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/products',
            builder: (_, state) => ProductListScreen(
              categoryId: state.uri.queryParameters['categoryId'],
            ),
          ),
          GoRoute(
            path: '/products/:id',
            builder: (_, state) =>
                ProductDetailScreen(productId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
          GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
          GoRoute(
            path: '/orders',
            builder: (_, __) => const OrderHistoryScreen(),
          ),
          GoRoute(
            path: '/orders/:id',
            builder: (_, state) =>
                OrderDetailScreen(orderId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
            path: '/admin',
            builder: (_, __) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/products',
            builder: (_, __) => const AdminProductScreen(),
          ),
          GoRoute(
            path: '/admin/orders',
            builder: (_, __) => const AdminOrderScreen(),
          ),
        ],
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

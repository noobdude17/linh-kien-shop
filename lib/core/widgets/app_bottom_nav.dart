import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/cart/providers/cart_provider.dart';
import '../../routes/app_routes.dart';
import '../theme/app_colors.dart';

/// Thanh điều hướng dưới: Trang chủ / Danh mục / Lắp đặt / Giỏ hàng / Tài khoản.
/// [currentIndex]: 0..4. Badge giỏ hàng đọc trực tiếp từ cartProvider.
class AppBottomNav extends ConsumerWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  static const _routes = [
    AppRoutes.home,
    AppRoutes.categories,
    AppRoutes.partPicker,
    AppRoutes.cart,
    AppRoutes.profile,
  ];

  void _onTap(BuildContext context, int i) {
    if (i == currentIndex) return;
    context.go(_routes[i]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 11),
          child: Row(
            children: [
              _item(context, 0, Icons.home_rounded, 'Trang chủ'),
              _item(context, 1, Icons.grid_view_rounded, 'Danh mục'),
              _item(context, 2, Icons.build_circle_outlined, 'Lắp đặt'),
              _item(
                context,
                3,
                Icons.shopping_cart_rounded,
                'Giỏ hàng',
                badge: cartCount,
              ),
              _item(context, 4, Icons.person_rounded, 'Tài khoản'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    int i,
    IconData icon,
    String label, {
    int badge = 0,
  }) {
    final active = i == currentIndex;
    final color = active ? AppColors.primary : AppColors.textTertiary;
    return Expanded(
      child: InkWell(
        onTap: () => _onTap(context, i),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 21, color: color),
                if (badge > 0)
                  Positioned(
                    top: -5,
                    right: -8,
                    // Nảy nhẹ mỗi khi số lượng đổi (key đổi → chạy lại tween).
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(badge),
                      tween: Tween(begin: 0.6, end: 1.0),
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.elasticOut,
                      builder: (_, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

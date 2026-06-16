import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_routes.dart';
import '../theme/app_colors.dart';

/// Thanh điều hướng dưới: Trang chủ / Danh mục / Giỏ hàng / Tài khoản.
/// [currentIndex]: 0..3. [cartCount] hiển thị badge cam trên tab Giỏ hàng.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final int cartCount;

  const AppBottomNav({super.key, required this.currentIndex, this.cartCount = 0});

  static const _routes = [
    AppRoutes.home,
    AppRoutes.categories,
    AppRoutes.cart,
    AppRoutes.profile,
  ];

  void _onTap(BuildContext context, int i) {
    if (i == currentIndex) return;
    context.go(_routes[i]);
  }

  @override
  Widget build(BuildContext context) {
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
              _item(context, 2, Icons.shopping_cart_rounded, 'Giỏ hàng',
                  badge: cartCount),
              _item(context, 3, Icons.person_rounded, 'Tài khoản'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int i, IconData icon, String label,
      {int badge = 0}) {
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
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
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
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
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

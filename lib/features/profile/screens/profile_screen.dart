import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../routes/app_routes.dart';
import '../../../data/models/user_model.dart';
import '../../auth/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return user != null ? _profileView(context, ref, user) : _loginView(context);
  }

  Scaffold _loginView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.surface,
                child: Icon(Icons.person_outline, size: 40, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              const Text('Đăng nhập để tiếp tục',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'Đăng nhập để xem đơn hàng, địa chỉ, sản phẩm yêu thích và thanh toán.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Đăng nhập', onPressed: () => context.go(AppRoutes.login)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go(AppRoutes.register),
                child: const Text('Chưa có tài khoản? Đăng ký'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Scaffold _profileView(BuildContext context, WidgetRef ref, UserModel user) {
    return Scaffold(
      body: Column(
        children: [
          _header(context, user.name, user.email,
              () => ref.read(authRepositoryProvider).signOut()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _menuCard([
                  _tile(context, Icons.inventory_2_outlined, 'Đơn hàng của tôi', AppRoutes.orders),
                  _tile(context, Icons.location_on_outlined, 'Địa chỉ giao hàng', AppRoutes.addresses),
                  _tile(context, Icons.favorite_border, 'Sản phẩm yêu thích', AppRoutes.wishlist),
                  _tile(context, Icons.notifications_outlined, 'Thông báo', AppRoutes.notifications),
                  _tile(context, Icons.credit_card, 'Phương thức thanh toán', null),
                  _tile(context, Icons.settings_outlined, 'Cài đặt', null),
                  _tile(context, Icons.help_outline, 'Trợ giúp & Hỗ trợ', null),
                ]),
                const SizedBox(height: 12),
                _menuCard([
                  _tile(context, Icons.admin_panel_settings_outlined, 'Quản trị (Admin)', AppRoutes.admin, color: AppColors.adminAccent),
                ]),
                const SizedBox(height: 12),
                _menuCard([
                  _tile(context, Icons.logout, 'Đăng xuất', null,
                      color: AppColors.error,
                      onTap: () => ref.read(authRepositoryProvider).signOut()),
                ]),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  Widget _header(BuildContext context, String? name, String? email, VoidCallback onLogout) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tài khoản', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const CircleAvatar(radius: 30, backgroundColor: AppColors.inputFill, child: Icon(Icons.person, color: AppColors.bodyText, size: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name?.isNotEmpty == true ? name! : 'Khách',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                          Text(email ?? '',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        // Theme dùng minimumSize.fromHeight (width=∞) → vỡ layout trong Row. Ép về kích thước theo nội dung.
                        minimumSize: const Size(64, 40),
                      ),
                      onPressed: () => context.go(AppRoutes.editProfile),
                      child: const Text('Chỉnh sửa'),
                    ),
                    IconButton(
                      tooltip: 'Đăng xuất',
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      onPressed: onLogout,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _menuCard(List<Widget> children) => Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 1)),
        ]),
        child: Column(children: children),
      );

  Widget _tile(BuildContext context, IconData icon, String label, String? route,
          {Color color = AppColors.textPrimary, VoidCallback? onTap}) =>
      ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(color: color, fontSize: 14)),
        trailing: (route != null || onTap != null)
            ? const Icon(Icons.chevron_right, color: AppColors.textTertiary)
            : null,
        onTap: onTap ?? (route != null ? () => context.go(route) : null),
      );
}

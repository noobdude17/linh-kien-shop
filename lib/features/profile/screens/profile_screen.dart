import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Đơn hàng của tôi'),
            onTap: () => context.go('/orders'),
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Quản trị (Admin)'),
            onTap: () => context.go('/admin'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            onTap: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}

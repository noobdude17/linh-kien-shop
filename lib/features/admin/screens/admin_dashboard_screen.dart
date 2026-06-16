import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _AdminCard(
            icon: Icons.inventory,
            label: 'Sản phẩm',
            onTap: () => context.go('/admin/products'),
          ),
          _AdminCard(
            icon: Icons.receipt_long,
            label: 'Đơn hàng',
            onTap: () => context.go('/admin/orders'),
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AdminCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

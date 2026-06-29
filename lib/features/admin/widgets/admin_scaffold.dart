import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

/// Khung chung cho admin console: header gradient tím + nền tím nhạt, để khu
/// quản trị trông tách bạch hẳn với storefront. Mọi màn admin dùng cái này.
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.title,
    required this.backRoute,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final String backRoute;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.adminPrimary,
        elevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.adminHeaderGradient),
        ),
        leading: BackButton(onPressed: () => context.go(backRoute)),
        title: Text(title),
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Trạng thái rỗng nhất quán.
class AdminEmpty extends StatelessWidget {
  const AdminEmpty({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon ?? Icons.inbox_outlined, size: 44, color: AppColors.adminAccent),
        const SizedBox(height: 10),
        Text(message, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    ),
  );
}

/// Trạng thái lỗi + nút thử lại, nhất quán mọi màn.
class AdminError extends StatelessWidget {
  const AdminError({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 44, color: AppColors.error),
        const SizedBox(height: 10),
        Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}

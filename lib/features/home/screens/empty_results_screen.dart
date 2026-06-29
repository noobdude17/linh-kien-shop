import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../routes/app_routes.dart';

class EmptyResultsScreen extends StatelessWidget {
  const EmptyResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
        title: const Text('Kết quả tìm kiếm'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('🔍', style: TextStyle(fontSize: 52)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Không tìm thấy sản phẩm',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thử từ khóa khác hoặc kiểm tra lại chính tả',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Thử từ khóa khác',
                onPressed: () => context.go(AppRoutes.search),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

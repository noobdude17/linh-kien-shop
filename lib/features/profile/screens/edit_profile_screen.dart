import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../routes/app_routes.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
        title: const Text('Chỉnh sửa thông tin'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: Stack(
              children: [
                const CircleAvatar(radius: 44, backgroundColor: AppColors.background, child: Text('👤', style: TextStyle(fontSize: 40))),
                Positioned(
                  bottom: 0, right: 0,
                  child: CircleAvatar(radius: 14, backgroundColor: AppColors.primary,
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _field('Họ và tên', 'Nguyễn Văn An'),
          _field('Email', 'an.nguyen@email.com', disabled: true),
          _field('Số điện thoại', '0912 345 678'),
          Row(
            children: [
              Expanded(child: _field('Ngày sinh', '15/03/1995')),
              const SizedBox(width: 12),
              Expanded(child: _field('Giới tính', 'Nam ▾')),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Lưu thay đổi', onPressed: () => context.go(AppRoutes.profile)),
        ],
      ),
    );
  }

  Widget _field(String label, String value, {bool disabled = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              enabled: !disabled,
              controller: TextEditingController(text: value),
              decoration: InputDecoration(
                suffixIcon: disabled ? const Icon(Icons.lock_outline, size: 18) : null,
                fillColor: disabled ? AppColors.background : AppColors.surface,
              ),
            ),
          ],
        ),
      );
}

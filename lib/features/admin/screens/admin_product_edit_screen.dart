import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../routes/app_routes.dart';

class AdminProductEditScreen extends StatefulWidget {
  const AdminProductEditScreen({super.key});

  @override
  State<AdminProductEditScreen> createState() => _AdminProductEditScreenState();
}

class _AdminProductEditScreenState extends State<AdminProductEditScreen> {
  bool _active = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.accent,
        leading: BackButton(onPressed: () => context.go(AppRoutes.adminProducts)),
        title: const Text('Thêm sản phẩm'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent, width: 1.5, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Text('📷', style: TextStyle(fontSize: 24)), Text('Thêm ảnh', style: TextStyle(fontSize: 11, color: AppColors.accent))],
                ),
              ),
              const SizedBox(width: 12),
              const ImagePlaceholder(label: 'IMG', height: 88, radius: 8),
            ],
          ),
          const SizedBox(height: 20),
          _field('Tên sản phẩm'),
          _field('Danh mục', value: 'Card đồ họa (GPU) ▾'),
          Row(
            children: [
              Expanded(child: _field('Giá')),
              const SizedBox(width: 8),
              Expanded(child: _field('Giá KM')),
              const SizedBox(width: 8),
              Expanded(child: _field('Tồn kho')),
            ],
          ),
          _field('Mô tả', maxLines: 3),
          _field('Thông số kỹ thuật', maxLines: 3),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Đang bán', style: TextStyle(fontSize: 14)),
            value: _active,
            activeThumbColor: AppColors.success,
            onChanged: (v) => setState(() => _active = v),
          ),
          const SizedBox(height: 8),
          PrimaryButton(label: 'Lưu sản phẩm', onPressed: () => context.go(AppRoutes.adminProducts)),
        ],
      ),
    );
  }

  Widget _field(String label, {String? value, int maxLines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(maxLines: maxLines, controller: value != null ? TextEditingController(text: value) : null),
          ],
        ),
      );
}

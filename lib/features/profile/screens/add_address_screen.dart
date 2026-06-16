import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../routes/app_routes.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  bool _isDefault = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.addresses)),
        title: const Text('Thêm địa chỉ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _field('Họ tên người nhận'),
          _field('Số điện thoại'),
          Row(
            children: [
              Expanded(child: _field('Tỉnh/Thành', value: 'TP.HCM ▾')),
              const SizedBox(width: 12),
              Expanded(child: _field('Quận/Huyện', value: 'Quận 1 ▾')),
            ],
          ),
          _field('Phường/Xã', value: 'Phường Bến Nghé ▾'),
          _field('Địa chỉ cụ thể', maxLines: 2),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Đặt làm địa chỉ mặc định', style: TextStyle(fontSize: 14)),
            value: _isDefault,
            activeThumbColor: AppColors.primary,
            onChanged: (v) => setState(() => _isDefault = v),
          ),
          const SizedBox(height: 8),
          PrimaryButton(label: 'Lưu địa chỉ', onPressed: () => context.go(AppRoutes.addresses)),
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
            TextField(
              maxLines: maxLines,
              controller: value != null ? TextEditingController(text: value) : null,
            ),
          ],
        ),
      );
}

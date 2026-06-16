import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/address_model.dart';
import '../../../routes/app_routes.dart';

class AddressListScreen extends StatelessWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
        title: const Text('Địa chỉ của tôi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        children: MockData.addresses.map((a) => _addressCard(context, a)).toList(),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: PrimaryButton(label: '+ Thêm địa chỉ mới', onPressed: () => context.go(AppRoutes.addAddress)),
      ),
    );
  }

  Widget _addressCard(BuildContext context, AddressModel a) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(AppDimens.cardPaddingLg),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppDimens.brCard, boxShadow: AppDimens.cardShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${a.name} · ${a.phone}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                if (a.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Mặc định', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(a.detail, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const Divider(height: 20),
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.go(AppRoutes.addAddress),
                  child: const Text('✏️ Sửa', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
                const SizedBox(width: 20),
                const Text('🗑️ Xóa', style: TextStyle(color: AppColors.error, fontSize: 13)),
              ],
            ),
          ],
        ),
      );
}

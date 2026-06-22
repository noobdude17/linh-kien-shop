import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../data/models/address_model.dart';
import '../../../routes/app_routes.dart';
import '../../auth/providers/auth_providers.dart';

class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    // Địa chỉ giao hàng mặc định = ảnh chụp lúc tạo tài khoản (không đổi khi sửa
    // hồ sơ). Tài khoản cũ/mock chưa có thì dựng tạm từ hồ sơ.
    final fallback = (user != null && (user.address?.trim().isNotEmpty ?? false))
        ? AddressModel(
            id: 'default',
            name: user.name,
            phone: user.phone ?? '',
            detail: user.address!,
            isDefault: true)
        : null;
    final def = user?.defaultAddress ?? fallback;
    final addresses = <AddressModel>[?def];
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
        title: const Text('Địa chỉ của tôi'),
      ),
      body: addresses.isEmpty
          ? const Center(child: Text('Chưa có địa chỉ'))
          : ListView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              children: addresses.map((a) => _addressCard(context, a)).toList(),
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
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Mặc định', style: TextStyle(color: AppColors.accentBlue, fontSize: 10, fontWeight: FontWeight.w700)),
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

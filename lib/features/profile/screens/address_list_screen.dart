import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../data/models/address_model.dart';
import '../../../routes/app_routes.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/address_providers.dart';

class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
        title: const Text('Địa chỉ của tôi'),
      ),
      body: addresses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi tải địa chỉ: $e')),
        data: (list) => ListView(
          padding: const EdgeInsets.all(AppDimens.screenPadding),
          children: [
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('Chưa có địa chỉ')),
              ),
            ...list.map((a) => _addressCard(context, ref, a)),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: PrimaryButton(
          label: '+ Thêm địa chỉ mới',
          onPressed: () => context.go(AppRoutes.addAddress),
        ),
      ),
    );
  }

  Widget _addressCard(BuildContext context, WidgetRef ref, AddressModel a) =>
      GestureDetector(
        onTap: a.isDefault ? null : () => _setDefault(context, ref, a),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(AppDimens.cardPaddingLg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimens.brCard,
            boxShadow: AppDimens.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width - 96,
                    ),
                    child: Text(
                      '${a.name} · ${a.phone}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (a.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlueBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Mặc định',
                        style: TextStyle(
                          color: AppColors.accentBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                a.detail,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const Divider(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.addAddress, extra: a),
                    child: const Text(
                      '✏️ Sửa',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _confirmDelete(context, ref, a),
                    child: const Text(
                      '🗑️ Xóa',
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                  if (!a.isDefault)
                    Text(
                      'Đặt mặc định',
                      style: TextStyle(
                        color: AppColors.accentBlue.withValues(alpha: .9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );

  Future<void> _setDefault(
    BuildContext context,
    WidgetRef ref,
    AddressModel a,
  ) async {
    final uid = ref.read(currentUserProvider)?.id;
    if (uid == null) return;
    await ref.read(addressRepositoryProvider).setDefault(uid, a.id);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AddressModel a,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa địa chỉ?'),
        content: Text('${a.name} · ${a.detail}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final uid = ref.read(currentUserProvider)?.id;
    if (uid == null) return;
    await ref.read(addressRepositoryProvider).delete(uid, a.id);
  }
}

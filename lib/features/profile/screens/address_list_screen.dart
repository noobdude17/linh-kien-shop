import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
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
            // Bảng debug (chỉ hiện ở bản debug) để soi dữ liệu đã lưu — step 4.
            if (kDebugMode)
              _DebugPanel(list: list, uid: ref.watch(currentUserProvider)?.id),
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
        // Chạm vào thẻ không phải mặc định → đặt làm mặc định.
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
              Row(
                children: [
                  Text(
                    '${a.name} · ${a.phone}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
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
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.addAddress, extra: a),
                    child: const Text(
                      '✏️ Sửa',
                      style: TextStyle(color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => _confirmDelete(context, ref, a),
                    child: const Text(
                      '🗑️ Xóa',
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                  if (!a.isDefault) ...[
                    const Spacer(),
                    Text(
                      'Đặt mặc định',
                      style: TextStyle(
                        color: AppColors.accentBlue.withValues(alpha: .9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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

/// Bảng kiểm tra trực quan cho step 4 (chỉ bản debug). Hiện:
/// - backend đang dùng (Firebase vs Mock),
/// - từng địa chỉ trong subcollection kèm lat/lng/isDefault,
/// - mirror `users/{uid}.defaultAddress` ĐỌC TRỰC TIẾP từ Firestore (không lấy
///   từ currentUser vì bản cache có thể cũ) để đối chiếu khớp địa chỉ mặc định.
/// Mở rộng/thu lại để đọc lại mirror sau khi đổi mặc định.
class _DebugPanel extends StatelessWidget {
  final List<AddressModel> list;
  final String? uid;
  const _DebugPanel({required this.list, required this.uid});

  static const _mono = TextStyle(fontFamily: 'monospace', fontSize: 11);

  @override
  Widget build(BuildContext context) {
    final fb = AppConfig.firebaseEnabled;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.accentSoftBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentSoftBorder),
      ),
      child: ExpansionTile(
        title: const Text(
          '🐞 DEBUG · dữ liệu địa chỉ đã lưu (step 4)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        subtitle: Text(
          'Backend: ${fb ? "Firebase (Firestore)" : "Mock (in-memory, không lưu Firebase)"}',
          style: const TextStyle(fontSize: 11),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'users/{uid}/addresses:',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          if (list.isEmpty) const Text('— trống —', style: _mono),
          ...list.map(
            (a) => Text(
              '• id=${a.id} default=${a.isDefault} lat=${a.latitude} lng=${a.longitude}',
              style: _mono,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Mirror users/{uid}.defaultAddress:',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          if (!fb)
            const Text('— Mock: không ghi Firebase —', style: _mono)
          else if (uid == null)
            const Text('— chưa đăng nhập —', style: _mono)
          else
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection(AppConstants.colUsers)
                  .doc(uid)
                  .get(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Text('đang tải…', style: _mono);
                }
                final def = snap.data!.data()?['defaultAddress'];
                if (def is! Map) {
                  return const Text('— chưa có mirror —', style: _mono);
                }
                return Text(
                  'detail=${def['detail']}\nlat=${def['latitude']} lng=${def['longitude']} default=${def['isDefault']}',
                  style: _mono,
                );
              },
            ),
        ],
      ),
    );
  }
}

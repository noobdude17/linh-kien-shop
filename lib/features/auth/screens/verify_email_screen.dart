import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../routes/app_routes.dart';
import '../providers/auth_providers.dart';

/// Cổng xác nhận email — bắt buộc với tài khoản đăng ký bằng email.
/// Firebase gửi LIÊN KẾT xác nhận; người dùng bấm liên kết rồi quay lại bấm
/// "Tôi đã xác nhận". Router tự cho qua khi emailVerified = true.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _checking = false;
  bool _resending = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      await ref.read(authRepositoryProvider).reloadUser();
      // Đã xác nhận → router tự chuyển Home. Chưa thì báo cho người dùng.
      final u = ref.read(authRepositoryProvider).currentUser;
      if (mounted && (u == null || !u.emailVerified)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa thấy xác nhận. Mở email và bấm liên kết trước nhé.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi lại liên kết xác nhận.')),
        );
      }
    } catch (e) {
      final tooMany = e.toString().contains('too-many-requests');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gửi lại thất bại: ${tooMany ? 'thử lại sau ít phút' : 'vui lòng thử lại'}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(currentUserProvider)?.email ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận email'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('✉️', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 24),
            Text(
              'Đã gửi liên kết xác nhận tới\n$email',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mở email, bấm vào liên kết, rồi quay lại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            _checking
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  )
                : PrimaryButton(label: 'Tôi đã xác nhận', onPressed: _check),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _resending ? null : _resend,
              child: Text(_resending ? 'Đang gửi...' : 'Gửi lại liên kết'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go(AppRoutes.login);
              },
              child: const Text('Dùng tài khoản khác'),
            ),
          ],
        ),
      ),
    );
  }
}

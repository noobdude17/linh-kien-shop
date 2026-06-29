import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../routes/app_routes.dart';
import '../providers/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email không hợp lệ')));
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gửi thất bại: ${_friendly(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        leading: BackButton(onPressed: () => context.go(AppRoutes.login)),
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
              child: Text(
                _sent ? '📬' : '🔑',
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 24),
            if (_sent) ...[
              Text(
                'Đã gửi liên kết đặt lại mật khẩu tới ${_email.text.trim()}.\n'
                'Mở email và làm theo hướng dẫn để đặt mật khẩu mới.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Về đăng nhập',
                onPressed: () => context.go(AppRoutes.login),
              ),
            ] else ...[
              const Text(
                'Nhập email để nhận liên kết đặt lại mật khẩu của bạn',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 20),
              _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    )
                  : PrimaryButton(label: 'Gửi liên kết', onPressed: _send),
            ],
          ],
        ),
      ),
    );
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('user-not-found')) return 'Email chưa được đăng ký';
    if (s.contains('invalid-email')) return 'Email không hợp lệ';
    if (s.contains('network')) return 'Lỗi mạng, kiểm tra kết nối';
    if (s.contains('too-many-requests')) return 'Thử lại sau ít phút';
    return 'Vui lòng thử lại';
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../routes/app_routes.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo tài khoản'),
        leading: BackButton(onPressed: () => context.go(AppRoutes.login)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const _Field(hint: 'Họ và tên', icon: Icons.person_outline),
            const _Field(hint: 'Email', icon: Icons.email_outlined),
            const _Field(hint: 'Số điện thoại', icon: Icons.phone_outlined),
            const _Field(hint: 'Mật khẩu', icon: Icons.lock_outline, obscure: true),
            const _Field(hint: 'Nhập lại mật khẩu', icon: Icons.lock_outline, obscure: true),
            Row(
              children: [
                Checkbox(value: true, onChanged: (_) {}),
                const Expanded(
                  child: Text('Tôi đồng ý với điều khoản sử dụng và chính sách bảo mật',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            PrimaryButton(label: 'Đăng ký', onPressed: () => context.go(AppRoutes.home)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Đã có tài khoản? '),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.login),
                  child: const Text('Đăng nhập',
                      style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool obscure;
  const _Field({required this.hint, required this.icon, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        obscureText: obscure,
        decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
      ),
    );
  }
}

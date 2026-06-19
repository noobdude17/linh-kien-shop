import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../routes/app_routes.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _email.text,
            password: _password.text,
          );
      // Đăng nhập xong → router tự redirect sang Home.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng nhập thất bại: ${_friendly(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text('⚡', style: TextStyle(fontSize: 48)),
                const Text('Linh Kiện Shop',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
                const SizedBox(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Đăng nhập', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.forgot),
                    child: const Text('Quên mật khẩu?'),
                  ),
                ),
                const SizedBox(height: 8),
                _loading
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())
                    : PrimaryButton(label: 'Đăng nhập', onPressed: _submit),
                const SizedBox(height: 20),
                Row(children: const [
                  Expanded(child: Divider()),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('hoặc')),
                  Expanded(child: Divider()),
                ]),
                const SizedBox(height: 20),
                AppOutlinedButton(
                  label: 'Tiếp tục với Google',
                  icon: Icons.g_mobiledata,
                  onPressed: _loading ? null : _submit, // TODO: tích hợp Google Sign-in thật
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chưa có tài khoản? '),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.register),
                      child: const Text('Đăng ký',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('user-not-found')) return 'Tài khoản không tồn tại';
    if (s.contains('wrong-password') || s.contains('invalid-credential')) return 'Sai mật khẩu';
    return 'Vui lòng thử lại';
  }
}

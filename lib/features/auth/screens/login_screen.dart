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

  Future<void> _google() async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // Thành công → router tự redirect sang Home.
    } catch (e) {
      final s = e.toString();
      // Scenario B: email đã có tài khoản mật khẩu → hỏi mật khẩu rồi liên kết.
      if (s.contains('link-password-required')) {
        if (mounted) await _linkGoogle();
      } else if (mounted && !s.contains('cancelled')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng nhập Google thất bại: ${_friendly(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Hỏi mật khẩu tài khoản sẵn có rồi liên kết Google vào (Scenario B).
  Future<void> _linkGoogle() async {
    final ctrl = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Liên kết Google'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Email này đã đăng ký bằng mật khẩu. Nhập mật khẩu để liên kết với Google.'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Mật khẩu'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Liên kết')),
        ],
      ),
    );
    if (password == null || password.isEmpty) return;
    try {
      await ref.read(authRepositoryProvider).linkPendingGoogleAccount(password);
      // Liên kết xong → đã đăng nhập → router tự redirect sang Home.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Liên kết thất bại: ${_friendly(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 48)),
                const Text('Linh Kiện Shop',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Đăng nhập', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
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
                  onPressed: _loading ? null : _google,
                ),
                const SizedBox(height: 8),
                // Gợi ý hiển thị cho MỌI người → không lộ tài khoản nào tồn tại.
                const Text(
                  'Đã đăng ký bằng Google? Hãy đăng nhập bằng Google.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chưa có tài khoản? '),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.register),
                      child: const Text('Đăng ký',
                          style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w500)),
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
    if (s.contains('credential-already-in-use') || s.contains('provider-already-linked')) {
      return 'Tài khoản Google này đã được liên kết với tài khoản khác';
    }
    if (s.contains('user-not-found')) return 'Tài khoản không tồn tại';
    if (s.contains('wrong-password') || s.contains('invalid-credential')) return 'Sai mật khẩu';
    if (s.contains('network')) return 'Lỗi mạng, kiểm tra kết nối';
    // Lộ mã lỗi thật để dễ chẩn đoán (tạm thời).
    final m = RegExp(r'\[([\w-]+)\]|code:\s*([\w-]+)').firstMatch(s);
    final code = m?.group(1) ?? m?.group(2);
    return code != null ? 'Lỗi: $code' : 'Vui lòng thử lại';
  }
}

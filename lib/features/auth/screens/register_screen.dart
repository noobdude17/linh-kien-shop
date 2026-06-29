import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../routes/app_routes.dart';
import '../../location/location_picker_screen.dart';
import '../providers/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _dob = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _agree = true;
  bool _loading = false;
  double? _lat, _lng; // toạ độ xác nhận từ map picker (null nếu nhập tay)

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _dob.dispose();
    _address.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      _dob.text =
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _pickLocation() async {
    final res = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: (_lat != null && _lng != null) ? LatLng(_lat!, _lng!) : null,
          initialText: _address.text.trim().isEmpty
              ? null
              : _address.text.trim(),
        ),
      ),
    );
    if (res != null) {
      setState(() {
        _address.text = res.address;
        _lat = res.lat;
        _lng = res.lng;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đồng ý điều khoản sử dụng')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(
            name: _name.text.trim(),
            email: _email.text,
            phone: _phone.text.trim(),
            password: _password.text,
            address: _address.text.trim(),
            dob: _dob.text.trim(),
            lat: _lat,
            lng: _lng,
          );
      // Đăng ký xong → đã đăng nhập nhưng email chưa xác nhận →
      // router tự đưa sang màn "Xác nhận email" (liên kết đã gửi trong signUp).
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đăng ký thất bại: ${_friendly(e)}')),
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
        title: const Text('Tạo tài khoản'),
        leading: BackButton(onPressed: () => context.go(AppRoutes.login)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(
                _name,
                'Họ và tên',
                Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nhập họ tên' : null,
              ),
              _field(
                _email,
                'Email',
                Icons.email_outlined,
                keyboard: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Email không hợp lệ'
                    : null,
              ),
              _field(
                _phone,
                'Số điện thoại',
                Icons.phone_outlined,
                keyboard: TextInputType.phone,
                validator: (v) => (v == null || v.trim().length < 9)
                    ? 'Số điện thoại không hợp lệ'
                    : null,
              ),
              _field(
                _dob,
                'Ngày sinh',
                Icons.cake_outlined,
                readOnly: true,
                onTap: _pickDob,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Chọn ngày sinh' : null,
              ),
              _field(
                _address,
                'Địa chỉ (chọn trên bản đồ)',
                Icons.location_on_outlined,
                readOnly: true,
                onTap: _pickLocation,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Chọn địa chỉ trên bản đồ'
                    : null,
              ),
              _field(
                _password,
                'Mật khẩu',
                Icons.lock_outline,
                obscure: true,
                validator: (v) => (v == null || v.length < 6)
                    ? 'Mật khẩu tối thiểu 6 ký tự'
                    : null,
              ),
              _field(
                _confirm,
                'Nhập lại mật khẩu',
                Icons.lock_outline,
                obscure: true,
                validator: (v) =>
                    (v != _password.text) ? 'Mật khẩu không khớp' : null,
              ),
              Row(
                children: [
                  Checkbox(
                    value: _agree,
                    onChanged: (v) => setState(() => _agree = v ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'Tôi đồng ý với điều khoản sử dụng và chính sách bảo mật',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    )
                  : PrimaryButton(label: 'Đăng ký', onPressed: _submit),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đã có tài khoản? '),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.login),
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    bool obscure = false,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboard,
        decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
        validator: validator,
      ),
    );
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('email-already-in-use')) {
      return 'Email này đã được đăng ký. Nếu trước đây bạn dùng Google, hãy đăng nhập bằng Google.';
    }
    if (s.contains('weak-password')) return 'Mật khẩu quá yếu';
    return 'Vui lòng thử lại';
  }
}

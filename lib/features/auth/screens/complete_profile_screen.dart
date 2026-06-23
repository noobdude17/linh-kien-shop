import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../routes/app_routes.dart';
import '../../location/location_picker_screen.dart';
import '../providers/auth_providers.dart';

/// Bắt buộc người dùng (đặc biệt đăng nhập Google) bổ sung thông tin cá nhân.
/// Router chặn mọi route khác đến khi hồ sơ đủ (phone + address), nên màn này
/// không có nút back / bỏ qua — đóng app giữa chừng sẽ hiện lại lần sau.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _dob = TextEditingController();
  bool _loading = false;
  bool _init = false;
  double? _lat, _lng; // toạ độ xác nhận từ map picker

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _dob.dispose();
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
      // dd/MM/yyyy — không cần gói intl.
      _dob.text = '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _pickLocation() async {
    final res = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initial: (_lat != null && _lng != null) ? LatLng(_lat!, _lng!) : null,
          initialText: _address.text.trim().isEmpty ? null : _address.text.trim(),
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
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            address: _address.text.trim(),
            dob: _dob.text.trim(),
            lat: _lat,
            lng: _lng,
          );
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu thông tin thất bại, thử lại')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (!_init && user != null) {
      _name.text = user.name;
      _init = true;
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Hoàn tất thông tin'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Vui lòng bổ sung thông tin để tiếp tục.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              _field(_name, 'Họ và tên', Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nhập họ tên'
                      : null),
              // Email đồng bộ từ tài khoản — chỉ đọc.
              TextFormField(
                enabled: false,
                initialValue: user?.email ?? '',
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  suffixIcon: Icon(Icons.lock_outline, size: 18),
                ),
              ),
              const SizedBox(height: 14),
              _field(_phone, 'Số điện thoại', Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().length < 9)
                      ? 'Số điện thoại không hợp lệ'
                      : null),
              _field(_dob, 'Ngày sinh', Icons.cake_outlined,
                  readOnly: true,
                  onTap: _pickDob,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Chọn ngày sinh'
                      : null),
              _field(_address, 'Địa chỉ (chọn trên bản đồ)', Icons.location_on_outlined,
                  readOnly: true, onTap: _pickLocation,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Chọn địa chỉ trên bản đồ'
                      : null),
              const SizedBox(height: 8),
              _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator())
                  : PrimaryButton(label: 'Tiếp tục', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
      {TextInputType? keyboard,
      bool readOnly = false,
      VoidCallback? onTap,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
        validator: validator,
      ),
    );
  }
}

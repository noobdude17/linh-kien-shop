import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../data/models/address_model.dart';
import '../../../routes/app_routes.dart';
import '../../auth/providers/auth_providers.dart';
import '../../location/location_picker_screen.dart';
import '../providers/address_providers.dart';

/// Thêm/sửa địa chỉ. [initial] != null → chế độ sửa (truyền qua go_router `extra`).
class AddAddressScreen extends ConsumerStatefulWidget {
  final AddressModel? initial;
  const AddAddressScreen({super.key, this.initial});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late bool _isDefault;
  double? _lat, _lng;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _name = TextEditingController(text: a?.name ?? '');
    _phone = TextEditingController(text: a?.phone ?? '');
    _address = TextEditingController(text: a?.detail ?? '');
    _isDefault = a?.isDefault ?? true;
    _lat = a?.latitude;
    _lng = a?.longitude;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final model = AddressModel(
      id: widget.initial?.id ?? '',
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      detail: _address.text.trim(),
      isDefault: _isDefault,
      latitude: _lat,
      longitude: _lng,
    );
    setState(() => _saving = true);
    try {
      final repo = ref.read(addressRepositoryProvider);
      if (_isEdit) {
        await repo.update(user.id, model);
      } else {
        await repo.add(user.id, model);
      }
      if (mounted) context.go(AppRoutes.addresses);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu địa chỉ thất bại, thử lại')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.addresses)),
        title: Text(_isEdit ? 'Sửa địa chỉ' : 'Thêm địa chỉ'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _field(_name, 'Họ tên người nhận', Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nhập họ tên' : null),
            _field(_phone, 'Số điện thoại', Icons.phone_outlined,
                keyboard: TextInputType.phone,
                validator: (v) => (v == null || v.trim().length < 9)
                    ? 'Số điện thoại không hợp lệ'
                    : null),
            _field(_address, 'Địa chỉ (chọn trên bản đồ)',
                Icons.location_on_outlined,
                readOnly: true, onTap: _pickLocation, maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Chọn địa chỉ trên bản đồ'
                    : null),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Đặt làm địa chỉ mặc định',
                  style: TextStyle(fontSize: 14)),
              value: _isDefault,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => setState(() => _isDefault = v),
            ),
            const SizedBox(height: 8),
            _saving
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator()))
                : PrimaryButton(label: 'Lưu địa chỉ', onPressed: _save),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
      {TextInputType? keyboard,
      bool readOnly = false,
      VoidCallback? onTap,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
        validator: validator,
      ),
    );
  }
}

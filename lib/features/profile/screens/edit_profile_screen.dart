import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../routes/app_routes.dart';
import '../../auth/providers/auth_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _dob = TextEditingController();
  bool _loading = false;
  bool _init = false;

  @override
  void dispose() {
    _name.dispose();
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
      _dob.text = '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            dob: _dob.text.trim(),
          );
      if (mounted) context.go(AppRoutes.profile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu thất bại, thử lại')),
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
      _phone.text = user.phone ?? '';
      _dob.text = user.dob ?? '';
      _init = true;
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
        title: const Text('Chỉnh sửa thông tin'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: Stack(
              children: [
                const CircleAvatar(radius: 44, backgroundColor: AppColors.background, child: Text('👤', style: TextStyle(fontSize: 40))),
                Positioned(
                  bottom: 0, right: 0,
                  child: CircleAvatar(radius: 14, backgroundColor: AppColors.accentBlue,
                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _field('Họ và tên', controller: _name),
          _field('Email', value: user?.email ?? '', disabled: true),
          _field('Số điện thoại', controller: _phone, keyboard: TextInputType.phone),
          _field('Ngày sinh', controller: _dob, readOnly: true, onTap: _pickDob),
          const SizedBox(height: 16),
          _loading
              ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
              : PrimaryButton(label: 'Lưu thay đổi', onPressed: _save),
        ],
      ),
    );
  }

  Widget _field(String label,
          {TextEditingController? controller,
          String? value,
          bool disabled = false,
          bool readOnly = false,
          VoidCallback? onTap,
          TextInputType? keyboard}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              enabled: !disabled,
              readOnly: readOnly,
              onTap: onTap,
              keyboardType: keyboard,
              controller: controller ?? TextEditingController(text: value),
              decoration: InputDecoration(
                suffixIcon: disabled ? const Icon(Icons.lock_outline, size: 18) : null,
                fillColor: disabled ? AppColors.background : AppColors.surface,
              ),
            ),
          ],
        ),
      );
}

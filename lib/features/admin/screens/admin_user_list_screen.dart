import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../routes/app_routes.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_scaffold.dart';

class AdminUserListScreen extends ConsumerStatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  ConsumerState<AdminUserListScreen> createState() =>
      _AdminUserListScreenState();
}

class _AdminUserListScreenState extends ConsumerState<AdminUserListScreen> {
  final _search = TextEditingController();
  bool? _locked;

  AdminUserQuery get _query =>
      AdminUserQuery(search: _search.text.trim(), locked: _locked, limit: 80);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(adminUsersProvider(_query));
    return AdminScaffold(
      title: 'Quản lý người dùng',
      backRoute: AppRoutes.admin,
      body: Column(
        children: [
          _filters(),
          Expanded(
            child: users.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AdminError(
                message: 'Không tải được người dùng',
                onRetry: () => ref.invalidate(adminUsersProvider),
              ),
              data: (page) => page.items.isEmpty
                  ? const AdminEmpty(
                      message: 'Không có người dùng',
                      icon: Icons.people_outline,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppDimens.screenPadding),
                      itemCount: page.items.length,
                      itemBuilder: (_, i) => _row(page.items[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              hintText: 'Tìm tên hoặc email',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Tất cả'),
                selected: _locked == null,
                onSelected: (_) => setState(() => _locked = null),
              ),
              ChoiceChip(
                label: const Text('Đang hoạt động'),
                selected: _locked == false,
                onSelected: (_) => setState(() => _locked = false),
              ),
              ChoiceChip(
                label: const Text('Đã khóa'),
                selected: _locked == true,
                onSelected: (_) => setState(() => _locked = true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              CircleAvatar(
                backgroundColor: user.isLocked
                    ? AppColors.errorBg
                    : AppColors.adminSurfaceTint,
                child: Icon(
                  user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                  color: user.isLocked ? AppColors.error : AppColors.adminAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isEmpty ? 'Chưa có tên' : user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => _onAction(user, v),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Sửa thông tin'),
                  ),
                  if (!user.isAdmin)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Xóa',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Badge + nút khóa cùng một Wrap → tự xuống dòng, không tràn ngang.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _badge(
                user.isAdmin ? 'Admin' : 'Khách hàng',
                AppColors.adminSurfaceTint,
                AppColors.adminAccent,
              ),
              if (user.isLocked)
                _badge('Đã khóa', AppColors.errorBg, AppColors.error)
              else
                _badge('Hoạt động', AppColors.successBg, AppColors.success),
              // Nút khóa rõ ràng, có nhãn — không còn là switch trống.
              if (!user.isAdmin)
                OutlinedButton.icon(
                  onPressed: () => _confirmLock(user, !user.isLocked),
                  icon: Icon(
                    user.isLocked ? Icons.lock_open : Icons.lock_outline,
                    size: 16,
                  ),
                  label: Text(user.isLocked ? 'Mở khóa' : 'Khóa'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: user.isLocked
                        ? AppColors.success
                        : AppColors.error,
                    side: BorderSide(
                      color: user.isLocked ? AppColors.success : AppColors.error,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(
      label,
      style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );

  void _onAction(UserModel user, String action) {
    switch (action) {
      case 'edit':
        _editUser(user);
      case 'delete':
        _confirmDelete(user);
    }
  }

  Future<void> _confirmLock(UserModel user, bool locked) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(locked ? 'Khóa người dùng?' : 'Mở khóa người dùng?'),
        content: Text(user.email),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(locked ? 'Khóa' : 'Mở khóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(adminRepositoryProvider).setUserLocked(user.id, locked);
    invalidateAdminData(ref);
  }

  Future<void> _confirmDelete(UserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa người dùng?'),
        content: Text(
          'Xóa hồ sơ "${user.email}". Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(adminRepositoryProvider).deleteUser(user.id);
    invalidateAdminData(ref);
  }

  Future<void> _editUser(UserModel user) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _UserEditSheet(user: user),
    );
    if (saved == true) invalidateAdminData(ref);
  }
}

/// Form sửa hồ sơ người dùng (tên/phone/địa chỉ/vai trò). Email không sửa —
/// nó gắn với tài khoản Auth.
class _UserEditSheet extends ConsumerStatefulWidget {
  const _UserEditSheet({required this.user});

  final UserModel user;

  @override
  ConsumerState<_UserEditSheet> createState() => _UserEditSheetState();
}

class _UserEditSheetState extends ConsumerState<_UserEditSheet> {
  late final _name = TextEditingController(text: widget.user.name);
  late final _phone = TextEditingController(text: widget.user.phone ?? '');
  late final _address = TextEditingController(text: widget.user.address ?? '');
  late String _role = widget.user.role;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final u = widget.user;
    final updated = UserModel(
      id: u.id,
      name: _name.text.trim(),
      email: u.email,
      role: _role,
      address: _address.text.trim(),
      phone: _phone.text.trim(),
      dob: u.dob,
      photoUrl: u.photoUrl,
      defaultAddress: u.defaultAddress,
      emailVerified: u.emailVerified,
      isLocked: u.isLocked,
    );
    try {
      await ref.read(adminRepositoryProvider).saveUser(updated);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lưu được, thử lại')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sửa: ${widget.user.email}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Họ tên'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Số điện thoại'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Địa chỉ'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Vai trò'),
            items: const [
              DropdownMenuItem(
                value: AppConstants.roleCustomer,
                child: Text('Khách hàng'),
              ),
              DropdownMenuItem(
                value: AppConstants.roleAdmin,
                child: Text('Admin'),
              ),
            ],
            onChanged: (v) => setState(() => _role = v ?? _role),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Đang lưu...' : 'Lưu thay đổi'),
            ),
          ),
        ],
      ),
    );
  }
}

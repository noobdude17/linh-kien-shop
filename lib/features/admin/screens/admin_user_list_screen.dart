import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../routes/app_routes.dart';
import '../providers/admin_providers.dart';

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.adminAccent,
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.go(AppRoutes.admin)),
        title: const Text('Quản lý người dùng'),
      ),
      body: Column(
        children: [
          _filters(),
          Expanded(
            child: users.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _error('Không tải được người dùng'),
              data: (page) => page.items.isEmpty
                  ? const Center(child: Text('Không có người dùng'))
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: user.isLocked
                ? AppColors.errorBg
                : AppColors.doneBg,
            child: Icon(
              user.isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: user.isLocked ? AppColors.error : AppColors.bodyText,
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
                const SizedBox(height: 4),
                Text(
                  '${user.role}${user.isLocked ? ' · Đã khóa' : ''}',
                  style: TextStyle(
                    color: user.isLocked ? AppColors.error : AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: user.isLocked,
            activeThumbColor: AppColors.error,
            onChanged: user.isAdmin ? null : (v) => _confirmLock(user, v),
          ),
        ],
      ),
    );
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

  Widget _error(String message) => Center(
    child: Text(
      message,
      style: const TextStyle(color: AppColors.textSecondary),
    ),
  );
}

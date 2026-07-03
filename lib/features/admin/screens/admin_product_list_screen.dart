import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../routes/app_routes.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_scaffold.dart';

class AdminProductListScreen extends ConsumerStatefulWidget {
  const AdminProductListScreen({super.key});

  @override
  ConsumerState<AdminProductListScreen> createState() =>
      _AdminProductListScreenState();
}

class _AdminProductListScreenState
    extends ConsumerState<AdminProductListScreen> {
  final _search = TextEditingController();
  bool? _active;

  AdminProductQuery get _query => AdminProductQuery(
    search: _search.text.trim(),
    active: _active,
    limit: 80,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(adminProductsProvider(_query));
    return AdminScaffold(
      title: 'Quản lý sản phẩm',
      backRoute: AppRoutes.admin,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.adminAccent,
        foregroundColor: Colors.white,
        onPressed: () => context.go(AppRoutes.adminProductEdit),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _filters(),
          Expanded(
            child: products.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AdminError(
                message: 'Không tải được sản phẩm',
                onRetry: () => ref.invalidate(adminProductsProvider),
              ),
              data: (page) => page.items.isEmpty
                  ? const AdminEmpty(
                      message: 'Không có sản phẩm',
                      icon: Icons.inventory_2_outlined,
                    )
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(adminProductsProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppDimens.screenPadding),
                        itemCount: page.items.length,
                        itemBuilder: (_, i) => _row(page.items[i]),
                      ),
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
              hintText: 'Tìm tên hoặc thương hiệu',
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
                selected: _active == null,
                onSelected: (_) => setState(() => _active = null),
              ),
              ChoiceChip(
                label: const Text('Đang bán'),
                selected: _active == true,
                onSelected: (_) => setState(() => _active = true),
              ),
              ChoiceChip(
                label: const Text('Đã ẩn'),
                selected: _active == false,
                onSelected: (_) => setState(() => _active = false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(ProductModel p) {
    final outOfStock = !p.inStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.brCard,
        boxShadow: AppDimens.cardShadow,
      ),
      child: Row(
        children: [
          ImagePlaceholder(
            label: p.imageLabel,
            imageUrl: p.primaryImageUrl,
            width: 54,
            height: 54,
            radius: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${p.categoryName} · ${p.brand}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      Formatter.price(p.price),
                      style: const TextStyle(
                        color: AppColors.adminPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    _badge(
                      p.isActive ? 'Đang bán' : 'Đã ẩn',
                      p.isActive ? AppColors.successBg : AppColors.doneBg,
                      p.isActive ? AppColors.success : AppColors.textSecondary,
                    ),
                    _badge(
                      outOfStock ? 'Hết hàng' : 'Còn ${p.stock}',
                      outOfStock ? AppColors.errorBg : AppColors.successBg,
                      outOfStock ? AppColors.error : AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.adminPrimary, size: 20),
            onPressed: () =>
                context.go('${AppRoutes.adminProductEdit}/${p.id}'),
          ),
          IconButton(
            icon: Icon(
              p.isActive
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: p.isActive ? AppColors.error : AppColors.success,
              size: 20,
            ),
            onPressed: () =>
                p.isActive ? _confirmHide(p) : _setActive(p, true),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _confirmHide(ProductModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ẩn sản phẩm?'),
        content: Text('Sản phẩm "${p.name}" sẽ không còn hiển thị cho khách.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ẩn', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _setActive(p, false);
  }

  Future<void> _setActive(ProductModel p, bool active) async {
    await ref.read(adminRepositoryProvider).setProductActive(p.id, active);
    invalidateAdminData(ref);
  }
}

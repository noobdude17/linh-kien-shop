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
import '../widgets/admin_search_field.dart';

class AdminProductListScreen extends ConsumerStatefulWidget {
  const AdminProductListScreen({super.key});

  @override
  ConsumerState<AdminProductListScreen> createState() =>
      _AdminProductListScreenState();
}

class _AdminProductListScreenState
    extends ConsumerState<AdminProductListScreen> {
  static const _pageSize = 30;

  final _search = TextEditingController();
  final _scrollController = ScrollController();
  bool? _active;
  List<ProductModel> _items = [];
  Object? _cursor;
  bool _hasMore = true;
  bool _loading = true;
  Object? _error;

  AdminProductQuery get _query => AdminProductQuery(
    search: _search.text.trim(),
    active: _active,
    limit: _pageSize,
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearBottom);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadProducts());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Quản lý sản phẩm',
      backRoute: AppRoutes.admin,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.adminAccent,
        foregroundColor: Colors.white,
        onPressed: () => context.push(AppRoutes.adminProductEdit),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _filters(),
          Expanded(child: _productList()),
        ],
      ),
    );
  }

  Widget _productList() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return AdminError(
        message: 'Không tải được sản phẩm',
        onRetry: _reloadProducts,
      );
    }
    if (_items.isEmpty) {
      return const AdminEmpty(
        message: 'Không có sản phẩm',
        icon: Icons.inventory_2_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _reloadProducts,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        itemCount: _items.length + (_hasMore || _loading ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _row(_items[i]);
        },
      ),
    );
  }

  Widget _filters() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          AdminSearchField(
            controller: _search,
            hintText: 'Tìm tên, thương hiệu, danh mục...',
            onChanged: (_) => _reloadProducts(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Tất cả'),
                selected: _active == null,
                onSelected: (_) => _setActiveFilter(null),
              ),
              ChoiceChip(
                label: const Text('Đang bán'),
                selected: _active == true,
                onSelected: (_) => _setActiveFilter(true),
              ),
              ChoiceChip(
                label: const Text('Đã ẩn'),
                selected: _active == false,
                onSelected: (_) => _setActiveFilter(false),
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
            icon: const Icon(
              Icons.edit,
              color: AppColors.adminPrimary,
              size: 20,
            ),
            onPressed: () =>
                context.push('${AppRoutes.adminProductEdit}/${p.id}'),
          ),
          IconButton(
            icon: Icon(
              p.isActive
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: p.isActive ? AppColors.error : AppColors.success,
              size: 20,
            ),
            onPressed: () => p.isActive ? _confirmHide(p) : _setActive(p, true),
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
    await _reloadProducts();
  }

  void _setActiveFilter(bool? active) {
    if (_active == active) return;
    setState(() => _active = active);
    _reloadProducts();
  }

  void _loadMoreNearBottom() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      _loadMoreProducts();
    }
  }

  Future<void> _reloadProducts() async {
    final query = _query;
    setState(() {
      _loading = true;
      _error = null;
      _hasMore = true;
      _cursor = null;
    });
    try {
      final page = await ref.read(adminRepositoryProvider).getProducts(query);
      if (!mounted || query != _query) return;
      setState(() {
        _items = page.items;
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || query != _query) return;
      setState(() {
        _error = e;
        _items = [];
        _loading = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_loading || !_hasMore) return;
    final query = AdminProductQuery(
      search: _search.text.trim(),
      active: _active,
      limit: _pageSize,
      cursor: _cursor,
    );
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(adminRepositoryProvider).getProducts(query);
      if (!mounted ||
          query.search != _query.search ||
          query.active != _active) {
        return;
      }
      final seen = _items.map((p) => p.id).toSet();
      setState(() {
        _items = [..._items, ...page.items.where((p) => seen.add(p.id))];
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }
}

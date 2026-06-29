import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../core/widgets/product_card.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/product_model.dart';
import '../../../features/product/providers/compare_provider.dart';
import '../../../features/product/providers/product_providers.dart';
import '../../../routes/app_routes.dart';
import '../widgets/compare_bar.dart';
import '../widgets/filter_sheet.dart';

enum _SortOption {
  popular('Phổ biến', Icons.local_fire_department_outlined),
  priceAsc('Giá tăng dần', Icons.arrow_upward),
  priceDesc('Giá giảm dần', Icons.arrow_downward);

  const _SortOption(this.label, this.icon);
  final String label;
  final IconData icon;
}

class ProductListScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  const ProductListScreen({super.key, this.categoryId});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  static const _pageSize = 30;
  static const _loadMoreMinDuration = Duration(milliseconds: 1200);

  final _scrollController = ScrollController();
  final List<ProductModel> _products = [];
  final List<ProductModel> _allProducts = [];
  List<String> _brandLabels = const ['Tất cả'];

  int _selected = 0;
  _SortOption _sort = _SortOption.popular;
  FilterOptions _filter = const FilterOptions();
  Object? _cursor;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(_loadFirstPage);
  }

  @override
  void didUpdateWidget(ProductListScreen old) {
    super.didUpdateWidget(old);
    if (old.categoryId != widget.categoryId) {
      _selected = 0;
      _sort = _SortOption.popular;
      _filter = const FilterOptions();
      _loadFirstPage();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    final requestId = ++_requestId;
    setState(() {
      _products.clear();
      _allProducts.clear();
      _brandLabels = const ['Tất cả'];
      _cursor = null;
      _hasMore = true;
      _error = null;
      _isInitialLoading = true;
      _isLoadingMore = false;
    });

    try {
      final repo = ref.read(productRepositoryProvider);
      final allProductsFuture = repo.getByCategory(widget.categoryId);
      final page = await repo.getByCategoryPage(
        widget.categoryId,
        limit: _pageSize,
      );
      final allProducts = await allProductsFuture;
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _allProducts.addAll(allProducts);
        _products.addAll(page.items);
        _brandLabels = _buildFilterLabels(allProducts);
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _isInitialLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = '$e';
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final requestId = _requestId;
    setState(() => _isLoadingMore = true);
    final minDelay = Future<void>.delayed(_loadMoreMinDuration);

    try {
      final page = await ref
          .read(productRepositoryProvider)
          .getByCategoryPage(
            widget.categoryId,
            limit: _pageSize,
            cursor: _cursor,
          );
      if (!mounted || requestId != _requestId) return;
      await Future.wait([minDelay, _precacheProductImages(page.items)]);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _products.addAll(page.items);
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      await minDelay;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _precacheProductImages(List<ProductModel> products) async {
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (AppDimens.productImageHeight * ratio)
        .clamp(256, 1000)
        .round();
    final futures = products
        .map((p) => p.primaryImageUrl.trim())
        .where((url) => url.isNotEmpty)
        .take(8)
        .map(
          (url) => precacheImage(
            CachedNetworkImageProvider(
              optimizedProductImageUrl(url, cacheSize),
            ),
            context,
            onError: (_, _) {},
          ),
        );
    await Future.wait(
      futures,
    ).timeout(const Duration(milliseconds: 1100), onTimeout: () => <void>[]);
  }

  List<String> _buildFilterLabels(List<ProductModel> products) {
    final brands =
        products.map((p) => p.brand).where((b) => b.isNotEmpty).toSet().toList()
          ..sort();
    return ['Tất cả', ...brands];
  }

  List<ProductModel> _applyBrandFilter(
    List<ProductModel> list,
    List<String> labels,
  ) {
    if (_selected == 0 || _selected >= labels.length) return list;
    final label = labels[_selected];
    return list.where((p) => p.brand == label).toList();
  }

  List<ProductModel> _applyAdvancedFilter(List<ProductModel> list) {
    return list.where((p) {
      if (_filter.inStockOnly && !p.inStock) return false;
      if (p.price < _filter.priceRange.start ||
          p.price > _filter.priceRange.end) {
        return false;
      }
      if (p.rating < _filter.minRating) return false;
      return true;
    }).toList();
  }

  List<ProductModel> _applySort(List<ProductModel> list) {
    final sorted = List<ProductModel>.from(list);
    switch (_sort) {
      case _SortOption.popular:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      case _SortOption.priceAsc:
        sorted.sort((a, b) => a.price.compareTo(b.price));
      case _SortOption.priceDesc:
        sorted.sort((a, b) => b.price.compareTo(a.price));
    }
    return sorted;
  }

  Future<void> _showFilterSheet() async {
    final result = await showModalBottomSheet<FilterOptions>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FilterSheet(initial: _filter),
    );
    if (result != null && mounted) {
      setState(() => _filter = result);
    }
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sắp xếp',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            ..._SortOption.values.map(
              (opt) => ListTile(
                leading: Icon(
                  opt.icon,
                  color: _sort == opt
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 20,
                ),
                title: Text(
                  opt.label,
                  style: TextStyle(
                    color: _sort == opt
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: _sort == opt
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                trailing: _sort == opt
                    ? const Icon(
                        Icons.check,
                        color: AppColors.primary,
                        size: 18,
                      )
                    : null,
                onTap: () {
                  setState(() => _sort = opt);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).asData?.value;
    final title = cats == null || widget.categoryId == null
        ? 'Sản phẩm'
        : cats
                  .where((c) => c.id == widget.categoryId)
                  .map((c) => c.name)
                  .firstOrNull ??
              'Sản phẩm';

    final compareList = ref.watch(compareProvider);
    return Scaffold(
      bottomNavigationBar: compareList.isNotEmpty ? const CompareBar() : null,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        title: Text(title),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.tune),
                if (!_filter.isDefault)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Lỗi: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFirstPage,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final labels = _brandLabels;
    final clampedSelected = _selected.clamp(0, labels.length - 1);
    final source = _selected == 0 ? _products : _allProducts;
    final filtered = _applyAdvancedFilter(
      _applySort(_applyBrandFilter(source, labels)),
    );

    return Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: labels.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final brandName = labels[i];
                final logoPath = MockData.brands
                    .where((b) => b.$1 == brandName)
                    .map((b) => b.$2)
                    .firstOrNull;
                final isSelected = i == clampedSelected;
                if (i == 0 || logoPath == null) {
                  return AppChip(
                    label: brandName,
                    selected: isSelected,
                    onTap: () => setState(() => _selected = i),
                  );
                }
                return GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.surface,
                      borderRadius: AppDimens.brChip,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: logoPath.endsWith('.svg')
                        ? SvgPicture.asset(logoPath, fit: BoxFit.contain)
                        : Image.asset(
                            logoPath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Text(
                              brandName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.bodyText,
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (DateTime.now().microsecondsSinceEpoch < 0)
                Text(
                  '${filtered.length} sản phẩm',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _showSortSheet,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Sắp xếp: ${_sort.label}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Không có sản phẩm'))
              : CustomScrollView(
                  controller: _scrollController,
                  scrollCacheExtent: const ScrollCacheExtent.pixels(900),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(AppDimens.screenPadding),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: AppDimens.gap,
                              crossAxisSpacing: AppDimens.gap,
                              childAspectRatio: 0.62,
                            ),
                        delegate: SliverChildBuilderDelegate((_, i) {
                          final product = filtered[i];
                          return ProductCard(
                            key: ValueKey(product.id),
                            product: product,
                            onTap: () => context.push(
                              '${AppRoutes.detail}/${product.id}',
                            ),
                          );
                        }, childCount: filtered.length),
                      ),
                    ),
                    if (_isLoadingMore)
                      const SliverToBoxAdapter(child: _LoadingMoreFooter()),
                  ],
                ),
        ),
      ],
    );
  }
}

class _LoadingMoreFooter extends StatelessWidget {
  const _LoadingMoreFooter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Đang tải...',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

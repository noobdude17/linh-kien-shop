import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/models/product_model.dart';
import '../../../features/cart/providers/cart_provider.dart';
import '../../../features/product/providers/product_providers.dart';
import '../../../routes/app_routes.dart';
import '../widgets/category_chip.dart';
import '../widgets/promo_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _pageSize = 32;
  static const _categoryBatchSize = 8;
  static const _loadMoreMinDuration = Duration(milliseconds: 1200);
  static const _homeCategoryIds = ['gpu', 'cpu', 'ram', 'storage'];

  final _scrollController = ScrollController();
  final List<ProductModel> _products = [];
  final Map<String, Object?> _cursors = {
    for (final categoryId in _homeCategoryIds) categoryId: null,
  };
  final Map<String, bool> _hasMoreByCategory = {
    for (final categoryId in _homeCategoryIds) categoryId: true,
  };

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _nextCategoryIndex = 0;
  int _requestId = 0;

  bool get _hasMore => _hasMoreByCategory.values.any((hasMore) => hasMore);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(_loadFirstPage);
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
      for (final categoryId in _homeCategoryIds) {
        _cursors[categoryId] = null;
        _hasMoreByCategory[categoryId] = true;
      }
      _nextCategoryIndex = 0;
      _error = null;
      _isInitialLoading = true;
      _isLoadingMore = false;
    });

    try {
      final newItems = await _loadProductBatch(requestId);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _products.addAll(newItems);
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
      final newItems = await _loadProductBatch(requestId);
      if (!mounted || requestId != _requestId) return;
      await Future.wait([minDelay, _precacheProductImages(newItems)]);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _products.addAll(newItems);
        _isLoadingMore = false;
      });
    } finally {
      if (mounted && requestId == _requestId && _isLoadingMore) {
        await minDelay;
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<List<ProductModel>> _loadProductBatch(int requestId) async {
    var added = 0;
    final batch = <ProductModel>[];
    final existingIds = _products.map((p) => p.id).toSet();

    while ((added < _pageSize || _wouldEndOnOddGridItem(batch)) && _hasMore) {
      final categoryId = _nextCategoryId();
      if (categoryId == null) break;
      final remaining = _pageSize - added;
      final limit = remaining > 0 ? remaining.clamp(1, _categoryBatchSize) : 1;

      final page = await ref
          .read(productRepositoryProvider)
          .getByCategoryPage(
            categoryId,
            limit: limit,
            cursor: _cursors[categoryId],
          );
      if (!mounted || requestId != _requestId) return batch;

      final newItems = page.items
          .where((product) => existingIds.add(product.id))
          .toList();
      batch.addAll(newItems);
      added += newItems.length;
      _cursors[categoryId] = page.cursor;
      _hasMoreByCategory[categoryId] = page.hasMore;
      _nextCategoryIndex = (_nextCategoryIndex + 1) % _homeCategoryIds.length;
    }

    return batch;
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

  String? _nextCategoryId() {
    for (var i = 0; i < _homeCategoryIds.length; i++) {
      final index = (_nextCategoryIndex + i) % _homeCategoryIds.length;
      final categoryId = _homeCategoryIds[index];
      if (_hasMoreByCategory[categoryId] == true) {
        _nextCategoryIndex = index;
        return categoryId;
      }
    }
    return null;
  }

  bool _wouldEndOnOddGridItem(List<ProductModel> batch) {
    return (_products.length + batch.length).isOdd;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      body: Column(
        children: [
          const _HomeHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadFirstPage,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                cacheExtent: 900,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.screenPadding,
                        AppDimens.screenPadding,
                        AppDimens.screenPadding,
                        0,
                      ),
                      child: PromoBanner(
                        onTap: () => context.go(AppRoutes.list),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.screenPadding,
                        8,
                        AppDimens.screenPadding,
                        0,
                      ),
                      child: SectionHeader(
                        title: 'Danh mục',
                        actionLabel: 'Xem tất cả →',
                        onAction: () => context.go(AppRoutes.categories),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 92,
                      child: categories.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Lỗi: $e')),
                        data: (list) => ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.screenPadding,
                          ),
                          itemCount: list.length > 7 ? 7 : list.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => CategoryChip(
                            category: list[i],
                            onTap: () => context.push(
                              '${AppRoutes.list}?categoryId=${list[i].id}',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.screenPadding,
                        8,
                        AppDimens.screenPadding,
                        0,
                      ),
                      child: SectionHeader(
                        title: 'Sản phẩm nổi bật',
                        actionLabel: 'Xem tất cả →',
                        onAction: () => context.go(AppRoutes.list),
                      ),
                    ),
                  ),
                  if (_isInitialLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (_error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(child: Text('L?i: $_error')),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(AppDimens.screenPadding),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => ProductCard(
                            key: ValueKey(_products[i].id),
                            product: _products[i],
                            onTap: () => context.push(
                              '${AppRoutes.detail}/${_products[i].id}',
                            ),
                          ),
                          childCount: _products.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: AppDimens.gap,
                              crossAxisSpacing: AppDimens.gap,
                              childAspectRatio: 0.62,
                            ),
                      ),
                    ),
                  if (_isLoadingMore)
                    const SliverToBoxAdapter(child: _LoadingMoreFooter()),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
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

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Linh Kiện Shop',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.inputFill,
                      minimumSize: const Size.square(44),
                    ),
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.bodyText,
                    ),
                    onPressed: () => context.go(AppRoutes.notifications),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.inputFill,
                          minimumSize: const Size.square(44),
                        ),
                        icon: const Icon(
                          Icons.shopping_cart_outlined,
                          color: AppColors.bodyText,
                        ),
                        onPressed: () => context.go(AppRoutes.cart),
                      ),
                      if (cartCount > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$cartCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.search),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: AppDimens.brInput,
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tìm kiếm CPU, RAM, Laptop...',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

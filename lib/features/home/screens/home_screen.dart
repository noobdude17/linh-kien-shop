import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../features/cart/providers/cart_provider.dart';
import '../../../features/product/providers/product_providers.dart';
import '../../../routes/app_routes.dart';
import '../widgets/category_chip.dart';
import '../widgets/promo_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredProductsProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      body: Column(
        children: [
          const _HomeHeader(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.screenPadding,
                      AppDimens.screenPadding,
                      AppDimens.screenPadding,
                      0,
                    ),
                    child: PromoBanner(onTap: () => context.go(AppRoutes.list)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.screenPadding, 8,
                      AppDimens.screenPadding, 0,
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
                      AppDimens.screenPadding, 8,
                      AppDimens.screenPadding, 0,
                    ),
                    child: SectionHeader(
                      title: 'Sản phẩm nổi bật',
                      actionLabel: 'Xem tất cả →',
                      onAction: () => context.go(AppRoutes.list),
                    ),
                  ),
                ),
                featured.when(
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Center(child: Text('Lỗi: $e')),
                  ),
                  data: (list) => SliverPadding(
                    padding: const EdgeInsets.all(AppDimens.screenPadding),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => ProductCard(
                          product: list[i],
                          onTap: () =>
                              context.push('${AppRoutes.detail}/${list[i].id}'),
                        ),
                        childCount: list.length,
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
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
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
                      const Icon(Icons.bolt_rounded,
                          color: AppColors.primary, size: 22),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: AppDimens.brInput,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: AppColors.textTertiary, size: 20),
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

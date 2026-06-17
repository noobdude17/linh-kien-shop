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
          _header(context, ref),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              children: [
                PromoBanner(onTap: () => context.go(AppRoutes.list)),
                const SizedBox(height: 8),
                SectionHeader(
                  title: 'Danh mục',
                  actionLabel: 'Xem tất cả →',
                  onAction: () => context.go(AppRoutes.categories),
                ),
                SizedBox(
                  height: 92,
                  child: categories.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Lỗi: $e')),
                    data: (list) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: list.length > 7 ? 7 : list.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => CategoryChip(
                        category: list[i],
                        onTap: () => context.go('${AppRoutes.list}?categoryId=${list[i].id}'),
                      ),
                    ),
                  ),
                ),
                SectionHeader(
                  title: 'Sản phẩm nổi bật',
                  actionLabel: 'Xem tất cả →',
                  onAction: () => context.go(AppRoutes.list),
                ),
                featured.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Center(child: Text('Lỗi: $e')),
                  data: (list) => GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppDimens.gap,
                    crossAxisSpacing: AppDimens.gap,
                    childAspectRatio: 0.62,
                    children: list
                        .map((p) => ProductCard(
                              product: p,
                              onTap: () => context.go('${AppRoutes.detail}/${p.id}'),
                            ))
                        .toList(),
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

  Widget _header(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartCountProvider);
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('⚡ Linh Kiện Shop',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () => context.go(AppRoutes.notifications),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                        onPressed: () => context.go(AppRoutes.cart),
                      ),
                      if (cartCount > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                            child: Text('$cartCount',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.search),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: AppDimens.brPill),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: AppColors.textTertiary, size: 20),
                      SizedBox(width: 8),
                      Text('Tìm kiếm CPU, RAM, Laptop...',
                          style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
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

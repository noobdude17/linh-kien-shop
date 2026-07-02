import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../features/product/providers/wishlist_provider.dart';
import '../../../routes/app_routes.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(wishlistProductsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
        title: const Text('Sản phẩm yêu thích'),
      ),
      body: productsAsync.when(
        loading: () => const ProductGridSkeleton(),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (products) => products.isEmpty
            ? EmptyState(
                icon: Icons.favorite_border_rounded,
                title: 'Chưa có sản phẩm yêu thích',
                message: 'Nhấn ♡ trên sản phẩm để lưu vào đây',
                actionLabel: 'Khám phá sản phẩm',
                onAction: () => context.go(AppRoutes.home),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(AppDimens.screenPadding),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppDimens.gap,
                  crossAxisSpacing: AppDimens.gap,
                  childAspectRatio: 0.62,
                ),
                itemCount: products.length,
                itemBuilder: (_, i) => ProductCard(
                  product: products[i],
                  showWishlistHeart: true,
                  heroEnabled: true,
                  onTap: () =>
                      context.go('${AppRoutes.detail}/${products[i].id}'),
                ),
              ),
      ),
    );
  }
}

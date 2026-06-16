import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/product_card.dart';
import '../../../data/mock_data.dart';
import '../../../routes/app_routes.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
        title: const Text('Sản phẩm yêu thích'),
        actions: [
          IconButton(
            icon: const Icon(Icons.inbox_outlined),
            tooltip: 'Xem trạng thái rỗng',
            onPressed: () => context.go(AppRoutes.wishlistEmpty),
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        mainAxisSpacing: AppDimens.gap,
        crossAxisSpacing: AppDimens.gap,
        childAspectRatio: 0.62,
        children: MockData.featured
            .map((p) => ProductCard(
                  product: p,
                  showWishlistHeart: true,
                  onTap: () => context.go('${AppRoutes.detail}/${p.id}'),
                ))
            .toList(),
      ),
    );
  }
}

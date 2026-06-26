import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../core/utils/formatter.dart';
import '../../features/product/providers/wishlist_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import 'image_placeholder.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final bool showWishlistHeart;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showWishlistHeart = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discount = product.discountPercent;
    final isWishlisted = showWishlistHeart
        ? ref.watch(wishlistProvider).contains(product.id)
        : false;

    return InkWell(
      onTap: onTap,
      borderRadius: AppDimens.brCard,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimens.brCard,
          boxShadow: AppDimens.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ImagePlaceholder(
                  label: product.imageLabel,
                  imageUrl: product.primaryImageUrl,
                  height: AppDimens.productImageHeight,
                  radius: 0,
                ),
                if (discount != null)
                  Positioned(top: 8, left: 8, child: _badge('-$discount%')),
                if (!product.inStock)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black26,
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Hết hàng',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (showWishlistHeart)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => ref
                          .read(wishlistProvider.notifier)
                          .toggle(product.id),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xCCFFFFFF),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isWishlisted ? Colors.red : AppColors.bodyText,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.productCardName,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          Formatter.price(product.price),
                          style: AppTextStyles.priceCard,
                        ),
                      ),
                      if (product.oldPrice != null) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            Formatter.price(product.oldPrice!),
                            style: AppTextStyles.oldPrice,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: AppColors.star),
                      const SizedBox(width: 2),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: AppTextStyles.productCardMeta,
                      ),
                      if (product.stockStatus == StockStatus.lowStock) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Sắp hết',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(text, style: AppTextStyles.badge.copyWith(fontSize: 11)),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Bật Hero bay ảnh sang trang chi tiết. Chỉ bật ở màn hình mà mỗi sản phẩm
  /// xuất hiện đúng một lần (grid chính) — tag Hero không được trùng.
  final bool heroEnabled;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showWishlistHeart = false,
    this.heroEnabled = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discount = product.discountPercent;
    final isWishlisted = showWishlistHeart
        ? ref.watch(wishlistProvider).contains(product.id)
        : false;

    return _PressableScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimens.brCard,
          boxShadow: AppDimens.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: AppDimens.productImageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (heroEnabled)
                    Hero(
                      tag: 'product-img-${product.id}',
                      child: ImagePlaceholder(
                        label: product.imageLabel,
                        imageUrl: product.primaryImageUrl,
                        width: double.infinity,
                        height: AppDimens.productImageHeight,
                        radius: 0,
                      ),
                    )
                  else
                    ImagePlaceholder(
                      label: product.imageLabel,
                      imageUrl: product.primaryImageUrl,
                      width: double.infinity,
                      height: AppDimens.productImageHeight,
                      radius: 0,
                    ),
                  if (discount != null)
                    Positioned(top: 8, left: 8, child: _badge('-$discount%')),
                  if (!product.inStock)
                    Positioned.fill(
                      child: Container(
                        color: AppColors.overlayScrim,
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
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(wishlistProvider.notifier)
                              .toggle(product.id);
                        },
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.wishlistChipBg,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(scale: anim, child: child),
                            child: Icon(
                              isWishlisted
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              key: ValueKey(isWishlisted),
                              size: 18,
                              color: isWishlisted
                                  ? AppColors.favorite
                                  : AppColors.bodyText,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
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
                  _PriceBlock(product: product),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: AppColors.star),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          product.rating.toStringAsFixed(1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.productCardMeta,
                        ),
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
      borderRadius: AppDimens.brPill,
    ),
    child: Text(text, style: AppTextStyles.badge.copyWith(fontSize: 11)),
  );
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SingleLinePrice(
          text: Formatter.price(product.price),
          style: AppTextStyles.priceCard,
        ),
        if (product.oldPrice != null) ...[
          const SizedBox(height: 2),
          _SingleLinePrice(
            text: Formatter.price(product.oldPrice!),
            style: AppTextStyles.oldPrice,
          ),
        ],
      ],
    );
  }
}

/// Thu nhỏ nhẹ khi nhấn — cảm giác "bấm được" cho cả card.
class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _SingleLinePrice extends StatelessWidget {
  const _SingleLinePrice({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: style,
        ),
      ),
    );
  }
}

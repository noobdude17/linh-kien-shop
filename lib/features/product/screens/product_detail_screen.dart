import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/product_variant.dart';
import '../../../data/product_listing_adapter.dart';
import '../../../data/models/review_model.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../features/cart/providers/cart_provider.dart';
import '../../../features/home/providers/recently_viewed_provider.dart';
import '../../../features/product/providers/compare_provider.dart';
import '../../../features/product/providers/product_providers.dart';
import '../../../features/product/providers/review_provider.dart';
import '../../../features/product/providers/wishlist_provider.dart';
import '../../../features/product/widgets/product_image_gallery.dart';
import '../../../features/product/widgets/review_card.dart';
import '../../../features/product/widgets/variant_selector.dart';
import '../utils/spec_display.dart';
import '../../../routes/app_routes.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;
  bool _isAdding = false;
  bool _tracked = false;
  ProductVariant? _selectedVariant;

  void _addToCart(ProductModel p, {required bool buyNow}) {
    if (_isAdding) return;
    final loggedIn = ref.read(authRepositoryProvider).currentUser != null;
    if (!loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng đăng nhập để mua hàng'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Đăng nhập',
            onPressed: () => context.go(AppRoutes.login),
          ),
        ),
      );
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _isAdding = true);
    ref
        .read(cartProvider.notifier)
        .add(
          p,
          qty: _qty,
          variant: _selectedVariant?.name ?? p.brand,
          variantId: _selectedVariant?.id ?? '',
          priceOverride: _selectedVariant?.price,
        );
    if (buyNow) {
      context.go(AppRoutes.checkout);
    } else {
      setState(() => _isAdding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm vào giỏ hàng'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _toggleCompare(ProductModel p) {
    final notifier = ref.read(compareProvider.notifier);
    final isIn = notifier.contains(p.id);
    if (!isIn) {
      if (notifier.atLimit) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tối đa 3 sản phẩm để so sánh'),
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }
      final cat = notifier.categoryId;
      if (cat != null && cat != p.categoryId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Chỉ so sánh sản phẩm cùng danh mục (${notifier.categoryName})',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }
    notifier.toggle(p);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isIn ? 'Đã xóa khỏi so sánh' : 'Đã thêm vào so sánh'),
        duration: const Duration(seconds: 2),
        action: isIn
            ? null
            : SnackBarAction(
                label: 'Xem',
                onPressed: () {
                  if (!mounted) return;
                  context.go(AppRoutes.compare);
                },
              ),
      ),
    );
  }

  void _showWriteReview(ProductModel p) {
    double selectedRating = 0;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Viết đánh giá',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(5, (i) {
                  final star = (i + 1).toDouble();
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedRating = star),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        i < selectedRating ? Icons.star : Icons.star_border,
                        color: AppColors.star,
                        size: 32,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Nhận xét của bạn...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusInput),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Gửi đánh giá',
                onPressed: () async {
                  if (selectedRating == 0) return;
                  final user = ref.read(authRepositoryProvider).currentUser;
                  final review = ReviewModel(
                    id: 'r_${DateTime.now().millisecondsSinceEpoch}',
                    productId: p.id,
                    userId: user?.id ?? 'me',
                    userName: user?.name.isNotEmpty == true
                        ? user!.name
                        : 'Bạn',
                    rating: selectedRating,
                    comment: controller.text.trim(),
                    createdAt: DateTime.now(),
                  );
                  Navigator.of(ctx).pop();
                  await ref.read(reviewRepositoryProvider).add(review);
                  // Tải lại đánh giá + sản phẩm để rating/số lượng cập nhật.
                  ref.invalidate(reviewProvider(p.id));
                  ref.invalidate(productDetailProvider(p.id));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return productAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const SingleChildScrollView(child: ProductDetailSkeleton()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Lỗi: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(productDetailProvider(widget.productId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
      data: (p) {
        if (p == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Không tìm thấy sản phẩm')),
          );
        }
        if (!_tracked) {
          _tracked = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(recentlyViewedProvider.notifier).add(widget.productId);
            }
          });
        }
        _selectRouteVariantIfNeeded(p);
        return _buildDetail(p);
      },
    );
  }

  void _selectRouteVariantIfNeeded(ProductModel product) {
    if (_selectedVariant != null ||
        !widget.productId.contains(productListingVariantSeparator)) {
      return;
    }
    final variantId = widget.productId
        .split(productListingVariantSeparator)
        .last;
    ProductVariant? routeVariant;
    for (final variant in product.variants) {
      if (variant.id == variantId) {
        routeVariant = variant;
        break;
      }
    }
    if (routeVariant == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedVariant == null) {
        setState(() => _selectedVariant = routeVariant);
      }
    });
  }

  Widget _buildDetail(ProductModel p) {
    final isWishlisted = ref.watch(
      wishlistProvider.select((ids) => ids.contains(p.id)),
    );
    final isComparing = ref.watch(
      compareProvider.select((list) => list.any((c) => c.id == p.id)),
    );

    // Effective price/stock based on selected variant
    final effectivePrice = _selectedVariant?.price ?? p.price;
    final effectiveOldPrice = _selectedVariant?.oldPrice ?? p.oldPrice;
    final effectiveStock = _selectedVariant != null
        ? _selectedVariant!.stock
        : p.stock;
    final effectiveInStock = _selectedVariant != null
        ? _selectedVariant!.isAvailable
        : p.inStock;
    final effectiveDiscount =
        effectiveOldPrice != null && effectiveOldPrice > effectivePrice
        ? (((effectiveOldPrice - effectivePrice) / effectiveOldPrice) * 100)
              .round()
        : null;
    // Must select variant if product has variants
    final canBuy =
        effectiveInStock &&
        (p.variants.isEmpty || _selectedVariant != null) &&
        !_isAdding;
    // Sản phẩm thật chứa thông số trong `compatibility`; helper tự fallback.
    final specs = displaySpecs(
      _selectedVariant == null ? p : p.withVariant(_selectedVariant!),
    );

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImageGallery(
                  images: [
                    if (p.primaryImageUrl.isNotEmpty) p.primaryImageUrl,
                    ...p.images.where((url) => url.trim() != p.primaryImageUrl),
                  ],
                  fallbackLabel: p.imageLabel,
                  height: AppDimens.heroImageHeight,
                  heroTag: 'product-img-${p.id}',
                ),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p.categoryName} · ${p.brand}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              Formatter.price(effectivePrice),
                              style: AppTextStyles.priceDetail,
                            ),
                            if (effectiveOldPrice != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  Formatter.price(effectiveOldPrice),
                                  style: AppTextStyles.oldPriceDetail,
                                ),
                              ),
                            if (effectiveDiscount != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '-$effectiveDiscount%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppColors.star,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${p.rating} (${p.reviewCount} đánh giá)',
                              style: AppTextStyles.meta,
                            ),
                            const SizedBox(width: 12),
                            _stockBadge(
                              effectiveInStock,
                              effectiveStock,
                              p.variants.isNotEmpty && _selectedVariant == null,
                            ),
                          ],
                        ),
                        // Variant selector
                        if (p.variants.isNotEmpty) _buildVariantSection(p),
                        if (specs.isNotEmpty) ...[
                          const Divider(height: 24),
                          Text(
                            'Thông số kỹ thuật',
                            style: AppTextStyles.sectionHeading.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildSpecTable(specs),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Số lượng',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            QuantityStepper(
                              value: _qty,
                              onChanged: canBuy
                                  ? (v) => setState(() => _qty = v)
                                  : null,
                            ),
                          ],
                        ),
                        _buildRelatedSection(p),
                        _buildReviewsSection(p),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleBtn(
                      Icons.arrow_back,
                      () => context.canPop()
                          ? context.pop()
                          : context.go(AppRoutes.home),
                    ),
                    Row(
                      children: [
                        _circleBtn(
                          Icons.compare_arrows,
                          () => _toggleCompare(p),
                          bgColor: isComparing
                              ? AppColors.accentBlue
                              : Colors.black38,
                        ),
                        const SizedBox(width: 8),
                        _circleBtn(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          () {
                            HapticFeedback.lightImpact();
                            ref.read(wishlistProvider.notifier).toggle(p.id);
                          },
                          iconColor: isWishlisted
                              ? AppColors.favorite
                              : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        _cartBtn(context),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: AppOutlinedButton(
                      label: 'Thêm giỏ hàng',
                      onPressed: canBuy
                          ? () => _addToCart(p, buyNow: false)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: _isAdding
                          ? 'Đang xử lý...'
                          : !effectiveInStock
                          ? 'Hết hàng'
                          : p.variants.isNotEmpty && _selectedVariant == null
                          ? 'Chọn phiên bản'
                          : 'Mua ngay',
                      onPressed: canBuy
                          ? () => _addToCart(p, buyNow: true)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantSection(ProductModel p) {
    final selectorLabel = switch (p.categoryId) {
      'ram' => 'Dung lượng / Tốc độ:',
      'storage' => 'Dung lượng:',
      _ => 'Phiên bản:',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              selectorLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (_selectedVariant != null)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width - 40,
                ),
                child: Text(
                  _selectedVariant!.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        VariantSelector(
          variants: p.variants,
          selected: _selectedVariant,
          onSelect: (v) => setState(() => _selectedVariant = v),
        ),
        if (_selectedVariant == null)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Vui lòng chọn một tùy chọn để tiếp tục',
              style: TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _stockBadge(bool inStock, int stock, bool pending) {
    if (pending) return const SizedBox.shrink();
    if (!inStock) return _chip('Hết hàng', AppColors.errorBg, AppColors.error);
    if (stock <= 5) {
      return _chip(
        'Sắp hết (còn $stock)',
        AppColors.warningBg,
        AppColors.warning,
      );
    }
    return _chip('Còn hàng ($stock)', AppColors.successBg, AppColors.success);
  }

  Widget _chip(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );

  Widget _buildRelatedSection(ProductModel p) {
    final relatedAsync = ref.watch(relatedProductsProvider(p.id));
    return relatedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (related) {
        if (related.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24),
            Text(
              'Sản phẩm liên quan',
              style: AppTextStyles.sectionHeading.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: related.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => SizedBox(
                  key: ValueKey(related[i].id),
                  width: 150,
                  child: ProductCard(
                    product: related[i],
                    onTap: () =>
                        context.go('${AppRoutes.detail}/${related[i].id}'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewsSection(ProductModel p) {
    final reviews =
        ref.watch(reviewProvider(p.id)).asData?.value ?? const <ReviewModel>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đánh giá (${reviews.length})',
              style: AppTextStyles.sectionHeading.copyWith(fontSize: 14),
            ),
            TextButton(
              onPressed: () => _showWriteReview(p),
              child: const Text(
                'Viết đánh giá',
                style: TextStyle(color: AppColors.accentBlue, fontSize: 13),
              ),
            ),
          ],
        ),
        if (reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Chưa có đánh giá nào',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...reviews.take(3).map((r) => ReviewCard(review: r)),
      ],
    );
  }

  Widget _buildSpecTable(Map<String, String> specs) {
    final entries = specs.entries.toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(entries.length, (i) {
          final e = entries[i];
          return Container(
            color: i.isEven ? AppColors.background : AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    formatSpecLabel(e.key),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _circleBtn(
    IconData icon,
    VoidCallback onTap, {
    Color bgColor = Colors.black38,
    Color iconColor = Colors.white,
  }) => InkWell(
    onTap: onTap,
    child: CircleAvatar(
      radius: 20,
      backgroundColor: bgColor,
      child: Icon(icon, color: iconColor, size: 20),
    ),
  );

  Widget _cartBtn(BuildContext context) {
    final count = ref.watch(cartCountProvider);
    return InkWell(
      onTap: () => context.go(AppRoutes.cart),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.black38,
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          if (count > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
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
    );
  }
}

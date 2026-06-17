import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/product_model.dart';
import '../../../features/cart/providers/cart_provider.dart';
import '../../../routes/app_routes.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;

  void _addToCart(ProductModel p, {required bool buyNow}) {
    ref.read(cartProvider.notifier).add(p, qty: _qty, variant: p.brand);
    if (buyNow) {
      context.go(AppRoutes.cart);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm vào giỏ hàng'), duration: Duration(seconds: 1)),
      );
    }
  }

  ProductModel get _product {
    final all = [...MockData.featured, ...MockData.gpuList];
    return all.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => MockData.featured.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _product;
    final discount = p.discountPercent;
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ImagePlaceholder(label: p.imageLabel, height: AppDimens.heroImageHeight, radius: 0),
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${p.categoryName} · ${p.brand}',
                            style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(p.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(Formatter.price(p.price), style: AppTextStyles.priceDetail),
                            const SizedBox(width: 8),
                            if (p.oldPrice != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(Formatter.price(p.oldPrice!), style: AppTextStyles.oldPrice.copyWith(fontSize: 14)),
                              ),
                            const SizedBox(width: 8),
                            if (discount != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(4)),
                                child: Text('-$discount%',
                                    style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.star, size: 16),
                            const SizedBox(width: 4),
                            Text('${p.rating} (${p.reviewCount} đánh giá)', style: AppTextStyles.meta),
                            const SizedBox(width: 12),
                            if (p.inStock)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(10)),
                                child: const Text('✓ Còn hàng',
                                    style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text('Thông số kỹ thuật', style: AppTextStyles.sectionHeading.copyWith(fontSize: 14)),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 3,
                          children: p.specs.entries.map((e) => _specTile(e.key, e.value)).toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Số lượng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            QuantityStepper(value: _qty, onChanged: (v) => setState(() => _qty = v)),
                          ],
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating top buttons
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleBtn(Icons.arrow_back, () => context.go(AppRoutes.list)),
                    _circleBtn(Icons.favorite_border, () => context.go(AppRoutes.wishlist)),
                  ],
                ),
              ),
            ),
          ),
          // Sticky bottom actions
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Row(
                children: [
                  Expanded(child: AppOutlinedButton(label: '🛒 Giỏ hàng', onPressed: () => _addToCart(p, buyNow: false))),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: PrimaryButton(label: 'Mua ngay', onPressed: () => _addToCart(p, buyNow: true))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specTile(String label, String value) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _circleBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.black38,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/product_model.dart';
import '../../../routes/app_routes.dart';

class AdminProductListScreen extends StatelessWidget {
  const AdminProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = MockData.featured;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.adminAccent,
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.go(AppRoutes.admin)),
        title: const Text('Quản lý sản phẩm'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        children: products.map((p) => _row(context, p)).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.adminAccent,
        onPressed: () => context.go(AppRoutes.adminProductEdit),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _row(BuildContext context, ProductModel p) {
    final outOfStock = !p.inStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.brCard,
        boxShadow: AppDimens.cardShadow,
      ),
      child: Row(
        children: [
          ImagePlaceholder(
            label: p.imageLabel,
            imageUrl: p.primaryImageUrl,
            width: 54,
            height: 54,
            radius: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  p.categoryName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      Formatter.price(p.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: outOfStock
                            ? AppColors.errorBg
                            : AppColors.successBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        outOfStock ? 'Hết hàng' : 'Còn ${p.stock}',
                        style: TextStyle(
                          color: outOfStock
                              ? AppColors.error
                              : AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary, size: 20),
            onPressed: () => context.go(AppRoutes.adminProductEdit),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 20,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

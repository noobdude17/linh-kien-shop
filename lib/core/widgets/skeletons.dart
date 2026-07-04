import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Khối xám bo góc — viên gạch cơ bản của mọi skeleton.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? radius;

  const SkeletonBox({super.key, this.width, required this.height, this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius ?? BorderRadius.circular(8),
      ),
    );
  }
}

/// Bọc shimmer chung — mọi skeleton dùng cùng màu/tốc độ.
class ShimmerWrap extends StatelessWidget {
  final Widget child;

  const ShimmerWrap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.inputFill,
      highlightColor: AppColors.surface,
      child: child,
    );
  }
}

/// Skeleton một product card (khớp layout ProductCard: ảnh + tên 2 dòng + giá).
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.brCard,
        boxShadow: AppDimens.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: ShimmerWrap(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(
              width: double.infinity,
              height: AppDimens.productImageHeight,
              radius: BorderRadius.zero,
            ),
            Padding(
              padding: const EdgeInsets.all(AppDimens.gap),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: double.infinity, height: 12),
                  SizedBox(height: 6),
                  SkeletonBox(width: 120, height: 12),
                  SizedBox(height: 12),
                  SkeletonBox(width: 80, height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lưới skeleton 2 cột — thay spinner khi tải danh sách sản phẩm.
class ProductGridSkeleton extends StatelessWidget {
  final int count;

  const ProductGridSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppDimens.screenPadding),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDimens.gap,
        crossAxisSpacing: AppDimens.gap,
        childAspectRatio: AppDimens.productGridAspectRatio(context),
      ),
      itemCount: count,
      itemBuilder: (_, _) => const ProductCardSkeleton(),
    );
  }
}

/// Skeleton dạng hàng (ảnh vuông + 2 dòng chữ) — cho list đơn hàng, linh kiện…
class ListTileSkeleton extends StatelessWidget {
  final int count;

  const ListTileSkeleton({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimens.screenPadding),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimens.gap),
      itemBuilder: (_, _) => Container(
        padding: const EdgeInsets.all(AppDimens.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimens.brCard,
          boxShadow: AppDimens.cardShadow,
        ),
        child: ShimmerWrap(
          child: Row(
            children: [
              const SkeletonBox(width: 56, height: 56),
              const SizedBox(width: AppDimens.gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: double.infinity, height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(width: 140, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton trang chi tiết sản phẩm: ảnh hero + các dòng nội dung.
class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(
            width: double.infinity,
            height: AppDimens.heroImageHeight,
            radius: BorderRadius.zero,
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimens.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: double.infinity, height: 18),
                SizedBox(height: 10),
                SkeletonBox(width: 200, height: 18),
                SizedBox(height: 20),
                SkeletonBox(width: 120, height: 22),
                SizedBox(height: 24),
                SkeletonBox(width: double.infinity, height: 12),
                SizedBox(height: 8),
                SkeletonBox(width: double.infinity, height: 12),
                SizedBox(height: 8),
                SkeletonBox(width: 240, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hàng chip danh mục skeleton (home, cao 92).
class CategoryRowSkeleton extends StatelessWidget {
  const CategoryRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.screenPadding,
        ),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimens.gap),
        itemBuilder: (_, _) => Column(
          children: const [
            SkeletonBox(
              width: 56,
              height: 56,
              radius: BorderRadius.all(Radius.circular(16)),
            ),
            SizedBox(height: 8),
            SkeletonBox(width: 48, height: 10),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/category_model.dart';
import '../../../features/product/providers/product_providers.dart';
import '../../../routes/app_routes.dart';

/// Danh mục: 3 slider ngang cuộn độc lập — Thương hiệu, Danh mục sản phẩm,
/// Sản phẩm thịnh hành.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final trending = ref.watch(featuredProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh mục'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go(AppRoutes.search),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 1 · Thương hiệu (logo, không tên)
          _Slider(
            title: 'Thương hiệu',
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding,
              ),
              itemCount: MockData.brands.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final (name, logo) = MockData.brands[i];
                return _BrandTile(
                  name: name,
                  logo: logo,
                  onTap: () => context.push(
                    '${AppRoutes.results}?q=${Uri.encodeComponent(name)}',
                  ),
                );
              },
            ),
          ),

          // 2 · Danh mục sản phẩm (icon + tên)
          _AsyncSlider(
            title: 'Danh mục sản phẩm',
            height: 112,
            value: categories,
            builder: (list) => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding,
              ),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _TypeTile(
                category: list[i] as CategoryModel,
                onTap: () =>
                    context.push('${AppRoutes.list}?categoryId=${list[i].id}'),
              ),
            ),
          ),

          // 3 · Sản phẩm thịnh hành (ảnh + tên + giá)
          _AsyncSlider(
            title: 'Sản phẩm thịnh hành',
            height: 264,
            value: trending,
            builder: (list) => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPadding,
              ),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(
                width: 160,
                child: ProductCard(
                  product: list[i],
                  onTap: () =>
                      context.push('${AppRoutes.detail}/${list[i].id}'),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

/// Khung 1 slider: tiêu đề + vùng cuộn ngang cao cố định.
class _Slider extends StatelessWidget {
  final String title;
  final double height;
  final Widget child;

  const _Slider({
    required this.title,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.screenPadding,
            8,
            AppDimens.screenPadding,
            0,
          ),
          child: SectionHeader(title: title),
        ),
        SizedBox(height: height, child: child),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Như [_Slider] nhưng bọc một AsyncValue (loading/error/data).
class _AsyncSlider extends StatelessWidget {
  final String title;
  final double height;
  final AsyncValue<List<dynamic>> value;
  final Widget Function(List<dynamic> list) builder;

  const _AsyncSlider({
    required this.title,
    required this.height,
    required this.value,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return _Slider(
      title: title,
      height: height,
      child: value.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: builder,
      ),
    );
  }
}

class _BrandTile extends StatelessWidget {
  final String name;
  final String logo;
  final VoidCallback onTap;

  const _BrandTile({
    required this.name,
    required this.logo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimens.brCard,
      child: Container(
        width: 88,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimens.brCard,
          border: Border.all(color: AppColors.border),
          boxShadow: AppDimens.cardShadow,
        ),
        alignment: Alignment.center,
        child: Image.asset(
          logo,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _TypeTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.categoryBgs[category.colorIndex %
        AppColors.categoryBgs.length];
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimens.brCard,
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: AppDimens.brCard,
              ),
              alignment: Alignment.center,
              child: Text(category.icon, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

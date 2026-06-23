import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../features/product/providers/product_providers.dart';
import '../../../routes/app_routes.dart';
import '../widgets/category_chip.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

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
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (list) => GridView.builder(
          padding: const EdgeInsets.all(AppDimens.screenPadding),
          itemCount: list.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: AppDimens.gap,
            crossAxisSpacing: AppDimens.gap,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (_, i) => CategoryChip(
            category: list[i],
            onTap: () =>
                context.go('${AppRoutes.list}?categoryId=${list[i].id}'),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../data/mock_data.dart';
import '../../../routes/app_routes.dart';
import '../widgets/category_chip.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        mainAxisSpacing: AppDimens.gap,
        crossAxisSpacing: AppDimens.gap,
        childAspectRatio: 0.85,
        children: MockData.categories
            .map((c) => CategoryChip(
                  category: c,
                  onTap: () => context.go('${AppRoutes.list}?categoryId=${c.id}'),
                ))
            .toList(),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1, cartCount: 3),
    );
  }
}

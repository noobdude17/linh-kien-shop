import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/product_card.dart';
import '../../../data/mock_data.dart';
import '../../../routes/app_routes.dart';

class ProductListScreen extends StatefulWidget {
  final String? categoryId;
  const ProductListScreen({super.key, this.categoryId});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  static const _filters = ['Tất cả', 'NVIDIA', 'AMD', 'RTX 40 Series', 'Dưới 10tr'];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
        title: const Text('Card đồ họa (GPU)'),
        actions: [IconButton(icon: const Icon(Icons.tune), onPressed: () {})],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => AppChip(
                  label: _filters[i],
                  selected: i == _selected,
                  onTap: () => setState(() => _selected = i),
                ),
              ),
            ),
          ),
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('12 sản phẩm', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Text('Sắp xếp: Phổ biến ▾',
                    style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              mainAxisSpacing: AppDimens.gap,
              crossAxisSpacing: AppDimens.gap,
              childAspectRatio: 0.62,
              children: MockData.gpuList
                  .map((p) => ProductCard(
                        product: p,
                        onTap: () => context.go('${AppRoutes.detail}/${p.id}'),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

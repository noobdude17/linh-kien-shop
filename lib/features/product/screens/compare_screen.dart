import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../data/models/product_model.dart';
import '../providers/compare_provider.dart';
import '../../../routes/app_routes.dart';

class CompareScreen extends ConsumerWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(compareProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
        title: const Text('So sánh sản phẩm'),
        actions: [
          if (products.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(compareProvider.notifier).clear(),
              child: const Text('Xóa tất cả',
                  style: TextStyle(color: AppColors.accent)),
            ),
        ],
      ),
      body: products.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.compare_arrows,
                      size: 64, color: AppColors.border),
                  SizedBox(height: 16),
                  Text('Chưa chọn sản phẩm để so sánh',
                      style: TextStyle(color: AppColors.textSecondary)),
                  SizedBox(height: 6),
                  Text('Tối đa 3 sản phẩm',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductHeaderRow(products: products, ref: ref),
                  const SizedBox(height: 16),
                  _CompareRow(
                    label: 'Giá',
                    values: products
                        .map((p) => Formatter.price(p.price))
                        .toList(),
                  ),
                  _CompareRow(
                    label: 'Đánh giá',
                    values: products
                        .map((p) =>
                            '${p.rating}★ (${p.reviewCount})')
                        .toList(),
                  ),
                  _CompareRow(
                    label: 'Tồn kho',
                    values: products
                        .map((p) => p.inStock ? 'Còn (${p.stock})' : 'Hết')
                        .toList(),
                  ),
                  _CompareRow(
                    label: 'Thương hiệu',
                    values: products.map((p) => p.brand).toList(),
                  ),
                  if (products.any((p) => p.specs.isNotEmpty)) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Thông số kỹ thuật',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    ..._buildSpecRows(products),
                  ],
                ],
              ),
            ),
    );
  }

  List<Widget> _buildSpecRows(List<ProductModel> products) {
    final allKeys = <String>{};
    for (final p in products) {
      allKeys.addAll(p.specs.keys);
    }
    return allKeys
        .map((key) => _CompareRow(
              label: key,
              values: products.map((p) => p.specs[key] ?? '—').toList(),
            ))
        .toList();
  }
}

class _ProductHeaderRow extends StatelessWidget {
  final List<ProductModel> products;
  final WidgetRef ref;
  const _ProductHeaderRow({required this.products, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 90),
          ...products.map(
            (p) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ImagePlaceholder(
                            label: p.imageLabel, height: 100, radius: 8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    GestureDetector(
                      onTap: () => ref.read(compareProvider.notifier).toggle(p),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.close,
                            size: 16, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final List<String> values;
  const _CompareRow({required this.label, required this.values});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ),
          ...values.map(
            (v) => Expanded(
              child: Text(v,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

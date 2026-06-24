import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/product_card.dart';
import '../../../data/models/product_model.dart';
import '../../../features/product/providers/product_providers.dart';
import '../../../routes/app_routes.dart';

enum _SortOption {
  popular('Phổ biến', Icons.local_fire_department_outlined),
  priceAsc('Giá tăng dần', Icons.arrow_upward),
  priceDesc('Giá giảm dần', Icons.arrow_downward);

  const _SortOption(this.label, this.icon);
  final String label;
  final IconData icon;
}

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String query;
  const SearchResultsScreen({super.key, required this.query});

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  int _selected = 0;
  _SortOption _sort = _SortOption.popular;

  List<String> _buildBrandLabels(List<ProductModel> products) {
    final brands = products
        .map((p) => p.brand)
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['Tất cả', ...brands];
  }

  List<ProductModel> _applyBrandFilter(
      List<ProductModel> list, List<String> labels) {
    if (_selected == 0) return list;
    final label = labels[_selected];
    return list.where((p) => p.brand == label).toList();
  }

  List<ProductModel> _applySort(List<ProductModel> list) {
    final sorted = List<ProductModel>.from(list);
    switch (_sort) {
      case _SortOption.popular:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      case _SortOption.priceAsc:
        sorted.sort((a, b) => a.price.compareTo(b.price));
      case _SortOption.priceDesc:
        sorted.sort((a, b) => b.price.compareTo(a.price));
    }
    return sorted;
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Sắp xếp',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            ..._SortOption.values.map(
              (opt) => ListTile(
                leading: Icon(opt.icon,
                    color: _sort == opt
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 20),
                title: Text(opt.label,
                    style: TextStyle(
                        color: _sort == opt
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: _sort == opt
                            ? FontWeight.w600
                            : FontWeight.normal)),
                trailing: _sort == opt
                    ? const Icon(Icons.check,
                        color: AppColors.primary, size: 18)
                    : null,
                onTap: () {
                  setState(() => _sort = opt);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchProvider(widget.query));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.search),
        ),
        title: results.maybeWhen(
          data: (list) => Text(
            'Kết quả cho "${widget.query}" (${list.length})',
            style: const TextStyle(fontSize: 15),
          ),
          orElse: () => Text(
            'Tìm kiếm "${widget.query}"',
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ),
      body: results.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Lỗi: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(searchProvider(widget.query)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off_rounded,
                        size: 72, color: AppColors.textTertiary),
                    const SizedBox(height: 24),
                    const Text('Không tìm thấy sản phẩm',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      'Thử từ khóa khác hoặc kiểm tra lại chính tả',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Thử từ khóa khác',
                      onPressed: () => context.go(AppRoutes.search),
                    ),
                  ],
                ),
              ),
            );
          }

          final labels = _buildBrandLabels(list);
          final clampedSelected = _selected.clamp(0, labels.length - 1);
          final filtered =
              _applySort(_applyBrandFilter(list, labels));

          return Column(
            children: [
              // Brand filter chips
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: labels.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => AppChip(
                      label: labels[i],
                      selected: i == clampedSelected,
                      onTap: () => setState(() => _selected = i),
                    ),
                  ),
                ),
              ),
              // Count + sort row
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${filtered.length} sản phẩm',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    GestureDetector(
                      onTap: _showSortSheet,
                      child: Row(
                        children: [
                          Text('Sắp xếp: ${_sort.label}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 2),
                          const Icon(Icons.keyboard_arrow_down,
                              color: AppColors.primary, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('Không có sản phẩm'))
                    : GridView.builder(
                        padding:
                            const EdgeInsets.all(AppDimens.screenPadding),
                        itemCount: filtered.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppDimens.gap,
                          crossAxisSpacing: AppDimens.gap,
                          childAspectRatio: 0.62,
                        ),
                        itemBuilder: (_, i) => ProductCard(
                          key: ValueKey(filtered[i].id),
                          product: filtered[i],
                          onTap: () => context
                              .push('${AppRoutes.detail}/${filtered[i].id}'),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

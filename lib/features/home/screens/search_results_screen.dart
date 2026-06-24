import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/product_card.dart';
import '../../../features/product/providers/product_providers.dart';
import '../../../routes/app_routes.dart';

class SearchResultsScreen extends ConsumerWidget {
  final String query;
  const SearchResultsScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchProvider(query));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.search),
        ),
        title: results.maybeWhen(
          data: (list) => Text(
            'Kết quả cho "$query" (${list.length})',
            style: const TextStyle(fontSize: 15),
          ),
          orElse: () => Text(
            'Tìm kiếm "$query"',
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
                onPressed: () => ref.invalidate(searchProvider(query)),
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
          return GridView.builder(
            padding: const EdgeInsets.all(AppDimens.screenPadding),
            itemCount: list.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppDimens.gap,
              crossAxisSpacing: AppDimens.gap,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (_, i) => ProductCard(
              product: list[i],
              onTap: () => context.push('${AppRoutes.detail}/${list[i].id}'),
            ),
          );
        },
      ),
    );
  }
}

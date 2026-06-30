import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../routes/app_routes.dart';
import '../providers/search_history_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    ref.read(recentSearchesProvider.notifier).add(q);
    context.push('${AppRoutes.results}?q=${Uri.encodeComponent(q)}');
  }

  @override
  Widget build(BuildContext context) {
    final recent = ref.watch(recentSearchesProvider);
    final trending = ref.watch(trendingSearchesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
        titleSpacing: 0,
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textTertiary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _submit,
                  decoration: const InputDecoration(
                    hintText: 'Tìm sản phẩm...',
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_controller.text.trim().isNotEmpty) {
                    _submit(_controller.text);
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
                child: const Icon(
                  Icons.close,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (recent.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tìm kiếm gần đây', style: AppTextStyles.sectionHeading),
                GestureDetector(
                  onTap: () =>
                      ref.read(recentSearchesProvider.notifier).clear(),
                  child: const Text(
                    'Xóa tất cả',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recent
                  .map((s) => AppChip(label: s, onTap: () => _submit(s)))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          Text('Xu hướng', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 12),
          trending.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
            data: (list) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: list
                  .map(
                    (s) => AppChip(
                      label: s,
                      trending: true,
                      onTap: () => _submit(s),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

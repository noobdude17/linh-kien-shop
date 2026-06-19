import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../data/mock_data.dart';
import '../../../routes/app_routes.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
        titleSpacing: 0,
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              const Icon(Icons.search, color: AppColors.textTertiary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Tìm sản phẩm...',
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.results),
                child: const Icon(Icons.close, color: AppColors.textTertiary, size: 20),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Tìm kiếm gần đây', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MockData.recentSearches
                .map((s) => AppChip(label: s, onTap: () => context.go(AppRoutes.results)))
                .toList(),
          ),
          const SizedBox(height: 24),
          Text('🔥 Xu hướng', style: AppTextStyles.sectionHeading),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MockData.trendingSearches
                .map((s) => AppChip(label: s, trending: true, onTap: () => context.go(AppRoutes.results)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../routes/app_routes.dart';
import '../providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminDashboardProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.adminAccent,
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
        title: const Text('Quản trị'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(adminDashboardProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: 'Không tải được dashboard',
          onRetry: () => ref.invalidate(adminDashboardProvider),
        ),
        data: (s) => ListView(
          padding: const EdgeInsets.all(AppDimens.screenPadding),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppDimens.gap,
              crossAxisSpacing: AppDimens.gap,
              childAspectRatio: 1.55,
              children: [
                _statCard('Sản phẩm đang bán', '${s.activeProducts}'),
                _statCard('Tổng đơn hàng', '${s.totalOrders}'),
                _statCard('Đơn chờ xử lý', '${s.pendingOrders}'),
                _statCard('Doanh thu', Formatter.price(s.deliveredRevenue)),
              ],
            ),
            const SizedBox(height: 16),
            _RevenueChart(values: s.revenue7d),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _quickAction(
                  context,
                  Icons.inventory_2_outlined,
                  'Sản phẩm',
                  AppRoutes.adminProducts,
                ),
                _quickAction(
                  context,
                  Icons.receipt_long_outlined,
                  'Đơn hàng',
                  AppRoutes.adminOrders,
                ),
                _quickAction(
                  context,
                  Icons.people_outline,
                  'Người dùng',
                  AppRoutes.adminUsers,
                ),
                _quickAction(
                  context,
                  Icons.rate_review_outlined,
                  'Đánh giá',
                  AppRoutes.adminReviews,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) => Container(
    padding: const EdgeInsets.all(AppDimens.cardPaddingLg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppDimens.brCard,
      border: const Border(
        left: BorderSide(color: AppColors.adminAccent, width: 3),
      ),
      boxShadow: AppDimens.cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );

  Widget _quickAction(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 52) / 2,
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: AppDimens.brCard,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.adminAccent,
            borderRadius: AppDimens.brCard,
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<double>(0, (max, v) => v > max ? v : max);
    const labels = ['T-6', 'T-5', 'T-4', 'T-3', 'T-2', 'T-1', 'Hôm nay'];
    return Container(
      padding: const EdgeInsets.all(AppDimens.cardPaddingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.brCard,
        boxShadow: AppDimens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh thu 7 ngày',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(values.length, (i) {
                final height = maxValue == 0
                    ? 8.0
                    : 8 + values[i] / maxValue * 92;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 22,
                      height: height,
                      decoration: const BoxDecoration(
                        color: AppColors.accentBlue,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 38,
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

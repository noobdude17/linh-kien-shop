import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../data/mock_data.dart';
import '../../../routes/app_routes.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.adminAccent,
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
        title: const Text('Quản trị'),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.build))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppDimens.gap,
            crossAxisSpacing: AppDimens.gap,
            childAspectRatio: 1.7,
            children: MockData.adminStats.map((s) => _statCard(s)).toList(),
          ),
          const SizedBox(height: 16),
          _revenueChart(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _quickAction('📦 Quản lý sản phẩm', AppColors.primary, () => context.go(AppRoutes.adminProducts))),
              const SizedBox(width: 12),
              Expanded(child: _quickAction('🧾 Quản lý đơn hàng', AppColors.adminAccent, () => context.go(AppRoutes.adminOrders))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(Map<String, dynamic> s) => Container(
        padding: const EdgeInsets.all(AppDimens.cardPaddingLg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimens.brCard,
          border: const Border(left: BorderSide(color: AppColors.adminAccent, width: 3)),
          boxShadow: AppDimens.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(s['label'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text(s['value'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
      );

  Widget _revenueChart() => Container(
        padding: const EdgeInsets.all(AppDimens.cardPaddingLg),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppDimens.brCard, boxShadow: AppDimens.cardShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Doanh thu 7 ngày', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(MockData.revenue7d.length, (i) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 22,
                        height: MockData.revenue7d[i],
                        decoration: const BoxDecoration(
                          color: AppColors.accentBlue,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(MockData.revenueDays[i], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      );

  Widget _quickAction(String label, Color color, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: color, borderRadius: AppDimens.brCard),
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      );
}

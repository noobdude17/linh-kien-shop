import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/order_model.dart';
import '../../../routes/app_routes.dart';

class AdminOrderManagementScreen extends StatelessWidget {
  const AdminOrderManagementScreen({super.key});

  static const _tabs = ['Tất cả', 'Chờ xác nhận', 'Đang giao', 'Hoàn thành'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.adminAccent,
          foregroundColor: Colors.white,
          leading: BackButton(onPressed: () => context.go(AppRoutes.admin)),
          title: const Text('Quản lý đơn hàng'),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            tabAlignment: TabAlignment.start,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppDimens.screenPadding),
          children: MockData.adminOrders().map((o) => _row(context, o)).toList(),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, OrderModel o) => InkWell(
        onTap: () => context.go(AppRoutes.adminOrderDetail),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(AppDimens.cardPaddingLg),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppDimens.brCard, boxShadow: AppDimens.cardShadow),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(o.code, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  StatusBadge(status: o.status),
                ],
              ),
              const SizedBox(height: 6),
              Text('👤 ${o.customerName} · ${Formatter.date(o.createdAt)} · ${o.itemCount} SP',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng tiền', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(Formatter.price(o.totalAmount),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      );
}

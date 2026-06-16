import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/order_model.dart';
import '../../../routes/app_routes.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  static const _tabs = ['Tất cả', 'Chờ xác nhận', 'Đang giao', 'Hoàn thành', 'Đã hủy'];

  @override
  Widget build(BuildContext context) {
    final orders = MockData.orders();
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
          title: const Text('Đơn hàng của tôi'),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            tabAlignment: TabAlignment.start,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppDimens.screenPadding),
          children: orders.map((o) => _orderCard(context, o)).toList(),
        ),
      ),
    );
  }

  Widget _orderCard(BuildContext context, OrderModel o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          const SizedBox(height: 12),
          Row(
            children: [
              ImagePlaceholder(label: o.items.isNotEmpty ? o.items.first.imageLabel : '', height: 48, radius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.items.isNotEmpty
                          ? '${o.items.first.name}${o.items.length > 1 ? ' và ${o.items.length - 1} sản phẩm khác' : ''}'
                          : 'Đơn hàng',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(Formatter.date(o.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng tiền', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(Formatter.price(o.totalAmount),
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('${AppRoutes.orderDetail}/${o.id}'),
                  child: const Text('Xem chi tiết'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(onPressed: () {}, child: const Text('Mua lại')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/order_model.dart';
import '../../../routes/app_routes.dart';
import '../providers/order_providers.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  static const _tabs = [
    ('Tất cả', null),
    ('Chờ xác nhận', AppConstants.statusPending),
    ('Đang giao', AppConstants.statusShipping),
    ('Hoàn thành', AppConstants.statusDelivered),
    ('Đã hủy', AppConstants.statusCancelled),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
          title: const Text('Đơn hàng của tôi'),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textTertiary,
            tabAlignment: TabAlignment.start,
            tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
          ),
        ),
        body: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.textTertiary),
                const SizedBox(height: 12),
                Text('Không tải được đơn hàng',
                    style:
                        const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(userOrdersProvider),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
          data: (orders) => TabBarView(
            children: _tabs.map((tab) {
              final filtered = tab.$2 == null
                  ? orders
                  : orders
                      .where((o) => o.status == tab.$2)
                      .toList();
              return filtered.isEmpty
                  ? const Center(
                      child: Text('Không có đơn hàng',
                          style: TextStyle(
                              color: AppColors.textSecondary)),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.refresh(userOrdersProvider.future),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(
                            AppDimens.screenPadding),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) =>
                            _orderCard(context, filtered[i]),
                      ),
                    );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _orderCard(BuildContext context, OrderModel o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppDimens.cardPaddingLg),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimens.brCard,
          boxShadow: AppDimens.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(o.code,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              StatusBadge(status: o.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ImagePlaceholder(
                  label: o.items.isNotEmpty
                      ? o.items.first.imageLabel
                      : '',
                  height: 48,
                  radius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.items.isNotEmpty
                          ? '${o.items.first.name}'
                              '${o.items.length > 1 ? ' và ${o.items.length - 1} sản phẩm khác' : ''}'
                          : 'Đơn hàng',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(Formatter.date(o.createdAt),
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng tiền',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              Text(Formatter.price(o.totalAmount),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      context.go('${AppRoutes.orderDetail}/${o.id}'),
                  child: const Text('Xem chi tiết'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                    onPressed: () {}, child: const Text('Mua lại')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../routes/app_routes.dart';
import '../providers/admin_providers.dart';

class AdminOrderManagementScreen extends ConsumerStatefulWidget {
  const AdminOrderManagementScreen({super.key});

  @override
  ConsumerState<AdminOrderManagementScreen> createState() =>
      _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState
    extends ConsumerState<AdminOrderManagementScreen> {
  final _search = TextEditingController();
  String? _status;

  static const _statuses = <(String, String?)>[
    ('Tất cả', null),
    ('Chờ xác nhận', AppConstants.statusPending),
    ('Đã xác nhận', AppConstants.statusConfirmed),
    ('Đang giao', AppConstants.statusShipping),
    ('Hoàn thành', AppConstants.statusDelivered),
    ('Đã hủy', AppConstants.statusCancelled),
  ];

  AdminOrderQuery get _query =>
      AdminOrderQuery(search: _search.text.trim(), status: _status, limit: 80);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(adminOrdersProvider(_query));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.adminAccent,
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.go(AppRoutes.admin)),
        title: const Text('Quản lý đơn hàng'),
      ),
      body: Column(
        children: [
          _filters(),
          Expanded(
            child: orders.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _error('Không tải được đơn hàng'),
              data: (page) => page.items.isEmpty
                  ? const Center(child: Text('Không có đơn hàng'))
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(adminOrdersProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppDimens.screenPadding),
                        itemCount: page.items.length,
                        itemBuilder: (_, i) => _row(page.items[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              hintText: 'Tìm mã đơn hoặc khách hàng',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final item = _statuses[i];
                return ChoiceChip(
                  label: Text(item.$1),
                  selected: _status == item.$2,
                  onSelected: (_) => setState(() => _status = item.$2),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(OrderModel o) => InkWell(
    onTap: () => context.go('${AppRoutes.adminOrderDetail}/${o.id}'),
    borderRadius: AppDimens.brCard,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppDimens.cardPaddingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.brCard,
        boxShadow: AppDimens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                o.code,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              StatusBadge(status: o.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${o.customerName} · ${Formatter.date(o.createdAt)} · ${o.itemCount} SP',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng tiền',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                Formatter.price(o.totalAmount),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _error(String message) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => ref.invalidate(adminOrdersProvider),
          child: const Text('Thử lại'),
        ),
      ],
    ),
  );
}

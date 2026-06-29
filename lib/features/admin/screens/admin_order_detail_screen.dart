import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/summary_row.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../routes/app_routes.dart';
import '../providers/admin_providers.dart';

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState
    extends ConsumerState<AdminOrderDetailScreen> {
  String? _nextStatus;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(adminOrderProvider(widget.orderId));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.adminAccent,
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.go(AppRoutes.adminOrders)),
        title: Text(order.valueOrNull?.code ?? 'Chi tiết đơn'),
      ),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _error('Không tải được đơn hàng'),
        data: (o) => o == null ? _error('Không tìm thấy đơn hàng') : _body(o),
      ),
    );
  }

  Widget _body(OrderModel order) {
    final options = _allowedNextStatuses(order.status);
    _nextStatus ??= options.isEmpty ? null : options.first;
    return ListView(
      padding: const EdgeInsets.all(AppDimens.screenPadding),
      children: [
        _card(
          'Khách hàng',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.customerName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                order.userId,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              StatusBadge(status: order.status),
            ],
          ),
        ),
        _card(
          'Địa chỉ giao hàng',
          Text(
            order.address,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        _card(
          'Sản phẩm',
          Column(
            children: order.items
                .map(
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${i.name}${i.variant.isNotEmpty ? ' · ${i.variant}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          'x${i.quantity}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Formatter.price(i.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        _card(
          '',
          Column(
            children: [
              SummaryRow(label: 'Thanh toán', value: _paymentLabel(order)),
              SummaryRow(
                label: 'Tạm tính',
                value: Formatter.price(order.subtotal),
              ),
              if (order.discount > 0)
                SummaryRow(
                  label: 'Giảm giá',
                  value: '-${Formatter.price(order.discount)}',
                ),
              const Divider(),
              SummaryRow(
                label: 'Tổng cộng',
                value: Formatter.price(order.totalAmount),
                isTotal: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Cập nhật trạng thái',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 8),
        if (options.isEmpty)
          const Text(
            'Đơn hàng đã ở trạng thái cuối.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else ...[
          DropdownButtonFormField<String>(
            initialValue: _nextStatus,
            decoration: const InputDecoration(
              labelText: 'Trạng thái tiếp theo',
            ),
            items: options
                .map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(OrderStatusLabel.map[status] ?? status),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _nextStatus = value),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminAccent,
              ),
              onPressed: _saving ? null : () => _update(order),
              child: Text(_saving ? 'Đang cập nhật...' : 'Cập nhật trạng thái'),
            ),
          ),
        ],
      ],
    );
  }

  List<String> _allowedNextStatuses(String current) {
    const all = [
      AppConstants.statusConfirmed,
      AppConstants.statusShipping,
      AppConstants.statusDelivered,
      AppConstants.statusCancelled,
    ];
    return all.where((status) => canTransitionOrder(current, status)).toList();
  }

  String _paymentLabel(OrderModel order) {
    final method = order.paymentMethod == AppConstants.payCod ? 'COD' : 'VNPay';
    return '$method · ${order.paid ? 'Đã thanh toán' : 'Chưa thanh toán'}';
  }

  Future<void> _update(OrderModel order) async {
    final next = _nextStatus;
    if (next == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật trạng thái?'),
        content: Text(
          '${OrderStatusLabel.map[order.status] ?? order.status} → ${OrderStatusLabel.map[next] ?? next}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).updateOrderStatus(order.id, next);
      _nextStatus = null;
      invalidateAdminData(ref);
      ref.invalidate(adminOrderProvider(order.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật trạng thái')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _card(String title, Widget child) => Container(
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
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        child,
      ],
    ),
  );

  Widget _error(String message) => Center(
    child: Text(
      message,
      style: const TextStyle(color: AppColors.textSecondary),
    ),
  );
}

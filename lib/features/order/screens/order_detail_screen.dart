import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/summary_row.dart';
import '../../../data/models/order_model.dart';
import '../../../routes/app_routes.dart';
import '../providers/order_providers.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.orders)),
        title: const Text('Chi tiết đơn hàng'),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 12),
              const Text(
                'Không tải được đơn hàng',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (order) {
          if (order == null) {
            return const Center(
              child: Text(
                'Không tìm thấy đơn hàng',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return _OrderDetailBody(order: order);
        },
      ),
    );
  }
}

class _OrderDetailBody extends ConsumerStatefulWidget {
  final OrderModel order;
  const _OrderDetailBody({required this.order});

  @override
  ConsumerState<_OrderDetailBody> createState() => _OrderDetailBodyState();
}

class _OrderDetailBodyState extends ConsumerState<_OrderDetailBody> {
  OrderModel get order => widget.order;
  bool _cancelling = false;

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: Text('Xác nhận hủy đơn ${order.code}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hủy đơn',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(orderRepositoryProvider).cancelOrder(order.id);
      ref.invalidate(userOrdersProvider);
      ref.invalidate(orderDetailProvider(order.id));
      if (mounted) context.go(AppRoutes.orders);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hủy thất bại: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _cancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildTimeline();
    final isCancellable =
        order.status == AppConstants.statusPending ||
        order.status == AppConstants.statusConfirmed;

    return ListView(
      padding: const EdgeInsets.all(AppDimens.screenPadding),
      children: [
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  _statusChip(order.status),
                ],
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < steps.length; i++)
                _timelineStep(steps[i], isLast: i == steps.length - 1),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Địa chỉ giao hàng',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                order.customerName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                order.address,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sản phẩm',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.quantity > 1
                              ? '${item.name} x${item.quantity}'
                              : item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Formatter.price(item.price * item.quantity),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _card(
          Column(
            children: [
              SummaryRow(
                label: 'Tổng tiền hàng',
                value: Formatter.price(order.subtotal),
              ),
              if (order.discount > 0)
                SummaryRow(
                  label: 'Giảm giá',
                  value: '-${Formatter.price(order.discount)}',
                  valueColor: AppColors.error,
                ),
              SummaryRow(
                label: 'Thanh toán',
                value: _paymentLabel(order.paymentMethod, order.paid),
                valueColor: order.paid ? AppColors.success : null,
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
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Liên hệ shop'),
              ),
            ),
            if (isCancellable) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: _cancelling ? null : _cancelOrder,
                  child: _cancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.error,
                          ),
                        )
                      : const Text('Hủy đơn'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  List<(String, String, bool, bool)> _buildTimeline() {
    const statuses = [
      AppConstants.statusPending,
      AppConstants.statusConfirmed,
      AppConstants.statusShipping,
      AppConstants.statusDelivered,
    ];
    const labels = [
      'Đặt hàng thành công',
      'Đã xác nhận',
      'Đang giao hàng',
      'Đã giao',
    ];

    final statusIndex = statuses.indexOf(order.status);
    final isCancelled = order.status == AppConstants.statusCancelled;

    if (isCancelled) {
      return [
        ('Đặt hàng', Formatter.date(order.createdAt), true, false),
        ('Đã hủy', '', false, true),
      ];
    }

    return List.generate(labels.length, (i) {
      final done = statusIndex > i;
      final active = statusIndex == i;
      final timeStr = i == 0 ? Formatter.date(order.createdAt) : '';
      return (labels[i], timeStr, done, active);
    });
  }

  String _paymentLabel(String method, bool paid) {
    final label = switch (method) {
      'vnpay' => 'VNPay',
      'cod' => 'Tiền mặt (COD)',
      'bank_transfer' => 'Chuyển khoản',
      _ => method,
    };
    return paid ? '$label · Đã thanh toán' : label;
  }

  Widget _statusChip(String status) {
    final label = OrderStatusLabel.map[status] ?? status;
    final color = switch (status) {
      AppConstants.statusDelivered => AppColors.success,
      AppConstants.statusCancelled => AppColors.error,
      AppConstants.statusShipping => AppColors.primary,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _timelineStep(
    (String, String, bool, bool) step, {
    bool isLast = false,
  }) {
    final (label, time, done, active) = step;
    final color = done
        ? AppColors.success
        : (active ? AppColors.primary : AppColors.border);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: color,
                child: Icon(
                  done
                      ? Icons.check
                      : (active ? Icons.local_shipping : Icons.circle),
                  size: 12,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? AppColors.success : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: active || done
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: active || done
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(AppDimens.cardPaddingLg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppDimens.brCard,
      boxShadow: AppDimens.cardShadow,
    ),
    child: child,
  );
}

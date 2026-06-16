import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/summary_row.dart';
import '../../../data/mock_data.dart';
import '../../../routes/app_routes.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Đặt hàng thành công', '16/06 09:24', true, false),
      ('Đã xác nhận', '16/06 10:05', true, false),
      ('Đang giao hàng', 'Dự kiến 18/06/2024', false, true),
      ('Đã giao', '', false, false),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.orders)),
        title: const Text('Chi tiết đơn hàng'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        children: [
          _card(Column(
            children: [
              for (int i = 0; i < steps.length; i++) _timelineStep(steps[i], isLast: i == steps.length - 1),
            ],
          )),
          const SizedBox(height: 10),
          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('📍 Địa chỉ giao hàng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              SizedBox(height: 8),
              Text('Nguyễn Văn An · 0912 345 678'),
              Text('123 Đường Nguyễn Huệ, P. Bến Nghé, Q.1, TP.HCM',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          )),
          const SizedBox(height: 10),
          _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              ...MockData.cartItems().map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(i.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                        Text(Formatter.price(i.price), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  )),
            ],
          )),
          const SizedBox(height: 10),
          _card(Column(
            children: const [
              SummaryRow(label: 'Tổng tiền hàng', value: '32.300.000đ'),
              SummaryRow(label: 'Giảm giá', value: '-2.500.000đ', valueColor: AppColors.error),
              SummaryRow(label: 'Thanh toán', value: 'VNPay · Đã thanh toán', valueColor: AppColors.success),
              Divider(),
              SummaryRow(label: 'Tổng cộng', value: '29.800.000đ', isTotal: true),
            ],
          )),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Liên hệ shop'))),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                  onPressed: () {},
                  child: const Text('Hủy đơn'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timelineStep((String, String, bool, bool) step, {bool isLast = false}) {
    final (label, time, done, active) = step;
    final color = done ? AppColors.success : (active ? AppColors.primary : AppColors.border);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(radius: 12, backgroundColor: color,
                  child: Icon(done ? Icons.check : (active ? Icons.local_shipping : Icons.circle), size: 12, color: Colors.white)),
              if (!isLast) Expanded(child: Container(width: 2, color: done ? AppColors.success : AppColors.border)),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: active || done ? FontWeight.w700 : FontWeight.w400,
                    color: active || done ? AppColors.textPrimary : AppColors.textTertiary, fontSize: 13)),
                if (time.isNotEmpty) Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.all(AppDimens.cardPaddingLg),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppDimens.brCard, boxShadow: AppDimens.cardShadow),
        child: child,
      );
}

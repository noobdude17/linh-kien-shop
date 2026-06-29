import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/summary_row.dart';
import '../../../data/mock_data.dart';
import '../../../routes/app_routes.dart';

class AdminOrderDetailScreen extends StatelessWidget {
  const AdminOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.adminAccent,
        foregroundColor: Colors.white,
        leading: BackButton(onPressed: () => context.go(AppRoutes.adminOrders)),
        title: const Text('Đơn LKS-...01'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        children: [
          _card(
            '👤 Khách hàng',
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nguyễn Văn An',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '0912 345 678 · an.nguyen@email.com',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _card(
            '📍 Địa chỉ giao hàng',
            const Text(
              '123 Đường Nguyễn Huệ, P. Bến Nghé, Q.1, TP.HCM',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          _card(
            'Sản phẩm',
            Column(
              children: MockData.cartItems()
                  .map(
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              i.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
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
            const Column(
              children: [
                SummaryRow(
                  label: 'Thanh toán',
                  value: 'VNPay · Đã thanh toán',
                  valueColor: AppColors.success,
                ),
                Divider(),
                SummaryRow(
                  label: 'Tổng cộng',
                  value: '29.800.000đ',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Chờ xác nhận'), Icon(Icons.arrow_drop_down)],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminAccent,
              ),
              onPressed: () => context.go(AppRoutes.adminOrders),
              child: const Text('Cập nhật trạng thái'),
            ),
          ),
        ],
      ),
    );
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
}

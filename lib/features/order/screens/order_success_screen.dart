import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/summary_row.dart';
import '../../../routes/app_routes.dart';
import '../providers/order_providers.dart';

class OrderSuccessScreen extends ConsumerWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderCreationProvider).valueOrNull;
    final code = order?.code ?? '—';
    final total = order?.totalAmount ?? 0;
    final payLabel = order?.paymentMethod == 'cod' ? 'COD' : 'VNPay';
    final address = order?.address ?? '—';
    final orderId = order?.id ?? 'o1';

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: const BoxDecoration(
                    color: AppColors.surface, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                      color: AppColors.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Đặt hàng thành công!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text(
                'Cảm ơn bạn đã mua hàng. Đơn hàng đang được xử lý.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'Mã đơn: $code',
                  style: const TextStyle(
                      color: AppColors.accentBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x0F000000),
                          blurRadius: 4,
                          offset: Offset(0, 1)),
                    ]),
                child: Column(
                  children: [
                    SummaryRow(label: 'Phương thức', value: payLabel),
                    SummaryRow(label: 'Giao đến', value: address),
                    const SummaryRow(label: 'Dự kiến', value: '2-3 ngày'),
                    SummaryRow(
                        label: 'Tổng cộng',
                        value: Formatter.price(total),
                        isTotal: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Theo dõi đơn hàng',
                onPressed: () =>
                    context.go('${AppRoutes.orderDetail}/$orderId'),
              ),
              const SizedBox(height: 10),
              AppOutlinedButton(
                label: 'Tiếp tục mua sắm',
                onPressed: () => context.go(AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

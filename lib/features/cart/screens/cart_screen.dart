import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../core/widgets/summary_row.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../routes/app_routes.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final total = subtotal;
    final notifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
        title: Text('Giỏ hàng (${items.length})'),
      ),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Giỏ hàng trống',
              message: 'Thêm sản phẩm để bắt đầu mua sắm',
              actionLabel: 'Khám phá sản phẩm',
              onAction: () => context.go(AppRoutes.home),
            )
          : ListView(
              padding: const EdgeInsets.all(AppDimens.screenPadding),
              children: [
                ...items.map((item) => _cartItem(context, notifier, item)),
                _voucherBox(),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(AppDimens.cardPaddingLg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppDimens.brCard,
                    boxShadow: AppDimens.cardShadow,
                  ),
                  child: Column(
                    children: [
                      SummaryRow(
                        label: 'Tạm tính',
                        value: Formatter.price(subtotal),
                      ),
                      const SummaryRow(
                        label: 'Phí vận chuyển',
                        value: 'Miễn phí',
                        valueColor: AppColors.success,
                      ),
                      const Divider(),
                      SummaryRow(
                        label: 'Tổng cộng',
                        value: Formatter.price(subtotal),
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : _bottomBar(context, items.length, total),
    );
  }

  Widget _cartItem(
    BuildContext context,
    CartNotifier notifier,
    CartItemModel item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.brCard,
        boxShadow: AppDimens.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.selected,
            onChanged: (_) => notifier.toggleSelected(
              item.productId,
              variantId: item.variantId,
            ),
          ),
          ImagePlaceholder(
            label: item.imageLabel,
            imageUrl: item.imageUrl,
            width: 64,
            height: 64,
            radius: 8,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  item.variant,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  Formatter.price(item.price),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                QuantityStepper(
                  value: item.quantity,
                  onChanged: (v) => notifier.setQuantity(
                    item.productId,
                    v,
                    variantId: item.variantId,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.textTertiary,
            ),
            onPressed: () =>
                notifier.remove(item.productId, variantId: item.variantId),
          ),
        ],
      ),
    );
  }

  Widget _voucherBox() => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(AppDimens.cardPadding),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppDimens.brCard,
      border: Border.all(color: AppColors.border, width: 1.2),
    ),
    child: Row(
      children: const [
        Text('🎟️', style: TextStyle(fontSize: 18)),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Thêm mã giảm giá / voucher',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        Text(
          'Áp dụng',
          style: TextStyle(
            color: AppColors.accentBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _bottomBar(BuildContext context, int count, double total) => Container(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      boxShadow: AppDimens.bottomBarShadow,
    ),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng thanh toán',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  Formatter.price(total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AccentButton(
              label: 'Đặt hàng ($count) →',
              onPressed: () => context.go(AppRoutes.checkout),
            ),
          ),
        ],
      ),
    ),
  );
}

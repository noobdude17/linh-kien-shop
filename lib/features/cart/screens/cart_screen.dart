import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../core/widgets/summary_row.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../routes/app_routes.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final List<CartItemModel> _items = MockData.cartItems();

  double get _subtotal => _items.where((e) => e.selected).fold(0, (s, e) => s + e.subtotal);
  double get _discount => 2500000;
  double get _total => _subtotal - _discount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.home)),
        title: Text('Giỏ hàng (${_items.length})'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        children: [
          ..._items.map(_cartItem),
          _voucherBox(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(AppDimens.cardPaddingLg),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppDimens.brCard, boxShadow: AppDimens.cardShadow),
            child: Column(
              children: [
                SummaryRow(label: 'Tạm tính', value: Formatter.price(_subtotal)),
                const SummaryRow(label: 'Phí vận chuyển', value: 'Miễn phí', valueColor: AppColors.success),
                SummaryRow(label: 'Giảm giá', value: '-${Formatter.price(_discount)}', valueColor: AppColors.error),
                const Divider(),
                SummaryRow(label: 'Tổng cộng', value: Formatter.price(_total), isTotal: true),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomBar(context),
    );
  }

  Widget _cartItem(CartItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppDimens.cardPadding),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppDimens.brCard, boxShadow: AppDimens.cardShadow),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.selected,
            onChanged: (v) => setState(() => item.selected = v ?? true),
          ),
          ImagePlaceholder(label: item.imageLabel, height: 64, radius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text(item.variant, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(Formatter.price(item.price),
                    style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                QuantityStepper(value: item.quantity, onChanged: (v) => setState(() => item.quantity = v)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textTertiary),
            onPressed: () => setState(() => _items.remove(item)),
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
          border: Border.all(color: AppColors.primary, width: 1.2),
        ),
        child: Row(
          children: const [
            Text('🎟️', style: TextStyle(fontSize: 18)),
            SizedBox(width: 10),
            Expanded(child: Text('Thêm mã giảm giá / voucher', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
            Text('Áp dụng', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _bottomBar(BuildContext context) => Container(
        decoration: const BoxDecoration(color: AppColors.surface, boxShadow: AppDimens.bottomBarShadow),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng thanh toán', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(Formatter.price(_total),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryButton(
                  label: 'Đặt hàng (${_items.length}) →',
                  onPressed: () => context.go(AppRoutes.checkout),
                ),
              ),
            ],
          ),
        ),
      );
}

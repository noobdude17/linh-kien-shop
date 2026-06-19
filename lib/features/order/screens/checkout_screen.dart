import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/summary_row.dart';
import '../../../data/mock_data.dart';
import '../../../routes/app_routes.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _payment = AppConstants.payVnpay;
  final _addr = MockData.addresses.first;
  final _items = MockData.cartItems();

  @override
  Widget build(BuildContext context) {
    final total = 29800000;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(AppRoutes.cart)),
        title: const Text('Đặt hàng'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        children: [
          _stepIndicator(),
          const SizedBox(height: 12),
          _section('📍 Địa chỉ giao hàng', trailing: GestureDetector(
            onTap: () => context.go(AppRoutes.addresses),
            child: const Text('Đổi →', style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w500)),
          ), child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_addr.name} · ${_addr.phone}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(_addr.detail, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              ],
            ),
          )),
          _section('📦 Sản phẩm (${_items.length})', child: Column(
            children: _items.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(i.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                  const SizedBox(width: 8),
                  Text('SL: ${i.quantity}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Text(Formatter.price(i.price), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ],
              ),
            )).toList(growable: false),
          )),
          _section('💳 Phương thức thanh toán', child: Column(
            children: [
              _paymentOption(AppConstants.payVnpay, 'VNPay', 'ATM / Ví điện tử / QR Code', _vnpayLogo()),
              const SizedBox(height: 8),
              _paymentOption(AppConstants.payCod, 'Thanh toán khi nhận hàng', 'COD · Kiểm tra hàng trước khi trả',
                  const Text('💵', style: TextStyle(fontSize: 24))),
            ],
          )),
          _section('', child: Column(
            children: [
              const SummaryRow(label: 'Tạm tính', value: '32.300.000đ'),
              const SummaryRow(label: 'Phí vận chuyển', value: 'Miễn phí', valueColor: AppColors.success),
              const SummaryRow(label: 'Giảm giá', value: '-2.500.000đ', valueColor: AppColors.error),
              const Divider(),
              SummaryRow(label: 'Tổng cộng', value: Formatter.price(total), isTotal: true),
            ],
          )),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: AppColors.surface, boxShadow: AppDimens.bottomBarShadow),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng thanh toán', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text(Formatter.price(total),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 10),
              _payment == AppConstants.payVnpay
                  ? AccentButton(label: 'Thanh toán qua VNPay 🔒', onPressed: () => context.go(AppRoutes.vnpay))
                  : AccentButton(label: 'Đặt hàng (COD)', onPressed: () => context.go(AppRoutes.success)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepIndicator() {
    Widget circle(String t, Color bg, Color fg) => CircleAvatar(radius: 14, backgroundColor: bg,
        child: Text(t, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppDimens.brCard, boxShadow: AppDimens.cardShadow),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(children: [circle('✓', AppColors.success, Colors.white), const SizedBox(height: 4), const Text('Giỏ hàng', style: TextStyle(fontSize: 10))]),
          Container(width: 40, height: 2, color: AppColors.success, margin: const EdgeInsets.only(bottom: 16)),
          Column(children: [circle('2', AppColors.accentBlue, Colors.white), const SizedBox(height: 4), const Text('Đặt hàng', style: TextStyle(fontSize: 10))]),
          Container(width: 40, height: 2, color: AppColors.border, margin: const EdgeInsets.only(bottom: 16)),
          Column(children: [circle('3', AppColors.border, AppColors.textSecondary), const SizedBox(height: 4), const Text('Thanh toán', style: TextStyle(fontSize: 10))]),
        ],
      ),
    );
  }

  Widget _section(String title, {Widget? child, Widget? trailing}) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(AppDimens.cardPaddingLg),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppDimens.brCard, boxShadow: AppDimens.cardShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ?trailing,
                ],
              ),
            if (title.isNotEmpty) const SizedBox(height: 12),
            ?child,
          ],
        ),
      );

  Widget _paymentOption(String value, String name, String desc, Widget logo) {
    final selected = _payment == value;
    return InkWell(
      onTap: () => setState(() => _payment = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? AppColors.accentBlue : AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(8),
          color: selected ? const Color(0xFFEFF6FF) : null,
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.accentBlue : AppColors.border, size: 20),
            const SizedBox(width: 10),
            logo,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vnpayLogo() => Container(
        width: 48, height: 28,
        decoration: BoxDecoration(color: AppColors.vnpBlue, borderRadius: BorderRadius.circular(6)),
        alignment: Alignment.center,
        child: const Text.rich(TextSpan(children: [
          TextSpan(text: 'VN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
          TextSpan(text: 'PAY', style: TextStyle(color: AppColors.vnpOrange, fontWeight: FontWeight.w900, fontSize: 11)),
        ])),
      );
}

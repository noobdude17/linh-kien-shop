import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/summary_row.dart';
import '../../../data/models/address_model.dart';
import '../../../routes/app_routes.dart';
import '../../cart/providers/cart_provider.dart';
import '../../profile/providers/address_providers.dart';
import '../providers/order_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _payment = AppConstants.payVnpay;
  bool _placing = false;

  Future<void> _submit({
    required double total,
    required AddressModel addr,
  }) async {
    if (_placing) return;
    final items = ref.read(cartProvider).where((e) => e.selected).toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 sản phẩm')),
      );
      return;
    }
    setState(() => _placing = true);
    try {
      await ref
          .read(orderCreationProvider.notifier)
          .placeOrder(
            items: items,
            totalAmount: total,
            address: '${addr.name} · ${addr.phone} — ${addr.detail}',
            paymentMethod: _payment,
          );
      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      if (_payment == AppConstants.payVnpay) {
        context.go(AppRoutes.vnpay);
      } else {
        context.go(AppRoutes.success);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt hàng thất bại, vui lòng thử lại')),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider).where((e) => e.selected).toList();
    final subtotal = ref.watch(cartSubtotalProvider);
    final addrAsync = ref.watch(addressesProvider);

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
          _buildAddressSection(addrAsync),
          _section(
            '📦 Sản phẩm (${items.length})',
            child: items.isEmpty
                ? const Text(
                    'Không có sản phẩm nào được chọn',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  )
                : Column(
                    children: items
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
                                const SizedBox(width: 8),
                                Text(
                                  'SL: ${i.quantity}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  Formatter.price(i.price),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          _section(
            '💳 Phương thức thanh toán',
            child: Column(
              children: [
                _paymentOption(
                  AppConstants.payVnpay,
                  'VNPay',
                  'ATM / Ví điện tử / QR Code',
                  _vnpayLogo(),
                ),
                const SizedBox(height: 8),
                _paymentOption(
                  AppConstants.payCod,
                  'Thanh toán khi nhận hàng',
                  'COD · Kiểm tra hàng trước khi trả',
                  const Text('💵', style: TextStyle(fontSize: 24)),
                ),
              ],
            ),
          ),
          _section(
            '',
            child: Column(
              children: [
                SummaryRow(label: 'Tạm tính', value: Formatter.price(subtotal)),
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
      bottomNavigationBar: _buildBottomBar(subtotal, addrAsync),
    );
  }

  Widget _buildAddressSection(AsyncValue<List<AddressModel>> addrAsync) {
    return addrAsync.when(
      loading: () => _section(
        '📍 Địa chỉ giao hàng',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => _section(
        '📍 Địa chỉ giao hàng',
        child: const Text(
          'Không tải được địa chỉ',
          style: TextStyle(color: AppColors.error, fontSize: 13),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return _section(
            '📍 Địa chỉ giao hàng',
            child: Column(
              children: [
                const Text(
                  'Chưa có địa chỉ giao hàng',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                AppOutlinedButton(
                  label: 'Thêm địa chỉ',
                  onPressed: () => context.go(AppRoutes.addAddress),
                ),
              ],
            ),
          );
        }
        final addr = list.first;
        return _section(
          '📍 Địa chỉ giao hàng',
          trailing: GestureDetector(
            onTap: () => context.go(AppRoutes.addresses),
            child: const Text(
              'Đổi →',
              style: TextStyle(
                color: AppColors.accentBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${addr.name} · ${addr.phone}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  addr.detail,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(
    double subtotal,
    AsyncValue<List<AddressModel>> addrAsync,
  ) {
    final addr = addrAsync.valueOrNull?.firstOrNull;
    final hasItems = ref.watch(cartProvider).any((e) => e.selected);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppDimens.bottomBarShadow,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng thanh toán',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  Formatter.price(subtotal),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_placing)
              const SizedBox(
                height: 50,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_payment == AppConstants.payVnpay)
              AccentButton(
                label: 'Thanh toán qua VNPay 🔒',
                onPressed: addr != null && hasItems
                    ? () => _submit(total: subtotal, addr: addr)
                    : null,
              )
            else
              AccentButton(
                label: 'Đặt hàng (COD)',
                onPressed: addr != null && hasItems
                    ? () => _submit(total: subtotal, addr: addr)
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _stepIndicator() {
    Widget circle(String t, Color bg, Color fg) => CircleAvatar(
      radius: 14,
      backgroundColor: bg,
      child: Text(
        t,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimens.brCard,
        boxShadow: AppDimens.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              circle('✓', AppColors.success, Colors.white),
              const SizedBox(height: 4),
              const Text('Giỏ hàng', style: TextStyle(fontSize: 10)),
            ],
          ),
          Container(
            width: 40,
            height: 2,
            color: AppColors.success,
            margin: const EdgeInsets.only(bottom: 16),
          ),
          Column(
            children: [
              circle('2', AppColors.accentBlue, Colors.white),
              const SizedBox(height: 4),
              const Text('Đặt hàng', style: TextStyle(fontSize: 10)),
            ],
          ),
          Container(
            width: 40,
            height: 2,
            color: AppColors.border,
            margin: const EdgeInsets.only(bottom: 16),
          ),
          Column(
            children: [
              circle('3', AppColors.border, AppColors.textSecondary),
              const SizedBox(height: 4),
              const Text('Thanh toán', style: TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(String title, {Widget? child, Widget? trailing}) => Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
          border: Border.all(
            color: selected ? AppColors.accentBlue : AppColors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          color: selected ? const Color(0xFFEFF6FF) : null,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.accentBlue : AppColors.border,
              size: 20,
            ),
            const SizedBox(width: 10),
            logo,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    desc,
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
      ),
    );
  }

  Widget _vnpayLogo() => Container(
    width: 48,
    height: 28,
    decoration: BoxDecoration(
      color: AppColors.vnpBlue,
      borderRadius: BorderRadius.circular(6),
    ),
    alignment: Alignment.center,
    child: const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'VN',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          TextSpan(
            text: 'PAY',
            style: TextStyle(
              color: AppColors.vnpOrange,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
  );
}

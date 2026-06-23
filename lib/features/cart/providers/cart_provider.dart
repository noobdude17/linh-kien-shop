import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/cart_item_model.dart';
import '../../../data/models/product_model.dart';

/// Quản lý state giỏ hàng toàn app (badge, màn Cart, Checkout đều đọc chung).
class CartNotifier extends Notifier<List<CartItemModel>> {
  @override
  List<CartItemModel> build() => []; // bắt đầu rỗng; user thêm qua add()

  void add(
    ProductModel p, {
    int qty = 1,
    String variant = '',
    double? priceOverride,
  }) {
    final idx = state.indexWhere(
      (e) => e.productId == p.id && e.variant == variant,
    );
    if (idx >= 0) {
      final updated = [...state];
      updated[idx].quantity += qty;
      state = updated;
    } else {
      state = [
        ...state,
        CartItemModel(
          productId: p.id,
          name: p.name,
          variant: variant,
          price: priceOverride ?? p.price,
          imageLabel: p.imageLabel,
          quantity: qty,
        ),
      ];
    }
  }

  void remove(String productId) {
    state = state.where((e) => e.productId != productId).toList();
  }

  void setQuantity(String productId, int qty) {
    if (qty < 1) return;
    state = [
      for (final e in state)
        if (e.productId == productId)
          (CartItemModel(
            productId: e.productId,
            name: e.name,
            variant: e.variant,
            price: e.price,
            imageLabel: e.imageLabel,
            quantity: qty,
            selected: e.selected,
          ))
        else
          e,
    ];
  }

  void toggleSelected(String productId) {
    state = [
      for (final e in state)
        if (e.productId == productId)
          (CartItemModel(
            productId: e.productId,
            name: e.name,
            variant: e.variant,
            price: e.price,
            imageLabel: e.imageLabel,
            quantity: e.quantity,
            selected: !e.selected,
          ))
        else
          e,
    ];
  }

  void clear() => state = [];
}

final cartProvider =
    NotifierProvider<CartNotifier, List<CartItemModel>>(CartNotifier.new);

/// Tổng tiền các item được chọn.
final cartSubtotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.where((e) => e.selected).fold(0.0, (s, e) => s + e.subtotal);
});

/// Số lượng dòng hàng (cho badge).
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).length;
});

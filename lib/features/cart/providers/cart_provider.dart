import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/cart_item_model.dart';
import '../../../data/models/product_model.dart';

/// Quản lý state giỏ hàng toàn app (badge, màn Cart, Checkout đều đọc chung).
class CartNotifier extends Notifier<List<CartItemModel>> {
  @override
  List<CartItemModel> build() => [];

  bool _matches(CartItemModel e, String productId, String variantId) =>
      e.productId == productId && e.variantId == variantId;

  void add(
    ProductModel p, {
    int qty = 1,
    String variant = '',
    String variantId = '',
    double? priceOverride,
  }) {
    final idx = state.indexWhere((e) => _matches(e, p.id, variantId));
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
          variantId: variantId,
          price: priceOverride ?? p.price,
          imageLabel: p.imageLabel,
          imageUrl: p.primaryImageUrl,
          quantity: qty,
        ),
      ];
    }
  }

  void remove(String productId, {String variantId = ''}) {
    state = state.where((e) => !_matches(e, productId, variantId)).toList();
  }

  void setQuantity(String productId, int qty, {String variantId = ''}) {
    if (qty < 1) return;
    state = [
      for (final e in state)
        if (_matches(e, productId, variantId))
          CartItemModel(
            productId: e.productId,
            name: e.name,
            variant: e.variant,
            variantId: e.variantId,
            price: e.price,
            imageLabel: e.imageLabel,
            imageUrl: e.imageUrl,
            quantity: qty,
            selected: e.selected,
          )
        else
          e,
    ];
  }

  void toggleSelected(String productId, {String variantId = ''}) {
    state = [
      for (final e in state)
        if (_matches(e, productId, variantId))
          CartItemModel(
            productId: e.productId,
            name: e.name,
            variant: e.variant,
            variantId: e.variantId,
            price: e.price,
            imageLabel: e.imageLabel,
            imageUrl: e.imageUrl,
            quantity: e.quantity,
            selected: !e.selected,
          )
        else
          e,
    ];
  }

  void clear() => state = [];
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItemModel>>(
  CartNotifier.new,
);

/// Tổng tiền các item được chọn.
final cartSubtotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.where((e) => e.selected).fold(0.0, (s, e) => s + e.subtotal);
});

/// Số lượng dòng hàng (cho badge).
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).length;
});

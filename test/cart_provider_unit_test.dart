import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linh_kien_shop/data/models/product_model.dart';
import 'package:linh_kien_shop/features/cart/providers/cart_provider.dart';

// Helper: build a throw-away product for the tests.
ProductModel product(String id, {double price = 100000, String name = 'Item'}) =>
    ProductModel(id: id, name: name, price: price, categoryId: 'cpu');

void main() {
  // Fresh Riverpod container per test so state never leaks between cases.
  late ProviderContainer container;
  CartNotifier notifier() => container.read(cartProvider.notifier);
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  group('CartNotifier – Unit tests', () {
    test('add() should put a new product into an empty cart', () {
      // STEP 1 – Arrange
      expect(container.read(cartProvider), isEmpty);
      // STEP 2 – Act
      notifier().add(product('p1'), qty: 2);
      // STEP 3 – Assert
      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.productId, 'p1');
      expect(cart.first.quantity, 2);
    });

    test('add() should merge quantity when the same product is added again', () {
      // Arrange
      notifier().add(product('p1'), qty: 1);
      // Act
      notifier().add(product('p1'), qty: 3);
      // Assert – one line, quantity summed
      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.quantity, 4);
    });

    test('add() should keep different variants of one product as separate lines',
        () {
      notifier().add(product('p1'), variantId: 'red');
      notifier().add(product('p1'), variantId: 'blue');
      expect(container.read(cartProvider).length, 2);
    });

    test('remove() should delete only the matching line', () {
      notifier().add(product('p1'));
      notifier().add(product('p2'));
      notifier().remove('p1');
      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.productId, 'p2');
    });

    test('setQuantity() should overwrite the quantity of a line', () {
      notifier().add(product('p1'), qty: 1);
      notifier().setQuantity('p1', 9);
      expect(container.read(cartProvider).first.quantity, 9);
    });

    test('setQuantity() should ignore invalid (< 1) quantities', () {
      notifier().add(product('p1'), qty: 5);
      notifier().setQuantity('p1', 0);
      // Quantity stays untouched.
      expect(container.read(cartProvider).first.quantity, 5);
    });

    test('toggleSelected() should flip the selected flag', () {
      notifier().add(product('p1')); // selected defaults to true
      notifier().toggleSelected('p1');
      expect(container.read(cartProvider).first.selected, false);
    });

    test('clear() should empty the whole cart', () {
      notifier().add(product('p1'));
      notifier().add(product('p2'));
      notifier().clear();
      expect(container.read(cartProvider), isEmpty);
    });
  });
}

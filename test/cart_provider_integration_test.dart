import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linh_kien_shop/data/models/product_model.dart';
import 'package:linh_kien_shop/features/cart/providers/cart_provider.dart';

// Integration test: verifies that CartNotifier and the two *derived* providers
// (cartSubtotalProvider + cartCountProvider) work together end-to-end, exactly
// as the badge, Cart screen and Checkout screen read them in the real app.

ProductModel product(String id, double price) =>
    ProductModel(id: id, name: id, price: price, categoryId: 'cpu');

void main() {
  late ProviderContainer container;
  CartNotifier notifier() => container.read(cartProvider.notifier);
  int count() => container.read(cartCountProvider);
  double subtotal() => container.read(cartSubtotalProvider);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  group('Cart flow – Integration test', () {
    test('a full shopping flow keeps count and subtotal consistent', () {
      // STEP 1 – Arrange: empty cart -> badge 0, total 0.
      expect(count(), 0);
      expect(subtotal(), 0);

      // STEP 2 – Act: add two products, one of them twice.
      notifier().add(product('cpu', 5000000), qty: 1); // 5,000,000
      notifier().add(product('ram', 2000000), qty: 2); // 4,000,000
      notifier().add(product('cpu', 5000000), qty: 1); // merges -> +5,000,000

      // STEP 3 – Assert: 2 lines, subtotal = 5M*2 + 2M*2 = 14,000,000.
      expect(count(), 2);
      expect(subtotal(), 14000000);
    });

    test('deselected lines are excluded from the subtotal but still counted',
        () {
      // Arrange
      notifier().add(product('cpu', 5000000)); // selected
      notifier().add(product('ram', 2000000)); // selected

      // Act – user unticks the RAM line before checkout.
      notifier().toggleSelected('ram');

      // Assert – both lines still shown (count 2), only CPU billed.
      expect(count(), 2);
      expect(subtotal(), 5000000);
    });

    test('changing quantity re-computes the subtotal live', () {
      notifier().add(product('cpu', 5000000), qty: 1);
      expect(subtotal(), 5000000);

      notifier().setQuantity('cpu', 3);
      expect(subtotal(), 15000000);
    });

    test('clearing the cart resets both derived providers', () {
      notifier().add(product('cpu', 5000000));
      notifier().add(product('ram', 2000000));

      notifier().clear();

      expect(count(), 0);
      expect(subtotal(), 0);
    });
  });
}

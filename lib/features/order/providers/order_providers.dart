import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/repositories/order_repository.dart';
import '../../auth/providers/auth_providers.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  if (AppConfig.firebaseEnabled) {
    return FirestoreOrderRepository(FirebaseFirestore.instance);
  }
  return MockOrderRepository();
});

class OrderCreationNotifier extends AsyncNotifier<OrderModel?> {
  @override
  FutureOr<OrderModel?> build() => null;

  Future<OrderModel> placeOrder({
    required List<CartItemModel> items,
    required double totalAmount,
    required String address,
    required String paymentMethod,
  }) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(currentUserProvider);
      final order = await ref.read(orderRepositoryProvider).create(
            userId: user?.id ?? 'guest',
            customerName: user?.name ?? 'Khách',
            items: items,
            subtotal: totalAmount,
            totalAmount: totalAmount,
            address: address,
            paymentMethod: paymentMethod,
          );
      state = AsyncData(order);
      return order;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final orderCreationProvider =
    AsyncNotifierProvider<OrderCreationNotifier, OrderModel?>(
  OrderCreationNotifier.new,
);

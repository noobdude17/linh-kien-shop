import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';

abstract class OrderRepository {
  Future<OrderModel> create({
    required String userId,
    required String customerName,
    required List<CartItemModel> items,
    required double subtotal,
    required double totalAmount,
    required String address,
    required String paymentMethod,
  });
  Future<List<OrderModel>> getByUser(String userId);
  Future<OrderModel?> getById(String id);
  Future<void> cancelOrder(String id);

  /// Đánh dấu đơn đã thanh toán thành công (paid=true). KHÔNG đổi trạng thái —
  /// đơn vẫn 'chờ xác nhận' tới khi admin duyệt.
  Future<void> markPaid(String id);
}

class MockOrderRepository implements OrderRepository {
  final List<OrderModel> _store = [];
  int _seq = 1;

  String _genCode() {
    final now = DateTime.now();
    final seq = (_seq).toString().padLeft(4, '0');
    return 'LKS-'
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '-$seq';
  }

  @override
  Future<OrderModel> create({
    required String userId,
    required String customerName,
    required List<CartItemModel> items,
    required double subtotal,
    required double totalAmount,
    required String address,
    required String paymentMethod,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final id = 'mock_${_seq++}';
    final order = OrderModel(
      id: id,
      code: _genCode(),
      userId: userId,
      customerName: customerName,
      items: items,
      subtotal: subtotal,
      totalAmount: totalAmount,
      status: AppConstants.statusPending,
      address: address,
      paymentMethod: paymentMethod,
      paid: false,
      createdAt: DateTime.now(),
    );
    _store.add(order);
    return order;
  }

  @override
  Future<List<OrderModel>> getByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _store.where((o) => o.userId == userId).toList().reversed.toList();
  }

  @override
  Future<OrderModel?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _store.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cancelOrder(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _store.indexWhere((o) => o.id == id);
    if (idx != -1) {
      _store[idx] = _store[idx].copyWith(status: AppConstants.statusCancelled);
    }
  }

  @override
  Future<void> markPaid(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _store.indexWhere((o) => o.id == id);
    if (idx != -1) {
      _store[idx] = _store[idx].copyWith(paid: true);
    }
  }
}

class FirestoreOrderRepository implements OrderRepository {
  final FirebaseFirestore _db;
  FirestoreOrderRepository(this._db);

  @override
  Future<OrderModel> create({
    required String userId,
    required String customerName,
    required List<CartItemModel> items,
    required double subtotal,
    required double totalAmount,
    required String address,
    required String paymentMethod,
  }) async {
    final now = DateTime.now();
    final docRef = _db.collection(AppConstants.colOrders).doc();
    final seq = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    final code =
        'LKS-'
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '-$seq';
    final order = OrderModel(
      id: docRef.id,
      code: code,
      userId: userId,
      customerName: customerName,
      items: items,
      subtotal: subtotal,
      totalAmount: totalAmount,
      status: AppConstants.statusPending,
      address: address,
      paymentMethod: paymentMethod,
      paid: false,
      createdAt: now,
    );
    await docRef.set(order.toFirestore());
    return order;
  }

  @override
  Future<List<OrderModel>> getByUser(String userId) async {
    final snap = await _db
        .collection(AppConstants.colOrders)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(OrderModel.fromFirestore).toList();
  }

  @override
  Future<OrderModel?> getById(String id) async {
    final doc = await _db.collection(AppConstants.colOrders).doc(id).get();
    if (!doc.exists) return null;
    return OrderModel.fromFirestore(doc);
  }

  @override
  Future<void> cancelOrder(String id) async {
    await _db.collection(AppConstants.colOrders).doc(id).update({
      'status': AppConstants.statusCancelled,
    });
  }

  @override
  Future<void> markPaid(String id) async {
    await _db.collection(AppConstants.colOrders).doc(id).update({
      'paid': true,
    });
  }
}

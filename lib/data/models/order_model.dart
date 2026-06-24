import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item_model.dart';

class OrderTimelineStep {
  final String label;
  final String icon;
  final DateTime? time;
  final bool done;
  final bool active;

  const OrderTimelineStep({
    required this.label,
    required this.icon,
    this.time,
    this.done = false,
    this.active = false,
  });
}

class OrderModel {
  final String id;
  final String code; // LKS-2024061601
  final String userId;
  final String customerName;
  final List<CartItemModel> items;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final String status;
  final String address;
  final String paymentMethod;
  final bool paid;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.code,
    required this.userId,
    this.customerName = '',
    required this.items,
    this.subtotal = 0,
    this.discount = 0,
    required this.totalAmount,
    required this.status,
    this.address = '',
    this.paymentMethod = 'vnpay',
    this.paid = false,
    required this.createdAt,
  });

  int get itemCount => items.fold(0, (s, e) => s + e.quantity);

  OrderModel copyWith({String? status}) => OrderModel(
        id: id,
        code: code,
        userId: userId,
        customerName: customerName,
        items: items,
        subtotal: subtotal,
        discount: discount,
        totalAmount: totalAmount,
        status: status ?? this.status,
        address: address,
        paymentMethod: paymentMethod,
        paid: paid,
        createdAt: createdAt,
      );

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      code: data['code'] ?? '',
      userId: data['userId'] ?? '',
      customerName: data['customerName'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => CartItemModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      address: data['address'] ?? '',
      paymentMethod: data['paymentMethod'] ?? 'vnpay',
      paid: data['paid'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'code': code,
        'userId': userId,
        'customerName': customerName,
        'items': items.map((e) => e.toMap()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'totalAmount': totalAmount,
        'status': status,
        'address': address,
        'paymentMethod': paymentMethod,
        'paid': paid,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

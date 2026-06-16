import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String imageUrl;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  double get subtotal => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['productId'] ?? '',
        productName: map['productName'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        quantity: map['quantity'] ?? 1,
        imageUrl: map['imageUrl'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
      };
}

class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String address;
  final String paymentMethod;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.address,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      address: data['address'] ?? '',
      paymentMethod: data['paymentMethod'] ?? 'vnpay',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'items': items.map((e) => e.toMap()).toList(),
        'totalAmount': totalAmount,
        'status': status,
        'address': address,
        'paymentMethod': paymentMethod,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_date.dart';

class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool isHidden;

  const ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isHidden = false,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // productId lấy từ path (products/{id}/reviews/{rid}) khi field thiếu —
    // để nút ẩn/hiện của admin luôn trỏ đúng sản phẩm.
    final pathProductId = doc.reference.parent.parent?.id ?? '';
    final dataProductId = (data['productId'] ?? '') as String;
    return ReviewModel(
      id: doc.id,
      productId: dataProductId.isNotEmpty ? dataProductId : pathProductId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: parseFirestoreDate(data['createdAt']),
      isHidden: data['isHidden'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'productId': productId,
    'userId': userId,
    'userName': userName,
    'rating': rating,
    'comment': comment,
    'createdAt': Timestamp.fromDate(createdAt),
    'isHidden': isHidden,
  };

  ReviewModel copyWith({bool? isHidden}) => ReviewModel(
    id: id,
    productId: productId,
    userId: userId,
    userName: userName,
    rating: rating,
    comment: comment,
    createdAt: createdAt,
    isHidden: isHidden ?? this.isHidden,
  );
}

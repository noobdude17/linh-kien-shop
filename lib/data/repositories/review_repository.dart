import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../mock_data.dart';
import '../models/review_model.dart';

/// Hợp đồng đánh giá sản phẩm. UI/provider phụ thuộc abstract này.
abstract class ReviewRepository {
  Future<List<ReviewModel>> getForProduct(String productId);

  /// Lưu đánh giá mới và cập nhật lại rating/reviewCount của sản phẩm.
  Future<void> add(ReviewModel review);
}

/// Hiện thực giả lập — dùng khi chưa cấu hình Firebase.
class MockReviewRepository implements ReviewRepository {
  Future<T> _delayed<T>(T value) =>
      Future.delayed(const Duration(milliseconds: 200), () => value);

  @override
  Future<List<ReviewModel>> getForProduct(String productId) => _delayed(
    MockData.reviews
        .where((r) => r.productId == productId && !r.isHidden)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );

  @override
  Future<void> add(ReviewModel review) async {
    MockData.reviews.insert(0, review);
  }
}

/// Hiện thực Firestore: products/{id}/reviews.
class FirestoreReviewRepository implements ReviewRepository {
  final FirebaseFirestore _db;
  FirestoreReviewRepository(this._db);

  CollectionReference<Map<String, dynamic>> _col(String productId) => _db
      .collection(AppConstants.colProducts)
      .doc(productId)
      .collection(AppConstants.colReviews);

  @override
  Future<List<ReviewModel>> getForProduct(String productId) async {
    final snap = await _col(
      productId,
    ).orderBy('createdAt', descending: true).get();
    return snap.docs
        .map(ReviewModel.fromFirestore)
        .where((review) => !review.isHidden)
        .toList();
  }

  @override
  Future<void> add(ReviewModel review) async {
    final productRef = _db
        .collection(AppConstants.colProducts)
        .doc(review.productId);
    final reviewRef = _col(review.productId).doc(review.id);

    // Cập nhật rating trung bình + reviewCount trên sản phẩm trong cùng giao dịch
    // để thẻ/sản phẩm phản ánh đúng số liệu sau khi đánh giá.
    await _db.runTransaction((tx) async {
      final productSnap = await tx.get(productRef);
      final data = productSnap.data() ?? {};
      final oldCount = ((data['reviewCount'] ?? 0) as num).toInt();
      final oldRating = (data['rating'] ?? 0).toDouble();

      tx.set(reviewRef, review.toFirestore());
      tx.update(productRef, {
        'rating': recomputeRating(oldRating, oldCount, review.rating),
        'reviewCount': oldCount + 1,
      });
    });
  }

  /// Trung bình mới sau khi thêm 1 đánh giá, làm tròn 1 chữ số thập phân.
  static double recomputeRating(
    double oldRating,
    int oldCount,
    double newRating,
  ) => ((oldRating * oldCount + newRating) / (oldCount + 1) * 10).round() / 10;
}

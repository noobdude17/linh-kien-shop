import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/review_model.dart';

class ReviewNotifier extends FamilyNotifier<List<ReviewModel>, String> {
  @override
  List<ReviewModel> build(String productId) {
    return MockData.reviews.where((r) => r.productId == productId).toList();
  }

  void addReview(ReviewModel review) {
    state = [review, ...state];
  }
}

final reviewProvider =
    NotifierProvider.family<ReviewNotifier, List<ReviewModel>, String>(
        ReviewNotifier.new);

import 'package:flutter_test/flutter_test.dart';
import 'package:linh_kien_shop/data/repositories/review_repository.dart';

void main() {
  test('recomputeRating averages and rounds to 1 decimal', () {
    // 4.8 trên 124 đánh giá, thêm 5 sao → (4.8*124 + 5)/125 = 4.8016 → 4.8
    expect(FirestoreReviewRepository.recomputeRating(4.8, 124, 5), 4.8);
    // Sản phẩm chưa có đánh giá: đúng bằng điểm đầu tiên.
    expect(FirestoreReviewRepository.recomputeRating(0, 0, 4), 4.0);
    // 3.0 trên 1 đánh giá, thêm 4 sao → 3.5
    expect(FirestoreReviewRepository.recomputeRating(3, 1, 4), 3.5);
  });
}
